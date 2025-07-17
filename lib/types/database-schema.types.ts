/**
 * 🤖 COPILOT CONTEXT: Database Schema Registry
 * 
 * @description Complete database schema for GitHub Copilot understanding
 * @domain POS System - Vietnamese Business Management
 * @architecture Multi-tenant with Row Level Security
 */

// =============================================
// DATABASE TABLES REGISTRY
// =============================================

export interface DatabaseTables {
  // Auth & User Management
  'auth.users': {
    id: string;
    email?: string;
    phone?: string;
    created_at: string;
    email_confirmed_at?: string;
    phone_confirmed_at?: string;
    encrypted_password?: string;
    raw_user_meta_data?: Record<string, unknown>;
    raw_app_meta_data?: Record<string, unknown>;
  };

  // User Profiles (extends auth.users)
  'pos_mini_modular3_user_profiles': {
    id: string; // References auth.users(id)
    full_name: string;
    business_id?: string;
    role: UserRole;
    email?: string;
    phone?: string;
    login_method: ContactMethod;
    status: UserStatus;
    permissions?: Record<string, boolean | string | number>;
    employee_id?: string;
    hire_date?: string;
    notes?: string;
    created_at: string;
    updated_at: string;
  };

  // Business Management
  'pos_mini_modular3_businesses': {
    id: string;
    name: string;
    code: string; // Auto-generated unique code (GKS00001)
    business_type: BusinessTypeEnum;
    phone?: string;
    email?: string;
    address?: string;
    tax_code?: string;
    legal_representative?: string;
    logo_url?: string;
    status: BusinessStatusEnum;
    settings?: Record<string, unknown>;
    trial_ends_at: string;
    max_users: number;
    max_products: number;
    subscription_tier: SubscriptionTier;
    subscription_status: SubscriptionStatus;
    subscription_starts_at?: string;
    subscription_ends_at?: string;
    created_at: string;
    updated_at: string;
  };

  // Admin Activity Tracking (NEW)
  'pos_mini_modular3_admin_credential_logs': {
    id: string;
    business_id: string;
    created_by: string; // Super admin user ID
    contact_method: ContactMethod;
    contact_value: string;
    password_generated: boolean;
    welcome_sent: boolean;
    welcome_sent_at?: string;
    temp_password: boolean;
    created_at: string;
  };

  // Business Setup Progress (NEW)
  'pos_mini_modular3_business_setup_progress': {
    business_id: string; // Primary key
    welcome_received: boolean;
    password_changed: boolean;
    profile_completed: boolean;
    first_product_added: boolean;
    first_sale_completed: boolean;
    setup_completed_at?: string;
    created_at: string;
    updated_at: string;
  };
}

// =============================================
// ENUM TYPES (Database Enums)
// =============================================

export type UserRole = 
  | 'super_admin'      // System super admin
  | 'household_owner'  // Business owner
  | 'manager'          // Business manager
  | 'seller'           // Sales staff
  | 'accountant';      // Accounting staff

export type UserStatus = 'active' | 'inactive' | 'suspended';

export type ContactMethod = 'email' | 'phone';

export type BusinessTypeEnum = 
  | 'retail'     // Bán lẻ
  | 'restaurant' // Nhà hàng
  | 'service'    // Dịch vụ  
  | 'wholesale'; // Bán sỉ

export type BusinessStatusEnum = 
  | 'trial'     // Đang dùng thử
  | 'active'    // Hoạt động
  | 'suspended' // Tạm ngưng
  | 'closed';   // Đã đóng

export type SubscriptionTier = 'free' | 'basic' | 'premium' | 'enterprise';
export type SubscriptionStatus = 'trial' | 'active' | 'past_due' | 'cancelled' | 'suspended' | 'expired';

// =============================================
// DATABASE FUNCTIONS REGISTRY
// =============================================

export interface DatabaseFunctions {
  // Super Admin Functions
  'pos_mini_modular3_super_admin_check_permission': {
    Args: Record<string, never>;
    Returns: boolean;
  };

  'pos_mini_modular3_super_admin_create_complete_business': {
    Args: {
      p_business_name: string;
      p_contact_method: string;
      p_contact_value: string;
      p_owner_full_name: string;
      p_business_type?: string;
      p_subscription_tier?: string;
      p_set_password?: string | null;
      p_is_active?: boolean;
    };
    Returns: {
      success: boolean;
      business_id?: string;
      business_name?: string;
      business_code?: string;
      business_status?: string;
      subscription_tier?: string;
      user_created?: boolean;
      user_id?: string;
      message?: string;
      error?: string;
    };
  };

  'pos_mini_modular3_super_admin_get_business_registration_stats': {
    Args: Record<string, never>;
    Returns: {
      total_businesses: number;
      active_businesses: number;
      trial_businesses: number;
      total_users: number;
      total_owners: number;
      total_staff: number;
    };
  };

  // Helper Functions (NEW)
  'generate_business_code': {
    Args: Record<string, never>; // Empty object
    Returns: string;
  };

  'get_default_business_settings': {
    Args: {
      p_business_type: BusinessTypeEnum;
      p_subscription_tier: SubscriptionTier;
    };
    Returns: {
      trial_days: number;
      max_users: number;
      max_products: number;
      features: string[];
      currency: string;
      timezone: string;
      language: string;
    };
  };

  // Enhanced Business Creation (NEW)
  'pos_mini_modular3_create_business_with_auth_simple': {
    Args: {
      p_business_name: string;
      p_contact_method: ContactMethod;
      p_contact_value: string;
      p_owner_name: string;
      p_business_type: BusinessTypeEnum;
      p_subscription_tier: SubscriptionTier;
      p_business_status: BusinessStatusEnum;
      p_subscription_status: SubscriptionStatus;
      p_password?: string | null;
      p_created_by_admin?: string | null;
    };
    Returns: {
      success: boolean;
      business_id?: string;
      user_id?: string;
      business_name?: string;
      business_code?: string;
      contact_method?: ContactMethod;
      contact_value?: string;
      auth_email?: string;
      password_set?: boolean;
      login_ready?: boolean;
      message?: string;
      error?: string;
    };
  };
}

// =============================================
// RPC FUNCTION TYPES (Type-safe RPC calls)
// =============================================

export type DatabaseFunctionName = keyof DatabaseFunctions;

export type DatabaseFunctionParams<T extends DatabaseFunctionName> = 
  DatabaseFunctions[T]['Args'];

export type DatabaseFunctionResult<T extends DatabaseFunctionName> = 
  DatabaseFunctions[T]['Returns'];

// =============================================
// SUPABASE CLIENT CONTEXTS
// =============================================

export interface SupabaseClientContext {
  type: 'browser' | 'server' | 'admin';
  hasRLS: boolean;
  permissions: string[];
  description: string;
  usage: string;
}

export const SUPABASE_CLIENTS: Record<string, SupabaseClientContext> = {
  browser: {
    type: 'browser',
    hasRLS: true,
    permissions: ['read_own', 'write_own'],
    description: 'Client-side operations with user session',
    usage: 'Form submissions, user-scoped queries'
  },
  server: {
    type: 'server',
    hasRLS: true,
    permissions: ['read_own', 'write_own', 'server_side'],
    description: 'Server-side operations with user session',
    usage: 'SSR, protected API routes'
  },
  admin: {
    type: 'admin',
    hasRLS: false,
    permissions: ['read_all', 'write_all', 'admin_functions'],
    description: 'Admin operations bypassing RLS',
    usage: 'Cross-tenant operations, admin functions'
  }
};

// =============================================
// ERROR HANDLING PATTERNS
// =============================================

export interface DatabaseError {
  code: string;
  message: string;
  details?: string;
  hint?: string;
}

export interface AppError {
  code: string;
  userMessage: string;
  technicalMessage: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

// =============================================
// VALIDATION SCHEMAS CONTEXT
// =============================================

export interface ValidationContext {
  emailRegex: RegExp;
  phoneRegex: RegExp;
  vietnamesePhoneFormats: string[];
  passwordMinLength: number;
  businessNameMaxLength: number;
  businessCodePattern: RegExp;
}

export const VALIDATION_PATTERNS: ValidationContext = {
  emailRegex: /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/,
  phoneRegex: /^(\+84|84|0)[0-9]{8,10}$/,
  vietnamesePhoneFormats: ['+84', '84', '0'],
  passwordMinLength: 6,
  businessNameMaxLength: 255,
  businessCodePattern: /^GKS\d{5}$/ // GKS00001, GKS00002, etc.
};

// =============================================
// BUSINESS DOMAIN INTERFACES
// =============================================

export interface BusinessRegistrationData {
  business_name: string;
  contact_method: ContactMethod;
  contact_value: string;
  owner_full_name: string;
  business_type: BusinessTypeEnum;
  subscription_tier: SubscriptionTier;
  business_status: BusinessStatusEnum;
  subscription_status: SubscriptionStatus;
  set_password?: string | null;
}

export interface BusinessRegistrationResult {
  success: boolean;
  business_id?: string;
  business_name?: string;
  business_code?: string;
  user_created?: boolean;
  user_id?: string;
  message?: string;
  error?: string;
  appError?: AppError;
  credentials_sent?: boolean;
  login_info?: {
    method: ContactMethod;
    value: string;
    temp_password?: boolean;
  };
}

// =============================================
// HELPER TYPES FOR COPILOT
// =============================================

export type DatabaseFunction<T extends keyof DatabaseFunctions> = {
  name: T;
  params: DatabaseFunctions[T]['Args'];
  returns: DatabaseFunctions[T]['Returns'];
};

// Copilot can use this to understand function calling patterns
export type RPCCall<T extends keyof DatabaseFunctions> = (
  functionName: T,
  params: DatabaseFunctions[T]['Args']
) => Promise<{ data: DatabaseFunctions[T]['Returns']; error: Error | null }>;

// Service Response Pattern
export interface ServiceResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  appError?: AppError;
}

// Paginated Response Pattern
export interface PaginatedResponse<T> {
  data: T[];
  count: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// Vietnamese Business Context
export interface VietnameseBusinessData {
  business_name: string; // Tên hộ kinh doanh
  owner_full_name: string; // Tên chủ hộ
  contact_value: string; // Email hoặc số điện thoại
  business_type: BusinessTypeEnum; // Loại hình kinh doanh
}

export default DatabaseFunctions;
