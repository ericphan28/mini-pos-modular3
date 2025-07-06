import { createClient } from '@supabase/supabase-js';

/**
 * Super Admin Client - Uses service_role to bypass RLS
 * Only use this for super admin operations on server-side
 * NEVER expose service_role key to client-side
 */
export const createAdminClient = () => {
  // Kiểm tra xem code có đang chạy ở phía client hay không
  const isClient = typeof window !== 'undefined';
  if (isClient) {
    console.warn('⚠️ Warning: createAdminClient should not be called from client-side code!');
    console.log('🔍 Debug: window object exists, this is client-side');
  } else {
    console.log('✅ Debug: createAdminClient called from server-side');
  }

  console.log('🔍 Debug: Environment check:', {
    hasSupabaseUrl: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
    hasServiceRoleKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    isClient,
    nodeEnv: process.env.NODE_ENV
  });

  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL environment variable');
    throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL environment variable')
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
    console.log('🔍 Available env vars:', Object.keys(process.env).filter(key => key.includes('SUPABASE')));
    throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')
  }

  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )
}

/**
 * Helper function to check if user is super admin
 * Uses admin client to bypass RLS
 */
export const checkSuperAdminAccess = async (userId: string) => {
  try {
    // ✅ Use admin client to bypass RLS
    const adminClient = createAdminClient()
    
    const { data: profile, error } = await adminClient
      .from('pos_mini_modular3_user_profiles')
      .select('role, email')
      .eq('id', userId)
      .single()

    if (error || !profile) {
      console.log("checkSuperAdminAccess - No profile found:", error)
      return false
    }

    console.log("checkSuperAdminAccess - Profile found:", profile)
    return profile.role === 'super_admin'
  } catch (error) {
    console.error("checkSuperAdminAccess - Error:", error)
    return false
  }
}
