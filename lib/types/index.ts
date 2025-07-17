/**
 * 🎯 CENTRALIZED TYPE EXPORTS
 * Single source of truth for all type definitions
 */

// =============================================
// CORE DATABASE TYPES
// =============================================
export type { Database, Json } from './database.types'

// =============================================
// ENUM TYPES & SERVICE PATTERNS
// =============================================
export type {
  UserRole,
  UserStatus,
  ContactMethod,
  BusinessTypeEnum,
  BusinessStatusEnum,
  SubscriptionTier,
  SubscriptionStatus,
  ServiceResponse,
  DatabaseError,
  AppError,
  DatabaseFunctions,
  DatabaseFunctionName,
  DatabaseFunctionParams,
  DatabaseFunctionResult
} from './database.types'

// =============================================
// DATABASE TABLE TYPES
// =============================================
export type {
  BusinessType,
  Business,
  UserProfile,
  Product,
  ProductCategory,
  BusinessTypeCategoryTemplate,
  InsertBusiness,
  InsertUserProfile,
  InsertProduct,
  UpdateBusiness,
  UpdateUserProfile,
  UpdateProduct
} from './database.types'

// =============================================
// BUSINESS DOMAIN TYPES
// =============================================
export type {
  BusinessTypeWithCategory,
  CategoryTemplate,
  BusinessTypeCategoryData,
  BusinessTypeCategoryId
} from './business.types'

// Export constants for validation
export {
  BUSINESS_STATUSES,
  SUBSCRIPTION_TIERS,
  SUBSCRIPTION_STATUSES,
  USER_ROLES,
  CONTACT_METHODS,
  BUSINESS_TYPE_CATEGORIES
} from './business.types'

// Export validation functions
export {
  isValidBusinessStatus,
  isValidSubscriptionTier,
  isValidUserRole,
  isValidContactMethod,
  getBusinessTypeCategory,
  getBusinessTypesForCategory,
  formatBusinessCode,
  generateBusinessSlug
} from './business.types'

// =============================================
// SUBSCRIPTION TYPES
// =============================================
export type {
  SubscriptionPlan,
  BusinessSubscription,
  FeatureName,
  LimitType
} from './subscription.types'
