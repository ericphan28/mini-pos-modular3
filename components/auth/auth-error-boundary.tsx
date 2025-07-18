'use client';

import React from 'react';

interface AuthErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

interface AuthErrorBoundaryProps {
  readonly children: React.ReactNode;
  readonly fallback?: React.ComponentType<{ error: Error; resetError: () => void }>;
}

export class AuthErrorBoundary extends React.Component<
  AuthErrorBoundaryProps,
  AuthErrorBoundaryState
> {
  constructor(props: AuthErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): AuthErrorBoundaryState {
    // Update state so the next render will show the fallback UI
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log error to console and any logging service
    console.error('AuthProvider Error:', error, errorInfo);
    
    // If we have business logger available, log there too
    try {
      if (typeof window !== 'undefined') {
        const globalWindow = window as { businessLogger?: { error: (type: string, message: string, data: object) => void } };
        if (globalWindow.businessLogger) {
          globalWindow.businessLogger.error('AUTH_PROVIDER_ERROR', 'AuthProvider crashed', {
            error: error.message,
            stack: error.stack,
            componentStack: errorInfo.componentStack,
          });
        }
      }
    } catch (logError) {
      // Ignore logging errors
      console.warn('Failed to log auth error:', logError);
    }
  }

  resetError = () => {
    this.setState({ hasError: false, error: undefined });
  };

  render() {
    if (this.state.hasError) {
      const { fallback: Fallback } = this.props;
      
      if (Fallback && this.state.error) {
        return <Fallback error={this.state.error} resetError={this.resetError} />;
      }

      // Default fallback UI
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-red-600 text-xl">⚠</span>
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                Lỗi xác thực
              </h2>
              <p className="text-gray-600 mb-6">
                Có lỗi xảy ra khi tải thông tin đăng nhập. Vui lòng thử lại.
              </p>
              <div className="space-y-3">
                <button
                  onClick={this.resetError}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
                >
                  Thử lại
                </button>
                <button
                  onClick={() => window.location.href = '/auth/login'}
                  className="w-full bg-gray-200 text-gray-800 py-2 px-4 rounded-md hover:bg-gray-300 transition-colors"
                >
                  Đăng nhập lại
                </button>
              </div>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
