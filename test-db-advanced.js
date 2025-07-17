#!/usr/bin/env node

/**
 * Advanced Database Test Script
 * Kiểm tra chi tiết database connection và user account
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function log(color, prefix, message, data = null) {
  const timestamp = new Date().toLocaleTimeString();
  console.log(`${color}[${timestamp}] ${prefix}:${colors.reset} ${message}`);
  if (data) {
    console.log(`${colors.cyan}   →${colors.reset}`, JSON.stringify(data, null, 2));
  }
}

function logSuccess(message, data = null) {
  log(colors.green, '✅ SUCCESS', message, data);
}

function logError(message, data = null) {
  log(colors.red, '❌ ERROR', message, data);
}

function logInfo(message, data = null) {
  log(colors.blue, '🔵 INFO', message, data);
}

function logWarning(message, data = null) {
  log(colors.yellow, '⚠️  WARN', message, data);
}

async function testAdvancedDatabase() {
  logInfo('Bắt đầu advanced database test');
  
  // Environment check
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    logError('Missing environment variables');
    return false;
  }

  // Create clients
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false }
  });
  
  const anonClient = createClient(supabaseUrl, anonKey);

  logSuccess('Clients created successfully');

  // Test 1: Admin client auth access
  logInfo('Test 1: Admin client - Auth users access');
  
  try {
    const { data: usersData, error: usersError } = await adminClient.auth.admin.listUsers({
      page: 1,
      perPage: 10
    });
    
    if (usersError) {
      logError('Không thể truy cập auth.users với admin client', usersError);
      return false;
    }
    
    logSuccess('Admin auth access OK', {
      totalUsers: usersData.users?.length || 0,
      users: usersData.users?.map(u => ({
        id: u.id,
        email: u.email,
        confirmed: !!u.email_confirmed_at,
        lastSignIn: u.last_sign_in_at
      })) || []
    });

    // Test 2: Find specific user
    logInfo('Test 2: Tìm user cym_sunset@yahoo.com');
    
    const targetUser = usersData.users?.find(user => user.email === 'cym_sunset@yahoo.com');
    
    if (!targetUser) {
      logWarning('User cym_sunset@yahoo.com KHÔNG TỒN TẠI trong auth.users');
      logInfo('Danh sách users hiện có:');
      usersData.users?.forEach(user => {
        console.log(`  - ${user.email} (ID: ${user.id})`);
      });
    } else {
      logSuccess('User tồn tại trong auth.users', {
        id: targetUser.id,
        email: targetUser.email,
        emailConfirmed: !!targetUser.email_confirmed_at,
        createdAt: targetUser.created_at,
        lastSignIn: targetUser.last_sign_in_at,
        userMetadata: targetUser.user_metadata
      });

      // Test 3: Check user's business associations
      logInfo('Test 3: Kiểm tra business associations của user');
      
      const { data: businessRoles, error: businessError } = await adminClient
        .from('pos_mini_modular3_user_business_roles')
        .select(`
          id,
          role,
          created_at,
          business:business_id (
            id,
            name,
            status,
            subscription:subscription_id (
              id,
              name,
              features
            )
          )
        `)
        .eq('user_id', targetUser.id);
      
      if (businessError) {
        logError('Không thể lấy business roles', businessError);
      } else if (!businessRoles || businessRoles.length === 0) {
        logWarning('User CHƯA ĐƯỢC GÁN VÀO BUSINESS NÀO');
        logInfo('Để khắc phục, cần tạo business và gán user vào business đó');
      } else {
        logSuccess('User có business associations', {
          totalBusinesses: businessRoles.length,
          businesses: businessRoles
        });
      }
    }
    
  } catch (error) {
    logError('Admin test failed', error.message);
    return false;
  }

  // Test 4: Test anon client limitations
  logInfo('Test 4: Anon client limitations');
  
  try {
    const { data: anonBusinesses, error: anonError } = await anonClient
      .from('pos_mini_modular3_businesses')
      .select('id, name')
      .limit(1);
    
    if (anonError) {
      logWarning('Anon client không thể truy cập businesses (RLS)', anonError.message);
    } else {
      logSuccess('Anon client có thể truy cập businesses', {
        count: anonBusinesses?.length || 0
      });
    }
    
  } catch (error) {
    logWarning('Anon test error', error.message);
  }

  // Test 5: Test authentication với credentials
  logInfo('Test 5: Test authentication với user credentials');
  
  try {
    const { data: loginData, error: loginError } = await anonClient.auth.signInWithPassword({
      email: 'cym_sunset@yahoo.com',
      password: 'Tnt@9961266'
    });
    
    if (loginError) {
      logError('Login thất bại', {
        message: loginError.message,
        status: loginError.status
      });
      
      if (loginError.message.includes('Invalid login credentials')) {
        logWarning('Có thể do:');
        console.log('  1. User không tồn tại');
        console.log('  2. Mật khẩu không đúng');
        console.log('  3. Email chưa được confirmed');
      }
    } else {
      logSuccess('Login thành công!', {
        userId: loginData.user?.id,
        email: loginData.user?.email,
        accessToken: loginData.session?.access_token ? 'Present' : 'Missing'
      });
      
      // Test authenticated request
      const { data: userBusinesses, error: userBusinessError } = await anonClient
        .from('pos_mini_modular3_user_business_roles')
        .select('*');
      
      if (userBusinessError) {
        logWarning('Authenticated user không thể truy cập business roles', userBusinessError);
      } else {
        logSuccess('Authenticated access works', {
          businessRoles: userBusinesses?.length || 0
        });
      }
      
      // Sign out
      await anonClient.auth.signOut();
      logInfo('Signed out successfully');
    }
    
  } catch (error) {
    logError('Authentication test error', error.message);
  }

  // Test 6: Database functions
  logInfo('Test 6: Test database functions');
  
  try {
    const { data: functionsList, error: functionsError } = await adminClient
      .from('pg_proc')
      .select('proname')
      .like('proname', 'pos_mini_modular3_%')
      .limit(10);
    
    if (functionsError) {
      logWarning('Không thể list database functions', functionsError);
    } else {
      logSuccess('Database functions', {
        functions: functionsList?.map(f => f.proname) || []
      });
    }
    
  } catch (error) {
    logWarning('Functions test error', error.message);
  }

  // Summary
  logInfo('='.repeat(60));
  logSuccess('ADVANCED DATABASE TEST HOÀN TẤT');
  logInfo('='.repeat(60));
  
  return true;
}

// Create test user function
async function createTestUser() {
  logInfo('Tạo test user cym_sunset@yahoo.com');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false }
  });

  try {
    const { data: userData, error: userError } = await adminClient.auth.admin.createUser({
      email: 'cym_sunset@yahoo.com',
      password: 'Tnt@9961266',
      email_confirm: true,
      user_metadata: {
        full_name: 'Test User Cym Sunset'
      }
    });

    if (userError) {
      logError('Không thể tạo user', userError);
      return false;
    }

    logSuccess('User đã được tạo', {
      id: userData.user?.id,
      email: userData.user?.email
    });

    return userData.user;
    
  } catch (error) {
    logError('Create user error', error.message);
    return false;
  }
}

// Run based on command line argument
if (require.main === module) {
  const command = process.argv[2];
  
  if (command === 'create-user') {
    createTestUser()
      .then((user) => {
        if (user) {
          logSuccess('User creation completed');
          process.exit(0);
        } else {
          logError('User creation failed');
          process.exit(1);
        }
      })
      .catch((error) => {
        logError('Unexpected error', error.message);
        process.exit(1);
      });
  } else {
    testAdvancedDatabase()
      .then((success) => {
        if (success) {
          logSuccess('All tests completed');
          process.exit(0);
        } else {
          logError('Some tests failed');
          process.exit(1);
        }
      })
      .catch((error) => {
        logError('Unexpected error', error.message);
        console.error(error);
        process.exit(1);
      });
  }
}

module.exports = { testAdvancedDatabase, createTestUser };
