'use client';

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { createClient } from "@/lib/supabase/client";
import {
    AlertTriangle,
    ArrowUpDown,
    Building2,
    CheckCircle,
    ChevronLeft,
    ChevronRight,
    ChevronsLeft,
    ChevronsRight,
    Clock,
    Edit,
    Eye,
    Filter,
    Mail,
    MoreHorizontal,
    RefreshCw,
    Search,
    TrendingDown,
    TrendingUp,
    Users,
    XCircle
} from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";

// 📊 Professional Types & Constants
interface BusinessInfo {
  id: string;
  business_name: string;
  business_code: string;
  business_type: string;
  status: string;
  subscription_tier: string;
  subscription_status: string;
  trial_ends_at: string;
  subscription_ends_at: string;
  created_at: string;
  updated_at: string;
  owner_name: string;
  owner_email: string;
  owner_status: string;
  owner_id: string;
  total_staff: number;
  active_staff: number;
}

interface BusinessListProps {
  businesses: BusinessInfo[];
  onRefresh?: () => void;
}

type SortField = keyof Pick<BusinessInfo, 
  'business_name' | 'business_type' | 'status' | 'subscription_tier' | 
  'created_at' | 'trial_ends_at' | 'owner_name' | 'active_staff' | 'total_staff'
>;

type SortDirection = 'asc' | 'desc';
type FilterValues = {
  search: string;
  status: string;
  type: string;
  tier: string;
  staffRange: string;
  expiryRange: string;
};

interface SortConfig {
  field: SortField;
  direction: SortDirection;
}

// 🎯 Performance Constants
const ITEMS_PER_PAGE_OPTIONS = [10, 25, 50, 100] as const;
const DEFAULT_ITEMS_PER_PAGE = 25;
const SEARCH_DEBOUNCE_MS = 300;

// 🎨 Professional Business Type Mapping
const BUSINESS_TYPE_CONFIG = {
  retail: { label: 'Bán lẻ', icon: '🛍️', color: 'blue' },
  restaurant: { label: 'Nhà hàng', icon: '🍽️', color: 'orange' },
  cafe: { label: 'Quán cà phê', icon: '☕', color: 'amber' },
  food_service: { label: 'Dịch vụ ăn uống', icon: '🥘', color: 'yellow' },
  beauty: { label: 'Làm đẹp', icon: '💄', color: 'pink' },
  spa: { label: 'Spa', icon: '🧖‍♀️', color: 'purple' },
  salon: { label: 'Salon', icon: '💇‍♀️', color: 'violet' },
  healthcare: { label: 'Y tế', icon: '🏥', color: 'red' },
  pharmacy: { label: 'Nhà thuốc', icon: '💊', color: 'green' },
  clinic: { label: 'Phòng khám', icon: '🩺', color: 'emerald' },
  education: { label: 'Giáo dục', icon: '📚', color: 'indigo' },
  gym: { label: 'Phòng gym', icon: '🏋️‍♀️', color: 'slate' },
  fashion: { label: 'Thời trang', icon: '👗', color: 'rose' },
  electronics: { label: 'Điện tử', icon: '📱', color: 'cyan' },
  automotive: { label: 'Ô tô', icon: '🚗', color: 'gray' },
  repair: { label: 'Sửa chữa', icon: '🔧', color: 'zinc' },
  cleaning: { label: 'Vệ sinh', icon: '🧽', color: 'lime' },
  construction: { label: 'Xây dựng', icon: '🏗️', color: 'stone' },
  consulting: { label: 'Tư vấn', icon: '💼', color: 'neutral' },
  finance: { label: 'Tài chính', icon: '💰', color: 'green' },
  real_estate: { label: 'Bất động sản', icon: '🏠', color: 'teal' },
  travel: { label: 'Du lịch', icon: '✈️', color: 'sky' },
  hotel: { label: 'Khách sạn', icon: '🏨', color: 'blue' },
  entertainment: { label: 'Giải trí', icon: '🎪', color: 'fuchsia' },
  sports: { label: 'Thể thao', icon: '⚽', color: 'orange' },
  agriculture: { label: 'Nông nghiệp', icon: '🌾', color: 'yellow' },
  manufacturing: { label: 'Sản xuất', icon: '🏭', color: 'gray' },
  wholesale: { label: 'Bán sỉ', icon: '📦', color: 'slate' },
  logistics: { label: 'Vận chuyển', icon: '🚚', color: 'amber' },
  service: { label: 'Dịch vụ', icon: '🛠️', color: 'blue' },
  other: { label: 'Khác', icon: '📋', color: 'gray' }
} as const;

// 🎯 Status Configuration
const STATUS_CONFIG = {
  active: { 
    label: 'Hoạt động', 
    icon: CheckCircle, 
    color: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400',
    priority: 1
  },
  trial: { 
    label: 'Dùng thử', 
    icon: Clock, 
    color: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
    priority: 2
  },
  suspended: { 
    label: 'Tạm dừng', 
    icon: AlertTriangle, 
    color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400',
    priority: 3
  },
  cancelled: { 
    label: 'Đã hủy', 
    icon: XCircle, 
    color: 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400',
    priority: 4
  }
} as const;

// 🚀 Performance Monitoring
class PerformanceMonitor {
  private static instance: PerformanceMonitor;
  private metrics: Map<string, number[]> = new Map();

  static getInstance() {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }

  startTimer(operation: string) {
    const start = performance.now();
    console.time(`🚀 [BUSINESS-LIST] ${operation}`);
    return {
      end: () => {
        const duration = performance.now() - start;
        console.timeEnd(`🚀 [BUSINESS-LIST] ${operation}`);
        
        if (!this.metrics.has(operation)) {
          this.metrics.set(operation, []);
        }
        this.metrics.get(operation)!.push(duration);
        
        // Log performance metrics
        const times = this.metrics.get(operation)!;
        const avg = times.reduce((a, b) => a + b, 0) / times.length;
        const latest = times[times.length - 1];
        
        console.log(`📊 [PERFORMANCE] ${operation}: ${latest.toFixed(2)}ms (avg: ${avg.toFixed(2)}ms)`);
        
        // Warning for slow operations
        if (latest > 100) {
          console.warn(`⚠️ [SLOW-OPERATION] ${operation} took ${latest.toFixed(2)}ms`);
        }
      }
    };
  }

  getMetrics() {
    const summary: Record<string, { avg: number; count: number; latest: number }> = {};
    
    for (const [operation, times] of this.metrics) {
      summary[operation] = {
        avg: times.reduce((a, b) => a + b, 0) / times.length,
        count: times.length,
        latest: times[times.length - 1] || 0
      };
    }
    
    return summary;
  }
}

// 🧠 Smart Search Algorithm
class SmartSearchEngine {
  private static normalizeString(str: string): string {
    return str
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D');
  }

  static search(businesses: BusinessInfo[], term: string): BusinessInfo[] {
    if (!term.trim()) return businesses;

    const normalizedTerm = this.normalizeString(term);
    const terms = normalizedTerm.split(/\s+/).filter(t => t.length > 0);

    return businesses.filter(business => {
      const searchableText = [
        business.business_name,
        business.business_code,
        business.owner_name,
        business.owner_email,
        BUSINESS_TYPE_CONFIG[business.business_type as keyof typeof BUSINESS_TYPE_CONFIG]?.label || business.business_type
      ].join(' ');

      const normalizedText = this.normalizeString(searchableText);

      // Exact match gets highest priority
      if (normalizedText.includes(normalizedTerm)) return true;

      // All terms must match (AND logic)
      return terms.every(term => normalizedText.includes(term));
    });
  }
}

// 📊 Analytics Helper
class BusinessAnalytics {
  static getInsights(businesses: BusinessInfo[]) {
    const timer = PerformanceMonitor.getInstance().startTimer('Analytics Calculation');
    
    const insights = {
      total: businesses.length,
      byStatus: this.groupBy(businesses, 'status'),
      byType: this.groupBy(businesses, 'business_type'),
      byTier: this.groupBy(businesses, 'subscription_tier'),
      expiringCount: this.getExpiringCount(businesses),
      averageStaff: this.getAverageStaff(businesses),
      trends: this.getTrends(businesses)
    };
    
    timer.end();
    
    console.log('📈 [ANALYTICS] Business Insights:', insights);
    return insights;
  }

  private static groupBy<T, K extends keyof T>(array: T[], key: K): Record<string, number> {
    return array.reduce((acc, item) => {
      const value = String(item[key]);
      acc[value] = (acc[value] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
  }

  private static getExpiringCount(businesses: BusinessInfo[]): number {
    const today = new Date();
    const sevenDaysFromNow = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    return businesses.filter(business => {
      const expiryDate = new Date(business.trial_ends_at || business.subscription_ends_at);
      return expiryDate >= today && expiryDate <= sevenDaysFromNow;
    }).length;
  }

  private static getAverageStaff(businesses: BusinessInfo[]): number {
    if (businesses.length === 0) return 0;
    return businesses.reduce((sum, b) => sum + (b.active_staff || 0), 0) / businesses.length;
  }

  private static getTrends(businesses: BusinessInfo[]) {
    const last30Days = businesses.filter(b => {
      const created = new Date(b.created_at);
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      return created >= thirtyDaysAgo;
    });

    return {
      newBusinesses: last30Days.length,
      growthRate: businesses.length > 0 ? (last30Days.length / businesses.length) * 100 : 0
    };
  }
}

export function BusinessListProfessional({ businesses, onRefresh }: BusinessListProps) {
  // 🚀 Performance monitoring
  const perfMonitor = PerformanceMonitor.getInstance();
  const renderTimer = useRef(perfMonitor.startTimer('Component Render'));

  // 📊 State Management
  const [filters, setFilters] = useState<FilterValues>({
    search: '',
    status: 'all',
    type: 'all',
    tier: 'all',
    staffRange: 'all',
    expiryRange: 'all'
  });

  const [sortConfig, setSortConfig] = useState<SortConfig>({
    field: 'created_at',
    direction: 'desc'
  });

  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(DEFAULT_ITEMS_PER_PAGE);
  const [loadingUpdates, setLoadingUpdates] = useState<Set<string>>(new Set());
  const [isRefreshing, setIsRefreshing] = useState(false);

  // 🔍 Debounced Search
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    searchTimeoutRef.current = setTimeout(() => {
      setDebouncedSearchTerm(filters.search);
      setCurrentPage(1);
    }, SEARCH_DEBOUNCE_MS);

    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
    };
  }, [filters.search]);

  // 📊 Optimized Data Processing
  const processedData = useMemo(() => {
    const timer = perfMonitor.startTimer('Data Processing');
    
    console.log('🔄 [PROCESSING] Starting data processing...', {
      inputCount: businesses.length,
      filters,
      sortConfig
    });

    // Step 1: Smart Search
    let filtered = SmartSearchEngine.search(businesses, debouncedSearchTerm);
    console.log('🔍 [SEARCH] Search results:', filtered.length);

    // Step 2: Advanced Filtering
    filtered = filtered.filter(business => {
      const statusMatch = filters.status === 'all' || business.status === filters.status;
      const typeMatch = filters.type === 'all' || business.business_type === filters.type;
      const tierMatch = filters.tier === 'all' || business.subscription_tier === filters.tier;
      
      // Staff range filtering
      let staffMatch = true;
      if (filters.staffRange !== 'all') {
        const staff = business.active_staff || 0;
        switch (filters.staffRange) {
          case '0':
            staffMatch = staff === 0;
            break;
          case '1-5':
            staffMatch = staff >= 1 && staff <= 5;
            break;
          case '6-20':
            staffMatch = staff >= 6 && staff <= 20;
            break;
          case '21+':
            staffMatch = staff >= 21;
            break;
        }
      }

      // Expiry range filtering
      let expiryMatch = true;
      if (filters.expiryRange !== 'all') {
        const expiryDate = new Date(business.trial_ends_at || business.subscription_ends_at);
        const today = new Date();
        const daysUntilExpiry = Math.ceil((expiryDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
        
        switch (filters.expiryRange) {
          case 'expired':
            expiryMatch = daysUntilExpiry < 0;
            break;
          case '0-7':
            expiryMatch = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
            break;
          case '8-30':
            expiryMatch = daysUntilExpiry >= 8 && daysUntilExpiry <= 30;
            break;
          case '31+':
            expiryMatch = daysUntilExpiry > 30;
            break;
        }
      }

      return statusMatch && typeMatch && tierMatch && staffMatch && expiryMatch;
    });

    console.log('🔧 [FILTER] After filtering:', filtered.length);

    // Step 3: Intelligent Sorting
    filtered.sort((a, b) => {
      let aValue: string | number = a[sortConfig.field];
      let bValue: string | number = b[sortConfig.field];
      
      // Handle different data types
      if (sortConfig.field === 'active_staff' || sortConfig.field === 'total_staff') {
        aValue = Number(aValue) || 0;
        bValue = Number(bValue) || 0;
      } else if (sortConfig.field === 'created_at' || sortConfig.field === 'trial_ends_at') {
        aValue = new Date(aValue || 0).getTime();
        bValue = new Date(bValue || 0).getTime();
      } else if (typeof aValue === 'string' && typeof bValue === 'string') {
        aValue = aValue.toLowerCase();
        bValue = bValue.toLowerCase();
      }
      
      let comparison = 0;
      if (aValue < bValue) comparison = -1;
      if (aValue > bValue) comparison = 1;
      
      return sortConfig.direction === 'desc' ? comparison * -1 : comparison;
    });

    console.log('📊 [SORT] After sorting by', sortConfig.field, sortConfig.direction);

    const result = {
      filteredBusinesses: filtered,
      totalItems: filtered.length,
      uniqueValues: {
        statuses: [...new Set(businesses.map(b => b.status))],
        types: [...new Set(businesses.map(b => b.business_type))],
        tiers: [...new Set(businesses.map(b => b.subscription_tier))]
      }
    };

    timer.end();
    return result;
  }, [businesses, debouncedSearchTerm, filters, sortConfig, perfMonitor]);

  // 📄 Pagination Logic
  const paginationData = useMemo(() => {
    const totalPages = Math.ceil(processedData.totalItems / itemsPerPage);
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    const paginatedBusinesses = processedData.filteredBusinesses.slice(startIndex, endIndex);

    console.log('📄 [PAGINATION]', {
      page: currentPage,
      totalPages,
      itemsPerPage,
      showing: paginatedBusinesses.length,
      total: processedData.totalItems
    });

    return {
      businesses: paginatedBusinesses,
      totalPages,
      startIndex,
      endIndex: Math.min(endIndex, processedData.totalItems),
      hasNextPage: currentPage < totalPages,
      hasPrevPage: currentPage > 1
    };
  }, [processedData.filteredBusinesses, processedData.totalItems, currentPage, itemsPerPage]);

  // 📊 Analytics
  const analytics = useMemo(() => {
    return BusinessAnalytics.getInsights(businesses);
  }, [businesses]);

  // 🎯 Event Handlers
  const handleFilterChange = useCallback((key: keyof FilterValues, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1);
  }, []);

  const handleSort = useCallback((field: SortField) => {
    const timer = perfMonitor.startTimer('Sort Change');
    
    setSortConfig(prev => ({
      field,
      direction: prev.field === field && prev.direction === 'asc' ? 'desc' : 'asc'
    }));
    
    console.log('📊 [SORT] Changed to:', field);
    timer.end();
  }, [perfMonitor]);

  const handlePageChange = useCallback((page: number) => {
    const newPage = Math.max(1, Math.min(page, paginationData.totalPages));
    setCurrentPage(newPage);
    console.log('📄 [PAGE] Changed to:', newPage);
  }, [paginationData.totalPages]);

  const resetFilters = useCallback(() => {
    const timer = perfMonitor.startTimer('Reset Filters');
    
    setFilters({
      search: '',
      status: 'all',
      type: 'all',
      tier: 'all',
      staffRange: 'all',
      expiryRange: 'all'
    });
    setCurrentPage(1);
    
    console.log('🔄 [RESET] Filters reset');
    timer.end();
  }, [perfMonitor]);

  // 🔄 Status Update Handler
  const handleStatusUpdate = useCallback(async (businessId: string, newStatus: string) => {
    const timer = perfMonitor.startTimer('Status Update');
    
    console.log('🔄 [UPDATE] Starting status update:', { businessId, newStatus });
    
    setLoadingUpdates(prev => new Set(prev).add(businessId));
    
    try {
      const supabase = createClient();
      
      const { error } = await supabase
        .from('pos_mini_modular3_businesses')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', businessId);
      
      if (error) {
        console.error('❌ [UPDATE] Database error:', error);
        throw error;
      }
      
      console.log('✅ [UPDATE] Status updated successfully');
      toast.success(`Đã cập nhật trạng thái thành "${STATUS_CONFIG[newStatus as keyof typeof STATUS_CONFIG]?.label}"`);
      
      // Refresh data if callback provided
      if (onRefresh) {
        onRefresh();
      }
      
    } catch (error) {
      console.error('❌ [UPDATE] Failed to update status:', error);
      toast.error('Không thể cập nhật trạng thái. Vui lòng thử lại.');
    } finally {
      setLoadingUpdates(prev => {
        const newSet = new Set(prev);
        newSet.delete(businessId);
        return newSet;
      });
      timer.end();
    }
  }, [onRefresh, perfMonitor]);

  // 🔄 Refresh Handler
  const handleRefresh = useCallback(async () => {
    if (!onRefresh) return;
    
    const timer = perfMonitor.startTimer('Data Refresh');
    setIsRefreshing(true);
    
    try {
      console.log('🔄 [REFRESH] Starting data refresh...');
      await onRefresh();
      console.log('✅ [REFRESH] Data refreshed successfully');
      toast.success('Đã làm mới dữ liệu');
    } catch (error) {
      console.error('❌ [REFRESH] Failed to refresh:', error);
      toast.error('Không thể làm mới dữ liệu');
    } finally {
      setIsRefreshing(false);
      timer.end();
    }
  }, [onRefresh, perfMonitor]);

  // 🎨 Rendering Helpers
  const formatBusinessType = useCallback((type: string) => {
    const config = BUSINESS_TYPE_CONFIG[type as keyof typeof BUSINESS_TYPE_CONFIG];
    return config ? `${config.icon} ${config.label}` : type;
  }, []);

  const getStatusBadge = useCallback((status: string) => {
    const config = STATUS_CONFIG[status as keyof typeof STATUS_CONFIG];
    if (!config) return <Badge variant="outline">{status}</Badge>;

    const Icon = config.icon;
    return (
      <Badge variant="secondary" className={config.color}>
        <Icon className="w-3 h-3 mr-1" />
        {config.label}
      </Badge>
    );
  }, []);

  const getTierBadge = useCallback((tier: string) => {
    const tierConfig = {
      free: { label: 'Miễn phí', color: 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400' },
      basic: { label: 'Cơ bản', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400' },
      premium: { label: 'Cao cấp', color: 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400' }
    };

    const config = tierConfig[tier as keyof typeof tierConfig];
    return config ? (
      <Badge variant="secondary" className={config.color}>
        {config.label}
      </Badge>
    ) : <Badge variant="outline">{tier}</Badge>;
  }, []);

  const formatDate = useCallback((dateString: string) => {
    if (!dateString) return 'Không xác định';
    
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      });
    } catch {
      return 'Ngày không hợp lệ';
    }
  }, []);

  const getDaysUntilExpiry = useCallback((dateString: string) => {
    if (!dateString) return null;
    
    try {
      const expiryDate = new Date(dateString);
      const today = new Date();
      const diffTime = expiryDate.getTime() - today.getTime();
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    } catch {
      return null;
    }
  }, []);

  // 🎨 Sortable Header Component
  const SortableHeader = useCallback(({ field, children, className = "" }: { 
    field: SortField; 
    children: React.ReactNode;
    className?: string;
  }) => (
    <TableHead 
      className={`cursor-pointer hover:bg-muted/50 transition-colors select-none ${className}`}
      onClick={() => handleSort(field)}
    >
      <div className="flex items-center gap-2">
        {children}
        <ArrowUpDown className="w-4 h-4 opacity-50" />
        {sortConfig.field === field && (
          <span className="text-xs font-bold">
            {sortConfig.direction === 'asc' ? '↑' : '↓'}
          </span>
        )}
      </div>
    </TableHead>
  ), [handleSort, sortConfig]);

  // Component cleanup
  useEffect(() => {
    const currentTimer = renderTimer.current;
    return () => {
      if (currentTimer) {
        currentTimer.end();
      }
    };
  }, []);

  // Log performance metrics periodically
  useEffect(() => {
    const interval = setInterval(() => {
      const metrics = perfMonitor.getMetrics();
      console.log('📊 [PERFORMANCE-SUMMARY]', metrics);
    }, 30000); // Every 30 seconds

    return () => clearInterval(interval);
  }, [perfMonitor]);

  return (
    <TooltipProvider>
      <div className="space-y-6">
        {/* 📊 Analytics Summary */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-muted/30 rounded-lg">
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{analytics.total}</div>
            <div className="text-xs text-muted-foreground">Tổng hộ KD</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-600">{analytics.byStatus.active || 0}</div>
            <div className="text-xs text-muted-foreground">Đang hoạt động</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-orange-600">{analytics.expiringCount}</div>
            <div className="text-xs text-muted-foreground">Sắp hết hạn</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-purple-600">{analytics.averageStaff.toFixed(1)}</div>
            <div className="text-xs text-muted-foreground">NV trung bình</div>
          </div>
        </div>

        {/* 🔍 Advanced Search & Filters */}
        <div className="space-y-4">
          {/* Search Bar */}
          <div className="flex items-center gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
              <Input
                placeholder="Tìm kiếm thông minh: tên hộ, mã, chủ hộ, email, loại hình..."
                value={filters.search}
                onChange={(e) => handleFilterChange('search', e.target.value)}
                className="pl-9"
              />
              {debouncedSearchTerm !== filters.search && (
                <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
                  <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                </div>
              )}
            </div>
            
            <Button 
              variant="outline" 
              onClick={resetFilters}
              disabled={Object.values(filters).every(v => v === '' || v === 'all')}
            >
              <Filter className="w-4 h-4 mr-2" />
              Xóa lọc
            </Button>

            {onRefresh && (
              <Button 
                variant="outline" 
                onClick={handleRefresh}
                disabled={isRefreshing}
              >
                <RefreshCw className={`w-4 h-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
                Làm mới
              </Button>
            )}
          </div>

          {/* Advanced Filters */}
          <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
            <div className="space-y-2">
              <Label className="text-xs font-medium">Trạng thái</Label>
              <Select value={filters.status} onValueChange={(value) => handleFilterChange('status', value)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Tất cả" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả trạng thái</SelectItem>
                  {processedData.uniqueValues.statuses.map(status => (
                    <SelectItem key={status} value={status}>
                      {STATUS_CONFIG[status as keyof typeof STATUS_CONFIG]?.label || status}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium">Loại hình</Label>
              <Select value={filters.type} onValueChange={(value) => handleFilterChange('type', value)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Tất cả" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả loại hình</SelectItem>
                  {processedData.uniqueValues.types.map(type => (
                    <SelectItem key={type} value={type}>
                      {formatBusinessType(type)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium">Gói dịch vụ</Label>
              <Select value={filters.tier} onValueChange={(value) => handleFilterChange('tier', value)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Tất cả" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả gói</SelectItem>
                  {processedData.uniqueValues.tiers.map(tier => (
                    <SelectItem key={tier} value={tier}>
                      {tier === 'free' ? 'Miễn phí' : tier === 'basic' ? 'Cơ bản' : tier === 'premium' ? 'Cao cấp' : tier}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium">Số nhân viên</Label>
              <Select value={filters.staffRange} onValueChange={(value) => handleFilterChange('staffRange', value)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Tất cả" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả</SelectItem>
                  <SelectItem value="0">Không có NV</SelectItem>
                  <SelectItem value="1-5">1-5 NV</SelectItem>
                  <SelectItem value="6-20">6-20 NV</SelectItem>
                  <SelectItem value="21+">21+ NV</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium">Thời hạn</Label>
              <Select value={filters.expiryRange} onValueChange={(value) => handleFilterChange('expiryRange', value)}>
                <SelectTrigger className="h-9">
                  <SelectValue placeholder="Tất cả" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả</SelectItem>
                  <SelectItem value="expired">Đã hết hạn</SelectItem>
                  <SelectItem value="0-7">0-7 ngày</SelectItem>
                  <SelectItem value="8-30">8-30 ngày</SelectItem>
                  <SelectItem value="31+">31+ ngày</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium">Hiển thị</Label>
              <Select value={itemsPerPage.toString()} onValueChange={(value) => {
                setItemsPerPage(Number(value));
                setCurrentPage(1);
              }}>
                <SelectTrigger className="h-9">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ITEMS_PER_PAGE_OPTIONS.map(option => (
                    <SelectItem key={option} value={option.toString()}>
                      {option}/trang
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Results Summary */}
          <div className="flex items-center justify-between text-sm text-muted-foreground p-3 bg-muted/20 rounded">
            <div className="flex items-center gap-4">
              <span>
                Hiển thị {paginationData.startIndex + 1}-{paginationData.endIndex} trong {processedData.totalItems} hộ kinh doanh
              </span>
              {(filters.search || Object.values(filters).some(v => v !== 'all' && v !== '')) && (
                <span className="text-blue-600 text-xs">
                  (đã lọc từ {businesses.length} hộ)
                </span>
              )}
            </div>
            {paginationData.totalPages > 1 && (
              <span>Trang {currentPage}/{paginationData.totalPages}</span>
            )}
          </div>
        </div>

        {/* 📊 Data Table */}
        <div className="rounded-lg border overflow-hidden bg-card">
          <Table>
            <TableHeader>
              <TableRow className="bg-muted/50">
                <SortableHeader field="business_name">
                  <Building2 className="w-4 h-4" />
                  Hộ kinh doanh
                </SortableHeader>
                <SortableHeader field="business_type">Loại hình</SortableHeader>
                <SortableHeader field="status">Trạng thái</SortableHeader>
                <SortableHeader field="subscription_tier">Gói dịch vụ</SortableHeader>
                <SortableHeader field="active_staff">
                  <Users className="w-4 h-4" />
                  Nhân viên
                </SortableHeader>
                <SortableHeader field="trial_ends_at">Hết hạn</SortableHeader>
                <TableHead>Thao tác</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {paginationData.businesses.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-12">
                    <div className="space-y-3">
                      <div className="text-4xl">🔍</div>
                      <div className="text-lg font-medium text-muted-foreground">
                        {Object.values(filters).some(v => v !== '' && v !== 'all') 
                          ? 'Không tìm thấy hộ kinh doanh nào phù hợp' 
                          : 'Chưa có hộ kinh doanh nào'
                        }
                      </div>
                      {Object.values(filters).some(v => v !== '' && v !== 'all') && (
                        <Button variant="outline" onClick={resetFilters}>
                          <Filter className="w-4 h-4 mr-2" />
                          Xóa bộ lọc
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ) : (
                paginationData.businesses.map((business) => {
                  const daysLeft = getDaysUntilExpiry(business.trial_ends_at || business.subscription_ends_at);
                  const isExpiringSoon = daysLeft !== null && daysLeft >= 0 && daysLeft <= 7;
                  const isExpired = daysLeft !== null && daysLeft < 0;
                  
                  return (
                    <TableRow 
                      key={business.id} 
                      className="hover:bg-muted/30 transition-colors"
                    >
                      <TableCell className="max-w-xs">
                        <div className="space-y-1">
                          <div className="font-medium truncate">{business.business_name}</div>
                          <div className="text-sm text-muted-foreground font-mono">
                            {business.business_code}
                          </div>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <Building2 className="w-3 h-3 flex-shrink-0" />
                            <span className="truncate">{business.owner_name}</span>
                          </div>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <Mail className="w-3 h-3 flex-shrink-0" />
                            <span className="truncate">{business.owner_email}</span>
                          </div>
                        </div>
                      </TableCell>
                      
                      <TableCell>
                        <Tooltip>
                          <TooltipTrigger>
                            <Badge variant="outline" className="cursor-help">
                              {formatBusinessType(business.business_type)}
                            </Badge>
                          </TooltipTrigger>
                          <TooltipContent>
                            Loại hình: {business.business_type}
                          </TooltipContent>
                        </Tooltip>
                      </TableCell>
                      
                      <TableCell>
                        {getStatusBadge(business.status)}
                      </TableCell>
                      
                      <TableCell>
                        {getTierBadge(business.subscription_tier)}
                      </TableCell>
                      
                      <TableCell>
                        <Tooltip>
                          <TooltipTrigger>
                            <div className="flex items-center gap-2 cursor-help">
                              <Users className="w-4 h-4 text-muted-foreground" />
                              <span className="font-medium">{business.active_staff}</span>
                              <span className="text-muted-foreground">/{business.total_staff}</span>
                              {business.active_staff > 0 && (
                                <div className="flex items-center">
                                  {business.active_staff === business.total_staff ? (
                                    <TrendingUp className="w-3 h-3 text-green-500" />
                                  ) : (
                                    <TrendingDown className="w-3 h-3 text-orange-500" />
                                  )}
                                </div>
                              )}
                            </div>
                          </TooltipTrigger>
                          <TooltipContent>
                            {business.active_staff} nhân viên đang hoạt động / {business.total_staff} tổng nhân viên
                          </TooltipContent>
                        </Tooltip>
                      </TableCell>
                      
                      <TableCell>
                        <div className="space-y-1">
                          <div className="text-sm">
                            {formatDate(business.trial_ends_at || business.subscription_ends_at)}
                          </div>
                          {daysLeft !== null && (
                            <div className={`text-xs font-medium ${
                              isExpired ? 'text-red-600' :
                              isExpiringSoon ? 'text-orange-600' :
                              'text-muted-foreground'
                            }`}>
                              {isExpired ? 'Đã hết hạn' :
                               daysLeft === 0 ? 'Hôm nay' :
                               daysLeft === 1 ? 'Ngày mai' :
                               `${daysLeft} ngày`}
                            </div>
                          )}
                        </div>
                      </TableCell>
                      
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Select 
                            value={business.status}
                            onValueChange={(value: string) => handleStatusUpdate(business.id, value)}
                            disabled={loadingUpdates.has(business.id)}
                          >
                            <SelectTrigger className="h-8 w-28">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {Object.entries(STATUS_CONFIG).map(([status, config]) => (
                                <SelectItem key={status} value={status}>
                                  <div className="flex items-center gap-2">
                                    <config.icon className="w-3 h-3" />
                                    {config.label}
                                  </div>
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                          
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button variant="ghost" size="sm">
                                <Eye className="w-4 h-4" />
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>
                              Xem chi tiết
                            </TooltipContent>
                          </Tooltip>

                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button variant="ghost" size="sm">
                                <Edit className="w-4 h-4" />
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>
                              Chỉnh sửa
                            </TooltipContent>
                          </Tooltip>

                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button variant="ghost" size="sm">
                                <MoreHorizontal className="w-4 h-4" />
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>
                              Thêm tùy chọn
                            </TooltipContent>
                          </Tooltip>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </div>
        
        {/* 📄 Advanced Pagination */}
        {paginationData.totalPages > 1 && (
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 bg-muted/20 rounded-lg">
            <div className="text-sm text-muted-foreground">
              Trang {currentPage} / {paginationData.totalPages} • {processedData.totalItems} hộ kinh doanh
            </div>
            
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(1)}
                disabled={!paginationData.hasPrevPage}
              >
                <ChevronsLeft className="w-4 h-4" />
              </Button>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={!paginationData.hasPrevPage}
              >
                <ChevronLeft className="w-4 h-4" />
              </Button>
              
              <div className="flex items-center gap-1">
                {Array.from({ length: Math.min(5, paginationData.totalPages) }, (_, i) => {
                  let pageNum;
                  if (paginationData.totalPages <= 5) {
                    pageNum = i + 1;
                  } else if (currentPage <= 3) {
                    pageNum = i + 1;
                  } else if (currentPage >= paginationData.totalPages - 2) {
                    pageNum = paginationData.totalPages - 4 + i;
                  } else {
                    pageNum = currentPage - 2 + i;
                  }
                  
                  return (
                    <Button
                      key={pageNum}
                      variant={currentPage === pageNum ? "default" : "outline"}
                      size="sm"
                      className="w-8 h-8 p-0"
                      onClick={() => handlePageChange(pageNum)}
                    >
                      {pageNum}
                    </Button>
                  );
                })}
              </div>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={!paginationData.hasNextPage}
              >
                <ChevronRight className="w-4 h-4" />
              </Button>
              
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(paginationData.totalPages)}
                disabled={!paginationData.hasNextPage}
              >
                <ChevronsRight className="w-4 h-4" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </TooltipProvider>
  );
}
