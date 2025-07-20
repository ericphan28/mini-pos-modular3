// ==================================================================================
// CENTRALIZED PERMISSION SYSTEM - TYPE DEFINITIONS
// ==================================================================================

'use client';

// ==================================================================================
// CORE PERMISSION TYPES
// ==================================================================================

export interface PermissionConfig {
  readonly features: Record<string, FeaturePermissionConfig>;
  readonly routes: Record<string, RoutePermissionConfig>;
  readonly businessRules: BusinessRule;
  readonly version: string;
  readonly lastUpdated: string;
}

export interface FeaturePermissionConfig {
  readonly name: string;
  readonly description: string;
  readonly requiredPermissions: readonly string[];
  readonly optionalPermissions: readonly string[];
  readonly subscriptionTiers: readonly ('free' | 'premium' | 'enterprise')[];
  readonly category: string;
}

export interface RoutePermissionConfig {
  readonly permissions: readonly string[];
  readonly requireAllPermissions: boolean;
  readonly allowedRoles: readonly UserRole[];
  readonly description: string;
}

export interface BusinessRule {
  readonly subscriptionTier?: Record<string, SubscriptionTier>;
  readonly businessStatus?: Record<string, BusinessStatus>;
  readonly userRole?: Record<string, readonly UserRole[]>;
}

// ==================================================================================
// USER AND SESSION TYPES
// ==================================================================================

export type UserRole = 
  | 'household_owner'
  | 'manager' 
  | 'staff'
  | 'accountant'
  | 'seller'
  | 'viewer'
  | 'super_admin';

export type SubscriptionTier = 'free' | 'premium' | 'enterprise';

export type BusinessStatus = 'active' | 'inactive' | 'suspended';

export interface UserPermissions {
  readonly features: Record<string, readonly string[]>;
  readonly allPermissions: readonly string[];
  readonly allowedRoutes: readonly string[];
  readonly restrictedFeatures: readonly string[];
}

export interface SessionData {
  readonly user: {
    readonly id: string;
    readonly email: string;
  };
  readonly business: {
    readonly id: string;
    readonly name: string;
    readonly user_role: UserRole;
    readonly subscription_tier: SubscriptionTier;
    readonly status: BusinessStatus;
    readonly role_permissions?: Record<string, string[]>;
  };
}

// ==================================================================================
// PERMISSION CHECK RESULTS
// ==================================================================================

export interface PermissionCheckResult {
  readonly allowed: boolean;
  readonly reason?: string;
  readonly error?: PermissionError;
  readonly metadata?: Record<string, unknown>;
}

export interface PermissionError {
  readonly type: 'INVALID_INPUT' | 'PERMISSION_DENIED' | 'SUBSCRIPTION_REQUIRED' | 
                'BUSINESS_STATUS_INVALID' | 'ROLE_INSUFFICIENT' | 'CONFIG_MISSING' | 'SYSTEM_ERROR';
  readonly message: string;
}

// ==================================================================================
// CONTEXT AND CACHING
// ==================================================================================

export interface PermissionContext {
  readonly resourceId?: string;
  readonly requireOwnership?: boolean;
  readonly timeRestriction?: {
    readonly startHour: number;
    readonly endHour: number;
  };
  readonly additionalChecks?: Record<string, unknown>;
}

export interface PermissionCacheEntry {
  readonly data: PermissionCheckResult;
  readonly timestamp: number;
  readonly ttl: number;
}

// ==================================================================================
// COMPONENT PROPS
// ==================================================================================

export interface PermissionGuardProps {
  readonly children: React.ReactNode;
  readonly requiredPermissions?: readonly string[];
  readonly requiredRole?: UserRole;
  readonly fallbackComponent?: React.ReactNode;
  readonly context?: PermissionContext;
}

export interface PermissionWrapperProps {
  readonly children: React.ReactNode;
  readonly permission: string;
  readonly fallback?: React.ReactNode;
  readonly context?: PermissionContext;
  readonly showFallback?: boolean;
}
