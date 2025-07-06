'use client';

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createClient } from '@/lib/supabase/client';
import { AlertCircle, Clock, Eye, EyeOff, Lock, Shield, User } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface LoginError {
  type: 'validation' | 'auth' | 'network' | 'access' | 'unknown';
  message: string;
  suggestion?: string;
}

interface UserProfile {
  profile_exists?: boolean;
  profile?: {
    business_id?: string;
    role?: string;
    full_name?: string;
    [key: string]: unknown;
  };
  business?: {
    id?: string;
    name?: string;
    business_type?: string;
    [key: string]: unknown;
  };
  // Legacy fields for backward compatibility
  business_id?: string;
  business_name?: string;
  role?: string;
  full_name?: string;
  error?: string;
}

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<LoginError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [debugInfo, setDebugInfo] = useState<unknown>(null);
  const router = useRouter();

  // Safe logging that won't crash Turbopack
  const safeLog = (level: 'info' | 'warn' | 'error', message: string, data?: unknown) => {
    try {
      const timestamp = new Date().toISOString();
      const logMessage = `[${timestamp}] ${message}`;
      
      if (level === 'error') {
        // Don't use console.error in development - it crashes Turbopack
        if (process.env.NODE_ENV === 'production') {
          console.error(logMessage, data);
        } else {
          console.warn(`ERROR: ${logMessage}`, data);
        }
      } else if (level === 'warn') {
        console.warn(logMessage, data);
      } else {
        console.log(logMessage, data);
      }
    } catch (logError) {
      // Silent fail on logging errors
      console.warn('Logging error:', logError);
    }
  };

  // Professional error classification without crashing
  const classifyError = (error: unknown): LoginError => {
    setDebugInfo(error); // Store for debugging
    
    if (!error) {
      return {
        type: 'unknown',
        message: 'Có lỗi không xác định xảy ra',
        suggestion: 'Vui lòng thử lại.'
      };
    }

    // Handle string errors
    if (typeof error === 'string') {
      const errorLower = error.toLowerCase();
      
      if (errorLower.includes('invalid') || errorLower.includes('credentials')) {
        return {
          type: 'auth',
          message: 'Email hoặc mật khẩu không chính xác',
          suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập.'
        };
      }
      
      if (errorLower.includes('network') || errorLower.includes('connection')) {
        return {
          type: 'network',
          message: 'Lỗi kết nối mạng',
          suggestion: 'Vui lòng kiểm tra kết nối internet và thử lại.'
        };
      }
      
      return {
        type: 'unknown',
        message: error,
        suggestion: 'Vui lòng thử lại.'
      };
    }

    // Handle object errors
    if (typeof error === 'object' && error !== null) {
      const errorObj = error as Record<string, unknown>;
      
      const message = errorObj.message as string;
      const code = errorObj.code as string;
      
      if (message) {
        const messageLower = message.toLowerCase();
        
        if (messageLower.includes('invalid') || messageLower.includes('credentials')) {
          return {
            type: 'auth',
            message: 'Email hoặc mật khẩu không chính xác',
            suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập.'
          };
        }
        
        if (messageLower.includes('network') || messageLower.includes('fetch')) {
          return {
            type: 'network',
            message: 'Lỗi kết nối mạng',
            suggestion: 'Vui lòng kiểm tra kết nối internet và thử lại.'
          };
        }
        
        if (messageLower.includes('timeout')) {
          return {
            type: 'network',
            message: 'Timeout kết nối',
            suggestion: 'Vui lòng thử lại sau.'
          };
        }
      }
      
      if (code) {
        const codeLower = code.toLowerCase();
        
        if (codeLower.includes('invalid') || codeLower.includes('unauthorized')) {
          return {
            type: 'auth',
            message: 'Email hoặc mật khẩu không chính xác',
            suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập.'
          };
        }
      }

      // Try to get status code
      const status = errorObj.status as number;
      if (typeof status === 'number') {
        const errorCode = Math.floor(status);
        
        if (errorCode === 401 || errorCode === 403) {
          return {
            type: 'auth',
            message: 'Email hoặc mật khẩu không chính xác',
            suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập.'
          };
        }

        if (errorCode >= 500) {
          return {
            type: 'network',
            message: 'Lỗi máy chủ',
            suggestion: 'Vui lòng thử lại sau ít phút.'
          };
        }
      }
    }

    // Default safe error
    return {
      type: 'unknown',
      message: 'Có lỗi xảy ra khi đăng nhập',
      suggestion: 'Vui lòng thử lại. Nếu lỗi tiếp tục, hãy liên hệ hỗ trợ.'
    };
  };

  // Validate input before submission
  const validateInput = (): LoginError | null => {
    try {
      if (!email.trim()) {
        return {
          type: 'validation',
          message: 'Email không được trống'
        };
      }

      if (!email.includes('@') || !email.includes('.')) {
        return {
          type: 'validation',
          message: 'Email không hợp lệ'
        };
      }

      if (!password) {
        return {
          type: 'validation',
          message: 'Mật khẩu không được trống'
        };
      }

      if (password.length < 6) {
        return {
          type: 'validation',
          message: 'Mật khẩu phải có ít nhất 6 ký tự'
        };
      }
      
      return null;
    } catch (validationError) {
      console.warn('Validation error:', validationError);
      return {
        type: 'validation',
        message: 'Thông tin đăng nhập không hợp lệ'
      };
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Reset states safely
    setError(null);
    setIsLoading(true);
    setDebugInfo(null);

    try {
      // Validate input
      const validationError = validateInput();
      if (validationError) {
        setError(validationError);
        return;
      }

      safeLog('info', '🔐 [LOGIN-FORM] Starting login process...');
      const supabase = createClient();
      const emailTrimmed = email.trim().toLowerCase();

      // Step 1: Authenticate user with comprehensive error handling
      safeLog('info', '🔐 [LOGIN-FORM] Attempting authentication...');
      
      let authData: unknown = null;
      let authError: unknown = null;

      try {
        const result = await supabase.auth.signInWithPassword({
          email: emailTrimmed,
          password: password,
        });
        
        authData = result.data;
        authError = result.error;
        
        safeLog('info', '🔐 [LOGIN-FORM] Auth result received', {
          hasUser: !!(result.data?.user),
          hasError: !!result.error,
          errorMessage: result.error?.message
        });
      } catch (authException) {
        safeLog('error', '🔐 [LOGIN-FORM] Auth exception caught', authException);
        authError = authException;
      }

      // Handle authentication errors
      if (authError) {
        const loginError = classifyError(authError);
        safeLog('warn', '🔐 [LOGIN-FORM] Authentication failed', { 
          error: loginError,
          originalError: authError
        });
        setError(loginError);
        return;
      }

      // Extract user safely
      const user = (authData as { user?: { id: string; email?: string } })?.user;
      if (!user?.id) {
        safeLog('error', '🔐 [LOGIN-FORM] No user in auth result');
        setError({
          type: 'auth',
          message: 'Đăng nhập thất bại',
          suggestion: 'Vui lòng thử lại.'
        });
        return;
      }

      safeLog('info', '🔐 [LOGIN-FORM] User authenticated successfully', { 
        userId: user.id,
        email: user.email
      });

      // Step 2: Get user profile for business users
      safeLog('info', '🏪 [BUSINESS-LOGIN] Getting business user profile...');
      console.log('🏪 [BUSINESS-LOGIN] User ID:', user.id);
      console.log('🏪 [BUSINESS-LOGIN] User Email:', user.email);
      
      let profileData: UserProfile | null = null;
      let profileError: unknown = null;

      try {
        console.log('🏪 [BUSINESS-LOGIN] Calling RPC function...');
        const result = await supabase.rpc(
          'pos_mini_modular3_get_user_profile_safe',
          { p_user_id: user.id }
        ) as { data: UserProfile | null; error: unknown };
        
        profileData = result.data;
        profileError = result.error;
        
        console.log('🏪 [BUSINESS-LOGIN] RPC result:', result);
        console.log('🏪 [BUSINESS-LOGIN] Profile data:', profileData);
        console.log('🏪 [BUSINESS-LOGIN] Profile error:', profileError);
        
        // Debug: Log the entire structure
        if (profileData) {
          console.log('🔍 [DEBUG] ProfileData structure:', JSON.stringify(profileData, null, 2));
          console.log('🔍 [DEBUG] Profile object:', profileData.profile);
          console.log('🔍 [DEBUG] Business object:', profileData.business);
          console.log('🔍 [DEBUG] Legacy business_id:', profileData.business_id);
        }
        
        safeLog('info', '🏪 [BUSINESS-LOGIN] Profile result:', {
          hasProfile: !!profileData,
          profileExists: profileData?.profile_exists,
          businessId: profileData?.profile?.business_id || profileData?.business_id,
          businessName: profileData?.business?.name || profileData?.business_name,
          role: profileData?.profile?.role || profileData?.role,
          error: profileError
        });
      } catch (profileException) {
        safeLog('error', '🔐 [LOGIN-FORM] Profile fetch exception', profileException);
        profileError = profileException;
      }

      // Handle profile errors
      if (profileError) {
        safeLog('error', '🔐 [LOGIN-FORM] Profile fetch failed', profileError);
        setError({
          type: 'access',
          message: 'Không thể tải thông tin tài khoản',
          suggestion: 'Vui lòng thử lại sau.'
        });
        return;
      }

      // Check if profile exists
      if (!profileData?.profile_exists) {
        safeLog('info', '🔐 [LOGIN-FORM] No profile found - redirecting to signup');
        router.push('/auth/sign-up');
        return;
      }

      // Extract business info from new structure
      const businessId = profileData?.profile?.business_id || profileData?.business_id;
      const businessName = profileData?.business?.name || profileData?.business_name;
      const userRole = profileData?.profile?.role || profileData?.role;

      // Check if user has business access
      if (!businessId) {
        safeLog('info', '🔐 [LOGIN-FORM] No business found - redirecting to business signup');
        router.push('/auth/sign-up?step=business');
        return;
      }

      // Step 4: Successful login - redirect to dashboard
      safeLog('info', '🔐 [LOGIN-FORM] Login successful - redirecting to dashboard', {
        businessId: businessId,
        businessName: businessName,
        role: userRole
      });
      
      router.push('/dashboard');

    } catch (error) {
      safeLog('error', '🔐 [LOGIN-FORM] Unexpected error in login process', error);
      const loginError = classifyError(error);
      setError(loginError);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader className="text-center">
        <CardTitle className="text-2xl font-bold">Đăng nhập</CardTitle>
        <CardDescription>
          Đăng nhập vào tài khoản của bạn để tiếp tục
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleLogin} className="space-y-4">
            {error && (
              <Alert variant="destructive" className="border-red-200 bg-red-50">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  <div className="space-y-1">
                    <p className="font-medium">{error.message}</p>
                    {error.suggestion && (
                      <p className="text-sm opacity-90">{error.suggestion}</p>
                    )}
                  </div>
                </AlertDescription>
              </Alert>
            )}

            <div className="space-y-2">
              <Label htmlFor="email" className="text-sm font-medium text-slate-700">
                Email
              </Label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-slate-400" />
                <Input
                  id="email"
                  type="email"
                  placeholder="your@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={isLoading}
                  className="pl-10 border-slate-300 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium text-slate-700">
                Mật khẩu
              </Label>
              <div className="relative">
                <Lock className="absolute left-3 top-3 h-4 w-4 text-slate-400" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isLoading}
                  className="pl-10 pr-10 border-slate-300 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-3 h-4 w-4 text-slate-400 hover:text-slate-600 transition-colors"
                  disabled={isLoading}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <Link 
                href="/auth/forgot-password" 
                className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors"
              >
                Quên mật khẩu?
              </Link>
              <Link 
                href="/auth/sign-up" 
                className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors"
              >
                Tạo tài khoản mới
              </Link>
            </div>

            <Button 
              type="submit" 
              className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium py-2.5 transition-all duration-200 shadow-lg hover:shadow-xl" 
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <Clock className="mr-2 h-4 w-4 animate-spin" />
                  Đang đăng nhập...
                </>
              ) : (
                <>
                  <Shield className="mr-2 h-4 w-4" />
                  Đăng nhập
                </>
              )}
            </Button>
          </form>

          <div className="mt-8 pt-6 border-t border-slate-200">
            <p className="text-center text-sm text-slate-600">
              Bạn là quản trị viên hệ thống?{' '}
              <Link href="/admin-login" className="text-blue-600 hover:text-blue-700 font-medium transition-colors">
                Đăng nhập Admin
              </Link>
            </p>
          </div>

          {/* Debug info for development */}
          {process.env.NODE_ENV === 'development' && debugInfo ? (
            <details className="mt-4 p-3 bg-slate-50 rounded-lg text-xs border border-slate-200">
              <summary className="cursor-pointer text-slate-600 font-medium">
                Debug Info (Development Only)
              </summary>
              <pre className="mt-2 text-xs text-slate-500 overflow-auto">
                {typeof debugInfo === 'string' 
                  ? debugInfo 
                  : typeof debugInfo === 'object' && debugInfo !== null
                    ? JSON.stringify(debugInfo, null, 2)
                    : String(debugInfo)
                }
              </pre>
            </details>
          ) : null}
        </CardContent>
      </Card>
  );
}
