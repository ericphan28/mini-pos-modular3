'use client';

import { useState } from 'react';

interface FeatureAccess {
  readonly hasAccess: boolean;
  readonly loading: boolean;
}

export function useFeatureAccess(feature: string, action?: string): FeatureAccess {
  // Simple hook - always allow access for now
  // TODO: Implement proper feature access logic when needed
  const [access] = useState<FeatureAccess>({
    hasAccess: true,
    loading: false
  });

  return access;
}
