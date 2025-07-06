/**
 * ==================================================================================
 * BACKUP ITEM API ROUTES - DELETE BACKUP
 * ==================================================================================
 * API endpoints for managing individual backup items
 */

import { createClient } from '@/lib/supabase/server';
import { createClient as createServiceClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

/**
 * DELETE /api/admin/backup/[id] - Delete a backup
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    // Create authenticated Supabase client for database operations
    const supabase = await createClient();
    
    // Create service client for storage operations (bypass RLS)
    const serviceClient = createServiceClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
    
    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ 
        success: false, 
        error: 'Unauthorized' 
      }, { status: 401 });
    }

    // Get backup metadata
    const { data: backup, error: fetchError } = await supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !backup) {
      return NextResponse.json({
        success: false,
        error: 'Backup not found'
      }, { status: 404 });
    }

    // Delete backup file from storage
    console.log(`🗑️ Attempting to delete file from storage: ${backup.storage_path}`);
    console.log(`📋 Full backup metadata:`, JSON.stringify(backup, null, 2));
    
    if (backup.storage_path) {
      // First, check what files exist in the bucket with more detailed info
      console.log('📁 Listing all files in backups bucket using service client...');
      const { data: listData, error: listError } = await serviceClient.storage
        .from('backups')
        .list('', { 
          limit: 100,
          offset: 0,
          sortBy: { column: 'name', order: 'asc' }
        });
      
      if (listError) {
        console.error('❌ Error listing files in bucket:', listError);
        console.error('List error details:', JSON.stringify(listError, null, 2));
      } else {
        console.log(`📁 Files in backup bucket (${listData?.length || 0} files):`, 
          listData?.map(f => ({ name: f.name, size: f.metadata?.size, updated: f.updated_at })) || []
        );
        
        // Check if our file exists - try multiple matching strategies
        const fileExists = listData?.some(f => 
          f.name === backup.filename || 
          f.name === backup.storage_path ||
          backup.storage_path.includes(f.name) ||
          f.name.includes(backup.id)
        );
        console.log(`🔍 Target file exists in bucket: ${fileExists}`);
      }
      
      // Try multiple deletion strategies
      const pathsToTry = [
        backup.storage_path,
        backup.filename,
        `${backup.filename}`,
        `/${backup.storage_path}`,
        `backups/${backup.storage_path}`
      ];
      
      let deleteSuccess = false;
      
      for (const pathToTry of pathsToTry) {
        console.log(`🗑️ Attempting to remove file with path: "${pathToTry}"`);
        const { data: deleteData, error: storageError } = await serviceClient.storage
          .from('backups')
          .remove([pathToTry]);
        
        if (!storageError) {
          console.log(`✅ Successfully deleted file with path "${pathToTry}". Response:`, deleteData);
          deleteSuccess = true;
          break;
        } else {
          console.log(`❌ Failed to delete with path "${pathToTry}":`, storageError.message);
        }
      }
      
      if (!deleteSuccess) {
        console.error('⚠️ Could not delete file from storage with any path strategy');
      }
    } else {
      console.log('⚠️ No storage_path found for backup, skipping file deletion');
    }

    // Delete backup metadata from database
    const { error: deleteError } = await supabase
      .from('pos_mini_modular3_backup_metadata')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('Error deleting backup metadata:', deleteError);
      return NextResponse.json({
        success: false,
        error: 'Failed to delete backup metadata'
      }, { status: 500 });
    }

    // Log the deletion
    console.log(`✅ Backup deleted successfully: ${id} (${backup.filename})`);

    return NextResponse.json({
      success: true,
      message: 'Backup deleted successfully'
    });

  } catch (error) {
    console.error('❌ Delete backup error:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    }, { status: 500 });
  }
}

/**
 * GET /api/admin/backup/[id] - Get backup details
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    // Create authenticated Supabase client
    const supabase = await createClient();
    
    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ 
        success: false, 
        error: 'Unauthorized' 
      }, { status: 401 });
    }

    // Get backup metadata
    const { data: backup, error: fetchError } = await supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !backup) {
      return NextResponse.json({
        success: false,
        error: 'Backup not found'
      }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      backup
    });

  } catch (error) {
    console.error('❌ Get backup error:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    }, { status: 500 });
  }
}
