-- ==================================================================================
-- QUICK FIX: Create Missing User Profile
-- ==================================================================================
-- Purpose: Create user profile for existing auth.users without profiles
-- Run this in Supabase SQL Editor after identifying missing profiles
-- ==================================================================================

-- Check current user's profile status
SELECT 
  u.id as auth_user_id,
  u.email,
  u.created_at as auth_created,
  up.id as profile_id,
  up.full_name,
  up.business_id,
  up.role
FROM auth.users u
LEFT JOIN pos_mini_modular3_user_profiles up ON up.id = u.id
WHERE u.email = 'cym_sunset@yahoo.com';  -- Replace with your email

-- ==================================================================================
-- SOLUTION 1: Create Profile for Specific User
-- ==================================================================================

-- Replace 'your-user-id' and 'your-email' with actual values
INSERT INTO pos_mini_modular3_user_profiles (
  id,
  business_id,
  full_name,
  phone,
  email,
  role,
  status,
  login_method,
  created_at,
  updated_at
) VALUES (
  '5f8d74cf-572a-4640-a565-34c5e1462f4e',  -- Replace with actual user ID
  NULL,  -- Will be assigned when user creates/joins business
  'User Name',  -- Replace with actual name
  NULL,
  'cym_sunset@yahoo.com',  -- Replace with actual email
  'business_owner',  -- Default role
  'active',
  'email',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  updated_at = NOW();

-- ==================================================================================
-- SOLUTION 2: Create Profiles for All Missing Users (Batch)
-- ==================================================================================

-- This will create profiles for all auth.users who don't have profiles yet
INSERT INTO pos_mini_modular3_user_profiles (
  id,
  business_id,
  full_name,
  phone,
  email,
  role,
  status,
  login_method,
  created_at,
  updated_at
)
SELECT 
  u.id,
  NULL as business_id,
  COALESCE(
    u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name',
    split_part(u.email, '@', 1)
  ) as full_name,
  u.phone,
  u.email,
  'business_owner' as role,
  'active' as status,
  CASE 
    WHEN u.phone IS NOT NULL AND u.email IS NULL THEN 'phone'
    ELSE 'email'
  END as login_method,
  u.created_at,
  NOW() as updated_at
FROM auth.users u
LEFT JOIN pos_mini_modular3_user_profiles up ON up.id = u.id
WHERE up.id IS NULL  -- Only users without profiles
  AND u.deleted_at IS NULL;  -- Only active users

-- ==================================================================================
-- VERIFICATION: Check if profiles were created
-- ==================================================================================

SELECT 
  'Total auth.users' as metric,
  COUNT(*) as count
FROM auth.users 
WHERE deleted_at IS NULL

UNION ALL

SELECT 
  'Total user_profiles' as metric,
  COUNT(*) as count
FROM pos_mini_modular3_user_profiles

UNION ALL

SELECT 
  'Missing profiles' as metric,
  COUNT(*) as count
FROM auth.users u
LEFT JOIN pos_mini_modular3_user_profiles up ON up.id = u.id
WHERE up.id IS NULL AND u.deleted_at IS NULL;

-- ==================================================================================
-- TEST: Verify Enhanced Auth Function Works
-- ==================================================================================

-- Test with your specific user ID
SELECT pos_mini_modular3_get_user_with_business_complete('5f8d74cf-572a-4640-a565-34c5e1462f4e'::uuid);

-- Should now return success=true with profile_exists=true
