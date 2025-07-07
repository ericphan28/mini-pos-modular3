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

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	8740cb15-5bea-480d-b58b-2f9fd51c144e	authenticated	authenticated	+84907131111@staff.pos.local	$2a$06$4Rz9QG7LE6XExIGTMX9dwumRLztCiPJ5rq8q3TIjJ2YIDSgyspRxS	2025-07-01 10:43:03.150311+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 10:43:03.150311+00	2025-07-01 10:43:03.150311+00	+84907131111	2025-07-01 10:43:03.150311+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	550ce2c2-2d18-4a75-8ece-0c2c8f4dadad	authenticated	authenticated	ericphan28@gmail.com	$2a$10$XeN2AYqNigpuM8vleGrlueHzo.Ck7waUtKgLmKP7s02jHgh2MRA.m	2025-06-30 21:45:29.779993+00	\N		2025-06-30 21:42:37.344249+00		\N			\N	2025-07-06 14:28:26.612989+00	{"provider": "email", "providers": ["email"]}	{"sub": "550ce2c2-2d18-4a75-8ece-0c2c8f4dadad", "email": "ericphan28@gmail.com", "email_verified": true, "phone_verified": false}	\N	2025-06-30 21:42:37.333746+00	2025-07-06 23:55:33.61246+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	c8c6a529-e57c-4dbf-900f-c26dd4815195	authenticated	authenticated	+84901234567@staff.pos.local	$2a$06$j8e0EwBGC.z7S7cRu9KDJOawWWcK62RMbIRFoMjgQ9DhR4a8Exe1e	2025-06-30 23:54:50.592949+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-06-30 23:54:50.592949+00	2025-06-30 23:54:50.592949+00	+84901234567	2025-06-30 23:54:50.592949+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	8388a0e3-0a1a-4ce2-9c54-257994d44616	authenticated	authenticated	+84909582083@staff.pos.local	$2a$06$055Vl2pUmCyyvCQB8obVU.ZjsWRbhY/J13Ssjz/Xr5RSrTcj1d/YS	2025-07-01 00:06:56.999574+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:06:56.999574+00	2025-07-01 00:06:56.999574+00	+84909582083	2025-07-01 00:06:56.999574+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	bba27899-25c8-4d5b-ba81-a0201f98bd00	authenticated	authenticated	+84907136029@staff.pos.local	$2a$06$Mg7gL8a5nk5ok/E3E0.CaObzsoHMqPkEFB4gcub0cjVyXwJJGWi2W	2025-07-01 00:09:24.007284+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:09:24.007284+00	2025-07-01 00:09:24.007284+00	+84907136029	2025-07-01 00:09:24.007284+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	b5ca076a-7b1f-4d4e-808d-0610f71288a8	authenticated	authenticated	+84922388399@staff.pos.local	$2a$06$cQXrBqc.jQeIUsIa77nU9eft0D3g0YdhY0I29qoaKJ1qtQLY2gSS.	2025-07-01 00:59:06.756329+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:59:06.756329+00	2025-07-01 00:59:06.756329+00	+84922388399	2025-07-01 00:59:06.756329+00			\N		0	\N		\N	f	\N	f
\N	8c3b94aa-68b1-47db-9029-07be27d3b917	\N	\N	test.direct@rpc.test	$2a$06$N6Uk6qpqut6jYt.jGz1auOFk/rJCfv5jFfjxlfHetNTZwlKT6MtUW	2025-07-03 13:28:51.257721+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "email", "providers": ["email"]}	{"full_name": "Test Direct Owner"}	\N	2025-07-03 13:28:51.257721+00	2025-07-03 13:28:51.257721+00	\N	\N			\N		0	\N		\N	f	\N	f
\N	2706a795-f2a4-46f6-8030-3553a8a1ecb0	\N	\N	test.direct2@rpc.test	$2a$06$wEf4Evk4QMjDHDPNMTkt9OkTSzM9VkLRYt9sh6iRuTSXZIlcVIq0u	2025-07-03 13:28:51.487484+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "email", "providers": ["email"]}	{"full_name": "Test Direct Owner 2"}	\N	2025-07-03 13:28:51.487484+00	2025-07-03 13:28:51.487484+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	90437fcb-0a83-44b7-ab05-322af922b451	authenticated	authenticated	bidathienlong01@gmail.com	$2a$10$wTPSitpXOKVHVSaR6/ohCODHENGpqSxzQRHlpMpN2Wm0JfCegaVDm	2025-07-02 19:43:50.594085+00	\N		2025-07-02 19:30:55.093304+00		\N			\N	2025-07-02 19:44:04.468565+00	{"provider": "email", "providers": ["email"]}	{"sub": "90437fcb-0a83-44b7-ab05-322af922b451", "email": "bidathienlong01@gmail.com", "phone": "0909564874", "address": "54 ap Gia Tân 2", "taxCode": "987026351478", "fullName": "Phan Thiên Long", "businessName": "Nhà Hàn Hoa Viên 79", "businessType": "fashion", "email_verified": true, "phone_verified": false}	\N	2025-07-02 19:30:55.052042+00	2025-07-02 19:44:04.481823+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	9c9bc32f-6b7e-4239-857a-83d9b8b16ce7	authenticated	authenticated	yenwinny83@gmail.com	$2a$10$C1lMtbgf/1EKPE7.vRGstOWpJlYGUiT1tx3/oNw86Xdbaxv8ObBbu	2025-07-01 12:00:03.406578+00	\N		2025-07-01 11:59:54.348181+00		\N			\N	2025-07-02 01:59:50.639001+00	{"provider": "email", "providers": ["email"]}	{"sub": "9c9bc32f-6b7e-4239-857a-83d9b8b16ce7", "email": "yenwinny83@gmail.com", "phone": "0909582083", "address": "145 Cạnh Sacombank Gia Yên", "taxCode": "987654456", "fullName": "Mẹ Yến", "businessName": "Của Hàng Rau Sạch Phi Yến", "businessType": "food_service", "email_verified": true, "phone_verified": false}	\N	2025-07-01 11:59:54.332309+00	2025-07-02 01:59:50.652378+00	\N	\N			\N		0	\N		\N	f	\N	f
\N	3a799c65-8c58-429c-9e48-4d74b236ab97	\N	\N	\N	$2a$06$aaId.rrWcLosmO4XBH7zweXRhrMANl.7tLRnFS2DZ6sgonolwND2S	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{"full_name": "Nguyên Ly"}	\N	2025-07-03 13:38:21.323452+00	2025-07-03 13:38:21.323452+00	+84909123456	2025-07-03 13:38:21.323452+00			\N		0	\N		\N	f	\N	f
\N	9d40bf3c-e5a3-44c2-96c7-4c36a479e668	\N	\N	\N	$2a$06$byCSpwUiKPtJza78STb5HeRghynJ3dfXPCTA18Z1C6S1ozcnSVZBW	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{"full_name": "Nguyễn Huy"}	\N	2025-07-03 13:39:20.303084+00	2025-07-03 13:39:20.303084+00	+84901456789	2025-07-03 13:39:20.303084+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	5f8d74cf-572a-4640-a565-34c5e1462f4e	authenticated	authenticated	cym_sunset@yahoo.com	$2a$10$l1ahnejet3PJUhiJi1cms.B2csLc9S3.Yhozu81/T/ynWz6x/YQr6	2025-07-01 09:11:33.876679+00	\N		2025-07-01 09:11:07.107667+00		\N			\N	2025-07-07 00:10:17.491723+00	{"provider": "email", "providers": ["email"]}	{"sub": "5f8d74cf-572a-4640-a565-34c5e1462f4e", "email": "cym_sunset@yahoo.com", "phone": "0907136029", "address": "D2/062A, Nam Son, Quang Trung, Thong Nhat", "taxCode": "3604005775", "fullName": "Phan Thiên Hào", "businessName": "An Nhiên Farm", "businessType": "cafe", "email_verified": true, "phone_verified": false}	\N	2025-07-01 09:11:07.073442+00	2025-07-07 00:10:17.501445+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	f1de66c9-166a-464c-89aa-bd75e1095040	authenticated	authenticated	admin@giakiemso.com	$2a$06$GVkqtUduJGusGD1zqEbrueKSzbDjbaqedwSmV4ilF1TsJqLBOUFpm	2025-07-02 02:16:30.46745+00	\N		2025-07-02 02:16:30.46745+00		\N			\N	2025-07-07 00:01:32.333413+00	{"provider": "email", "providers": ["email"]}	{"full_name": "Super Administrator"}	f	2025-07-02 02:16:30.46745+00	2025-07-07 00:01:32.342115+00	0907136029	2025-07-02 02:16:30.46745+00			\N		0	\N		\N	f	\N	f
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
61473fc9-16b2-45b8-87f0-45e0dc8612ef	An Nhiên Farm	BIZ1751366425	cafe	\N	\N	D2/062A, Nam Son, Quang Trung, Thong Nhat	3604005775	\N	\N	trial	{}	free	trial	2025-07-01 10:40:25.745418+00	\N	2025-07-31 10:40:25.745418+00	5	50	2025-07-01 10:40:25.745418+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
dda92815-c1f0-4597-8c05-47ec1eb50873	Của Hàng Rau Sạch Phi Yến	BIZ1751371309	retail	\N	\N	145 Cạnh Sacombank Gia Yên	987654456	\N	\N	trial	{}	free	trial	2025-07-01 12:01:49.27648+00	\N	2025-07-31 12:01:49.27648+00	5	50	2025-07-01 12:01:49.27648+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
e997773b-8876-4837-aa80-c2f82cf07f83	Chao Lòng Viên Minh Châu	SAFE202507026623	service	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-02 18:55:36.167643+00	2025-08-01 18:55:36.167643+00	2025-08-01 18:55:36.167643+00	3	100	2025-07-02 18:55:36.167643+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
c182f174-6372-4b34-964d-765fdc6dabbd	Lẩu Cua Đồng Thanh Sơn	BIZ202507039693	fashion	\N	\N	\N	\N	\N	\N	active	{}	premium	active	2025-07-03 13:38:21.323452+00	\N	\N	50	5000	2025-07-03 13:38:21.323452+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
7a2a2404-8498-4396-bd2b-e6745591652b	Test Direct RPC Business 2333	BIZ202507036302	retail	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-03 13:28:51.487484+00	2025-08-02 13:28:51.487484+00	2025-08-02 13:28:51.487484+00	3	50	2025-07-03 13:28:51.487484+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
37c75836-edb9-4dc2-8bbe-83ad87ba274e	Gas Tân Yên 563 business 	BIZ202507032595	construction	\N	\N	\N	\N	\N	\N	active	{}	basic	active	2025-07-03 13:39:20.303084+00	\N	\N	10	500	2025-07-03 13:39:20.303084+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
1f0290fe-3ed1-440b-9a0b-68885aaba9f8	Test Direct RPC trucchi	BIZ202507032202	fashion	\N	\N	\N	\N	\N	\N	active	{}	free	trial	2025-07-03 13:28:51.257721+00	2025-08-02 13:28:51.257721+00	2025-08-02 13:28:51.257721+00	3	50	2025-07-03 13:28:51.257721+00	2025-07-04 22:53:46.665466+00	{}	{}	\N	\N
97da7e62-0409-4882-b80c-2c75b60cb0da	Bida Thiên Long 3\n	BIZ000001	retail	\N	\N	\N	\N	\N	\N	trial	{}	free	trial	2025-06-30 22:38:05.559244+00	\N	2025-07-30 22:38:05.559244+00	3	50	2025-06-30 22:38:05.559244+00	2025-07-04 23:33:51.772724+00	{}	{}	\N	\N
\.


--
-- Data for Name: pos_mini_modular3_admin_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_admin_sessions (id, super_admin_id, target_business_id, impersonated_role, session_reason, session_start, session_end, is_active, created_at) FROM stdin;
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
-- Data for Name: pos_mini_modular3_backup_downloads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_downloads (id, backup_id, downloaded_at, downloaded_by, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_backup_schedules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_schedules (id, name, backup_type, cron_expression, enabled, compression, encryption, retention_days, last_run_at, next_run_at, failure_count, last_error, created_by, created_at, updated_at) FROM stdin;
8bad2bc1-a479-48c1-a58c-6424e34e58ea	Daily Incremental Backup	incremental	0 2 * * *	t	gzip	t	30	\N	2025-07-04 15:50:02.923339+00	0	\N	system	2025-07-03 15:50:02.923339+00	2025-07-04 22:53:45.51178+00
f46e39c3-5a40-48f7-984a-27cd5704fb09	Weekly Full Backup	full	0 3 * * 0	t	gzip	t	90	\N	2025-07-10 15:50:02.923339+00	0	\N	system	2025-07-03 15:50:02.923339+00	2025-07-04 22:53:45.51178+00
\.


--
-- Data for Name: pos_mini_modular3_backup_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_backup_notifications (id, type, title, message, backup_id, schedule_id, read, created_at, details) FROM stdin;
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
f1de66c9-166a-464c-89aa-bd75e1095040	\N	Super Administrator	0907136029	admin@giakiemso.com	\N	super_admin	active	[]	email	\N	\N	\N	\N	2025-07-02 02:16:30.46745+00	2025-07-04 22:53:48.217743+00
8c3b94aa-68b1-47db-9029-07be27d3b917	1f0290fe-3ed1-440b-9a0b-68885aaba9f8	Test Direct Owner	\N	test.direct@rpc.test	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-03 13:28:51.257721+00	2025-07-04 22:53:48.217743+00
3a799c65-8c58-429c-9e48-4d74b236ab97	c182f174-6372-4b34-964d-765fdc6dabbd	Nguyên Ly	+84909123456	\N	\N	household_owner	active	[]	phone	\N	\N	\N	\N	2025-07-03 13:38:21.323452+00	2025-07-04 22:53:48.217743+00
9d40bf3c-e5a3-44c2-96c7-4c36a479e668	37c75836-edb9-4dc2-8bbe-83ad87ba274e	Nguyễn Huy	+84901456789	\N	\N	household_owner	active	[]	phone	\N	\N	\N	\N	2025-07-03 13:39:20.303084+00	2025-07-04 22:53:48.217743+00
2706a795-f2a4-46f6-8030-3553a8a1ecb0	7a2a2404-8498-4396-bd2b-e6745591652b	Test Direct Owner 33	\N	test.direct2@rpc.test	\N	household_owner	active	[]	email	\N	\N	\N	\N	2025-07-03 13:28:51.487484+00	2025-07-04 22:53:48.217743+00
\.


--
-- Data for Name: pos_mini_modular3_business_invitations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_invitations (id, business_id, invited_by, email, role, invitation_token, status, expires_at, accepted_at, accepted_by, created_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_categories (id, business_id, parent_id, name, description, display_order, color_code, icon_name, image_url, is_active, is_featured, slug, meta_title, meta_description, settings, created_at, updated_at, created_by, updated_by) FROM stdin;
bdcdf79e-8122-4030-9d9d-0844b6f7d8d6	61473fc9-16b2-45b8-87f0-45e0dc8612ef	\N	test-category-1751844179009	Test category for migration verification	0	\N	\N	\N	t	f	testcategory1751844179009	\N	\N	{}	2025-07-06 23:22:58.954508+00	2025-07-06 23:22:58.954508+00	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
3471e860-c2b3-4370-8cd4-338ee6a64a4f	61473fc9-16b2-45b8-87f0-45e0dc8612ef	\N	test-category-1751844591889	Test category for migration verification	0	\N	\N	\N	t	f	testcategory1751844591889	\N	\N	{}	2025-07-06 23:29:51.78536+00	2025-07-06 23:29:51.78536+00	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
3d0c2b0f-be55-4eb9-a6d9-266557347ba9	61473fc9-16b2-45b8-87f0-45e0dc8612ef	\N	test-category-1751845371372	Test category for migration verification	0	\N	\N	\N	t	f	testcategory1751845371372	\N	\N	{}	2025-07-06 23:42:51.285252+00	2025-07-06 23:42:51.285252+00	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
\.


--
-- Data for Name: pos_mini_modular3_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_products (id, business_id, category_id, name, description, short_description, sku, barcode, internal_code, unit_price, cost_price, sale_price, min_price, max_discount_percent, current_stock, min_stock_level, max_stock_level, reorder_point, unit_of_measure, weight, weight_unit, dimensions, brand, manufacturer, origin_country, tax_rate, tax_category, is_active, is_featured, is_digital, has_variants, track_stock, allow_backorder, tags, display_order, slug, meta_title, meta_description, images, primary_image, specifications, attributes, settings, view_count, sale_count, last_sold_at, created_at, updated_at, created_by, updated_by) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_variants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_variants (id, product_id, business_id, name, sku, barcode, attributes, unit_price, cost_price, sale_price, current_stock, min_stock_level, reorder_point, weight, dimensions, image_url, is_active, display_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_images (id, product_id, variant_id, business_id, url, filename, original_filename, alt_text, size_bytes, width, height, format, is_primary, display_order, is_active, created_at, uploaded_by) FROM stdin;
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
-- Data for Name: pos_mini_modular3_role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_role_permissions (id, subscription_tier, user_role, feature_name, can_read, can_write, can_delete, can_manage, usage_limit, config_data, created_at, updated_at) FROM stdin;
366d08c0-0ebe-4d84-9f00-33a48eb69bfd	free	business_owner	product_management	t	t	t	t	20	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
7dcb1350-225f-4582-9f6a-c5497c7b8337	free	business_owner	pos_interface	t	t	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
8756f907-f221-4ecd-940f-ad7cc196c0da	free	business_owner	basic_reports	t	f	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
f89469f6-1670-44b3-9fa2-7a6b47623c54	free	business_owner	staff_management	t	t	t	t	3	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
6a98ccc5-3d99-4236-a454-206329b61497	free	business_owner	financial_tracking	t	t	f	t	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
805bdb3e-aa4e-4340-b0c4-ba7b280e619d	free	seller	product_management	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
2e10602e-d882-4add-bc96-184a98fef5ca	free	seller	pos_interface	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
fdaa9936-511a-4f70-9ed0-e0ab1a1c8633	free	seller	basic_reports	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
edf121d3-4b08-4028-a5d8-393b2d6f47d3	free	accountant	product_management	t	f	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
15ae7d18-c2ef-419f-977e-7b663f0abfed	free	accountant	financial_tracking	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
f2522ee3-c1bd-4281-8ea0-2a8318af1478	free	accountant	basic_reports	t	t	f	f	\N	{}	2025-07-06 16:40:23.275321+00	2025-07-06 16:40:23.275321+00
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
-- PostgreSQL database dump complete
--

