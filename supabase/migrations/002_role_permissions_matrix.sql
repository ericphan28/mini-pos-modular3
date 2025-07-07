-- ==================================================================================
-- MIGRATION 002: Role Permissions Matrix
-- ==================================================================================
-- Purpose: Create comprehensive role-based permission system
-- Date: 2025-07-07
-- Dependencies: 001_business_subscription_system.sql
-- ==================================================================================

-- 1. Create role permissions matrix table
CREATE TABLE IF NOT EXISTS pos_mini_modular3_role_permissions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_tier text NOT NULL,
    user_role text NOT NULL,
    feature_name text NOT NULL,
    can_read boolean DEFAULT false,
    can_write boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    can_manage boolean DEFAULT false,
    usage_limit integer, -- null = unlimited
    config_data jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    CONSTRAINT role_permissions_tier_check 
    CHECK (subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])),
    
    CONSTRAINT role_permissions_role_check 
    CHECK (user_role = ANY (ARRAY['business_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text, 'super_admin'::text])),
    
    UNIQUE(subscription_tier, user_role, feature_name)
);

-- 2. Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_role_permissions_lookup 
ON pos_mini_modular3_role_permissions(subscription_tier, user_role, feature_name);

CREATE INDEX IF NOT EXISTS idx_role_permissions_tier_role 
ON pos_mini_modular3_role_permissions(subscription_tier, user_role);

-- 3. Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER update_role_permissions_updated_at 
    BEFORE UPDATE ON pos_mini_modular3_role_permissions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Insert default permissions for ALL tiers
INSERT INTO pos_mini_modular3_role_permissions 
(subscription_tier, user_role, feature_name, can_read, can_write, can_delete, can_manage, usage_limit) VALUES

-- ==================================================================================
-- FREE TIER PERMISSIONS
-- ==================================================================================

-- FREE TIER - BUSINESS OWNER
('free', 'business_owner', 'products', true, true, true, true, 50),
('free', 'business_owner', 'inventory', true, true, false, true, null),
('free', 'business_owner', 'pos_interface', true, true, false, true, null),
('free', 'business_owner', 'basic_reports', true, false, false, true, null),
('free', 'business_owner', 'staff_management', true, true, true, true, 3),
('free', 'business_owner', 'business_settings', true, true, false, true, null),

-- FREE TIER - MANAGER
('free', 'manager', 'products', true, true, false, false, null),
('free', 'manager', 'inventory', true, true, false, false, null),
('free', 'manager', 'pos_interface', true, true, false, false, null),
('free', 'manager', 'basic_reports', true, false, false, false, null),
('free', 'manager', 'staff_management', true, false, false, false, null),

-- FREE TIER - SELLER
('free', 'seller', 'products', true, false, false, false, null),
('free', 'seller', 'inventory', true, false, false, false, null),
('free', 'seller', 'pos_interface', true, true, false, false, null),
('free', 'seller', 'basic_reports', true, false, false, false, null),

-- FREE TIER - ACCOUNTANT
('free', 'accountant', 'products', true, false, false, false, null),
('free', 'accountant', 'basic_reports', true, true, false, false, null),
('free', 'accountant', 'financial_tracking', true, true, false, false, null),

-- ==================================================================================
-- BASIC TIER PERMISSIONS
-- ==================================================================================

-- BASIC TIER - BUSINESS OWNER
('basic', 'business_owner', 'products', true, true, true, true, 500),
('basic', 'business_owner', 'inventory', true, true, true, true, null),
('basic', 'business_owner', 'pos_interface', true, true, false, true, null),
('basic', 'business_owner', 'reports', true, true, false, true, null),
('basic', 'business_owner', 'staff_management', true, true, true, true, 10),
('basic', 'business_owner', 'business_settings', true, true, true, true, null),
('basic', 'business_owner', 'integrations', true, true, false, true, 5),

-- BASIC TIER - MANAGER
('basic', 'manager', 'products', true, true, true, false, null),
('basic', 'manager', 'inventory', true, true, true, false, null),
('basic', 'manager', 'pos_interface', true, true, false, false, null),
('basic', 'manager', 'reports', true, true, false, false, null),
('basic', 'manager', 'staff_management', true, true, false, false, null),

-- BASIC TIER - SELLER
('basic', 'seller', 'products', true, true, false, false, null),
('basic', 'seller', 'inventory', true, true, false, false, null),
('basic', 'seller', 'pos_interface', true, true, false, false, null),
('basic', 'seller', 'reports', true, false, false, false, null),

-- BASIC TIER - ACCOUNTANT
('basic', 'accountant', 'products', true, false, false, false, null),
('basic', 'accountant', 'reports', true, true, false, false, null),
('basic', 'accountant', 'financial_tracking', true, true, true, false, null),

-- ==================================================================================
-- PREMIUM TIER PERMISSIONS
-- ==================================================================================

-- PREMIUM TIER - BUSINESS OWNER (Full access)
('premium', 'business_owner', 'products', true, true, true, true, null),
('premium', 'business_owner', 'inventory', true, true, true, true, null),
('premium', 'business_owner', 'pos_interface', true, true, true, true, null),
('premium', 'business_owner', 'reports', true, true, true, true, null),
('premium', 'business_owner', 'staff_management', true, true, true, true, null),
('premium', 'business_owner', 'business_settings', true, true, true, true, null),
('premium', 'business_owner', 'integrations', true, true, true, true, null),
('premium', 'business_owner', 'advanced_analytics', true, true, true, true, null),
('premium', 'business_owner', 'api_access', true, true, true, true, null),

-- PREMIUM TIER - MANAGER
('premium', 'manager', 'products', true, true, true, false, null),
('premium', 'manager', 'inventory', true, true, true, false, null),
('premium', 'manager', 'pos_interface', true, true, false, false, null),
('premium', 'manager', 'reports', true, true, false, false, null),
('premium', 'manager', 'staff_management', true, true, true, false, null),
('premium', 'manager', 'advanced_analytics', true, false, false, false, null),

-- PREMIUM TIER - SELLER
('premium', 'seller', 'products', true, true, false, false, null),
('premium', 'seller', 'inventory', true, true, false, false, null),
('premium', 'seller', 'pos_interface', true, true, false, false, null),
('premium', 'seller', 'reports', true, false, false, false, null),

-- PREMIUM TIER - ACCOUNTANT
('premium', 'accountant', 'products', true, false, false, false, null),
('premium', 'accountant', 'reports', true, true, true, false, null),
('premium', 'accountant', 'financial_tracking', true, true, true, false, null),
('premium', 'accountant', 'advanced_analytics', true, true, false, false, null),

-- ==================================================================================
-- SUPER ADMIN PERMISSIONS (All access)
-- ==================================================================================
('free', 'super_admin', 'system_management', true, true, true, true, null),
('basic', 'super_admin', 'system_management', true, true, true, true, null),
('premium', 'super_admin', 'system_management', true, true, true, true, null)

ON CONFLICT (subscription_tier, user_role, feature_name) DO NOTHING;

-- 5. Add RLS policies for security
ALTER TABLE pos_mini_modular3_role_permissions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see permissions for their subscription tier and role
CREATE POLICY "Users can view their role permissions"
ON pos_mini_modular3_role_permissions FOR SELECT
USING (
    -- Super admins can see all permissions
    EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'super_admin'
    )
    OR
    -- Regular users can see their own tier/role permissions
    EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles up
        JOIN pos_mini_modular3_businesses b ON b.id = up.business_id
        WHERE up.id = auth.uid() 
        AND b.subscription_tier = pos_mini_modular3_role_permissions.subscription_tier
        AND up.role = pos_mini_modular3_role_permissions.user_role
    )
);

-- Only super admins can modify permissions
CREATE POLICY "Only super admins can modify permissions"
ON pos_mini_modular3_role_permissions FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'super_admin'
    )
);

-- 6. Add comments for documentation
COMMENT ON TABLE pos_mini_modular3_role_permissions IS 'Role-based permission matrix for different subscription tiers';
COMMENT ON COLUMN pos_mini_modular3_role_permissions.subscription_tier IS 'Business subscription level: free, basic, premium';
COMMENT ON COLUMN pos_mini_modular3_role_permissions.user_role IS 'User role within business: business_owner, manager, seller, accountant, super_admin';
COMMENT ON COLUMN pos_mini_modular3_role_permissions.feature_name IS 'Feature or module name for permission checking';
COMMENT ON COLUMN pos_mini_modular3_role_permissions.usage_limit IS 'Maximum usage allowed (null = unlimited)';

-- Migration success message
DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 002 COMPLETED: Role Permissions Matrix';
    RAISE NOTICE '📊 Created comprehensive permission system for all tiers';
    RAISE NOTICE '🔒 Added RLS policies for security';
    RAISE NOTICE '📈 Total permissions created: %', (SELECT COUNT(*) FROM pos_mini_modular3_role_permissions);
END $$;
