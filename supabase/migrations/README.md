# Supabase Migrations - POS Mini Modular 3

## Migration Files Structure

### Core System Migrations (Required)
- `001_business_subscription_system.sql` - Business subscription management
- `002_role_permissions_matrix.sql` - User roles and permissions  
- `003_admin_sessions.sql` - Admin session management
- `004_enhanced_auth_functions.sql` - Enhanced authentication functions ⭐

### Feature Migrations (Optional)
- `005_auth_access_functions.sql` - Auth schema access functions
- `006_product_management_system.sql` - Product and category tables
- `007_product_functions.sql` - Product management functions

### Utility Files
- `000_migration_guide.sql` - Master guide with instructions
- `000_run_all_migrations.sql` - Legacy comprehensive migration (deprecated)

## How to Run Migrations

### Method 1: Individual Migrations (Recommended)
1. Open Supabase Dashboard → SQL Editor
2. Copy content from each migration file in order:
   - Run `001_business_subscription_system.sql`
   - Run `002_role_permissions_matrix.sql`
   - Run `003_admin_sessions.sql`
   - Run `004_enhanced_auth_functions.sql` ⭐ **ESSENTIAL**
3. Optionally run feature migrations 005-007

### Method 2: Using Migration Guide
1. Open `000_migration_guide.sql`
2. Follow the instructions and verification queries

## Migration Status
✅ All core migrations (001-004) are tested and working
✅ Enhanced auth system is implemented and functional
✅ All files follow consistent naming convention

## Important Notes
- Migration 004 is **ESSENTIAL** for the enhanced auth system
- All migrations are idempotent (safe to run multiple times)
- Always run migrations in order: 001 → 002 → 003 → 004
- Feature migrations (005-007) can be run as needed

## Testing
Run the enhanced auth test page at `/test-enhanced-auth` to verify the system after migration 004.

## ✅ File migration chính: `001_complete_schema.sql`

**Nội dung gộp từ 12+ migrations cũ:**

### 🏗️ **Core Schema (v3.0.0)**
- `pos_mini_modular3_businesses` - Bảng hộ kinh doanh (multi-tenant)
- `pos_mini_modular3_user_profiles` - Hồ sơ người dùng (role-based) 
- `pos_mini_modular3_business_invitations` - Mời nhân viên
- `pos_mini_modular3_subscription_plans` - Gói dịch vụ

### 🔧 **Enhanced Functions**
- ✅ `pos_mini_modular3_create_business_with_contact()` - Tạo hộ KD với email/phone
- ✅ `pos_mini_modular3_create_business_owner()` - Đăng ký chủ hộ
- ✅ `pos_mini_modular3_create_super_admin()` - Tạo super admin
- ✅ `pos_mini_modular3_invite_staff_member()` - Mời nhân viên
- ✅ `pos_mini_modular3_accept_invitation()` - Chấp nhận lời mời

### 🛡️ **Security & RLS**
- Row Level Security (RLS) policies hoàn chỉnh
- Multi-tenant data isolation
- Role-based access control

### 🇻🇳 **Vietnamese Localization**
- Vietnamese phone number validation (+84, 0x format)
- Business types: retail, restaurant, service, wholesale
- Subscription tiers with VND pricing

## 📦 Backup migrations

Tất cả migrations cũ đã được backup trong thư mục `migrations_backup_20250630_150415/`:

- `001_cores_schema.sql` (original)
- `002_subscription_tiers.sql`
- `003_fix_rls_recursion.sql`
- `005_super_admin_management.sql`
- `005_super_admin_management_FIXED.sql`
- `006_final_rls_fix.sql`
- `007_fix_rls_permissions.sql`
- `008_fix_subscription_tier.sql`
- `009_add_phone_support.sql`
- `20241224000000_enhanced_business_functions.sql`
- `20241224000001_create_enhanced_tables.sql`
- `20241224000002_seed_enhanced_data.sql`

## 🚀 Deployment

### Fresh database (khuyến nghị):
```bash
supabase db reset
```

### Production deployment:
```bash
supabase db push
```

## ✨ Lợi ích của việc gộp migrations

1. **✅ Nhất quán** - Một file duy nhất, dễ quản lý
2. **🚀 Performance** - Deploy nhanh hơn (1 transaction thay vì 12+)
3. **🔧 Maintenance** - Dễ debug và troubleshoot
4. **📝 Documentation** - Self-documented với comments đầy đủ
5. **🛡️ Reliability** - Giảm risk conflict giữa migrations

## 🎯 Version Information

- **Schema Version**: 3.0.0
- **Migration Date**: 2025-06-30
- **Environment**: Production Ready
- **Features**: Complete POS system with multi-tenant architecture

---

*Được tạo bởi POS Mini Modular 3 Vietnam development team*
