-- ==================================================================================
-- POS MINI MODULAR 3 - RUN ALL MIGRATIONS
-- ==================================================================================
-- Purpose: Execute all migrations in correct order
-- Usage: Copy toàn bộ script này vào Supabase SQL Editor và Run
-- Date: 2025-07-07
-- ==================================================================================

DO $$
BEGIN
    RAISE NOTICE '🚀 STARTING POS MINI MODULAR 3 MIGRATIONS...';
    RAISE NOTICE '📅 Migration Date: %', NOW();
    RAISE NOTICE '==================================================================================';
END $$;

-- ==================================================================================
-- MIGRATION 001: Business Subscription System
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

-- Add constraints
DO $$ 
BEGIN
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
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_businesses_subscription_status 
ON pos_mini_modular3_businesses(subscription_status);

CREATE INDEX IF NOT EXISTS idx_businesses_subscription_tier 
ON pos_mini_modular3_businesses(subscription_tier);

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 001 COMPLETED: Business Subscription System';
END $$;

-- ==================================================================================
-- MIGRATION 002: Role Permissions Matrix
-- ==================================================================================

-- Create role permissions table
CREATE TABLE IF NOT EXISTS pos_mini_modular3_role_permissions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_tier text NOT NULL,
    user_role text NOT NULL,
    feature_name text NOT NULL,
    can_read boolean DEFAULT false,
    can_write boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    can_manage boolean DEFAULT false,
    usage_limit integer,
    config_data jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    CONSTRAINT role_permissions_tier_check 
    CHECK (subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])),
    
    CONSTRAINT role_permissions_role_check 
    CHECK (user_role = ANY (ARRAY['business_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text, 'super_admin'::text])),
    
    UNIQUE(subscription_tier, user_role, feature_name)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_role_permissions_lookup 
ON pos_mini_modular3_role_permissions(subscription_tier, user_role, feature_name);

-- Insert default permissions
INSERT INTO pos_mini_modular3_role_permissions 
(subscription_tier, user_role, feature_name, can_read, can_write, can_delete, can_manage, usage_limit) VALUES
-- FREE TIER
('free', 'business_owner', 'products', true, true, true, true, 50),
('free', 'business_owner', 'inventory', true, true, false, true, null),
('free', 'business_owner', 'pos_interface', true, true, false, true, null),
('free', 'business_owner', 'basic_reports', true, false, false, true, null),
('free', 'business_owner', 'staff_management', true, true, true, true, 3),
('free', 'seller', 'products', true, false, false, false, null),
('free', 'seller', 'pos_interface', true, true, false, false, null),
-- BASIC TIER
('basic', 'business_owner', 'products', true, true, true, true, 500),
('basic', 'business_owner', 'inventory', true, true, true, true, null),
('basic', 'business_owner', 'reports', true, true, false, true, null),
-- PREMIUM TIER
('premium', 'business_owner', 'products', true, true, true, true, null),
('premium', 'business_owner', 'advanced_analytics', true, true, true, true, null)
ON CONFLICT (subscription_tier, user_role, feature_name) DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 002 COMPLETED: Role Permissions Matrix';
END $$;

-- ==================================================================================
-- MIGRATION 003: Admin Sessions
-- ==================================================================================

-- Create admin sessions table
CREATE TABLE IF NOT EXISTS pos_mini_modular3_admin_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    super_admin_id uuid NOT NULL,
    target_business_id uuid NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
    impersonated_role text NOT NULL DEFAULT 'business_owner',
    session_reason text,
    session_data jsonb DEFAULT '{}',
    session_start timestamp with time zone DEFAULT now(),
    session_end timestamp with time zone,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active 
ON pos_mini_modular3_admin_sessions(super_admin_id, is_active, target_business_id);

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 003 COMPLETED: Admin Sessions';
END $$;

-- ==================================================================================
-- MIGRATION 004: Enhanced Auth Functions
-- ==================================================================================

-- Function: Get user with complete business context
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_user_with_business_complete(
    p_user_id uuid
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_profile RECORD;
    business_data RECORD;
    permissions_data jsonb := '{}';
    result jsonb;
BEGIN
    -- Get user profile
    SELECT 
        up.id,
        up.business_id,
        up.full_name,
        up.email,
        up.phone,
        up.role,
        up.status,
        up.login_method,
        up.created_at
    INTO user_profile
    FROM pos_mini_modular3_user_profiles up
    WHERE up.id = p_user_id
    AND up.status = 'active';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User profile not found or inactive'
        );
    END IF;
    
    -- Get business data if exists
    IF user_profile.business_id IS NOT NULL THEN
        SELECT 
            b.id,
            b.name,
            b.code,
            b.business_type,
            b.subscription_tier,
            b.subscription_status,
            b.trial_ends_at,
            b.usage_stats
        INTO business_data
        FROM pos_mini_modular3_businesses b
        WHERE b.id = user_profile.business_id;
        
        -- Get permissions
        SELECT jsonb_object_agg(
            rp.feature_name,
            jsonb_build_object(
                'can_read', rp.can_read,
                'can_write', rp.can_write,
                'can_delete', rp.can_delete,
                'can_manage', rp.can_manage,
                'usage_limit', rp.usage_limit
            )
        ) INTO permissions_data
        FROM pos_mini_modular3_role_permissions rp
        WHERE rp.subscription_tier = business_data.subscription_tier
        AND rp.user_role = user_profile.role;
    END IF;
    
    -- Build result
    result := jsonb_build_object(
        'success', true,
        'user', jsonb_build_object(
            'id', user_profile.id,
            'business_id', user_profile.business_id,
            'full_name', user_profile.full_name,
            'email', user_profile.email,
            'role', user_profile.role,
            'status', user_profile.status
        ),
        'business', CASE 
            WHEN business_data.id IS NOT NULL THEN
                jsonb_build_object(
                    'id', business_data.id,
                    'name', business_data.name,
                    'code', business_data.code,
                    'business_type', business_data.business_type,
                    'subscription_tier', business_data.subscription_tier,
                    'subscription_status', business_data.subscription_status,
                    'trial_ends_at', business_data.trial_ends_at
                )
            ELSE NULL
        END,
        'permissions', COALESCE(permissions_data, '{}'),
        'session_info', jsonb_build_object(
            'login_time', now()
        )
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Database error: ' || SQLERRM
    );
END;
$$;

-- Function: Check user permission
CREATE OR REPLACE FUNCTION pos_mini_modular3_check_user_permission(
    p_user_id uuid,
    p_feature text,
    p_action text DEFAULT 'read'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    user_data RECORD;
    business_data RECORD;
    permission_record RECORD;
    result jsonb;
BEGIN
    -- Get user and business data
    SELECT 
        up.id,
        up.business_id,
        up.role,
        up.status,
        b.subscription_tier,
        b.subscription_status
    INTO user_data
    FROM pos_mini_modular3_user_profiles up
    LEFT JOIN pos_mini_modular3_businesses b ON b.id = up.business_id
    WHERE up.id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('allowed', false, 'error', 'User not found');
    END IF;
    
    -- Super admin has all permissions
    IF user_data.role = 'super_admin' THEN
        RETURN jsonb_build_object('allowed', true, 'reason', 'Super admin access');
    END IF;
    
    -- Check permission
    SELECT 
        rp.can_read,
        rp.can_write,
        rp.can_delete,
        rp.can_manage,
        rp.usage_limit
    INTO permission_record
    FROM pos_mini_modular3_role_permissions rp
    WHERE rp.subscription_tier = user_data.subscription_tier
    AND rp.user_role = user_data.role
    AND rp.feature_name = p_feature;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('allowed', false, 'error', 'No permission defined');
    END IF;
    
    -- Check specific action
    CASE p_action
        WHEN 'read' THEN
            IF NOT permission_record.can_read THEN
                RETURN jsonb_build_object('allowed', false, 'error', 'Read permission denied');
            END IF;
        WHEN 'write' THEN
            IF NOT permission_record.can_write THEN
                RETURN jsonb_build_object('allowed', false, 'error', 'Write permission denied');
            END IF;
        WHEN 'delete' THEN
            IF NOT permission_record.can_delete THEN
                RETURN jsonb_build_object('allowed', false, 'error', 'Delete permission denied');
            END IF;
        WHEN 'manage' THEN
            IF NOT permission_record.can_manage THEN
                RETURN jsonb_build_object('allowed', false, 'error', 'Manage permission denied');
            END IF;
    END CASE;
    
    RETURN jsonb_build_object('allowed', true, 'feature', p_feature, 'action', p_action);
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('allowed', false, 'error', 'Database error: ' || SQLERRM);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION pos_mini_modular3_get_user_with_business_complete(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_check_user_permission(uuid, text, text) TO authenticated;

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 004 COMPLETED: Enhanced Auth Functions';
END $$;

-- ==================================================================================
-- MIGRATION COMPLETED
-- ==================================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 ALL MIGRATIONS COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '📊 Enhanced Auth System is now ready for use';
    RAISE NOTICE '🔗 Test at: /test-enhanced-auth';
    RAISE NOTICE '==================================================================================';
END $$;
