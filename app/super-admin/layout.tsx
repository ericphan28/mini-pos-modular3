import { SuperAdminLayoutClient } from "@/components/super-admin/layout-client";
import { checkSuperAdminAccess, createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { cache } from "react";

// 🚀 PERFORMANCE: Cache super admin check để tránh duplicate calls
const getCachedSuperAdminStatus = cache(async (userId: string) => {
  const isAdmin = await checkSuperAdminAccess(userId);
  console.log(`🔍 [LAYOUT] Cached super admin check: ${userId.slice(0,8)}... -> ${isAdmin}`);
  return isAdmin;
});

// 🚀 PERFORMANCE: Cache profile fetch để tránh duplicate calls  
const getCachedProfile = cache(async (userId: string) => {
  const adminClient = createAdminClient();
  const { data: profile } = await adminClient
    .from('pos_mini_modular3_user_profiles')
    .select('full_name, status')
    .eq('id', userId)
    .single();
  
  console.log(`📋 [LAYOUT] Cached profile fetch: ${userId.slice(0,8)}... -> ${!!profile}`);
  return profile || { full_name: 'Super Administrator', status: 'active' };
});

export default async function SuperAdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const isDev = process.env.NODE_ENV === 'development';
  if (isDev) console.log("🏛️ [LAYOUT] Starting...");
  
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (isDev) console.log(`🏛️ [LAYOUT] User: ${user?.id?.slice(0,8)}... ${user?.email}`);

  if (!user) {
    if (isDev) console.log("❌ [LAYOUT] No user, redirecting");
    return redirect("/admin-login");
  }

  // ✅ Cached super admin check để tránh duplicate
  const isSuperAdmin = await getCachedSuperAdminStatus(user.id);
  
  if (!isSuperAdmin) {
    if (isDev) console.log("❌ [LAYOUT] Not super admin, redirecting");
    return redirect("/admin-login");
  }

  // ✅ Cached profile fetch để tránh duplicate
  const displayProfile = await getCachedProfile(user.id);

  if (isDev) console.log("✅ [LAYOUT] Layout check passed");

  return (
    <SuperAdminLayoutClient user={user} profile={displayProfile}>
      {children}
    </SuperAdminLayoutClient>
  );
}
