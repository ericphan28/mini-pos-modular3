-- ==================================================================================
-- POS MINI MODULAR 3 - DATABASE EXPORT
-- ==================================================================================
-- Generated: 2025-07-05T14:14:43.676Z
-- Format: SUPABASE
-- Target: Supabase PostgreSQL Database
-- 
-- Instructions:
-- 1. Copy this entire script
-- 2. Open Supabase Dashboard > SQL Editor
-- 3. Create a new query
-- 4. Paste and run this script
-- 
-- This script creates tables and inserts data with conflict resolution
-- ==================================================================================


-- ==================================================================================
-- SCHEMA EXPORT
-- ==================================================================================

-- Table: auth.users (empty - basic schema)
CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_backup_downloads (empty - basic schema)
CREATE TABLE IF NOT EXISTS pos_mini_modular3_backup_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE pos_mini_modular3_backup_downloads ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_backup_metadata
CREATE TABLE IF NOT EXISTS pos_mini_modular3_backup_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename TEXT,
  type TEXT,
  size INTEGER,
  checksum TEXT,
  created_at TIMESTAMPTZ,
  version TEXT,
  tables JSONB,
  compressed BOOLEAN,
  encrypted BOOLEAN,
  storage_path TEXT,
  retention_until TEXT,
  status TEXT,
  error_message TEXT,
  created_by TEXT
);

-- Enable RLS for pos_mini_modular3_backup_metadata
ALTER TABLE pos_mini_modular3_backup_metadata ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_backup_notifications (empty - basic schema)
CREATE TABLE IF NOT EXISTS pos_mini_modular3_backup_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE pos_mini_modular3_backup_notifications ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_backup_schedules
CREATE TABLE IF NOT EXISTS pos_mini_modular3_backup_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  backup_type TEXT,
  cron_expression TEXT,
  enabled BOOLEAN,
  compression TEXT,
  encryption BOOLEAN,
  retention_days INTEGER,
  last_run_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ,
  failure_count INTEGER,
  last_error TEXT,
  created_by TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_backup_schedules
ALTER TABLE pos_mini_modular3_backup_schedules ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_business_invitations (empty - basic schema)
CREATE TABLE IF NOT EXISTS pos_mini_modular3_business_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE pos_mini_modular3_business_invitations ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_business_types
CREATE TABLE IF NOT EXISTS pos_mini_modular3_business_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  value TEXT,
  label TEXT,
  description TEXT,
  icon TEXT,
  category TEXT,
  is_active BOOLEAN,
  sort_order INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_business_types
ALTER TABLE pos_mini_modular3_business_types ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_businesses
CREATE TABLE IF NOT EXISTS pos_mini_modular3_businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  code TEXT,
  business_type TEXT,
  phone TEXT,
  email VARCHAR(255),
  address TEXT,
  tax_code TEXT,
  legal_representative TEXT,
  logo_url TEXT,
  status TEXT,
  settings JSONB,
  subscription_tier TEXT,
  subscription_status TEXT,
  subscription_starts_at TIMESTAMPTZ,
  subscription_ends_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  max_users INTEGER,
  max_products INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_businesses
ALTER TABLE pos_mini_modular3_businesses ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_restore_history
CREATE TABLE IF NOT EXISTS pos_mini_modular3_restore_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_id TEXT,
  restored_at TIMESTAMPTZ,
  restored_by TEXT,
  restore_type TEXT,
  target_tables TEXT,
  success BOOLEAN,
  error_message TEXT,
  duration_ms INTEGER,
  rows_affected INTEGER,
  restore_point_id TEXT
);

-- Enable RLS for pos_mini_modular3_restore_history
ALTER TABLE pos_mini_modular3_restore_history ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_restore_points
CREATE TABLE IF NOT EXISTS pos_mini_modular3_restore_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ,
  tables_backup JSONB,
  schema_backup TEXT,
  created_by TEXT,
  expires_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_restore_points
ALTER TABLE pos_mini_modular3_restore_points ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_subscription_history (empty - basic schema)
CREATE TABLE IF NOT EXISTS pos_mini_modular3_subscription_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE pos_mini_modular3_subscription_history ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_subscription_plans
CREATE TABLE IF NOT EXISTS pos_mini_modular3_subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier TEXT,
  name TEXT,
  price_monthly INTEGER,
  max_users INTEGER,
  max_products INTEGER,
  max_warehouses INTEGER,
  max_branches INTEGER,
  features JSONB,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_subscription_plans
ALTER TABLE pos_mini_modular3_subscription_plans ENABLE ROW LEVEL SECURITY;

-- Table: pos_mini_modular3_user_profiles
CREATE TABLE IF NOT EXISTS pos_mini_modular3_user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id TEXT,
  full_name TEXT,
  phone TEXT,
  email VARCHAR(255),
  avatar_url TEXT,
  role TEXT,
  status TEXT,
  permissions JSONB,
  login_method TEXT,
  last_login_at TIMESTAMPTZ,
  employee_id TEXT,
  hire_date TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- Enable RLS for pos_mini_modular3_user_profiles
ALTER TABLE pos_mini_modular3_user_profiles ENABLE ROW LEVEL SECURITY;


-- ==================================================================================
-- DATA EXPORT (pg_dump style)
-- ==================================================================================

-- Data for table: auth.users (14 rows)
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '550ce2c2-2d18-4a75-8ece-0c2c8f4dadad', 'authenticated', 'authenticated', 'ericphan28@gmail.com', '$2a$10$XeN2AYqNigpuM8vleGrlueHzo.Ck7waUtKgLmKP7s02jHgh2MRA.m', '2025-06-30T21:45:29.779993+00:00', NULL, '', '2025-06-30T21:42:37.344249+00:00', '', NULL, '', '', NULL, '2025-07-05T13:47:19.143779+00:00', '{"provider":"email","providers":["email"]}'::jsonb, '{"sub":"550ce2c2-2d18-4a75-8ece-0c2c8f4dadad","email":"ericphan28@gmail.com","email_verified":true,"phone_verified":false}'::jsonb, NULL, '2025-06-30T21:42:37.333746+00:00', '2025-07-05T13:47:19.147253+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'c8c6a529-e57c-4dbf-900f-c26dd4815195', 'authenticated', 'authenticated', '+84901234567@staff.pos.local', '$2a$06$j8e0EwBGC.z7S7cRu9KDJOawWWcK62RMbIRFoMjgQ9DhR4a8Exe1e', '2025-06-30T23:54:50.592949+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{}'::jsonb, false, '2025-06-30T23:54:50.592949+00:00', '2025-06-30T23:54:50.592949+00:00', '+84901234567', '2025-06-30T23:54:50.592949+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '8388a0e3-0a1a-4ce2-9c54-257994d44616', 'authenticated', 'authenticated', '+84909582083@staff.pos.local', '$2a$06$055Vl2pUmCyyvCQB8obVU.ZjsWRbhY/J13Ssjz/Xr5RSrTcj1d/YS', '2025-07-01T00:06:56.999574+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{}'::jsonb, false, '2025-07-01T00:06:56.999574+00:00', '2025-07-01T00:06:56.999574+00:00', '+84909582083', '2025-07-01T00:06:56.999574+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'bba27899-25c8-4d5b-ba81-a0201f98bd00', 'authenticated', 'authenticated', '+84907136029@staff.pos.local', '$2a$06$Mg7gL8a5nk5ok/E3E0.CaObzsoHMqPkEFB4gcub0cjVyXwJJGWi2W', '2025-07-01T00:09:24.007284+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{}'::jsonb, false, '2025-07-01T00:09:24.007284+00:00', '2025-07-01T00:09:24.007284+00:00', '+84907136029', '2025-07-01T00:09:24.007284+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'b5ca076a-7b1f-4d4e-808d-0610f71288a8', 'authenticated', 'authenticated', '+84922388399@staff.pos.local', '$2a$06$cQXrBqc.jQeIUsIa77nU9eft0D3g0YdhY0I29qoaKJ1qtQLY2gSS.', '2025-07-01T00:59:06.756329+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{}'::jsonb, false, '2025-07-01T00:59:06.756329+00:00', '2025-07-01T00:59:06.756329+00:00', '+84922388399', '2025-07-01T00:59:06.756329+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '5f8d74cf-572a-4640-a565-34c5e1462f4e', 'authenticated', 'authenticated', 'cym_sunset@yahoo.com', '$2a$10$l1ahnejet3PJUhiJi1cms.B2csLc9S3.Yhozu81/T/ynWz6x/YQr6', '2025-07-01T09:11:33.876679+00:00', NULL, '', '2025-07-01T09:11:07.107667+00:00', '', NULL, '', '', NULL, '2025-07-01T10:45:08.605363+00:00', '{"provider":"email","providers":["email"]}'::jsonb, '{"sub":"5f8d74cf-572a-4640-a565-34c5e1462f4e","email":"cym_sunset@yahoo.com","phone":"0907136029","address":"D2/062A, Nam Son, Quang Trung, Thong Nhat","taxCode":"3604005775","fullName":"Phan Thiên Hào","businessName":"An Nhiên Farm","businessType":"cafe","email_verified":true,"phone_verified":false}'::jsonb, NULL, '2025-07-01T09:11:07.073442+00:00', '2025-07-01T10:45:08.613579+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '8740cb15-5bea-480d-b58b-2f9fd51c144e', 'authenticated', 'authenticated', '+84907131111@staff.pos.local', '$2a$06$4Rz9QG7LE6XExIGTMX9dwumRLztCiPJ5rq8q3TIjJ2YIDSgyspRxS', '2025-07-01T10:43:03.150311+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{}'::jsonb, false, '2025-07-01T10:43:03.150311+00:00', '2025-07-01T10:43:03.150311+00:00', '+84907131111', '2025-07-01T10:43:03.150311+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '9c9bc32f-6b7e-4239-857a-83d9b8b16ce7', 'authenticated', 'authenticated', 'yenwinny83@gmail.com', '$2a$10$C1lMtbgf/1EKPE7.vRGstOWpJlYGUiT1tx3/oNw86Xdbaxv8ObBbu', '2025-07-01T12:00:03.406578+00:00', NULL, '', '2025-07-01T11:59:54.348181+00:00', '', NULL, '', '', NULL, '2025-07-02T01:59:50.639001+00:00', '{"provider":"email","providers":["email"]}'::jsonb, '{"sub":"9c9bc32f-6b7e-4239-857a-83d9b8b16ce7","email":"yenwinny83@gmail.com","phone":"0909582083","address":"145 Cạnh Sacombank Gia Yên","taxCode":"987654456","fullName":"Mẹ Yến","businessName":"Của Hàng Rau Sạch Phi Yến","businessType":"food_service","email_verified":true,"phone_verified":false}'::jsonb, NULL, '2025-07-01T11:59:54.332309+00:00', '2025-07-02T01:59:50.652378+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'f1de66c9-166a-464c-89aa-bd75e1095040', 'authenticated', 'authenticated', 'admin@giakiemso.com', '$2a$06$GVkqtUduJGusGD1zqEbrueKSzbDjbaqedwSmV4ilF1TsJqLBOUFpm', '2025-07-02T02:16:30.46745+00:00', NULL, '', '2025-07-02T02:16:30.46745+00:00', '', NULL, '', '', NULL, '2025-07-05T13:44:03.613575+00:00', '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Super Administrator"}'::jsonb, false, '2025-07-02T02:16:30.46745+00:00', '2025-07-05T13:44:03.616122+00:00', '0907136029', '2025-07-02T02:16:30.46745+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '90437fcb-0a83-44b7-ab05-322af922b451', 'authenticated', 'authenticated', 'bidathienlong01@gmail.com', '$2a$10$wTPSitpXOKVHVSaR6/ohCODHENGpqSxzQRHlpMpN2Wm0JfCegaVDm', '2025-07-02T19:43:50.594085+00:00', NULL, '', '2025-07-02T19:30:55.093304+00:00', '', NULL, '', '', NULL, '2025-07-02T19:44:04.468565+00:00', '{"provider":"email","providers":["email"]}'::jsonb, '{"sub":"90437fcb-0a83-44b7-ab05-322af922b451","email":"bidathienlong01@gmail.com","phone":"0909564874","address":"54 ap Gia Tân 2","taxCode":"987026351478","fullName":"Phan Thiên Long","businessName":"Nhà Hàn Hoa Viên 79","businessType":"fashion","email_verified":true,"phone_verified":false}'::jsonb, NULL, '2025-07-02T19:30:55.052042+00:00', '2025-07-02T19:44:04.481823+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES (NULL, '8c3b94aa-68b1-47db-9029-07be27d3b917', NULL, NULL, 'test.direct@rpc.test', '$2a$06$N6Uk6qpqut6jYt.jGz1auOFk/rJCfv5jFfjxlfHetNTZwlKT6MtUW', '2025-07-03T13:28:51.257721+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Test Direct Owner"}'::jsonb, NULL, '2025-07-03T13:28:51.257721+00:00', '2025-07-03T13:28:51.257721+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES (NULL, '2706a795-f2a4-46f6-8030-3553a8a1ecb0', NULL, NULL, 'test.direct2@rpc.test', '$2a$06$wEf4Evk4QMjDHDPNMTkt9OkTSzM9VkLRYt9sh6iRuTSXZIlcVIq0u', '2025-07-03T13:28:51.487484+00:00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Test Direct Owner 2"}'::jsonb, NULL, '2025-07-03T13:28:51.487484+00:00', '2025-07-03T13:28:51.487484+00:00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES (NULL, '3a799c65-8c58-429c-9e48-4d74b236ab97', NULL, NULL, NULL, '$2a$06$aaId.rrWcLosmO4XBH7zweXRhrMANl.7tLRnFS2DZ6sgonolwND2S', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{"full_name":"Nguyên Ly"}'::jsonb, NULL, '2025-07-03T13:38:21.323452+00:00', '2025-07-03T13:38:21.323452+00:00', '+84909123456', '2025-07-03T13:38:21.323452+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES (NULL, '9d40bf3c-e5a3-44c2-96c7-4c36a479e668', NULL, NULL, NULL, '$2a$06$byCSpwUiKPtJza78STb5HeRghynJ3dfXPCTA18Z1C6S1ozcnSVZBW', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider":"phone","providers":["phone"]}'::jsonb, '{"full_name":"Nguyễn Huy"}'::jsonb, NULL, '2025-07-03T13:39:20.303084+00:00', '2025-07-03T13:39:20.303084+00:00', '+84901456789', '2025-07-03T13:39:20.303084+00:00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false)
  ON CONFLICT (id) DO UPDATE SET
    instance_id = EXCLUDED.instance_id,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    invited_at = EXCLUDED.invited_at,
    confirmation_token = EXCLUDED.confirmation_token,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    recovery_token = EXCLUDED.recovery_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change = EXCLUDED.email_change,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    is_super_admin = EXCLUDED.is_super_admin,
    updated_at = EXCLUDED.updated_at,
    phone = EXCLUDED.phone,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    phone_change = EXCLUDED.phone_change,
    phone_change_token = EXCLUDED.phone_change_token,
    phone_change_sent_at = EXCLUDED.phone_change_sent_at,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_confirm_status = EXCLUDED.email_change_confirm_status,
    banned_until = EXCLUDED.banned_until,
    reauthentication_token = EXCLUDED.reauthentication_token,
    reauthentication_sent_at = EXCLUDED.reauthentication_sent_at,
    is_sso_user = EXCLUDED.is_sso_user,
    deleted_at = EXCLUDED.deleted_at,
    is_anonymous = EXCLUDED.is_anonymous;

-- Table pos_mini_modular3_backup_downloads is empty

-- Data for table: pos_mini_modular3_backup_metadata (7 rows)
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('1ep6obol1h1mco943i0', 'pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc', 'data', 6984, 'e2f3e30cfb0548453783adff2c8385c314bc210f9af4189ac2d3e5e7fd4dc42f', '2025-07-04T03:24:54.072+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc', '2025-08-03T03:24:55.997+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('15v2kx2zp3ymcoxduiq', 'pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc', 'data', 7860, '2f34b42804472f1aa370c281e8004f9b64283ca4a3feab15dc5ced6dd52ef654', '2025-07-04T14:44:19.778+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc', '2025-08-03T14:44:21.28+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('0akl4fn6laafmcotdaeb', 'pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc', 'data', 7299, '892d2e05d1968b295633d099c0a91b92d343ddc1f742c46dedf4286820bc0402', '2025-07-04T12:51:55.235+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc', '2025-08-03T12:51:57.487+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('aiaawarjb1mco62qfu', 'pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc', 'data', 6612, '34992f4a7ce8e0bddf4d7791a4d61c6b9b8bcb19d0b5c8348719cac6c3dea508', '2025-07-04T01:59:51.642+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc', '2025-08-03T01:59:53.308+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('qsw626zysbpmco5tkrn', 'pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc', 'data', 6199, '9d87b9fe7f1f73a0ed69962e927d5209c7e0b0792cfdcdf030672d11c0be4423', '2025-07-04T01:52:44.387+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc', '2025-08-03T01:52:45.827+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('n7tjq9mkd3mcpg7cxv', 'pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc', 'full', 8630, '66770dde62b33761d44fa50dc7d2c6f52a5315f69b91c2de02d34d6103910bb7', '2025-07-04T23:31:09.763+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc', '2025-08-03T23:31:12.213+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;
INSERT INTO pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) VALUES ('aey5miijilmcq8vofz', 'pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc', 'full', 8598, 'd703319c969a7e115ddf6359bb3bcaca56272e2d5846c90916bedbdc0f5ac2ee', '2025-07-05T12:53:53.663+00:00', 'Unknown', '["pos_mini_modular3_backup_downloads","pos_mini_modular3_backup_metadata","pos_mini_modular3_backup_notifications","pos_mini_modular3_backup_schedules","pos_mini_modular3_business_invitations","pos_mini_modular3_business_types","pos_mini_modular3_businesses","pos_mini_modular3_restore_history","pos_mini_modular3_restore_points","pos_mini_modular3_subscription_history","pos_mini_modular3_subscription_plans","pos_mini_modular3_user_profiles"]'::jsonb, true, true, 'pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc', '2025-08-04T12:53:55.926+00:00', 'completed', NULL, 'system')
  ON CONFLICT (id) DO UPDATE SET
    filename = EXCLUDED.filename,
    type = EXCLUDED.type,
    size = EXCLUDED.size,
    checksum = EXCLUDED.checksum,
    version = EXCLUDED.version,
    tables = EXCLUDED.tables,
    compressed = EXCLUDED.compressed,
    encrypted = EXCLUDED.encrypted,
    storage_path = EXCLUDED.storage_path,
    retention_until = EXCLUDED.retention_until,
    status = EXCLUDED.status,
    error_message = EXCLUDED.error_message,
    created_by = EXCLUDED.created_by;

-- Table pos_mini_modular3_backup_notifications is empty

-- Data for table: pos_mini_modular3_backup_schedules (2 rows)
INSERT INTO pos_mini_modular3_backup_schedules (id, name, backup_type, cron_expression, enabled, compression, encryption, retention_days, last_run_at, next_run_at, failure_count, last_error, created_by, created_at, updated_at) VALUES ('8bad2bc1-a479-48c1-a58c-6424e34e58ea', 'Daily Incremental Backup', 'incremental', '0 2 * * *', true, 'gzip', true, 30, NULL, '2025-07-04T15:50:02.923339+00:00', 0, NULL, 'system', '2025-07-03T15:50:02.923339+00:00', '2025-07-04T22:53:45.51178+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    backup_type = EXCLUDED.backup_type,
    cron_expression = EXCLUDED.cron_expression,
    enabled = EXCLUDED.enabled,
    compression = EXCLUDED.compression,
    encryption = EXCLUDED.encryption,
    retention_days = EXCLUDED.retention_days,
    last_run_at = EXCLUDED.last_run_at,
    next_run_at = EXCLUDED.next_run_at,
    failure_count = EXCLUDED.failure_count,
    last_error = EXCLUDED.last_error,
    created_by = EXCLUDED.created_by,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_backup_schedules (id, name, backup_type, cron_expression, enabled, compression, encryption, retention_days, last_run_at, next_run_at, failure_count, last_error, created_by, created_at, updated_at) VALUES ('f46e39c3-5a40-48f7-984a-27cd5704fb09', 'Weekly Full Backup', 'full', '0 3 * * 0', true, 'gzip', true, 90, NULL, '2025-07-10T15:50:02.923339+00:00', 0, NULL, 'system', '2025-07-03T15:50:02.923339+00:00', '2025-07-04T22:53:45.51178+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    backup_type = EXCLUDED.backup_type,
    cron_expression = EXCLUDED.cron_expression,
    enabled = EXCLUDED.enabled,
    compression = EXCLUDED.compression,
    encryption = EXCLUDED.encryption,
    retention_days = EXCLUDED.retention_days,
    last_run_at = EXCLUDED.last_run_at,
    next_run_at = EXCLUDED.next_run_at,
    failure_count = EXCLUDED.failure_count,
    last_error = EXCLUDED.last_error,
    created_by = EXCLUDED.created_by,
    updated_at = EXCLUDED.updated_at;

-- Error: Could not export data for table pos_mini_modular3_business_invitations - permission denied for table users

-- Data for table: pos_mini_modular3_business_types (31 rows)
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('1dc28a52-de30-4c51-82e5-2c54a33fbb5c', 'retail', '🏪 Bán lẻ', 'Cửa hàng bán lẻ, siêu thị mini, tạp hóa', '🏪', 'retail', true, 10, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('380698d9-442e-4ead-a777-46b638ea641f', 'wholesale', '📦 Bán sỉ', 'Bán sỉ, phân phối hàng hóa', '📦', 'retail', true, 20, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('b48d76f0-b535-466c-861b-b6304ed28d80', 'fashion', '👗 Thời trang', 'Quần áo, giày dép, phụ kiện thời trang', '👗', 'retail', true, 30, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('abe66183-1d93-453f-8ddf-bf3961b9f254', 'electronics', '📱 Điện tử', 'Điện thoại, máy tính, thiết bị điện tử', '📱', 'retail', true, 40, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('a09e0ef4-68cd-4306-aaaa-e3894bf34ac4', 'restaurant', '🍽️ Nhà hàng', 'Nhà hàng, quán ăn, fast food', '🍽️', 'food', true, 110, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('0a631496-d43b-4593-9997-11a76457c1d1', 'cafe', '☕ Quán cà phê', 'Cà phê, trà sữa, đồ uống', '☕', 'food', true, 120, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('7f6a0248-48d4-42bf-b69d-b06ae8a78d08', 'food_service', '🍱 Dịch vụ ăn uống', 'Catering, giao đồ ăn, suất ăn công nghiệp', '🍱', 'food', true, 130, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('24cfb1e4-3243-4f2b-a49d-ec775b4644e6', 'beauty', '💄 Làm đẹp', 'Mỹ phẩm, làm đẹp, chăm sóc da', '💄', 'beauty', true, 210, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('0ae5962c-a16d-4e07-860b-9ea13d174576', 'spa', '🧖‍♀️ Spa', 'Spa, massage, thư giãn', '🧖‍♀️', 'beauty', true, 220, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('88b16cdc-3c76-4633-888d-748b08a40c48', 'salon', '💇‍♀️ Salon', 'Cắt tóc, tạo kiểu, làm nail', '💇‍♀️', 'beauty', true, 230, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('929559c9-d7a0-4292-a9f4-6aff2b8e8539', 'healthcare', '🏥 Y tế', 'Dịch vụ y tế, chăm sóc sức khỏe', '🏥', 'healthcare', true, 310, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('768b62b6-6b1c-4665-8296-1a0f9b7512bf', 'pharmacy', '💊 Nhà thuốc', 'Hiệu thuốc, dược phẩm', '💊', 'healthcare', true, 320, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('28066e50-889c-4181-b303-d77d598c5dbc', 'clinic', '🩺 Phòng khám', 'Phòng khám tư, chuyên khoa', '🩺', 'healthcare', true, 330, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('01f7f102-d0b5-4dce-98e5-26343f19f182', 'education', '🎓 Giáo dục', 'Trung tâm dạy học, đào tạo', '🎓', 'professional', true, 410, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('7ac90817-0d1b-4a18-8857-5cba2ef63e9c', 'consulting', '💼 Tư vấn', 'Dịch vụ tư vấn, chuyên môn', '💼', 'professional', true, 420, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('0785cb7a-689a-4591-94c0-6eba1261db0f', 'finance', '💰 Tài chính', 'Dịch vụ tài chính, bảo hiểm', '💰', 'professional', true, 430, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('34bfe785-4294-4890-bbf6-038acb095710', 'real_estate', '🏘️ Bất động sản', 'Môi giới, tư vấn bất động sản', '🏘️', 'professional', true, 440, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('0dbcca8f-9ce3-47ed-9297-c3a2b785451e', 'automotive', '🚗 Ô tô', 'Sửa chữa, bảo dưỡng ô tô, xe máy', '🚗', 'technical', true, 510, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('a68d37f4-a91f-4247-9e2f-e05e1a6331ed', 'repair', '🔧 Sửa chữa', 'Sửa chữa điện tử, đồ gia dụng', '🔧', 'technical', true, 520, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('0de2b85d-4410-4fb1-b00a-1a716c3be98a', 'cleaning', '🧹 Vệ sinh', 'Dịch vụ vệ sinh, dọn dẹp', '🧹', 'technical', true, 530, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('cb7fd67f-1574-458d-ad38-c6df271d9adf', 'construction', '🏗️ Xây dựng', 'Xây dựng, sửa chữa nhà cửa', '🏗️', 'technical', true, 540, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('7911c5f3-4be8-482b-a6b7-d0fcf55bf650', 'travel', '✈️ Du lịch', 'Tour du lịch, dịch vụ lữ hành', '✈️', 'entertainment', true, 610, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('2c14d3ba-8afb-4651-b1d6-514060332e39', 'hotel', '🏨 Khách sạn', 'Khách sạn, nhà nghỉ, homestay', '🏨', 'entertainment', true, 620, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('7ac93735-73a9-4517-8d80-d2d6b45e735a', 'entertainment', '🎉 Giải trí', 'Karaoke, game, sự kiện', '🎉', 'entertainment', true, 630, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('50787e95-4a31-4c94-bd22-1224cee4a8be', 'sports', '⚽ Thể thao', 'Sân thể thao, dụng cụ thể thao', '⚽', 'entertainment', true, 640, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('103b4ac9-dd72-4d7a-93d8-1b62ac03f6e5', 'agriculture', '🌾 Nông nghiệp', 'Nông sản, thủy sản, chăn nuôi', '🌾', 'industrial', true, 710, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('546c8520-8b18-4795-aa94-02612bdab76c', 'manufacturing', '🏭 Sản xuất', 'Sản xuất, gia công, chế biến', '🏭', 'industrial', true, 720, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('1dfd7419-5dd5-47d4-9daa-0841a597f47b', 'logistics', '🚚 Logistics', 'Vận chuyển, kho bãi, logistics', '🚚', 'industrial', true, 730, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('181ca2e0-58b7-4002-8f1b-6bdbe9442f47', 'service', '🔧 Dịch vụ', 'Dịch vụ tổng hợp khác', '🔧', 'service', true, 910, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('6eef9c17-98df-445c-88c3-3153a7970ac4', 'other', '🏢 Khác', 'Các loại hình kinh doanh khác', '🏢', 'other', true, 999, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) VALUES ('8b66bec4-57ff-40a5-9210-ab7e5ceb0a73', 'gym', '💪 Gym & Thể thao', 'Phòng gym, yoga, thể dục thể thao', '💪', 'sports', true, 240, '2025-07-03T10:59:01.990231+00:00', '2025-07-04T22:53:46.113917+00:00')
  ON CONFLICT (id) DO UPDATE SET
    value = EXCLUDED.value,
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order,
    updated_at = EXCLUDED.updated_at;

-- Data for table: pos_mini_modular3_businesses (8 rows)
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('61473fc9-16b2-45b8-87f0-45e0dc8612ef', 'An Nhiên Farm', 'BIZ1751366425', 'cafe', NULL, NULL, 'D2/062A, Nam Son, Quang Trung, Thong Nhat', '3604005775', NULL, NULL, 'trial', '{}'::jsonb, 'free', 'trial', '2025-07-01T10:40:25.745418+00:00', NULL, '2025-07-31T10:40:25.745418+00:00', 5, 50, '2025-07-01T10:40:25.745418+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('dda92815-c1f0-4597-8c05-47ec1eb50873', 'Của Hàng Rau Sạch Phi Yến', 'BIZ1751371309', 'retail', NULL, NULL, '145 Cạnh Sacombank Gia Yên', '987654456', NULL, NULL, 'trial', '{}'::jsonb, 'free', 'trial', '2025-07-01T12:01:49.27648+00:00', NULL, '2025-07-31T12:01:49.27648+00:00', 5, 50, '2025-07-01T12:01:49.27648+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('e997773b-8876-4837-aa80-c2f82cf07f83', 'Chao Lòng Viên Minh Châu', 'SAFE202507026623', 'service', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}'::jsonb, 'free', 'trial', '2025-07-02T18:55:36.167643+00:00', '2025-08-01T18:55:36.167643+00:00', '2025-08-01T18:55:36.167643+00:00', 3, 100, '2025-07-02T18:55:36.167643+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('c182f174-6372-4b34-964d-765fdc6dabbd', 'Lẩu Cua Đồng Thanh Sơn', 'BIZ202507039693', 'fashion', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}'::jsonb, 'premium', 'active', '2025-07-03T13:38:21.323452+00:00', NULL, NULL, 50, 5000, '2025-07-03T13:38:21.323452+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('7a2a2404-8498-4396-bd2b-e6745591652b', 'Test Direct RPC Business 2333', 'BIZ202507036302', 'retail', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}'::jsonb, 'free', 'trial', '2025-07-03T13:28:51.487484+00:00', '2025-08-02T13:28:51.487484+00:00', '2025-08-02T13:28:51.487484+00:00', 3, 50, '2025-07-03T13:28:51.487484+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('37c75836-edb9-4dc2-8bbe-83ad87ba274e', 'Gas Tân Yên 563 business ', 'BIZ202507032595', 'construction', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}'::jsonb, 'basic', 'active', '2025-07-03T13:39:20.303084+00:00', NULL, NULL, 10, 500, '2025-07-03T13:39:20.303084+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('1f0290fe-3ed1-440b-9a0b-68885aaba9f8', 'Test Direct RPC trucchi', 'BIZ202507032202', 'fashion', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}'::jsonb, 'free', 'trial', '2025-07-03T13:28:51.257721+00:00', '2025-08-02T13:28:51.257721+00:00', '2025-08-02T13:28:51.257721+00:00', 3, 50, '2025-07-03T13:28:51.257721+00:00', '2025-07-04T22:53:46.665466+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) VALUES ('97da7e62-0409-4882-b80c-2c75b60cb0da', 'Bida Thiên Long 3\n', 'BIZ000001', 'retail', NULL, NULL, NULL, NULL, NULL, NULL, 'trial', '{}'::jsonb, 'free', 'trial', '2025-06-30T22:38:05.559244+00:00', NULL, '2025-07-30T22:38:05.559244+00:00', 3, 50, '2025-06-30T22:38:05.559244+00:00', '2025-07-04T23:33:51.772724+00:00')
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    business_type = EXCLUDED.business_type,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    tax_code = EXCLUDED.tax_code,
    legal_representative = EXCLUDED.legal_representative,
    logo_url = EXCLUDED.logo_url,
    status = EXCLUDED.status,
    settings = EXCLUDED.settings,
    subscription_tier = EXCLUDED.subscription_tier,
    subscription_status = EXCLUDED.subscription_status,
    subscription_starts_at = EXCLUDED.subscription_starts_at,
    subscription_ends_at = EXCLUDED.subscription_ends_at,
    trial_ends_at = EXCLUDED.trial_ends_at,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    updated_at = EXCLUDED.updated_at;

-- Data for table: pos_mini_modular3_restore_history (11 rows)
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('d46ff2c8-cbdd-4efb-be2d-78deb40e3bd4', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:47:20.054551+00:00', 'system', 'full', NULL, true, NULL, 7255, 6, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('cfee99fb-95fb-4ca6-9d30-7a9106328913', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:48:36.178514+00:00', 'system', 'full', NULL, true, NULL, 6775, 6, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('ab2a481b-7ba2-4935-99c1-1d07b9ad26d9', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:49:37.401882+00:00', 'system', 'full', NULL, false, 'Failed statements: 3', 7245, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('adee8e12-cb82-4c8c-920a-a9c5cc03229e', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:51:22.076096+00:00', 'system', 'full', NULL, false, 'Failed statements: 3', 7055, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('7fc394ad-d094-4f1c-898a-7b8d767cabfd', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:52:35.461462+00:00', 'system', 'full', NULL, false, 'Failed statements: 3', 7087, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('6503ffc7-c519-43c1-bdee-9a8723eb3c52', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:57:14.550814+00:00', 'system', 'full', NULL, false, 'Failed statements: 2', 6613, 6, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('80cd0207-c6b4-4672-8ff7-9e4ae16f491d', '15v2kx2zp3ymcoxduiq', '2025-07-04T14:59:19.804183+00:00', 'system', 'full', NULL, false, 'Failed statements: 2', 6518, 6, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('c9e879e4-de28-46d9-8ede-a1a806ddfffc', '0akl4fn6laafmcotdaeb', '2025-07-04T13:02:28.416021+00:00', 'system', 'full', NULL, true, NULL, 1612, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('3e08561e-ee58-4dda-bd3e-836871827130', '0akl4fn6laafmcotdaeb', '2025-07-04T14:36:49.982449+00:00', 'system', 'full', NULL, true, NULL, 1901, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('75ea3fd3-fd1b-4c82-8752-1ff7ca024605', '0akl4fn6laafmcotdaeb', '2025-07-04T14:42:16.570982+00:00', 'system', 'full', NULL, true, NULL, 7716, 5, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;
INSERT INTO pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) VALUES ('b190abb7-9c68-4a28-9a56-290d34ae69bf', '15v2kx2zp3ymcoxduiq', '2025-07-04T22:53:51.442042+00:00', 'system', 'full', NULL, true, NULL, 8731, 6, NULL)
  ON CONFLICT (id) DO UPDATE SET
    backup_id = EXCLUDED.backup_id,
    restored_at = EXCLUDED.restored_at,
    restored_by = EXCLUDED.restored_by,
    restore_type = EXCLUDED.restore_type,
    target_tables = EXCLUDED.target_tables,
    success = EXCLUDED.success,
    error_message = EXCLUDED.error_message,
    duration_ms = EXCLUDED.duration_ms,
    rows_affected = EXCLUDED.rows_affected,
    restore_point_id = EXCLUDED.restore_point_id;

-- Data for table: pos_mini_modular3_restore_points (31 rows)
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640676007_7xxs8a9vdvx', '2025-07-04T14:51:16.092+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:51:16.092+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640510167_v5gmu4ixzrj', '2025-07-04T14:48:30.357+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:48:30.357+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751669623638_aw5ekvmyig6', '2025-07-04T22:53:43.73+00:00', '{}'::jsonb, '', 'system', '2025-07-11T22:53:43.73+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751634147696_is9nixixlf', '2025-07-04T13:02:27.81+00:00', '{}'::jsonb, '', 'system', '2025-07-11T13:02:27.81+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751639808959_davp3fqyj6k', '2025-07-04T14:36:49.049+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:36:49.049+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751641028860_blsaixz2jb4', '2025-07-04T14:57:08.949+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:57:08.949+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751633606873_t9pymxb147s', '2025-07-04T12:53:26.964+00:00', '{}'::jsonb, '', 'system', '2025-07-11T12:53:26.964+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640129549_lm8jpkwt42', '2025-07-04T14:42:09.713+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:42:09.713+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751617487365_egol6m4kpoi', '2025-07-04T08:24:47.523+00:00', '{}'::jsonb, '', 'system', '2025-07-11T08:24:47.523+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751599680266_e4ylybiwohn', '2025-07-04T03:28:00.363+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:28:00.363+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751633770702_wc9scqxqvni', '2025-07-04T12:56:10.797+00:00', '{}'::jsonb, '', 'system', '2025-07-11T12:56:10.797+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751599701897_05vqy5o6r664', '2025-07-04T03:28:22.069+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:28:22.069+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751617947874_d4146ntfc9n', '2025-07-04T08:32:28.06+00:00', '{}'::jsonb, '', 'system', '2025-07-11T08:32:28.06+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751594519363_opt8v2gldo', '2025-07-04T02:01:59.46+00:00', '{}'::jsonb, '', 'system', '2025-07-11T02:01:59.46+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751594669921_pa4u2vraza', '2025-07-04T02:04:30.018+00:00', '{}'::jsonb, '', 'system', '2025-07-11T02:04:30.018+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751594729358_y5vzx79po8d', '2025-07-04T02:05:29.467+00:00', '{}'::jsonb, '', 'system', '2025-07-11T02:05:29.467+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751597076340_mv2s4qidpx', '2025-07-04T02:44:36.517+00:00', '{}'::jsonb, '', 'system', '2025-07-11T02:44:36.517+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751597626143_dgo8va2z645', '2025-07-04T02:53:46.239+00:00', '{}'::jsonb, '', 'system', '2025-07-11T02:53:46.239+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751598070832_0c1dxr1f8sh', '2025-07-04T03:01:10.931+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:01:10.931+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640570969_aa15cj8jr1i', '2025-07-04T14:49:31.066+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:49:31.066+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751641154217_n483fe0z9va', '2025-07-04T14:59:14.322+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:59:14.322+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751598400796_yz3c2wr16kc', '2025-07-04T03:06:40.987+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:06:40.987+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751598620105_jgx2qdwzgrh', '2025-07-04T03:10:20.204+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:10:20.204+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751598822849_4estkyxni6d', '2025-07-04T03:13:42.951+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:13:42.951+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751586732148_3rq1payl0ud', '2025-07-03T23:52:12.255+00:00', '{}'::jsonb, '', 'system', '2025-07-10T23:52:12.255+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751599718015_kplgdqk4t6n', '2025-07-04T03:28:38.11+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:28:38.111+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640433715_iqc0vpgpmec', '2025-07-04T14:47:13.809+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:47:13.809+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751640749325_02jp2uw2z8lq', '2025-07-04T14:52:29.422+00:00', '{}'::jsonb, '', 'system', '2025-07-11T14:52:29.422+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751586876910_il8998novgh', '2025-07-03T23:54:37.012+00:00', '{}'::jsonb, '', 'system', '2025-07-10T23:54:37.012+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751599766420_41k2fwrnvzz', '2025-07-04T03:29:26.515+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:29:26.516+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;
INSERT INTO pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) VALUES ('rp_1751599827243_si4k85c0lpa', '2025-07-04T03:30:27.342+00:00', '{}'::jsonb, '', 'system', '2025-07-11T03:30:27.342+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tables_backup = EXCLUDED.tables_backup,
    schema_backup = EXCLUDED.schema_backup,
    created_by = EXCLUDED.created_by,
    expires_at = EXCLUDED.expires_at;

-- Table pos_mini_modular3_subscription_history is empty

-- Data for table: pos_mini_modular3_subscription_plans (3 rows)
INSERT INTO pos_mini_modular3_subscription_plans (id, tier, name, price_monthly, max_users, max_products, max_warehouses, max_branches, features, is_active, created_at, updated_at) VALUES ('d70ea130-fa83-43e5-a540-353d5385de45', 'free', 'Gói Miễn Phí', 0, 3, 50, 1, 1, '["basic_pos","inventory_tracking","sales_reports"]'::jsonb, true, '2025-06-30T09:20:59.160071+00:00', '2025-06-30T09:20:59.160071+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tier = EXCLUDED.tier,
    name = EXCLUDED.name,
    price_monthly = EXCLUDED.price_monthly,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    max_warehouses = EXCLUDED.max_warehouses,
    max_branches = EXCLUDED.max_branches,
    features = EXCLUDED.features,
    is_active = EXCLUDED.is_active,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_subscription_plans (id, tier, name, price_monthly, max_users, max_products, max_warehouses, max_branches, features, is_active, created_at, updated_at) VALUES ('09523773-7c0b-4583-b5eb-5fdc8820bc4f', 'basic', 'Gói Cơ Bản', 299000, 10, 500, 2, 3, '["advanced_pos","multi_warehouse","customer_management","loyalty_program","detailed_analytics"]'::jsonb, true, '2025-06-30T09:20:59.160071+00:00', '2025-06-30T09:20:59.160071+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tier = EXCLUDED.tier,
    name = EXCLUDED.name,
    price_monthly = EXCLUDED.price_monthly,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    max_warehouses = EXCLUDED.max_warehouses,
    max_branches = EXCLUDED.max_branches,
    features = EXCLUDED.features,
    is_active = EXCLUDED.is_active,
    updated_at = EXCLUDED.updated_at;
INSERT INTO pos_mini_modular3_subscription_plans (id, tier, name, price_monthly, max_users, max_products, max_warehouses, max_branches, features, is_active, created_at, updated_at) VALUES ('41106873-3c32-41a6-9680-a6c611a81157', 'premium', 'Gói Cao Cấp', 599000, 50, 5000, 5, 10, '["enterprise_pos","multi_branch","advanced_analytics","api_access","priority_support","custom_reports","inventory_optimization"]'::jsonb, true, '2025-06-30T09:20:59.160071+00:00', '2025-06-30T09:20:59.160071+00:00')
  ON CONFLICT (id) DO UPDATE SET
    tier = EXCLUDED.tier,
    name = EXCLUDED.name,
    price_monthly = EXCLUDED.price_monthly,
    max_users = EXCLUDED.max_users,
    max_products = EXCLUDED.max_products,
    max_warehouses = EXCLUDED.max_warehouses,
    max_branches = EXCLUDED.max_branches,
    features = EXCLUDED.features,
    is_active = EXCLUDED.is_active,
    updated_at = EXCLUDED.updated_at;

-- Data for table: pos_mini_modular3_user_profiles (1 rows)
INSERT INTO pos_mini_modular3_user_profiles (id, business_id, full_name, phone, email, avatar_url, role, status, permissions, login_method, last_login_at, employee_id, hire_date, notes, created_at, updated_at) VALUES ('f1de66c9-166a-464c-89aa-bd75e1095040', NULL, 'Super Administrator', '0907136029', 'admin@giakiemso.com', NULL, 'super_admin', 'active', '[]'::jsonb, 'email', NULL, NULL, NULL, NULL, '2025-07-02T02:16:30.46745+00:00', '2025-07-04T22:53:48.217743+00:00')
  ON CONFLICT (id) DO UPDATE SET
    business_id = EXCLUDED.business_id,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    avatar_url = EXCLUDED.avatar_url,
    role = EXCLUDED.role,
    status = EXCLUDED.status,
    permissions = EXCLUDED.permissions,
    login_method = EXCLUDED.login_method,
    last_login_at = EXCLUDED.last_login_at,
    employee_id = EXCLUDED.employee_id,
    hire_date = EXCLUDED.hire_date,
    notes = EXCLUDED.notes,
    updated_at = EXCLUDED.updated_at;


-- ==================================================================================
-- EXPORT COMPLETED SUCCESSFULLY
-- ==================================================================================
-- Script generated for POS Mini Modular 3
-- Format: SUPABASE
-- 
-- All tables and data have been exported with upsert logic
-- Existing data will be updated, new data will be inserted
-- 
-- If you encounter any issues:
-- 1. Check that all required extensions are enabled
-- 2. Ensure you have proper permissions for the target schema
-- 3. Verify table names match your database schema
-- 
-- Support: Contact your system administrator
-- ==================================================================================
