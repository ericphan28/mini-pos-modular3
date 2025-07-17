import type { SubscriptionTier, SubscriptionStatus } from './database.types'

export interface SubscriptionPlan {
  id: string;
  tier: SubscriptionTier;
  name: string;
  price_monthly: number;
  max_users: number;
  max_products: number | null;
  max_warehouses: number | null;
  max_branches: number | null;
  features: string[];
  is_active: boolean;
}

export interface BusinessSubscription {
  subscription_tier: SubscriptionTier;
  subscription_status: SubscriptionStatus;
  subscription_starts_at: string;
  subscription_ends_at: string | null;
  trial_ends_at: string;
}

export type FeatureName = 
  | 'product_management'
  | 'product_categories'
  | 'basic_pos'
  | 'inventory_management'
  | 'customer_management'
  | 'supplier_management'
  | 'advanced_reports'
  | 'advanced_analytics'
  | 'multi_branch'
  | 'e_invoice'
  | 'payment_integration'
  | 'unlimited_api'
  | 'priority_support'
  | 'email_support';

export type LimitType = 'users' | 'products' | 'warehouses' | 'branches';