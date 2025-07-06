/**
 * ==================================================================================
 * BACKUP MANAGEMENT PAGE
 * ==================================================================================
 * Super Admin page for backup and restore operations
 */

import { BackupManager } from '@/components/backup/backup-manager';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Backup & Restore | Super Admin',
  description: 'Quản lý backup và khôi phục database hệ thống POS Mini Modular',
};

export default function BackupPage() {
  return (
    <div className="container mx-auto p-6">
      <BackupManager />
    </div>
  );
}
