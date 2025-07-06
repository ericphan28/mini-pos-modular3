import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { checkSuperAdminAccess } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { AlertTriangle, ArrowLeft, BarChart3, Database, Settings, Shield, Users } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

export default async function SettingsPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return redirect("/auth/login");
  }

  // Check if user is super admin
  const isSuperAdmin = await checkSuperAdminAccess(user.id);
  
  if (!isSuperAdmin) {
    return redirect("/dashboard");
  }

  return (
    <div className="space-y-6 md:space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button asChild variant="outline" size="sm">
          <Link href="/super-admin">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Quay lại Dashboard
          </Link>
        </Button>
        <div className="space-y-1">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
            Cài đặt hệ thống
          </h1>
          <p className="text-muted-foreground">
            Quản lý cấu hình và thiết lập hệ thống POS Mini Modular
          </p>
        </div>
      </div>

      {/* Settings Categories */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Database Management */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
                <Database className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Database Management</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Backup và restore database
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Quản lý backup, restore và migration dữ liệu hệ thống
              </div>
              <Button asChild className="w-full" variant="outline">
                <Link href="/super-admin/settings/database">
                  <Database className="w-4 h-4 mr-2" />
                  Quản lý Database
                </Link>
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* System Configuration */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center">
                <Settings className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">System Configuration</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Cấu hình hệ thống chung
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Thiết lập các tham số hệ thống, email templates, và notifications
              </div>
              <Button className="w-full" variant="outline" disabled>
                <Settings className="w-4 h-4 mr-2" />
                Cấu hình hệ thống
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* User Management */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center">
                <Users className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">User Management</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Quản lý super admin
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Thêm, xóa và quản lý quyền các super admin trong hệ thống
              </div>
              <Button className="w-full" variant="outline" disabled>
                <Users className="w-4 h-4 mr-2" />
                Quản lý Admin
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Security */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-red-500 to-red-600 rounded-lg flex items-center justify-center">
                <Shield className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Security & Audit</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Bảo mật và audit logs
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Xem logs hoạt động, cấu hình bảo mật và monitoring
              </div>
              <Button className="w-full" variant="outline" disabled>
                <Shield className="w-4 h-4 mr-2" />
                Security Settings
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Analytics */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg flex items-center justify-center">
                <BarChart3 className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Analytics & Reports</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Báo cáo và thống kê
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Xem báo cáo tổng quan, export dữ liệu và analytics
              </div>
              <Button className="w-full" variant="outline" disabled>
                <BarChart3 className="w-4 h-4 mr-2" />
                Xem báo cáo
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Maintenance */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50 hover:scale-105 transition-transform duration-200">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-yellow-500 to-yellow-600 rounded-lg flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Maintenance Mode</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Bảo trì hệ thống
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="text-sm text-muted-foreground">
                Bật/tắt chế độ bảo trì, thông báo downtime
              </div>
              <Button className="w-full" variant="outline" disabled>
                <AlertTriangle className="w-4 h-4 mr-2" />
                Maintenance Mode
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* System Information */}
      <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
        <CardHeader className="border-b border-border/50">
          <CardTitle className="text-lg">Thông tin hệ thống</CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <h4 className="font-medium text-sm mb-2">Version</h4>
              <p className="text-2xl font-bold text-primary">3.1.0</p>
              <p className="text-xs text-muted-foreground">POS Mini Modular</p>
            </div>
            <div>
              <h4 className="font-medium text-sm mb-2">Environment</h4>
              <p className="text-2xl font-bold text-green-600">Production</p>
              <p className="text-xs text-muted-foreground">Supabase Cloud</p>
            </div>
            <div>
              <h4 className="font-medium text-sm mb-2">Last Updated</h4>
              <p className="text-2xl font-bold text-blue-600">Today</p>
              <p className="text-xs text-muted-foreground">July 1, 2025</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
