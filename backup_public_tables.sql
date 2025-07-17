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
-- Name: pos_mini_modular3_add_inventory_transaction(uuid, uuid, integer, uuid, text, text, uuid, text, numeric, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_add_inventory_transaction(p_business_id uuid, p_product_id uuid, p_quantity_change integer, p_variant_id uuid DEFAULT NULL::uuid, p_transaction_type text DEFAULT 'adjustment'::text, p_reference_type text DEFAULT 'manual'::text, p_reference_id uuid DEFAULT NULL::uuid, p_notes text DEFAULT NULL::text, p_unit_cost numeric DEFAULT NULL::numeric, p_created_by uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_current_quantity integer;
    v_new_quantity integer;
    v_transaction_id uuid;
BEGIN
    -- Get current quantity
    SELECT COALESCE(MAX(quantity_after), 0)
    INTO v_current_quantity
    FROM pos_mini_modular3_product_inventory
    WHERE product_id = p_product_id
    AND (p_variant_id IS NULL OR variant_id = p_variant_id)
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Calculate new quantity
    v_new_quantity := v_current_quantity + p_quantity_change;
    
    -- Prevent negative inventory
    IF v_new_quantity < 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'NEGATIVE_INVENTORY',
            'message', 'Số lượng tồn kho không thể âm',
            'current_quantity', v_current_quantity,
            'requested_change', p_quantity_change
        );
    END IF;
    
    -- Insert inventory transaction
    INSERT INTO pos_mini_modular3_product_inventory (
        business_id,
        product_id,
        variant_id,
        transaction_type,
        quantity_change,
        quantity_after,
        reference_type,
        reference_id,
        notes,
        unit_cost,
        created_by
    ) VALUES (
        p_business_id,
        p_product_id,
        p_variant_id,
        p_transaction_type,
        p_quantity_change,
        v_new_quantity,
        p_reference_type,
        p_reference_id,
        p_notes,
        p_unit_cost,
        p_created_by
    ) RETURNING id INTO v_transaction_id;
    
    -- Update variant inventory if variant specified
    IF p_variant_id IS NOT NULL THEN
        UPDATE pos_mini_modular3_product_variants
        SET 
            inventory_quantity = v_new_quantity,
            updated_at = now()
        WHERE id = p_variant_id;
    END IF;
    
    -- Update product inventory cache
    PERFORM pos_mini_modular3_update_product_inventory_cache(p_product_id);
    
    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'previous_quantity', v_current_quantity,
        'quantity_change', p_quantity_change,
        'new_quantity', v_new_quantity
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'TRANSACTION_FAILED',
            'message', 'Lỗi khi cập nhật tồn kho',
            'error_detail', SQLERRM
        );
END;
$$;


--
-- Name: pos_mini_modular3_auto_setup_categories(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_auto_setup_categories(p_business_id uuid, p_business_type text DEFAULT 'retail'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_template record;
    v_category record;
    v_parent_id uuid;
    v_category_id uuid;
    v_categories_created integer := 0;
    v_result jsonb;
BEGIN
    -- Check if business exists
    IF NOT EXISTS (SELECT 1 FROM pos_mini_modular3_businesses WHERE id = p_business_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND',
            'message', 'Doanh nghiệp không tồn tại'
        );
    END IF;
    
    -- Check if categories already exist
    IF EXISTS (SELECT 1 FROM pos_mini_modular3_product_categories WHERE business_id = p_business_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'CATEGORIES_ALREADY_EXIST',
            'message', 'Danh mục sản phẩm đã được thiết lập cho doanh nghiệp này'
        );
    END IF;
    
    -- First pass: Create root categories (no parent)
    FOR v_template IN 
        SELECT * FROM pos_mini_modular3_business_type_category_templates 
        WHERE business_type = p_business_type 
        AND parent_category_name IS NULL
        AND is_active = true
        ORDER BY sort_order, category_name
    LOOP
        INSERT INTO pos_mini_modular3_product_categories (
            business_id,
            name,
            description,
            icon,
            color_hex,
            parent_id,
            sort_order,
            is_active,
            is_default,
            is_required,
            allows_inventory,
            allows_variants,
            requires_description,
            slug
        ) VALUES (
            p_business_id,
            v_template.category_name,
            v_template.category_description,
            v_template.category_icon,
            v_template.category_color_hex,
            NULL, -- No parent for root categories
            v_template.sort_order,
            true,
            v_template.is_default,
            v_template.is_required,
            v_template.allows_inventory,
            v_template.allows_variants,
            v_template.requires_description,
            pos_mini_modular3_generate_category_slug(v_template.category_name, p_business_id)
        ) RETURNING id INTO v_category_id;
        
        v_categories_created := v_categories_created + 1;
    END LOOP;
    
    -- Second pass: Create child categories (with parent)
    FOR v_template IN 
        SELECT * FROM pos_mini_modular3_business_type_category_templates 
        WHERE business_type = p_business_type 
        AND parent_category_name IS NOT NULL
        AND is_active = true
        ORDER BY sort_order, category_name
    LOOP
        -- Find parent category ID
        SELECT id INTO v_parent_id
        FROM pos_mini_modular3_product_categories
        WHERE business_id = p_business_id
        AND name = v_template.parent_category_name;
        
        -- Only create if parent exists
        IF v_parent_id IS NOT NULL THEN
            INSERT INTO pos_mini_modular3_product_categories (
                business_id,
                name,
                description,
                icon,
                color_hex,
                parent_id,
                sort_order,
                is_active,
                is_default,
                is_required,
                allows_inventory,
                allows_variants,
                requires_description,
                slug
            ) VALUES (
                p_business_id,
                v_template.category_name,
                v_template.category_description,
                v_template.category_icon,
                v_template.category_color_hex,
                v_parent_id,
                v_template.sort_order,
                true,
                v_template.is_default,
                v_template.is_required,
                v_template.allows_inventory,
                v_template.allows_variants,
                v_template.requires_description,
                pos_mini_modular3_generate_category_slug(v_template.category_name, p_business_id)
            );
            
            v_categories_created := v_categories_created + 1;
        END IF;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'categories_created', v_categories_created,
        'business_type', p_business_type,
        'message', format('Đã tạo %s danh mục sản phẩm cho loại hình %s', v_categories_created, p_business_type)
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'AUTO_SETUP_FAILED',
            'message', 'Lỗi khi thiết lập danh mục tự động',
            'error_detail', SQLERRM
        );
END;
$$;


--
-- Name: pos_mini_modular3_bulk_update_inventory(uuid, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_bulk_update_inventory(p_business_id uuid, p_inventory_updates jsonb, p_updated_by uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_update record;
    v_success_count integer := 0;
    v_error_count integer := 0;
    v_errors jsonb := '[]'::jsonb;
    v_result jsonb;
BEGIN
    -- Process each inventory update
    FOR v_update IN SELECT * FROM jsonb_array_elements(p_inventory_updates)
    LOOP
        BEGIN
            -- Add inventory transaction
            SELECT pos_mini_modular3_add_inventory_transaction(
                p_business_id,
                (v_update->>'product_id')::uuid,
                (v_update->>'variant_id')::uuid,
                (v_update->>'quantity_change')::integer,
                COALESCE(v_update->>'transaction_type', 'adjustment'),
                COALESCE(v_update->>'reference_type', 'bulk_update'),
                (v_update->>'reference_id')::uuid,
                v_update->>'notes',
                (v_update->>'unit_cost')::decimal,
                p_updated_by
            ) INTO v_result;
            
            IF v_result->>'success' = 'true' THEN
                v_success_count := v_success_count + 1;
            ELSE
                v_error_count := v_error_count + 1;
                v_errors := v_errors || jsonb_build_object(
                    'product_id', v_update->>'product_id',
                    'variant_id', v_update->>'variant_id',
                    'error', v_result->>'error',
                    'message', v_result->>'message'
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                v_errors := v_errors || jsonb_build_object(
                    'product_id', v_update->>'product_id',
                    'variant_id', v_update->>'variant_id',
                    'error', 'TRANSACTION_FAILED',
                    'message', SQLERRM
                );
        END;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', v_error_count = 0,
        'success_count', v_success_count,
        'error_count', v_error_count,
        'errors', v_errors,
        'message', format('Đã cập nhật %s sản phẩm thành công, %s lỗi', v_success_count, v_error_count)
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BULK_UPDATE_FAILED',
            'message', 'Lỗi khi cập nhật hàng loạt',
            'error_detail', SQLERRM
        );
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
-- Name: pos_mini_modular3_category_auto_slug(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_category_auto_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Generate slug if not provided or name changed
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.name != NEW.name) THEN
        NEW.slug := pos_mini_modular3_generate_category_slug(NEW.name, NEW.business_id);
    END IF;
    
    -- Update timestamp
    NEW.updated_at := now();
    
    RETURN NEW;
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
-- Name: pos_mini_modular3_check_feature(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_feature(p_business_id uuid, p_feature_key text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_business_tier TEXT;
    v_feature_config JSONB;
    v_business_override RECORD;
    v_tier_default RECORD;
    v_feature RECORD;
BEGIN
    -- Get business subscription tier
    SELECT subscription_tier INTO v_business_tier
    FROM pos_mini_modular3_businesses
    WHERE id = p_business_id;
    
    -- Get feature definition
    SELECT * INTO v_feature
    FROM pos_mini_modular3_features
    WHERE feature_key = p_feature_key;
    
    IF v_feature IS NULL THEN
        RETURN jsonb_build_object('enabled', false, 'error', 'Feature not found');
    END IF;
    
    -- Check business-specific override first
    SELECT * INTO v_business_override
    FROM pos_mini_modular3_business_features bf
    WHERE bf.business_id = p_business_id 
    AND bf.feature_id = v_feature.id
    AND (bf.expires_at IS NULL OR bf.expires_at > NOW());
    
    IF v_business_override IS NOT NULL THEN
        RETURN jsonb_build_object(
            'enabled', v_business_override.is_enabled,
            'value', COALESCE(v_business_override.feature_value, v_feature.default_value),
            'source', 'business_override'
        );
    END IF;
    
    -- Check tier default
    SELECT * INTO v_tier_default
    FROM pos_mini_modular3_tier_features tf
    WHERE tf.subscription_tier = v_business_tier
    AND tf.feature_id = v_feature.id;
    
    IF v_tier_default IS NOT NULL THEN
        RETURN jsonb_build_object(
            'enabled', v_tier_default.is_enabled,
            'value', COALESCE(v_tier_default.feature_value, v_feature.default_value),
            'usage_limit', v_tier_default.usage_limit,
            'source', 'tier_default'
        );
    END IF;
    
    -- Return feature default
    RETURN jsonb_build_object(
        'enabled', false,
        'value', v_feature.default_value,
        'source', 'feature_default'
    );
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
-- Name: pos_mini_modular3_check_permission(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_permission(p_action character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_role VARCHAR(50);
BEGIN
    v_role := pos_mini_modular3_get_user_role();
    
    -- Owner has all permissions
    IF v_role = 'owner' THEN
        RETURN TRUE;
    END IF;
    
    -- Admin has most permissions
    IF v_role = 'admin' THEN
        RETURN p_action NOT IN ('delete_business', 'transfer_ownership');
    END IF;
    
    -- Manager permissions
    IF v_role = 'manager' THEN
        RETURN p_action IN (
            'view_products', 'create_product', 'update_product', 
            'view_sales', 'create_sale', 'view_reports'
        );
    END IF;
    
    -- Staff permissions
    IF v_role = 'staff' THEN
        RETURN p_action IN (
            'view_products', 'create_sale', 'view_own_sales'
        );
    END IF;
    
    RETURN FALSE;
END;
$$;


--
-- Name: pos_mini_modular3_check_product_limit(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_product_limit(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_subscription_tier TEXT;
    v_current_count INTEGER := 0;
    v_max_limit INTEGER;
    v_table_exists BOOLEAN;
    v_columns_info TEXT;
BEGIN
    -- Check if products table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'pos_mini_modular3_products'
    ) INTO v_table_exists;
    
    -- Get business subscription tier
    SELECT subscription_tier INTO v_subscription_tier
    FROM pos_mini_modular3_businesses
    WHERE id = p_business_id;
    
    -- Get current product count with error handling
    IF v_table_exists THEN
        BEGIN
            -- Try counting with is_active column
            SELECT COUNT(*) INTO v_current_count
            FROM pos_mini_modular3_products
            WHERE business_id = p_business_id 
            AND (is_active IS NULL OR is_active = true);
        EXCEPTION WHEN OTHERS THEN
            BEGIN
                -- Fallback: count all products if is_active column doesn't exist
                SELECT COUNT(*) INTO v_current_count
                FROM pos_mini_modular3_products
                WHERE business_id = p_business_id;
            EXCEPTION WHEN OTHERS THEN
                v_current_count := 0;
            END;
        END;
    END IF;
    
    -- Set limits based on tier
    CASE COALESCE(v_subscription_tier, 'free')
        WHEN 'free' THEN v_max_limit := 20;
        WHEN 'basic' THEN v_max_limit := 500;
        WHEN 'premium' THEN v_max_limit := 5000;
        WHEN 'enterprise' THEN v_max_limit := 50000;
        ELSE v_max_limit := 20;
    END CASE;
    
    RETURN jsonb_build_object(
        'can_create', v_current_count < v_max_limit,
        'current_count', v_current_count,
        'max_limit', v_max_limit,
        'tier', COALESCE(v_subscription_tier, 'free'),
        'remaining', v_max_limit - v_current_count,
        'table_exists', v_table_exists
    );
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
-- Name: pos_mini_modular3_check_user_permission(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_check_user_permission(p_user_id uuid, p_feature_name text, p_action text DEFAULT 'read'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
        b.subscription_status
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
$$;


--
-- Name: pos_mini_modular3_cleanup_expired_login_attempts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_cleanup_expired_login_attempts() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.pos_mini_modular3_failed_login_attempts
  WHERE is_locked = true 
  AND lock_expires_at IS NOT NULL 
  AND lock_expires_at < now();
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_cleanup_expired_login_attempts(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_cleanup_expired_login_attempts() IS 'Cleanup function for expired login attempt locks';


--
-- Name: pos_mini_modular3_cleanup_expired_sessions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_cleanup_expired_sessions() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.pos_mini_modular3_enhanced_user_sessions
  WHERE expires_at < now();
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_cleanup_expired_sessions(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_cleanup_expired_sessions() IS 'Cleanup function for expired user sessions';


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
-- Name: pos_mini_modular3_create_category(text, text, uuid, text, text, text, boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_category(p_name text, p_description text DEFAULT NULL::text, p_parent_id uuid DEFAULT NULL::uuid, p_color_code text DEFAULT NULL::text, p_icon_name text DEFAULT NULL::text, p_image_url text DEFAULT NULL::text, p_is_featured boolean DEFAULT false, p_display_order integer DEFAULT 0) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  new_category_id UUID;
  category_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Validate required fields
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên danh mục không được để trống'
    );
  END IF;
  
  -- Generate slug from name
  category_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
  category_slug := regexp_replace(category_slug, '\s+', '-', 'g');
  
  -- Validate parent category exists if provided
  IF p_parent_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_parent_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục cha không tồn tại'
      );
    END IF;
  END IF;
  
  -- Check if category name already exists in business
  IF EXISTS (
    SELECT 1 FROM pos_mini_modular3_product_categories 
    WHERE business_id = current_business_id AND name = trim(p_name)
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên danh mục đã tồn tại'
    );
  END IF;
  
  -- Insert new category
  INSERT INTO pos_mini_modular3_product_categories (
    business_id,
    parent_id,
    name,
    description,
    slug,
    color_code,
    icon_name,
    image_url,
    is_featured,
    display_order,
    created_by,
    updated_by
  ) VALUES (
    current_business_id,
    p_parent_id,
    trim(p_name),
    p_description,
    category_slug,
    p_color_code,
    p_icon_name,
    p_image_url,
    p_is_featured,
    p_display_order,
    current_user_id,
    current_user_id
  ) RETURNING id INTO new_category_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Danh mục đã được tạo thành công',
    'category_id', new_category_id,
    'slug', category_slug
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_create_category(p_name text, p_description text, p_parent_id uuid, p_color_code text, p_icon_name text, p_image_url text, p_is_featured boolean, p_display_order integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_create_category(p_name text, p_description text, p_parent_id uuid, p_color_code text, p_icon_name text, p_image_url text, p_is_featured boolean, p_display_order integer) IS 'Create a new product category with validation and business isolation';


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
-- Name: pos_mini_modular3_create_product(text, text, uuid, text, text, numeric, numeric, integer, integer, text, boolean, boolean, boolean, text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_product(p_name text, p_description text DEFAULT NULL::text, p_category_id uuid DEFAULT NULL::uuid, p_sku text DEFAULT NULL::text, p_barcode text DEFAULT NULL::text, p_unit_price numeric DEFAULT 0, p_cost_price numeric DEFAULT 0, p_current_stock integer DEFAULT 0, p_min_stock_level integer DEFAULT 5, p_unit_of_measure text DEFAULT 'piece'::text, p_track_stock boolean DEFAULT true, p_is_active boolean DEFAULT true, p_is_featured boolean DEFAULT false, p_tags text[] DEFAULT '{}'::text[], p_primary_image text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_business_id uuid;
    v_sku text;
    v_product_id uuid;
    v_result jsonb;
    v_category_name text;
BEGIN
    -- Get business_id from session
    v_business_id := pos_mini_modular3_get_session_business_id();
    
    IF v_business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Không thể xác định business_id từ session'
        );
    END IF;

    -- Check product limit for business
    IF NOT pos_mini_modular3_check_product_limit(v_business_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Đã đạt giới hạn số sản phẩm cho gói dịch vụ hiện tại'
        );
    END IF;

    -- Validate required fields
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Tên sản phẩm không được để trống'
        );
    END IF;

    -- Generate SKU if not provided
    v_sku := COALESCE(p_sku, pos_mini_modular3_generate_sku(v_business_id, p_name));

    -- Check SKU uniqueness
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_products 
        WHERE business_id = v_business_id AND sku = v_sku
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SKU đã tồn tại: ' || v_sku
        );
    END IF;

    -- Generate new product ID
    v_product_id := gen_random_uuid();

    -- Insert product with basic required fields
    INSERT INTO pos_mini_modular3_products (
        id, business_id, name, sku, 
        unit_price, current_stock, min_stock_level,
        created_at, updated_at
    ) VALUES (
        v_product_id, v_business_id, p_name, v_sku,
        p_unit_price, p_current_stock, p_min_stock_level,
        NOW(), NOW()
    );

    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'id', v_product_id,
            'business_id', v_business_id,
            'name', p_name,
            'sku', v_sku,
            'unit_price', p_unit_price,
            'current_stock', p_current_stock,
            'min_stock_level', p_min_stock_level
        )
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Lỗi khi tạo sản phẩm: ' || SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_create_product_complete(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_product_complete(p_product_data jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_business_id uuid;
    v_product_id uuid;
    v_sku text;
    v_slug text;
    v_result jsonb;
BEGIN
    -- Get business_id
    v_business_id := pos_mini_modular3_get_session_business_id();
    
    IF v_business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND',
            'message', 'Không thể xác định business_id'
        );
    END IF;

    -- Validate required fields
    IF NOT (p_product_data ? 'name') OR (p_product_data->>'name') = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_DATA',
            'message', 'Tên sản phẩm không được trống'
        );
    END IF;

    -- Check product limit
    IF NOT (pos_mini_modular3_check_product_limit(v_business_id)->>'can_create')::boolean THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'PRODUCT_LIMIT_EXCEEDED',
            'message', 'Đã đạt giới hạn số sản phẩm cho gói hiện tại'
        );
    END IF;

    -- Generate SKU và slug
    v_sku := COALESCE(p_product_data->>'sku', pos_mini_modular3_generate_sku(v_business_id));
    v_slug := pos_mini_modular3_generate_product_slug(p_product_data->>'name', v_business_id);
    
    -- Check SKU uniqueness
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_products 
        WHERE business_id = v_business_id AND sku = v_sku
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'DUPLICATE_SKU',
            'message', 'SKU đã tồn tại: ' || v_sku
        );
    END IF;

    -- Generate product ID
    v_product_id := gen_random_uuid();

    -- Insert product
    INSERT INTO pos_mini_modular3_products (
        id, business_id, category_id, name, description, short_description,
        sku, barcode, price, cost_price, compare_at_price, unit_price, sale_price,
        product_type, has_variants, variant_options,
        track_inventory, track_stock, inventory_policy,
        current_stock, total_inventory, available_inventory, min_stock_level,
        weight, dimensions, images, featured_image, primary_image,
        slug, tags, specifications, meta_title, meta_description,
        status, is_active, is_featured, is_digital, requires_shipping,
        is_taxable, tax_rate, created_at, updated_at
    ) VALUES (
        v_product_id,
        v_business_id,
        NULLIF(p_product_data->>'category_id', '')::uuid,
        p_product_data->>'name',
        p_product_data->>'description',
        p_product_data->>'short_description',
        v_sku,
        p_product_data->>'barcode',
        COALESCE((p_product_data->>'price')::numeric, 0),
        COALESCE((p_product_data->>'cost_price')::numeric, 0),
        NULLIF(p_product_data->>'compare_at_price', '')::numeric,
        COALESCE((p_product_data->>'unit_price')::numeric, (p_product_data->>'price')::numeric, 0),
        NULLIF(p_product_data->>'sale_price', '')::numeric,
        COALESCE(p_product_data->>'product_type', 'simple'),
        COALESCE((p_product_data->>'has_variants')::boolean, false),
        COALESCE(p_product_data->'variant_options', '[]'::jsonb),
        COALESCE((p_product_data->>'track_inventory')::boolean, true),
        COALESCE((p_product_data->>'track_stock')::boolean, true),
        COALESCE(p_product_data->>'inventory_policy', 'deny'),
        COALESCE((p_product_data->>'current_stock')::integer, 0),
        COALESCE((p_product_data->>'total_inventory')::integer, 0),
        COALESCE((p_product_data->>'available_inventory')::integer, 0),
        COALESCE((p_product_data->>'min_stock_level')::integer, 5),
        NULLIF(p_product_data->>'weight', '')::numeric,
        COALESCE(p_product_data->'dimensions', '{}'::jsonb),
        COALESCE(p_product_data->'images', '[]'::jsonb),
        p_product_data->>'featured_image',
        p_product_data->>'primary_image',
        v_slug,
        COALESCE(p_product_data->'tags', '[]'::jsonb),
        COALESCE(p_product_data->'specifications', '{}'::jsonb),
        p_product_data->>'meta_title',
        p_product_data->>'meta_description',
        COALESCE(p_product_data->>'status', 'draft'),
        COALESCE((p_product_data->>'is_active')::boolean, true),
        COALESCE((p_product_data->>'is_featured')::boolean, false),
        COALESCE((p_product_data->>'is_digital')::boolean, false),
        COALESCE((p_product_data->>'requires_shipping')::boolean, true),
        COALESCE((p_product_data->>'is_taxable')::boolean, true),
        COALESCE((p_product_data->>'tax_rate')::numeric, 0),
        now(),
        now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'id', v_product_id,
            'business_id', v_business_id,
            'sku', v_sku,
            'slug', v_slug,
            'name', p_product_data->>'name'
        ),
        'message', 'Sản phẩm đã được tạo thành công'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'CREATE_FAILED',
        'message', 'Lỗi khi tạo sản phẩm',
        'error_detail', SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_create_product_v2(text, text, uuid, text, text, numeric, numeric, numeric, integer, integer, boolean, boolean, boolean, boolean, boolean, boolean, numeric, jsonb, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_product_v2(p_name text, p_description text DEFAULT NULL::text, p_category_id uuid DEFAULT NULL::uuid, p_sku text DEFAULT NULL::text, p_barcode text DEFAULT NULL::text, p_price numeric DEFAULT 0, p_cost_price numeric DEFAULT 0, p_compare_at_price numeric DEFAULT NULL::numeric, p_current_stock integer DEFAULT 0, p_min_stock_level integer DEFAULT 5, p_track_stock boolean DEFAULT true, p_is_active boolean DEFAULT true, p_is_featured boolean DEFAULT false, p_is_digital boolean DEFAULT false, p_requires_shipping boolean DEFAULT true, p_is_taxable boolean DEFAULT true, p_tax_rate numeric DEFAULT 0, p_tags jsonb DEFAULT '[]'::jsonb, p_primary_image text DEFAULT NULL::text, p_specifications jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_business_id uuid;
    v_sku text;
    v_product_id uuid;
    v_slug text;
    v_result jsonb;
BEGIN
    -- Get business_id from current user
    v_business_id := pos_mini_modular3_current_user_business_id();
    
    IF v_business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND',
            'message', 'Không thể xác định business_id'
        );
    END IF;

    -- Check product limit
    DECLARE
        v_limit_check jsonb;
    BEGIN
        v_limit_check := pos_mini_modular3_check_product_limit(v_business_id);
        IF NOT (v_limit_check->>'can_create')::boolean THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'PRODUCT_LIMIT_EXCEEDED',
                'message', 'Đã đạt giới hạn số sản phẩm',
                'limit_info', v_limit_check
            );
        END IF;
    END;

    -- Validate required fields
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_NAME',
            'message', 'Tên sản phẩm không được để trống'
        );
    END IF;

    -- Generate SKU if not provided
    v_sku := COALESCE(nullif(trim(p_sku), ''), pos_mini_modular3_generate_sku(v_business_id, 'PRD'));

    -- Check SKU uniqueness
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_products 
        WHERE business_id = v_business_id AND sku = v_sku
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SKU_EXISTS',
            'message', 'SKU đã tồn tại: ' || v_sku
        );
    END IF;

    -- Generate slug
    v_slug := pos_mini_modular3_generate_product_slug(p_name, v_business_id);

    -- Generate product ID
    v_product_id := gen_random_uuid();

    -- Insert product with all fields từ schema thực tế
    INSERT INTO pos_mini_modular3_products (
        id,
        business_id,
        category_id,
        name,
        description,
        sku,
        barcode,
        price,
        cost_price,
        compare_at_price,
        current_stock,
        min_stock_level,
        track_stock,
        is_active,
        is_featured,
        is_digital,
        requires_shipping,
        is_taxable,
        tax_rate,
        slug,
        tags,
        primary_image,
        specifications,
        status,
        created_at,
        updated_at
    ) VALUES (
        v_product_id,
        v_business_id,
        p_category_id,
        trim(p_name),
        p_description,
        v_sku,
        p_barcode,
        p_price,
        p_cost_price,
        p_compare_at_price,
        p_current_stock,
        p_min_stock_level,
        p_track_stock,
        p_is_active,
        p_is_featured,
        p_is_digital,
        p_requires_shipping,
        p_is_taxable,
        p_tax_rate,
        v_slug,
        p_tags,
        p_primary_image,
        p_specifications,
        'draft', -- default status
        now(),
        now()
    );

    -- Build success result
    v_result := jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'id', v_product_id,
            'business_id', v_business_id,
            'name', trim(p_name),
            'sku', v_sku,
            'slug', v_slug,
            'price', p_price,
            'current_stock', p_current_stock,
            'is_active', p_is_active,
            'status', 'draft'
        ),
        'message', 'Sản phẩm đã được tạo thành công'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'CREATE_FAILED',
        'message', 'Lỗi khi tạo sản phẩm: ' || SQLERRM
    );
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
-- Name: pos_mini_modular3_create_user_session(uuid, jsonb, inet, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_create_user_session(p_user_id uuid, p_device_info jsonb DEFAULT '{}'::jsonb, p_ip_address inet DEFAULT NULL::inet, p_user_agent text DEFAULT NULL::text, p_expires_hours integer DEFAULT 24) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_session_id UUID;
    v_session_token UUID;
BEGIN
    -- Generate new session
    v_session_token := gen_random_uuid();
    
    INSERT INTO pos_mini_modular3_user_sessions (
        user_id, session_token, device_info, ip_address, user_agent, expires_at
    ) VALUES (
        p_user_id, v_session_token, p_device_info, p_ip_address, p_user_agent,
        NOW() + (p_expires_hours || ' hours')::INTERVAL
    ) RETURNING id INTO v_session_id;
    
    -- Log activity
    INSERT INTO pos_mini_modular3_session_activities (session_id, activity_type)
    VALUES (v_session_id, 'login');
    
    RETURN v_session_token;
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
-- Name: pos_mini_modular3_generate_category_slug(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_generate_category_slug(p_name text, p_business_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_base_slug text;
    v_slug text;
    v_counter integer := 0;
    v_exists boolean;
BEGIN
    -- Create base slug from name
    v_base_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
    v_base_slug := regexp_replace(v_base_slug, '\s+', '-', 'g');
    v_base_slug := trim(v_base_slug, '-');
    
    -- If empty, use default
    IF v_base_slug = '' THEN
        v_base_slug := 'category';
    END IF;
    
    v_slug := v_base_slug;
    
    -- Check for uniqueness and add counter if needed
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM pos_mini_modular3_product_categories 
            WHERE business_id = p_business_id AND slug = v_slug
        ) INTO v_exists;
        
        IF NOT v_exists THEN
            EXIT;
        END IF;
        
        v_counter := v_counter + 1;
        v_slug := v_base_slug || '-' || v_counter;
    END LOOP;
    
    RETURN v_slug;
END;
$$;


--
-- Name: pos_mini_modular3_generate_product_slug(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_generate_product_slug(p_name text, p_business_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_base_slug text;
    v_slug text;
    v_counter integer := 0;
    v_exists boolean;
BEGIN
    -- Create base slug from name
    v_base_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
    v_base_slug := regexp_replace(v_base_slug, '\s+', '-', 'g');
    v_base_slug := trim(v_base_slug, '-');
    
    -- If empty, use default
    IF v_base_slug = '' THEN
        v_base_slug := 'product';
    END IF;
    
    v_slug := v_base_slug;
    
    -- Check for uniqueness and add counter if needed
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM pos_mini_modular3_products 
            WHERE business_id = p_business_id AND slug = v_slug
        ) INTO v_exists;
        
        IF NOT v_exists THEN
            EXIT;
        END IF;
        
        v_counter := v_counter + 1;
        v_slug := v_base_slug || '-' || v_counter;
    END LOOP;
    
    RETURN v_slug;
END;
$$;


--
-- Name: pos_mini_modular3_generate_sku(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_generate_sku(p_business_id uuid, p_category_prefix text DEFAULT 'PRD'::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_sku TEXT;
    v_counter INTEGER := 1;
    v_base_sku TEXT;
BEGIN
    -- Generate base SKU with timestamp
    v_base_sku := p_category_prefix || to_char(NOW(), 'YYMMDD');
    
    LOOP
        v_sku := v_base_sku || LPAD(v_counter::TEXT, 3, '0');
        
        -- Check if SKU exists
        IF NOT EXISTS (
            SELECT 1 FROM pos_mini_modular3_products 
            WHERE business_id = p_business_id AND sku = v_sku
        ) THEN
            RETURN v_sku;
        END IF;
        
        v_counter := v_counter + 1;
        
        -- Safety check
        IF v_counter > 999 THEN
            v_base_sku := p_category_prefix || to_char(NOW(), 'YYMMDDHH24MI');
            v_counter := 1;
        END IF;
    END LOOP;
END;
$$;


--
-- Name: pos_mini_modular3_get_all_tables_info(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_all_tables_info() RETURNS TABLE(schema_name text, table_name text, table_type text)
    LANGUAGE sql SECURITY DEFINER
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


--
-- Name: FUNCTION pos_mini_modular3_get_all_tables_info(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_get_all_tables_info() IS 'Get information about all tables available for export, similar to pg_dump';


--
-- Name: pos_mini_modular3_get_auth_users(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_auth_users() RETURNS TABLE(instance_id uuid, id uuid, aud text, role text, email text, encrypted_password text, email_confirmed_at timestamp with time zone, invited_at timestamp with time zone, confirmation_token text, confirmation_sent_at timestamp with time zone, recovery_token text, recovery_sent_at timestamp with time zone, email_change_token_new text, email_change text, email_change_sent_at timestamp with time zone, last_sign_in_at timestamp with time zone, raw_app_meta_data jsonb, raw_user_meta_data jsonb, is_super_admin boolean, created_at timestamp with time zone, updated_at timestamp with time zone, phone text, phone_confirmed_at timestamp with time zone, phone_change text, phone_change_token text, phone_change_sent_at timestamp with time zone, email_change_token_current text, email_change_confirm_status smallint, banned_until timestamp with time zone, reauthentication_token text, reauthentication_sent_at timestamp with time zone, is_sso_user boolean, deleted_at timestamp with time zone, is_anonymous boolean)
    LANGUAGE sql SECURITY DEFINER
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


--
-- Name: FUNCTION pos_mini_modular3_get_auth_users(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_get_auth_users() IS 'Safely access auth.users table data for export purposes';


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
-- Name: pos_mini_modular3_get_categories_hierarchy(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_categories_hierarchy(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_result jsonb;
BEGIN
    -- Build hierarchical structure
    WITH RECURSIVE category_tree AS (
        -- Root categories (no parent)
        SELECT 
            id,
            business_id,
            name,
            description,
            icon,
            color_hex,
            parent_id,
            sort_order,
            is_active,
            is_default,
            is_required,
            allows_inventory,
            allows_variants,
            requires_description,
            slug,
            product_count,
            0 as level,
            ARRAY[sort_order, id::text] as path
        FROM pos_mini_modular3_product_categories
        WHERE business_id = p_business_id 
        AND parent_id IS NULL
        AND is_active = true
        
        UNION ALL
        
        -- Child categories
        SELECT 
            c.id,
            c.business_id,
            c.name,
            c.description,
            c.icon,
            c.color_hex,
            c.parent_id,
            c.sort_order,
            c.is_active,
            c.is_default,
            c.is_required,
            c.allows_inventory,
            c.allows_variants,
            c.requires_description,
            c.slug,
            c.product_count,
            ct.level + 1,
            ct.path || ARRAY[c.sort_order, c.id::text]
        FROM pos_mini_modular3_product_categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
        WHERE c.is_active = true
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'name', name,
            'description', description,
            'icon', icon,
            'color_hex', color_hex,
            'parent_id', parent_id,
            'sort_order', sort_order,
            'level', level,
            'is_default', is_default,
            'is_required', is_required,
            'allows_inventory', allows_inventory,
            'allows_variants', allows_variants,
            'requires_description', requires_description,
            'slug', slug,
            'product_count', product_count
        ) ORDER BY path
    ) INTO v_result
    FROM category_tree;
    
    RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'HIERARCHY_FETCH_FAILED',
            'message', 'Lỗi khi lấy cây danh mục',
            'error_detail', SQLERRM
        );
END;
$$;


--
-- Name: pos_mini_modular3_get_category_tree(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_category_tree(p_parent_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  current_business_id UUID;
  result jsonb;
BEGIN
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  WITH RECURSIVE category_tree AS (
    -- Base case: categories with specified parent_id (or root categories if NULL)
    SELECT 
      id, name, description, parent_id, slug, color_code, icon_name, 
      image_url, is_active, is_featured, display_order, created_at,
      ARRAY[display_order, id::text] as sort_path,
      0 as level
    FROM pos_mini_modular3_product_categories
    WHERE business_id = current_business_id 
      AND parent_id IS NOT DISTINCT FROM p_parent_id
      AND is_active = true
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
      c.id, c.name, c.description, c.parent_id, c.slug, c.color_code, c.icon_name,
      c.image_url, c.is_active, c.is_featured, c.display_order, c.created_at,
      ct.sort_path || ARRAY[c.display_order, c.id::text],
      ct.level + 1
    FROM pos_mini_modular3_product_categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
    WHERE c.business_id = current_business_id 
      AND c.is_active = true
      AND ct.level < 5 -- Prevent infinite recursion
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'name', name,
      'description', description,
      'parent_id', parent_id,
      'slug', slug,
      'color_code', color_code,
      'icon_name', icon_name,
      'image_url', image_url,
      'is_featured', is_featured,
      'display_order', display_order,
      'level', level,
      'created_at', created_at
    ) ORDER BY sort_path
  ) INTO result
  FROM category_tree;
  
  RETURN COALESCE(result, '[]'::jsonb);

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_get_category_tree(p_parent_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_get_category_tree(p_parent_id uuid) IS 'Get hierarchical category tree for the current business';


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
-- Name: pos_mini_modular3_get_product_details(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_product_details(p_business_id uuid, p_product_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_product record;
    v_variants jsonb;
    v_inventory_history jsonb;
    v_category jsonb;
    v_result jsonb;
BEGIN
    -- Get product details
    SELECT * INTO v_product
    FROM pos_mini_modular3_products
    WHERE id = p_product_id AND business_id = p_business_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'PRODUCT_NOT_FOUND',
            'message', 'Sản phẩm không tồn tại'
        );
    END IF;
    
    -- Get category info
    SELECT jsonb_build_object(
        'id', id,
        'name', name,
        'slug', slug,
        'icon', icon,
        'color_hex', color_hex
    ) INTO v_category
    FROM pos_mini_modular3_product_categories
    WHERE id = v_product.category_id;
    
    -- Get variants if product has variants
    IF v_product.has_variants THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', id,
                'title', title,
                'option1', option1,
                'option2', option2,
                'option3', option3,
                'sku', sku,
                'barcode', barcode,
                'price', price,
                'cost_price', cost_price,
                'compare_at_price', compare_at_price,
                'inventory_quantity', inventory_quantity,
                'inventory_policy', inventory_policy,
                'weight', weight,
                'dimensions', dimensions,
                'image', image,
                'is_active', is_active,
                'position', position,
                'created_at', created_at,
                'updated_at', updated_at
            ) ORDER BY position, title
        ) INTO v_variants
        FROM pos_mini_modular3_product_variants
        WHERE product_id = p_product_id AND is_active = true;
    END IF;
    
    -- Get recent inventory history (last 10 transactions)
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'transaction_type', transaction_type,
            'quantity_change', quantity_change,
            'quantity_after', quantity_after,
            'reference_type', reference_type,
            'notes', notes,
            'location_name', location_name,
            'unit_cost', unit_cost,
            'created_at', created_at
        ) ORDER BY created_at DESC
    ) INTO v_inventory_history
    FROM (
        SELECT * FROM pos_mini_modular3_product_inventory
        WHERE product_id = p_product_id
        ORDER BY created_at DESC
        LIMIT 10
    ) recent_inventory;
    
    -- Build result
    v_result := jsonb_build_object(
        'success', true,
        'product', jsonb_build_object(
            'id', v_product.id,
            'business_id', v_product.business_id,
            'category_id', v_product.category_id,
            'category', v_category,
            'name', v_product.name,
            'description', v_product.description,
            'short_description', v_product.short_description,
            'sku', v_product.sku,
            'barcode', v_product.barcode,
            'price', v_product.price,
            'cost_price', v_product.cost_price,
            'compare_at_price', v_product.compare_at_price,
            'product_type', v_product.product_type,
            'has_variants', v_product.has_variants,
            'variant_options', v_product.variant_options,
            'track_inventory', v_product.track_inventory,
            'inventory_policy', v_product.inventory_policy,
            'total_inventory', v_product.total_inventory,
            'available_inventory', v_product.available_inventory,
            'weight', v_product.weight,
            'dimensions', v_product.dimensions,
            'images', v_product.images,
            'featured_image', v_product.featured_image,
            'slug', v_product.slug,
            'tags', v_product.tags,
            'meta_title', v_product.meta_title,
            'meta_description', v_product.meta_description,
            'status', v_product.status,
            'is_featured', v_product.is_featured,
            'is_digital', v_product.is_digital,
            'requires_shipping', v_product.requires_shipping,
            'is_taxable', v_product.is_taxable,
            'tax_rate', v_product.tax_rate,
            'created_at', v_product.created_at,
            'updated_at', v_product.updated_at,
            'published_at', v_product.published_at,
            'variants', COALESCE(v_variants, '[]'::jsonb),
            'inventory_history', COALESCE(v_inventory_history, '[]'::jsonb)
        )
    );
    
    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'FETCH_FAILED',
            'message', 'Lỗi khi lấy thông tin sản phẩm',
            'error_detail', SQLERRM
        );
END;
$$;


--
-- Name: pos_mini_modular3_get_products(uuid, text, boolean, boolean, boolean, text[], integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_products(p_category_id uuid DEFAULT NULL::uuid, p_search_term text DEFAULT NULL::text, p_is_active boolean DEFAULT NULL::boolean, p_is_featured boolean DEFAULT NULL::boolean, p_has_low_stock boolean DEFAULT NULL::boolean, p_tags text[] DEFAULT NULL::text[], p_page integer DEFAULT 1, p_limit integer DEFAULT 20, p_sort_by text DEFAULT 'name'::text, p_sort_order text DEFAULT 'ASC'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_business_id uuid;
    v_offset integer;
    v_total_count integer;
    v_products_record record;
    v_products_array jsonb[] := '{}';
BEGIN
    -- Get business_id from session
    v_business_id := pos_mini_modular3_get_session_business_id();
    
    IF v_business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Không thể xác định business_id từ session'
        );
    END IF;

    -- Calculate offset for pagination
    v_offset := (GREATEST(p_page, 1) - 1) * GREATEST(p_limit, 1);

    -- Get total count
    SELECT COUNT(*) INTO v_total_count
    FROM pos_mini_modular3_products p
    WHERE p.business_id = v_business_id
    AND (p_search_term IS NULL OR p.name ILIKE '%' || p_search_term || '%' OR p.sku ILIKE '%' || p_search_term || '%');

    -- Get products data with basic query (avoid complex column checking)
    FOR v_products_record IN 
        SELECT p.*, c.name as category_name
        FROM pos_mini_modular3_products p
        LEFT JOIN pos_mini_modular3_categories c ON p.category_id = c.id
        WHERE p.business_id = v_business_id
        AND (p_category_id IS NULL OR p.category_id = p_category_id)
        AND (p_search_term IS NULL OR p.name ILIKE '%' || p_search_term || '%' OR p.sku ILIKE '%' || p_search_term || '%')
        ORDER BY 
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'ASC' THEN p.name END ASC,
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'DESC' THEN p.name END DESC,
            p.name ASC
        LIMIT p_limit OFFSET v_offset
    LOOP
        v_products_array := v_products_array || jsonb_build_object(
            'id', v_products_record.id,
            'business_id', v_products_record.business_id,
            'name', v_products_record.name,
            'category_id', v_products_record.category_id,
            'category_name', COALESCE(v_products_record.category_name, ''),
            'sku', v_products_record.sku,
            'unit_price', COALESCE(v_products_record.unit_price, 0),
            'current_stock', COALESCE(v_products_record.current_stock, 0),
            'min_stock_level', COALESCE(v_products_record.min_stock_level, 0),
            'created_at', v_products_record.created_at,
            'updated_at', v_products_record.updated_at
        );
    END LOOP;

    -- Build final result
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'products', to_jsonb(v_products_array),
            'pagination', jsonb_build_object(
                'page', p_page,
                'limit', p_limit,
                'total', v_total_count,
                'total_pages', CEIL(v_total_count::numeric / p_limit::numeric)
            )
        )
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'Lỗi khi lấy danh sách sản phẩm: ' || SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_get_products_advanced(uuid, uuid, text, text, boolean, boolean, boolean, text[], integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_products_advanced(p_business_id uuid DEFAULT NULL::uuid, p_category_id uuid DEFAULT NULL::uuid, p_search_term text DEFAULT NULL::text, p_status text DEFAULT 'active'::text, p_is_active boolean DEFAULT true, p_is_featured boolean DEFAULT NULL::boolean, p_has_low_stock boolean DEFAULT NULL::boolean, p_tags text[] DEFAULT NULL::text[], p_page integer DEFAULT 1, p_limit integer DEFAULT 20, p_sort_by text DEFAULT 'name'::text, p_sort_order text DEFAULT 'ASC'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_business_id uuid;
    v_offset integer;
    v_total_count integer;
    v_products jsonb;
    v_where_conditions text[] := '{}';
    v_query text;
BEGIN
    -- Get business_id
    v_business_id := COALESCE(p_business_id, pos_mini_modular3_get_session_business_id());
    
    IF v_business_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'BUSINESS_NOT_FOUND',
            'message', 'Không thể xác định business_id'
        );
    END IF;

    -- Build where conditions
    v_where_conditions := v_where_conditions || ('business_id = ' || quote_literal(v_business_id));
    
    IF p_status IS NOT NULL THEN
        v_where_conditions := v_where_conditions || ('status = ' || quote_literal(p_status));
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_where_conditions := v_where_conditions || ('is_active = ' || p_is_active);
    END IF;
    
    IF p_category_id IS NOT NULL THEN
        v_where_conditions := v_where_conditions || ('category_id = ' || quote_literal(p_category_id));
    END IF;
    
    IF p_is_featured IS NOT NULL THEN
        v_where_conditions := v_where_conditions || ('is_featured = ' || p_is_featured);
    END IF;
    
    IF p_search_term IS NOT NULL THEN
        v_where_conditions := v_where_conditions || (
            '(name ILIKE ' || quote_literal('%' || p_search_term || '%') || 
            ' OR description ILIKE ' || quote_literal('%' || p_search_term || '%') ||
            ' OR sku ILIKE ' || quote_literal('%' || p_search_term || '%') || ')'
        );
    END IF;
    
    IF p_has_low_stock = true THEN
        v_where_conditions := v_where_conditions || ('current_stock <= min_stock_level');
    END IF;

    -- Calculate offset
    v_offset := (GREATEST(p_page, 1) - 1) * GREATEST(p_limit, 1);

    -- Get products with category info
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'business_id', p.business_id,
            'category_id', p.category_id,
            'category', CASE 
                WHEN c.id IS NOT NULL THEN jsonb_build_object(
                    'id', c.id,
                    'name', c.name,
                    'slug', c.slug,
                    'icon', c.icon,
                    'color_hex', c.color_hex
                )
                ELSE NULL
            END,
            'name', p.name,
            'description', p.description,
            'short_description', p.short_description,
            'sku', p.sku,
            'barcode', p.barcode,
            'price', p.price,
            'unit_price', p.unit_price,
            'cost_price', p.cost_price,
            'sale_price', p.sale_price,
            'compare_at_price', p.compare_at_price,
            'product_type', p.product_type,
            'has_variants', p.has_variants,
            'variant_options', p.variant_options,
            'track_inventory', p.track_inventory,
            'track_stock', p.track_stock,
            'inventory_policy', p.inventory_policy,
            'current_stock', p.current_stock,
            'total_inventory', p.total_inventory,
            'available_inventory', p.available_inventory,
            'min_stock_level', p.min_stock_level,
            'is_low_stock', (p.current_stock <= p.min_stock_level),
            'weight', p.weight,
            'dimensions', p.dimensions,
            'images', p.images,
            'featured_image', p.featured_image,
            'primary_image', p.primary_image,
            'slug', p.slug,
            'tags', p.tags,
            'specifications', p.specifications,
            'meta_title', p.meta_title,
            'meta_description', p.meta_description,
            'status', p.status,
            'is_active', p.is_active,
            'is_featured', p.is_featured,
            'is_digital', p.is_digital,
            'requires_shipping', p.requires_shipping,
            'is_taxable', p.is_taxable,
            'tax_rate', p.tax_rate,
            'created_at', p.created_at,
            'updated_at', p.updated_at,
            'published_at', p.published_at
        )
        ORDER BY 
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'ASC' THEN p.name END ASC,
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'DESC' THEN p.name END DESC,
            CASE WHEN p_sort_by = 'price' AND p_sort_order = 'ASC' THEN p.price END ASC,
            CASE WHEN p_sort_by = 'price' AND p_sort_order = 'DESC' THEN p.price END DESC,
            CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'ASC' THEN p.created_at END ASC,
            CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'DESC' THEN p.created_at END DESC,
            p.name ASC
    ) INTO v_products
    FROM pos_mini_modular3_products p
    LEFT JOIN pos_mini_modular3_product_categories c ON p.category_id = c.id
    WHERE (array_to_string(v_where_conditions, ' AND '))::boolean
    LIMIT p_limit OFFSET v_offset;

    -- Get total count
    EXECUTE 'SELECT COUNT(*) FROM pos_mini_modular3_products p WHERE ' || 
            array_to_string(v_where_conditions, ' AND ') 
    INTO v_total_count;

    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'products', COALESCE(v_products, '[]'::jsonb),
            'pagination', jsonb_build_object(
                'page', p_page,
                'limit', p_limit,
                'total', v_total_count,
                'total_pages', CEIL(v_total_count::numeric / p_limit::numeric),
                'has_next', (p_page * p_limit) < v_total_count,
                'has_prev', p_page > 1
            )
        ),
        'filters', jsonb_build_object(
            'business_id', v_business_id,
            'category_id', p_category_id,
            'search_term', p_search_term,
            'status', p_status,
            'is_active', p_is_active,
            'is_featured', p_is_featured,
            'has_low_stock', p_has_low_stock,
            'sort_by', p_sort_by,
            'sort_order', p_sort_order
        )
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'QUERY_FAILED',
        'message', 'Lỗi khi lấy danh sách sản phẩm',
        'error_detail', SQLERRM
    );
END;
$$;


--
-- Name: pos_mini_modular3_get_session_business_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_session_business_id() RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_business_id UUID;
    v_user_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Try to get business_id from user_profiles table
    SELECT business_id INTO v_business_id
    FROM pos_mini_modular3_user_profiles
    WHERE user_id = v_user_id;

    -- If not found in profiles, try from business_users table
    IF v_business_id IS NULL THEN
        SELECT business_id INTO v_business_id
        FROM pos_mini_modular3_business_users
        WHERE user_id = v_user_id
        AND status = 'active'
        LIMIT 1;
    END IF;

    -- If still not found, check if user is a business owner
    IF v_business_id IS NULL THEN
        SELECT id INTO v_business_id
        FROM pos_mini_modular3_businesses
        WHERE owner_id = v_user_id
        AND status = 'active'
        LIMIT 1;
    END IF;

    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'No business found for current user';
    END IF;

    RETURN v_business_id;
END;
$$;


--
-- Name: pos_mini_modular3_get_user_permissions(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_user_permissions(p_user_id uuid, p_user_role text) RETURNS TABLE(permission_key text, permission_name text, is_granted boolean, source text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  -- Role-based permissions
  SELECT 
    p.permission_key,
    p.permission_name,
    rpm.is_granted,
    'role' as source
  FROM public.pos_mini_modular3_permissions p
  JOIN public.pos_mini_modular3_role_permission_mappings rpm ON p.id = rpm.permission_id
  WHERE rpm.user_role = p_user_role
  
  UNION ALL
  
  -- User-specific overrides
  SELECT 
    p.permission_key,
    p.permission_name,
    upo.is_granted,
    'override' as source
  FROM public.pos_mini_modular3_permissions p
  JOIN public.pos_mini_modular3_user_permission_overrides upo ON p.id = upo.permission_id
  WHERE upo.user_id = p_user_id
  AND (upo.expires_at IS NULL OR upo.expires_at > now());
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_get_user_permissions(p_user_id uuid, p_user_role text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_get_user_permissions(p_user_id uuid, p_user_role text) IS 'Get all permissions for a user including role-based and overrides';


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
-- Name: pos_mini_modular3_get_user_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_user_role() RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_role VARCHAR(50);
    v_user_id UUID;
    v_business_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get business_id
    v_business_id := pos_mini_modular3_get_session_business_id();

    -- Check if user is business owner
    IF EXISTS (
        SELECT 1 FROM pos_mini_modular3_businesses 
        WHERE id = v_business_id AND owner_id = v_user_id
    ) THEN
        RETURN 'owner';
    END IF;

    -- Get role from user_profiles
    SELECT role INTO v_role
    FROM pos_mini_modular3_user_profiles
    WHERE user_id = v_user_id AND business_id = v_business_id;

    -- If not found, get from business_users
    IF v_role IS NULL THEN
        SELECT role INTO v_role
        FROM pos_mini_modular3_business_users
        WHERE user_id = v_user_id AND business_id = v_business_id;
    END IF;

    RETURN COALESCE(v_role, 'staff');
END;
$$;


--
-- Name: pos_mini_modular3_get_user_with_business_complete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_get_user_with_business_complete(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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

    -- Get business information - REMOVED CODE FIELD
    SELECT 
        b.id,
        b.name,
        b.business_type,
        b.email,
        b.phone,
        b.address,
        b.tax_code,
        b.subscription_tier,
        b.subscription_status,
        b.trial_ends_at,
        b.features_enabled,
        b.usage_stats,
        b.status,
        bt.label as business_type_name
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

    -- Build successful result - REMOVED CODE FIELD
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
-- Name: pos_mini_modular3_product_auto_slug(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_product_auto_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Generate slug if not provided or name changed
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.name != NEW.name) THEN
        NEW.slug := pos_mini_modular3_generate_product_slug(NEW.name, NEW.business_id);
    END IF;
    
    -- Update published_at when status changes to active
    IF TG_OP = 'UPDATE' AND OLD.status != 'active' AND NEW.status = 'active' AND NEW.published_at IS NULL THEN
        NEW.published_at := now();
    END IF;
    
    -- Update timestamp
    NEW.updated_at := now();
    
    RETURN NEW;
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
-- Name: pos_mini_modular3_search_products(uuid, text, uuid, text, boolean, integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_search_products(p_business_id uuid, p_search_term text DEFAULT NULL::text, p_category_id uuid DEFAULT NULL::uuid, p_status text DEFAULT 'active'::text, p_is_featured boolean DEFAULT NULL::boolean, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_sort_by text DEFAULT 'name'::text, p_sort_order text DEFAULT 'asc'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    v_where_clause text := '';
    v_order_clause text := '';
    v_query text;
    v_count_query text;
    v_total_count integer;
    v_products jsonb;
BEGIN
    -- Build WHERE clause
    v_where_clause := 'WHERE p.business_id = $1 AND p.status = $2';
    
    IF p_search_term IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND (p.name ILIKE $3 OR p.description ILIKE $3 OR p.sku ILIKE $3)';
    END IF;
    
    IF p_category_id IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND p.category_id = ' || quote_literal(p_category_id);
    END IF;
    
    IF p_is_featured IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND p.is_featured = ' || p_is_featured;
    END IF;
    
    -- Build ORDER clause
    CASE p_sort_by
        WHEN 'name' THEN v_order_clause := 'ORDER BY p.name';
        WHEN 'price' THEN v_order_clause := 'ORDER BY p.price';
        WHEN 'created_at' THEN v_order_clause := 'ORDER BY p.created_at';
        WHEN 'updated_at' THEN v_order_clause := 'ORDER BY p.updated_at';
        WHEN 'inventory' THEN v_order_clause := 'ORDER BY p.total_inventory';
        ELSE v_order_clause := 'ORDER BY p.name';
    END CASE;
    
    IF p_sort_order = 'desc' THEN
        v_order_clause := v_order_clause || ' DESC';
    ELSE
        v_order_clause := v_order_clause || ' ASC';
    END IF;
    
    -- Get total count
    v_count_query := '
        SELECT COUNT(*)
        FROM pos_mini_modular3_products p
        LEFT JOIN pos_mini_modular3_product_categories c ON p.category_id = c.id
        ' || v_where_clause;
    
    IF p_search_term IS NOT NULL THEN
        EXECUTE v_count_query INTO v_total_count USING p_business_id, p_status, '%' || p_search_term || '%';
    ELSE
        EXECUTE v_count_query INTO v_total_count USING p_business_id, p_status;
    END IF;
    
    -- Get products
    v_query := '
        SELECT jsonb_agg(
            jsonb_build_object(
                ''id'', p.id,
                ''name'', p.name,
                ''description'', p.short_description,
                ''sku'', p.sku,
                ''price'', p.price,
                ''cost_price'', p.cost_price,
                ''compare_at_price'', p.compare_at_price,
                ''has_variants'', p.has_variants,
                ''total_inventory'', p.total_inventory,
                ''available_inventory'', p.available_inventory,
                ''featured_image'', p.featured_image,
                ''slug'', p.slug,
                ''status'', p.status,
                ''is_featured'', p.is_featured,
                ''is_digital'', p.is_digital,
                ''category'', CASE 
                    WHEN c.id IS NOT NULL THEN 
                        jsonb_build_object(
                            ''id'', c.id,
                            ''name'', c.name,
                            ''slug'', c.slug,
                            ''icon'', c.icon,
                            ''color_hex'', c.color_hex
                        )
                    ELSE NULL
                END,
                ''created_at'', p.created_at,
                ''updated_at'', p.updated_at
            ) ' || v_order_clause || '
        )
        FROM pos_mini_modular3_products p
        LEFT JOIN pos_mini_modular3_product_categories c ON p.category_id = c.id
        ' || v_where_clause || ' ' || v_order_clause || '
        LIMIT $' || (CASE WHEN p_search_term IS NOT NULL THEN '4' ELSE '3' END) || '
        OFFSET $' || (CASE WHEN p_search_term IS NOT NULL THEN '5' ELSE '4' END);
    
    IF p_search_term IS NOT NULL THEN
        EXECUTE v_query INTO v_products USING p_business_id, p_status, '%' || p_search_term || '%', p_limit, p_offset;
    ELSE
        EXECUTE v_query INTO v_products USING p_business_id, p_status, p_limit, p_offset;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'products', COALESCE(v_products, '[]'::jsonb),
        'pagination', jsonb_build_object(
            'total_count', v_total_count,
            'limit', p_limit,
            'offset', p_offset,
            'has_more', (p_offset + p_limit) < v_total_count
        ),
        'filters', jsonb_build_object(
            'search_term', p_search_term,
            'category_id', p_category_id,
            'status', p_status,
            'is_featured', p_is_featured,
            'sort_by', p_sort_by,
            'sort_order', p_sort_order
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SEARCH_FAILED',
            'message', 'Lỗi khi tìm kiếm sản phẩm',
            'error_detail', SQLERRM
        );
END;
$_$;


--
-- Name: pos_mini_modular3_search_products_v2(uuid, text, uuid, text, boolean, integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_search_products_v2(p_business_id uuid, p_search_term text DEFAULT NULL::text, p_category_id uuid DEFAULT NULL::uuid, p_status text DEFAULT 'active'::text, p_is_featured boolean DEFAULT NULL::boolean, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_sort_by text DEFAULT 'name'::text, p_sort_order text DEFAULT 'asc'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    v_total_count integer;
    v_products jsonb;
    v_query text;
BEGIN
    -- Build dynamic query
    v_query := 'SELECT COUNT(*) FROM pos_mini_modular3_products p WHERE p.business_id = $1';
    
    IF p_status IS NOT NULL THEN
        v_query := v_query || ' AND p.status = ''' || p_status || '''';
    END IF;
    
    IF p_search_term IS NOT NULL THEN
        v_query := v_query || ' AND (p.name ILIKE ''%' || p_search_term || '%'' OR p.sku ILIKE ''%' || p_search_term || '%'')';
    END IF;
    
    IF p_category_id IS NOT NULL THEN
        v_query := v_query || ' AND p.category_id = ''' || p_category_id || '''';
    END IF;
    
    IF p_is_featured IS NOT NULL THEN
        v_query := v_query || ' AND p.is_featured = ' || p_is_featured;
    END IF;
    
    -- Get total count
    EXECUTE v_query INTO v_total_count USING p_business_id;
    
    -- Get products with pagination
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'description', p.description,
            'sku', p.sku,
            'price', p.price,
            'cost_price', p.cost_price,
            'current_stock', p.current_stock,
            'min_stock_level', p.min_stock_level,
            'track_stock', p.track_stock,
            'is_active', p.is_active,
            'is_featured', p.is_featured,
            'is_digital', p.is_digital,
            'status', p.status,
            'slug', p.slug,
            'primary_image', p.primary_image,
            'tags', p.tags,
            'category', CASE 
                WHEN c.id IS NOT NULL THEN 
                    jsonb_build_object(
                        'id', c.id,
                        'name', c.name,
                        'slug', c.slug
                    )
                ELSE NULL
            END,
            'created_at', p.created_at,
            'updated_at', p.updated_at
        ) ORDER BY 
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'asc' THEN p.name END ASC,
            CASE WHEN p_sort_by = 'name' AND p_sort_order = 'desc' THEN p.name END DESC,
            CASE WHEN p_sort_by = 'price' AND p_sort_order = 'asc' THEN p.price END ASC,
            CASE WHEN p_sort_by = 'price' AND p_sort_order = 'desc' THEN p.price END DESC,
            p.created_at DESC
    ) INTO v_products
    FROM pos_mini_modular3_products p
    LEFT JOIN pos_mini_modular3_product_categories c ON p.category_id = c.id
    WHERE p.business_id = p_business_id
    AND (p_status IS NULL OR p.status = p_status)
    AND (p_search_term IS NULL OR p.name ILIKE '%' || p_search_term || '%' OR p.sku ILIKE '%' || p_search_term || '%')
    AND (p_category_id IS NULL OR p.category_id = p_category_id)
    AND (p_is_featured IS NULL OR p.is_featured = p_is_featured)
    LIMIT p_limit OFFSET p_offset;
    
    RETURN jsonb_build_object(
        'success', true,
        'products', COALESCE(v_products, '[]'::jsonb),
        'pagination', jsonb_build_object(
            'total_count', v_total_count,
            'limit', p_limit,
            'offset', p_offset,
            'has_more', (p_offset + p_limit) < v_total_count
        ),
        'filters', jsonb_build_object(
            'search_term', p_search_term,
            'category_id', p_category_id,
            'status', p_status,
            'is_featured', p_is_featured,
            'sort_by', p_sort_by,
            'sort_order', p_sort_order
        )
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', 'SEARCH_FAILED',
        'message', 'Lỗi khi tìm kiếm sản phẩm: ' || SQLERRM
    );
END;
$_$;


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
-- Name: pos_mini_modular3_terminate_session(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_terminate_session(p_session_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_session_id UUID;
BEGIN
    -- Get session ID and update to inactive
    UPDATE pos_mini_modular3_user_sessions 
    SET is_active = false, updated_at = NOW()
    WHERE session_token = p_session_token
    RETURNING id INTO v_session_id;
    
    IF v_session_id IS NOT NULL THEN
        -- Log logout activity
        INSERT INTO pos_mini_modular3_session_activities (session_id, activity_type)
        VALUES (v_session_id, 'logout');
        
        RETURN true;
    END IF;
    
    RETURN false;
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
-- Name: pos_mini_modular3_track_feature_usage(uuid, text, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_track_feature_usage(p_business_id uuid, p_feature_key text, p_user_id uuid DEFAULT NULL::uuid, p_usage_data jsonb DEFAULT '{}'::jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_feature_id UUID;
BEGIN
    -- Get feature ID
    SELECT id INTO v_feature_id
    FROM pos_mini_modular3_features
    WHERE feature_key = p_feature_key;
    
    IF v_feature_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Insert or update usage
    INSERT INTO pos_mini_modular3_feature_usage (
        business_id, feature_id, user_id, usage_data
    ) VALUES (
        p_business_id, v_feature_id, p_user_id, p_usage_data
    )
    ON CONFLICT (business_id, feature_id, usage_date)
    DO UPDATE SET
        usage_count = pos_mini_modular3_feature_usage.usage_count + 1,
        usage_data = p_usage_data;
    
    RETURN true;
END;
$$;


--
-- Name: pos_mini_modular3_update_category(uuid, text, text, uuid, text, text, text, boolean, boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_category(p_category_id uuid, p_name text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_parent_id uuid DEFAULT NULL::uuid, p_color_code text DEFAULT NULL::text, p_icon_name text DEFAULT NULL::text, p_image_url text DEFAULT NULL::text, p_is_featured boolean DEFAULT NULL::boolean, p_is_active boolean DEFAULT NULL::boolean, p_display_order integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  category_record RECORD;
  new_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Check if category exists and belongs to current business
  SELECT * INTO category_record
  FROM pos_mini_modular3_product_categories
  WHERE id = p_category_id AND business_id = current_business_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Danh mục không tồn tại'
    );
  END IF;
  
  -- Validate parent category if provided
  IF p_parent_id IS NOT NULL AND p_parent_id != category_record.parent_id THEN
    -- Prevent circular reference
    IF p_parent_id = p_category_id THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Không thể chọn chính danh mục này làm danh mục cha'
      );
    END IF;
    
    -- Check if parent exists
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_parent_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục cha không tồn tại'
      );
    END IF;
  END IF;
  
  -- Generate new slug if name is updated
  IF p_name IS NOT NULL AND trim(p_name) != category_record.name THEN
    new_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
    new_slug := regexp_replace(new_slug, '\s+', '-', 'g');
    
    -- Check if new name already exists
    IF EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE business_id = current_business_id 
        AND name = trim(p_name) 
        AND id != p_category_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Tên danh mục đã tồn tại'
      );
    END IF;
  ELSE
    new_slug := category_record.slug;
  END IF;
  
  -- Update category
  UPDATE pos_mini_modular3_product_categories SET
    name = COALESCE(trim(p_name), name),
    description = COALESCE(p_description, description),
    parent_id = COALESCE(p_parent_id, parent_id),
    slug = new_slug,
    color_code = COALESCE(p_color_code, color_code),
    icon_name = COALESCE(p_icon_name, icon_name),
    image_url = COALESCE(p_image_url, image_url),
    is_featured = COALESCE(p_is_featured, is_featured),
    is_active = COALESCE(p_is_active, is_active),
    display_order = COALESCE(p_display_order, display_order),
    updated_by = current_user_id
  WHERE id = p_category_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Danh mục đã được cập nhật thành công',
    'category_id', p_category_id
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;


--
-- Name: FUNCTION pos_mini_modular3_update_category(p_category_id uuid, p_name text, p_description text, p_parent_id uuid, p_color_code text, p_icon_name text, p_image_url text, p_is_featured boolean, p_is_active boolean, p_display_order integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pos_mini_modular3_update_category(p_category_id uuid, p_name text, p_description text, p_parent_id uuid, p_color_code text, p_icon_name text, p_image_url text, p_is_featured boolean, p_is_active boolean, p_display_order integer) IS 'Update existing product category with validation';


--
-- Name: pos_mini_modular3_update_category_product_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_category_product_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update old category count
    IF TG_OP = 'UPDATE' AND OLD.category_id IS NOT NULL AND OLD.category_id != NEW.category_id THEN
        UPDATE pos_mini_modular3_product_categories
        SET product_count = (
            SELECT COUNT(*) FROM pos_mini_modular3_products 
            WHERE category_id = OLD.category_id AND status = 'active'
        )
        WHERE id = OLD.category_id;
    ELSIF TG_OP = 'DELETE' AND OLD.category_id IS NOT NULL THEN
        UPDATE pos_mini_modular3_product_categories
        SET product_count = (
            SELECT COUNT(*) FROM pos_mini_modular3_products 
            WHERE category_id = OLD.category_id AND status = 'active'
        )
        WHERE id = OLD.category_id;
    END IF;
    
    -- Update new category count
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.category_id IS NOT NULL THEN
        UPDATE pos_mini_modular3_product_categories
        SET product_count = (
            SELECT COUNT(*) FROM pos_mini_modular3_products 
            WHERE category_id = NEW.category_id AND status = 'active'
        )
        WHERE id = NEW.category_id;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_update_category_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_category_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_update_feature_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_feature_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_update_product_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_product_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: pos_mini_modular3_update_session_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_session_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
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
-- Name: pos_mini_modular3_update_usage_stats(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_usage_stats(p_business_id uuid, p_feature_name text, p_increment integer DEFAULT 1) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_new_usage integer;
BEGIN
    -- Get current usage
    SELECT 
        COALESCE((usage_stats->p_feature_name)::integer, 0)
    INTO v_new_usage
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
$$;


--
-- Name: pos_mini_modular3_update_variant_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_update_variant_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
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
-- Name: pos_mini_modular3_validate_subscription(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_validate_subscription(p_business_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


--
-- Name: pos_mini_modular3_variant_inventory_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_mini_modular3_variant_inventory_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update product inventory cache when variant inventory changes
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        PERFORM pos_mini_modular3_update_product_inventory_cache(NEW.product_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM pos_mini_modular3_update_product_inventory_cache(OLD.product_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
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
-- Name: update_business_membership_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_business_membership_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
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
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    permission_key text NOT NULL,
    permission_name text NOT NULL,
    description text,
    category text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: pos_mini_modular3_admin_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_admin_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    super_admin_id uuid NOT NULL,
    target_business_id uuid NOT NULL,
    impersonated_role text DEFAULT 'business_owner'::text NOT NULL,
    session_reason text,
    session_start timestamp with time zone DEFAULT now(),
    session_end timestamp with time zone,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT admin_session_role_check CHECK ((impersonated_role = ANY (ARRAY['business_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text])))
);


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
-- Name: pos_mini_modular3_business_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_business_features (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    is_enabled boolean NOT NULL,
    feature_value jsonb,
    override_reason text,
    enabled_by uuid,
    enabled_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_business_features; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_business_features IS 'Business-specific feature overrides';


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
-- Name: pos_mini_modular3_business_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_business_memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying DEFAULT 'seller'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    permissions jsonb DEFAULT '[]'::jsonb,
    invited_by uuid,
    invited_at timestamp with time zone,
    joined_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_valid_role CHECK (((role)::text = ANY ((ARRAY['owner'::character varying, 'manager'::character varying, 'seller'::character varying, 'accountant'::character varying, 'household_owner'::character varying])::text[]))),
    CONSTRAINT check_valid_status CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'pending'::character varying, 'suspended'::character varying])::text[])))
);


--
-- Name: pos_mini_modular3_business_type_category_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_business_type_category_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_type text NOT NULL,
    template_name text NOT NULL,
    description text,
    category_name text NOT NULL,
    category_description text,
    category_icon text,
    category_color_hex text DEFAULT '#6B7280'::text,
    parent_category_name text,
    sort_order integer DEFAULT 0,
    is_default boolean DEFAULT false,
    is_required boolean DEFAULT false,
    allows_inventory boolean DEFAULT true,
    allows_variants boolean DEFAULT true,
    requires_description boolean DEFAULT false,
    is_active boolean DEFAULT true,
    version integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT template_sort_order_positive CHECK ((sort_order >= 0))
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
    features_enabled jsonb DEFAULT '{}'::jsonb,
    usage_stats jsonb DEFAULT '{}'::jsonb,
    last_billing_date timestamp with time zone,
    next_billing_date timestamp with time zone,
    CONSTRAINT business_max_products_positive CHECK ((max_products > 0)),
    CONSTRAINT business_max_users_positive CHECK ((max_users > 0)),
    CONSTRAINT business_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['trial'::text, 'active'::text, 'suspended'::text, 'expired'::text, 'cancelled'::text]))),
    CONSTRAINT business_subscription_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text, 'enterprise'::text]))),
    CONSTRAINT pos_mini_modular3_businesses_business_type_valid CHECK (((business_type IS NOT NULL) AND (length(TRIM(BOTH FROM business_type)) > 0) AND (length(business_type) <= 50))),
    CONSTRAINT pos_mini_modular3_businesses_name_check CHECK ((length(TRIM(BOTH FROM name)) > 0)),
    CONSTRAINT pos_mini_modular3_businesses_status_check CHECK ((status = ANY (ARRAY['trial'::text, 'active'::text, 'suspended'::text, 'closed'::text]))),
    CONSTRAINT pos_mini_modular3_businesses_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['trial'::text, 'active'::text, 'past_due'::text, 'cancelled'::text]))),
    CONSTRAINT pos_mini_modular3_businesses_subscription_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])))
);


--
-- Name: COLUMN pos_mini_modular3_businesses.subscription_tier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_mini_modular3_businesses.subscription_tier IS 'Business subscription plan: free, basic, premium';


--
-- Name: COLUMN pos_mini_modular3_businesses.subscription_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_mini_modular3_businesses.subscription_status IS 'Current subscription status: trial, active, suspended, expired, cancelled';


--
-- Name: COLUMN pos_mini_modular3_businesses.features_enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_mini_modular3_businesses.features_enabled IS 'JSON object containing enabled features for this business';


--
-- Name: COLUMN pos_mini_modular3_businesses.usage_stats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_mini_modular3_businesses.usage_stats IS 'JSON object tracking current usage against limits';


--
-- Name: pos_mini_modular3_enhanced_user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_enhanced_user_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_token text NOT NULL,
    device_info jsonb DEFAULT '{}'::jsonb,
    ip_address text,
    user_agent text,
    fingerprint text,
    location_data jsonb DEFAULT '{}'::jsonb,
    security_flags jsonb DEFAULT '{}'::jsonb,
    risk_score integer DEFAULT 0,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    last_activity_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_enhanced_user_sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_enhanced_user_sessions IS 'Enhanced session tracking with device fingerprinting and risk assessment';


--
-- Name: pos_mini_modular3_failed_login_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_failed_login_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identifier text NOT NULL,
    identifier_type text DEFAULT 'email'::text NOT NULL,
    attempt_count integer DEFAULT 1,
    last_attempt_at timestamp with time zone DEFAULT now(),
    is_locked boolean DEFAULT false,
    lock_expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_failed_login_attempts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_failed_login_attempts IS 'Tracks failed login attempts for account lockout security';


--
-- Name: pos_mini_modular3_feature_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_feature_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    user_id uuid,
    usage_count integer DEFAULT 1,
    usage_data jsonb DEFAULT '{}'::jsonb,
    usage_date date DEFAULT CURRENT_DATE,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_feature_usage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_feature_usage IS 'Feature usage tracking for analytics and limits';


--
-- Name: pos_mini_modular3_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_features (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    feature_key text NOT NULL,
    feature_name text NOT NULL,
    description text,
    feature_type text NOT NULL,
    default_value jsonb NOT NULL,
    is_system_feature boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_features_feature_type_check CHECK ((feature_type = ANY (ARRAY['boolean'::text, 'string'::text, 'number'::text, 'json'::text])))
);


--
-- Name: TABLE pos_mini_modular3_features; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_features IS 'System feature definitions with types and default values';


--
-- Name: pos_mini_modular3_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    permission_key text NOT NULL,
    permission_name text NOT NULL,
    description text,
    category text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_permissions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_permissions IS 'System permissions with Vietnamese names';


--
-- Name: pos_mini_modular3_product_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    icon text,
    color_hex text DEFAULT '#6B7280'::text,
    parent_id uuid,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_default boolean DEFAULT false,
    is_required boolean DEFAULT false,
    allows_inventory boolean DEFAULT true,
    allows_variants boolean DEFAULT true,
    requires_description boolean DEFAULT false,
    slug text,
    product_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT category_color_hex_valid CHECK ((color_hex ~ '^#[0-9A-Fa-f]{6}$'::text)),
    CONSTRAINT category_sort_order_positive CHECK ((sort_order >= 0))
);


--
-- Name: TABLE pos_mini_modular3_product_categories; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_product_categories IS 'Product categories with hierarchical support and business isolation';


--
-- Name: pos_mini_modular3_product_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_product_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid,
    variant_id uuid,
    business_id uuid NOT NULL,
    url text NOT NULL,
    filename text,
    original_filename text,
    alt_text text,
    size_bytes integer,
    width integer,
    height integer,
    format text,
    is_primary boolean DEFAULT false,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    uploaded_by uuid,
    CONSTRAINT pos_mini_modular3_product_images_alt_text_check CHECK ((length(alt_text) <= 200)),
    CONSTRAINT pos_mini_modular3_product_images_check CHECK ((((product_id IS NOT NULL) AND (variant_id IS NULL)) OR ((product_id IS NULL) AND (variant_id IS NOT NULL)))),
    CONSTRAINT pos_mini_modular3_product_images_format_check CHECK ((format = ANY (ARRAY['jpg'::text, 'jpeg'::text, 'png'::text, 'webp'::text, 'gif'::text]))),
    CONSTRAINT pos_mini_modular3_product_images_height_check CHECK ((height > 0)),
    CONSTRAINT pos_mini_modular3_product_images_size_bytes_check CHECK ((size_bytes > 0)),
    CONSTRAINT pos_mini_modular3_product_images_width_check CHECK ((width > 0)),
    CONSTRAINT product_images_display_order_positive CHECK ((display_order >= 0))
);


--
-- Name: TABLE pos_mini_modular3_product_images; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_product_images IS 'Product images with metadata';


--
-- Name: pos_mini_modular3_product_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_product_inventory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    product_id uuid NOT NULL,
    variant_id uuid,
    transaction_type text NOT NULL,
    quantity_change integer NOT NULL,
    quantity_after integer NOT NULL,
    reference_type text,
    reference_id uuid,
    notes text,
    location_name text DEFAULT 'default'::text,
    unit_cost numeric(12,2),
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT inventory_quantity_after_positive CHECK ((quantity_after >= 0)),
    CONSTRAINT inventory_quantity_change_non_zero CHECK ((quantity_change <> 0)),
    CONSTRAINT pos_mini_modular3_product_inventory_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['adjustment'::text, 'sale'::text, 'return'::text, 'transfer'::text, 'damage'::text])))
);


--
-- Name: pos_mini_modular3_product_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_product_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    business_id uuid NOT NULL,
    title text NOT NULL,
    option1 text,
    option2 text,
    option3 text,
    sku text,
    barcode text,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    cost_price numeric(12,2) DEFAULT 0,
    compare_at_price numeric(12,2),
    inventory_quantity integer DEFAULT 0,
    inventory_policy text DEFAULT 'deny'::text,
    weight numeric(8,3),
    dimensions jsonb,
    image text,
    is_active boolean DEFAULT true,
    "position" integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_product_variants_inventory_policy_check CHECK ((inventory_policy = ANY (ARRAY['allow'::text, 'deny'::text]))),
    CONSTRAINT variant_cost_positive CHECK ((cost_price >= (0)::numeric)),
    CONSTRAINT variant_inventory_positive CHECK ((inventory_quantity >= 0)),
    CONSTRAINT variant_position_positive CHECK (("position" >= 0)),
    CONSTRAINT variant_price_positive CHECK ((price >= (0)::numeric))
);


--
-- Name: pos_mini_modular3_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    category_id uuid,
    name text NOT NULL,
    description text,
    short_description text,
    sku text,
    barcode text,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    cost_price numeric(12,2) DEFAULT 0,
    compare_at_price numeric(12,2),
    product_type text DEFAULT 'simple'::text,
    has_variants boolean DEFAULT false,
    variant_options jsonb DEFAULT '[]'::jsonb,
    track_inventory boolean DEFAULT true,
    inventory_policy text DEFAULT 'deny'::text,
    total_inventory integer DEFAULT 0,
    available_inventory integer DEFAULT 0,
    weight numeric(8,3),
    dimensions jsonb,
    images jsonb DEFAULT '[]'::jsonb,
    featured_image text,
    slug text,
    tags jsonb DEFAULT '[]'::jsonb,
    meta_title text,
    meta_description text,
    status text DEFAULT 'draft'::text,
    is_featured boolean DEFAULT false,
    is_digital boolean DEFAULT false,
    requires_shipping boolean DEFAULT true,
    is_taxable boolean DEFAULT true,
    tax_rate numeric(5,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    published_at timestamp with time zone,
    unit_price numeric(10,2) DEFAULT 0,
    sale_price numeric(10,2),
    current_stock integer DEFAULT 0,
    min_stock_level integer DEFAULT 5,
    track_stock boolean DEFAULT true,
    is_active boolean DEFAULT true,
    primary_image text,
    specifications jsonb DEFAULT '{}'::jsonb,
    created_by uuid,
    updated_by uuid,
    CONSTRAINT pos_mini_modular3_products_current_stock_check CHECK ((current_stock >= 0)),
    CONSTRAINT pos_mini_modular3_products_inventory_policy_check CHECK ((inventory_policy = ANY (ARRAY['allow'::text, 'deny'::text]))),
    CONSTRAINT pos_mini_modular3_products_product_type_check CHECK ((product_type = ANY (ARRAY['simple'::text, 'variant'::text]))),
    CONSTRAINT pos_mini_modular3_products_sale_price_check CHECK ((sale_price >= (0)::numeric)),
    CONSTRAINT pos_mini_modular3_products_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'archived'::text]))),
    CONSTRAINT pos_mini_modular3_products_unit_price_check CHECK ((unit_price >= (0)::numeric)),
    CONSTRAINT product_available_inventory_positive CHECK ((available_inventory >= 0)),
    CONSTRAINT product_cost_price_positive CHECK ((cost_price >= (0)::numeric)),
    CONSTRAINT product_inventory_positive CHECK ((total_inventory >= 0)),
    CONSTRAINT product_price_positive CHECK ((price >= (0)::numeric))
);


--
-- Name: TABLE pos_mini_modular3_products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_products IS 'Main products table with comprehensive inventory and pricing management';


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
-- Name: pos_mini_modular3_role_permission_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_role_permission_mappings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_role text NOT NULL,
    permission_id uuid NOT NULL,
    is_granted boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_role_permission_mappings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_role_permission_mappings IS 'Role-based permission assignments';


--
-- Name: pos_mini_modular3_role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_role_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_tier text NOT NULL,
    user_role text NOT NULL,
    feature_name text NOT NULL,
    can_read boolean DEFAULT false,
    can_write boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    can_manage boolean DEFAULT false,
    usage_limit integer,
    config_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT role_permissions_role_check CHECK ((user_role = ANY (ARRAY['business_owner'::text, 'household_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text, 'super_admin'::text]))),
    CONSTRAINT role_permissions_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])))
);


--
-- Name: pos_mini_modular3_security_audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_security_audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type text NOT NULL,
    user_id uuid,
    session_token text,
    ip_address text,
    user_agent text,
    event_data jsonb DEFAULT '{}'::jsonb,
    severity text DEFAULT 'INFO'::text,
    message text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_security_audit_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_security_audit_logs IS 'Security audit trail for all authentication and authorization events';


--
-- Name: pos_mini_modular3_session_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_session_activities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    activity_type text NOT NULL,
    activity_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_session_activities_activity_type_check CHECK ((activity_type = ANY (ARRAY['login'::text, 'logout'::text, 'action'::text, 'timeout'::text])))
);


--
-- Name: TABLE pos_mini_modular3_session_activities; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_session_activities IS 'Activity log for user sessions';


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
-- Name: pos_mini_modular3_tier_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_tier_features (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_tier text NOT NULL,
    feature_id uuid NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    feature_value jsonb,
    usage_limit integer,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT pos_mini_modular3_tier_features_subscription_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text, 'enterprise'::text])))
);


--
-- Name: TABLE pos_mini_modular3_tier_features; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_tier_features IS 'Default features enabled for each subscription tier';


--
-- Name: pos_mini_modular3_user_permission_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_user_permission_overrides (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    is_granted boolean NOT NULL,
    granted_by uuid,
    reason text,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_user_permission_overrides; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_user_permission_overrides IS 'User-specific permission overrides';


--
-- Name: pos_mini_modular3_user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_mini_modular3_user_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_token uuid DEFAULT gen_random_uuid() NOT NULL,
    device_info jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip_address inet,
    user_agent text,
    is_active boolean DEFAULT true,
    last_activity timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE pos_mini_modular3_user_sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pos_mini_modular3_user_sessions IS 'User session tracking for device management and security';


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permissions (id, permission_key, permission_name, description, category, created_at) FROM stdin;
9625d03f-80fe-4ab3-9609-746386835341	product.create	Tạo sản phẩm	Tạo sản phẩm mới	product	2025-07-13 18:44:54.337931+00
b091475b-ef02-4c9a-b67e-b69b28390d96	product.delete	Xóa sản phẩm	Xóa sản phẩm	product	2025-07-13 18:44:54.337931+00
058284cd-a7bf-46ab-831e-1870594de4b3	user.create	Tạo nhân viên	Tạo tài khoản nhân viên	user	2025-07-13 18:44:54.337931+00
1917a976-b013-4c90-8875-a00c7c4de1b1	user.delete	Xóa nhân viên	Xóa tài khoản nhân viên	user	2025-07-13 18:44:54.337931+00
cb0c5865-7bdd-417a-b065-5e8c270f1bc5	business.view_reports	Xem báo cáo	Xem các báo cáo kinh doanh	business	2025-07-13 18:44:54.337931+00
693652d8-93e6-400d-bbfd-e7ae36327869	product.read	Xem sản phẩm	Xem danh sách và chi tiết sản phẩm	product	2025-07-13 19:22:43.46839+00
9ede09aa-478d-4763-828b-eaee65d45703	product.update	Cập nhật sản phẩm	Chỉnh sửa thông tin sản phẩm	product	2025-07-13 19:22:43.46839+00
f435b208-fb94-443b-8b01-aaff917cc2f5	product.manage_categories	Quản lý danh mục	Tạo/sửa/xóa danh mục sản phẩm	product	2025-07-13 19:22:43.46839+00
fe85b479-b6c0-4081-8b71-2db58f4519d8	product.manage_inventory	Quản lý tồn kho	Điều chỉnh số lượng tồn kho	product	2025-07-13 19:22:43.46839+00
14572288-ad66-4c0a-9d46-dc78082df259	product.view_cost_price	Xem giá vốn	Xem giá vốn sản phẩm	product	2025-07-13 19:22:43.46839+00
ce3db7eb-60fc-42ef-a504-f4a564166394	user.read	Xem thông tin nhân viên	Xem danh sách nhân viên	user	2025-07-13 19:22:43.46839+00
2a6d461d-b941-4514-8863-d9d809737777	user.update	Cập nhật nhân viên	Chỉnh sửa thông tin nhân viên	user	2025-07-13 19:22:43.46839+00
0e600b21-9eac-4ba0-90a9-093e7490cdaa	user.manage_permissions	Quản lý quyền	Phân quyền cho nhân viên	user	2025-07-13 19:22:43.46839+00
73def10f-afee-432c-9f75-d6b2999d7dae	business.read	Xem thông tin doanh nghiệp	Xem thông tin doanh nghiệp	business	2025-07-13 19:22:43.46839+00
5f8d88e1-26d0-49fb-bc6b-59420f8a8661	business.update	Cập nhật doanh nghiệp	Chỉnh sửa thông tin doanh nghiệp	business	2025-07-13 19:22:43.46839+00
647587b4-0c64-40ad-8c5e-ed4b1ebfc3d5	business.manage_settings	Quản lý cài đặt	Thay đổi cài đặt hệ thống	business	2025-07-13 19:22:43.46839+00
3bd0fbf4-4e23-4524-b47c-3a6849849e6a	financial.view_revenue	Xem doanh thu	Xem thông tin doanh thu	financial	2025-07-13 19:22:43.46839+00
69ebc3d4-2ea5-4210-bc0a-1949e1e50d1e	financial.view_cost	Xem chi phí	Xem thông tin chi phí	financial	2025-07-13 19:22:43.46839+00
2aa5099a-d7cc-4f16-8b34-c9ec3f5d7154	financial.manage_pricing	Quản lý giá bán	Thay đổi giá bán sản phẩm	financial	2025-07-13 19:22:43.46839+00
e016e1ef-fa09-4f8f-9ec3-c5f2921a1af8	system.view_logs	Xem logs hệ thống	Xem logs và audit trail	system	2025-07-13 19:22:43.46839+00
7cd5c639-43bb-44cf-9c74-55bd007d7576	system.manage_backup	Quản lý backup	Tạo và khôi phục backup	system	2025-07-13 19:22:43.46839+00
2da63f57-f2c8-4988-8c5a-23a3247f73fa	system.super_admin	Super Admin	Quyền cao nhất của hệ thống	system	2025-07-13 19:22:43.46839+00
\.


--
-- Data for Name: pos_mini_modular3_admin_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_admin_sessions (id, super_admin_id, target_business_id, impersonated_role, session_reason, session_start, session_end, is_active, created_at) FROM stdin;
\.


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
aey5miijilmcq8vofz	pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc	full	8598	d703319c969a7e115ddf6359bb3bcaca56272e2d5846c90916bedbdc0f5ac2ee	2025-07-05 12:53:53.663+00	Unknown	["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]	t	t	pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc	2025-08-04 12:53:55.926+00	completed	\N	system
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
-- Data for Name: pos_mini_modular3_business_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_features (id, business_id, feature_id, is_enabled, feature_value, override_reason, enabled_by, enabled_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_business_invitations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_invitations (id, business_id, invited_by, email, role, invitation_token, status, expires_at, accepted_at, accepted_by, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_business_memberships; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_memberships (id, business_id, user_id, role, status, permissions, invited_by, invited_at, joined_at, created_at, updated_at) FROM stdin;
fa617169-84f2-4f0a-b062-798d69611ba6	6f699d8d-3a1d-4820-8d3f-a824608181ec	5f8d74cf-572a-4640-a565-34c5e1462f4e	household_owner	active	[]	\N	\N	2025-07-16 02:06:02.41061+00	2025-07-16 02:06:02.41061+00	2025-07-16 02:06:02.41061+00
\.


--
-- Data for Name: pos_mini_modular3_business_type_category_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_type_category_templates (id, business_type, template_name, description, category_name, category_description, category_icon, category_color_hex, parent_category_name, sort_order, is_default, is_required, allows_inventory, allows_variants, requires_description, is_active, version, created_at, updated_at) FROM stdin;
5091fe7d-9bbf-4248-8b55-5b990086eed2	agriculture	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
95b242e8-8091-4039-83e6-0d73302b9175	agriculture	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
258a327d-4a27-4bb8-9710-2aa2bff41c27	automotive	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
e54c430b-597a-4bda-936a-a77951386817	automotive	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
371626d4-adf7-44bf-a64f-41a8b4b0db5c	beauty	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
b674c8d7-e084-44c1-b98a-7affddfbd182	beauty	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
ba48d393-2fa3-4cff-b7cd-5bb4d1dd3b45	cafe	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
9999d669-b1d2-46c2-9d5f-f5e034050510	cafe	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
dd181cb8-9265-47ed-ab9f-7c38eaf0cbcb	cleaning	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
d82488b9-108a-41eb-93e4-61a28887ab06	cleaning	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
17eaa040-f0a4-4648-8f7a-cff0c273f6bc	clinic	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
d124093e-217b-4ba6-993c-64a9f5b5c9ee	clinic	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
dd5fd0d9-7ec8-47f6-a4ab-4c396c775ef0	construction	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
8ac3dd89-09af-464c-86c5-fcf2d681b6d9	construction	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
89a007d9-3293-4d10-b8f2-82d9a8b6bfab	consulting	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
3d184b02-e714-4231-b596-9f5468e5a68a	consulting	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
cfca4a33-0650-4fb5-872e-0b30141285c9	education	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
59b027fc-a6f3-4203-905a-b9e1ab3ad6b9	education	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
f2f5d130-ff91-4dfe-b3d8-e2b9a8826dd9	electronics	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
905982ee-2544-4e0c-8f88-f156689be0b2	electronics	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
4d6d5494-eb01-44b1-a13f-436fefa00a46	entertainment	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
3eea454b-4d9d-4b1d-8d82-dadb18bbefa1	entertainment	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
cd0ca5db-37a0-456c-8687-f42657dd3d8d	fashion	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
f896ab90-3433-4f18-b834-bd32e82b7f18	fashion	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
25c703ef-31ca-4928-8a62-48a3a694f2d6	finance	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
2c362391-5163-430a-810e-49aa6b1ca1f4	finance	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
130f873b-4c5a-48b1-9cc3-176d194e2bb3	food_service	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
b37f31b7-8e68-499f-98a2-52939db7ada5	food_service	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
8718f1e4-b90b-4cc0-879d-5cdda656ae11	gym	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
c71460bc-c11d-4b69-be8d-82c1ef6817f7	gym	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
a84e30d8-4d91-48ce-be48-23c9a36ca03f	healthcare	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
0a9a0845-5260-4806-bb2e-b280753dacf7	healthcare	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
4ba15d8c-c55e-4ad9-ac6e-65b3c4febba2	hotel	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
73762ef0-f3d9-4771-b877-5afc9e16e2e2	hotel	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
711aac20-978d-46b3-b796-792f2f849481	logistics	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
e28f1c51-8592-4213-8c3b-23fad8e90c7a	logistics	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
6cd11ec5-9738-46b0-9bde-da13d402b0fc	manufacturing	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
92955571-e38d-4bf5-ae17-52839e2858e2	manufacturing	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
c7fcfd70-cd8c-4704-af81-8e4f7bd42a0c	other	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
ffd124c6-7b62-45b4-9104-9f24aded05be	other	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
219928c3-a4ee-4717-ac34-12361f70f9f8	pharmacy	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
48e694ae-664a-4804-9d41-1f58811db4fc	pharmacy	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
d93ad2d2-8e09-436b-805a-bf4625166933	real_estate	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
090d0605-16f4-49ab-99d2-952d273a5391	real_estate	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
522bbe4c-b1a7-4f28-9e4f-8f016a317c75	repair	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
6f6713ac-cfab-4dd1-8ad4-f3e299a90b33	repair	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
a39e972c-bf4d-4235-84af-7fb9393b849e	restaurant	Restaurant Basic	\N	Khai vị	Món ăn khai vị, salad, soup	🥗	#10B981	\N	10	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
0817e74b-87d0-4e78-98b7-2338262569e6	restaurant	Restaurant Basic	\N	Món chính	Cơm, phở, bún, món chính	🍛	#F59E0B	\N	20	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
01b4f257-b662-42a5-b6ca-bd616505e07e	restaurant	Restaurant Basic	\N	Tráng miệng	Chè, bánh ngọt, kem	🍰	#EC4899	\N	30	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
6f7a2535-e5c0-42ed-a46f-3c018cd9ba09	restaurant	Restaurant Basic	\N	Đồ uống	Nước ngọt, bia, trà, cà phê	☕	#3B82F6	\N	40	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
c33eb929-93f6-492d-9833-cd46e8a11fe3	restaurant	Restaurant Basic	\N	Combo	Set ăn, combo ưu đãi	🍱	#8B5CF6	\N	50	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
a7e7db6b-cee8-4c4a-bb05-dc4566267464	retail	Retail Basic	\N	Thực phẩm	Đồ ăn, thức uống, thực phẩm tươi sống	🍎	#10B981	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
33115617-ee47-46c5-b30f-30dfcd38062a	retail	Retail Basic	\N	Đồ uống	Nước ngọt, bia rượu, đồ uống có cồn	🥤	#3B82F6	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
dc3af747-cc3d-4b8c-8a10-d90f85fc10d8	retail	Retail Basic	\N	Gia dụng	Đồ dùng trong nhà, dụng cụ nấu nướng	🏠	#F59E0B	\N	30	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
d359cd3f-f58e-45a8-87bd-2171c6bcf564	retail	Retail Basic	\N	Điện tử	Điện thoại, máy tính, thiết bị điện tử	📱	#8B5CF6	\N	40	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
8da4d532-bc90-4437-87c4-7d2a46b1030d	retail	Retail Basic	\N	Thời trang	Quần áo, giày dép, phụ kiện	👕	#EC4899	\N	50	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
2a619071-f849-42c7-8789-2739d79d3bdb	salon	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
e8026d13-bc3a-4377-91e5-e806eb55394c	salon	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
8642c339-027a-4de8-ab08-0c9e2c8b2864	service	Service Basic	\N	Dịch vụ cơ bản	Dịch vụ chăm sóc, tư vấn	🛠️	#10B981	\N	10	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
4ac7f6df-72bc-4f93-8a8c-ac2c5cb5e1b8	service	Service Basic	\N	Dịch vụ cao cấp	Dịch vụ premium, VIP	⭐	#F59E0B	\N	20	t	f	f	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
4ffcdb3b-8b29-42e4-ae4c-bf7fb1cc6bcc	service	Service Basic	\N	Sản phẩm	Sản phẩm bán kèm dịch vụ	📦	#3B82F6	\N	30	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
6e83d231-cb26-497e-b7bd-516d502ab76c	spa	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
5e3411e8-3dde-462e-b1f2-d1cec8867666	spa	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
77fce905-0bb8-4064-a585-6c2412008ab1	sports	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
393ed885-4a62-41ab-af2d-a12761711dc1	sports	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
10a9fe69-33c7-443f-9c4c-f5f6f79eeb9b	travel	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
e0c6efc2-80c1-4e7f-90c4-98381355ab8b	travel	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
22d5b887-7e65-4ee8-b1c6-851de5913805	wholesale	Basic Template	\N	Sản phẩm chính	Sản phẩm và dịch vụ chính	📦	#6B7280	\N	10	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
2652b827-9482-416d-849c-6ff58d3dbff3	wholesale	Basic Template	\N	Phụ kiện	Phụ kiện và sản phẩm bổ sung	🔧	#9CA3AF	\N	20	t	f	t	t	f	t	1	2025-07-07 02:10:19.011267+00	2025-07-07 02:10:19.011267+00
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

COPY public.pos_mini_modular3_businesses (id, name, code, business_type, phone, email, address, tax_code, legal_representative, logo_url, status, settings, subscription_tier, subscription_status, subscription_starts_at, subscription_ends_at, trial_ends_at, max_users, max_products, created_at, updated_at, features_enabled, usage_stats, last_billing_date, next_billing_date) FROM stdin;
6f699d8d-3a1d-4820-8d3f-a824608181ec	Highland Coffee Demo	DEMO001	cafe	\N	\N	\N	\N	\N	\N	active	{}	free	active	2025-07-10 19:47:25.443433+00	\N	2025-08-09 19:47:25.443433+00	3	50	2025-07-10 19:47:25.443433+00	2025-07-10 19:47:25.443433+00	{}	{}	\N	\N
\.


--
-- Data for Name: pos_mini_modular3_enhanced_user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_enhanced_user_sessions (id, user_id, session_token, device_info, ip_address, user_agent, fingerprint, location_data, security_flags, risk_score, expires_at, created_at, last_activity_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_failed_login_attempts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_failed_login_attempts (id, identifier, identifier_type, attempt_count, last_attempt_at, is_locked, lock_expires_at, created_at) FROM stdin;
b01b49a6-d55a-4035-a3d1-df4f86e8404c	quick.test@example.com	email	1	2025-07-13 20:51:05.518+00	f	\N	2025-07-13 20:51:05.040276+00
b73a5efb-fab2-4507-9522-a39cac6a875a	client.test@example.com	email	1	2025-07-13 20:55:31.146+00	f	\N	2025-07-13 20:55:30.651319+00
\.


--
-- Data for Name: pos_mini_modular3_feature_usage; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_feature_usage (id, business_id, feature_id, user_id, usage_count, usage_data, usage_date, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_features (id, feature_key, feature_name, description, feature_type, default_value, is_system_feature, created_at, updated_at) FROM stdin;
5892d548-e8e8-4f69-bcc9-0d36e26dfa18	max_products	Giới hạn sản phẩm	Số lượng sản phẩm tối đa có thể tạo	number	20	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
0f7468ea-4cb2-467a-b0be-77aa14691d16	max_staff	Giới hạn nhân viên	Số lượng nhân viên tối đa	number	2	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
706f7789-cb15-46a1-be6b-e6ca62fa4931	module_inventory_management	Quản lý kho hàng	Truy cập module quản lý kho	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
e1e93563-9c71-4b94-9131-69a4396348c7	module_advanced_reports	Báo cáo nâng cao	Truy cập module báo cáo nâng cao	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
fb5e41a7-5930-4630-9e85-6ee5f11550ad	module_staff_management	Quản lý nhân viên	Truy cập module quản lý nhân viên	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
e72ac267-55bc-45d0-8f8a-531379f1d0e9	module_api_access	Truy cập API	Sử dụng REST API	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
e016c54c-dbb2-4b47-b42f-d27dbfd6da1b	module_multi_location	Nhiều địa điểm	Quản lý nhiều cửa hàng	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
f4a1e5cb-7ff2-4ec6-9933-263bee8221db	advanced_reports	Báo cáo nâng cao	Truy cập báo cáo chi tiết và analytics	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
32c95473-e891-4f44-a331-d6d7f0d4a547	multi_location	Nhiều địa điểm	Quản lý nhiều cửa hàng/chi nhánh	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
cdc6c5c3-36e1-4d00-8d1f-e6d2151650a8	api_access	Truy cập API	Sử dụng REST API cho tích hợp	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
1a6a370b-69bf-447e-9acf-02b1bd08867b	custom_receipts	Hóa đơn tùy chỉnh	Thiết kế template hóa đơn riêng	boolean	false	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
7a7c7b38-95e5-4c30-9fbd-cde69dcdff44	inventory_alerts	Cảnh báo tồn kho	Thông báo khi sản phẩm sắp hết	boolean	true	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
5376ba1c-efc0-4b15-bc1a-6bca62e5c981	backup_frequency	Tần suất backup	Backup dữ liệu tự động	string	"manual"	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
42869034-7077-48da-9521-7dd6ffd1e2cb	data_retention_days	Lưu trữ dữ liệu	Số ngày lưu trữ dữ liệu	number	30	t	2025-07-08 00:45:07.723382+00	2025-07-08 00:45:07.723382+00
\.


--
-- Data for Name: pos_mini_modular3_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_permissions (id, permission_key, permission_name, description, category, created_at) FROM stdin;
c3d90810-60c2-41d4-894a-982411be6d14	product.create	Tạo sản phẩm	Tạo sản phẩm mới	product	2025-07-13 19:38:51.507244+00
83b7b48c-61a3-4d55-aae8-b43b5fc3115e	product.read	Xem sản phẩm	Xem danh sách và chi tiết sản phẩm	product	2025-07-13 19:38:51.507244+00
ed0ef6b3-00ad-4392-87c6-2b330faa3597	product.update	Cập nhật sản phẩm	Chỉnh sửa thông tin sản phẩm	product	2025-07-13 19:38:51.507244+00
9ce1aa3f-434c-408f-ab35-1ce43791a6a4	product.delete	Xóa sản phẩm	Xóa sản phẩm khỏi hệ thống	product	2025-07-13 19:38:51.507244+00
b22f5bcb-109d-406a-816d-e93ae91780c7	product.manage_categories	Quản lý danh mục	Tạo/sửa/xóa danh mục sản phẩm	product	2025-07-13 19:38:51.507244+00
86576bc3-8ab5-4b44-bee9-39a54e73938e	product.manage_inventory	Quản lý tồn kho	Điều chỉnh số lượng tồn kho	product	2025-07-13 19:38:51.507244+00
3ffb1842-a2c9-4c00-8416-81cbe6c74ae8	product.view_cost_price	Xem giá vốn	Xem giá vốn sản phẩm	product	2025-07-13 19:38:51.507244+00
6115ccf5-759a-4bee-aaf2-efca0c0ad419	user.create	Tạo nhân viên	Tạo tài khoản nhân viên mới	user	2025-07-13 19:38:51.507244+00
b5515c3a-29d5-4227-93b0-34c7cd51ff85	user.read	Xem thông tin nhân viên	Xem danh sách nhân viên	user	2025-07-13 19:38:51.507244+00
e119f276-a382-48fb-b0f6-50e7b373b33e	user.update	Cập nhật nhân viên	Chỉnh sửa thông tin nhân viên	user	2025-07-13 19:38:51.507244+00
310e4386-7928-4889-a924-dcf478cb821f	user.delete	Xóa nhân viên	Xóa tài khoản nhân viên	user	2025-07-13 19:38:51.507244+00
8c2ad9b5-52b1-4a7a-8af3-269cee4a042c	user.manage_permissions	Quản lý quyền	Phân quyền cho nhân viên	user	2025-07-13 19:38:51.507244+00
1aa1b9e2-065d-4f9c-9b0d-fcde1546b53f	business.read	Xem thông tin doanh nghiệp	Xem thông tin doanh nghiệp	business	2025-07-13 19:38:51.507244+00
4c7af922-331c-4441-a7fc-c35d3c21d2ac	business.update	Cập nhật doanh nghiệp	Chỉnh sửa thông tin doanh nghiệp	business	2025-07-13 19:38:51.507244+00
ef942c28-d433-4942-b22f-fbab28d45da1	business.view_reports	Xem báo cáo	Xem các báo cáo kinh doanh	business	2025-07-13 19:38:51.507244+00
fb39b54a-e24f-4465-8dbc-35836bbc3a93	business.manage_settings	Quản lý cài đặt	Thay đổi cài đặt hệ thống	business	2025-07-13 19:38:51.507244+00
1b786d09-25a7-4fb6-a773-6d7d1ca45b12	financial.view_revenue	Xem doanh thu	Xem thông tin doanh thu	financial	2025-07-13 19:38:51.507244+00
88c93939-119a-4e56-8c43-bcf3de19baa9	financial.view_cost	Xem chi phí	Xem thông tin chi phí	financial	2025-07-13 19:38:51.507244+00
e22c0d8a-f4eb-4cf7-914d-4f9e71f22096	financial.manage_pricing	Quản lý giá bán	Thay đổi giá bán sản phẩm	financial	2025-07-13 19:38:51.507244+00
a97b68bd-c07e-431b-999e-d0816d2fb23d	system.view_logs	Xem logs hệ thống	Xem logs và audit trail	system	2025-07-13 19:38:51.507244+00
c26d8dee-98e2-433a-942e-9a89deb02919	system.manage_backup	Quản lý backup	Tạo và khôi phục backup	system	2025-07-13 19:38:51.507244+00
f53aa075-e7ee-4e6a-ad1d-66da64fb0f73	system.super_admin	Super Admin	Quyền cao nhất của hệ thống	system	2025-07-13 19:38:51.507244+00
823ad400-082a-454f-83c0-de5f9c2232f1	dashboard_access	Dashboard Access	Allow user to access main dashboard interface	system	2025-07-14 01:52:52.769013+00
\.


--
-- Data for Name: pos_mini_modular3_product_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_categories (id, business_id, name, description, icon, color_hex, parent_id, sort_order, is_active, is_default, is_required, allows_inventory, allows_variants, requires_description, slug, product_count, created_at, updated_at, created_by, updated_by) FROM stdin;
44850b57-4762-45ee-a0ef-86ec16177c49	6f699d8d-3a1d-4820-8d3f-a824608181ec	Đồ uống	Trà, nước ép, smoothie	\N	#6B7280	\N	2	t	f	f	t	t	f	ung	0	2025-07-10 19:47:25.443433+00	2025-07-10 19:47:25.443433+00	\N	\N
3f73118a-e473-48ae-a2ce-82c0cc0d40ed	6f699d8d-3a1d-4820-8d3f-a824608181ec	Đồ ăn	Bánh ngọt, sandwich	\N	#6B7280	\N	3	t	f	f	t	t	f	n	0	2025-07-10 19:47:25.443433+00	2025-07-10 19:47:25.443433+00	\N	\N
f39bb53d-b7ca-424a-a8c8-79bb000e455a	6f699d8d-3a1d-4820-8d3f-a824608181ec	Cà phê	Các loại cà phê espresso, americano	\N	#6B7280	\N	1	t	f	f	t	t	f	c-ph	0	2025-07-10 19:47:25.443433+00	2025-07-12 05:17:30.080015+00	\N	\N
\.


--
-- Data for Name: pos_mini_modular3_product_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_images (id, product_id, variant_id, business_id, url, filename, original_filename, alt_text, size_bytes, width, height, format, is_primary, display_order, is_active, created_at, uploaded_by) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_inventory (id, business_id, product_id, variant_id, transaction_type, quantity_change, quantity_after, reference_type, reference_id, notes, location_name, unit_cost, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_variants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_variants (id, product_id, business_id, title, option1, option2, option3, sku, barcode, price, cost_price, compare_at_price, inventory_quantity, inventory_policy, weight, dimensions, image, is_active, "position", created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_products (id, business_id, category_id, name, description, short_description, sku, barcode, price, cost_price, compare_at_price, product_type, has_variants, variant_options, track_inventory, inventory_policy, total_inventory, available_inventory, weight, dimensions, images, featured_image, slug, tags, meta_title, meta_description, status, is_featured, is_digital, requires_shipping, is_taxable, tax_rate, created_at, updated_at, published_at, unit_price, sale_price, current_stock, min_stock_level, track_stock, is_active, primary_image, specifications, created_by, updated_by) FROM stdin;
eb258577-ffde-4f7a-9773-3707a4095ddb	6f699d8d-3a1d-4820-8d3f-a824608181ec	f39bb53d-b7ca-424a-a8c8-79bb000e455a	Nồi cơm điện	Nồi cơm HItachi	\N	\N	\N	1000000.00	750000.00	0.00	simple	f	[]	t	deny	0	0	0.000	\N	[]	\N	ni-cm-in	["noicom", "thiet bi gia dinh"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 01:19:32.47205+00	2025-07-12 01:19:32.47205+00	\N	0.00	\N	9	1	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
7ef359c4-cce3-4521-9453-94f42afe8f96	6f699d8d-3a1d-4820-8d3f-a824608181ec	\N	Bò Úc - Lõi Vai  Bò 200g	Hàng chính hãng có giấy tờ đầy đủ	\N	\N	\N	0.00	0.00	0.00	simple	f	[]	t	deny	0	0	0.000	\N	[]	\N	b-c-li-vai-b-200g	["bo uc", "ga uc"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 02:56:12.170081+00	2025-07-12 02:56:12.170081+00	\N	0.00	\N	100	5	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
e2aab8f4-2db5-40b1-8bd1-7d17d0721234	6f699d8d-3a1d-4820-8d3f-a824608181ec	f39bb53d-b7ca-424a-a8c8-79bb000e455a	Bida 01	Thang bida  Thien Long	\N	\N	\N	50000.00	30000.00	\N	simple	f	[]	t	deny	0	0	\N	\N	[]	\N	bida-01	["khuyen mai", "the tag"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 05:17:30.080015+00	2025-07-12 05:17:30.080015+00	\N	0.00	\N	60	5	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
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
-- Data for Name: pos_mini_modular3_role_permission_mappings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_role_permission_mappings (id, user_role, permission_id, is_granted, created_at) FROM stdin;
b2dd23ea-bb71-4796-af5e-265216401c22	household_owner	c3d90810-60c2-41d4-894a-982411be6d14	t	2025-07-13 19:38:51.507244+00
e1808047-53e6-4524-ad7d-c205f3664ce2	household_owner	83b7b48c-61a3-4d55-aae8-b43b5fc3115e	t	2025-07-13 19:38:51.507244+00
2ba336e8-8c30-4ba8-be7d-f1cd4418fd1b	household_owner	ed0ef6b3-00ad-4392-87c6-2b330faa3597	t	2025-07-13 19:38:51.507244+00
7991400d-efb6-4f0e-9671-dd3ec1200b96	household_owner	9ce1aa3f-434c-408f-ab35-1ce43791a6a4	t	2025-07-13 19:38:51.507244+00
e323aab1-e368-472d-9bbf-f579ae382c8a	household_owner	b22f5bcb-109d-406a-816d-e93ae91780c7	t	2025-07-13 19:38:51.507244+00
e719eab6-1523-4d43-937e-58793bd0c912	household_owner	86576bc3-8ab5-4b44-bee9-39a54e73938e	t	2025-07-13 19:38:51.507244+00
0825d557-f524-44dd-b2ba-43542f33136f	household_owner	3ffb1842-a2c9-4c00-8416-81cbe6c74ae8	t	2025-07-13 19:38:51.507244+00
ed6e178e-02b7-4c0b-a9bd-11345b0ea359	household_owner	6115ccf5-759a-4bee-aaf2-efca0c0ad419	t	2025-07-13 19:38:51.507244+00
c7ddec26-0a4a-42fb-88eb-c5e63238efd1	household_owner	b5515c3a-29d5-4227-93b0-34c7cd51ff85	t	2025-07-13 19:38:51.507244+00
e4cc6571-63fe-4509-9b6f-7dff3fcf5104	household_owner	e119f276-a382-48fb-b0f6-50e7b373b33e	t	2025-07-13 19:38:51.507244+00
402890a6-7692-44b3-aa9a-2e867a083553	household_owner	310e4386-7928-4889-a924-dcf478cb821f	t	2025-07-13 19:38:51.507244+00
16dd1099-e93e-42cc-9820-2b633a23ed07	household_owner	8c2ad9b5-52b1-4a7a-8af3-269cee4a042c	t	2025-07-13 19:38:51.507244+00
2cb6f0ee-87d0-404d-928b-ce709df8a7bf	household_owner	1aa1b9e2-065d-4f9c-9b0d-fcde1546b53f	t	2025-07-13 19:38:51.507244+00
4048ff44-f668-46f8-92d8-eeacf693b3b3	household_owner	4c7af922-331c-4441-a7fc-c35d3c21d2ac	t	2025-07-13 19:38:51.507244+00
310abcb6-0972-45e6-bb15-7fa3695b94f3	household_owner	ef942c28-d433-4942-b22f-fbab28d45da1	t	2025-07-13 19:38:51.507244+00
e29bafd7-8c08-4de9-b334-3da78ac9fc13	household_owner	fb39b54a-e24f-4465-8dbc-35836bbc3a93	t	2025-07-13 19:38:51.507244+00
1c815943-e796-4649-8284-f2f7211e3089	household_owner	1b786d09-25a7-4fb6-a773-6d7d1ca45b12	t	2025-07-13 19:38:51.507244+00
b7cd66b5-97c8-4eba-9fa4-590b04082779	household_owner	88c93939-119a-4e56-8c43-bcf3de19baa9	t	2025-07-13 19:38:51.507244+00
831bf4fb-53f7-4cb7-9280-5b766dab7362	household_owner	e22c0d8a-f4eb-4cf7-914d-4f9e71f22096	t	2025-07-13 19:38:51.507244+00
49e95b3f-0f9d-4884-9ce9-c243c56c50cf	household_owner	a97b68bd-c07e-431b-999e-d0816d2fb23d	t	2025-07-13 19:38:51.507244+00
faa39a6c-71c3-4839-9e63-c78e8b13176e	household_owner	c26d8dee-98e2-433a-942e-9a89deb02919	t	2025-07-13 19:38:51.507244+00
adab6c7c-b1ff-45af-8418-b46ffdd48838	household_owner	f53aa075-e7ee-4e6a-ad1d-66da64fb0f73	t	2025-07-13 19:38:51.507244+00
9aa9fa75-2203-44fb-9c56-f5f3a8c9104e	manager	c3d90810-60c2-41d4-894a-982411be6d14	t	2025-07-13 19:38:51.507244+00
e178836b-2fed-4a4a-ba4e-d0c43970eb70	manager	83b7b48c-61a3-4d55-aae8-b43b5fc3115e	t	2025-07-13 19:38:51.507244+00
c2c7ec61-5a88-4a71-b0b0-19b6018ebe98	manager	ed0ef6b3-00ad-4392-87c6-2b330faa3597	t	2025-07-13 19:38:51.507244+00
48696c4e-148c-41c9-a88b-5393bbd895a5	manager	b22f5bcb-109d-406a-816d-e93ae91780c7	t	2025-07-13 19:38:51.507244+00
8d8ddb4f-30d3-4697-8a70-7988d3e7780b	manager	86576bc3-8ab5-4b44-bee9-39a54e73938e	t	2025-07-13 19:38:51.507244+00
e90c1ada-9d3c-4ae4-bcd4-717a53f6ed81	manager	6115ccf5-759a-4bee-aaf2-efca0c0ad419	t	2025-07-13 19:38:51.507244+00
19f20b1e-b53b-4948-87a9-ed048774984b	manager	b5515c3a-29d5-4227-93b0-34c7cd51ff85	t	2025-07-13 19:38:51.507244+00
0dac814d-407e-4161-a6a2-799237c8b566	manager	e119f276-a382-48fb-b0f6-50e7b373b33e	t	2025-07-13 19:38:51.507244+00
68ec0ccd-8ac0-456d-b5ad-9ec888403c81	manager	1aa1b9e2-065d-4f9c-9b0d-fcde1546b53f	t	2025-07-13 19:38:51.507244+00
a4dabc52-28b6-409c-ab91-0930d33262c7	manager	ef942c28-d433-4942-b22f-fbab28d45da1	t	2025-07-13 19:38:51.507244+00
9ea4e1cf-11f1-4da7-b38a-296339b1eaab	manager	1b786d09-25a7-4fb6-a773-6d7d1ca45b12	t	2025-07-13 19:38:51.507244+00
ee01dcbe-5e9e-46f6-8a22-e9452fc04831	manager	e22c0d8a-f4eb-4cf7-914d-4f9e71f22096	t	2025-07-13 19:38:51.507244+00
36de1b86-1907-48fc-ad0f-99b366b61928	seller	c3d90810-60c2-41d4-894a-982411be6d14	t	2025-07-13 19:38:51.507244+00
73a5f4dd-092d-41fd-8f9b-839abe16cc6a	seller	83b7b48c-61a3-4d55-aae8-b43b5fc3115e	t	2025-07-13 19:38:51.507244+00
2679877d-4547-4942-9a36-63e54f0a1ad3	seller	ed0ef6b3-00ad-4392-87c6-2b330faa3597	t	2025-07-13 19:38:51.507244+00
5e573ecd-6c1c-45e7-9367-acb8397d2a3a	seller	b5515c3a-29d5-4227-93b0-34c7cd51ff85	t	2025-07-13 19:38:51.507244+00
63797e98-aae7-415d-ac07-8d2c9fbb9a9e	accountant	83b7b48c-61a3-4d55-aae8-b43b5fc3115e	t	2025-07-13 19:38:51.507244+00
7d08abe3-f23c-4510-a1d3-53e18579e67b	accountant	3ffb1842-a2c9-4c00-8416-81cbe6c74ae8	t	2025-07-13 19:38:51.507244+00
a3928ad7-e404-402d-8482-580c3a2a829c	accountant	b5515c3a-29d5-4227-93b0-34c7cd51ff85	t	2025-07-13 19:38:51.507244+00
5ba11196-83fd-49b4-bff5-6bb167d354da	accountant	1aa1b9e2-065d-4f9c-9b0d-fcde1546b53f	t	2025-07-13 19:38:51.507244+00
065e2aba-2349-4470-b40d-bf5594675b36	accountant	ef942c28-d433-4942-b22f-fbab28d45da1	t	2025-07-13 19:38:51.507244+00
9b0e8aba-8a09-4198-a8c2-4c754d7b3d88	accountant	1b786d09-25a7-4fb6-a773-6d7d1ca45b12	t	2025-07-13 19:38:51.507244+00
054c8382-5350-45a0-8871-bab5b54b53e9	accountant	88c93939-119a-4e56-8c43-bcf3de19baa9	t	2025-07-13 19:38:51.507244+00
25c3926b-9537-40ae-9a55-8bfd9cea4265	super_admin	c3d90810-60c2-41d4-894a-982411be6d14	t	2025-07-13 19:38:51.507244+00
0c48bd21-2bd8-4814-83a8-6509e0fae24c	super_admin	83b7b48c-61a3-4d55-aae8-b43b5fc3115e	t	2025-07-13 19:38:51.507244+00
139fef61-e147-4918-a280-a89cafd9b0cb	super_admin	ed0ef6b3-00ad-4392-87c6-2b330faa3597	t	2025-07-13 19:38:51.507244+00
218c666b-e65f-4b80-9614-15a2ec276fe6	super_admin	9ce1aa3f-434c-408f-ab35-1ce43791a6a4	t	2025-07-13 19:38:51.507244+00
a796f924-f1a0-4b45-bbef-f70e656186ad	super_admin	b22f5bcb-109d-406a-816d-e93ae91780c7	t	2025-07-13 19:38:51.507244+00
97c96d31-7794-4d60-bbb6-be07f209e109	super_admin	86576bc3-8ab5-4b44-bee9-39a54e73938e	t	2025-07-13 19:38:51.507244+00
430a3a92-23c4-4ecc-86b1-238f63db9ffc	super_admin	3ffb1842-a2c9-4c00-8416-81cbe6c74ae8	t	2025-07-13 19:38:51.507244+00
9b818557-208e-4ffd-8d5f-8bf469765e59	super_admin	6115ccf5-759a-4bee-aaf2-efca0c0ad419	t	2025-07-13 19:38:51.507244+00
50bd2b13-ee5b-42fb-b3ec-55615565eec0	super_admin	b5515c3a-29d5-4227-93b0-34c7cd51ff85	t	2025-07-13 19:38:51.507244+00
de5af1ab-ca05-4799-aef7-b683fddbea9a	super_admin	e119f276-a382-48fb-b0f6-50e7b373b33e	t	2025-07-13 19:38:51.507244+00
21c4b1f0-7a58-46ce-9cfe-998fb47d73e0	super_admin	310e4386-7928-4889-a924-dcf478cb821f	t	2025-07-13 19:38:51.507244+00
749ffb75-44a1-4bb2-ae59-973c37dacfdc	super_admin	8c2ad9b5-52b1-4a7a-8af3-269cee4a042c	t	2025-07-13 19:38:51.507244+00
4803e2aa-90ad-4c6f-85b0-bc0583ce135e	super_admin	1aa1b9e2-065d-4f9c-9b0d-fcde1546b53f	t	2025-07-13 19:38:51.507244+00
bd07be56-dddd-41ba-867a-fd33c860d20a	super_admin	4c7af922-331c-4441-a7fc-c35d3c21d2ac	t	2025-07-13 19:38:51.507244+00
cb74f92d-e0f2-419b-8d19-8f7fad8a1b87	super_admin	ef942c28-d433-4942-b22f-fbab28d45da1	t	2025-07-13 19:38:51.507244+00
b1508726-9168-4e38-9b7f-a639c2a0eb0f	super_admin	fb39b54a-e24f-4465-8dbc-35836bbc3a93	t	2025-07-13 19:38:51.507244+00
4caee604-ed8b-4b70-a8c3-95211f2c0d47	super_admin	1b786d09-25a7-4fb6-a773-6d7d1ca45b12	t	2025-07-13 19:38:51.507244+00
d90ce830-8354-4784-8b78-1358197b4bae	super_admin	88c93939-119a-4e56-8c43-bcf3de19baa9	t	2025-07-13 19:38:51.507244+00
e27aaeb4-3901-4b8b-b4fc-b870cfd81268	super_admin	e22c0d8a-f4eb-4cf7-914d-4f9e71f22096	t	2025-07-13 19:38:51.507244+00
2ec4e1a3-609e-43bc-9ec4-ee06dbc7eba2	super_admin	a97b68bd-c07e-431b-999e-d0816d2fb23d	t	2025-07-13 19:38:51.507244+00
17b8f525-0552-4814-9e4e-34bedd77df4f	super_admin	c26d8dee-98e2-433a-942e-9a89deb02919	t	2025-07-13 19:38:51.507244+00
899147d0-1074-4e5b-b672-fdb6714e476b	super_admin	f53aa075-e7ee-4e6a-ad1d-66da64fb0f73	t	2025-07-13 19:38:51.507244+00
b7b6c358-a088-4375-a003-c4138ced2880	admin	823ad400-082a-454f-83c0-de5f9c2232f1	t	2025-07-14 01:52:52.769013+00
d6433eda-8ca6-4df2-8d70-0383f5703de0	manager	823ad400-082a-454f-83c0-de5f9c2232f1	t	2025-07-14 01:52:52.769013+00
1b469e1e-a527-48d6-9d65-b8d834e91b3b	staff	823ad400-082a-454f-83c0-de5f9c2232f1	t	2025-07-14 01:52:52.769013+00
7d9a8201-c706-407e-8838-9d6e7b0c2ca4	user	823ad400-082a-454f-83c0-de5f9c2232f1	t	2025-07-14 01:52:52.769013+00
\.


--
-- Data for Name: pos_mini_modular3_role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_role_permissions (id, subscription_tier, user_role, feature_name, can_read, can_write, can_delete, can_manage, usage_limit, config_data, created_at, updated_at) FROM stdin;
805bdb3e-aa4e-4340-b0c4-ba7b280e619d	free	seller	product_management	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
2e10602e-d882-4add-bc96-184a98fef5ca	free	seller	pos_interface	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
fdaa9936-511a-4f70-9ed0-e0ab1a1c8633	free	seller	basic_reports	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
edf121d3-4b08-4028-a5d8-393b2d6f47d3	free	accountant	product_management	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
15ae7d18-c2ef-419f-977e-7b663f0abfed	free	accountant	financial_tracking	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
f2522ee3-c1bd-4281-8ea0-2a8318af1478	free	accountant	basic_reports	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
f89469f6-1670-44b3-9fa2-7a6b47623c54	free	household_owner	staff_management	t	t	t	t	3	{}	2025-07-06 16:40:23.275321+00	2025-07-10 17:50:35.085322+00
6a98ccc5-3d99-4236-a454-206329b61497	free	household_owner	financial_tracking	t	t	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-10 17:50:35.085322+00
366d08c0-0ebe-4d84-9f00-33a48eb69bfd	free	household_owner	product_management	t	t	t	t	50	{}	2025-07-06 16:40:23.275321+00	2025-07-10 23:55:27.136861+00
dd653483-67f0-4c03-a559-541e5cf0f884	free	household_owner	category_management	t	t	t	t	\N	{}	2025-07-10 23:55:27.136861+00	2025-07-10 23:55:27.136861+00
659c5b15-dfd1-49d3-bdda-51b4eff4fe30	free	household_owner	inventory_management	t	t	t	t	\N	{}	2025-07-10 23:55:27.136861+00	2025-07-10 23:55:27.136861+00
7dcb1350-225f-4582-9f6a-c5497c7b8337	free	household_owner	pos_interface	t	t	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-10 23:55:27.136861+00
8756f907-f221-4ecd-940f-ad7cc196c0da	free	household_owner	basic_reports	t	t	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-10 23:55:27.136861+00
\.


--
-- Data for Name: pos_mini_modular3_security_audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_security_audit_logs (id, event_type, user_id, session_token, ip_address, user_agent, event_data, severity, message, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_session_activities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_session_activities (id, session_id, activity_type, activity_data, created_at) FROM stdin;
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
-- Data for Name: pos_mini_modular3_tier_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_tier_features (id, subscription_tier, feature_id, is_enabled, feature_value, usage_limit, created_at) FROM stdin;
5a64f1b4-4b22-4228-bdf5-1a3b006f3ddc	free	5892d548-e8e8-4f69-bcc9-0d36e26dfa18	t	20	20	2025-07-08 00:45:07.723382+00
c4f41945-d34d-4217-9888-fe957ae0ba9b	free	0f7468ea-4cb2-467a-b0be-77aa14691d16	t	2	2	2025-07-08 00:45:07.723382+00
95218f40-ecb9-4b48-b6b8-ad520a278da3	free	706f7789-cb15-46a1-be6b-e6ca62fa4931	f	false	\N	2025-07-08 00:45:07.723382+00
b1e56129-5f3b-47b8-8cad-404d96ffef97	free	e1e93563-9c71-4b94-9131-69a4396348c7	f	false	\N	2025-07-08 00:45:07.723382+00
c47dd125-d0fc-47d7-94a5-0fdc4395c672	free	fb5e41a7-5930-4630-9e85-6ee5f11550ad	f	false	\N	2025-07-08 00:45:07.723382+00
0a0e976a-34e8-4376-89c7-cf80682a5883	free	e72ac267-55bc-45d0-8f8a-531379f1d0e9	f	false	\N	2025-07-08 00:45:07.723382+00
ad92a7d3-f7ad-47b5-b605-481fc0b5a02d	free	e016c54c-dbb2-4b47-b42f-d27dbfd6da1b	f	false	\N	2025-07-08 00:45:07.723382+00
9ec20005-c560-419b-9286-ff9be221f729	free	f4a1e5cb-7ff2-4ec6-9933-263bee8221db	f	false	\N	2025-07-08 00:45:07.723382+00
46f905c8-e71a-43f9-a213-d3cb864be5d0	free	32c95473-e891-4f44-a331-d6d7f0d4a547	f	false	\N	2025-07-08 00:45:07.723382+00
3250ab02-17b0-4b02-8d86-63930a458c90	free	cdc6c5c3-36e1-4d00-8d1f-e6d2151650a8	f	false	\N	2025-07-08 00:45:07.723382+00
08e17784-0cdb-4505-8756-5db81c3ab8ee	free	1a6a370b-69bf-447e-9acf-02b1bd08867b	f	false	\N	2025-07-08 00:45:07.723382+00
1c2208a5-8e29-4078-a24b-697e7ceb1a20	free	7a7c7b38-95e5-4c30-9fbd-cde69dcdff44	t	true	\N	2025-07-08 00:45:07.723382+00
d4dd3b71-2f28-4cf8-9232-03c128f9dfdc	free	5376ba1c-efc0-4b15-bc1a-6bca62e5c981	f	"manual"	\N	2025-07-08 00:45:07.723382+00
3cabf072-7379-4382-909f-c0e81cd7d5f9	free	42869034-7077-48da-9521-7dd6ffd1e2cb	f	30	\N	2025-07-08 00:45:07.723382+00
76a68f19-2778-458f-b6ee-f8a91f671b46	basic	5892d548-e8e8-4f69-bcc9-0d36e26dfa18	t	500	500	2025-07-08 00:45:07.723382+00
41d47d03-5924-4453-a68c-50e105342b26	basic	0f7468ea-4cb2-467a-b0be-77aa14691d16	t	10	10	2025-07-08 00:45:07.723382+00
7a66e5c0-7459-4cc2-9cfb-842beca1f094	basic	706f7789-cb15-46a1-be6b-e6ca62fa4931	t	false	\N	2025-07-08 00:45:07.723382+00
485ce93e-bbff-4873-8416-d5b2c67b7ccf	basic	e1e93563-9c71-4b94-9131-69a4396348c7	f	false	\N	2025-07-08 00:45:07.723382+00
4bc51ccb-723d-4854-8bee-8abc02cfcc94	basic	fb5e41a7-5930-4630-9e85-6ee5f11550ad	t	false	\N	2025-07-08 00:45:07.723382+00
0db1cc86-517c-4e8d-afe8-1ef3dc444c8b	basic	e72ac267-55bc-45d0-8f8a-531379f1d0e9	f	false	\N	2025-07-08 00:45:07.723382+00
09549130-9d07-4ce5-89b7-f099f1011f95	basic	e016c54c-dbb2-4b47-b42f-d27dbfd6da1b	f	false	\N	2025-07-08 00:45:07.723382+00
8fcd6b21-6997-4174-8e37-4c13bb725d01	basic	f4a1e5cb-7ff2-4ec6-9933-263bee8221db	t	false	\N	2025-07-08 00:45:07.723382+00
2aa825ea-1554-40cd-9e9a-7add58a30ceb	basic	32c95473-e891-4f44-a331-d6d7f0d4a547	f	false	\N	2025-07-08 00:45:07.723382+00
a918a76c-13fa-4a39-94e1-afc60f96d925	basic	cdc6c5c3-36e1-4d00-8d1f-e6d2151650a8	f	false	\N	2025-07-08 00:45:07.723382+00
94cac99d-749e-4664-b6bf-3b5c7586144a	basic	1a6a370b-69bf-447e-9acf-02b1bd08867b	t	false	\N	2025-07-08 00:45:07.723382+00
56cb6ac7-1cee-4c3a-ace2-5441c63cc355	basic	7a7c7b38-95e5-4c30-9fbd-cde69dcdff44	t	true	\N	2025-07-08 00:45:07.723382+00
3b18fc43-8c51-4906-b1e1-c395b3aedf92	basic	5376ba1c-efc0-4b15-bc1a-6bca62e5c981	f	"daily"	\N	2025-07-08 00:45:07.723382+00
38fd848a-2690-4dc0-ae50-d252a95ad62b	basic	42869034-7077-48da-9521-7dd6ffd1e2cb	f	90	\N	2025-07-08 00:45:07.723382+00
9d16a886-d1d7-45b5-9447-30ce1f738b37	premium	5892d548-e8e8-4f69-bcc9-0d36e26dfa18	t	5000	5000	2025-07-08 00:45:07.723382+00
0ad1fe60-71fb-4e7b-8af7-03b83363386e	premium	0f7468ea-4cb2-467a-b0be-77aa14691d16	t	50	50	2025-07-08 00:45:07.723382+00
7e7fde5f-da2b-46e9-8916-87879da471a4	premium	706f7789-cb15-46a1-be6b-e6ca62fa4931	t	false	\N	2025-07-08 00:45:07.723382+00
eb34c4f4-cead-4d9e-9c8f-1c94940732ba	premium	e1e93563-9c71-4b94-9131-69a4396348c7	t	false	\N	2025-07-08 00:45:07.723382+00
addfcd46-0765-4686-a601-bb3d5fcf8694	premium	fb5e41a7-5930-4630-9e85-6ee5f11550ad	t	false	\N	2025-07-08 00:45:07.723382+00
e6891e90-d3ca-425b-98f2-b733e3816e5f	premium	e72ac267-55bc-45d0-8f8a-531379f1d0e9	t	false	\N	2025-07-08 00:45:07.723382+00
f5e87f85-73d6-4dbf-a433-074589dec6c5	premium	e016c54c-dbb2-4b47-b42f-d27dbfd6da1b	t	false	\N	2025-07-08 00:45:07.723382+00
77fe9e35-7275-426e-8774-917353b58da2	premium	f4a1e5cb-7ff2-4ec6-9933-263bee8221db	t	false	\N	2025-07-08 00:45:07.723382+00
06449851-49ef-49f2-99bf-1a093545251c	premium	32c95473-e891-4f44-a331-d6d7f0d4a547	t	false	\N	2025-07-08 00:45:07.723382+00
3e8b3b05-a16e-4142-a4c7-24c6af7d7593	premium	cdc6c5c3-36e1-4d00-8d1f-e6d2151650a8	t	false	\N	2025-07-08 00:45:07.723382+00
e36dc19f-1aa0-42e5-8718-b84ed4da83f9	premium	1a6a370b-69bf-447e-9acf-02b1bd08867b	t	false	\N	2025-07-08 00:45:07.723382+00
a2a9d1cd-8b06-44f4-996b-0d290d77c0ba	premium	7a7c7b38-95e5-4c30-9fbd-cde69dcdff44	t	true	\N	2025-07-08 00:45:07.723382+00
edf6be57-383a-4887-97d2-e08b445f5f49	premium	5376ba1c-efc0-4b15-bc1a-6bca62e5c981	t	"hourly"	\N	2025-07-08 00:45:07.723382+00
de35e9df-825b-4c6f-92c6-698a7aa3aeea	premium	42869034-7077-48da-9521-7dd6ffd1e2cb	t	365	\N	2025-07-08 00:45:07.723382+00
ddd01531-c7b8-4e45-8b62-bc2903201c18	enterprise	5892d548-e8e8-4f69-bcc9-0d36e26dfa18	t	50000	50000	2025-07-08 00:45:07.723382+00
0c5560a7-d852-4f29-980f-7ac83beccad6	enterprise	0f7468ea-4cb2-467a-b0be-77aa14691d16	t	500	500	2025-07-08 00:45:07.723382+00
d539fcff-2061-4308-8130-ff9f5291f9a2	enterprise	706f7789-cb15-46a1-be6b-e6ca62fa4931	t	false	\N	2025-07-08 00:45:07.723382+00
48be7f09-5fb7-4152-8310-e51d76235ff0	enterprise	e1e93563-9c71-4b94-9131-69a4396348c7	t	false	\N	2025-07-08 00:45:07.723382+00
fdcbd316-6139-4fa7-bb0b-1e308bcbb059	enterprise	fb5e41a7-5930-4630-9e85-6ee5f11550ad	t	false	\N	2025-07-08 00:45:07.723382+00
8bc3d46c-4243-42b3-bcd8-f4230e120090	enterprise	e72ac267-55bc-45d0-8f8a-531379f1d0e9	t	false	\N	2025-07-08 00:45:07.723382+00
6d62ff06-2fd4-4d32-9b71-348357a68b0d	enterprise	e016c54c-dbb2-4b47-b42f-d27dbfd6da1b	t	false	\N	2025-07-08 00:45:07.723382+00
2ac23bf9-3d41-4ef1-b085-640cf6662e14	enterprise	f4a1e5cb-7ff2-4ec6-9933-263bee8221db	t	false	\N	2025-07-08 00:45:07.723382+00
e166d6db-fc66-4671-8695-2dcc1e8eac47	enterprise	32c95473-e891-4f44-a331-d6d7f0d4a547	t	false	\N	2025-07-08 00:45:07.723382+00
3ec49c5f-bbc1-43ae-971d-916a45d67942	enterprise	cdc6c5c3-36e1-4d00-8d1f-e6d2151650a8	t	false	\N	2025-07-08 00:45:07.723382+00
2c251058-d702-4331-ab6b-dc5a7beff329	enterprise	1a6a370b-69bf-447e-9acf-02b1bd08867b	t	false	\N	2025-07-08 00:45:07.723382+00
760bd480-9363-4e04-907d-d0a960de0874	enterprise	7a7c7b38-95e5-4c30-9fbd-cde69dcdff44	t	true	\N	2025-07-08 00:45:07.723382+00
1049c7bc-c72b-4710-8d78-4cffa143972d	enterprise	5376ba1c-efc0-4b15-bc1a-6bca62e5c981	t	"realtime"	\N	2025-07-08 00:45:07.723382+00
48fc5070-1975-4be1-8fac-47bd61bf6d6f	enterprise	42869034-7077-48da-9521-7dd6ffd1e2cb	t	1095	\N	2025-07-08 00:45:07.723382+00
\.


--
-- Data for Name: pos_mini_modular3_user_permission_overrides; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_user_permission_overrides (id, user_id, permission_id, is_granted, granted_by, reason, expires_at, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_user_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_user_profiles (id, business_id, full_name, phone, email, avatar_url, role, status, permissions, login_method, last_login_at, employee_id, hire_date, notes, created_at, updated_at) FROM stdin;
5f8d74cf-572a-4640-a565-34c5e1462f4e	6f699d8d-3a1d-4820-8d3f-a824608181ec	Demo Owner (Cym)	\N	cym_sunset@yahoo.com	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-10 19:47:25.443433+00	2025-07-10 19:47:25.443433+00
8740cb15-5bea-480d-b58b-2f9fd51c144e	6f699d8d-3a1d-4820-8d3f-a824608181ec	Demo Staff 1	\N	+84907131111@staff.pos.local	\N	seller	active	[]	email	\N	\N	\N	\N	2025-07-10 19:47:25.443433+00	2025-07-10 19:47:25.443433+00
f1de66c9-166a-464c-89aa-bd75e1095040	\N	Super Administrator	+84907136029	admin@giakiemso.com	\N	super_admin	active	[]	email	\N	\N	\N	\N	2025-07-02 02:16:30.46745+00	2025-07-08 07:51:08.498093+00
\.


--
-- Data for Name: pos_mini_modular3_user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_user_sessions (id, user_id, session_token, device_info, ip_address, user_agent, is_active, last_activity, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Name: pos_mini_modular3_product_categories category_name_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT category_name_business_unique UNIQUE (business_id, name);


--
-- Name: pos_mini_modular3_product_categories category_slug_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT category_slug_business_unique UNIQUE (business_id, slug);


--
-- Name: permissions permissions_permission_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_permission_key_key UNIQUE (permission_key);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_admin_sessions pos_mini_modular3_admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_admin_sessions
    ADD CONSTRAINT pos_mini_modular3_admin_sessions_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_business_features pos_mini_modular3_business_features_business_id_feature_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_features
    ADD CONSTRAINT pos_mini_modular3_business_features_business_id_feature_id_key UNIQUE (business_id, feature_id);


--
-- Name: pos_mini_modular3_business_features pos_mini_modular3_business_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_features
    ADD CONSTRAINT pos_mini_modular3_business_features_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_business_memberships pos_mini_modular3_business_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_memberships
    ADD CONSTRAINT pos_mini_modular3_business_memberships_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_business_type_category_templates pos_mini_modular3_business_type_category_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_type_category_templates
    ADD CONSTRAINT pos_mini_modular3_business_type_category_templates_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_enhanced_user_sessions pos_mini_modular3_enhanced_user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_enhanced_user_sessions
    ADD CONSTRAINT pos_mini_modular3_enhanced_user_sessions_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_enhanced_user_sessions pos_mini_modular3_enhanced_user_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_enhanced_user_sessions
    ADD CONSTRAINT pos_mini_modular3_enhanced_user_sessions_session_token_key UNIQUE (session_token);


--
-- Name: pos_mini_modular3_failed_login_attempts pos_mini_modular3_failed_login_attempts_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_failed_login_attempts
    ADD CONSTRAINT pos_mini_modular3_failed_login_attempts_identifier_key UNIQUE (identifier);


--
-- Name: pos_mini_modular3_failed_login_attempts pos_mini_modular3_failed_login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_failed_login_attempts
    ADD CONSTRAINT pos_mini_modular3_failed_login_attempts_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_feature_usage pos_mini_modular3_feature_usa_business_id_feature_id_usage__key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_feature_usage
    ADD CONSTRAINT pos_mini_modular3_feature_usa_business_id_feature_id_usage__key UNIQUE (business_id, feature_id, usage_date);


--
-- Name: pos_mini_modular3_feature_usage pos_mini_modular3_feature_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_feature_usage
    ADD CONSTRAINT pos_mini_modular3_feature_usage_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_features pos_mini_modular3_features_feature_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_features
    ADD CONSTRAINT pos_mini_modular3_features_feature_key_key UNIQUE (feature_key);


--
-- Name: pos_mini_modular3_features pos_mini_modular3_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_features
    ADD CONSTRAINT pos_mini_modular3_features_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_permissions pos_mini_modular3_permissions_permission_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_permissions
    ADD CONSTRAINT pos_mini_modular3_permissions_permission_key_key UNIQUE (permission_key);


--
-- Name: pos_mini_modular3_permissions pos_mini_modular3_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_permissions
    ADD CONSTRAINT pos_mini_modular3_permissions_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_product_categories pos_mini_modular3_product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT pos_mini_modular3_product_categories_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_product_images pos_mini_modular3_product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_images
    ADD CONSTRAINT pos_mini_modular3_product_images_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_product_inventory pos_mini_modular3_product_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_inventory
    ADD CONSTRAINT pos_mini_modular3_product_inventory_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_product_variants pos_mini_modular3_product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_variants
    ADD CONSTRAINT pos_mini_modular3_product_variants_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_business_id_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_business_id_sku_key UNIQUE (business_id, sku);


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_business_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_business_id_slug_key UNIQUE (business_id, slug);


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_role_permissions pos_mini_modular3_role_permis_subscription_tier_user_role_f_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permissions
    ADD CONSTRAINT pos_mini_modular3_role_permis_subscription_tier_user_role_f_key UNIQUE (subscription_tier, user_role, feature_name);


--
-- Name: pos_mini_modular3_role_permission_mappings pos_mini_modular3_role_permission_m_user_role_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permission_mappings
    ADD CONSTRAINT pos_mini_modular3_role_permission_m_user_role_permission_id_key UNIQUE (user_role, permission_id);


--
-- Name: pos_mini_modular3_role_permission_mappings pos_mini_modular3_role_permission_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permission_mappings
    ADD CONSTRAINT pos_mini_modular3_role_permission_mappings_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_role_permissions pos_mini_modular3_role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permissions
    ADD CONSTRAINT pos_mini_modular3_role_permissions_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_security_audit_logs pos_mini_modular3_security_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_security_audit_logs
    ADD CONSTRAINT pos_mini_modular3_security_audit_logs_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_session_activities pos_mini_modular3_session_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_session_activities
    ADD CONSTRAINT pos_mini_modular3_session_activities_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_tier_features pos_mini_modular3_tier_feature_subscription_tier_feature_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_tier_features
    ADD CONSTRAINT pos_mini_modular3_tier_feature_subscription_tier_feature_id_key UNIQUE (subscription_tier, feature_id);


--
-- Name: pos_mini_modular3_tier_features pos_mini_modular3_tier_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_tier_features
    ADD CONSTRAINT pos_mini_modular3_tier_features_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_user_permission_overrides pos_mini_modular3_user_permission_ove_user_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_permission_overrides
    ADD CONSTRAINT pos_mini_modular3_user_permission_ove_user_id_permission_id_key UNIQUE (user_id, permission_id);


--
-- Name: pos_mini_modular3_user_permission_overrides pos_mini_modular3_user_permission_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_permission_overrides
    ADD CONSTRAINT pos_mini_modular3_user_permission_overrides_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_user_sessions pos_mini_modular3_user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_sessions
    ADD CONSTRAINT pos_mini_modular3_user_sessions_pkey PRIMARY KEY (id);


--
-- Name: pos_mini_modular3_user_sessions pos_mini_modular3_user_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_sessions
    ADD CONSTRAINT pos_mini_modular3_user_sessions_session_token_key UNIQUE (session_token);


--
-- Name: pos_mini_modular3_products product_name_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT product_name_business_unique UNIQUE (business_id, name);


--
-- Name: pos_mini_modular3_products product_sku_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT product_sku_business_unique UNIQUE (business_id, sku);


--
-- Name: pos_mini_modular3_products product_slug_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT product_slug_business_unique UNIQUE (business_id, slug);


--
-- Name: pos_mini_modular3_business_type_category_templates template_category_business_type_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_type_category_templates
    ADD CONSTRAINT template_category_business_type_unique UNIQUE (business_type, category_name);


--
-- Name: pos_mini_modular3_business_memberships unique_user_business_membership; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_memberships
    ADD CONSTRAINT unique_user_business_membership UNIQUE (user_id, business_id);


--
-- Name: pos_mini_modular3_product_variants variant_sku_business_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_variants
    ADD CONSTRAINT variant_sku_business_unique UNIQUE (business_id, sku);


--
-- Name: pos_mini_modular3_product_variants variant_title_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_variants
    ADD CONSTRAINT variant_title_product_unique UNIQUE (product_id, title);


--
-- Name: idx_admin_sessions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_sessions_active ON public.pos_mini_modular3_admin_sessions USING btree (super_admin_id, is_active, target_business_id);


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
-- Name: idx_business_features_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_features_business_id ON public.pos_mini_modular3_business_features USING btree (business_id);


--
-- Name: idx_business_memberships_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_memberships_business_id ON public.pos_mini_modular3_business_memberships USING btree (business_id);


--
-- Name: idx_business_memberships_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_memberships_role ON public.pos_mini_modular3_business_memberships USING btree (role);


--
-- Name: idx_business_memberships_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_memberships_status ON public.pos_mini_modular3_business_memberships USING btree (status);


--
-- Name: idx_business_memberships_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_memberships_user_id ON public.pos_mini_modular3_business_memberships USING btree (user_id);


--
-- Name: idx_business_types_category_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_category_sort ON public.pos_mini_modular3_business_types USING btree (category, sort_order);


--
-- Name: idx_business_types_value_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_value_active ON public.pos_mini_modular3_business_types USING btree (value, is_active);


--
-- Name: idx_businesses_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_businesses_code ON public.pos_mini_modular3_businesses USING btree (code);


--
-- Name: idx_businesses_subscription_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_businesses_subscription_status ON public.pos_mini_modular3_businesses USING btree (subscription_status);


--
-- Name: idx_businesses_subscription_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_businesses_subscription_tier ON public.pos_mini_modular3_businesses USING btree (subscription_tier);


--
-- Name: idx_categories_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_active ON public.pos_mini_modular3_product_categories USING btree (business_id, is_active);


--
-- Name: idx_categories_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_business_id ON public.pos_mini_modular3_product_categories USING btree (business_id);


--
-- Name: idx_categories_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_parent_id ON public.pos_mini_modular3_product_categories USING btree (parent_id);


--
-- Name: idx_category_templates_business_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_category_templates_business_type ON public.pos_mini_modular3_business_type_category_templates USING btree (business_type);


--
-- Name: idx_enhanced_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enhanced_sessions_expires ON public.pos_mini_modular3_enhanced_user_sessions USING btree (expires_at);


--
-- Name: idx_enhanced_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enhanced_sessions_token ON public.pos_mini_modular3_enhanced_user_sessions USING btree (session_token);


--
-- Name: idx_enhanced_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enhanced_sessions_user_id ON public.pos_mini_modular3_enhanced_user_sessions USING btree (user_id);


--
-- Name: idx_failed_login_attempts_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_failed_login_attempts_identifier ON public.pos_mini_modular3_failed_login_attempts USING btree (identifier);


--
-- Name: idx_failed_login_attempts_lock_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_failed_login_attempts_lock_expires ON public.pos_mini_modular3_failed_login_attempts USING btree (lock_expires_at) WHERE (lock_expires_at IS NOT NULL);


--
-- Name: idx_feature_usage_business_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feature_usage_business_date ON public.pos_mini_modular3_feature_usage USING btree (business_id, usage_date);


--
-- Name: idx_images_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_images_business_id ON public.pos_mini_modular3_product_images USING btree (business_id);


--
-- Name: idx_images_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_images_primary ON public.pos_mini_modular3_product_images USING btree (product_id, is_primary) WHERE (is_primary = true);


--
-- Name: idx_images_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_images_product_id ON public.pos_mini_modular3_product_images USING btree (product_id);


--
-- Name: idx_images_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_images_variant_id ON public.pos_mini_modular3_product_images USING btree (variant_id);


--
-- Name: idx_inventory_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_business_id ON public.pos_mini_modular3_product_inventory USING btree (business_id);


--
-- Name: idx_inventory_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_created_at ON public.pos_mini_modular3_product_inventory USING btree (product_id, created_at DESC);


--
-- Name: idx_inventory_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_product_id ON public.pos_mini_modular3_product_inventory USING btree (product_id);


--
-- Name: idx_inventory_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_variant_id ON public.pos_mini_modular3_product_inventory USING btree (variant_id);


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
-- Name: idx_pos_mini_modular3_enhanced_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_enhanced_sessions_expires ON public.pos_mini_modular3_enhanced_user_sessions USING btree (expires_at);


--
-- Name: idx_pos_mini_modular3_enhanced_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_enhanced_sessions_token ON public.pos_mini_modular3_enhanced_user_sessions USING btree (session_token);


--
-- Name: idx_pos_mini_modular3_enhanced_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_enhanced_sessions_user_id ON public.pos_mini_modular3_enhanced_user_sessions USING btree (user_id);


--
-- Name: idx_pos_mini_modular3_failed_login_attempts_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_failed_login_attempts_identifier ON public.pos_mini_modular3_failed_login_attempts USING btree (identifier);


--
-- Name: idx_pos_mini_modular3_failed_login_attempts_lock_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_failed_login_attempts_lock_expires ON public.pos_mini_modular3_failed_login_attempts USING btree (lock_expires_at) WHERE (lock_expires_at IS NOT NULL);


--
-- Name: idx_pos_mini_modular3_security_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_security_audit_logs_created_at ON public.pos_mini_modular3_security_audit_logs USING btree (created_at);


--
-- Name: idx_pos_mini_modular3_security_audit_logs_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_security_audit_logs_event_type ON public.pos_mini_modular3_security_audit_logs USING btree (event_type);


--
-- Name: idx_pos_mini_modular3_security_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_mini_modular3_security_audit_logs_user_id ON public.pos_mini_modular3_security_audit_logs USING btree (user_id);


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
-- Name: idx_product_categories_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_categories_active ON public.pos_mini_modular3_product_categories USING btree (business_id, is_active);


--
-- Name: idx_product_categories_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_categories_business_id ON public.pos_mini_modular3_product_categories USING btree (business_id);


--
-- Name: idx_product_categories_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_categories_parent_id ON public.pos_mini_modular3_product_categories USING btree (parent_id);


--
-- Name: idx_product_categories_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_categories_slug ON public.pos_mini_modular3_product_categories USING btree (business_id, slug);


--
-- Name: idx_products_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_active ON public.pos_mini_modular3_products USING btree (business_id, is_active);


--
-- Name: idx_products_business_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_business_category ON public.pos_mini_modular3_products USING btree (business_id, category_id);


--
-- Name: idx_products_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_business_id ON public.pos_mini_modular3_products USING btree (business_id);


--
-- Name: idx_products_business_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_business_status ON public.pos_mini_modular3_products USING btree (business_id, status);


--
-- Name: idx_products_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_category_id ON public.pos_mini_modular3_products USING btree (category_id);


--
-- Name: idx_products_featured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_featured ON public.pos_mini_modular3_products USING btree (business_id, is_featured) WHERE (is_featured = true);


--
-- Name: idx_products_name_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_name_search ON public.pos_mini_modular3_products USING gin (to_tsvector('english'::regconfig, name));


--
-- Name: idx_products_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_sku ON public.pos_mini_modular3_products USING btree (business_id, sku);


--
-- Name: idx_products_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_slug ON public.pos_mini_modular3_products USING btree (business_id, slug);


--
-- Name: idx_products_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_status ON public.pos_mini_modular3_products USING btree (business_id, status);


--
-- Name: idx_products_stock_low; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_stock_low ON public.pos_mini_modular3_products USING btree (business_id, current_stock, min_stock_level) WHERE (track_stock = true);


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
-- Name: idx_role_permissions_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_lookup ON public.pos_mini_modular3_role_permissions USING btree (subscription_tier, user_role, feature_name);


--
-- Name: idx_session_activities_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_activities_session_id ON public.pos_mini_modular3_session_activities USING btree (session_id);


--
-- Name: idx_tier_features_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tier_features_tier ON public.pos_mini_modular3_tier_features USING btree (subscription_tier);


--
-- Name: idx_user_profiles_auth_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_auth_user_id ON public.pos_mini_modular3_user_profiles USING btree (id);


--
-- Name: idx_user_profiles_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_business_id ON public.pos_mini_modular3_user_profiles USING btree (business_id);


--
-- Name: idx_user_profiles_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_email ON public.pos_mini_modular3_user_profiles USING btree (email);


--
-- Name: idx_user_profiles_id_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_id_active ON public.pos_mini_modular3_user_profiles USING btree (id) WHERE (status = 'active'::text);


--
-- Name: idx_user_profiles_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_profiles_role ON public.pos_mini_modular3_user_profiles USING btree (role);


--
-- Name: idx_user_sessions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_active ON public.pos_mini_modular3_user_sessions USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_user_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_expires ON public.pos_mini_modular3_user_sessions USING btree (expires_at);


--
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user_id ON public.pos_mini_modular3_user_sessions USING btree (user_id);


--
-- Name: idx_variants_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_active ON public.pos_mini_modular3_product_variants USING btree (product_id, is_active);


--
-- Name: idx_variants_business_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_business_id ON public.pos_mini_modular3_product_variants USING btree (business_id);


--
-- Name: idx_variants_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_product_id ON public.pos_mini_modular3_product_variants USING btree (product_id);


--
-- Name: idx_variants_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_sku ON public.pos_mini_modular3_product_variants USING btree (business_id, sku);


--
-- Name: pos_mini_modular3_product_categories category_auto_slug_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER category_auto_slug_trigger BEFORE INSERT OR UPDATE ON public.pos_mini_modular3_product_categories FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_category_auto_slug();


--
-- Name: pos_mini_modular3_products product_auto_slug_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER product_auto_slug_trigger BEFORE INSERT OR UPDATE ON public.pos_mini_modular3_products FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_product_auto_slug();


--
-- Name: pos_mini_modular3_business_features trigger_update_business_feature_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_business_feature_updated_at BEFORE UPDATE ON public.pos_mini_modular3_business_features FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_feature_updated_at();


--
-- Name: pos_mini_modular3_business_memberships trigger_update_business_membership_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_business_membership_updated_at BEFORE UPDATE ON public.pos_mini_modular3_business_memberships FOR EACH ROW EXECUTE FUNCTION public.update_business_membership_updated_at();


--
-- Name: pos_mini_modular3_features trigger_update_feature_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_feature_updated_at BEFORE UPDATE ON public.pos_mini_modular3_features FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_feature_updated_at();


--
-- Name: pos_mini_modular3_products trigger_update_product_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_product_timestamp BEFORE UPDATE ON public.pos_mini_modular3_products FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_product_timestamp();


--
-- Name: pos_mini_modular3_user_sessions trigger_update_session_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_session_updated_at BEFORE UPDATE ON public.pos_mini_modular3_user_sessions FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_session_updated_at();


--
-- Name: pos_mini_modular3_products update_category_product_count_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_category_product_count_trigger AFTER INSERT OR DELETE OR UPDATE ON public.pos_mini_modular3_products FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_update_category_product_count();


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
-- Name: pos_mini_modular3_product_variants variant_inventory_cache_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER variant_inventory_cache_trigger AFTER INSERT OR DELETE OR UPDATE ON public.pos_mini_modular3_product_variants FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_variant_inventory_update();


--
-- Name: pos_mini_modular3_business_memberships fk_business_memberships_business_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_memberships
    ADD CONSTRAINT fk_business_memberships_business_id FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_business_memberships fk_business_memberships_invited_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_memberships
    ADD CONSTRAINT fk_business_memberships_invited_by FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: pos_mini_modular3_business_memberships fk_business_memberships_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_memberships
    ADD CONSTRAINT fk_business_memberships_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_businesses fk_business_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_businesses
    ADD CONSTRAINT fk_business_type FOREIGN KEY (business_type) REFERENCES public.pos_mini_modular3_business_types(value) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: pos_mini_modular3_admin_sessions pos_mini_modular3_admin_sessions_super_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_admin_sessions
    ADD CONSTRAINT pos_mini_modular3_admin_sessions_super_admin_id_fkey FOREIGN KEY (super_admin_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_admin_sessions pos_mini_modular3_admin_sessions_target_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_admin_sessions
    ADD CONSTRAINT pos_mini_modular3_admin_sessions_target_business_id_fkey FOREIGN KEY (target_business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


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
-- Name: pos_mini_modular3_business_features pos_mini_modular3_business_features_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_features
    ADD CONSTRAINT pos_mini_modular3_business_features_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_business_features pos_mini_modular3_business_features_enabled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_features
    ADD CONSTRAINT pos_mini_modular3_business_features_enabled_by_fkey FOREIGN KEY (enabled_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_business_features pos_mini_modular3_business_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_features
    ADD CONSTRAINT pos_mini_modular3_business_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.pos_mini_modular3_features(id) ON DELETE CASCADE;


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
-- Name: pos_mini_modular3_business_type_category_templates pos_mini_modular3_business_type_category_tem_business_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_business_type_category_templates
    ADD CONSTRAINT pos_mini_modular3_business_type_category_tem_business_type_fkey FOREIGN KEY (business_type) REFERENCES public.pos_mini_modular3_business_types(value) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_feature_usage pos_mini_modular3_feature_usage_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_feature_usage
    ADD CONSTRAINT pos_mini_modular3_feature_usage_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_feature_usage pos_mini_modular3_feature_usage_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_feature_usage
    ADD CONSTRAINT pos_mini_modular3_feature_usage_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.pos_mini_modular3_features(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_feature_usage pos_mini_modular3_feature_usage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_feature_usage
    ADD CONSTRAINT pos_mini_modular3_feature_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_product_categories pos_mini_modular3_product_categories_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT pos_mini_modular3_product_categories_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_categories pos_mini_modular3_product_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT pos_mini_modular3_product_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_product_categories pos_mini_modular3_product_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT pos_mini_modular3_product_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.pos_mini_modular3_product_categories(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_categories pos_mini_modular3_product_categories_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_categories
    ADD CONSTRAINT pos_mini_modular3_product_categories_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_product_images pos_mini_modular3_product_images_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_images
    ADD CONSTRAINT pos_mini_modular3_product_images_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_images pos_mini_modular3_product_images_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_images
    ADD CONSTRAINT pos_mini_modular3_product_images_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.pos_mini_modular3_user_profiles(id);


--
-- Name: pos_mini_modular3_product_inventory pos_mini_modular3_product_inventory_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_inventory
    ADD CONSTRAINT pos_mini_modular3_product_inventory_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_inventory pos_mini_modular3_product_inventory_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_inventory
    ADD CONSTRAINT pos_mini_modular3_product_inventory_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.pos_mini_modular3_user_profiles(id);


--
-- Name: pos_mini_modular3_product_inventory pos_mini_modular3_product_inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_inventory
    ADD CONSTRAINT pos_mini_modular3_product_inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.pos_mini_modular3_products(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_inventory pos_mini_modular3_product_inventory_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_inventory
    ADD CONSTRAINT pos_mini_modular3_product_inventory_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.pos_mini_modular3_product_variants(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_variants pos_mini_modular3_product_variants_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_variants
    ADD CONSTRAINT pos_mini_modular3_product_variants_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_product_variants pos_mini_modular3_product_variants_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_product_variants
    ADD CONSTRAINT pos_mini_modular3_product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.pos_mini_modular3_products(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.pos_mini_modular3_businesses(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.pos_mini_modular3_product_categories(id) ON DELETE SET NULL;


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_products pos_mini_modular3_products_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_products
    ADD CONSTRAINT pos_mini_modular3_products_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: pos_mini_modular3_restore_history pos_mini_modular3_restore_history_backup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_restore_history
    ADD CONSTRAINT pos_mini_modular3_restore_history_backup_id_fkey FOREIGN KEY (backup_id) REFERENCES public.pos_mini_modular3_backup_metadata(id);


--
-- Name: pos_mini_modular3_role_permission_mappings pos_mini_modular3_role_permission_mappings_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permission_mappings
    ADD CONSTRAINT pos_mini_modular3_role_permission_mappings_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.pos_mini_modular3_permissions(id);


--
-- Name: pos_mini_modular3_session_activities pos_mini_modular3_session_activities_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_session_activities
    ADD CONSTRAINT pos_mini_modular3_session_activities_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.pos_mini_modular3_user_sessions(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_tier_features pos_mini_modular3_tier_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_tier_features
    ADD CONSTRAINT pos_mini_modular3_tier_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.pos_mini_modular3_features(id) ON DELETE CASCADE;


--
-- Name: pos_mini_modular3_user_permission_overrides pos_mini_modular3_user_permission_overrides_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_permission_overrides
    ADD CONSTRAINT pos_mini_modular3_user_permission_overrides_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.pos_mini_modular3_permissions(id);


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
-- Name: pos_mini_modular3_user_sessions pos_mini_modular3_user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_user_sessions
    ADD CONSTRAINT pos_mini_modular3_user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


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
-- Name: pos_mini_modular3_admin_sessions Business owners can view sessions targeting their business; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Business owners can view sessions targeting their business" ON public.pos_mini_modular3_admin_sessions FOR SELECT TO authenticated USING ((target_business_id IN ( SELECT pos_mini_modular3_user_profiles.business_id
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'business_owner'::text)))));


--
-- Name: pos_mini_modular3_admin_sessions Super admins can manage admin sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Super admins can manage admin sessions" ON public.pos_mini_modular3_admin_sessions TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text)))));


--
-- Name: pos_mini_modular3_business_features business_features_business_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY business_features_business_isolation ON public.pos_mini_modular3_business_features TO authenticated USING (((business_id = public.pos_mini_modular3_current_user_business_id()) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


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
-- Name: pos_mini_modular3_product_categories categories_business_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_business_isolation ON public.pos_mini_modular3_product_categories TO authenticated USING (((business_id = public.pos_mini_modular3_current_user_business_id()) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


--
-- Name: pos_mini_modular3_feature_usage feature_usage_business_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY feature_usage_business_isolation ON public.pos_mini_modular3_feature_usage TO authenticated USING (((business_id = public.pos_mini_modular3_current_user_business_id()) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


--
-- Name: pos_mini_modular3_features features_readable_by_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY features_readable_by_all ON public.pos_mini_modular3_features FOR SELECT TO authenticated USING (true);


--
-- Name: pos_mini_modular3_product_images images_business_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY images_business_isolation ON public.pos_mini_modular3_product_images TO authenticated USING (((business_id = public.pos_mini_modular3_current_user_business_id()) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


--
-- Name: pos_mini_modular3_business_invitations invited_users_see_own_invitations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invited_users_see_own_invitations ON public.pos_mini_modular3_business_invitations FOR SELECT TO authenticated USING ((email IN ( SELECT users.email
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: pos_mini_modular3_admin_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_admin_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_business_features; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_features ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_business_invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_business_memberships; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_memberships ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_business_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_business_types ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_businesses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_businesses ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_feature_usage; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_feature_usage ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_features; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_features ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_product_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_product_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_product_images; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_product_images ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_products ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_session_activities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_session_activities ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_subscription_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_subscription_history ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_subscription_plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_subscription_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_tier_features; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_tier_features ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_user_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_user_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_user_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_user_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_mini_modular3_product_images product_images_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY product_images_access ON public.pos_mini_modular3_product_images TO authenticated USING (((product_id IN ( SELECT p.id
   FROM public.pos_mini_modular3_products p
  WHERE (p.business_id = public.pos_mini_modular3_current_user_business_id()))) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


--
-- Name: pos_mini_modular3_products products_business_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY products_business_isolation ON public.pos_mini_modular3_products TO authenticated USING (((business_id = public.pos_mini_modular3_current_user_business_id()) OR (EXISTS ( SELECT 1
   FROM public.pos_mini_modular3_user_profiles
  WHERE ((pos_mini_modular3_user_profiles.id = auth.uid()) AND (pos_mini_modular3_user_profiles.role = 'super_admin'::text))))));


--
-- Name: pos_mini_modular3_business_memberships service_role_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_access ON public.pos_mini_modular3_business_memberships USING ((current_setting('role'::text) = 'service_role'::text));


--
-- Name: pos_mini_modular3_session_activities session_activities_own_user_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_activities_own_user_only ON public.pos_mini_modular3_session_activities TO authenticated USING ((session_id IN ( SELECT pos_mini_modular3_user_sessions.id
   FROM public.pos_mini_modular3_user_sessions
  WHERE (pos_mini_modular3_user_sessions.user_id = auth.uid()))));


--
-- Name: pos_mini_modular3_user_sessions sessions_own_user_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sessions_own_user_only ON public.pos_mini_modular3_user_sessions TO authenticated USING ((user_id = auth.uid()));


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
-- Name: pos_mini_modular3_tier_features tier_features_readable_by_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tier_features_readable_by_all ON public.pos_mini_modular3_tier_features FOR SELECT TO authenticated USING (true);


--
-- Name: pos_mini_modular3_user_profiles user_own_access_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_own_access_only ON public.pos_mini_modular3_user_profiles TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


--
-- Name: pos_mini_modular3_user_profiles users_own_profile_safe; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_own_profile_safe ON public.pos_mini_modular3_user_profiles TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


--
-- Name: pos_mini_modular3_business_memberships users_view_own_memberships; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_view_own_memberships ON public.pos_mini_modular3_business_memberships FOR SELECT USING ((auth.uid() = user_id));


--
-- PostgreSQL database dump complete
--

