import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { createAdminClient } from "@/lib/supabase/admin";
import {
  Activity,
  AlertTriangle,
  BarChart3,
  Building2,
  DollarSign,
  Heart,
  Plus,
  RefreshCw,
  Users
} from "lucide-react";
import Link from "next/link";

export default async function SuperAdminPage() {
  const startTime = Date.now();
  console.log("🚀 [SUPER-ADMIN-PAGE] Starting page load...");
  
  const adminClient = createAdminClient();

  try {
    // ✅ IMPROVED: Load data with debug queries
    const [statsResult, businessesResult, debugResult] = await Promise.allSettled([
      // Main stats view
      adminClient
        .from('pos_mini_modular3_super_admin_stats')
        .select('*')
        .single(),
      
      // Business list
      adminClient
        .from('pos_mini_modular3_super_admin_businesses')
        .select('*')
        .order('created_at', { ascending: false }),
      
      // ✅ NEW: Debug query to check raw data
      adminClient
        .from('pos_mini_modular3_businesses')
        .select('id, name, status, subscription_tier, created_at')
    ]);

    // Handle results
    const stats = statsResult.status === 'fulfilled' && !statsResult.value.error 
      ? statsResult.value.data 
      : null;
    
    const businesses = businessesResult.status === 'fulfilled' && !businessesResult.value.error 
      ? businessesResult.value.data 
      : [];

    const debugData = debugResult.status === 'fulfilled' && !debugResult.value.error 
      ? debugResult.value.data 
      : [];

    // ✅ IMPROVED: Better fallback calculation based on actual data
    const fallbackStats = {
      total_businesses: debugData?.length || 0,
      active_businesses: debugData?.filter(b => b.status === 'active')?.length || 0,
      trial_businesses: debugData?.filter(b => b.status === 'trial')?.length || 0,
      total_users: Math.max(debugData?.length || 0, 1), // At least super admin
      total_owners: debugData?.length || 0, // Each business has 1 owner
      total_staff: 0, // Need separate query
      businesses_this_month: debugData?.filter(b => {
        const created = new Date(b.created_at);
        const now = new Date();
        return created.getMonth() === now.getMonth() && created.getFullYear() === now.getFullYear();
      })?.length || 0,
      estimated_revenue: debugData?.filter(b => b.status === 'active')?.length * 199000 || 0,
      revenue_growth: 0.15
    };

    const displayStats = stats || fallbackStats;
    
    // ✅ VALIDATION: Log data issues
    console.log("📊 [SUPER-ADMIN-PAGE] Data validation:", {
      source: stats ? 'view' : 'calculated',
      raw_businesses: debugData?.length,
      calculated_active: fallbackStats.active_businesses,
      view_active: stats?.active_businesses,
      data_consistent: stats?.total_businesses === debugData?.length
    });

    // ✅ Performance tracking
    const loadTime = Date.now() - startTime;
    console.log(`⏱️ [SUPER-ADMIN-PAGE] Data loaded in ${loadTime}ms`);

    return (
      <div className="space-y-6 md:space-y-8 animate-fade-in">
        {/* ✅ IMPROVED: Data quality warnings */}
        {!stats && (
          <Card className="border-amber-200 bg-amber-50 dark:bg-amber-900/20">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-amber-700 dark:text-amber-400">
                  <AlertTriangle className="w-5 h-5" />
                  <div>
                    <span className="font-medium">View thống kê chưa hoạt động</span>
                    <p className="text-sm">Đang tính toán từ dữ liệu thô ({debugData?.length || 0} businesses)</p>
                  </div>
                </div>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => window.location.reload()}
                  className="border-amber-300 text-amber-700 hover:bg-amber-100"
                >
                  <RefreshCw className="w-4 h-4 mr-1" />
                  Làm mới
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* ✅ IMPROVED: Show data quality info */}
        {displayStats.total_businesses > 0 && displayStats.active_businesses === 0 && (
          <Card className="border-blue-200 bg-blue-50 dark:bg-blue-900/20">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-blue-700 dark:text-blue-400">
                <Building2 className="w-5 h-5" />
                <span className="text-sm">
                  Có {displayStats.total_businesses} hộ kinh doanh đang ở giai đoạn thử nghiệm.
                  <strong> Cần kích hoạt để tính doanh thu.</strong>
                </span>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Welcome Message */}
        <div className="space-y-2">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
            Chào mừng trở lại!
          </h1>
          <p className="text-muted-foreground">
            Tổng quan hệ thống POS Mini Modular - {new Date().toLocaleDateString('vi-VN', { 
              weekday: 'long', 
              year: 'numeric', 
              month: 'long', 
              day: 'numeric' 
            })} • Load time: {loadTime}ms
          </p>
        </div>

        {/* ✅ IMPROVED: Stats với thông tin chi tiết hơn */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card className="bg-gradient-to-br from-blue-500 to-blue-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-blue-100">
                  Tổng số hộ KD
                </CardTitle>
                <Building2 className="w-5 h-5 text-blue-200" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{displayStats.total_businesses || 0}</div>
              <p className="text-xs text-blue-200 mt-1">
                +{displayStats.businesses_this_month || 0} hộ tháng này
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-green-500 to-green-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-green-100">
                  Hộ đang hoạt động
                </CardTitle>
                <Activity className="w-5 h-5 text-green-200" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{displayStats.active_businesses || 0}</div>
              <p className="text-xs text-green-200 mt-1">
                {displayStats.trial_businesses || 0} hộ đang thử nghiệm
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-yellow-500 to-orange-500 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-yellow-100">
                  Người dùng hệ thống
                </CardTitle>
                <Users className="w-5 h-5 text-yellow-200" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{displayStats.total_users || 0}</div>
              <p className="text-xs text-yellow-200 mt-1">
                {displayStats.total_owners || 0} chủ hộ • {displayStats.total_staff || 0} nhân viên
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-purple-500 to-purple-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-purple-100">
                  Doanh thu ước tính
                </CardTitle>
                <DollarSign className="w-5 h-5 text-purple-200" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">
                {(displayStats.estimated_revenue || 0).toLocaleString('vi-VN')} ₫
              </div>
              <p className="text-xs text-purple-200 mt-1">
                Từ {displayStats.active_businesses || 0} hộ đang hoạt động
              </p>
            </CardContent>
          </Card>
        </div>

        {/* ✅ ADDED BACK: Quick Actions */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Plus className="w-5 h-5 text-green-600" />
                Tạo hộ kinh doanh mới
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-sm mb-4">
                Tạo hộ kinh doanh mới với đầy đủ thông tin và tài khoản chủ hộ
              </p>
              <Button asChild className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800">
                <Link href="/super-admin/create-business">
                  <Plus className="w-4 h-4 mr-2" />
                  Tạo hộ mới
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <BarChart3 className="w-5 h-5 text-blue-600" />
                Phân tích & Báo cáo
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-sm mb-4">
                Xem báo cáo chi tiết về hoạt động của hệ thống
              </p>
              <Button asChild variant="outline" className="w-full">
                <Link href="/super-admin/analytics">
                  <BarChart3 className="w-4 h-4 mr-2" />
                  Xem báo cáo
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <AlertTriangle className="w-5 h-5 text-amber-600" />
                Cảnh báo hệ thống
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground text-sm mb-4">
                Kiểm tra các vấn đề cần xử lý trong hệ thống
              </p>
              <Button asChild variant="outline" className="w-full">
                <Link href="/super-admin/alerts">
                  <AlertTriangle className="w-4 h-4 mr-2" />
                  Xem cảnh báo
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* ✅ ADDED BACK: Gia Kiệm Số Branding Banner */}
        <Card className="shadow-lg border-0 bg-gradient-to-br from-purple-100 to-purple-200 dark:from-purple-900/30 dark:to-purple-800/30 border-purple-200/50 dark:border-purple-700/50">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl flex items-center justify-center shadow-lg">
                  <Heart className="w-8 h-8 text-white" />
                </div>
                <div>
                  <h3 className="text-xl font-bold text-purple-900 dark:text-purple-100 mb-1">
                    Được hỗ trợ bởi GiaKiemSo.com
                  </h3>
                  <p className="text-purple-700 dark:text-purple-300">
                    Giải pháp POS Mini toàn diện cho doanh nghiệp Việt - Tin cậy bởi <span className="font-semibold">1000+</span> doanh nghiệp
                  </p>
                </div>
              </div>
              <div className="hidden md:flex items-center gap-4 text-purple-600 dark:text-purple-400">
                <div className="text-center">
                  <div className="text-2xl font-bold">99.9%</div>
                  <div className="text-xs">Uptime</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold">24/7</div>
                  <div className="text-xs">Hỗ trợ</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold">∞</div>
                  <div className="text-xs">Tính năng</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 🎯 ADDED BACK: Business List Preview - PHẦN NÀY LÀ QUAN TRỌNG! */}
        <Card className="shadow-lg border-0 bg-gradient-to-br from-card to-card/50">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2 text-xl">
                <Building2 className="w-6 h-6 text-purple-600" />
                🏢 Hộ kinh doanh gần đây
              </CardTitle>
              <Button asChild variant="outline" size="sm">
                <Link href="/super-admin/businesses">
                  Xem tất cả ({(businesses?.length || debugData?.length || 0)} hộ)
                </Link>
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {/* ✅ IMPROVED: Show businesses từ view hoặc fallback từ raw data */}
            {(businesses && businesses.length > 0) || (debugData && debugData.length > 0) ? (
              <div className="space-y-3">
                {/* ✅ Ưu tiên businesses từ view, nếu không có thì dùng debugData */}
                {(businesses?.length > 0 ? businesses : debugData)?.slice(0, 5)?.map((business, index) => (
                  <div key={business.id} className="flex items-center justify-between p-4 rounded-lg bg-background/50 border hover:border-purple-200 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-purple-100 to-purple-200 dark:from-purple-900 dark:to-purple-800 flex items-center justify-center">
                        <Building2 className="w-5 h-5 text-purple-600" />
                      </div>
                      <div>
                        <p className="font-medium">
                          {business.business_name || business.name || `Hộ kinh doanh #${index + 1}`}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {business.owner_name || 'Chưa có thông tin chủ hộ'} • 
                          {business.business_type || 'Loại hình chưa xác định'} •
                          <span className="text-xs text-gray-500 ml-1">
                            {new Date(business.created_at).toLocaleDateString('vi-VN')}
                          </span>
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={business.status === 'active' ? 'default' : 'secondary'}>
                        {business.status === 'active' ? '🟢 Hoạt động' : 
                         business.status === 'trial' ? '🟡 Thử nghiệm' : 
                         '🔴 ' + business.status}
                      </Badge>
                      <Badge variant="outline" className="text-xs">
                        {business.subscription_tier || 'free'}
                      </Badge>
                    </div>
                  </div>
                ))}
                
                {/* ✅ Show summary info */}
                <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                  <div className="text-sm text-gray-600 dark:text-gray-400 flex items-center justify-between">
                    <span>
                      📊 Hiển thị {Math.min(5, (businesses?.length || debugData?.length || 0))} / {(businesses?.length || debugData?.length || 0)} hộ kinh doanh
                    </span>
                    <span>
                      🆕 {displayStats.businesses_this_month || 0} hộ mới tháng này
                    </span>
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <Building2 className="w-12 h-12 text-muted-foreground/50 mx-auto mb-4" />
                <p className="text-muted-foreground mb-2">
                  🏢 Chưa có hộ kinh doanh nào trong hệ thống
                </p>
                <p className="text-sm text-gray-500 mb-4">
                  Hãy tạo hộ kinh doanh đầu tiên để bắt đầu sử dụng hệ thống
                </p>
                <Button asChild className="mt-4" size="sm">
                  <Link href="/super-admin/create-business">
                    <Plus className="w-4 h-4 mr-2" />
                    Tạo hộ đầu tiên
                  </Link>
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        {/* ✅ NEW: Debug panel (chỉ show khi có vấn đề) */}
        {(!stats || displayStats.total_businesses !== debugData?.length) && (
          <Card className="border-gray-200 bg-gray-50 dark:bg-gray-900/20">
            <CardHeader>
              <CardTitle className="text-sm flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-gray-600" />
                🔧 Thông tin debug (cho dev)
              </CardTitle>
            </CardHeader>
            <CardContent className="text-xs space-y-1">
              <div>• Raw businesses count: {debugData?.length || 0}</div>
              <div>• View businesses count: {stats?.total_businesses || 'N/A'}</div>
              <div>• View businesses list: {businesses?.length || 0}</div>
              <div>• Active from raw: {debugData?.filter(b => b.status === 'active')?.length || 0}</div>
              <div>• Data source: {stats ? '🟢 database view' : '🟡 calculated fallback'}</div>
              <div>• Load time: {loadTime}ms</div>
            </CardContent>
          </Card>
        )}
      </div>
    );
  } catch (error) {
    console.error("🚨 [SUPER-ADMIN-PAGE] Error loading dashboard:", error);
    
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Card className="p-6 text-center">
          <AlertTriangle className="w-12 h-12 text-amber-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">Lỗi tải dữ liệu dashboard</h3>
          <p className="text-muted-foreground mb-4">
            Database có thể chưa được setup đúng cách. Vui lòng kiểm tra migrations.
          </p>
          <div className="space-x-2">
            <Button onClick={() => window.location.reload()}>
              <RefreshCw className="w-4 h-4 mr-2" />
              Thử lại
            </Button>
            <Button asChild variant="outline">
              <Link href="/super-admin/create-business">
                Tạo business đầu tiên
              </Link>
            </Button>
          </div>
        </Card>
      </div>
    );
  }
}
