/**
 * ==================================================================================
 * USER AUTH CHECK API
 * ==================================================================================
 * API để kiểm tra authentication status của user
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabase = await createClient();
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      return NextResponse.json({
        isAuthenticated: false,
        error: authError.message
      });
    }

    if (!user) {
      return NextResponse.json({
        isAuthenticated: false,
        error: 'No user found'
      });
    }

    // Get additional user info if available
    let userProfile = null;
    try {
      const { data: profile } = await supabase
        .from('pos_mini_modular3_user_profiles')
        .select('role, full_name, business_id')
        .eq('id', user.id)
        .single();
      
      userProfile = profile;
    } catch (err) {
      console.log('Could not fetch user profile:', err);
    }

    return NextResponse.json({
      isAuthenticated: true,
      user: {
        id: user.id,
        email: user.email,
        role: userProfile?.role || 'unknown',
        full_name: userProfile?.full_name || null,
        business_id: userProfile?.business_id || null
      }
    });

  } catch (error) {
    console.error('❌ Auth check failed:', error);
    
    return NextResponse.json({
      isAuthenticated: false,
      error: error instanceof Error ? error.message : 'Auth check failed'
    }, { status: 500 });
  }
}
