// Auth context and provider
export { AuthProvider, useAuth } from './auth-context';

// Convenience hooks
export {
  useAuthState,
  useSession,
  useUserProfile,
  useBusinessContext,
  usePermissions,
  usePermissionCheck,
  useAuthActions,
  useFeatureAccess,
  useBusinessInfo,
  useUserInfo,
} from './hooks';

// Types
export type {
  AuthUser,
  UserProfile,
  BusinessContext,
  PermissionSet,
  SessionData,
  AuthContextState,
  AuthContextActions,
  AuthContext,
} from './types';
