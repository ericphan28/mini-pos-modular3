import Link from "next/link";
import { POSButton, POSButtonProps } from "@/components/ui/pos-button";
import { ArrowRight } from "lucide-react";
import { forwardRef } from "react";

// Login Button - Always uses secondary variant (inverted colors)
interface LoginButtonProps extends Omit<POSButtonProps, 'posVariant'> {
  href?: string;
}

const LoginButton = forwardRef<HTMLButtonElement, LoginButtonProps>(
  ({ href = "/auth/login", children = "Đăng nhập", ...props }, ref) => {
    return (
      <POSButton
        asChild
        posVariant="secondary"
        ref={ref}
        {...props}
      >
        <Link href={href}>{children}</Link>
      </POSButton>
    );
  }
);

// Signup Button - Always uses primary variant (green)
interface SignupButtonProps extends Omit<POSButtonProps, 'posVariant'> {
  href?: string;
  showArrow?: boolean;
}

const SignupButton = forwardRef<HTMLButtonElement, SignupButtonProps>(
  ({ href = "/auth/sign-up", children = "Bắt đầu miễn phí", showArrow = false, className, ...props }, ref) => {
    return (
      <POSButton
        asChild
        posVariant="primary"
        className={className}
        ref={ref}
        {...props}
      >
        <Link href={href} className={showArrow ? "flex items-center gap-2" : ""}>
          {children}
          {showArrow && <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />}
        </Link>
      </POSButton>
    );
  }
);

// Dashboard Button
interface DashboardButtonProps extends Omit<POSButtonProps, 'posVariant'> {
  href?: string;
}

const DashboardButton = forwardRef<HTMLButtonElement, DashboardButtonProps>(
  ({ href = "/onboarding", children = "Bảng điều khiển", ...props }, ref) => {
    return (
      <POSButton
        asChild
        posVariant="primary"
        ref={ref}
        {...props}
      >
        <Link href={href}>{children}</Link>
      </POSButton>
    );
  }
);

LoginButton.displayName = "LoginButton";
SignupButton.displayName = "SignupButton";
DashboardButton.displayName = "DashboardButton";

export { LoginButton, SignupButton, DashboardButton };
