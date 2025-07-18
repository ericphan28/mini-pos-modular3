// Session management exports - DISABLED (Using React Context pattern)
// export { SessionManager } from './manager';
export { MultiLayerCache } from './cache';
export { sessionLogger } from './logger';

// Import SessionManager for internal use - DISABLED (Using React Context pattern)  
// import { SessionManager } from './manager';

// Types
export type {
  UserSession,
  SessionManagerConfig,
  SessionValidationResult,
  SessionEvent,
  UserProfile,
  BusinessContext,
  PermissionSet,
  SecurityContext,
  CacheMetadata,
  PermissionCheckResult,
  UserRole,
  SubscriptionTier,
  CacheStorageType,
  CacheLayer,
  SessionStorage,
  SessionStorageOptions,
  RefreshConfig
} from './types';

// Default configuration - DISABLED (Using React Context pattern)
// import type { SessionManagerConfig } from './types';

// export const defaultSessionConfig: SessionManagerConfig = {
export const defaultSessionConfig = {
  storage: {
    enableMemoryCache: true,
    enableLocalStorage: true,
    enableCookies: false,
    memoryTTL: 15 * 60 * 1000, // 15 minutes
    localStorageTTL: 24 * 60 * 60 * 1000, // 24 hours
    cookieTTL: 7 * 24 * 60 * 60 * 1000 // 7 days
  },
  refresh: {
    enableBackgroundRefresh: true,
    refreshInterval: 5 * 60 * 1000, // 5 minutes
    refreshThreshold: 5 * 60 * 1000, // Refresh when 5 minutes left
    maxRefreshRetries: 3
  },
  security: {
    enableDeviceFingerprinting: true,
    enableRiskScoring: true,
    maxConcurrentSessions: 3,
    sessionTimeoutWarning: 5 // minutes before expiry
  }
};

// Singleton session manager instance - DISABLED (Using React Context pattern)
/*
let sessionManagerInstance: SessionManager | null = null;

export function getSessionManager(config?: any): SessionManager {
  if (!sessionManagerInstance) {
    sessionManagerInstance = new SessionManager(config);
  }
  
  return sessionManagerInstance;
}

export function destroySessionManager(): void {
  if (sessionManagerInstance) {
    sessionManagerInstance.destroy();
    sessionManagerInstance = null;
  }
}

export const sessionManager = getSessionManager();
*/
