/**
 * Test script to debug Supabase Storage issues
 * Usage: node tools/test-storage.js
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
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Use service role for admin operations

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables');
  console.error('NEXT_PUBLIC_SUPABASE_URL:', supabaseUrl ? 'Found' : 'Missing');
  console.error('SUPABASE_SERVICE_ROLE_KEY:', supabaseKey ? 'Found' : 'Missing');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testStorage() {
  console.log('🔍 Testing Supabase Storage...');
  
  try {
    // 1. List all buckets
    console.log('\n📦 Listing all buckets...');
    const { data: buckets, error: bucketsError } = await supabase.storage.listBuckets();
    
    if (bucketsError) {
      console.error('❌ Error listing buckets:', bucketsError);
      return;
    }
    
    console.log('✅ Buckets found:', buckets?.map(b => ({
      name: b.name,
      public: b.public,
      created_at: b.created_at
    })) || []);
    
    // 2. Check if backups bucket exists
    const backupsBucket = buckets?.find(b => b.name === 'backups');
    if (!backupsBucket) {
      console.log('\n🔧 Creating backups bucket...');
      const { data: newBucket, error: createError } = await supabase.storage.createBucket('backups', {
        public: false,
        allowedMimeTypes: ['application/sql', 'application/gzip', 'application/octet-stream'],
        fileSizeLimit: 1024 * 1024 * 1024 // 1GB
      });
      
      if (createError) {
        console.error('❌ Error creating bucket:', createError);
        return;
      }
      
      console.log('✅ Bucket created:', newBucket);
    } else {
      console.log('✅ Backups bucket already exists');
    }
    
    // 3. List files in backups bucket
    console.log('\n📁 Listing files in backups bucket...');
    const { data: files, error: listError } = await supabase.storage
      .from('backups')
      .list('', {
        limit: 100,
        offset: 0,
        sortBy: { column: 'name', order: 'asc' }
      });
    
    if (listError) {
      console.error('❌ Error listing files:', listError);
      return;
    }
    
    console.log(`✅ Files in backups bucket (${files?.length || 0} files):`);
    files?.forEach(file => {
      console.log(`  - ${file.name} (${file.metadata?.size || 'unknown'} bytes, updated: ${file.updated_at})`);
    });
    
    // 4. Test upload a small file
    console.log('\n📤 Testing file upload...');
    const testContent = Buffer.from('This is a test backup file content');
    const testFilename = `test-backup-${Date.now()}.sql`;
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('backups')
      .upload(testFilename, testContent, {
        contentType: 'application/octet-stream',
        upsert: false
      });
    
    if (uploadError) {
      console.error('❌ Error uploading test file:', uploadError);
      return;
    }
    
    console.log('✅ Test file uploaded successfully:', uploadData);
    
    // 5. Verify the file exists
    console.log('\n🔍 Verifying uploaded file...');
    const { data: verifyFiles, error: verifyError } = await supabase.storage
      .from('backups')
      .list();
    
    if (verifyError) {
      console.error('❌ Error verifying files:', verifyError);
      return;
    }
    
    const uploadedFile = verifyFiles?.find(f => f.name === testFilename);
    if (uploadedFile) {
      console.log('✅ Test file found in bucket:', uploadedFile);
    } else {
      console.log('❌ Test file not found in bucket');
    }
    
    // 6. Clean up test file
    console.log('\n🗑️ Cleaning up test file...');
    const { error: deleteError } = await supabase.storage
      .from('backups')
      .remove([testFilename]);
    
    if (deleteError) {
      console.error('❌ Error deleting test file:', deleteError);
    } else {
      console.log('✅ Test file deleted successfully');
    }
    
    console.log('\n✅ Storage test completed successfully!');
    
  } catch (error) {
    console.error('💥 Unexpected error:', error);
  }
}

// Run the test
testStorage().then(() => {
  console.log('\n🏁 Test finished');
  process.exit(0);
}).catch(error => {
  console.error('💥 Test failed:', error);
  process.exit(1);
});
