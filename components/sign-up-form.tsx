"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { POSButton } from "@/components/ui/pos-button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { businessTypeCategoriesService } from "@/lib/services/business-type-categories.service";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

// ✅ ENHANCED: Use business type categories service
const businessTypeCategories = businessTypeCategoriesService.getBusinessTypeCategories();

export function SignUpForm({
  className,
  ...props
}: React.ComponentPropsWithoutRef<"div">) {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    repeatPassword: "",
    fullName: "",
    phone: "",
    businessName: "",
    businessType: "",
    address: "",
    taxCode: "",
  });
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [skipEmailConfirmation, setSkipEmailConfirmation] = useState(false);
  const router = useRouter();

  const validatePhone = (phone: string): boolean => {
    if (!phone || phone.trim() === '') return true; // Phone is optional
    
    const cleanPhone = phone.replace(/[\s\-\(\)\.]/g, '');
    
    // Vietnamese phone patterns
    const phonePatterns = [
      /^0[3-9]\d{8}$/,           // Mobile: 03x, 05x, 07x, 08x, 09x (10 digits)
      /^84[3-9]\d{8}$/,          // International mobile: +84
      /^[0-9]{8,15}$/            // General international format
    ];
    
    return phonePatterns.some(pattern => pattern.test(cleanPhone));
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    const supabase = createClient();
    setIsLoading(true);
    setError(null);

    try {
      // Validate passwords
      if (formData.password !== formData.repeatPassword) {
        throw new Error("Mật khẩu nhập lại không khớp");
      }

      // Validate required fields
      if (!formData.fullName || !formData.businessName || !formData.businessType) {
        throw new Error("Vui lòng điền đầy đủ thông tin bắt buộc");
      }

      // Validate phone format
      if (formData.phone && !validatePhone(formData.phone)) {
        throw new Error("Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam (10-11 số)");
      }

      console.log('🔧 [SIGNUP] Starting signup process...', {
        email: formData.email,
        skipEmailConfirmation,
        businessName: formData.businessName,
        businessType: formData.businessType
      });

      // Store business info in metadata
      const businessInfo = {
        fullName: formData.fullName.trim(),
        phone: formData.phone.trim() || null,
        businessName: formData.businessName.trim(),
        businessType: formData.businessType,
        address: formData.address.trim() || null,
        taxCode: formData.taxCode.trim() || null,
      };

      if (skipEmailConfirmation) {
        // Development mode: Skip email confirmation
        console.log('🔧 [SIGNUP] Development mode: Skipping email confirmation');
        
        const { data, error } = await supabase.auth.signUp({
          email: formData.email,
          password: formData.password,
          options: {
            data: businessInfo,
            emailRedirectTo: `${window.location.origin}/auth/confirm?redirect=/dashboard`
          },
        });

        if (error) throw error;

        if (data.user) {
          console.log('✅ [SIGNUP] User created, creating business profile directly...');
          
          // Create business profile immediately using RPC
          const { data: rpcResult, error: rpcError } = await supabase.rpc(
            'pos_mini_modular3_create_complete_business_owner',
            {
              p_user_id: data.user.id,
              p_email: formData.email,
              p_full_name: businessInfo.fullName,
              p_business_name: businessInfo.businessName,
              p_business_type: businessInfo.businessType,
              p_phone: businessInfo.phone,
              p_address: businessInfo.address,
              p_tax_code: businessInfo.taxCode
            }
          );

          console.log('🔧 [SIGNUP] RPC result:', { rpcResult, rpcError });

          if (rpcError) {
            console.error('❌ [SIGNUP] Failed to create business profile:', rpcError);
            throw new Error('Tạo tài khoản thành công nhưng không thể tạo thông tin doanh nghiệp: ' + rpcError.message);
          }

          if (rpcResult && rpcResult.success === false) {
            console.error('❌ [SIGNUP] Business creation failed:', rpcResult);
            throw new Error('Không thể tạo thông tin doanh nghiệp: ' + (rpcResult.error || 'Unknown error'));
          }

          console.log('✅ [SIGNUP] Business profile created successfully');
          // Redirect directly to dashboard
          router.push('/dashboard');
        }
      } else {
        // Production mode: Normal email confirmation flow
        console.log('🔧 [SIGNUP] Production mode: Using email confirmation');
        
        const { error } = await supabase.auth.signUp({
          email: formData.email,
          password: formData.password,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/confirm?redirect=/dashboard`,
            data: businessInfo
          },
        });

        if (error) throw error;
        
        console.log('✅ [SIGNUP] Signup successful, redirecting to success page');
        router.push("/auth/sign-up-success");
      }
    } catch (error: unknown) {
      console.error('❌ [SIGNUP] Signup error:', error);
      setError(error instanceof Error ? error.message : "Có lỗi xảy ra khi đăng ký");
    } finally {
      setIsLoading(false);
    }
  };

  const updateFormData = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  return (
    <div className={cn("flex flex-col gap-6", className)} {...props}>
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Đăng ký</CardTitle>
          <CardDescription>
            Nhập thông tin để tạo tài khoản mới
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSignUp}>
            <div className="flex flex-col gap-6">
              {/* Development mode toggle */}
              {process.env.NODE_ENV === 'development' && (
                <div className="flex items-center space-x-2 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
                  <input
                    type="checkbox"
                    id="skipEmailConfirmation"
                    checked={skipEmailConfirmation}
                    onChange={(e) => setSkipEmailConfirmation(e.target.checked)}
                    className="h-4 w-4"
                  />
                  <label htmlFor="skipEmailConfirmation" className="text-sm text-yellow-800">
                    Skip email confirmation (Development only)
                  </label>
                </div>
              )}

              <div className="grid gap-2">
                <Label htmlFor="email">Email <span className="text-red-500">*</span></Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="m@example.com"
                  required
                  value={formData.email}
                  onChange={(e) => updateFormData("email", e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="password">Mật khẩu <span className="text-red-500">*</span></Label>
                <Input
                  id="password"
                  type="password"
                  required
                  value={formData.password}
                  onChange={(e) => updateFormData("password", e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="repeatPassword">Nhập lại mật khẩu <span className="text-red-500">*</span></Label>
                <Input
                  id="repeatPassword"
                  type="password"
                  required
                  value={formData.repeatPassword}
                  onChange={(e) => updateFormData("repeatPassword", e.target.value)}
                />
              </div>

              <hr className="my-4" />
              <h3 className="text-lg font-semibold">Thông tin cá nhân</h3>

              <div className="grid gap-2">
                <Label htmlFor="fullName">Họ và tên <span className="text-red-500">*</span></Label>
                <Input
                  id="fullName"
                  placeholder="Nguyễn Văn A"
                  required
                  value={formData.fullName}
                  onChange={(e) => updateFormData("fullName", e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="phone">Số điện thoại</Label>
                <Input
                  id="phone"
                  placeholder="0901234567 hoặc +84901234567"
                  value={formData.phone}
                  onChange={(e) => updateFormData("phone", e.target.value)}
                />
                {formData.phone && !validatePhone(formData.phone) && (
                  <p className="text-sm text-red-600">
                    Số điện thoại không hợp lệ
                  </p>
                )}
              </div>

              <hr className="my-4" />
              <h3 className="text-lg font-semibold">Thông tin doanh nghiệp</h3>

              <div className="grid gap-2">
                <Label htmlFor="businessName">Tên doanh nghiệp <span className="text-red-500">*</span></Label>
                <Input
                  id="businessName"
                  placeholder="Công ty ABC"
                  required
                  value={formData.businessName}
                  onChange={(e) => updateFormData("businessName", e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="businessType">Loại hình kinh doanh <span className="text-red-500">*</span></Label>
                <Select value={formData.businessType} onValueChange={(value) => updateFormData("businessType", value)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Chọn loại hình kinh doanh" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60">
                    {/* ✅ ENHANCED: Render business types by categories */}
                    {businessTypeCategories.map((category) => (
                      <div key={category.id}>
                        <div className="px-2 py-1 text-xs font-semibold text-muted-foreground border-t mt-1 pt-2">
                          {category.icon} {category.name}
                        </div>
                        {category.types.map((type) => (
                          <SelectItem key={type.value} value={type.value}>
                            {type.label}
                          </SelectItem>
                        ))}
                      </div>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="address">Địa chỉ</Label>
                <Input
                  id="address"
                  placeholder="123 Đường ABC, Quận 1, TP.HCM"
                  value={formData.address}
                  onChange={(e) => updateFormData("address", e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="taxCode">Mã số thuế</Label>
                <Input
                  id="taxCode"
                  placeholder="0123456789"
                  value={formData.taxCode}
                  onChange={(e) => updateFormData("taxCode", e.target.value)}
                />
              </div>

              {error && (
                <div className="text-red-600 text-sm bg-red-50 p-3 rounded-md border border-red-200">
                  <div className="flex items-start gap-2">
                    <span className="text-red-500">⚠️</span>
                    <div>
                      <strong>Lỗi:</strong> {error}
                      {error.includes('phone') && (
                        <div className="mt-2 text-xs">
                          <strong>Gợi ý:</strong> Số điện thoại hợp lệ: 0901234567, +84901234567
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}

              <POSButton type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Đang xử lý..." : "Đăng ký"}
              </POSButton>
              <div className="mt-4 text-center text-sm">
                Đã có tài khoản?{" "}
                <Link href="/auth/login" className="underline">
                  Đăng nhập
                </Link>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
