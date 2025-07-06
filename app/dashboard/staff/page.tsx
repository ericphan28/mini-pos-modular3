'use client'

import { CreateStaffForm } from '@/components/staff/create-staff-form'
import { StaffList } from '@/components/staff/staff-list'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'
import { type StaffMember } from '@/lib/services/staff-management.service'
import { createClient } from '@/lib/supabase/client'
import { Phone, Plus, Shield, UserCheck, Users } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

interface StaffStats {
  total: number;
  active: number;
  by_role: Record<string, number>;
}

export default function StaffManagementPage() {
  const [staffMembers, setStaffMembers] = useState<StaffMember[]>([])
  const [stats, setStats] = useState<StaffStats>({
    total: 0,
    active: 0,
    by_role: {}
  })
  const [businessInfo, setBusinessInfo] = useState<{
    id: string;
    name: string;
    max_users: number;
  } | null>(null)
  const [currentUserId, setCurrentUserId] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const { toast } = useToast()
  const router = useRouter()

  // Load data using updated functions
  const loadData = async () => {
    setLoading(true)
    try {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()

      if (!user) {
        router.push('/auth/login')
        return
      }

      setCurrentUserId(user.id)

      // Get user profile and business info
      const { data: profileData, error: profileError } = await supabase.rpc(
        'pos_mini_modular3_get_user_profile_safe',
        { p_user_id: user.id }
      )

      if (profileError || !profileData?.profile_exists) {
        router.push('/auth/confirm?redirect=/dashboard/staff')
        return
      }

      const profile = profileData.profile
      const business = profileData.business

      // Check if user is business owner/manager
      if (!['household_owner', 'manager'].includes(profile.role)) {
        toast({
          title: "Không có quyền truy cập",
          description: "Bạn không có quyền quản lý nhân viên",
          variant: "destructive",
        })
        router.push('/dashboard')
        return
      }

      setBusinessInfo(business)

      // Load staff members using direct function (bypass auth context issues)
      const { data: staffData, error: staffError } = await supabase.rpc(
        'pos_mini_modular3_get_business_staff_direct',
        { 
          p_business_id: business.id,
          p_current_user_id: user.id
        }
      )

      if (staffError) {
        console.error('Staff loading error:', staffError)
        toast({
          title: "Lỗi",
          description: "Không thể tải danh sách nhân viên",
          variant: "destructive",
        })
        return
      }

      if (!staffData?.success) {
        toast({
          title: "Lỗi",
          description: staffData?.error || "Không thể tải danh sách nhân viên",
          variant: "destructive",
        })
        return
      }

      // Process data
      const staff = staffData?.staff || []
      setStaffMembers(staff)

      // Calculate stats
      const activeStaff = staff.filter((member: StaffMember) => member.status === 'active')
      const roleStats = staff.reduce((acc: Record<string, number>, member: StaffMember) => {
        acc[member.role] = (acc[member.role] || 0) + 1
        return acc
      }, {})

      setStats({
        total: staff.length,
        active: activeStaff.length,
        by_role: roleStats
      })

    } catch (error) {
      console.error('Error loading staff data:', error)
      toast({
        title: "Lỗi",
        description: "Không thể tải dữ liệu nhân viên",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const handleStaffCreated = () => {
    setShowCreateForm(false)
    loadData() // Reload data after creating staff
  }

  const handleStaffUpdated = () => {
    loadData() // Reload data after updating staff
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
          <div className="space-y-2">
            <h3 className="text-lg font-semibold text-foreground">Đang tải dữ liệu</h3>
            <p className="text-muted-foreground">Vui lòng chờ trong giây lát...</p>
          </div>
        </div>
      </div>
    )
  }

  const getRoleDisplayName = (role: string) => {
    const roleNames = {
      household_owner: 'Chủ cửa hàng',
      manager: 'Quản lý',
      seller: 'Nhân viên bán hàng',
      accountant: 'Kế toán'
    }
    return roleNames[role as keyof typeof roleNames] || role
  }

  return (
    <div className="space-y-8 p-6 lg:p-8">
      {/* Header - Supabase Style */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
        <div className="space-y-2">
          <h1 className="text-2xl lg:text-3xl font-bold bg-gradient-to-r from-foreground to-foreground/80 bg-clip-text text-transparent">
            Quản lý nhân viên
          </h1>
          <p className="text-muted-foreground text-sm lg:text-base">
            <span className="font-medium text-primary">{businessInfo?.name}</span> • Tạo và quản lý tài khoản nhân viên
          </p>
        </div>
        <Button 
          onClick={() => setShowCreateForm(true)}
          className="bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary shadow-lg hover:shadow-xl transition-all duration-200 self-start lg:self-auto"
          size="lg"
        >
          <Plus className="h-4 w-4 mr-2" />
          Tạo nhân viên mới
        </Button>
      </div>

      {/* Stats Cards - Enhanced Supabase Style */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
        <Card className="bg-gradient-to-br from-card to-card/50 border-border/50 hover:shadow-lg transition-all duration-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Tổng nhân viên</CardTitle>
            <div className="w-8 h-8 bg-gradient-to-br from-primary/20 to-primary/10 rounded-lg flex items-center justify-center">
              <Users className="h-4 w-4 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-foreground">{stats.total}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Tối đa {businessInfo?.max_users || 3} người
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-card to-card/50 border-border/50 hover:shadow-lg transition-all duration-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Đang hoạt động</CardTitle>
            <div className="w-8 h-8 bg-gradient-to-br from-green-500/20 to-green-500/10 rounded-lg flex items-center justify-center">
              <UserCheck className="h-4 w-4 text-green-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-foreground">{stats.active}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Nhân viên có thể đăng nhập
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-card to-card/50 border-border/50 hover:shadow-lg transition-all duration-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Quản lý</CardTitle>
            <div className="w-8 h-8 bg-gradient-to-br from-purple-500/20 to-purple-500/10 rounded-lg flex items-center justify-center">
              <Shield className="h-4 w-4 text-purple-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-foreground">
              {(stats.by_role.household_owner || 0) + (stats.by_role.manager || 0)}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Chủ cửa hàng + Quản lý
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-card to-card/50 border-border/50 hover:shadow-lg transition-all duration-200">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Đăng nhập bằng</CardTitle>
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500/20 to-blue-500/10 rounded-lg flex items-center justify-center">
              <Phone className="h-4 w-4 text-blue-600" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-foreground">SĐT</div>
            <p className="text-xs text-muted-foreground mt-1">
              Số điện thoại + mật khẩu
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Role Statistics */}
      {Object.keys(stats.by_role).length > 0 && (
        <Card className="bg-gradient-to-br from-card to-card/50 border-border/50">
          <CardHeader>
            <CardTitle className="text-lg font-semibold">Thống kê theo vai trò</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {Object.entries(stats.by_role).map(([role, count]) => (
                <div key={role} className="text-center p-4 bg-gradient-to-br from-primary/5 to-primary/10 rounded-xl border border-primary/20">
                  <div className="text-2xl font-bold text-primary">{count}</div>
                  <div className="text-sm text-muted-foreground font-medium mt-1">{getRoleDisplayName(role)}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Staff List */}
      <Card className="bg-gradient-to-br from-card to-card/50 border-border/50">
        <CardHeader className="border-b border-border/50">
          <CardTitle className="text-lg font-semibold">Danh sách nhân viên</CardTitle>
          <p className="text-sm text-muted-foreground">
            Quản lý thông tin và quyền truy cập của nhân viên
          </p>
        </CardHeader>
        <CardContent className="p-6">
          <StaffList 
            staffMembers={staffMembers}
            businessInfo={businessInfo}
            currentUserId={currentUserId}
            onStaffUpdated={handleStaffUpdated}
          />
        </CardContent>
      </Card>

      {/* Create Staff Form Modal */}
      {showCreateForm && businessInfo?.id && (
        <CreateStaffForm
          businessId={businessInfo.id}
          currentUserId={currentUserId}
          onSuccess={handleStaffCreated}
          onCancel={() => setShowCreateForm(false)}
        />
      )}
    </div>
  )
}
