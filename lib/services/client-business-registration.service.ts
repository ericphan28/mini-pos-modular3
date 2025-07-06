/**
 * 🚀 CLIENT-SAFE BUSINESS REGISTRATION SERVICE
 * 
 * @description Phiên bản an toàn để sử dụng ở client-side
 * @features Client-side validation, API calls, không sử dụng service role key
 * @version 1.0 - Client-Safe Edition
 */

import { clientBusinessTypeService } from './client-business-type.service';

// =============================================
// 🔥 TYPE DEFINITIONS
// =============================================

export interface BusinessRegistrationData {
  business_name: string;
  contact_method: 'email' | 'phone';
  contact_value: string;
  owner_full_name: string;
  business_type: string;
  subscription_tier: string;
  business_status: string;
  subscription_status: string;
  set_password?: string;
}

export interface BusinessRegistrationResult {
  success: boolean;
  business_id?: string;
  business_name?: string;
  business_code?: string;
  business_status?: string;
  subscription_tier?: string;
  subscription_status?: string;
  user_created?: boolean;
  user_id?: string;
  max_users?: number;
  max_products?: number;
  contact_method?: string;
  contact_value?: string;
  owner_name?: string;
  trial_ends_at?: string;
  message?: string;
  error?: string;
  error_code?: string;
  hint?: string;
  sessionId?: string;
  duration?: number;
}

export interface ValidationResult {
  success: boolean;
  errors?: string[];
  warnings?: string[];
  fieldValidations?: {
    business_name?: { valid: boolean; message?: string };
    contact_value?: { valid: boolean; message?: string };
    owner_full_name?: { valid: boolean; message?: string };
    business_type?: { valid: boolean; message?: string; availableTypes?: string[] };
    subscription_tier?: { valid: boolean; message?: string };
  };
}

// =============================================
// 🚀 CLIENT BUSINESS REGISTRATION SERVICE
// =============================================

export class ClientBusinessRegistrationService {
  private static instance: ClientBusinessRegistrationService;
  private readonly LOG_PREFIX = '🏢 ClientBusinessRegistration';

  static getInstance(): ClientBusinessRegistrationService {
    if (!this.instance) {
      this.instance = new ClientBusinessRegistrationService();
    }
    return this.instance;
  }

  // =============================================
  // 🔍 CLIENT-SIDE VALIDATION METHODS
  // =============================================

  /**
   * Client-side validation - không cần database connection
   */
  validateData(data: BusinessRegistrationData): ValidationResult {
    console.log(`${this.LOG_PREFIX}: 🔍 Starting client-side validation`);

    const errors: string[] = [];
    const warnings: string[] = [];
    const fieldValidations: ValidationResult['fieldValidations'] = {};

    // 🔍 Business Name Validation
    if (!data.business_name?.trim()) {
      errors.push('Tên hộ kinh doanh không được trống');
      fieldValidations.business_name = { valid: false, message: 'Trống' };
    } else if (data.business_name.trim().length < 3) {
      errors.push('Tên hộ kinh doanh phải có ít nhất 3 ký tự');
      fieldValidations.business_name = { valid: false, message: 'Quá ngắn' };
    } else if (data.business_name.trim().length > 100) {
      errors.push('Tên hộ kinh doanh không được vượt quá 100 ký tự');
      fieldValidations.business_name = { valid: false, message: 'Quá dài' };
    } else {
      fieldValidations.business_name = { valid: true };
      
      // Check for suspicious business names
      const suspiciousNames = ['test', 'demo', 'sample', 'example'];
      if (suspiciousNames.some(name => data.business_name.toLowerCase().includes(name))) {
        warnings.push('Tên hộ kinh doanh có vẻ là dữ liệu thử nghiệm');
      }
    }

    // 🔍 Contact Value Validation
    if (!data.contact_value?.trim()) {
      errors.push('Thông tin liên lạc không được trống');
      fieldValidations.contact_value = { valid: false, message: 'Trống' };
    } else {
      fieldValidations.contact_value = { valid: true };
    }

    // 🔍 Owner Name Validation
    if (!data.owner_full_name?.trim()) {
      errors.push('Tên chủ hộ không được trống');
      fieldValidations.owner_full_name = { valid: false, message: 'Trống' };
    } else if (data.owner_full_name.trim().length < 2) {
      errors.push('Tên chủ hộ phải có ít nhất 2 ký tự');
      fieldValidations.owner_full_name = { valid: false, message: 'Quá ngắn' };
    } else {
      fieldValidations.owner_full_name = { valid: true };
    }

    // 🔍 Contact Method Validation
    if (!['email', 'phone'].includes(data.contact_method)) {
      errors.push('Phương thức liên lạc phải là email hoặc phone');
    }

    // 🔍 Enhanced Email Validation
    if (data.contact_method === 'email' && data.contact_value?.trim()) {
      const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
      const email = data.contact_value.trim();
      
      if (!emailRegex.test(email)) {
        errors.push('Định dạng email không hợp lệ');
        fieldValidations.contact_value = { valid: false, message: 'Định dạng không hợp lệ' };
      } else {
        // Enhanced security checks
        const domain = email.split('@')[1]?.toLowerCase();
        const suspiciousDomains = ['example.com', 'test.com', 'demo.com', 'fake.com', 'temporary.email'];
        
        if (suspiciousDomains.includes(domain)) {
          errors.push('Vui lòng sử dụng email thật');
          fieldValidations.contact_value = { valid: false, message: 'Email không hợp lệ' };
        }

        // Check for disposable email domains
        const disposableDomains = ['10minutemail.com', 'tempmail.org', 'guerrillamail.com'];
        if (disposableDomains.includes(domain)) {
          warnings.push('Email có vẻ là email tạm thời');
        }
      }
    }

    // 🔍 Enhanced Phone Validation
    if (data.contact_method === 'phone' && data.contact_value?.trim()) {
      const phoneRegex = /^(\+84|84|0)[0-9]{8,10}$/;
      const cleanPhone = data.contact_value.replace(/[^0-9+]/g, '');
      
      if (!phoneRegex.test(cleanPhone)) {
        errors.push('Số điện thoại không đúng định dạng Việt Nam (VD: 0909123456, +84909123456)');
        fieldValidations.contact_value = { valid: false, message: 'Định dạng không hợp lệ' };
      }
    }

    // 🔍 Business Type Validation (using client-safe service)
    const validTypes = clientBusinessTypeService.getBusinessTypes().map(t => t.value);
    if (!validTypes.includes(data.business_type)) {
      errors.push(`Loại hình kinh doanh không hợp lệ. Các loại hình khả dụng: ${validTypes.join(', ')}`);
      fieldValidations.business_type = { 
        valid: false, 
        message: 'Không hợp lệ',
        availableTypes: validTypes
      };
    } else {
      fieldValidations.business_type = { valid: true };
    }

    // 🔍 Subscription Tier Validation
    if (!['free', 'basic', 'premium'].includes(data.subscription_tier)) {
      errors.push('Gói dịch vụ không hợp lệ');
      fieldValidations.subscription_tier = { valid: false, message: 'Không hợp lệ' };
    } else {
      fieldValidations.subscription_tier = { valid: true };
    }

    // 🔍 Password Validation (if provided)
    if (data.set_password && data.set_password.trim()) {
      if (data.set_password.trim().length < 6) {
        errors.push('Mật khẩu phải có ít nhất 6 ký tự');
      }
      if (data.set_password.trim().length > 50) {
        errors.push('Mật khẩu không được vượt quá 50 ký tự');
      }
      
      // Enhanced password strength check
      const password = data.set_password.trim();
      const hasLetter = /[A-Za-z]/.test(password);
      const hasNumber = /[0-9]/.test(password);
      const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
      
      if (!hasLetter || !hasNumber) {
        warnings.push('Mật khẩu nên chứa cả chữ và số để bảo mật tốt hơn');
      }
      
      if (hasLetter && hasNumber && hasSpecial && password.length >= 8) {
        // Strong password
      } else if (hasLetter && hasNumber && password.length >= 6) {
        warnings.push('Mật khẩu khá mạnh, có thể thêm ký tự đặc biệt để bảo mật tốt hơn');
      }
    }

    const result: ValidationResult = {
      success: errors.length === 0,
      errors: errors.length > 0 ? errors : undefined,
      warnings: warnings.length > 0 ? warnings : undefined,
      fieldValidations
    };

    console.log(`${this.LOG_PREFIX}: ✅ Client validation completed`, {
      success: result.success,
      errorsCount: errors.length,
      warningsCount: warnings.length
    });

    return result;
  }

  // =============================================
  // 🚀 API COMMUNICATION METHODS
  // =============================================

  /**
   * Tạo hộ kinh doanh thông qua API endpoint (server-side)
   */
  async createBusinessWithOwner(data: BusinessRegistrationData): Promise<BusinessRegistrationResult> {
    console.log(`${this.LOG_PREFIX}: 🚀 Starting business creation through API`);

    try {
      // Client-side validation trước
      const validation = this.validateData(data);
      if (!validation.success) {
        console.log(`${this.LOG_PREFIX}: ❌ Client validation failed`);
        return {
          success: false,
          error: validation.errors?.join('; ') || 'Dữ liệu không hợp lệ',
          error_code: 'CLIENT_VALIDATION_ERROR'
        };
      }

      console.log(`${this.LOG_PREFIX}: ✅ Client validation passed, calling API`);

      // Gọi API endpoint để xử lý ở server-side
      const response = await fetch('/api/admin/create-business', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          businessName: data.business_name,
          contactMethod: data.contact_method,
          contactValue: data.contact_value,
          ownerFullName: data.owner_full_name,
          businessType: data.business_type,
          subscriptionTier: data.subscription_tier,
          businessStatus: data.business_status,
          subscriptionStatus: data.subscription_status,
          setPassword: data.set_password
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        console.error(`${this.LOG_PREFIX}: ❌ API request failed:`, errorData);
        return {
          success: false,
          error: errorData.error || `HTTP ${response.status}: ${response.statusText}`,
          error_code: 'API_ERROR'
        };
      }

      const apiResult = await response.json();
      console.log(`${this.LOG_PREFIX}: ✅ API call successful:`, apiResult);

      return apiResult.data || apiResult;

    } catch (error) {
      console.error(`${this.LOG_PREFIX}: ❌ Unexpected error:`, error);
      return {
        success: false,
        error: 'Có lỗi hệ thống xảy ra khi tạo hộ kinh doanh',
        error_code: 'SYSTEM_ERROR',
        hint: 'Vui lòng thử lại sau hoặc liên hệ hỗ trợ'
      };
    }
  }

  // =============================================
  // 🔧 UTILITY METHODS
  // =============================================

  /**
   * Get business types (client-safe)
   */
  getBusinessTypes() {
    return clientBusinessTypeService.getBusinessTypes();
  }

  /**
   * Get subscription tiers
   */
  getSubscriptionTiers() {
    return [
      { value: 'free', label: 'Gói miễn phí (3 người dùng)' },
      { value: 'basic', label: 'Gói cơ bản (10 người dùng)' },
      { value: 'premium', label: 'Gói cao cấp (50 người dùng)' }
    ];
  }
}

// Export singleton instance
export const clientBusinessRegistrationService = ClientBusinessRegistrationService.getInstance();
