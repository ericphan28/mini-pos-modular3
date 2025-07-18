'use client';

// Simple utility to pass server data to client
export function getServerProfileData(): unknown {
  if (typeof window === 'undefined') return null;
  
  try {
    return (window as { __SERVER_PROFILE_DATA__?: unknown }).__SERVER_PROFILE_DATA__ || null;
  } catch {
    return null;
  }
}

export function setServerProfileData(data: unknown): void {
  if (typeof window === 'undefined') return;
  
  try {
    (window as { __SERVER_PROFILE_DATA__?: unknown }).__SERVER_PROFILE_DATA__ = data;
  } catch {
    // Ignore errors
  }
}
