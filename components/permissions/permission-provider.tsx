// ==================================================================================
// HIGH-LEVEL PERMISSION PROVIDER
// ==================================================================================
// Provides permission context and manages permission state at application level

'use client';

import React, { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from 'react';
import { useAuth } from '@/lib/auth/auth-context';
import { permissionEngine } from '@/lib/permissions/permission-engine';
import { PERMISSION_CONFIG } from '@/lib/permissions/permission-config';
import { adaptSessionData } from '@/lib/permissions/session-adapter';

// ==================================================================================
// PERMISSION PROVIDER CONTEXT
// ==================================================================================

interface PermissionProviderContext {
  readonly isReady: boolean;
  readonly hasError: boolean;
  readonly errorMessage?: string;
  readonly permissionVersion: string;
  readonly lastUpdated: string;
  readonly refresh: () => Promise<void>;
}

const PermissionContext = createContext<PermissionProviderContext | null>(null);

// ==================================================================================
// PERMISSION PROVIDER COMPONENT
// ==================================================================================

interface PermissionProviderProps {
  readonly children: ReactNode;
  readonly fallback?: ReactNode;
  readonly errorFallback?: ReactNode;
}

export function PermissionProvider({ children, fallback, errorFallback }: PermissionProviderProps) {
  const { isAuthenticated, sessionData, isLoading } = useAuth();
  const [isReady, setIsReady] = useState(false);
  const [hasError, setHasError] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string>();

  // Initialize permission system
  const initializePermissionSystem = useCallback(async (): Promise<void> => {
    try {
      setHasError(false);
      setErrorMessage(undefined);

      // Ensure permission engine is initialized
      if (!permissionEngine) {
        throw new Error('Permission engine not available');
      }

      // Initialize with configuration
      permissionEngine.initialize(PERMISSION_CONFIG);

      // Test permission system with a basic check
      if (sessionData) {
        // Convert auth session to permission session format
        const permissionSession = adaptSessionData(sessionData);
        
        // This will validate the session compatibility
        const testResult = await permissionEngine.checkPermission(
          permissionSession,
          'access_pos' // Basic permission that should exist
        );
        
        console.log('🔒 [PERMISSION PROVIDER] System test result:', testResult);
      }

      setIsReady(true);
      console.log('🔒 [PERMISSION PROVIDER] System initialized successfully');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Permission system initialization failed';
      console.error('🔒 [PERMISSION PROVIDER] Initialization error:', error);
      setHasError(true);
      setErrorMessage(message);
      setIsReady(false);
    }
  }, [sessionData]);

  useEffect(() => {
    if (!isAuthenticated || !sessionData || isLoading) {
      setIsReady(false);
      return;
    }

    initializePermissionSystem();
  }, [isAuthenticated, sessionData, isLoading, initializePermissionSystem]);

  const refresh = async (): Promise<void> => {
    if (sessionData) {
      await initializePermissionSystem();
    }
  };

  const contextValue: PermissionProviderContext = {
    isReady,
    hasError,
    errorMessage,
    permissionVersion: PERMISSION_CONFIG.version,
    lastUpdated: PERMISSION_CONFIG.lastUpdated,
    refresh
  };

  // Show loading state
  if (isLoading || (!isReady && !hasError && isAuthenticated)) {
    return (
      <PermissionContext.Provider value={contextValue}>
        {fallback || <PermissionLoadingFallback />}
      </PermissionContext.Provider>
    );
  }

  // Show error state
  if (hasError) {
    return (
      <PermissionContext.Provider value={contextValue}>
        {errorFallback || <PermissionErrorFallback error={errorMessage} onRetry={refresh} />}
      </PermissionContext.Provider>
    );
  }

  // Normal render
  return (
    <PermissionContext.Provider value={contextValue}>
      {children}
    </PermissionContext.Provider>
  );
}

// ==================================================================================
// PERMISSION PROVIDER HOOK
// ==================================================================================

export function usePermissionProvider(): PermissionProviderContext {
  const context = useContext(PermissionContext);
  if (!context) {
    throw new Error('usePermissionProvider must be used within a PermissionProvider');
  }
  return context;
}

// ==================================================================================
// DEFAULT FALLBACK COMPONENTS
// ==================================================================================

function PermissionLoadingFallback() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          Đang khởi tạo hệ thống quyền
        </h3>
        <p className="text-sm text-gray-600">
          Vui lòng chờ trong giây lát...
        </p>
      </div>
    </div>
  );
}

interface PermissionErrorFallbackProps {
  readonly error?: string;
  readonly onRetry: () => Promise<void>;
}

function PermissionErrorFallback({ error, onRetry }: PermissionErrorFallbackProps) {
  const [isRetrying, setIsRetrying] = useState(false);

  const handleRetry = async (): Promise<void> => {
    setIsRetrying(true);
    try {
      await onRetry();
    } finally {
      setIsRetrying(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
        <div className="text-center">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
            <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            Lỗi khởi tạo hệ thống quyền
          </h3>
          <p className="text-sm text-gray-600 mb-4">
            {error || 'Có lỗi xảy ra khi khởi tạo hệ thống quyền'}
          </p>
          <div className="space-y-3">
            <button
              onClick={handleRetry}
              disabled={isRetrying}
              className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isRetrying ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Đang thử lại...
                </>
              ) : (
                'Thử lại'
              )}
            </button>
            <button
              onClick={() => window.location.reload()}
              className="w-full inline-flex justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Tải lại trang
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ==================================================================================
// PERMISSION BOUNDARY COMPONENT
// ==================================================================================

interface PermissionBoundaryProps {
  readonly children: ReactNode;
  readonly fallback?: ReactNode;
}

/**
 * Error boundary specifically for permission-related errors
 */
export function PermissionBoundary({ children, fallback }: PermissionBoundaryProps) {
  const [hasError, setHasError] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const handleError = (event: ErrorEvent) => {
      if (event.error?.message?.includes('permission')) {
        setHasError(true);
        setError(event.error);
        event.preventDefault();
      }
    };

    window.addEventListener('error', handleError);
    return () => window.removeEventListener('error', handleError);
  }, []);

  if (hasError) {
    return fallback || (
      <div className="p-4 bg-red-50 border border-red-200 rounded-md">
        <div className="text-red-800">
          <h4 className="font-medium mb-2">Permission Error</h4>
          <p className="text-sm">{error?.message || 'An permission-related error occurred'}</p>
          <button
            onClick={() => setHasError(false)}
            className="mt-2 text-xs text-red-600 hover:text-red-800 underline"
          >
            Try again
          </button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
