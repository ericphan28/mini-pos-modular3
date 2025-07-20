// ==================================================================================
// PERMISSION SYSTEM ADAPTER
// ==================================================================================
// Adapts existing auth types to permission system types

import type { SessionData as AuthSessionData } from '@/lib/auth/types';
import type { SessionData as PermissionSessionData, UserRole } from './permission-types';

/**
 * Convert auth session data to permission session data
 */
export function adaptSessionData(authSession: AuthSessionData): PermissionSessionData {
  return {
    user: {
      id: authSession.user.id,
      email: authSession.user.email
    },
    business: {
      id: authSession.business.id,
      name: authSession.business.name,
      user_role: (authSession.permissions.role as UserRole) || 'staff',
      subscription_tier: authSession.business.subscriptionTier === 'basic' ? 'free' : 
                        authSession.business.subscriptionTier === 'premium' ? 'premium' : 
                        authSession.business.subscriptionTier === 'enterprise' ? 'enterprise' : 'free',
      status: authSession.business.status,
      role_permissions: convertPermissionsToRoleFormat(authSession.permissions.permissions)
    }
  };
}

/**
 * Convert flat permissions array to role-based format
 * Handle both formats: 'feature.action' (from database) and 'action_feature' (legacy)
 */
function convertPermissionsToRoleFormat(permissions: readonly string[]): Record<string, string[]> {
  const rolePermissions: Record<string, string[]> = {};
  
  console.log('🔧 [SESSION ADAPTER] Converting permissions:', permissions);
  
  permissions.forEach(permission => {
    let featureName: string;
    
    // Handle 'feature.action' format (from database)
    if (permission.includes('.')) {
      const [feature] = permission.split('.');
      featureName = feature;
    } 
    // Handle 'action_feature' format (legacy)
    else {
      // Extract feature from permission name using mapping
      const featureMapping = getFeatureFromLegacyPermission(permission);
      if (featureMapping) {
        featureName = featureMapping.feature;
      } else {
        console.warn('🔧 [SESSION ADAPTER] Unknown permission format:', permission);
        return;
      }
    }
    
    // Initialize feature array if not exists
    if (!rolePermissions[featureName]) {
      rolePermissions[featureName] = [];
    }
    
    // Add permission to feature group (use original permission name)
    rolePermissions[featureName].push(permission);
  });
  
  console.log('🔧 [SESSION ADAPTER] Converted role permissions:', rolePermissions);
  return rolePermissions;
}

/**
 * Map legacy permission names to feature and action
 */
function getFeatureFromLegacyPermission(permission: string): { feature: string; action: string } | null {
  // Define feature mappings based on permission patterns
  const legacyMappings: Record<string, { feature: string; action: string }> = {
    'view_staff': { feature: 'staff_management', action: 'view' },
    'create_staff': { feature: 'staff_management', action: 'create' },
    'edit_staff': { feature: 'staff_management', action: 'edit' },
    'delete_staff': { feature: 'staff_management', action: 'delete' },
    'view_staff_reports': { feature: 'staff_management', action: 'view_reports' },
    'manage_staff_roles': { feature: 'staff_management', action: 'manage_roles' },
    
    'view_financial_summary': { feature: 'financial_tracking', action: 'view_summary' },
    'view_revenue_reports': { feature: 'financial_tracking', action: 'view_reports' },
    'view_detailed_financial': { feature: 'financial_tracking', action: 'view_detailed' },
    'export_financial_data': { feature: 'financial_tracking', action: 'export' },
    
    'view_products': { feature: 'product_management', action: 'view' },
    'create_products': { feature: 'product_management', action: 'create' },
    'edit_products': { feature: 'product_management', action: 'edit' },
    'delete_products': { feature: 'product_management', action: 'delete' },
    'bulk_product_operations': { feature: 'product_management', action: 'bulk_operations' },
    'view_product_analytics': { feature: 'product_management', action: 'view_analytics' },
    
    'access_pos': { feature: 'pos_interface', action: 'access' },
    'process_transactions': { feature: 'pos_interface', action: 'process' },
    'apply_discounts': { feature: 'pos_interface', action: 'apply_discounts' },
    'handle_returns': { feature: 'pos_interface', action: 'handle_returns' },
    'view_transaction_history': { feature: 'pos_interface', action: 'view_history' },
    
    'view_reports': { feature: 'basic_reports', action: 'view' },
    'generate_reports': { feature: 'basic_reports', action: 'generate' },
    'export_reports': { feature: 'basic_reports', action: 'export' },
    'schedule_reports': { feature: 'basic_reports', action: 'schedule' },
    
    'view_inventory': { feature: 'inventory_management', action: 'view' },
    'update_inventory': { feature: 'inventory_management', action: 'update' },
    'track_inventory': { feature: 'inventory_management', action: 'track' },
    'inventory_alerts': { feature: 'inventory_management', action: 'alerts' },
    
    'view_categories': { feature: 'category_management', action: 'view' },
    'create_categories': { feature: 'category_management', action: 'create' },
    'edit_categories': { feature: 'category_management', action: 'edit' },
    'delete_categories': { feature: 'category_management', action: 'delete' }
  };
  
  return legacyMappings[permission] || null;
}
