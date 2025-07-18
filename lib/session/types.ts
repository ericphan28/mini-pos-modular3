// Session management types for POS system

export interface UserProfile {
  readonly id: string;
  readonly email: string;
  readonly fullName: string;
  readonly phone?: string;
  readonly role: UserRole;
  readonly status: string;
  readonly loginMethod: string;
  readonly lastLoginAt?: string;
}

export interface BusinessContext {
  readonly id: string;
  readonly name: string;
  readonly code: string;
  readonly businessType: string;
  readonly subscriptionTier: SubscriptionTier;
  readonly subscriptionStatus: string;
  readonly maxUsers: number;
  readonly maxProducts: number;
  readonly trialEndsAt?: string;
  readonly subscriptionEndsAt?: string;
  readonly featuresEnabled: Record<string, unknown>;
}

export interface PermissionSet {
  readonly [featureName: string]: {
    readonly canRead: boolean;
    readonly canWrite: boolean;
    readonly canDelete: boolean;
    readonly canManage: boolean;
    readonly usageLimit?: number;
    readonly currentUsage?: number;
  };
}

export interface SecurityContext {
  readonly ipAddress: string;
  readonly userAgent: string;
  readonly deviceFingerprint?: string;
  readonly riskScore: number;
  readonly loginTime: string;
  readonly lastActivity: string;
  readonly sessionId: string;
}

export interface CacheMetadata {
  readonly createdAt: string;
  readonly lastRefresh: string;
  readonly ttl: number;
  readonly version: number;
  readonly source: 'login' | 'refresh' | 'cache';
}

export interface UserSession {
  readonly sessionId: string;
  readonly userId: string;
  readonly sessionToken: string;
  readonly expiresAt: string;
  readonly profile: UserProfile;
  readonly business: BusinessContext;
  readonly permissions: PermissionSet;
  readonly security: SecurityContext;
  readonly cacheInfo: CacheMetadata;
}

export interface SessionStorageOptions {
  readonly enableMemoryCache: boolean;
  readonly enableLocalStorage: boolean;
  readonly enableCookies: boolean;
  readonly memoryTTL: number; // milliseconds
  readonly localStorageTTL: number; // milliseconds
  readonly cookieTTL: number; // milliseconds
}

export interface SessionValidationResult {
  readonly isValid: boolean;
  readonly reason?: 'expired' | 'invalid_token' | 'not_found' | 'security_violation';
  readonly session?: UserSession;
  readonly needsRefresh: boolean;
}

// User roles in the system
export type UserRole = 
  | 'household_owner'
  | 'business_manager' 
  | 'staff_member'
  | 'cashier'
  | 'inventory_manager'
  | 'viewer';

// Subscription tiers
export type SubscriptionTier = 
  | 'free' 
  | 'basic' 
  | 'professional' 
  | 'enterprise';

// Cache storage types
export type CacheStorageType = 'memory' | 'localStorage' | 'sessionStorage';

// Session events for logging
export interface SessionEvent {
  readonly type: 'created' | 'refreshed' | 'expired' | 'invalidated' | 'accessed';
  readonly sessionId: string;
  readonly userId: string;
  readonly timestamp: string;
  readonly metadata?: Record<string, unknown>;
}

// Background refresh configuration
export interface RefreshConfig {
  readonly enableBackgroundRefresh: boolean;
  readonly refreshInterval: number; // milliseconds
  readonly refreshThreshold: number; // refresh when TTL < threshold
  readonly maxRefreshRetries: number;
}

// Session manager configuration
export interface SessionManagerConfig {
  readonly storage: SessionStorageOptions;
  readonly refresh: RefreshConfig;
  readonly security: {
    readonly enableDeviceFingerprinting: boolean;
    readonly enableRiskScoring: boolean;
    readonly maxConcurrentSessions: number;
    readonly sessionTimeoutWarning: number; // minutes before expiry
  };
}

// Cache layer interface
export interface CacheLayer {
  get(key: string): Promise<unknown | null>;
  set(key: string, value: unknown, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
  has(key: string): Promise<boolean>;
}

// Session storage interface
export interface SessionStorage {
  store(session: UserSession): Promise<void>;
  retrieve(sessionId: string): Promise<UserSession | null>;
  remove(sessionId: string): Promise<void>;
  cleanup(): Promise<number>; // returns count of cleaned sessions
}

// Permission check result
export interface PermissionCheckResult {
  readonly hasPermission: boolean;
  readonly reason?: string;
  readonly usageInfo?: {
    readonly current: number;
    readonly limit: number;
    readonly remaining: number;
  };
}
