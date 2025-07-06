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
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '8740cb15-5bea-480d-b58b-2f9fd51c144e', 'authenticated', 'authenticated', '+84907131111@staff.pos.local', '$2a$06$4Rz9QG7LE6XExIGTMX9dwumRLztCiPJ5rq8q3TIjJ2YIDSgyspRxS', '2025-07-01 10:43:03.150311+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{}', false, '2025-07-01 10:43:03.150311+00', '2025-07-01 10:43:03.150311+00', '+84907131111', '2025-07-01 10:43:03.150311+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '5f8d74cf-572a-4640-a565-34c5e1462f4e', 'authenticated', 'authenticated', 'cym_sunset@yahoo.com', '$2a$10$l1ahnejet3PJUhiJi1cms.B2csLc9S3.Yhozu81/T/ynWz6x/YQr6', '2025-07-01 09:11:33.876679+00', NULL, '', '2025-07-01 09:11:07.107667+00', '', NULL, '', '', NULL, '2025-07-01 10:45:08.605363+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "5f8d74cf-572a-4640-a565-34c5e1462f4e", "email": "cym_sunset@yahoo.com", "phone": "0907136029", "address": "D2/062A, Nam Son, Quang Trung, Thong Nhat", "taxCode": "3604005775", "fullName": "Phan Thiên Hào", "businessName": "An Nhiên Farm", "businessType": "cafe", "email_verified": true, "phone_verified": false}', NULL, '2025-07-01 09:11:07.073442+00', '2025-07-01 10:45:08.613579+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', 'c8c6a529-e57c-4dbf-900f-c26dd4815195', 'authenticated', 'authenticated', '+84901234567@staff.pos.local', '$2a$06$j8e0EwBGC.z7S7cRu9KDJOawWWcK62RMbIRFoMjgQ9DhR4a8Exe1e', '2025-06-30 23:54:50.592949+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{}', false, '2025-06-30 23:54:50.592949+00', '2025-06-30 23:54:50.592949+00', '+84901234567', '2025-06-30 23:54:50.592949+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '8388a0e3-0a1a-4ce2-9c54-257994d44616', 'authenticated', 'authenticated', '+84909582083@staff.pos.local', '$2a$06$055Vl2pUmCyyvCQB8obVU.ZjsWRbhY/J13Ssjz/Xr5RSrTcj1d/YS', '2025-07-01 00:06:56.999574+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{}', false, '2025-07-01 00:06:56.999574+00', '2025-07-01 00:06:56.999574+00', '+84909582083', '2025-07-01 00:06:56.999574+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', 'bba27899-25c8-4d5b-ba81-a0201f98bd00', 'authenticated', 'authenticated', '+84907136029@staff.pos.local', '$2a$06$Mg7gL8a5nk5ok/E3E0.CaObzsoHMqPkEFB4gcub0cjVyXwJJGWi2W', '2025-07-01 00:09:24.007284+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{}', false, '2025-07-01 00:09:24.007284+00', '2025-07-01 00:09:24.007284+00', '+84907136029', '2025-07-01 00:09:24.007284+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', 'b5ca076a-7b1f-4d4e-808d-0610f71288a8', 'authenticated', 'authenticated', '+84922388399@staff.pos.local', '$2a$06$cQXrBqc.jQeIUsIa77nU9eft0D3g0YdhY0I29qoaKJ1qtQLY2gSS.', '2025-07-01 00:59:06.756329+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{}', false, '2025-07-01 00:59:06.756329+00', '2025-07-01 00:59:06.756329+00', '+84922388399', '2025-07-01 00:59:06.756329+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES (NULL, '8c3b94aa-68b1-47db-9029-07be27d3b917', NULL, NULL, 'test.direct@rpc.test', '$2a$06$N6Uk6qpqut6jYt.jGz1auOFk/rJCfv5jFfjxlfHetNTZwlKT6MtUW', '2025-07-03 13:28:51.257721+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{"full_name": "Test Direct Owner"}', NULL, '2025-07-03 13:28:51.257721+00', '2025-07-03 13:28:51.257721+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES (NULL, '2706a795-f2a4-46f6-8030-3553a8a1ecb0', NULL, NULL, 'test.direct2@rpc.test', '$2a$06$wEf4Evk4QMjDHDPNMTkt9OkTSzM9VkLRYt9sh6iRuTSXZIlcVIq0u', '2025-07-03 13:28:51.487484+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{"full_name": "Test Direct Owner 2"}', NULL, '2025-07-03 13:28:51.487484+00', '2025-07-03 13:28:51.487484+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '90437fcb-0a83-44b7-ab05-322af922b451', 'authenticated', 'authenticated', 'bidathienlong01@gmail.com', '$2a$10$wTPSitpXOKVHVSaR6/ohCODHENGpqSxzQRHlpMpN2Wm0JfCegaVDm', '2025-07-02 19:43:50.594085+00', NULL, '', '2025-07-02 19:30:55.093304+00', '', NULL, '', '', NULL, '2025-07-02 19:44:04.468565+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "90437fcb-0a83-44b7-ab05-322af922b451", "email": "bidathienlong01@gmail.com", "phone": "0909564874", "address": "54 ap Gia Tân 2", "taxCode": "987026351478", "fullName": "Phan Thiên Long", "businessName": "Nhà Hàn Hoa Viên 79", "businessType": "fashion", "email_verified": true, "phone_verified": false}', NULL, '2025-07-02 19:30:55.052042+00', '2025-07-02 19:44:04.481823+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '9c9bc32f-6b7e-4239-857a-83d9b8b16ce7', 'authenticated', 'authenticated', 'yenwinny83@gmail.com', '$2a$10$C1lMtbgf/1EKPE7.vRGstOWpJlYGUiT1tx3/oNw86Xdbaxv8ObBbu', '2025-07-01 12:00:03.406578+00', NULL, '', '2025-07-01 11:59:54.348181+00', '', NULL, '', '', NULL, '2025-07-02 01:59:50.639001+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "9c9bc32f-6b7e-4239-857a-83d9b8b16ce7", "email": "yenwinny83@gmail.com", "phone": "0909582083", "address": "145 Cạnh Sacombank Gia Yên", "taxCode": "987654456", "fullName": "Mẹ Yến", "businessName": "Của Hàng Rau Sạch Phi Yến", "businessType": "food_service", "email_verified": true, "phone_verified": false}', NULL, '2025-07-01 11:59:54.332309+00', '2025-07-02 01:59:50.652378+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES (NULL, '3a799c65-8c58-429c-9e48-4d74b236ab97', NULL, NULL, NULL, '$2a$06$aaId.rrWcLosmO4XBH7zweXRhrMANl.7tLRnFS2DZ6sgonolwND2S', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{"full_name": "Nguyên Ly"}', NULL, '2025-07-03 13:38:21.323452+00', '2025-07-03 13:38:21.323452+00', '+84909123456', '2025-07-03 13:38:21.323452+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES (NULL, '9d40bf3c-e5a3-44c2-96c7-4c36a479e668', NULL, NULL, NULL, '$2a$06$byCSpwUiKPtJza78STb5HeRghynJ3dfXPCTA18Z1C6S1ozcnSVZBW', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "phone", "providers": ["phone"]}', '{"full_name": "Nguyễn Huy"}', NULL, '2025-07-03 13:39:20.303084+00', '2025-07-03 13:39:20.303084+00', '+84901456789', '2025-07-03 13:39:20.303084+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', 'f1de66c9-166a-464c-89aa-bd75e1095040', 'authenticated', 'authenticated', 'admin@giakiemso.com', '$2a$06$GVkqtUduJGusGD1zqEbrueKSzbDjbaqedwSmV4ilF1TsJqLBOUFpm', '2025-07-02 02:16:30.46745+00', NULL, '', '2025-07-02 02:16:30.46745+00', '', NULL, '', '', NULL, '2025-07-05 13:44:03.613575+00', '{"provider": "email", "providers": ["email"]}', '{"full_name": "Super Administrator"}', false, '2025-07-02 02:16:30.46745+00', '2025-07-05 13:44:03.616122+00', '0907136029', '2025-07-02 02:16:30.46745+00', '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users VALUES ('00000000-0000-0000-0000-000000000000', '550ce2c2-2d18-4a75-8ece-0c2c8f4dadad', 'authenticated', 'authenticated', 'ericphan28@gmail.com', '$2a$10$XeN2AYqNigpuM8vleGrlueHzo.Ck7waUtKgLmKP7s02jHgh2MRA.m', '2025-06-30 21:45:29.779993+00', NULL, '', '2025-06-30 21:42:37.344249+00', '', NULL, '', '', NULL, '2025-07-05 13:47:19.143779+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "550ce2c2-2d18-4a75-8ece-0c2c8f4dadad", "email": "ericphan28@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2025-06-30 21:42:37.333746+00', '2025-07-05 13:47:19.147253+00', NULL, NULL, '', '', NULL, DEFAULT, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: pos_mini_modular3_backup_metadata; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('1ep6obol1h1mco943i0', 'pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc', 'data', 6984, 'e2f3e30cfb0548453783adff2c8385c314bc210f9af4189ac2d3e5e7fd4dc42f', '2025-07-04 03:24:54.072+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-data-2025-07-04-03-24-54-1ep6obol.sql.gz.enc', '2025-08-03 03:24:55.997+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('15v2kx2zp3ymcoxduiq', 'pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc', 'data', 7860, '2f34b42804472f1aa370c281e8004f9b64283ca4a3feab15dc5ced6dd52ef654', '2025-07-04 14:44:19.778+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-data-2025-07-04-14-44-19-15v2kx2z.sql.gz.enc', '2025-08-03 14:44:21.28+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('0akl4fn6laafmcotdaeb', 'pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc', 'data', 7299, '892d2e05d1968b295633d099c0a91b92d343ddc1f742c46dedf4286820bc0402', '2025-07-04 12:51:55.235+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-data-2025-07-04-12-51-55-0akl4fn6.sql.gz.enc', '2025-08-03 12:51:57.487+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('aiaawarjb1mco62qfu', 'pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc', 'data', 6612, '34992f4a7ce8e0bddf4d7791a4d61c6b9b8bcb19d0b5c8348719cac6c3dea508', '2025-07-04 01:59:51.642+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-data-2025-07-04-01-59-51-aiaawarj.sql.gz.enc', '2025-08-03 01:59:53.308+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('qsw626zysbpmco5tkrn', 'pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc', 'data', 6199, '9d87b9fe7f1f73a0ed69962e927d5209c7e0b0792cfdcdf030672d11c0be4423', '2025-07-04 01:52:44.387+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-data-2025-07-04-01-52-44-qsw626zy.sql.gz.enc', '2025-08-03 01:52:45.827+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('n7tjq9mkd3mcpg7cxv', 'pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc', 'full', 8630, '66770dde62b33761d44fa50dc7d2c6f52a5315f69b91c2de02d34d6103910bb7', '2025-07-04 23:31:09.763+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-full-2025-07-04-23-31-09-n7tjq9mk.sql.gz.enc', '2025-08-03 23:31:12.213+00', 'completed', NULL, 'system');
INSERT INTO public.pos_mini_modular3_backup_metadata VALUES ('aey5miijilmcq8vofz', 'pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc', 'full', 8598, 'd703319c969a7e115ddf6359bb3bcaca56272e2d5846c90916bedbdc0f5ac2ee', '2025-07-05 12:53:53.663+00', 'Unknown', '["pos_mini_modular3_backup_downloads", "pos_mini_modular3_backup_metadata", "pos_mini_modular3_backup_notifications", "pos_mini_modular3_backup_schedules", "pos_mini_modular3_business_invitations", "pos_mini_modular3_business_types", "pos_mini_modular3_businesses", "pos_mini_modular3_restore_history", "pos_mini_modular3_restore_points", "pos_mini_modular3_subscription_history", "pos_mini_modular3_subscription_plans", "pos_mini_modular3_user_profiles"]', true, true, 'pos-mini-full-2025-07-05-12-53-53-aey5miij.sql.gz.enc', '2025-08-04 12:53:55.926+00', 'completed', NULL, 'system');


--
-- Data for Name: pos_mini_modular3_backup_downloads; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: pos_mini_modular3_backup_schedules; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_backup_schedules VALUES ('8bad2bc1-a479-48c1-a58c-6424e34e58ea', 'Daily Incremental Backup', 'incremental', '0 2 * * *', true, 'gzip', true, 30, NULL, '2025-07-04 15:50:02.923339+00', 0, NULL, 'system', '2025-07-03 15:50:02.923339+00', '2025-07-04 22:53:45.51178+00');
INSERT INTO public.pos_mini_modular3_backup_schedules VALUES ('f46e39c3-5a40-48f7-984a-27cd5704fb09', 'Weekly Full Backup', 'full', '0 3 * * 0', true, 'gzip', true, 90, NULL, '2025-07-10 15:50:02.923339+00', 0, NULL, 'system', '2025-07-03 15:50:02.923339+00', '2025-07-04 22:53:45.51178+00');


--
-- Data for Name: pos_mini_modular3_backup_notifications; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: pos_mini_modular3_business_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_business_types VALUES ('1dc28a52-de30-4c51-82e5-2c54a33fbb5c', 'retail', '🏪 Bán lẻ', 'Cửa hàng bán lẻ, siêu thị mini, tạp hóa', '🏪', 'retail', true, 10, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('380698d9-442e-4ead-a777-46b638ea641f', 'wholesale', '📦 Bán sỉ', 'Bán sỉ, phân phối hàng hóa', '📦', 'retail', true, 20, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('b48d76f0-b535-466c-861b-b6304ed28d80', 'fashion', '👗 Thời trang', 'Quần áo, giày dép, phụ kiện thời trang', '👗', 'retail', true, 30, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('abe66183-1d93-453f-8ddf-bf3961b9f254', 'electronics', '📱 Điện tử', 'Điện thoại, máy tính, thiết bị điện tử', '📱', 'retail', true, 40, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('a09e0ef4-68cd-4306-aaaa-e3894bf34ac4', 'restaurant', '🍽️ Nhà hàng', 'Nhà hàng, quán ăn, fast food', '🍽️', 'food', true, 110, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('0a631496-d43b-4593-9997-11a76457c1d1', 'cafe', '☕ Quán cà phê', 'Cà phê, trà sữa, đồ uống', '☕', 'food', true, 120, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('7f6a0248-48d4-42bf-b69d-b06ae8a78d08', 'food_service', '🍱 Dịch vụ ăn uống', 'Catering, giao đồ ăn, suất ăn công nghiệp', '🍱', 'food', true, 130, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('24cfb1e4-3243-4f2b-a49d-ec775b4644e6', 'beauty', '💄 Làm đẹp', 'Mỹ phẩm, làm đẹp, chăm sóc da', '💄', 'beauty', true, 210, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('0ae5962c-a16d-4e07-860b-9ea13d174576', 'spa', '🧖‍♀️ Spa', 'Spa, massage, thư giãn', '🧖‍♀️', 'beauty', true, 220, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('88b16cdc-3c76-4633-888d-748b08a40c48', 'salon', '💇‍♀️ Salon', 'Cắt tóc, tạo kiểu, làm nail', '💇‍♀️', 'beauty', true, 230, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('929559c9-d7a0-4292-a9f4-6aff2b8e8539', 'healthcare', '🏥 Y tế', 'Dịch vụ y tế, chăm sóc sức khỏe', '🏥', 'healthcare', true, 310, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('768b62b6-6b1c-4665-8296-1a0f9b7512bf', 'pharmacy', '💊 Nhà thuốc', 'Hiệu thuốc, dược phẩm', '💊', 'healthcare', true, 320, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('28066e50-889c-4181-b303-d77d598c5dbc', 'clinic', '🩺 Phòng khám', 'Phòng khám tư, chuyên khoa', '🩺', 'healthcare', true, 330, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('01f7f102-d0b5-4dce-98e5-26343f19f182', 'education', '🎓 Giáo dục', 'Trung tâm dạy học, đào tạo', '🎓', 'professional', true, 410, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('7ac90817-0d1b-4a18-8857-5cba2ef63e9c', 'consulting', '💼 Tư vấn', 'Dịch vụ tư vấn, chuyên môn', '💼', 'professional', true, 420, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('0785cb7a-689a-4591-94c0-6eba1261db0f', 'finance', '💰 Tài chính', 'Dịch vụ tài chính, bảo hiểm', '💰', 'professional', true, 430, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('34bfe785-4294-4890-bbf6-038acb095710', 'real_estate', '🏘️ Bất động sản', 'Môi giới, tư vấn bất động sản', '🏘️', 'professional', true, 440, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('0dbcca8f-9ce3-47ed-9297-c3a2b785451e', 'automotive', '🚗 Ô tô', 'Sửa chữa, bảo dưỡng ô tô, xe máy', '🚗', 'technical', true, 510, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('a68d37f4-a91f-4247-9e2f-e05e1a6331ed', 'repair', '🔧 Sửa chữa', 'Sửa chữa điện tử, đồ gia dụng', '🔧', 'technical', true, 520, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('0de2b85d-4410-4fb1-b00a-1a716c3be98a', 'cleaning', '🧹 Vệ sinh', 'Dịch vụ vệ sinh, dọn dẹp', '🧹', 'technical', true, 530, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('cb7fd67f-1574-458d-ad38-c6df271d9adf', 'construction', '🏗️ Xây dựng', 'Xây dựng, sửa chữa nhà cửa', '🏗️', 'technical', true, 540, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('7911c5f3-4be8-482b-a6b7-d0fcf55bf650', 'travel', '✈️ Du lịch', 'Tour du lịch, dịch vụ lữ hành', '✈️', 'entertainment', true, 610, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('2c14d3ba-8afb-4651-b1d6-514060332e39', 'hotel', '🏨 Khách sạn', 'Khách sạn, nhà nghỉ, homestay', '🏨', 'entertainment', true, 620, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('7ac93735-73a9-4517-8d80-d2d6b45e735a', 'entertainment', '🎉 Giải trí', 'Karaoke, game, sự kiện', '🎉', 'entertainment', true, 630, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('50787e95-4a31-4c94-bd22-1224cee4a8be', 'sports', '⚽ Thể thao', 'Sân thể thao, dụng cụ thể thao', '⚽', 'entertainment', true, 640, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('103b4ac9-dd72-4d7a-93d8-1b62ac03f6e5', 'agriculture', '🌾 Nông nghiệp', 'Nông sản, thủy sản, chăn nuôi', '🌾', 'industrial', true, 710, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('546c8520-8b18-4795-aa94-02612bdab76c', 'manufacturing', '🏭 Sản xuất', 'Sản xuất, gia công, chế biến', '🏭', 'industrial', true, 720, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('1dfd7419-5dd5-47d4-9daa-0841a597f47b', 'logistics', '🚚 Logistics', 'Vận chuyển, kho bãi, logistics', '🚚', 'industrial', true, 730, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('181ca2e0-58b7-4002-8f1b-6bdbe9442f47', 'service', '🔧 Dịch vụ', 'Dịch vụ tổng hợp khác', '🔧', 'service', true, 910, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('6eef9c17-98df-445c-88c3-3153a7970ac4', 'other', '🏢 Khác', 'Các loại hình kinh doanh khác', '🏢', 'other', true, 999, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');
INSERT INTO public.pos_mini_modular3_business_types VALUES ('8b66bec4-57ff-40a5-9210-ab7e5ceb0a73', 'gym', '💪 Gym & Thể thao', 'Phòng gym, yoga, thể dục thể thao', '💪', 'sports', true, 240, '2025-07-03 10:59:01.990231+00', '2025-07-04 22:53:46.113917+00');


--
-- Data for Name: pos_mini_modular3_businesses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_businesses VALUES ('61473fc9-16b2-45b8-87f0-45e0dc8612ef', 'An Nhiên Farm', 'BIZ1751366425', 'cafe', NULL, NULL, 'D2/062A, Nam Son, Quang Trung, Thong Nhat', '3604005775', NULL, NULL, 'trial', '{}', 'free', 'trial', '2025-07-01 10:40:25.745418+00', NULL, '2025-07-31 10:40:25.745418+00', 5, 50, '2025-07-01 10:40:25.745418+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('dda92815-c1f0-4597-8c05-47ec1eb50873', 'Của Hàng Rau Sạch Phi Yến', 'BIZ1751371309', 'retail', NULL, NULL, '145 Cạnh Sacombank Gia Yên', '987654456', NULL, NULL, 'trial', '{}', 'free', 'trial', '2025-07-01 12:01:49.27648+00', NULL, '2025-07-31 12:01:49.27648+00', 5, 50, '2025-07-01 12:01:49.27648+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('e997773b-8876-4837-aa80-c2f82cf07f83', 'Chao Lòng Viên Minh Châu', 'SAFE202507026623', 'service', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}', 'free', 'trial', '2025-07-02 18:55:36.167643+00', '2025-08-01 18:55:36.167643+00', '2025-08-01 18:55:36.167643+00', 3, 100, '2025-07-02 18:55:36.167643+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('c182f174-6372-4b34-964d-765fdc6dabbd', 'Lẩu Cua Đồng Thanh Sơn', 'BIZ202507039693', 'fashion', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}', 'premium', 'active', '2025-07-03 13:38:21.323452+00', NULL, NULL, 50, 5000, '2025-07-03 13:38:21.323452+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('7a2a2404-8498-4396-bd2b-e6745591652b', 'Test Direct RPC Business 2333', 'BIZ202507036302', 'retail', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}', 'free', 'trial', '2025-07-03 13:28:51.487484+00', '2025-08-02 13:28:51.487484+00', '2025-08-02 13:28:51.487484+00', 3, 50, '2025-07-03 13:28:51.487484+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('37c75836-edb9-4dc2-8bbe-83ad87ba274e', 'Gas Tân Yên 563 business ', 'BIZ202507032595', 'construction', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}', 'basic', 'active', '2025-07-03 13:39:20.303084+00', NULL, NULL, 10, 500, '2025-07-03 13:39:20.303084+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('1f0290fe-3ed1-440b-9a0b-68885aaba9f8', 'Test Direct RPC trucchi', 'BIZ202507032202', 'fashion', NULL, NULL, NULL, NULL, NULL, NULL, 'active', '{}', 'free', 'trial', '2025-07-03 13:28:51.257721+00', '2025-08-02 13:28:51.257721+00', '2025-08-02 13:28:51.257721+00', 3, 50, '2025-07-03 13:28:51.257721+00', '2025-07-04 22:53:46.665466+00');
INSERT INTO public.pos_mini_modular3_businesses VALUES ('97da7e62-0409-4882-b80c-2c75b60cb0da', 'Bida Thiên Long 3
', 'BIZ000001', 'retail', NULL, NULL, NULL, NULL, NULL, NULL, 'trial', '{}', 'free', 'trial', '2025-06-30 22:38:05.559244+00', NULL, '2025-07-30 22:38:05.559244+00', 3, 50, '2025-06-30 22:38:05.559244+00', '2025-07-04 23:33:51.772724+00');


--
-- Data for Name: pos_mini_modular3_user_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('550ce2c2-2d18-4a75-8ece-0c2c8f4dadad', '97da7e62-0409-4882-b80c-2c75b60cb0da', 'Bida Thiên Long 2', NULL, 'ericphan28@gmail.com', NULL, 'household_owner', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-06-30 22:38:05.559244+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('c8c6a529-e57c-4dbf-900f-c26dd4815195', '97da7e62-0409-4882-b80c-2c75b60cb0da', 'Nguyễn Văn A', '+84901234567', '+84901234567@staff.pos.local', NULL, 'seller', 'active', '[]', 'phone', NULL, 'NV001', '2025-06-30', 'Nhân viên bán hàng ca sáng', '2025-06-30 23:54:50.592949+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('8388a0e3-0a1a-4ce2-9c54-257994d44616', '97da7e62-0409-4882-b80c-2c75b60cb0da', 'Eric Phan', '+84909582083', '+84909582083@staff.pos.local', NULL, 'seller', 'active', '[]', 'phone', NULL, NULL, '2025-07-01', 'tét', '2025-07-01 00:06:56.999574+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('bba27899-25c8-4d5b-ba81-a0201f98bd00', '97da7e62-0409-4882-b80c-2c75b60cb0da', 'Cym Thang', '+84907136029', '+84907136029@staff.pos.local', NULL, 'manager', 'active', '[]', 'phone', NULL, 'Abcd', '2025-07-01', 'Thang PHan', '2025-07-01 00:09:24.007284+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('b5ca076a-7b1f-4d4e-808d-0610f71288a8', '97da7e62-0409-4882-b80c-2c75b60cb0da', 'Phan Thiên Vinh', '+84922388399', '+84922388399@staff.pos.local', NULL, 'seller', 'active', '[]', 'phone', NULL, 'Thien Vinh', '2025-07-01', 'Phan Thiên Vinh', '2025-07-01 00:59:06.756329+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('5f8d74cf-572a-4640-a565-34c5e1462f4e', '61473fc9-16b2-45b8-87f0-45e0dc8612ef', 'Phan Thiên Hào', '0907136029', 'cym_sunset@yahoo.com', NULL, 'household_owner', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-07-01 10:40:25.745418+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('8740cb15-5bea-480d-b58b-2f9fd51c144e', '61473fc9-16b2-45b8-87f0-45e0dc8612ef', 'Hào 2', '+84907131111', '+84907131111@staff.pos.local', NULL, 'manager', 'active', '[]', 'phone', NULL, 'cym_sunset@yahoo.com', '2025-07-01', 'khogn biet', '2025-07-01 10:43:03.150311+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('9c9bc32f-6b7e-4239-857a-83d9b8b16ce7', 'dda92815-c1f0-4597-8c05-47ec1eb50873', 'Mẹ Yến', '0909582083', 'yenwinny83@gmail.com', NULL, 'household_owner', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-07-01 12:01:49.27648+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('f1de66c9-166a-464c-89aa-bd75e1095040', NULL, 'Super Administrator', '0907136029', 'admin@giakiemso.com', NULL, 'super_admin', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-07-02 02:16:30.46745+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('8c3b94aa-68b1-47db-9029-07be27d3b917', '1f0290fe-3ed1-440b-9a0b-68885aaba9f8', 'Test Direct Owner', NULL, 'test.direct@rpc.test', NULL, 'household_owner', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-07-03 13:28:51.257721+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('3a799c65-8c58-429c-9e48-4d74b236ab97', 'c182f174-6372-4b34-964d-765fdc6dabbd', 'Nguyên Ly', '+84909123456', NULL, NULL, 'household_owner', 'active', '[]', 'phone', NULL, NULL, NULL, NULL, '2025-07-03 13:38:21.323452+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('9d40bf3c-e5a3-44c2-96c7-4c36a479e668', '37c75836-edb9-4dc2-8bbe-83ad87ba274e', 'Nguyễn Huy', '+84901456789', NULL, NULL, 'household_owner', 'active', '[]', 'phone', NULL, NULL, NULL, NULL, '2025-07-03 13:39:20.303084+00', '2025-07-04 22:53:48.217743+00');
INSERT INTO public.pos_mini_modular3_user_profiles VALUES ('2706a795-f2a4-46f6-8030-3553a8a1ecb0', '7a2a2404-8498-4396-bd2b-e6745591652b', 'Test Direct Owner 33', NULL, 'test.direct2@rpc.test', NULL, 'household_owner', 'active', '[]', 'email', NULL, NULL, NULL, NULL, '2025-07-03 13:28:51.487484+00', '2025-07-04 22:53:48.217743+00');


--
-- Data for Name: pos_mini_modular3_business_invitations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: pos_mini_modular3_restore_history; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_restore_history VALUES ('d46ff2c8-cbdd-4efb-be2d-78deb40e3bd4', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:47:20.054551+00', 'system', 'full', NULL, true, NULL, 7255, 6, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('cfee99fb-95fb-4ca6-9d30-7a9106328913', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:48:36.178514+00', 'system', 'full', NULL, true, NULL, 6775, 6, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('ab2a481b-7ba2-4935-99c1-1d07b9ad26d9', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:49:37.401882+00', 'system', 'full', NULL, false, 'Failed statements: 3', 7245, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('adee8e12-cb82-4c8c-920a-a9c5cc03229e', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:51:22.076096+00', 'system', 'full', NULL, false, 'Failed statements: 3', 7055, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('7fc394ad-d094-4f1c-898a-7b8d767cabfd', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:52:35.461462+00', 'system', 'full', NULL, false, 'Failed statements: 3', 7087, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('6503ffc7-c519-43c1-bdee-9a8723eb3c52', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:57:14.550814+00', 'system', 'full', NULL, false, 'Failed statements: 2', 6613, 6, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('80cd0207-c6b4-4672-8ff7-9e4ae16f491d', '15v2kx2zp3ymcoxduiq', '2025-07-04 14:59:19.804183+00', 'system', 'full', NULL, false, 'Failed statements: 2', 6518, 6, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('c9e879e4-de28-46d9-8ede-a1a806ddfffc', '0akl4fn6laafmcotdaeb', '2025-07-04 13:02:28.416021+00', 'system', 'full', NULL, true, NULL, 1612, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('3e08561e-ee58-4dda-bd3e-836871827130', '0akl4fn6laafmcotdaeb', '2025-07-04 14:36:49.982449+00', 'system', 'full', NULL, true, NULL, 1901, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('75ea3fd3-fd1b-4c82-8752-1ff7ca024605', '0akl4fn6laafmcotdaeb', '2025-07-04 14:42:16.570982+00', 'system', 'full', NULL, true, NULL, 7716, 5, NULL);
INSERT INTO public.pos_mini_modular3_restore_history VALUES ('b190abb7-9c68-4a28-9a56-290d34ae69bf', '15v2kx2zp3ymcoxduiq', '2025-07-04 22:53:51.442042+00', 'system', 'full', NULL, true, NULL, 8731, 6, NULL);


--
-- Data for Name: pos_mini_modular3_restore_points; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640676007_7xxs8a9vdvx', '2025-07-04 14:51:16.092+00', '{}', '', 'system', '2025-07-11 14:51:16.092+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640510167_v5gmu4ixzrj', '2025-07-04 14:48:30.357+00', '{}', '', 'system', '2025-07-11 14:48:30.357+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751669623638_aw5ekvmyig6', '2025-07-04 22:53:43.73+00', '{}', '', 'system', '2025-07-11 22:53:43.73+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751634147696_is9nixixlf', '2025-07-04 13:02:27.81+00', '{}', '', 'system', '2025-07-11 13:02:27.81+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751639808959_davp3fqyj6k', '2025-07-04 14:36:49.049+00', '{}', '', 'system', '2025-07-11 14:36:49.049+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751641028860_blsaixz2jb4', '2025-07-04 14:57:08.949+00', '{}', '', 'system', '2025-07-11 14:57:08.949+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751633606873_t9pymxb147s', '2025-07-04 12:53:26.964+00', '{}', '', 'system', '2025-07-11 12:53:26.964+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640129549_lm8jpkwt42', '2025-07-04 14:42:09.713+00', '{}', '', 'system', '2025-07-11 14:42:09.713+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751617487365_egol6m4kpoi', '2025-07-04 08:24:47.523+00', '{}', '', 'system', '2025-07-11 08:24:47.523+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751599680266_e4ylybiwohn', '2025-07-04 03:28:00.363+00', '{}', '', 'system', '2025-07-11 03:28:00.363+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751633770702_wc9scqxqvni', '2025-07-04 12:56:10.797+00', '{}', '', 'system', '2025-07-11 12:56:10.797+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751599701897_05vqy5o6r664', '2025-07-04 03:28:22.069+00', '{}', '', 'system', '2025-07-11 03:28:22.069+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751617947874_d4146ntfc9n', '2025-07-04 08:32:28.06+00', '{}', '', 'system', '2025-07-11 08:32:28.06+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751594519363_opt8v2gldo', '2025-07-04 02:01:59.46+00', '{}', '', 'system', '2025-07-11 02:01:59.46+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751594669921_pa4u2vraza', '2025-07-04 02:04:30.018+00', '{}', '', 'system', '2025-07-11 02:04:30.018+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751594729358_y5vzx79po8d', '2025-07-04 02:05:29.467+00', '{}', '', 'system', '2025-07-11 02:05:29.467+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751597076340_mv2s4qidpx', '2025-07-04 02:44:36.517+00', '{}', '', 'system', '2025-07-11 02:44:36.517+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751597626143_dgo8va2z645', '2025-07-04 02:53:46.239+00', '{}', '', 'system', '2025-07-11 02:53:46.239+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751598070832_0c1dxr1f8sh', '2025-07-04 03:01:10.931+00', '{}', '', 'system', '2025-07-11 03:01:10.931+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640570969_aa15cj8jr1i', '2025-07-04 14:49:31.066+00', '{}', '', 'system', '2025-07-11 14:49:31.066+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751641154217_n483fe0z9va', '2025-07-04 14:59:14.322+00', '{}', '', 'system', '2025-07-11 14:59:14.322+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751598400796_yz3c2wr16kc', '2025-07-04 03:06:40.987+00', '{}', '', 'system', '2025-07-11 03:06:40.987+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751598620105_jgx2qdwzgrh', '2025-07-04 03:10:20.204+00', '{}', '', 'system', '2025-07-11 03:10:20.204+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751598822849_4estkyxni6d', '2025-07-04 03:13:42.951+00', '{}', '', 'system', '2025-07-11 03:13:42.951+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751586732148_3rq1payl0ud', '2025-07-03 23:52:12.255+00', '{}', '', 'system', '2025-07-10 23:52:12.255+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751599718015_kplgdqk4t6n', '2025-07-04 03:28:38.11+00', '{}', '', 'system', '2025-07-11 03:28:38.111+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640433715_iqc0vpgpmec', '2025-07-04 14:47:13.809+00', '{}', '', 'system', '2025-07-11 14:47:13.809+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751640749325_02jp2uw2z8lq', '2025-07-04 14:52:29.422+00', '{}', '', 'system', '2025-07-11 14:52:29.422+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751586876910_il8998novgh', '2025-07-03 23:54:37.012+00', '{}', '', 'system', '2025-07-10 23:54:37.012+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751599766420_41k2fwrnvzz', '2025-07-04 03:29:26.515+00', '{}', '', 'system', '2025-07-11 03:29:26.516+00');
INSERT INTO public.pos_mini_modular3_restore_points VALUES ('rp_1751599827243_si4k85c0lpa', '2025-07-04 03:30:27.342+00', '{}', '', 'system', '2025-07-11 03:30:27.342+00');


--
-- Data for Name: pos_mini_modular3_subscription_history; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: pos_mini_modular3_subscription_plans; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pos_mini_modular3_subscription_plans VALUES ('d70ea130-fa83-43e5-a540-353d5385de45', 'free', 'Gói Miễn Phí', 0, 3, 50, 1, 1, '["basic_pos", "inventory_tracking", "sales_reports"]', true, '2025-06-30 09:20:59.160071+00', '2025-06-30 09:20:59.160071+00');
INSERT INTO public.pos_mini_modular3_subscription_plans VALUES ('09523773-7c0b-4583-b5eb-5fdc8820bc4f', 'basic', 'Gói Cơ Bản', 299000, 10, 500, 2, 3, '["advanced_pos", "multi_warehouse", "customer_management", "loyalty_program", "detailed_analytics"]', true, '2025-06-30 09:20:59.160071+00', '2025-06-30 09:20:59.160071+00');
INSERT INTO public.pos_mini_modular3_subscription_plans VALUES ('41106873-3c32-41a6-9680-a6c611a81157', 'premium', 'Gói Cao Cấp', 599000, 50, 5000, 5, 10, '["enterprise_pos", "multi_branch", "advanced_analytics", "api_access", "priority_support", "custom_reports", "inventory_optimization"]', true, '2025-06-30 09:20:59.160071+00', '2025-06-30 09:20:59.160071+00');


--
-- PostgreSQL database dump complete
--

