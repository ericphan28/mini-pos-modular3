import { CreateBusinessFormOptimizedWithErrorBoundary } from "@/components/super-admin/create-business-form-optimized";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ArrowLeft, Building2, Plus } from "lucide-react";
import Link from "next/link";
import { Suspense } from "react";

// 🚀 PERFORMANCE: No auth validation needed - Layout already handles it
// 🚀 OPTIMIZATION: Removed duplicate validateSuperAdminAccess

// 🚀 PERFORMANCE: Loading component for suspense
function CreateBusinessLoading() {
  return (
    <div className="space-y-6 md:space-y-8 animate-pulse">
      <div className="flex items-center gap-4">
        <div className="w-32 h-10 bg-gray-200 rounded"></div>
        <div className="space-y-2">
          <div className="w-64 h-8 bg-gray-200 rounded"></div>
          <div className="w-96 h-4 bg-gray-200 rounded"></div>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 h-96 bg-gray-200 rounded"></div>
        <div className="space-y-6">
          <div className="h-48 bg-gray-200 rounded"></div>
          <div className="h-32 bg-gray-200 rounded"></div>
        </div>
      </div>
    </div>
  );
}

// 🚀 PERFORMANCE: Sidebar component được optimize
function OptimizedSidebar() {
  return (
    <div className="space-y-6">
      {/* Help & Guidelines */}
      <Card className="shadow-lg border-0 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <Building2 className="w-5 h-5 text-blue-600" />
            Hướng dẫn nhanh
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-sm text-blue-700 dark:text-blue-200 space-y-2">
            <div>✅ Tên hộ kinh doanh</div>
            <div>✅ Họ tên chủ hộ</div>
            <div>✅ Email hoặc số điện thoại</div>
            <div>✅ Loại hình kinh doanh</div>
          </div>
        </CardContent>
      </Card>

      {/* Service Tiers */}
      <Card className="shadow-lg border-0 bg-gradient-to-br from-amber-50 to-amber-100 dark:from-amber-900/20 dark:to-amber-800/20">
        <CardHeader>
          <CardTitle className="text-lg text-amber-900 dark:text-amber-100">
            Gói dịch vụ
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {[
            { name: 'Miễn phí', desc: '1 người dùng, tính năng cơ bản' },
            { name: 'Cơ bản', desc: '3 người dùng, báo cáo nâng cao' },
            { name: 'Cao cấp', desc: 'Không giới hạn, API, tích hợp' }
          ].map((tier, idx) => (
            <div key={idx} className="p-3 bg-white/50 dark:bg-gray-800/50 rounded-lg">
              <h5 className="font-semibold text-sm">{tier.name}</h5>
              <p className="text-xs text-muted-foreground">{tier.desc}</p>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

export default function CreateBusinessPage() {
  // 🚀 ULTRA-PERFORMANCE: No auth check needed - Layout handles it
  // This eliminates the duplicate checkSuperAdminAccess calls

  return (
    <div className="space-y-6 md:space-y-8 animate-fade-in">
      {/* Header - Optimized */}
      <div className="flex items-center gap-4">
        <Button asChild variant="outline" size="sm">
          <Link href="/super-admin">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Quay lại
          </Link>
        </Button>
        <div className="space-y-1">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
            Tạo hộ kinh doanh mới
          </h1>
          <p className="text-muted-foreground">
            Tạo hộ kinh doanh mới với đầy đủ thông tin và quyền quản lý
          </p>
        </div>
      </div>

      {/* Main Content - With Suspense */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Form Card */}
        <div className="lg:col-span-2">
          <Card className="shadow-lg border-0 bg-gradient-to-br from-card to-card/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-xl">
                <Plus className="w-6 h-6 text-green-600" />
                Thông tin hộ kinh doanh
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Suspense fallback={<CreateBusinessLoading />}>
                <CreateBusinessFormOptimizedWithErrorBoundary />
              </Suspense>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <OptimizedSidebar />
      </div>
    </div>
  );
}
