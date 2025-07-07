#!/usr/bin/env node

// demo-terminal-log.js - Test terminal logging
// Run: node demo-terminal-log.js

const colorCodes = {
  INFO: '\x1b[34m',      // Blue
  SUCCESS: '\x1b[32m',   // Green
  WARN: '\x1b[33m',      // Yellow
  ERROR: '\x1b[31m',     // Red
  DEBUG: '\x1b[35m',     // Magenta
  RESET: '\x1b[0m'       // Reset
};

function formatLog(level, step, message, data = null) {
  const timestamp = new Date().toLocaleTimeString('vi-VN');
  const icon = {
    INFO: '🔵',
    SUCCESS: '✅', 
    WARN: '⚠️',
    ERROR: '❌',
    DEBUG: '🔍'
  }[level];

  const colorCode = colorCodes[level] || '';
  const resetCode = colorCodes.RESET;
  const dataStr = data ? '\n' + JSON.stringify(data, null, 2) : '';
  
  return `${colorCode}${icon} [${timestamp}] ${step}: ${message}${dataStr}${resetCode}`;
}

console.log('\n🚀 === DEMO TERMINAL LOGGING SYSTEM ===\n');

// Demo successful login flow
setTimeout(() => {
  console.log(formatLog('INFO', 'INIT', 'Khởi tạo các bước đăng nhập'));
}, 100);

setTimeout(() => {
  console.log(formatLog('INFO', 'VALIDATION', 'Kiểm tra thông tin đầu vào', { email: 'demo@example.com' }));
}, 300);

setTimeout(() => {
  console.log(formatLog('SUCCESS', 'VALIDATION', 'Thông tin hợp lệ'));
}, 500);

setTimeout(() => {
  console.log(formatLog('INFO', 'AUTH', 'Gửi yêu cầu xác thực', { email: 'demo@example.com' }));
}, 700);

setTimeout(() => {
  console.log(formatLog('SUCCESS', 'AUTH', 'Xác thực thành công', { 
    userId: 'demo-uuid-123', 
    email: 'demo@example.com' 
  }));
}, 1000);

setTimeout(() => {
  console.log(formatLog('INFO', 'PROFILE', 'Bắt đầu tải profile người dùng'));
}, 1200);

setTimeout(() => {
  console.log(formatLog('WARN', 'PROFILE', 'Profile không tồn tại - thử tạo tự động'));
}, 1400);

setTimeout(() => {
  console.log(formatLog('SUCCESS', 'PROFILE', 'Tạo profile thành công - tiếp tục login'));
}, 1600);

setTimeout(() => {
  console.log(formatLog('SUCCESS', 'LOGIN', 'Đăng nhập thành công - chuyển hướng dashboard', {
    businessId: 'demo-business-123',
    businessName: 'Demo Company', 
    role: 'staff',
    subscriptionStatus: 'active'
  }));
}, 1800);

setTimeout(() => {
  console.log('\n✅ Terminal logging demo completed!');
  console.log('💡 This is how logs will appear in your PowerShell terminal when running npm run dev\n');
}, 2000);
