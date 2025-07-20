'use client';

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createClient } from '@/lib/supabase/client';
import { optimizedLogger } from '@/lib/utils/optimized-logger';
import { SessionCacheManager, type CompleteUserSession } from '@/lib/utils/session-cache';
import { authLogger, setLoggerContext } from '@/lib/logger';
import { AlertCircle, AlertTriangle, CheckCircle, Clock, Eye, EyeOff, Lock, Shield, User, XCircle } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface LoginError {
  type: 'validation' | 'auth' | 'network' | 'access' | 'unknown';
  message: string;
  suggestion?: string;
  actionText?: string;
  actionHref?: string;
}

interface LoginStep {
  id: string;
  name: string;
  status: 'pending' | 'processing' | 'completed' | 'error';
  details?: string;
}

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<LoginError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [debugInfo, setDebugInfo] = useState<unknown>(null);
  const [currentStep, setCurrentStep] = useState<string>('');
  const [loginSteps, setLoginSteps] = useState<LoginStep[]>([]);
  const router = useRouter();

  // Quản lý các bước đăng nhập
  const initializeSteps = (): void => {
    const steps: LoginStep[] = [
      { id: 'validation', name: 'Kiểm tra thông tin đầu vào', status: 'pending' },
      { id: 'auth', name: 'Xác thực tài khoản', status: 'pending' },
      { id: 'profile', name: 'Tải thông tin người dùng', status: 'pending' },
      { id: 'business', name: 'Kiểm tra doanh nghiệp', status: 'pending' },
      { id: 'permissions', name: 'Tải quyền truy cập (Permission System v2.0)', status: 'pending' },
      { id: 'redirect', name: 'Chuyển hướng', status: 'pending' }
    ];
    setLoginSteps(steps);
    optimizedLogger.info('LOGIN_INIT', 'Khởi tạo quy trình đăng nhập với permissions', { 
      steps: steps.length,
      permissionSystemEnabled: true,
      version: '2.0'
    });
  };

  const updateStep = (stepId: string, status: LoginStep['status'], details?: string): void => {
    setLoginSteps(prev => prev.map(step => 
      step.id === stepId 
        ? { ...step, status, details }
        : step
    ));
    setCurrentStep(stepId);
    
    if (status === 'processing') {
      optimizedLogger.info('LOGIN_STEP', `🔄 ${stepId} ${details || 'Đang xử lý'}`, { 
        step: stepId, 
        action: 'processing',
        permissionSystemActive: stepId === 'permissions'
      });
    } else if (status === 'completed') {
      optimizedLogger.success('LOGIN_STEP', `✅ ${stepId} ${details || 'Hoàn thành'}`, {
        step: stepId,
        action: 'completed',
        permissionSystemActive: stepId === 'permissions'
      });
    } else if (status === 'error') {
      optimizedLogger.error('LOGIN_STEP', `❌ ${stepId} ${details || 'Có lỗi xảy ra'}`, {
        step: stepId,
        action: 'error',
        details
      });
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

    // Khởi tạo các bước đăng nhập
    initializeSteps();

    // Set initial logger context với IP và User Agent
    const userAgent = typeof navigator !== 'undefined' ? navigator.userAgent : 'Unknown';
    const ipAddress = '192.168.1.1'; // TODO: Get real IP from request
    
    setLoggerContext({
      ip_address: ipAddress,
      user_agent: userAgent,
      request_id: `login_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    });

    try {
      // Step 1: Validate input
      updateStep('validation', 'processing', 'Kiểm tra email và mật khẩu');
      const validationError = validateInput();
      if (validationError) {
        updateStep('validation', 'error', validationError.message);
        setError(validationError);
        
        // Log validation failure
        await authLogger.loginFailed({
          reason: 'Validation failed',
          email: email.includes('@') ? email : undefined,
          phone: !email.includes('@') ? email : undefined,
          ip_address: ipAddress,
          user_agent: userAgent,
          error_code: 'VALIDATION_ERROR'
        });
        
        return;
      }
      updateStep('validation', 'completed', 'Thông tin hợp lệ');

      optimizedLogger.info('LOGIN-FORM', 'Bắt đầu quá trình đăng nhập');
      const supabase = createClient();
      const emailTrimmed = email.trim().toLowerCase();

      // Log login attempt
      await authLogger.loginAttempt({
        email: emailTrimmed.includes('@') ? emailTrimmed : undefined,
        phone: !emailTrimmed.includes('@') ? emailTrimmed : undefined,
        method: emailTrimmed.includes('@') ? 'email' : 'phone',
        ip_address: ipAddress,
        user_agent: userAgent
      });

      // Step 2: Authenticate user
      updateStep('auth', 'processing', 'Đang xác thực với Supabase');
      optimizedLogger.info('AUTH', 'Gửi yêu cầu xác thực', { email: emailTrimmed });
      
      let authData: unknown = null;
      let authError: unknown = null;

      try {
        const result = await supabase.auth.signInWithPassword({
          email: emailTrimmed,
          password: password,
        });
        
        authData = result.data;
        authError = result.error;
        
        optimizedLogger.debug('AUTH', 'Nhận kết quả xác thực', {
          hasUser: !!(result.data?.user),
          hasError: !!result.error,
          errorMessage: result.error?.message
        });
      } catch (authException) {
        optimizedLogger.error('AUTH', 'Exception trong quá trình xác thực', authException);
        authError = authException;
      }

      // Handle authentication errors
      if (authError) {
        updateStep('auth', 'error', 'Xác thực thất bại');
        const loginError = classifyError(authError);
        optimizedLogger.warn('AUTH', 'Xác thực thất bại', { 
          error: loginError,
          originalError: authError
        });
        
        // Log login failure với professional logger
        await authLogger.loginFailed({
          reason: loginError.message,
          email: emailTrimmed.includes('@') ? emailTrimmed : undefined,
          phone: !emailTrimmed.includes('@') ? emailTrimmed : undefined,
          ip_address: ipAddress,
          user_agent: userAgent,
          error_code: 'AUTH_FAILED'
        });
        
        setError(loginError);
        return;
      }

      // Extract user safely
      const user = (authData as { user?: { id: string; email?: string; user_metadata?: Record<string, unknown> } })?.user;
      if (!user?.id) {
        updateStep('auth', 'error', 'Không có thông tin người dùng');
        optimizedLogger.error('AUTH', 'Không có user trong kết quả auth');
        
        await authLogger.loginFailed({
          reason: 'No user data returned',
          email: emailTrimmed.includes('@') ? emailTrimmed : undefined,
          phone: !emailTrimmed.includes('@') ? emailTrimmed : undefined,
          ip_address: ipAddress,
          user_agent: userAgent,
          error_code: 'NO_USER_DATA'
        });
        
        setError({
          type: 'auth',
          message: 'Đăng nhập thất bại',
          suggestion: 'Vui lòng thử lại.'
        });
        return;
      }

      updateStep('auth', 'completed', `Đã xác thực: ${user.email}`);
      optimizedLogger.success('AUTH', 'Xác thực thành công', { 
        userId: user.id,
        email: user.email
      });

      // Step 3: Get user profile
      updateStep('profile', 'processing', 'Đang tải thông tin người dùng');
      optimizedLogger.info('PROFILE', 'Bắt đầu tải profile người dùng');
      
      // First, let's check if the function exists
      try {
        optimizedLogger.debug('PROFILE', 'Kiểm tra function enhanced auth');
        const functionCheckResult = await supabase.rpc('pos_mini_modular3_get_user_with_business_complete', { p_user_id: user.id });
        optimizedLogger.debug('PROFILE', 'Kết quả kiểm tra function', functionCheckResult);
      } catch (functionCheckError) {
        updateStep('profile', 'error', 'Function enhanced auth không tồn tại');
        optimizedLogger.error('PROFILE', 'Enhanced auth function check failed', functionCheckError);
        
        // Fallback to basic profile check
        updateStep('profile', 'processing', 'Fallback: kiểm tra profile cơ bản');
        optimizedLogger.info('PROFILE', 'Chuyển sang kiểm tra profile cơ bản');
        try {
          const profileCheck = await supabase
            .from('pos_mini_modular3_user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
          
          optimizedLogger.debug('PROFILE', 'Kết quả kiểm tra profile cơ bản', profileCheck);
          
          if (profileCheck.error) {
            optimizedLogger.error('PROFILE', 'Không tìm thấy profile', profileCheck.error);
            
            // If no profile exists, try to create one automatically
            if (profileCheck.error.code === 'PGRST116') {
              updateStep('profile', 'processing', 'Tạo profile tự động');
              optimizedLogger.info('PROFILE', 'Không có profile - thử tạo tự động');
              
              try {
                // Create basic profile for the user
                const createProfileResult = await supabase
                  .from('pos_mini_modular3_user_profiles')
                  .insert({
                    id: user.id,
                    email: user.email || emailTrimmed,
                    full_name: user.email?.split('@')[0] || 'User',
                    role: 'staff', // Default role
                    status: 'active',
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString()
                  });
                
                optimizedLogger.debug('PROFILE', 'Kết quả tạo profile', createProfileResult);
                
                if (createProfileResult.error) {
                  optimizedLogger.error('PROFILE', 'Không thể tạo profile tự động', createProfileResult.error);
                  updateStep('profile', 'error', 'Không thể tạo profile - chuyển hướng signup');
                  router.push('/auth/sign-up');
                  return;
                } else {
                  updateStep('profile', 'completed', 'Đã tạo profile thành công');
                  optimizedLogger.success('PROFILE', 'Tạo profile thành công - tiếp tục login');
                }
              } catch (createError) {
                optimizedLogger.error('PROFILE', 'Exception khi tạo profile', createError);
                updateStep('profile', 'error', 'Lỗi khi tạo profile - chuyển hướng signup');
                router.push('/auth/sign-up');
                return;
              }
            }
          } else {
            updateStep('profile', 'completed', 'Tìm thấy profile cơ bản');
          }
          
          // Continue with simple redirect after profile check/creation
          updateStep('business', 'completed', 'Bỏ qua kiểm tra business (fallback)');
          updateStep('permissions', 'completed', '⚠️ Permission System: Fallback mode (no permissions loaded)');
          updateStep('redirect', 'processing', 'Chuyển hướng dashboard');
          optimizedLogger.warn('PERMISSIONS_FALLBACK', 'Permission system using fallback mode - no permissions loaded');
          optimizedLogger.success('PROFILE', 'Profile OK, chuyển hướng dashboard');
          optimizedLogger.success('LOGIN', 'Đăng nhập thành công (fallback mode)');
          router.push('/dashboard');
          return;
          
        } catch (fallbackError) {
          optimizedLogger.error('PROFILE', 'Fallback profile check cũng thất bại', fallbackError);
        }
        
        // Ultimate fallback - just redirect to dashboard
        updateStep('profile', 'completed', 'Ultimate fallback');
        updateStep('business', 'completed', 'Bỏ qua tất cả kiểm tra');
        updateStep('permissions', 'completed', '🚨 Permission System: Emergency fallback (bypassed)');
        updateStep('redirect', 'processing', 'Chuyển hướng dashboard (fallback)');
        optimizedLogger.error('PERMISSIONS_EMERGENCY', 'Permission system emergency fallback - all checks bypassed');
        optimizedLogger.warn('PROFILE', 'Ultimate fallback - chuyển hướng dashboard');
        router.push('/dashboard');
        return;
      }
      
      let profileData: unknown = null;
      let profileError: unknown = null;

      try {
        optimizedLogger.info('PROFILE', 'Gọi enhanced RPC function');
        const result = await supabase.rpc(
          'pos_mini_modular3_get_user_with_business_complete',
          { p_user_id: user.id }
        ) as { data: unknown; error: unknown };
        
        profileData = result.data;
        profileError = result.error;
        
        optimizedLogger.debug('PROFILE', 'Enhanced RPC result', result);
        optimizedLogger.debug('PROFILE', 'Enhanced profile data', profileData);
        optimizedLogger.debug('PROFILE', 'Enhanced profile error', profileError);
        
        // Debug: Log the entire structure
        if (profileData && typeof profileData === 'object') {
          optimizedLogger.debug('PROFILE', 'ProfileData structure', JSON.stringify(profileData, null, 2));
        }
        
        optimizedLogger.info('PROFILE', 'Enhanced profile result', {
          hasProfile: !!profileData,
          success: (profileData as { success?: boolean })?.success,
          profileExists: (profileData as { profile_exists?: boolean })?.profile_exists,
          error: profileError
        });
      } catch (profileException) {
        optimizedLogger.error('PROFILE', 'Profile fetch exception', profileException);
        profileError = profileException;
      }

      // Handle profile errors
      if (profileError) {
        updateStep('profile', 'error', 'Lỗi khi tải profile');
        optimizedLogger.error('PROFILE', 'Profile fetch failed', profileError);
        setError({
          type: 'access',
          message: 'Không thể tải thông tin tài khoản',
          suggestion: 'Vui lòng thử lại sau.'
        });
        return;
      }

      // Handle profile data
      if (!profileData || typeof profileData !== 'object') {
        updateStep('profile', 'error', 'Dữ liệu profile không hợp lệ');
        optimizedLogger.error('PROFILE', 'Invalid profile data format');
        setError({
          type: 'access',
          message: 'Dữ liệu tài khoản không hợp lệ',
          suggestion: 'Vui lòng thử lại sau.'
        });
        return;
      }

      const profile = profileData as Record<string, unknown>;

      // Check if the request was successful
      if (!profile.success) {
        const errorCode = profile.error as string;
        const errorMessage = profile.message as string;
        
        updateStep('profile', 'error', `${errorCode}: ${errorMessage}`);
        optimizedLogger.warn('PROFILE', 'Profile request failed', { 
          error: errorCode, 
          message: errorMessage 
        });

        // Handle specific error cases with better user experience
        switch (errorCode) {
          case 'USER_PROFILE_NOT_FOUND':
            optimizedLogger.info('PROFILE', 'Profile không tồn tại - thử tạo tự động');
            
            // Try to create profile automatically
            try {
              updateStep('profile', 'processing', 'Tạo profile tự động');
              
              const createProfileResult = await supabase
                .from('pos_mini_modular3_user_profiles')
                .insert({
                  id: user.id,
                  email: user.email || emailTrimmed,
                  full_name: user.email?.split('@')[0] || 'User',
                  role: 'staff',
                  status: 'active',
                  created_at: new Date().toISOString(),
                  updated_at: new Date().toISOString()
                });
              
              if (createProfileResult.error) {
                optimizedLogger.error('PROFILE', 'Không thể tạo profile tự động', createProfileResult.error);
                setError({
                  type: 'access',
                  message: 'Tài khoản chưa được thiết lập đầy đủ',
                  suggestion: 'Không thể tạo profile tự động. Vui lòng hoàn tất quá trình đăng ký.',
                  actionText: 'Tạo Profile',
                  actionHref: '/auth/sign-up'
                });
                return;
              } else {
                optimizedLogger.success('PROFILE', 'Tạo profile thành công - tiếp tục login');
                updateStep('profile', 'completed', 'Đã tạo profile thành công');
                // Continue with basic redirect
                updateStep('business', 'completed', 'Profile mới tạo - skip business check');
                updateStep('permissions', 'completed', 'Profile mới tạo - role staff');
                updateStep('redirect', 'processing', 'Chuyển hướng dashboard');
                optimizedLogger.success('LOGIN', 'Đăng nhập thành công với profile mới');
                router.push('/dashboard');
                return;
              }
            } catch (createError) {
              optimizedLogger.error('PROFILE', 'Exception khi tạo profile', createError);
              setError({
                type: 'access',
                message: 'Không thể tạo profile tự động',
                suggestion: 'Vui lòng hoàn tất quá trình đăng ký.',
                actionText: 'Tạo Profile',
                actionHref: '/auth/sign-up'
              });
              return;
            }
            
          case 'NO_BUSINESS_ASSIGNED':
            updateStep('business', 'error', 'Chưa được gán doanh nghiệp');
            optimizedLogger.info('BUSINESS', 'Không có business được gán');
            setError({
              type: 'access',
              message: 'Tài khoản chưa được gán vào doanh nghiệp',
              suggestion: 'Vui lòng liên hệ quản trị viên để được gán vào doanh nghiệp.'
            });
            return;
            
          case 'BUSINESS_NOT_FOUND_OR_INACTIVE':
            updateStep('business', 'error', 'Doanh nghiệp không hoạt động');
            setError({
              type: 'access',
              message: 'Doanh nghiệp không tồn tại hoặc đã bị khóa',
              suggestion: 'Vui lòng liên hệ quản trị viên.'
            });
            return;
            
          case 'SUBSCRIPTION_INACTIVE':
            updateStep('business', 'error', 'Subscription hết hạn');
            setError({
              type: 'access',
              message: 'Gói dịch vụ đã hết hạn hoặc bị tạm dừng',
              suggestion: 'Vui lòng gia hạn gói dịch vụ để tiếp tục sử dụng.'
            });
            return;
            
          case 'TRIAL_EXPIRED':
            updateStep('business', 'error', 'Trial đã hết hạn');
            setError({
              type: 'access',
              message: 'Thời gian dùng thử đã hết hạn',
              suggestion: 'Vui lòng nâng cấp lên gói trả phí để tiếp tục sử dụng.'
            });
            return;
            
          default:
            setError({
              type: 'access',
              message: errorMessage || 'Có lỗi xảy ra khi đăng nhập',
              suggestion: 'Vui lòng thử lại sau.'
            });
            return;
        }
      }

      updateStep('profile', 'completed', 'Profile loaded thành công');

      // Extract user and business info from enhanced structure
      const userObj = profile.user as Record<string, unknown>;
      const businessObj = profile.business as Record<string, unknown>;
      const permissionsObj = profile.permissions as Record<string, unknown>;

      const businessId = businessObj?.id as string;
      const businessName = businessObj?.name as string;
      const userRole = userObj?.role as string;
      const subscriptionStatus = businessObj?.subscription_status as string;
      const subscriptionTier = businessObj?.subscription_tier as string; // Fix: Get actual subscription tier

      updateStep('business', 'completed', `Business: ${businessName} (${subscriptionStatus})`);
      
      // Count actual permissions correctly (not just features)
      const totalPermissions = Object.values(permissionsObj || {}).reduce((count: number, perms) => {
        const permissions = perms as { can_read?: boolean; can_write?: boolean; can_delete?: boolean; can_manage?: boolean };
        let featurePermCount = 0;
        if (permissions.can_read) featurePermCount++;
        if (permissions.can_write) featurePermCount++;
        if (permissions.can_delete) featurePermCount++;
        if (permissions.can_manage) featurePermCount++;
        return count + featurePermCount;
      }, 0);
      
      const featureCount = Object.keys(permissionsObj || {}).length;
      
      updateStep('permissions', 'completed', `🔐 Permission System v2.0: Role ${userRole} (${totalPermissions} permissions from ${featureCount} features loaded)`);

      // Log detailed permission info
      optimizedLogger.success('PERMISSIONS_LOADED', 'Permission system successfully loaded user permissions', {
        userRole,
        featureCount: featureCount,
        permissionCount: totalPermissions, // Fix: Use actual permission count
        businessId: businessId,
        subscriptionTier: subscriptionTier, // Fix: Use actual subscription tier, not status
        subscriptionStatus: subscriptionStatus, // Add subscription status for clarity
        permissionSystemVersion: '2.0'
      });

      // **TÍCH HỢP SESSION CACHE** - Cache session sau khi đăng nhập thành công
      try {
        // Tạo complete session object từ enhanced profile data theo đúng interface
        const completeSession: CompleteUserSession = {
          success: true,
          profile_exists: true,
          user: {
            id: user.id,
            profile_id: user.id, // Same as user ID
            email: user.email || emailTrimmed,
            role: userRole || 'staff',
            full_name: (userObj?.full_name as string) || user.email?.split('@')[0] || 'User',
            phone: (userObj?.phone as string) || null,
            login_method: emailTrimmed.includes('@') ? 'email' : 'phone',
            status: (userObj?.status as string) || 'active'
          },
          business: {
            id: businessId,
            name: businessName || 'Unknown Business',
            business_type: (businessObj?.business_type as string) || 'unknown',
            business_type_name: (businessObj?.business_type_name as string) || 'Unknown Type',
            business_code: (businessObj?.business_code as string) || '',
            contact_email: (businessObj?.contact_email as string) || null,
            contact_phone: (businessObj?.contact_phone as string) || null,
            address: (businessObj?.address as string) || null,
            subscription_tier: (businessObj?.subscription_tier as string) || 'basic',
            subscription_status: subscriptionStatus || 'unknown',
            trial_end_date: (businessObj?.trial_end_date as string) || null,
            features_enabled: (businessObj?.features_enabled as Record<string, unknown>) || {},
            usage_stats: (businessObj?.usage_stats as Record<string, unknown>) || {},
            status: (businessObj?.status as string) || 'active'
          },
          permissions: permissionsObj as Record<string, unknown> || {},
          session_info: {
            login_time: new Date().toISOString(),
            user_agent: userAgent
          }
        };

        // Cache session 
        SessionCacheManager.cacheSession(completeSession);
        optimizedLogger.success('CACHE', 'Session được cache thành công', {
          userId: user.id,
          businessId,
          loginTime: completeSession.session_info.login_time
        });
      } catch (cacheError) {
        // Cache error không làm crash login flow
        optimizedLogger.warn('CACHE', 'Không thể cache session, tiếp tục đăng nhập bình thường', cacheError);
      }

      // Step 4: Successful login - redirect to dashboard
      updateStep('redirect', 'processing', 'Chuyển hướng tới dashboard');
      optimizedLogger.success('LOGIN', 'Đăng nhập thành công - chuyển hướng dashboard', {
        businessId,
        businessName,
        role: userRole,
        subscriptionStatus,
        permissionsCount: Object.keys(permissionsObj || {}).length,
        sessionCached: true
      });
      
      // Log successful login với professional logger
      const sessionId = (authData as { session?: { access_token: string } })?.session?.access_token || '';
      
      await authLogger.loginSuccess({
        user_id: user.id,
        email: user.email,
        business_id: businessId,
        role: userRole || 'unknown',
        login_method: emailTrimmed.includes('@') ? 'email' : 'phone',
        is_first_login: false // TODO: Determine if first login
      }, {
        session_id: sessionId,
        ip_address: ipAddress,
        user_agent: userAgent,
        expires_at: (authData as { session?: { expires_at?: string } })?.session?.expires_at
      });
      
      router.push('/dashboard');

    } catch (error) {
      updateStep(currentStep || 'unknown', 'error', 'Lỗi không mong muốn');
      optimizedLogger.error('LOGIN_ERROR', 'Lỗi đăng nhập', {
        step: currentStep,
        permissionSystemActive: true,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
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
            {/* Login Steps Progress (chỉ hiện khi đang loading) */}
            {isLoading && loginSteps.length > 0 && (
              <div className="bg-slate-50 p-4 rounded-lg border">
                <h4 className="text-sm font-medium text-slate-700 mb-3">Tiến trình đăng nhập:</h4>
                <div className="space-y-2">
                  {loginSteps.map((step) => (
                    <div key={step.id} className="flex items-center gap-2 text-sm">
                      {step.status === 'pending' && (
                        <div className="w-4 h-4 rounded-full border-2 border-slate-300"></div>
                      )}
                      {step.status === 'processing' && (
                        <div className="w-4 h-4 rounded-full border-2 border-blue-500 border-t-transparent animate-spin"></div>
                      )}
                      {step.status === 'completed' && (
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      )}
                      {step.status === 'error' && (
                        <XCircle className="w-4 h-4 text-red-500" />
                      )}
                      <span className={`${
                        step.status === 'completed' ? 'text-green-700' :
                        step.status === 'error' ? 'text-red-700' :
                        step.status === 'processing' ? 'text-blue-700 font-medium' :
                        'text-slate-500'
                      }`}>
                        {step.name}
                      </span>
                      {step.details && (
                        <span className="text-xs text-slate-500 ml-1">
                          ({step.details})
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {error && (
              <Alert variant="destructive" className="border-red-200 bg-red-50">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  <div className="space-y-2">
                    <p className="font-medium">{error.message}</p>
                    {error.suggestion && (
                      <p className="text-sm opacity-90">{error.suggestion}</p>
                    )}
                    {error.actionText && error.actionHref && (
                      <div className="pt-1">
                        <Link 
                          href={error.actionHref}
                          className="inline-flex items-center gap-1 text-sm bg-red-100 hover:bg-red-200 text-red-700 px-3 py-1 rounded-md transition-colors"
                        >
                          <AlertTriangle className="w-3 h-3" />
                          {error.actionText}
                        </Link>
                      </div>
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

          {/* Enhanced Debug info for development */}
          {process.env.NODE_ENV === 'development' ? (
            <div className="mt-4 space-y-2">
              {/* Step by step progress for debugging */}
              {loginSteps.length > 0 ? (
                <details className="p-3 bg-blue-50 rounded-lg text-xs border border-blue-200">
                  <summary className="cursor-pointer text-blue-700 font-medium">
                    🔍 Login Steps Debug (Development)
                  </summary>
                  <div className="mt-2 space-y-1">
                    {loginSteps.map((step, index) => (
                      <div key={step.id} className="text-xs">
                        <span className="font-mono">
                          {index + 1}. {step.name}: 
                        </span>
                        <span className={`ml-1 ${
                          step.status === 'completed' ? 'text-green-600' :
                          step.status === 'error' ? 'text-red-600' :
                          step.status === 'processing' ? 'text-blue-600' :
                          'text-slate-500'
                        }`}>
                          {step.status}
                        </span>
                        {step.details ? (
                          <div className="text-slate-500 ml-4 text-xs">
                            {step.details}
                          </div>
                        ) : null}
                      </div>
                    ))}
                  </div>
                </details>
              ) : null}

              {/* Error debug info */}
              {debugInfo ? (
                <details className="p-3 bg-slate-50 rounded-lg text-xs border border-slate-200">
                  <summary className="cursor-pointer text-slate-600 font-medium">
                    🐛 Error Debug Info (Development Only)
                  </summary>
                  <pre className="mt-2 text-xs text-slate-500 overflow-auto max-h-32">
                    {typeof debugInfo === 'string' 
                      ? debugInfo 
                      : typeof debugInfo === 'object' && debugInfo !== null
                        ? JSON.stringify(debugInfo, null, 2)
                        : String(debugInfo)
                    }
                  </pre>
                </details>
              ) : null}

              {/* Console log hint */}
              <div className="p-2 bg-green-50 rounded text-xs text-green-700 border border-green-200">
                💡 <strong>Debug Tip:</strong> Mở Console (F12) để xem chi tiết log màu sắc của quá trình đăng nhập
              </div>
            </div>
          ) : null}
        </CardContent>
      </Card>
  );
}
