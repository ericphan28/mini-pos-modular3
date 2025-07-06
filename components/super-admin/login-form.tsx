'use client';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface FormData {
  email: string;
  password: string;
}

interface LoginState {
  isLoading: boolean;
  error: string | null;
  step: 'idle' | 'authenticating' | 'verifying' | 'success';
}

// ✅ SỬA: Bỏ JSX.Element return type
export default function SuperAdminLoginForm() {
  const [formData, setFormData] = useState<FormData>({ 
    email: '', 
    password: '' 
  });
  const [loginState, setLoginState] = useState<LoginState>({
    isLoading: false,
    error: null,
    step: 'idle'
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showDevHint, setShowDevHint] = useState(true);
  const router = useRouter();

  const handleInputChange = (field: keyof FormData, value: string): void => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (loginState.error) {
      setLoginState(prev => ({ ...prev, error: null }));
    }
  };

  const validateForm = (): boolean => {
    if (!formData.email.trim()) {
      setLoginState(prev => ({ ...prev, error: 'Email is required' }));
      return false;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      setLoginState(prev => ({ ...prev, error: 'Please enter a valid email address' }));
      return false;
    }
    if (!formData.password) {
      setLoginState(prev => ({ ...prev, error: 'Password is required' }));
      return false;
    }
    if (formData.password.length < 6) {
      setLoginState(prev => ({ ...prev, error: 'Password must be at least 6 characters' }));
      return false;
    }
    return true;
  };

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    
    if (!validateForm()) return;

    console.log('🚀 [SUPER-ADMIN-FORM] ========================================');
    console.log('🚀 [SUPER-ADMIN-FORM] Login attempt started');
    console.log('🚀 [SUPER-ADMIN-FORM] Email:', formData.email);
    console.log('🚀 [SUPER-ADMIN-FORM] Password length:', formData.password.length);
    console.log('🚀 [SUPER-ADMIN-FORM] ========================================');
    
    setLoginState({ isLoading: true, error: null, step: 'authenticating' });

    try {
      const supabase = createClient();
      const trimmedEmail = formData.email.trim().toLowerCase();
      
      console.log('🔍 [SUPER-ADMIN-FORM] Step 1: Creating Supabase client');
      console.log('🔍 [SUPER-ADMIN-FORM] Trimmed email:', trimmedEmail);

      // Step 1: Authentication
      console.log('🔑 [SUPER-ADMIN-FORM] Step 2: Attempting authentication...');
      
      const authStartTime = Date.now();
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: trimmedEmail,
        password: formData.password,
      });
      const authDuration = Date.now() - authStartTime;

      console.log('⏱️ [SUPER-ADMIN-FORM] Auth request took:', authDuration, 'ms');
      console.log('📊 [SUPER-ADMIN-FORM] Auth response:', {
        success: !authError,
        hasUser: !!authData?.user,
        userId: authData?.user?.id,
        userEmail: authData?.user?.email,
        emailConfirmed: authData?.user?.email_confirmed_at,
        authError: authError ? {
          message: authError.message,
          status: authError.status,
          name: authError.name
        } : null
      });

      if (authError) {
        console.error('❌ [SUPER-ADMIN-FORM] Authentication failed');
        console.error('❌ [SUPER-ADMIN-FORM] Error details:', {
          message: authError.message,
          status: authError.status,
          name: authError.name,
          details: (authError as unknown as Record<string, unknown>).details,
          hint: (authError as unknown as Record<string, unknown>).hint
        });
        
        let errorMessage = 'Authentication failed. Please try again.';
        
        if (authError.message.includes('Invalid login credentials')) {
          errorMessage = 'Invalid email or password';
          console.log('🔍 [SUPER-ADMIN-FORM] Specific error: Invalid credentials');
        } else if (authError.message.includes('Email not confirmed')) {
          errorMessage = 'Please confirm your email address before signing in';
          console.log('🔍 [SUPER-ADMIN-FORM] Specific error: Email not confirmed');
        } else if (authError.message.includes('Too many requests')) {
          errorMessage = 'Too many login attempts. Please try again later';
          console.log('🔍 [SUPER-ADMIN-FORM] Specific error: Rate limited');
        }

        setLoginState({ isLoading: false, error: errorMessage, step: 'idle' });
        return;
      }

      if (!authData.user) {
        console.error('❌ [SUPER-ADMIN-FORM] No user data returned despite no auth error');
        setLoginState({ isLoading: false, error: 'Authentication failed', step: 'idle' });
        return;
      }

      console.log('✅ [SUPER-ADMIN-FORM] Authentication successful!');
      console.log('👤 [SUPER-ADMIN-FORM] User details:', {
        id: authData.user.id,
        email: authData.user.email,
        emailConfirmed: authData.user.email_confirmed_at,
        createdAt: authData.user.created_at,
        lastSignIn: authData.user.last_sign_in_at
      });

      // Step 2: Verify super admin privileges
      console.log('🛡️ [SUPER-ADMIN-FORM] Step 3: Verifying super admin privileges...');
      setLoginState(prev => ({ ...prev, step: 'verifying' }));

      const verifyStartTime = Date.now();
      const response = await fetch('/api/auth/verify-super-admin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: authData.user.id }),
      });
      const verifyDuration = Date.now() - verifyStartTime;

      console.log('⏱️ [SUPER-ADMIN-FORM] Verify request took:', verifyDuration, 'ms');
      console.log('📊 [SUPER-ADMIN-FORM] Verify response status:', response.status);

      if (!response.ok) {
        console.error('❌ [SUPER-ADMIN-FORM] API verification failed');
        console.error('❌ [SUPER-ADMIN-FORM] Response details:', {
          status: response.status,
          statusText: response.statusText,
          url: response.url
        });

        // Try to get response body for more details
        try {
          const errorBody = await response.text();
          console.error('❌ [SUPER-ADMIN-FORM] Response body:', errorBody);
        } catch (bodyError) {
          console.error('❌ [SUPER-ADMIN-FORM] Could not read response body:', bodyError);
        }

        await supabase.auth.signOut();
        setLoginState({ 
          isLoading: false, 
          error: 'Unable to verify permissions. Please contact support.', 
          step: 'idle' 
        });
        return;
      }

      const verifyData = await response.json();
      console.log('✅ [SUPER-ADMIN-FORM] Verification successful!');
      console.log('📊 [SUPER-ADMIN-FORM] Verify data:', verifyData);

      // Step 3: Success
      console.log('🎉 [SUPER-ADMIN-FORM] Login process completed successfully!');
      setLoginState({ isLoading: false, error: null, step: 'success' });

      // Redirect to super admin dashboard
      console.log('🚀 [SUPER-ADMIN-FORM] Redirecting to /super-admin...');
      router.push('/super-admin');

    } catch (error) {
      console.error('💥 [SUPER-ADMIN-FORM] Unexpected error during login process');
      console.error('💥 [SUPER-ADMIN-FORM] Error details:', {
        name: error instanceof Error ? error.name : 'Unknown',
        message: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });

      setLoginState({ 
        isLoading: false, 
        error: 'An unexpected error occurred. Please try again.', 
        step: 'idle' 
      });
    }

    console.log('🏁 [SUPER-ADMIN-FORM] Login process ended');
    console.log('🚀 [SUPER-ADMIN-FORM] ========================================');
  };

  const getStatusText = (): string => {
    switch (loginState.step) {
      case 'authenticating':
        return 'Authenticating...';
      case 'verifying':
        return 'Verifying permissions...';
      case 'success':
        return 'Login successful!';
      default:
        return 'Sign In';
    }
  };

  return (
    <div className="w-full max-w-md mx-auto">
      {/* Development hint */}
      {showDevHint && (
        <div className="mb-6 p-4 bg-amber-50 border border-amber-200 rounded-lg">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-amber-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <p className="text-sm text-amber-700">
                <strong>Development Mode:</strong> Use registered super admin credentials.
              </p>
              <button
                onClick={() => setShowDevHint(false)}
                className="text-xs text-amber-600 hover:text-amber-800 underline mt-1"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <Label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Email Address
          </Label>
          <Input
            id="email"
            type="email"
            value={formData.email}
            onChange={(e) => handleInputChange('email', e.target.value)}
            placeholder="admin@giakiemso.com"
            className="mt-1"
            disabled={loginState.isLoading}
            autoComplete="email"
            required
          />
        </div>

        <div>
          <Label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Password
          </Label>
          <div className="mt-1 relative">
            <Input
              id="password"
              type={showPassword ? 'text' : 'password'}
              value={formData.password}
              onChange={(e) => handleInputChange('password', e.target.value)}
              placeholder="Enter your password"
              className="pr-10"
              disabled={loginState.isLoading}
              autoComplete="current-password"
              required
            />
            <button
              type="button"
              className="absolute inset-y-0 right-0 pr-3 flex items-center"
              onClick={() => setShowPassword(!showPassword)}
              disabled={loginState.isLoading}
            >
              {showPassword ? (
                <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
                </svg>
              ) : (
                <svg className="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {loginState.error && (
          <div className="rounded-md bg-red-50 p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{loginState.error}</p>
              </div>
            </div>
          </div>
        )}

        <Button
          type="submit"
          className="w-full"
          disabled={loginState.isLoading}
        >
          {loginState.isLoading ? (
            <div className="flex items-center">
              <svg className="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {getStatusText()}
            </div>
          ) : (
            getStatusText()
          )}
        </Button>
      </form>

      <div className="mt-6 text-center">
        <p className="text-xs text-gray-500">
          Check browser console for detailed debug information
        </p>
      </div>
    </div>
  );
}
