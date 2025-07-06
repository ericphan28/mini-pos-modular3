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
  { name: "Tổng quan", href: "/super-admin", icon: Shield },
  { name: "Hộ kinh doanh", href: "/super-admin/businesses", icon: Building2 },
  { name: "Người dùng", href: "/super-admin/users", icon: Users },
  { name: "Thống kê", href: "/super-admin/analytics", icon: BarChart3 },
  { name: "Hệ thống", href: "/super-admin/system", icon: Database },
  { 
    name: "Backup & Restore", 
    href: "/super-admin/backup", 
    icon: Shield,
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
  { name: "Cài đặt", href: "/super-admin/settings", icon: Settings },
];

const quickActions = [
  { name: "Tạo hộ KD", href: "/super-admin/create-business", icon: Plus },
  { name: "Báo cáo", href: "/super-admin/reports", icon: TrendingUp },
  { name: "Cảnh báo", href: "/super-admin/alerts", icon: AlertTriangle }
];

interface SuperAdminMobileSidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export function SuperAdminMobileSidebar({ isOpen, onClose }: SuperAdminMobileSidebarProps) {
  const pathname = usePathname();
  const [expandedMenu, setExpandedMenu] = useState<string | null>(null);

  // Prevent scrolling when sidebar is open
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

  // Close on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 md:hidden">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-gray-900/80 transition-opacity duration-300"
        onClick={onClose}
      />
      
      {/* Sidebar */}
      <div className={cn(
        "fixed inset-y-0 left-0 w-full max-w-xs bg-gradient-to-b from-white to-purple-50/30 dark:from-gray-900 dark:to-purple-900/30 shadow-xl transition-transform duration-300 ease-in-out",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex flex-col h-full pt-6 pb-4 overflow-y-auto">
          {/* Close button */}
          <div className="absolute top-4 right-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={onClose}
              className="text-muted-foreground hover:text-foreground hover:bg-muted"
            >
              <X className="w-5 h-5" />
              <span className="sr-only">Đóng menu</span>
            </Button>
          </div>

          {/* Logo */}
          <div className="flex items-center flex-shrink-0 px-6 mb-6">
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
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 space-y-2">
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
                        <span className="flex-1 text-left">{item.name}</span>
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
                                onClick={onClose}
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
                      key={item.name}
                      href={item.href}
                      onClick={onClose}
                      className={cn(
                        "group flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200",
                        isActive
                          ? "bg-gradient-to-r from-purple-600 to-purple-700 text-white shadow-lg shadow-purple-500/25"
                          : "text-muted-foreground hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 hover:text-purple-700 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 dark:hover:text-purple-300"
                      )}
                    >
                      <item.icon className="w-5 h-5" />
                      {item.name}
                    </Link>
                  )}
                </div>
              );
            })}
          </nav>

          {/* Quick Actions */}
          <div className="px-4 pb-6">
            <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3 px-4">
              Thao tác nhanh
            </div>
            <div className="space-y-1">
              {quickActions.map((action) => (
                <Link
                  key={action.name}
                  href={action.href}
                  onClick={onClose}
                  className="group flex items-center gap-3 px-4 py-2 text-sm text-muted-foreground hover:text-foreground rounded-lg hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 transition-all duration-200"
                >
                  <action.icon className="w-4 h-4" />
                  {action.name}
                </Link>
              ))}
            </div>
          </div>

          {/* Footer */}
          <div className="px-4 mt-auto">
            <div className="rounded-xl p-4 bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-200/50 dark:border-purple-800/50">
              <div className="text-center">
                <Heart className="w-5 h-5 text-purple-600 mx-auto mb-2" />
                <div className="text-xs text-purple-700 dark:text-purple-300 font-medium">
                  GiaKiemSo.com
                </div>
                <div className="text-xs text-purple-600/70 dark:text-purple-400/70">
                  Giải pháp POS Mini toàn diện
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
