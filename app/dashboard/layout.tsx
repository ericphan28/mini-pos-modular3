'use client'

import DashboardLayoutClient from "@/components/dashboard/layout-client";
import { createClient } from "@/lib/supabase/client";
import { optimizedLogger } from '@/lib/utils/optimized-logger';
import { SessionCacheManager } from '@/lib/utils/session-cache';
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

interface User {
  id: string;
  email?: string;
  created_at: string;
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

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      const startTime = Date.now();
      
      try {
        // **TỐI ƯU: Batch logging để giảm HTTP requests**
        optimizedLogger.info('DASHBOARD', 'Starting auth check for dashboard', { timestamp: new Date().toISOString() });
        
        // **TỐI ƯU 1: Ưu tiên lấy session từ cache trước (FAST PATH)**
        const cachedSession = SessionCacheManager.getCachedSession();
        
        if (cachedSession) {
          // Cache hit - instant load
          const loadTime = Date.now() - startTime;
          optimizedLogger.success('CACHE_HIT', 'Using cached session for instant load', {
            userId: cachedSession.user.id,
            businessId: cachedSession.business.id,
            loadTime: `${loadTime}ms`,
            source: 'localStorage_cache'
          });
          
          setUser({
            id: cachedSession.user.id,
            email: cachedSession.user.email,
            created_at: cachedSession.session_info.login_time
          });
          
          setLoading(false);
          return;
        }
        
        // **TỐI ƯU 2: Cache miss - optimized RPC flow (SLOW PATH)**
        optimizedLogger.info('CACHE_MISS', 'No cached session, executing RPC flow');
        
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
          optimizedLogger.warn('AUTH_FAILED', 'No authenticated user, redirecting to login');
          router.push('/auth/login');
          return;
        }

        // **TỐI ƯU 3: Efficient profile check với better error handling**
        const { data: profileData, error: profileError } = await supabase.rpc(
          'pos_mini_modular3_get_user_profile_safe',
          { p_user_id: user.id }
        );

        if (profileError || !profileData?.profile_exists) {
          const loadTime = Date.now() - startTime;
          optimizedLogger.warn('PROFILE_ISSUE', 'Profile validation failed, redirecting', {
            error: profileError?.message || 'Profile not found',
            profileExists: profileData?.profile_exists,
            loadTime: `${loadTime}ms`,
            redirectTo: '/auth/confirm'
          });
          router.push('/auth/confirm?redirect=/dashboard');
          return;
        }

        // **TỐI ƯU 4: Successful fallback flow với performance metrics**
        const loadTime = Date.now() - startTime;
        optimizedLogger.success('AUTH_SUCCESS', 'Dashboard auth completed successfully', {
          userId: user.id,
          method: 'rpc_fallback',
          loadTime: `${loadTime}ms`,
          cacheRecommendation: 'Consider login to enable session cache'
        });
        setUser({
          id: user.id,
          email: user.email,
          created_at: user.created_at
        });
      } catch (error) {
        const loadTime = Date.now() - startTime;
        optimizedLogger.error('DASHBOARD_ERROR', 'Dashboard auth check failed', {
          error: error instanceof Error ? error.message : 'Unknown error',
          loadTime: `${loadTime}ms`,
          fallbackAction: 'Redirecting to login'
        });
        router.push('/auth/login');
      } finally {
        setLoading(false);
      }
    };

    // **TỐI ƯU: Kiểm tra cache địa phương trước khi gọi hàm xác thực**
    const cachedUser = getCachedDashboardAuth();
    if (cachedUser) {
      optimizedLogger.info('CACHE_HIT', 'Using cached dashboard auth', {
        userId: cachedUser.id,
        source: 'localStorage',
        timestamp: new Date().toISOString()
      });
      setUser(cachedUser);
      setLoading(false);
      return;
    }

    checkAuth();
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
