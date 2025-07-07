-- ==================================================================================
-- MIGRATION 005: Auth Access Functions
-- ==================================================================================
-- Purpose: Functions to safely access auth schema from export SQL API
-- Date: 2025-07-07
-- Dependencies: 001-004 core system migrations
-- ==================================================================================

-- Function to get all tables info like pg_dump
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_all_tables_info()
RETURNS TABLE (
  schema_name text,
  table_name text,
  table_type text
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    schemaname::text as schema_name,
    tablename::text as table_name,
    'BASE TABLE'::text as table_type
  FROM pg_tables 
  WHERE schemaname IN ('public', 'auth')
  AND (
    (schemaname = 'public' AND tablename LIKE 'pos_mini_modular3_%') OR
    (schemaname = 'auth' AND tablename = 'users')
  )
  ORDER BY schemaname, tablename;
$$;

-- Function to get auth.users data safely
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_auth_users()
RETURNS TABLE (
  instance_id uuid,
  id uuid,
  aud text,
  role text,
  email text,
  encrypted_password text,
  email_confirmed_at timestamptz,
  invited_at timestamptz,
  confirmation_token text,
  confirmation_sent_at timestamptz,
  recovery_token text,
  recovery_sent_at timestamptz,
  email_change_token_new text,
  email_change text,
  email_change_sent_at timestamptz,
  last_sign_in_at timestamptz,
  raw_app_meta_data jsonb,
  raw_user_meta_data jsonb,
  is_super_admin boolean,
  created_at timestamptz,
  updated_at timestamptz,
  phone text,
  phone_confirmed_at timestamptz,
  phone_change text,
  phone_change_token text,
  phone_change_sent_at timestamptz,
  email_change_token_current text,
  email_change_confirm_status smallint,
  banned_until timestamptz,
  reauthentication_token text,
  reauthentication_sent_at timestamptz,
  is_sso_user boolean,
  deleted_at timestamptz,
  is_anonymous boolean
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    invited_at,
    confirmation_token,
    confirmation_sent_at,
    recovery_token,
    recovery_sent_at,
    email_change_token_new,
    email_change,
    email_change_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at,
    is_sso_user,
    deleted_at,
    is_anonymous
  FROM auth.users
  ORDER BY created_at;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION pos_mini_modular3_get_all_tables_info() TO authenticated;
GRANT EXECUTE ON FUNCTION pos_mini_modular3_get_auth_users() TO authenticated;

-- Comment the functions
COMMENT ON FUNCTION pos_mini_modular3_get_all_tables_info() IS 'Get information about all tables available for export, similar to pg_dump';
COMMENT ON FUNCTION pos_mini_modular3_get_auth_users() IS 'Safely access auth.users table data for export purposes';
