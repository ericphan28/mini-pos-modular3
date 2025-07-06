import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";

export function SignUpUserSteps() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Bắt đầu sử dụng POS Mini Modular</CardTitle>
        <CardDescription>
          Tạo tài khoản để bắt đầu quản lý cửa hàng của bạn
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <h4 className="font-medium">✨ Tính năng miễn phí</h4>
          <ul className="text-sm text-muted-foreground space-y-1">
            <li>• Quản lý sản phẩm (tối đa 50 sản phẩm)</li>
            <li>• Bán hàng cơ bản</li>
            <li>• Báo cáo đơn giản</li>
            <li>• Quản lý 3 người dùng</li>
            <li>• Hỗ trợ qua email</li>
          </ul>
        </div>
        
        <div className="flex gap-2">
          <Button asChild>
            <Link href="/auth/sign-up">
              Đăng ký miễn phí
            </Link>
          </Button>
          <Button asChild variant="outline">
            <Link href="/auth/login">
              Đăng nhập
            </Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
