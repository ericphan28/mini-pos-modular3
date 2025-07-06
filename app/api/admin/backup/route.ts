/**
 * ==================================================================================
 * BACKUP API ROUTES
 * ==================================================================================
 * RESTful API endpoints for backup operations
 * POST /api/admin/backup - Create new backup
 * GET /api/admin/backup - List all backups
 */

import { BackupService } from '@/lib/backup/backup-service';
import { BackupConfig } from '@/lib/backup/types';
import { createAdminClient } from '@/lib/supabase/admin';
import { NextRequest, NextResponse } from 'next/server';

/**
 * Create a new backup
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { 
      type = 'full',
      compression = 'gzip',
      encryption = false,
      retention = 30,
      tables,
      excludeTables,
      lastBackupTime
    } = body;

    // Validate input
    if (!['full', 'incremental', 'schema', 'data'].includes(type)) {
      return NextResponse.json(
        { success: false, error: 'Invalid backup type' },
        { status: 400 }
      );
    }

    const config: BackupConfig = {
      type,
      compression,
      encryption,
      retention,
      tables,
      excludeTables,
      lastBackupTime
    };

    const adminClient = createAdminClient();
    const backupService = new BackupService(adminClient);

    // Get user ID from session (in real implementation)
    const userId = 'system'; // Replace with actual user ID from auth

    // Create backup
    const result = await backupService.createBackup(config, userId);

    return NextResponse.json({
      success: true,
      backup: result,
      downloadUrl: `/api/admin/backup/${result.id}/download`
    });

  } catch (error) {
    console.error('❌ Backup creation failed:', error);
    
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const statusCode = errorMessage.includes('Invalid') ? 400 : 500;
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Backup creation failed',
        details: errorMessage
      },
      { status: statusCode }
    );
  }
}

/**
 * List all backups with optional filtering
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type');
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');
    const status = searchParams.get('status') || 'completed';

    const adminClient = createAdminClient();
    
    let query = adminClient
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Add type filter if specified
    if (type && ['full', 'incremental', 'schema', 'data'].includes(type)) {
      query = query.eq('type', type);
    }

    const { data: backups, error, count } = await query;

    if (error) {
      throw error;
    }

    // Calculate storage statistics
    const totalSize = backups?.reduce((sum, backup) => sum + backup.size, 0) || 0;
    const oldestBackup = backups?.[backups.length - 1]?.created_at;
    const newestBackup = backups?.[0]?.created_at;

    return NextResponse.json({
      success: true,
      backups: backups || [],
      pagination: {
        total: count || 0,
        limit,
        offset,
        hasMore: (count || 0) > offset + limit
      },
      statistics: {
        totalSize,
        totalBackups: count || 0,
        oldestBackup,
        newestBackup
      }
    });

  } catch (error) {
    console.error('❌ Failed to list backups:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to list backups',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

/**
 * Delete a backup (soft delete with retention policy)
 */
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const backupId = searchParams.get('id');

    if (!backupId) {
      return NextResponse.json(
        { success: false, error: 'Backup ID is required' },
        { status: 400 }
      );
    }

    const adminClient = createAdminClient();

    // Check if backup exists
    const { data: backup, error: fetchError } = await adminClient
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('id', backupId)
      .single();

    if (fetchError || !backup) {
      return NextResponse.json(
        { success: false, error: 'Backup not found' },
        { status: 404 }
      );
    }

    // Soft delete - mark as expired
    const { error: updateError } = await adminClient
      .from('pos_mini_modular3_backup_metadata')
      .update({ 
        status: 'expired',
        retention_until: new Date().toISOString()
      })
      .eq('id', backupId);

    if (updateError) {
      throw updateError;
    }

    // TODO: Schedule physical file deletion
    // This should be handled by a background job

    return NextResponse.json({
      success: true,
      message: 'Backup marked for deletion'
    });

  } catch (error) {
    console.error('❌ Failed to delete backup:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to delete backup',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}
