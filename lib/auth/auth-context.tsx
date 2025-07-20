'use client';

import React, { createContext, useContext, useReducer, useCallback, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import { authPermissionBridge, initializePermissions } from '@/lib/permissions/auth-permission-integration';
import type { 
  AuthContext, 
  AuthContextState, 
  SessionData, 
  AuthUser, 
  UserProfile, 
  BusinessContext, 
  PermissionSet,
  PermissionCache
} from './types';

// Auth state reducer actions
type AuthAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_SESSION'; payload: SessionData }
  | { type: 'SET_ERROR'; payload: string }
  | { type: 'CLEAR_SESSION' }
  | { type: 'CLEAR_ERROR' }
  | { type: 'UPDATE_LAST_ACTIVITY' }
  | { type: 'SET_PERMISSION_LOADING'; payload: boolean }
  | { type: 'SET_PERMISSION_CACHE'; payload: PermissionCache };

// Initial state
const initialState: AuthContextState = {
  isLoading: true,
  isAuthenticated: false,
  sessionData: null,
  error: null,
  permissionCache: null,
  permissionLoading: false,
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
    
    case 'SET_PERMISSION_LOADING':
      return { ...state, permissionLoading: action.payload };
    
    case 'SET_PERMISSION_CACHE':
      return { ...state, permissionCache: action.payload, permissionLoading: false };
    
    default:
      return state;
  }
}

// Create context
const AuthContextInstance = createContext<AuthContext | null>(null);

// Auth provider component
interface AuthProviderProps {
  readonly children: React.ReactNode;
  readonly initialSessionData?: SessionData | null;
}

export function AuthProvider({ children, initialSessionData }: AuthProviderProps) {
  const [state, dispatch] = useReducer(authReducer, initialState);
  const supabase = createClient();

  // Load session from cache with validation
  const loadCachedSession = useCallback((): SessionData | null => {
    try {
      const cached = localStorage.getItem('pos_session_data');
      if (cached) {
        const sessionData = JSON.parse(cached) as SessionData;
        
        // Validate session age (24 hours max)
        const sessionAge = Date.now() - new Date(sessionData.loginTime).getTime();
        const maxAge = 24 * 60 * 60 * 1000; // 24 hours
        
        if (sessionAge > maxAge) {
          console.warn('🔐 [AUTH CONTEXT] Cached session expired, clearing');
          localStorage.removeItem('pos_session_data');
          return null;
        }
        
        // Validate business status
        if (sessionData.business.status !== 'active') {
          console.warn('🔐 [AUTH CONTEXT] Business not active in cache, clearing');
          localStorage.removeItem('pos_session_data');
          return null;
        }
        
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

  // Load user session with permissions using existing database function
  const loadUserSession = useCallback(async (user: AuthUser): Promise<void> => {
    try {
      console.log('🔐 [AUTH CONTEXT] Loading user session for:', user.id);
      
      // Call existing RPC function that includes complete user, business and permissions data
      const { data: userData, error: profileError } = await supabase.rpc(
        'pos_mini_modular3_get_user_with_business_complete',
        { p_user_id: user.id }
      );

      console.log('🔐 [AUTH CONTEXT] RPC response:', { userData, profileError });

      if (profileError) {
        console.error('🔐 [AUTH CONTEXT] Profile error:', profileError);
        throw new Error(`Profile error: ${profileError.message}`);
      }

      if (!userData) {
        console.error('🔐 [AUTH CONTEXT] No profile data returned');
        throw new Error('No profile data returned');
      }

      // Check if the response indicates success
      if (!userData.success) {
        console.error('🔐 [AUTH CONTEXT] User session load failed:', userData.error, userData.message);
        throw new Error(userData.message || 'Failed to load user session');
      }

      // Extract user, business and permissions from the JSON response
      const userInfo = userData.user;
      const businessInfo = userData.business;
      const permissionsInfo = userData.permissions || {};
      const sessionInfo = userData.session_info || {};

      console.log('🔐 [AUTH CONTEXT] Extracted data:', { userInfo, businessInfo, permissionsInfo });

      // Validate required data - STRICT VALIDATION
      if (!userInfo || !businessInfo) {
        console.error('🔐 [AUTH CONTEXT] Missing required data:', { 
          hasUserInfo: !!userInfo, 
          hasBusinessInfo: !!businessInfo 
        });
        throw new Error('Thiếu thông tin user hoặc business từ database');
      }

      // Validate business ID exists
      if (!businessInfo.id) {
        console.error('🔐 [AUTH CONTEXT] Business ID không hợp lệ:', businessInfo);
        throw new Error('User không có business ID hợp lệ');
      }

      // Validate business status - MUST be active
      if (businessInfo.status !== 'active') {
        console.error('🔐 [AUTH CONTEXT] Business không active:', { 
          businessId: businessInfo.id,
          currentStatus: businessInfo.status 
        });
        throw new Error(`Business không active. Status: ${businessInfo.status}`);
      }

      // Validate subscription status - ALIGN WITH ACTUAL DATA
      if (businessInfo.subscription_status && !['active', 'trial'].includes(businessInfo.subscription_status)) {
        console.error('🔐 [AUTH CONTEXT] Subscription không hợp lệ:', {
          businessId: businessInfo.id,
          subscriptionStatus: businessInfo.subscription_status
        });
        throw new Error(`Subscription không hợp lệ: ${businessInfo.subscription_status}`);
      }

      // Log actual business data for debugging
      console.log('🔐 [AUTH CONTEXT] Business data validation:', {
        businessId: businessInfo.id,
        businessName: businessInfo.name,
        actualSubscriptionTier: businessInfo.subscription_tier, // Should be 'free' not 'premium'
        actualSubscriptionStatus: businessInfo.subscription_status, // Should be 'active'
        businessStatus: businessInfo.status
      });

      // Build profile from the user object
      const profile: UserProfile = {
        id: userInfo.profile_id || userInfo.id,
        fullName: userInfo.full_name || '',
        email: userInfo.email || user.email,
        phoneNumber: userInfo.phone || undefined,
      };

      // Build business context from the business object - MATCH ACTUAL DATABASE SCHEMA
      // Map 'free' tier to 'basic' for compatibility while preserving original value
      const actualTier = businessInfo.subscription_tier;
      const mappedTier = actualTier === 'free' ? 'basic' : actualTier;
      
      console.log('🔐 [AUTH CONTEXT] Subscription tier mapping:', {
        actual: actualTier,
        mapped: mappedTier
      });

      const business: BusinessContext = {
        id: businessInfo.id,
        name: businessInfo.name,
        status: businessInfo.status as 'active' | 'inactive' | 'suspended',
        subscriptionTier: mappedTier as 'basic' | 'premium' | 'enterprise',
        subscriptionStatus: businessInfo.subscription_status as 'active' | 'expired' | 'canceled' | 'trial',
      };

      console.log('🔐 [AUTH CONTEXT] Business context built:', {
        id: business.id,
        name: business.name,
        actualTier: actualTier, // Original from database: 'free'
        mappedTier: business.subscriptionTier, // For feature access: 'basic'
        subscriptionStatus: business.subscriptionStatus,
        businessStatus: business.status
      });

      // Build permissions with actual database structure
      // Database returns: { "feature_name": { can_read: bool, can_write: bool, can_delete: bool, can_manage: bool } }
      const features: string[] = [];
      const permissionsList: string[] = [];

      console.log('🔐 [AUTH CONTEXT] Raw permissions from database:', permissionsInfo);

      Object.entries(permissionsInfo).forEach(([featureName, permissions]) => {
        const perms = permissions as { can_read?: boolean; can_write?: boolean; can_delete?: boolean; can_manage?: boolean };
        
        console.log(`🔐 [AUTH CONTEXT] Processing feature: ${featureName}`, perms);
        
        // Add feature if user has any permission
        if (perms.can_read || perms.can_write || perms.can_delete || perms.can_manage) {
          features.push(featureName);
        }

        // Build permission strings in correct format (feature.action)
        if (perms.can_read) permissionsList.push(`${featureName}.read`);
        if (perms.can_write) permissionsList.push(`${featureName}.write`);
        if (perms.can_delete) permissionsList.push(`${featureName}.delete`);
        if (perms.can_manage) permissionsList.push(`${featureName}.manage`);
      });

      console.log('🔐 [AUTH CONTEXT] Processed permissions:', {
        totalFeatures: features.length,
        totalPermissions: permissionsList.length,
        features: features,
        permissions: permissionsList
      });

      // Validate permission count với actual database expectations
      // Expected cho household_owner + free tier: 7 features, ~25 permissions total
      if (userInfo.role === 'household_owner' && actualTier === 'free') {
        console.log('🔐 [AUTH CONTEXT] Household owner validation:', {
          expectedFeatures: 7,
          actualFeatures: features.length,
          expectedPermissionsRange: '20-28',
          actualPermissions: permissionsList.length,
          featuresMatch: features.length === 7,
          permissionsInRange: permissionsList.length >= 20 && permissionsList.length <= 28
        });
        
        if (features.length !== 7) {
          console.warn('🔐 [AUTH CONTEXT] WARNING: Feature count mismatch for household_owner', {
            expected: 7,
            actual: features.length,
            subscriptionTier: actualTier
          });
        }
      }

      const permissions: PermissionSet = {
        role: userInfo.role || 'viewer',
        permissions: permissionsList,
        features: features,
      };

      console.log('🔐 [AUTH CONTEXT] Built session objects:', { profile, business, permissions });

      const sessionData: SessionData = {
        user,
        profile,
        business,
        permissions,
        loginTime: sessionInfo.login_time || new Date().toISOString(),
        lastActivity: new Date().toISOString(),
      };

      console.log('🔐 [AUTH CONTEXT] Session data saved successfully');

      // Save to cache and state
      saveCachedSession(sessionData);
      dispatch({ type: 'SET_SESSION', payload: sessionData });

      // Generate permission cache asynchronously
      try {
        dispatch({ type: 'SET_PERMISSION_LOADING', payload: true });
        const permissionCache = await initializePermissions(sessionData);
        dispatch({ type: 'SET_PERMISSION_CACHE', payload: permissionCache });
        console.log('🔐 [AUTH CONTEXT] Permission cache initialized:', permissionCache);
      } catch (permissionError) {
        console.error('🔐 [AUTH CONTEXT] Permission cache initialization failed:', permissionError);
        dispatch({ type: 'SET_PERMISSION_LOADING', payload: false });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to load session data';
      console.error('🔐 [AUTH CONTEXT] Session load error:', { 
        error: message, 
        userId: user.id,
        timestamp: new Date().toISOString() 
      });
      dispatch({ type: 'SET_ERROR', payload: message });
      throw error;
    }
  }, [supabase, saveCachedSession]);  // Login function
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
      await loadUserSession(authData.user as AuthUser);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Login failed';
      dispatch({ type: 'SET_ERROR', payload: message });
      throw error;
    }
  }, [supabase.auth, loadUserSession]);

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

  // Check permission - corrected to match database schema
  const checkPermission = useCallback((feature: string, action = 'read'): boolean => {
    if (!state.sessionData) return false;
    
    const { permissions } = state.sessionData;
    
    // Database uses format: "product_management.read", "staff_management.write", etc.
    const permissionKey = `${feature}.${action}`;
    
    // Check explicit permission first
    if (permissions.permissions.includes(permissionKey)) {
      return true;
    }
    
    // Fallback: if user has feature access and it's read action
    if (action === 'read' && permissions.features.includes(feature)) {
      return true;
    }
    
    // Super admin or household_owner has all permissions
    if (permissions.role === 'super_admin' || permissions.role === 'household_owner') {
      return true;
    }
    
    return false;
  }, [state.sessionData]);

  // Refresh session
  const refreshSession = useCallback(async (): Promise<void> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await loadUserSession(user as AuthUser);
      } else {
        dispatch({ type: 'CLEAR_SESSION' });
      }
    } catch (error) {
      console.error('Session refresh failed:', error);
      dispatch({ type: 'CLEAR_SESSION' });
    }
  }, [supabase.auth, loadUserSession]);

  // Clear error
  const clearError = useCallback((): void => {
    dispatch({ type: 'CLEAR_ERROR' });
  }, []);

  // ==================================================================================
  // ENHANCED PERMISSION METHODS
  // ==================================================================================

  // Enhanced permission checking
  const hasPermission = useCallback((permission: string): boolean => {
    if (!state.sessionData) {
      return false;
    }

    const { permissions } = state.sessionData;
    
    // Check if permission exists directly
    if (permissions.permissions.includes(permission)) {
      return true;
    }

    // Convert legacy format to database format and check
    const databaseFormat = convertLegacyToDatabase(permission);
    if (databaseFormat && permissions.permissions.includes(databaseFormat)) {
      return true;
    }

    // Super admin or household_owner has all permissions
    if (permissions.role === 'super_admin' || permissions.role === 'household_owner') {
      return true;
    }
    
    return false;
  }, [state.sessionData]);

  /**
   * Convert legacy permission format to database format
   */
  const convertLegacyToDatabase = (permission: string): string | null => {
    const legacyToDatabase: Record<string, string> = {
      'staff_view': 'staff_management.read',
      'staff_create': 'staff_management.write',
      'staff_edit': 'staff_management.write',
      'staff_delete': 'staff_management.delete',
      'product_view': 'product_management.read',
      'product_create': 'product_management.write',
      'product_edit': 'product_management.write',
      'product_delete': 'product_management.delete',
      'financial_view': 'financial_tracking.read',
      'report_view': 'basic_reports.read',
      'pos_access': 'pos_interface.read'
    };

    return legacyToDatabase[permission] || null;
  };

  // Feature access checking
  const hasFeatureAccess = useCallback((feature: string): boolean => {
    if (!state.sessionData) {
      return false;
    }

    const { permissions } = state.sessionData;

    // Super admin or household_owner has all features
    if (permissions.role === 'super_admin' || permissions.role === 'household_owner') {
      return true;
    }

    // Check if feature exists in user's features list
    const userFeatures = permissions.features || [];
    return userFeatures.includes(feature);
  }, [state.sessionData]);

  // Route access checking  
  const canAccessRoute = useCallback((route: string): boolean => {
    if (!state.sessionData) {
      return false;
    }

    const { permissions } = state.sessionData;

    // Super admin or household_owner has all routes
    if (permissions.role === 'super_admin' || permissions.role === 'household_owner') {
      return true;
    }

    // Map routes to features
    const routeToFeature: Record<string, string> = {
      '/dashboard': 'dashboard',
      '/staff': 'staff_management', 
      '/products': 'product_management',
      '/financial': 'financial_tracking',
      '/reports': 'basic_reports',
      '/pos': 'pos_interface',
      '/inventory': 'inventory_management',
      '/customer': 'customer_management'
    };

    const requiredFeature = routeToFeature[route];
    if (!requiredFeature) {
      return false; // Unknown route
    }

    // Check if user has the required feature
    const userFeatures = permissions.features || [];
    return userFeatures.includes(requiredFeature);
  }, [state.sessionData]);

  // Get user permissions
  const getUserPermissions = useCallback((): Record<string, readonly string[]> => {
    if (!state.permissionCache) {
      return {};
    }

    return authPermissionBridge.getUserPermissions(state.permissionCache);
  }, [state.permissionCache]);

  // Get subscription limits
  const getSubscriptionLimits = useCallback((): Record<string, boolean> => {
    if (!state.permissionCache) {
      return {};
    }

    return authPermissionBridge.getSubscriptionLimits(state.permissionCache);
  }, [state.permissionCache]);

  // Refresh permissions
  const refreshPermissions = useCallback(async (): Promise<void> => {
    if (!state.sessionData) {
      return;
    }

    try {
      dispatch({ type: 'SET_PERMISSION_LOADING', payload: true });
      
      const newCache = await authPermissionBridge.refreshPermissions(state.sessionData);
      dispatch({ type: 'SET_PERMISSION_CACHE', payload: newCache });
    } catch (error) {
      console.error('Permission refresh failed:', error);
      dispatch({ type: 'SET_PERMISSION_LOADING', payload: false });
    }
  }, [state.sessionData]);

  // Initialize session on mount
  useEffect(() => {
    let mounted = true;

    const initializeSession = async (): Promise<void> => {
      try {
        // 1. Use initial session data if provided (from server)
        if (initialSessionData && mounted) {
          dispatch({ type: 'SET_SESSION', payload: initialSessionData });
          saveCachedSession(initialSessionData);
          return; // Skip further initialization
        }

        // 2. Check cached session
        const cached = loadCachedSession();
        if (cached && mounted) {
          dispatch({ type: 'SET_SESSION', payload: cached });
        }

        // 3. Verify with Supabase (only if no initial data)
        const { data: { user } } = await supabase.auth.getUser();
        if (user && mounted) {
          await loadUserSession(user as AuthUser);
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
  }, [supabase.auth, loadCachedSession, loadUserSession, clearCachedSession, initialSessionData, saveCachedSession]);

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
    // Enhanced permission methods
    hasPermission,
    hasFeatureAccess,
    getUserPermissions,
    canAccessRoute,
    refreshPermissions,
    getSubscriptionLimits,
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
