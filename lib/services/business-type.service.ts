/**
 * 🏪 BUSINESS TYPE MANAGEMENT SERVICE
 * Quản lý các loại hình kinh doanh và đồng bộ từ database
 */

import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/client'; // ✅ THÊM DÒNG NÀY

export interface BusinessType {
  value: string;
  label: string;
  description?: string;
  icon?: string;
  active: boolean;
  category?: string;
  sortOrder?: number;
}

export interface BusinessTypeStats {
  type: string;
  count: number;
  percentage: number;
}

export class BusinessTypeService {
  private static instance: BusinessTypeService;
  private cachedTypes: BusinessType[] | null = null;
  private lastCacheTime = 0;
  private readonly CACHE_DURATION = 10 * 60 * 1000; // 10 minutes

  static getInstance(): BusinessTypeService {
    if (!this.instance) {
      this.instance = new BusinessTypeService();
    }
    return this.instance;
  }

  /**
   * 📊 Lấy thống kê business types từ database
   */
  async getBusinessTypeStats(): Promise<BusinessTypeStats[]> {
    try {
      console.log('🔍 BusinessType: Fetching stats from database...');
      
      let adminClient;
      try {
        adminClient = createAdminClient();
      } catch (e) {
        console.warn('⚠️ BusinessType: Service role key missing, falling back to static types:', e);
        return []; // Trả về mảng rỗng để fallback về static types
      }
      
      const { data: businesses, error } = await adminClient
        .from('pos_mini_modular3_businesses')
        .select('business_type')
        .not('business_type', 'is', null);

      if (error) {
        console.error('❌ BusinessType: Error fetching stats:', error);
        return [];
      }

      console.log('📊 BusinessType: Raw business data:', businesses);

      // Đếm và tính phần trăm
      const typeCounts = businesses.reduce((acc: Record<string, number>, business) => {
        const type = business.business_type || 'unknown';
        acc[type] = (acc[type] || 0) + 1;
        return acc;
      }, {});

      const totalCount = businesses.length;
      const stats: BusinessTypeStats[] = Object.entries(typeCounts).map(([type, count]) => ({
        type,
        count,
        percentage: totalCount > 0 ? Math.round((count / totalCount) * 100) : 0
      }));

      console.log('✅ BusinessType: Calculated stats:', stats);
      return stats.sort((a, b) => b.count - a.count);

    } catch (error) {
      console.error('❌ BusinessType: Unexpected error in getBusinessTypeStats:', error);
      return [];
    }
  }

  /**
   * ✅ FIXED: Get business types - works for both authenticated and anonymous users
   */
  async getBusinessTypesFromDB(): Promise<BusinessType[]> {
    try {
      console.log('🔍 BusinessType: Fetching types (public access)...');
      
      // ✅ Use regular client (not admin) for public data
      const supabase = createClient();
      
      const { data: businessTypes, error } = await supabase
        .from('pos_mini_modular3_business_types')
        .select('*')
        .eq('is_active', true)
        .order('category, sort_order, label');

      if (error) {
        console.error('❌ BusinessType: Error fetching:', error);
        return this.getFallbackBusinessTypes();
      }

      console.log(`✅ BusinessType: Loaded ${businessTypes.length} types (public)`);
      
      this.cachedTypes = businessTypes.map(bt => ({
        value: bt.value,
        label: bt.label,
        description: bt.description,
        icon: bt.icon,
        active: bt.is_active,
        category: bt.category,
        sortOrder: bt.sort_order
      }));

      return this.cachedTypes;
      
    } catch (error) {
      console.error('❌ BusinessType: Unexpected error:', error);
      return this.getFallbackBusinessTypes();
    }
  }

  /**
   * 🔍 Get business types by category
   */
  async getBusinessTypesByCategory(): Promise<Record<string, BusinessType[]>> {
    const types = await this.getBusinessTypesFromDB();
    
    return types.reduce((acc, type) => {
      const category = type.category || 'other';
      if (!acc[category]) {
        acc[category] = [];
      }
      acc[category].push(type);
      return acc;
    }, {} as Record<string, BusinessType[]>);
  }

  /**
   * 🔧 Admin: Add new business type
   */
  async addBusinessType(typeData: Omit<BusinessType, 'active'>): Promise<boolean> {
    try {
      // ✅ Admin operations use admin client
      const adminClient = createAdminClient();
      
      const { error } = await adminClient
        .from('pos_mini_modular3_business_types')
        .insert({
          value: typeData.value,
          label: typeData.label,
          description: typeData.description,
          icon: typeData.icon,
          category: typeData.category || 'other',
          sort_order: typeData.sortOrder || 0,
          is_active: true
        });

      if (error) {
        console.error('❌ BusinessType: Error adding type:', error);
        return false;
      }

      this.clearCache();
      return true;
      
    } catch (error) {
      console.error('❌ BusinessType: Error adding type:', error);
      return false;
    }
  }

  /**
   * 🔧 Admin: Update business type
   */
  async updateBusinessType(value: string, updates: Partial<BusinessType>): Promise<boolean> {
    try {
      const adminClient = createAdminClient();
      
      const { error } = await adminClient
        .from('pos_mini_modular3_business_types')
        .update({
          label: updates.label,
          description: updates.description,
          icon: updates.icon,
          category: updates.category,
          sort_order: updates.sortOrder,
          is_active: updates.active,
          updated_at: new Date().toISOString()
        })
        .eq('value', value);

      if (error) {
        console.error('❌ BusinessType: Error updating type:', error);
        return false;
      }

      // Clear cache
      this.clearCache();
      console.log(`✅ BusinessType: Updated type: ${value}`);
      return true;
      
    } catch (error) {
      console.error('❌ BusinessType: Error updating type:', error);
      return false;
    }
  }

  /**
   * 🛡️ Fallback business types (if database fails)
   */
  private getFallbackBusinessTypes(): BusinessType[] {
    console.log('⚠️ BusinessType: Using fallback static types');
    return [
      { value: 'retail', label: '🏪 Bán lẻ', active: true, category: 'retail' },
      { value: 'restaurant', label: '🍽️ Nhà hàng', active: true, category: 'food' },
      { value: 'cafe', label: '☕ Quán cà phê', active: true, category: 'food' },
      { value: 'beauty', label: '💄 Làm đẹp', active: true, category: 'beauty' },
      { value: 'service', label: '🔧 Dịch vụ', active: true, category: 'service' },
      { value: 'other', label: '🏢 Khác', active: true, category: 'other' }
    ];
  }

  /**
   * 🔄 Clear cache
   */
  clearCache(): void {
    console.log('🗑️ BusinessType: Clearing cache');
    this.cachedTypes = null;
    this.lastCacheTime = 0;
  }

  /**
   * 📊 Get type by value
   */
  async getBusinessTypeByValue(value: string): Promise<BusinessType | null> {
    const types = await this.getBusinessTypesFromDB();
    return types.find(t => t.value === value) || null;
  }
}

// Export singleton
export const businessTypeService = BusinessTypeService.getInstance();