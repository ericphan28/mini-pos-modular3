'use client';

import { useAuth } from '@/lib/auth/auth-context';
import { useMemo, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';

interface PermissionChecks {
  readonly hasPermission: (permission: string) => boolean;
  readonly canAccess: {
    // Product permissions
    readonly createProduct: boolean;
    readonly editProduct: boolean;
    readonly deleteProduct: boolean;
    readonly viewCostPrice: boolean;
    readonly manageCategories: boolean;
    readonly manageInventory: boolean;
    
    // User permissions
    readonly createUser: boolean;
    readonly editUser: boolean;
    readonly deleteUser: boolean;
    readonly managePermissions: boolean;
    
    // Business permissions
    readonly viewReports: boolean;
    readonly manageSettings: boolean;
    readonly updateBusiness: boolean;
    
    // Financial permissions
    readonly viewRevenue: boolean;
    readonly viewCost: boolean;
    readonly managePricing: boolean;
    
    // System permissions
    readonly viewLogs: boolean;
    readonly manageBackup: boolean;
    readonly superAdmin: boolean;
  };
  readonly userRole: string;
  readonly isOwner: boolean;
  readonly isManager: boolean;
  readonly isSuperAdmin: boolean;
  readonly businessTier: string;
  readonly refreshPermissions: () => Promise<void>;
  readonly emergencyRollback: (userId: string, reason?: string) => Promise<boolean>;
}

export function usePermissions(): PermissionChecks {
  const { sessionData, refreshSession } = useAuth();
  
  const permissions = useMemo(() => {
    if (!sessionData?.permissions?.permissions) return [];
    
    // Handle JSONB array from database
    const perms = sessionData.permissions.permissions;
    return Array.isArray(perms) ? perms : [];
  }, [sessionData?.permissions?.permissions]);
  
  const hasPermission = useCallback((permission: string): boolean => {
    if (!permissions.length) return false;
    
    // Check exact permission
    if (permissions.includes(permission)) return true;
    
    // Check wildcard permissions (e.g., "product.*" covers "product.create")
    const [module] = permission.split('.');
    if (permissions.includes(`${module}.*`)) return true;
    
    // Check super admin wildcard
    if (permissions.includes('*')) return true;
    
    return false;
  }, [permissions]);
  
  const canAccess = useMemo(() => ({
    // Product permissions
    createProduct: hasPermission('product.create'),
    editProduct: hasPermission('product.update'),
    deleteProduct: hasPermission('product.delete'),
    viewCostPrice: hasPermission('product.view_cost_price'),
    manageCategories: hasPermission('product.manage_categories'),
    manageInventory: hasPermission('product.manage_inventory'),
    
    // User permissions
    createUser: hasPermission('user.create'),
    editUser: hasPermission('user.update'),
    deleteUser: hasPermission('user.delete'),
    managePermissions: hasPermission('user.manage_permissions'),
    
    // Business permissions
    viewReports: hasPermission('business.view_reports'),
    manageSettings: hasPermission('business.manage_settings'),
    updateBusiness: hasPermission('business.update'),
    
    // Financial permissions
    viewRevenue: hasPermission('financial.view_revenue'),
    viewCost: hasPermission('financial.view_cost'),
    managePricing: hasPermission('financial.manage_pricing'),
    
    // System permissions
    viewLogs: hasPermission('system.view_logs'),
    manageBackup: hasPermission('system.manage_backup'),
    superAdmin: hasPermission('system.super_admin')
  }), [hasPermission]);
  
  const refreshPermissions = useCallback(async (): Promise<void> => {
    try {
      await refreshSession();
    } catch (error: unknown) {
      console.error('Failed to refresh permissions:', error);
    }
  }, [refreshSession]);
  
  const emergencyRollback = useCallback(async (
    userId: string, 
    reason = 'Emergency permission rollback'
  ): Promise<boolean> => {
    try {
      const supabase = createClient();
      
      const { data, error } = await supabase.rpc(
        'pos_mini_modular3_emergency_permission_rollback',
        { 
          p_user_id: userId,
          p_reason: reason
        }
      );
      
      if (error) {
        console.error('Rollback failed:', error);
        return false;
      }
      
      if (data?.success) {
        // Refresh permissions if rollback affects current user
        if (userId === sessionData?.user.id) {
          await refreshPermissions();
        }
        return true;
      }
      
      return false;
    } catch (error: unknown) {
      console.error('Emergency rollback error:', error);
      return false;
    }
  }, [sessionData?.user.id, refreshPermissions]);
  
  return {
    hasPermission,
    canAccess,
    userRole: sessionData?.permissions?.role || 'viewer',
    isOwner: sessionData?.permissions?.role === 'household_owner',
    isManager: sessionData?.permissions?.role === 'manager',
    isSuperAdmin: hasPermission('system.super_admin'),
    businessTier: sessionData?.business?.subscriptionTier || 'basic',
    refreshPermissions,
    emergencyRollback
  };
}

// Server-side permission validation hook
export function useServerPermissions() {
  const supabase = createClient();
  
  const validatePermission = useCallback(async (
    permission: string,
    userId?: string
  ): Promise<boolean> => {
    try {
      const { data, error } = await supabase.rpc(
        'pos_mini_modular3_check_permission_runtime',
        { 
          p_user_id: userId || (await supabase.auth.getUser()).data.user?.id,
          p_permission: permission
        }
      );
      
      if (error) {
        console.error('Server permission check failed:', error);
        return false;
      }
      
      return Boolean(data);
    } catch (error: unknown) {
      console.error('Permission validation error:', error);
      return false;
    }
  }, [supabase]);
  
  return { validatePermission };
}
