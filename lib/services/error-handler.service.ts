/**
 * Error Handler for Business Registration System
 * Provides consistent error handling and user-friendly messages
 */

export interface AppError {
  code: string;
  message: string;
  userMessage: string;
  severity: 'error' | 'warning' | 'info';
}

export class BusinessRegistrationError extends Error {
  constructor(
    public code: string,
    public userMessage: string,
    public severity: 'error' | 'warning' | 'info' = 'error',
    message?: string
  ) {
    super(message || userMessage);
    this.name = 'BusinessRegistrationError';
  }
}

// =============================================
// ERROR CODES & MESSAGES
// =============================================

export const ERROR_CODES = {
  // Validation Errors
  VALIDATION_FAILED: 'VALIDATION_FAILED',
  INVALID_EMAIL: 'INVALID_EMAIL',
  INVALID_PHONE: 'INVALID_PHONE',
  WEAK_PASSWORD: 'WEAK_PASSWORD',
  REQUIRED_FIELD: 'REQUIRED_FIELD',

  // Business Logic Errors
  DUPLICATE_CONTACT: 'DUPLICATE_CONTACT',
  BUSINESS_EXISTS: 'BUSINESS_EXISTS',
  INVALID_BUSINESS_TYPE: 'INVALID_BUSINESS_TYPE',
  INVALID_SUBSCRIPTION: 'INVALID_SUBSCRIPTION',

  // Permission Errors
  PERMISSION_DENIED: 'PERMISSION_DENIED',
  NOT_SUPER_ADMIN: 'NOT_SUPER_ADMIN',

  // System Errors
  DATABASE_ERROR: 'DATABASE_ERROR',
  FUNCTION_NOT_FOUND: 'FUNCTION_NOT_FOUND',
  NETWORK_ERROR: 'NETWORK_ERROR',
  UNKNOWN_ERROR: 'UNKNOWN_ERROR',

  // Profile & RLS Errors
  PROFILE_NOT_FOUND: 'PROFILE_NOT_FOUND',
  RLS_RECURSION: 'RLS_RECURSION',
  PROFILE_CHECK_FAILED: 'PROFILE_CHECK_FAILED'
} as const;

const ERROR_MESSAGES: Record<string, { message: string; userMessage: string; severity: 'error' | 'warning' | 'info' }> = {
  [ERROR_CODES.VALIDATION_FAILED]: {
    message: 'Form validation failed',
    userMessage: 'Vui lòng kiểm tra lại thông tin đã nhập',
    severity: 'error'
  },
  [ERROR_CODES.INVALID_EMAIL]: {
    message: 'Invalid email format',
    userMessage: 'Định dạng email không hợp lệ',
    severity: 'error'
  },
  [ERROR_CODES.INVALID_PHONE]: {
    message: 'Invalid phone number format',
    userMessage: 'Số điện thoại không đúng định dạng Việt Nam',
    severity: 'error'
  },
  [ERROR_CODES.WEAK_PASSWORD]: {
    message: 'Password too weak',
    userMessage: 'Mật khẩu phải có ít nhất 6 ký tự',
    severity: 'error'
  },
  [ERROR_CODES.REQUIRED_FIELD]: {
    message: 'Required field missing',
    userMessage: 'Vui lòng điền đầy đủ thông tin bắt buộc',
    severity: 'error'
  },
  [ERROR_CODES.DUPLICATE_CONTACT]: {
    message: 'Contact information already exists',
    userMessage: 'Email hoặc số điện thoại này đã được đăng ký',
    severity: 'error'
  },
  [ERROR_CODES.BUSINESS_EXISTS]: {
    message: 'Business name already exists',
    userMessage: 'Tên hộ kinh doanh đã tồn tại',
    severity: 'error'
  },
  [ERROR_CODES.INVALID_BUSINESS_TYPE]: {
    message: 'Invalid business type',
    userMessage: 'Loại hình kinh doanh không hợp lệ',
    severity: 'error'
  },
  [ERROR_CODES.INVALID_SUBSCRIPTION]: {
    message: 'Invalid subscription configuration',
    userMessage: 'Cấu hình gói dịch vụ không hợp lệ',
    severity: 'error'
  },
  [ERROR_CODES.PERMISSION_DENIED]: {
    message: 'Permission denied',
    userMessage: 'Bạn không có quyền thực hiện thao tác này',
    severity: 'error'
  },
  [ERROR_CODES.NOT_SUPER_ADMIN]: {
    message: 'Super admin access required',
    userMessage: 'Chỉ Super Admin mới có quyền tạo hộ kinh doanh',
    severity: 'error'
  },
  [ERROR_CODES.DATABASE_ERROR]: {
    message: 'Database operation failed',
    userMessage: 'Lỗi cơ sở dữ liệu. Vui lòng thử lại sau',
    severity: 'error'
  },
  [ERROR_CODES.FUNCTION_NOT_FOUND]: {
    message: 'Database function not found',
    userMessage: 'Chức năng chưa được cài đặt. Vui lòng liên hệ quản trị viên',
    severity: 'warning'
  },
  [ERROR_CODES.NETWORK_ERROR]: {
    message: 'Network connection failed',
    userMessage: 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại',
    severity: 'error'
  },
  [ERROR_CODES.UNKNOWN_ERROR]: {
    message: 'Unknown error occurred',
    userMessage: 'Đã có lỗi không xác định xảy ra',
    severity: 'error'
  },
  [ERROR_CODES.PROFILE_NOT_FOUND]: {
    message: 'User profile not found',
    userMessage: 'Không tìm thấy thông tin người dùng',
    severity: 'warning'
  },
  [ERROR_CODES.RLS_RECURSION]: {
    message: 'RLS policy recursion detected',
    userMessage: 'Đang tải thông tin người dùng...',
    severity: 'info'
  },
  [ERROR_CODES.PROFILE_CHECK_FAILED]: {
    message: 'Profile check failed',
    userMessage: 'Không thể kiểm tra thông tin người dùng',
    severity: 'error'
  }
};

// =============================================
// ERROR PARSER
// =============================================

export class ErrorHandler {
  /**
   * Parse error from different sources and return standardized AppError
   */
  static parseError(error: unknown): AppError {
    // Handle BusinessRegistrationError
    if (error instanceof BusinessRegistrationError) {
      return {
        code: error.code,
        message: error.message,
        userMessage: error.userMessage,
        severity: error.severity
      };
    }

    // Handle string errors
    if (typeof error === 'string') {
      return this.parseStringError(error);
    }

    // Handle object errors (like from Supabase)
    if (error && typeof error === 'object' && 'message' in error) {
      return this.parseObjectError(error as { message: string; code?: string });
    }

    // Default unknown error
    return {
      code: ERROR_CODES.UNKNOWN_ERROR,
      message: String(error),
      userMessage: ERROR_MESSAGES[ERROR_CODES.UNKNOWN_ERROR].userMessage,
      severity: 'error'
    };
  }

  /**
   * Parse string error messages
   */
  private static parseStringError(error: string): AppError {
    const lowerError = error.toLowerCase();

    // Check for specific patterns
    if (lowerError.includes('email') && lowerError.includes('invalid')) {
      return this.createError(ERROR_CODES.INVALID_EMAIL);
    }

    if (lowerError.includes('phone') && lowerError.includes('invalid')) {
      return this.createError(ERROR_CODES.INVALID_PHONE);
    }

    if (lowerError.includes('password') && lowerError.includes('weak')) {
      return this.createError(ERROR_CODES.WEAK_PASSWORD);
    }

    if (lowerError.includes('permission denied')) {
      return this.createError(ERROR_CODES.PERMISSION_DENIED);
    }

    if (lowerError.includes('super admin')) {
      return this.createError(ERROR_CODES.NOT_SUPER_ADMIN);
    }

    if (lowerError.includes('already exists') || lowerError.includes('duplicate')) {
      return this.createError(ERROR_CODES.DUPLICATE_CONTACT);
    }

    if (lowerError.includes('function') && lowerError.includes('does not exist')) {
      return this.createError(ERROR_CODES.FUNCTION_NOT_FOUND);
    }

    if (lowerError.includes('network') || lowerError.includes('connection')) {
      return this.createError(ERROR_CODES.NETWORK_ERROR);
    }

    // Default to unknown error with original message
    return {
      code: ERROR_CODES.UNKNOWN_ERROR,
      message: error,
      userMessage: error,
      severity: 'error'
    };
  }

  /**
   * Parse object errors (from APIs, Supabase, etc.)
   */
  private static parseObjectError(error: { message: string; code?: string }): AppError {
    // Use provided error code if available
    if (error.code && ERROR_MESSAGES[error.code]) {
      return this.createError(error.code);
    }

    // Parse message string
    return this.parseStringError(error.message);
  }

  /**
   * Create standardized error from error code
   */
  private static createError(code: string): AppError {
    const errorInfo = ERROR_MESSAGES[code] || ERROR_MESSAGES[ERROR_CODES.UNKNOWN_ERROR];
    
    return {
      code,
      message: errorInfo.message,
      userMessage: errorInfo.userMessage,
      severity: errorInfo.severity
    };
  }

  /**
   * Log error for debugging (in development)
   */
  static logError(error: AppError, context?: string): void {
    if (process.env.NODE_ENV === 'development') {
      console.group(`🚨 Business Registration Error ${context ? `(${context})` : ''}`);
      console.error('Code:', error.code);
      console.error('Message:', error.message);
      console.error('User Message:', error.userMessage);
      console.error('Severity:', error.severity);
      console.groupEnd();
    }
  }
}

// =============================================
// NOTIFICATION HELPERS
// =============================================

export interface NotificationOptions {
  title?: string;
  description: string;
  duration?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export class NotificationService {
  /**
   * Show success notification
   */
  static success(options: NotificationOptions): void {
    // Implementation depends on your notification library
    // This is a placeholder for the interface
    console.log('SUCCESS:', options);
  }

  /**
   * Show error notification from AppError
   */
  static error(error: AppError, context?: string): void {
    ErrorHandler.logError(error, context);
    
    // Implementation depends on your notification library
    console.log('ERROR:', {
      title: 'Có lỗi xảy ra',
      description: error.userMessage,
      severity: error.severity
    });
  }

  /**
   * Show warning notification
   */
  static warning(options: NotificationOptions): void {
    console.log('WARNING:', options);
  }

  /**
   * Show info notification
   */
  static info(options: NotificationOptions): void {
    console.log('INFO:', options);
  }
}
