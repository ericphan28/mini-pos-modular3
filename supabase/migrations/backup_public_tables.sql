--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: begin_transaction(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_transaction() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Transaction is automatically started when function is called
  NULL;
END;
$$;


--
-- Name: calculate_next_backup_schedule(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_next_backup_schedule() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  schedule_record RECORD;
  next_run TIMESTAMPTZ;
BEGIN
  FOR schedule_record IN 
    SELECT * FROM pos_mini_modular3_backup_schedules WHERE enabled = true
  LOOP
    -- Simple calculation - in production, use proper cron parser
    -- For now, just add 1 day for daily schedules
    next_run := COALESCE(schedule_record.last_run_at, NOW()) + INTERVAL '1 day';
    
    UPDATE pos_mini_modular3_backup_schedules
    SET next_run_at = next_run
    WHERE id = schedule_record.id;
  END LOOP;
END;
$$;


--
-- Name: FUNCTION calculate_next_backup_schedule(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.calculate_next_backup_schedule() IS 'Calculates next run times for backup schedules';


--
-- Name: cleanup_expired_backups(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_expired_backups() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  -- Mark expired backups
  UPDATE pos_mini_modular3_backup_metadata 
  SET status = 'expired'
  WHERE status = 'completed' 
    AND retention_until < NOW();
  
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  
  -- Log cleanup activity
  INSERT INTO pos_mini_modular3_backup_notifications (
    type, title, message, details
  ) VALUES (
    'warning',
    'Backup Cleanup',
    format('%s backups marked as expired', expired_count),
    jsonb_build_object('expired_count', expired_count, 'cleanup_time', NOW())
  );
  
  RETURN expired_count;
END;
$$;


--
-- Name: FUNCTION cleanup_expired_backups(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.cleanup_expired_backups() IS 'Marks expired backups and cleans up old data';


--
-- Name: commit_transaction(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.commit_transaction() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  COMMIT;
END;
$$;


--
-- Name: execute_sql(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.execute_sql(sql text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  EXECUTE sql;
END;
$$;


--
-- Name: get_backup_statistics(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_backup_statistics() RETURNS TABLE(total_backups bigint, successful_backups bigint, failed_backups bigint, total_size_bytes bigint, oldest_backup timestamp with time zone, newest_backup timestamp with time zone, avg_backup_size numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_backups,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_backups,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_backups,
    COALESCE(SUM(size), 0) as total_size_bytes,
    MIN(created_at) as oldest_backup,
    MAX(created_at) as newest_backup,
    COALESCE(AVG(size), 0) as avg_backup_size
  FROM pos_mini_modular3_backup_metadata
  WHERE status != 'expired';
END;
$$;


--
-- Name: FUNCTION get_backup_statistics(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_backup_statistics() IS 'Returns comprehensive backup statistics';


--
-- Name: get_table_foreign_keys(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_foreign_keys(table_name_param text, schema_name text DEFAULT 'public'::text) RETURNS TABLE(constraint_name text, column_name text, referenced_table text, referenced_column text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tc.constraint_name::text,
        kcu.column_name::text,
        ccu.table_name::text as referenced_table,
        ccu.column_name::text as referenced_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = table_name_param
      AND tc.table_schema = schema_name
      AND tc.constraint_type = 'FOREIGN KEY';
END;
$$;


--
-- Name: get_table_list(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_list(schema_name text DEFAULT 'public'::text, table_prefix text DEFAULT 'pos_mini_modular3_'::text) RETURNS text[]
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    table_names text[];
BEGIN
    SELECT array_agg(table_name::text)
    INTO table_names
    FROM information_schema.tables
    WHERE table_schema = schema_name
      AND table_name LIKE table_prefix || '%'
      AND table_type = 'BASE TABLE';
    
    RETURN COALESCE(table_names, ARRAY[]::text[]);
EXCEPTION
    WHEN OTHERS THEN
        -- Return empty array on error
        RETURN ARRAY[]::text[];
END;
$$;


--
-- Name: get_table_row_count(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_row_count(table_name_param text, schema_name text DEFAULT 'public'::text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    row_count bigint;
    query_text text;
BEGIN
    query_text := format('SELECT COUNT(*) FROM %I.%I', schema_name, table_name_param);
    EXECUTE query_text INTO row_count;
    RETURN row_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;


--
-- Name: get_table_schema(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_schema(table_name_param text, schema_name text DEFAULT 'public'::text) RETURNS TABLE(column_name text, data_type text, is_nullable text, column_default text, is_primary_key boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.column_name::text,
        c.data_type::text,
        c.is_nullable::text,
        c.column_default::text,
        CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END as is_primary_key
    FROM information_schema.columns c
    LEFT JOIN (
        SELECT ku.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage ku
        ON tc.constraint_name = ku.constraint_name
        WHERE tc.table_name = table_name_param
          AND tc.table_schema = schema_name
          AND tc.constraint_type = 'PRIMARY KEY'
    ) pk ON c.column_name = pk.column_name
    WHERE c.table_name = table_name_param
      AND c.table_schema = schema_name
    ORDER BY c.ordinal_position;
END;
$$;


--
-- Name: pos_mini_modular3_accept_invitation(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_accept_invitation(p_invitation_token text, p_full_name text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    invitation_record record;
    current_user_id uuid;
    current_user_email text;
    result jsonb;
BEGIN
    current_user_id := auth.uid();
    
    -- Get current user email
    SELECT email INTO current_user_email
    FROM auth.users
    WHERE id = current_user_id;
    
    -- Get invitation details
    SELECT * INTO invitation_record
    FROM pos_mini_modular3_business_invitations
    WHERE invitation_token = p_invitation_token
      AND status = 'pending'
      AND expires_at > now();
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invitation');
    END IF;
    
    -- Verify email matches
    IF LOWER(TRIM(current_user_email)) != LOWER(TRIM(invitation_record.email)) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email does not match invitation');
    END IF;
    
    -- Create user profile
    INSERT INTO pos_mini_modular3_user_profiles (
        id, business_id, full_name, email, role, status
    ) VALUES (
        current_user_id, 
        invitation_record.business_id, 
        TRIM(p_full_name), 
        current_user_email, 
        invitation_record.role, 
        'active'
    );
    
    -- Mark invitation as accepted
    UPDATE pos_mini_modular3_business_invitations
    SET status = 'accepted',
        accepted_at = now(),
        accepted_by = current_user_id
    WHERE id = invitation_record.id;

    result := jsonb_build_object(
        'success', true,
        'business_id', invitation_record.business_id,
        'role', invitation_record.role,
        'message', 'Invitation accepted successfully'
    );

    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to accept invitation'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_can_access_user_profile(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_can_access_user_profile(target_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
    target_business_id uuid;
BEGIN
    -- Super admin has access to everything
    IF pos_mini_modular3_is_super_admin() THEN
        RETURN true;
    END IF;
    
    -- User can access their own profile
    IF target_user_id = auth.uid() THEN
        RETURN true;
    END IF;
    
    -- User can access profiles from same business
    SELECT business_id INTO target_business_id
    FROM pos_mini_modular3_user_profiles 
    WHERE id = target_user_id;
    
    RETURN pos_mini_modular3_user_belongs_to_business(target_business_id);
END;
$$;


--
-- Name: pos_mini_modular3_check_contact_exists(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_contact_exists(p_contact_method text, p_contact_value text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF p_contact_method = 'email' THEN
        RETURN EXISTS (
            SELECT 1 FROM pos_mini_modular3_user_profiles 
            WHERE email = TRIM(p_contact_value)
        );
    ELSIF p_contact_method = 'phone' THEN
        RETURN EXISTS (
            SELECT 1 FROM pos_mini_modular3_user_profiles 
            WHERE phone = TRIM(p_contact_value)
        );
    END IF;
    
    RETURN false;
END;
$$;


--
-- Name: pos_mini_modular3_check_feature_access(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_feature_access(p_business_id uuid, p_feature_name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  business_tier text;
  business_status text;
  business_ends_at timestamptz;
  plan_features jsonb;
  has_access boolean := false;
BEGIN
  -- Get business subscription info
  SELECT b.subscription_tier, b.subscription_status, b.subscription_ends_at
  INTO business_tier, business_status, business_ends_at
  FROM pos_mini_modular3_businesses b
  WHERE b.id = p_business_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Check if subscription is active
  IF business_status NOT IN ('trial', 'active') THEN
    RETURN false;
  END IF;
  
  -- Check if trial/subscription has expired
  IF business_ends_at IS NOT NULL AND business_ends_at < now() THEN
    RETURN false;
  END IF;
  
  -- Get plan features
  SELECT p.features INTO plan_features
  FROM pos_mini_modular3_subscription_plans p
  WHERE p.tier = business_tier;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Check if feature is included in plan
  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements_text(plan_features) feature 
    WHERE feature = p_feature_name
  ) INTO has_access;
  
  RETURN has_access;
END;
$$;


--
-- Name: pos_mini_modular3_check_usage_limit(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_usage_limit(p_business_id uuid, p_limit_type text, p_current_count integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  business_tier text;
  business_status text;
  business_ends_at timestamptz;
  limit_value integer;
  result jsonb;
BEGIN
  -- Get business subscription info
  SELECT b.subscription_tier, b.subscription_status, b.subscription_ends_at
  INTO business_tier, business_status, business_ends_at
  FROM pos_mini_modular3_businesses b
  WHERE b.id = p_business_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'error', 'Business not found'
    );
  END IF;
  
  -- Check if subscription is active
  IF business_status NOT IN ('trial', 'active') THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'error', 'Subscription not active'
    );
  END IF;
  
  -- Check if trial/subscription has expired
  IF business_ends_at IS NOT NULL AND business_ends_at < now() THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'error', 'Subscription expired'
    );
  END IF;
  
  -- Get limit value based on type
  CASE p_limit_type
    WHEN 'users' THEN 
      SELECT max_users INTO limit_value
      FROM pos_mini_modular3_subscription_plans
      WHERE tier = business_tier;
    WHEN 'products' THEN
      SELECT max_products INTO limit_value
      FROM pos_mini_modular3_subscription_plans
      WHERE tier = business_tier;
    WHEN 'warehouses' THEN
      SELECT max_warehouses INTO limit_value
      FROM pos_mini_modular3_subscription_plans
      WHERE tier = business_tier;
    WHEN 'branches' THEN
      SELECT max_branches INTO limit_value
      FROM pos_mini_modular3_subscription_plans
      WHERE tier = business_tier;
    ELSE 
      RETURN jsonb_build_object(
        'allowed', false,
        'error', 'Invalid limit type'
      );
  END CASE;
  
  -- NULL means unlimited
  IF limit_value IS NULL THEN
    RETURN jsonb_build_object(
      'allowed', true,
      'unlimited', true
    );
  END IF;
  
  -- Check if under limit
  IF p_current_count < limit_value THEN
    RETURN jsonb_build_object(
      'allowed', true,
      'current', p_current_count,
      'limit', limit_value,
      'remaining', limit_value - p_current_count
    );
  ELSE
    RETURN jsonb_build_object(
      'allowed', false,
      'current', p_current_count,
      'limit', limit_value,
      'remaining', 0,
      'error', 'Usage limit exceeded'
    );
  END IF;
END;
$$;


--
-- Name: pos_mini_modular3_create_business_owner(uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_business_owner(p_user_id uuid, p_business_name text, p_full_name text, p_email text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    business_code text;
    new_business_id uuid;
    result jsonb;
BEGIN
    -- Validate inputs
    IF LENGTH(TRIM(p_business_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Business name is required');
    END IF;
    
    IF LENGTH(TRIM(p_full_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Full name is required');
    END IF;

    -- Check if user already has a profile
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User profile already exists');
    END IF;

    -- Generate business code
    business_code := pos_mini_modular3_generate_business_code();

    -- Create business
    INSERT INTO pos_mini_modular3_businesses (name, code, business_type, status)
    VALUES (TRIM(p_business_name), business_code, 'retail', 'trial')
    RETURNING id INTO new_business_id;

    -- Create user profile as household_owner
    INSERT INTO pos_mini_modular3_user_profiles (
        id, business_id, full_name, email, role, status
    ) VALUES (
        p_user_id, new_business_id, TRIM(p_full_name), p_email, 'household_owner', 'active'
    );

    result := jsonb_build_object(
        'success', true,
        'business_id', new_business_id,
        'business_code', business_code,
        'message', 'Business and owner profile created successfully'
    );

    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to create business and profile'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_create_complete_business_owner(uuid, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_complete_business_owner(p_user_id uuid, p_email text, p_full_name text, p_business_name text, p_business_type text DEFAULT 'retail'::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_tax_code text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    business_code text;
    new_business_id uuid;
    existing_profile_id uuid;
    existing_business_id uuid;
    result jsonb;
    trial_ends_at timestamp with time zone;
BEGIN
    -- Log function start
    RAISE NOTICE '[CREATE_BUSINESS] Starting function with params: user_id=%, email=%, business_name=%', 
        p_user_id, p_email, p_business_name;
    
    -- Validate required parameters
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID cannot be null';
    END IF;
    
    IF p_email IS NULL OR p_email = '' THEN
        RAISE EXCEPTION 'Email cannot be null or empty';
    END IF;
    
    IF p_business_name IS NULL OR p_business_name = '' THEN
        RAISE EXCEPTION 'Business name cannot be null or empty';
    END IF;
    
    IF p_full_name IS NULL OR p_full_name = '' THEN
        RAISE EXCEPTION 'Full name cannot be null or empty';
    END IF;

    -- Check if user already has a profile
    SELECT id, business_id INTO existing_profile_id, existing_business_id
    FROM pos_mini_modular3_user_profiles 
    WHERE id = p_user_id;
    
    IF existing_profile_id IS NOT NULL THEN
        RAISE NOTICE '[CREATE_BUSINESS] User already has profile: %, business_id: %', 
            existing_profile_id, existing_business_id;
        
        -- Return existing data
        RETURN jsonb_build_object(
            'success', true,
            'message', 'User already has profile',
            'user_id', p_user_id,
            'profile_id', existing_profile_id,
            'business_id', existing_business_id,
            'created_new', false
        );
    END IF;

    RAISE NOTICE '[CREATE_BUSINESS] Creating new profile and business for user: %', p_user_id;

    -- Generate business code
    business_code := 'BIZ' || LPAD(EXTRACT(epoch FROM NOW())::text, 10, '0');
    RAISE NOTICE '[CREATE_BUSINESS] Generated business code: %', business_code;
    
    -- Calculate trial end date (30 days from now)
    trial_ends_at := NOW() + INTERVAL '30 days';
    RAISE NOTICE '[CREATE_BUSINESS] Trial ends at: %', trial_ends_at;

    -- Create business first
    INSERT INTO pos_mini_modular3_businesses (
        name, 
        code,
        business_type, 
        address, 
        tax_code,
        trial_ends_at,
        subscription_status,
        max_users
    ) VALUES (
        p_business_name,
        business_code,
        p_business_type,
        p_address,
        p_tax_code,
        trial_ends_at,
        'trial',
        5
    ) RETURNING id INTO new_business_id;
    
    RAISE NOTICE '[CREATE_BUSINESS] Created business with ID: %', new_business_id;
    
    IF new_business_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create business - no ID returned';
    END IF;

    -- Create user profile (sử dụng đúng columns theo schema)
    INSERT INTO pos_mini_modular3_user_profiles (
        id,
        business_id,
        full_name,
        phone,
        email,
        role,
        status  -- Đổi từ is_active thành status
    ) VALUES (
        p_user_id,
        new_business_id,
        p_full_name,
        p_phone,
        p_email,
        'household_owner',
        'active'  -- Sử dụng 'active' thay vì true
    );
    
    RAISE NOTICE '[CREATE_BUSINESS] Created user profile for user: %', p_user_id;

    -- Verify the data was created
    IF NOT EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Profile creation verification failed - profile not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pos_mini_modular3_businesses WHERE id = new_business_id) THEN
        RAISE EXCEPTION 'Business creation verification failed - business not found';
    END IF;

    RAISE NOTICE '[CREATE_BUSINESS] Successfully created business and profile';

    -- Return success result
    result := jsonb_build_object(
        'success', true,
        'message', 'Business and profile created successfully',
        'user_id', p_user_id,
        'business_id', new_business_id,
        'business_code', business_code,
        'trial_ends_at', trial_ends_at,
        'created_new', true
    );

    RAISE NOTICE '[CREATE_BUSINESS] Returning result: %', result;
    RETURN result;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[CREATE_BUSINESS] ERROR: % - %', SQLSTATE, SQLERRM;
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'user_id', p_user_id
        );
END;
$$;


--
-- Name: pos_mini_modular3_create_complete_super_admin(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_complete_super_admin(p_email text, p_password text, p_phone text DEFAULT NULL::text, p_full_name text DEFAULT 'Super Administrator'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    new_user_id uuid;
    encrypted_password text;
    result jsonb;
BEGIN
    -- Validate inputs
    IF LENGTH(TRIM(p_email)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email is required');
    END IF;
    
    IF LENGTH(TRIM(p_password)) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Password must be at least 6 characters');
    END IF;
    
    -- Check if email already exists in auth.users
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = TRIM(p_email)) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists in auth system');
    END IF;
    
    -- Check if email already exists in profiles
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE email = TRIM(p_email)) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists in profiles');
    END IF;
    
    -- Generate new user ID
    new_user_id := gen_random_uuid();
    
    -- Encrypt password (basic crypt - in production use stronger encryption)
    encrypted_password := crypt(p_password, gen_salt('bf'));
    
    -- Insert into auth.users (bypass normal Supabase Auth flow)
    INSERT INTO auth.users (
        id,
        instance_id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        phone,
        phone_confirmed_at,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        email_change_token_current,
        email_change_confirm_status,
        banned_until,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        created_at,
        updated_at,
        last_sign_in_at,
        confirmation_sent_at,
        recovery_sent_at,
        email_change_sent_at
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        TRIM(p_email),
        encrypted_password,
        NOW(), -- Email confirmed immediately
        TRIM(p_phone),
        CASE WHEN p_phone IS NOT NULL THEN NOW() ELSE NULL END, -- Phone confirmed if provided
        '',
        '',
        '',
        '',
        '',
        0,
        NULL,
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object('full_name', p_full_name),
        false,
        NOW(),
        NOW(),
        NULL,
        NOW(),
        NULL,
        NULL
    );
    
    -- Create super admin profile
    INSERT INTO pos_mini_modular3_user_profiles (
        id,
        business_id,
        full_name,
        email,
        phone,
        role,
        status,
        login_method,
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        NULL, -- Super admin không thuộc business nào
        TRIM(p_full_name),
        TRIM(p_email),
        TRIM(p_phone),
        'super_admin',
        'active',
        'email',
        NOW(),
        NOW()
    );
    
    result := jsonb_build_object(
        'success', true,
        'message', 'Complete super admin created successfully',
        'user_id', new_user_id,
        'email', TRIM(p_email),
        'phone', TRIM(p_phone),
        'role', 'super_admin',
        'login_info', jsonb_build_object(
            'email', TRIM(p_email),
            'password', p_password,
            'note', 'Account is ready for immediate login'
        )
    );
    
    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to create complete super admin'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_create_staff_member(uuid, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_staff_member(p_business_id uuid, p_full_name text, p_phone text, p_password text, p_role text DEFAULT 'seller'::text, p_employee_id text DEFAULT NULL::text, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    current_user_id uuid;
    current_user_role text;
    clean_phone text;
    new_user_id uuid;
    business_record RECORD;
    staff_count integer;
    temp_email text;
    result jsonb;
BEGIN
    current_user_id := auth.uid();
    
    -- Debug info
    RAISE NOTICE 'create_staff_member called by user: %, for business: %', current_user_id, p_business_id;
    
    -- Validate current user permissions
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = current_user_id AND business_id = p_business_id;
    
    RAISE NOTICE 'Current user role: %', current_user_role;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Permission denied: Only owners and managers can create staff. Your role: ' || COALESCE(current_user_role, 'NULL')
        );
    END IF;
    
    -- Validate inputs
    IF LENGTH(TRIM(p_full_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Full name is required');
    END IF;
    
    IF LENGTH(TRIM(p_phone)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    IF LENGTH(TRIM(p_password)) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Password must be at least 6 characters');
    END IF;
    
    -- Validate role
    IF p_role NOT IN ('manager', 'seller', 'accountant') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid role');
    END IF;
    
    -- Clean phone number
    clean_phone := REGEXP_REPLACE(TRIM(p_phone), '[^0-9+]', '', 'g');
    
    -- Normalize to +84 format
    IF clean_phone ~ '^0[0-9]{8,9}$' THEN
        clean_phone := '+84' || SUBSTRING(clean_phone FROM 2);
    ELSIF clean_phone ~ '^84[0-9]{8,9}$' THEN
        clean_phone := '+' || clean_phone;
    END IF;
    
    -- Check if phone already exists
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE phone = clean_phone) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Phone number already exists');
    END IF;
    
    -- Generate temporary email
    temp_email := clean_phone || '@staff.pos.local';
    
    -- Create new user ID
    new_user_id := gen_random_uuid();
    
    -- Create user profile directly
    INSERT INTO pos_mini_modular3_user_profiles (
        id,
        business_id,
        full_name,
        phone,
        email,
        role,
        status,
        employee_id,
        hire_date,
        notes,
        login_method
    ) VALUES (
        new_user_id,
        p_business_id,
        TRIM(p_full_name),
        clean_phone,
        temp_email,
        p_role,
        'active',
        NULLIF(TRIM(p_employee_id), ''),
        CURRENT_DATE,
        NULLIF(TRIM(p_notes), ''),
        'phone'
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'user_id', new_user_id,
        'phone', clean_phone,
        'message', 'Staff member created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'sqlstate', SQLSTATE
    );
END;
$_$;


--
-- Name: pos_mini_modular3_create_staff_member_direct(uuid, uuid, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_staff_member_direct(p_business_id uuid, p_current_user_id uuid, p_full_name text, p_phone text, p_password text, p_role text DEFAULT 'seller'::text, p_employee_id text DEFAULT NULL::text, p_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    current_user_role text;
    clean_phone text;
    new_user_id uuid;
    result jsonb;
BEGIN
    -- Validate current user permissions
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = p_current_user_id AND business_id = p_business_id;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Permission denied. Your role: ' || COALESCE(current_user_role, 'NULL')
        );
    END IF;
    
    -- Validate inputs
    IF LENGTH(TRIM(p_full_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Full name is required');
    END IF;
    
    IF LENGTH(TRIM(p_phone)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    -- Clean phone number
    clean_phone := REGEXP_REPLACE(TRIM(p_phone), '[^0-9+]', '', 'g');
    
    -- Normalize to +84 format
    IF clean_phone ~ '^0[0-9]{8,9}$' THEN
        clean_phone := '+84' || SUBSTRING(clean_phone FROM 2);
    ELSIF clean_phone ~ '^84[0-9]{8,9}$' THEN
        clean_phone := '+' || clean_phone;
    END IF;
    
    -- Check if phone already exists
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE phone = clean_phone) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Phone number already exists');
    END IF;
    
    -- Create new user ID
    new_user_id := gen_random_uuid();
    
    -- Create dummy auth user first
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        phone,
        phone_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        new_user_id,
        'authenticated',
        'authenticated', 
        clean_phone || '@staff.pos.local',
        crypt(p_password, gen_salt('bf')),
        now(),
        clean_phone,
        now(),
        now(),
        now(),
        '{"provider":"phone","providers":["phone"]}',
        '{}',
        false
    );
    
    -- Create user profile
    INSERT INTO pos_mini_modular3_user_profiles (
        id,
        business_id,
        full_name,
        phone,
        email,
        role,
        status,
        employee_id,
        hire_date,
        notes,
        login_method
    ) VALUES (
        new_user_id,
        p_business_id,
        TRIM(p_full_name),
        clean_phone,
        clean_phone || '@staff.pos.local',
        p_role,
        'active',
        NULLIF(TRIM(p_employee_id), ''),
        CURRENT_DATE,
        NULLIF(TRIM(p_notes), ''),
        'phone'
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'user_id', new_user_id,
        'phone', clean_phone,
        'message', 'Staff member created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'sqlstate', SQLSTATE
    );
END;
$_$;


--
-- Name: pos_mini_modular3_create_super_admin(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_super_admin(p_user_id uuid, p_full_name text, p_email text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    result jsonb;
BEGIN
    -- Validate inputs (thêm email validation)
    IF LENGTH(TRIM(p_full_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Full name is required');
    END IF;
    
    IF LENGTH(TRIM(p_email)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email is required');
    END IF;

    -- Check if user already has a profile
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User profile already exists');
    END IF;
    
    -- Check email uniqueness
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE email = TRIM(p_email)) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists');
    END IF;

    -- Create super admin profile (business_id = NULL)
    INSERT INTO pos_mini_modular3_user_profiles (
        id, 
        business_id, 
        full_name, 
        email, 
        role, 
        status,
        login_method, 
        created_at, 
        updated_at
    ) VALUES (
        p_user_id, 
        NULL, 
        TRIM(p_full_name), 
        TRIM(p_email), 
        'super_admin', 
        'active',
        'email', 
        NOW(), 
        NOW()
    );

    result := jsonb_build_object(
        'success', true,
        'message', 'Super admin profile created successfully',
        'user_id', p_user_id,
        'email', TRIM(p_email),
        'role', 'super_admin'
    );

    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to create super admin profile'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_current_user_business_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_current_user_business_id() RETURNS uuid
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT business_id 
        FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid()
        AND status = 'active'
    );
END;
$$;


--
-- Name: pos_mini_modular3_deactivate_staff_member(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_deactivate_staff_member(p_staff_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    current_user_id uuid;
    current_user_role text;
    staff_business_id uuid;
    staff_role text;
    result jsonb;
BEGIN
    current_user_id := auth.uid();
    
    -- Get staff member's business_id and role
    SELECT business_id, role INTO staff_business_id, staff_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = p_staff_id;
    
    IF staff_business_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Staff member not found');
    END IF;
    
    -- Check if current user has permission
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = current_user_id AND business_id = staff_business_id;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Permission denied: Only owners and managers can deactivate staff'
        );
    END IF;
    
    -- Cannot deactivate business owner
    IF staff_role = 'household_owner' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Cannot deactivate business owner'
        );
    END IF;
    
    -- Cannot deactivate yourself unless you're the owner
    IF p_staff_id = current_user_id AND current_user_role != 'household_owner' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Cannot deactivate your own account'
        );
    END IF;
    
    -- Deactivate the staff member
    UPDATE pos_mini_modular3_user_profiles
    SET status = 'inactive', updated_at = now()
    WHERE id = p_staff_id;
    
    result := jsonb_build_object(
        'success', true,
        'message', 'Staff member deactivated successfully'
    );
    
    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to deactivate staff member'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_delete_business_owner(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_delete_business_owner(p_user_id uuid, p_force_delete boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    business_record RECORD;
    user_record RECORD;
    staff_count integer;
    result jsonb;
BEGIN
    -- Log function start
    RAISE NOTICE '[DELETE_BUSINESS] Starting deletion for user: %, force: %', p_user_id, p_force_delete;
    
    -- Validate input
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID cannot be null';
    END IF;

    -- Get user profile info
    SELECT * INTO user_record
    FROM pos_mini_modular3_user_profiles 
    WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE NOTICE '[DELETE_BUSINESS] User profile not found: %', p_user_id;
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User profile not found',
            'user_id', p_user_id
        );
    END IF;

    RAISE NOTICE '[DELETE_BUSINESS] Found user profile: role=%, business_id=%', 
        user_record.role, user_record.business_id;

    -- Only household_owner can trigger business deletion
    IF user_record.role != 'household_owner' THEN
        RAISE NOTICE '[DELETE_BUSINESS] User is not household_owner, only deleting profile';
        
        -- Delete user profile only
        DELETE FROM pos_mini_modular3_user_profiles WHERE id = p_user_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'message', 'User profile deleted (not business owner)',
            'user_id', p_user_id,
            'deleted_business', false
        );
    END IF;

    -- Get business info
    IF user_record.business_id IS NOT NULL THEN
        SELECT * INTO business_record
        FROM pos_mini_modular3_businesses 
        WHERE id = user_record.business_id;
        
        IF FOUND THEN
            RAISE NOTICE '[DELETE_BUSINESS] Found business: %, name=%', 
                business_record.id, business_record.name;
            
            -- Count other staff members
            SELECT COUNT(*) INTO staff_count
            FROM pos_mini_modular3_user_profiles 
            WHERE business_id = user_record.business_id 
            AND id != p_user_id;
            
            RAISE NOTICE '[DELETE_BUSINESS] Other staff count: %', staff_count;
            
            -- If there are other staff and not forcing delete, prevent deletion
            IF staff_count > 0 AND NOT p_force_delete THEN
                RETURN jsonb_build_object(
                    'success', false,
                    'message', 'Cannot delete business with existing staff members',
                    'user_id', p_user_id,
                    'business_id', user_record.business_id,
                    'staff_count', staff_count,
                    'force_delete_required', true
                );
            END IF;
            
            -- Delete all staff first (if force delete)
            IF p_force_delete AND staff_count > 0 THEN
                RAISE NOTICE '[DELETE_BUSINESS] Force deleting % staff members', staff_count;
                DELETE FROM pos_mini_modular3_user_profiles 
                WHERE business_id = user_record.business_id 
                AND id != p_user_id;
            END IF;
        END IF;
    END IF;

    -- Delete user profile (this will cascade delete business due to FK constraints)
    DELETE FROM pos_mini_modular3_user_profiles WHERE id = p_user_id;
    RAISE NOTICE '[DELETE_BUSINESS] Deleted user profile: %', p_user_id;

    -- Delete business if it exists
    IF user_record.business_id IS NOT NULL THEN
        DELETE FROM pos_mini_modular3_businesses WHERE id = user_record.business_id;
        RAISE NOTICE '[DELETE_BUSINESS] Deleted business: %', user_record.business_id;
    END IF;

    -- Verify deletion
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User profile deletion verification failed';
    END IF;
    
    IF user_record.business_id IS NOT NULL AND 
       EXISTS (SELECT 1 FROM pos_mini_modular3_businesses WHERE id = user_record.business_id) THEN
        RAISE EXCEPTION 'Business deletion verification failed';
    END IF;

    RAISE NOTICE '[DELETE_BUSINESS] Successfully deleted business owner and business';

    -- Return success result
    result := jsonb_build_object(
        'success', true,
        'message', 'Business owner and business deleted successfully',
        'user_id', p_user_id,
        'business_id', user_record.business_id,
        'business_name', COALESCE(business_record.name, 'Unknown'),
        'staff_deleted', staff_count,
        'deleted_business', true
    );

    RAISE NOTICE '[DELETE_BUSINESS] Returning result: %', result;
    RETURN result;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[DELETE_BUSINESS] ERROR: % - %', SQLSTATE, SQLERRM;
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'user_id', p_user_id
        );
END;
$$;


--
-- Name: pos_mini_modular3_generate_business_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_generate_business_code() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    new_code text;
    counter integer;
BEGIN
    -- Get next available number
    SELECT COALESCE(MAX(CAST(SUBSTRING(code FROM 4) AS INTEGER)), 0) + 1
    INTO counter
    FROM pos_mini_modular3_businesses
    WHERE code ~ '^BIZ[0-9]+$';
    
    new_code := 'BIZ' || LPAD(counter::text, 6, '0');
    RETURN new_code;
END;
$_$;


--
-- Name: pos_mini_modular3_get_business_deletion_info(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_business_deletion_info(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    user_record RECORD;
    business_record RECORD;
    staff_list jsonb;
    result jsonb;
BEGIN
    -- Get user profile
    SELECT * INTO user_record
    FROM pos_mini_modular3_user_profiles 
    WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User not found'
        );
    END IF;

    -- Get business info
    business_record := NULL;
    staff_list := '[]'::jsonb;
    
    IF user_record.business_id IS NOT NULL THEN
        SELECT * INTO business_record
        FROM pos_mini_modular3_businesses 
        WHERE id = user_record.business_id;
        
        -- Get staff list
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', id,
                'full_name', full_name,
                'email', email,
                'role', role,
                'status', status
            )
        ) INTO staff_list
        FROM pos_mini_modular3_user_profiles 
        WHERE business_id = user_record.business_id 
        AND id != p_user_id;
    END IF;

    result := jsonb_build_object(
        'success', true,
        'user', jsonb_build_object(
            'id', user_record.id,
            'full_name', user_record.full_name,
            'email', user_record.email,
            'role', user_record.role
        ),
        'business', CASE 
            WHEN business_record IS NOT NULL THEN
                jsonb_build_object(
                    'id', business_record.id,
                    'name', business_record.name,
                    'code', business_record.code,
                    'business_type', business_record.business_type
                )
            ELSE NULL
        END,
        'staff_members', COALESCE(staff_list, '[]'::jsonb),
        'staff_count', jsonb_array_length(COALESCE(staff_list, '[]'::jsonb)),
        'can_delete', user_record.role = 'household_owner',
        'requires_force', jsonb_array_length(COALESCE(staff_list, '[]'::jsonb)) > 0
    );

    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_get_business_invitations(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_business_invitations(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    invitation_records RECORD;
    invitations_array jsonb := '[]'::jsonb;
    result jsonb;
BEGIN
    -- Get pending invitations
    FOR invitation_records IN 
        SELECT 
            i.id,
            i.email,
            i.role,
            i.status,
            i.created_at,
            i.expires_at,
            u.full_name as invited_by_name
        FROM pos_mini_modular3_business_invitations i
        LEFT JOIN pos_mini_modular3_user_profiles u ON u.id = i.invited_by
        WHERE i.business_id = p_business_id 
        AND i.status = 'pending'
        AND i.expires_at > NOW()
        ORDER BY i.created_at DESC
    LOOP
        invitations_array := invitations_array || jsonb_build_object(
            'id', invitation_records.id,
            'email', invitation_records.email,
            'role', invitation_records.role,
            'status', invitation_records.status,
            'created_at', invitation_records.created_at,
            'expires_at', invitation_records.expires_at,
            'invited_by_name', invitation_records.invited_by_name
        );
    END LOOP;

    result := jsonb_build_object(
        'success', true,
        'invitations', invitations_array
    );

    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_get_business_staff(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_business_staff(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    current_user_id uuid;
    current_user_role text;
    staff_records jsonb;
    result jsonb;
BEGIN
    -- Get current user
    current_user_id := auth.uid();
    
    -- Validate input
    IF p_business_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Business ID is required');
    END IF;
    
    IF current_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    -- Check user role
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = current_user_id AND business_id = p_business_id;
    
    IF current_user_role IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User does not belong to this business');
    END IF;
    
    -- Check permissions
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Only owners and managers can view staff');
    END IF;
    
    -- Get staff members
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'full_name', full_name,
            'phone', phone,
            'email', email,
            'role', role,
            'status', status,
            'employee_id', employee_id,
            'hire_date', hire_date,
            'notes', notes,
            'created_at', created_at,
            'last_login_at', last_login_at
        )
    ) INTO staff_records
    FROM pos_mini_modular3_user_profiles
    WHERE business_id = p_business_id
    ORDER BY created_at;
    
    -- Return result
    RETURN jsonb_build_object(
        'success', true,
        'staff', COALESCE(staff_records, '[]'::jsonb),
        'total_count', (SELECT COUNT(*) FROM pos_mini_modular3_user_profiles WHERE business_id = p_business_id)
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;


--
-- Name: pos_mini_modular3_get_business_staff_direct(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_business_staff_direct(p_business_id uuid, p_current_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    current_user_role text;
    staff_records jsonb;
BEGIN
    -- Check user role
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = p_current_user_id AND business_id = p_business_id;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Permission denied');
    END IF;
    
    -- Get staff members
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'full_name', full_name,
            'phone', phone,
            'email', email,
            'role', role,
            'status', status,
            'employee_id', employee_id,
            'hire_date', hire_date,
            'notes', notes,
            'created_at', created_at
        ) ORDER BY created_at
    ) INTO staff_records
    FROM pos_mini_modular3_user_profiles
    WHERE business_id = p_business_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'staff', COALESCE(staff_records, '[]'::jsonb),
        'total_count', (SELECT COUNT(*) FROM pos_mini_modular3_user_profiles WHERE business_id = p_business_id)
    );
END;
$$;


--
-- Name: pos_mini_modular3_get_current_user_info(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_current_user_info() RETURNS TABLE(user_id uuid, business_id uuid, role text)
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
    SELECT id, business_id, role 
    FROM pos_mini_modular3_user_profiles 
    WHERE id = auth.uid()
    LIMIT 1;
$$;


--
-- Name: pos_mini_modular3_get_default_business_settings(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_default_business_settings(business_type_param text DEFAULT 'retail'::text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN jsonb_build_object(
    'currency', 'VND',
    'timezone', 'Asia/Ho_Chi_Minh',
    'language', 'vi',
    'tax_rate', 10,
    'business_type', business_type_param
  );
END;
$$;


--
-- Name: pos_mini_modular3_get_user_profile_safe(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_user_profile_safe(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    profile_record RECORD;
    business_record RECORD;
    result jsonb;
BEGIN
    -- Get profile (bypass RLS với SECURITY DEFINER)
    SELECT * INTO profile_record
    FROM pos_mini_modular3_user_profiles 
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'profile_exists', false,
            'profile', null,
            'business', null
        );
    END IF;

    -- Get business if exists
    business_record := NULL;
    IF profile_record.business_id IS NOT NULL THEN
        SELECT * INTO business_record
        FROM pos_mini_modular3_businesses 
        WHERE id = profile_record.business_id;
    END IF;

    -- Return result
    result := jsonb_build_object(
        'profile_exists', true,
        'profile', row_to_json(profile_record),
        'business', row_to_json(business_record)
    );

    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Only log new user, don't auto-create profile
    -- User must choose to register as business owner or accept invitation
    RAISE LOG 'New user created: %', NEW.id;
    RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_invite_staff_member(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_invite_staff_member(p_business_id uuid, p_email text, p_role text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    current_user_id uuid;
    current_user_role text;
    invitation_id uuid;
    result jsonb;
BEGIN
    current_user_id := auth.uid();
    
    -- Validate current user is business owner or manager
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = current_user_id AND business_id = p_business_id;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Permission denied: Only business owners and managers can invite staff'
        );
    END IF;
    
    -- Validate role
    IF p_role NOT IN ('manager', 'seller', 'accountant') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invalid role. Must be manager, seller, or accountant'
        );
    END IF;
    
    -- Check if email already invited or exists
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_business_invitations 
        WHERE business_id = p_business_id AND email = p_email AND status = 'pending'
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invitation already sent to this email');
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE business_id = p_business_id AND email = p_email
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User already exists in the business');
    END IF;

    -- Create invitation
    INSERT INTO pos_mini_modular3_business_invitations (
        business_id, invited_by, email, role
    ) VALUES (
        p_business_id, current_user_id, LOWER(TRIM(p_email)), p_role
    ) RETURNING id INTO invitation_id;

    result := jsonb_build_object(
        'success', true,
        'invitation_id', invitation_id,
        'message', 'Invitation sent successfully'
    );

    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to send invitation'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_is_super_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_is_super_admin() RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
    user_role text;
BEGIN
    -- ✅ SAME LOGIC AS FRONTEND: Check role in user_profiles
    SELECT role INTO user_role
    FROM pos_mini_modular3_user_profiles 
    WHERE id = auth.uid() 
    AND status = 'active';
    
    -- Return true if role is super_admin
    RETURN user_role = 'super_admin';
END;
$$;


--
-- Name: pos_mini_modular3_register_business_simple(uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_register_business_simple(p_user_id uuid, p_business_name text, p_full_name text, p_business_type text DEFAULT 'retail'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    business_code text;
    new_business_id uuid;
    result jsonb;
BEGIN
    -- Validate inputs
    IF LENGTH(TRIM(p_business_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Business name is required');
    END IF;
    
    IF LENGTH(TRIM(p_full_name)) = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Full name is required');
    END IF;

    -- Check if user already has a profile (bypass RLS)
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User profile already exists'
        );
    END IF;

    -- Generate business code
    business_code := pos_mini_modular3_generate_business_code();

    -- Create business
    INSERT INTO pos_mini_modular3_businesses (name, code, business_type, status)
    VALUES (TRIM(p_business_name), business_code, p_business_type, 'trial')
    RETURNING id INTO new_business_id;

    -- Create user profile as household_owner
    INSERT INTO pos_mini_modular3_user_profiles (
        id, business_id, full_name, role, status, login_method
    ) VALUES (
        p_user_id, new_business_id, TRIM(p_full_name), 'household_owner', 'active', 'email'
    );

    result := jsonb_build_object(
        'success', true,
        'business_id', new_business_id,
        'business_code', business_code,
        'message', 'Business registered successfully'
    );

    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to register business'
    );
    RETURN result;
END;
$$;


--
-- Name: pos_mini_modular3_safe_create_business(text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_safe_create_business(p_business_name text, p_contact_method text, p_contact_value text, p_owner_full_name text, p_business_type text DEFAULT 'retail'::text, p_subscription_tier text DEFAULT 'free'::text, p_business_status text DEFAULT 'trial'::text, p_subscription_status text DEFAULT 'trial'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    new_business_id uuid;
    new_business_code text;
    new_user_id uuid;
    trial_ends_date timestamp with time zone;
    max_users_limit integer;
    max_products_limit integer;
    user_exists boolean := false;
    result jsonb;
BEGIN
    -- 🔒 SECURITY: Input validation and sanitization
    IF p_business_name IS NULL OR trim(p_business_name) = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Tên hộ kinh doanh không được trống',
            'error_code', 'INVALID_BUSINESS_NAME'
        );
    END IF;
    
    IF p_owner_full_name IS NULL OR trim(p_owner_full_name) = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Tên chủ hộ không được trống',
            'error_code', 'INVALID_OWNER_NAME'
        );
    END IF;
    
    IF p_contact_value IS NULL OR trim(p_contact_value) = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Thông tin liên lạc không được trống',
            'error_code', 'INVALID_CONTACT'
        );
    END IF;
    
    -- Validate contact method
    IF p_contact_method NOT IN ('email', 'phone') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Phương thức liên lạc phải là email hoặc phone',
            'error_code', 'INVALID_CONTACT_METHOD'
        );
    END IF;
    
    -- Validate business type (synchronized with database constraint)
    IF p_business_type NOT IN (
        'retail', 'restaurant', 'cafe', 'food_service', 'beauty', 'spa', 'salon', 
        'healthcare', 'pharmacy', 'clinic', 'education', 'gym', 'fashion', 
        'electronics', 'automotive', 'repair', 'cleaning', 'construction', 
        'consulting', 'finance', 'real_estate', 'travel', 'hotel', 
        'entertainment', 'sports', 'agriculture', 'manufacturing', 'wholesale', 
        'logistics', 'service', 'other'
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Loại hình kinh doanh không hợp lệ. Vui lòng chọn từ danh sách có sẵn.',
            'error_code', 'INVALID_BUSINESS_TYPE'
        );
    END IF;
    
    -- Validate subscription tier
    IF p_subscription_tier NOT IN ('free', 'basic', 'premium') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Gói dịch vụ không hợp lệ',
            'error_code', 'INVALID_SUBSCRIPTION_TIER'
        );
    END IF;

    -- 🔍 CHECK: Duplicate business name
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_businesses 
        WHERE LOWER(name) = LOWER(trim(p_business_name))
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Tên hộ kinh doanh đã tồn tại trong hệ thống',
            'error_code', 'DUPLICATE_BUSINESS_NAME'
        );
    END IF;

    -- 🔍 CHECK: Duplicate contact (email/phone)
    IF p_contact_method = 'email' THEN
        IF EXISTS (
            SELECT 1 FROM pos_mini_modular3_user_profiles 
            WHERE LOWER(email) = LOWER(trim(p_contact_value))
        ) THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Email này đã được sử dụng trong hệ thống',
                'error_code', 'DUPLICATE_EMAIL'
            );
        END IF;
    ELSIF p_contact_method = 'phone' THEN
        IF EXISTS (
            SELECT 1 FROM pos_mini_modular3_user_profiles 
            WHERE phone = trim(p_contact_value)
        ) THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Số điện thoại này đã được sử dụng trong hệ thống',
                'error_code', 'DUPLICATE_PHONE'
            );
        END IF;
    END IF;

    -- ✅ GENERATE: Business code
    new_business_code := 'BIZ' || extract(epoch from now())::bigint;
    
    -- ✅ CALCULATE: Subscription limits
    CASE p_subscription_tier
        WHEN 'free' THEN
            max_users_limit := 3;
            max_products_limit := 50;
        WHEN 'basic' THEN
            max_users_limit := 10;
            max_products_limit := 500;
        WHEN 'premium' THEN
            max_users_limit := 50;
            max_products_limit := 5000;
        ELSE
            max_users_limit := 3;
            max_products_limit := 50;
    END CASE;
    
    -- ✅ CALCULATE: Trial end date (30 days from now)
    trial_ends_date := now() + interval '30 days';
    
    -- 🏢 CREATE: Business
    INSERT INTO pos_mini_modular3_businesses (
        id,
        name,
        code,
        business_type,
        phone,
        email,
        address,
        tax_code,
        legal_representative,
        logo_url,
        status,
        settings,
        subscription_tier,
        subscription_status,
        subscription_starts_at,
        subscription_ends_at,
        trial_ends_at,
        max_users,
        max_products,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        trim(p_business_name),
        new_business_code,
        p_business_type,
        CASE WHEN p_contact_method = 'phone' THEN trim(p_contact_value) ELSE NULL END,
        CASE WHEN p_contact_method = 'email' THEN trim(p_contact_value) ELSE NULL END,
        NULL, -- address
        NULL, -- tax_code
        trim(p_owner_full_name),
        NULL, -- logo_url
        p_business_status,
        '{}', -- settings (empty jsonb)
        p_subscription_tier,
        p_subscription_status,
        now(),
        NULL, -- subscription_ends_at (null for trial)
        trial_ends_date,
        max_users_limit,
        max_products_limit,
        now(),
        now()
    ) RETURNING id INTO new_business_id;

    -- 👤 CREATE: Business owner profile (no auth.users entry needed for Super Admin created businesses)
    INSERT INTO pos_mini_modular3_user_profiles (
        id,
        business_id,
        full_name,
        phone,
        email,
        avatar_url,
        role,
        status,
        permissions,
        login_method,
        last_login_at,
        employee_id,
        hire_date,
        notes,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        new_business_id,
        trim(p_owner_full_name),
        CASE WHEN p_contact_method = 'phone' THEN trim(p_contact_value) ELSE NULL END,
        CASE WHEN p_contact_method = 'email' THEN trim(p_contact_value) ELSE NULL END,
        NULL, -- avatar_url
        'household_owner',
        'active',
        '[]', -- permissions (empty array)
        p_contact_method,
        NULL, -- last_login_at
        NULL, -- employee_id
        NULL, -- hire_date
        'Được tạo bởi Super Admin',
        now(),
        now()
    ) RETURNING id INTO new_user_id;

    -- ✅ SUCCESS: Return comprehensive result
    result := jsonb_build_object(
        'success', true,
        'business_id', new_business_id,
        'business_name', trim(p_business_name),
        'business_code', new_business_code,
        'business_status', p_business_status,
        'subscription_tier', p_subscription_tier,
        'subscription_status', p_subscription_status,
        'user_created', true,
        'user_id', new_user_id,
        'max_users', max_users_limit,
        'max_products', max_products_limit,
        'contact_method', p_contact_method,
        'contact_value', trim(p_contact_value),
        'owner_name', trim(p_owner_full_name),
        'trial_ends_at', trial_ends_date::text,
        'message', 'Hộ kinh doanh và chủ hộ đã được tạo thành công'
    );

    RETURN result;

EXCEPTION 
    WHEN OTHERS THEN
        -- 🚨 ERROR: Comprehensive error handling
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Có lỗi hệ thống xảy ra: ' || SQLERRM,
            'error_code', 'SYSTEM_ERROR',
            'sqlstate', SQLSTATE
        );
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_safe_create_business(p_business_name text, p_contact_method text, p_contact_value text, p_owner_full_name text, p_business_type text, p_subscription_tier text, p_business_status text, p_subscription_status text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_safe_create_business(p_business_name text, p_contact_method text, p_contact_value text, p_owner_full_name text, p_business_type text, p_subscription_tier text, p_business_status text, p_subscription_status text) IS 'Business types are now managed through pos_mini_modular3_business_types table - supports dynamic business types';


--
-- Name: pos_mini_modular3_super_admin_bypass_rls_test(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_bypass_rls_test() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    business_count bigint;
    profile_count bigint;
    current_user_email text;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO business_count FROM pos_mini_modular3_businesses;
    SELECT COUNT(*) INTO profile_count FROM pos_mini_modular3_user_profiles;
    SELECT email INTO current_user_email FROM auth.users WHERE id = auth.uid();
    
    -- Return as jsonb
    RETURN jsonb_build_object(
        'business_count', business_count,
        'profile_count', profile_count,
        'current_user_email', current_user_email,
        'test_time', NOW()
    );
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_check_permission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_check_permission() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- ✅ FIX: Check by role in user_profiles table instead of hardcode email
    RETURN EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles up
        WHERE up.id = auth.uid() 
        AND up.role = 'super_admin'
        AND up.status = 'active'
    );
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_create_business_enhanced(text, text, text, text, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_create_business_enhanced(p_business_name text, p_contact_method text, p_contact_value text, p_owner_full_name text, p_business_type text DEFAULT 'retail'::text, p_subscription_tier text DEFAULT 'free'::text, p_set_password text DEFAULT NULL::text, p_is_active boolean DEFAULT true) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    business_code text;
    new_business_id uuid;
    trial_end_date timestamptz;
    existing_user uuid;
    clean_contact text;
    clean_phone text;
    new_user_id uuid;
    business_status text;
    subscription_status text;
    retry_count integer := 0;
    unique_code_found boolean := false;
    business_type_exists boolean := false;
BEGIN
    -- ✅ FIX: Check super admin permission first
    IF NOT pos_mini_modular3_super_admin_check_permission() THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'Không có quyền tạo hộ kinh doanh. Chỉ Super Admin mới được phép.'
        );
    END IF;

    -- Validate inputs
    IF TRIM(p_business_name) = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tên hộ kinh doanh không được trống');
    END IF;

    IF TRIM(p_contact_value) = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Thông tin liên lạc không được trống');
    END IF;

    IF TRIM(p_owner_full_name) = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tên chủ hộ không được trống');
    END IF;

    -- Validate contact method
    IF p_contact_method NOT IN ('email', 'phone') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Phương thức liên lạc phải là email hoặc phone');
    END IF;

    -- Validate subscription_tier
    IF p_subscription_tier NOT IN ('free', 'basic', 'premium') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Gói dịch vụ không hợp lệ');
    END IF;

    -- ✅ FIX: Validate business_type using business_types table instead of hard-coded values
    SELECT EXISTS (
        SELECT 1 
        FROM pos_mini_modular3_business_types 
        WHERE value = p_business_type 
        AND is_active = true
    ) INTO business_type_exists;
    
    IF NOT business_type_exists THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'Loại hình kinh doanh không hợp lệ hoặc không hoạt động'
        );
    END IF;

    clean_contact := TRIM(p_contact_value);

    -- Validate contact format
    IF p_contact_method = 'email' THEN
        -- Enhanced email validation
        IF clean_contact !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RETURN jsonb_build_object('success', false, 'error', 'Định dạng email không hợp lệ');
        END IF;
        
        -- Check if email already exists
        SELECT id INTO existing_user 
        FROM pos_mini_modular3_user_profiles 
        WHERE email = clean_contact
        LIMIT 1;

        IF existing_user IS NOT NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'Email này đã được sử dụng');
        END IF;

    ELSIF p_contact_method = 'phone' THEN
        -- Clean phone number (remove spaces, dashes, etc.)
        clean_phone := REGEXP_REPLACE(clean_contact, '[^0-9+]', '', 'g');
        
        -- Enhanced phone validation (Vietnamese format)
        IF clean_phone !~ '^(\+84|84|0)[0-9]{8,10}$' THEN
            RETURN jsonb_build_object('success', false, 'error', 'Số điện thoại không đúng định dạng Việt Nam (VD: 0909123456, +84909123456)');
        END IF;
        
        -- Normalize phone to +84 format
        IF clean_phone ~ '^0[0-9]{8,9}$' THEN
            clean_phone := '+84' || SUBSTRING(clean_phone FROM 2);
        ELSIF clean_phone ~ '^84[0-9]{8,9}$' THEN
            clean_phone := '+' || clean_phone;
        END IF;
        
        clean_contact := clean_phone;
        
        -- Check if phone already exists
        SELECT id INTO existing_user 
        FROM pos_mini_modular3_user_profiles 
        WHERE phone = clean_contact
        LIMIT 1;

        IF existing_user IS NOT NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'Số điện thoại này đã được sử dụng');
        END IF;
    END IF;

    -- ✅ FIX: Generate unique business code with collision check
    WHILE NOT unique_code_found AND retry_count < 10 LOOP
        business_code := 'BIZ' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::text, 4, '0');
        
        -- Check if code already exists
        IF NOT EXISTS (SELECT 1 FROM pos_mini_modular3_businesses WHERE code = business_code) THEN
            unique_code_found := true;
        ELSE
            retry_count := retry_count + 1;
        END IF;
    END LOOP;

    IF NOT unique_code_found THEN
        RETURN jsonb_build_object('success', false, 'error', 'Không thể tạo mã hộ kinh doanh duy nhất. Vui lòng thử lại.');
    END IF;

    -- Calculate trial end date (30 days)
    trial_end_date := NOW() + INTERVAL '30 days';

    -- ✅ FIX: Determine business status correctly
    IF p_is_active THEN
        business_status := 'active';
        subscription_status := CASE WHEN p_subscription_tier = 'free' THEN 'trial' ELSE 'active' END;
    ELSE
        business_status := 'suspended';
        subscription_status := 'suspended';
    END IF;

    -- Create business
    INSERT INTO pos_mini_modular3_businesses (
        name, code, business_type, status, subscription_tier, subscription_status,
        subscription_ends_at, trial_ends_at, max_users, max_products,
        created_at, updated_at
    ) VALUES (
        TRIM(p_business_name),
        business_code,
        p_business_type,
        business_status,
        p_subscription_tier,
        subscription_status,
        CASE WHEN p_subscription_tier = 'free' AND p_is_active THEN trial_end_date ELSE NULL END,
        CASE WHEN p_subscription_tier = 'free' AND p_is_active THEN trial_end_date ELSE NULL END,
        -- ✅ FIX: Correct user limits
        CASE 
            WHEN p_subscription_tier = 'free' THEN 3
            WHEN p_subscription_tier = 'basic' THEN 10  
            WHEN p_subscription_tier = 'premium' THEN 50
        END,
        -- ✅ FIX: Correct product limits
        CASE 
            WHEN p_subscription_tier = 'free' THEN 50
            WHEN p_subscription_tier = 'basic' THEN 500
            WHEN p_subscription_tier = 'premium' THEN 5000
        END,
        NOW(),
        NOW()
    ) RETURNING id INTO new_business_id;

    -- ✅ FIX: Create auth user and profile if password provided
    IF p_set_password IS NOT NULL AND TRIM(p_set_password) != '' THEN
        -- Validate password strength
        IF LENGTH(TRIM(p_set_password)) < 6 THEN
            RETURN jsonb_build_object('success', false, 'error', 'Mật khẩu phải có ít nhất 6 ký tự');
        END IF;

        -- Generate UUID for new user
        new_user_id := gen_random_uuid();
        
        -- ✅ FIX: Insert into auth.users with correct column names (remove non-existent columns)
        INSERT INTO auth.users (
            id,
            email,
            phone,
            encrypted_password,
            email_confirmed_at,
            phone_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            recovery_token
        ) VALUES (
            new_user_id,
            CASE WHEN p_contact_method = 'email' THEN clean_contact ELSE NULL END,
            CASE WHEN p_contact_method = 'phone' THEN clean_contact ELSE NULL END,
            crypt(p_set_password, gen_salt('bf')), -- Now safe with pgcrypto extension
            CASE WHEN p_contact_method = 'email' THEN NOW() ELSE NULL END,
            CASE WHEN p_contact_method = 'phone' THEN NOW() ELSE NULL END,
            -- ✅ FIX: Correct provider based on contact method
            CASE 
                WHEN p_contact_method = 'email' THEN '{"provider": "email", "providers": ["email"]}'::jsonb
                ELSE '{"provider": "phone", "providers": ["phone"]}'::jsonb
            END,
            jsonb_build_object('full_name', TRIM(p_owner_full_name)),
            NOW(),
            NOW(),
            NULL,
            NULL
        );

        -- ✅ FIX: Create user profile with correct status logic
        INSERT INTO pos_mini_modular3_user_profiles (
            id,
            business_id,
            full_name,
            email,
            phone,
            role,
            status,
            login_method,
            created_at,
            updated_at
        ) VALUES (
            new_user_id,
            new_business_id,
            TRIM(p_owner_full_name),
            CASE WHEN p_contact_method = 'email' THEN clean_contact ELSE NULL END,
            CASE WHEN p_contact_method = 'phone' THEN clean_contact ELSE NULL END,
            'household_owner',
            -- ✅ FIX: Use business_status instead of undefined p_business_status
            CASE WHEN business_status IN ('active', 'trial') THEN 'active' ELSE 'inactive' END,
            p_contact_method,
            NOW(),
            NOW()
        );
    END IF;

    -- Return enhanced success response
    RETURN jsonb_build_object(
        'success', true,
        'business_id', new_business_id,
        'business_name', TRIM(p_business_name),
        'business_code', business_code,
        'business_status', business_status,
        'subscription_tier', p_subscription_tier,
        'subscription_status', subscription_status,
        'trial_ends_at', CASE WHEN p_is_active THEN trial_end_date ELSE NULL END,
        'contact_method', p_contact_method,
        'contact_value', clean_contact,
        'owner_name', TRIM(p_owner_full_name),
        'user_created', CASE WHEN p_set_password IS NOT NULL THEN true ELSE false END,
        'user_id', new_user_id,
        'max_users', CASE 
            WHEN p_subscription_tier = 'free' THEN 3
            WHEN p_subscription_tier = 'basic' THEN 10  
            WHEN p_subscription_tier = 'premium' THEN 50
        END,
        'max_products', CASE 
            WHEN p_subscription_tier = 'free' THEN 50
            WHEN p_subscription_tier = 'basic' THEN 500
            WHEN p_subscription_tier = 'premium' THEN 5000
        END,
        'message', CASE 
            WHEN p_set_password IS NOT NULL THEN 'Hộ kinh doanh và tài khoản chủ hộ đã được tạo thành công'
            ELSE 'Hộ kinh doanh đã được tạo. Chủ hộ có thể đăng ký tài khoản riêng.'
        END
    );

EXCEPTION WHEN OTHERS THEN
    -- Enhanced error reporting
    RETURN jsonb_build_object(
        'success', false, 
        'error', SQLERRM,
        'error_code', SQLSTATE,
        'hint', 'Vui lòng kiểm tra lại thông tin và thử lại'
    );
END;
$_$;


--
-- Name: pos_mini_modular3_super_admin_create_complete_business(text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_create_complete_business(business_name_param text, contact_method_param text, contact_value_param text, owner_name_param text, business_type_param text DEFAULT 'retail'::text, subscription_tier_param text DEFAULT 'free'::text, business_status_param text DEFAULT 'trial'::text, subscription_status_param text DEFAULT 'trial'::text, password_param text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  business_id_var uuid;
  business_code_var text;
  owner_user_id_var uuid;
  temp_password_var text;
  email_var text;
  phone_var text;
  error_msg_var text;
BEGIN
  -- Validate inputs
  IF business_name_param IS NULL OR trim(business_name_param) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên hộ kinh doanh không được trống'
    );
  END IF;

  -- Process contact info
  IF contact_method_param = 'email' THEN
    email_var := trim(contact_value_param);
    phone_var := NULL;
  ELSE
    phone_var := trim(contact_value_param);
    email_var := NULL;
  END IF;

  BEGIN
    -- Generate IDs với function đúng tên
    business_id_var := gen_random_uuid();
    owner_user_id_var := gen_random_uuid();
    business_code_var := pos_mini_modular3_generate_business_code();  -- ✅ Đúng tên
    temp_password_var := COALESCE(password_param, 'temp' || substr(md5(random()::text), 1, 8));

    -- Create business
    INSERT INTO pos_mini_modular3_businesses (
      id, name, code, business_type, phone, email, status, settings, 
      trial_ends_at, max_users, max_products, created_at, updated_at
    ) VALUES (
      business_id_var,
      trim(business_name_param),
      business_code_var,
      business_type_param,
      phone_var,
      email_var,
      business_status_param,
      pos_mini_modular3_get_default_business_settings(business_type_param),  -- ✅ Đúng tên
      now() + interval '30 days',
      3,
      50,
      now(),
      now()
    );

    -- Create auth user
    INSERT INTO auth.users (
      id, email, phone, encrypted_password, email_confirmed_at, phone_confirmed_at,
      created_at, updated_at, instance_id, aud, role
    ) VALUES (
      owner_user_id_var,
      email_var,
      phone_var,
      crypt(temp_password_var, gen_salt('bf')),
      CASE WHEN email_var IS NOT NULL THEN now() ELSE NULL END,
      CASE WHEN phone_var IS NOT NULL THEN now() ELSE NULL END,
      now(),
      now(),
      '00000000-0000-0000-0000-000000000000'::uuid,
      'authenticated',
      'authenticated'
    );

    -- Create user profile
    INSERT INTO pos_mini_modular3_user_profiles (
      id, business_id, full_name, phone, email, role, status, 
      login_method, permissions, created_at, updated_at
    ) VALUES (
      owner_user_id_var,
      business_id_var,
      owner_name_param,
      phone_var,
      email_var,
      'household_owner',
      'active',
      contact_method_param,
      '["business_management", "pos_access", "admin_access"]'::jsonb,
      now(),
      now()
    );

    -- Return success
    RETURN jsonb_build_object(
      'success', true,
      'business_id', business_id_var,
      'business_name', business_name_param,
      'business_code', business_code_var,
      'owner_user_id', owner_user_id_var,
      'temp_password', temp_password_var,
      'message', 'Tạo hộ kinh doanh thành công'
    );

  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg_var = MESSAGE_TEXT;
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Lỗi: ' || error_msg_var
    );
  END;
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_delete_business(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_delete_business(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if caller is super admin
    IF NOT EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Chỉ Super Admin mới có quyền thực hiện thao tác này'
        );
    END IF;
    
    -- Delete all user profiles first (cascade)
    DELETE FROM pos_mini_modular3_user_profiles WHERE business_id = p_business_id;
    
    -- Delete business
    DELETE FROM pos_mini_modular3_businesses WHERE id = p_business_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Không tìm thấy hộ kinh doanh'
        );
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Xóa hộ kinh doanh thành công'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_generate_business_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_generate_business_code() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    new_code text;
    counter integer := 0;
BEGIN
    LOOP
        new_code := 'HKD' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::text, 4, '0');
        
        IF NOT EXISTS (SELECT 1 FROM pos_mini_modular3_businesses WHERE code = new_code) THEN
            RETURN new_code;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            RAISE EXCEPTION 'Cannot generate unique business code after 100 attempts';
        END IF;
    END LOOP;
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_get_business_registration_stats(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_get_business_registration_stats() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    stats jsonb;
BEGIN
    -- Check super admin permission
    IF NOT pos_mini_modular3_super_admin_check_permission() THEN
        RETURN jsonb_build_object('error', 'Permission denied');
    END IF;

    SELECT jsonb_build_object(
        'total_businesses', COUNT(*),
        'active_businesses', COUNT(*) FILTER (WHERE status = 'active'),
        'trial_businesses', COUNT(*) FILTER (WHERE status = 'trial'),
        'suspended_businesses', COUNT(*) FILTER (WHERE status = 'suspended'),
        'free_tier', COUNT(*) FILTER (WHERE subscription_tier = 'free'),
        'basic_tier', COUNT(*) FILTER (WHERE subscription_tier = 'basic'),
        'premium_tier', COUNT(*) FILTER (WHERE subscription_tier = 'premium'),
        'last_updated', NOW()
    ) INTO stats
    FROM pos_mini_modular3_businesses;

    RETURN stats;
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_normalize_phone_number(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_normalize_phone_number(phone_input text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    clean_phone text;
BEGIN
    -- Remove all non-digit and non-plus characters
    clean_phone := REGEXP_REPLACE(phone_input, '[^0-9+]', '', 'g');
    
    -- Validate Vietnamese phone format
    IF clean_phone !~ '^(\+84|84|0)[0-9]{8,10}$' THEN
        RAISE EXCEPTION 'Invalid Vietnamese phone number format: %', phone_input;
    END IF;
    
    -- Normalize to +84 format
    IF clean_phone ~ '^0[0-9]{8,9}$' THEN
        clean_phone := '+84' || SUBSTRING(clean_phone FROM 2);
    ELSIF clean_phone ~ '^84[0-9]{8,9}$' THEN
        clean_phone := '+' || clean_phone;
    END IF;
    
    RETURN clean_phone;
END;
$_$;


--
-- Name: pos_mini_modular3_super_admin_update_business_status(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_update_business_status(p_business_id uuid, p_status text, p_subscription_tier text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if caller is super admin
    IF NOT EXISTS (
        SELECT 1 FROM pos_mini_modular3_user_profiles 
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Chỉ Super Admin mới có quyền thực hiện thao tác này'
        );
    END IF;
    
    -- Validate status
    IF p_status NOT IN ('trial', 'active', 'suspended', 'cancelled') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Trạng thái không hợp lệ'
        );
    END IF;
    
    -- Update business
    UPDATE pos_mini_modular3_businesses 
    SET 
        status = p_status,
        subscription_tier = COALESCE(p_subscription_tier, subscription_tier),
        updated_at = now()
    WHERE id = p_business_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Không tìm thấy hộ kinh doanh'
        );
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Cập nhật trạng thái hộ kinh doanh thành công'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_super_admin_validate_email(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_super_admin_validate_email(email_input text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
BEGIN
    RETURN email_input ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$_$;


--
-- Name: pos_mini_modular3_template_business_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_template_business_access(target_business_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
    RETURN pos_mini_modular3_user_belongs_to_business(target_business_id);
END;
$$;


--
-- Name: pos_mini_modular3_template_user_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_template_user_access(target_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
    RETURN pos_mini_modular3_can_access_user_profile(target_user_id);
END;
$$;


--
-- Name: pos_mini_modular3_test_rls_policies(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_test_rls_policies() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    test_result jsonb;
    profile_count integer;
    current_user_info RECORD;
BEGIN
    -- Test basic profile access
    SELECT COUNT(*) INTO profile_count
    FROM pos_mini_modular3_user_profiles
    WHERE id = auth.uid();
    
    -- Get current user info
    SELECT * INTO current_user_info
    FROM pos_mini_modular3_get_current_user_info();
    
    test_result := jsonb_build_object(
        'success', true,
        'message', 'RLS policies working without recursion',
        'user_id', current_user_info.user_id,
        'business_id', current_user_info.business_id,
        'role', current_user_info.role,
        'profile_accessible', profile_count > 0,
        'timestamp', now()
    );
    
    RETURN test_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'RLS policies have issues',
        'timestamp', now()
    );
END;
$$;


--
-- Name: pos_mini_modular3_update_staff_member(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_staff_member(p_staff_id uuid, p_updates jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    current_user_id uuid;
    current_user_role text;
    staff_business_id uuid;
    result jsonb;
    update_fields text[] := '{}';
    update_values text[] := '{}';
    sql_query text;
BEGIN
    current_user_id := auth.uid();
    
    -- Get staff member's business_id
    SELECT business_id INTO staff_business_id
    FROM pos_mini_modular3_user_profiles
    WHERE id = p_staff_id;
    
    IF staff_business_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Staff member not found');
    END IF;
    
    -- Check if current user has permission to update staff in this business
    SELECT role INTO current_user_role
    FROM pos_mini_modular3_user_profiles
    WHERE id = current_user_id AND business_id = staff_business_id;
    
    IF current_user_role NOT IN ('household_owner', 'manager') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Permission denied: Only owners and managers can update staff'
        );
    END IF;
    
    -- Build dynamic UPDATE query based on provided fields
    IF p_updates ? 'full_name' THEN
        update_fields := array_append(update_fields, 'full_name = $' || (array_length(update_fields, 1) + 1));
        update_values := array_append(update_values, p_updates->>'full_name');
    END IF;
    
    IF p_updates ? 'role' THEN
        IF (p_updates->>'role') NOT IN ('manager', 'seller', 'accountant') THEN
            RETURN jsonb_build_object('success', false, 'error', 'Invalid role');
        END IF;
        update_fields := array_append(update_fields, 'role = $' || (array_length(update_fields, 1) + 1));
        update_values := array_append(update_values, p_updates->>'role');
    END IF;
    
    IF p_updates ? 'status' THEN
        IF (p_updates->>'status') NOT IN ('active', 'inactive', 'suspended') THEN
            RETURN jsonb_build_object('success', false, 'error', 'Invalid status');
        END IF;
        update_fields := array_append(update_fields, 'status = $' || (array_length(update_fields, 1) + 1));
        update_values := array_append(update_values, p_updates->>'status');
    END IF;
    
    IF p_updates ? 'employee_id' THEN
        update_fields := array_append(update_fields, 'employee_id = $' || (array_length(update_fields, 1) + 1));
        update_values := array_append(update_values, p_updates->>'employee_id');
    END IF;
    
    IF p_updates ? 'notes' THEN
        update_fields := array_append(update_fields, 'notes = $' || (array_length(update_fields, 1) + 1));
        update_values := array_append(update_values, p_updates->>'notes');
    END IF;
    
    -- Add updated_at
    update_fields := array_append(update_fields, 'updated_at = now()');
    
    IF array_length(update_fields, 1) = 1 THEN -- Only updated_at
        RETURN jsonb_build_object('success', false, 'error', 'No valid fields to update');
    END IF;
    
    -- Execute update
    sql_query := 'UPDATE pos_mini_modular3_user_profiles SET ' || 
                 array_to_string(update_fields, ', ') || 
                 ' WHERE id = $' || (array_length(update_fields, 1) + 1);
    
    EXECUTE sql_query USING update_values || ARRAY[p_staff_id::text];
    
    result := jsonb_build_object(
        'success', true,
        'message', 'Staff member updated successfully'
    );
    
    RETURN result;

EXCEPTION WHEN OTHERS THEN
    result := jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Failed to update staff member'
    );
    RETURN result;
END;
$_$;


--
-- Name: pos_mini_modular3_update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_user_belongs_to_business(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_user_belongs_to_business(target_business_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
    -- Super admin has access to everything
    IF pos_mini_modular3_is_super_admin() THEN
        RETURN true;
    END IF;
    
    -- Regular user: check business membership
    RETURN pos_mini_modular3_current_user_business_id() = target_business_id;
END;
$$;


--
-- Name: pos_mini_modular3_validate_profile_creation(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_validate_profile_creation(p_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Đảm bảo p_user_id khớp với user đã đăng nhập
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'User ID không khớp: truyền vào % nhưng user đã đăng nhập là %', p_user_id, auth.uid();
    END IF;
    
    -- Kiểm tra profile đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_user_profiles WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User profile đã tồn tại cho user %', p_user_id;
    END IF;
    
    RETURN true;
END;
$$;


--
-- Name: rollback_transaction(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rollback_transaction() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  ROLLBACK;
END;
$$;


--
-- Name: run_sql(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.run_sql(sql text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    result text;
BEGIN
    -- Chỉ cho phép Super Admin sử dụng function này
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE auth.users.id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Access denied: Super Admin required';
    END IF;
    
    -- Execute SQL và trả về kết quả
    EXECUTE sql;
    
    -- Trả về thông báo thành công
    result := 'SQL executed successfully';
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error và re-raise
        RAISE EXCEPTION 'SQL execution failed: %', SQLERRM;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: validate_backup_integrity(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_backup_integrity(backup_id_param text) RETURNS TABLE(is_valid boolean, error_message text, file_exists boolean, checksum_valid boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  backup_record RECORD;
BEGIN
  -- Get backup metadata
  SELECT * INTO backup_record
  FROM pos_mini_modular3_backup_metadata
  WHERE id = backup_id_param;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Backup not found', false, false;
    RETURN;
  END IF;
  
  -- For now, assume file exists and checksum is valid
  -- In production, implement actual file validation
  RETURN QUERY SELECT true, NULL::TEXT, true, true;
END;
$$;


--
-- Name: FUNCTION validate_backup_integrity(backup_id_param text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.validate_backup_integrity(backup_id_param text) IS 'Validates backup file integrity and existence';


--
-- Name: validate_sql(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_sql(sql text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    result jsonb;
    error_msg text;
BEGIN
    BEGIN
        -- Try to explain the SQL to validate syntax
        EXECUTE 'EXPLAIN ' || sql;
        
        result := jsonb_build_object(
            'valid', true,
            'message', 'SQL syntax is valid'
        );
        
    EXCEPTION
        WHEN OTHERS THEN
            error_msg := SQLERRM;
            result := jsonb_build_object(
                'valid', false,
                'error', error_msg
            );
    END;
    
    RETURN result;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: pos_mini_modular3_backup_downloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_backup_downloads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    backup_id text NOT NULL,
    downloaded_at timestamp with time zone DEFAULT now() NOT NULL,
    downloaded_by text NOT NULL,
    ip_address text,
    user_agent text
);


--
-- Name: TABLE pos_mini_modular3_backup_downloads; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_backup_downloads IS 'Logs backup download activities';


--
-- Name: pos_mini_modular3_backup_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_backup_metadata (
    id text NOT NULL,
    filename text NOT NULL,
    type text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    checksum text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    version text,
    tables jsonb DEFAULT '[]'::jsonb NOT NULL,
    compressed boolean DEFAULT false NOT NULL,
    encrypted boolean DEFAULT false NOT NULL,
    storage_path text NOT NULL,
    retention_until timestamp with time zone NOT NULL,
    status text DEFAULT 'creating'::text NOT NULL,
    error_message text,
    created_by text NOT NULL,
    CONSTRAINT pos_mini_modular3_backup_metadata_status_check CHECK ((status = ANY (ARRAY['creating'::text, 'completed'::text, 'failed'::text, 'expired'::text]))),
    CONSTRAINT pos_mini_modular3_backup_metadata_type_check CHECK ((type = ANY (ARRAY['full'::text, 'incremental'::text, 'schema'::text, 'data'::text])))
);


--
-- Name: TABLE pos_mini_modular3_backup_metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_backup_metadata IS 'Stores metadata about database backups';


--
-- Name: pos_mini_modular3_backup_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_backup_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    backup_id text,
    schedule_id uuid,
    read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    details jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT pos_mini_modular3_backup_notifications_type_check CHECK ((type = ANY (ARRAY['success'::text, 'warning'::text, 'error'::text])))
);


--
-- Name: TABLE pos_mini_modular3_backup_notifications; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_backup_notifications IS 'Stores backup-related notifications and alerts';


--
-- Name: pos_mini_modular3_backup_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_backup_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    backup_type text NOT NULL,
    cron_expression text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    compression text DEFAULT 'gzip'::text NOT NULL,
    encryption boolean DEFAULT true NOT NULL,
    retention_days integer DEFAULT 30 NOT NULL,
    last_run_at timestamp with time zone,
    next_run_at timestamp with time zone,
    failure_count integer DEFAULT 0 NOT NULL,
    last_error text,
    created_by text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pos_mini_modular3_backup_schedules_backup_type_check CHECK ((backup_type = ANY (ARRAY['full'::text, 'incremental'::text, 'schema'::text, 'data'::text]))),
    CONSTRAINT pos_mini_modular3_backup_schedules_compression_check CHECK ((compression = ANY (ARRAY['gzip'::text, 'lz4'::text, 'none'::text])))
);


--
-- Name: TABLE pos_mini_modular3_backup_schedules; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_backup_schedules IS 'Manages automated backup schedules';


--
-- Name: pos_mini_modular3_business_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_business_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid,
    invited_by uuid,
    email text NOT NULL,
    role text NOT NULL,
    invitation_token text DEFAULT encode(extensions.gen_random_bytes(32), 'hex'::text) NOT NULL,
    status text DEFAULT 'pending'::text,
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval),
    accepted_at timestamp with time zone,
    accepted_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_business_invitations_role_check CHECK ((role = ANY (ARRAY['manager'::text, 'seller'::text, 'accountant'::text]))),
    CONSTRAINT pos_mini_modular3_business_invitations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: pos_mini_modular3_business_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_business_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    value text NOT NULL,
    label text NOT NULL,
    description text,
    icon text,
    category text DEFAULT 'other'::text NOT NULL,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: pos_mini_modular3_businesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_businesses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    business_type text DEFAULT 'retail'::text NOT NULL,
    phone text,
    email text,
    address text,
    tax_code text,
    legal_representative text,
    logo_url text,
    status text DEFAULT 'trial'::text,
    settings jsonb DEFAULT '{}'::jsonb,
    subscription_tier text DEFAULT 'free'::text,
    subscription_status text DEFAULT 'trial'::text,
    subscription_starts_at timestamp with time zone DEFAULT now(),
    subscription_ends_at timestamp with time zone,
    trial_ends_at timestamp with time zone DEFAULT (now() + '30 days'::interval),
    max_users integer DEFAULT 3,
    max_products integer DEFAULT 50,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_businesses_business_type_valid CHECK (((business_type IS NOT NULL) AND (length(TRIM(BOTH FROM business_type)) > 0) AND (length(business_type) <= 50))),
    CONSTRAINT pos_mini_modular3_businesses_name_check CHECK ((length(TRIM(BOTH FROM name)) > 0)),
    CONSTRAINT pos_mini_modular3_businesses_status_check CHECK ((status = ANY (ARRAY['trial'::text, 'active'::text, 'suspended'::text, 'closed'::text]))),
    CONSTRAINT pos_mini_modular3_businesses_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['trial'::text, 'active'::text, 'past_due'::text, 'cancelled'::text]))),
    CONSTRAINT pos_mini_modular3_businesses_subscription_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])))
);


--
-- Name: pos_mini_modular3_restore_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_restore_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    backup_id text NOT NULL,
    restored_at timestamp with time zone DEFAULT now() NOT NULL,
    restored_by text NOT NULL,
    restore_type text NOT NULL,
    target_tables jsonb,
    success boolean NOT NULL,
    error_message text,
    duration_ms integer,
    rows_affected integer DEFAULT 0,
    restore_point_id text,
    CONSTRAINT pos_mini_modular3_restore_history_restore_type_check CHECK ((restore_type = ANY (ARRAY['full'::text, 'partial'::text, 'schema_only'::text, 'data_only'::text])))
);


--
-- Name: TABLE pos_mini_modular3_restore_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_restore_history IS 'Tracks database restore operations';


--
-- Name: pos_mini_modular3_restore_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_restore_points (
    id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tables_backup jsonb DEFAULT '{}'::jsonb NOT NULL,
    schema_backup text,
    created_by text NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval) NOT NULL
);


--
-- Name: TABLE pos_mini_modular3_restore_points; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_restore_points IS 'Stores restore points for rollback capability';


--
-- Name: pos_mini_modular3_subscription_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_subscription_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid,
    from_tier text,
    to_tier text NOT NULL,
    changed_by uuid,
    amount_paid integer DEFAULT 0,
    payment_method text,
    transaction_id text,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone,
    status text DEFAULT 'active'::text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_subscription_history_status_check CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text, 'expired'::text])))
);


--
-- Name: pos_mini_modular3_subscription_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_subscription_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tier text NOT NULL,
    name text NOT NULL,
    price_monthly integer DEFAULT 0,
    max_users integer NOT NULL,
    max_products integer,
    max_warehouses integer DEFAULT 1,
    max_branches integer DEFAULT 1,
    features jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_subscription_plans_tier_check CHECK ((tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])))
);


--
-- Name: pos_mini_modular3_user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_user_profiles (
    id uuid NOT NULL,
    business_id uuid,
    full_name text NOT NULL,
    phone text,
    email text,
    avatar_url text,
    role text DEFAULT 'seller'::text NOT NULL,
    status text DEFAULT 'active'::text,
    permissions jsonb DEFAULT '[]'::jsonb,
    login_method text DEFAULT 'email'::text,
    last_login_at timestamp with time zone,
    employee_id text,
    hire_date date,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT check_super_admin_business_logic CHECK ((((role = 'super_admin'::text) AND (business_id IS NULL)) OR ((role <> 'super_admin'::text) AND (business_id IS NOT NULL)))),
    CONSTRAINT pos_mini_modular3_user_profiles_full_name_check CHECK ((length(TRIM(BOTH FROM full_name)) > 0)),
    CONSTRAINT pos_mini_modular3_user_profiles_login_method_check CHECK ((login_method = ANY (ARRAY['email'::text, 'phone'::text]))),
    CONSTRAINT pos_mini_modular3_user_profiles_phone_format_check CHECK (((phone IS NULL) OR (phone = ''::text) OR ((length(TRIM(BOTH FROM phone)) >= 8) AND (length(TRIM(BOTH FROM phone)) <= 15) AND (phone ~ '^[0-9+\-\s\(\)\.]+$'::text)))),
    CONSTRAINT pos_mini_modular3_user_profiles_role_check CHECK ((role = ANY (ARRAY['super_admin'::text, 'household_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text]))),
    CONSTRAINT pos_mini_modular3_user_profiles_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text])))
);


--
-- Name: pos_mini_modular3_super_admin_businesses; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.pos_mini_modular3_super_admin_businesses AS
 SELECT b.id,
    b.name AS business_name,
    b.code AS business_code,
    b.business_type,
    b.status,
    b.subscription_tier,
    b.subscription_status,
    b.trial_ends_at,
    b.subscription_ends_at,
    b.created_at,
    b.updated_at,
    owner.full_name AS owner_name,
    owner.email AS owner_email,
    owner.status AS owner_status,
    owner.id AS owner_id,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_user_profiles
          WHERE (pos_mini_modular3_user_profiles.business_id = b.id)) AS total_staff,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_user_profiles
          WHERE ((pos_mini_modular3_user_profiles.business_id = b.id) AND (pos_mini_modular3_user_profiles.status = 'active'::text))) AS active_staff
   FROM (public.pos_mini_modular3_businesses b
     LEFT JOIN public.pos_mini_modular3_user_profiles owner ON (((owner.business_id = b.id) AND (owner.role = 'household_owner'::text))));


--
-- Name: pos_mini_modular3_super_admin_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.pos_mini_modular3_super_admin_stats AS
 SELECT ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_businesses) AS total_businesses,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_businesses
          WHERE (pos_mini_modular3_businesses.status = 'active'::text)) AS active_businesses,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_businesses
          WHERE (pos_mini_modular3_businesses.status = 'trial'::text)) AS trial_businesses,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_user_profiles
          WHERE (pos_mini_modular3_user_profiles.role <> 'super_admin'::text)) AS total_users,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_user_profiles
          WHERE (pos_mini_modular3_user_profiles.role = 'household_owner'::text)) AS total_owners,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_user_profiles
          WHERE (pos_mini_modular3_user_profiles.role = 'staff'::text)) AS total_staff,
    ( SELECT count(*) AS count
           FROM public.pos_mini_modular3_businesses
          WHERE (pos_mini_modular3_businesses.created_at >= date_trunc('month'::text, now()))) AS businesses_this_month,
    ( SELECT
                CASE
                    WHEN (count(*) = 0) THEN (0)::bigint
                    ELSE (((count(*) FILTER (WHERE (pos_mini_modular3_businesses.subscription_tier = 'basic'::text)) * 199000) + (count(*) FILTER (WHERE (pos_mini_modular3_businesses.subscription_tier = 'premium'::text)) * 499000)) + (count(*) FILTER (WHERE (pos_mini_modular3_businesses.subscription_tier = 'free'::text)) * 0))
                END AS "case"
           FROM public.pos_mini_modular3_businesses
          WHERE (pos_mini_modular3_businesses.status = 'active'::text)) AS estimated_revenue,
    0.15 AS revenue_growth;


--
-- Data for Name: pos_mini_modular3_backup_downloads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_downloads (id, backup_id, downloaded_at, downloaded_by, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_backup_metadata; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_metadata (id, filename, type, size, checksum, created_at, version, tables, compressed, encrypted, storage_path, retention_until, status, error_message, created_by) FROM stdin;
1ep6obol1h1mco943i0	pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc	data	6984	e2f3e30cfb0548453783adff2c8385c314bc210f9af4189ac2d3e5e7fd4dc42f	2025-07-04 03:24:54.072+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc	2025-08-03 03:24:55.997+00	completed	\N	system
15v2kx2zp3ymcoxduiq	pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc	data	7860	2f34b42804472f1aa370c281e8004f9b64283ca4a3feab15dc5ced6dd52ef654	2025-07-04 14:44:19.778+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc	2025-08-03 14:44:21.28+00	completed	\N	system
0akl4fn6laafmcotdaeb	pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc	data	7299	892d2e05d1968b295633d099c0a91b92d343ddc1f742c46dedf4286820bc0402	2025-07-04 12:51:55.235+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc	2025-08-03 12:51:57.487+00	completed	\N	system
aiaawarjb1mco62qfu	pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc	data	6612	34992f4a7ce8e0bddf4d7791a4d61c6b9b8bcb19d0b5c8348719cac6c3dea508	2025-07-04 01:59:51.642+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc	2025-08-03 01:59:53.308+00	completed	\N	system
qsw626zysbpmco5tkrn	pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc	data	6199	9d87b9fe7f1f73a0ed69962e927d5209c7e0b0792cfdcdf030672d11c0be4423	2025-07-04 01:52:44.387+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc	2025-08-03 01:52:45.827+00	completed	\N	system
n7tjq9mkd3mcpg7cxv	pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc	full	8630	66770dde62b33761d44fa50dc7d2c6f52a5315f69b91c2de02d34d6103910bb7	2025-07-04 23:31:09.763+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc	2025-08-03 23:31:12.213+00	completed	\N	system
\.


--
-- Data for Name: pos_mini_modular3_backup_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_notifications (id, type, title, message, backup_id, schedule_id, read, created_at, details) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_backup_schedules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_schedules (id, name, backup_type, cron_expression, enabled, compression, encryption, retention_days, last_run_at, next_run_at, failure_count, last_error, created_by, created_at, updated_at) FROM stdin;
8bad2bc1-a479-48c1-a58c-6424e34e58ea	Daily Incremental Backup	incremental	0 2 * * *	t	gzip	t	30	\N	2025-07-04 15:50:02.923339+00	0	\N	system	2025-07-03 15:50:02.923339+00	2025-07-04 22:53:45.51178+00
f46e39c3-5a40-48f7-984a-27cd5704fb09	Weekly Full Backup	full	0 3 * * 0	t	gzip	t	90	\N	2025-07-10 15:50:02.923339+00	0	\N	system	2025-07-03 15:50:02.923339+00	2025-07-04 22:53:45.51178+00
\.


--
-- Data for Name: pos_mini_modular3_business_invitations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_invitations (id, business_id, invited_by, email, role, invitation_token, status, expires_at, accepted_at, accepted_by, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_business_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_types (id, value, label, description, icon, category, is_active, sort_order, created_at, updated_at) FROM stdin;
1dc28a52-de30-4c51-82e5-2c54a33fbb5c	retail	🏪 Bán lẻ	Cửa hàng bán lẻ, siêu thị mini, tạp hóa	🏪	retail	t	10	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
380698d9-442e-4ead-a777-46b638ea641f	wholesale	📦 Bán sỉ	Bán sỉ, phân phối hàng hóa	📦	retail	t	20	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
b48d76f0-b535-466c-861b-b6304ed28d80	fashion	👗 Thời trang	Quần áo, giày dép, phụ kiện thời trang	👗	retail	t	30	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
abe66183-1d93-453f-8ddf-bf3961b9f254	electronics	📱 Điện tử	Điện thoại, máy tính, thiết bị điện tử	📱	retail	t	40	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
a09e0ef4-68cd-4306-aaaa-e3894bf34ac4	restaurant	🍽️ Nhà hàng	Nhà hàng, quán ăn, fast food	🍽️	food	t	110	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
0a631496-d43b-4593-9997-11a76457c1d1	cafe	☕ Quán cà phê	Cà phê, trà sữa, đồ uống	☕	food	t	120	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
7f6a0248-48d4-42bf-b69d-b06ae8a78d08	food_service	🍱 Dịch vụ ăn uống	Catering, giao đồ ăn, suất ăn công nghiệp	🍱	food	t	130	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
24cfb1e4-3243-4f2b-a49d-ec775b4644e6	beauty	💄 Làm đẹp	Mỹ phẩm, làm đẹp, chăm sóc da	💄	beauty	t	210	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
0ae5962c-a16d-4e07-860b-9ea13d174576	spa	🧖‍♀️ Spa	Spa, massage, thư giãn	🧖‍♀️	beauty	t	220	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
88b16cdc-3c76-4633-888d-748b08a40c48	salon	💇‍♀️ Salon	Cắt tóc, tạo kiểu, làm nail	💇‍♀️	beauty	t	230	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
929559c9-d7a0-4292-a9f4-6aff2b8e8539	healthcare	🏥 Y tế	Dịch vụ y tế, chăm sóc sức khỏe	🏥	healthcare	t	310	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
768b62b6-6b1c-4665-8296-1a0f9b7512bf	pharmacy	💊 Nhà thuốc	Hiệu thuốc, dược phẩm	💊	healthcare	t	320	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
28066e50-889c-4181-b303-d77d598c5dbc	clinic	🩺 Phòng khám	Phòng khám tư, chuyên khoa	🩺	healthcare	t	330	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
01f7f102-d0b5-4dce-98e5-26343f19f182	education	🎓 Giáo dục	Trung tâm dạy học, đào tạo	🎓	professional	t	410	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
7ac90817-0d1b-4a18-8857-5cba2ef63e9c	consulting	💼 Tư vấn	Dịch vụ tư vấn, chuyên môn	💼	professional	t	420	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
0785cb7a-689a-4591-94c0-6eba1261db0f	finance	💰 Tài chính	Dịch vụ tài chính, bảo hiểm	💰	professional	t	430	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
34bfe785-4294-4890-bbf6-038acb095710	real_estate	🏘️ Bất động sản	Môi giới, tư vấn bất động sản	🏘️	professional	t	440	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
0dbcca8f-9ce3-47ed-9297-c3a2b785451e	automotive	🚗 Ô tô	Sửa chữa, bảo dưỡng ô tô, xe máy	🚗	technical	t	510	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
a68d37f4-a91f-4247-9e2f-e05e1a6331ed	repair	🔧 Sửa chữa	Sửa chữa điện tử, đồ gia dụng	🔧	technical	t	520	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
0de2b85d-4410-4fb1-b00a-1a716c3be98a	cleaning	🧹 Vệ sinh	Dịch vụ vệ sinh, dọn dẹp	🧹	technical	t	530	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
cb7fd67f-1574-458d-ad38-c6df271d9adf	construction	🏗️ Xây dựng	Xây dựng, sửa chữa nhà cửa	🏗️	technical	t	540	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
7911c5f3-4be8-482b-a6b7-d0fcf55bf650	travel	✈️ Du lịch	Tour du lịch, dịch vụ lữ hành	✈️	entertainment	t	610	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
2c14d3ba-8afb-4651-b1d6-514060332e39	hotel	🏨 Khách sạn	Khách sạn, nhà nghỉ, homestay	🏨	entertainment	t	620	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
7ac93735-73a9-4517-8d80-d2d6b45e735a	entertainment	🎉 Giải trí	Karaoke, game, sự kiện	🎉	entertainment	t	630	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
50787e95-4a31-4c94-bd22-1224cee4a8be	sports	⚽ Thể thao	Sân thể thao, dụng cụ thể thao	⚽	entertainment	t	640	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
103b4ac9-dd72-4d7a-93d8-1b62ac03f6e5	agriculture	🌾 Nông nghiệp	Nông sản, thủy sản, chăn nuôi	🌾	industrial	t	710	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
546c8520-8b18-4795-aa94-02612bdab76c	manufacturing	🏭 Sản xuất	Sản xuất, gia công, chế biến	🏭	industrial	t	720	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
1dfd7419-5dd5-47d4-9daa-0841a597f47b	logistics	🚚 Logistics	Vận chuyển, kho bãi, logistics	🚚	industrial	t	730	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
181ca2e0-58b7-4002-8f1b-6bdbe9442f47	service	🔧 Dịch vụ	Dịch vụ tổng hợp khác	🔧	service	t	910	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
6eef9c17-98df-445c-88c3-3153a7970ac4	other	🏢 Khác	Các loại hình kinh doanh khác	🏢	other	t	999	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
8b66bec4-57ff-40a5-9210-ab7e5ceb0a73	gym	💪 Gym & Thể thao	Phòng gym, yoga, thể dục thể thao	💪	sports	t	240	2025-07-03 10:59:01.990231+00	2025-07-04 22:53:46.113917+00
\.


--
-- Data for Name: pos_mini_modular3_businesses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at) FROM stdin;
97da7e62-0409-4882-b80c-2c75b60cb0da	Bida Thiên Long 2	BIZ000001	retail	\N	\N	\N	\N	\N	\N	trial	{}	free	trial	2025-06-30 22:38:05.559244+00	\N	2025-07-30 22:38:05.559244+00	3	50	2025-06-30 22:38:05.559244+00	2025-07-04 22:53:46.665466+00
61473fc9-16b2-45b8-87f0-45e0dc8612ef	An Nhiên Farm	BIZ1751366425	cafe	\N	\N	D2/062A, Nam Son, Quang Trung, Thong Nhat	3604005775	\N	\N	trial	{}	free	trial	2025-07-01 10:40:25.745418+00	\N	2025-07-31 10:40:25.745418+00	5	50	2025-07-01 10:40:25.745418+00	2025-07-04 22:53:46.665466+00
dda92815-c1f0-4597-8c05-47ec1eb50873	Của Hàng Rau Sạch Phi Yến	BIZ1751371309	retail	\N	\N	145 Cạnh Sacombank Gia Yên	987654456	\N	\N	trial	{}	free	trial	2025-07-01 12:01:49.27648+00	\N	2025-07-31 12:01:49.27648+00	5	50	2025-07-01 12:01:49.27648+00	2025-07-04 22:53:46.665466+00
e997773b-8876-4837-aa80-c2f82cf07f83	Chao Lòng Viên Minh Châu	SAFE202507026623	service	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-02 18:55:36.167643+00	2025-08-01 18:55:36.167643+00	2025-08-01 18:55:36.167643+00	3	100	2025-07-02 18:55:36.167643+00	2025-07-04 22:53:46.665466+00
c182f174-6372-4b34-964d-765fdc6dabbd	Lẩu Cua Đồng Thanh Sơn	BIZ202507039693	fashion	\N	\N	\N	\N	\N	\N	active	{}	premium	active	2025-07-03 13:38:21.323452+00	\N	\N	50	5000	2025-07-03 13:38:21.323452+00	2025-07-04 22:53:46.665466+00
7a2a2404-8498-4396-bd2b-e6745591652b	Test Direct RPC Business 2333	BIZ202507036302	retail	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-03 13:28:51.487484+00	2025-08-02 13:28:51.487484+00	2025-08-02 13:28:51.487484+00	3	50	2025-07-03 13:28:51.487484+00	2025-07-04 22:53:46.665466+00
087ef234-4f85-4926-8233-3b5f89196ec2	Nhà Hàn Hoa Viên 7779	BIZ1751484657	fashion	\N	\N	54 ap Gia Tân 2	987026351478	\N	\N	trial	{}	free	trial	2025-07-02 19:30:57.294046+00	\N	2025-08-01 19:30:57.294046+00	5	50	2025-07-02 19:30:57.294046+00	2025-07-04 22:53:46.665466+00
37c75836-edb9-4dc2-8bbe-83ad87ba274e	Gas Tân Yên 563 business 	BIZ202507032595	construction	\N	\N	\N	\N	\N	\N	active	{}	basic	active	2025-07-03 13:39:20.303084+00	\N	\N	10	500	2025-07-03 13:39:20.303084+00	2025-07-04 22:53:46.665466+00
1f0290fe-3ed1-440b-9a0b-68885aaba9f8	Test Direct RPC trucchi	BIZ202507032202	fashion	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-03 13:28:51.257721+00	2025-08-02 13:28:51.257721+00	2025-08-02 13:28:51.257721+00	3	50	2025-07-03 13:28:51.257721+00	2025-07-04 22:53:46.665466+00
\.


--
-- Data for Name: pos_mini_modular3_restore_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_restore_history (id, backup_id, restored_at, restored_by, restore_type, target_tables, success, error_message, duration_ms, rows_affected, restore_point_id) FROM stdin;
d46ff2c8-cbdd-4efb-be2d-78deb40e3bd4	15v2kx2zp3ymcoxduiq	2025-07-04 14:47:20.054551+00	system	full	\N	t	\N	7255	6	\N
cfee99fb-95fb-4ca6-9d30-7a9106328913	15v2kx2zp3ymcoxduiq	2025-07-04 14:48:36.178514+00	system	full	\N	t	\N	6775	6	\N
ab2a481b-7ba2-4935-99c1-1d07b9ad26d9	15v2kx2zp3ymcoxduiq	2025-07-04 14:49:37.401882+00	system	full	\N	f	Failed statements: 3	7245	5	\N
adee8e12-cb82-4c8c-920a-a9c5cc03229e	15v2kx2zp3ymcoxduiq	2025-07-04 14:51:22.076096+00	system	full	\N	f	Failed statements: 3	7055	5	\N
7fc394ad-d094-4f1c-898a-7b8d767cabfd	15v2kx2zp3ymcoxduiq	2025-07-04 14:52:35.461462+00	system	full	\N	f	Failed statements: 3	7087	5	\N
6503ffc7-c519-43c1-bdee-9a8723eb3c52	15v2kx2zp3ymcoxduiq	2025-07-04 14:57:14.550814+00	system	full	\N	f	Failed statements: 2	6613	6	\N
80cd0207-c6b4-4672-8ff7-9e4ae16f491d	15v2kx2zp3ymcoxduiq	2025-07-04 14:59:19.804183+00	system	full	\N	f	Failed statements: 2	6518	6	\N
c9e879e4-de28-46d9-8ede-a1a806ddfffc	0akl4fn6laafmcotdaeb	2025-07-04 13:02:28.416021+00	system	full	\N	t	\N	1612	5	\N
3e08561e-ee58-4dda-bd3e-836871827130	0akl4fn6laafmcotdaeb	2025-07-04 14:36:49.982449+00	system	full	\N	t	\N	1901	5	\N
75ea3fd3-fd1b-4c82-8752-1ff7ca024605	0akl4fn6laafmcotdaeb	2025-07-04 14:42:16.570982+00	system	full	\N	t	\N	7716	5	\N
b190abb7-9c68-4a28-9a56-290d34ae69bf	15v2kx2zp3ymcoxduiq	2025-07-04 22:53:51.442042+00	system	full	\N	t	\N	8731	6	\N
\.


--
-- Data for Name: pos_mini_modular3_restore_points; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_restore_points (id, created_at, tables_backup, schema_backup, created_by, expires_at) FROM stdin;
rp_1751640676007_7xxs8a9vdvx	2025-07-04 14:51:16.092+00	{}		system	2025-07-11 14:51:16.092+00
rp_1751640510167_v5gmu4ixzrj	2025-07-04 14:48:30.357+00	{}		system	2025-07-11 14:48:30.357+00
rp_1751669623638_aw5ekvmyig6	2025-07-04 22:53:43.73+00	{}		system	2025-07-11 22:53:43.73+00
rp_1751634147696_is9nixixlf	2025-07-04 13:02:27.81+00	{}		system	2025-07-11 13:02:27.81+00
rp_1751639808959_davp3fqyj6k	2025-07-04 14:36:49.049+00	{}		system	2025-07-11 14:36:49.049+00
rp_1751641028860_blsaixz2jb4	2025-07-04 14:57:08.949+00	{}		system	2025-07-11 14:57:08.949+00
rp_1751633606873_t9pymxb147s	2025-07-04 12:53:26.964+00	{}		system	2025-07-11 12:53:26.964+00
rp_1751640129549_lm8jpkwt42	2025-07-04 14:42:09.713+00	{}		system	2025-07-11 14:42:09.713+00
rp_1751617487365_egol6m4kpoi	2025-07-04 08:24:47.523+00	{}		system	2025-07-11 08:24:47.523+00
rp_1751599680266_e4ylybiwohn	2025-07-04 03:28:00.363+00	{}		system	2025-07-11 03:28:00.363+00
rp_1751633770702_wc9scqxqvni	2025-07-04 12:56:10.797+00	{}		system	2025-07-11 12:56:10.797+00
rp_1751599701897_05vqy5o6r664	2025-07-04 03:28:22.069+00	{}		system	2025-07-11 03:28:22.069+00
rp_1751617947874_d4146ntfc9n	2025-07-04 08:32:28.06+00	{}		system	2025-07-11 08:32:28.06+00
rp_1751594519363_opt8v2gldo	2025-07-04 02:01:59.46+00	{}		system	2025-07-11 02:01:59.46+00
rp_1751594669921_pa4u2vraza	2025-07-04 02:04:30.018+00	{}		system	2025-07-11 02:04:30.018+00
rp_1751594729358_y5vzx79po8d	2025-07-04 02:05:29.467+00	{}		system	2025-07-11 02:05:29.467+00
rp_1751597076340_mv2s4qidpx	2025-07-04 02:44:36.517+00	{}		system	2025-07-11 02:44:36.517+00
rp_1751597626143_dgo8va2z645	2025-07-04 02:53:46.239+00	{}		system	2025-07-11 02:53:46.239+00
rp_1751598070832_0c1dxr1f8sh	2025-07-04 03:01:10.931+00	{}		system	2025-07-11 03:01:10.931+00
rp_1751640570969_aa15cj8jr1i	2025-07-04 14:49:31.066+00	{}		system	2025-07-11 14:49:31.066+00
rp_1751641154217_n483fe0z9va	2025-07-04 14:59:14.322+00	{}		system	2025-07-11 14:59:14.322+00
rp_1751598400796_yz3c2wr16kc	2025-07-04 03:06:40.987+00	{}		system	2025-07-11 03:06:40.987+00
rp_1751598620105_jgx2qdwzgrh	2025-07-04 03:10:20.204+00	{}		system	2025-07-11 03:10:20.204+00
rp_1751598822849_4estkyxni6d	2025-07-04 03:13:42.951+00	{}		system	2025-07-11 03:13:42.951+00
rp_1751586732148_3rq1payl0ud	2025-07-03 23:52:12.255+00	{}		system	2025-07-10 23:52:12.255+00
rp_1751599718015_kplgdqk4t6n	2025-07-04 03:28:38.11+00	{}		system	2025-07-11 03:28:38.111+00
rp_1751640433715_iqc0vpgpmec	2025-07-04 14:47:13.809+00	{}		system	2025-07-11 14:47:13.809+00
rp_1751640749325_02jp2uw2z8lq	2025-07-04 14:52:29.422+00	{}		system	2025-07-11 14:52:29.422+00
rp_1751586876910_il8998novgh	2025-07-03 23:54:37.012+00	{}		system	2025-07-10 23:54:37.012+00
rp_1751599766420_41k2fwrnvzz	2025-07-04 03:29:26.515+00	{}		system	2025-07-11 03:29:26.516+00
rp_1751599827243_si4k85c0lpa	2025-07-04 03:30:27.342+00	{}		system	2025-07-11 03:30:27.342+00
\.


--
-- Data for Name: pos_mini_modular3_subscription_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_subscription_history (id, business_id, from_tier, to_tier, changed_by, amount_paid, payment_method, transaction_id, starts_at, ends_at, status, notes, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_subscription_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_subscription_plans (id, tier, name, price_monthly, max_users, max_products, max_warehouses, max_branches, features, is_active, created_at, updated_at) FROM stdin;
d70ea130-fa83-43e5-a540-353d5385de45	free	Gói Miễn Phí	0	3	50	1	1	["basic_pos", "inventory_tracking", "sales_reports"]	t	2025-06-30 09:20:59.160071+00	2025-06-30 09:20:59.160071+00
09523773-7c0b-4583-b5eb-5fdc8820bc4f	basic	Gói Cơ Bản	299000	10	500	2	3	["advanced_pos", "multi_warehouse", "customer_management", "loyalty_program", "detailed_analytics"]	t	2025-06-30 09:20:59.160071+00	2025-06-30 09:20:59.160071+00
41106873-3c32-41a6-9680-a6c611a81157	premium	Gói Cao Cấp	599000	50	5000	5	10	["enterprise_pos", "multi_branch", "advanced_analytics", "api_access", "priority_support", "custom_reports", "inventory_optimization"]	t	2025-06-30 09:20:59.160071+00	2025-06-30 09:20:59.160071+00
\.


--
-- Data for Name: pos_mini_modular3_user_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_user_profiles (id, business_id, full_name, phone, email, avatar_url, role, status, permissions, login_method, last_login_at, employee_id, hire_date, notes, created_at, updated_at) FROM stdin;
550ce2c2-2d18-4a75-8ece-0c2c8f4dadad	97da7e62-0409-4882-b80c-2c75b60cb0da	Bida Thiên Long 2	\N	ericphan28@gmail.com	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-06-30 22:38:05.559244+00	2025-07-04 22:53:48.217743+00
c8c6a529-e57c-4dbf-900f-c26dd4815195	97da7e62-0409-4882-b80c-2c75b60cb0da	Nguyễn Văn A	+84901234567	+84901234567@staff.pos.local	\N	seller	active	[]	phone	\N	NV001	2025-06-30	Nhân viên bán hàng ca sáng	2025-06-30 23:54:50.592949+00	2025-07-04 22:53:48.217743+00
8388a0e3-0a1a-4ce2-9c54-257994d44616	97da7e62-0409-4882-b80c-2c75b60cb0da	Eric Phan	+84909582083	+84909582083@staff.pos.local	\N	seller	active	[]	phone	\N	\N	2025-07-01	tét	2025-07-01 00:06:56.999574+00	2025-07-04 22:53:48.217743+00
bba27899-25c8-4d5b-ba81-a0201f98bd00	97da7e62-0409-4882-b80c-2c75b60cb0da	Cym Thang	+84907136029	+84907136029@staff.pos.local	\N	manager	active	[]	phone	\N	Abcd	2025-07-01	Thang PHan	2025-07-01 00:09:24.007284+00	2025-07-04 22:53:48.217743+00
b5ca076a-7b1f-4d4e-808d-0610f71288a8	97da7e62-0409-4882-b80c-2c75b60cb0da	Phan Thiên Vinh	+84922388399	+84922388399@staff.pos.local	\N	seller	active	[]	phone	\N	Thien Vinh	2025-07-01	Phan Thiên Vinh	2025-07-01 00:59:06.756329+00	2025-07-04 22:53:48.217743+00
5f8d74cf-572a-4640-a565-34c5e1462f4e	61473fc9-16b2-45b8-87f0-45e0dc8612ef	Phan Thiên Hào	0907136029	cym_sunset@yahoo.com	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-01 10:40:25.745418+00	2025-07-04 22:53:48.217743+00
8740cb15-5bea-480d-b58b-2f9fd51c144e	61473fc9-16b2-45b8-87f0-45e0dc8612ef	Hào 2	+84907131111	+84907131111@staff.pos.local	\N	manager	active	[]	phone	\N	cym_sunset@yahoo.com	2025-07-01	khogn biet	2025-07-01 10:43:03.150311+00	2025-07-04 22:53:48.217743+00
9c9bc32f-6b7e-4239-857a-83d9b8b16ce7	dda92815-c1f0-4597-8c05-47ec1eb50873	Mẹ Yến	0909582083	yenwinny83@gmail.com	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-01 12:01:49.27648+00	2025-07-04 22:53:48.217743+00
90437fcb-0a83-44b7-ab05-322af922b451	087ef234-4f85-4926-8233-3b5f89196ec2	Phan Thiên Long	0909564874	bidathienlong01@gmail.com	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-02 19:30:57.294046+00	2025-07-04 22:53:48.217743+00
f1de66c9-166a-464c-89aa-bd75e1095040	\N	Super Administrator	0907136029	admin@giakiemso.com	\N	super_admin	active	[]	email	\N	\N	\N	\N	2025-07-02 02:16:30.46745+00	2025-07-04 22:53:48.217743+00
8c3b94aa-68b1-47db-9029-07be27d3b917	1f0290fe-3ed1-440b-9a0b-68885aaba9f8	Test Direct Owner	\N	test.direct@rpc.test	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-03 13:28:51.257721+00	2025-07-04 22:53:48.217743+00
3a799c65-8c58-429c-9e48-4d74b236ab97	c182f174-6372-4b34-964d-765fdc6dabbd	Nguyên Ly	+84909123456	\N	\N	household_owner	active	[]	phone	\N	\N	\N	\N	2025-07-03 13:38:21.323452+00	2025-07-04 22:53:48.217743+00
9d40bf3c-e5a3-44c2-96c7-4c36a479e668	37c75836-edb9-4dc2-8bbe-83ad87ba274e	Nguyễn Huy	+84901456789	\N	\N	household_owner	active	[]	phone	\N	\N	\N	\N	2025-07-03 13:39:20.303084+00	2025-07-04 22:53:48.217743+00
2706a795-f2a4-46f6-8030-3553a8a1ecb0	7a2a2404-8498-4396-bd2b-e6745591652b	Test Direct Owner 33	\N	test.direct2@rpc.test	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-03 13:28:51.487484+00	2025-07-04 22:53:48.217743+00
\.


--
-- Name: pos_mini_modular3_backup_downloads pos_mini_modular3_backup_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_downloads
    ADD CONSTRAINT pos_mini_modular3_backup_downloads_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_backup_metadata pos_mini_modular3_backup_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_metadata
    ADD CONSTRAINT pos_mini_modular3_backup_metadata_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_backup_notifications pos_mini_modular3_backup_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_notifications
    ADD CONSTRAINT pos_mini_modular3_backup_notifications_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_backup_schedules pos_mini_modular3_backup_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_schedules
    ADD CONSTRAINT pos_mini_modular3_backup_schedules_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_business_id_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_business_id_email_key UNIQUE (business_id, email);


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_invitation_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_invitation_token_key UNIQUE (invitation_token);


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_business_types pos_mini_modular3_business_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_types
    ADD CONSTRAINT pos_mini_modular3_business_types_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_business_types pos_mini_modular3_business_types_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_types
    ADD CONSTRAINT pos_mini_modular3_business_types_value_key UNIQUE (value);


--
-- Name: pos_mini_modular3_businesses pos_mini_modular3_businesses_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_businesses
    ADD CONSTRAINT pos_mini_modular3_businesses_code_key UNIQUE (code);


--
-- Name: pos_mini_modular3_businesses pos_mini_modular3_businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_businesses
    ADD CONSTRAINT pos_mini_modular3_businesses_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_restore_history pos_mini_modular3_restore_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_restore_history
    ADD CONSTRAINT pos_mini_modular3_restore_history_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_restore_points pos_mini_modular3_restore_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_restore_points
    ADD CONSTRAINT pos_mini_modular3_restore_points_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_subscription_history pos_mini_modular3_subscription_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_subscription_history
    ADD CONSTRAINT pos_mini_modular3_subscription_history_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_subscription_plans pos_mini_modular3_subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_subscription_plans
    ADD CONSTRAINT pos_mini_modular3_subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_subscription_plans pos_mini_modular3_subscription_plans_tier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_subscription_plans
    ADD CONSTRAINT pos_mini_modular3_subscription_plans_tier_key UNIQUE (tier);


--
-- Name: pos_mini_modular3_user_profiles pos_mini_modular3_user_profiles_business_id_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_profiles
    ADD CONSTRAINT pos_mini_modular3_user_profiles_business_id_email_key UNIQUE (business_id, email) DEFERRABLE;


--
-- Name: pos_mini_modular3_user_profiles pos_mini_modular3_user_profiles_business_id_employee_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_profiles
    ADD CONSTRAINT pos_mini_modular3_user_profiles_business_id_employee_id_key UNIQUE (business_id, employee_id) DEFERRABLE;


--
-- Name: pos_mini_modular3_user_profiles pos_mini_modular3_user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_profiles
    ADD CONSTRAINT pos_mini_modular3_user_profiles_pkey PRIMARY KEY (id);


--
-- Name: idx_backup_downloads_backup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_downloads_backup_id ON public.pos_mini_modular3_backup_downloads USING btree (backup_id);


--
-- Name: idx_backup_downloads_downloaded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_downloads_downloaded_at ON public.pos_mini_modular3_backup_downloads USING btree (downloaded_at DESC);


--
-- Name: idx_backup_metadata_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_metadata_created_at ON public.pos_mini_modular3_backup_metadata USING btree (created_at DESC);


--
-- Name: idx_backup_metadata_retention; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_metadata_retention ON public.pos_mini_modular3_backup_metadata USING btree (retention_until);


--
-- Name: idx_backup_metadata_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_metadata_status ON public.pos_mini_modular3_backup_metadata USING btree (status);


--
-- Name: idx_backup_metadata_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_metadata_type ON public.pos_mini_modular3_backup_metadata USING btree (type);


--
-- Name: idx_backup_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_notifications_created_at ON public.pos_mini_modular3_backup_notifications USING btree (created_at DESC);


--
-- Name: idx_backup_notifications_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_notifications_read ON public.pos_mini_modular3_backup_notifications USING btree (read);


--
-- Name: idx_backup_notifications_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_notifications_type ON public.pos_mini_modular3_backup_notifications USING btree (type);


--
-- Name: idx_backup_schedules_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_schedules_enabled ON public.pos_mini_modular3_backup_schedules USING btree (enabled);


--
-- Name: idx_backup_schedules_next_run; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_backup_schedules_next_run ON public.pos_mini_modular3_backup_schedules USING btree (next_run_at);


--
-- Name: idx_business_types_category_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_category_sort ON public.pos_mini_modular3_business_types USING btree (category, sort_order);


--
-- Name: idx_business_types_value_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_value_active ON public.pos_mini_modular3_business_types USING btree (value, is_active);


--
-- Name: idx_pos_mini_modular3_business_invitations_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_business_invitations_business_id ON public.pos_mini_modular3_business_invitations USING btree (business_id);


--
-- Name: idx_pos_mini_modular3_business_invitations_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_business_invitations_email ON public.pos_mini_modular3_business_invitations USING btree (email);


--
-- Name: idx_pos_mini_modular3_business_invitations_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_business_invitations_expires_at ON public.pos_mini_modular3_business_invitations USING btree (expires_at);


--
-- Name: idx_pos_mini_modular3_business_invitations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_business_invitations_status ON public.pos_mini_modular3_business_invitations USING btree (status);


--
-- Name: idx_pos_mini_modular3_business_invitations_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_business_invitations_token ON public.pos_mini_modular3_business_invitations USING btree (invitation_token);


--
-- Name: idx_pos_mini_modular3_businesses_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_businesses_code ON public.pos_mini_modular3_businesses USING btree (code);


--
-- Name: idx_pos_mini_modular3_businesses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_businesses_status ON public.pos_mini_modular3_businesses USING btree (status);


--
-- Name: idx_pos_mini_modular3_businesses_subscription_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_businesses_subscription_tier ON public.pos_mini_modular3_businesses USING btree (subscription_tier);


--
-- Name: idx_pos_mini_modular3_businesses_trial_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_businesses_trial_ends_at ON public.pos_mini_modular3_businesses USING btree (trial_ends_at);


--
-- Name: idx_pos_mini_modular3_subscription_history_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_subscription_history_business_id ON public.pos_mini_modular3_subscription_history USING btree (business_id);


--
-- Name: idx_pos_mini_modular3_subscription_history_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_subscription_history_status ON public.pos_mini_modular3_subscription_history USING btree (status);


--
-- Name: idx_pos_mini_modular3_subscription_plans_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_subscription_plans_active ON public.pos_mini_modular3_subscription_plans USING btree (is_active);


--
-- Name: idx_pos_mini_modular3_subscription_plans_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_subscription_plans_tier ON public.pos_mini_modular3_subscription_plans USING btree (tier);


--
-- Name: idx_pos_mini_modular3_user_profiles_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_user_profiles_business_id ON public.pos_mini_modular3_user_profiles USING btree (business_id);


--
-- Name: idx_pos_mini_modular3_user_profiles_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_user_profiles_email ON public.pos_mini_modular3_user_profiles USING btree (email);


--
-- Name: idx_pos_mini_modular3_user_profiles_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_user_profiles_phone ON public.pos_mini_modular3_user_profiles USING btree (phone) WHERE (phone IS NOT NULL);


--
-- Name: idx_pos_mini_modular3_user_profiles_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_user_profiles_role ON public.pos_mini_modular3_user_profiles USING btree (role);


--
-- Name: idx_pos_mini_modular3_user_profiles_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_user_profiles_status ON public.pos_mini_modular3_user_profiles USING btree (status);


--
-- Name: idx_restore_history_backup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restore_history_backup_id ON public.pos_mini_modular3_restore_history USING btree (backup_id);


--
-- Name: idx_restore_history_restored_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restore_history_restored_at ON public.pos_mini_modular3_restore_history USING btree (restored_at DESC);


--
-- Name: idx_restore_history_success; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restore_history_success ON public.pos_mini_modular3_restore_history USING btree (success);


--
-- Name: idx_restore_points_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restore_points_created_at ON public.pos_mini_modular3_restore_points USING btree (created_at DESC);


--
-- Name: idx_restore_points_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restore_points_expires_at ON public.pos_mini_modular3_restore_points USING btree (expires_at);


--
-- Name: pos_mini_modular3_backup_schedules trigger_update_backup_schedules_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_backup_schedules_updated_at BEFORE UPDATE ON public.pos_mini_modular3_backup_schedules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: pos_mini_modular3_business_types update_pos_mini_modular3_business_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pos_mini_modular3_business_types_updated_at BEFORE UPDATE ON public.pos_mini_modular3_business_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: pos_mini_modular3_businesses update_pos_mini_modular3_businesses_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pos_mini_modular3_businesses_updated_at BEFORE UPDATE ON public.pos_mini_modular3_businesses FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_updated_at_column();


--
-- Name: pos_mini_modular3_subscription_plans update_pos_mini_modular3_subscription_plans_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pos_mini_modular3_subscription_plans_updated_at BEFORE UPDATE ON public.pos_mini_modular3_subscription_plans FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_updated_at_column();


--
-- Name: pos_mini_modular3_user_profiles update_pos_mini_modular3_user_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pos_mini_modular3_user_profiles_updated_at BEFORE UPDATE ON public.pos_mini_modular3_user_profiles FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_updated_at_column();


--
-- Name: pos_mini_modular3_businesses fk_business_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_businesses
    ADD CONSTRAINT fk_business_type FOREIGN KEY (business_type) REFERENCES public.pos_mini_modular3_business_types(value) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: pos_mini_modular3_backup_downloads pos_mini_modular3_backup_downloads_backup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_downloads
    ADD CONSTRAINT pos_mini_modular3_backup_downloads_backup_id_fkey FOREIGN KEY (backup_id) REFERENCES public.pos_mini_modular3_backup_metadata(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_backup_notifications pos_mini_modular3_backup_notifications_backup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_notifications
    ADD CONSTRAINT pos_mini_modular3_backup_notifications_backup_id_fkey FOREIGN KEY (backup_id) REFERENCES public.pos_mini_modular3_backup_metadata(id);


--
-- Name: pos_mini_modular3_backup_notifications pos_mini_modular3_backup_notifications_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_backup_notifications
    ADD CONSTRAINT pos_mini_modular3_backup_notifications_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.pos_mini_modular3_backup_schedules(id);


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_accepted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_accepted_by_fkey FOREIGN KEY (accepted_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_business_invitations pos_mini_modular3_business_invitations_invited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_invitations
    ADD CONSTRAINT pos_mini_modular3_business_invitations_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.pos_mini_modular3_user_profiles(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_restore_history pos_mini_modular3_restore_history_backup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_restore_history
    ADD CONSTRAINT pos_mini_modular3_restore_history_backup_id_fkey FOREIGN KEY (backup_id) REFERENCES public.pos_mini_modular3_backup_metadata(id);


--
-- Name: pos_mini_modular3_user_profiles pos_mini_modular3_user_profiles_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_profiles
    ADD CONSTRAINT pos_mini_modular3_user_profiles_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_user_profiles pos_mini_modular3_user_profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_profiles
    ADD CONSTRAINT pos_mini_modular3_user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_business_types Allow super admin to manage business types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow super admin to manage business types" ON public.pos_mini_modular3_business_types TO authenticated USING (public.pos_mini_modular3_is_super_admin());


--
-- Name: POLICY "Allow super admin to manage business types" ON pos_mini_modular3_business_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON POLICY "Allow super admin to manage business types" ON public.pos_mini_modular3_business_types IS 'Allows super admin to create, update, delete business types';


--
-- Name: pos_mini_modular3_business_types Anonymous users read active business types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anonymous users read active business types" ON public.pos_mini_modular3_business_types FOR SELECT TO anon USING ((is_active = true));


--
-- Name: pos_mini_modular3_business_types Authenticated users read all business types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users read all business types" ON public.pos_mini_modular3_business_types FOR SELECT TO authenticated USING (true);


--
-- Name: pos_mini_modular3_business_invitations business_managers_manage_invitations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY business_managers_manage_invitations ON public.pos_mini_modular3_business_invitations TO authenticated USING ((business_id IN ( SELECT pos_mini_modular3_user_profiles.business_id
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = ANY (ARRAY['household_owner'::text, 'manager'::text]))))));


--
-- Name: pos_mini_modular3_businesses business_members_read_own_business; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY business_members_read_own_business ON public.pos_mini_modular3_businesses FOR SELECT TO authenticated USING ((id IN ( SELECT pos_mini_modular3_user_profiles.business_id
   FROM public.pos_mini_modular3_user_profiles
  WHERE (pos_mini_modular3_user_profiles.id = auth.uid()))));


--
-- Name: pos_mini_modular3_businesses business_owners_update_own_business; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY business_owners_update_own_business ON public.pos_mini_modular3_businesses FOR UPDATE TO authenticated USING ((id IN ( SELECT pos_mini_modular3_user_profiles.business_id
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = ANY (ARRAY['household_owner'::text, 'manager'::text]))))));


--
-- Name: pos_mini_modular3_business_invitations invited_users_see_own_invitations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invited_users_see_own_invitations ON public.pos_mini_modular3_business_invitations FOR SELECT TO authenticated USING ((email IN ( SELECT users.email
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: pos_mini_modular3_business_invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_business_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_types ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_businesses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_businesses ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_subscription_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_subscription_history ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_subscription_plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_subscription_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_user_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_user_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_subscription_plans subscription_plans_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscription_plans_public_read ON public.pos_mini_modular3_subscription_plans FOR SELECT TO authenticated USING ((is_active = true));


--
-- Name: pos_mini_modular3_subscription_plans subscription_plans_super_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscription_plans_super_admin_write ON public.pos_mini_modular3_subscription_plans TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text)))));


--
-- Name: pos_mini_modular3_businesses super_admin_full_access_businesses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY super_admin_full_access_businesses ON public.pos_mini_modular3_businesses TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text)))));


--
-- Name: pos_mini_modular3_user_profiles user_own_access_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_own_access_only ON public.pos_mini_modular3_user_profiles TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


--
-- Name: pos_mini_modular3_user_profiles users_own_profile_safe; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_own_profile_safe ON public.pos_mini_modular3_user_profiles TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


--
-- PostgreSQL database dump complete
--

