// Test Terminal Logging for Staff Dashboard
// Run this to demo terminal logs: node test-terminal-demo.js

const { OptimizedTerminalLogger } = require('./lib/utils/optimized-logger');

// Simulate staff dashboard actions
async function demoStaffDashboardLogs() {
  const terminalLogger = new OptimizedTerminalLogger();

  console.log('\n=== 🎬 DEMO: STAFF DASHBOARD TERMINAL LOGGING ===\n');

  // 1. Component Mount
  terminalLogger.info('🔄 COMPONENT_MOUNT', 'Staff Management Page được khởi tạo', {
    component: 'StaffManagementPage',
    mount_time: new Date().toLocaleString('vi-VN')
  });

  await new Promise(resolve => setTimeout(resolve, 500));

  // 2. Start Loading Dashboard
  terminalLogger.info('🚀 STAFF_DASHBOARD', 'Bắt đầu tải trang quản lý nhân viên', { 
    timestamp: new Date().toISOString() 
  });

  await new Promise(resolve => setTimeout(resolve, 300));

  // 3. User Authentication
  terminalLogger.info('👤 USER_AUTH', 'User đã xác thực', { 
    user_id: 'abc12345...' 
  });

  await new Promise(resolve => setTimeout(resolve, 200));

  // 4. Business Info Loaded
  terminalLogger.success('🏢 BUSINESS_LOADED', 'Thông tin business đã load', { 
    business_name: 'Cửa Hàng Demo', 
    user_role: 'household_owner' 
  });

  await new Promise(resolve => setTimeout(resolve, 400));

  // 5. Staff Loading
  terminalLogger.info('📊 STAFF_LOADING', 'Đang tải danh sách nhân viên...', { 
    business_id: 'xyz78901...' 
  });

  await new Promise(resolve => setTimeout(resolve, 600));

  // 6. Success Dashboard Load
  terminalLogger.success('✅ STAFF_DASHBOARD_LOADED', 'Dashboard nhân viên đã load thành công!', {
    business_name: 'Cửa Hàng Demo',
    total_staff: 5,
    active_staff: 4,
    role_distribution: { manager: 1, seller: 3, accountant: 1 },
    loaded_by: 'Nguyễn Văn Admin',
    timestamp: new Date().toLocaleString('vi-VN')
  });

  await new Promise(resolve => setTimeout(resolve, 1000));

  // 7. User Action - Create Staff
  terminalLogger.info('🎯 UI_ACTION', 'User nhấn nút "Tạo nhân viên mới"', {
    user_id: 'abc12345...',
    business_name: 'Cửa Hàng Demo',
    action_time: new Date().toLocaleString('vi-VN')
  });

  await new Promise(resolve => setTimeout(resolve, 800));

  // 8. Staff Created Successfully
  terminalLogger.success('👤 STAFF_CREATED', 'Tạo nhân viên mới thành công!', {
    created_by: 'abc12345...',
    business_name: 'Cửa Hàng Demo',
    action_time: new Date().toLocaleString('vi-VN'),
    business_id: 'xyz78901...'
  });

  await new Promise(resolve => setTimeout(resolve, 500));

  // 9. Staff Updated
  terminalLogger.success('✏️ STAFF_UPDATED', 'Cập nhật thông tin nhân viên thành công!', {
    updated_by: 'abc12345...',
    business_name: 'Cửa Hàng Demo',
    action_time: new Date().toLocaleString('vi-VN'),
    business_id: 'xyz78901...'
  });

  await new Promise(resolve => setTimeout(resolve, 300));

  // 10. Component Unmount
  terminalLogger.debug('🧹 COMPONENT_UNMOUNT', 'Staff Management Page đã unmount', {
    component: 'StaffManagementPage',
    unmount_time: new Date().toLocaleString('vi-VN')
  });

  console.log('\n=== 🎉 DEMO HOÀN TẤT ===');
  console.log('✅ Tất cả logs đã hiển thị trên terminal server');
  console.log('🖥️ Trong thực tế, logs sẽ xuất hiện khi user sử dụng dashboard');
  console.log('📊 Logs bao gồm: authentication, loading, actions, errors, metrics\n');
}

// Simulate Error Scenario
async function demoErrorScenario() {
  const terminalLogger = new OptimizedTerminalLogger();

  console.log('\n=== ⚠️ DEMO: ERROR SCENARIOS ===\n');

  // Unauthorized Access
  terminalLogger.warn('🚨 UNAUTHORIZED_ACCESS', 'User role "seller" không có quyền truy cập staff management', {
    user_id: 'def67890...',
    business_id: 'xyz78901...',
    attempted_role: 'seller'
  });

  await new Promise(resolve => setTimeout(resolve, 500));

  // Loading Error
  terminalLogger.error('❌ STAFF_LOAD_ERROR', 'Lỗi tải danh sách nhân viên', {
    business_id: 'xyz78901...',
    error_code: 'PERMISSION_DENIED',
    error_message: 'RLS policy violation'
  });

  await new Promise(resolve => setTimeout(resolve, 500));

  // Critical Error
  terminalLogger.error('💥 CRITICAL_ERROR', 'Lỗi nghiêm trọng khi tải dashboard', {
    error_message: 'Cannot read property of undefined',
    stack_preview: 'at loadData (page.tsx:45:12)...',
    user_id: 'abc12345...'
  });

  console.log('\n=== ⚠️ ERROR DEMO HOÀN TẤT ===\n');
}

// Run demos
async function runDemo() {
  try {
    await demoStaffDashboardLogs();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await demoErrorScenario();
  } catch (error) {
    console.error('Demo error:', error);
  }
}

// Start demo
runDemo();
