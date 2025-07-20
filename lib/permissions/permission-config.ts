// ==================================================================================
// CENTRALIZED PERMISSION CONFIGURATION
// ==================================================================================
// Contains all permission definitions, route mappings, and business rules
// for the POS system. This is the single source of truth for permission logic.

import type {
  PermissionConfig,
  FeaturePermissionConfig,
  RoutePermissionConfig,
  BusinessRule
} from './permission-types';

// ==================================================================================
// FEATURE PERMISSION DEFINITIONS
// ==================================================================================

export const FEATURE_PERMISSIONS: Record<string, FeaturePermissionConfig> = {
  // Staff Management Feature
  staff_management: {
    name: 'Quản lý nhân viên',
    description: 'Quản lý thông tin và quyền hạn nhân viên',
    requiredPermissions: ['view_staff', 'create_staff', 'edit_staff', 'delete_staff'],
    optionalPermissions: ['view_staff_reports', 'manage_staff_roles'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'management'
  },

  // Financial Tracking Feature  
  financial_tracking: {
    name: 'Theo dõi tài chính',
    description: 'Quản lý doanh thu, chi phí và báo cáo tài chính',
    requiredPermissions: ['view_financial_summary', 'view_revenue_reports'],
    optionalPermissions: ['view_detailed_financial', 'export_financial_data', 'manage_expenses'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'finance'
  },

  // Product Management Feature
  product_management: {
    name: 'Quản lý sản phẩm',
    description: 'Quản lý thông tin sản phẩm và giá cả',
    requiredPermissions: ['view_products', 'create_products', 'edit_products', 'delete_products'],
    optionalPermissions: ['bulk_product_operations', 'product_analytics'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'inventory'
  },

  // Category Management Feature
  category_management: {
    name: 'Quản lý danh mục',
    description: 'Quản lý danh mục sản phẩm',
    requiredPermissions: ['view_categories', 'create_categories', 'edit_categories', 'delete_categories'],
    optionalPermissions: ['category_analytics'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'inventory'
  },

  // Inventory Management Feature
  inventory_management: {
    name: 'Quản lý kho',
    description: 'Theo dõi tồn kho và nhập xuất hàng',
    requiredPermissions: ['view_inventory', 'update_inventory'],
    optionalPermissions: ['inventory_alerts', 'bulk_inventory_operations', 'inventory_analytics'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'inventory'
  },

  // POS Interface Feature
  pos_interface: {
    name: 'Giao diện bán hàng',
    description: 'Giao diện thanh toán và xử lý đơn hàng',
    requiredPermissions: ['access_pos', 'process_sales'],
    optionalPermissions: ['advanced_pos_features', 'pos_customization'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'sales'
  },

  // Basic Reports Feature
  basic_reports: {
    name: 'Báo cáo cơ bản',
    description: 'Xem các báo cáo cơ bản về doanh số và kho',
    requiredPermissions: ['view_basic_reports'],
    optionalPermissions: ['export_reports', 'schedule_reports', 'advanced_analytics'],
    subscriptionTiers: ['free', 'premium', 'enterprise'],
    category: 'reporting'
  }
} as const;

// ==================================================================================
// ROUTE PERMISSION MAPPINGS
// ==================================================================================

export const ROUTE_PERMISSIONS: Record<string, RoutePermissionConfig> = {
  // Dashboard Routes
  '/dashboard': {
    permissions: ['access_pos'], // Basic dashboard access
    requireAllPermissions: false,
    allowedRoles: ['household_owner', 'staff', 'manager'],
    description: 'Trang chủ dashboard'
  },

  // Staff Management Routes
  '/dashboard/staff': {
    permissions: ['view_staff'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem danh sách nhân viên'
  },
  '/dashboard/staff/create': {
    permissions: ['create_staff'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Tạo nhân viên mới'
  },
  '/dashboard/staff/[id]': {
    permissions: ['view_staff', 'edit_staff'],
    requireAllPermissions: false,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem/chỉnh sửa thông tin nhân viên'
  },

  // Financial Routes
  '/dashboard/financial': {
    permissions: ['view_financial_summary'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem tổng quan tài chính'
  },
  '/dashboard/financial/reports': {
    permissions: ['view_revenue_reports'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem báo cáo doanh thu'
  },
  '/dashboard/financial/detailed': {
    permissions: ['view_detailed_financial'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner'],
    description: 'Xem báo cáo tài chính chi tiết'
  },

  // Product Management Routes
  '/dashboard/products': {
    permissions: ['view_products'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager', 'staff'],
    description: 'Xem danh sách sản phẩm'
  },
  '/dashboard/products/create': {
    permissions: ['create_products'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Tạo sản phẩm mới'
  },
  '/dashboard/products/[id]': {
    permissions: ['view_products', 'edit_products'],
    requireAllPermissions: false,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem/chỉnh sửa sản phẩm'
  },

  // Category Management Routes
  '/dashboard/categories': {
    permissions: ['view_categories'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem danh mục sản phẩm'
  },
  '/dashboard/categories/create': {
    permissions: ['create_categories'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Tạo danh mục mới'
  },

  // Inventory Routes
  '/dashboard/inventory': {
    permissions: ['view_inventory'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager', 'staff'],
    description: 'Xem tình trạng kho'
  },
  '/dashboard/inventory/manage': {
    permissions: ['update_inventory'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Cập nhật tồn kho'
  },

  // POS Routes
  '/dashboard/pos': {
    permissions: ['access_pos'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager', 'staff'],
    description: 'Giao diện bán hàng'
  },
  '/dashboard/pos/sales': {
    permissions: ['process_sales'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager', 'staff'],
    description: 'Xử lý bán hàng'
  },

  // Reports Routes
  '/dashboard/reports': {
    permissions: ['view_basic_reports'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Xem báo cáo cơ bản'
  },
  '/dashboard/reports/advanced': {
    permissions: ['advanced_analytics'],
    requireAllPermissions: true,
    allowedRoles: ['household_owner'],
    description: 'Báo cáo và phân tích nâng cao'
  },

  // Admin Routes
  '/dashboard/settings': {
    permissions: ['view_staff'], // Basic settings access
    requireAllPermissions: true,
    allowedRoles: ['household_owner', 'manager'],
    description: 'Cài đặt hệ thống'
  },
  '/super-admin': {
    permissions: [], // Special handling for super admin
    requireAllPermissions: false,
    allowedRoles: ['super_admin'],
    description: 'Trang quản trị hệ thống'
  }
} as const;

// ==================================================================================
// BUSINESS RULES CONFIGURATION
// ==================================================================================

export const BUSINESS_RULES: BusinessRule = {
  // Subscription tier requirements for specific permissions
  subscriptionTier: {
    // Premium features
    'view_detailed_financial': 'premium',
    'export_financial_data': 'premium',
    'bulk_product_operations': 'premium',
    'inventory_alerts': 'premium',
    'export_reports': 'premium',
    'advanced_pos_features': 'premium',
    
    // Enterprise features  
    'manage_staff_roles': 'enterprise',
    'bulk_inventory_operations': 'enterprise',
    'schedule_reports': 'enterprise',
    'advanced_analytics': 'enterprise',
    'pos_customization': 'enterprise'
  },

  // Business status requirements
  businessStatus: {
    // All features require active business
    'access_pos': 'active',
    'process_sales': 'active',
    'view_staff': 'active',
    'create_staff': 'active'
  },

  // User role restrictions
  userRole: {
    // Owner-only permissions
    'delete_staff': ['household_owner'],
    'view_detailed_financial': ['household_owner'],
    'manage_staff_roles': ['household_owner'],
    'advanced_analytics': ['household_owner'],
    
    // Manager+ permissions
    'create_staff': ['household_owner', 'manager'],
    'edit_staff': ['household_owner', 'manager'],
    'view_financial_summary': ['household_owner', 'manager'],
    'create_products': ['household_owner', 'manager'],
    'delete_products': ['household_owner', 'manager'],
    'create_categories': ['household_owner', 'manager'],
    'delete_categories': ['household_owner', 'manager'],
    
    // All roles (including staff)
    'view_products': ['household_owner', 'manager', 'staff'],
    'access_pos': ['household_owner', 'manager', 'staff'],
    'process_sales': ['household_owner', 'manager', 'staff'],
    'view_inventory': ['household_owner', 'manager', 'staff']
  }
} as const;

// ==================================================================================
// COMPLETE PERMISSION CONFIGURATION
// ==================================================================================

export const PERMISSION_CONFIG: PermissionConfig = {
  features: FEATURE_PERMISSIONS,
  routes: ROUTE_PERMISSIONS,
  businessRules: BUSINESS_RULES,
  version: '1.0.0',
  lastUpdated: new Date().toISOString()
} as const;

// ==================================================================================
// PERMISSION CONSTANTS AND UTILITIES
// ==================================================================================

// All available permissions (extracted from features)
export const ALL_PERMISSIONS = Object.values(FEATURE_PERMISSIONS)
  .flatMap(feature => [...feature.requiredPermissions, ...feature.optionalPermissions])
  .filter((permission, index, array) => array.indexOf(permission) === index)
  .sort();

// Permissions grouped by category
export const PERMISSIONS_BY_CATEGORY = Object.entries(FEATURE_PERMISSIONS)
  .reduce((acc, [, feature]) => {
    if (!acc[feature.category]) {
      acc[feature.category] = [];
    }
    acc[feature.category].push(...feature.requiredPermissions, ...feature.optionalPermissions);
    return acc;
  }, {} as Record<string, string[]>);

// Free tier permissions (default for new businesses)
export const FREE_TIER_PERMISSIONS = Object.entries(FEATURE_PERMISSIONS)
  .filter(([, feature]) => feature.subscriptionTiers.includes('free'))
  .flatMap(([, feature]) => feature.requiredPermissions);

// Premium tier additional permissions
export const PREMIUM_TIER_PERMISSIONS = Object.entries(BUSINESS_RULES.subscriptionTier || {})
  .filter(([, tier]) => tier === 'premium')
  .map(([permission]) => permission);

// Enterprise tier additional permissions  
export const ENTERPRISE_TIER_PERMISSIONS = Object.entries(BUSINESS_RULES.subscriptionTier || {})
  .filter(([, tier]) => tier === 'enterprise')
  .map(([permission]) => permission);

// ==================================================================================
// VALIDATION FUNCTIONS
// ==================================================================================

/**
 * Validate if a permission exists in the system
 */
export function isValidPermission(permission: string): boolean {
  return ALL_PERMISSIONS.includes(permission);
}

/**
 * Get permissions by subscription tier
 */
export function getPermissionsByTier(tier: 'free' | 'premium' | 'enterprise'): readonly string[] {
  switch (tier) {
    case 'free':
      return FREE_TIER_PERMISSIONS;
    case 'premium':
      return [...FREE_TIER_PERMISSIONS, ...PREMIUM_TIER_PERMISSIONS];
    case 'enterprise':
      return [...FREE_TIER_PERMISSIONS, ...PREMIUM_TIER_PERMISSIONS, ...ENTERPRISE_TIER_PERMISSIONS];
    default:
      return FREE_TIER_PERMISSIONS;
  }
}

/**
 * Check if permission requires specific subscription tier
 */
export function getRequiredTier(permission: string): 'free' | 'premium' | 'enterprise' {
  if (ENTERPRISE_TIER_PERMISSIONS.includes(permission)) return 'enterprise';
  if (PREMIUM_TIER_PERMISSIONS.includes(permission)) return 'premium';
  return 'free';
}

/**
 * Get feature by permission
 */
export function getFeatureByPermission(permission: string): string | null {
  for (const [featureKey, feature] of Object.entries(FEATURE_PERMISSIONS)) {
    if (feature.requiredPermissions.includes(permission) || 
        feature.optionalPermissions.includes(permission)) {
      return featureKey;
    }
  }
  return null;
}

/**
 * Get route configuration by pathname
 */
export function getRouteConfig(pathname: string): RoutePermissionConfig | null {
  // Exact match first
  if (ROUTE_PERMISSIONS[pathname]) {
    return ROUTE_PERMISSIONS[pathname];
  }

  // Dynamic route matching (e.g., /dashboard/staff/[id])
  for (const [routePattern, config] of Object.entries(ROUTE_PERMISSIONS)) {
    if (routePattern.includes('[') && matchDynamicRoute(pathname, routePattern)) {
      return config;
    }
  }

  return null;
}

/**
 * Match dynamic routes with parameters
 */
function matchDynamicRoute(pathname: string, pattern: string): boolean {
  const patternParts = pattern.split('/');
  const pathParts = pathname.split('/');

  if (patternParts.length !== pathParts.length) {
    return false;
  }

  return patternParts.every((part, index) => {
    if (part.startsWith('[') && part.endsWith(']')) {
      return true; // Dynamic segment
    }
    return part === pathParts[index];
  });
}
