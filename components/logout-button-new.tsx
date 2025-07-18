'use client';

import { POSButton } from '@/components/ui/pos-button';
import { useAuthActions, useAuthState } from '@/lib/auth';
import { useRouter } from 'next/navigation';

export function LogoutButton() {
  const { logout } = useAuthActions();
  const { isLoading } = useAuthState();
  const router = useRouter();

  const handleLogout = async (): Promise<void> => {
    try {
      await logout();
      router.push('/');
    } catch (error) {
      console.error('Logout failed:', error);
      // Even if logout fails, redirect to home
      router.push('/');
    }
  };

  return (
    <POSButton
      variant="ghost"
      size="sm"
      onClick={handleLogout}
      disabled={isLoading}
      className="w-full justify-start"
    >
      {isLoading ? 'Đang đăng xuất...' : 'Đăng xuất'}
    </POSButton>
  );
}
