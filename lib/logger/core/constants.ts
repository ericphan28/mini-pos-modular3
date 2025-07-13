export const LOG_LEVELS = {
  ERROR: { value: 0, name: 'ERROR', color: '🔴' },
  WARN: { value: 1, name: 'WARN', color: '🟡' },
  INFO: { value: 2, name: 'INFO', color: '🔵' },
  DEBUG: { value: 3, name: 'DEBUG', color: '⚫' },
} as const;

export const LOG_CATEGORIES = {
  AUTH: { name: 'AUTH', description: 'Authentication & Authorization', emoji: '🔐' },
  BUSINESS: { name: 'BUSINESS', description: 'Business Operations', emoji: '💼' },
  SECURITY: { name: 'SECURITY', description: 'Security Events', emoji: '🛡️' },
  PERFORMANCE: { name: 'PERFORMANCE', description: 'Performance Monitoring', emoji: '⚡' },
  AUDIT: { name: 'AUDIT', description: 'Compliance & Audit Trail', emoji: '📋' },
  ERROR: { name: 'ERROR', description: 'Application Errors', emoji: '❌' },
  USER: { name: 'USER', description: 'User Interactions', emoji: '👤' },
  SYSTEM: { name: 'SYSTEM', description: 'System Health', emoji: '⚙️' },
} as const;

export const VIETNAMESE_BUSINESS_EVENTS = {
  PRODUCT_CREATED: 'Tạo sản phẩm mới',
  PRODUCT_UPDATED: 'Cập nhật sản phẩm',
  PRODUCT_DELETED: 'Xóa sản phẩm',
  ORDER_CREATED: 'Tạo đơn hàng mới',
  ORDER_COMPLETED: 'Hoàn thành đơn hàng',
  ORDER_CANCELLED: 'Hủy đơn hàng',
  PAYMENT_PROCESSED: 'Xử lý thanh toán',
  PAYMENT_FAILED: 'Thanh toán thất bại',
  INVENTORY_UPDATED: 'Cập nhật tồn kho',
  INVENTORY_LOW: 'Tồn kho thấp',
  USER_LOGIN: 'Đăng nhập người dùng',
  USER_LOGOUT: 'Đăng xuất người dùng',
  USER_REGISTERED: 'Đăng ký người dùng mới',
  BUSINESS_REGISTERED: 'Đăng ký hộ kinh doanh',
  BUSINESS_UPDATED: 'Cập nhật thông tin kinh doanh',
  SUBSCRIPTION_CHANGED: 'Thay đổi gói đăng ký',
  SUBSCRIPTION_EXPIRED: 'Gói đăng ký hết hạn',
  PERMISSION_GRANTED: 'Cấp quyền truy cập',
  PERMISSION_DENIED: 'Từ chối quyền truy cập',
  DATA_EXPORT: 'Xuất dữ liệu',
  DATA_IMPORT: 'Nhập dữ liệu',
  BACKUP_CREATED: 'Tạo sao lưu',
  BACKUP_RESTORED: 'Khôi phục từ sao lưu',
} as const;

export const PERFORMANCE_THRESHOLDS = {
  FAST: 100, // ms
  NORMAL: 500, // ms
  SLOW: 1000, // ms
  CRITICAL: 5000, // ms
} as const;

export const LOG_RETENTION_PERIODS = {
  FINANCIAL_LOGS: 10, // years - Vietnamese accounting law
  USER_ACTIVITY: 2, // years - GDPR compliance
  SYSTEM_LOGS: 1, // year - operational requirements
  DEBUG_LOGS: 30, // days - development needs
  SECURITY_LOGS: 5, // years - security compliance
} as const;
