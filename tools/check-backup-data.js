/**
 * Script to check backup metadata and compare with storage files
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

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

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkBackupData() {
  console.log('🔍 Checking backup metadata vs storage files...');
  
  try {
    // 1. Get all backup metadata from database
    console.log('\n📋 Fetching backup metadata from database...');
    const { data: backups, error: dbError } = await supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (dbError) {
      console.error('❌ Error fetching backup metadata:', dbError);
      return;
    }
    
    console.log(`✅ Found ${backups?.length || 0} backup records in database:`);
    backups?.forEach((backup, index) => {
      console.log(`\n  ${index + 1}. Backup ID: ${backup.id}`);
      console.log(`     Filename: ${backup.filename}`);
      console.log(`     Storage Path: ${backup.storage_path}`);
      console.log(`     Status: ${backup.status}`);
      console.log(`     Size: ${backup.size} bytes`);
      console.log(`     Created: ${backup.created_at}`);
    });
    
    // 2. Get all files from storage
    console.log('\n📁 Fetching files from backups bucket...');
    const { data: storageFiles, error: storageError } = await supabase.storage
      .from('backups')
      .list('', {
        limit: 100,
        sortBy: { column: 'name', order: 'asc' }
      });
    
    if (storageError) {
      console.error('❌ Error fetching storage files:', storageError);
      return;
    }
    
    console.log(`\n✅ Found ${storageFiles?.length || 0} files in storage:`);
    storageFiles?.forEach((file, index) => {
      console.log(`  ${index + 1}. ${file.name} (${file.metadata?.size || 'unknown'} bytes, updated: ${file.updated_at})`);
    });
    
    // 3. Compare and find mismatches
    console.log('\n🔍 Comparing database records with storage files...');
    
    if (!backups || !storageFiles) {
      console.log('❌ No data to compare');
      return;
    }
    
    const orphanedDbRecords = [];
    const orphanedStorageFiles = [...storageFiles];
    
    backups.forEach(backup => {
      const matchingFile = storageFiles.find(file => 
        file.name === backup.filename || 
        file.name === backup.storage_path ||
        backup.storage_path === file.name ||
        backup.storage_path.endsWith(file.name)
      );
      
      if (matchingFile) {
        console.log(`✅ Match found: ${backup.filename} ↔ ${matchingFile.name}`);
        // Remove from orphaned list
        const index = orphanedStorageFiles.findIndex(f => f.name === matchingFile.name);
        if (index > -1) orphanedStorageFiles.splice(index, 1);
      } else {
        console.log(`❌ No storage file for: ${backup.filename} (path: ${backup.storage_path})`);
        orphanedDbRecords.push(backup);
      }
    });
    
    // 4. Report orphaned items
    if (orphanedDbRecords.length > 0) {
      console.log(`\n⚠️ Found ${orphanedDbRecords.length} database records without storage files:`);
      orphanedDbRecords.forEach(backup => {
        console.log(`  - ${backup.filename} (ID: ${backup.id})`);
      });
    }
    
    if (orphanedStorageFiles.length > 0) {
      console.log(`\n⚠️ Found ${orphanedStorageFiles.length} storage files without database records:`);
      orphanedStorageFiles.forEach(file => {
        console.log(`  - ${file.name}`);
      });
    }
    
    if (orphanedDbRecords.length === 0 && orphanedStorageFiles.length === 0) {
      console.log('\n✅ All backup records have matching storage files!');
    }
    
  } catch (error) {
    console.error('💥 Unexpected error:', error);
  }
}

// Run the check
checkBackupData().then(() => {
  console.log('\n🏁 Check completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Check failed:', error);
  process.exit(1);
});
