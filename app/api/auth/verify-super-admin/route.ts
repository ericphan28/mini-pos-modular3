import { checkSuperAdminAccess } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

// Support both GET and POST methods
export async function GET(request: NextRequest) {
  return handleVerification(request);
}

export async function POST(request: NextRequest) {
  return handleVerification(request);
}

async function handleVerification(request: NextRequest) {
  const requestId = Math.random().toString(36).substring(7);
  
  try {
    console.log('� ================================');
    console.log(`�🔍 [API-VERIFY-${requestId}] Super admin verification started`);
    console.log(`🔍 [API-VERIFY-${requestId}] Method: ${request.method}`);
    console.log(`🔍 [API-VERIFY-${requestId}] URL: ${request.url}`);
    console.log(`🔍 [API-VERIFY-${requestId}] Headers:`, {
      userAgent: request.headers.get('user-agent'),
      contentType: request.headers.get('content-type'),
      authorization: request.headers.get('authorization') ? 'Present' : 'Missing',
      cookie: request.headers.get('cookie') ? 'Present' : 'Missing'
    });

    // Try to get request body if POST
    if (request.method === 'POST') {
      try {
        const body = await request.json();
        console.log(`📝 [API-VERIFY-${requestId}] Request body:`, body);
      } catch (bodyError) {
        console.log(`⚠️ [API-VERIFY-${requestId}] Could not parse request body:`, bodyError);
      }
    }

    // Get current authenticated user
    console.log(`🔐 [API-VERIFY-${requestId}] Creating Supabase client...`);
    const supabase = await createClient();
    
    console.log(`👤 [API-VERIFY-${requestId}] Getting authenticated user...`);
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    console.log(`📊 [API-VERIFY-${requestId}] Auth result:`, {
      hasUser: !!user,
      userId: user?.id,
      userEmail: user?.email,
      authError: authError ? {
        message: authError.message,
        name: authError.name
      } : null
    });

    if (authError || !user) {
      console.log(`❌ [API-VERIFY-${requestId}] No authenticated user`);
      console.log(`❌ [API-VERIFY-${requestId}] Auth error details:`, authError);
      return NextResponse.json(
        { 
          error: 'Unauthorized', 
          isSuperAdmin: false,
          details: 'No authenticated user found',
          requestId 
        },
        { status: 401 }
      );
    }

    console.log(`�️ [API-VERIFY-${requestId}] Checking super admin access for user: ${user.id}`);
    console.log(`🛡️ [API-VERIFY-${requestId}] User email: ${user.email}`);

    // Check super admin privileges
    const startTime = Date.now();
    const isSuperAdmin = await checkSuperAdminAccess(user.id);
    const checkDuration = Date.now() - startTime;

    console.log(`⏱️ [API-VERIFY-${requestId}] Super admin check took: ${checkDuration}ms`);
    console.log(`✅ [API-VERIFY-${requestId}] Super admin check result: ${isSuperAdmin}`);

    // Log access attempt for audit trail
    const auditLog = {
      requestId,
      userId: user.id,
      email: user.email,
      timestamp: new Date().toISOString(),
      isSuperAdmin,
      userAgent: request.headers.get('user-agent'),
      ip: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown',
      method: request.method,
      checkDuration
    };
    
    console.log(`📝 [API-VERIFY-${requestId}] Audit log:`, auditLog);

    const response = {
      isSuperAdmin,
      userId: user.id,
      email: user.email,
      timestamp: new Date().toISOString(),
      requestId
    };

    console.log(`🎉 [API-VERIFY-${requestId}] Verification successful, returning:`, response);
    console.log('🚀 ================================');

    return NextResponse.json(response);
    
  } catch (error) {
    console.error(`� [API-VERIFY-${requestId}] Unexpected error:`, {
      name: error instanceof Error ? error.name : 'Unknown',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined
    });
    
    console.log('🚀 ================================');
    
    return NextResponse.json(
      { 
        error: 'Internal server error', 
        isSuperAdmin: false,
        details: error instanceof Error ? error.message : 'Unknown error',
        requestId 
      },
      { status: 500 }
    );
  }
}
