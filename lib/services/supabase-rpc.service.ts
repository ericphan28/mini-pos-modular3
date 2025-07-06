/**
 * 🤖 COPILOT CONTEXT: Type-safe Supabase Client Service
 * 
 * @description Unified service for all Supabase operations
 * @pattern Factory pattern with type safety
 * @security Context-aware client selection
 */

import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/client';
import type {
  AppError,
  DatabaseError,
  DatabaseFunctionName,
  DatabaseFunctionParams,
  DatabaseFunctionResult,
  ServiceResponse
} from '@/lib/types/database-schema.types';

// =============================================
// TYPE-SAFE RPC WRAPPER
// =============================================

export class SupabaseRPCService {
  private static instance: SupabaseRPCService;

  static getInstance(): SupabaseRPCService {
    if (!this.instance) {
      this.instance = new SupabaseRPCService();
    }
    return this.instance;
  }

  /**
   * 🤖 COPILOT: Type-safe RPC call with automatic client selection
   * 
   * @param functionName Database function name (auto-complete available)
   * @param params Function parameters (type-checked)
   * @param clientType Which client to use (browser/server/admin)
   * @returns Promise with typed result
   */
  async callFunction<T extends DatabaseFunctionName>(
    functionName: T,
    params: DatabaseFunctionParams<T>,
    clientType: 'browser' | 'server' | 'admin' = 'browser'
  ): Promise<ServiceResponse<DatabaseFunctionResult<T>>> {
    try {
      console.log(`🔵 RPC Call [${clientType}]: ${functionName}`, params);

      // Select appropriate client
      const client = this.getClient(clientType);
      
      // Execute RPC call with proper typing
      const { data, error } = await client.rpc(
        functionName as string, 
        params as Record<string, unknown>
      );

      if (error) {
        console.error(`🔴 RPC Error [${functionName}]:`, error);
        return {
          success: false,
          error: error.message,
          appError: this.parseError(error)
        };
      }

      console.log(`✅ RPC Success [${functionName}]:`, data);
      return {
        success: true,
        data: data as DatabaseFunctionResult<T>
      };

    } catch (error) {
      console.error(`🔴 RPC Exception [${functionName}]:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        appError: this.parseError(error)
      };
    }
  }

  /**
   * 🤖 COPILOT: Get appropriate Supabase client based on context
   */
  private getClient(type: 'browser' | 'server' | 'admin') {
    switch (type) {
      case 'browser':
        return createClient();
      case 'server':
        // For server client, we'll use browser client for now
        // TODO: Implement proper server client when needed
        return createClient();
      case 'admin':
        return createAdminClient();
      default:
        throw new Error(`Unknown client type: ${type}`);
    }
  }

  /**
   * 🤖 COPILOT: Parse database errors into user-friendly messages
   */
  private parseError(error: unknown): AppError {
    const message = this.extractErrorMessage(error);
    
    // Common database error patterns
    const errorPatterns: Record<string, AppError> = {
      'function does not exist': {
        code: 'FUNCTION_NOT_FOUND',
        userMessage: 'Chức năng chưa được cài đặt',
        technicalMessage: message,
        severity: 'high'
      },
      'permission denied': {
        code: 'PERMISSION_DENIED',
        userMessage: 'Bạn không có quyền thực hiện thao tác này',
        technicalMessage: message,
        severity: 'medium'
      },
      'duplicate key value': {
        code: 'DUPLICATE_KEY',
        userMessage: 'Thông tin đã tồn tại trong hệ thống',
        technicalMessage: message,
        severity: 'low'
      },
      'connection': {
        code: 'CONNECTION_ERROR',
        userMessage: 'Lỗi kết nối database',
        technicalMessage: message,
        severity: 'critical'
      },
      'violates check constraint': {
        code: 'CONSTRAINT_VIOLATION',
        userMessage: 'Dữ liệu không đúng định dạng yêu cầu',
        technicalMessage: message,
        severity: 'medium'
      }
    };

    // Find matching pattern
    for (const [pattern, appError] of Object.entries(errorPatterns)) {
      if (message.toLowerCase().includes(pattern.toLowerCase())) {
        return appError;
      }
    }

    // Default error
    return {
      code: 'UNKNOWN_ERROR',
      userMessage: 'Có lỗi xảy ra, vui lòng thử lại',
      technicalMessage: message,
      severity: 'medium'
    };
  }

  /**
   * Extract error message from various error types
   */
  private extractErrorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    
    if (typeof error === 'string') {
      return error;
    }
    
    if (error && typeof error === 'object' && 'message' in error) {
      return String((error as { message: unknown }).message);
    }
    
    return 'Unknown error';
  }

  /**
   * 🤖 COPILOT: Check if function exists before calling
   */
  async functionExists(functionName: string): Promise<boolean> {
    try {
      // Try to get function metadata from information_schema
      const client = this.getClient('admin');
      const { data, error } = await client
        .from('information_schema.routines')
        .select('routine_name')
        .eq('routine_schema', 'public')
        .eq('routine_name', functionName)
        .limit(1);

      return !error && data && data.length > 0;
    } catch {
      return false;
    }
  }

  /**
   * 🤖 COPILOT: Get available functions for debugging
   */
  async getAvailableFunctions(): Promise<string[]> {
    try {
      const client = this.getClient('admin');
      const { data, error } = await client
        .from('information_schema.routines')
        .select('routine_name')
        .eq('routine_schema', 'public')
        .like('routine_name', 'pos_mini_modular3_%');

      if (error || !data) {
        return [];
      }

      return data.map(row => row.routine_name);
    } catch {
      return [];
    }
  }
}

// =============================================
// SPECIALIZED SERVICES
// =============================================

/**
 * 🤖 COPILOT: Super Admin specific operations
 */
export class SuperAdminService {
  private static instance: SuperAdminService;
  private rpc = SupabaseRPCService.getInstance();

  // ✅ ADD: getInstance method
  static getInstance() {
    if (!this.instance) {
      this.instance = new SuperAdminService();
    }
    return this.instance;
  }

  /**
   * Check if current user has super admin permission
   */
  async checkPermission() {
    const result = await this.rpc.callFunction(
      'pos_mini_modular3_super_admin_check_permission',
      {},
      'browser'
    );
    return result.success && result.data === true;
  }

  /**
   * Get business registration statistics
   */
  async getBusinessStats() {
    return await this.rpc.callFunction(
      'pos_mini_modular3_super_admin_get_business_registration_stats',
      {},
      'admin'
    );
  }

  /**
   * Create business with complete owner account (UPDATED - using correct function)
   */
  async createBusinessWithOwner(params: {
    p_business_name: string;
    p_contact_method: string;
    p_contact_value: string;
    p_owner_full_name: string;
    p_business_type?: string;
    p_subscription_tier?: string;
    p_set_password?: string | null;
    p_is_active?: boolean;
  }) {
    return await this.rpc.callFunction(
      'pos_mini_modular3_super_admin_create_complete_business',
      params,
      'admin'
    );
  }

  /**
   * Create business with simple auth (alternative method)
   */
  async createBusinessWithAuth(params: DatabaseFunctionParams<'pos_mini_modular3_create_business_with_auth_simple'>) {
    return await this.rpc.callFunction(
      'pos_mini_modular3_create_business_with_auth_simple',
      params,
      'admin'
    );
  }

  /**
   * ✅ ENHANCED: Create business with enhanced function
   */
  async createBusinessEnhanced(params: {
    p_business_name: string;
    p_contact_method: string;
    p_contact_value: string;
    p_owner_full_name: string;
    p_business_type?: string;
    p_subscription_tier?: string;
    p_set_password?: string | null;
    p_is_active?: boolean;
  }) {
    return await this.rpc.callFunction(
      'pos_mini_modular3_super_admin_create_complete_business',
      params,
      'admin'
    );
  }
}

/**
 * 🤖 COPILOT: Business operations service
 */
export class BusinessService {
  private static instance: BusinessService;
  private rpc = SupabaseRPCService.getInstance();

  // ✅ ADD: getInstance method
  static getInstance(): BusinessService {
    if (!this.instance) {
      this.instance = new BusinessService();
    }
    return this.instance;
  }

  /**
   * Generate unique business code
   */
  async generateCode(): Promise<string> {
    const result = await this.rpc.callFunction(
      'generate_business_code',
      {},
      'admin'
    );
    
    if (result.success && result.data) {
      return result.data;
    }
    
    // Fallback: generate client-side
    const timestamp = Date.now().toString().slice(-5);
    return `GKS${timestamp}`;
  }

  /**
   * Get default business settings
   */
  async getDefaultSettings(businessType: string, subscriptionTier: string) {
    return await this.rpc.callFunction(
      'get_default_business_settings',
      {
        p_business_type: businessType as DatabaseFunctionParams<'get_default_business_settings'>['p_business_type'],
        p_subscription_tier: subscriptionTier as DatabaseFunctionParams<'get_default_business_settings'>['p_subscription_tier']
      },
      'admin'
    );
  }
}

// =============================================
// EXPORTS
// =============================================

// Export singleton instances
export const supabaseRPC = SupabaseRPCService.getInstance();
export const superAdminService = SuperAdminService.getInstance();
export const businessService = BusinessService.getInstance();

// Export types for external usage
export type { AppError, DatabaseError, ServiceResponse };

// Re-export for convenience
    export {
    type DatabaseFunctionName,
    type DatabaseFunctionParams,
    type DatabaseFunctionResult
  } from '@/lib/types/database-schema.types';

