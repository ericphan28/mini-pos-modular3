# 🎯 **HƯỚNG DẪN APPLY MIGRATIONS - POS MINI MODULAR 3**

## � **Cấu trúc Migrations mới (đã chuẩn hóa):**

```
📁 supabase/migrations/
├── 000_migration_guide.sql               # 📖 Hướng dẫn master
├── 001_business_subscription_system.sql  # ✅ Core: Business subscription
├── 002_role_permissions_matrix.sql       # ✅ Core: User roles & permissions
├── 003_admin_sessions.sql                # ✅ Core: Admin sessions
├── 004_enhanced_auth_functions.sql       # ⭐ Core: Enhanced auth (ESSENTIAL)
├── 005_auth_access_functions.sql         # 🔧 Feature: Auth access functions
├── 006_product_management_system.sql     # 🔧 Feature: Product tables
├── 007_product_functions.sql             # 🔧 Feature: Product functions
└── README.md                             # 📋 Chi tiết hướng dẫn
```

## 🚀 **Quy trình Apply Migrations:**

### **Bước 1: Migrations Core System (BẮT BUỘC)**
Chạy theo thứ tự CHÍNH XÁC:

1. **001_business_subscription_system.sql**
2. **002_role_permissions_matrix.sql** 
3. **003_admin_sessions.sql**
4. **004_enhanced_auth_functions.sql** ⭐ **ESSENTIAL cho auth system**

### **Bước 2: Feature Migrations (TÙY CHỌN)**
5. **005_auth_access_functions.sql** (cho Export SQL feature)
6. **006_product_management_system.sql** (cho Product management)
7. **007_product_functions.sql** (cho Product functions)

## 📝 **Cách thực hiện từng migration:**

### **Copy nội dung file migration:**
```
Ví dụ: supabase/migrations/001_business_subscription_system.sql
```

### **Mở Supabase Dashboard:**
1. Truy cập [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project của bạn
3. Vào **SQL Editor** (sidebar bên trái)
4. Click **"New query"**

### **Paste và chạy:**
1. **Paste toàn bộ nội dung** file migration vào SQL Editor
2. Click **"Run"** để execute
3. Kiểm tra không có lỗi trước khi chuyển migration tiếp theo

## ✅ **Kết quả mong đợi sau khi hoàn thành:**

### **Sau Migration 001-004 (Core):**
- ✅ Business subscription system
- ✅ Role permissions matrix 
- ✅ Admin sessions
- ✅ Enhanced auth functions (get_user_with_business_complete, check_user_permission, etc.)

### **Sau Migration 005-007 (Features):**
- ✅ Export SQL functions
- ✅ Product management tables
- ✅ Product management functions

## 🧪 **Testing sau migration:**

### **Test Enhanced Auth System:**
```
Vào: /test-enhanced-auth
Kiểm tra: User info, business context, permissions
```

### **Test Export SQL (nếu chạy migration 005):**
```
Super Admin → Backup → Export SQL (button màu indigo)
```

## 🚨 **LƯU Ý QUAN TRỌNG:**
- ⚠️ **KHÔNG** dùng `npx supabase db push`
- ✅ **LUÔN** copy-paste vào Supabase SQL Editor  
- ✅ **CHẠY THEO THỨ TỰ** 001 → 002 → 003 → 004
- ⭐ **Migration 004 là ESSENTIAL** - không thể bỏ qua
- 🔄 **Tất cả migrations đều idempotent** (an toàn chạy nhiều lần)

## 📞 **Hỗ trợ:**
- Đọc chi tiết: `supabase/migrations/README.md`
- Hướng dẫn master: `supabase/migrations/000_migration_guide.sql`
