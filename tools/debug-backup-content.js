/**
 * Script to debug backup content and encryption
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

async function debugBackupContent() {
  try {
    console.log('🔍 Starting backup content debug...');
    console.log('📋 Environment check:', {
      supabaseUrl: !!supabaseUrl,
      supabaseKey: !!supabaseKey,
      encryptionKey: !!encryptionKey
    });
    
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
    console.log('📋 Testing backup:', {
      id: backup.id,
      filename: backup.filename,
      size: backup.size,
      compressed: backup.compressed,
      encrypted: backup.encrypted
    });
    
    // Download file
    console.log('📥 Downloading backup file...');
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('backups')
      .download(backup.storage_path);
    
    if (downloadError) {
      console.error('❌ Download failed:', downloadError);
      return;
    }
    
    let content = Buffer.from(await fileData.arrayBuffer());
    console.log('✅ Downloaded:', content.length, 'bytes');
    console.log('📋 File header (hex):', content.slice(0, 32).toString('hex'));
    console.log('📋 File header (ascii):', content.slice(0, 32).toString('ascii'));
    
    // Decrypt if needed
    if (backup.encrypted) {
      console.log('🔓 Decrypting...');
      
      try {
        const algorithm = 'aes-256-gcm';
        const key = Buffer.from(encryptionKey, 'utf8');
        
        // Extract components
        const iv = content.slice(0, 16);
        const authTag = content.slice(16, 32);
        const encrypted = content.slice(32);
        
        console.log('📋 Decryption info:', {
          totalSize: content.length,
          ivSize: iv.length,
          authTagSize: authTag.length,
          encryptedSize: encrypted.length,
          iv: iv.toString('hex'),
          authTag: authTag.toString('hex')
        });
        
        const decipher = createDecipheriv(algorithm, key, iv);
        decipher.setAuthTag(authTag);
        
        content = Buffer.concat([decipher.update(encrypted), decipher.final()]);
        console.log('✅ Decrypted:', content.length, 'bytes');
        console.log('📋 Decrypted header:', content.slice(0, 32).toString('hex'));
        
      } catch (decryptError) {
        console.error('❌ Decryption failed:', decryptError);
        return;
      }
    }
    
    // Decompress if needed
    if (backup.compressed) {
      console.log('📦 Decompressing...');
      
      try {
        content = await gunzipAsync(content);
        console.log('✅ Decompressed:', content.length, 'bytes');
        console.log('📋 Decompressed starts with:', content.slice(0, 100).toString('utf8'));
        
      } catch (decompressError) {
        console.error('❌ Decompression failed:', decompressError);
        return;
      }
    }
    
    // Convert to text and analyze
    const textContent = content.toString('utf8');
    console.log('📝 Final content:');
    console.log('   Length:', textContent.length, 'characters');
    console.log('   First 500 chars:', textContent.substring(0, 500));
    console.log('   Contains INSERT:', textContent.toLowerCase().includes('insert'));
    console.log('   Contains CREATE:', textContent.toLowerCase().includes('create'));
    console.log('   Contains SQL:', textContent.toLowerCase().includes('sql'));
    
    // Save to file for inspection
    const debugFile = path.join(process.cwd(), 'debug-backup-content.sql');
    fs.writeFileSync(debugFile, textContent);
    console.log('💾 Content saved to:', debugFile);
    
  } catch (error) {
    console.error('💥 Debug failed:', error);
  }
}

debugBackupContent().then(() => {
  console.log('🏁 Debug completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Debug crashed:', error);
  process.exit(1);
});
