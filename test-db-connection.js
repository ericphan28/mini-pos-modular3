#!/usr/bin/env node

/**
 * Test Database Connection Script
 * Kiểm tra kết nối Supabase database qua anon key
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

async function testDatabaseConnection() {
  logInfo('Bắt đầu test kết nối database');
  
  // 1. Kiểm tra environment variables
  logInfo('Kiểm tra environment variables');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl) {
    logError('NEXT_PUBLIC_SUPABASE_URL không được cấu hình');
    return false;
  }
  
  if (!supabaseKey) {
    logError('NEXT_PUBLIC_SUPABASE_ANON_KEY không được cấu hình');
    return false;
  }
  
  logSuccess('Environment variables OK', {
    url: supabaseUrl,
    key: `${supabaseKey.substring(0, 20)}...`
  });

  // 2. Tạo Supabase client
  logInfo('Tạo Supabase client');
  
  let supabase;
  try {
    supabase = createClient(supabaseUrl, supabaseKey);
    logSuccess('Supabase client đã được tạo');
  } catch (error) {
    logError('Không thể tạo Supabase client', error.message);
    return false;
  }

  // 3. Test basic connection với public table (nếu có)
  logInfo('Test kết nối cơ bản');
  
  try {
    // Thử truy cập một bảng public đơn giản
    const { data, error, count } = await supabase
      .from('pos_mini_modular3_businesses')
      .select('id, name', { count: 'exact' })
      .limit(1);
    
    if (error) {
      logError('Không thể truy cập bảng businesses', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      });
      return false;
    }
    
    logSuccess('Truy cập bảng businesses thành công', {
      totalRecords: count,
      sampleData: data
    });
    
  } catch (error) {
    logError('Lỗi khi test kết nối cơ bản', error.message);
    return false;
  }

  // 4. Test auth table access (có thể bị giới hạn với anon key)
  logInfo('Test truy cập auth tables');
  
  try {
    const { data: authData, error: authError } = await supabase.auth.getSession();
    
    if (authError) {
      logWarning('Không thể lấy session (bình thường với anon key)', authError.message);
    } else {
      logSuccess('Auth system accessible', {
        hasSession: !!authData.session
      });
    }
    
  } catch (error) {
    logWarning('Auth test có lỗi (có thể bình thường)', error.message);
  }

  // 5. Test user business roles table
  logInfo('Test truy cập user business roles table');
  
  try {
    const { data: rolesData, error: rolesError, count: rolesCount } = await supabase
      .from('pos_mini_modular3_user_business_roles')
      .select('id, role', { count: 'exact' })
      .limit(1);
    
    if (rolesError) {
      logError('Không thể truy cập bảng user_business_roles', {
        code: rolesError.code,
        message: rolesError.message
      });
    } else {
      logSuccess('Truy cập bảng user_business_roles thành công', {
        totalRecords: rolesCount,
        sampleData: rolesData
      });
    }
    
  } catch (error) {
    logError('Lỗi khi test user business roles', error.message);
  }

  // 6. Test subscriptions table
  logInfo('Test truy cập subscriptions table');
  
  try {
    const { data: subsData, error: subsError, count: subsCount } = await supabase
      .from('pos_mini_modular3_subscriptions')
      .select('id, name, features', { count: 'exact' })
      .limit(5);
    
    if (subsError) {
      logError('Không thể truy cập bảng subscriptions', {
        code: subsError.code,
        message: subsError.message
      });
    } else {
      logSuccess('Truy cập bảng subscriptions thành công', {
        totalRecords: subsCount,
        availablePlans: subsData?.map(s => s.name) || []
      });
    }
    
  } catch (error) {
    logError('Lỗi khi test subscriptions', error.message);
  }

  // 7. Test RPC functions
  logInfo('Test RPC functions');
  
  try {
    // Test function để lấy user với business
    const { data: rpcData, error: rpcError } = await supabase
      .rpc('pos_mini_modular3_get_user_with_business', {
        p_user_id: '00000000-0000-0000-0000-000000000000' // Dummy UUID
      });
    
    if (rpcError) {
      if (rpcError.code === '42883') {
        logWarning('RPC function chưa được tạo (cần migration)', rpcError.message);
      } else {
        logError('RPC function có lỗi', {
          code: rpcError.code,
          message: rpcError.message
        });
      }
    } else {
      logSuccess('RPC function accessible', { result: rpcData });
    }
    
  } catch (error) {
    logWarning('RPC test có lỗi', error.message);
  }

  // 8. Test specific user lookup
  logInfo('Test tìm user cụ thể');
  
  try {
    // Thử tìm user thông qua join với auth.users (nếu có quyền)
    const { data: userData, error: userError } = await supabase
      .from('pos_mini_modular3_user_business_roles')
      .select(`
        id,
        role,
        created_at
      `)
      .limit(1);
    
    if (userError) {
      logWarning('Không thể tìm user data', {
        code: userError.code,
        message: userError.message
      });
    } else {
      logSuccess('User data accessible', {
        hasUserRoles: userData?.length > 0,
        sampleRole: userData?.[0]
      });
    }
    
  } catch (error) {
    logWarning('User lookup có lỗi', error.message);
  }

  // 9. Summary
  logInfo('='.repeat(50));
  logInfo('KẾT QUẢ TEST DATABASE CONNECTION');
  logInfo('='.repeat(50));
  
  logSuccess('Database connection test hoàn tất');
  logInfo('Nếu có lỗi RLS (Row Level Security), đây là bình thường với anon key');
  logInfo('Để test đầy đủ, cần dùng authenticated user hoặc service role key');
  
  return true;
}

// Chạy test
if (require.main === module) {
  testDatabaseConnection()
    .then((success) => {
      if (success) {
        logSuccess('Test hoàn tất');
        process.exit(0);
      } else {
        logError('Test thất bại');
        process.exit(1);
      }
    })
    .catch((error) => {
      logError('Test bị lỗi không mong muốn', error.message);
      console.error(error);
      process.exit(1);
    });
}

module.exports = { testDatabaseConnection };
