# 🔐 Enhanced Auth System Testing Guide

## � URGENT: Login Debug Steps

### 🔍 Quick Diagnosis
If login is failing, follow these steps:

1. **Test Migration Status**: Navigate to `http://localhost:3001/test-migrations`
2. **Check Console Logs**: Open F12 > Console and look for:
   - `🔐 [LOGIN-FORM]` - Basic login steps
   - `🚀 [ENHANCED-AUTH]` - Enhanced auth system  
   - `❌ [ERROR]` - Error details

### 🚨 If Login Fails
The login form now has enhanced debugging and fallbacks:
- ✅ Tests if enhanced auth function exists
- ✅ Falls back to basic profile checking
- ✅ Ultimate fallback to dashboard redirect

---

## 📋 Migration Deployment Guide

### 1.1 Copy Migration 004
```sql
-- Copy toàn bộ nội dung file: supabase/migrations/004_enhanced_auth_functions.sql
-- Paste vào Supabase Dashboard > SQL Editor > Run
```

### 1.2 Verify Migration Success
Kiểm tra các functions đã được tạo:
```sql
-- Test query in Supabase SQL Editor
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'pos_mini_modular3_%' 
AND routine_name IN (
  'pos_mini_modular3_get_user_with_business_complete',
  'pos_mini_modular3_check_user_permission',
  'pos_mini_modular3_update_usage_stats',
  'pos_mini_modular3_validate_subscription'
)
ORDER BY routine_name;
```

## 🚀 Step 2: Run Migration 005 (Auth Access Functions)

### 2.1 Copy Migration 005
```sql
-- Copy toàn bộ nội dung file: supabase/migrations/005_auth_access_functions.sql
-- Paste vào Supabase Dashboard > SQL Editor > Run
```

### 2.2 Test Migration 005
```sql
-- Test auth access functions
SELECT * FROM pos_mini_modular3_get_all_tables_info();
SELECT COUNT(*) FROM pos_mini_modular3_get_auth_users();
```

## 🚀 Step 3: Run Migration 006 (Product Management System)

### 3.1 Copy Migration 006
```sql
-- Copy toàn bộ nội dung file: supabase/migrations/006_product_management_system.sql
-- Paste vào Supabase Dashboard > SQL Editor > Run
```

### 3.2 Verify Tables Created
```sql
-- Check product management tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'pos_mini_modular3_product%'
ORDER BY table_name;
```

## 🚀 Step 4: Run Migration 007 (Product Functions)

### 4.1 Copy Migration 007
```sql
-- Copy toàn bộ nội dung file: supabase/migrations/007_product_functions.sql
-- Paste vào Supabase Dashboard > SQL Editor > Run
```

### 4.2 Verify Product Functions
```sql
-- Check product management functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'pos_mini_modular3_%product%' 
OR routine_name LIKE 'pos_mini_modular3_%category%'
ORDER BY routine_name;
```

## 🧪 Step 5: Test Enhanced Auth Service

### 5.1 Start Development Server
```powershell
cd d:\Thang\with-supabase-appnpx
npm run dev
```

### 5.2 Access Test Page
Navigate to: `http://localhost:3000/test-enhanced-auth`

### 5.3 Test Scenarios

#### A. Login Test
1. **Login với existing user**
2. **Check user profile loading**
3. **Verify business assignment**
4. **Check subscription status**

#### B. Permission Test
1. **Read permissions** - các features cơ bản
2. **Write permissions** - tạo/sửa data
3. **Delete permissions** - xóa data
4. **Manage permissions** - quản lý system

#### C. Usage Limits Test
1. **Test usage tracking**
2. **Test limit enforcement**
3. **Test subscription tier limits**

### 5.4 Expected Results

#### ✅ Successful Login
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "owner",
    "full_name": "User Name"
  },
  "business": {
    "id": "uuid", 
    "name": "Business Name",
    "subscription_tier": "free",
    "subscription_status": "trial"
  },
  "permissions": {
    "products": { "can_read": true, "can_write": true },
    "reports": { "can_read": true, "can_write": false }
  }
}
```

#### ❌ Common Errors
1. **USER_PROFILE_NOT_FOUND** - Chưa tạo profile
2. **NO_BUSINESS_ASSIGNED** - Chưa assign business
3. **SUBSCRIPTION_INACTIVE** - Hết hạn trial
4. **PERMISSION_DENIED** - Không có quyền

## 🔧 Step 6: Manual Testing Via SQL

### 6.1 Test User with Business Function
```sql
-- Replace 'your-user-uuid' with actual user ID
SELECT pos_mini_modular3_get_user_with_business_complete('your-user-uuid'::uuid);
```

### 6.2 Test Permission Check
```sql
-- Test permission for specific user and feature
SELECT pos_mini_modular3_check_user_permission(
  'your-user-uuid'::uuid,
  'products',
  'read'
);
```

### 6.3 Test Usage Stats Update
```sql
-- Test usage tracking
SELECT pos_mini_modular3_update_usage_stats(
  'your-business-uuid'::uuid,
  'products',
  1
);
```

### 6.4 Test Subscription Validation
```sql
-- Test subscription status validation
SELECT pos_mini_modular3_validate_subscription('your-business-uuid'::uuid);
```

## 🎯 Step 7: Integration Testing

### 7.1 Test Login Flow
1. **Login page** → Check if Enhanced Auth Service loads
2. **Dashboard redirect** → Verify permissions loaded
3. **Feature access** → Test actual permission gates

### 7.2 Test Permission Gates
```typescript
// In any component
import { PermissionGate } from '@/components/feature-gates/permission-gate';

<PermissionGate feature="products" action="write">
  <Button>Create Product</Button>
</PermissionGate>
```

### 7.3 Test Business Context
```typescript
// Check business context in components
const { business, permissions } = useEnhancedAuth();
```

## ⚠️ Troubleshooting

### Issue 1: Migration Failed
```sql
-- Check for existing functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_name LIKE 'pos_mini_modular3_%';

-- Drop if needed and re-run
DROP FUNCTION IF EXISTS pos_mini_modular3_get_user_with_business_complete(uuid);
```

### Issue 2: Permission Test Failed
```sql
-- Check role permissions data
SELECT * FROM pos_mini_modular3_role_permissions 
WHERE subscription_tier = 'free' AND user_role = 'owner';
```

### Issue 3: User Profile Not Found
```sql
-- Check user profiles
SELECT * FROM pos_mini_modular3_user_profiles 
WHERE id = 'your-user-uuid';

-- Create profile if missing (replace with your data)
INSERT INTO pos_mini_modular3_user_profiles (
  id, business_id, full_name, role, status
) VALUES (
  'your-user-uuid', 'your-business-uuid', 'Your Name', 'owner', 'active'
);
```

## ✅ Success Checklist

- [ ] Migration 004: Enhanced Auth Functions ✅
- [ ] Migration 005: Auth Access Functions ✅ 
- [ ] Migration 006: Product Management System ✅
- [ ] Migration 007: Product Functions ✅
- [ ] Test page loads without errors ✅
- [ ] User session loads successfully ✅
- [ ] Business context available ✅
- [ ] Permissions working correctly ✅
- [ ] Usage limits enforced ✅
- [ ] SQL functions responding ✅

## 🔄 Next Steps

After successful testing:
1. **Implement Product Management UI** using new functions
2. **Add Inventory Management** features
3. **Enhance Dashboard** with real permission checks
4. **Add Business Settings** management
5. **Implement Reports** with role-based access

---

**✨ Ready to test! Follow the steps in order for best results.**
