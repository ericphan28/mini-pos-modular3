import { BusinessListProfessional } from "@/components/super-admin/business-list-professional";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { checkSuperAdminAccess, createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { ArrowLeft, Building2, Plus, TrendingUp } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

// Define BusinessInfo type locally for type safety
interface BusinessInfo {
  id: string;
  business_name: string;
  business_code: string;
  business_type: string;
  status: string;
  subscription_tier: string;
  subscription_status: string;
  trial_ends_at: string;
  subscription_ends_at: string;
  created_at: string;
  updated_at: string;
  owner_name: string;
  owner_email: string;
  owner_status: string;
  owner_id: string;
  total_staff: number;
  active_staff: number;
}

// 🚀 Performance Logging
function logPagePerformance(startTime: number, businessCount: number) {
  const loadTime = Date.now() - startTime;
  console.log(`📊 [BUSINESSES-PAGE] Loaded in ${loadTime}ms with ${businessCount} businesses`);
  
  if (loadTime > 1000) {
    console.warn(`⚠️ [SLOW-PAGE] Businesses page took ${loadTime}ms to load`);
  }
  
  return loadTime;
}

export default async function BusinessesPage() {
  const pageStartTime = Date.now();
  console.log('🚀 [BUSINESSES-PAGE] Starting page load...');

  // 🔐 Authentication & Authorization
  const authTimer = Date.now();
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    console.log('❌ [BUSINESSES-PAGE] No user found, redirecting to login');
    return redirect("/auth/login");
  }

  console.log(`🔐 [BUSINESSES-PAGE] User authenticated: ${user.email} (${Date.now() - authTimer}ms)`);

  // Check if user is super admin
  const adminCheckTimer = Date.now();
  const isSuperAdmin = await checkSuperAdminAccess(user.id);
  
  if (!isSuperAdmin) {
    console.log('❌ [BUSINESSES-PAGE] User is not super admin, redirecting');
    return redirect("/dashboard");
  }

  console.log(`🛡️ [BUSINESSES-PAGE] Super admin access verified (${Date.now() - adminCheckTimer}ms)`);

  // 📊 Data Fetching with Performance Monitoring
  const dataTimer = Date.now();
  const adminClient = createAdminClient();
  
  try {
    console.log('📊 [BUSINESSES-PAGE] Fetching business data...');
    
    const { data: businesses, error }: { data: BusinessInfo[] | null; error: unknown } = await adminClient
      .from('pos_mini_modular3_super_admin_businesses')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ [BUSINESSES-PAGE] Database error:', error);
      throw error;
    }

    const businessCount = businesses?.length || 0;
    const dataLoadTime = Date.now() - dataTimer;
    
    console.log(`✅ [BUSINESSES-PAGE] Data loaded: ${businessCount} businesses (${dataLoadTime}ms)`);

    // 📊 Quick Analytics
    const analytics = {
      total: businessCount,
      active: businesses?.filter(b => b.status === 'active').length || 0,
      trial: businesses?.filter(b => b.status === 'trial').length || 0,
      suspended: businesses?.filter(b => b.status === 'suspended').length || 0,
      cancelled: businesses?.filter(b => b.status === 'cancelled').length || 0,
    };

    console.log('📈 [BUSINESSES-PAGE] Quick analytics:', analytics);

    // Log total performance
    const totalLoadTime = logPagePerformance(pageStartTime, businessCount);

    return (
      <div className="space-y-6 md:space-y-8 animate-fade-in">
        {/* 📊 Enhanced Header with Analytics */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Button asChild variant="outline" size="sm">
              <Link href="/super-admin">
                <ArrowLeft className="w-4 h-4 mr-2" />
                Quay lại Dashboard
              </Link>
            </Button>
            <div className="space-y-1">
              <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
                Quản lý hộ kinh doanh
              </h1>
              <p className="text-muted-foreground">
                Danh sách và quản lý tất cả hộ kinh doanh trong hệ thống • Tải trong {totalLoadTime}ms
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Button asChild variant="outline" size="sm">
              <Link href="/super-admin/analytics">
                <TrendingUp className="w-4 h-4 mr-2" />
                Thống kê
              </Link>
            </Button>
            <Button asChild className="bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800">
              <Link href="/super-admin/create-business">
                <Plus className="w-4 h-4 mr-2" />
                Tạo hộ mới
              </Link>
            </Button>
          </div>
        </div>

        {/* 📊 Quick Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <Card className="border-l-4 border-l-blue-500">
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-blue-600">{analytics.total}</div>
              <div className="text-xs text-muted-foreground">Tổng hộ KD</div>
            </CardContent>
          </Card>
          
          <Card className="border-l-4 border-l-green-500">
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-green-600">{analytics.active}</div>
              <div className="text-xs text-muted-foreground">Hoạt động</div>
            </CardContent>
          </Card>
          
          <Card className="border-l-4 border-l-blue-400">
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-blue-400">{analytics.trial}</div>
              <div className="text-xs text-muted-foreground">Dùng thử</div>
            </CardContent>
          </Card>
          
          <Card className="border-l-4 border-l-yellow-500">
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-yellow-600">{analytics.suspended}</div>
              <div className="text-xs text-muted-foreground">Tạm dừng</div>
            </CardContent>
          </Card>
          
          <Card className="border-l-4 border-l-red-500">
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-red-600">{analytics.cancelled}</div>
              <div className="text-xs text-muted-foreground">Đã hủy</div>
            </CardContent>
          </Card>
        </div>

        {/* 📊 Professional Business List */}
        <Card className="shadow-lg border-0 bg-gradient-to-br from-card to-card/50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-xl">
              <Building2 className="w-6 h-6 text-purple-600" />
              Danh sách hộ kinh doanh
              <span className="ml-auto text-sm font-normal text-muted-foreground">
                {businessCount} hộ
              </span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <BusinessListProfessional businesses={businesses || []} />
          </CardContent>
        </Card>
      </div>
    );

  } catch (error) {
    console.error('❌ [BUSINESSES-PAGE] Failed to load:', error);
    
    return (
      <div className="space-y-6 md:space-y-8">
        <div className="flex items-center gap-4">
          <Button asChild variant="outline" size="sm">
            <Link href="/super-admin">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Quay lại Dashboard
            </Link>
          </Button>
          <div className="space-y-1">
            <h1 className="text-3xl font-bold text-red-600">
              Lỗi tải dữ liệu
            </h1>
            <p className="text-muted-foreground">
              Không thể tải danh sách hộ kinh doanh. Vui lòng thử lại.
            </p>
          </div>
        </div>

        <Card className="border-red-200 bg-red-50">
          <CardContent className="p-6">
            <div className="text-center space-y-4">
              <div className="text-4xl">❌</div>
              <div className="text-lg font-medium text-red-800">
                Không thể tải dữ liệu hộ kinh doanh
              </div>
              <div className="text-sm text-red-600">
                {error instanceof Error ? error.message : 'Lỗi không xác định'}
              </div>
              <Button 
                variant="outline" 
                onClick={() => window.location.reload()}
                className="mt-4"
              >
                Thử lại
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }
}
