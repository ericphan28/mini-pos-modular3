import { updateSession } from "@/lib/supabase/middleware";
import { type NextRequest, NextResponse } from "next/server";

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 🚀 ULTRA-FAST: Tối thiểu logging
  const isDev = process.env.NODE_ENV === 'development';
  
  // ⚡ OPTIMIZATION: Aggressive static asset skipping
  if (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/favicon') ||
    pathname.includes('.') ||
    pathname === '/admin-login'
  ) {
    return NextResponse.next();
  }

  // 🚀 ULTRA-PERFORMANCE: Minimal logging cho critical paths only
  const shouldLog = isDev && (pathname.startsWith('/super-admin') || pathname.startsWith('/api'));
  
  if (shouldLog) {
    console.log(`🔍 [MW] ${pathname}`);
  }

  // 🚀 PERFORMANCE: Single try-catch với timeout protection
  try {
    const response = await Promise.race([
      updateSession(request),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Middleware timeout')), 3000)
      )
    ]) as NextResponse;
    
    if (shouldLog) {
      console.log(`✅ [MW] ${pathname}`);
    }
    
    return response;
  } catch (error) {
    console.error(`🚨 [MW] ${pathname}:`, error instanceof Error ? error.message : error);
    return NextResponse.next();
  }
}

export const config = {
  matcher: [
    /*
     * 🚀 SIMPLE: Match specific paths only
     */
    '/super-admin/:path*',
    '/dashboard/:path*',
    '/auth/:path*',
    '/',
    '/api/admin/:path*'
  ],
};
