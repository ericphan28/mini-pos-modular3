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
import { staffService, type InviteStaffInput } from '@/lib/services/staff-management.service'
import { Mail, Send, X } from 'lucide-react'
import { useState } from 'react'

interface InviteStaffFormProps {
  onClose: () => void
  onInvitationSent: () => void
}

export function InviteStaffForm({ onClose, onInvitationSent }: InviteStaffFormProps) {
  const [formData, setFormData] = useState<InviteStaffInput>({
    email: '',
    role: 'seller'
  })
  const [loading, setLoading] = useState(false)
  const { toast } = useToast()

  const roleOptions = [
    { value: 'manager', label: 'Quản lý', description: 'Có thể quản lý nhân viên và cài đặt' },
    { value: 'seller', label: 'Nhân viên bán hàng', description: 'Sử dụng POS và quản lý bán hàng' },
    { value: 'accountant', label: 'Kế toán', description: 'Quản lý tài chính và báo cáo' }
  ]

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.email.trim()) {
      toast({
        title: "Lỗi",
        description: "Vui lòng nhập email",
        variant: "destructive",
      })
      return
    }

    setLoading(true)
    
    try {
      const result = await staffService.inviteStaff(formData)
      
      if (result.success) {
        onInvitationSent()
      } else {
        toast({
          title: "Lỗi",
          description: result.error || "Không thể gửi lời mời",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error('Error inviting staff:', error)
      toast({
        title: "Lỗi",
        description: "Đã xảy ra lỗi khi gửi lời mời",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <Card className="w-full max-w-md">
        <div className="p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-semibold">Mời nhân viên mới</h2>
              <p className="text-sm text-muted-foreground">
                Gửi lời mời qua email để thêm nhân viên vào hộ kinh doanh
              </p>
            </div>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="h-4 w-4" />
            </Button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Email */}
            <div className="space-y-2">
              <Label htmlFor="email">Email nhân viên</Label>
              <div className="relative">
                <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="email"
                  type="email"
                  placeholder="example@email.com"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="pl-10"
                  required
                />
              </div>
              <p className="text-xs text-muted-foreground">
                Lời mời sẽ được gửi đến email này
              </p>
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
                className="flex-1 bg-green-600 hover:bg-green-700"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    Đang gửi...
                  </>
                ) : (
                  <>
                    <Send className="mr-2 h-4 w-4" />
                    Gửi lời mời
                  </>
                )}
              </Button>
            </div>
          </form>

          {/* Help Text */}
          <div className="mt-6 p-4 bg-blue-50 rounded-lg">
            <h4 className="text-sm font-medium text-blue-900 mb-2">
              Lưu ý quan trọng:
            </h4>
            <ul className="text-xs text-blue-700 space-y-1">
              <li>• Lời mời có hiệu lực trong 7 ngày</li>
              <li>• Nhân viên sẽ nhận được email với link đăng ký</li>
              <li>• Họ cần tạo tài khoản mới nếu chưa có</li>
              <li>• Bạn có thể hủy lời mời bất kỳ lúc nào</li>
            </ul>
          </div>
        </div>
      </Card>
    </div>
  )
}
