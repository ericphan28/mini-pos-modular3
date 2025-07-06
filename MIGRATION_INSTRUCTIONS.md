# 🎯 **HƯỚNG DẪN APPLY MIGRATION**

## 📋 **File cần chạy trong Supabase SQL Editor:**

### **Bước 1: Copy toàn bộ nội dung file:**
```
d:\Thang\with-supabase-appnpx\supabase\migrations\20250705_auth_access_functions.sql
```

### **Bước 2: Mở Supabase Dashboard:**
1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project của bạn
3. Vào **SQL Editor** (sidebar bên trái)
4. Click **"New query"**

### **Bước 3: Paste và chạy:**
1. **Paste toàn bộ nội dung** file migration vào SQL Editor
2. Click **"Run"** để execute
3. Kiểm tra không có lỗi

## ✅ **Kết quả mong đợi:**
- Tạo function: `pos_mini_modular3_get_all_tables_info()`
- Tạo function: `pos_mini_modular3_get_auth_users()`
- Grant permissions cho authenticated users

## 🧪 **Test sau khi apply:**
Sau khi chạy migration, test Export SQL tại:
```
Super Admin → Backup → Export SQL (button màu indigo)
```

Debug info sẽ hiển thị trong Browser Console (F12)

## 🚨 **LƯU Ý:**
- **KHÔNG** dùng `npx supabase db push`
- **LUÔN** copy-paste vào Supabase SQL Editor
- Đây là workflow tiêu chuẩn cho project này
