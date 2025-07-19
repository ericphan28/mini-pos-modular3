import { usePermissions } from '@/hooks/use-permissions';
import { ReactNode } from 'react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Shield, AlertTriangle } from 'lucide-react';

interface PermissionGateProps {
  readonly permission: string;
  readonly fallback?: ReactNode;
  readonly children: ReactNode;
  readonly showFallback?: boolean;
  readonly className?: string;
}

export default function PermissionGate({ 
  permission, 
  fallback = null, 
  children,
  showFallback = false,
  className = ""
}: PermissionGateProps) {
  const { hasPermission, userRole } = usePermissions();
  
  if (!hasPermission(permission)) {
    if (showFallback) {
      return (
        <Alert className={`border-orange-200 bg-orange-50 ${className}`}>
          <AlertTriangle className="h-4 w-4 text-orange-600" />
          <AlertDescription className="text-orange-800">
            Bạn không có quyền truy cập tính năng này. 
            <br />
            <span className="text-xs text-orange-600">
              Role hiện tại: {userRole} | Cần quyền: {permission}
            </span>
          </AlertDescription>
        </Alert>
      );
    }
    
    return fallback;
  }
  
  return <>{children}</>;
}

// Higher-order component for permission-based page protection
interface PermissionPageProps {
  readonly requiredPermission: string;
  readonly children: ReactNode;
  readonly loadingComponent?: ReactNode;
  readonly accessDeniedComponent?: ReactNode;
}

export function PermissionPage({ 
  requiredPermission, 
  children,
  loadingComponent = <div>Đang kiểm tra quyền truy cập...</div>,
  accessDeniedComponent
}: PermissionPageProps) {
  const { hasPermission, userRole } = usePermissions();
  
  // Show loading while checking permissions
  if (!userRole) {
    return <>{loadingComponent}</>;
  }
  
  // Check permission
  if (!hasPermission(requiredPermission)) {
    if (accessDeniedComponent) {
      return <>{accessDeniedComponent}</>;
    }
    
    return (
      <div className="flex items-center justify-center min-h-[400px] p-6">
        <Alert className="max-w-md border-red-200 bg-red-50">
          <Shield className="h-4 w-4 text-red-600" />
          <AlertDescription className="text-red-800">
            <div className="space-y-2">
              <p className="font-medium">Không có quyền truy cập</p>
              <p className="text-sm">
                Bạn cần quyền <code className="bg-red-100 px-1 rounded">{requiredPermission}</code> để truy cập trang này.
              </p>
              <p className="text-xs text-red-600">
                Role hiện tại: {userRole}
              </p>
            </div>
          </AlertDescription>
        </Alert>
      </div>
    );
  }
  
  return <>{children}</>;
}

// Role-based navigation component
interface RoleBasedNavProps {
  readonly children: ReactNode;
  readonly allowedRoles: readonly string[];
  readonly fallback?: ReactNode;
}

export function RoleBasedNav({ 
  children, 
  allowedRoles, 
  fallback = null 
}: RoleBasedNavProps) {
  const { userRole } = usePermissions();
  
  if (!allowedRoles.includes(userRole)) {
    return fallback;
  }
  
  return <>{children}</>;
}

// Emergency rollback component (for super admins)
interface EmergencyRollbackProps {
  readonly userId: string;
  readonly userName: string;
  readonly onSuccess?: () => void;
  readonly onError?: (error: string) => void;
}

export function EmergencyRollback({ 
  userId, 
  userName, 
  onSuccess, 
  onError 
}: EmergencyRollbackProps) {
  const { emergencyRollback, isSuperAdmin } = usePermissions();
  
  if (!isSuperAdmin) return null;
  
  const handleRollback = async (): Promise<void> => {
    try {
      const reason = prompt(
        `Xác nhận rollback quyền cho ${userName}?\nNhập lý do:`
      );
      
      if (!reason) return;
      
      const success = await emergencyRollback(userId, reason);
      
      if (success) {
        onSuccess?.();
      } else {
        onError?.('Rollback thất bại');
      }
    } catch (error: unknown) {
      onError?.(error instanceof Error ? error.message : 'Lỗi không xác định');
    }
  };
  
  return (
    <button
      onClick={handleRollback}
      className="px-2 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors"
      title="Emergency Permission Rollback (Super Admin Only)"
    >
      🚨 Rollback
    </button>
  );
}
