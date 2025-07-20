# CENTRALIZED PERMISSION SYSTEM - IMPLEMENTATION GUIDE

## 🏗️ KIẾN TRÚC TỔNG QUAN

### Architecture Layers
```
┌─────────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                          │
│  Route Guards → Component Guards → Feature Wrappers        │
├─────────────────────────────────────────────────────────────┤
│                PERMISSION LOGIC LAYER                       │
│  Permission Engine → Role Resolver → Business Logic        │
├─────────────────────────────────────────────────────────────┤
│               CONFIGURATION LAYER                           │
│  Route Config → Permission Maps → Business Rules           │
├─────────────────────────────────────────────────────────────┤
│                   DATA LAYER                               │
│  Database Schema → Auth Context → Cache Management         │
└─────────────────────────────────────────────────────────────┘
```

## 📊 DATABASE SCHEMA HIỆN CÓ

### Existing Tables (KHÔNG cần tạo thêm)
- ✅ `pos_mini_modular3_role_permissions` - Role permissions mapping
- ✅ `pos_mini_modular3_permissions` - Permission definitions  
- ✅ `pos_mini_modular3_businesses` - Business context
- ✅ `auth.users` - User authentication

### Existing RPC Functions (KHÔNG cần tạo thêm)
- ✅ `pos_mini_modular3_get_user_with_business_complete` - Complete user data

### Permission Data Structure (Hiện có)
```typescript
// Database returns format:
{
  "staff_management": { can_read: true, can_write: true, can_delete: true, can_manage: true },
  "financial_tracking": { can_read: true, can_write: true, can_delete: false, can_manage: true },
  "product_management": { can_read: true, can_write: true, can_delete: true, can_manage: true },
  // ... 7 features total for household_owner + free tier
}
```

## 📁 CẤU TRÚC FILE IMPLEMENTATION

### 🆕 Files cần TẠO MỚI

#### 1. Permission Engine Core
```
lib/permissions/
├── permission-engine.ts          ← Core permission processing logic
├── permission-types.ts           ← TypeScript definitions
├── permission-resolver.ts        ← Permission calculation logic
└── permission-cache.ts           ← Performance caching
```

#### 2. Configuration Layer
```
lib/permissions/configs/
├── route-permissions.ts          ← Route-level permission config
├── feature-permissions.ts        ← Component-level permissions
└── business-rules.ts             ← Business logic rules
```

#### 3. Guard Components
```
components/guards/
├── route-permission-guard.tsx    ← Global route protection
├── feature-permission-guard.tsx  ← Component protection
└── permission-wrapper.tsx        ← Micro-permissions
```

#### 4. Error Handling
```
components/errors/
├── permission-error-pages.tsx    ← Standardized error UX
└── permission-error-boundary.tsx ← Error boundaries
```

#### 5. Development Tools
```
components/dev/
├── permission-debugger.tsx       ← Debug panel (dev only)
└── permission-inspector.tsx      ← Permission inspection
```

### ✏️ Files cần MODIFY

#### 1. Auth Context Enhancement
```
lib/auth/auth-context.tsx          ← Extend with permission methods
```

#### 2. Layout Integration
```
app/layout.tsx                     ← Integrate route guard
```

#### 3. Existing Pages
```
app/dashboard/page.tsx             ← Add permission validation
app/products/page.tsx              ← Add permission checking
app/staff/page.tsx                 ← Add tier validation
```

## 🔧 IMPLEMENTATION SPECIFICATIONS

### 1. Permission Engine Core Logic

#### Route Permission Configuration
```typescript
interface RoutePermissionConfig {
  readonly path: string;
  readonly requiredPermissions: readonly string[];
  readonly requiredRole?: 'household_owner' | 'manager' | 'staff' | 'viewer';
  readonly minSubscriptionTier?: 'basic' | 'premium' | 'enterprise';
  readonly businessStatusRequired?: 'active';
}
```

#### Permission Resolution Algorithm
```
1. Authentication Check → User logged in?
2. Business Validation → Business active?
3. Subscription Tier Check → Meet minimum tier?
4. Role Authorization → Has required role?
5. Feature Permission Check → Has specific permissions?
6. Cache Result → Store for performance
```

### 2. Error Handling Strategy

#### Error Classification
- `AuthenticationRequired` - Not logged in
- `BusinessInactive` - Business not active
- `InsufficientRole` - Role too low
- `MissingPermissions` - Specific permissions missing
- `SubscriptionUpgradeRequired` - Tier too low

#### User Experience Flow
```
Error Detected → Classify Error → Show Appropriate Message → Suggest Action
```

### 3. Performance Optimization

#### Caching Strategy
- Session-level permission cache
- Route-level permission pre-computation
- Background permission warming
- Cache invalidation on role/business changes

#### Database Optimization
- Leverage existing RPC function
- No additional database queries needed
- Use auth context permission data

## 🎯 IMPLEMENTATION PHASES

### Phase 1: Core Infrastructure (Day 1-2)
1. **CREATE** `lib/permissions/permission-types.ts`
   - TypeScript interfaces for all permission types
   - Route configuration types
   - Error response types

2. **CREATE** `lib/permissions/permission-engine.ts`
   - Core permission checking logic
   - Integration with existing auth context
   - Cache management

3. **CREATE** `components/guards/route-permission-guard.tsx`
   - Global route protection component
   - Error page routing
   - Loading state management

4. **CREATE** `components/errors/permission-error-pages.tsx`
   - Standardized error components
   - User-friendly error messages
   - Upgrade prompts

### Phase 2: Configuration & Rules (Day 3)
1. **CREATE** `lib/permissions/configs/route-permissions.ts`
   - Route permission mappings
   - Based on existing database permissions
   - Progressive enhancement

2. **CREATE** `lib/permissions/configs/business-rules.ts`
   - Subscription tier rules
   - Business status validations
   - Role hierarchy definitions

3. **MODIFY** `app/layout.tsx`
   - Integrate RoutePermissionGuard
   - Maintain existing auth flow

### Phase 3: Component Guards (Day 4)
1. **CREATE** `components/guards/feature-permission-guard.tsx`
   - Component-level protection
   - Conditional rendering
   - Fallback handling

2. **CREATE** `components/guards/permission-wrapper.tsx`
   - Micro-permission wrapper
   - Button/link access control
   - Progressive disclosure

3. **MODIFY** existing pages
   - Add permission validation
   - Maintain current functionality

### Phase 4: Development Tools (Day 5)
1. **CREATE** `components/dev/permission-debugger.tsx`
   - Development debugging panel
   - Permission inspection
   - Role simulation

2. **CREATE** documentation and testing
   - Usage examples
   - Permission testing scenarios
   - Performance benchmarks

## 🛡️ SECURITY CONSIDERATIONS

### Input Validation
- All permission requests validated
- Type-safe permission checking
- SQL injection prevention (using existing RPC)

### Performance Security
- Rate limiting on permission checks
- Cache-based attack prevention
- Memory leak protection

### Business Logic Security
- Principle of least privilege
- Default deny, explicit grant
- Audit trail through existing logging

## 📈 INTEGRATION WITH EXISTING SYSTEM

### Auth Context Integration
- Extend existing `useAuth` hook
- Add `checkPermission` method enhancement
- Maintain backward compatibility

### Database Integration
- Use existing `pos_mini_modular3_get_user_with_business_complete` RPC
- No new database tables needed
- Leverage current permission structure

### UI Component Integration
- Seamless integration with existing components
- Maintain current design system
- Progressive enhancement approach

## 🔍 TESTING STRATEGY

### Unit Tests
- Permission engine logic
- Route configuration validation
- Error handling scenarios

### Integration Tests
- Auth context integration
- Database permission loading
- Cache performance testing

### User Acceptance Tests
- Permission denial flows
- Upgrade prompts
- Role-based access scenarios

## 📊 MONITORING & ANALYTICS

### Permission Metrics
- Access denial rates
- Permission check performance
- Cache hit rates
- User upgrade conversions

### Security Monitoring
- Failed access attempts
- Permission escalation attempts
- Anomalous access patterns

## 🎯 SUCCESS CRITERIA

### Functionality
- ✅ All routes protected by appropriate permissions
- ✅ Granular component-level permission control
- ✅ User-friendly error messages and upgrade flows
- ✅ Development debugging tools

### Performance
- ✅ Permission checks < 10ms average
- ✅ Cache hit rate > 90%
- ✅ No impact on existing page load times
- ✅ Memory usage within acceptable limits

### Security
- ✅ No unauthorized access possible
- ✅ All permission denials logged
- ✅ Secure by default implementation
- ✅ Audit trail maintained

### Developer Experience
- ✅ Clear permission configuration
- ✅ Easy to add new permissions
- ✅ Rich debugging tools
- ✅ Comprehensive documentation

---

## 🚀 READY FOR IMPLEMENTATION

Thiết kế này tận dụng:
- ✅ **Existing Database Schema** - Không cần tables mới
- ✅ **Current Auth Context** - Extend thay vì replace
- ✅ **Existing RPC Functions** - Tận dụng data hiện có
- ✅ **Current UI Components** - Progressive enhancement
- ✅ **Established Patterns** - Consistent với codebase

**Hệ thống này ready để implement với minimal disruption và maximum security.**