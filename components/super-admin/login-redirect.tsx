"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

interface SuperAdminLoginRedirectProps {
  message?: string;
}

export function SuperAdminLoginRedirect({ message = "Vui lòng đăng nhập với tài khoản Super Admin" }: SuperAdminLoginRedirectProps) {
  const router = useRouter();

  useEffect(() => {
    // Redirect to super admin login after a short delay
    const timer = setTimeout(() => {
      router.push('/admin-login');
    }, 2000);

    return () => clearTimeout(timer);
  }, [router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
      <div className="text-center space-y-6">
        <div className="w-20 h-20 mx-auto bg-gradient-to-br from-purple-600 to-blue-600 rounded-2xl flex items-center justify-center shadow-lg">
          <svg className="w-10 h-10 text-white animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        
        <div className="space-y-2">
          <h1 className="text-2xl font-bold text-white">
            Yêu cầu xác thực Super Admin
          </h1>
          <p className="text-white/80">
            {message}
          </p>
        </div>
        
        <div className="flex items-center justify-center gap-2 text-white/60">
          <div className="w-2 h-2 bg-purple-400 rounded-full animate-bounce"></div>
          <div className="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
          <div className="w-2 h-2 bg-purple-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
        </div>
      </div>
    </div>
  );
}