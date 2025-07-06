# 🔍 Schema Inventory - GitHub Copilot Reference

## 🗄️ Available Database Components

### Tables
- `pos_mini_modular3_businesses` - Core business data with subscription management
- `pos_mini_modular3_user_profiles` - User profiles extending auth.users
- `pos_mini_modular3_admin_credential_logs` - Admin action audit trail (NEW)
- `pos_mini_modular3_business_setup_progress` - Business onboarding tracking (NEW)
- `auth.users` - Supabase authentication table

### Functions (RPC callable)
- `pos_mini_modular3_super_admin_create_business_with_owner_accoun` - Legacy business creation
- `pos_mini_modular3_create_business_with_auth_simple` - Enhanced business creation (NEW)
- `pos_mini_modular3_super_admin_check_permission` - Super admin permission check
- `pos_mini_modular3_super_admin_get_business_registration_stats` - Dashboard statistics
- `generate_business_code` - Generate unique business codes (NEW)
- `get_default_business_settings` - Get default settings by tier (NEW)

### Views
- `pos_mini_modular3_super_admin_stats` - Dashboard statistics view
- `pos_mini_modular3_super_admin_businesses` - Business list with details

### Services (Type-safe)
- `BusinessRegistrationEnhancedService` - Main business creation service with logging
- `BusinessTypeService` - Dynamic business type management service
- `SupabaseRPCService` - Type-safe RPC wrapper (NEW)
- `SuperAdminService` - Admin-specific operations (NEW)
- `BusinessService` - Business utility operations (NEW)

## 🎯 Common Patterns

### Creating Business (Enhanced - Use This)
```typescript
// Pattern: Enhanced business creation with comprehensive logging
const service = BusinessRegistrationEnhancedService.getInstance();
const result = await service.createBusinessWithOwnerEnhanced({
  business_name: "Cửa hàng ABC",
  contact_method: "email",
  contact_value: "owner@example.com",
  owner_full_name: "Nguyễn Văn A",
  business_type: "retail",
  subscription_tier: "free",
  business_status: "trial",
  subscription_status: "trial",
  set_password: "securepassword123"
});
```

### Type-safe RPC Calls (NEW)
```typescript
// Pattern: Type-safe RPC with enhanced error handling
import { supabaseRPC } from '@/lib/services/supabase-rpc.service';

const result = await supabaseRPC.callFunction(
  'pos_mini_modular3_super_admin_check_permission',
  {},
  'browser' // or 'admin' for admin operations
);

if (result.success) {
  const hasPermission = result.data; // Type-safe!
}
```

### Error Handling Pattern (Enhanced)
```typescript
// Pattern: Comprehensive error handling
if (!result.success) {
  console.error('Operation failed:', result.error);
  
  if (result.appError) {
    // Handle structured error
    switch (result.appError.severity) {
      case 'critical':
        // Show error modal
        break;
      case 'medium':
        // Show toast notification
        break;
      default:
        // Log only
    }
  }
  
  return { success: false, error: result.error };
}
```

### Checking Permissions (Enhanced)
```typescript
// Pattern: Enhanced permission checking
import { superAdminService } from '@/lib/services/supabase-rpc.service';

const hasPermission = await superAdminService.checkPermission();
if (!hasPermission) {
  return { success: false, error: 'Unauthorized' };
}
```

## ⚠️ DO NOT CREATE
These components already exist. Use them instead of creating new ones:

### ❌ Don't Create These Functions
- Business creation functions (use existing)
- Admin permission checks (use SuperAdminService)
- Business code generation (use BusinessService)
- User profile management (use existing tables)

### ❌ Don't Create These Services
- Basic Supabase clients (use enhanced RPC service)
- Error handlers (use existing ErrorHandler)
- Validation schemas (extend existing Zod schemas)

### ❌ Don't Create These Types
- Database interfaces (use types from database-schema.types.ts)
- Error types (use AppError from types)
- RPC function signatures (already defined)

## ✅ RECOMMENDED PATTERNS

### For New Features
1. **Check existing components first** using schema inventory
2. **Extend existing services** rather than creating new ones
3. **Use type-safe RPC service** for database operations
4. **Follow Vietnamese business context** in naming and messages
5. **Use enhanced error handling** patterns

### For Database Operations
1. **Use SuperAdminService** for admin operations
2. **Use BusinessService** for business utilities
3. **Use SupabaseRPCService** for custom RPC calls
4. **Check function exists** before calling new functions

### For Validation
1. **Extend existing Zod schemas** rather than creating new ones
2. **Use smart auto-correction** patterns for contact methods
3. **Follow Vietnamese phone/email** format validation
4. **Include meaningful error messages** in Vietnamese

This inventory helps GitHub Copilot suggest accurate, consistent code that follows established patterns.
