'use client';

import { useEffect, useState } from 'react';
import { subscriptionService } from '@/lib/services/subscription.service';
import type { FeatureName } from '@/lib/types/subscription.types';
import { Card, CardContent } from '@/components/ui/card';
import { POSButton } from '@/components/ui/pos-button';
import { Lock, Zap } from 'lucide-react';
import Link from 'next/link';

interface FeatureGateProps {
  businessId: string;
  feature: FeatureName;
  children: React.ReactNode;
  fallback?: React.ReactNode;
  showUpgradePrompt?: boolean;
}

export function FeatureGate({ 
  businessId, 
  feature, 
  children, 
  fallback,
  showUpgradePrompt = true 
}: FeatureGateProps) {
  const [hasAccess, setHasAccess] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAccess = async () => {
      if (!businessId) return;
      
      setLoading(true);
      const access = await subscriptionService.checkFeatureAccess(businessId, feature);
      setHasAccess(access);
      setLoading(false);
    };

    checkAccess();
  }, [businessId, feature]);

  if (loading) {
    return (
      <div className="animate-pulse">
        <div className="h-4 bg-muted rounded w-3/4 mb-2"></div>
        <div className="h-4 bg-muted rounded w-1/2"></div>
      </div>
    );
  }

  if (hasAccess) {
    return <>{children}</>;
  }

  if (fallback) {
    return <>{fallback}</>;
  }

  if (showUpgradePrompt) {
    return <UpgradePrompt feature={feature} />;
  }

  return null;
}

function UpgradePrompt({ feature }: { feature: FeatureName }) {
  const getFeatureInfo = (feature: FeatureName) => {
    const features: Record<FeatureName, {
      title: string;
      description: string;
      requiredPlan: string;
    }> = {
      product_management: {
        title: 'Quản lý sản phẩm',
        description: 'Quản lý danh mục và thông tin sản phẩm',
        requiredPlan: 'Gói Cơ bản'
      },
      product_categories: {
        title: 'Danh mục sản phẩm',
        description: 'Phân loại sản phẩm theo danh mục',
        requiredPlan: 'Gói Cơ bản'
      },
      basic_pos: {
        title: 'Bán hàng cơ bản',
        description: 'Giao diện bán hàng đơn giản',
        requiredPlan: 'Gói Cơ bản'
      },
      inventory_management: {
        title: 'Quản lý kho hàng',
        description: 'Theo dõi tồn kho, nhập xuất hàng, và quản lý nhiều kho',
        requiredPlan: 'Gói Cơ bản'
      },
      customer_management: {
        title: 'Quản lý khách hàng',
        description: 'Lưu trữ thông tin khách hàng, lịch sử mua hàng',
        requiredPlan: 'Gói Cơ bản'
      },
      supplier_management: {
        title: 'Quản lý nhà cung cấp',
        description: 'Quản lý thông tin nhà cung cấp và đơn nhập hàng',
        requiredPlan: 'Gói Cơ bản'
      },
      advanced_reports: {
        title: 'Báo cáo nâng cao',
        description: 'Phân tích chi tiết doanh thu, lợi nhuận, và xu hướng',
        requiredPlan: 'Gói Cơ bản'
      },
      advanced_analytics: {
        title: 'Phân tích nâng cao',
        description: 'Phân tích dữ liệu chi tiết và xu hướng',
        requiredPlan: 'Gói Cơ bản'
      },
      multi_branch: {
        title: 'Quản lý nhiều chi nhánh',
        description: 'Mở rộng kinh doanh với nhiều cửa hàng',
        requiredPlan: 'Gói Nâng cao'
      },
      e_invoice: {
        title: 'Hóa đơn điện tử',
        description: 'Tạo và gửi hóa đơn điện tử hợp pháp',
        requiredPlan: 'Gói Nâng cao'
      },
      payment_integration: {
        title: 'Tích hợp thanh toán',
        description: 'Kết nối với các cổng thanh toán',
        requiredPlan: 'Gói Nâng cao'
      },
      unlimited_api: {
        title: 'API không giới hạn',
        description: 'Truy cập API không giới hạn',
        requiredPlan: 'Gói Nâng cao'
      },
      priority_support: {
        title: 'Hỗ trợ ưu tiên',
        description: 'Hỗ trợ khách hàng 24/7',
        requiredPlan: 'Gói Nâng cao'
      },
      email_support: {
        title: 'Hỗ trợ email',
        description: 'Hỗ trợ qua email',
        requiredPlan: 'Gói Cơ bản'
      }
    };

    return features[feature] || {
      title: 'Tính năng cao cấp',
      description: 'Tính năng này yêu cầu nâng cấp gói dịch vụ',
      requiredPlan: 'Gói trả phí'
    };
  };

  const info = getFeatureInfo(feature);

  return (
    <Card className="border-dashed border-2 border-muted-foreground/20">
      <CardContent className="p-6 text-center">
        <div className="w-12 h-12 bg-muted rounded-lg flex items-center justify-center mx-auto mb-4">
          <Lock className="w-6 h-6 text-muted-foreground" />
        </div>
        <h3 className="font-semibold text-foreground mb-2">{info.title}</h3>
        <p className="text-sm text-muted-foreground mb-4">{info.description}</p>
        <div className="bg-primary/10 rounded-lg p-3 mb-4">
          <p className="text-sm font-medium text-primary">
            Cần nâng cấp lên {info.requiredPlan}
          </p>
        </div>
        <Link href="/business/subscription">
          <POSButton posVariant="primary" className="w-full">
            <Zap className="w-4 h-4 mr-2" />
            Nâng cấp ngay
          </POSButton>
        </Link>
      </CardContent>
    </Card>
  );
}