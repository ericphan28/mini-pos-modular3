import { createClient } from "@/lib/supabase/server";
import { LogoutButton } from "./logout-button";
import { LoginButton, SignupButton, DashboardButton } from "./ui/auth-buttons";

export async function AuthButton() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  return user ? (
    <div className="flex items-center gap-3">
      <div className="hidden sm:flex items-center gap-3">
        <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-primary-foreground text-sm font-medium">
          {user.email?.charAt(0).toUpperCase()}
        </div>
        <div className="flex flex-col">
          <span className="text-sm font-medium text-foreground">
            {user.email?.split('@')[0]}
          </span>
          <span className="text-xs text-muted-foreground">
            {user.email}
          </span>
        </div>
      </div>
      <DashboardButton size="sm" />
      <LogoutButton />
    </div>
  ) : (
    <div className="flex items-center gap-2">
      <LoginButton size="sm" />
      <SignupButton size="sm" />
    </div>
  );
}
