import { CheckCircle } from "lucide-react";
import { LoginButton, SignupButton } from "./ui/auth-buttons";

export function Hero() {
  return (
    <div className="relative">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-green-50 via-background to-emerald-50 dark:from-background dark:via-background dark:to-green-950/20 -z-10" />
      
      <div className="container mx-auto px-4 py-20 lg:py-32">
        <div className="flex flex-col items-center text-center max-w-4xl mx-auto">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300 px-4 py-2 rounded-full text-sm font-medium mb-8">
            <CheckCircle className="w-4 h-4" />
            Miễn phí 30 ngày đầu tiên
          </div>

          {/* Main heading */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight mb-6">
            <span className="bg-gradient-to-r from-foreground via-foreground to-foreground bg-clip-text text-transparent">
              POS Mini
            </span>
            <br />
            <span className="bg-gradient-to-r from-primary to-emerald-600 bg-clip-text text-transparent">
              Modular
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-xl md:text-2xl text-muted-foreground mb-8 max-w-3xl leading-relaxed">
            Hệ thống quản lý bán hàng hiện đại, đơn giản và hiệu quả
            <br className="hidden md:block" />
            <span className="text-primary font-medium">đặc biệt dành cho các hộ kinh doanh tại Việt Nam</span>
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 mb-12">
            <SignupButton size="lg" showArrow={true} className="shadow-lg hover:shadow-xl transition-all duration-200 group" />
            <LoginButton size="lg" />
          </div>

          {/* Features list */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left max-w-3xl">
            <div className="flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-primary mt-1 flex-shrink-0" />
              <div>
                <h3 className="font-semibold text-foreground mb-1">Không cần cài đặt</h3>
                <p className="text-sm text-muted-foreground">Sử dụng ngay trên trình duyệt web</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-primary mt-1 flex-shrink-0" />
              <div>
                <h3 className="font-semibold text-foreground mb-1">Dễ sử dụng</h3>
                <p className="text-sm text-muted-foreground">Giao diện đơn giản, thân thiện</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-primary mt-1 flex-shrink-0" />
              <div>
                <h3 className="font-semibold text-foreground mb-1">Hỗ trợ 24/7</h3>
                <p className="text-sm text-muted-foreground">Đội ngũ hỗ trợ tận tình</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
