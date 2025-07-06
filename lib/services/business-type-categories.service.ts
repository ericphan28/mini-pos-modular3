/**
 * 🏪 BUSINESS TYPE CATEGORIES SERVICE
 * 
 * Quản lý các nhóm loại hình kinh doanh để hiển thị UI dễ dàng hơn
 * Phân chia 31 business types thành 7 categories logic
 */

import { BusinessType } from './business-type.service';

export interface BusinessTypeCategory {
  id: string;
  name: string;
  icon: string;
  description: string;
  types: BusinessType[];
}

export class BusinessTypeCategoriesService {
  private static instance: BusinessTypeCategoriesService;
  
  static getInstance(): BusinessTypeCategoriesService {
    if (!this.instance) {
      this.instance = new BusinessTypeCategoriesService();
    }
    return this.instance;
  }

  /**
   * 📋 Lấy tất cả categories với business types
   */
  getBusinessTypeCategories(): BusinessTypeCategory[] {
    return [
      {
        id: 'retail_commerce',
        name: 'Bán hàng & Thương mại',
        icon: '🛒',
        description: 'Cửa hàng, bán lẻ, bán sỉ, thời trang',
        types: [
          {
            value: 'retail',
            label: '🏪 Bán lẻ',
            description: 'Cửa hàng bán lẻ, siêu thị mini, tạp hóa',
            icon: '🏪',
            active: true
          },
          {
            value: 'wholesale',
            label: '📦 Bán sỉ',
            description: 'Bán sỉ, phân phối hàng hóa',
            icon: '📦',
            active: true
          },
          {
            value: 'fashion',
            label: '👗 Thời trang',
            description: 'Quần áo, giày dép, phụ kiện thời trang',
            icon: '👗',
            active: true
          },
          {
            value: 'electronics',
            label: '📱 Điện tử',
            description: 'Điện thoại, máy tính, thiết bị điện tử',
            icon: '📱',
            active: true
          }
        ]
      },
      {
        id: 'food_beverage',
        name: 'Ẩm thực & Đồ uống',
        icon: '🍽️',
        description: 'Nhà hàng, quán cà phê, dịch vụ ăn uống',
        types: [
          {
            value: 'restaurant',
            label: '🍽️ Nhà hàng',
            description: 'Nhà hàng, quán ăn, fast food',
            icon: '🍽️',
            active: true
          },
          {
            value: 'cafe',
            label: '☕ Quán cà phê',
            description: 'Cà phê, trà sữa, đồ uống',
            icon: '☕',
            active: true
          },
          {
            value: 'food_service',
            label: '🍱 Dịch vụ ăn uống',
            description: 'Catering, giao đồ ăn, suất ăn công nghiệp',
            icon: '🍱',
            active: true
          }
        ]
      },
      {
        id: 'beauty_wellness',
        name: 'Làm đẹp & Sức khỏe',
        icon: '💄',
        description: 'Spa, salon, gym, chăm sóc sức khỏe',
        types: [
          {
            value: 'beauty',
            label: '💄 Làm đẹp',
            description: 'Mỹ phẩm, làm đẹp, chăm sóc da',
            icon: '💄',
            active: true
          },
          {
            value: 'spa',
            label: '🧖‍♀️ Spa',
            description: 'Spa, massage, thư giãn',
            icon: '🧖‍♀️',
            active: true
          },
          {
            value: 'salon',
            label: '💇‍♀️ Salon',
            description: 'Cắt tóc, tạo kiểu, làm nail',
            icon: '💇‍♀️',
            active: true
          },
          {
            value: 'gym',
            label: '💪 Gym & Thể thao',
            description: 'Phòng gym, yoga, thể dục thể thao',
            icon: '💪',
            active: true
          }
        ]
      },
      {
        id: 'healthcare',
        name: 'Y tế & Chăm sóc sức khỏe',
        icon: '🏥',
        description: 'Phòng khám, nhà thuốc, dịch vụ y tế',
        types: [
          {
            value: 'healthcare',
            label: '🏥 Y tế',
            description: 'Dịch vụ y tế, chăm sóc sức khỏe',
            icon: '🏥',
            active: true
          },
          {
            value: 'pharmacy',
            label: '💊 Nhà thuốc',
            description: 'Hiệu thuốc, dược phẩm',
            icon: '💊',
            active: true
          },
          {
            value: 'clinic',
            label: '🩺 Phòng khám',
            description: 'Phòng khám tư, chuyên khoa',
            icon: '🩺',
            active: true
          }
        ]
      },
      {
        id: 'professional_services',
        name: 'Dịch vụ chuyên nghiệp',
        icon: '💼',
        description: 'Giáo dục, tư vấn, tài chính, bất động sản',
        types: [
          {
            value: 'education',
            label: '🎓 Giáo dục',
            description: 'Trung tâm dạy học, đào tạo',
            icon: '🎓',
            active: true
          },
          {
            value: 'consulting',
            label: '💼 Tư vấn',
            description: 'Dịch vụ tư vấn, chuyên môn',
            icon: '💼',
            active: true
          },
          {
            value: 'finance',
            label: '💰 Tài chính',
            description: 'Dịch vụ tài chính, bảo hiểm',
            icon: '💰',
            active: true
          },
          {
            value: 'real_estate',
            label: '🏘️ Bất động sản',
            description: 'Môi giới, tư vấn bất động sản',
            icon: '🏘️',
            active: true
          }
        ]
      },
      {
        id: 'technical_services',
        name: 'Dịch vụ kỹ thuật',
        icon: '🔧',
        description: 'Sửa chữa, xây dựng, vệ sinh',
        types: [
          {
            value: 'automotive',
            label: '🚗 Ô tô',
            description: 'Sửa chữa, bảo dưỡng ô tô, xe máy',
            icon: '🚗',
            active: true
          },
          {
            value: 'repair',
            label: '🔧 Sửa chữa',
            description: 'Sửa chữa điện tử, đồ gia dụng',
            icon: '🔧',
            active: true
          },
          {
            value: 'cleaning',
            label: '🧹 Vệ sinh',
            description: 'Dịch vụ vệ sinh, dọn dẹp',
            icon: '🧹',
            active: true
          },
          {
            value: 'construction',
            label: '🏗️ Xây dựng',
            description: 'Xây dựng, sửa chữa nhà cửa',
            icon: '🏗️',
            active: true
          }
        ]
      },
      {
        id: 'entertainment_industrial',
        name: 'Giải trí & Công nghiệp',
        icon: '🎉',
        description: 'Du lịch, khách sạn, sản xuất, nông nghiệp',
        types: [
          {
            value: 'travel',
            label: '✈️ Du lịch',
            description: 'Tour du lịch, dịch vụ lữ hành',
            icon: '✈️',
            active: true
          },
          {
            value: 'hotel',
            label: '🏨 Khách sạn',
            description: 'Khách sạn, nhà nghỉ, homestay',
            icon: '🏨',
            active: true
          },
          {
            value: 'entertainment',
            label: '🎉 Giải trí',
            description: 'Karaoke, game, sự kiện',
            icon: '🎉',
            active: true
          },
          {
            value: 'sports',
            label: '⚽ Thể thao',
            description: 'Sân thể thao, dụng cụ thể thao',
            icon: '⚽',
            active: true
          },
          {
            value: 'agriculture',
            label: '🌾 Nông nghiệp',
            description: 'Nông sản, thủy sản, chăn nuôi',
            icon: '🌾',
            active: true
          },
          {
            value: 'manufacturing',
            label: '🏭 Sản xuất',
            description: 'Sản xuất, gia công, chế biến',
            icon: '🏭',
            active: true
          },
          {
            value: 'logistics',
            label: '🚚 Vận chuyển',
            description: 'Vận chuyển, giao hàng, logistics',
            icon: '🚚',
            active: true
          },
          {
            value: 'service',
            label: '🔧 Dịch vụ tổng hợp',
            description: 'Các dịch vụ khác',
            icon: '🔧',
            active: true
          },
          {
            value: 'other',
            label: '📋 Khác',
            description: 'Loại hình kinh doanh khác',
            icon: '📋',
            active: true
          }
        ]
      }
    ];
  }

  /**
   * 🔍 Tìm category chứa business type
   */
  findCategoryByBusinessType(businessType: string): BusinessTypeCategory | null {
    const categories = this.getBusinessTypeCategories();
    return categories.find(category => 
      category.types.some(type => type.value === businessType)
    ) || null;
  }

  /**
   * 📊 Lấy tất cả business types dạng flat list
   */
  getAllBusinessTypes(): BusinessType[] {
    const categories = this.getBusinessTypeCategories();
    return categories.flatMap(category => category.types);
  }

  /**
   * ✅ Validate business type
   */
  validateBusinessType(type: string): boolean {
    const allTypes = this.getAllBusinessTypes();
    return allTypes.some(t => t.value === type);
  }

  /**
   * 🏷️ Lấy thông tin business type
   */
  getBusinessTypeInfo(type: string): BusinessType | null {
    const allTypes = this.getAllBusinessTypes();
    return allTypes.find(t => t.value === type) || null;
  }

  /**
   * 📋 Lấy danh sách business types cho Select component
   */
  getBusinessTypesForSelect(): Array<{ value: string; label: string; category: string }> {
    const categories = this.getBusinessTypeCategories();
    const result: Array<{ value: string; label: string; category: string }> = [];
    
    categories.forEach(category => {
      category.types.forEach(type => {
        result.push({
          value: type.value,
          label: type.label,
          category: category.name
        });
      });
    });
    
    return result;
  }
}

// Export singleton
export const businessTypeCategoriesService = BusinessTypeCategoriesService.getInstance();
