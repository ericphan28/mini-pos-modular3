# COPILOT CODE GENERATION RULES - ALWAYS FOLLOW

## TypeScript Strict Rules (strict: true enabled)
- NO `any` type - use `unknown`, specific interfaces, or generics
- NO unused variables/imports - clean all imports and variables
- ALL functions MUST have explicit return types
- Handle null/undefined explicitly with proper type guards
- Use `Record<string, never>` instead of empty object type `{}`

## React/Next.js 15 Rules
- Client components need 'use client' directive at top
- useSearchParams()/useRouter() MUST be wrapped in Suspense boundary
- Use proper imports from 'next/navigation'
- Server components by default (no 'use client' unless hooks needed)
- **REACT TYPES: Either import React OR omit JSX.Element return type**
- For function components: `export default function Component() {` (NO JSX.Element)
- If using JSX.Element: MUST import React: `import React from 'react'`

## Error Handling
- catch blocks MUST have typed error parameter: `catch (error: unknown)`
- Use type narrowing for error handling: `if (error instanceof Error)`
- NO console.log in production code - use proper error handling

## Code Quality Standards
- Use `interface` over `type` for object shapes
- Prefer `readonly` arrays when data won't change
- Clean, production-ready code only
- Remove all unused imports and variables before suggesting code

## Project Context
- Next.js 15 + TypeScript + Supabase integration
- Path alias: `@/*` points to project root
- Multi-tenant POS system for Vietnamese market
- Use Vietnamese for user-facing text
- Enterprise-grade security and error handling required

## Database & SQL Management
- **ALWAYS use Supabase SQL Editor** instead of CLI commands
- Copy SQL scripts directly into Supabase Dashboard > SQL Editor > Run
- NO `npx supabase db push` or similar CLI commands
- All database functions/tables use `pos_mini_modular3_` prefix
- SQL scripts must be compatible with Supabase SQL Editor format
- Export SQL feature generates scripts for direct Supabase SQL Editor execution

## ESLint Compliance Requirements
- Code must pass all ESLint rules without warnings
- No @typescript-eslint/no-explicit-any violations
- No @typescript-eslint/no-unused-vars violations
- No missing return type annotations
- Proper React component typing with explicit props interfaces

## React Component Patterns:

### ✅ CORRECT - Omit JSX.Element:
```typescript
export default function MyComponent() {
  return <div>content</div>;
}
```

### ✅ CORRECT - With JSX.Element (requires React import):
```typescript
import React from 'react';

export default function MyComponent(): JSX.Element {
  return <div>content</div>;
}
```

### ❌ WRONG - JSX.Element without React import:
```typescript
export default function MyComponent(): JSX.Element {  // ERROR!
  return <div>content</div>;
}
```

### ✅ CORRECT - With props:
```typescript
interface Props {
  readonly title: string;
}

export default function MyComponent({ title }: Props) {
  return <div>{title}</div>;
}
```

## Function Return Types:
- React components: Omit return type OR import React for JSX.Element
- Async functions: `Promise<ReturnType>`
- Event handlers: `Promise<void>` or `void`
- Utility functions: Explicit return type always required

## Import Patterns:
- React hooks: `import { useState, useEffect } from 'react'`
- Next.js: `import { useRouter } from 'next/navigation'`
- Supabase: `import { createClient } from '@/lib/supabase/client'`
- UI components: `import { Button } from '@/components/ui/button'`

**CRITICAL**: Always choose either NO return type OR proper React import for JSX.Element!
