// Test Auth Context với actual database data
// Verify logic hoạt động đúng với Highland Coffee Demo business

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://oxtsowfvjchelqdxcbhs.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94dHNvd2Z2amNoZWxxZHhjYmhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwNzcyNDksImV4cCI6MjA2NjY1MzI0OX0.N95sD7R1ewAPu4nrqPkV9Fj4XHanw-sgGsh24MBUOQ8';

async function testAuthContextLogic() {
  console.log('🧪 Testing Auth Context Logic với Actual Database Data');
  console.log('=' .repeat(60));

  const supabase = createClient(supabaseUrl, supabaseKey);

  try {
    // Test với actual user ID từ database
    const actualUserId = '5f8d74cf-572a-4640-a565-34c5e1462f4e'; // Highland Coffee Demo user
    
    console.log('📋 Testing với actual user:', actualUserId);

    // Call RPC function như auth context
    const { data: userData, error: rpcError } = await supabase.rpc(
      'pos_mini_modular3_get_user_with_business_complete',
      { p_user_id: actualUserId }
    );

    console.log('🔍 RPC Response:', { 
      success: userData?.success,
      error: rpcError,
      hasUser: !!userData?.user,
      hasBusiness: !!userData?.business,
      hasPermissions: !!userData?.permissions
    });

    if (rpcError) {
      throw new Error(`RPC Error: ${rpcError.message}`);
    }

    if (!userData?.success) {
      throw new Error(`RPC Failed: ${userData?.message}`);
    }

    // Extract data như auth context
    const businessInfo = userData.business;
    const permissionsInfo = userData.permissions || {};

    console.log('📋 User Info:', {
      id: userData.user?.profile_id || userData.user?.id,
      fullName: userData.user?.full_name,
      email: userData.user?.email,
      role: userData.user?.role
    });

    console.log('\n📊 Business Data Validation:');
    console.log('- Business ID:', businessInfo.id);
    console.log('- Business Name:', businessInfo.name);
    console.log('- Subscription Tier (actual):', businessInfo.subscription_tier);
    console.log('- Subscription Status:', businessInfo.subscription_status);
    console.log('- Business Status:', businessInfo.status);

    // Test subscription tier mapping
    const actualTier = businessInfo.subscription_tier;
    const mappedTier = actualTier === 'free' ? 'basic' : actualTier;

    console.log('\n🔄 Subscription Tier Mapping:');
    console.log('- Actual từ DB:', actualTier);
    console.log('- Mapped for features:', mappedTier);
    console.log('- Mapping correct?', actualTier === 'free' && mappedTier === 'basic');

    // Test permissions processing
    console.log('\n🔐 Permissions Processing:');
    console.log('Raw permissions từ DB:', JSON.stringify(permissionsInfo, null, 2));

    const features = [];
    const permissionsList = [];

    Object.entries(permissionsInfo).forEach(([featureName, permissions]) => {
      const perms = permissions;
      
      console.log(`\n- Feature: ${featureName}`);
      console.log(`  └─ can_read: ${perms.can_read}`);
      console.log(`  └─ can_write: ${perms.can_write}`);
      console.log(`  └─ can_delete: ${perms.can_delete}`);
      console.log(`  └─ can_manage: ${perms.can_manage}`);
      
      // Add feature if user has any permission
      if (perms.can_read || perms.can_write || perms.can_delete || perms.can_manage) {
        features.push(featureName);
      }

      // Build permission strings
      if (perms.can_read) permissionsList.push(`${featureName}.read`);
      if (perms.can_write) permissionsList.push(`${featureName}.write`);
      if (perms.can_delete) permissionsList.push(`${featureName}.delete`);
      if (perms.can_manage) permissionsList.push(`${featureName}.manage`);
    });

    console.log('\n📈 Permission Summary:');
    console.log('- Total features:', features.length);
    console.log('- Total permissions:', permissionsList.length);
    console.log('- Features accessible:', features);
    console.log('- All permissions:', permissionsList);

    // Validate business logic
    console.log('\n✅ Business Logic Validation:');
    
    // Check if business is valid for access
    const isBusinessValid = businessInfo.status === 'active';
    console.log('- Business status valid:', isBusinessValid);

    // Check subscription
    const isSubscriptionValid = ['active', 'trial'].includes(businessInfo.subscription_status);
    console.log('- Subscription valid:', isSubscriptionValid);

    // Check if user has minimum permissions
    const hasBasicAccess = features.length > 0 && permissionsList.length > 0;
    console.log('- Has basic access:', hasBasicAccess);

    // Overall validation
    const overallValid = isBusinessValid && isSubscriptionValid && hasBasicAccess;
    console.log('- Overall validation PASSED:', overallValid);

    // Expected values từ actual data analysis
    console.log('\n🎯 Expected vs Actual:');
    console.log('- Expected business name: Highland Coffee Demo');
    console.log('- Actual business name:', businessInfo.name);
    console.log('- Business name match:', businessInfo.name === 'Highland Coffee Demo');
    
    console.log('- Expected subscription tier: free');
    console.log('- Actual subscription tier:', actualTier);
    console.log('- Tier match:', actualTier === 'free');
    
    console.log('- Expected permission count: 7 features × 4 permissions = 28');
    console.log('- Actual permission count:', permissionsList.length);
    console.log('- Expected features: 7 (staff_management, financial_tracking, etc.)');
    console.log('- Actual features:', features.length);

    if (overallValid) {
      console.log('\n🎉 AUTH CONTEXT LOGIC TEST PASSED!');
      console.log('✅ All validations successful với actual database data');
    } else {
      console.log('\n❌ AUTH CONTEXT LOGIC TEST FAILED!');
      console.log('Some validations failed');
    }

  } catch (error) {
    console.error('\n💥 Test Error:', error.message);
    console.error('Stack:', error.stack);
  }
}

// Run test
testAuthContextLogic().catch(console.error);
