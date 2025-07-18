'use client'

import DashboardLayoutClient from "@/components/dashboard/layout-client";
import { createClient } from "@/lib/supabase/client";
import { businessLogger, setLoggerContext, clearLoggerContext } from '@/lib/logger';
import { SessionCacheManager } from '@/lib/utils/session-cache';
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

interface User {
  readonly id: string;
  readonly email?: string;
  readonly created_at: string;
}

const DASHBOARD_AUTH_CACHE_KEY = 'dashboard_auth_cache';
const DASHBOARD_AUTH_CACHE_TTL = 2 * 60 * 1000; // 2 minutes

interface DashboardAuthCache {
  readonly user: User;
  readonly timestamp: number;
  readonly source: 'session_cache' | 'rpc_call';
}

function getCachedDashboardAuth(): User | null {
  if (typeof window === 'undefined') return null;
  
  try {
    const cached = localStorage.getItem(DASHBOARD_AUTH_CACHE_KEY);
    if (!cached) return null;
    
    const parsedCache: DashboardAuthCache = JSON.parse(cached);
    const isExpired = Date.now() - parsedCache.timestamp > DASHBOARD_AUTH_CACHE_TTL;
    
    if (isExpired) {
      localStorage.removeItem(DASHBOARD_AUTH_CACHE_KEY);
      return null;
    }
    
    return parsedCache.user;
  } catch {
    return null;
  }
}

function setCachedDashboardAuth(user: User): void {
  if (typeof window === 'undefined') return;
  
  try {
    const cache: DashboardAuthCache = {
      user,
      timestamp: Date.now(),
      source: 'rpc_call'
    };
    
    localStorage.setItem(DASHBOARD_AUTH_CACHE_KEY, JSON.stringify(cache));
  } catch {
    // Ignore cache errors in production
  }
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async (): Promise<void> => {
      // Set initial logger context
      setLoggerContext({
        session_id: `dashboard_${Date.now()}`,
        user_agent: typeof window !== 'undefined' ? window.navigator.userAgent : 'server'
      });

      try {
        // **PERFORMANCE TRACKING: Total dashboard load time**
        await businessLogger.performanceTrack(
          'DASHBOARD_TOTAL_LOAD',
          { business_id: 'system', user_id: 'unknown' },
          async () => {
            // **TỐI ƯU 1: Ưu tiên lấy session từ cache trước (FAST PATH)**
            const cachedSession = await businessLogger.performanceTrack(
              'SESSION_CACHE_CHECK',
              { business_id: 'system', user_id: 'unknown' },
              async () => SessionCacheManager.getCachedSession(),
              { cache_type: 'session_cache' }
            );
            
            if (cachedSession) {
              // Cache hit - instant load
              await businessLogger.performanceTrack(
                'CACHE_HIT_PROCESSING',
                { business_id: cachedSession.business.id, user_id: cachedSession.user.id },
                async () => {
                  const userData: User = {
                    id: cachedSession.user.id,
                    email: cachedSession.user.email,
                    created_at: cachedSession.session_info.login_time
                  };
                  
                  setUser(userData);
                  setCachedDashboardAuth(userData);
                  
                  // Update logger context with user info
                  setLoggerContext({
                    user_id: cachedSession.user.id,
                    business_id: cachedSession.business.id
                  });
                },
                { 
                  source: 'localStorage_cache',
                  cache_hit: true
                }
              );
              
              setLoading(false);
              return;
            }
            
            // **TỐI ƯU 2: Cache miss - optimized RPC flow (SLOW PATH)**
            await businessLogger.performanceTrack(
              'AUTH_USER_CHECK',
              { business_id: 'system', user_id: 'unknown' },
              async () => {
                const supabase = createClient();
                const { data: { user: authUser } } = await supabase.auth.getUser();
                
                if (!authUser) {
                  throw new Error('No authenticated user');
                }

                // **TỐI ƯU 3: Efficient profile check với better error handling**
                const profileResult = await businessLogger.performanceTrack(
                  'PROFILE_VALIDATION',
                  { business_id: 'unknown', user_id: authUser.id },
                  async () => {
                    const result = await supabase.rpc(
                      'pos_mini_modular3_get_user_profile_safe',
                      { p_user_id: authUser.id }
                    );
                    return result;
                  },
                  { user_id: authUser.id }
                );

                const { data: profileData, error: profileError } = profileResult as { 
                  data: { 
                    profile_exists?: boolean; 
                    business?: { id?: string }; 
                  } | null; 
                  error: Error | null; 
                };

                if (profileError || !profileData?.profile_exists) {
                  throw new Error(`Profile validation failed: ${profileError?.message || 'Profile not found'}`);
                }

                // **TỐI ƯU 4: Successful fallback flow**
                await businessLogger.performanceTrack(
                  'USER_STATE_UPDATE',
                  { 
                    business_id: profileData.business?.id || 'unknown', 
                    user_id: authUser.id 
                  },
                  async () => {
                    const userData: User = {
                      id: authUser.id,
                      email: authUser.email,
                      created_at: authUser.created_at
                    };
                    
                    setUser(userData);
                    setCachedDashboardAuth(userData);
                    
                    // Update logger context
                    setLoggerContext({
                      user_id: authUser.id,
                      business_id: profileData.business?.id || 'unknown'
                    });
                  },
                  { method: 'rpc_fallback' }
                );
              },
              { cache_miss: true }
            );
          },
          { component: 'dashboard_layout' }
        );
      } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        
        if (errorMessage.includes('No authenticated user')) {
          router.push('/auth/login');
        } else if (errorMessage.includes('Profile validation failed')) {
          router.push('/auth/confirm?redirect=/dashboard');
        } else {
          router.push('/auth/login');
        }
      } finally {
        setLoading(false);
      }
    };

    // **TỐI ƯU: Kiểm tra cache địa phương trước khi gọi hàm xác thực**
    const cachedUser = getCachedDashboardAuth();
    if (cachedUser) {
      setLoggerContext({
        user_id: cachedUser.id,
        session_id: `dashboard_cached_${Date.now()}`
      });
      
      void businessLogger.performanceTrack(
        'DASHBOARD_CACHE_HIT',
        { business_id: 'unknown', user_id: cachedUser.id },
        async () => {
          setUser(cachedUser);
          setLoading(false);
        },
        { source: 'localStorage', cache_type: 'dashboard_auth' }
      );
      return;
    }

    void checkAuth();
    
    // Cleanup function
    return () => {
      clearLoggerContext();
    };
  }, [router]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="text-muted-foreground">Đang tải...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return <DashboardLayoutClient user={user}>{children}</DashboardLayoutClient>;
}
