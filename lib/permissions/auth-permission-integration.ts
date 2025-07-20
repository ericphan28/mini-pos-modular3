// ==================================================================================
// AUTH-PERMISSION INTEGRATION BRIDGE
// ==================================================================================
// Bridge layer connecting auth system with centralized permission system

'use client';

import { permissionEngine } from './permission-engine';
import { adaptSessionData } from './session-adapter';
import { getPermissionsByTier, getRouteConfig, ALL_PERMISSIONS } from './permission-config';
import type { SessionData as AuthSessionData, PermissionCache } from '@/lib/auth/types';

// ==================================================================================
// PERMISSION SYNC SERVICE
// ==================================================================================

export class AuthPermissionBridge {
  private static instance: AuthPermissionBridge;
  private permissionCache: Map<string, PermissionCache> = new Map();
  private lastSyncTime: number = 0;
  private readonly SYNC_INTERVAL = 5 * 60 * 1000; // 5 minutes

  static getInstance(): AuthPermissionBridge {
    if (!AuthPermissionBridge.instance) {
      AuthPermissionBridge.instance = new AuthPermissionBridge();
    }
    return AuthPermissionBridge.instance;
  }

  /**
   * Generate permission cache from auth session data
   */
  async generatePermissionCache(authSession: AuthSessionData): Promise<PermissionCache> {
    try {
      // Convert to permission session format
      const permissionSession = adaptSessionData(authSession);
      
      // Get user permissions from permission engine
      const userPermissions = permissionEngine.getUserPermissions(permissionSession);
      
      // Calculate subscription-based limits
      const subscriptionLimits = this.calculateSubscriptionLimits(
        authSession.business.subscriptionTier,
        userPermissions.allPermissions
      );

      // Generate allowed routes
      const allowedRoutes = this.calculateAllowedRoutes(userPermissions.allPermissions);

      const cache: PermissionCache = {
        lastUpdated: new Date().toISOString(),
        userPermissions: userPermissions.features,
        allowedRoutes,
        restrictedFeatures: userPermissions.restrictedFeatures,
        subscriptionLimits
      };

      // Cache the result
      const cacheKey = `${authSession.user.id}:${authSession.business.id}`;
      this.permissionCache.set(cacheKey, cache);
      this.lastSyncTime = Date.now();

      return cache;
    } catch (error) {
      console.error('Permission cache generation failed:', error);
      return this.getEmptyCache();
    }
  }

  /**
   * Check if user has specific permission
   */
  async hasPermission(authSession: AuthSessionData, permission: string): Promise<boolean> {
    try {
      const permissionSession = adaptSessionData(authSession);
      const result = await permissionEngine.checkPermission(permissionSession, permission);
      return result.allowed;
    } catch (error) {
      console.error('Permission check failed:', error);
      return false;
    }
  }

  /**
   * Check if user has access to specific feature
   */
  hasFeatureAccess(cache: PermissionCache, feature: string): boolean {
    return !!cache.userPermissions[feature] && cache.userPermissions[feature].length > 0;
  }

  /**
   * Check if user can access specific route
   */
  canAccessRoute(cache: PermissionCache, route: string): boolean {
    return cache.allowedRoutes.includes(route);
  }

  /**
   * Get user permissions from cache
   */
  getUserPermissions(cache: PermissionCache): Record<string, readonly string[]> {
    return cache.userPermissions;
  }

  /**
   * Get subscription limits from cache
   */
  getSubscriptionLimits(cache: PermissionCache): Record<string, boolean> {
    return cache.subscriptionLimits;
  }

  /**
   * Check if permission cache needs refresh
   */
  needsRefresh(cache: PermissionCache | null): boolean {
    if (!cache) return true;
    
    const cacheAge = Date.now() - new Date(cache.lastUpdated).getTime();
    return cacheAge > this.SYNC_INTERVAL;
  }

  /**
   * Refresh permissions from database
   */
  async refreshPermissions(authSession: AuthSessionData): Promise<PermissionCache> {
    // In a real implementation, this would fetch fresh data from database
    // For now, we'll regenerate the cache
    return this.generatePermissionCache(authSession);
  }

  /**
   * Clear permission cache for user
   */
  clearCache(userId: string, businessId: string): void {
    const cacheKey = `${userId}:${businessId}`;
    this.permissionCache.delete(cacheKey);
  }

  /**
   * Clear all permission caches
   */
  clearAllCaches(): void {
    this.permissionCache.clear();
  }

  // ==================================================================================
  // PRIVATE HELPER METHODS
  // ==================================================================================

  private calculateSubscriptionLimits(
    tier: string, 
    userPermissions: readonly string[]
  ): Record<string, boolean> {
    const limits: Record<string, boolean> = {};
    
    // Map subscription tier to permission tier
    const permissionTier = tier === 'basic' ? 'free' : 
                          tier === 'premium' ? 'premium' : 
                          tier === 'enterprise' ? 'enterprise' : 'free';
    
    const tierPermissions = getPermissionsByTier(permissionTier as 'free' | 'premium' | 'enterprise');
    
    // Check each permission against tier limits
    ALL_PERMISSIONS.forEach(permission => {
      limits[permission] = tierPermissions.includes(permission) && userPermissions.includes(permission);
    });

    return limits;
  }

  private calculateAllowedRoutes(userPermissions: readonly string[]): readonly string[] {
    const allowedRoutes: string[] = [];

    // Check each route against user permissions
    const routes = [
      '/dashboard',
      '/dashboard/staff',
      '/dashboard/staff/create',
      '/dashboard/financial',
      '/dashboard/financial/reports',
      '/dashboard/financial/detailed',
      '/dashboard/products',
      '/dashboard/products/create',
      '/dashboard/categories',
      '/dashboard/categories/create',
      '/dashboard/inventory',
      '/dashboard/inventory/manage',
      '/dashboard/pos',
      '/dashboard/pos/sales',
      '/dashboard/reports',
      '/dashboard/reports/advanced',
      '/dashboard/settings'
    ];

    routes.forEach(route => {
      const routeConfig = getRouteConfig(route);
      if (routeConfig) {
        const hasAccess = routeConfig.requireAllPermissions
          ? routeConfig.permissions.every(p => userPermissions.includes(p))
          : routeConfig.permissions.some(p => userPermissions.includes(p));
        
        if (hasAccess) {
          allowedRoutes.push(route);
        }
      } else {
        // Default routes that don't require specific permissions
        allowedRoutes.push(route);
      }
    });

    return allowedRoutes;
  }

  private getEmptyCache(): PermissionCache {
    return {
      lastUpdated: new Date().toISOString(),
      userPermissions: {},
      allowedRoutes: ['/dashboard'],
      restrictedFeatures: [],
      subscriptionLimits: {}
    };
  }
}

// ==================================================================================
// SINGLETON INSTANCE EXPORT
// ==================================================================================

export const authPermissionBridge = AuthPermissionBridge.getInstance();

// ==================================================================================
// UTILITY FUNCTIONS
// ==================================================================================

/**
 * Initialize permission integration for auth session
 */
export async function initializePermissions(authSession: AuthSessionData): Promise<PermissionCache> {
  return authPermissionBridge.generatePermissionCache(authSession);
}

/**
 * Quick permission check using auth session
 */
export async function checkAuthPermission(authSession: AuthSessionData, permission: string): Promise<boolean> {
  return authPermissionBridge.hasPermission(authSession, permission);
}

/**
 * Validate if auth session is compatible with permission system
 */
export function validateAuthSession(authSession: AuthSessionData): boolean {
  return !!(
    authSession?.user?.id &&
    authSession?.user?.email &&
    authSession?.business?.id &&
    authSession?.business?.name &&
    authSession?.permissions?.role
  );
}
