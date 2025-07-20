# 🧪 HƯỚNG DẪN TEST PERMISSION SYSTEM

## 📋 **OVERVIEW**
Hướng dẫn chi tiết để test Centralized Permission System với tài khoản `cym_sunset@yahoo.com`

## 🚀 **BƯỚC 1: KHỞI CHẠY SERVER**

1. **Development Server đã chạy:**
   - Server: `http://localhost:3001`
   - Status: ✅ Ready

2. **Kiểm tra trạng thái:**
   ```bash
   # Server sẽ hiển thị:
   ✓ Starting...
   ⚠ Port 3000 is in use, using available port 3001 instead.
   ```

## 🔐 **BƯỚC 2: TRUY CẬP TEST PAGE**

1. **Mở browser và truy cập:**
   ```
   http://localhost:3001/test-permissions
   ```

2. **Giao diện sẽ hiển thị:**
   - 🔒 Permission System Test Dashboard
   - Login form với email đã điền sẵn: `cym_sunset@yahoo.com`
   - Password field (cần nhập password)

## 🧪 **BƯỚC 3: TEST LOGIN & PERMISSION SYSTEM**

### **3.1 Authentication Test**
1. **Nhập password** cho tài khoản `cym_sunset@yahoo.com`
2. **Click "Login & Test Permission System"**
3. **Kiểm tra kết quả:**
   ```
   ✅ Authentication successful!
   ✅ Session loaded: cym_sunset@yahoo.com
   ✅ Business: [Business Name] (basic/premium/enterprise)
   ✅ Role: household_owner
   ✅ Features: 7 (staff, product, financial, report, pos, inventory, customer)
   ✅ Permissions: 25+ total
   ```

### **3.2 Permission Cache Test**
Sau khi login thành công:
1. **System Status** sẽ hiển thị:
   ```
   Authentication: ✅ Active
   Permission Cache: ✅ Loaded  
   Permission Loading: ✅ Ready
   Sync Status: ✅ Active
   ```

2. **Automatic Permission Tests** sẽ chạy và hiển thị:
   ```
   🧪 Running permission tests...
   ✅ Permission cache loaded
   ✅ User permissions: 7 features
   ✅ Subscription limits: X limits
   ```

### **3.3 Individual Permission Tests**
System sẽ test từng permission:
```
✅ Permission staff_view: ALLOWED
✅ Permission staff_create: ALLOWED
✅ Permission product_view: ALLOWED
✅ Permission financial_view: ALLOWED
❌ Permission super_admin_only: DENIED
```

### **3.4 Feature Access Tests**
```
✅ Feature staff: ACCESSIBLE
✅ Feature product: ACCESSIBLE  
✅ Feature financial: ACCESSIBLE
❌ Feature restricted_feature: RESTRICTED
```

### **3.5 Route Access Tests**
```
✅ Route /dashboard: ACCESSIBLE
✅ Route /staff: ACCESSIBLE
✅ Route /products: ACCESSIBLE
✅ Route /financial: ACCESSIBLE (nếu có permission)
```

## 🎣 **BƯỚC 4: TEST REACT HOOKS**

### **4.1 Live Hook Examples**
Giao diện sẽ hiển thị live data từ hooks:

**Staff Permissions:**
```
View: ✅ (từ useStaffPermissions.canViewStaff)
Create: ✅ (từ useStaffPermissions.canCreateStaff)  
Edit: ✅ (từ useStaffPermissions.canEditStaff)
Delete: ❌ (từ useStaffPermissions.canDeleteStaff)
```

**Product Permissions:**
```
View: ✅ (từ useProductPermissions.canViewProducts)
Create: ✅ (từ useProductPermissions.canCreateProducts)
Edit: ✅ (từ useProductPermissions.canEditProducts)
Delete: ❌ (từ useProductPermissions.canDeleteProducts)
```

**Feature Access:**
```
Staff: ✅ (từ hasFeatureAccess('staff'))
Product: ✅ (từ hasFeatureAccess('product'))
Financial: ✅ (từ hasFeatureAccess('financial'))
POS: ✅ (từ hasFeatureAccess('pos'))
```

## 🔄 **BƯỚC 5: TEST SYNC SYSTEM**

### **5.1 Manual Sync Test**
1. **Click "🔄 Manual Sync"** button
2. **Kiểm tra kết quả:**
   ```
   🔄 Syncing... (button disabled)
   → Background sync chạy
   → Permission cache refresh
   → ✅ Sync completed
   ```

### **5.2 Background Sync Monitoring**
- **Sync Status**: Active/Inactive
- **Auto-sync**: Chạy mỗi 5 phút
- **Error handling**: Retry logic nếu có lỗi

## 📊 **BƯỚC 6: KIỂM TRA CONSOLE LOGS**

### **6.1 Mở Developer Tools**
Press `F12` → Console tab

### **6.2 Kiểm tra Auth Logs**
```javascript
🔐 [AUTH CONTEXT] Loading user session for: [user-id]
🔐 [AUTH CONTEXT] RPC response: { userData, profileError }
🔐 [AUTH CONTEXT] Extracted data: { userInfo, businessInfo, permissionsInfo }
🔐 [AUTH CONTEXT] Business data validation: { businessId, subscriptionTier, status }
🔐 [AUTH CONTEXT] Processed permissions: { totalFeatures: 7, totalPermissions: 25 }
🔐 [AUTH CONTEXT] Session data saved successfully
🔐 [AUTH CONTEXT] Permission cache initialized
```

### **6.3 Kiểm tra Permission Logs**
```javascript
🔒 [PERMISSION PROVIDER] System initialized successfully
🔒 [PERMISSION ENGINE] Permission check: staff_view → ALLOWED
🔒 [PERMISSION BRIDGE] Cache generated for user: [user-id]
🔄 [PERMISSION SYNC] Sync completed successfully
```

## ✅ **EXPECTED RESULTS cho cym_sunset@yahoo.com**

### **User Profile:**
- **Email**: cym_sunset@yahoo.com
- **Role**: household_owner
- **Business**: [Business Name]
- **Subscription Tier**: free → mapped to 'basic'

### **Expected Permissions (Free Tier):**
```
Features (7): staff, product, financial, report, pos, inventory, customer
Permissions (~25): 
  - staff_view, staff_create, staff_edit
  - product_view, product_create, product_edit
  - financial_view, financial_basic_reports
  - report_view, report_basic
  - pos_access, pos_basic_operations
  - inventory_view, inventory_basic
  - customer_view, customer_basic
```

### **Route Access:**
```
✅ /dashboard - Always accessible
✅ /staff - Staff feature access
✅ /products - Product feature access  
✅ /financial - Financial feature access (basic)
✅ /pos - POS feature access (basic)
❌ /admin - Admin only (should be denied)
```

### **Subscription Limits (Free Tier):**
```
- Max staff: 5
- Max products: 100
- Max customers: 500
- Advanced reports: ❌ Disabled
- Multi-location: ❌ Disabled
- API access: ❌ Disabled
```

## 🚨 **COMMON ISSUES & TROUBLESHOOTING**

### **Issue 1: Authentication Failed**
```
❌ Login failed: Authentication failed
```
**Solution**: Kiểm tra password đúng cho tài khoản `cym_sunset@yahoo.com`

### **Issue 2: Permission Cache Not Loading**
```
⚠️ Permission cache not yet loaded
```
**Solution**: 
- Đợi 2-3 giây sau login
- Check console logs cho errors
- Try manual sync

### **Issue 3: Business Not Active**
```
❌ Business không active. Status: inactive
```
**Solution**: Kiểm tra business status trong database

### **Issue 4: Permission Count Mismatch**
```
⚠️ WARNING: Feature count mismatch for household_owner
Expected: 7, Actual: 5
```
**Solution**: Kiểm tra database permissions cho user này

## 🔍 **DEBUGGING TIPS**

### **1. Console Debugging**
```javascript
// Check auth state
console.log('Auth State:', useAuth());

// Check permission cache  
console.log('Permission Cache:', permissionCache);

// Test specific permission
console.log('Can view staff:', hasPermission('staff_view'));
```

### **2. Network Tab**
- Kiểm tra RPC calls đến Supabase
- Verify response data structure
- Check for API errors

### **3. Application Tab**
- Check localStorage for cached session
- Verify session data structure
- Check cache TTL

## 🎉 **SUCCESS CRITERIA**

Test được coi là **THÀNH CÔNG** khi:

1. ✅ **Authentication**: Login thành công với `cym_sunset@yahoo.com`
2. ✅ **Session Loading**: User data, business data, permissions load đúng
3. ✅ **Permission Cache**: Cache generation successful  
4. ✅ **Individual Permissions**: Các permission checks return đúng results
5. ✅ **Feature Access**: Feature access checks work correctly
6. ✅ **Route Protection**: Route access validation works
7. ✅ **React Hooks**: All permission hooks return expected values
8. ✅ **Sync System**: Manual và auto-sync work properly
9. ✅ **Error Handling**: Proper error messages và fallbacks
10. ✅ **Console Logs**: No errors, proper debug information

## 📝 **TEST CHECKLIST**

- [ ] Server running on localhost:3001
- [ ] Test page accessible at /test-permissions  
- [ ] Login successful với cym_sunset@yahoo.com
- [ ] Permission cache loaded (✅ status)
- [ ] Individual permission tests pass
- [ ] Feature access tests pass
- [ ] Route access tests pass  
- [ ] React hooks show correct values
- [ ] Manual sync works
- [ ] Console shows proper logs
- [ ] No errors in browser console
- [ ] All expected permissions present
- [ ] Subscription limits correct

## 🚀 **NEXT STEPS AFTER SUCCESSFUL TEST**

1. **Integration Testing**: Test trong actual app components
2. **Route Protection**: Implement route guards với canAccessRoute()
3. **Component Updates**: Update existing components với permission hooks
4. **Subscription Enforcement**: Implement subscription limit checking
5. **Performance Testing**: Test với multiple users và large datasets

---

**Happy Testing! 🧪✨**
