'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { useToast } from '@/hooks/use-toast'
import { staffService, type StaffMember } from '@/lib/services/staff-management.service'
import { Calendar, Edit, IdCard, Mail, MoreVertical, Phone, Trash2, Users } from 'lucide-react'
import { useState } from 'react'
import { EditStaffForm } from './edit-staff-form'

interface StaffListProps {
  staffMembers: StaffMember[]
  businessInfo: {
    id: string;
    name: string;
    max_users: number;
  } | null
  currentUserId: string
  onStaffUpdated: () => void
}

export function StaffList({ staffMembers, onStaffUpdated }: StaffListProps) {
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null)
  const { toast } = useToast()

  const roleLabels = {
    household_owner: 'Chủ cửa hàng',
    manager: 'Quản lý',
    seller: 'Nhân viên bán hàng',
    accountant: 'Kế toán'
  }

  const statusLabels = {
    active: 'Đang hoạt động',
    inactive: 'Tạm ngưng',
    suspended: 'Bị khóa'
  }

  const statusColors = {
    active: 'bg-gradient-to-r from-green-500/10 to-green-500/5 text-green-700 border-green-500/20',
    inactive: 'bg-gradient-to-r from-gray-500/10 to-gray-500/5 text-gray-700 border-gray-500/20',
    suspended: 'bg-gradient-to-r from-red-500/10 to-red-500/5 text-red-700 border-red-500/20'
  }

  const roleColors = {
    household_owner: 'bg-gradient-to-r from-yellow-500/10 to-yellow-500/5 text-yellow-700 border-yellow-500/20',
    manager: 'bg-gradient-to-r from-purple-500/10 to-purple-500/5 text-purple-700 border-purple-500/20',
    seller: 'bg-gradient-to-r from-blue-500/10 to-blue-500/5 text-blue-700 border-blue-500/20',
    accountant: 'bg-gradient-to-r from-orange-500/10 to-orange-500/5 text-orange-700 border-orange-500/20'
  }

  const handleRemoveStaff = async (staffId: string, staffName: string) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa nhân viên "${staffName}"?`)) {
      return
    }

    const result = await staffService.removeStaffMember(staffId)
    
    if (result.success) {
      toast({
        title: "Thành công",
        description: "Nhân viên đã được xóa khỏi hệ thống",
      })
      onStaffUpdated()
    } else {
      toast({
        title: "Lỗi",
        description: result.error || "Không thể xóa nhân viên",
        variant: "destructive",
      })
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('vi-VN')
  }

  if (staffMembers.length === 0) {
    return (
      <div className="text-center py-12 space-y-4">
        <div className="mx-auto w-16 h-16 bg-gradient-to-br from-muted to-muted/50 rounded-2xl flex items-center justify-center">
          <Users className="h-8 w-8 text-muted-foreground" />
        </div>
        <div className="space-y-2">
          <h3 className="text-lg font-semibold text-foreground">Chưa có nhân viên</h3>
          <p className="text-muted-foreground max-w-md mx-auto">
            Hãy mời nhân viên đầu tiên để bắt đầu xây dựng đội ngũ của bạn
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-foreground">
          Danh sách nhân viên ({staffMembers.length})
        </h2>
      </div>
      
      <div className="grid gap-4">
        {staffMembers.map((staff) => (
          <Card key={staff.id} className="bg-gradient-to-br from-card to-card/50 border-border/50 hover:shadow-lg transition-all duration-200">
            <div className="p-6">
              <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-6">
                <div className="flex items-start space-x-4 flex-1">
                  {/* Avatar */}
                  <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-xl flex items-center justify-center text-primary-foreground font-semibold text-lg shadow-lg">
                    {staff.full_name.charAt(0).toUpperCase()}
                  </div>

                  {/* Staff Info */}
                  <div className="flex-1 space-y-3">
                    <div className="flex flex-wrap items-center gap-3">
                      <h3 className="text-lg font-semibold text-foreground">{staff.full_name}</h3>
                      <Badge className={roleColors[staff.role as keyof typeof roleColors]}>
                        {roleLabels[staff.role as keyof typeof roleLabels]}
                      </Badge>
                      <Badge className={statusColors[staff.status as keyof typeof statusColors]}>
                        {statusLabels[staff.status as keyof typeof statusLabels]}
                      </Badge>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                      {staff.email && (
                        <div className="flex items-center space-x-2 text-muted-foreground">
                          <Mail className="h-4 w-4" />
                          <span>{staff.email}</span>
                        </div>
                      )}
                      
                      {staff.phone && (
                        <div className="flex items-center space-x-2 text-muted-foreground">
                          <Phone className="h-4 w-4" />
                          <span>{staff.phone}</span>
                        </div>
                      )}

                      {staff.employee_id && (
                        <div className="flex items-center space-x-2 text-muted-foreground">
                          <IdCard className="h-4 w-4" />
                          <span>Mã NV: {staff.employee_id}</span>
                        </div>
                      )}

                      <div className="flex items-center space-x-2 text-muted-foreground">
                        <Calendar className="h-4 w-4" />
                        <span>Tham gia: {formatDate(staff.created_at)}</span>
                      </div>
                    </div>

                    {staff.last_login_at && (
                      <div className="text-sm text-muted-foreground">
                        Đăng nhập cuối: {formatDate(staff.last_login_at)}
                      </div>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-48">
                    <DropdownMenuItem onClick={() => setEditingStaff(staff)}>
                      <Edit className="mr-2 h-4 w-4" />
                      Chỉnh sửa
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      onClick={() => handleRemoveStaff(staff.id, staff.full_name)}
                      className="text-red-600 focus:text-red-600"
                    >
                      <Trash2 className="mr-2 h-4 w-4" />
                      Xóa nhân viên
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Edit Staff Form Modal */}
      {editingStaff && (
        <EditStaffForm
          staff={editingStaff}
          onClose={() => setEditingStaff(null)}
          onStaffUpdated={() => {
            setEditingStaff(null)
            onStaffUpdated()
          }}
        />
      )}
    </div>
  )
}
