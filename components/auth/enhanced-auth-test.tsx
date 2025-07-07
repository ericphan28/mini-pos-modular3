'use client';

import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { EnhancedBusinessAuthService, type CompleteUserSession, type PermissionResult } from '@/lib/auth/enhanced-business-auth.service';
import { AlertCircle, Building2, CheckCircle, Clock, Shield, User, XCircle } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';

export function EnhancedAuthTest() {
  const [userSession, setUserSession] = useState<CompleteUserSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [permissions, setPermissions] = useState<Record<string, PermissionResult>>({});
  const [testingPermissions, setTestingPermissions] = useState(false);

  // Features to test permissions
  const testFeatures = [
    'products',
    'inventory',
    'reports',
    'staff_management',
    'business_settings'
  ];

  const testActions = ['read', 'write', 'delete', 'manage'] as const;

  const loadUserSession = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const session = await EnhancedBusinessAuthService.getCurrentUserWithBusiness();
      setUserSession(session);
    } catch (err: unknown) {
      console.error('Error loading user session:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUserSession();
  }, [loadUserSession]);

  // Separate effect to test permissions when user session changes
  useEffect(() => {
    if (userSession?.success) {
      testPermissions();
    }
  }, [userSession]); // eslint-disable-line react-hooks/exhaustive-deps

  const testPermissions = async () => {
    if (!userSession?.success) return;
    
    setTestingPermissions(true);
    const permissionResults: Record<string, PermissionResult> = {};
    
    try {
      // Test basic read permissions for all features
      for (const feature of testFeatures) {
        const result = await EnhancedBusinessAuthService.hasPermission(feature, 'read');
        permissionResults[`${feature}_read`] = result;
      }
      
      setPermissions(permissionResults);
    } catch (err: unknown) {
      console.error('Error testing permissions:', err);
    } finally {
      setTestingPermissions(false);
    }
  };

  const testSpecificPermission = async (feature: string, action: typeof testActions[number]) => {
    try {
      const result = await EnhancedBusinessAuthService.hasPermission(feature, action);
      setPermissions(prev => ({
        ...prev,
        [`${feature}_${action}`]: result
      }));
    } catch (err: unknown) {
      console.error(`Error testing ${feature}_${action}:`, err);
    }
  };

  if (loading) {
    return (
      <Card className="w-full max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="w-5 h-5 animate-spin" />
            Đang tải thông tin xác thực...
          </CardTitle>
        </CardHeader>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className="w-full max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle className="text-red-600 flex items-center gap-2">
            <XCircle className="w-5 h-5" />
            Lỗi tải dữ liệu
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
          <Button onClick={loadUserSession} className="mt-4">
            Thử lại
          </Button>
        </CardContent>
      </Card>
    );
  }

  if (!userSession?.success) {
    return (
      <Card className="w-full max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle className="text-yellow-600 flex items-center gap-2">
            <AlertCircle className="w-5 h-5" />
            Thông tin xác thực không hợp lệ
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              {userSession?.message || 'Không thể tải thông tin người dùng'}
            </AlertDescription>
          </Alert>
          <Button onClick={loadUserSession} className="mt-4">
            Tải lại
          </Button>
        </CardContent>
      </Card>
    );
  }

  const { user, business, permissions: userPermissions, session_info } = userSession;

  return (
    <div className="w-full max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <CardTitle className="text-green-600 flex items-center gap-2">
            <CheckCircle className="w-5 h-5" />
            Enhanced Auth System - Đang hoạt động
          </CardTitle>
          <CardDescription>
            Thông tin chi tiết về phiên đăng nhập và quyền truy cập
          </CardDescription>
        </CardHeader>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* User Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="w-5 h-5" />
              Thông tin người dùng
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between">
              <span className="font-medium">Email:</span>
              <span className="text-sm">{user.email}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Họ tên:</span>
              <span className="text-sm">{user.full_name || 'Chưa cập nhật'}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Vai trò:</span>
              <Badge variant="outline">{user.role}</Badge>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Trạng thái:</span>
              <Badge variant={user.status === 'active' ? 'default' : 'destructive'}>
                {user.status}
              </Badge>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Đăng nhập bằng:</span>
              <span className="text-sm">{user.login_method}</span>
            </div>
          </CardContent>
        </Card>

        {/* Business Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Building2 className="w-5 h-5" />
              Thông tin doanh nghiệp
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between">
              <span className="font-medium">Tên:</span>
              <span className="text-sm">{business.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Loại hình:</span>
              <span className="text-sm">{business.business_type_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Mã doanh nghiệp:</span>
              <span className="text-sm font-mono">{business.business_code}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Gói dịch vụ:</span>
              <Badge variant={business.subscription_tier === 'free' ? 'secondary' : 'default'}>
                {business.subscription_tier}
              </Badge>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Trạng thái:</span>
              <Badge variant={business.subscription_status === 'active' ? 'default' : 'destructive'}>
                {business.subscription_status}
              </Badge>
            </div>
            {business.trial_end_date && (
              <div className="flex justify-between">
                <span className="font-medium">Hết hạn thử:</span>
                <span className="text-sm">
                  {new Date(business.trial_end_date).toLocaleDateString('vi-VN')}
                </span>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Permissions Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="w-5 h-5" />
            Quyền truy cập hệ thống
          </CardTitle>
          <CardDescription>
            Quyền được gán cho vai trò {user.role} trong gói {business.subscription_tier}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {Object.entries(userPermissions).map(([feature, perms]) => (
              <div key={feature} className="p-3 border rounded-lg">
                <h4 className="font-medium text-sm mb-2">{feature}</h4>
                <div className="space-y-1 text-xs">
                  <div className="flex justify-between">
                    <span>Đọc:</span>
                    <Badge variant={perms.can_read ? 'default' : 'secondary'} className="h-4 text-xs">
                      {perms.can_read ? 'Có' : 'Không'}
                    </Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>Ghi:</span>
                    <Badge variant={perms.can_write ? 'default' : 'secondary'} className="h-4 text-xs">
                      {perms.can_write ? 'Có' : 'Không'}
                    </Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>Xóa:</span>
                    <Badge variant={perms.can_delete ? 'default' : 'secondary'} className="h-4 text-xs">
                      {perms.can_delete ? 'Có' : 'Không'}
                    </Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>Quản lý:</span>
                    <Badge variant={perms.can_manage ? 'default' : 'secondary'} className="h-4 text-xs">
                      {perms.can_manage ? 'Có' : 'Không'}
                    </Badge>
                  </div>
                  {perms.usage_limit && (
                    <div className="text-xs text-muted-foreground pt-1">
                      Giới hạn: {perms.usage_limit}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Permission Testing */}
      <Card>
        <CardHeader>
          <CardTitle>Test quyền truy cập realtime</CardTitle>
          <CardDescription>
            Test các quyền truy cập cho từng tính năng
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <Button 
              onClick={testPermissions} 
              disabled={testingPermissions}
              className="mb-4"
            >
              {testingPermissions ? 'Đang test...' : 'Test tất cả quyền đọc'}
            </Button>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {testFeatures.map(feature => (
                <div key={feature} className="p-3 border rounded-lg">
                  <h4 className="font-medium mb-2">{feature}</h4>
                  <div className="space-y-2">
                    {testActions.map(action => {
                      const permKey = `${feature}_${action}`;
                      const result = permissions[permKey];
                      
                      return (
                        <div key={action} className="flex items-center justify-between text-sm">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => testSpecificPermission(feature, action)}
                            className="h-6 px-2"
                          >
                            {action}
                          </Button>
                          {result ? (
                            <Badge 
                              variant={result.allowed ? 'default' : 'destructive'}
                              className="h-5 text-xs"
                            >
                              {result.allowed ? 'OK' : 'Từ chối'}
                            </Badge>
                          ) : (
                            <span className="text-xs text-muted-foreground">Chưa test</span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Session Info */}
      <Card>
        <CardHeader>
          <CardTitle>Thông tin phiên làm việc</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium">Thời gian đăng nhập:</span>
              <p>{new Date(session_info.login_time).toLocaleString('vi-VN')}</p>
            </div>
            {session_info.user_agent && (
              <div>
                <span className="font-medium">User Agent:</span>
                <p className="text-xs text-muted-foreground break-all">
                  {session_info.user_agent}
                </p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Usage Stats */}
      {Object.keys(business.usage_stats).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Thống kê sử dụng</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {Object.entries(business.usage_stats).map(([feature, usage]) => (
                <div key={feature} className="text-center p-3 border rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">{usage as number}</div>
                  <div className="text-sm text-muted-foreground">{feature}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
