# 🚀 Quick Reference - GitHub Copilot Shortcuts

## 🎯 Instant Commands

### Enhanced Business Creation (RECOMMENDED)
```typescript
// Copilot can auto-complete this entire enhanced flow
import { BusinessRegistrationEnhancedService } from '@/lib/services/business-registration-enhanced.service';

const service = BusinessRegistrationEnhancedService.getInstance();
const result = await service.createBusinessWithOwnerEnhanced({
  business_name: "Tạp hóa ABC",
  contact_method: "email", // or "phone"
  contact_value: "owner@example.com",
  owner_full_name: "Nguyễn Văn A",
  business_type: "retail", // "restaurant", "service", "wholesale"
  subscription_tier: "free", // "basic", "premium"
  business_status: "trial", // "active", "suspended", "closed"
  subscription_status: "trial", // "active", "suspended", "cancelled"
  set_password: "securepassword123" // optional
});

if (result.success) {
  console.log('Business created:', result.business_code);
  console.log('Session ID:', result.sessionId);
  console.log('Process duration:', result.duration, 'ms');
  
  if (result.user_created) {
    console.log('Owner account created:', result.user_id);
    console.log('Contact method:', result.contact_method, '-', result.contact_value);
  }
}
```

### Type-safe RPC Calls
```typescript
// Enhanced RPC service with type safety
import { supabaseRPC, superAdminService } from '@/lib/services/supabase-rpc.service';

// Check admin permission
const hasPermission = await superAdminService.checkPermission();

// Get business statistics
const statsResult = await superAdminService.getBusinessStats();
if (statsResult.success) {
  const stats = statsResult.data; // Type-safe access
}

// Custom RPC call
const result = await supabaseRPC.callFunction(
  'pos_mini_modular3_function_name',
  { p_param1: 'value1' },
  'admin' // client type
);
```

### Error Handling Pattern
```typescript
// Comprehensive error handling
if (!result.success) {
  // User-friendly error message
  toast.error('Lỗi', { description: result.error });
  
  // Technical error for logging
  if (result.appError) {
    console.error(`[${result.appError.code}] ${result.appError.technicalMessage}`);
    
    // Handle by severity
    switch (result.appError.severity) {
      case 'critical':
        // System alert
        break;
      case 'high':
        // Error modal
        break;
      case 'medium':
        // Toast notification
        break;
      case 'low':
        // Silent log
        break;
    }
  }
}
```

### Smart Validation with Auto-correction
```typescript
// The existing Zod schema automatically handles:
// - Email/phone auto-detection
// - Vietnamese phone normalization (+84 format)
// - Contact method correction
// - Password strength validation

const validationResult = businessRegistrationSchema.safeParse(data);
if (!validationResult.success) {
  const errors = validationResult.error.errors.map(e => e.message);
  return { success: false, error: errors.join(', ') };
}

const correctedData = validationResult.data; // Auto-corrected data
```

## 📊 Available Database Views
- `pos_mini_modular3_super_admin_stats` - Dashboard statistics
- `pos_mini_modular3_super_admin_businesses` - Business list with details

## 🎯 Function Name Shortcuts (Auto-complete Ready)

### Super Admin Functions
```typescript
// Exact function names for Copilot autocomplete:
'pos_mini_modular3_super_admin_check_permission'
'pos_mini_modular3_super_admin_create_business_with_owner_accoun' // Legacy
'pos_mini_modular3_super_admin_get_business_registration_stats'
```

### Enhanced Functions (NEW)
```typescript
// New enhanced functions:
'pos_mini_modular3_create_business_with_auth_simple' // Recommended
'generate_business_code'
'get_default_business_settings'
```

## 🔧 Service Shortcuts

### Business Registration Service
```typescript
import { BusinessRegistrationEnhancedService } from '@/lib/services/business-registration-enhanced.service';

const service = BusinessRegistrationEnhancedService.getInstance();

// Enhanced method (RECOMMENDED)
await service.createBusinessWithCompleteAccount(data);

// Legacy method (fallback)
await service.createBusinessWithOwner(data);

// Utility methods
await service.isSuperAdmin();
await service.getRegistrationStats();
```

### Enhanced Services (NEW)
```typescript
import { 
  supabaseRPC, 
  superAdminService, 
  businessService 
} from '@/lib/services/supabase-rpc.service';

// Super Admin operations
await superAdminService.checkPermission();
await superAdminService.getBusinessStats();
await superAdminService.createBusinessWithAuth(params);

// Business utilities
await businessService.generateCode();
await businessService.getDefaultSettings(type, tier);

// Generic RPC calls
await supabaseRPC.callFunction(functionName, params, clientType);
```

## 🌍 Vietnamese Business Context

### Business Types (Vietnamese)
```typescript
type BusinessType = 
  | 'retail'     // Cửa hàng bán lẻ
  | 'restaurant' // Nhà hàng, quán ăn
  | 'service'    // Dịch vụ
  | 'wholesale'; // Bán sỉ
```

### Contact Methods
```typescript
type ContactMethod = 'email' | 'phone';

// Auto-detection examples:
// Input: "0909123456" + method: "email" → Auto-corrected to method: "phone"
// Input: "test@example.com" + method: "phone" → Auto-corrected to method: "email"
// Input: "0909123456" → Normalized to "+84909123456"
```

### Subscription Tiers
```typescript
type SubscriptionTier = 'free' | 'basic' | 'premium';

// Free: 30 days trial, 3 users, 50 products
// Basic: Paid tier, more features
// Premium: Full features, unlimited
```

## 🔒 Security Patterns

### Client Types
```typescript
// Use appropriate client for security:
'browser' // Client-side with RLS, user session
'server'  // Server-side with RLS, user session
'admin'   // Service role, bypasses RLS (admin only)
```

### Permission Checking
```typescript
// Always check permissions before admin operations
const hasPermission = await superAdminService.checkPermission();
if (!hasPermission) {
  return { success: false, error: 'Unauthorized' };
}
```

This quick reference enables GitHub Copilot to generate accurate, consistent code that follows all established patterns and Vietnamese business context.
