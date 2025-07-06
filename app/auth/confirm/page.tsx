'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { createClient } from '@/lib/supabase/client'
import { CheckCircle, Clock, Loader2, UserPlus, XCircle } from 'lucide-react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Suspense, useEffect, useState } from 'react'

// Define proper types instead of using 'any'
interface DebugInfo {
  searchParams?: Record<string, string>;
  verifyError?: string;
  unexpectedError?: string;
  userCheck?: {
    hasUser: boolean;
    userId?: string;
    email?: string;
    emailConfirmed?: string;
    userError?: unknown;
  };
  profileCheck?: {
    profile_exists?: boolean;
    error?: unknown;
  };
  businessCreation?: {
    success?: boolean;
    data?: unknown;
    error?: unknown;
  };
}

interface UserMetadata {
  businessType?: string;
  businessName?: string;
  fullName?: string;
  [key: string]: unknown;
}

function ConfirmContent() {
  const [status, setStatus] = useState<'loading' | 'success' | 'error' | 'expired' | 'creating_profile'>('loading')
  const [message, setMessage] = useState('')
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null)
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirect') || '/dashboard'

  useEffect(() => {
    const handleEmailConfirmation = async () => {
      const supabase = createClient()
      
      try {
        // Store search params for debugging
        setDebugInfo({
          searchParams: Object.fromEntries(searchParams.entries())
        })

        // Check if user exists (email should be confirmed at this point)
        const { data: { user }, error: userError } = await supabase.auth.getUser()
        
        if (userError) {
          console.error('❌ User check error:', userError)
          setDebugInfo(prev => ({
            ...prev,
            userCheck: {
              hasUser: false,
              userError: userError.message
            }
          }))
          setStatus('error')
          setMessage('Lỗi xác thực tài khoản. Vui lòng thử lại.')
          return
        }

        if (!user) {
          console.log('❌ No user found')
          setDebugInfo(prev => ({
            ...prev,
            userCheck: {
              hasUser: false
            }
          }))
          setStatus('error')
          setMessage('Không tìm thấy tài khoản. Vui lòng đăng ký lại.')
          return
        }

        console.log('✅ User found:', user.id)
        setDebugInfo(prev => ({
          ...prev,
          userCheck: {
            hasUser: true,
            userId: user.id,
            email: user.email,
            emailConfirmed: user.email_confirmed_at
          }
        }))

        // Check email confirmation status
        if (!user.email_confirmed_at) {
          console.log('⚠️ Email not confirmed yet')
          setStatus('error')
          setMessage('Email chưa được xác nhận. Vui lòng kiểm tra email và nhấn vào link xác nhận.')
          return
        }

        // Check if user already has a profile
        const { data: profileData, error: profileError } = await supabase
          .rpc('pos_mini_modular3_get_user_profile_safe', {
            p_user_id: user.id
          })

        if (profileError) {
          console.error('❌ Profile check error:', profileError)
          setDebugInfo(prev => ({
            ...prev,
            profileCheck: {
              error: profileError.message
            }
          }))
          // Continue with profile creation even if check fails
        } else if (profileData?.profile_exists) {
          console.log('✅ User profile already exists')
          setDebugInfo(prev => ({
            ...prev,
            profileCheck: {
              profile_exists: true
            }
          }))
          
          // Profile exists, redirect to dashboard
          setStatus('success')
          setMessage('Tài khoản đã được xác nhận! Đang chuyển hướng...')
          setTimeout(() => {
            router.push(redirectTo)
          }, 2000)
          return
        }

        // Profile doesn't exist, create it
        console.log('📝 Creating user profile...')
        setStatus('creating_profile')
        setMessage('Đang tạo hồ sơ người dùng...')
        
        setDebugInfo(prev => ({
          ...prev,
          profileCheck: {
            profile_exists: false
          }
        }))

        // Get user metadata for profile creation
        const userMetadata = user.user_metadata as UserMetadata
        
        // Create profile using the business registration service
        const { data: businessData, error: businessError } = await supabase
          .rpc('pos_mini_modular3_create_user_profile_after_confirmation', {
            p_user_id: user.id,
            p_email: user.email!,
            p_full_name: userMetadata.fullName || user.email!.split('@')[0],
            p_business_name: userMetadata.businessName || null,
            p_business_type: userMetadata.businessType || 'retail'
          })

        if (businessError) {
          console.error('❌ Profile creation error:', businessError)
          setDebugInfo(prev => ({
            ...prev,
            businessCreation: {
              success: false,
              error: businessError.message
            }
          }))
          setStatus('error')
          setMessage('Có lỗi xảy ra khi tạo hồ sơ. Vui lòng liên hệ hỗ trợ.')
          return
        }

        console.log('✅ Profile created successfully:', businessData)
        setDebugInfo(prev => ({
          ...prev,
          businessCreation: {
            success: true,
            data: businessData
          }
        }))

        // Success - redirect to dashboard
        setStatus('success')
        setMessage('Tài khoản đã được xác nhận và tạo hồ sơ thành công!')
        
        setTimeout(() => {
          router.push(redirectTo)
        }, 2000)

      } catch (error) {
        console.error('❌ Unexpected error:', error)
        const errorMessage = error instanceof Error ? error.message : 'Lỗi không xác định'
        
        setDebugInfo(prev => ({
          ...prev,
          unexpectedError: errorMessage
        }))
        
        setStatus('error')
        setMessage('Có lỗi không mong muốn xảy ra. Vui lòng thử lại.')
      }
    }

    handleEmailConfirmation()
  }, [searchParams, router, redirectTo])

  const getStatusIcon = () => {
    switch (status) {
      case 'loading':
      case 'creating_profile':
        return <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
      case 'success':
        return <CheckCircle className="h-8 w-8 text-green-500" />
      case 'error':
        return <XCircle className="h-8 w-8 text-red-500" />
      case 'expired':
        return <Clock className="h-8 w-8 text-orange-500" />
      default:
        return <UserPlus className="h-8 w-8 text-blue-500" />
    }
  }

  const getStatusColor = () => {
    switch (status) {
      case 'loading':
      case 'creating_profile':
        return 'text-blue-600'
      case 'success':
        return 'text-green-600'
      case 'error':
        return 'text-red-600'
      case 'expired':
        return 'text-orange-600'
      default:
        return 'text-blue-600'
    }
  }

  const getStatusTitle = () => {
    switch (status) {
      case 'loading':
        return 'Đang xác nhận email...'
      case 'creating_profile':
        return 'Đang tạo hồ sơ...'
      case 'success':
        return 'Xác nhận thành công!'
      case 'error':
        return 'Xác nhận thất bại'
      case 'expired':
        return 'Link đã hết hạn'
      default:
        return 'Xác nhận email'
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            {getStatusIcon()}
          </div>
          <CardTitle className={`text-2xl font-bold ${getStatusColor()}`}>
            {getStatusTitle()}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-center">
            <p className="text-gray-600 mb-4">
              {message}
            </p>
          </div>

          {/* Debug info - only show in development */}
          {process.env.NODE_ENV === 'development' && debugInfo && (
            <details className="mt-4 p-3 bg-gray-50 rounded-lg text-xs">
              <summary className="cursor-pointer text-gray-700 font-medium">
                Debug Info (Development Only)
              </summary>
              <pre className="whitespace-pre-wrap text-gray-600 overflow-auto">
                {JSON.stringify(debugInfo, null, 2)}
              </pre>
            </details>
          )}

          {status === 'error' && (
            <div className="space-y-2">
              <button
                onClick={() => window.location.href = '/auth/login'}
                className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 transition-colors"
              >
                Về trang đăng nhập
              </button>
              <button
                onClick={() => window.location.href = '/auth/sign-up'}
                className="w-full bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700 transition-colors"
              >
                Đăng ký lại
              </button>
            </div>
          )}

          {(status === 'success' || status === 'creating_profile') && (
            <div className="text-sm text-gray-500">
              Bạn sẽ được chuyển hướng tự động trong giây lát...
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

// Loading fallback component
function ConfirmPageFallback() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
          </div>
          <CardTitle className="text-2xl font-bold text-blue-600">
            Đang tải...
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center">
            <p className="text-gray-600">
              Vui lòng chờ trong giây lát...
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

// Main export component with Suspense boundary
export default function ConfirmPage() {
  return (
    <Suspense fallback={<ConfirmPageFallback />}>
      <ConfirmContent />
    </Suspense>
  )
}
