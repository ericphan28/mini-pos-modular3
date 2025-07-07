'use client';

interface PermissionGateProps {
  readonly feature: string;
  readonly action?: string;
  readonly children: React.ReactNode;
  readonly fallback?: React.ReactNode;
}

export default function PermissionGate({
  feature: _feature, // eslint-disable-line @typescript-eslint/no-unused-vars
  action: _action = 'read', // eslint-disable-line @typescript-eslint/no-unused-vars
  children,
  fallback
}: PermissionGateProps) {
  // Simple permission check - always allow for now
  // TODO: Implement proper permission logic when needed
  const hasAccess = true;

  if (!hasAccess) {
    return fallback ? <>{fallback}</> : null;
  }

  return <>{children}</>;
}
