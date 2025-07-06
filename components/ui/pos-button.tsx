import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { Button, ButtonProps } from "./button";
import { cn } from "@/lib/utils";

// Extend shadcn/ui button với POS-specific variants
const posButtonVariants = cva("", {
  variants: {
    posVariant: {
      // Primary - Green button (brand color)
      primary: "bg-primary hover:bg-primary/90 text-primary-foreground border-0 shadow-sm",
      
      // Secondary - Inverted colors for light/dark mode
      secondary: "bg-gray-900 dark:bg-white text-white dark:text-gray-900 hover:bg-gray-800 dark:hover:bg-gray-100 border-0 transition-colors",
      
      // Danger - Red for destructive actions
      danger: "bg-destructive hover:bg-destructive/90 text-destructive-foreground border-0 shadow-sm",
      
      // Success - Green success variant
      success: "bg-green-600 hover:bg-green-700 text-white border-0 shadow-sm",
      
      // Warning - Yellow/orange
      warning: "bg-yellow-600 hover:bg-yellow-700 text-white border-0 shadow-sm",
    },
  },
});

export interface POSButtonProps 
  extends ButtonProps,
    VariantProps<typeof posButtonVariants> {}

const POSButton = React.forwardRef<HTMLButtonElement, POSButtonProps>(
  ({ className, posVariant, ...props }, ref) => {
    return (
      <Button
        className={cn(posButtonVariants({ posVariant }), className)}
        ref={ref}
        {...props}
      />
    );
  }
);

POSButton.displayName = "POSButton";

export { POSButton, posButtonVariants };
