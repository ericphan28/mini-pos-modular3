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
00000000-0000-0000-0000-000000000000	5f8d74cf-572a-4640-a565-34c5e1462f4e	authenticated	authenticated	cym_sunset@yahoo.com	$2a$10$l1ahnejet3PJUhiJi1cms.B2csLc9S3.Yhozu81/T/ynWz6x/YQr6	2025-07-18 12:25:53.847923+00	\N		2025-07-01 09:11:07.107667+00		\N			\N	2025-07-19 13:43:43.059226+00	{"provider": "email", "providers": ["email"]}	{"sub": "5f8d74cf-572a-4640-a565-34c5e1462f4e", "email": "cym_sunset@yahoo.com", "phone": "0907136029", "address": "D2/062A, Nam Son, Quang Trung, Thong Nhat", "taxCode": "3604005775", "fullName": "Phan Thiên Hào", "businessName": "An Nhiên Farm", "businessType": "cafe", "email_verified": true, "phone_verified": false}	\N	2025-07-01 09:11:07.073442+00	2025-07-19 13:43:43.060991+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	c8c6a529-e57c-4dbf-900f-c26dd4815195	authenticated	authenticated	+84901234567@staff.pos.local	$2a$06$j8e0EwBGC.z7S7cRu9KDJOawWWcK62RMbIRFoMjgQ9DhR4a8Exe1e	2025-06-30 23:54:50.592949+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-06-30 23:54:50.592949+00	2025-06-30 23:54:50.592949+00	+84901234567	2025-06-30 23:54:50.592949+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	8388a0e3-0a1a-4ce2-9c54-257994d44616	authenticated	authenticated	+84909582083@staff.pos.local	$2a$06$055Vl2pUmCyyvCQB8obVU.ZjsWRbhY/J13Ssjz/Xr5RSrTcj1d/YS	2025-07-01 00:06:56.999574+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:06:56.999574+00	2025-07-01 00:06:56.999574+00	+84909582083	2025-07-01 00:06:56.999574+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	bba27899-25c8-4d5b-ba81-a0201f98bd00	authenticated	authenticated	+84907136029@staff.pos.local	$2a$06$Mg7gL8a5nk5ok/E3E0.CaObzsoHMqPkEFB4gcub0cjVyXwJJGWi2W	2025-07-01 00:09:24.007284+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:09:24.007284+00	2025-07-01 00:09:24.007284+00	+84907136029	2025-07-01 00:09:24.007284+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	b5ca076a-7b1f-4d4e-808d-0610f71288a8	authenticated	authenticated	+84922388399@staff.pos.local	$2a$06$cQXrBqc.jQeIUsIa77nU9eft0D3g0YdhY0I29qoaKJ1qtQLY2gSS.	2025-07-01 00:59:06.756329+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{}	f	2025-07-01 00:59:06.756329+00	2025-07-01 00:59:06.756329+00	+84922388399	2025-07-01 00:59:06.756329+00			\N		0	\N		\N	f	\N	f
\N	8c3b94aa-68b1-47db-9029-07be27d3b917	\N	\N	test.direct@rpc.test	$2a$06$N6Uk6qpqut6jYt.jGz1auOFk/rJCfv5jFfjxlfHetNTZwlKT6MtUW	2025-07-03 13:28:51.257721+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "email", "providers": ["email"]}	{"full_name": "Test Direct Owner"}	\N	2025-07-03 13:28:51.257721+00	2025-07-03 13:28:51.257721+00	\N	\N			\N		0	\N		\N	f	\N	f
\N	2706a795-f2a4-46f6-8030-3553a8a1ecb0	\N	\N	test.direct2@rpc.test	$2a$06$wEf4Evk4QMjDHDPNMTkt9OkTSzM9VkLRYt9sh6iRuTSXZIlcVIq0u	2025-07-03 13:28:51.487484+00	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "email", "providers": ["email"]}	{"full_name": "Test Direct Owner 2"}	\N	2025-07-03 13:28:51.487484+00	2025-07-03 13:28:51.487484+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	9c9bc32f-6b7e-4239-857a-83d9b8b16ce7	authenticated	authenticated	yenwinny83@gmail.com	$2a$10$C1lMtbgf/1EKPE7.vRGstOWpJlYGUiT1tx3/oNw86Xdbaxv8ObBbu	2025-07-01 12:00:03.406578+00	\N		2025-07-01 11:59:54.348181+00		\N			\N	2025-07-02 01:59:50.639001+00	{"provider": "email", "providers": ["email"]}	{"sub": "9c9bc32f-6b7e-4239-857a-83d9b8b16ce7", "email": "yenwinny83@gmail.com", "phone": "0909582083", "address": "145 Cạnh Sacombank Gia Yên", "taxCode": "987654456", "fullName": "Mẹ Yến", "businessName": "Của Hàng Rau Sạch Phi Yến", "businessType": "food_service", "email_verified": true, "phone_verified": false}	\N	2025-07-01 11:59:54.332309+00	2025-07-02 01:59:50.652378+00	\N	\N			\N		0	\N		\N	f	\N	f
\N	3a799c65-8c58-429c-9e48-4d74b236ab97	\N	\N	\N	$2a$06$aaId.rrWcLosmO4XBH7zweXRhrMANl.7tLRnFS2DZ6sgonolwND2S	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{"full_name": "Nguyên Ly"}	\N	2025-07-03 13:38:21.323452+00	2025-07-03 13:38:21.323452+00	+84909123456	2025-07-03 13:38:21.323452+00			\N		0	\N		\N	f	\N	f
\N	9d40bf3c-e5a3-44c2-96c7-4c36a479e668	\N	\N	\N	$2a$06$byCSpwUiKPtJza78STb5HeRghynJ3dfXPCTA18Z1C6S1ozcnSVZBW	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{"provider": "phone", "providers": ["phone"]}	{"full_name": "Nguyễn Huy"}	\N	2025-07-03 13:39:20.303084+00	2025-07-03 13:39:20.303084+00	+84901456789	2025-07-03 13:39:20.303084+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	f1de66c9-166a-464c-89aa-bd75e1095040	authenticated	authenticated	admin@giakiemso.com	$2a$06$GVkqtUduJGusGD1zqEbrueKSzbDjbaqedwSmV4ilF1TsJqLBOUFpm	2025-07-02 02:16:30.46745+00	\N		2025-07-02 02:16:30.46745+00		\N			\N	2025-07-07 00:01:32.333413+00	{"provider": "email", "providers": ["email"]}	{"full_name": "Super Administrator"}	f	2025-07-02 02:16:30.46745+00	2025-07-07 00:01:32.342115+00	0907136029	2025-07-02 02:16:30.46745+00			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	550ce2c2-2d18-4a75-8ece-0c2c8f4dadad	authenticated	authenticated	ericphan28@gmail.com	$2a$10$XeN2AYqNigpuM8vleGrlueHzo.Ck7waUtKgLmKP7s02jHgh2MRA.m	2025-06-30 21:45:29.779993+00	\N		2025-06-30 21:42:37.344249+00		\N			\N	2025-07-07 10:26:30.619998+00	{"provider": "email", "providers": ["email"]}	{"sub": "550ce2c2-2d18-4a75-8ece-0c2c8f4dadad", "email": "ericphan28@gmail.com", "email_verified": true, "phone_verified": false}	\N	2025-06-30 21:42:37.333746+00	2025-07-10 14:11:44.423104+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


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
-- Data for Name: pos_mini_modular3_business_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_business_features (id, business_id, feature_id, is_enabled, feature_value, override_reason, enabled_by, enabled_at, expires_at, created_at, updated_at) FROM stdin;
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
-- Data for Name: pos_mini_modular3_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_products (id, business_id, category_id, name, description, short_description, sku, barcode, price, cost_price, compare_at_price, product_type, has_variants, variant_options, track_inventory, inventory_policy, total_inventory, available_inventory, weight, dimensions, images, featured_image, slug, tags, meta_title, meta_description, status, is_featured, is_digital, requires_shipping, is_taxable, tax_rate, created_at, updated_at, published_at, unit_price, sale_price, current_stock, min_stock_level, track_stock, is_active, primary_image, specifications, created_by, updated_by) FROM stdin;
eb258577-ffde-4f7a-9773-3707a4095ddb	6f699d8d-3a1d-4820-8d3f-a824608181ec	f39bb53d-b7ca-424a-a8c8-79bb000e455a	Nồi cơm điện	Nồi cơm HItachi	\N	\N	\N	1000000.00	750000.00	0.00	simple	f	[]	t	deny	0	0	0.000	\N	[]	\N	ni-cm-in	["noicom", "thiet bi gia dinh"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 01:19:32.47205+00	2025-07-12 01:19:32.47205+00	\N	0.00	\N	9	1	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
7ef359c4-cce3-4521-9453-94f42afe8f96	6f699d8d-3a1d-4820-8d3f-a824608181ec	\N	Bò Úc - Lõi Vai  Bò 200g	Hàng chính hãng có giấy tờ đầy đủ	\N	\N	\N	0.00	0.00	0.00	simple	f	[]	t	deny	0	0	0.000	\N	[]	\N	b-c-li-vai-b-200g	["bo uc", "ga uc"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 02:56:12.170081+00	2025-07-12 02:56:12.170081+00	\N	0.00	\N	100	5	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
e2aab8f4-2db5-40b1-8bd1-7d17d0721234	6f699d8d-3a1d-4820-8d3f-a824608181ec	f39bb53d-b7ca-424a-a8c8-79bb000e455a	Bida 01	Thang bida  Thien Long	\N	\N	\N	50000.00	30000.00	\N	simple	f	[]	t	deny	0	0	\N	\N	[]	\N	bida-01	["khuyen mai", "the tag"]	\N	\N	draft	t	f	t	t	0.00	2025-07-12 05:17:30.080015+00	2025-07-12 05:17:30.080015+00	\N	0.00	\N	60	5	t	t	\N	{}	5f8d74cf-572a-4640-a565-34c5e1462f4e	5f8d74cf-572a-4640-a565-34c5e1462f4e
\.


--
-- Data for Name: pos_mini_modular3_product_variants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_variants (id, product_id, business_id, title, option1, option2, option3, sku, barcode, price, cost_price, compare_at_price, inventory_quantity, inventory_policy, weight, dimensions, image, is_active, "position", created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pos_mini_modular3_product_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_product_inventory (id, business_id, product_id, variant_id, transaction_type, quantity_change, quantity_after, reference_type, reference_id, notes, location_name, unit_cost, created_by, created_at) FROM stdin;
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
-- Data for Name: pos_mini_modular3_user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_mini_modular3_user_sessions (id, user_id, session_token, device_info, ip_address, user_agent, is_active, last_activity, expires_at, created_at, updated_at) FROM stdin;
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
-- PostgreSQL database dump complete
--

