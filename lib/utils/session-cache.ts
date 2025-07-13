interface CompleteUserSession {
  readonly success: boolean;
  readonly profile_exists: boolean;
  readonly user: {
    readonly id: string;
    readonly profile_id: string;
    readonly email: string;
    readonly role: string;
    readonly full_name: string;
    readonly phone: string | null;
    readonly login_method: string;
    readonly status: string;
  };
  readonly business: {
    readonly id: string;
    readonly name: string;
    readonly business_type: string;
    readonly business_type_name: string;
    readonly business_code: string;
    readonly contact_email: string | null;
    readonly contact_phone: string | null;
    readonly address: string | null;
    readonly subscription_tier: string;
    readonly subscription_status: string;
    readonly trial_end_date: string | null;
    readonly features_enabled: Record<string, unknown>;
    readonly usage_stats: Record<string, unknown>;
    readonly status: string;
  };
  readonly permissions: Record<string, unknown>;
  readonly session_info: {
    readonly login_time: string;
    readonly user_agent?: string;
  };
}

interface LoginCache {
  readonly sessionData: CompleteUserSession;
  readonly timestamp: number;
  readonly expiresAt: number;
}

export class SessionCacheManager {
  private static readonly CACHE_KEY = 'pos_session_cache';
  private static readonly CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

  public static cacheSession(sessionData: CompleteUserSession): void {
    if (typeof window === 'undefined') return;
    
    const cache: LoginCache = {
      sessionData,
      timestamp: Date.now(),
      expiresAt: Date.now() + this.CACHE_DURATION,
    };
    
    try {
      sessionStorage.setItem(this.CACHE_KEY, JSON.stringify(cache));
    } catch (error: unknown) {
      console.warn('Failed to cache session data:', error);
    }
  }

  public static getCachedSession(): CompleteUserSession | null {
    if (typeof window === 'undefined') return null;
    
    try {
      const cached = sessionStorage.getItem(this.CACHE_KEY);
      if (!cached) return null;
      
      const parsedCache = JSON.parse(cached) as LoginCache;
      
      // Check if cache is still valid
      if (Date.now() > parsedCache.expiresAt) {
        this.clearCache();
        return null;
      }
      
      return parsedCache.sessionData;
    } catch (error: unknown) {
      console.warn('Failed to read cached session:', error);
      this.clearCache();
      return null;
    }
  }

  public static clearCache(): void {
    if (typeof window === 'undefined') return;
    
    try {
      sessionStorage.removeItem(this.CACHE_KEY);
    } catch (error: unknown) {
      console.warn('Failed to clear cache:', error);
    }
  }

  public static isCacheValid(): boolean {
    return this.getCachedSession() !== null;
  }

  public static transformEnhancedDataToSession(enhancedData: unknown): CompleteUserSession | null {
    try {
      const data = enhancedData as {
        success?: boolean;
        user?: Record<string, unknown>;
        business?: Record<string, unknown>;
        permissions?: Record<string, unknown>;
        session_info?: Record<string, unknown>;
      };

      if (!data.success || !data.user || !data.business) {
        return null;
      }

      const user = data.user;
      const business = data.business;
      const permissions = data.permissions || {};
      const sessionInfo = data.session_info || {};

      return {
        success: true,
        profile_exists: true,
        user: {
          id: String(user.id || ''),
          profile_id: String(user.profile_id || user.id || ''),
          email: String(user.email || ''),
          role: String(user.role || 'staff'),
          full_name: String(user.full_name || ''),
          phone: user.phone ? String(user.phone) : null,
          login_method: String(user.login_method || 'email'),
          status: String(user.status || 'active'),
        },
        business: {
          id: String(business.id || ''),
          name: String(business.name || ''),
          business_type: String(business.business_type || ''),
          business_type_name: String(business.business_type_name || business.business_type || ''),
          business_code: String(business.code || ''),
          contact_email: business.email ? String(business.email) : null,
          contact_phone: business.phone ? String(business.phone) : null,
          address: business.address ? String(business.address) : null,
          subscription_tier: String(business.subscription_tier || 'free'),
          subscription_status: String(business.subscription_status || 'trial'),
          trial_end_date: business.trial_ends_at ? String(business.trial_ends_at) : null,
          features_enabled: (business.features_enabled as Record<string, unknown>) || {},
          usage_stats: (business.usage_stats as Record<string, unknown>) || {},
          status: String(business.status || 'active'),
        },
        permissions,
        session_info: {
          login_time: String(sessionInfo.login_time || new Date().toISOString()),
          user_agent: sessionInfo.user_agent ? String(sessionInfo.user_agent) : undefined,
        },
      };
    } catch (error: unknown) {
      console.error('Failed to transform enhanced data:', error);
      return null;
    }
  }
}

export type { CompleteUserSession, LoginCache };
