'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { createClient } from '@/lib/supabase/client'
import { AlertCircle, Building, Clock, Mail, UserCheck } from 'lucide-react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { Suspense, useCallback, useEffect, useState } from 'react'

interface InvitationData {
  id: string
  email: string
  role: 'manager' | 'seller' | 'accountant'
  expires_at: string
  business: {
    name: string
    business_type: string
  }
  invited_by: {
    full_name: string
    email: string
  }
}

// Loading component for Suspense fallback
function InvitationLoading() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="container mx-auto max-w-md pt-20">
        <Card className="p-8 shadow-lg">
          <div className="text-center">
            <Clock className="mx-auto h-12 w-12 text-blue-600 animate-spin" />
            <h1 className="mt-4 text-2xl font-bold text-gray-900">Đang tải...</h1>
            <p className="mt-2 text-gray-600">Vui lòng chờ trong giây lát</p>
          </div>
        </Card>
      </div>
    </div>
  )
}

// Component that uses useSearchParams
function InvitationContent() {
  const searchParams = useSearchParams()
  const token = searchParams.get('token')
  
  const [invitation, setInvitation] = useState<InvitationData | null>(null)
  const [fullName, setFullName] = useState('')
  const [loading, setLoading] = useState(true)
  const [accepting, setAccepting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  const supabase = createClient()

  const roleLabels = {
    manager: 'Quản lý',
    seller: 'Nhân viên bán hàng',
    accountant: 'Kế toán'
  }

  const businessTypeLabels = {
    retail: 'Bán lẻ',
    restaurant: 'Nhà hàng',
    service: 'Dịch vụ',
    wholesale: 'Bán sỉ'
  }

  const fetchInvitation = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('pos_mini_modular3_business_invitations')
        .select(`
          id,
          email,
          role,
          expires_at,
          business:pos_mini_modular3_businesses!business_id (
            name,
            business_type
          ),
          invited_by:pos_mini_modular3_user_profiles!invited_by (
            full_name,
            email
          )
        `)
        .eq('invitation_token', token)
        .eq('status', 'pending')
        .single()

      if (error || !data) {
        setError('Lời mời không tồn tại hoặc đã hết hạn')
        return
      }

      // Check if invitation is expired
      if (new Date(data.expires_at) < new Date()) {
        setError('Lời mời đã hết hạn')
        return
      }

      // Transform the data to match our interface
      const transformedData = {
        id: data.id,
        email: data.email,
        role: data.role,
        expires_at: data.expires_at,
        business: data.business[0], // Take first element from array
        invited_by: data.invited_by[0] // Take first element from array
      }

      setInvitation(transformedData)
    } catch (error) {
      console.error('Error fetching invitation:', error)
      setError('Không thể tải thông tin lời mời')
    } finally {
      setLoading(false)
    }
  }, [supabase, token])

  useEffect(() => {
    if (!token) {
      setError('Token lời mời không hợp lệ')
      setLoading(false)
      return
    }

    fetchInvitation()
  }, [token, fetchInvitation])

  const handleAcceptInvitation = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!fullName.trim()) {
      setError('Vui lòng nhập họ và tên')
      return
    }

    if (!invitation) return

    setAccepting(true)
    setError(null)

    try {
      // Check if user is authenticated
      const { data: { user } } = await supabase.auth.getUser()

      if (!user) {
        setError('Bạn cần đăng nhập để chấp nhận lời mời')
        return
      }

      // Check if user email matches invitation email
      if (user.email?.toLowerCase() !== invitation.email.toLowerCase()) {
        setError('Email của bạn không khớp với lời mời. Vui lòng đăng nhập bằng email được mời.')
        return
      }

      // Accept invitation using RPC function
      const { data, error } = await supabase.rpc(
        'pos_mini_modular3_accept_invitation',
        {
          p_invitation_token: token,
          p_full_name: fullName.trim()
        }
      )

      if (error) {
        console.error('Error accepting invitation:', error)
        setError('Lỗi khi chấp nhận lời mời')
        return
      }

      if (!data?.success) {
        setError(data?.error || 'Không thể chấp nhận lời mời')
        return
      }

      setSuccess(true)
    } catch (error) {
      console.error('Error in handleAcceptInvitation:', error)
      setError('Đã xảy ra lỗi không mong muốn')
    } finally {
      setAccepting(false)
    }
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <Card className="w-full max-w-md p-8">
          <div className="text-center space-y-4">
            <div className="animate-spin w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto"></div>
            <p className="text-muted-foreground">Đang tải thông tin lời mời...</p>
          </div>
        </Card>
      </div>
    )
  }

  if (error || !invitation) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-50 to-pink-100 flex items-center justify-center p-4">
        <Card className="w-full max-w-md p-8">
          <div className="text-center space-y-4">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto">
              <AlertCircle className="w-8 h-8 text-red-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-red-900">Lời mời không hợp lệ</h1>
              <p className="text-red-700 mt-2">{error}</p>
            </div>
            <Link href="/auth/login">
              <Button variant="outline" className="w-full">
                Về trang đăng nhập
              </Button>
            </Link>
          </div>
        </Card>
      </div>
    )
  }

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-100 flex items-center justify-center p-4">
        <Card className="w-full max-w-md p-8">
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
              <UserCheck className="w-8 h-8 text-green-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-green-900">Chào mừng bạn!</h1>
              <p className="text-green-700 mt-2">
                Bạn đã chấp nhận lời mời thành công và trở thành nhân viên của{' '}
                <strong>{invitation.business.name}</strong>
              </p>
            </div>
            <Link href="/dashboard">
              <Button className="w-full bg-green-600 hover:bg-green-700">
                Vào Dashboard
              </Button>
            </Link>
          </div>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <div className="p-8">
          {/* Header */}
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <UserCheck className="w-8 h-8 text-blue-600" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900">Lời mời nhân viên</h1>
            <p className="text-muted-foreground mt-2">
              Bạn được mời tham gia làm việc tại hộ kinh doanh
            </p>
          </div>

          {/* Invitation Details */}
          <div className="space-y-6 mb-8">
            <div className="bg-blue-50 rounded-lg p-6 space-y-4">
              <div className="flex items-center space-x-3">
                <Building className="w-5 h-5 text-blue-600" />
                <div>
                  <h3 className="font-semibold text-blue-900">{invitation.business.name}</h3>
                  <p className="text-sm text-blue-700">
                    {businessTypeLabels[invitation.business.business_type as keyof typeof businessTypeLabels]}
                  </p>
                </div>
              </div>

              <div className="flex items-center space-x-3">
                <Mail className="w-5 h-5 text-blue-600" />
                <div>
                  <p className="text-sm text-blue-900">Được mời bởi:</p>
                  <p className="font-medium text-blue-900">{invitation.invited_by.full_name}</p>
                  <p className="text-sm text-blue-700">{invitation.invited_by.email}</p>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="text-sm text-blue-900">Vai trò:</span>
                  <Badge className="bg-blue-200 text-blue-900">
                    {roleLabels[invitation.role]}
                  </Badge>
                </div>
                <div className="flex items-center space-x-2 text-sm text-blue-700">
                  <Clock className="w-4 h-4" />
                  <span>{formatTimeRemaining(invitation.expires_at)}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Accept Form */}
          <form onSubmit={handleAcceptInvitation} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="fullName">Họ và tên của bạn</Label>
              <Input
                id="fullName"
                placeholder="Nguyễn Văn A"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                Tên này sẽ hiển thị trong hệ thống
              </p>
            </div>

            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm text-red-600">{error}</p>
              </div>
            )}

            <Button
              type="submit"
              className="w-full bg-blue-600 hover:bg-blue-700"
              disabled={accepting}
            >
              {accepting ? (
                <>
                  <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                  Đang chấp nhận...
                </>
              ) : (
                <>
                  <UserCheck className="mr-2 h-4 w-4" />
                  Chấp nhận lời mời
                </>
              )}
            </Button>
          </form>

          <div className="mt-6 text-center">
            <Link href="/auth/login" className="text-sm text-muted-foreground hover:text-primary">
              Chưa có tài khoản? Đăng ký tại đây
            </Link>
          </div>
        </div>
      </Card>
    </div>
  )
}

// Main component with Suspense boundary
export default function InvitationPage() {
  return (
    <Suspense fallback={<InvitationLoading />}>
      <InvitationContent />
    </Suspense>
  )
}
