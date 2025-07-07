'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useState } from 'react';

export default function LoginDemoPage() {
  const [demoStep, setDemoStep] = useState(0);

  // Demo console logging patterns
  const demoConsoleLog = (): void => {
    const logger = {
      info: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.log(`%c🔵 [${timestamp}] ${step}: ${message}`, 'color: #3b82f6; font-weight: bold;', data || '');
      },
      success: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.log(`%c✅ [${timestamp}] ${step}: ${message}`, 'color: #10b981; font-weight: bold;', data || '');
      },
      warn: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.warn(`%c⚠️ [${timestamp}] ${step}: ${message}`, 'color: #f59e0b; font-weight: bold;', data || '');
      },
      error: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.error(`%c❌ [${timestamp}] ${step}: ${message}`, 'color: #ef4444; font-weight: bold;', data || '');
      },
      debug: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.log(`%c🔍 [${timestamp}] ${step}: ${message}`, 'color: #8b5cf6; font-style: italic;', data || '');
      }
    };

    console.log('%c🚀 === DEMO ENHANCED LOGIN LOGGING ===', 'color: #16a34a; font-size: 16px; font-weight: bold;');
    
    // Demo sequence
    setTimeout(() => {
      logger.info('VALIDATION', 'Kiểm tra thông tin đầu vào', { email: 'demo@example.com' });
    }, 100);
    
    setTimeout(() => {
      logger.success('VALIDATION', 'Thông tin hợp lệ');
      logger.info('AUTH', 'Gửi yêu cầu xác thực', { email: 'demo@example.com' });
    }, 600);
    
    setTimeout(() => {
      logger.success('AUTH', 'Xác thực thành công', { userId: 'demo-uuid-123', email: 'demo@example.com' });
      logger.info('PROFILE', 'Bắt đầu tải profile người dùng');
    }, 1100);
    
    setTimeout(() => {
      logger.debug('PROFILE', 'Kiểm tra function enhanced auth');
      logger.success('PROFILE', 'Profile loaded thành công');
    }, 1600);
    
    setTimeout(() => {
      logger.success('BUSINESS', 'Business: Demo Company (active)', { businessId: 'demo-business-123' });
      logger.success('PERMISSIONS', 'Role: admin (15 permissions)', { role: 'admin', permissions: 15 });
    }, 2100);
    
    setTimeout(() => {
      logger.success('LOGIN', 'Đăng nhập thành công - chuyển hướng dashboard', {
        businessId: 'demo-business-123',
        businessName: 'Demo Company',
        role: 'admin',
        subscriptionStatus: 'active',
        permissionsCount: 15
      });
    }, 2600);
  };

  const demoErrorLog = (): void => {
    const logger = {
      info: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.log(`%c🔵 [${timestamp}] ${step}: ${message}`, 'color: #3b82f6; font-weight: bold;', data || '');
      },
      warn: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.warn(`%c⚠️ [${timestamp}] ${step}: ${message}`, 'color: #f59e0b; font-weight: bold;', data || '');
      },
      error: (step: string, message: string, data?: unknown) => {
        const timestamp = new Date().toLocaleTimeString('vi-VN');
        console.error(`%c❌ [${timestamp}] ${step}: ${message}`, 'color: #ef4444; font-weight: bold;', data || '');
      }
    };

    console.log('%c❌ === DEMO ERROR SCENARIOS ===', 'color: #dc2626; font-size: 16px; font-weight: bold;');
    
    setTimeout(() => {
      logger.info('AUTH', 'Gửi yêu cầu xác thực', { email: 'wrong@example.com' });
    }, 100);
    
    setTimeout(() => {
      logger.error('AUTH', 'Xác thực thất bại', { 
        error: { type: 'auth', message: 'Email hoặc mật khẩu không chính xác' },
        originalError: { message: 'Invalid login credentials' }
      });
    }, 600);
    
    setTimeout(() => {
      logger.info('PROFILE', 'Bắt đầu tải profile người dùng');
    }, 1100);
    
    setTimeout(() => {
      logger.warn('PROFILE', 'Profile request failed', { 
        error: 'USER_PROFILE_NOT_FOUND', 
        message: 'Tài khoản chưa được thiết lập đầy đủ' 
      });
      logger.error('PROFILE', 'Profile không tồn tại - cần setup');
    }, 1600);
  };

  const demoSteps = [
    'Idle',
    'Validation',
    'Authentication', 
    'Profile Loading',
    'Business Check',
    'Permissions',
    'Redirect'
  ];

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            🚀 Enhanced Login System Demo
          </h1>
          <p className="text-gray-600">
            Demo các tính năng mới của hệ thống đăng nhập với logging chi tiết
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Console Demo */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                🔍 Console Logging Demo
              </CardTitle>
              <CardDescription>
                Xem console log với màu sắc và format đẹp
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-green-50 p-3 rounded-lg border border-green-200">
                <p className="text-sm text-green-700">
                  💡 Mở Console (F12) trước khi click để xem log
                </p>
              </div>
              
              <Button 
                onClick={demoConsoleLog}
                className="w-full bg-blue-600 hover:bg-blue-700"
              >
                🎯 Demo Successful Login Flow
              </Button>
              
              <Button 
                onClick={demoErrorLog}
                variant="destructive"
                className="w-full"
              >
                ❌ Demo Error Scenarios
              </Button>
            </CardContent>
          </Card>

          {/* Step Progress Demo */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                ⚡ Step Progress Demo
              </CardTitle>
              <CardDescription>
                Xem cách hiển thị tiến trình từng bước
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-slate-50 p-4 rounded-lg border">
                <h4 className="text-sm font-medium text-slate-700 mb-3">Tiến trình đăng nhập:</h4>
                <div className="space-y-2">
                  {demoSteps.map((step, index) => (
                    <div key={index} className="flex items-center gap-2 text-sm">
                      {index < demoStep ? (
                        <div className="w-4 h-4 rounded-full bg-green-500 flex items-center justify-center">
                          <span className="text-white text-xs">✓</span>
                        </div>
                      ) : index === demoStep ? (
                        <div className="w-4 h-4 rounded-full border-2 border-blue-500 border-t-transparent animate-spin"></div>
                      ) : (
                        <div className="w-4 h-4 rounded-full border-2 border-slate-300"></div>
                      )}
                      <span className={`${
                        index < demoStep ? 'text-green-700' :
                        index === demoStep ? 'text-blue-700 font-medium' :
                        'text-slate-500'
                      }`}>
                        {step}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="flex gap-2">
                <Button 
                  onClick={() => setDemoStep(prev => Math.min(prev + 1, demoSteps.length - 1))}
                  size="sm"
                  disabled={demoStep >= demoSteps.length - 1}
                >
                  Next Step
                </Button>
                <Button 
                  onClick={() => setDemoStep(0)}
                  variant="outline"
                  size="sm"
                >
                  Reset
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Features Overview */}
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>✨ Tính năng mới</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                  <h4 className="font-medium text-gray-900 mb-2">🎨 Console Logging</h4>
                  <ul className="space-y-1 text-gray-600">
                    <li>• 🔵 Info logs (màu xanh dương)</li>
                    <li>• ✅ Success logs (màu xanh lá)</li>
                    <li>• ⚠️ Warning logs (màu vàng)</li>
                    <li>• ❌ Error logs (màu đỏ)</li>
                    <li>• 🔍 Debug logs (màu tím)</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-medium text-gray-900 mb-2">🔄 Step Tracking</h4>
                  <ul className="space-y-1 text-gray-600">
                    <li>• Real-time progress indicator</li>
                    <li>• Error state với details</li>
                    <li>• Success confirmation</li>
                    <li>• Fallback mechanism</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-medium text-gray-900 mb-2">🛡️ Error Handling</h4>
                  <ul className="space-y-1 text-gray-600">
                    <li>• Validation errors</li>
                    <li>• Authentication failures</li>
                    <li>• Network issues</li>
                    <li>• Access permission errors</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-medium text-gray-900 mb-2">📱 UI Enhancements</h4>
                  <ul className="space-y-1 text-gray-600">
                    <li>• Loading indicators</li>
                    <li>• Progress visualization</li>
                    <li>• Error messages với actions</li>
                    <li>• Debug panel (development)</li>
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="mt-8 text-center">
          <p className="text-sm text-gray-500">
            Xem thêm chi tiết trong <code className="bg-gray-100 px-2 py-1 rounded">ENHANCED_LOGIN_GUIDE.md</code>
          </p>
        </div>
      </div>
    </div>
  );
}
