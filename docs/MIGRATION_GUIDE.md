# 🗄️ Hướng dẫn chạy Database Migration

## � **Cấu trúc Migrations mới (2025-07-07)**

```
📁 supabase/migrations/          # ← TẤT CẢ migrations ở đây
├── 001_business_subscription_system.sql  # ✅ Core
├── 002_role_permissions_matrix.sql       # ✅ Core  
├── 003_admin_sessions.sql                # ✅ Core
├── 004_enhanced_auth_functions.sql       # ⭐ Core (ESSENTIAL)
├── 005_auth_access_functions.sql         # 🔧 Feature
├── 006_product_management_system.sql     # 🔧 Feature
└── 007_product_functions.sql             # 🔧 Feature
```

## �📋 **Thứ tự thực hiện (BẮT BUỘC)**

### **CORE SYSTEM (001-004) - CHẠY THEO THỨ TỰ:**

#### **Bước 1: Business Subscription System**
1. Mở Supabase Dashboard → SQL Editor
2. Copy nội dung file `001_business_subscription_system.sql`
3. Paste vào editor và click **Run**
4. Verify: Business table có subscription columns

#### **Bước 2: Role Permissions Matrix**
1. Copy nội dung file `002_role_permissions_matrix.sql`
2. Paste vào SQL Editor và **Run**
3. Verify: Bảng `pos_mini_modular3_role_permissions` đã tạo

#### **Bước 3: Admin Sessions**
1. Copy nội dung file `003_admin_sessions.sql`
2. Paste vào SQL Editor và **Run**
3. Verify: Bảng `pos_mini_modular3_admin_sessions` đã tạo

#### **Bước 4: Enhanced Auth Functions (ESSENTIAL)**
1. Copy nội dung file `004_enhanced_auth_functions.sql`
2. Paste vào SQL Editor và **Run**
3. Verify: Functions `pos_mini_modular3_get_user_with_business_complete()` etc.

### **FEATURE SYSTEM (005-007) - TÙY CHỌN:**
- **005**: Auth access functions (cho Export SQL)
- **006**: Product management tables  
- **007**: Product management functions

## ✅ **Verification Steps**

### **Test Enhanced Auth System:**
1. Vào `/test-enhanced-auth` 
2. Kiểm tra user info, business context, permissions hiển thị đúng
3. Xác nhận không có lỗi console

### **Kiểm tra Database Functions:**
```sql
-- Kiểm tra enhanced auth functions đã tạo
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'pos_mini_modular3_%' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Test function hoạt động
SELECT pos_mini_modular3_get_user_with_business_complete(auth.uid());
```

## 🚨 **Troubleshooting**

### **Lỗi thường gặp:**

#### **"relation already exists"**
- Nghĩa là bảng/cột đã tồn tại
- An toàn, có thể bỏ qua

#### **"column does not exist"**
- Chạy lại migration 001 trước
- Đảm bảo `pos_mini_modular3_businesses` table tồn tại

#### **"constraint violation"**
- Kiểm tra dữ liệu existing có hợp lệ không
- Có thể cần clean up data trước migration

### **Rollback nếu cần:**
```sql
-- Xóa bảng mới tạo (CHỈ KHI CẦN THIẾT)
DROP TABLE IF EXISTS pos_mini_modular3_admin_sessions;
DROP TABLE IF EXISTS pos_mini_modular3_role_permissions;

-- Xóa cột subscription từ businesses (NGUY HIỂM)
ALTER TABLE pos_mini_modular3_businesses 
DROP COLUMN IF EXISTS subscription_tier,
DROP COLUMN IF EXISTS subscription_status,
DROP COLUMN IF EXISTS subscription_starts_at,
DROP COLUMN IF EXISTS subscription_ends_at,
DROP COLUMN IF EXISTS trial_ends_at,
DROP COLUMN IF EXISTS feature_access,
DROP COLUMN IF EXISTS usage_limits,
DROP COLUMN IF EXISTS current_usage;
```

## 🎯 **Sau khi Migration xong**

### **Test Authentication mới:**
1. Login vào app
2. Kiểm tra `BusinessAuthService` hoạt động
3. Test `PermissionGate` component
4. Verify subscription logic

### **Update code để sử dụng:**
```typescript
// Import service mới
import { businessAuth } from '@/lib/auth/business-auth.service';
import { useFeatureAccess } from '@/hooks/use-feature-access';
import PermissionGate from '@/components/feature-gates/permission-gate';

// Sử dụng trong component
const { hasAccess, currentUsage, limit } = useFeatureAccess('product_management');
```

---
**📅 Tạo: 2025-07-06 | Migration cho business-centric auth model**
