-- ==================================================================================
-- MIGRATION 003: Admin Sessions & Impersonation System
-- ==================================================================================
-- Purpose: Create admin impersonation system for customer support
-- Date: 2025-07-07
-- Dependencies: 001_business_subscription_system.sql, 002_role_permissions_matrix.sql
-- ==================================================================================

-- 1. Create admin sessions table for impersonation tracking
CREATE TABLE IF NOT EXISTS pos_mini_modular3_admin_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    super_admin_id uuid NOT NULL, -- References auth.users(id) but no FK for flexibility
    target_business_id uuid NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
    impersonated_role text NOT NULL DEFAULT 'business_owner',
    session_reason text,
    session_data jsonb DEFAULT '{}', -- Store additional session context
    session_start timestamp with time zone DEFAULT now(),
    session_end timestamp with time zone,
    is_active boolean DEFAULT true,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    CONSTRAINT admin_session_role_check 
    CHECK (impersonated_role = ANY (ARRAY['business_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text])),
    
    CONSTRAINT admin_session_dates_check
    CHECK (session_end IS NULL OR session_end >= session_start)
);

-- 2. Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active 
ON pos_mini_modular3_admin_sessions(super_admin_id, is_active, target_business_id);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_business 
ON pos_mini_modular3_admin_sessions(target_business_id, is_active);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_timerange 
ON pos_mini_modular3_admin_sessions(session_start, session_end) 
WHERE is_active = true;

-- 3. Create trigger for updated_at
CREATE OR REPLACE TRIGGER update_admin_sessions_updated_at 
    BEFORE UPDATE ON pos_mini_modular3_admin_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Enable Row Level Security
ALTER TABLE pos_mini_modular3_admin_sessions ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

-- Policy: Super admins can manage all admin sessions
CREATE POLICY "Super admins can manage admin sessions" 
ON pos_mini_modular3_admin_sessions
FOR ALL TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active'
    )
);

-- Policy: Business owners can view sessions targeting their business (audit trail)
CREATE POLICY "Business owners can view sessions targeting their business" 
ON pos_mini_modular3_admin_sessions
FOR SELECT TO authenticated 
USING (
    target_business_id IN (
        SELECT business_id FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'business_owner' AND status = 'active'
    )
);

-- 6. Helper functions for admin session management

-- Function: Start admin impersonation session
CREATE OR REPLACE FUNCTION pos_mini_modular3_start_admin_session(
    p_target_business_id uuid,
    p_impersonated_role text DEFAULT 'business_owner',
    p_session_reason text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    current_admin_id uuid;
    existing_session_id uuid;
    new_session_id uuid;
    business_exists boolean;
    result jsonb;
BEGIN
    -- Check if caller is super admin
    SELECT id INTO current_admin_id
    FROM pos_mini_modular3_user_profiles
    WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active';
    
    IF current_admin_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only super admins can start impersonation sessions'
        );
    END IF;
    
    -- Validate target business exists
    SELECT EXISTS (
        SELECT 1 FROM pos_mini_modular3_businesses 
        WHERE id = p_target_business_id AND status = 'active'
    ) INTO business_exists;
    
    IF NOT business_exists THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Target business not found or inactive'
        );
    END IF;
    
    -- Validate impersonated role
    IF p_impersonated_role NOT IN ('business_owner', 'manager', 'seller', 'accountant') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invalid impersonated role'
        );
    END IF;
    
    -- Check for existing active session
    SELECT id INTO existing_session_id
    FROM pos_mini_modular3_admin_sessions
    WHERE super_admin_id = current_admin_id
    AND target_business_id = p_target_business_id
    AND is_active = true;
    
    IF existing_session_id IS NOT NULL THEN
        -- Update existing session
        UPDATE pos_mini_modular3_admin_sessions
        SET 
            impersonated_role = p_impersonated_role,
            session_reason = COALESCE(p_session_reason, session_reason),
            session_start = now(),
            updated_at = now()
        WHERE id = existing_session_id
        RETURNING id INTO new_session_id;
    ELSE
        -- Create new session
        INSERT INTO pos_mini_modular3_admin_sessions (
            super_admin_id,
            target_business_id,
            impersonated_role,
            session_reason,
            ip_address,
            user_agent
        ) VALUES (
            current_admin_id,
            p_target_business_id,
            p_impersonated_role,
            p_session_reason,
            inet_client_addr(),
            current_setting('request.headers', true)::jsonb->>'user-agent'
        ) RETURNING id INTO new_session_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'session_id', new_session_id,
        'message', 'Admin impersonation session started'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Failed to start admin session: ' || SQLERRM
    );
END;
$$;

-- Function: End admin impersonation session
CREATE OR REPLACE FUNCTION pos_mini_modular3_end_admin_session(
    p_session_id uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    current_admin_id uuid;
    session_count integer;
    result jsonb;
BEGIN
    -- Check if caller is super admin
    SELECT id INTO current_admin_id
    FROM pos_mini_modular3_user_profiles
    WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active';
    
    IF current_admin_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only super admins can end impersonation sessions'
        );
    END IF;
    
    -- End specific session or all active sessions for this admin
    IF p_session_id IS NOT NULL THEN
        UPDATE pos_mini_modular3_admin_sessions
        SET 
            is_active = false,
            session_end = now(),
            updated_at = now()
        WHERE id = p_session_id 
        AND super_admin_id = current_admin_id
        AND is_active = true;
        
        GET DIAGNOSTICS session_count = ROW_COUNT;
    ELSE
        UPDATE pos_mini_modular3_admin_sessions
        SET 
            is_active = false,
            session_end = now(),
            updated_at = now()
        WHERE super_admin_id = current_admin_id
        AND is_active = true;
        
        GET DIAGNOSTICS session_count = ROW_COUNT;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'sessions_ended', session_count,
        'message', 'Admin impersonation session(s) ended'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Failed to end admin session: ' || SQLERRM
    );
END;
$$;

-- Function: Get active admin sessions
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_active_admin_sessions(
    p_business_id uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    current_user_id uuid;
    current_user_role text;
    sessions_data jsonb;
    result jsonb;
BEGIN
    -- Get current user info
    SELECT id, role INTO current_user_id, current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = auth.uid() AND status = 'active';
    
    IF current_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found or inactive'
        );
    END IF;
    
    -- Build query based on user role
    IF current_user_role = 'super_admin' THEN
        -- Super admin can see all sessions
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'target_business_id', s.target_business_id,
                'business_name', b.name,
                'impersonated_role', s.impersonated_role,
                'session_reason', s.session_reason,
                'session_start', s.session_start,
                'duration_minutes', EXTRACT(EPOCH FROM (now() - s.session_start))/60
            )
        ) INTO sessions_data
        FROM pos_mini_modular3_admin_sessions s
        JOIN pos_mini_modular3_businesses b ON b.id = s.target_business_id
        WHERE s.is_active = true
        AND (p_business_id IS NULL OR s.target_business_id = p_business_id);
        
    ELSE
        -- Business owners can only see sessions targeting their business
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'impersonated_role', s.impersonated_role,
                'session_start', s.session_start,
                'session_reason', s.session_reason
            )
        ) INTO sessions_data
        FROM pos_mini_modular3_admin_sessions s
        JOIN pos_mini_modular3_user_profiles up ON up.business_id = s.target_business_id
        WHERE s.is_active = true
        AND up.id = current_user_id
        AND up.role = 'business_owner';
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'sessions', COALESCE(sessions_data, '[]'::jsonb),
        'total_count', jsonb_array_length(COALESCE(sessions_data, '[]'::jsonb))
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Failed to get admin sessions: ' || SQLERRM
    );
END;
$$;

-- 7. Grant execute permissions
GRANT EXECUTE ON FUNCTION pos_mini_modular3_start_admin_session(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_end_admin_session(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_get_active_admin_sessions(uuid) TO authenticated;

-- 8. Add comments for documentation
COMMENT ON TABLE pos_mini_modular3_admin_sessions IS 'Admin impersonation sessions for customer support and debugging';
COMMENT ON FUNCTION pos_mini_modular3_start_admin_session(uuid, text, text) IS 'Start admin impersonation session for business support';
COMMENT ON FUNCTION pos_mini_modular3_end_admin_session(uuid) IS 'End admin impersonation session';
COMMENT ON FUNCTION pos_mini_modular3_get_active_admin_sessions(uuid) IS 'Get active admin sessions with filtering';

-- Migration success message
DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 003 COMPLETED: Admin Sessions & Impersonation System';
    RAISE NOTICE '🔒 Created secure admin impersonation tracking';
    RAISE NOTICE '📊 Added session management functions';
    RAISE NOTICE '🛡️ Added RLS policies for audit trail';
END $$;
