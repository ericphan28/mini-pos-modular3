'use client'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useToast } from '@/hooks/use-toast'
import { createClient } from '@/lib/supabase/client'
import { Briefcase, Eye, EyeOff, Key, Phone, User, X } from 'lucide-react'
import { useState } from 'react'

interface CreateStaffFormProps {
  businessId: string
  currentUserId: string
  onSuccess: () => void
  onCancel: () => void
}

export function CreateStaffForm({ businessId, currentUserId, onSuccess, onCancel }: CreateStaffFormProps) {
  const [formData, setFormData] = useState({
    full_name: '',
    phone: '',
    password: '',
    role: 'seller',
    employee_id: '',
    notes: ''
  })
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const { toast } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const supabase = createClient()
      
      // Validate form data
      if (!formData.full_name.trim()) {
        toast({
          title: "Lỗi",
          description: "Vui lòng nhập họ tên nhân viên",
          variant: "destructive",
        })
        return
      }

      if (!formData.phone.trim()) {
        toast({
          title: "Lỗi", 
          description: "Vui lòng nhập số điện thoại",
          variant: "destructive",
        })
        return
      }

      if (formData.password.length < 6) {
        toast({
          title: "Lỗi",
          description: "Mật khẩu phải có ít nhất 6 ký tự",
          variant: "destructive",
        })
        return
      }

      // Create staff member using direct function
      const { data, error } = await supabase.rpc(
        'pos_mini_modular3_create_staff_member_direct',
        {
          p_business_id: businessId,
          p_current_user_id: currentUserId,
          p_full_name: formData.full_name.trim(),
          p_phone: formData.phone.trim(),
          p_password: formData.password,
          p_role: formData.role,
          p_employee_id: formData.employee_id.trim() || null,
          p_notes: formData.notes.trim() || null
        }
      )

      if (error) {
        console.error('Create staff error:', error)
        toast({
          title: "Lỗi",
          description: "Không thể tạo nhân viên. Vui lòng thử lại.",
          variant: "destructive",
        })
        return
      }

      if (!data?.success) {
        toast({
          title: "Lỗi",
          description: data?.error || "Không thể tạo nhân viên",
          variant: "destructive",
        })
        return
      }

      // Show success message with login credentials
      toast({
        title: "Tạo nhân viên thành công!",
        description: `${formData.full_name} có thể đăng nhập bằng số điện thoại ${data.phone}`,
      })

      // Show password for manager to share
      alert(`🎉 Nhân viên đã được tạo thành công!

📱 Số điện thoại: ${data.phone}
🔐 Mật khẩu: ${formData.password}

⚠️ Vui lòng chia sẻ thông tin đăng nhập này cho nhân viên.
Họ có thể đăng nhập ngay bằng số điện thoại và mật khẩu trên.`)

      onSuccess()

    } catch (error) {
      console.error('Error creating staff:', error)
      toast({
        title: "Lỗi",
        description: "Có lỗi xảy ra khi tạo nhân viên",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const generatePassword = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    let password = ''
    for (let i = 0; i < 8; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    setFormData(prev => ({ ...prev, password }))
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto bg-gradient-to-br from-card to-card/50 border-border/50 shadow-2xl">
        <CardHeader className="relative border-b border-border/50">
          <Button
            variant="ghost"
            size="sm"
            onClick={onCancel}
            className="absolute right-4 top-4 h-8 w-8 p-0"
            disabled={loading}
          >
            <X className="h-4 w-4" />
          </Button>
          <CardTitle className="flex items-center text-xl">
            <div className="w-8 h-8 bg-gradient-to-br from-primary to-primary/80 rounded-lg flex items-center justify-center mr-3">
              <User className="h-4 w-4 text-primary-foreground" />
            </div>
            Tạo nhân viên mới
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            Tạo tài khoản đăng nhập bằng số điện thoại cho nhân viên
          </p>
        </CardHeader>
        <CardContent className="p-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Full Name */}
            <div className="space-y-2">
              <Label htmlFor="full_name" className="text-sm font-medium">
                Họ và tên <span className="text-red-500">*</span>
              </Label>
              <Input
                id="full_name"
                type="text"
                value={formData.full_name}
                onChange={(e) => setFormData(prev => ({ ...prev, full_name: e.target.value }))}
                placeholder="Nguyễn Văn A"
                className="bg-background/50 border-border/50 focus:bg-background"
                required
              />
            </div>

            {/* Phone */}
            <div className="space-y-2">
              <Label htmlFor="phone" className="text-sm font-medium">
                Số điện thoại <span className="text-red-500">*</span>
              </Label>
              <div className="relative">
                <Phone className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="phone"
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData(prev => ({ ...prev, phone: e.target.value }))}
                  placeholder="0901234567"
                  className="pl-10 bg-background/50 border-border/50 focus:bg-background"
                  required
                />
              </div>
              <p className="text-xs text-muted-foreground">
                Nhân viên sẽ dùng số điện thoại này để đăng nhập
              </p>
            </div>

            {/* Password */}
            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium">
                Mật khẩu <span className="text-red-500">*</span>
              </Label>
              <div className="relative">
                <Key className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={formData.password}
                  onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
                  placeholder="Nhập mật khẩu"
                  className="pl-10 pr-12 bg-background/50 border-border/50 focus:bg-background"
                  required
                  minLength={6}
                />
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-2 top-2 h-8 w-8 p-0"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </Button>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={generatePassword}
                className="text-xs h-8"
              >
                Tạo mật khẩu ngẫu nhiên
              </Button>
            </div>

            {/* Role */}
            <div className="space-y-2">
              <Label htmlFor="role" className="text-sm font-medium">Vai trò</Label>
              <div className="relative">
                <Briefcase className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <select
                  id="role"
                  value={formData.role}
                  onChange={(e) => setFormData(prev => ({ ...prev, role: e.target.value }))}
                  className="w-full pl-10 pr-4 py-2 bg-background/50 border border-border/50 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent transition-colors"
                >
                  <option value="seller">Nhân viên bán hàng</option>
                  <option value="manager">Quản lý</option>
                  <option value="accountant">Kế toán</option>
                </select>
              </div>
            </div>

            {/* Employee ID (Optional) */}
            <div className="space-y-2">
              <Label htmlFor="employee_id" className="text-sm font-medium">Mã nhân viên (tùy chọn)</Label>
              <Input
                id="employee_id"
                type="text"
                value={formData.employee_id}
                onChange={(e) => setFormData(prev => ({ ...prev, employee_id: e.target.value }))}
                placeholder="NV001"
                className="bg-background/50 border-border/50 focus:bg-background"
              />
            </div>

            {/* Notes (Optional) */}
            <div className="space-y-2">
              <Label htmlFor="notes" className="text-sm font-medium">Ghi chú (tùy chọn)</Label>
              <textarea
                id="notes"
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Ghi chú về nhân viên..."
                className="w-full px-3 py-2 bg-background/50 border border-border/50 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent transition-colors resize-none"
                rows={3}
              />
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={onCancel}
                className="flex-1"
                disabled={loading}
              >
                Hủy
              </Button>
              <Button
                type="submit"
                disabled={loading}
                className="flex-1 bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary shadow-lg"
              >
                {loading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Đang tạo...
                  </>
                ) : (
                  <>
                    <User className="h-4 w-4 mr-2" />
                    Tạo nhân viên
                  </>
                )}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}