/**
 * ==================================================================================
 * RESTORE API ROUTES
 * ==================================================================================
 * RESTful API endpoints for database restore operations
 * POST /api/admin/restore - Perform database restore
 * POST /api/admin/restore/validate - Validate restore operation
 */

import { RestoreService } from '@/lib/backup/restore-service';
import { RestoreOptions } from '@/lib/backup/types';
import { createAdminClient } from '@/lib/supabase/admin';
import { NextRequest, NextResponse } from 'next/server';

/**
 * Validate restore operation (dry run)
 */
export async function POST(request: NextRequest) {
  try {
    console.log(`🔍 Starting restore validation...`);
    
    const body = await request.json();
    console.log(`📝 Validation request body:`, body);
    
    const { 
      backupId,
      targetTables,
      restoreAuth = false,
      pointInTime,
      overwriteExisting = true
    } = body;

    if (!backupId) {
      console.error(`❌ Missing backup ID in validation request`);
      return NextResponse.json(
        { success: false, error: 'Backup ID is required' },
        { status: 400 }
      );
    }

    console.log(`🔧 Creating restore options for validation...`);
    const options: RestoreOptions = {
      backupId,
      targetTables,
      restoreAuth,
      pointInTime,
      overwriteExisting,
      dryRun: true, // Always dry run for validation
      createRestorePoint: false // No restore point needed for validation
    };

    console.log(`📡 Creating admin client and restore service...`);
    const adminClient = createAdminClient();
    const restoreService = new RestoreService(adminClient);

    // Validate restore
    console.log(`🔍 Validating restore with options:`, options);
    const validation = await restoreService.validateRestore(options);
    console.log(`✅ Validation completed:`, validation);
    
    if (!validation.valid) {
      console.error(`❌ Validation failed:`, validation.error);
      return NextResponse.json({
        success: false,
        error: validation.error,
        valid: false
      });
    }

    // Perform dry run
    console.log(`🧪 Performing dry run...`);
    const result = await restoreService.performRestore(options);
    console.log(`✅ Dry run completed:`, result);

    return NextResponse.json({
      success: true,
      valid: true,
      warnings: validation.warnings,
      dryRunResult: result,
      message: 'Validation completed successfully'
    });

  } catch (error) {
    console.error('💥 Restore validation failed:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Restore validation failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

/**
 * Perform database restore
 */
export async function PUT(request: NextRequest) {
  try {
    console.log(`🔄 Starting restore operation...`);
    
    const body = await request.json();
    console.log(`📝 Restore request body:`, body);
    
    const { 
      backupId,
      targetTables,
      restoreAuth = false,
      pointInTime,
      overwriteExisting = true,
      createRestorePoint = true,
      confirmDangerous = false,
      userId = 'system' // Default user ID if not provided
    } = body;

    if (!backupId) {
      console.error(`❌ Missing backup ID in restore request`);
      return NextResponse.json(
        { success: false, error: 'Backup ID is required' },
        { status: 400 }
      );
    }

    // Safety check for full restore
    if (!targetTables && !confirmDangerous) {
      console.error(`❌ Full database restore requires explicit confirmation`);
      return NextResponse.json(
        { 
          success: false, 
          error: 'Full database restore requires explicit confirmation',
          requiresConfirmation: true
        },
        { status: 400 }
      );
    }

    console.log(`🔧 Creating restore options...`);
    const options: RestoreOptions = {
      backupId,
      targetTables,
      restoreAuth,
      pointInTime,
      overwriteExisting,
      dryRun: false,
      createRestorePoint,
      userId // Pass userId to restore options
    };

    console.log(`📡 Creating admin client and restore service...`);
    const adminClient = createAdminClient();
    const restoreService = new RestoreService(adminClient);

    // First validate the restore
    console.log(`🔍 Pre-restore validation with options:`, options);
    const validation = await restoreService.validateRestore(options);
    console.log(`✅ Pre-restore validation result:`, validation);
    
    if (!validation.valid) {
      console.error(`❌ Pre-restore validation failed:`, validation.error);
      return NextResponse.json({
        success: false,
        error: validation.error
      }, { status: 400 });
    }

    // Perform actual restore
    console.log(`🚀 Performing actual restore...`);
    const result = await restoreService.performRestore(options);
    console.log(`✅ Restore operation completed:`, result);

    if (result.success) {
      console.log(`🎉 Restore successful!`);
      return NextResponse.json({
        success: true,
        result,
        message: 'Database restored successfully'
      });
    } else {
      console.error(`❌ Restore failed:`, result);
      return NextResponse.json({
        success: false,
        error: result.message,
        result
      }, { status: 500 });
    }

  } catch (error) {
    console.error('💥 Restore operation failed:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Restore operation failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

/**
 * Get restore history and status
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = parseInt(searchParams.get('offset') || '0');

    const adminClient = createAdminClient();

    // Get restore history from audit logs or dedicated table
    const { data: restoreHistory, error } = await adminClient
      .from('pos_mini_modular3_restore_history')
      .select(`
        *,
        backup:backup_id(filename, type, created_at),
        user:restored_by(full_name)
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.warn('Restore history table not found, returning empty result');
      return NextResponse.json({
        success: true,
        restoreHistory: [],
        pagination: { total: 0, limit, offset, hasMore: false }
      });
    }

    return NextResponse.json({
      success: true,
      restoreHistory: restoreHistory || [],
      pagination: {
        total: restoreHistory?.length || 0,
        limit,
        offset,
        hasMore: (restoreHistory?.length || 0) === limit
      }
    });

  } catch (error) {
    console.error('❌ Failed to get restore history:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to get restore history',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}
