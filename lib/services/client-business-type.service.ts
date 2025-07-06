/**
 * 🏪 CLIENT-SAFE BUSINESS TYPE SERVICE
 * 
 * Phiên bản an toàn để sử dụng ở client-side của BusinessTypeService
 * Chỉ sử dụng static types, không kết nối đến database bằng service role
 */

import { BusinessType } from './business-type.service';

export class ClientBusinessTypeService {
  private static instance: ClientBusinessTypeService;
  
  static getInstance(): ClientBusinessTypeService {
    if (!this.instance) {
      this.instance = new ClientBusinessTypeService();
    }
    return this.instance;
  }

  /**
   * ✅ FIXED: Complete business types synced with database constraint
   * Database constraint: 31 business types
   */
  getBusinessTypes(): BusinessType[] {
    return [
      // 🛒 Retail & Commerce
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
      },

      // 🍽️ Food & Beverage
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
      },

      // 💄 Beauty & Wellness
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
        icon: '�',
        active: true
      },

      // 🏥 Healthcare
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
      },

      // 🎓 Education & Professional Services
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
        icon: '�',
        active: true
      },
      {
        value: 'real_estate',
        label: '🏘️ Bất động sản',
        description: 'Môi giới, tư vấn bất động sản',
        icon: '🏘️',
        active: true
      },

      // 🛠️ Technical & Repair Services
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
      },

      // 🎯 Entertainment & Hospitality
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

      // 🌾 Industrial & Agriculture
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

      // 🔧 General Services
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
    ];
  }

  /**
   * Kiểm tra loại hình kinh doanh có hợp lệ không
   */
  validateBusinessType(type: string): boolean {
    const types = this.getBusinessTypes();
    return types.some(t => t.value === type);
  }

  /**
   * Format nhãn loại hình kinh doanh
   */
  formatTypeLabel(type: string): string {
    const words = type.split('_').map(word => 
      word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
    );
    return words.join(' ');
  }
}

// Export singleton instance
export const clientBusinessTypeService = ClientBusinessTypeService.getInstance();
