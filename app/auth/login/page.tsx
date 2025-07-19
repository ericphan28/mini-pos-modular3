'use client';

import { LoginForm } from "@/components/login-form";
import { optimizedLogger } from "@/lib/utils/optimized-logger";
import { authLogger } from "@/lib/logger";
import { Shield } from "lucide-react";
import Link from "next/link";
import { useEffect } from "react";

export default function Page() {
  useEffect(() => {
    const startTime = performance.now();
    
    // Page load tracking với permission system info
    optimizedLogger.info('PAGE_LOAD', 'Login page với Enhanced Permission System', {
      url: window.location.href,
      userAgent: navigator.userAgent,
      viewport: `${window.innerWidth}x${window.innerHeight}`,
      timestamp: new Date().toISOString(),
      permissionSystem: 'enabled',
      version: 'v2.0-permissions'
    });

    // Performance monitoring
    const loadTime = performance.now() - startTime;
    optimizedLogger.debug('PAGE_PERFORMANCE', 'Login page load performance', {
      loadTime: `${loadTime.toFixed(2)}ms`,
      readyState: document.readyState,
      permissionSystemEnabled: true
    });

    // Professional auth logger
    authLogger.loginAttempt({
      method: 'email',
      ip_address: 'client-side', // Will be updated by server
      user_agent: navigator.userAgent,
    }).catch(error => {
      optimizedLogger.warn('LOGGER_ERROR', 'Failed to log page access', error);
    });

    // Page visibility tracking
    const handleVisibilityChange = () => {
      optimizedLogger.debug('PAGE_VISIBILITY', `Login page ${document.hidden ? 'hidden' : 'visible'} - Permission System Active`);
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      optimizedLogger.debug('PAGE_CLEANUP', 'Login page unmounted - Permission system cleanup');
    };
  }, []);

  const handleSuperAdminClick = () => {
    optimizedLogger.info('NAVIGATION', 'User clicked Super Admin login', {
      from: '/auth/login',
      to: '/admin-login',
      timestamp: new Date().toISOString(),
      permissionBypass: true
    });
  };

  return (
    <div className="flex min-h-svh w-full items-center justify-center p-6 md:p-10">
      <div className="w-full max-w-sm space-y-6">
        {/* Enhanced Login Form - Keep existing detailed logging */}
        <LoginForm />
        
        {/* Super Admin Link */}
        <div className="text-center">
          <Link 
            href="/admin-login"
            onClick={handleSuperAdminClick}
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          >
            <Shield className="w-4 h-4" />
            Đăng nhập Super Admin
          </Link>
        </div>
        
        {/* Permission System Status */}
        <div className="text-center">
          <p className="text-xs text-muted-foreground">
            🔐 Permission System v2.0 | 
            <span className="text-green-600 font-medium">Active</span>
          </p>
        </div>
      </div>
    </div>
  );
}
