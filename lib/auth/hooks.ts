'use client';

import { useAuth } from './auth-context';
import type { SessionData, UserProfile, BusinessContext, PermissionSet } from './types';

// Hook for authentication state
export function useAuthState() {
  const { isLoading, isAuthenticated, error } = useAuth();
  return { isLoading, isAuthenticated, error };
}

// Hook for session data
export function useSession(): SessionData | null {
  const { sessionData } = useAuth();
  return sessionData;
}

// Hook for user profile
export function useUserProfile(): UserProfile | null {
  const { sessionData } = useAuth();
  return sessionData?.profile || null;
}

// Hook for business context
export function useBusinessContext(): BusinessContext | null {
  const { sessionData } = useAuth();
  return sessionData?.business || null;
}

// Hook for permissions
export function usePermissions(): PermissionSet | null {
  const { sessionData } = useAuth();
  return sessionData?.permissions || null;
}

// Hook for permission checking
export function usePermissionCheck() {
  const { checkPermission } = useAuth();
  return checkPermission;
}

// Hook for auth actions
export function useAuthActions() {
  const { login, logout, refreshSession, clearError } = useAuth();
  return { login, logout, refreshSession, clearError };
}

// Hook for checking specific permissions
export function useFeatureAccess(feature: string) {
  const checkPermission = usePermissionCheck();
  const permissions = usePermissions();
  
  return {
    canRead: checkPermission(feature, 'read'),
    canWrite: checkPermission(feature, 'write'),
    canDelete: checkPermission(feature, 'delete'),
    canAdmin: checkPermission(feature, 'admin'),
    hasFeature: permissions?.features.includes(feature) || false,
    role: permissions?.role || '',
  };
}

// Hook for business info
export function useBusinessInfo() {
  const business = useBusinessContext();
  
  return {
    businessId: business?.id || '',
    businessName: business?.name || '',
    isActive: business?.status === 'active',
    subscriptionTier: business?.subscriptionTier || 'basic',
    isSubscriptionActive: business?.subscriptionStatus === 'active',
  };
}

// Hook for user info
export function useUserInfo() {
  const profile = useUserProfile();
  const { sessionData } = useAuth();
  
  return {
    userId: profile?.id || '',
    userEmail: profile?.email || '',
    fullName: profile?.fullName || '',
    avatarUrl: profile?.avatarUrl,
    phoneNumber: profile?.phoneNumber,
    loginTime: sessionData?.loginTime,
    lastActivity: sessionData?.lastActivity,
  };
}
