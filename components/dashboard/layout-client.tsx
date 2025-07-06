'use client'

import { LogoutButton } from "@/components/logout-button";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  BarChart3,
  Bell,
  Calculator,
  ChevronLeft,
  ChevronRight,
  Home,
  Menu,
  Package,
  Search,
  Settings,
  UserCheck,
  Users,
  X
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

interface User {
  id: string;
  email?: string;
  created_at: string;
}

interface DashboardLayoutClientProps {
  children: React.ReactNode;
  user: User;
}

interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
}

const navItems: NavItem[] = [
  { href: '/dashboard', label: 'Tổng quan', icon: Home },
  { href: '/dashboard/pos', label: 'Bán hàng', icon: Calculator },
  { href: '/dashboard/products', label: 'Sản phẩm', icon: Package },
  { href: '/dashboard/customers', label: 'Khách hàng', icon: Users },
  { href: '/dashboard/staff', label: 'Nhân viên', icon: UserCheck },
  { href: '/dashboard/reports', label: 'Báo cáo', icon: BarChart3 },
  { href: '/dashboard/settings', label: 'Cài đặt', icon: Settings },
];

export default function DashboardLayoutClient({ children, user }: DashboardLayoutClientProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const pathname = usePathname();

  // Check if current path is active
  const isActive = useCallback((href: string) => {
    if (href === '/dashboard') {
      return pathname === '/dashboard';
    }
    return pathname.startsWith(href);
  }, [pathname]);

  // Close mobile menu when route changes
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [pathname]);

  // Prevent body scroll when mobile menu is open
  useEffect(() => {
    if (mobileMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [mobileMenuOpen]);

  // Handle escape key to close mobile menu
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setMobileMenuOpen(false);
      }
    };

    if (mobileMenuOpen) {
      document.addEventListener('keydown', handleEscape);
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
    };
  }, [mobileMenuOpen]);

  // Save sidebar state to localStorage
  useEffect(() => {
    const savedState = localStorage.getItem('sidebar-collapsed');
    if (savedState !== null) {
      setSidebarCollapsed(JSON.parse(savedState));
    }
  }, []);

  const toggleSidebar = () => {
    const newState = !sidebarCollapsed;
    setSidebarCollapsed(newState);
    localStorage.setItem('sidebar-collapsed', JSON.stringify(newState));
  };

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop Sidebar */}
      <div className={`hidden lg:flex lg:flex-col transition-all duration-300 ease-in-out ${
        sidebarCollapsed ? 'lg:w-20' : 'lg:w-72'
      }`}>
        <div className="flex flex-col flex-grow pt-6 overflow-y-auto bg-gradient-to-b from-card to-card/50 border-r border-border/50 backdrop-blur-sm">
          {/* Logo & Collapse Button */}
          <div className="flex items-center justify-between px-6 mb-8">
            <div className={`flex items-center gap-3 transition-all duration-300 ${
              sidebarCollapsed ? 'opacity-0 w-0 overflow-hidden' : 'opacity-100'
            }`}>
              <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-xl flex items-center justify-center shadow-lg">
                <span className="text-primary-foreground font-bold text-lg">P</span>
              </div>
              <div>
                <h1 className="text-xl font-bold text-foreground">POS Mini</h1>
                <p className="text-xs text-muted-foreground">Modular System</p>
              </div>
            </div>
            
            {sidebarCollapsed && (
              <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-xl flex items-center justify-center shadow-lg mx-auto">
                <span className="text-primary-foreground font-bold text-lg">P</span>
              </div>
            )}
            
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleSidebar}
              className={`h-8 w-8 p-0 transition-all duration-300 ${
                sidebarCollapsed ? 'absolute right-2 top-6' : 'relative'
              }`}
              title={sidebarCollapsed ? 'Mở rộng sidebar' : 'Thu gọn sidebar'}
            >
              {sidebarCollapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
            </Button>
          </div>

          {/* Navigation */}
          <div className="flex-grow flex flex-col">
            <nav className="flex-1 px-4 pb-4 space-y-2" role="navigation" aria-label="Sidebar navigation">
              {navItems.map((item) => {
                const Icon = item.icon;
                const active = isActive(item.href);
                
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`group flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 ${
                      active
                        ? 'bg-gradient-to-r from-primary to-primary/90 text-primary-foreground shadow-lg'
                        : 'text-muted-foreground hover:bg-gradient-to-r hover:from-primary/10 hover:to-primary/5 hover:text-primary'
                    } ${sidebarCollapsed ? 'justify-center' : ''}`}
                    aria-current={active ? 'page' : undefined}
                    title={sidebarCollapsed ? item.label : undefined}
                  >
                    <Icon className="w-4 h-4 flex-shrink-0" />
                    <span className={`transition-all duration-300 ${
                      sidebarCollapsed ? 'opacity-0 w-0 overflow-hidden' : 'opacity-100'
                    }`}>
                      {item.label}
                    </span>
                  </Link>
                );
              })}
            </nav>

            {/* User Profile Card */}
            <div className="p-4">
              <div className="bg-gradient-to-r from-primary/10 to-primary/5 rounded-xl p-4 border border-primary/20">
                <div className={`flex items-center gap-3 ${sidebarCollapsed ? 'justify-center' : ''}`}>
                  <div className="w-8 h-8 bg-gradient-to-br from-primary to-primary/80 rounded-lg flex items-center justify-center flex-shrink-0">
                    <span className="text-primary-foreground font-semibold text-sm">
                      {user?.email?.charAt(0).toUpperCase() || 'U'}
                    </span>
                  </div>
                  <div className={`flex-1 min-w-0 transition-all duration-300 ${
                    sidebarCollapsed ? 'opacity-0 w-0 overflow-hidden' : 'opacity-100'
                  }`}>
                    <p className="text-sm font-medium text-foreground truncate">
                      {user?.email || 'User'}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Đang hoạt động
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Mobile Sidebar Overlay */}
      {mobileMenuOpen && (
        <div className="lg:hidden fixed inset-0 z-50 flex">
          {/* Backdrop */}
          <div 
            className="fixed inset-0 bg-black/50 backdrop-blur-sm"
            onClick={() => setMobileMenuOpen(false)}
            aria-hidden="true"
          />
          
          {/* Sidebar */}
          <div 
            className="relative flex flex-col w-80 max-w-[80vw] bg-gradient-to-b from-card to-card/50 border-r border-border/50 backdrop-blur-sm shadow-2xl"
            role="dialog"
            aria-modal="true"
            aria-label="Mobile navigation menu"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-border/50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-xl flex items-center justify-center shadow-lg">
                  <span className="text-primary-foreground font-bold text-lg">P</span>
                </div>
                <div>
                  <h1 className="text-xl font-bold text-foreground">POS Mini</h1>
                  <p className="text-xs text-muted-foreground">Modular System</p>
                </div>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setMobileMenuOpen(false)}
                className="h-8 w-8 p-0"
                aria-label="Close menu"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>

            {/* Navigation */}
            <nav className="flex-1 px-4 py-4 space-y-2 overflow-y-auto" role="navigation" aria-label="Mobile navigation">
              {navItems.map((item) => {
                const Icon = item.icon;
                const active = isActive(item.href);
                
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`group flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 ${
                      active
                        ? 'bg-gradient-to-r from-primary to-primary/90 text-primary-foreground shadow-lg'
                        : 'text-muted-foreground hover:bg-gradient-to-r hover:from-primary/10 hover:to-primary/5 hover:text-primary'
                    }`}
                    aria-current={active ? 'page' : undefined}
                  >
                    <Icon className="w-4 h-4" />
                    {item.label}
                  </Link>
                );
              })}
            </nav>

            {/* User Profile */}
            <div className="p-4 border-t border-border/50">
              <div className="bg-gradient-to-r from-primary/10 to-primary/5 rounded-xl p-4 border border-primary/20">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-gradient-to-br from-primary to-primary/80 rounded-lg flex items-center justify-center">
                    <span className="text-primary-foreground font-semibold text-sm">
                      {user?.email?.charAt(0).toUpperCase() || 'U'}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground truncate">
                      {user?.email || 'User'}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Đang hoạt động
                    </p>
                  </div>
                </div>
                <div className="mt-3 pt-3 border-t border-border/20 flex gap-2">
                  <ThemeSwitcher />
                  <LogoutButton />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        {/* Header */}
        <header className="bg-gradient-to-r from-card/95 to-card/80 backdrop-blur-lg border-b border-border/50 px-4 lg:px-8 py-4 sticky top-0 z-40">
          <div className="flex items-center justify-between">
            {/* Left Side */}
            <div className="flex items-center gap-4">
              {/* Mobile Menu Button */}
              <Button
                variant="ghost"
                size="sm"
                className="lg:hidden h-8 w-8 p-0"
                onClick={() => setMobileMenuOpen(true)}
                aria-label="Open navigation menu"
              >
                <Menu className="w-5 h-5" />
              </Button>
              
              {/* Desktop Sidebar Toggle - Only show when sidebar is collapsed */}
              <Button
                variant="ghost"
                size="sm"
                className={`hidden lg:flex h-8 w-8 p-0 transition-opacity duration-300 ${
                  sidebarCollapsed ? 'opacity-100' : 'opacity-0 pointer-events-none'
                }`}
                onClick={toggleSidebar}
                aria-label="Expand sidebar"
              >
                <Menu className="w-5 h-5" />
              </Button>
              
              {/* Title */}
              <div className="space-y-1">
                <h2 className="text-xl lg:text-2xl font-bold text-foreground">
                  Dashboard
                </h2>
                <p className="text-xs lg:text-sm text-muted-foreground hidden sm:block">
                  Chào mừng trở lại, <span className="font-medium text-primary">{user?.email}</span>
                </p>
              </div>
            </div>
            
            {/* Right Side */}
            <div className="flex items-center gap-2 lg:gap-3">
              {/* Search - Desktop Only */}
              <div className="hidden xl:flex relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <Input
                  placeholder="Tìm kiếm..."
                  className="pl-10 w-80 bg-background/50 border-border/50 focus:bg-background transition-colors"
                />
              </div>
              
              {/* Status Indicator - Hidden on small screens */}
              <div className="hidden sm:flex items-center gap-2 px-3 py-2 bg-primary/10 rounded-lg">
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                <span className="text-sm font-medium text-primary">Online</span>
              </div>
              
              {/* Notifications */}
              <Button variant="ghost" size="sm" className="relative h-8 w-8 p-0" aria-label="Notifications">
                <Bell className="w-4 h-4" />
                <span className="absolute -top-1 -right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </Button>
              
              {/* Theme Switcher - Desktop Only */}
              <div className="hidden lg:block">
                <ThemeSwitcher />
              </div>
              
              {/* Logout Button - Desktop Only */}
              <div className="hidden lg:block">
                <LogoutButton />
              </div>
            </div>
          </div>
          
          {/* Mobile Search */}
          <div className="xl:hidden mt-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Tìm kiếm..."
                className="pl-10 bg-background/50 border-border/50 focus:bg-background transition-colors"
              />
            </div>
          </div>
        </header>
        
        {/* Main Content */}
        <main className="flex-1 bg-gradient-to-br from-background to-background/80 pb-20 lg:pb-8">
          {children}
        </main>
        
        {/* Mobile Bottom Navigation */}
        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-gradient-to-t from-card to-card/80 backdrop-blur-lg border-t border-border/50 px-2 py-2 z-40">
          <nav className="flex justify-around items-center" role="navigation" aria-label="Bottom navigation">
            {navItems.slice(0, 5).map((item) => {
              const Icon = item.icon;
              const active = isActive(item.href);
              
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex flex-col items-center gap-1 p-2 rounded-lg transition-colors min-w-0 ${
                    active ? 'text-primary' : 'text-muted-foreground'
                  }`}
                  aria-current={active ? 'page' : undefined}
                >
                  <Icon className="w-5 h-5 flex-shrink-0" />
                  <span className="text-xs font-medium truncate">{item.label}</span>
                </Link>
              );
            })}
            {/* More button for additional items */}
            <Button
              variant="ghost"
              size="sm"
              className="flex flex-col items-center gap-1 p-2 h-auto text-muted-foreground min-w-0"
              onClick={() => setMobileMenuOpen(true)}
              aria-label="More navigation options"
            >
              <Menu className="w-5 h-5 flex-shrink-0" />
              <span className="text-xs truncate">Thêm</span>
            </Button>
          </nav>
        </div>
      </div>
    </div>
  );
}