import { createClient } from '@/lib/supabase/client'
import { z } from 'zod'

// Types for staff management
export interface StaffMember {
  id: string
  full_name: string
  email: string
  phone?: string
  role: 'manager' | 'seller' | 'accountant'
  status: 'active' | 'inactive' | 'suspended'
  employee_id?: string
  hire_date?: string
  last_login_at?: string
  created_at: string
  avatar_url?: string
}

export interface BusinessInvitation {
  id: string
  email: string
  role: 'manager' | 'seller' | 'accountant'
  status: 'pending' | 'accepted' | 'expired' | 'cancelled'
  expires_at: string
  created_at: string
  invitation_token: string
  invited_by: {
    full_name: string
    email: string
  }
}

// Validation schemas
export const inviteStaffSchema = z.object({
  email: z.string().email('Email không hợp lệ'),
  role: z.enum(['manager', 'seller', 'accountant'], {
    errorMap: () => ({ message: 'Vai trò không hợp lệ' })
  })
})

export const updateStaffSchema = z.object({
  full_name: z.string().min(1, 'Tên không được trống'),
  role: z.enum(['manager', 'seller', 'accountant']),
  status: z.enum(['active', 'inactive', 'suspended']),
  employee_id: z.string().optional(),
  phone: z.string().optional()
})

export type InviteStaffInput = z.infer<typeof inviteStaffSchema>
export type UpdateStaffInput = z.infer<typeof updateStaffSchema>

class StaffManagementService {
  private supabase = createClient()

  // Get all staff members for current business
  async getStaffMembers(): Promise<{ data: StaffMember[] | null; error: string | null }> {
    try {
      const { data: profile } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .select('business_id')
        .eq('id', (await this.supabase.auth.getUser()).data.user?.id)
        .single()

      if (!profile?.business_id) {
        return { data: null, error: 'Không tìm thấy thông tin hộ kinh doanh' }
      }

      const { data, error } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .select(`
          id,
          full_name,
          email,
          phone,
          role,
          status,
          employee_id,
          hire_date,
          last_login_at,
          created_at,
          avatar_url
        `)
        .eq('business_id', profile.business_id)
        .neq('role', 'household_owner') // Exclude business owner
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching staff:', error)
        return { data: null, error: 'Lỗi khi tải danh sách nhân viên' }
      }

      return { data: data as StaffMember[], error: null }
    } catch (error) {
      console.error('Error in getStaffMembers:', error)
      return { data: null, error: 'Lỗi hệ thống' }
    }
  }

  // Get pending invitations
  async getPendingInvitations(): Promise<{ data: BusinessInvitation[] | null; error: string | null }> {
    try {
      const { data: profile } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .select('business_id')
        .eq('id', (await this.supabase.auth.getUser()).data.user?.id)
        .single()

      if (!profile?.business_id) {
        return { data: null, error: 'Không tìm thấy thông tin hộ kinh doanh' }
      }

      const { data, error } = await this.supabase
        .from('pos_mini_modular3_business_invitations')
        .select(`
          id,
          email,
          role,
          status,
          expires_at,
          created_at,
          invitation_token,
          invited_by:pos_mini_modular3_user_profiles!invited_by(
            full_name,
            email
          )
        `)
        .eq('business_id', profile.business_id)
        .eq('status', 'pending')
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching invitations:', error)
        return { data: null, error: 'Lỗi khi tải danh sách lời mời' }
      }

      return { data: data as unknown as BusinessInvitation[], error: null }
    } catch (error) {
      console.error('Error in getPendingInvitations:', error)
      return { data: null, error: 'Lỗi hệ thống' }
    }
  }

  // Invite new staff member
  async inviteStaff(input: InviteStaffInput): Promise<{ success: boolean; error?: string }> {
    try {
      const validatedInput = inviteStaffSchema.parse(input)
      
      const { data: profile } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .select('business_id')
        .eq('id', (await this.supabase.auth.getUser()).data.user?.id)
        .single()

      if (!profile?.business_id) {
        return { success: false, error: 'Không tìm thấy thông tin hộ kinh doanh' }
      }

      const { data, error } = await this.supabase.rpc(
        'pos_mini_modular3_invite_staff_member',
        {
          p_business_id: profile.business_id,
          p_email: validatedInput.email.toLowerCase().trim(),
          p_role: validatedInput.role
        }
      )

      if (error) {
        console.error('Error inviting staff:', error)
        return { success: false, error: 'Lỗi khi gửi lời mời' }
      }

      if (!data?.success) {
        return { success: false, error: data?.error || 'Không thể gửi lời mời' }
      }

      return { success: true }
    } catch (error) {
      if (error instanceof z.ZodError) {
        return { success: false, error: error.errors[0].message }
      }
      console.error('Error in inviteStaff:', error)
      return { success: false, error: 'Lỗi hệ thống' }
    }
  }

  // Update staff member
  async updateStaffMember(staffId: string, input: UpdateStaffInput): Promise<{ success: boolean; error?: string }> {
    try {
      const validatedInput = updateStaffSchema.parse(input)

      const { error } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .update({
          full_name: validatedInput.full_name,
          role: validatedInput.role,
          status: validatedInput.status,
          employee_id: validatedInput.employee_id || null,
          phone: validatedInput.phone || null
        })
        .eq('id', staffId)

      if (error) {
        console.error('Error updating staff:', error)
        return { success: false, error: 'Lỗi khi cập nhật thông tin nhân viên' }
      }

      return { success: true }
    } catch (error) {
      if (error instanceof z.ZodError) {
        return { success: false, error: error.errors[0].message }
      }
      console.error('Error in updateStaffMember:', error)
      return { success: false, error: 'Lỗi hệ thống' }
    }
  }

  // Cancel invitation
  async cancelInvitation(invitationId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await this.supabase
        .from('pos_mini_modular3_business_invitations')
        .update({ status: 'cancelled' })
        .eq('id', invitationId)

      if (error) {
        console.error('Error cancelling invitation:', error)
        return { success: false, error: 'Lỗi khi hủy lời mời' }
      }

      return { success: true }
    } catch (error) {
      console.error('Error in cancelInvitation:', error)
      return { success: false, error: 'Lỗi hệ thống' }
    }
  }

  // Remove staff member (soft delete by changing status)
  async removeStaffMember(staffId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await this.supabase
        .from('pos_mini_modular3_user_profiles')
        .update({ status: 'inactive' })
        .eq('id', staffId)

      if (error) {
        console.error('Error removing staff:', error)
        return { success: false, error: 'Lỗi khi xóa nhân viên' }
      }

      return { success: true }
    } catch (error) {
      console.error('Error in removeStaffMember:', error)
      return { success: false, error: 'Lỗi hệ thống' }
    }
  }

  // Get staff statistics
  async getStaffStats(): Promise<{
    data: {
      total: number
      active: number
      pending_invitations: number
      by_role: Record<string, number>
    } | null
    error: string | null
  }> {
    try {
      const [staffResult, invitationsResult] = await Promise.all([
        this.getStaffMembers(),
        this.getPendingInvitations()
      ])

      if (staffResult.error || invitationsResult.error) {
        return { data: null, error: 'Lỗi khi tải thống kê' }
      }

      const staff = staffResult.data || []
      const invitations = invitationsResult.data || []

      const stats = {
        total: staff.length,
        active: staff.filter(s => s.status === 'active').length,
        pending_invitations: invitations.length,
        by_role: staff.reduce((acc, member) => {
          acc[member.role] = (acc[member.role] || 0) + 1
          return acc
        }, {} as Record<string, number>)
      }

      return { data: stats, error: null }
    } catch (error) {
      console.error('Error in getStaffStats:', error)
      return { data: null, error: 'Lỗi hệ thống' }
    }
  }
}

export const staffService = new StaffManagementService()
