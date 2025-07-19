# 🚨 Permission System Rollback Guide

> **CRITICAL**: Hướng dẫn rollback hệ thống permissions khi gặp sự cố

## 📋 **Quick Rollback Commands**

### **1. Emergency User Rollback (Database)**
```sql
-- Rollback user về role seller (ít quyền nhất)
SELECT pos_mini_modular3_emergency_permission_rollback(
  'user_id_here'::UUID,
  'Emergency rollback due to security issue'
);

-- Rollback tất cả users trong business về seller
UPDATE pos_mini_modular3_user_profiles 
SET role = 'seller', updated_at = NOW()
WHERE business_id = 'business_id_here'::UUID
  AND role != 'household_owner'; -- Giữ nguyên owner
```

### **2. Disable Permission Feature (Frontend)**
```typescript
// File: hooks/use-permissions.ts
// Comment out permission checks để tạm thời disable
const hasPermission = useCallback((permission: string): boolean => {
  // EMERGENCY: Return true để bypass tất cả permission checks
  return true; 
  
  // Original logic (comment out)
  // if (!permissions.length) return false;
  // if (permissions.includes(permission)) return true;
  // ...
}, [permissions]);
```

### **3. Revert Login Form**
```typescript
// File: app/auth/login/page.tsx
// Thay thế LoginFormEnhanced bằng LoginForm cũ
import { LoginForm } from "@/components/login-form"; // OLD
// import { LoginFormEnhanced } from "@/components/auth/login-form-enhanced"; // NEW

export default function Page() {
  return (
    <div className="...">
      <LoginForm /> {/* ROLLBACK TO OLD */}
      {/* <LoginFormEnhanced /> NEW */}
    </div>
  );
}
```

## 🔄 **Database Rollback Steps**

### **Step 1: Backup Current State**
```sql
-- Backup current permissions before rollback
CREATE TABLE pos_mini_modular3_permissions_backup_$(date +%Y%m%d) AS 
SELECT * FROM pos_mini_modular3_user_profiles;

CREATE TABLE pos_mini_modular3_audit_backup_$(date +%Y%m%d) AS 
SELECT * FROM pos_mini_modular3_audit_logs WHERE created_at > NOW() - INTERVAL '1 DAY';
```

### **Step 2: Reset Permissions**
```sql
-- Reset all users to safe defaults
UPDATE pos_mini_modular3_user_profiles 
SET role = CASE 
  WHEN role = 'household_owner' THEN 'household_owner' -- Keep owners
  WHEN role = 'super_admin' THEN 'super_admin' -- Keep super admins  
  ELSE 'seller' -- Everyone else becomes seller
END,
updated_at = NOW()
WHERE role IS NOT NULL;

-- Log the rollback
INSERT INTO pos_mini_modular3_audit_logs (
  business_id, user_id, action, details, created_at
) VALUES (
  NULL, 
  auth.uid(), 
  'MASS_PERMISSION_ROLLBACK',
  jsonb_build_object(
    'reason', 'Emergency rollback',
    'timestamp', NOW(),
    'affected_users', (SELECT COUNT(*) FROM pos_mini_modular3_user_profiles)
  ),
  NOW()
);
```

### **Step 3: Disable Enhanced Functions**
```sql
-- Temporarily disable enhanced permission functions
ALTER FUNCTION pos_mini_modular3_get_user_with_permissions RENAME TO pos_mini_modular3_get_user_with_permissions_disabled;
ALTER FUNCTION pos_mini_modular3_check_permission_runtime RENAME TO pos_mini_modular3_check_permission_runtime_disabled;

-- Use fallback to old function
-- (Assumes pos_mini_modular3_get_user_with_business_complete still exists)
```

## 🛡️ **Frontend Rollback Steps**

### **Step 1: Disable Permission Hooks**
```typescript
// File: hooks/use-permissions.ts
// Add emergency bypass at the top of usePermissions()
export function usePermissions(): PermissionChecks {
  // 🚨 EMERGENCY BYPASS - REMOVE WHEN FIXED
  const EMERGENCY_BYPASS = true;
  
  if (EMERGENCY_BYPASS) {
    return {
      hasPermission: () => true,
      canAccess: {
        createProduct: true,
        editProduct: true,
        deleteProduct: true,
        // ... all permissions set to true
      },
      userRole: 'emergency_bypass',
      isOwner: false,
      isManager: false,
      isSuperAdmin: false,
      businessTier: 'basic',
      refreshPermissions: async () => {},
      emergencyRollback: async () => false
    };
  }
  
  // Original logic continues...
}
```

### **Step 2: Revert Auth Context**
```typescript
// File: lib/auth/auth-context.tsx
// Revert loadUserSession to use old RPC function
const { data: profileData, error: profileError } = await supabase.rpc(
  'pos_mini_modular3_get_user_with_business_complete', // OLD FUNCTION
  { p_user_id: user.id }
);

// Comment out new permission loading logic
const permissions: PermissionSet = {
  role: userData.user_role || 'viewer',
  permissions: [], // EMPTY - no permissions loaded
  features: [], // EMPTY - no features loaded
};
```

### **Step 3: Remove Permission Gates**
```typescript
// Temporarily disable all PermissionGate components
// Replace with simple div wrappers
<div>{children}</div> // Instead of <PermissionGate>
```

## 📞 **Emergency Contacts & Procedures**

### **Rollback Triggers:**
1. **Users cannot login** → Apply Frontend Step 1
2. **Permission errors in console** → Apply Database Step 3
3. **Complete system failure** → Apply all steps in order
4. **Security breach** → Database Step 2 + notify admin

### **Testing After Rollback:**
1. Test basic login with old form
2. Verify dashboard access works
3. Check that no permission errors appear
4. Confirm business functionality works

### **Recovery Plan:**
1. Fix the issue in development
2. Test thoroughly in staging
3. Gradually re-enable features
4. Monitor logs closely

## 🔍 **Monitoring & Verification**

### **Check System Health:**
```sql
-- Verify all users have valid roles
SELECT role, COUNT(*) 
FROM pos_mini_modular3_user_profiles 
GROUP BY role;

-- Check for permission errors in last hour
SELECT COUNT(*) 
FROM pos_mini_modular3_audit_logs 
WHERE action LIKE '%ERROR%' 
  AND created_at > NOW() - INTERVAL '1 HOUR';
```

### **Frontend Health Check:**
```javascript
// Console commands to verify
console.log('Auth context:', window.authContext);
console.log('Permission system:', window.permissions);
```

---

## ⚠️ **Important Notes**

- **Always backup before rollback**
- **Document the reason for rollback**
- **Test in staging first if possible**
- **Notify users about temporary restrictions**
- **Monitor system closely after rollback**

**Contact: System Administrator for emergency support** 🚨
