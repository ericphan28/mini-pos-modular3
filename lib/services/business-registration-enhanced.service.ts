/**
 * 🚀 ENHANCED BUSINESS REGISTRATION SERVICE WITH COMPREHENSIVE LOGGING
 * 
 * @description Complete business registration with advanced logging, monitoring & type safety
 * @domain POS System - Vietnamese Business Management
 * @pattern Hybrid approach (App validation + Database business logic)
 * @features Advanced logging, session tracking, performance monitoring, dynamic validation
 * @version 2.0 - Enhanced Logging Edition
 */

import { createClient } from '@/lib/supabase/client';
import { type SupabaseClient } from '@supabase/supabase-js';
// ✅ FIX: Import the BusinessType to resolve the type error
import { BusinessTypeService, type BusinessType } from './business-type.service';
import { SupabaseRPCService } from './supabase-rpc.service';

// =============================================
// 🔥 ENHANCED TYPE DEFINITIONS WITH LOGGING
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
  validationDetails?: ValidationResult;
}

// 🆕 Enhanced Database Response Types
export interface EnhancedDBResult {
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
}

// 🆕 Enhanced Service Response
export interface EnhancedServiceResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  error_code?: string;
  hint?: string;
  metadata?: {
    duration: number;
    sessionId: string;
    timestamp: string;
    validationResults?: Record<string, unknown>;
  };
}

// 🆕 Logging Session Interface
export interface LoggingSession {
  sessionId: string;
  startTime: number;
  operation: string;
  businessName?: string;
  contactMethod?: string;
  stages: LoggingStage[];
}

export interface LoggingStage {
  stage: string;
  status: 'started' | 'completed' | 'failed';
  timestamp: number;
  duration?: number;
  data?: unknown;
  error?: string;
}

// 🆕 Validation Result Interface
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
  securityChecks?: {
    suspiciousEmail?: boolean;
    testData?: boolean;
    duplicateCheck?: boolean;
  };
}

// =============================================
// 🚀 ENHANCED BUSINESS REGISTRATION SERVICE
// =============================================

export class BusinessRegistrationEnhancedService {
  private static instance: BusinessRegistrationEnhancedService;
  private supabase: SupabaseClient;
  private rpcService = SupabaseRPCService.getInstance();
  private businessTypeService = BusinessTypeService.getInstance();
  
  private activeSessions: Map<string, LoggingSession> = new Map();
  private readonly LOG_PREFIX = '🏢 BusinessRegistration';

  constructor(supabaseClient?: SupabaseClient) {
    if (supabaseClient) {
      this.supabase = supabaseClient;
    } else {
      this.supabase = createClient();
    }
  }

  static getInstance(supabaseClient?: SupabaseClient): BusinessRegistrationEnhancedService {
    if (!BusinessRegistrationEnhancedService.instance || supabaseClient) {
      BusinessRegistrationEnhancedService.instance = new BusinessRegistrationEnhancedService(supabaseClient);
    }
    return BusinessRegistrationEnhancedService.instance;
  }

  // =============================================
  // 🔄 ENHANCED LOGGING METHODS
  // =============================================

  /**
   * 🆕 Generate unique session ID
   */
  private generateSessionId(): string {
    return `br_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 🆕 Start logging session
   */
  private startLoggingSession(operation: string, businessName?: string, contactMethod?: string): string {
    const sessionId = this.generateSessionId();
    const session: LoggingSession = {
      sessionId,
      startTime: Date.now(),
      operation,
      businessName,
      contactMethod,
      stages: []
    };

    this.activeSessions.set(sessionId, session);
    
    console.log(`${this.LOG_PREFIX}: 🚀 Starting session [${sessionId}] - ${operation}`, {
      businessName,
      contactMethod,
      timestamp: new Date().toISOString()
    });

    return sessionId;
  }

  /**
   * 🆕 Log stage in session
   */
  private logStage(sessionId: string, stage: string, status: 'started' | 'completed' | 'failed', data?: unknown, error?: string): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;

    const timestamp = Date.now();
    const lastStage = session.stages[session.stages.length - 1];
    
    const stageInfo: LoggingStage = {
      stage,
      status,
      timestamp,
      data: data ? JSON.stringify(data).substring(0, 200) : undefined,
      error
    };

    // Calculate duration if completing a stage
    if (status === 'completed' && lastStage && lastStage.stage === stage && lastStage.status === 'started') {
      stageInfo.duration = timestamp - lastStage.timestamp;
    }

    session.stages.push(stageInfo);

    const emoji = status === 'started' ? '🔄' : status === 'completed' ? '✅' : '❌';
    const durationText = stageInfo.duration ? `(${stageInfo.duration}ms)` : '';
    
    console.log(`${this.LOG_PREFIX}: ${emoji} [${sessionId}] ${stage} - ${status} ${durationText}`, {
      data: data ? (typeof data === 'string' ? data : JSON.stringify(data).substring(0, 100)) : undefined,
      error
    });
  }

  /**
   * 🆕 End logging session
   */
  private endLoggingSession(sessionId: string, success: boolean, result?: unknown): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;

    const totalDuration = Date.now() - session.startTime;
    const emoji = success ? '🎉' : '💥';
    
    console.log(`${this.LOG_PREFIX}: ${emoji} Session [${sessionId}] completed - ${success ? 'SUCCESS' : 'FAILED'} (${totalDuration}ms)`, {
      operation: session.operation,
      businessName: session.businessName,
      totalStages: session.stages.length,
      result: result ? JSON.stringify(result).substring(0, 200) : undefined
    });

    // Keep session for a short time for debugging
    setTimeout(() => {
      this.activeSessions.delete(sessionId);
    }, 60000); // Remove after 1 minute
  }

  // =============================================
  // 🔍 ENHANCED VALIDATION METHODS
  // =============================================

  /**
   * 🆕 Enhanced validation with comprehensive checks and dynamic business types
   */
  async validateDataEnhanced(data: BusinessRegistrationData, sessionId: string): Promise<ValidationResult> {
    this.logStage(sessionId, 'validation', 'started', { fields: Object.keys(data) });

    const errors: string[] = [];
    const warnings: string[] = [];
    const fieldValidations: ValidationResult['fieldValidations'] = {};
    const securityChecks: ValidationResult['securityChecks'] = {};

    try {
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
          securityChecks.testData = true;
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
            securityChecks.suspiciousEmail = true;
            fieldValidations.contact_value = { valid: false, message: 'Email không hợp lệ' };
          }

          // Check for disposable email domains
          const disposableDomains = ['10minutemail.com', 'tempmail.org', 'guerrillamail.com'];
          if (disposableDomains.includes(domain)) {
            warnings.push('Email có vẻ là email tạm thời');
            securityChecks.suspiciousEmail = true;
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

      // 🔍 Dynamic Business Type Validation
      this.logStage(sessionId, 'business_type_validation', 'started');
      
      try {
        const availableTypes = await this.businessTypeService.getBusinessTypesFromDB();
        const validTypes = availableTypes.filter(t => t.active).map(t => t.value);
        
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
        
        this.logStage(sessionId, 'business_type_validation', 'completed', { validTypes, selectedType: data.business_type });
      } catch (error) {
        this.logStage(sessionId, 'business_type_validation', 'failed', null, error instanceof Error ? error.message : 'Unknown error');
        warnings.push('Không thể xác thực loại hình kinh doanh từ database, sử dụng validation mặc định');
        
        // ✅ FIXED: Fallback to complete static validation (synced with database constraint)
        const validBusinessTypes = [
          'retail', 'wholesale', 'service', 'restaurant', 'cafe', 'food_service', 
          'beauty', 'spa', 'salon', 'healthcare', 'pharmacy', 'clinic', 'education', 
          'gym', 'fashion', 'electronics', 'automotive', 'repair', 'cleaning', 
          'construction', 'consulting', 'finance', 'real_estate', 'travel', 'hotel',
          'entertainment', 'sports', 'agriculture', 'manufacturing', 'logistics', 'other'
        ];
        
        if (!validBusinessTypes.includes(data.business_type)) {
          errors.push(`Loại hình kinh doanh không hợp lệ. Các loại hình khả dụng: ${validBusinessTypes.join(', ')}`);
          fieldValidations.business_type = { 
            valid: false, 
            message: 'Không hợp lệ',
            availableTypes: validBusinessTypes
          };
        } else {
          fieldValidations.business_type = { valid: true };
        }
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

      // 🔍 Duplicate Contact Check
      if (fieldValidations.contact_value?.valid && data.contact_value?.trim()) {
        this.logStage(sessionId, 'duplicate_check', 'started');
        
        try {
          const isDuplicate = await this.checkContactExists(data.contact_method, data.contact_value.trim());
          
          if (isDuplicate) {
            errors.push(`${data.contact_method === 'email' ? 'Email' : 'Số điện thoại'} này đã được sử dụng`);
            securityChecks.duplicateCheck = true;
          }
          
          this.logStage(sessionId, 'duplicate_check', 'completed', { isDuplicate });
        } catch (error) {
          this.logStage(sessionId, 'duplicate_check', 'failed', null, error instanceof Error ? error.message : 'Unknown error');
          warnings.push('Không thể kiểm tra trùng lặp thông tin liên lạc');
        }
      }

      const result: ValidationResult = {
        success: errors.length === 0,
        errors: errors.length > 0 ? errors : undefined,
        warnings: warnings.length > 0 ? warnings : undefined,
        fieldValidations,
        securityChecks
      };

      this.logStage(sessionId, 'validation', 'completed', { 
        errorsCount: errors.length, 
        warningsCount: warnings.length,
        success: result.success 
      });

      return result;

    } catch (error) {
      this.logStage(sessionId, 'validation', 'failed', null, error instanceof Error ? error.message : 'Unknown error');
      
      return {
        success: false,
        errors: ['Có lỗi xảy ra khi validate dữ liệu'],
        fieldValidations,
        securityChecks
      };
    }
  }

  // =============================================
  // 🚀 ENHANCED BUSINESS CREATION METHOD
  // =============================================

  /**
   * 🆕 Enhanced business creation with comprehensive logging and monitoring
   * ✅ FIXED: Now calls API for frontend usage with better error handling
   */
  async createBusinessWithOwnerEnhanced(data: BusinessRegistrationData): Promise<BusinessRegistrationResult> {
    const sessionId = this.startLoggingSession('createBusinessWithOwnerEnhanced', data.business_name, data.contact_method);
    
    try {
      // Check if running in browser environment
      if (typeof window !== 'undefined') {
        // Browser environment - call API
        this.logStage(sessionId, 'environment_detection', 'completed', { environment: 'browser' });
        console.log(`${this.LOG_PREFIX}: 🌐 Browser environment detected, calling API`);
        
        try {
          this.logStage(sessionId, 'api_call_preparation', 'started');
          const payload = {
            businessName: data.business_name,
            contactMethod: data.contact_method,
            contactValue: data.contact_value,
            ownerFullName: data.owner_full_name,
            businessType: data.business_type,
            subscriptionTier: data.subscription_tier,
            businessStatus: data.business_status,
            subscriptionStatus: data.subscription_status,
            setPassword: data.set_password
          };
          this.logStage(sessionId, 'api_call_preparation', 'completed', { payload });

          // Call API with proper error handling
          this.logStage(sessionId, 'api_call', 'started');
          const response = await fetch('/api/admin/create-business', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload)
          });
          const result = await response.json();
          this.logStage(sessionId, 'api_call', 'completed', { 
            status: response.status,
            success: result.success 
          });
          
          if (!response.ok || !result.success) {
            this.logStage(sessionId, 'api_error_handling', 'completed', { 
              status: response.status,
              error: result.error 
            });
            this.endLoggingSession(sessionId, false, result);
            
            return {
              success: false,
              error: result.error || 'API call failed',
              error_code: result.error_code || 'API_ERROR'
            };
          }

          this.endLoggingSession(sessionId, true, result.data);
          return {
            success: true,
            ...result.data
          };
        } catch (error) {
          this.logStage(sessionId, 'api_call', 'failed', { 
            error: error instanceof Error ? error.message : 'Unknown error'
          });
          this.endLoggingSession(sessionId, false, { error });
          
          return {
            success: false,
            error: error instanceof Error ? error.message : 'Lỗi kết nối API',
            error_code: 'API_CONNECTION_ERROR'
          };
        }
      } else {
        // Server environment - call database directly
        this.logStage(sessionId, 'Environment Check', 'completed', { environment: 'server' });
        return await this.createBusinessWithOwnerSimple(data, sessionId);
      }
    } catch (error) {
      this.endLoggingSession(sessionId, false, { error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * 🆕 Simple business creation for server-side usage
   * ✅ FIXED: Use correct database function
   */
  async createBusinessWithOwnerSimple(data: BusinessRegistrationData, sessionId: string): Promise<BusinessRegistrationResult> {
    try {
      this.logStage(sessionId, 'Validation', 'started');
      const validation = await this.validateDataEnhanced(data, sessionId);
      if (!validation.success) {
        this.logStage(sessionId, 'Validation', 'failed', validation);
        const errorResult = {
          success: false,
          error: validation.errors?.join('; ') || 'Dữ liệu không hợp lệ',
          error_code: 'VALIDATION_ERROR',
          validationDetails: validation
        };
        this.endLoggingSession(sessionId, false, errorResult);
        return errorResult;
      }
      this.logStage(sessionId, 'Validation', 'completed', validation);

      // 🔒 SECURITY: Sanitize inputs to prevent injection
      this.logStage(sessionId, 'sanitization', 'started');
      const sanitizedData = {
        business_name: data.business_name.trim().replace(/[<>\"']/g, ''),
        contact_method: data.contact_method,
        contact_value: data.contact_value.trim().replace(/[<>\"']/g, ''),
        owner_full_name: data.owner_full_name.trim().replace(/[<>\"']/g, ''),
        business_type: data.business_type,
        subscription_tier: data.subscription_tier,
        business_status: data.business_status,
        subscription_status: data.subscription_status,
        set_password: data.set_password
      };
      this.logStage(sessionId, 'sanitization', 'completed');

      console.log(`${this.LOG_PREFIX}: 🔒 Data sanitized, calling database function`);

      // 🆕 TRANSACTION: Begin transaction for atomicity
      this.logStage(sessionId, 'database_transaction', 'started');
      
      // ✅ FIX: Use correct database function name with transaction support
      this.logStage(sessionId, 'Database Call', 'started', { function: 'pos_mini_modular3_super_admin_create_business_enhanced' });
      const { data: dbData, error: dbError } = await this.supabase.rpc('pos_mini_modular3_super_admin_create_business_enhanced', {
        p_business_name: sanitizedData.business_name,
        p_contact_method: sanitizedData.contact_method,
        p_contact_value: sanitizedData.contact_value,
        p_owner_full_name: sanitizedData.owner_full_name,
        p_business_type: sanitizedData.business_type,
        p_subscription_tier: sanitizedData.subscription_tier,
        p_set_password: sanitizedData.set_password,
        p_is_active: sanitizedData.business_status === 'active'
      });

      if (dbError) {
        this.logStage(sessionId, 'Database Call', 'failed', dbError);
        // 🔧 IMPROVED: Better error categorization
        let userFriendlyError = 'Có lỗi xảy ra khi tạo hộ kinh doanh';
        let errorCode = 'DATABASE_ERROR';
        
        if (dbError.message?.includes('duplicate') || dbError.message?.includes('already exists')) {
          userFriendlyError = 'Email hoặc tên hộ kinh doanh đã tồn tại trong hệ thống';
          errorCode = 'DUPLICATE_ERROR';
        } else if (dbError.message?.includes('permission') || dbError.message?.includes('access')) {
          userFriendlyError = 'Bạn không có quyền thực hiện thao tác này';
          errorCode = 'PERMISSION_ERROR';
        } else if (dbError.message?.includes('function') && dbError.message?.includes('does not exist')) {
          userFriendlyError = 'Chức năng chưa được cài đặt trong hệ thống';
          errorCode = 'FUNCTION_NOT_FOUND';
        }
        
        this.endLoggingSession(sessionId, false, { error: userFriendlyError });
        
        return {
          success: false,
          error: userFriendlyError,
          error_code: errorCode,
          hint: 'Kiểm tra kết nối database và permissions'
        };
      }

      // Cũng cần kiểm tra nếu dbData báo lỗi
      if (dbData && typeof dbData === 'object' && 'error' in dbData && !dbData.success) {
        this.logStage(sessionId, 'Database Call', 'failed', dbData);
        const errorMsg = dbData.error || 'Lỗi không xác định từ database';
        
        this.endLoggingSession(sessionId, false, { error: errorMsg });
        
        return {
          success: false,
          error: errorMsg,
          error_code: 'DATABASE_LOGIC_ERROR',
          hint: 'Lỗi xử lý trong database function'
        };
      }

      this.logStage(sessionId, 'Database Call', 'completed', dbData);
      const result = dbData as EnhancedDBResult;
      this.logStage(sessionId, 'result_mapping', 'started');
      console.log(`${this.LOG_PREFIX}: ✅ Database call successful:`, result);

      // Map database response to service response
      const mappedResult: BusinessRegistrationResult = {
        success: true,
        business_id: result.business_id,
        business_name: result.business_name,
        business_code: result.business_code,
        business_status: result.business_status,
        subscription_tier: result.subscription_tier,
        subscription_status: result.subscription_status,
        user_created: !!result.user_created,
        user_id: result.user_id,
        max_users: result.max_users,
        max_products: result.max_products,
        contact_method: result.contact_method,
        contact_value: result.contact_value,
        owner_name: result.owner_name,
        trial_ends_at: result.trial_ends_at,
        message: result.message
      };
      this.logStage(sessionId, 'result_mapping', 'completed');

      this.endLoggingSession(sessionId, true, mappedResult);
      console.log(`${this.LOG_PREFIX}: ✅ Business creation completed successfully`);
      return mappedResult;

    } catch (error) {
      this.logStage(sessionId, 'Exception', 'failed', error);
      this.endLoggingSession(sessionId, false, { error: error instanceof Error ? error.message : 'Unknown error' });
      console.error(`${this.LOG_PREFIX}: ❌ Unexpected error:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Lỗi không xác định',
        error_code: 'UNEXPECTED_ERROR'
      };
    }
  }

  // =============================================
  //  ENHANCED UTILITY METHODS
  // =============================================

  /**
   * Check if email/phone already exists with enhanced logging
   */
  async checkContactExists(contactMethod: 'email' | 'phone', contactValue: string): Promise<boolean> {
    try {
      const { data: result, error } = await this.supabase.rpc(
        'pos_mini_modular3_check_contact_exists',
        {
          p_contact_method: contactMethod,
          p_contact_value: contactValue.trim()
        }
      );
      
      if (error) {
        console.error(`${this.LOG_PREFIX}: Error checking contact exists:`, error);
        return false;
      }
      
      return result === true;
    } catch (error) {
      console.error(`${this.LOG_PREFIX}: Error checking contact exists:`, error);
      return false;
    }
  }

  /**
   * 🆕 Get business types dynamically from database
   */
  async getBusinessTypesEnhanced(): Promise<BusinessType[]> {
    try {
      return await this.businessTypeService.getBusinessTypesFromDB();
    } catch (error) {
      console.error(`${this.LOG_PREFIX}: Error fetching business types:`, error);
      return this.getBusinessTypesStatic();
    }
  }

  /**
   * Get business types (static fallback)
   */
  getBusinessTypesStatic(): BusinessType[] {
    return [
      { value: 'retail', label: 'Bán lẻ', active: true },
      { value: 'restaurant', label: 'Nhà hàng / Quán ăn', active: true },
      { value: 'service', label: 'Dịch vụ', active: true },
      { value: 'wholesale', label: 'Bán sỉ', active: true }
    ];
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

  /**
   * 🆕 Get session info for debugging
   */
  getSessionInfo(sessionId: string): LoggingSession | null {
    return this.activeSessions.get(sessionId) || null;
  }

  /**
   * 🆕 Get all active sessions (for monitoring)
   */
  getActiveSessions(): LoggingSession[] {
    return Array.from(this.activeSessions.values());
  }

  /**
   * 🆕 Clear old sessions
   */
  clearOldSessions(): void {
    const now = Date.now();
    const maxAge = 300000; // 5 minutes
    
    for (const [sessionId, session] of this.activeSessions.entries()) {
      if (now - session.startTime > maxAge) {
        this.activeSessions.delete(sessionId);
      }
    }
  }

  // =============================================
  // 🔧 UTILITY METHODS
  // =============================================

  /**
   * Map business type từ client format sang database format
   */
  private mapBusinessType(businessType: string): string {
    const typeMapping: Record<string, string> = {
      'retail': 'ban_le',
      'restaurant': 'nha_hang',
      'cafe': 'cafe_tra_sua', 
      'service': 'dich_vu',
      'wholesale': 'ban_si',
      'online': 'ban_online',
      'other': 'khac'
    };

    const mapped = typeMapping[businessType] || businessType;
    console.log(`🔧 Business type mapping: ${businessType} -> ${mapped}`);
    return mapped;
  }

}

// Export singleton instance
export const businessRegistrationEnhancedService = BusinessRegistrationEnhancedService.getInstance();

// Backward compatibility export
export const businessRegistrationService = businessRegistrationEnhancedService;
