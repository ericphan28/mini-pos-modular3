import { createClient } from '@/lib/supabase/client';

export interface BusinessUser {
  readonly id: string;
  readonly email: string;
  readonly role: string;
  readonly business?: {
    readonly id: string;
    readonly name: string;
    readonly business_type: string;
  };
}

class BusinessAuthServiceImpl {
  private static instance: BusinessAuthServiceImpl;

  static getInstance(): BusinessAuthServiceImpl {
    if (!BusinessAuthServiceImpl.instance) {
      BusinessAuthServiceImpl.instance = new BusinessAuthServiceImpl();
    }
    return BusinessAuthServiceImpl.instance;
  }

  async getCurrentUserWithBusiness(): Promise<BusinessUser | null> {
    try {
      const supabase = createClient();
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user) {
        return null;
      }

      // Simple return - TODO: Add business logic when needed
      return {
        id: user.id,
        email: user.email || '',
        role: 'business_owner',
        business: {
          id: 'default',
          name: 'Default Business',
          business_type: 'retail'
        }
      };
    } catch (error: unknown) {
      console.error('Error getting user with business:', error);
      return null;
    }
  }

  async hasPermission(_feature: string, _action?: string): Promise<boolean> { // eslint-disable-line @typescript-eslint/no-unused-vars
    // Simple permission check - always allow for now
    // TODO: Implement proper permission logic when needed
    return true;
  }
}

export const BusinessAuthService = BusinessAuthServiceImpl.getInstance();
