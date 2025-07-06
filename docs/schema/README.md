# Database Schema Documentation

## 📋 **Mục đích**

Folder này chứa các file schema reference để hỗ trợ GitHub Copilot và development team hiểu rõ cấu trúc database khi phát triển tính năng mới.

## 📁 **Cấu trúc Files**

### **Core Files:**
- **`latest_schema_reference.sql`** - 🎯 **Main reference cho Copilot**
  - Luôn được cập nhật với schema mới nhất
  - Chứa tables, functions, và development patterns
  - Copilot sẽ sử dụng file này để hiểu database structure

- **`complete_schema_[timestamp].sql`** - Backup schema đầy đủ theo thời gian
- **`tables_structure_[timestamp].sql`** - Chỉ table definitions (không có functions)

### **Generated Files (Auto-cleanup):**
- Chỉ giữ lại 5 files gần nhất của mỗi loại
- Tự động xóa files cũ để tiết kiệm dung lượng

## 🚀 **Cách sử dụng**

### **1. Auto Backup Schema cho Copilot:**
```powershell
# Chạy script tự động
.\scripts\backup_schema_for_copilot.ps1

# Với verbose output
.\scripts\backup_schema_for_copilot.ps1 -Verbose
```

### **2. Manual Backup:**
```powershell
# Schema only
$env:PGPASSWORD = "Ex8bngfrY9PVaHt5"
pg_dump --host=aws-0-ap-southeast-1.pooler.supabase.com --port=6543 --username=postgres.oxtsowfvjchelqdxcbhs --dbname=postgres --schema=public --schema-only --no-owner --no-privileges --file=docs/schema/manual_backup.sql
```

### **3. Development Workflow:**

#### **Trước khi develop feature mới:**
```powershell
# Update schema cho Copilot
.\scripts\backup_schema_for_copilot.ps1
```

#### **Sau khi thay đổi database schema:**
```powershell
# Update lại reference
.\scripts\backup_schema_for_copilot.ps1

# Commit changes
git add docs/schema/latest_schema_reference.sql
git commit -m "Update schema reference after [feature_name]"
```

## 🤖 **GitHub Copilot Integration**

### **Copilot sẽ sử dụng:**
- `latest_schema_reference.sql` để hiểu database structure
- Function signatures để suggest đúng parameters
- Table relationships để generate proper JOIN queries
- RLS patterns để suggest secure queries
- Common patterns section để generate consistent code

### **Ví dụ Copilot suggestions:**

#### **Khi tạo function mới:**
```sql
-- Copilot sẽ suggest đúng naming convention:
CREATE FUNCTION pos_mini_modular3_new_feature(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
```

#### **Khi query data:**
```sql
-- Copilot sẽ suggest business isolation:
SELECT * FROM pos_mini_modular3_businesses 
WHERE id = pos_mini_modular3_current_user_business_id();
```

#### **Khi check permissions:**
```sql
-- Copilot sẽ suggest permission patterns:
IF NOT pos_mini_modular3_can_access_user_profile($1) THEN
    RAISE EXCEPTION 'Access denied';
END IF;
```

## 📊 **Database Overview**

### **Core Tables:**
- `pos_mini_modular3_businesses` - Business information
- `pos_mini_modular3_user_profiles` - User profiles và roles
- `pos_mini_modular3_business_types` - Business type reference
- `pos_mini_modular3_subscription_plans` - Subscription tiers

### **Support Tables:**
- `pos_mini_modular3_business_invitations` - Staff invitation system
- `pos_mini_modular3_backup_*` - Backup management system

### **Common Roles:**
- `super_admin` - System administrator
- `household_owner` - Business owner
- `manager` - Business manager
- `seller` - Sales staff
- `accountant` - Accounting staff

### **Common Statuses:**
- `active` / `inactive` - User/business status
- `trial` / `active` / `expired` - Subscription status
- `pending` / `accepted` / `rejected` - Invitation status

## 🔒 **Security Patterns**

### **Row Level Security (RLS):**
- Tất cả tables đều enable RLS
- Business isolation qua `business_id`
- Super admin có access toàn bộ

### **Function Security:**
- Tất cả functions dùng `SECURITY DEFINER`
- Built-in permission checks
- Standardized error handling

## 🛠️ **Maintenance**

### **Regular Tasks:**
1. **Weekly:** Chạy schema backup
2. **After migration:** Update schema reference
3. **Before release:** Verify schema changes

### **Troubleshooting:**
```powershell
# Check if files are up to date
Get-ChildItem docs/schema/ | Sort-Object LastWriteTime -Descending

# Manual cleanup
Remove-Item docs/schema/complete_schema_*.sql | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-7) }
```

## 📈 **Best Practices**

### **For Developers:**
1. **Always reference** `latest_schema_reference.sql` trước khi code
2. **Follow naming conventions** trong schema
3. **Use common patterns** có sẵn trong reference
4. **Update schema** sau mỗi database change

### **For Copilot:**
1. Schema reference luôn được update
2. Patterns và examples rõ ràng
3. Function signatures đầy đủ
4. Security patterns consistent

---

**🎯 Mục tiêu: Giúp GitHub Copilot hiểu rõ database structure và generate code chính xác, an toàn cho project POS Mini Modular 3!**
