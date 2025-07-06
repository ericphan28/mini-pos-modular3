'use client';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectGroup, SelectItem, SelectLabel, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from '@/hooks/use-toast';
import { BusinessType, businessTypeService } from '@/lib/services/business-type.service';
import { Eye, EyeOff } from 'lucide-react';
import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

// 🎯 PERFORMANCE: Type definitions
interface FormData {
  business_name: string;
  business_type: string;
  contact_method: 'email' | 'phone';
  contact_value: string;
  owner_full_name: string;
  subscription_tier: string;
  business_status: string;
  subscription_status: string;
  set_password: boolean;
  password: string;
}

// 🎯 PERFORMANCE: Status mappings with emojis
const STATUS_MAPPINGS = {
  business: {
    'trial': { text: '🆓 Thử nghiệm', label: 'thử nghiệm' },
    'active': { text: '✅ Hoạt động', label: 'hoạt động' },
    'inactive': { text: '⏸️ Tạm ngưng', label: 'tạm ngưng' },
    'suspended': { text: '⚠️ Tạm ngưng thanh toán', label: 'tạm ngưng do không thanh toán' },
    'cancelled': { text: '❌ Đã hủy', label: 'đã hủy' }
  },
  subscription: {
    'trial': { text: '🆓 Thử nghiệm', label: 'thử nghiệm' },
    'active': { text: '✅ Hoạt động', label: 'hoạt động' },
    'inactive': { text: '⏸️ Tạm ngưng', label: 'tạm ngưng' },
    'suspended': { text: '⚠️ Tạm ngưng thanh toán', label: 'tạm ngưng do không thanh toán' },
    'cancelled': { text: '❌ Đã hủy', label: 'đã hủy' }
  }
} as const;

// 🚀 PERFORMANCE: Form validation với memoization và debounce
const validateFormField = (field: string, value: unknown, formData: FormData): string | null => {
  switch (field) {
    case 'business_name':
      return !value || typeof value !== 'string' || !value.trim() ? 'Tên hộ kinh doanh không được trống' : null;
    case 'contact_value':
      if (!value || typeof value !== 'string' || !value.trim()) {
        return 'Thông tin liên hệ không được trống';
      }
      if (formData.contact_method === 'email') {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return !emailRegex.test(value) ? 'Email không đúng định dạng' : null;
      }
      if (formData.contact_method === 'phone') {
        const phoneRegex = /^(\+84|84|0)[0-9]{8,10}$/;
        const cleanPhone = value.replace(/[^0-9+]/g, '');
        return !phoneRegex.test(cleanPhone) ? 'Số điện thoại không đúng định dạng' : null;
      }
      return null;
    case 'owner_full_name':
      return !value || typeof value !== 'string' || !value.trim() ? 'Tên chủ hộ không được trống' : null;
    case 'password':
      return formData.set_password && (!value || typeof value !== 'string' || value.length < 6) 
        ? 'Mật khẩu phải có ít nhất 6 ký tự' : null;
    default:
      return null;
  }
};

const validateForm = (formData: FormData): { isValid: boolean; errors: string[] } => {
  const fields = ['business_name', 'contact_value', 'owner_full_name', 'password'];
  const errors: string[] = [];
  
  fields.forEach(field => {
    const error = validateFormField(field, formData[field as keyof FormData], formData);
    if (error) errors.push(error);
  });
  
  return { isValid: errors.length === 0, errors };
};

// 🚀 PERFORMANCE: Memoized components to prevent re-renders
const ContactMethodRadio = memo(({ 
  method, 
  currentMethod, 
  onChange, 
  disabled,
  icon,
  label 
}: {
  method: 'email' | 'phone';
  currentMethod: string;
  onChange: (method: 'email' | 'phone') => void;
  disabled: boolean;
  icon: string;
  label: string;
}) => (
  <label className="flex items-center space-x-2 cursor-pointer">
    <input
      type="radio"
      name="contact_method"
      checked={currentMethod === method}
      onChange={() => onChange(method)}
      disabled={disabled}
      className="text-primary"
    />
    <span>{icon} {label}</span>
  </label>
));
ContactMethodRadio.displayName = 'ContactMethodRadio';

const StatusSelect = memo(({ 
  value, 
  onChange, 
  disabled, 
  options, 
  label 
}: {
  value: string;
  onChange: (value: string) => void;
  disabled: boolean;
  options: Record<string, { text: string; label: string }>;
  label: string;
}) => (
  <div className="space-y-2">
    <Label htmlFor={label.toLowerCase().replace(/\s+/g, '_')}>{label}</Label>
    <Select value={value} onValueChange={onChange} disabled={disabled}>
      <SelectTrigger>
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {Object.entries(options).map(([key, option]) => (
          <SelectItem key={key} value={key}>
            {option.text}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  </div>
));
StatusSelect.displayName = 'StatusSelect';

function ErrorFallback({ error, resetErrorBoundary }: { error: Error; resetErrorBoundary: () => void }) {
  return (
    <div className="p-6 border border-red-200 rounded-lg bg-red-50">
      <h2 className="text-lg font-semibold text-red-800 mb-2">Có lỗi xảy ra</h2>
      <p className="text-red-600 mb-4">{error.message}</p>
      <Button onClick={resetErrorBoundary} variant="outline">
        Thử lại
      </Button>
    </div>
  );
}

export function CreateBusinessFormOptimizedWithErrorBoundary() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onError={(error, errorInfo) => {
        console.error('❌ [CREATE-BUSINESS-ERROR]:', error, errorInfo);
      }}
    >
      <CreateBusinessFormOptimized />
    </ErrorBoundary>
  );
}

export function CreateBusinessFormOptimized() {
  // 🚀 PERFORMANCE: State optimization với refs để tránh re-render
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const debounceTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const formStartTimeRef = useRef<number>(Date.now());
  
  const [formData, setFormData] = useState<FormData>({
    business_name: '',
    business_type: 'retail',
    contact_method: 'email' as const,
    contact_value: '',
    owner_full_name: '',
    subscription_tier: 'free',
    business_status: 'trial',
    subscription_status: 'trial',
    set_password: false,
    password: ''
  });

  const [isSuperAdmin, setIsSuperAdmin] = useState<boolean | null>(null);
  const [authLoading, setAuthLoading] = useState(true);

  // 🔧 State for loading business types dynamically
  const [businessTypesByCategory, setBusinessTypesByCategory] = useState<Record<string, BusinessType[]>>({});
  const [isLoadingTypes, setIsLoadingTypes] = useState(true);

  // ✅ ADD: Check super admin status on component mount
  useEffect(() => {
    const checkSuperAdminStatus = async () => {
      try {
        const response = await fetch('/api/auth/verify-super-admin', {
          method: 'GET'
        });

        const result = await response.json();
        setIsSuperAdmin(result.isSuperAdmin);
      } catch (error) {
        console.error('❌ Super admin check failed:', error);
        setIsSuperAdmin(false);
      } finally {
        setAuthLoading(false);
      }
    };

    checkSuperAdminStatus();
  }, []);

  // Load business types
  useEffect(() => {
    const fetchBusinessTypes = async () => {
      try {
        const types = await businessTypeService.getBusinessTypesFromDB();
        // setBusinessTypes(types); // Removed unused state
        
        // Group by category
        const grouped = types.reduce((acc, type) => {
          const category = type.category || 'Other';
          if (!acc[category]) {
            acc[category] = [];
          }
          acc[category].push(type);
          return acc;
        }, {} as Record<string, BusinessType[]>);
        
        setBusinessTypesByCategory(grouped);
      } catch (error) {
        console.error('Failed to load business types:', error);
        toast({
          title: "Lỗi tải loại hình kinh doanh",
          description: "Không thể tải danh sách loại hình kinh doanh. Vui lòng thử lại sau.",
          variant: "destructive"
        });
      } finally {
        setIsLoadingTypes(false);
      }
    };
    
    fetchBusinessTypes();
  }, []);

  // 🚀 PERFORMANCE: Optimized input handler with debouncing
  const handleInputChange = useCallback((field: keyof FormData, value: string | boolean) => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }
    
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
    
    // Clear password field when set_password is disabled
    if (field === 'set_password' && !value) {
      setFormData(prev => ({ ...prev, password: '' }));
    }
    
    // Debounce validation for better performance
    debounceTimeoutRef.current = setTimeout(() => {
      console.log(`🔄 [FORM-DEBUG] Field ${field} updated:`, value);
    }, 300);
  }, []);

  // Contact method change handler
  const handleContactMethodChange = useCallback((method: 'email' | 'phone') => {
    handleInputChange('contact_method', method);
    // Clear contact value when method changes
    handleInputChange('contact_value', '');
  }, [handleInputChange]);

  // Get current validation state
  const validation = validateForm(formData);

  // ✅ IMPROVED: Add super admin check before submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Check super admin status first
    if (!isSuperAdmin) {
      toast({
        title: 'Không có quyền truy cập',
        description: 'Bạn cần quyền Super Admin để tạo hộ kinh doanh',
        variant: 'destructive'
      });
      return;
    }

    // Validate form
    const validation = validateForm(formData);
    if (!validation.isValid) {
      toast({
        title: 'Lỗi nhập liệu',
        description: validation.errors.join(', '),
        variant: 'destructive'
      });
      return;
    }
    
    setLoading(true);
    
    try {
      const startTime = Date.now();
      
      // 🔍 DEBUG: Log form submission
      console.log('🚀 [CREATE-BUSINESS-DEBUG] Form submission started:', {
        timestamp: new Date().toISOString(),
        formData: {
          business_name: formData.business_name,
          business_type: formData.business_type,
          contact_method: formData.contact_method,
          contact_value: formData.contact_value,
          owner_full_name: formData.owner_full_name,
          subscription_tier: formData.subscription_tier,
          business_status: formData.business_status,
          subscription_status: formData.subscription_status,
          set_password: formData.set_password
        }
      });

      // ✅ FIX: Call API endpoint instead of direct service
      const payload = {
        businessName: formData.business_name.trim(),
        contactMethod: formData.contact_method,
        contactValue: formData.contact_value.trim(),
        ownerFullName: formData.owner_full_name.trim(),
        businessType: formData.business_type,
        subscriptionTier: formData.subscription_tier,
        businessStatus: formData.business_status,
        subscriptionStatus: formData.subscription_status,
        setPassword: formData.set_password && formData.password.trim().length >= 6 ? formData.password.trim() : undefined
      };

      console.log('🔍 [CREATE-BUSINESS-DEBUG] Calling API with payload:', payload);

      // Call API endpoint
      const response = await fetch('/api/admin/create-business', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload)
      });

      const result = await response.json();
      const duration = Date.now() - startTime;

      // 🔍 DEBUG: Log API response
      console.log('🔍 [CREATE-BUSINESS-DEBUG] API response:', {
        duration: `${duration}ms`,
        success: result.success,
        error: result.error,
        status: response.status,
        data: result.data
      });

      // Handle API errors
      if (!response.ok || !result.success) {
        console.error('❌ [CREATE-BUSINESS-DEBUG] API call failed:', {
          status: response.status,
          error: result.error,
          formData: formData,
          timestamp: new Date().toISOString()
        });
        
        throw new Error(result.error || 'Không thể tạo hộ kinh doanh');
      }

      // Extract data from API response
      const businessData = result.data;

      // 🔍 DEBUG: Log success
      console.log('✅ [CREATE-BUSINESS-DEBUG] Business created successfully:', {
        business_name: businessData.business_name,
        business_code: businessData.business_code,
        business_id: businessData.business_id
      });

      // Show success message
      const businessStatus = STATUS_MAPPINGS.business[formData.business_status as keyof typeof STATUS_MAPPINGS.business];
      const subscriptionStatus = STATUS_MAPPINGS.subscription[formData.subscription_status as keyof typeof STATUS_MAPPINGS.subscription];
      
      if (businessData.user_created) {
        toast({
          title: '🎉 Tạo hộ kinh doanh thành công!',
          description: `Hộ kinh doanh "${businessData.business_name}" đã được tạo với mã ${businessData.business_code}. ${businessData.user_created ? 'Tài khoản chủ hộ đã được tạo.' : 'Sử dụng tài khoản hiện có.'}`,
          variant: 'default'
        });
      } else {
        toast({
          title: '✅ Cập nhật hộ kinh doanh thành công!',
          description: `Hộ kinh doanh "${businessData.business_name}" đã được cập nhật với trạng thái ${businessStatus?.label} và gói ${subscriptionStatus?.label}`,
          variant: 'default'
        });
      }

      // Reset form after success
      setFormData({
        business_name: '',
        business_type: 'retail',
        contact_method: 'email',
        contact_value: '',
        owner_full_name: '',
        subscription_tier: 'free',
        business_status: 'trial',
        subscription_status: 'trial',
        set_password: false,
        password: ''
      });

      // Reset timer for new form
      formStartTimeRef.current = Date.now();

    } catch (error: unknown) {
      // 🔍 DEBUG: Log detailed error
      console.error('❌ [CREATE-BUSINESS-DEBUG] Exception caught:', {
        error: error instanceof Error ? {
          name: error.name,
          message: error.message,
          stack: error.stack
        } : error,
        formData: formData,
        timestamp: new Date().toISOString()
      });
      
      console.error('❌ API Error:', error);
      
      toast({
        title: 'Lỗi hệ thống',
        description: error instanceof Error ? error.message : 'Có lỗi không xác định xảy ra',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  // Show loading state while checking auth
  if (authLoading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        <span className="ml-2">Đang kiểm tra quyền truy cập...</span>
      </div>
    );
  }

  // Show unauthorized message
  if (!isSuperAdmin) {
    return (
      <div className="p-8 text-center">
        <h2 className="text-xl font-semibold text-red-600 mb-2">Không có quyền truy cập</h2>
        <p className="text-muted-foreground">Bạn cần quyền Super Admin để sử dụng tính năng này.</p>
      </div>
    );
  }

  // 🚀 RENDER: Optimized render
  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Business Name */}
      <div className="space-y-2">
        <Label htmlFor="business_name">Tên hộ kinh doanh *</Label>
        <Input
          id="business_name"
          value={formData.business_name}
          onChange={(e) => handleInputChange('business_name', e.target.value)}
          placeholder="VD: Cửa hàng tạp hóa Minh Châu"
          disabled={loading}
        />
      </div>

      {/* Business Type - Updated with Dynamic Data */}
      <div className="space-y-2">
        <Label htmlFor="business_type">Loại hình kinh doanh *</Label>
        <Select
          value={formData.business_type}
          onValueChange={(value) => handleInputChange('business_type', value)}
          disabled={loading || isLoadingTypes}
        >
          <SelectTrigger className="text-base py-6">
            <SelectValue placeholder={isLoadingTypes ? "Đang tải..." : "Chọn loại hình kinh doanh..."} />
          </SelectTrigger>
          <SelectContent className="max-h-96">
            {Object.entries(businessTypesByCategory).map(([category, types]) => (
              <SelectGroup key={category}>
                <SelectLabel className="font-bold text-primary">{category}</SelectLabel>
                {types.map((type) => (
                  <SelectItem key={type.value} value={type.value}>
                    <div className="flex items-center gap-3">
                      <span className="text-lg">{type.icon}</span>
                      <div className="flex flex-col">
                        <span className="font-semibold">{type.label}</span>
                        <span className="text-xs text-muted-foreground">{type.description}</span>
                      </div>
                    </div>
                  </SelectItem>
                ))}
              </SelectGroup>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Contact Method Selection */}
      <div className="space-y-2">
        <Label>Phương thức liên hệ *</Label>
        <div className="flex space-x-6">
          <ContactMethodRadio
            method="email"
            currentMethod={formData.contact_method}
            onChange={handleContactMethodChange}
            disabled={loading}
            icon="📧"
            label="Email"
          />
          <ContactMethodRadio
            method="phone"
            currentMethod={formData.contact_method}
            onChange={handleContactMethodChange}
            disabled={loading}
            icon="📱"
            label="Số điện thoại"
          />
        </div>
      </div>

      {/* Contact Value */}
      <div className="space-y-2">
        <Label htmlFor="contact_value">
          {formData.contact_method === 'email' ? 'Email' : 'Số điện thoại'} *
        </Label>
        <Input
          id="contact_value"
          type={formData.contact_method === 'email' ? 'email' : 'tel'}
          value={formData.contact_value}
          onChange={(e) => handleInputChange('contact_value', e.target.value)}
          placeholder={formData.contact_method === 'email' ? 'VD: admin@hokinhdoanh.vn' : 'VD: 0909123456'}
          disabled={loading}
        />
      </div>

      {/* Owner Full Name */}
      <div className="space-y-2">
        <Label htmlFor="owner_full_name">Họ tên chủ hộ *</Label>
        <Input
          id="owner_full_name"
          value={formData.owner_full_name}
          onChange={(e) => handleInputChange('owner_full_name', e.target.value)}
          placeholder="VD: Nguyễn Văn A"
          disabled={loading}
        />
      </div>

      {/* Subscription Tier */}
      <div className="space-y-2">
        <Label htmlFor="subscription_tier">Gói dịch vụ</Label>
        <Select
          value={formData.subscription_tier}
          onValueChange={(value) => handleInputChange('subscription_tier', value)}
          disabled={loading}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="free">🆓 Gói miễn phí (3 người dùng)</SelectItem>
            <SelectItem value="basic">💰 Gói cơ bản (10 người dùng)</SelectItem>
            <SelectItem value="premium">👑 Gói cao cấp (50 người dùng)</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Business Status and Subscription Status */}
      <div className="grid grid-cols-2 gap-4">
        <StatusSelect
          value={formData.business_status}
          onChange={(value) => handleInputChange('business_status', value)}
          disabled={loading}
          options={STATUS_MAPPINGS.business}
          label="Trạng thái hộ kinh doanh"
        />
        <StatusSelect
          value={formData.subscription_status}
          onChange={(value) => handleInputChange('subscription_status', value)}
          disabled={loading}
          options={STATUS_MAPPINGS.subscription}
          label="Trạng thái đăng ký"
        />
      </div>

      {/* Set Password Option */}
      <div className="space-y-4">
        <div className="flex items-center space-x-2">
          <input
            type="checkbox"
            id="set_password"
            checked={formData.set_password}
            onChange={(e) => handleInputChange('set_password', e.target.checked)}
            disabled={loading}
            className="rounded"
          />
          <Label htmlFor="set_password">Đặt mật khẩu cho chủ hộ</Label>
        </div>

        {formData.set_password && (
          <div className="space-y-2">
            <Label htmlFor="password">Mật khẩu *</Label>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? 'text' : 'password'}
                value={formData.password}
                onChange={(e) => handleInputChange('password', e.target.value)}
                placeholder="Nhập mật khẩu (tối thiểu 6 ký tự)"
                disabled={loading}
                className="pr-10"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center"
                disabled={loading}
              >
                {showPassword ? (
                  <EyeOff className="h-4 w-4 text-gray-400" />
                ) : (
                  <Eye className="h-4 w-4 text-gray-400" />
                )}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Submit Button */}
      <Button
        type="submit"
        disabled={loading || !validation.isValid}
        className="w-full"
      >
        {loading ? (
          <>
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
            Đang tạo hộ kinh doanh...
          </>
        ) : (
          '🏢 Tạo hộ kinh doanh mới'
        )}
      </Button>

      {/* Validation Errors */}
      {!validation.isValid && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <h4 className="font-semibold text-red-800 mb-2">Vui lòng kiểm tra lại:</h4>
          <ul className="text-sm text-red-600 space-y-1">
            {validation.errors.map((error, index) => (
              <li key={index}>• {error}</li>
            ))}
          </ul>
        </div>
      )}
    </form>
  );
}