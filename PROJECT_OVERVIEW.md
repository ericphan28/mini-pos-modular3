# POS Mini Modular - Hệ thống POS cho Hộ Kinh Doanh Việt Nam

## 📋 Tổng quan Project

**POS Mini Modular** là hệ thống quản lý bán hàng hiện đại được thiết kế đặc biệt cho các hộ kinh doanh tại Việt Nam. Hệ thống được xây dựng với Next.js 15, TypeScript strict mode, và Supabase backend.

### 🎯 Mục tiêu chính
- Hỗ trợ multi-tenant POS system
- Enterprise-grade security và logging
- Giao diện tiếng Việt thân thiện
- High performance với session caching
- Real-time business analytics

### 🏗️ Tech Stack
- **Frontend**: Next.js 15 + TypeScript (strict mode)
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: React Context + Reducers
- **Logging**: Custom business logger với tracing
- **Authentication**: Supabase Auth với session caching

## 🚀 Trạng thái hiện tại (January 2025)

### ✅ Đã hoàn thành
1. **Authentication System** - Hoàn thiện với session management
2. **Dashboard Core** - Business analytics với real-time data
3. **Database Schema** - Optimized cho multi-tenant architecture
4. **Logging System** - Professional business logger với trace IDs
5. **UI Components** - Complete shadcn/ui setup với Vietnamese localization
6. **Performance Optimization** - AuthProvider optimization để tránh duplicate API calls

### 🔄 Đang phát triển
1. **POS Module** - Core selling functionality
2. **Inventory Management** - Stock tracking và management
3. **Staff Management** - Multi-user support với role-based permissions
4. **Reporting** - Advanced business reports

### 📁 Cấu trúc thư mục quan trọng

```
├── app/                          # Next.js 15 App Router
│   ├── auth/login/              # Authentication pages
│   ├── dashboard/               # Main dashboard
│   └── layout.tsx               # Root layout với AuthProvider
├── components/                   # Reusable UI components
│   ├── ui/                      # shadcn/ui components
│   └── auth/                    # Authentication components
├── lib/                         # Core utilities
│   ├── auth/                    # Authentication system
│   ├── logger/                  # Business logging system
│   ├── supabase/               # Database connections
│   └── utils/                   # Helper functions
├── supabase/                    # Database migrations
└── docs/                        # Documentation
```

## 🔧 Hệ thống Authentication

### Architecture
- **Server-side**: Supabase Auth với RLS policies
- **Client-side**: React Context với session caching
- **RPC Function**: `pos_mini_modular3_get_user_profile_safe`

### Recent Fix (January 2025)
Đã sửa lỗi "Failed to load user profile" bằng cách:
- Thêm `initialSessionData` prop vào AuthProvider
- Skip re-fetch khi đã có dữ liệu từ server
- Sử dụng consistent RPC function giữa dashboard và AuthProvider

### Usage
```tsx
// Layout.tsx - Backward compatible
<AuthProvider>
  {children}
</AuthProvider>

// Với initial data (future enhancement)
<AuthProvider initialSessionData={serverSessionData}>
  {children}
</AuthProvider>
```

## 📊 Business Logger System

### Features
- **Trace IDs**: Theo dõi request flow hoàn chỉnh
- **Performance Tracking**: Đo lường thời gian thực hiện
- **Business Context**: User ID + Business ID trong mọi log
- **Structured Logging**: JSON format với metadata

### Example Usage
```typescript
await businessLogger.performanceTrack(
  'GET_USER_PROFILE_SAFE',
  { business_id: 'xxx', user_id: 'yyy' },
  async () => {
    return await supabase.rpc('pos_mini_modular3_get_user_profile_safe', {
      p_user_id: userId
    });
  },
  { component: 'dashboard_page' }
);
```

## 🗄️ Database Schema

### Key Tables
- `pos_mini_modular3_profiles` - User profiles với business associations
- `pos_mini_modular3_businesses` - Multi-tenant business data
- `pos_mini_modular3_*` - Tất cả tables có prefix để tránh conflicts

### RPC Functions
- `pos_mini_modular3_get_user_profile_safe` - Main profile function
- `pos_mini_modular3_*` - Business logic functions

## 🚀 Development Workflow

### Getting Started
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

### Code Standards
- TypeScript strict mode enabled
- ESLint với custom rules
- No `any` types allowed
- Explicit return types required
- Vietnamese cho user-facing text

### Git Workflow
```bash
# Feature development
git checkout -b feature/ten-tinh-nang
git commit -m "feat: Thêm tính năng xxx"
git push origin feature/ten-tinh-nang

# Bug fixes
git commit -m "fix: Sửa lỗi yyy"

# Documentation
git commit -m "docs: Cập nhật documentation"
```

## 🐛 Common Issues & Solutions

### 1. Auth Provider Error
**Problem**: "Failed to load user profile"
**Solution**: Đã fix bằng initialSessionData prop và consistent RPC usage

### 2. Performance Issues
**Problem**: Dashboard load chậm
**Solution**: Server-side data passing và session caching

### 3. Database Connection
**Problem**: Supabase timeout
**Solution**: Connection pooling và retry logic

## 📚 Key Files để hiểu Project

1. **`app/layout.tsx`** - Root layout và AuthProvider setup
2. **`lib/auth/auth-context.tsx`** - Complete authentication system
3. **`app/dashboard/page.tsx`** - Main dashboard với business logic
4. **`lib/logger/index.ts`** - Business logging system
5. **`supabase/migrations/`** - Database schema definitions

## 🎯 Priorities cho tương lai

### Short-term (1-2 tháng)
1. Complete POS selling module
2. Inventory tracking system
3. Basic reporting dashboard

### Medium-term (3-6 tháng)
1. Advanced analytics
2. Mobile app support
3. Payment integration

### Long-term (6+ tháng)
1. Multi-location support
2. Advanced accounting integration
3. AI-powered business insights

---

## 🤖 **AI Assistant Context Guide**

> **CRITICAL SECTION**: Essential information cho AI assistant trong future development sessions

### 🎯 **Project Quick Identity**
- **Tên project**: POS Mini Modular (database prefix: `pos_mini_modular3_`)
- **Mục đích**: Multi-tenant POS system cho Vietnamese small businesses  
- **Phase hiện tại**: Core Development (auth ✅, dashboard ✅, POS module 🔄)
- **Ngôn ngữ**: Vietnamese UI, English code/comments

### 🔧 **Critical Technical Decisions**
1. **TypeScript strict mode** - NO any types allowed
2. **Next.js 15 App Router** - Server components by default
3. **Supabase với RLS** - All database security via row-level policies
4. **Session caching** - AuthProvider optimization để tránh duplicate calls
5. **Business logging** - Terminal output với structured trace IDs

### 🗃️ **Database Convention**
```typescript
// All functions/tables có prefix: pos_mini_modular3_
pos_mini_modular3_get_user_profile_safe()       // User profile RPC
pos_mini_modular3_get_user_with_business_complete() // Business context RPC
pos_mini_modular3_businesses                     // Business table
pos_mini_modular3_user_profiles                  // User profiles table
```

### 🔐 **Authentication Architecture**
- **Entry point**: `lib/auth/auth-context.tsx` (AuthProvider)
- **Server integration**: `app/layout.tsx` wraps entire app
- **Session flow**: Supabase Auth → User Profile → Business Association
- **Recent optimization**: initialSessionData prop để reuse server data
- **Common issue**: Ensure RPC function consistency between client/server

### 📊 **Features Currently Working**
```typescript
✅ Authentication: Login/logout với session management
✅ Dashboard: Real-time business metrics display  
✅ User Profiles: Business association và role permissions
✅ Logging: Terminal output với color-coded structured logs
✅ Database: Complete schema với 7 migration files ready
```

### 🚧 **Development Patterns**
```typescript
// React components - EITHER omit return type OR import React
export default function Component() { }              // ✅ Recommended
import React from 'react';                           
export default function Component(): JSX.Element { } // ✅ Alternative

// Error handling - Always type catch blocks
try { } catch (error: unknown) { }                   // ✅ Required

// Database - Use RPC functions only
const { data } = await supabase.rpc('pos_mini_modular3_get_user_profile_safe')
```

### 📁 **Critical Files Context**
```typescript
lib/auth/auth-context.tsx          // 🔑 Main authentication system
app/dashboard/page.tsx             // 📊 Business dashboard logic
lib/logger/business-logger.ts      // 🪵 Logging infrastructure  
supabase/migrations/               // 🗃️ Database schema evolution
MIGRATION_INSTRUCTIONS.md         // 📋 Database deployment guide
```

### 🐛 **Recent Fixes Record**
- **AuthProvider "Failed to load user profile"** → Fixed: Unified RPC function usage
- **Dashboard performance 900ms+** → Optimized: Server data passing
- **Over-engineered hydration** → Simplified: Removed complex unnecessary files
- **Documentation scattered** → Consolidated: Comprehensive AI-friendly docs

### 🔄 **Standard Development Flow**
1. **Start**: `npm run dev` hoặc run task "test-optimized-system"
2. **Database changes**: Copy migration files → Supabase SQL Editor (NO CLI)
3. **Auth testing**: Visit `/test-enhanced-auth` endpoint  
4. **Debug**: Terminal logs với business logger structured output
5. **Deploy**: azure.yaml ready for AZD deployment

### ⚠️ **Critical "Don'ts" for Future Development**
```typescript
❌ NO: any types (TypeScript strict enforced)
❌ NO: npx supabase db push (use SQL Editor only)  
❌ NO: Direct table queries (use RPC functions)
❌ NO: Console.log in production (use business logger)
❌ NO: JSX.Element without React import
```

### 🎯 **Next Development Priorities**
1. **POS selling module** - Core transaction functionality
2. **Inventory management** - Stock tracking system
3. **Staff permissions** - Role-based access control
4. **Advanced reporting** - Business analytics expansion

**Note**: Project có foundation rất solid. Authentication và dashboard systems production-ready. AI assistant có thể confidently continue development with these established patterns.

---

**Note**: Project này đang được actively developed với focus on Vietnamese market needs. Authentication system đã stable, đang phát triển core business features.
