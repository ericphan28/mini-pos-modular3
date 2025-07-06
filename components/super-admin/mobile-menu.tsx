"use client";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import {
    AlertTriangle,
    BarChart3,
    Building2,
    ChevronDown,
    Crown,
    Database,
    Heart,
    Menu,
    Plus,
    RefreshCw,
    Settings,
    Shield,
    TrendingUp,
    Users,
    X
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

const navigation = [
  { 
    name: "Tổng quan", 
    href: "/super-admin", 
    icon: Shield,
    description: "Dashboard chính"
  },
  { 
    name: "Hộ kinh doanh", 
    href: "/super-admin/businesses", 
    icon: Building2,
    description: "Quản lý hộ KD"
  },
  { 
    name: "Người dùng", 
    href: "/super-admin/users", 
    icon: Users,
    description: "Quản lý users"
  },
  { 
    name: "Thống kê", 
    href: "/super-admin/analytics", 
    icon: BarChart3,
    description: "Phân tích dữ liệu"
  },
  { 
    name: "Hệ thống", 
    href: "/super-admin/system", 
    icon: Database,
    description: "Quản lý hệ thống"
  },
  { 
    name: "Backup & Restore", 
    href: "/super-admin/backup", 
    icon: Shield,
    description: "Sao lưu & khôi phục",
    subItems: [
      {
        name: "Backup Manager",
        href: "/super-admin/backup",
        icon: Database
      },
      {
        name: "Restore Manager", 
        href: "/super-admin/restore",
        icon: RefreshCw
      }
    ]
  },
  { 
    name: "Cài đặt", 
    href: "/super-admin/settings", 
    icon: Settings,
    description: "Cấu hình"
  },
];

const quickActions = [
  {
    name: "Tạo hộ KD",
    href: "/super-admin/create-business",
    icon: Plus,
    color: "text-green-600 dark:text-green-400"
  },
  {
    name: "Báo cáo",
    href: "/super-admin/reports",
    icon: TrendingUp,
    color: "text-blue-600 dark:text-blue-400"
  },
  {
    name: "Cảnh báo",
    href: "/super-admin/alerts",
    icon: AlertTriangle,
    color: "text-amber-600 dark:text-amber-400"
  }
];

interface MobileMenuProps {
  isOpen: boolean;
  onClose: () => void;
}

export function MobileMenu({ isOpen, onClose }: MobileMenuProps) {
  const pathname = usePathname();
  const [expandedMenu, setExpandedMenu] = useState<string | null>(null);

  // Close sidebar when route changes
  useEffect(() => {
    onClose();
  }, [pathname, onClose]);

  // Close sidebar when clicking outside
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <>
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm z-40 md:hidden"
        onClick={onClose}
      />
      
      {/* Mobile Menu */}
      <div className={cn(
        "fixed top-0 left-0 h-full w-80 bg-white dark:bg-gray-900 z-50 transform transition-transform duration-300 ease-in-out md:hidden shadow-2xl",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl flex items-center justify-center shadow-lg">
                <Crown className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-lg font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
                  Super Admin
                </h1>
                <p className="text-xs text-muted-foreground">
                  Gia Kiệm Số System
                </p>
              </div>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={onClose}
              className="p-2"
            >
              <X className="w-5 h-5" />
            </Button>
          </div>

          {/* Navigation */}
          <div className="flex-1 overflow-y-auto">
            <nav className="p-4 space-y-2">
              {navigation.map((item) => {
                const isActive = pathname === item.href || 
                  (item.href !== "/super-admin" && pathname.startsWith(item.href));
                const hasSubItems = item.subItems && item.subItems.length > 0;
                const isExpanded = expandedMenu === item.name;
                
                return (
                  <div key={item.name}>
                    {hasSubItems ? (
                      <div>
                        <button
                          onClick={() => setExpandedMenu(isExpanded ? null : item.name)}
                          className={cn(
                            "group w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200",
                            isActive
                              ? "bg-gradient-to-r from-purple-600 to-purple-700 text-white shadow-lg shadow-purple-500/25"
                              : "text-muted-foreground hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 hover:text-purple-700 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 dark:hover:text-purple-300"
                          )}
                        >
                          <item.icon className={cn(
                            "flex-shrink-0 w-5 h-5",
                            isActive ? "text-white" : "text-muted-foreground group-hover:text-purple-600"
                          )} />
                          <div className="flex-1 min-w-0 text-left">
                            <div className="font-medium">{item.name}</div>
                            <div className={cn(
                              "text-xs truncate",
                              isActive ? "text-purple-100" : "text-muted-foreground"
                            )}>
                              {item.description}
                            </div>
                          </div>
                          <ChevronDown className={cn(
                            "w-4 h-4 transition-transform",
                            isExpanded ? "rotate-180" : "",
                            isActive ? "text-white" : "text-muted-foreground"
                          )} />
                        </button>
                        
                        {isExpanded && (
                          <div className="mt-2 ml-4 space-y-1">
                            {item.subItems.map((subItem) => {
                              const isSubActive = pathname === subItem.href;
                              return (
                                <Link
                                  key={subItem.name}
                                  href={subItem.href}
                                  className={cn(
                                    "group flex items-center gap-3 px-4 py-2 text-sm rounded-lg transition-all duration-200",
                                    isSubActive
                                      ? "bg-purple-100 text-purple-700 dark:bg-purple-900/50 dark:text-purple-300"
                                      : "text-muted-foreground hover:bg-purple-50 hover:text-purple-600 dark:hover:bg-purple-900/30 dark:hover:text-purple-300"
                                  )}
                                >
                                  <subItem.icon className="w-4 h-4" />
                                  {subItem.name}
                                </Link>
                              );
                            })}
                          </div>
                        )}
                      </div>
                    ) : (
                      <Link
                        href={item.href}
                        className={cn(
                          "group flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200",
                          isActive
                            ? "bg-gradient-to-r from-purple-600 to-purple-700 text-white shadow-lg shadow-purple-500/25"
                            : "text-muted-foreground hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 hover:text-purple-700 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 dark:hover:text-purple-300"
                        )}
                      >
                        <item.icon className={cn(
                          "flex-shrink-0 w-5 h-5",
                          isActive ? "text-white" : "text-muted-foreground group-hover:text-purple-600"
                        )} />
                        <div className="flex-1 min-w-0">
                          <div className="font-medium">{item.name}</div>
                          <div className={cn(
                            "text-xs truncate",
                            isActive ? "text-purple-100" : "text-muted-foreground"
                          )}>
                            {item.description}
                          </div>
                        </div>
                      </Link>
                    )}
                  </div>
                );
              })}
            </nav>

            {/* Quick Actions */}
            <div className="px-4 py-4 border-t border-border/50">
              <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3 px-4">
                Thao tác nhanh
              </div>
              <div className="space-y-1">
                {quickActions.map((action) => (
                  <Link
                    key={action.name}
                    href={action.href}
                    className="group flex items-center gap-3 px-4 py-2 text-sm text-muted-foreground hover:text-foreground rounded-lg hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 transition-all duration-200"
                  >
                    <action.icon className={cn("w-4 h-4", action.color)} />
                    {action.name}
                  </Link>
                ))}
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="p-4 border-t border-border/50">
            <div className="rounded-xl p-4 bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-200/50 dark:border-purple-800/50">
              <div className="text-center">
                <Heart className="w-5 h-5 text-purple-600 mx-auto mb-2" />
                <div className="text-xs text-purple-700 dark:text-purple-300 font-medium">
                  GiaKiemSo.com
                </div>
                <div className="text-xs text-purple-600/70 dark:text-purple-400/70">
                  Giải pháp POS Mini toàn diện
                </div>
                <div className="flex items-center justify-center gap-2 mt-2 text-xs">
                  <span className="text-green-600 font-medium">99.9%</span>
                  <span className="text-purple-600/70">Uptime</span>
                  <span className="text-blue-600 font-medium">24/7</span>
                  <span className="text-purple-600/70">Hỗ trợ</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

// Mobile Menu Button Component
export function MobileMenuButton({ onClick }: { onClick: () => void }) {
  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={onClick}
      className="md:hidden p-2"
    >
      <Menu className="w-5 h-5" />
    </Button>
  );
}
