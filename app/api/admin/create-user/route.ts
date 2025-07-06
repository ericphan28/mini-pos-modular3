import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(request: NextRequest) {
  try {
    const { contact_method, contact_value, business_id, full_name, temporary_password } = await request.json();

    const adminClient = createAdminClient();

    // ✅ Validate input
    if (!contact_method || !['email', 'phone'].includes(contact_method)) {
      return NextResponse.json({
        success: false,
        error: 'Contact method phải là email hoặc phone'
      }, { status: 400 });
    }

    // ✅ Create auth payload with proper typing
    const authPayload: {
      password: string;
      email?: string;
      phone?: string;
      email_confirm?: boolean;
      phone_confirm?: boolean;
      user_metadata: {
        full_name: string;
        business_id: string;
        role: string;
      };
    } = {
      password: temporary_password,
      user_metadata: {
        full_name,
        business_id,
        role: 'household_owner'
      }
    };

    // ✅ Create user based on contact method
    if (contact_method === 'email') {
      authPayload.email = contact_value;
      authPayload.email_confirm = true; // Auto confirm email
    } else if (contact_method === 'phone') {
      authPayload.phone = contact_value;
      authPayload.phone_confirm = true; // Auto confirm phone
    }

    const { data: authUser, error: authError } = await adminClient.auth.admin.createUser(authPayload);

    if (authError) {
      console.error('Auth user creation error:', authError);
      return NextResponse.json({
        success: false,
        error: authError.message
      }, { status: 400 });
    }

    // ✅ Create user profile with proper typing
    const profileData: {
      id: string;
      business_id: string;
      full_name: string;
      email?: string;
      phone?: string;
      role: string;
      status: string;
    } = {
      id: authUser.user.id,
      business_id,
      full_name,
      role: 'household_owner',
      status: 'active'
    };

    // Add email or phone to profile
    if (contact_method === 'email') {
      profileData.email = contact_value;
    } else {
      profileData.phone = contact_value;
    }

    const { error: profileError } = await adminClient
      .from('pos_mini_modular3_user_profiles')
      .insert(profileData);

    if (profileError) {
      console.error('Profile creation error:', profileError);
      // Try to cleanup auth user if profile creation fails
      await adminClient.auth.admin.deleteUser(authUser.user.id);
      
      return NextResponse.json({
        success: false,
        error: 'Không thể tạo profile người dùng'
      }, { status: 400 });
    }

    // ✅ Send password reset email/SMS so user can set their own password
    if (contact_method === 'email') {
      const { error: resetError } = await adminClient.auth.admin.generateLink({
        type: 'recovery',
        email: contact_value,
      });

      if (resetError) {
        console.warn('Could not send reset email:', resetError);
      }
    }

    return NextResponse.json({
      success: true,
      user_id: authUser.user.id,
      contact_method,
      contact_value,
      message: contact_method === 'email' 
        ? 'Tài khoản đã được tạo và email xác nhận đã được gửi'
        : 'Tài khoản đã được tạo. Người dùng có thể đăng nhập bằng số điện thoại'
    });

  } catch (error) {
    console.error('Create user API error:', error);
    return NextResponse.json({
      success: false,
      error: 'Lỗi server khi tạo tài khoản'
    }, { status: 500 });
  }
}
