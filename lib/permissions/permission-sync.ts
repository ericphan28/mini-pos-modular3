// ==================================================================================
// PERMISSION SYNCHRONIZATION SYSTEM
// ==================================================================================
// Handles background synchronization of permissions and cache management

import { createClient } from '@/lib/supabase/client';
import { permissionEngine } from './permission-engine';
import { adaptSessionData } from './session-adapter';
import type { SessionData as AuthSessionData } from '@/lib/auth/types';
import type { SessionData, UserPermissions } from './permission-types';

// ==================================================================================
// SYNC CONFIGURATION
// ==================================================================================

interface SyncConfiguration {
  readonly syncIntervalMs: number;
  readonly maxRetryAttempts: number;
  readonly retryDelayMs: number;
  readonly batchSize: number;
  readonly enableAutoSync: boolean;
}

const DEFAULT_SYNC_CONFIG: SyncConfiguration = {
  syncIntervalMs: 5 * 60 * 1000, // 5 minutes
  maxRetryAttempts: 3,
  retryDelayMs: 1000,
  batchSize: 50,
  enableAutoSync: true
};

// ==================================================================================
// PERMISSION SYNC MANAGER
// ==================================================================================

class PermissionSyncManager {
  private config: SyncConfiguration = DEFAULT_SYNC_CONFIG;
  private syncTimer: NodeJS.Timeout | null = null;
  private isSyncing = false;
  private retryCount = 0;
  private lastSyncTime: Date | null = null;
  private syncListeners: Set<(status: SyncStatus) => void> = new Set();

  // Sync status
  private status: SyncStatus = {
    isActive: false,
    lastSync: null,
    nextSync: null,
    errorCount: 0,
    successCount: 0
  };

  // ==================================================================================
  // INITIALIZATION
  // ==================================================================================

  configure(config: Partial<SyncConfiguration>): void {
    this.config = { ...this.config, ...config };
    
    if (this.config.enableAutoSync && !this.syncTimer) {
      this.startAutoSync();
    } else if (!this.config.enableAutoSync && this.syncTimer) {
      this.stopAutoSync();
    }
  }

  startAutoSync(): void {
    if (this.syncTimer) return;

    console.log('🔄 [PERMISSION SYNC] Starting auto-sync with interval:', this.config.syncIntervalMs);
    
    this.syncTimer = setInterval(() => {
      this.performSync().catch(console.error);
    }, this.config.syncIntervalMs);

    this.updateStatus({ isActive: true, nextSync: new Date(Date.now() + this.config.syncIntervalMs) });
  }

  stopAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
      console.log('🔄 [PERMISSION SYNC] Auto-sync stopped');
    }

    this.updateStatus({ isActive: false, nextSync: null });
  }

  // ==================================================================================
  // MANUAL SYNC OPERATIONS
  // ==================================================================================

  async syncUserPermissions(sessionData: AuthSessionData): Promise<UserPermissions> {
    try {
      console.log('🔄 [PERMISSION SYNC] Syncing permissions for user:', sessionData.user.id);

      // Convert session format
      const permissionSession = adaptSessionData(sessionData);

      // Fetch fresh data from database
      const freshData = await this.fetchUserDataFromDatabase(sessionData.user.id);
      
      if (freshData) {
        // Update session with fresh data
        const updatedSession = this.mergeSessionData(permissionSession, freshData);
        
        // Generate new permissions
        const permissions = permissionEngine.getUserPermissions(updatedSession);
        
        console.log('🔄 [PERMISSION SYNC] Permissions generated successfully');
        return permissions;
      }

      // Fallback to current session
      return permissionEngine.getUserPermissions(permissionSession);
    } catch (error) {
      console.error('🔄 [PERMISSION SYNC] Error syncing user permissions:', error);
      throw error;
    }
  }

  async performSync(): Promise<void> {
    if (this.isSyncing) {
      console.log('🔄 [PERMISSION SYNC] Sync already in progress, skipping');
      return;
    }

    this.isSyncing = true;
    this.updateStatus({ lastSync: new Date(), nextSync: new Date(Date.now() + this.config.syncIntervalMs) });

    try {
      await this.syncSystemConfiguration();
      await this.cleanupExpiredCaches();
      
      this.retryCount = 0;
      this.lastSyncTime = new Date();
      this.updateStatus({ successCount: this.status.successCount + 1 });
      
      console.log('🔄 [PERMISSION SYNC] Sync completed successfully');
    } catch (error) {
      this.retryCount++;
      this.updateStatus({ errorCount: this.status.errorCount + 1 });
      
      console.error('🔄 [PERMISSION SYNC] Sync failed:', error);
      
      if (this.retryCount < this.config.maxRetryAttempts) {
        console.log(`🔄 [PERMISSION SYNC] Retrying in ${this.config.retryDelayMs}ms (attempt ${this.retryCount}/${this.config.maxRetryAttempts})`);
        setTimeout(() => this.performSync(), this.config.retryDelayMs);
      } else {
        console.error('🔄 [PERMISSION SYNC] Max retry attempts reached');
        this.retryCount = 0;
      }
    } finally {
      this.isSyncing = false;
    }
  }

  // ==================================================================================
  // DATABASE OPERATIONS
  // ==================================================================================

  private async fetchUserDataFromDatabase(userId: string): Promise<DatabaseUserData | null> {
    try {
      const supabase = createClient();
      
      const { data, error } = await supabase.rpc('pos_mini_modular3_get_user_with_business_complete', {
        user_id: userId
      });

      if (error) {
        console.error('🔄 [PERMISSION SYNC] Database fetch error:', error);
        return null;
      }

      if (!data || data.length === 0) {
        console.warn('🔄 [PERMISSION SYNC] No data found for user:', userId);
        return null;
      }

      return data[0] as DatabaseUserData;
    } catch (error) {
      console.error('🔄 [PERMISSION SYNC] Database fetch exception:', error);
      return null;
    }
  }

  private async syncSystemConfiguration(): Promise<void> {
    // Check for permission system configuration updates
    // This could include new features, permission changes, etc.
    console.log('🔄 [PERMISSION SYNC] Checking system configuration...');
    
    // For now, just validate that the config is available
    if (!this.config) {
      throw new Error('Sync configuration not available');
    }
  }

  private async cleanupExpiredCaches(): Promise<void> {
    // Clean up any expired cache entries
    console.log('🔄 [PERMISSION SYNC] Cleaning up expired caches...');
    
    // This would typically interact with a cache store
    // For now, just log the operation
  }

  // ==================================================================================
  // DATA MERGING
  // ==================================================================================

  private mergeSessionData(currentSession: SessionData, freshData: DatabaseUserData): SessionData {
    // Merge fresh database data with current session
    return {
      ...currentSession,
      business: {
        ...currentSession.business,
        subscription_tier: this.mapSubscriptionTier(freshData.subscription_tier),
        status: this.mapBusinessStatus(freshData.business_status),
        role_permissions: this.mapPermissions(freshData.permissions || [])
      }
    };
  }

  private mapBusinessStatus(status: string): 'active' | 'inactive' | 'suspended' {
    switch (status?.toLowerCase()) {
      case 'active': return 'active';
      case 'inactive': return 'inactive';
      case 'suspended': return 'suspended';
      default: return 'active';
    }
  }

  private mapPermissions(permissions: string[]): Record<string, string[]> {
    // Convert array of permissions to feature-grouped permissions
    const grouped: Record<string, string[]> = {};
    
    permissions.forEach(permission => {
      // Extract feature from permission name (e.g., "staff_view" -> "staff")
      const parts = permission.split('_');
      if (parts.length >= 2) {
        const feature = parts[0];
        if (!grouped[feature]) {
          grouped[feature] = [];
        }
        grouped[feature].push(permission);
      }
    });
    
    return grouped;
  }

  private mapSubscriptionTier(tier: string): 'free' | 'premium' | 'enterprise' {
    switch (tier?.toLowerCase()) {
      case 'basic': return 'free';
      case 'premium': return 'premium';
      case 'enterprise': return 'enterprise';
      default: return 'free';
    }
  }

  // ==================================================================================
  // EVENT SYSTEM
  // ==================================================================================

  onSyncStatusChange(listener: (status: SyncStatus) => void): () => void {
    this.syncListeners.add(listener);
    
    // Return unsubscribe function
    return () => {
      this.syncListeners.delete(listener);
    };
  }

  private updateStatus(updates: Partial<SyncStatus>): void {
    this.status = { ...this.status, ...updates };
    
    // Notify listeners
    this.syncListeners.forEach(listener => {
      try {
        listener(this.status);
      } catch (error) {
        console.error('🔄 [PERMISSION SYNC] Error in sync listener:', error);
      }
    });
  }

  getStatus(): SyncStatus {
    return { ...this.status };
  }

  // ==================================================================================
  // CLEANUP
  // ==================================================================================

  destroy(): void {
    this.stopAutoSync();
    this.syncListeners.clear();
    console.log('🔄 [PERMISSION SYNC] Sync manager destroyed');
  }
}

// ==================================================================================
// TYPE DEFINITIONS
// ==================================================================================

interface SyncStatus {
  readonly isActive: boolean;
  readonly lastSync: Date | null;
  readonly nextSync: Date | null;
  readonly errorCount: number;
  readonly successCount: number;
}

interface DatabaseUserData {
  readonly user_id: string;
  readonly business_id: string;
  readonly business_name: string;
  readonly subscription_tier: string;
  readonly business_status: string;
  readonly user_role: string;
  readonly permissions: string[];
}

// ==================================================================================
// SINGLETON INSTANCE
// ==================================================================================

export const permissionSyncManager = new PermissionSyncManager();

// ==================================================================================
// REACT HOOKS
// ==================================================================================

import { useEffect, useState } from 'react';

/**
 * React hook for monitoring sync status
 */
export function useSyncStatus(): SyncStatus {
  const [status, setStatus] = useState<SyncStatus>(permissionSyncManager.getStatus());

  useEffect(() => {
    const unsubscribe = permissionSyncManager.onSyncStatusChange(setStatus);
    return unsubscribe;
  }, []);

  return status;
}

/**
 * React hook for manual sync operations
 */
export function usePermissionSync() {
  const [isSyncing, setIsSyncing] = useState(false);

  const syncUserPermissions = async (sessionData: AuthSessionData): Promise<UserPermissions> => {
    setIsSyncing(true);
    try {
      return await permissionSyncManager.syncUserPermissions(sessionData);
    } finally {
      setIsSyncing(false);
    }
  };

  const performManualSync = async (): Promise<void> => {
    setIsSyncing(true);
    try {
      await permissionSyncManager.performSync();
    } finally {
      setIsSyncing(false);
    }
  };

  return {
    isSyncing,
    syncUserPermissions,
    performManualSync,
    startAutoSync: () => permissionSyncManager.startAutoSync(),
    stopAutoSync: () => permissionSyncManager.stopAutoSync(),
    configure: (config: Partial<SyncConfiguration>) => permissionSyncManager.configure(config)
  };
}

// ==================================================================================
// INITIALIZATION
// ==================================================================================

// Auto-start sync manager in client environment
if (typeof window !== 'undefined') {
  // Start with default configuration
  permissionSyncManager.configure(DEFAULT_SYNC_CONFIG);
  
  // Clean up on page unload
  window.addEventListener('beforeunload', () => {
    permissionSyncManager.destroy();
  });
}
