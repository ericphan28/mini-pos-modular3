"use client";

import { User } from "@supabase/supabase-js";
import { LogoutButton } from "@/components/logout-button";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import {
  Bell,
  Search,
  Crown,
  Shield,
  Settings,
  HelpCircle,
  Menu
} from "lucide-react";

interface SuperAdminHeaderProps {
  user: User;
  profile: {
    full_name?: string;
  } | null;
  onMobileMenuClick: () => void;
}

export function SuperAdminHeader({ user, profile, onMobileMenuClick }: SuperAdminHeaderProps) {
  return (
    <header className="bg-white/80 dark:bg-gray-900/80 backdrop-blur-lg border-b border-border/50 px-6 py-4 sticky top-0 z-40">
      <div className="flex items-center justify-between">
        {/* Mobile Menu Button */}
        <div className="md:hidden">
          <Button variant="ghost" size="sm" onClick={onMobileMenuClick}>
            <Menu className="w-5 h-5" />
          </Button>
        </div>

        {/* Search Bar - Hidden on mobile */}
        <div className="hidden lg:flex items-center flex-1 max-w-md">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Tìm kiếm hộ kinh doanh, người dùng..."
              className="pl-10 bg-background/50 border-border/50 focus:bg-background transition-colors"
            />
          </div>
        </div>

        {/* Right Side Actions */}
        <div className="flex items-center gap-4">
          {/* Notifications */}
          <Button variant="ghost" size="sm" className="relative">
            <Bell className="w-5 h-5" />
            <Badge variant="destructive" className="absolute -top-1 -right-1 w-5 h-5 p-0 text-xs flex items-center justify-center">
              3
            </Badge>
          </Button>

          {/* Help */}
          <Button variant="ghost" size="sm">
            <HelpCircle className="w-5 h-5" />
          </Button>

          {/* Theme Switcher */}
          <ThemeSwitcher />

          {/* Divider */}
          <div className="h-6 w-px bg-border" />

          {/* User Profile */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="flex items-center gap-3 px-3 py-2 h-auto">
                <div className="w-8 h-8 bg-gradient-to-br from-purple-600 to-purple-700 rounded-full flex items-center justify-center">
                  <Crown className="w-4 h-4 text-white" />
                </div>
                <div className="hidden sm:flex flex-col items-start">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">
                      {profile?.full_name || user.email?.split('@')[0]}
                    </span>
                    <Badge variant="secondary" className="text-xs bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
                      <Shield className="w-3 h-3 mr-1" />
                      Super Admin
                    </Badge>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {user.email}
                  </span>
                </div>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-64">
              <div className="flex items-center gap-3 p-3">
                <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-purple-700 rounded-full flex items-center justify-center">
                  <Crown className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm">
                    {profile?.full_name || user.email?.split('@')[0]}
                  </p>
                  <p className="text-xs text-muted-foreground truncate">
                    {user.email}
                  </p>
                  <div className="flex items-center gap-1 mt-1">
                    <Shield className="w-3 h-3 text-purple-600" />
                    <span className="text-xs text-purple-600 font-medium">Super Administrator</span>
                  </div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Powered by <span className="font-semibold text-purple-600">GiaKiemSo.com</span>
                  </div>
                </div>
              </div>
              <DropdownMenuSeparator />
              <DropdownMenuItem asChild>
                <a href="/super-admin/profile" className="flex items-center gap-2">
                  <Settings className="w-4 h-4" />
                  Cài đặt tài khoản
                </a>
              </DropdownMenuItem>
              <DropdownMenuItem asChild>
                <a href="/super-admin/settings" className="flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  Cài đặt hệ thống
                </a>
              </DropdownMenuItem>
              <DropdownMenuItem asChild>
                <a href="/super-admin/help" className="flex items-center gap-2">
                  <HelpCircle className="w-4 h-4" />
                  Hướng dẫn sử dụng
                </a>
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem asChild>
                <LogoutButton />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        {/* Mobile Search - Show below on mobile */}
      </div>
      
      {/* Mobile Search Bar */}
      <div className="lg:hidden mt-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Tìm kiếm..."
            className="pl-10 bg-background/50 border-border/50 focus:bg-background transition-colors"
          />
        </div>
      </div>
    </header>
  );
}
