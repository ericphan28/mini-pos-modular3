/**
 * ==================================================================================
 * BACKUP DOWNLOAD API ROUTE
 * ==================================================================================
 * Secure download endpoint for backup files
 * GET /api/admin/backup/[id]/download - Download backup file
 */

import { createAdminClient } from '@/lib/supabase/admin';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: backupId } = await params;

    if (!backupId) {
      return NextResponse.json(
        { success: false, error: 'Backup ID is required' },
        { status: 400 }
      );
    }

    const adminClient = createAdminClient();

    // Get backup metadata
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

    // Check if backup is still valid (not expired)
    if (backup.status === 'expired' || new Date(backup.retention_until) < new Date()) {
      return NextResponse.json(
        { success: false, error: 'Backup has expired' },
        { status: 410 }
      );
    }

    // Get download URL from storage
    const { data: urlData, error: urlError } = await adminClient.storage
      .from('backups')
      .createSignedUrl(backup.storage_path, 3600); // 1 hour expiry

    if (urlError || !urlData) {
      return NextResponse.json(
        { success: false, error: 'Failed to generate download URL' },
        { status: 500 }
      );
    }

    // Log download activity
    await adminClient
      .from('pos_mini_modular3_backup_downloads')
      .insert({
        backup_id: backupId,
        downloaded_at: new Date().toISOString(),
        downloaded_by: 'system', // Replace with actual user ID
        ip_address: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
      });

    // Return download URL or redirect
    return NextResponse.json({
      success: true,
      downloadUrl: urlData.signedUrl,
      filename: backup.filename,
      size: backup.size,
      expiresAt: new Date(Date.now() + 3600 * 1000).toISOString()
    });

  } catch (error) {
    console.error('❌ Failed to generate download URL:', error);
    
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to generate download URL',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}
