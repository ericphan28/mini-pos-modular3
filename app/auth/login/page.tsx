import { LoginForm } from "@/components/login-form";
import { Shield } from "lucide-react";
import Link from "next/link";

export default function Page() {
  return (
    <div className="flex min-h-svh w-full items-center justify-center p-6 md:p-10">
      <div className="w-full max-w-sm space-y-6">
        <LoginForm />
        
        {/* Super Admin Link */}
        <div className="text-center">
          <Link 
            href="/admin-login"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          >
            <Shield className="w-4 h-4" />
            Đăng nhập Super Admin
          </Link>
        </div>
      </div>
    </div>
  );
}
