'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { optimizedLogger } from '@/lib/utils/optimized-logger';
import { SessionCacheManager, type CompleteUserSession } from '@/lib/utils/session-cache';
import { AlertCircle, Archive, CheckCircle, Database, RefreshCw, Trash2, XCircle } from 'lucide-react';
import { useState } from 'react';

export default function TestSessionCachePage() {
  const [cachedSession, setCachedSession] = useState<CompleteUserSession | null>(null);
  const [cacheStatus, setCacheStatus] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const checkCache = (): void => {
    try {
      setLoading(true);
      optimizedLogger.info('TEST', 'Kiểm tra session cache');
      
      const session = SessionCacheManager.getCachedSession();
      
      if (session) {
        setCachedSession(session);
        setCacheStatus('Cache tồn tại và hợp lệ');
        optimizedLogger.success('TEST', 'Tìm thấy cached session', {
          userId: session.user.id,
          businessId: session.business.id,
          loginTime: session.session_info.login_time
        });
      } else {
        setCachedSession(null);
        setCacheStatus('Không có cache hoặc cache đã hết hạn');
        optimizedLogger.warn('TEST', 'Không tìm thấy cached session');
      }
    } catch (error) {
      setCacheStatus(`Lỗi khi kiểm tra cache: ${error instanceof Error ? error.message : 'Unknown error'}`);
      optimizedLogger.error('TEST', 'Lỗi khi kiểm tra cache', error);
    } finally {
      setLoading(false);
    }
  };

  const clearCache = (): void => {
    try {
      setLoading(true);
      optimizedLogger.info('TEST', 'Xóa session cache');
      
      SessionCacheManager.clearCache();
      setCachedSession(null);
      setCacheStatus('Cache đã được xóa');
      
      optimizedLogger.success('TEST', 'Cache đã được xóa thành công');
    } catch (error) {
      setCacheStatus(`Lỗi khi xóa cache: ${error instanceof Error ? error.message : 'Unknown error'}`);
      optimizedLogger.error('TEST', 'Lỗi khi xóa cache', error);
    } finally {
      setLoading(false);
    }
  };

  const createMockSession = (): void => {
    try {
      setLoading(true);
      optimizedLogger.info('TEST', 'Tạo mock session để test cache');
      
      const mockSession: CompleteUserSession = {
        success: true,
        profile_exists: true,
        user: {
          id: 'test-user-id',
          profile_id: 'test-profile-id',
          email: 'test@example.com',
          role: 'admin',
          full_name: 'Test User',
          phone: '+84123456789',
          login_method: 'email',
          status: 'active'
        },
        business: {
          id: 'test-business-id',
          name: 'Test Business',
          business_type: 'restaurant',
          business_type_name: 'Nhà hàng',
          business_code: 'TEST001',
          contact_email: 'business@test.com',
          contact_phone: '+84987654321',
          address: '123 Test Street, Test City',
          subscription_tier: 'premium',
          subscription_status: 'active',
          trial_end_date: null,
          features_enabled: {
            pos: true,
            inventory: true,
            reporting: true,
            multi_location: false
          },
          usage_stats: {
            transactions_this_month: 150,
            revenue_this_month: 45000000
          },
          status: 'active'
        },
        permissions: {
          'pos.view': true,
          'pos.create': true,
          'pos.edit': true,
          'pos.delete': false,
          'inventory.view': true,
          'inventory.manage': true,
          'reports.view': true,
          'settings.manage': true
        },
        session_info: {
          login_time: new Date().toISOString(),
          user_agent: 'Mozilla/5.0 (Test Browser)'
        }
      };
      
      SessionCacheManager.cacheSession(mockSession);
      setCachedSession(mockSession);
      setCacheStatus('Mock session đã được tạo và cache');
      
      optimizedLogger.success('TEST', 'Mock session đã được tạo và cache thành công', {
        userId: mockSession.user.id,
        businessId: mockSession.business.id
      });
    } catch (error) {
      setCacheStatus(`Lỗi khi tạo mock session: ${error instanceof Error ? error.message : 'Unknown error'}`);
      optimizedLogger.error('TEST', 'Lỗi khi tạo mock session', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Test Session Cache System
        </h1>
        <p className="text-gray-600">
          Kiểm tra hệ thống cache session để tối ưu hóa hiệu suất đăng nhập
        </p>
      </div>

      {/* Controls */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Archive className="w-5 h-5" />
            Cache Controls
          </CardTitle>
          <CardDescription>
            Kiểm tra, tạo mock, và xóa session cache
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-3">
            <Button
              onClick={checkCache}
              disabled={loading}
              className="flex items-center gap-2"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Kiểm tra Cache
            </Button>
            
            <Button
              onClick={createMockSession}
              disabled={loading}
              variant="outline"
              className="flex items-center gap-2"
            >
              <Database className="w-4 h-4" />
              Tạo Mock Session
            </Button>
            
            <Button
              onClick={clearCache}
              disabled={loading}
              variant="destructive"
              className="flex items-center gap-2"
            >
              <Trash2 className="w-4 h-4" />
              Xóa Cache
            </Button>
          </div>
          
          {cacheStatus && (
            <div className="mt-4 p-3 rounded-lg bg-blue-50 border border-blue-200">
              <div className="flex items-center gap-2 text-blue-700">
                {cachedSession ? (
                  <CheckCircle className="w-4 h-4" />
                ) : cacheStatus.includes('Lỗi') ? (
                  <XCircle className="w-4 h-4" />
                ) : (
                  <AlertCircle className="w-4 h-4" />
                )}
                <span className="text-sm font-medium">{cacheStatus}</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Cache Data Display */}
      {cachedSession && (
        <div className="space-y-6">
          {/* User Info */}
          <Card>
            <CardHeader>
              <CardTitle>User Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-500">User ID</label>
                  <p className="font-mono text-sm">{cachedSession.user.id}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Email</label>
                  <p>{cachedSession.user.email}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Full Name</label>
                  <p>{cachedSession.user.full_name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Role</label>
                  <p className="font-medium text-blue-600">{cachedSession.user.role}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Status</label>
                  <p className="text-green-600">{cachedSession.user.status}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Login Method</label>
                  <p>{cachedSession.user.login_method}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Business Info */}
          <Card>
            <CardHeader>
              <CardTitle>Business Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-500">Business ID</label>
                  <p className="font-mono text-sm">{cachedSession.business.id}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Business Name</label>
                  <p className="font-medium">{cachedSession.business.name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Business Type</label>
                  <p>{cachedSession.business.business_type_name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Subscription</label>
                  <p className="font-medium text-purple-600">
                    {cachedSession.business.subscription_tier} ({cachedSession.business.subscription_status})
                  </p>
                </div>
                <div className="md:col-span-2">
                  <label className="text-sm font-medium text-gray-500">Address</label>
                  <p>{cachedSession.business.address || 'Không có địa chỉ'}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Permissions */}
          <Card>
            <CardHeader>
              <CardTitle>Permissions ({Object.keys(cachedSession.permissions).length} quyền)</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
                {Object.entries(cachedSession.permissions).map(([permission, enabled]) => (
                  <div key={permission} className="flex items-center gap-2">
                    {enabled ? (
                      <CheckCircle className="w-4 h-4 text-green-500" />
                    ) : (
                      <XCircle className="w-4 h-4 text-red-500" />
                    )}
                    <span className={`text-sm ${enabled ? 'text-green-700' : 'text-red-700'}`}>
                      {permission}
                    </span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Session Info */}
          <Card>
            <CardHeader>
              <CardTitle>Session Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-500">Login Time</label>
                  <p className="font-mono text-sm">{cachedSession.session_info.login_time}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">User Agent</label>
                  <p className="text-sm text-gray-600 break-all">
                    {cachedSession.session_info.user_agent || 'Không có thông tin'}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Features & Usage Stats */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Features Enabled</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {Object.entries(cachedSession.business.features_enabled as Record<string, boolean>).map(([feature, enabled]) => (
                    <div key={feature} className="flex items-center gap-2">
                      {enabled ? (
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      ) : (
                        <XCircle className="w-4 h-4 text-red-500" />
                      )}
                      <span className={`text-sm ${enabled ? 'text-green-700' : 'text-red-700'}`}>
                        {feature}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Usage Statistics</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {Object.entries(cachedSession.business.usage_stats as Record<string, unknown>).map(([stat, value]) => (
                    <div key={stat}>
                      <label className="text-sm font-medium text-gray-500 capitalize">
                        {stat.replace(/_/g, ' ')}
                      </label>
                      <p className="font-medium">{String(value)}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )}

      {/* Instructions */}
      <Card className="mt-8">
        <CardHeader>
          <CardTitle>Hướng dẫn sử dụng</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 text-sm">
            <p><strong>1. Kiểm tra Cache:</strong> Xem session hiện tại có được cache không</p>
            <p><strong>2. Tạo Mock Session:</strong> Tạo session giả để test cache (5 phút TTL)</p>
            <p><strong>3. Xóa Cache:</strong> Xóa session cache hiện tại</p>
            <p><strong>4. Test Flow:</strong> Đăng nhập bình thường → Check cache → Reload page → Session vẫn có từ cache</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
