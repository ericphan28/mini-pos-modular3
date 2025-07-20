// ==================================================================================
// ROUTE PERMISSION GUARD COMPONENT
// ==================================================================================
// Provides route-level permission checking and access control for the POS system
// Integrates with the centralized permission engine and auth context

'use client';

import { useEffect, useState, useCallback, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { permissionEngine } from './permission-engine';
import { useAuth } from '@/lib/auth/auth-context';
import { adaptSessionData } from './session-adapter';
import type { RoutePermissionConfig, PermissionContext, PermissionCheckResult } from './permission-types';
import type { SessionData as AuthSessionData } from '@/lib/auth/types';

// ==================================================================================
// ROUTE GUARD COMPONENT INTERFACES
// ==================================================================================

interface RouteGuardProps {
  readonly children: ReactNode;
  readonly requiredPermissions?: readonly string[];
  readonly requiredRole?: string;
  readonly fallbackRoute?: string;
  readonly loadingComponent?: ReactNode;
  readonly accessDeniedComponent?: ReactNode;
  readonly context?: PermissionContext;
}

interface RouteGuardState {
  readonly isChecking: boolean;
  readonly hasAccess: boolean;
  readonly error: string | null;
  readonly permissionResults?: Record<string, PermissionCheckResult>;
}

// ==================================================================================
// ROUTE PERMISSION GUARD COMPONENT
// ==================================================================================

export function RoutePermissionGuard({
  children,
  requiredPermissions = [],
  requiredRole,
  fallbackRoute = '/dashboard',
  loadingComponent,
  accessDeniedComponent,
  context
}: RouteGuardProps) {
  const { sessionData, isLoading } = useAuth();
  const router = useRouter();
  
  const [guardState, setGuardState] = useState<RouteGuardState>({
    isChecking: true,
    hasAccess: false,
    error: null
  });

  const checkRouteAccess = useCallback(async (): Promise<void> => {
    // Wait for auth to load
    if (isLoading) {
      return;
    }

    // No session = no access
    if (!sessionData) {
      setGuardState({
        isChecking: false,
        hasAccess: false,
        error: 'No active session'
      });
      router.push('/auth/login');
      return;
    }

    try {
      setGuardState(prev => ({ ...prev, isChecking: true, error: null }));

      // Convert auth session to permission session
      const session = adaptSessionData(sessionData);

      // Check role requirement first
      if (requiredRole && session.business?.user_role !== requiredRole) {
        setGuardState({
          isChecking: false,
          hasAccess: false,
          error: `Required role: ${requiredRole}, current role: ${session.business?.user_role || 'none'}`
        });
        router.push(fallbackRoute);
        return;
      }

      // Check permissions if specified
      if (requiredPermissions.length > 0) {
        const permissionResults = await permissionEngine.checkMultiplePermissions(
          session,
          requiredPermissions,
          context
        );

        const allPermissionsGranted = requiredPermissions.every(
          permission => permissionResults[permission]?.allowed
        );

        if (!allPermissionsGranted) {
          const deniedPermissions = requiredPermissions.filter(
            permission => !permissionResults[permission]?.allowed
          );

          setGuardState({
            isChecking: false,
            hasAccess: false,
            error: `Access denied. Missing permissions: ${deniedPermissions.join(', ')}`,
            permissionResults
          });
          router.push(fallbackRoute);
          return;
        }

        setGuardState({
          isChecking: false,
          hasAccess: true,
          error: null,
          permissionResults
        });
      } else {
        // No specific permissions required, just valid session
        setGuardState({
          isChecking: false,
          hasAccess: true,
          error: null
        });
      }
    } catch (error) {
      setGuardState({
        isChecking: false,
        hasAccess: false,
        error: `Permission check failed: ${error instanceof Error ? error.message : 'Unknown error'}`
      });
      router.push(fallbackRoute);
    }
  }, [sessionData, isLoading, requiredRole, requiredPermissions, context, router, fallbackRoute]);

  useEffect(() => {
    checkRouteAccess();
  }, [checkRouteAccess]);

  // Show loading state
  if (isLoading || guardState.isChecking) {
    return loadingComponent || <RouteGuardLoading />;
  }

  // Show access denied
  if (!guardState.hasAccess) {
    return accessDeniedComponent || (
      <RouteGuardAccessDenied 
        error={guardState.error}
        fallbackRoute={fallbackRoute}
      />
    );
  }

  // Render children if access granted
  return <>{children}</>;
}

// ==================================================================================
// PERMISSION WRAPPER COMPONENT
// ==================================================================================

interface PermissionWrapperProps {
  readonly children: ReactNode;
  readonly permission: string;
  readonly fallback?: ReactNode;
  readonly context?: PermissionContext;
  readonly showFallback?: boolean;
}

export function PermissionWrapper({
  children,
  permission,
  fallback,
  context,
  showFallback = true
}: PermissionWrapperProps) {
  const { sessionData } = useAuth();
  const [hasPermission, setHasPermission] = useState<boolean>(false);
  const [isChecking, setIsChecking] = useState<boolean>(true);

  const checkPermission = useCallback(async (): Promise<void> => {
    if (!sessionData) {
      setHasPermission(false);
      setIsChecking(false);
      return;
    }

    try {
      const session = adaptSessionData(sessionData);
      const result = await permissionEngine.checkPermission(session, permission, context);
      setHasPermission(result.allowed);
    } catch (error) {
      console.error('Permission check error:', error);
      setHasPermission(false);
    } finally {
      setIsChecking(false);
    }
  }, [sessionData, permission, context]);

  useEffect(() => {
    checkPermission();
  }, [checkPermission]);

  if (isChecking) {
    return null; // Or a small loading indicator
  }

  if (hasPermission) {
    return <>{children}</>;
  }

  if (showFallback && fallback) {
    return <>{fallback}</>;
  }

  return null;
}

// ==================================================================================
// ROUTE-BASED PERMISSION HOOK
// ==================================================================================

export function useRoutePermissions(routeConfig?: RoutePermissionConfig) {
  const { sessionData } = useAuth();
  const [permissions, setPermissions] = useState<Record<string, PermissionCheckResult>>({});
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const checkRoutePermissions = useCallback(async (): Promise<void> => {
    if (!sessionData || !routeConfig) {
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      const session = adaptSessionData(sessionData);
      const results = await permissionEngine.checkMultiplePermissions(
        session,
        routeConfig.permissions
      );
      setPermissions(results);
    } catch (error) {
      console.error('Route permission check error:', error);
      setPermissions({});
    } finally {
      setIsLoading(false);
    }
  }, [sessionData, routeConfig]);

  useEffect(() => {
    checkRoutePermissions();
  }, [checkRoutePermissions]);

  const hasAllPermissions = routeConfig ? 
    routeConfig.permissions.every(p => permissions[p]?.allowed) : false;

  const hasAnyPermission = routeConfig ?
    routeConfig.permissions.some(p => permissions[p]?.allowed) : false;

  return {
    permissions,
    hasAllPermissions,
    hasAnyPermission,
    isLoading,
    refresh: checkRoutePermissions
  };
}

// ==================================================================================
// DEFAULT LOADING AND ACCESS DENIED COMPONENTS
// ==================================================================================

function RouteGuardLoading() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="flex flex-col items-center space-y-4">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <p className="text-sm text-gray-600">Đang kiểm tra quyền truy cập...</p>
      </div>
    </div>
  );
}

interface RouteGuardAccessDeniedProps {
  readonly error: string | null;
  readonly fallbackRoute: string;
}

function RouteGuardAccessDenied({ error, fallbackRoute }: RouteGuardAccessDeniedProps) {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
        <div className="text-center">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
            <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="mt-4 text-lg font-medium text-gray-900">
            Không có quyền truy cập
          </h3>
          <p className="mt-2 text-sm text-gray-500">
            {error || 'Bạn không có quyền truy cập vào trang này'}
          </p>
          <div className="mt-6 space-y-3">
            <button
              onClick={() => router.push(fallbackRoute)}
              className="w-full inline-flex justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Về trang chủ
            </button>
            <button
              onClick={() => router.back()}
              className="w-full inline-flex justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Quay lại
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ==================================================================================
// UTILITY FUNCTIONS FOR ROUTE PROTECTION
// ==================================================================================

/**
 * Create a higher-order component for route protection
 */
export function withRoutePermission(
  requiredPermissions: readonly string[],
  options?: {
    readonly requiredRole?: string;
    readonly fallbackRoute?: string;
    readonly loadingComponent?: ReactNode;
    readonly accessDeniedComponent?: ReactNode;
  }
) {
  return function PermissionWrapper<P extends object>(
    Component: React.ComponentType<P>
  ) {
    return function ProtectedComponent(props: P) {
      return (
        <RoutePermissionGuard
          requiredPermissions={requiredPermissions}
          requiredRole={options?.requiredRole}
          fallbackRoute={options?.fallbackRoute}
          loadingComponent={options?.loadingComponent}
          accessDeniedComponent={options?.accessDeniedComponent}
        >
          <Component {...props} />
        </RoutePermissionGuard>
      );
    };
  };
}

/**
 * Check if current route is accessible
 */
export async function checkRouteAccess(
  pathname: string,
  sessionData: AuthSessionData,
  routeConfig: RoutePermissionConfig
): Promise<boolean> {
  if (!sessionData) return false;

  try {
    const session = adaptSessionData(sessionData);
    const results = await permissionEngine.checkMultiplePermissions(
      session,
      routeConfig.permissions
    );

    return routeConfig.requireAllPermissions
      ? routeConfig.permissions.every(p => results[p]?.allowed)
      : routeConfig.permissions.some(p => results[p]?.allowed);
  } catch (error) {
    console.error('Route access check error:', error);
    return false;
  }
}
