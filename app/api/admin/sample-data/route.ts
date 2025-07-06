/**
 * ==================================================================================
 * SAMPLE DATA API ENDPOINT
 * ==================================================================================
 * API để thêm dữ liệu mẫu vào database
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function POST() {
  try {
    const supabase = await createClient();
    
    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    console.log(`🚀 Starting sample data insertion for user: ${user.email}`);

    // Sample business types
    const businessTypes = [
      {
        id: '550e8400-e29b-41d4-a716-446655440001',
        name: 'Cửa hàng nhỏ',
        description: 'Dành cho cửa hàng quy mô nhỏ',
        features: { pos: true, inventory: true },
        max_staff: 5,
        max_products: 100
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440002',
        name: 'Cửa hàng vừa',
        description: 'Dành cho cửa hàng quy mô vừa',
        features: { pos: true, inventory: true, staff: true },
        max_staff: 20,
        max_products: 500
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440003',
        name: 'Cửa hàng lớn',
        description: 'Dành cho cửa hàng quy mô lớn',
        features: { pos: true, inventory: true, staff: true, analytics: true },
        max_staff: 100,
        max_products: 2000
      }
    ];

    // Insert business types
    for (const businessType of businessTypes) {
      await supabase
        .from('pos_mini_modular3_business_types')
        .upsert({
          ...businessType,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }
    console.log('✅ Inserted business types');

    // Sample subscription plans
    const subscriptionPlans = [
      {
        id: '550e8400-e29b-41d4-a716-446655440031',
        name: 'Gói cơ bản',
        description: 'Gói dành cho cửa hàng nhỏ',
        price_monthly: 199000,
        price_yearly: 1990000,
        features: { pos: true, inventory: true, reports: false },
        max_users: 3,
        max_products: 100,
        is_active: true
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440032',
        name: 'Gói chuyên nghiệp',
        description: 'Gói dành cho cửa hàng vừa và lớn',
        price_monthly: 499000,
        price_yearly: 4990000,
        features: { pos: true, inventory: true, reports: true, analytics: true },
        max_users: 10,
        max_products: 1000,
        is_active: true
      }
    ];

    // Insert subscription plans
    for (const plan of subscriptionPlans) {
      await supabase
        .from('pos_mini_modular3_subscription_plans')
        .upsert({
          ...plan,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }
    console.log('✅ Inserted subscription plans');

    // Sample businesses
    const businesses = [
      {
        id: '550e8400-e29b-41d4-a716-446655440021',
        name: 'Cửa hàng tiện lợi ABC',
        business_type_id: '550e8400-e29b-41d4-a716-446655440002',
        owner_id: '550e8400-e29b-41d4-a716-446655440012',
        status: 'active',
        address: '123 Đường ABC, Quận 1, TP.HCM',
        phone: '+84912345678',
        email: 'owner@cuahang1.com',
        tax_code: '0123456789',
        settings: { currency: 'VND', timezone: 'Asia/Ho_Chi_Minh' }
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440022',
        name: 'Cửa hàng thời trang XYZ',
        business_type_id: '550e8400-e29b-41d4-a716-446655440001',
        owner_id: '550e8400-e29b-41d4-a716-446655440012',
        status: 'active',
        address: '456 Đường XYZ, Quận 3, TP.HCM',
        phone: '+84987654321',
        email: 'fashion@xyz.com',
        tax_code: '0987654321',
        settings: { currency: 'VND', timezone: 'Asia/Ho_Chi_Minh' }
      }
    ];

    // Insert businesses
    for (const business of businesses) {
      await supabase
        .from('pos_mini_modular3_businesses')
        .upsert({
          ...business,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }
    console.log('✅ Inserted businesses');

    // Sample user profiles
    const userProfiles = [
      {
        id: '550e8400-e29b-41d4-a716-446655440011',
        email: 'admin@giakiemso.com',
        full_name: 'Quản trị viên hệ thống',
        role: 'super_admin',
        business_id: null,
        phone: '+84987654321',
        avatar_url: null,
        status: 'active'
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440012',
        email: 'owner@cuahang1.com',
        full_name: 'Chủ cửa hàng 1',
        role: 'business_owner',
        business_id: '550e8400-e29b-41d4-a716-446655440021',
        phone: '+84912345678',
        avatar_url: null,
        status: 'active'
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440013',
        email: 'staff@cuahang1.com',
        full_name: 'Nhân viên cửa hàng 1',
        role: 'staff',
        business_id: '550e8400-e29b-41d4-a716-446655440021',
        phone: '+84987123456',
        avatar_url: null,
        status: 'active'
      }
    ];

    // Insert user profiles
    for (const profile of userProfiles) {
      await supabase
        .from('pos_mini_modular3_user_profiles')
        .upsert({
          ...profile,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }
    console.log('✅ Inserted user profiles');

    // Sample subscription history
    const subscriptionHistory = [
      {
        id: '550e8400-e29b-41d4-a716-446655440041',
        business_id: '550e8400-e29b-41d4-a716-446655440021',
        plan_id: '550e8400-e29b-41d4-a716-446655440032',
        status: 'active',
        start_date: new Date().toISOString(),
        end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // +30 days
        amount_paid: 499000,
        payment_method: 'bank_transfer'
      },
      {
        id: '550e8400-e29b-41d4-a716-446655440042',
        business_id: '550e8400-e29b-41d4-a716-446655440022',
        plan_id: '550e8400-e29b-41d4-a716-446655440031',
        status: 'active',
        start_date: new Date().toISOString(),
        end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // +30 days
        amount_paid: 199000,
        payment_method: 'credit_card'
      }
    ];

    // Insert subscription history
    for (const history of subscriptionHistory) {
      await supabase
        .from('pos_mini_modular3_subscription_history')
        .upsert({
          ...history,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }
    console.log('✅ Inserted subscription history');

    // Get row counts for verification
    const tableCounts = [];
    
    const tables = [
      'pos_mini_modular3_business_types',
      'pos_mini_modular3_user_profiles',
      'pos_mini_modular3_businesses',
      'pos_mini_modular3_subscription_plans',
      'pos_mini_modular3_subscription_history'
    ];

    for (const table of tables) {
      const { count } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      tableCounts.push({
        table_name: table,
        row_count: count || 0
      });
    }

    console.log('✅ Sample data insertion completed');

    return NextResponse.json({
      success: true,
      result: tableCounts,
      message: 'Sample data inserted successfully'
    });

  } catch (error) {
    console.error('❌ Sample data insertion failed:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Sample data insertion failed'
    }, { status: 500 });
  }
}
