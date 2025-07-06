import { DatabaseBackupClient } from "@/components/super-admin/database-backup-client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { checkSuperAdminAccess } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { AlertTriangle, Archive, ArrowLeft, Clock, Database, HardDrive, Shield, Upload } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

export default async function DatabaseManagementPage() {
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

  // Get database statistics
  const databaseStats = {
    total_tables: 12,
    total_functions: 15,
    total_records: 0,
    database_size: "0 MB",
    last_backup: null
  };

  try {
    // Get basic statistics
    const { data: businesses } = await supabase.from('pos_mini_modular3_businesses').select('id');
    const { data: users } = await supabase.from('pos_mini_modular3_user_profiles').select('id');
    
    databaseStats.total_records = (businesses?.length || 0) + (users?.length || 0);
  } catch (error) {
    console.error('Error getting database stats:', error);
  }

  return (
    <div className="space-y-6 md:space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button asChild variant="outline" size="sm">
          <Link href="/super-admin/settings">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Quay lại Settings
          </Link>
        </Button>
        <div className="space-y-1">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-700 to-blue-900 dark:from-blue-300 dark:to-blue-100 bg-clip-text text-transparent">
            Quản lý Database
          </h1>
          <p className="text-muted-foreground">
            Backup, restore và quản lý dữ liệu hệ thống
          </p>
        </div>
      </div>

      {/* Database Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="bg-gradient-to-br from-blue-500 to-blue-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-medium text-blue-100">
                Tổng Tables
              </CardTitle>
              <Database className="w-5 h-5 text-blue-200" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{databaseStats.total_tables}</div>
            <p className="text-xs text-blue-200 mt-1">
              Tables hệ thống
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-500 to-green-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-medium text-green-100">
                Functions
              </CardTitle>
              <HardDrive className="w-5 h-5 text-green-200" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{databaseStats.total_functions}</div>
            <p className="text-xs text-green-200 mt-1">
              Stored procedures
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-purple-500 to-purple-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-medium text-purple-100">
                Tổng Records
              </CardTitle>
              <Archive className="w-5 h-5 text-purple-200" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{databaseStats.total_records.toLocaleString()}</div>
            <p className="text-xs text-purple-200 mt-1">
              Dữ liệu hệ thống
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-orange-500 to-orange-600 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200 hover:scale-105">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-medium text-orange-100">
                Database Size
              </CardTitle>
              <HardDrive className="w-5 h-5 text-orange-200" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{databaseStats.database_size}</div>
            <p className="text-xs text-orange-200 mt-1">
              Dung lượng sử dụng
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Backup Management */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Full Database Backup */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
                <Database className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Full Database Backup</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Backup toàn bộ schema và dữ liệu
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Clock className="w-4 h-4" />
                <span>Backup cuối: {databaseStats.last_backup || 'Chưa có'}</span>
              </div>
              
              <div className="space-y-3">
                <div className="p-3 bg-muted/50 rounded-lg">
                  <h4 className="font-medium text-sm mb-2">Bao gồm:</h4>
                  <ul className="text-xs space-y-1 text-muted-foreground">
                    <li>• Schema (tables, functions, RLS policies)</li>
                    <li>• Dữ liệu businesses và users</li>
                    <li>• Configuration và settings</li>
                    <li>• Metadata và statistics</li>
                  </ul>
                </div>
                
                <DatabaseBackupClient type="full" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Schema Only Backup */}
        <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
          <CardHeader className="border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center">
                <Shield className="w-5 h-5 text-white" />
              </div>
              <div>
                <CardTitle className="text-lg">Schema Backup</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Chỉ backup cấu trúc database
                </p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="space-y-3">
                <div className="p-3 bg-muted/50 rounded-lg">
                  <h4 className="font-medium text-sm mb-2">Bao gồm:</h4>
                  <ul className="text-xs space-y-1 text-muted-foreground">
                    <li>• Tables structure</li>
                    <li>• Functions và procedures</li>
                    <li>• RLS policies</li>
                    <li>• Indexes và constraints</li>
                  </ul>
                </div>
                
                <DatabaseBackupClient type="schema" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Data Migration */}
      <Card className="shadow-lg hover:shadow-xl transition-shadow border-0 bg-gradient-to-br from-card to-card/50">
        <CardHeader className="border-b border-border/50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center">
              <Upload className="w-5 h-5 text-white" />
            </div>
            <div>
              <CardTitle className="text-lg">Data Migration & Restore</CardTitle>
              <p className="text-sm text-muted-foreground">
                Import dữ liệu và khôi phục từ backup
              </p>
            </div>
          </div>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-3">
              <h4 className="font-medium">Import dữ liệu</h4>
              <div className="p-4 border-2 border-dashed border-border rounded-lg text-center">
                <Upload className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
                <p className="text-sm text-muted-foreground mb-3">
                  Kéo thả file SQL hoặc click để chọn
                </p>
                <Button variant="outline" size="sm">
                  Chọn file backup
                </Button>
              </div>
            </div>
            
            <div className="space-y-3">
              <h4 className="font-medium">Restore Options</h4>
              <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm">
                  <input type="checkbox" className="rounded" defaultChecked />
                  Drop existing data
                </label>
                <label className="flex items-center gap-2 text-sm">
                  <input type="checkbox" className="rounded" />
                  Backup before restore
                </label>
                <label className="flex items-center gap-2 text-sm">
                  <input type="checkbox" className="rounded" />
                  Validate data integrity
                </label>
              </div>
              <Button variant="destructive" size="sm" className="w-full" disabled>
                <AlertTriangle className="w-4 h-4 mr-2" />
                Restore Database
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Warning */}
      <Card className="border-yellow-200 bg-yellow-50 dark:border-yellow-800 dark:bg-yellow-900/20">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5" />
            <div className="space-y-1">
              <h4 className="font-medium text-yellow-800 dark:text-yellow-200">
                Lưu ý quan trọng
              </h4>
              <p className="text-sm text-yellow-700 dark:text-yellow-300">
                Các thao tác backup/restore có thể ảnh hưởng đến hiệu suất hệ thống. 
                Nên thực hiện trong giờ ít người dùng và có kế hoạch backup định kỳ.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}