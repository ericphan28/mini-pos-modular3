import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
// import { sessionManager } from '@/lib/session'; // DISABLED - Using React Context pattern

export async function POST(request: NextRequest): Promise<NextResponse> {
  const startTime = Date.now();
  
  try {
    console.log('\n🚪 ============= LOGOUT REQUEST STARTED =============');
    console.log('📅 Timestamp:', new Date().toISOString());
    console.log('🌐 User-Agent:', request.headers.get('user-agent') || 'Unknown');
    console.log('📍 IP Address:', request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'Unknown');

    // Parse request body
    const body = await request.json();
    console.log('📦 Request Body:', JSON.stringify(body, null, 2));

    const { userId, reason = 'manual' } = body;

    if (!userId) {
      console.log('❌ Logout failed: Missing userId');
      return NextResponse.json(
        { success: false, error: 'Missing userId' },
        { status: 400 }
      );
    }

    console.log('👤 User ID:', userId);
    console.log('🔍 Logout Reason:', reason);

    // Get current session before logout - DISABLED (Using React Context pattern)
    // const currentSession = await sessionManager.getValidSession(userId);
    console.log('🔑 Current Session: Using React Context pattern - API simplified');
    
    // Create Supabase client
    const supabase = await createClient();
    
    // Get Supabase session
    const { data: { session: supabaseSession } } = await supabase.auth.getSession();
    console.log('🔐 Supabase Session:', supabaseSession ? 'Active' : 'None');

    // Perform logout with session manager - DISABLED (Using React Context pattern)
    console.log('\n🔄 Executing simplified logout process...');
    // await sessionManager.logout(userId); // DISABLED - React Context handles this
    console.log('⚠️ SessionManager logout DISABLED - React Context pattern used');

    // Supabase logout
    if (supabaseSession) {
      console.log('🔄 Signing out from Supabase...');
      await supabase.auth.signOut();
      console.log('✅ Supabase logout completed');
    }

    // Log to database via terminal-log API
    try {
      console.log('📝 Logging to database...');
      
      const logData = {
        operation: 'USER_LOGOUT',
        user_id: userId,
        status: 'success',
        details: {
          reason,
          sessionId: 'react-context-session', // currentSession?.sessionId - DISABLED
          logoutTime: new Date().toISOString(),
          userAgent: request.headers.get('user-agent'),
          ipAddress: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip'),
          duration: Date.now() - startTime
        },
        timestamp: new Date().toISOString()
      };

      // Use terminal-log API for database logging
      const logResponse = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/terminal-log`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(logData)
      });

      if (logResponse.ok) {
        console.log('✅ Database log saved successfully');
      } else {
        console.log('⚠️ Database log failed:', await logResponse.text());
      }
    } catch (logError) {
      console.log('⚠️ Database logging error:', logError);
    }

    const duration = Date.now() - startTime;
    console.log('\n🎉 LOGOUT COMPLETED SUCCESSFULLY');
    console.log('⏱️ Total Duration:', `${duration}ms`);
    console.log('🚪 ============= LOGOUT REQUEST ENDED =============\n');

    return NextResponse.json({
      success: true,
      message: 'Logout successful',
      data: {
        userId,
        reason,
        duration,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    const duration = Date.now() - startTime;
    
    console.log('\n💥 LOGOUT ERROR OCCURRED');
    console.log('❌ Error:', error instanceof Error ? error.message : 'Unknown error');
    console.log('⏱️ Duration:', `${duration}ms`);
    console.log('🚪 ============= LOGOUT REQUEST ENDED =============\n');

    return NextResponse.json(
      { 
        success: false, 
        error: error instanceof Error ? error.message : 'Logout failed',
        duration 
      },
      { status: 500 }
    );
  }
}
