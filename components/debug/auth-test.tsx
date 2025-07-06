'use client';

import { Button } from '@/components/ui/button';
import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';

interface AuthTestResult {
  success: boolean;
  message?: string;
  profile?: unknown;
  user?: unknown;
  profileError?: unknown;
  error?: unknown;
  functionCall?: boolean;
  data?: unknown;
}

// ✅ SỬA: Bỏ JSX.Element hoặc import React
export default function AuthDebugTest() {
  const [result, setResult] = useState<AuthTestResult | null>(null);
  const [loading, setLoading] = useState(false);

  const testSuperAdminAuth = async (): Promise<void> => {
    setLoading(true);
    const supabase = createClient();
    
    // ✅ SỬA: Dùng đúng email của bạn
    const TEST_EMAIL = 'admin@giakiemso.com';
    const TEST_PASSWORD = 'Tnt@9961266';
    
    console.log('🚀 [AUTH-DEBUG] ===========================================');
    console.log('🚀 [AUTH-DEBUG] Starting Super Admin Debug Process');
    console.log('🚀 [AUTH-DEBUG] Test Email:', TEST_EMAIL);
    console.log('🚀 [AUTH-DEBUG] ===========================================');
    
    try {
      // Step 1: Check if user exists in profiles table
      console.log('🔍 [AUTH-DEBUG] Step 1: Checking user_profiles table...');
      const { data: profiles, error: profileError } = await supabase
        .from('pos_mini_modular3_user_profiles')
        .select('*')
        .eq('email', TEST_EMAIL);

      console.log('📊 [AUTH-DEBUG] Profile Query Result:', {
        profiles,
        profileError,
        profilesCount: profiles?.length || 0
      });

      if (profileError) {
        console.error('❌ [AUTH-DEBUG] Profile query failed:', profileError);
      } else {
        console.log('✅ [AUTH-DEBUG] Profile query success. Found profiles:', profiles?.length || 0);
        if (profiles && profiles.length > 0) {
          profiles.forEach((profile, index) => {
            console.log(`📋 [AUTH-DEBUG] Profile ${index + 1}:`, {
              id: profile.id,
              email: profile.email,
              role: profile.role,
              full_name: profile.full_name,
              created_at: profile.created_at
            });
          });
        }
      }

      // Step 2: Check auth.users table (indirect via RPC or try login)
      console.log('🔍 [AUTH-DEBUG] Step 2: Testing direct authentication...');
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
      });

      console.log('🔐 [AUTH-DEBUG] Auth Result:', {
        success: !authError,
        authError: authError ? {
          message: authError.message,
          status: authError.status,
          details: 'Supabase Auth Error'
        } : null,
        user: authData?.user ? {
          id: authData.user.id,
          email: authData.user.email,
          email_confirmed_at: authData.user.email_confirmed_at,
          created_at: authData.user.created_at,
          last_sign_in_at: authData.user.last_sign_in_at
        } : null
      });

      if (authError) {
        console.error('❌ [AUTH-DEBUG] Authentication failed:', authError.message);
        
        // Step 3: Try to create super admin if auth failed
        console.log('🔧 [AUTH-DEBUG] Step 3: Attempting to create super admin...');
        const { data: createData, error: createError } = await supabase.rpc('pos_mini_modular3_create_complete_super_admin', {
          p_email: TEST_EMAIL,
          p_password: TEST_PASSWORD,
          p_phone: '0907136029',
          p_full_name: 'Super Administrator'
        });

        console.log('🏗️ [AUTH-DEBUG] Create Super Admin Result:', {
          success: !createError,
          createData,
          createError: createError ? {
            message: createError.message,
            details: createError.details,
            hint: createError.hint
          } : null
        });

        if (!createError) {
          console.log('✅ [AUTH-DEBUG] Super admin created successfully!');
          
          // Step 4: Try login again after creation
          console.log('🔍 [AUTH-DEBUG] Step 4: Re-testing authentication after creation...');
          
          // Wait a bit for database consistency
          await new Promise(resolve => setTimeout(resolve, 1000));
          
          const { data: authData2, error: authError2 } = await supabase.auth.signInWithPassword({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
          });

          console.log('🔐 [AUTH-DEBUG] Re-auth Result:', {
            success: !authError2,
            authError2: authError2?.message,
            user2: authData2?.user ? {
              id: authData2.user.id,
              email: authData2.user.email
            } : null
          });

          if (!authError2) {
            console.log('🎉 [AUTH-DEBUG] SUCCESS! Login works after creation');
            setResult({
              success: true,
              message: 'Super admin created and login successful!',
              user: authData2.user,
              data: createData
            });
          } else {
            console.error('❌ [AUTH-DEBUG] Still failed after creation:', authError2.message);
            setResult({
              success: false,
              message: 'Created super admin but still cannot login',
              error: authError2.message,
              data: createData
            });
          }
        } else {
          console.error('❌ [AUTH-DEBUG] Failed to create super admin:', createError.message);
          setResult({
            success: false,
            message: 'Cannot create super admin',
            error: createError.message,
            profileError
          });
        }
      } else {
        console.log('🎉 [AUTH-DEBUG] SUCCESS! Login successful on first try');
        setResult({
          success: true,
          message: 'Login successful!',
          profile: profiles,
          user: authData.user
        });
        
        // Sign out for clean state
        await supabase.auth.signOut();
      }

    } catch (error) {
      console.error('💥 [AUTH-DEBUG] Unexpected error:', error);
      setResult({
        success: false,
        error: error,
        message: 'Unexpected error during debug'
      });
    }
    
    console.log('🏁 [AUTH-DEBUG] Debug process completed');
    console.log('🚀 [AUTH-DEBUG] ===========================================');
    setLoading(false);
  };

  const createSuperAdmin = async (): Promise<void> => {
    setLoading(true);
    const supabase = createClient();
    
    console.log('🛠️ [CREATE-ADMIN] Creating super admin...');
    
    try {
      const { data, error } = await supabase.rpc('pos_mini_modular3_create_complete_super_admin', {
        p_email: 'admin@giakiemso.com',
        p_password: 'Tnt@9961266',
        p_phone: '0907136029',
        p_full_name: 'Super Administrator'
      });

      console.log('🛠️ [CREATE-ADMIN] Result:', { data, error });

      setResult({
        functionCall: true,
        data,
        error,
        success: !error
      });

    } catch (error) {
      console.error('💥 [CREATE-ADMIN] Error:', error);
      setResult({
        functionCall: true,
        success: false,
        error: error
      });
    }
    
    setLoading(false);
  };

  return (
    <div className="p-6 bg-white dark:bg-gray-800 rounded-lg border space-y-4">
      <h3 className="text-lg font-semibold">Super Admin Auth Debug</h3>
      
      <div className="bg-blue-50 border border-blue-200 rounded p-3 text-sm">
        <p><strong>Test Credentials:</strong></p>
        <p>Email: admin@giakiemso.com</p>
        <p>Password: Tnt@9961266</p>
        <p className="text-blue-600 mt-2">Check browser console for detailed logs!</p>
      </div>
      
      <div className="flex gap-2">
        <Button onClick={testSuperAdminAuth} disabled={loading}>
          {loading ? 'Testing...' : 'Run Full Debug'}
        </Button>
        
        <Button onClick={createSuperAdmin} disabled={loading} variant="outline">
          {loading ? 'Creating...' : 'Create Super Admin Only'}
        </Button>
      </div>

      {result && (
        <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-700 rounded text-sm">
          <pre>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}