import { BusinessRegistrationEnhancedService } from '@/lib/services/business-registration-enhanced.service';
import { ErrorHandler } from '@/lib/services/error-handler.service';
import { createClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    const supabase = await createClient();
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ success: false, error: 'Unauthorized' }, { status: 401 });
    }
    
    const { data: isSuperAdmin, error: roleError } = await supabase.rpc('pos_mini_modular3_is_super_admin');
    
    if (roleError || !isSuperAdmin) {
      return NextResponse.json({ success: false, error: 'Forbidden' }, { status: 403 });
    }
    
    console.log('🔐 API: Super Admin authentication verified for user:', user.email);
    
    // ✅ RESTORED: Use the service layer, which is now fixed.
    const businessService = BusinessRegistrationEnhancedService.getInstance(supabase);

    console.log('🔵 API: Original request body:', body);

    // Map data from request body to service data structure
    const mappedData = {
      business_name: body.businessName?.trim() || '',
      contact_method: body.contactMethod as 'email' | 'phone',
      contact_value: body.contactValue?.trim() || '',
      owner_full_name: body.ownerFullName?.trim() || '',
      business_type: body.businessType || 'retail',
      subscription_tier: body.subscriptionTier || 'free',
      business_status: body.businessStatus || 'trial', // Service will convert this to p_is_active
      subscription_status: body.subscriptionStatus || 'trial',
      set_password: body.setPassword?.trim() || undefined
    };

    console.log('🔵 API: Mapped data for service:', mappedData);

    const result = await businessService.createBusinessWithOwnerEnhanced(mappedData);

    if (!result.success) {
      console.error('❌ API: Business creation failed:', result.error);
      return NextResponse.json({
        success: false,
        error: result.error || 'Business creation failed',
        error_code: result.error_code,
        validationDetails: result.validationDetails
      }, { status: 400 });
    }

    console.log('✅ API: Business created successfully via service:', {
      businessId: result.business_id,
      businessName: result.business_name,
    });

    return NextResponse.json({
      success: true,
      data: result
    }, { status: 200 });

  } catch (error) {
    const errorResponse = ErrorHandler.parseError(error);
    console.error('❌ API: Exception caught:', errorResponse);
    return NextResponse.json({
      success: false,
      error: errorResponse.userMessage,
    }, { status: 500 });
  }
}
