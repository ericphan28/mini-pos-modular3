import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { hasEnvVars } from "../utils";

export async function updateSession(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  
  // 🚀 ULTRA-PERFORMANCE: Tối thiểu logging
  const isDev = process.env.NODE_ENV === 'development';
  const shouldLog = isDev && pathname.startsWith('/super-admin');
  
  let supabaseResponse = NextResponse.next({ request });

  // 🚀 OPTIMIZATION: Early return for missing env vars
  if (!hasEnvVars) {
    return supabaseResponse;
  }

  // 🚀 PERFORMANCE: Single supabase client creation
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // 🚀 ULTRA-FAST: Get user với reduced timeout
  const { data: { user } } = await Promise.race([
    supabase.auth.getUser(),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Auth timeout')), 2000)
    )
  ]) as { data: { user: { id: string; email?: string } | null } };

  if (shouldLog) {
    console.log(`👤 [MW] User: ${user?.id?.slice(0,8)}... ${user?.email}`);
  }

  // 🚀 ULTRA-FAST: Optimized route checking với Set lookup
  const publicRoutes = new Set([
    '/', '/auth', '/login', '/admin-login'
  ]);
  
  const isPublicRoute = publicRoutes.has(pathname) || 
    pathname.startsWith('/auth/') || 
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/api/auth/');

  if (shouldLog) {
    console.log(`🛡️ [MW] Route: ${pathname} (public: ${isPublicRoute}, user: ${!!user})`);
  }

  // 🚀 FAST PATH: Handle redirects efficiently
  if (!isPublicRoute && !user) {
    if (shouldLog) console.log(`🚨 [MW] Redirect to login: ${pathname}`);
    const url = request.nextUrl.clone();
    url.pathname = "/auth/login";
    return NextResponse.redirect(url);
  }

  // 🚀 SUPER ADMIN: Optimized super admin route handling
  if (pathname.startsWith("/super-admin") && pathname !== "/admin-login") {
    if (!user) {
      if (shouldLog) console.log(`🚨 [MW] Super admin redirect: ${pathname}`);
      const url = request.nextUrl.clone();
      url.pathname = "/admin-login";
      return NextResponse.redirect(url);
    }
  }

  if (shouldLog) console.log(`✅ [MW] Allow: ${pathname}`);
  return supabaseResponse;
}
