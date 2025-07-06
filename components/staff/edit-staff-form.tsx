'use client'

import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { useToast } from '@/hooks/use-toast'
import { staffService, type StaffMember, type UpdateStaffInput } from '@/lib/services/staff-management.service'
import { Save, User, X } from 'lucide-react'
import { useState } from 'react'

interface EditStaffFormProps {
  staff: StaffMember
  onClose: () => void
  onStaffUpdated: () => void
}

export function EditStaffForm({ staff, onClose, onStaffUpdated }: EditStaffFormProps) {
  const [formData, setFormData] = useState<UpdateStaffInput>({
    full_name: staff.full_name,
    role: staff.role,
    status: staff.status,
    employee_id: staff.employee_id || '',
    phone: staff.phone || ''
  })
  const [loading, setLoading] = useState(false)
  const { toast } = useToast()

  const roleOptions = [
    { value: 'manager', label: 'Quản lý', description: 'Có thể quản lý nhân viên và cài đặt' },
    { value: 'seller', label: 'Nhân viên bán hàng', description: 'Sử dụng POS và quản lý bán hàng' },
    { value: 'accountant', label: 'Kế toán', description: 'Quản lý tài chính và báo cáo' }
  ]

  const statusOptions = [
    { value: 'active', label: 'Đang hoạt động', color: 'text-green-600' },
    { value: 'inactive', label: 'Tạm ngưng', color: 'text-gray-600' },
    { value: 'suspended', label: 'Bị khóa', color: 'text-red-600' }
  ]

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.full_name.trim()) {
      toast({
        title: "Lỗi",
        description: "Vui lòng nhập tên nhân viên",
        variant: "destructive",
      })
      return
    }

    setLoading(true)
    
    try {
      const result = await staffService.updateStaffMember(staff.id, formData)
      
      if (result.success) {
        toast({
          title: "Thành công",
          description: "Thông tin nhân viên đã được cập nhật",
        })
        onStaffUpdated()
      } else {
        toast({
          title: "Lỗi",
          description: result.error || "Không thể cập nhật thông tin nhân viên",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error('Error updating staff:', error)
      toast({
        title: "Lỗi",
        description: "Đã xảy ra lỗi khi cập nhật thông tin",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <Card className="w-full max-w-lg">
        <div className="p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-semibold">Chỉnh sửa thông tin nhân viên</h2>
              <p className="text-sm text-muted-foreground">
                Cập nhật thông tin và quyền hạn của {staff.full_name}
              </p>
            </div>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="h-4 w-4" />
            </Button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Full Name */}
            <div className="space-y-2">
              <Label htmlFor="fullName">Họ và tên</Label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="fullName"
                  placeholder="Nguyễn Văn A"
                  value={formData.full_name}
                  onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                  className="pl-10"
                  required
                />
              </div>
            </div>

            {/* Employee ID */}
            <div className="space-y-2">
              <Label htmlFor="employeeId">Mã nhân viên (tùy chọn)</Label>
              <Input
                id="employeeId"
                placeholder="NV001"
                value={formData.employee_id}
                onChange={(e) => setFormData({ ...formData, employee_id: e.target.value })}
              />
            </div>

            {/* Phone */}
            <div className="space-y-2">
              <Label htmlFor="phone">Số điện thoại (tùy chọn)</Label>
              <Input
                id="phone"
                type="tel"
                placeholder="0909123456"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>

            {/* Role */}
            <div className="space-y-2">
              <Label htmlFor="role">Vai trò</Label>
              <Select 
                value={formData.role} 
                onValueChange={(value: 'manager' | 'seller' | 'accountant') => 
                  setFormData({ ...formData, role: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {roleOptions.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <div>
                        <div className="font-medium">{option.label}</div>
                        <div className="text-xs text-muted-foreground">
                          {option.description}
                        </div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Status */}
            <div className="space-y-2">
              <Label htmlFor="status">Trạng thái</Label>
              <Select 
                value={formData.status} 
                onValueChange={(value: 'active' | 'inactive' | 'suspended') => 
                  setFormData({ ...formData, status: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {statusOptions.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <div className={option.color}>
                        {option.label}
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Actions */}
            <div className="flex space-x-2 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={onClose}
                className="flex-1"
                disabled={loading}
              >
                Hủy
              </Button>
              <Button
                type="submit"
                className="flex-1"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    Đang lưu...
                  </>
                ) : (
                  <>
                    <Save className="mr-2 h-4 w-4" />
                    Lưu thay đổi
                  </>
                )}
              </Button>
            </div>
          </form>

          {/* Info */}
          <div className="mt-6 p-4 bg-blue-50 rounded-lg">
            <h4 className="text-sm font-medium text-blue-900 mb-2">
              Thông tin bổ sung:
            </h4>
            <div className="text-xs text-blue-700 space-y-1">
              <div>Email: {staff.email}</div>
              <div>Tham gia: {new Date(staff.created_at).toLocaleDateString('vi-VN')}</div>
              {staff.last_login_at && (
                <div>Đăng nhập cuối: {new Date(staff.last_login_at).toLocaleDateString('vi-VN')}</div>
              )}
            </div>
          </div>
        </div>
      </Card>
    </div>
  )
}
