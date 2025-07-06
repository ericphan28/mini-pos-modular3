/**
 * ==================================================================================
 * RESTORE PAGE - SUPER ADMIN
 * ==================================================================================
 * Professional database restore interface
 */

import RestoreManager from '@/components/backup/restore-manager';

export default function RestorePage() {
  return (
    <div className="container mx-auto p-6">
      <RestoreManager />
    </div>
  );
}
