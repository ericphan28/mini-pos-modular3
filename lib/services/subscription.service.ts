import { createClient } from '@/lib/supabase/client';
import type { FeatureName, LimitType, SubscriptionPlan } from '@/lib/types/subscription.types';

export class SubscriptionService {
  private supabase = createClient();

  /**
   * Kiểm tra quyền truy cập tính năng
   */
  async checkFeatureAccess(businessId: string, feature: FeatureName): Promise<boolean> {
    try {
      const { data, error } = await this.supabase
        .rpc('pos_mini_modular3_check_feature_access', {
          p_business_id: businessId,
          p_feature_name: feature
        });

      if (error) {
        console.error('Feature access check error:', error);
        return false;
      }

      return data as boolean;
    } catch (error) {
      console.error('Feature access check failed:', error);
      return false;
    }
  }

  /**
   * Kiểm tra giới hạn sử dụng
   */
  async checkUsageLimit(
    businessId: string, 
    limitType: LimitType, 
    currentCount: number
  ): Promise<{
    allowed: boolean;
    current?: number;
    limit?: number;
    remaining?: number;
    unlimited?: boolean;
    error?: string;
  }> {
    try {
      const { data, error } = await this.supabase
        .rpc('pos_mini_modular3_check_usage_limit', {
          p_business_id: businessId,
          p_limit_type: limitType,
          p_current_count: currentCount
        });

      if (error) {
        console.error('Usage limit check error:', error);
        return { allowed: false, error: error.message };
      }

      return data;
    } catch (error) {
      console.error('Usage limit check failed:', error);
      return { allowed: false, error: 'Check failed' };
    }
  }

  /**
   * Lấy thông tin tất cả gói dịch vụ
   */
  async getSubscriptionPlans(): Promise<SubscriptionPlan[]> {
    const { data, error } = await this.supabase
      .from('pos_mini_modular3_subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('price_monthly', { ascending: true });

    if (error) {
      console.error('Get subscription plans error:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Lấy thông tin gói hiện tại của business
   */
  async getCurrentPlan(businessId: string): Promise<SubscriptionPlan | null> {
    try {
      // First get business subscription tier
      const { data: business, error: businessError } = await this.supabase
        .from('pos_mini_modular3_businesses')
        .select('subscription_tier')
        .eq('id', businessId)
        .single();

      if (businessError || !business) {
        console.error('Get business error:', businessError);
        return null;
      }

      // Then get the plan details
      const { data: plan, error: planError } = await this.supabase
        .from('pos_mini_modular3_subscription_plans')
        .select('*')
        .eq('tier', business.subscription_tier)
        .single();

      if (planError || !plan) {
        console.error('Get plan error:', planError);
        return null;
      }

      return plan as SubscriptionPlan;
    } catch (error) {
      console.error('Get current plan failed:', error);
      return null;
    }
  }
}

// Export singleton instance
export const subscriptionService = new SubscriptionService();