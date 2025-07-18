'use client';

import React, { createContext, useContext, useReducer, useCallback, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { 
  AuthContext, 
  AuthContextState, 
  SessionData, 
  AuthUser, 
  UserProfile, 
  BusinessContext, 
  PermissionSet 
} from './types';

// Auth state reducer actions
type AuthAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_SESSION'; payload: SessionData }
  | { type: 'SET_ERROR'; payload: string }
  | { type: 'CLEAR_SESSION' }
  | { type: 'CLEAR_ERROR' }
  | { type: 'UPDATE_LAST_ACTIVITY' };

// Initial state
const initialState: AuthContextState = {
  isLoading: true,
  isAuthenticated: false,
  sessionData: null,
  error: null,
};

// Auth reducer
function authReducer(state: AuthContextState, action: AuthAction): AuthContextState {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    
    case 'SET_SESSION':
      return {
        ...state,
        isLoading: false,
        isAuthenticated: true,
        sessionData: action.payload,
        error: null,
      };
    
    case 'SET_ERROR':
      return {
        ...state,
        isLoading: false,
        error: action.payload,
      };
    
    case 'CLEAR_SESSION':
      return {
        ...initialState,
        isLoading: false,
      };
    
    case 'CLEAR_ERROR':
      return { ...state, error: null };
    
    case 'UPDATE_LAST_ACTIVITY':
      return state.sessionData ? {
        ...state,
        sessionData: {
          ...state.sessionData,
          lastActivity: new Date().toISOString(),
        },
      } : state;
    
    default:
      return state;
  }
}

// Create context
const AuthContextInstance = createContext<AuthContext | null>(null);

// Auth provider component
interface AuthProviderProps {
  readonly children: React.ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [state, dispatch] = useReducer(authReducer, initialState);
  const supabase = createClient();

  // Load session from cache
  const loadCachedSession = useCallback((): SessionData | null => {
    try {
      const cached = localStorage.getItem('pos_session_data');
      if (cached) {
        const sessionData = JSON.parse(cached) as SessionData;
        return sessionData;
      }
    } catch (error) {
      console.warn('Failed to load cached session:', error);
    }
    return null;
  }, []);

  // Save session to cache
  const saveCachedSession = useCallback((sessionData: SessionData): void => {
    try {
      localStorage.setItem('pos_session_data', JSON.stringify(sessionData));
    } catch (error) {
      console.warn('Failed to save session to cache:', error);
    }
  }, []);

  // Clear cached session
  const clearCachedSession = useCallback((): void => {
    try {
      localStorage.removeItem('pos_session_data');
    } catch (error) {
      console.warn('Failed to clear cached session:', error);
    }
  }, []);

  // Load complete session data
  const loadCompleteSession = useCallback(async (user: AuthUser): Promise<void> => {
    try {
      // Load user profile
      const { data: profileData, error: profileError } = await supabase
        .rpc('get_enhanced_user_profile', { user_id: user.id });

      if (profileError || !profileData.success) {
        throw new Error('Failed to load user profile');
      }

      const profile: UserProfile = {
        id: user.id,
        fullName: profileData.profile.full_name || user.email || '',
        email: user.email || '',
        avatarUrl: profileData.profile.avatar_url,
        phoneNumber: profileData.profile.phone_number,
        timezone: profileData.profile.timezone,
      };

      const business: BusinessContext = {
        id: profileData.business.id,
        name: profileData.business.name,
        status: profileData.business.status,
        subscriptionTier: profileData.business.subscription_tier,
        subscriptionStatus: profileData.business.subscription_status,
      };

      const permissions: PermissionSet = {
        role: profileData.permissions.role,
        permissions: profileData.permissions.permissions || [],
        features: profileData.permissions.features || [],
      };

      const sessionData: SessionData = {
        user,
        profile,
        business,
        permissions,
        loginTime: new Date().toISOString(),
        lastActivity: new Date().toISOString(),
      };

      // Save to cache and state
      saveCachedSession(sessionData);
      dispatch({ type: 'SET_SESSION', payload: sessionData });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to load session data';
      dispatch({ type: 'SET_ERROR', payload: message });
      throw error;
    }
  }, [supabase, saveCachedSession]);

  // Login function
  const login = useCallback(async (email: string, password: string): Promise<void> => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      // Authenticate with Supabase
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError || !authData.user) {
        throw new Error(authError?.message || 'Authentication failed');
      }

      // Load complete session data
      await loadCompleteSession(authData.user as AuthUser);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Login failed';
      dispatch({ type: 'SET_ERROR', payload: message });
      throw error;
    }
  }, [supabase.auth, loadCompleteSession]);

  // Logout function
  const logout = useCallback(async (): Promise<void> => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });

      // Sign out from Supabase
      await supabase.auth.signOut();

      // Clear cached session
      clearCachedSession();

      // Update state
      dispatch({ type: 'CLEAR_SESSION' });
    } catch (error) {
      console.error('Logout error:', error);
      // Even if logout fails, clear local state
      clearCachedSession();
      dispatch({ type: 'CLEAR_SESSION' });
    }
  }, [supabase.auth, clearCachedSession]);

  // Check permission
  const checkPermission = useCallback((feature: string, action = 'read'): boolean => {
    if (!state.sessionData) return false;
    
    const { permissions } = state.sessionData;
    const permissionKey = `${feature}:${action}`;
    
    return permissions.permissions.includes(permissionKey) || 
           permissions.features.includes(feature);
  }, [state.sessionData]);

  // Refresh session
  const refreshSession = useCallback(async (): Promise<void> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await loadCompleteSession(user as AuthUser);
      } else {
        dispatch({ type: 'CLEAR_SESSION' });
      }
    } catch (error) {
      console.error('Session refresh failed:', error);
      dispatch({ type: 'CLEAR_SESSION' });
    }
  }, [supabase.auth, loadCompleteSession]);

  // Clear error
  const clearError = useCallback((): void => {
    dispatch({ type: 'CLEAR_ERROR' });
  }, []);

  // Initialize session on mount
  useEffect(() => {
    let mounted = true;

    const initializeSession = async (): Promise<void> => {
      try {
        // Check cached session first
        const cached = loadCachedSession();
        if (cached && mounted) {
          dispatch({ type: 'SET_SESSION', payload: cached });
        }

        // Verify with Supabase
        const { data: { user } } = await supabase.auth.getUser();
        if (user && mounted) {
          await loadCompleteSession(user as AuthUser);
        } else if (mounted) {
          clearCachedSession();
          dispatch({ type: 'CLEAR_SESSION' });
        }
      } catch (error) {
        console.error('Session initialization failed:', error);
        if (mounted) {
          clearCachedSession();
          dispatch({ type: 'CLEAR_SESSION' });
        }
      }
    };

    initializeSession();

    return () => {
      mounted = false;
    };
  }, [supabase.auth, loadCachedSession, loadCompleteSession, clearCachedSession]);

  // Activity tracking
  useEffect(() => {
    if (!state.isAuthenticated) return;

    const updateActivity = (): void => {
      dispatch({ type: 'UPDATE_LAST_ACTIVITY' });
    };

    const events = ['mousedown', 'keydown', 'scroll', 'touchstart'];
    events.forEach(event => {
      document.addEventListener(event, updateActivity, { passive: true });
    });

    return () => {
      events.forEach(event => {
        document.removeEventListener(event, updateActivity);
      });
    };
  }, [state.isAuthenticated]);

  // Context value
  const contextValue: AuthContext = {
    ...state,
    login,
    logout,
    checkPermission,
    refreshSession,
    clearError,
  };

  return (
    <AuthContextInstance.Provider value={contextValue}>
      {children}
    </AuthContextInstance.Provider>
  );
}

// Hook to use auth context
export function useAuth(): AuthContext {
  const context = useContext(AuthContextInstance);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
