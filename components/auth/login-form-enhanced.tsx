'use client';

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useAuth } from '@/lib/auth/auth-context';
import { optimizedLogger } from '@/lib/utils/optimized-logger';
import { authLogger } from '@/lib/logger';
import { AlertCircle, CheckCircle, Shield, Eye, EyeOff, Loader2 } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface LoginError {
  readonly type: 'validation' | 'auth' | 'network' | 'permissions' | 'unknown';
  readonly message: string;
  readonly suggestion?: string;
}

interface LoginStep {
  readonly id: string;
  readonly name: string;
  readonly status: 'pending' | 'processing' | 'completed' | 'error';
  readonly details?: string;
}

export function LoginFormEnhanced() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<LoginError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loginSteps, setLoginSteps] = useState<readonly LoginStep[]>([]);
  const [currentStep, setCurrentStep] = useState<string>('');
  
  const { login } = useAuth();
  const router = useRouter();

  // Initialize login steps
  const initializeSteps = (): void => {
    const steps: LoginStep[] = [
      { id: 'validation', name: 'Kiểm tra thông tin đầu vào', status: 'pending' },
      { id: 'auth', name: 'Xác thực tài khoản', status: 'pending' },
      { id: 'profile', name: 'Tải thông tin người dùng', status: 'pending' },
      { id: 'business', name: 'Kiểm tra doanh nghiệp', status: 'pending' },
      { id: 'permissions', name: 'Tải quyền truy cập', status: 'pending' },
      { id: 'cache', name: 'Lưu session cache', status: 'pending' },
      { id: 'redirect', name: 'Chuyển hướng dashboard', status: 'pending' }
    ];
    setLoginSteps(steps);
    optimizedLogger.info('LOGIN_INIT', 'Khởi tạo quy trình đăng nhập với permissions', { steps: steps.length });
  };

  const updateStep = (stepId: string, status: LoginStep['status'], details?: string): void => {
    setLoginSteps(prev => prev.map(step => 
      step.id === stepId 
        ? { ...step, status, details }
        : step
    ));
    setCurrentStep(stepId);
    
    if (status === 'processing') {
      optimizedLogger.info('LOGIN_STEP', `🔄 ${stepId}`, details);
    } else if (status === 'completed') {
      optimizedLogger.success('LOGIN_STEP', `✅ ${stepId}`, details);
    } else if (status === 'error') {
      optimizedLogger.error('LOGIN_STEP', `❌ ${stepId}`, details);
    }
  };

  const classifyError = (error: unknown): LoginError => {
    if (!error) {
      return {
        type: 'unknown',
        message: 'Có lỗi không xác định xảy ra',
        suggestion: 'Vui lòng thử lại sau.'
      };
    }

    if (typeof error === 'string') {
      const errorLower = error.toLowerCase();
      
      if (errorLower.includes('invalid') || errorLower.includes('credentials')) {
        return {
          type: 'auth',
          message: 'Email hoặc mật khẩu không chính xác',
          suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập.'
        };
      }
      
      if (errorLower.includes('permission') || errorLower.includes('access')) {
        return {
          type: 'permissions',
          message: 'Không có quyền truy cập hệ thống',
          suggestion: 'Liên hệ quản trị viên để được cấp quyền.'
        };
      }
      
      if (errorLower.includes('network') || errorLower.includes('connection')) {
        return {
          type: 'network',
          message: 'Lỗi kết nối mạng',
          suggestion: 'Kiểm tra kết nối internet và thử lại.'
        };
      }
    }

    // Handle Supabase errors
    if (error && typeof error === 'object' && 'message' in error) {
      const errorObj = error as { message: string; code?: string };
      
      if (errorObj.code === 'invalid_credentials') {
        return {
          type: 'auth',
          message: 'Thông tin đăng nhập không chính xác',
          suggestion: 'Kiểm tra lại email và mật khẩu.'
        };
      }
      
      if (errorObj.message.includes('Profile error')) {
        return {
          type: 'permissions',
          message: 'Lỗi tải thông tin tài khoản',
          suggestion: 'Tài khoản có thể chưa được thiết lập đầy đủ.'
        };
      }
    }

    return {
      type: 'unknown',
      message: 'Đăng nhập thất bại',
      suggestion: 'Vui lòng thử lại sau ít phút.'
    };
  };

  const validateInputs = (): boolean => {
    updateStep('validation', 'processing', 'Kiểm tra email và mật khẩu');
    
    if (!email || !password) {
      updateStep('validation', 'error', 'Email và mật khẩu không được để trống');
      setError({
        type: 'validation',
        message: 'Vui lòng nhập đầy đủ email và mật khẩu',
        suggestion: 'Cả hai trường đều bắt buộc.'
      });
      return false;
    }

    if (!email.includes('@')) {
      updateStep('validation', 'error', 'Email không hợp lệ');
      setError({
        type: 'validation',
        message: 'Email không đúng định dạng',
        suggestion: 'Nhập email có chứa ký tự @.'
      });
      return false;
    }

    if (password.length < 6) {
      updateStep('validation', 'error', 'Mật khẩu quá ngắn');
      setError({
        type: 'validation',
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
        suggestion: 'Sử dụng mật khẩu dài hơn.'
      });
      return false;
    }

    updateStep('validation', 'completed', 'Thông tin đầu vào hợp lệ');
    return true;
  };

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    
    setIsLoading(true);
    setError(null);
    initializeSteps();

    try {
      // Step 1: Validate inputs
      if (!validateInputs()) {
        return;
      }

      // Step 2: Authenticate with Supabase
      updateStep('auth', 'processing', 'Đang xác thực với server');
      
      // Log login attempt
      await authLogger.loginAttempt({
        method: 'email',
        ip_address: 'client-side',
        user_agent: navigator.userAgent,
      });

      // Use auth context login (this will handle permissions loading)
      await login(email, password);
      
      updateStep('auth', 'completed', 'Xác thực thành công');
      updateStep('profile', 'completed', 'Đã tải thông tin người dùng');
      updateStep('business', 'completed', 'Đã kiểm tra doanh nghiệp'); 
      updateStep('permissions', 'completed', 'Đã tải quyền truy cập');
      updateStep('cache', 'completed', 'Đã lưu session cache');

      // Step 3: Redirect to dashboard
      updateStep('redirect', 'processing', 'Chuyển hướng đến dashboard');
      
      await authLogger.loginSuccess(
        {
          user_id: '',
          email,
          role: 'user',
          login_method: 'email'
        },
        {
          session_id: 'temp-session',
          ip_address: 'client-side'
        }
      );

      updateStep('redirect', 'completed', 'Đăng nhập thành công');
      
      optimizedLogger.success('LOGIN_SUCCESS', 'Đăng nhập thành công với permissions', {
        email,
        timestamp: new Date().toISOString()
      });

      // Small delay for better UX
      setTimeout(() => {
        router.push('/dashboard');
      }, 500);

    } catch (error: unknown) {
      optimizedLogger.error('LOGIN_ERROR', 'Lỗi đăng nhập', error);
      
      // Log failed attempt
      await authLogger.loginFailed({
        reason: 'authentication_failed',
        email,
        ip_address: 'client-side',
      });

      const loginError = classifyError(error);
      setError(loginError);
      
      // Update failed step
      if (currentStep) {
        updateStep(currentStep, 'error', loginError.message);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const getStepIcon = (step: LoginStep): React.ReactNode => {
    switch (step.status) {
      case 'processing':
        return <Loader2 className="w-4 h-4 animate-spin text-blue-600" />;
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-600" />;
      default:
        return <div className="w-4 h-4 rounded-full border-2 border-gray-300" />;
    }
  };

  return (
    <Card className="w-full max-w-sm">
      <CardHeader className="space-y-1">
        <div className="flex items-center gap-2">
          <Shield className="w-5 h-5 text-primary" />
          <CardTitle className="text-2xl">Đăng nhập</CardTitle>
        </div>
        <CardDescription>
          Nhập email và mật khẩu để truy cập hệ thống POS
        </CardDescription>
      </CardHeader>
      
      <CardContent className="space-y-4">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="name@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isLoading}
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="password">Mật khẩu</Label>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Nhập mật khẩu"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isLoading}
                required
              />
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                onClick={() => setShowPassword(!showPassword)}
                disabled={isLoading}
              >
                {showPassword ? (
                  <EyeOff className="h-4 w-4" />
                ) : (
                  <Eye className="h-4 w-4" />
                )}
              </Button>
            </div>
          </div>

          {error && (
            <Alert variant="destructive">
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

          {/* Login Steps Progress */}
          {isLoading && loginSteps.length > 0 && (
            <div className="space-y-2 p-3 bg-muted rounded-lg">
              <p className="text-sm font-medium text-muted-foreground">Tiến trình đăng nhập:</p>
              <div className="space-y-1">
                {loginSteps.map((step) => (
                  <div key={step.id} className="flex items-center gap-2 text-xs">
                    {getStepIcon(step)}
                    <span className={
                      step.status === 'completed' ? 'text-green-600' :
                      step.status === 'error' ? 'text-red-600' :
                      step.status === 'processing' ? 'text-blue-600' :
                      'text-gray-500'
                    }>
                      {step.name}
                    </span>
                    {step.details && (
                      <span className="text-gray-400">- {step.details}</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          <Button 
            type="submit" 
            className="w-full" 
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Đang đăng nhập...
              </>
            ) : (
              'Đăng nhập'
            )}
          </Button>
        </form>

        <div className="text-center text-sm text-muted-foreground">
          Chưa có tài khoản?{" "}
          <Button variant="link" className="p-0 h-auto" asChild>
            <a href="/auth/sign-up">Đăng ký ngay</a>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
