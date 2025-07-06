import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { createClient } from '@/lib/supabase/server';
import {
  AlertCircle,
  BarChart3,
  CheckCircle,
  Clock,
  DollarSign,
  Package,
  ShoppingCart,
  TrendingUp,
  Users
} from 'lucide-react';
import Link from 'next/link';
import { redirect } from 'next/navigation';

// Define proper types
interface ProfileData {
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
    status?: string;
    subscription_tier?: string;
    [key: string]: unknown;
  };
  // Legacy fields for backward compatibility
  business_id?: string;
  business_name?: string;
  business_type?: string;
  status?: string;
  subscription_tier?: string;
  role?: string;
  full_name?: string;
  error?: string;
}

interface RPCResult {
  data: ProfileData | null;
  error: Error | null;
}

export default async function DashboardPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return redirect('/auth/login');
  }

  // ✅ Get user profile for business dashboard access
  let profileData: ProfileData | null = null;
  let rpcError: Error | null = null;
  
  try {
    const result = await supabase.rpc(
      'pos_mini_modular3_get_user_profile_safe',
      { p_user_id: user.id }
    ) as RPCResult;
    
    profileData = result.data;
    rpcError = result.error;

    // Debug: Log the entire structure
    if (profileData) {
      console.log('🔍 [DASHBOARD-DEBUG] ProfileData structure:', JSON.stringify(profileData, null, 2));
      console.log('🔍 [DASHBOARD-DEBUG] Profile object:', profileData.profile);
      console.log('🔍 [DASHBOARD-DEBUG] Business object:', profileData.business);
      console.log('🔍 [DASHBOARD-DEBUG] Legacy business_id:', profileData.business_id);
    }

    console.log("📊 [DASHBOARD] RPC Profile result:", {
      success: !!profileData,
      hasProfile: profileData?.profile_exists,
      businessId: profileData?.profile?.business_id || profileData?.business_id,
      businessName: profileData?.business?.name || profileData?.business_name,
      role: profileData?.profile?.role || profileData?.role,
      error: rpcError?.message
    });

  } catch (error) {
    console.error("❌ [DASHBOARD] RPC call failed:", error);
    rpcError = error instanceof Error ? error : new Error('Unknown error');
  }

  // Handle RPC errors
  if (rpcError) {
    console.error("❌ [DASHBOARD] RPC Error:", rpcError);
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-red-600">
              <AlertCircle className="w-5 h-5" />
              Lỗi tải dữ liệu
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600 mb-4">
              Không thể tải thông tin tài khoản. Vui lòng thử lại.
            </p>
            <Button asChild className="w-full">
              <Link href="/auth/login">Đăng nhập lại</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Check profile existence
  if (!profileData?.profile_exists) {
    console.log("❌ [DASHBOARD] No profile found, redirecting to sign-up");
    return redirect('/auth/sign-up');
  }

  // Extract data from new structure
  const businessId = profileData?.profile?.business_id || profileData?.business_id;
  const businessName = profileData?.business?.name || profileData?.business_name;
  const userRole = profileData?.profile?.role || profileData?.role;
  const fullName = profileData?.profile?.full_name || profileData?.full_name;
  const businessStatus = profileData?.business?.status || profileData?.status || 'active';

  // Check business membership
  if (!businessId) {
    console.log("❌ [DASHBOARD] No business found, redirecting to business creation");
    return redirect('/auth/sign-up?step=business');
  }

  console.log("✅ [DASHBOARD] Dashboard access granted:", {
    businessId: businessId,
    businessName: businessName,
    role: userRole
  });

  // Get business statistics (mock data for now)
  const businessStats = {
    totalProducts: 0,
    totalSales: 0,
    totalCustomers: 0,
    monthlyRevenue: 0,
    dailySales: 0,
    pendingOrders: 0,
    lowStockItems: 0,
    activeStaff: 1
  };

  // Quick stats cards data
  const quickStats = [
    {
      title: 'Doanh thu tháng',
      value: businessStats.monthlyRevenue.toLocaleString() + ' ₫',
      icon: DollarSign,
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      trend: '+12%'
    },
    {
      title: 'Đơn hàng hôm nay',
      value: businessStats.dailySales.toString(),
      icon: ShoppingCart,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      trend: '+5%'
    },
    {
      title: 'Sản phẩm',
      value: businessStats.totalProducts.toString(),
      icon: Package,
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
      trend: 'Mới'
    },
    {
      title: 'Nhân viên',
      value: businessStats.activeStaff.toString(),
      icon: Users,
      color: 'text-orange-600',
      bgColor: 'bg-orange-50',
      trend: 'Hoạt động'
    }
  ];

  // Quick actions
  const quickActions = [
    {
      title: 'Quản lý sản phẩm',
      description: 'Thêm, sửa, xóa sản phẩm',
      href: '/dashboard/products',
      icon: Package,
      color: 'from-blue-500 to-blue-600'
    },
    {
      title: 'Bán hàng',
      description: 'Tạo đơn hàng mới',
      href: '/dashboard/pos',
      icon: ShoppingCart,
      color: 'from-green-500 to-green-600'
    },
    {
      title: 'Báo cáo',
      description: 'Xem thống kê và báo cáo',
      href: '/dashboard/reports',
      icon: BarChart3,
      color: 'from-purple-500 to-purple-600'
    },
    {
      title: 'Nhân viên',
      description: 'Quản lý nhân viên',
      href: '/dashboard/staff',
      icon: Users,
      color: 'from-orange-500 to-orange-600'
    }
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">
            Chào mừng trở lại!
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            {businessName} • {fullName}
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <Badge variant="outline" className="text-xs">
            {userRole}
          </Badge>
          <Badge 
            variant={businessStatus === 'active' ? 'default' : 'secondary'}
            className="text-xs"
          >
            {businessStatus === 'active' ? 'Hoạt động' : 'Thử nghiệm'}
          </Badge>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {quickStats.map((stat) => (
          <Card key={stat.title} className="hover:shadow-md transition-shadow">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                    {stat.title}
                  </p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {stat.value}
                  </p>
                  <p className="text-xs text-green-600 mt-1">
                    {stat.trend}
                  </p>
                </div>
                <div className={`p-2 rounded-lg ${stat.bgColor}`}>
                  <stat.icon className={`w-6 h-6 ${stat.color}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {quickActions.map((action) => (
          <Card key={action.title} className="hover:shadow-lg transition-all duration-200 hover:scale-105 group cursor-pointer">
            <Link href={action.href}>
              <CardContent className="p-6 text-center">
                <div className={`w-12 h-12 mx-auto mb-4 rounded-lg bg-gradient-to-r ${action.color} flex items-center justify-center group-hover:scale-110 transition-transform`}>
                  <action.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-2 group-hover:text-blue-600 transition-colors">
                  {action.title}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {action.description}
                </p>
              </CardContent>
            </Link>
          </Card>
        ))}
      </div>

      {/* Recent Activity & Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="w-5 h-5" />
              Hoạt động gần đây
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="text-center py-8 text-gray-500">
                <Package className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                <p>Chưa có hoạt động nào</p>
                <p className="text-sm">Bắt đầu bằng cách thêm sản phẩm đầu tiên</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Alerts & Notifications */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertCircle className="w-5 h-5" />
              Thông báo
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-start gap-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <CheckCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                <div>
                  <p className="font-medium text-blue-900 dark:text-blue-100">
                    Chào mừng đến với POS Mini!
                  </p>
                  <p className="text-sm text-blue-700 dark:text-blue-300">
                    Hệ thống đã sẵn sàng để bạn bắt đầu kinh doanh.
                  </p>
                </div>
              </div>

              {businessStats.lowStockItems > 0 && (
                <div className="flex items-start gap-3 p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg">
                  <AlertCircle className="w-5 h-5 text-orange-600 mt-0.5" />
                  <div>
                    <p className="font-medium text-orange-900 dark:text-orange-100">
                      Sản phẩm sắp hết hàng
                    </p>
                    <p className="text-sm text-orange-700 dark:text-orange-300">
                      {businessStats.lowStockItems} sản phẩm cần nhập thêm hàng.
                    </p>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Getting Started Guide */}
      <Card className="border-dashed border-2 border-gray-300 dark:border-gray-600">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5" />
            Bắt đầu nhanh
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="font-bold text-blue-600">1</span>
              </div>
              <h4 className="font-medium mb-2">Thêm sản phẩm</h4>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                Bắt đầu bằng cách thêm sản phẩm vào kho
              </p>
              <Button asChild variant="outline" size="sm">
                <Link href="/dashboard/products">
                  Thêm sản phẩm
                </Link>
              </Button>
            </div>

            <div className="text-center">
              <div className="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="font-bold text-green-600">2</span>
              </div>
              <h4 className="font-medium mb-2">Mời nhân viên</h4>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                Thêm nhân viên để cùng quản lý cửa hàng
              </p>
              <Button asChild variant="outline" size="sm">
                <Link href="/dashboard/staff">
                  Mời nhân viên
                </Link>
              </Button>
            </div>

            <div className="text-center">
              <div className="w-10 h-10 bg-purple-100 dark:bg-purple-900 rounded-full flex items-center justify-center mx-auto mb-3">
                <span className="font-bold text-purple-600">3</span>
              </div>
              <h4 className="font-medium mb-2">Bắt đầu bán</h4>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                Tạo đơn hàng đầu tiên của bạn
              </p>
              <Button asChild variant="outline" size="sm">
                <Link href="/dashboard/pos">
                  Bán hàng
                </Link>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
