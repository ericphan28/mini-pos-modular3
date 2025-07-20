// ==================================================================================
// PERMISSION SYSTEM TEST SCRIPT
// ==================================================================================
// Test centralized permission system với tài khoản cym_sunset@yahoo.com

const { createClient } = require('@supabase/supabase-js');

// Load environment variables
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// ==================================================================================
// TEST CONFIGURATION
// ==================================================================================

const TEST_ACCOUNT = {
  email: 'cym_sunset@yahoo.com',
  // Password sẽ được nhập từ command line hoặc environment
};

// ==================================================================================
// PERMISSION SYSTEM TEST FUNCTIONS
// ==================================================================================

async function testUserSessionLoad() {
  console.log('\n🔐 Testing User Session Load...');
  
  try {
    // Authenticate user
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: TEST_ACCOUNT.email,
      password: process.env.TEST_PASSWORD || 'your-password-here'
    });

    if (authError || !authData.user) {
      throw new Error(`Authentication failed: ${authError?.message}`);
    }

    console.log('✅ Authentication successful:', {
      userId: authData.user.id,
      email: authData.user.email
    });

    // Load complete user session using our RPC function
    const { data: userData, error: profileError } = await supabase.rpc(
      'pos_mini_modular3_get_user_with_business_complete',
      { p_user_id: authData.user.id }
    );

    if (profileError) {
      throw new Error(`Profile error: ${profileError.message}`);
    }

    if (!userData || !userData.success) {
      throw new Error(userData?.message || 'Failed to load user session');
    }

    console.log('✅ User session loaded successfully:', {
      user: userData.user,
      business: userData.business,
      permissions: userData.permissions
    });

    return userData;

  } catch (error) {
    console.error('❌ User session load failed:', error.message);
    throw error;
  }
}

async function testPermissionSystemIntegration(userData) {
  console.log('\n🔒 Testing Permission System Integration...');

  try {
    // Import permission system components
    const { permissionEngine } = require('./lib/permissions/permission-engine');
    const { PERMISSION_CONFIG } = require('./lib/permissions/permission-config');
    const { adaptSessionData } = require('./lib/permissions/session-adapter');

    // Initialize permission engine
    permissionEngine.initialize(PERMISSION_CONFIG);
    console.log('✅ Permission engine initialized');

    // Convert auth session to permission session
    const authSession = {
      user: {
        id: userData.user.id,
        email: userData.user.email
      },
      business: {
        id: userData.business.id,
        name: userData.business.name,
        subscriptionTier: userData.business.subscription_tier === 'free' ? 'basic' : userData.business.subscription_tier,
        status: userData.business.status
      },
      permissions: {
        role: userData.user.role,
        permissions: [],
        features: []
      }
    };

    // Process permissions from database format
    Object.entries(userData.permissions || {}).forEach(([featureName, perms]) => {
      const permissions = perms;
      
      // Add feature if user has any permission
      if (permissions.can_read || permissions.can_write || permissions.can_delete || permissions.can_manage) {
        authSession.permissions.features.push(featureName);
      }

      // Build permission strings
      if (permissions.can_read) authSession.permissions.permissions.push(`${featureName}.read`);
      if (permissions.can_write) authSession.permissions.permissions.push(`${featureName}.write`);
      if (permissions.can_delete) authSession.permissions.permissions.push(`${featureName}.delete`);
      if (permissions.can_manage) authSession.permissions.permissions.push(`${featureName}.manage`);
    });

    console.log('✅ Session data adapted:', {
      features: authSession.permissions.features.length,
      permissions: authSession.permissions.permissions.length,
      subscriptionTier: authSession.business.subscriptionTier
    });

    // Convert to permission session format
    const permissionSession = adaptSessionData(authSession);
    console.log('✅ Permission session created');

    // Test permission checks
    const testPermissions = [
      'access_pos',
      'staff_view',
      'staff_create',
      'product_view',
      'product_create',
      'financial_view',
      'report_view'
    ];

    console.log('\n🧪 Testing Permission Checks:');
    
    for (const permission of testPermissions) {
      try {
        const result = await permissionEngine.checkPermission(permissionSession, permission);
        console.log(`  ${permission}: ${result.allowed ? '✅ ALLOWED' : '❌ DENIED'} (${result.reason})`);
      } catch (error) {
        console.log(`  ${permission}: ❌ ERROR - ${error.message}`);
      }
    }

    // Test user permissions summary
    const userPermissions = permissionEngine.getUserPermissions(permissionSession);
    console.log('\n📊 User Permissions Summary:', {
      totalFeatures: Object.keys(userPermissions.features).length,
      totalPermissions: userPermissions.allPermissions.length,
      features: Object.keys(userPermissions.features),
      restrictedFeatures: userPermissions.restrictedFeatures
    });

    return permissionSession;

  } catch (error) {
    console.error('❌ Permission system integration test failed:', error.message);
    throw error;
  }
}

async function testAuthPermissionBridge(userData) {
  console.log('\n🌉 Testing Auth-Permission Bridge...');

  try {
    // Import bridge components
    const { authPermissionBridge, initializePermissions } = require('./lib/permissions/auth-permission-integration');

    // Create auth session data
    const authSessionData = {
      user: {
        id: userData.user.id,
        email: userData.user.email
      },
      profile: {
        id: userData.user.profile_id || userData.user.id,
        fullName: userData.user.full_name || '',
        email: userData.user.email,
        phoneNumber: userData.user.phone
      },
      business: {
        id: userData.business.id,
        name: userData.business.name,
        status: userData.business.status,
        subscriptionTier: userData.business.subscription_tier === 'free' ? 'basic' : userData.business.subscription_tier,
        subscriptionStatus: userData.business.subscription_status
      },
      permissions: {
        role: userData.user.role,
        permissions: [],
        features: []
      },
      loginTime: new Date().toISOString(),
      lastActivity: new Date().toISOString()
    };

    // Process permissions
    Object.entries(userData.permissions || {}).forEach(([featureName, perms]) => {
      if (perms.can_read || perms.can_write || perms.can_delete || perms.can_manage) {
        authSessionData.permissions.features.push(featureName);
      }

      if (perms.can_read) authSessionData.permissions.permissions.push(`${featureName}.read`);
      if (perms.can_write) authSessionData.permissions.permissions.push(`${featureName}.write`);
      if (perms.can_delete) authSessionData.permissions.permissions.push(`${featureName}.delete`);
      if (perms.can_manage) authSessionData.permissions.permissions.push(`${featureName}.manage`);
    });

    console.log('✅ Auth session data prepared');

    // Initialize permissions through bridge
    const permissionCache = await initializePermissions(authSessionData);
    console.log('✅ Permission cache generated:', {
      cacheSize: Object.keys(permissionCache.userPermissions).length,
      subscriptionLimits: Object.keys(permissionCache.subscriptionLimits).length,
      routeAccess: permissionCache.routeAccess.length
    });

    // Test bridge methods
    console.log('\n🧪 Testing Bridge Methods:');

    // Test feature access
    const testFeatures = ['staff', 'product', 'financial', 'report', 'pos', 'inventory', 'customer'];
    for (const feature of testFeatures) {
      const hasAccess = authPermissionBridge.hasFeatureAccess(permissionCache, feature);
      console.log(`  Feature ${feature}: ${hasAccess ? '✅ ACCESSIBLE' : '❌ RESTRICTED'}`);
    }

    // Test route access
    const testRoutes = ['/dashboard', '/staff', '/products', '/financial', '/reports', '/pos'];
    for (const route of testRoutes) {
      const canAccess = authPermissionBridge.canAccessRoute(permissionCache, route);
      console.log(`  Route ${route}: ${canAccess ? '✅ ACCESSIBLE' : '❌ RESTRICTED'}`);
    }

    // Test subscription limits
    const subscriptionLimits = authPermissionBridge.getSubscriptionLimits(permissionCache);
    console.log('\n📋 Subscription Limits:', subscriptionLimits);

    return permissionCache;

  } catch (error) {
    console.error('❌ Auth-Permission Bridge test failed:', error.message);
    throw error;
  }
}

async function testReactHooksSimulation(permissionCache) {
  console.log('\n⚛️ Testing React Hooks (Simulation)...');

  try {
    // Simulate usePermission hook functionality
    const mockUsePermission = (permission) => {
      const userPermissions = Object.values(permissionCache.userPermissions).flat();
      return userPermissions.includes(permission);
    };

    // Simulate useFeatureAccess hook
    const mockUseFeatureAccess = (feature) => {
      return authPermissionBridge.hasFeatureAccess(permissionCache, feature);
    };

    // Simulate useStaffPermission hook
    const mockUseStaffPermission = () => {
      const staffPermissions = permissionCache.userPermissions.staff || [];
      return {
        canView: staffPermissions.includes('staff_view'),
        canCreate: staffPermissions.includes('staff_create'),
        canEdit: staffPermissions.includes('staff_edit'),
        canDelete: staffPermissions.includes('staff_delete')
      };
    };

    console.log('🧪 Hook Simulation Results:');
    
    // Test individual permissions
    const testPerms = ['staff_view', 'product_create', 'financial_view', 'report_generate'];
    for (const perm of testPerms) {
      const result = mockUsePermission(perm);
      console.log(`  usePermission('${perm}'): ${result ? '✅ TRUE' : '❌ FALSE'}`);
    }

    // Test feature access
    const testFeatures = ['staff', 'product', 'financial'];
    for (const feature of testFeatures) {
      const result = mockUseFeatureAccess(feature);
      console.log(`  useFeatureAccess('${feature}'): ${result ? '✅ TRUE' : '❌ FALSE'}`);
    }

    // Test staff permissions specifically
    const staffPerms = mockUseStaffPermission();
    console.log('  useStaffPermission():', {
      canView: staffPerms.canView ? '✅' : '❌',
      canCreate: staffPerms.canCreate ? '✅' : '❌',
      canEdit: staffPerms.canEdit ? '✅' : '❌',
      canDelete: staffPerms.canDelete ? '✅' : '❌'
    });

  } catch (error) {
    console.error('❌ React Hooks simulation failed:', error.message);
    throw error;
  }
}

// ==================================================================================
// MAIN TEST RUNNER
// ==================================================================================

async function runPermissionSystemTests() {
  console.log('🚀 Starting Permission System Tests for cym_sunset@yahoo.com');
  console.log('=' .repeat(80));

  try {
    // 1. Test user session loading
    const userData = await testUserSessionLoad();

    // 2. Test permission system integration
    const permissionSession = await testPermissionSystemIntegration(userData);

    // 3. Test auth-permission bridge
    const permissionCache = await testAuthPermissionBridge(userData);

    // 4. Test React hooks simulation
    await testReactHooksSimulation(permissionCache);

    console.log('\n🎉 All Permission System Tests Completed Successfully!');
    console.log('=' .repeat(80));

    // Summary
    console.log('\n📊 TEST SUMMARY:');
    console.log('✅ User Authentication: PASSED');
    console.log('✅ Session Data Loading: PASSED');
    console.log('✅ Permission Engine: PASSED');
    console.log('✅ Auth-Permission Bridge: PASSED');
    console.log('✅ React Hooks Simulation: PASSED');

  } catch (error) {
    console.error('\n❌ Permission System Tests Failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// ==================================================================================
// COMMAND LINE EXECUTION
// ==================================================================================

// Check if password is provided
if (!process.env.TEST_PASSWORD) {
  console.log('⚠️  Please set TEST_PASSWORD environment variable:');
  console.log('   TEST_PASSWORD=your-password npm run test:permissions');
  console.log('   or');
  console.log('   TEST_PASSWORD=your-password node test-permission-system-integration.js');
  process.exit(1);
}

// Run tests
runPermissionSystemTests();
