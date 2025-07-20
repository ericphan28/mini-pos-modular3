// ==================================================================================
// PERMISSION HOOK - CONVENIENT API FOR COMPONENTS
// ==================================================================================
// Easy-to-use React hook for permission checking in components

'use client';

import { useMemo } from 'react';
import { useAuth } from '@/lib/auth/auth-context';

// ==================================================================================
// PERMISSION HOOK INTERFACES
// ==================================================================================

interface UsePermissionReturn {
  // Permission checking methods
  readonly hasPermission: (permission: string) => boolean;
  readonly hasFeatureAccess: (feature: string) => boolean;
  readonly canAccessRoute: (route: string) => boolean;
  
  // Permission data
  readonly userPermissions: Record<string, readonly string[]>;
  readonly allowedRoutes: readonly string[];
  readonly restrictedFeatures: readonly string[];
  readonly subscriptionLimits: Record<string, boolean>;
  
  // State information
  readonly isLoading: boolean;
  readonly permissionLoading: boolean;
  readonly isAuthenticated: boolean;
  
  // Utility methods
  readonly refreshPermissions: () => Promise<void>;
  readonly getPermissionCount: () => number;
  readonly getFeatureCount: () => number;
}

interface UsePermissionChecksReturn {
  readonly hasAnyPermission: (permissions: readonly string[]) => boolean;
  readonly hasAllPermissions: (permissions: readonly string[]) => boolean;
  readonly getMissingPermissions: (permissions: readonly string[]) => readonly string[];
  readonly getAvailableFeatures: () => readonly string[];
  readonly isFeatureRestricted: (feature: string) => boolean;
}

// ==================================================================================
// MAIN PERMISSION HOOK
// ==================================================================================

/**
 * Main permission hook providing comprehensive permission checking
 */
export function usePermission(): UsePermissionReturn {
  const {
    isLoading,
    isAuthenticated,
    permissionLoading,
    permissionCache,
    hasPermission,
    hasFeatureAccess,
    canAccessRoute,
    getUserPermissions,
    getSubscriptionLimits,
    refreshPermissions
  } = useAuth();

  // Memoize permission data to avoid unnecessary re-renders
  const permissionData = useMemo(() => {
    if (!permissionCache) {
      return {
        userPermissions: {},
        allowedRoutes: [] as readonly string[],
        restrictedFeatures: [] as readonly string[],
        subscriptionLimits: {}
      };
    }

    return {
      userPermissions: getUserPermissions(),
      allowedRoutes: permissionCache.allowedRoutes,
      restrictedFeatures: permissionCache.restrictedFeatures,
      subscriptionLimits: getSubscriptionLimits()
    };
  }, [permissionCache, getUserPermissions, getSubscriptionLimits]);

  // Memoize utility functions
  const utilities = useMemo(() => ({
    getPermissionCount: (): number => {
      const permissions = Object.values(permissionData.userPermissions).flat();
      return permissions.length;
    },
    
    getFeatureCount: (): number => {
      return Object.keys(permissionData.userPermissions).length;
    }
  }), [permissionData.userPermissions]);

  return {
    // Permission checking methods
    hasPermission,
    hasFeatureAccess,
    canAccessRoute,
    
    // Permission data
    ...permissionData,
    
    // State information
    isLoading,
    permissionLoading,
    isAuthenticated,
    
    // Utility methods
    refreshPermissions,
    ...utilities
  };
}

// ==================================================================================
// ADVANCED PERMISSION CHECKS HOOK
// ==================================================================================

/**
 * Advanced permission checking hook for complex scenarios
 */
export function usePermissionChecks(): UsePermissionChecksReturn {
  const { userPermissions, hasPermission, restrictedFeatures } = usePermission();

  return useMemo(() => ({
    /**
     * Check if user has any of the specified permissions
     */
    hasAnyPermission: (permissions: readonly string[]): boolean => {
      return permissions.some(permission => hasPermission(permission));
    },

    /**
     * Check if user has all of the specified permissions
     */
    hasAllPermissions: (permissions: readonly string[]): boolean => {
      return permissions.every(permission => hasPermission(permission));
    },

    /**
     * Get list of permissions user doesn't have from specified list
     */
    getMissingPermissions: (permissions: readonly string[]): readonly string[] => {
      return permissions.filter(permission => !hasPermission(permission));
    },

    /**
     * Get list of features user has access to
     */
    getAvailableFeatures: (): readonly string[] => {
      return Object.keys(userPermissions).filter(feature => 
        !restrictedFeatures.includes(feature)
      );
    },

    /**
     * Check if specific feature is restricted for user
     */
    isFeatureRestricted: (feature: string): boolean => {
      return restrictedFeatures.includes(feature);
    }
  }), [userPermissions, hasPermission, restrictedFeatures]);
}

// ==================================================================================
// FEATURE-SPECIFIC HOOKS
// ==================================================================================

/**
 * Hook for staff management permissions
 */
export function useStaffPermissions() {
  const { hasPermission } = usePermission();
  
  return useMemo(() => ({
    canViewStaff: hasPermission('view_staff'),
    canCreateStaff: hasPermission('create_staff'),
    canEditStaff: hasPermission('edit_staff'),
    canDeleteStaff: hasPermission('delete_staff'),
    canViewReports: hasPermission('view_staff_reports'),
    canManageRoles: hasPermission('manage_staff_roles')
  }), [hasPermission]);
}

/**
 * Hook for financial permissions
 */
export function useFinancialPermissions() {
  const { hasPermission } = usePermission();
  
  return useMemo(() => ({
    canViewSummary: hasPermission('view_financial_summary'),
    canViewReports: hasPermission('view_revenue_reports'),
    canViewDetailed: hasPermission('view_detailed_financial'),
    canExportData: hasPermission('export_financial_data'),
    canManageExpenses: hasPermission('manage_expenses')
  }), [hasPermission]);
}

/**
 * Hook for product management permissions
 */
export function useProductPermissions() {
  const { hasPermission } = usePermission();
  
  return useMemo(() => ({
    canViewProducts: hasPermission('view_products'),
    canCreateProducts: hasPermission('create_products'),
    canEditProducts: hasPermission('edit_products'),
    canDeleteProducts: hasPermission('delete_products'),
    canBulkOperations: hasPermission('bulk_product_operations'),
    canViewAnalytics: hasPermission('product_analytics')
  }), [hasPermission]);
}

/**
 * Hook for POS permissions
 */
export function usePOSPermissions() {
  const { hasPermission } = usePermission();
  
  return useMemo(() => ({
    canAccessPOS: hasPermission('access_pos'),
    canProcessSales: hasPermission('process_sales'),
    canUseAdvancedFeatures: hasPermission('advanced_pos_features'),
    canCustomizePOS: hasPermission('pos_customization')
  }), [hasPermission]);
}

// ==================================================================================
// SUBSCRIPTION-AWARE HOOKS
// ==================================================================================

/**
 * Hook for subscription-aware permission checking
 */
export function useSubscriptionPermissions() {
  const { subscriptionLimits, hasPermission } = usePermission();
  
  return useMemo(() => ({
    /**
     * Check if permission is available in current subscription
     */
    isPermissionInSubscription: (permission: string): boolean => {
      return subscriptionLimits[permission] === true;
    },

    /**
     * Check if user has permission and it's included in subscription
     */
    hasSubscriptionPermission: (permission: string): boolean => {
      return hasPermission(permission) && subscriptionLimits[permission] === true;
    },

    /**
     * Get permissions that require subscription upgrade
     */
    getUpgradeRequiredPermissions: (permissions: readonly string[]): readonly string[] => {
      return permissions.filter(permission => 
        !hasPermission(permission) || subscriptionLimits[permission] === false
      );
    }
  }), [subscriptionLimits, hasPermission]);
}
