"use client";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import {
  AlertTriangle,
  BarChart3,
  Building2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Crown,
  Database,
  Heart,
  Plus,
  RefreshCw,
  Settings,
  Shield,
  TrendingUp,
  Users
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

// 🔧 FIX: Persistent sidebar state
const SIDEBAR_STORAGE_KEY = 'super-admin-sidebar-collapsed';

export function SuperAdminSidebar() {
  const pathname = usePathname();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [expandedMenu, setExpandedMenu] = useState<string | null>(null);

  // 🔧 FIX: Load sidebar state from localStorage
  useEffect(() => {
    const saved = localStorage.getItem(SIDEBAR_STORAGE_KEY);
    if (saved !== null) {
      setIsCollapsed(JSON.parse(saved));
    }
    setMounted(true);
  }, []);

  // 🔧 FIX: Save sidebar state to localStorage
  useEffect(() => {
    if (mounted) {
      localStorage.setItem(SIDEBAR_STORAGE_KEY, JSON.stringify(isCollapsed));
    }
  }, [isCollapsed, mounted]);

  // 🔧 FIX: Prevent hydration mismatch
  if (!mounted) {
    return (
      <div className="hidden md:flex md:flex-col md:w-72">
        <div className="flex flex-col flex-grow pt-6 overflow-y-auto bg-gradient-to-b from-white to-purple-50/30 dark:from-gray-900 dark:to-purple-900/30 border-r border-border/50 backdrop-blur-sm">
          {/* Loading skeleton */}
          <div className="animate-pulse">
            <div className="h-16 bg-gray-200 dark:bg-gray-700 mx-6 mb-6 rounded"></div>
            <div className="space-y-2 px-4">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="h-12 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={cn(
      "hidden md:flex md:flex-col transition-all duration-300",
      isCollapsed ? "md:w-16" : "md:w-72"
    )}>
      <div className="flex flex-col flex-grow pt-6 overflow-y-auto bg-gradient-to-b from-white to-purple-50/30 dark:from-gray-900 dark:to-purple-900/30 border-r border-border/50 backdrop-blur-sm">
        {/* Logo & Branding */}
        <div className="flex items-center flex-shrink-0 px-6 mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl flex items-center justify-center shadow-lg">
              <Crown className="w-6 h-6 text-white" />
            </div>
            {/* Hide text on mobile, show on desktop when not collapsed */}
            {!isCollapsed && (
              <div>
                <h1 className="text-lg font-bold bg-gradient-to-r from-purple-700 to-purple-900 dark:from-purple-300 dark:to-purple-100 bg-clip-text text-transparent">
                  Super Admin
                </h1>
                <p className="text-xs text-muted-foreground">
                  Gia Kiệm Số System
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Collapse Button */}
        <div className="px-4 mb-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="w-full justify-start text-muted-foreground hover:text-foreground"
          >
            {isCollapsed ? (
              <ChevronRight className="w-4 h-4" />
            ) : (
              <>
                <ChevronLeft className="w-4 h-4 mr-2" />
                Thu gọn
              </>
            )}
          </Button>
        </div>

        {/* Navigation */}
        <div className="flex-grow flex flex-col">
          <nav className="flex-1 px-4 pb-4 space-y-2">
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
                            : "text-muted-foreground hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 hover:text-purple-700 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 dark:hover:text-purple-300",
                          // Desktop responsive
                          isCollapsed && "justify-center px-2"
                        )}
                      >
                        <item.icon className={cn(
                          "flex-shrink-0 w-5 h-5",
                          isActive ? "text-white" : "text-muted-foreground group-hover:text-purple-600"
                        )} />
                        {/* Show text when not collapsed */}
                        {!isCollapsed && (
                          <div className="flex-1 min-w-0 text-left">
                            <div className="font-medium">{item.name}</div>
                            <div className={cn(
                              "text-xs truncate",
                              isActive ? "text-purple-100" : "text-muted-foreground"
                            )}>
                              {item.description}
                            </div>
                          </div>
                        )}
                        {!isCollapsed && (
                          <ChevronDown className={cn(
                            "w-4 h-4 transition-transform",
                            isExpanded ? "rotate-180" : "",
                            isActive ? "text-white" : "text-muted-foreground"
                          )} />
                        )}
                      </button>
                      
                      {!isCollapsed && isExpanded && (
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
                          : "text-muted-foreground hover:bg-gradient-to-r hover:from-purple-50 hover:to-purple-100 hover:text-purple-700 dark:hover:from-purple-900/30 dark:hover:to-purple-800/30 dark:hover:text-purple-300",
                        // Desktop responsive
                        isCollapsed && "justify-center px-2"
                      )}
                    >
                      <item.icon className={cn(
                        "flex-shrink-0 w-5 h-5",
                        isActive ? "text-white" : "text-muted-foreground group-hover:text-purple-600"
                      )} />
                      {/* Show text when not collapsed */}
                      {!isCollapsed && (
                        <div className="flex-1 min-w-0">
                          <div className="font-medium">{item.name}</div>
                          <div className={cn(
                            "text-xs truncate",
                            isActive ? "text-purple-100" : "text-muted-foreground"
                          )}>
                            {item.description}
                          </div>
                        </div>
                      )}
                    </Link>
                  )}
                </div>
              );
            })}
          </nav>

          {/* Quick Actions */}
          {!isCollapsed && (
            <div className="px-4 pb-6">
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
          )}

          {/* Footer */}
          <div className="px-4 pb-6 mt-auto">
            <div className={cn(
              "rounded-xl p-4 bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-200/50 dark:border-purple-800/50",
              isCollapsed && "px-2"
            )}>
              {!isCollapsed ? (
                <div className="text-center">
                  <Heart className="w-5 h-5 text-purple-600 mx-auto mb-2" />
                  <div className="text-xs text-purple-700 dark:text-purple-300 font-medium">
                    GiaKiemSo.com
                  </div>
                  <div className="text-xs text-purple-600/70 dark:text-purple-400/70">
                    Giải pháp POS Mini toàn diện cho doanh nghiệp Việt - Tin cậy bởi 1000+ DN
                  </div>
                  <div className="flex items-center justify-center gap-2 mt-2 text-xs">
                    <span className="text-green-600 font-medium">99.9%</span>
                    <span className="text-purple-600/70">Uptime</span>
                    <span className="text-blue-600 font-medium">24/7</span>
                    <span className="text-purple-600/70">Hỗ trợ</span>
                  </div>
                </div>
              ) : (
                <div className="text-center">
                  <Heart className="w-5 h-5 text-purple-600 mx-auto" />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
