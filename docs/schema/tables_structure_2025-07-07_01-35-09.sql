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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


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
    features_enabled jsonb DEFAULT '{}'::jsonb,
    usage_stats jsonb DEFAULT '{}'::jsonb,
    last_billing_date timestamp with time zone,
    next_billing_date timestamp with time zone,
    CONSTRAINT business_max_products_positive CHECK ((max_products > 0)),
    CONSTRAINT business_max_users_positive CHECK ((max_users > 0)),
    CONSTRAINT business_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['trial'::text, 'active'::text, 'suspended'::text, 'expired'::text, 'cancelled'::text]))),
    CONSTRAINT business_subscription_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text]))),
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
    CONSTRAINT role_permissions_role_check CHECK ((user_role = ANY (ARRAY['business_owner'::text, 'manager'::text, 'seller'::text, 'accountant'::text, 'super_admin'::text]))),
    CONSTRAINT role_permissions_tier_check CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'basic'::text, 'premium'::text])))
);


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
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


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
-- Name: pos_mini_modular3_role_permissions pos_mini_modular3_role_permis_subscription_tier_user_role_f_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permissions
    ADD CONSTRAINT pos_mini_modular3_role_permis_subscription_tier_user_role_f_key UNIQUE (subscription_tier, user_role, feature_name);


--
-- Name: pos_mini_modular3_role_permissions pos_mini_modular3_role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_mini_modular3_role_permissions
    ADD CONSTRAINT pos_mini_modular3_role_permissions_pkey PRIMARY KEY (id);


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
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


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
-- Name: idx_business_types_category_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_category_sort ON public.pos_mini_modular3_business_types USING btree (category, sort_order);


--
-- Name: idx_business_types_value_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_types_value_active ON public.pos_mini_modular3_business_types USING btree (value, is_active);


--
-- Name: idx_businesses_subscription_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_businesses_subscription_status ON public.pos_mini_modular3_businesses USING btree (subscription_status);


--
-- Name: idx_businesses_subscription_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_businesses_subscription_tier ON public.pos_mini_modular3_businesses USING btree (subscription_tier);


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
-- Name: idx_role_permissions_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_lookup ON public.pos_mini_modular3_role_permissions USING btree (subscription_tier, user_role, feature_name);


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.pos_mini_modular3_handle_new_user();


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
-- Name: pos_mini_modular3_role_permissions update_role_permissions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_role_permissions_updated_at BEFORE UPDATE ON public.pos_mini_modular3_role_permissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


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
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

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
-- Name: pos_mini_modular3_admin_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_mini_modular3_admin_sessions ENABLE ROW LEVEL SECURITY;

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

