/**
 * Script to test decompression logic separately
 */

const { createClient } = require('@supabase/supabase-js');
const { createDecipheriv } = require('crypto');
const { promisify } = require('util');
const { gunzip } = require('zlib');
const fs = require('fs');
const path = require('path');

const gunzipAsync = promisify(gunzip);

// Read environment variables from .env.local
function loadEnvFile() {
  try {
    const envPath = path.join(process.cwd(), '.env.local');
    const envContent = fs.readFileSync(envPath, 'utf8');
    
    envContent.split('\n').forEach(line => {
      const trimmedLine = line.trim();
      if (trimmedLine && !trimmedLine.startsWith('#')) {
        const [key, ...valueParts] = trimmedLine.split('=');
        if (key && valueParts.length > 0) {
          process.env[key.trim()] = valueParts.join('=').trim();
        }
      }
    });
  } catch (error) {
    console.error('❌ Could not load .env.local:', error.message);
  }
}

loadEnvFile();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const encryptionKey = process.env.BACKUP_ENCRYPTION_KEY;

if (!supabaseUrl || !supabaseKey || !encryptionKey) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testDecompression() {
  try {
    console.log('🧪 Testing decompression logic...');
    
    // Get the latest backup
    const { data: backups, error } = await supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('status', 'completed')
      .order('created_at', { ascending: false })
      .limit(1);
    
    if (error || !backups || backups.length === 0) {
      console.error('❌ No backups found:', error);
      return;
    }
    
    const backup = backups[0];
    console.log('📋 Testing backup:', backup.filename);
    
    // Download file
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('backups')
      .download(backup.storage_path);
    
    if (downloadError) {
      console.error('❌ Download failed:', downloadError);
      return;
    }
    
    let content = Buffer.from(await fileData.arrayBuffer());
    console.log('📥 Downloaded:', content.length, 'bytes');
    
    // Decrypt
    if (backup.encrypted) {
      console.log('🔓 Decrypting...');
      
      const algorithm = 'aes-256-gcm';
      const key = Buffer.from(encryptionKey, 'utf8');
      
      const iv = content.slice(0, 16);
      const authTag = content.slice(16, 32);
      const encrypted = content.slice(32);
      
      const decipher = createDecipheriv(algorithm, key, iv);
      decipher.setAuthTag(authTag);
      
      content = Buffer.concat([decipher.update(encrypted), decipher.final()]);
      console.log('✅ Decrypted:', content.length, 'bytes');
    }
    
    // Test decompression logic
    if (backup.compressed) {
      console.log('📦 Testing decompression...');
      console.log('📦 Content header (hex):', content.slice(0, 20).toString('hex'));
      console.log('📦 Magic number check: 1f=', content[0] === 0x1f, ', 8b=', content[1] === 0x8b);
      
      if (content[0] === 0x1f && content[1] === 0x8b) {
        console.log('✅ Gzip magic number detected, decompressing...');
        try {
          const decompressed = await gunzipAsync(content);
          console.log('✅ Decompression successful:', decompressed.length, 'bytes');
          
          const text = decompressed.toString('utf8');
          console.log('📝 First 200 chars:', text.substring(0, 200));
          console.log('📝 Contains SQL keywords:');
          console.log('   - INSERT:', text.toLowerCase().includes('insert'));
          console.log('   - CREATE:', text.toLowerCase().includes('create'));
          console.log('   - SELECT:', text.toLowerCase().includes('select'));
          
          // Save decompressed content
          const outputFile = path.join(process.cwd(), 'test-decompressed-content.sql');
          fs.writeFileSync(outputFile, text);
          console.log('💾 Decompressed content saved to:', outputFile);
          
        } catch (gzipError) {
          console.error('❌ Gzip decompression failed:', gzipError);
        }
      } else {
        console.log('❌ No gzip magic number found');
        console.log('📋 Raw content preview:', content.slice(0, 100).toString('utf8'));
      }
    }
    
  } catch (error) {
    console.error('💥 Test failed:', error);
  }
}

testDecompression().then(() => {
  console.log('🏁 Test completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Test crashed:', error);
  process.exit(1);
});
