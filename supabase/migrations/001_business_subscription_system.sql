-- ==================================================================================
-- MIGRATION 001: Business Subscription System
-- ==================================================================================
-- Purpose: Add subscription management to businesses table
-- Date: 2025-07-07
-- Dependencies: pos_mini_modular3_businesses table must exist
-- ==================================================================================

-- Add subscription columns to businesses table
ALTER TABLE pos_mini_modular3_businesses 
ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_status text DEFAULT 'trial',
ADD COLUMN IF NOT EXISTS subscription_starts_at timestamptz,
ADD COLUMN IF NOT EXISTS subscription_ends_at timestamptz,
ADD COLUMN IF NOT EXISTS trial_ends_at timestamptz,
ADD COLUMN IF NOT EXISTS max_users integer DEFAULT 3,
ADD COLUMN IF NOT EXISTS max_products integer DEFAULT 50,
ADD COLUMN IF NOT EXISTS features_enabled jsonb DEFAULT '{}',
ADD COLUMN IF NOT EXISTS usage_stats jsonb DEFAULT '{}',
ADD COLUMN IF NOT EXISTS last_billing_date timestamptz,
ADD COLUMN IF NOT EXISTS next_billing_date timestamptz;

-- Add constraints (separate statements to avoid IF NOT EXISTS issues)
DO $$ 
BEGIN
    -- Check if constraint already exists before adding
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE constraint_name = 'business_subscription_tier_check'
    ) THEN
        ALTER TABLE pos_mini_modular3_businesses 
        ADD CONSTRAINT business_subscription_tier_check 
        CHECK (subscription_tier IN ('free', 'basic', 'premium'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE constraint_name = 'business_subscription_status_check'
    ) THEN
        ALTER TABLE pos_mini_modular3_businesses 
        ADD CONSTRAINT business_subscription_status_check 
        CHECK (subscription_status IN ('trial', 'active', 'suspended', 'expired', 'cancelled'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE constraint_name = 'business_max_users_positive'
    ) THEN
        ALTER TABLE pos_mini_modular3_businesses 
        ADD CONSTRAINT business_max_users_positive 
        CHECK (max_users > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE constraint_name = 'business_max_products_positive'
    ) THEN
        ALTER TABLE pos_mini_modular3_businesses 
        ADD CONSTRAINT business_max_products_positive 
        CHECK (max_products > 0);
    END IF;
END $$;

-- Update existing businesses with default subscription data
UPDATE pos_mini_modular3_businesses 
SET 
    subscription_tier = 'free',
    subscription_status = 'trial',
    subscription_starts_at = COALESCE(created_at, now()),
    trial_ends_at = COALESCE(created_at, now()) + interval '30 days',
    max_users = 3,
    max_products = 50,
    features_enabled = '{
        "products": true,
        "sales": true,
        "basic_reports": true,
        "inventory": false,
        "advanced_reports": false,
        "multi_location": false,
        "api_access": false
    }'::jsonb,
    usage_stats = '{
        "current_users": 1,
        "current_products": 0,
        "monthly_transactions": 0
    }'::jsonb,
    next_billing_date = COALESCE(created_at, now()) + interval '30 days'
WHERE subscription_tier IS NULL;

-- Create indexes for subscription queries
CREATE INDEX IF NOT EXISTS idx_businesses_subscription_status 
ON pos_mini_modular3_businesses(subscription_status);

CREATE INDEX IF NOT EXISTS idx_businesses_subscription_tier 
ON pos_mini_modular3_businesses(subscription_tier);

CREATE INDEX IF NOT EXISTS idx_businesses_trial_ends_at 
ON pos_mini_modular3_businesses(trial_ends_at) 
WHERE trial_ends_at IS NOT NULL;

-- Add comments
COMMENT ON COLUMN pos_mini_modular3_businesses.subscription_tier IS 'Business subscription plan: free, basic, premium';
COMMENT ON COLUMN pos_mini_modular3_businesses.subscription_status IS 'Current subscription status: trial, active, suspended, expired, cancelled';
COMMENT ON COLUMN pos_mini_modular3_businesses.trial_ends_at IS 'When trial period ends (30 days from creation)';
COMMENT ON COLUMN pos_mini_modular3_businesses.features_enabled IS 'JSON object containing enabled features for this business';
COMMENT ON COLUMN pos_mini_modular3_businesses.usage_stats IS 'JSON object tracking current usage against limits';

-- Migration success message
DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 001 COMPLETED: Business Subscription System';
    RAISE NOTICE '📊 Added subscription management columns to businesses table';
    RAISE NOTICE '🔒 Added subscription tier and status constraints';
    RAISE NOTICE '📈 Added usage tracking and feature management';
END $$;
