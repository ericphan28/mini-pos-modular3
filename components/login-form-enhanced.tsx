'use client';

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createClient } from '@/lib/supabase/client';
import { AlertCircle, Clock, Eye, EyeOff, Lock, Shield, User, UserPlus } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface LoginError {
  type: 'validation' | 'auth' | 'network' | 'profile' | 'business' | 'unknown';
  message: string;
  suggestion?: string;
  actionButton?: {
    text: string;
    action: () => void;
  };
}

// ==================================================================================
// HỆ THỐNG LOG NÂNG CAO
// ==================================================================================
class LoginLogger {
  private static logs: Array<{ timestamp: string; level: string; step: string; message: string; data?: unknown }> = [];
  
  static log(level: 'info' | 'warn' | 'error' | 'success', step: string, message: string, data?: unknown) {
    const timestamp = new Date().toLocaleTimeString('vi-VN');
    const logEntry = { timestamp, level, step, message, data };
    
    // Thêm vào mảng logs
    this.logs.push(logEntry);
    
    // Console log với format đẹp
    const icon = {
      info: '📝',
      warn: '⚠️',
      error: '❌',
      success: '✅'
    }[level];
    
    const logMessage = `${icon} [${timestamp}] [${step}] ${message}`;
    
    if (level === 'error') {
      console.error(logMessage, data);
    } else if (level === 'warn') {
      console.warn(logMessage, data);
    } else if (level === 'success') {
      console.log(`%c${logMessage}`, 'color: green; font-weight: bold', data);
    } else {
      console.log(logMessage, data);
    }
  }
  
  static getLogs() {
    return this.logs;
  }
  
  static clearLogs() {
    this.logs = [];
  }
  
  static exportLogs() {
    return JSON.stringify(this.logs, null, 2);
  }
}

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<LoginError | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loginStep, setLoginStep] = useState<string>('idle');
  const router = useRouter();

  // ==================================================================================
  // BƯỚC 1: VALIDATION INPUT
  // ==================================================================================
  const validateInput = (): LoginError | null => {
    LoginLogger.log('info', 'VALIDATION', 'Bắt đầu kiểm tra dữ liệu đầu vào');
    
    if (!email.trim()) {
      LoginLogger.log('warn', 'VALIDATION', 'Email trống');
      return {
        type: 'validation',
        message: 'Vui lòng nhập địa chỉ email',
        suggestion: 'Email không được để trống'
      };
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      LoginLogger.log('warn', 'VALIDATION', 'Email không hợp lệ', { email: email.trim() });
      return {
        type: 'validation',
        message: 'Địa chỉ email không đúng định dạng',
        suggestion: 'Vui lòng nhập email đúng định dạng (ví dụ: user@example.com)'
      };
    }

    if (!password) {
      LoginLogger.log('warn', 'VALIDATION', 'Mật khẩu trống');
      return {
        type: 'validation',
        message: 'Vui lòng nhập mật khẩu',
        suggestion: 'Mật khẩu không được để trống'
      };
    }

    if (password.length < 6) {
      LoginLogger.log('warn', 'VALIDATION', 'Mật khẩu quá ngắn', { length: password.length });
      return {
        type: 'validation',
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
        suggestion: 'Vui lòng nhập mật khẩu dài hơn'
      };
    }

    LoginLogger.log('success', 'VALIDATION', 'Dữ liệu đầu vào hợp lệ');
    return null;
  };

  // ==================================================================================
  // BƯỚC 2: XÁC THỰC SUPABASE AUTH
  // ==================================================================================
  const authenticateUser = async (emailTrimmed: string, password: string) => {
    LoginLogger.log('info', 'AUTH', 'Bắt đầu xác thực với Supabase Auth');
    setLoginStep('Đang xác thực...');
    
    const supabase = createClient();
    
    try {
      const result = await supabase.auth.signInWithPassword({
        email: emailTrimmed,
        password: password,
      });
      
      LoginLogger.log('info', 'AUTH', 'Nhận được kết quả xác thực', {
        hasUser: !!result.data?.user,
        hasError: !!result.error,
        userEmail: result.data?.user?.email
      });

      if (result.error) {
        LoginLogger.log('error', 'AUTH', 'Xác thực thất bại', result.error);
        
        const errorMessage = result.error.message.toLowerCase();
        if (errorMessage.includes('invalid') || errorMessage.includes('credentials')) {
          return {
            success: false,
            error: {
              type: 'auth' as const,
              message: 'Email hoặc mật khẩu không chính xác',
              suggestion: 'Vui lòng kiểm tra lại thông tin đăng nhập'
            }
          };
        }
        
        return {
          success: false,
          error: {
            type: 'auth' as const,
            message: 'Không thể đăng nhập',
            suggestion: 'Vui lòng thử lại sau'
          }
        };
      }

      if (!result.data?.user) {
        LoginLogger.log('error', 'AUTH', 'Không có thông tin user trong kết quả');
        return {
          success: false,
          error: {
            type: 'auth' as const,
            message: 'Không thể lấy thông tin tài khoản',
            suggestion: 'Vui lòng thử lại'
          }
        };
      }

      LoginLogger.log('success', 'AUTH', 'Xác thực thành công', {
        userId: result.data.user.id,
        email: result.data.user.email
      });

      return {
        success: true,
        user: result.data.user
      };

    } catch (exception) {
      LoginLogger.log('error', 'AUTH', 'Exception trong quá trình xác thực', exception);
      return {
        success: false,
        error: {
          type: 'network' as const,
          message: 'Lỗi kết nối mạng',
          suggestion: 'Vui lòng kiểm tra kết nối internet và thử lại'
        }
      };
    }
  };

  // ==================================================================================
  // BƯỚC 3: KIỂM TRA PROFILE NGƯỜI DÙNG
  // ==================================================================================
  const checkUserProfile = async (userId: string) => {
    LoginLogger.log('info', 'PROFILE', 'Bắt đầu kiểm tra profile người dùng');
    setLoginStep('Đang tải thông tin tài khoản...');
    
    const supabase = createClient();
    
    try {
      // Kiểm tra Enhanced Auth Function
      const enhancedResult = await supabase.rpc(
        'pos_mini_modular3_get_user_with_business_complete',
        { p_user_id: userId }
      );
      
      LoginLogger.log('info', 'PROFILE', 'Kết quả Enhanced Auth', {
        hasData: !!enhancedResult.data,
        hasError: !!enhancedResult.error,
        success: enhancedResult.data?.success
      });

      if (enhancedResult.error) {
        LoginLogger.log('error', 'PROFILE', 'Lỗi Enhanced Auth Function', enhancedResult.error);
        throw new Error('Enhanced Auth Function failed');
      }

      const profileData = enhancedResult.data;
      
      if (!profileData || !profileData.success) {
        const errorCode = profileData?.error;
        const errorMessage = profileData?.message;
        
        LoginLogger.log('warn', 'PROFILE', 'Profile check thất bại', { 
          errorCode, 
          errorMessage 
        });

        // Xử lý các trường hợp cụ thể
        switch (errorCode) {
          case 'USER_PROFILE_NOT_FOUND':
            return {
              success: false,
              error: {
                type: 'profile' as const,
                message: 'Tài khoản chưa được thiết lập đầy đủ',
                suggestion: 'Tài khoản của bạn cần được thiết lập thêm thông tin',
                actionButton: {
                  text: 'Hoàn tất đăng ký',
                  action: () => {
                    LoginLogger.log('info', 'REDIRECT', 'Chuyển hướng đến trang đăng ký');
                    router.push('/auth/sign-up');
                  }
                }
              }
            };
            
          case 'NO_BUSINESS_ASSIGNED':
            return {
              success: false,
              error: {
                type: 'business' as const,
                message: 'Tài khoản chưa được gán vào doanh nghiệp',
                suggestion: 'Vui lòng liên hệ quản trị viên để được thêm vào doanh nghiệp'
              }
            };
            
          case 'SUBSCRIPTION_INACTIVE':
            return {
              success: false,
              error: {
                type: 'business' as const,
                message: 'Gói dịch vụ đã hết hạn',
                suggestion: 'Vui lòng gia hạn gói dịch vụ để tiếp tục sử dụng'
              }
            };
            
          case 'TRIAL_EXPIRED':
            return {
              success: false,
              error: {
                type: 'business' as const,
                message: 'Thời gian dùng thử đã hết hạn',
                suggestion: 'Vui lòng nâng cấp lên gói trả phí để tiếp tục'
              }
            };
            
          default:
            return {
              success: false,
              error: {
                type: 'unknown' as const,
                message: errorMessage || 'Có lỗi xảy ra khi tải thông tin tài khoản',
                suggestion: 'Vui lòng thử lại sau'
              }
            };
        }
      }

      LoginLogger.log('success', 'PROFILE', 'Profile check thành công', {
        hasUser: !!profileData.user,
        hasBusiness: !!profileData.business,
        hasPermissions: !!profileData.permissions
      });

      return {
        success: true,
        profileData
      };

    } catch (exception) {
      LoginLogger.log('error', 'PROFILE', 'Exception trong profile check', exception);
      
      // Fallback: Kiểm tra profile cơ bản
      LoginLogger.log('info', 'FALLBACK', 'Thử kiểm tra profile cơ bản');
      
      try {
        const basicProfileResult = await supabase
          .from('pos_mini_modular3_user_profiles')
          .select('id, full_name, role, business_id')
          .eq('id', userId)
          .single();
          
        if (basicProfileResult.error) {
          if (basicProfileResult.error.code === 'PGRST116') {
            LoginLogger.log('warn', 'FALLBACK', 'Không tìm thấy profile cơ bản');
            return {
              success: false,
              error: {
                type: 'profile' as const,
                message: 'Tài khoản chưa được thiết lập',
                suggestion: 'Vui lòng hoàn tất quá trình đăng ký',
                actionButton: {
                  text: 'Đăng ký ngay',
                  action: () => router.push('/auth/sign-up')
                }
              }
            };
          }
          
          throw basicProfileResult.error;
        }
        
        LoginLogger.log('success', 'FALLBACK', 'Tìm thấy profile cơ bản', basicProfileResult.data);
        
        return {
          success: true,
          profileData: {
            success: true,
            user: { id: userId, ...basicProfileResult.data },
            fallbackMode: true
          }
        };
        
      } catch (fallbackException) {
        LoginLogger.log('error', 'FALLBACK', 'Fallback cũng thất bại', fallbackException);
        
        return {
          success: false,
          error: {
            type: 'unknown' as const,
            message: 'Không thể tải thông tin tài khoản',
            suggestion: 'Vui lòng thử lại sau hoặc liên hệ hỗ trợ'
          }
        };
      }
    }
  };

  // ==================================================================================
  // BƯỚC 4: XỬ LÝ ĐĂNG NHẬP CHÍNH
  // ==================================================================================
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Reset states
    setError(null);
    setIsLoading(true);
    setLoginStep('Bắt đầu đăng nhập');
    LoginLogger.clearLogs();
    
    LoginLogger.log('info', 'LOGIN-START', '🚀 Bắt đầu quá trình đăng nhập', {
      email: email.trim(),
      timestamp: new Date().toISOString()
    });

    try {
      // Bước 1: Validation
      const validationError = validateInput();
      if (validationError) {
        setError(validationError);
        return;
      }

      const emailTrimmed = email.trim().toLowerCase();

      // Bước 2: Xác thực
      const authResult = await authenticateUser(emailTrimmed, password);
      if (!authResult.success) {
        setError(authResult.error);
        return;
      }

      // Bước 3: Kiểm tra Profile
      const profileResult = await checkUserProfile(authResult.user.id);
      if (!profileResult.success) {
        setError(profileResult.error);
        return;
      }

      // Bước 4: Đăng nhập thành công
      LoginLogger.log('success', 'LOGIN-SUCCESS', '🎉 Đăng nhập thành công!');
      setLoginStep('Đăng nhập thành công! Đang chuyển hướng...');
      
      // Delay nhỏ để user thấy thông báo thành công
      setTimeout(() => {
        router.push('/dashboard');
      }, 1000);

    } catch (exception) {
      LoginLogger.log('error', 'LOGIN-EXCEPTION', 'Exception không mong muốn', exception);
      setError({
        type: 'unknown',
        message: 'Có lỗi không mong muốn xảy ra',
        suggestion: 'Vui lòng thử lại sau'
      });
    } finally {
      setIsLoading(false);
    }
  };

  // ==================================================================================
  // UI COMPONENTS
  // ==================================================================================
  const exportLogs = () => {
    const logs = LoginLogger.exportLogs();
    const blob = new Blob([logs], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `login-logs-${new Date().toISOString()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="flex min-h-svh w-full items-center justify-center p-6 md:p-10">
      <div className="w-full max-w-sm space-y-6">
        <Card>
          <CardHeader className="text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
              <Shield className="h-6 w-6 text-primary" />
            </div>
            <CardTitle>Đăng nhập</CardTitle>
            <CardDescription>
              Đăng nhập vào tài khoản của bạn để tiếp tục
            </CardDescription>
          </CardHeader>
          
          <CardContent>
            <form onSubmit={handleLogin} className="space-y-4">
              {/* Email Input */}
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="email"
                    placeholder="cym_sunset@yahoo.com"
                    type="email"
                    autoCapitalize="none"
                    autoComplete="email"
                    autoCorrect="off"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10"
                    disabled={isLoading}
                  />
                </div>
              </div>

              {/* Password Input */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label htmlFor="password">Mật khẩu</Label>
                  <Link 
                    href="/auth/forgot-password" 
                    className="text-sm text-primary hover:underline"
                  >
                    Quên mật khẩu?
                  </Link>
                </div>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="password"
                    placeholder="Tnt@9961266"
                    type={showPassword ? "text" : "password"}
                    autoCapitalize="none"
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-10 pr-10"
                    disabled={isLoading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    disabled={isLoading}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </button>
                </div>
              </div>

              {/* Error Display */}
              {error && (
                <Alert variant="destructive">
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription className="space-y-2">
                    <div className="font-medium">{error.message}</div>
                    {error.suggestion && (
                      <div className="text-sm opacity-90">{error.suggestion}</div>
                    )}
                    {error.actionButton && (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={error.actionButton.action}
                        className="mt-2"
                      >
                        <UserPlus className="mr-2 h-4 w-4" />
                        {error.actionButton.text}
                      </Button>
                    )}
                  </AlertDescription>
                </Alert>
              )}

              {/* Login Status */}
              {isLoading && loginStep && (
                <div className="flex items-center justify-center space-x-2 text-sm text-muted-foreground">
                  <Clock className="h-4 w-4 animate-spin" />
                  <span>{loginStep}</span>
                </div>
              )}

              {/* Submit Button */}
              <Button 
                type="submit" 
                className="w-full" 
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <Clock className="mr-2 h-4 w-4 animate-spin" />
                    Đang đăng nhập...
                  </>
                ) : (
                  'Đăng nhập'
                )}
              </Button>
            </form>

            {/* Debug Section (Development Only) */}
            {process.env.NODE_ENV === 'development' && (
              <div className="mt-4 pt-4 border-t">
                <details className="text-xs">
                  <summary className="cursor-pointer text-muted-foreground hover:text-foreground">
                    🔧 Debug Information
                  </summary>
                  <div className="mt-2 space-y-2">
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={exportLogs}
                      className="w-full text-xs"
                    >
                      📝 Export Logs
                    </Button>
                    <div className="text-xs text-muted-foreground">
                      Bước hiện tại: {loginStep}
                    </div>
                  </div>
                </details>
              </div>
            )}
          </CardContent>
        </Card>
        
        {/* Additional Links */}
        <div className="text-center space-y-2">
          <div className="text-sm text-muted-foreground">
            Chưa có tài khoản?{' '}
            <Link href="/auth/sign-up" className="text-primary hover:underline">
              Tạo tài khoản mới
            </Link>
          </div>
          
          <Link 
            href="/admin-login"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          >
            <Shield className="w-4 h-4" />
            Đăng nhập Super Admin
          </Link>
        </div>
      </div>
    </div>
  );
}
