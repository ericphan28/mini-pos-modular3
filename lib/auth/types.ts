import type { User } from '@supabase/supabase-js';

// Core authentication state
export interface AuthUser extends User {
  id: string;
  email: string;
}

// User profile data
export interface UserProfile {
  readonly id: string;
  readonly fullName: string;
  readonly email: string;
  readonly avatarUrl?: string;
  readonly phoneNumber?: string;
  readonly timezone?: string;
}

// Business context
export interface BusinessContext {
  readonly id: string;
  readonly name: string;
  readonly status: 'active' | 'inactive' | 'suspended';
  readonly subscriptionTier: 'basic' | 'premium' | 'enterprise';
  readonly subscriptionStatus: 'active' | 'expired' | 'canceled';
}

// Permission set
export interface PermissionSet {
  readonly role: string;
  readonly permissions: readonly string[];
  readonly features: readonly string[];
}

// Complete session data
export interface SessionData {
  readonly user: AuthUser;
  readonly profile: UserProfile;
  readonly business: BusinessContext;
  readonly permissions: PermissionSet;
  readonly loginTime: string;
  readonly lastActivity: string;
}

// Auth context state
export interface AuthContextState {
  readonly isLoading: boolean;
  readonly isAuthenticated: boolean;
  readonly sessionData: SessionData | null;
  readonly error: string | null;
}

// Auth context actions
export interface AuthContextActions {
  readonly login: (email: string, password: string) => Promise<void>;
  readonly logout: () => Promise<void>;
  readonly checkPermission: (feature: string, action?: string) => boolean;
  readonly refreshSession: () => Promise<void>;
  readonly clearError: () => void;
}

// Complete auth context
export interface AuthContext extends AuthContextState, AuthContextActions {}
