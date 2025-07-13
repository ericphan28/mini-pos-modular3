'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { businessLogger, authLogger, logger, setLoggerContext } from '@/lib/logger';
import { BusinessService } from '@/lib/services/business.service';
import { ShoppingCart, User, FileText, Activity, CheckCircle, XCircle } from 'lucide-react';

interface TestResult {
  readonly success: boolean;
  readonly message: string;
  readonly data?: unknown;
  readonly error?: string;
}

export default function LoggerTestPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState<TestResult[]>([]);
  const [productName, setProductName] = useState('Coca Cola 330ml');
  const [productPrice, setProductPrice] = useState(15000);
  const [productCategory, setProductCategory] = useState('beverages');

  const businessService = new BusinessService();

  const mockUserContext = {
    user_id: 'test_user_123',
    business_id: 'test_business_456',
  };

  const addResult = (result: TestResult): void => {
    setResults(prev => [result, ...prev]);
  };

  const clearResults = (): void => {
    setResults([]);
  };

  const testBasicLogging = async (): Promise<void> => {
    try {
      setLoggerContext({
        user_id: mockUserContext.user_id,
        business_id: mockUserContext.business_id,
        request_id: `test_${Date.now()}`,
      });

      await logger.info('TEST', 'BASIC_LOG', 'Kiểm tra basic logging system', {
        test_type: 'basic_logging',
        timestamp: new Date().toISOString(),
      });

      await logger.warn('TEST', 'WARNING_LOG', 'Cảnh báo test system', {
        warning_level: 'medium',
      });

      await logger.error('TEST', 'ERROR_LOG', 'Lỗi test system', new Error('Test error message'), {
        error_context: 'testing_phase',
      });

      addResult({
        success: true,
        message: 'Basic logging test thành công - kiểm tra console',
      });
    } catch (error: unknown) {
      addResult({
        success: false,
        message: 'Basic logging test thất bại',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  };

  const testAuthLogging = async (): Promise<void> => {
    try {
      // Test login attempt
      await authLogger.loginAttempt({
        email: 'test@example.com',
        method: 'email',
        ip_address: '192.168.1.100',
        user_agent: 'Mozilla/5.0 Test Browser',
      });

      // Test login success
      await authLogger.loginSuccess({
        user_id: mockUserContext.user_id,
        email: 'test@example.com',
        business_id: mockUserContext.business_id,
        role: 'manager',
        login_method: 'email',
        is_first_login: false,
      }, {
        session_id: 'test_session_789',
        ip_address: '192.168.1.100',
        user_agent: 'Mozilla/5.0 Test Browser',
      });

      // Test permission change
      await authLogger.permissionChanged({
        user_id: mockUserContext.user_id,
        business_id: mockUserContext.business_id,
        old_role: 'staff',
        new_role: 'manager',
        permissions_added: ['manage_products', 'view_reports'],
        permissions_removed: [],
      }, {
        changed_by: 'admin_123',
        reason: 'Promotion to manager role',
        ip_address: '192.168.1.100',
      });

      addResult({
        success: true,
        message: 'Auth logging test thành công - kiểm tra console',
      });
    } catch (error: unknown) {
      addResult({
        success: false,
        message: 'Auth logging test thất bại',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  };

  const testBusinessLogging = async (): Promise<void> => {
    try {
      setIsLoading(true);

      // Test product creation
      const productResult = await businessService.createProduct({
        name: productName,
        price: productPrice,
        category: productCategory,
        sku: `SKU_${Date.now()}`,
        description: 'Test product từ logger demo',
      }, mockUserContext);

      if (!productResult.success) {
        throw new Error(productResult.error || 'Failed to create product');
      }

      // Test order completion
      await businessLogger.orderCompleted({
        id: `order_${Date.now()}`,
        total: 45000,
        items_count: 3,
        payment_method: 'cash',
        customer_id: 'customer_123',
        discount_amount: 5000,
        tax_amount: 4500,
      }, mockUserContext);

      // Test payment processing
      await businessLogger.paymentProcessed({
        payment_id: `payment_${Date.now()}`,
        order_id: `order_${Date.now()}`,
        amount: 45000,
        method: 'cash',
        status: 'success',
        transaction_id: `txn_${Date.now()}`,
      }, mockUserContext);

      // Test inventory update
      await businessLogger.inventoryUpdated({
        product_id: 'product_123',
        product_name: productName,
        old_quantity: 100,
        new_quantity: 97,
        reason: 'Sale transaction',
        reference_id: `order_${Date.now()}`,
      }, mockUserContext);

      addResult({
        success: true,
        message: 'Business logging test thành công - kiểm tra console',
        data: productResult.product,
      });
    } catch (error: unknown) {
      addResult({
        success: false,
        message: 'Business logging test thất bại',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    } finally {
      setIsLoading(false);
    }
  };

  const testStaffOperations = async (): Promise<void> => {
    try {
      addResult({ success: false, message: '🚀 Testing staff operations...' });

      setLoggerContext({
        user_id: 'manager_123',
        business_id: 'business_456',
        session_id: `staff-test-${Date.now()}`
      });

      // Test staff dashboard load
      await logger.info(
        'BUSINESS',
        'STAFF_DASHBOARD_LOADED',
        'Tải trang quản lý nhân viên thành công',
        {
          business_id: 'business_456',
          staff_count: 5,
          active_staff: 4,
          role_distribution: { manager: 1, seller: 3, accountant: 1 },
          loaded_by: 'manager_123',
          load_time: new Date().toISOString()
        }
      );

      // Test staff invitation
      await logger.info(
        'BUSINESS',
        'STAFF_INVITED',
        'Mời nhân viên thành công',
        {
          business_id: 'business_456',
          target_email: 'newstaff@example.com',
          target_role: 'seller',
          invited_by: 'manager_123'
        }
      );

      // Test staff permission change
      await logger.info(
        'BUSINESS',
        'STAFF_PERMISSION_CHANGED',
        'Thay đổi quyền nhân viên',
        {
          business_id: 'business_456',
          staff_id: 'staff_789',
          old_role: 'seller',
          new_role: 'manager',
          changed_by: 'manager_123'
        }
      );

      addResult({
        success: true,
        message: '✅ Staff operations logging completed',
        data: {
          events_logged: 3,
          context: 'staff_management'
        }
      });

    } catch (error) {
      addResult({
        success: false,
        message: '❌ Staff operations test failed',
        error: error instanceof Error ? error.message : String(error)
      });
    }
  };

  const testPerformanceTracking = async (): Promise<void> => {
    try {
      addResult({ success: false, message: '⚡ Testing performance tracking...' });

      const result = await businessLogger.performanceTrack(
        'STAFF_DASHBOARD_LOAD',
        { business_id: 'business_456', user_id: 'manager_123' },
        async () => {
          // Simulate loading staff data
          await new Promise(resolve => setTimeout(resolve, 500));
          return {
            staff_count: 5,
            load_time: 500,
            success: true
          };
        }
      );

      addResult({
        success: true,
        message: '✅ Performance tracking completed',
        data: result
      });

    } catch (error) {
      addResult({
        success: false,
        message: '❌ Performance tracking failed',
        error: error instanceof Error ? error.message : String(error)
      });
    }
  };

  const testErrorScenarios = async (): Promise<void> => {
    try {
      // Test validation error
      const invalidProductResult = await businessService.createProduct({
        name: '', // Invalid name
        price: -100, // Invalid price
        category: 'test',
      }, mockUserContext);

      // Test suspicious activity
      await authLogger.suspiciousActivity({
        user_id: mockUserContext.user_id,
        activity_type: 'MULTIPLE_FAILED_LOGINS',
        severity: 'high',
        description: 'User attempted login 10 times in 5 minutes',
        ip_address: '192.168.1.100',
        user_agent: 'Suspicious Bot/1.0',
        additional_info: {
          attempts_count: 10,
          time_window_minutes: 5,
          suspected_attack: true,
        },
      });

      addResult({
        success: true,
        message: 'Error scenarios test hoàn thành',
        data: {
          product_validation: invalidProductResult.success ? 'passed' : 'failed as expected',
          suspicious_activity: 'logged',
        },
      });
    } catch (error: unknown) {
      addResult({
        success: false,
        message: 'Error scenarios test thất bại',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="w-5 h-5" />
            Logger System Test Dashboard
          </CardTitle>
          <CardDescription>
            Test và demo hệ thống logging chuyên nghiệp cho POS Mini Modular 3
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Configuration */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label htmlFor="productName">Tên sản phẩm test</Label>
              <Input
                id="productName"
                value={productName}
                onChange={(e) => setProductName(e.target.value)}
                placeholder="Tên sản phẩm"
              />
            </div>
            <div>
              <Label htmlFor="productPrice">Giá sản phẩm</Label>
              <Input
                id="productPrice"
                type="number"
                value={productPrice}
                onChange={(e) => setProductPrice(Number(e.target.value))}
                placeholder="Giá"
              />
            </div>
            <div>
              <Label htmlFor="productCategory">Danh mục</Label>
              <Select value={productCategory} onValueChange={setProductCategory}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="beverages">Đồ uống</SelectItem>
                  <SelectItem value="snacks">Đồ ăn vặt</SelectItem>
                  <SelectItem value="electronics">Điện tử</SelectItem>
                  <SelectItem value="clothing">Quần áo</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Test Buttons */}
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <Button
              onClick={testBasicLogging}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <FileText className="w-5 h-5" />
              <span>Basic Logging</span>
            </Button>

            <Button
              onClick={testAuthLogging}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <User className="w-5 h-5" />
              <span>Auth Logging</span>
            </Button>

            <Button
              onClick={testBusinessLogging}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <ShoppingCart className="w-5 h-5" />
              <span>Business Logging</span>
            </Button>

            <Button
              onClick={testPerformanceTracking}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <Activity className="w-5 h-5" />
              <span>Performance Test</span>
            </Button>

            <Button
              onClick={testStaffOperations}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <User className="w-5 h-5" />
              <span>Staff Operations</span>
            </Button>

            <Button
              onClick={testErrorScenarios}
              disabled={isLoading}
              variant="outline"
              className="h-20 flex flex-col gap-2"
            >
              <XCircle className="w-5 h-5" />
              <span>Error Scenarios</span>
            </Button>

            <Button
              onClick={clearResults}
              disabled={isLoading}
              variant="destructive"
              className="h-20 flex flex-col gap-2"
            >
              <FileText className="w-5 h-5" />
              <span>Clear Results</span>
            </Button>
          </div>

          {/* Mock Context Info */}
          <Alert>
            <User className="w-4 h-4" />
            <AlertDescription>
              Mock Context: User ID: <code>{mockUserContext.user_id}</code>, 
              Business ID: <code>{mockUserContext.business_id}</code>
            </AlertDescription>
          </Alert>

          {/* Results */}
          {results.length > 0 && (
            <div className="space-y-3">
              <h3 className="text-lg font-semibold">Test Results</h3>
              {results.map((result, index) => (
                <Alert key={index} className={result.success ? 'border-green-200' : 'border-red-200'}>
                  <div className="flex items-start gap-2">
                    {result.success ? (
                      <CheckCircle className="w-4 h-4 text-green-600 mt-0.5" />
                    ) : (
                      <XCircle className="w-4 h-4 text-red-600 mt-0.5" />
                    )}
                    <div className="flex-1">
                      <AlertDescription className="text-sm">
                        <strong className={result.success ? 'text-green-800' : 'text-red-800'}>
                          {result.message}
                        </strong>
                        {result.error && (
                          <div className="mt-1 text-red-600 text-xs">
                            Error: {result.error}
                          </div>
                        )}
                        {result.data && typeof result.data === 'object' && result.data !== null ? (
                          <details className="mt-2">
                            <summary className="cursor-pointer text-xs text-gray-600">
                              Xem chi tiết data
                            </summary>
                            <pre className="mt-1 text-xs bg-gray-50 p-2 rounded overflow-auto">
                              {JSON.stringify(result.data as Record<string, unknown>, null, 2)}
                            </pre>
                          </details>
                        ) : null}
                      </AlertDescription>
                    </div>
                  </div>
                </Alert>
              ))}
            </div>
          )}

          {/* Instructions */}
          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-semibold text-blue-900 mb-2">Hướng dẫn sử dụng:</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• Mở Developer Console (F12) để xem logs chi tiết</li>
              <li>• Click các nút test để kiểm tra từng loại logging</li>
              <li>• Logger sẽ hiển thị màu sắc và format khác nhau cho dev/production</li>
              <li>• Kiểm tra performance tracking và error handling</li>
              <li>• Tất cả logs đều structured và có thể export</li>
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
