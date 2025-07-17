#!/usr/bin/env node

/**
 * Check Existing Tables Script
 * Kiểm tra các tables hiện có trong database
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

async function checkExistingTables() {
  logInfo('Bắt đầu kiểm tra tables hiện có trong database');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    logError('Missing environment variables');
    return false;
  }
  
  // Sử dụng service role key để có quyền truy cập đầy đủ
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  logInfo('Tạo client với service role key');
  
  try {
    // 1. Kiểm tra tất cả tables trong schema public
    logInfo('Lấy danh sách tất cả tables');
    
    const { data: tables, error: tablesError } = await supabase
      .from('information_schema.tables')
      .select('table_name, table_type')
      .eq('table_schema', 'public')
      .order('table_name');
    
    if (tablesError) {
      logError('Không thể lấy danh sách tables', tablesError);
      return false;
    }
    
    logSuccess(`Tìm thấy ${tables.length} tables`, {
      tables: tables.map(t => t.table_name)
    });
    
    // 2. Tìm các tables có prefix pos_mini_modular3_
    const posTabels = tables.filter(t => t.table_name.startsWith('pos_mini_modular3_'));
    
    if (posTabels.length > 0) {
      logSuccess(`Tìm thấy ${posTabels.length} POS tables`, {
        posTables: posTabels.map(t => t.table_name)
      });
    } else {
      logWarning('KHÔNG tìm thấy tables POS nào!');
      logInfo('Cần chạy migration để tạo tables');
    }
    
    // 3. Kiểm tra các tables cần thiết
    const requiredTables = [
      'pos_mini_modular3_businesses',
      'pos_mini_modular3_subscriptions', 
      'pos_mini_modular3_user_business_roles',
      'pos_mini_modular3_business_types'
    ];
    
    logInfo('Kiểm tra các tables cần thiết');
    
    for (const tableName of requiredTables) {
      const exists = tables.some(t => t.table_name === tableName);
      if (exists) {
        logSuccess(`Table ${tableName} ✓`);
        
        // Kiểm tra structure của table
        try {
          const { data: columns, error: colError } = await supabase
            .from('information_schema.columns')
            .select('column_name, data_type, is_nullable')
            .eq('table_schema', 'public')
            .eq('table_name', tableName)
            .order('ordinal_position');
          
          if (!colError && columns) {
            logInfo(`  Columns: ${columns.map(c => c.column_name).join(', ')}`);
          }
        } catch (err) {
          logWarning(`  Cannot get columns for ${tableName}`);
        }
        
      } else {
        logError(`Table ${tableName} ❌ MISSING`);
      }
    }
    
    // 4. Kiểm tra functions
    logInfo('Kiểm tra RPC functions');
    
    const { data: functions, error: funcError } = await supabase
      .from('information_schema.routines')
      .select('routine_name, routine_type')
      .eq('routine_schema', 'public')
      .ilike('routine_name', 'pos_mini_modular3_%');
    
    if (funcError) {
      logWarning('Không thể kiểm tra functions', funcError);
    } else {
      if (functions && functions.length > 0) {
        logSuccess(`Tìm thấy ${functions.length} POS functions`, {
          functions: functions.map(f => f.routine_name)
        });
      } else {
        logWarning('KHÔNG tìm thấy POS functions nào!');
      }
    }
    
    // 5. Kiểm tra auth.users
    logInfo('Kiểm tra auth.users table');
    
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 5
    });
    
    if (authError) {
      logError('Không thể truy cập auth.users', authError);
    } else {
      logSuccess(`Auth users table OK - ${authUsers.users.length} users found`, {
        sampleEmails: authUsers.users.slice(0, 3).map(u => u.email)
      });
      
      // Tìm user cụ thể
      const targetUser = authUsers.users.find(u => u.email === 'cym_sunset@yahoo.com');
      if (targetUser) {
        logSuccess('Tìm thấy target user!', {
          id: targetUser.id,
          email: targetUser.email,
          confirmed: !!targetUser.email_confirmed_at,
          lastSignIn: targetUser.last_sign_in_at
        });
      } else {
        logWarning('KHÔNG tìm thấy user cym_sunset@yahoo.com');
      }
    }
    
    // 6. Summary và recommendations
    logInfo('='.repeat(60));
    logInfo('KẾT QUẢ KIỂM TRA DATABASE');
    logInfo('='.repeat(60));
    
    const hasPOSTables = posTabels.length > 0;
    const hasRequiredTables = requiredTables.every(table => 
      tables.some(t => t.table_name === table)
    );
    
    if (hasPOSTables && hasRequiredTables) {
      logSuccess('✅ Database đã được setup đầy đủ');
      logInfo('💡 Có thể test login bình thường');
    } else {
      logError('❌ Database CHƯA được setup đầy đủ');
      logWarning('🔧 CẦN CHẠY MIGRATION trước khi có thể login');
      
      if (!hasPOSTables) {
        logError('  - Thiếu tất cả POS tables');
      }
      
      for (const table of requiredTables) {
        const exists = tables.some(t => t.table_name === table);
        if (!exists) {
          logError(`  - Thiếu table: ${table}`);
        }
      }
      
      logInfo('📝 HƯỚNG DẪN KHẮC PHỤC:');
      logInfo('  1. Kiểm tra folder supabase/migrations/');
      logInfo('  2. Chạy migration trong Supabase Dashboard');
      logInfo('  3. Hoặc chạy: npx supabase db push (nếu có setup local)');
    }
    
    return hasRequiredTables;
    
  } catch (error) {
    logError('Lỗi khi kiểm tra database', error.message);
    console.error(error);
    return false;
  }
}

// Chạy kiểm tra
if (require.main === module) {
  checkExistingTables()
    .then((success) => {
      if (success) {
        logSuccess('Kiểm tra hoàn tất - Database OK');
        process.exit(0);
      } else {
        logError('Kiểm tra hoàn tất - Database cần setup');
        process.exit(1);
      }
    })
    .catch((error) => {
      logError('Kiểm tra thất bại', error.message);
      process.exit(1);
    });
}

module.exports = { checkExistingTables };
