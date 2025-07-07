// ==================================================================================
// POS Mini Modular 3 - Enhanced Auth Service
// ==================================================================================
// Purpose: Complete auth system với real permission checking và business context
// Dependencies: Enhanced auth functions từ migration 004
// ==================================================================================

import { createClient } from '@/lib/supabase/client';

// ==================================================================================
// TYPE DEFINITIONS
// ==================================================================================

export interface PermissionResult {
  readonly success: boolean;
  readonly allowed: boolean;
  readonly error?: string;
  readonly message?: string;
  readonly permission?: {
    readonly can_read: boolean;
    readonly can_write: boolean;
    readonly can_delete: boolean;
    readonly can_manage: boolean;
  };
  readonly usage_info?: {
    readonly current_usage: number;
    readonly usage_limit: number | null;
    readonly usage_remaining: number | null;
  };
}

export interface UsageUpdateResult {
  readonly success: boolean;
  readonly feature_name: string;
  readonly new_usage: number;
  readonly usage_limit: number | null;
  readonly limit_exceeded: boolean;
  readonly error?: string;
  readonly message?: string;
}

export interface SubscriptionValidation {
  readonly success: boolean;
  readonly subscription_tier: 'free' | 'basic' | 'premium';
  readonly subscription_status: 'trial' | 'active' | 'suspended' | 'expired' | 'cancelled';
  readonly trial_end_date: string | null;
  readonly is_active: boolean;
  readonly days_remaining: number | null;
  readonly updated: boolean;
  readonly error?: string;
  readonly message?: string;
}

export interface EnhancedBusinessUser {
  readonly id: string;
  readonly profile_id: string;
  readonly email: string;
  readonly role: 'super_admin' | 'business_owner' | 'manager' | 'seller' | 'accountant';
  readonly full_name: string | null;
  readonly phone: string | null;
  readonly login_method: 'email' | 'phone';
  readonly status: string;
}

export interface BusinessContext {
  readonly id: string;
  readonly name: string;
  readonly business_type: string;
  readonly business_type_name: string;
  readonly business_code: string;
  readonly contact_email: string | null;
  readonly contact_phone: string | null;
  readonly address: string | null;
  readonly subscription_tier: 'free' | 'basic' | 'premium';
  readonly subscription_status: 'trial' | 'active' | 'suspended' | 'expired' | 'cancelled';
  readonly trial_end_date: string | null;
  readonly features_enabled: Record<string, boolean>;
  readonly usage_stats: Record<string, number>;
  readonly status: string;
}

export interface UserPermissions {
  readonly [feature: string]: {
    readonly can_read: boolean;
    readonly can_write: boolean;
    readonly can_delete: boolean;
    readonly can_manage: boolean;
    readonly usage_limit?: number;
  };
}

export interface CompleteUserSession {
  readonly success: boolean;
  readonly profile_exists: boolean;
  readonly user: EnhancedBusinessUser;
  readonly business: BusinessContext;
  readonly permissions: UserPermissions;
  readonly session_info: {
    readonly login_time: string;
    readonly user_agent?: string;
  };
  readonly error?: string;
  readonly message?: string;
}

// Legacy interface for backward compatibility
export interface BusinessUser {
  readonly id: string;
  readonly email: string;
  readonly role: string;
  readonly business?: {
    readonly id: string;
    readonly name: string;
    readonly business_type: string;
  };
}

// ==================================================================================
// ENHANCED AUTH SERVICE IMPLEMENTATION
// ==================================================================================

class EnhancedBusinessAuthServiceImpl {
  private static instance: EnhancedBusinessAuthServiceImpl;
  private userCache: Map<string, { data: CompleteUserSession; timestamp: number }> = new Map();
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  static getInstance(): EnhancedBusinessAuthServiceImpl {
    if (!EnhancedBusinessAuthServiceImpl.instance) {
      EnhancedBusinessAuthServiceImpl.instance = new EnhancedBusinessAuthServiceImpl();
    }
    return EnhancedBusinessAuthServiceImpl.instance;
  }

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * Get complete user with business context và cached permissions
   */
  async getCurrentUserWithBusiness(): Promise<CompleteUserSession | null> {
    try {
      const supabase = createClient();
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user) {
        return null;
      }

      // Check cache first
      const cached = this.userCache.get(user.id);
      if (cached && (Date.now() - cached.timestamp) < this.CACHE_TTL) {
        return cached.data;
      }

      // Call enhanced database function với correct user ID
      const { data, error: rpcError } = await supabase.rpc(
        'pos_mini_modular3_get_user_with_business_complete',
        { p_user_id: user.id } // Use auth.users.id directly
      ) as { data: CompleteUserSession | null; error: unknown };

      if (rpcError) {
        console.error('Error getting user with business:', rpcError);
        return null;
      }

      if (!data || !data.success) {
        // Handle specific error cases
        if (data?.error === 'USER_PROFILE_NOT_FOUND') {
          return {
            success: false,
            profile_exists: false,
            error: 'USER_PROFILE_NOT_FOUND',
            message: data.message || 'Không tìm thấy thông tin người dùng'
          } as CompleteUserSession;
        }
        
        return data;
      }

      // Cache successful result
      this.userCache.set(user.id, {
        data,
        timestamp: Date.now()
      });

      return data;

    } catch (error: unknown) {
      console.error('Error in getCurrentUserWithBusiness:', error);
      return null;
    }
  }

  /**
   * Check specific permission với usage limits
   */
  async hasPermission(
    feature: string, 
    action: 'read' | 'write' | 'delete' | 'manage' = 'read'
  ): Promise<PermissionResult> {
    try {
      const supabase = createClient();
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user) {
        return {
          success: false,
          allowed: false,
          error: 'USER_NOT_AUTHENTICATED',
          message: 'Người dùng chưa đăng nhập'
        };
      }

      // Call permission check function với correct user ID
      const { data, error: rpcError } = await supabase.rpc(
        'pos_mini_modular3_check_user_permission',
        { 
          p_user_id: user.id, // Use auth.users.id directly
          p_feature_name: feature,
          p_action: action
        }
      ) as { data: PermissionResult | null; error: unknown };

      if (rpcError) {
        console.error('Error checking permission:', rpcError);
        return {
          success: false,
          allowed: false,
          error: 'PERMISSION_CHECK_FAILED',
          message: 'Lỗi khi kiểm tra quyền truy cập'
        };
      }

      return data || {
        success: false,
        allowed: false,
        error: 'NO_RESULT',
        message: 'Không có kết quả kiểm tra quyền'
      };

    } catch (error: unknown) {
      console.error('Error in hasPermission:', error);
      return {
        success: false,
        allowed: false,
        error: 'INTERNAL_ERROR',
        message: 'Lỗi hệ thống khi kiểm tra quyền'
      };
    }
  }

  /**
   * Update usage statistics cho feature
   */
  async updateUsageStats(
    businessId: string,
    feature: string,
    increment = 1
  ): Promise<UsageUpdateResult> {
    try {
      const supabase = createClient();
      
      const { data, error: rpcError } = await supabase.rpc(
        'pos_mini_modular3_update_usage_stats',
        { 
          p_business_id: businessId,
          p_feature_name: feature,
          p_increment: increment
        }
      ) as { data: UsageUpdateResult | null; error: unknown };

      if (rpcError) {
        console.error('Error updating usage stats:', rpcError);
        return {
          success: false,
          feature_name: feature,
          new_usage: 0,
          usage_limit: null,
          limit_exceeded: false,
          error: 'UPDATE_FAILED',
          message: 'Không thể cập nhật thống kê sử dụng'
        };
      }

      // Clear user cache after usage update
      this.clearUserCache();

      return data || {
        success: false,
        feature_name: feature,
        new_usage: 0,
        usage_limit: null,
        limit_exceeded: false,
        error: 'NO_RESULT',
        message: 'Không có kết quả cập nhật'
      };

    } catch (error: unknown) {
      console.error('Error in updateUsageStats:', error);
      return {
        success: false,
        feature_name: feature,
        new_usage: 0,
        usage_limit: null,
        limit_exceeded: false,
        error: 'INTERNAL_ERROR',
        message: 'Lỗi hệ thống khi cập nhật thống kê'
      };
    }
  }

  /**
   * Validate subscription status
   */
  async validateSubscription(businessId: string): Promise<SubscriptionValidation> {
    try {
      const supabase = createClient();
      
      const { data, error: rpcError } = await supabase.rpc(
        'pos_mini_modular3_validate_subscription',
        { p_business_id: businessId }
      ) as { data: SubscriptionValidation | null; error: unknown };

      if (rpcError) {
        console.error('Error validating subscription:', rpcError);
        return {
          success: false,
          subscription_tier: 'free',
          subscription_status: 'expired',
          trial_end_date: null,
          is_active: false,
          days_remaining: null,
          updated: false,
          error: 'VALIDATION_FAILED',
          message: 'Lỗi khi kiểm tra trạng thái subscription'
        };
      }

      return data || {
        success: false,
        subscription_tier: 'free',
        subscription_status: 'expired',
        trial_end_date: null,
        is_active: false,
        days_remaining: null,
        updated: false,
        error: 'NO_RESULT',
        message: 'Không có kết quả validation'
      };

    } catch (error: unknown) {
      console.error('Error in validateSubscription:', error);
      return {
        success: false,
        subscription_tier: 'free',
        subscription_status: 'expired',
        trial_end_date: null,
        is_active: false,
        days_remaining: null,
        updated: false,
        error: 'INTERNAL_ERROR',
        message: 'Lỗi hệ thống khi validate subscription'
      };
    }
  }

  /**
   * Legacy method for backward compatibility
   */
  async getCurrentUserWithBusinessLegacy(): Promise<BusinessUser | null> {
    const completeUser = await this.getCurrentUserWithBusiness();
    
    if (!completeUser || !completeUser.success) {
      return null;
    }

    return {
      id: completeUser.user.id,
      email: completeUser.user.email,
      role: completeUser.user.role,
      business: {
        id: completeUser.business.id,
        name: completeUser.business.name,
        business_type: completeUser.business.business_type
      }
    };
  }

  /**
   * Clear user cache (call sau khi update data)
   */
  clearUserCache(): void {
    this.userCache.clear();
  }

  /**
   * Clear cache for specific user
   */
  clearUserCacheForUser(userId: string): void {
    this.userCache.delete(userId);
  }

  /**
   * Get cached user session without database call
   */
  getCachedUserSession(userId: string): CompleteUserSession | null {
    const cached = this.userCache.get(userId);
    if (cached && (Date.now() - cached.timestamp) < this.CACHE_TTL) {
      return cached.data;
    }
    return null;
  }
}

// ==================================================================================
// EXPORT INSTANCES
// ==================================================================================

// Enhanced service instance
export const EnhancedBusinessAuthService = EnhancedBusinessAuthServiceImpl.getInstance();

// Legacy service for backward compatibility
export const BusinessAuthService = {
  async getCurrentUserWithBusiness(): Promise<BusinessUser | null> {
    return EnhancedBusinessAuthService.getCurrentUserWithBusinessLegacy();
  },
  
  async hasPermission(feature: string, action?: string): Promise<boolean> {
    const result = await EnhancedBusinessAuthService.hasPermission(
      feature, 
      (action as 'read' | 'write' | 'delete' | 'manage') || 'read'
    );
    return result.allowed;
  }
};

// Default export
export default EnhancedBusinessAuthService;
