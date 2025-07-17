import type { BusinessType, Business, BusinessTypeCategoryTemplate } from './database.types'
import type { 
  BusinessStatusEnum, 
  SubscriptionTier, 
  UserRole, 
  ContactMethod 
} from './database.types'

// Business Types with categories
export interface BusinessTypeWithCategory extends BusinessType {
  readonly categoryLabel: string
}

export interface BusinessData extends Business {
  readonly subscription?: SubscriptionData
  readonly owner?: UserProfileData
  readonly stats?: BusinessStats
}

export interface SubscriptionData {
  readonly tier: string
  readonly status: string
  readonly startsAt: string
  readonly endsAt?: string
  readonly trialEndsAt?: string
  readonly maxUsers: number
  readonly maxProducts: number
  readonly features: readonly string[]
}

export interface UserProfileData {
  readonly id: string
  readonly fullName: string
  readonly email?: string
  readonly phone?: string
  readonly role: string
  readonly status: string
  readonly lastLoginAt?: string
}

export interface BusinessStats {
  readonly totalUsers: number
  readonly totalProducts: number
  readonly totalOrders: number
  readonly monthlyRevenue: number
  readonly storageUsed: number
}

export interface CreateBusinessData {
  readonly businessName: string
  readonly contactMethod: 'email' | 'phone'
  readonly contactValue: string
  readonly ownerFullName: string
  readonly businessType?: string
  readonly subscriptionTier?: string
  readonly businessStatus?: string
  readonly subscriptionStatus?: string
}

export interface BusinessRegistrationResult {
  readonly success: boolean
  readonly businessId?: string
  readonly ownerId?: string
  readonly businessCode?: string
  readonly message?: string
  readonly error?: string
}

export interface CategoryTemplate extends BusinessTypeCategoryTemplate {
  readonly subcategories?: readonly CategoryTemplate[]
}

export interface BusinessTypeCategoryData {
  readonly id: string
  readonly name: string
  readonly description?: string
  readonly icon?: string
  readonly types: readonly BusinessType[]
  readonly templates: readonly CategoryTemplate[]
}

// Constants
export const BUSINESS_STATUSES = [
  'trial',
  'active', 
  'suspended',
  'closed'
] as const

export const SUBSCRIPTION_TIERS = [
  'free',
  'basic',
  'premium', 
  'enterprise'
] as const

export const SUBSCRIPTION_STATUSES = [
  'trial',
  'active',
  'suspended',
  'expired',
  'cancelled'
] as const

export const USER_ROLES = [
  'super_admin',
  'household_owner',
  'manager',
  'seller',
  'accountant'
] as const

export const CONTACT_METHODS = [
  'email',
  'phone'
] as const

// Business type categories from database
export const BUSINESS_TYPE_CATEGORIES = [
  {
    id: 'retail_food' as const,
    name: 'Bán lẻ & Ẩm thực',
    description: 'Cửa hàng bán lẻ, nhà hàng, quán ăn',
    icon: '🏪',
    types: ['retail', 'wholesale', 'restaurant', 'cafe', 'food_service', 'grocery'] as const
  },
  {
    id: 'health_beauty' as const,
    name: 'Y tế & Làm đẹp',
    description: 'Dịch vụ chăm sóc sức khỏe và làm đẹp',
    icon: '💊',
    types: ['healthcare', 'pharmacy', 'clinic', 'beauty', 'spa', 'salon'] as const
  },
  {
    id: 'professional' as const,
    name: 'Dịch vụ chuyên nghiệp',
    description: 'Giáo dục, tư vấn, tài chính',
    icon: '💼',
    types: ['education', 'consulting', 'finance', 'real_estate'] as const
  },
  {
    id: 'lifestyle' as const,
    name: 'Thể thao & Giải trí',
    description: 'Gym, thể thao, du lịch, giải trí',
    icon: '🏋️',
    types: ['gym', 'sports', 'travel', 'hotel', 'entertainment'] as const
  },
  {
    id: 'industrial' as const,
    name: 'Sản xuất & Kỹ thuật',
    description: 'Sản xuất, sửa chữa, xây dựng',
    icon: '🔧',
    types: ['manufacturing', 'automotive', 'repair', 'construction', 'logistics'] as const
  }
] as const

export type BusinessTypeCategoryId = typeof BUSINESS_TYPE_CATEGORIES[number]['id']

// Validation functions
export function isValidBusinessStatus(status: string): status is BusinessStatusEnum {
  return BUSINESS_STATUSES.includes(status as BusinessStatusEnum)
}

export function isValidSubscriptionTier(tier: string): tier is SubscriptionTier {
  return SUBSCRIPTION_TIERS.includes(tier as SubscriptionTier)
}

export function isValidUserRole(role: string): role is UserRole {
  return USER_ROLES.includes(role as UserRole)
}

export function isValidContactMethod(method: string): method is ContactMethod {
  return CONTACT_METHODS.includes(method as ContactMethod)
}

// Helper functions
export function getBusinessTypeCategory(businessType: string): BusinessTypeCategoryId | null {
  for (const category of BUSINESS_TYPE_CATEGORIES) {
    if (category.types.includes(businessType as never)) {
      return category.id
    }
  }
  return null
}

export function getBusinessTypesForCategory(categoryId: BusinessTypeCategoryId): readonly string[] {
  const category = BUSINESS_TYPE_CATEGORIES.find(cat => cat.id === categoryId)
  return category?.types || []
}

export function formatBusinessCode(code: string): string {
  return code.toUpperCase().replace(/[^A-Z0-9]/g, '')
}

export function generateBusinessSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '-')
    .substring(0, 50)
}
