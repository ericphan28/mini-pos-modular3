# DATABASE CONNECTION TEST GUIDE

## 📋 **Mô tả**

Scripts test kết nối database và debug các vấn đề authentication.

## 🚀 **Cách chạy Tests**

### **1. Test cơ bản với Anon Key**
```bash
# Chạy test kết nối database qua anon key
npm run test:db

# Hoặc chạy trực tiếp
node test-db-connection.js
```

**Kiểm tra:**
- ✅ Environment variables
- ✅ Supabase client creation
- ✅ Basic table access
- ✅ Auth system status
- ✅ RPC functions

### **2. Test nâng cao với Service Role**
```bash
# Chạy test chi tiết với service role key
npm run test:db-advanced

# Hoặc chạy trực tiếp  
node test-db-advanced.js
```

**Kiểm tra:**
- ✅ Admin client access
- ✅ Auth.users table access
- ✅ User existence check
- ✅ Business associations
- ✅ Login với credentials
- ✅ Database functions

### **3. Tạo Test User (nếu cần)**
```bash
# Tạo user cym_sunset@yahoo.com nếu chưa tồn tại
npm run test:create-user

# Hoặc chạy trực tiếp
node test-db-advanced.js create-user
```

## 🔍 **Kết quả mong đợi**

### **✅ Thành công**
```
✅ SUCCESS: Environment variables OK
✅ SUCCESS: Supabase client đã được tạo
✅ SUCCESS: Truy cập bảng businesses thành công
✅ SUCCESS: User tồn tại trong auth.users
✅ SUCCESS: Login thành công!
```

### **❌ Lỗi thường gặp**

#### **1. User không tồn tại**
```
⚠️ WARN: User cym_sunset@yahoo.com KHÔNG TỒN TẠI trong auth.users
```
**Giải pháp:** Chạy `npm run test:create-user`

#### **2. Mật khẩu sai**
```
❌ ERROR: Login thất bại - Invalid login credentials
```
**Giải pháp:** Kiểm tra lại mật khẩu hoặc reset password

#### **3. RLS Policy**
```
⚠️ WARN: Anon client không thể truy cập businesses (RLS)
```
**Giải pháp:** Bình thường, RLS bảo vệ data

#### **4. Business Association**
```
⚠️ WARN: User CHƯA ĐƯỢC GÁN VÀO BUSINESS NÀO
```
**Giải pháp:** Cần tạo business và gán user

## 🛠️ **Debug Commands**

### **Kiểm tra Environment**
```bash
# Kiểm tra env vars
echo $env:NEXT_PUBLIC_SUPABASE_URL
echo $env:SUPABASE_SERVICE_ROLE_KEY
```

### **Kiểm tra Network**
```bash
# Test kết nối đến Supabase
curl -I https://oxtsowfvjchelqdxcbhs.supabase.co
```

### **Manual SQL Check**
Chạy trong Supabase SQL Editor:
```sql
-- Kiểm tra user tồn tại
SELECT id, email, email_confirmed_at, created_at 
FROM auth.users 
WHERE email = 'cym_sunset@yahoo.com';

-- Kiểm tra business associations
SELECT ubr.*, b.name as business_name
FROM pos_mini_modular3_user_business_roles ubr
JOIN pos_mini_modular3_businesses b ON ubr.business_id = b.id
WHERE ubr.user_id IN (
  SELECT id FROM auth.users WHERE email = 'cym_sunset@yahoo.com'
);
```

## 📊 **Output Examples**

### **Successful Test Output**
```
🔵 INFO: Bắt đầu test kết nối database
✅ SUCCESS: Environment variables OK
✅ SUCCESS: Supabase client đã được tạo  
✅ SUCCESS: Truy cập bảng businesses thành công
✅ SUCCESS: Admin auth access OK
✅ SUCCESS: User tồn tại trong auth.users
✅ SUCCESS: Login thành công!
✅ SUCCESS: All tests completed
```

### **Failed Test Output**
```
🔵 INFO: Bắt đầu advanced database test
✅ SUCCESS: Clients created successfully
✅ SUCCESS: Admin auth access OK
⚠️ WARN: User cym_sunset@yahoo.com KHÔNG TỒN TẠI trong auth.users
❌ ERROR: Login thất bại - Invalid login credentials
⚠️ WARN: User CHƯA ĐƯỢC GÁN VÀO BUSINESS NÀO
```

## 🎯 **Troubleshooting**

### **1. Environment Issues**
- Kiểm tra `.env.local` có đúng keys
- Restart development server
- Clear Next.js cache

### **2. Network Issues**  
- Kiểm tra firewall/proxy
- Test kết nối trực tiếp đến Supabase URL
- Kiểm tra DNS resolution

### **3. Database Issues**
- Kiểm tra Supabase project status
- Verify database migrations
- Check RLS policies

### **4. Authentication Issues**
- Verify user exists trong auth.users
- Check email confirmation status
- Test password reset if needed

## 📱 **Quick Commands Summary**

```bash
# Test cơ bản
npm run test:db

# Test nâng cao  
npm run test:db-advanced

# Tạo user test
npm run test:create-user

# Kiểm tra logs
cat .next/cache/logs/database-test.log
```

## 💡 **Tips**

1. **Chạy test:db trước** để kiểm tra basic connection
2. **Nếu basic test OK**, chạy test:db-advanced cho detailed analysis  
3. **Nếu user không tồn tại**, chạy test:create-user
4. **Check Supabase Dashboard** để verify changes
5. **Monitor logs** để debug chi tiết

---

🔗 **Related Files:**
- `test-db-connection.js` - Basic connection test
- `test-db-advanced.js` - Advanced testing with auth
- `.env.local` - Environment configuration
- `lib/supabase/client.ts` - Supabase client setup
