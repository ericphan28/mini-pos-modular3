"use client";

import { createClient } from "@/lib/supabase/client";
import { POSButton } from "@/components/ui/pos-button";
import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";

export function LogoutButton() {
  const router = useRouter();

  const logout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
  };

  return (
    <POSButton 
      onClick={logout} 
      variant="ghost" 
      size="sm"
      className="text-muted-foreground hover:text-foreground hover:bg-muted/50 px-2"
      title="Đăng xuất"
    >
      <LogOut className="h-4 w-4" />
    </POSButton>
  );
}
