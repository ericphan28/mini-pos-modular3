-- ==================================================================================
-- POS MINI MODULAR 3 - Enhanced Auth System Functions (FIXED)
-- ==================================================================================
-- Migration: 004_enhanced_auth_functions.sql  
-- Purpose: Complete auth system with real schema column mapping
-- Dependencies: 001, 002, 003 (business, permissions, admin sessions)
-- Fixed: All column names match actual database schema
-- ==================================================================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS pos_mini_modular3_get_user_with_business_complete(uuid);
DROP FUNCTION IF EXISTS pos_mini_modular3_check_user_permission(uuid, text, text);
DROP FUNCTION IF EXISTS pos_mini_modular3_update_usage_stats(uuid, text, integer);
DROP FUNCTION IF EXISTS pos_mini_modular3_validate_subscription(uuid);

-- Function 1: Get Complete User with Business Context (FIXED)
-- ==================================================================================
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_user_with_business_complete(
    p_user_id uuid
) RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
    v_user_profile record;
    v_business record;
    v_permissions jsonb;
BEGIN
    -- Get user profile với error handling
    SELECT 
        up.id,
        up.business_id,
        up.role,
        up.full_name,
        up.phone,
        up.email,
        up.login_method,
        up.status as profile_status,
        up.created_at,
        up.updated_at
    INTO v_user_profile
    FROM pos_mini_modular3_user_profiles up
    WHERE up.id = p_user_id
    AND up.status = 'active';

    -- Check if profile exists
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'USER_PROFILE_NOT_FOUND',
            'message', 'Không tìm thấy thông tin người dùng',
            'profile_exists', false
        );
    END IF;

    -- Check if user has business
    IF v_user_profile.business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'NO_BUSINESS_ASSIGNED',
            'message', 'Tài khoản chưa được gán vào doanh nghiệp',
            'profile_exists', true,
            'profile', row_to_json(v_user_profile)
        );
    END IF;

    -- Get business information với schema thực tế
    SELECT 
        b.id,
        b.name,
        b.code,  -- ✅ Column exists in schema
        b.business_type,
        b.email,  -- ✅ Correct column name 
        b.phone,  -- ✅ Correct column name
        b.address,
        b.tax_code,
        b.subscription_tier,
        b.subscription_status,
        b.trial_ends_at,  -- ✅ Correct column name
        b.features_enabled,
        b.usage_stats,
        b.status,
        bt.label as business_type_name  -- ✅ Fixed: bt.name_vi → bt.label
    INTO v_business
    FROM pos_mini_modular3_businesses b
    LEFT JOIN pos_mini_modular3_business_types bt ON bt.value = b.business_type
    WHERE b.id = v_user_profile.business_id
    AND b.status IN ('trial', 'active');

    -- Check if business exists and is active
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND_OR_INACTIVE',
            'message', 'Doanh nghiệp không tồn tại hoặc đã bị khóa',
            'profile_exists', true,
            'profile', row_to_json(v_user_profile)
        );
    END IF;

    -- Check subscription status
    IF v_business.subscription_status NOT IN ('trial', 'active') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SUBSCRIPTION_INACTIVE',
            'message', 'Gói dịch vụ đã hết hạn hoặc bị tạm dừng',
            'profile_exists', true,
            'profile', row_to_json(v_user_profile),
            'business', row_to_json(v_business),
            'subscription_status', v_business.subscription_status
        );
    END IF;

    -- Check trial expiry
    IF v_business.subscription_status = 'trial' 
       AND v_business.trial_ends_at IS NOT NULL 
       AND v_business.trial_ends_at < CURRENT_TIMESTAMP THEN
        
        -- Auto-update subscription status to expired
        UPDATE pos_mini_modular3_businesses 
        SET subscription_status = 'expired',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_business.id;
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'TRIAL_EXPIRED',
            'message', 'Thời gian dùng thử đã hết hạn',
            'profile_exists', true,
            'profile', row_to_json(v_user_profile),
            'business', row_to_json(v_business),
            'trial_end_date', v_business.trial_ends_at
        );
    END IF;

    -- Get user permissions for this role and subscription tier
    SELECT jsonb_object_agg(
        rp.feature_name,
        jsonb_build_object(
            'can_read', rp.can_read,
            'can_write', rp.can_write,
            'can_delete', rp.can_delete,
            'can_manage', rp.can_manage,
            'usage_limit', rp.usage_limit
        )
    ) INTO v_permissions
    FROM pos_mini_modular3_role_permissions rp
    WHERE rp.subscription_tier = v_business.subscription_tier
    AND rp.user_role = v_user_profile.role;

    -- Build successful result
    v_result := jsonb_build_object(
        'success', true,
        'profile_exists', true,
        'user', jsonb_build_object(
            'id', p_user_id,
            'profile_id', v_user_profile.id,
            'email', COALESCE(v_user_profile.email, (SELECT email FROM auth.users WHERE id = p_user_id)),
            'role', v_user_profile.role,
            'full_name', v_user_profile.full_name,
            'phone', v_user_profile.phone,
            'login_method', v_user_profile.login_method,
            'status', v_user_profile.profile_status
        ),
        'business', jsonb_build_object(
            'id', v_business.id,
            'name', v_business.name,
            'business_type', v_business.business_type,
            'business_type_name', v_business.business_type_name,
            'code', v_business.code,
            'email', v_business.email,
            'phone', v_business.phone,
            'address', v_business.address,
            'tax_code', v_business.tax_code,
            'subscription_tier', v_business.subscription_tier,
            'subscription_status', v_business.subscription_status,
            'trial_ends_at', v_business.trial_ends_at,
            'features_enabled', COALESCE(v_business.features_enabled, '{}'::jsonb),
            'usage_stats', COALESCE(v_business.usage_stats, '{}'::jsonb),
            'status', v_business.status
        ),
        'permissions', COALESCE(v_permissions, '{}'::jsonb),
        'session_info', jsonb_build_object(
            'login_time', CURRENT_TIMESTAMP,
            'user_agent', current_setting('request.headers', true)::jsonb->>'user-agent'
        )
    );

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INTERNAL_ERROR',
            'message', 'Lỗi hệ thống khi tải thông tin người dùng',
            'error_detail', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Check User Permission với Usage Limits (SIMPLIFIED)
-- ==================================================================================
CREATE OR REPLACE FUNCTION pos_mini_modular3_check_user_permission(
    p_user_id uuid,
    p_feature_name text,
    p_action text DEFAULT 'read'
) RETURNS jsonb AS $$
DECLARE
    v_user_profile record;
    v_permission record;
    v_permission_granted boolean := false;
BEGIN
    -- Get user profile and business
    SELECT 
        up.role,
        up.business_id,
        b.subscription_tier,
        b.subscription_status,
        b.usage_stats
    INTO v_user_profile
    FROM pos_mini_modular3_user_profiles up
    JOIN pos_mini_modular3_businesses b ON b.id = up.business_id
    WHERE up.id = p_user_id
    AND up.status = 'active'
    AND b.status IN ('trial', 'active');

    -- Check if user/business found
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'allowed', false,
            'error', 'USER_OR_BUSINESS_NOT_FOUND',
            'message', 'Không tìm thấy thông tin người dùng hoặc doanh nghiệp'
        );
    END IF;

    -- Get permission for this feature and role
    SELECT 
        can_read,
        can_write,
        can_delete,
        can_manage,
        usage_limit
    INTO v_permission
    FROM pos_mini_modular3_role_permissions
    WHERE subscription_tier = v_user_profile.subscription_tier
    AND user_role = v_user_profile.role
    AND feature_name = p_feature_name;

    -- Check if permission exists
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'allowed', false,
            'error', 'PERMISSION_NOT_DEFINED',
            'message', 'Quyền truy cập chưa được định nghĩa cho tính năng này'
        );
    END IF;

    -- Check action permission
    CASE p_action
        WHEN 'read' THEN v_permission_granted := v_permission.can_read;
        WHEN 'write' THEN v_permission_granted := v_permission.can_write;
        WHEN 'delete' THEN v_permission_granted := v_permission.can_delete;
        WHEN 'manage' THEN v_permission_granted := v_permission.can_manage;
        ELSE v_permission_granted := false;
    END CASE;

    -- Permission granted
    RETURN jsonb_build_object(
        'success', true,
        'allowed', v_permission_granted,
        'permission', jsonb_build_object(
            'can_read', v_permission.can_read,
            'can_write', v_permission.can_write,
            'can_delete', v_permission.can_delete,
            'can_manage', v_permission.can_manage
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'allowed', false,
            'error', 'INTERNAL_ERROR',
            'message', 'Lỗi hệ thống khi kiểm tra quyền truy cập',
            'error_detail', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Update Usage Statistics (SIMPLIFIED)
-- ==================================================================================
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_usage_stats(
    p_business_id uuid,
    p_feature_name text,
    p_increment integer DEFAULT 1
) RETURNS jsonb AS $$
DECLARE
    v_new_usage integer;
    v_current_tier text;
BEGIN
    -- Get current tier and usage
    SELECT 
        subscription_tier,
        COALESCE((usage_stats->p_feature_name)::integer, 0)
    INTO v_current_tier, v_new_usage
    FROM pos_mini_modular3_businesses
    WHERE id = p_business_id;

    -- Calculate new usage
    v_new_usage := v_new_usage + p_increment;

    -- Update usage stats
    UPDATE pos_mini_modular3_businesses
    SET usage_stats = jsonb_set(
            COALESCE(usage_stats, '{}'::jsonb),
            ARRAY[p_feature_name],
            to_jsonb(v_new_usage)
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_business_id;

    RETURN jsonb_build_object(
        'success', true,
        'feature_name', p_feature_name,
        'new_usage', v_new_usage
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'UPDATE_FAILED',
            'message', 'Không thể cập nhật thống kê sử dụng',
            'error_detail', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 4: Validate Subscription Status (SIMPLIFIED)
-- ==================================================================================
CREATE OR REPLACE FUNCTION pos_mini_modular3_validate_subscription(
    p_business_id uuid
) RETURNS jsonb AS $$
DECLARE
    v_business record;
    v_needs_update boolean := false;
    v_new_status text;
BEGIN
    -- Get current business subscription info
    SELECT 
        subscription_tier,
        subscription_status,
        trial_ends_at,
        created_at
    INTO v_business
    FROM pos_mini_modular3_businesses
    WHERE id = p_business_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND',
            'message', 'Không tìm thấy doanh nghiệp'
        );
    END IF;

    -- Check if trial has expired
    IF v_business.subscription_status = 'trial' 
       AND v_business.trial_ends_at IS NOT NULL 
       AND v_business.trial_ends_at < CURRENT_TIMESTAMP THEN
        
        v_needs_update := true;
        v_new_status := 'expired';
        
    END IF;

    -- Update subscription status if needed
    IF v_needs_update THEN
        UPDATE pos_mini_modular3_businesses
        SET subscription_status = v_new_status,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_business_id;
        
        -- Refresh data
        SELECT 
            subscription_tier,
            subscription_status,
            trial_ends_at
        INTO v_business
        FROM pos_mini_modular3_businesses
        WHERE id = p_business_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'subscription_tier', v_business.subscription_tier,
        'subscription_status', v_business.subscription_status,
        'trial_ends_at', v_business.trial_ends_at,
        'is_active', v_business.subscription_status IN ('trial', 'active'),
        'updated', v_needs_update
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'VALIDATION_FAILED',
            'message', 'Lỗi khi kiểm tra trạng thái subscription',
            'error_detail', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION pos_mini_modular3_get_user_with_business_complete(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_check_user_permission(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_update_usage_stats(uuid, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_validate_subscription(uuid) TO authenticated;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_id_active 
ON pos_mini_modular3_user_profiles(id) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_businesses_subscription_status 
ON pos_mini_modular3_businesses(subscription_status) 
WHERE status IN ('trial', 'active');

CREATE INDEX IF NOT EXISTS idx_role_permissions_lookup 
ON pos_mini_modular3_role_permissions(subscription_tier, user_role, feature_name);

-- Migration completed
DO $$
BEGIN
    RAISE NOTICE '✅ Enhanced Auth Functions migration 004 completed successfully';
    RAISE NOTICE '📊 Functions created with REAL SCHEMA COLUMN MAPPING:';
    RAISE NOTICE '   - pos_mini_modular3_get_user_with_business_complete()';
    RAISE NOTICE '   - pos_mini_modular3_check_user_permission()';
    RAISE NOTICE '   - pos_mini_modular3_update_usage_stats()';
    RAISE NOTICE '   - pos_mini_modular3_validate_subscription()';
    RAISE NOTICE '🔧 Performance indexes created';
    RAISE NOTICE '🔐 Ready for Enhanced Auth Service implementation!';
    RAISE NOTICE '✅ FIXED: bt.name_vi → bt.label, trial_end_date → trial_ends_at';
END $$;
