// ==================================================================================
// CENTRALIZED PERMISSION ENGINE - CORE BUSINESS LOGIC
// ==================================================================================
// Implements the permission checking engine with caching, role validation,
// and business logic enforcement for the POS system

'use client';

import type {
  PermissionConfig,
  UserPermissions,
  PermissionCheckResult,
  PermissionError,
  SessionData,
  PermissionCacheEntry,
  PermissionContext
} from './permission-types';

// ==================================================================================
// PERMISSION CACHE MANAGEMENT
// ==================================================================================

class PermissionCache {
  private cache = new Map<string, PermissionCacheEntry>();
  private readonly TTL = 5 * 60 * 1000; // 5 minutes cache

  set(key: string, data: PermissionCheckResult): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: this.TTL
    });
  }

  get(key: string): PermissionCheckResult | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    if (Date.now() - entry.timestamp > entry.ttl) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  clear(): void {
    this.cache.clear();
  }

  private generateKey(userId: string, businessId: string, permission: string): string {
    return `${userId}:${businessId}:${permission}`;
  }

  getCachedPermission(userId: string, businessId: string, permission: string): PermissionCheckResult | null {
    return this.get(this.generateKey(userId, businessId, permission));
  }

  cachePermission(userId: string, businessId: string, permission: string, result: PermissionCheckResult): void {
    this.set(this.generateKey(userId, businessId, permission), result);
  }
}

// ==================================================================================
// PERMISSION ENGINE CORE
// ==================================================================================

export class PermissionEngine {
  private cache = new PermissionCache();
  private config: PermissionConfig | null = null;

  /**
   * Initialize permission engine with configuration
   */
  initialize(config: PermissionConfig): void {
    this.config = config;
    this.cache.clear();
  }

  /**
   * Check if user has specific permission
   */
  async checkPermission(
    session: SessionData,
    permission: string,
    context?: PermissionContext
  ): Promise<PermissionCheckResult> {
    try {
      // Input validation
      if (!session?.user?.id || !session.business?.id || !permission) {
        return this.createError('INVALID_INPUT', 'Missing required session or permission data');
      }

      // Check cache first
      const cached = this.cache.getCachedPermission(session.user.id, session.business.id, permission);
      if (cached) {
        return cached;
      }

      // Perform permission check
      const result = await this.performPermissionCheck(session, permission, context);
      
      // Cache result if successful
      if (result.allowed) {
        this.cache.cachePermission(session.user.id, session.business.id, permission, result);
      }

      return result;
    } catch (error) {
      return this.createError('SYSTEM_ERROR', `Permission check failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Check multiple permissions at once
   */
  async checkMultiplePermissions(
    session: SessionData,
    permissions: readonly string[],
    context?: PermissionContext
  ): Promise<Record<string, PermissionCheckResult>> {
    const results: Record<string, PermissionCheckResult> = {};

    await Promise.all(
      permissions.map(async (permission) => {
        results[permission] = await this.checkPermission(session, permission, context);
      })
    );

    return results;
  }

  /**
   * Get all permissions for user
   */
  getUserPermissions(session: SessionData): UserPermissions {
    if (!session?.business?.role_permissions) {
      return {
        features: {},
        allPermissions: [],
        allowedRoutes: [],
        restrictedFeatures: []
      };
    }

    const rolePermissions = session.business.role_permissions;
    const features: Record<string, readonly string[]> = {};
    const allPermissions: string[] = [];

    // Process features and permissions
    Object.entries(rolePermissions).forEach(([featureKey, permissions]) => {
      if (permissions && Array.isArray(permissions)) {
        features[featureKey] = permissions;
        allPermissions.push(...permissions);
      }
    });

    return {
      features,
      allPermissions,
      allowedRoutes: this.calculateAllowedRoutes(allPermissions),
      restrictedFeatures: this.calculateRestrictedFeatures(features)
    };
  }

  /**
   * Validate business rules
   */
  validateBusinessRules(session: SessionData, permission: string): PermissionCheckResult {
    if (!this.config) {
      return this.createError('CONFIG_MISSING', 'Permission configuration not initialized');
    }

    const rules = this.config.businessRules;

    // Check subscription tier restrictions
    if (rules.subscriptionTier) {
      const requiredTier = rules.subscriptionTier[permission as keyof typeof rules.subscriptionTier];
      if (requiredTier && session.business?.subscription_tier !== requiredTier) {
        return this.createError(
          'SUBSCRIPTION_REQUIRED',
          `Feature requires ${requiredTier} subscription tier`
        );
      }
    }

    // Check business status
    if (rules.businessStatus) {
      const requiredStatus = rules.businessStatus[permission as keyof typeof rules.businessStatus];
      if (requiredStatus && session.business?.status !== requiredStatus) {
        return this.createError(
          'BUSINESS_STATUS_INVALID',
          `Business must be ${requiredStatus} to access this feature`
        );
      }
    }

    // Check user role restrictions
    if (rules.userRole) {
      const allowedRoles = rules.userRole[permission as keyof typeof rules.userRole];
      if (allowedRoles && !allowedRoles.includes(session.business?.user_role || '')) {
        return this.createError(
          'ROLE_INSUFFICIENT',
          `User role insufficient for this permission`
        );
      }
    }

    return { allowed: true, reason: 'Business rules validated' };
  }

  /**
   * Clear permission cache
   */
  clearCache(): void {
    this.cache.clear();
  }

  // ==================================================================================
  // PRIVATE HELPER METHODS
  // ==================================================================================

  private async performPermissionCheck(
    session: SessionData,
    permission: string,
    context?: PermissionContext
  ): Promise<PermissionCheckResult> {
    // 1. Validate business rules first
    const businessValidation = this.validateBusinessRules(session, permission);
    if (!businessValidation.allowed) {
      return businessValidation;
    }

    // 2. Check if user has the permission in their role
    const userPermissions = this.getUserPermissions(session);
    
    // Handle different permission formats
    const hasPermission = this.checkPermissionInUserPermissions(userPermissions.allPermissions, permission);

    if (!hasPermission) {
      console.log(`🔍 [PERMISSION ENGINE] Permission check failed for: ${permission}`);
      console.log('Available permissions:', userPermissions.allPermissions);
      return this.createError(
        'PERMISSION_DENIED',
        `User does not have permission: ${permission}`
      );
    }

    // 3. Additional context-based validation
    if (context) {
      const contextValidation = await this.validateContext(session, permission, context);
      if (!contextValidation.allowed) {
        return contextValidation;
      }
    }

    return {
      allowed: true,
      reason: 'Permission granted',
      metadata: {
        permission,
        userId: session.user.id,
        businessId: session.business.id,
        userRole: session.business.user_role,
        subscriptionTier: session.business.subscription_tier
      }
    };
  }

  /**
   * Check if permission exists in user's permission list
   * Handle multiple permission formats for compatibility
   */
  private checkPermissionInUserPermissions(userPermissions: readonly string[], requestedPermission: string): boolean {
    // Direct match (exact permission)
    if (userPermissions.includes(requestedPermission)) {
      return true;
    }

    // Convert legacy test format to database format and check
    const databaseFormat = this.convertLegacyToDatabase(requestedPermission);
    if (databaseFormat && userPermissions.includes(databaseFormat)) {
      return true;
    }

    // Convert database format to legacy format and check
    const legacyFormat = this.convertDatabaseToLegacy(requestedPermission);
    if (legacyFormat && userPermissions.includes(legacyFormat)) {
      return true;
    }

    // Check if any permission matches the pattern
    return userPermissions.some(perm => {
      // Check if permission starts with feature name
      if (requestedPermission.includes('_')) {
        const [action, feature] = requestedPermission.split('_');
        return perm.includes(feature) && perm.includes(action);
      }
      return false;
    });
  }

  /**
   * Convert legacy permission format to database format
   * e.g. 'staff_view' -> 'staff_management.read'
   */
  private convertLegacyToDatabase(permission: string): string | null {
    const legacyToDatabase: Record<string, string> = {
      'staff_view': 'staff_management.read',
      'staff_create': 'staff_management.write',
      'staff_edit': 'staff_management.write',
      'staff_delete': 'staff_management.delete',
      'product_view': 'product_management.read',
      'product_create': 'product_management.write',
      'product_edit': 'product_management.write',
      'product_delete': 'product_management.delete',
      'financial_view': 'financial_tracking.read',
      'report_view': 'basic_reports.read',
      'pos_access': 'pos_interface.read'
    };

    return legacyToDatabase[permission] || null;
  }

  /**
   * Convert database permission format to legacy format
   * e.g. 'staff_management.read' -> 'staff_view'
   */
  private convertDatabaseToLegacy(permission: string): string | null {
    if (!permission.includes('.')) return null;

    const [feature, action] = permission.split('.');
    
    const databaseToLegacy: Record<string, Record<string, string>> = {
      'staff_management': {
        'read': 'staff_view',
        'write': 'staff_create',
        'delete': 'staff_delete'
      },
      'product_management': {
        'read': 'product_view',
        'write': 'product_create',
        'delete': 'product_delete'
      },
      'financial_tracking': {
        'read': 'financial_view'
      },
      'basic_reports': {
        'read': 'report_view'
      },
      'pos_interface': {
        'read': 'pos_access'
      }
    };

    return databaseToLegacy[feature]?.[action] || null;
  }

  private async validateContext(
    session: SessionData,
    permission: string,
    context: PermissionContext
  ): Promise<PermissionCheckResult> {
    // Implement context-specific validation logic here
    // For example: resource ownership, time-based restrictions, etc.
    
    if (context.resourceId && context.requireOwnership) {
      // Check if user owns the resource
      // This would require additional database queries
      // Implementation depends on specific business requirements
    }

    if (context.timeRestriction) {
      const now = new Date();
      const currentHour = now.getHours();
      const { startHour, endHour } = context.timeRestriction;
      
      if (currentHour < startHour || currentHour > endHour) {
        return this.createError('PERMISSION_DENIED', 'Access restricted during this time');
      }
    }

    return { allowed: true, reason: 'Context validation passed' };
  }

  private calculateAllowedRoutes(permissions: readonly string[]): readonly string[] {
    if (!this.config?.routes) return [];

    const allowedRoutes: string[] = [];

    Object.entries(this.config.routes).forEach(([route, config]) => {
      if (config.permissions.some(p => permissions.includes(p))) {
        allowedRoutes.push(route);
      }
    });

    return allowedRoutes;
  }

  private calculateRestrictedFeatures(features: Record<string, readonly string[]>): readonly string[] {
    if (!this.config?.features) return [];

    const restrictedFeatures: string[] = [];

    Object.entries(this.config.features).forEach(([featureKey, featureConfig]) => {
      const userFeaturePermissions = features[featureKey] || [];
      const hasAllRequired = featureConfig.requiredPermissions.every(p => 
        userFeaturePermissions.includes(p)
      );

      if (!hasAllRequired) {
        restrictedFeatures.push(featureKey);
      }
    });

    return restrictedFeatures;
  }

  private createError(type: PermissionError['type'], message: string): PermissionCheckResult {
    return {
      allowed: false,
      error: { type, message },
      reason: message
    };
  }
}

// ==================================================================================
// SINGLETON INSTANCE EXPORT
// ==================================================================================

export const permissionEngine = new PermissionEngine();

// ==================================================================================
// UTILITY FUNCTIONS
// ==================================================================================

/**
 * Quick permission check utility
 */
export async function hasPermission(
  session: SessionData,
  permission: string,
  context?: PermissionContext
): Promise<boolean> {
  const result = await permissionEngine.checkPermission(session, permission, context);
  return result.allowed;
}

/**
 * Permission check with detailed result
 */
export async function checkPermissionDetailed(
  session: SessionData,
  permission: string,
  context?: PermissionContext
): Promise<PermissionCheckResult> {
  return permissionEngine.checkPermission(session, permission, context);
}

/**
 * Get user's feature access summary
 */
export function getFeatureAccess(session: SessionData): UserPermissions {
  return permissionEngine.getUserPermissions(session);
}
