import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";

export function ConnectSupabaseSteps() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Kết nối Supabase</CardTitle>
        <CardDescription>
          Bạn cần cấu hình environment variables để kết nối với Supabase
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <h4 className="font-medium">Bước 1: Tạo dự án Supabase</h4>
          <p className="text-sm text-muted-foreground">
            Tạo một dự án mới tại{" "}
            <a 
              href="https://database.new" 
              target="_blank" 
              className="font-medium text-primary hover:underline"
            >
              database.new
            </a>
          </p>
        </div>
        
        <div className="space-y-2">
          <h4 className="font-medium">Bước 2: Cấu hình environment variables</h4>
          <p className="text-sm text-muted-foreground">
            Đổi tên <code>.env.example</code> thành <code>.env.local</code> và cập nhật:
          </p>
          <div className="bg-muted p-3 rounded text-sm font-mono">
            NEXT_PUBLIC_SUPABASE_URL=[YOUR_SUPABASE_URL]<br />
            NEXT_PUBLIC_SUPABASE_ANON_KEY=[YOUR_SUPABASE_ANON_KEY]
          </div>
        </div>

        <Button asChild>
          <Link href="https://supabase.com/dashboard/project/_/settings/api" target="_blank">
            Lấy API Keys
          </Link>
        </Button>
      </CardContent>
    </Card>
  );
}
