'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'
import { staffService, type BusinessInvitation } from '@/lib/services/staff-management.service'
import { Clock, Copy, Mail, X } from 'lucide-react'
import { useState } from 'react'

interface PendingInvitationsProps {
  invitations: BusinessInvitation[]
  onInvitationCancelled: () => void
}

export function PendingInvitations({ invitations, onInvitationCancelled }: PendingInvitationsProps) {
  const [cancellingId, setCancellingId] = useState<string | null>(null)
  const { toast } = useToast()

  const roleLabels = {
    manager: 'Quản lý',
    seller: 'Nhân viên bán hàng',
    accountant: 'Kế toán'
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const formatTimeRemaining = (expiresAt: string) => {
    const now = new Date()
    const expiry = new Date(expiresAt)
    const diff = expiry.getTime() - now.getTime()
    
    if (diff <= 0) return 'Đã hết hạn'
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    
    if (days > 0) return `Còn ${days} ngày`
    if (hours > 0) return `Còn ${hours} giờ`
    return 'Sắp hết hạn'
  }

  const handleCancelInvitation = async (invitationId: string, email: string) => {
    if (!confirm(`Bạn có chắc chắn muốn hủy lời mời gửi đến "${email}"?`)) {
      return
    }

    setCancellingId(invitationId)
    
    try {
      const result = await staffService.cancelInvitation(invitationId)
      
      if (result.success) {
        toast({
          title: "Thành công",
          description: "Lời mời đã được hủy",
        })
        onInvitationCancelled()
      } else {
        toast({
          title: "Lỗi",
          description: result.error || "Không thể hủy lời mời",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error('Error cancelling invitation:', error)
      toast({
        title: "Lỗi",
        description: "Đã xảy ra lỗi khi hủy lời mời",
        variant: "destructive",
      })
    } finally {
      setCancellingId(null)
    }
  }

  const copyInvitationLink = async (token: string) => {
    const inviteUrl = `${window.location.origin}/auth/invitation?token=${token}`
    
    try {
      await navigator.clipboard.writeText(inviteUrl)
      toast({
        title: "Đã sao chép",
        description: "Link mời đã được sao chép vào clipboard",
      })
    } catch {
      toast({
        title: "Lỗi",
        description: "Không thể sao chép link",
        variant: "destructive",
      })
    }
  }

  if (invitations.length === 0) {
    return null
  }

  return (
    <Card className="p-6">
      <div className="flex items-center space-x-2 mb-4">
        <Clock className="h-5 w-5 text-orange-500" />
        <h2 className="text-xl font-semibold">Lời mời đang chờ ({invitations.length})</h2>
      </div>
      
      <div className="space-y-3">
        {invitations.map((invitation) => {
          const isExpiringSoon = new Date(invitation.expires_at).getTime() - Date.now() < 24 * 60 * 60 * 1000
          
          return (
            <div
              key={invitation.id}
              className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center space-x-4">
                <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
                  <Mail className="h-5 w-5 text-orange-600" />
                </div>
                
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <span className="font-medium">{invitation.email}</span>
                    <Badge variant="secondary">
                      {roleLabels[invitation.role]}
                    </Badge>
                  </div>
                  
                  <div className="text-sm text-muted-foreground">
                    Mời bởi: {invitation.invited_by.full_name} • {formatDate(invitation.created_at)}
                  </div>
                  
                  <div className={`text-sm ${isExpiringSoon ? 'text-red-600' : 'text-muted-foreground'}`}>
                    {formatTimeRemaining(invitation.expires_at)}
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => copyInvitationLink(invitation.invitation_token)}
                >
                  <Copy className="h-4 w-4 mr-1" />
                  Copy link
                </Button>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleCancelInvitation(invitation.id, invitation.email)}
                  disabled={cancellingId === invitation.id}
                  className="text-red-600 hover:text-red-700"
                >
                  {cancellingId === invitation.id ? (
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-red-600 border-t-transparent" />
                  ) : (
                    <X className="h-4 w-4" />
                  )}
                </Button>
              </div>
            </div>
          )
        })}
      </div>

      <div className="mt-4 p-3 bg-yellow-50 rounded-lg">
        <div className="flex items-start space-x-2">
          <Clock className="h-4 w-4 text-yellow-600 mt-0.5" />
          <div className="text-sm">
            <p className="font-medium text-yellow-800">Lưu ý về lời mời:</p>
            <p className="text-yellow-700">
              Lời mời có hiệu lực trong 7 ngày. Nhân viên cần đăng ký tài khoản với email được mời để có thể tham gia.
            </p>
          </div>
        </div>
      </div>
    </Card>
  )
}
