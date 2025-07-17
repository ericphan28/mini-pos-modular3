export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      pos_mini_modular3_admin_sessions: {
        Row: {
          id: string
          super_admin_id: string
          target_business_id: string
          impersonated_role: string
          session_reason?: string
          session_start: string
          session_end?: string
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: string
          super_admin_id: string
          target_business_id: string
          impersonated_role?: string
          session_reason?: string
          session_start?: string
          session_end?: string
          is_active?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          super_admin_id?: string
          target_business_id?: string
          impersonated_role?: string
          session_reason?: string
          session_start?: string
          session_end?: string
          is_active?: boolean
          created_at?: string
        }
      }
      
      pos_mini_modular3_backup_metadata: {
        Row: {
          id: string
          backup_type: string
          business_id?: string
          file_path: string
          file_name: string
          size: number
          status: string
          compression: string
          encryption: boolean
          retention_until: string
          checksum?: string
          created_at: string
          updated_at: string
          completed_at?: string
          error_message?: string
        }
        Insert: {
          id?: string
          backup_type: string
          business_id?: string
          file_path: string
          file_name: string
          size?: number
          status?: string
          compression?: string
          encryption?: boolean
          retention_until: string
          checksum?: string
          created_at?: string
          updated_at?: string
          completed_at?: string
          error_message?: string
        }
        Update: {
          backup_type?: string
          business_id?: string
          file_path?: string
          file_name?: string
          size?: number
          status?: string
          compression?: string
          encryption?: boolean
          retention_until?: string
          checksum?: string
          created_at?: string
          updated_at?: string
          completed_at?: string
          error_message?: string
        }
      }

      pos_mini_modular3_business_invitations: {
        Row: {
          id: string
          business_id: string
          email: string
          role: string
          invitation_token: string
          status: string
          invited_by: string
          expires_at: string
          accepted_at?: string
          accepted_by?: string
          created_at: string
        }
        Insert: {
          id?: string
          business_id: string
          email: string
          role: string
          invitation_token: string
          status?: string
          invited_by: string
          expires_at: string
          accepted_at?: string
          accepted_by?: string
          created_at?: string
        }
        Update: {
          business_id?: string
          email?: string
          role?: string
          invitation_token?: string
          status?: string
          invited_by?: string
          expires_at?: string
          accepted_at?: string
          accepted_by?: string
          created_at?: string
        }
      }

      pos_mini_modular3_business_type_category_templates: {
        Row: {
          id: string
          business_type: string
          template_name: string
          description?: string
          category_name: string
          category_description?: string
          category_icon?: string
          category_color_hex: string
          parent_category_name?: string
          sort_order: number
          is_default: boolean
          is_required: boolean
          allows_inventory: boolean
          allows_variants: boolean
          requires_description: boolean
          is_active: boolean
          version: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          business_type: string
          template_name: string
          description?: string
          category_name: string
          category_description?: string
          category_icon?: string
          category_color_hex: string
          parent_category_name?: string
          sort_order?: number
          is_default?: boolean
          is_required?: boolean
          allows_inventory?: boolean
          allows_variants?: boolean
          requires_description?: boolean
          is_active?: boolean
          version?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          business_type?: string
          template_name?: string
          description?: string
          category_name?: string
          category_description?: string
          category_icon?: string
          category_color_hex?: string
          parent_category_name?: string
          sort_order?: number
          is_default?: boolean
          is_required?: boolean
          allows_inventory?: boolean
          allows_variants?: boolean
          requires_description?: boolean
          is_active?: boolean
          version?: number
          created_at?: string
          updated_at?: string
        }
      }

      pos_mini_modular3_business_types: {
        Row: {
          id: string
          value: string
          label: string
          description?: string
          icon?: string
          category: string
          is_active: boolean
          sort_order: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          value: string
          label: string
          description?: string
          icon?: string
          category: string
          is_active?: boolean
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          value?: string
          label?: string
          description?: string
          icon?: string
          category?: string
          is_active?: boolean
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
      }

      pos_mini_modular3_businesses: {
        Row: {
          id: string
          name: string
          code: string
          business_type: string
          phone?: string
          email?: string
          address?: string
          tax_code?: string
          legal_representative?: string
          logo_url?: string
          status: string
          settings: Json
          subscription_tier: string
          subscription_status: string
          subscription_starts_at: string
          subscription_ends_at?: string
          trial_ends_at?: string
          max_users: number
          max_products: number
          created_at: string
          updated_at: string
          features_enabled: Json
          usage_stats: Json
          last_billing_date?: string
          next_billing_date?: string
        }
        Insert: {
          id?: string
          name: string
          code: string
          business_type?: string
          phone?: string
          email?: string
          address?: string
          tax_code?: string
          legal_representative?: string
          logo_url?: string
          status?: string
          settings?: Json
          subscription_tier?: string
          subscription_status?: string
          subscription_starts_at?: string
          subscription_ends_at?: string
          trial_ends_at?: string
          max_users?: number
          max_products?: number
          created_at?: string
          updated_at?: string
          features_enabled?: Json
          usage_stats?: Json
          last_billing_date?: string
          next_billing_date?: string
        }
        Update: {
          name?: string
          code?: string
          business_type?: string
          phone?: string
          email?: string
          address?: string
          tax_code?: string
          legal_representative?: string
          logo_url?: string
          status?: string
          settings?: Json
          subscription_tier?: string
          subscription_status?: string
          subscription_starts_at?: string
          subscription_ends_at?: string
          trial_ends_at?: string
          max_users?: number
          max_products?: number
          created_at?: string
          updated_at?: string
          features_enabled?: Json
          usage_stats?: Json
          last_billing_date?: string
          next_billing_date?: string
        }
      }

      pos_mini_modular3_enhanced_user_sessions: {
        Row: {
          id: string
          user_id: string
          session_token: string
          device_info: Json
          ip_address?: string
          user_agent?: string
          fingerprint?: string
          location_data: Json
          security_flags: Json
          risk_score: number
          expires_at: string
          created_at: string
          last_activity_at: string
        }
        Insert: {
          id?: string
          user_id: string
          session_token: string
          device_info?: Json
          ip_address?: string
          user_agent?: string
          fingerprint?: string
          location_data?: Json
          security_flags?: Json
          risk_score?: number
          expires_at: string
          created_at?: string
          last_activity_at?: string
        }
        Update: {
          user_id?: string
          session_token?: string
          device_info?: Json
          ip_address?: string
          user_agent?: string
          fingerprint?: string
          location_data?: Json
          security_flags?: Json
          risk_score?: number
          expires_at?: string
          created_at?: string
          last_activity_at?: string
        }
      }

      pos_mini_modular3_failed_login_attempts: {
        Row: {
          id: string
          identifier: string
          identifier_type: string
          attempt_count: number
          last_attempt_at: string
          is_locked: boolean
          lock_expires_at?: string
          created_at: string
        }
        Insert: {
          id?: string
          identifier: string
          identifier_type: string
          attempt_count?: number
          last_attempt_at?: string
          is_locked?: boolean
          lock_expires_at?: string
          created_at?: string
        }
        Update: {
          identifier?: string
          identifier_type?: string
          attempt_count?: number
          last_attempt_at?: string
          is_locked?: boolean
          lock_expires_at?: string
          created_at?: string
        }
      }

      pos_mini_modular3_product_categories: {
        Row: {
          id: string
          business_id: string
          parent_id?: string
          name: string
          description?: string
          slug: string
          icon?: string
          color_hex?: string
          image_url?: string
          sort_order: number
          is_active: boolean
          is_featured: boolean
          meta_title?: string
          meta_description?: string
          created_at: string
          updated_at: string
          created_by?: string
          updated_by?: string
        }
        Insert: {
          id?: string
          business_id: string
          parent_id?: string
          name: string
          description?: string
          slug?: string
          icon?: string
          color_hex?: string
          image_url?: string
          sort_order?: number
          is_active?: boolean
          is_featured?: boolean
          meta_title?: string
          meta_description?: string
          created_at?: string
          updated_at?: string
          created_by?: string
          updated_by?: string
        }
        Update: {
          business_id?: string
          parent_id?: string
          name?: string
          description?: string
          slug?: string
          icon?: string
          color_hex?: string
          image_url?: string
          sort_order?: number
          is_active?: boolean
          is_featured?: boolean
          meta_title?: string
          meta_description?: string
          created_at?: string
          updated_at?: string
          created_by?: string
          updated_by?: string
        }
      }

      pos_mini_modular3_product_inventory: {
        Row: {
          id: string
          business_id: string
          product_id: string
          variant_id?: string
          transaction_type: string
          quantity_change: number
          quantity_after: number
          reference_type?: string
          reference_id?: string
          notes?: string
          unit_cost?: number
          created_by?: string
          created_at: string
        }
        Insert: {
          id?: string
          business_id: string
          product_id: string
          variant_id?: string
          transaction_type: string
          quantity_change: number
          quantity_after: number
          reference_type?: string
          reference_id?: string
          notes?: string
          unit_cost?: number
          created_by?: string
          created_at?: string
        }
        Update: {
          business_id?: string
          product_id?: string
          variant_id?: string
          transaction_type?: string
          quantity_change?: number
          quantity_after?: number
          reference_type?: string
          reference_id?: string
          notes?: string
          unit_cost?: number
          created_by?: string
          created_at?: string
        }
      }

      pos_mini_modular3_products: {
        Row: {
          id: string
          business_id: string
          category_id?: string
          name: string
          description?: string
          short_description?: string
          sku?: string
          barcode?: string
          price: number
          cost_price: number
          compare_at_price?: number
          unit_price: number
          sale_price?: number
          current_stock: number
          min_stock_level: number
          track_stock: boolean
          is_active: boolean
          primary_image?: string
          specifications: Json
          product_type: string
          has_variants: boolean
          variant_options: Json
          track_inventory: boolean
          inventory_policy: string
          total_inventory: number
          available_inventory: number
          weight?: number
          dimensions?: Json
          images: Json
          featured_image?: string
          slug?: string
          tags: Json
          meta_title?: string
          meta_description?: string
          status: string
          is_featured: boolean
          is_digital: boolean
          requires_shipping: boolean
          is_taxable: boolean
          tax_rate: number
          created_at: string
          updated_at: string
          published_at?: string
          created_by?: string
          updated_by?: string
        }
        Insert: {
          id?: string
          business_id: string
          category_id?: string
          name: string
          description?: string
          short_description?: string
          sku?: string
          barcode?: string
          price?: number
          cost_price?: number
          compare_at_price?: number
          unit_price?: number
          sale_price?: number
          current_stock?: number
          min_stock_level?: number
          track_stock?: boolean
          is_active?: boolean
          primary_image?: string
          specifications?: Json
          product_type?: string
          has_variants?: boolean
          variant_options?: Json
          track_inventory?: boolean
          inventory_policy?: string
          total_inventory?: number
          available_inventory?: number
          weight?: number
          dimensions?: Json
          images?: Json
          featured_image?: string
          slug?: string
          tags?: Json
          meta_title?: string
          meta_description?: string
          status?: string
          is_featured?: boolean
          is_digital?: boolean
          requires_shipping?: boolean
          is_taxable?: boolean
          tax_rate?: number
          created_at?: string
          updated_at?: string
          published_at?: string
          created_by?: string
          updated_by?: string
        }
        Update: {
          business_id?: string
          category_id?: string
          name?: string
          description?: string
          short_description?: string
          sku?: string
          barcode?: string
          price?: number
          cost_price?: number
          compare_at_price?: number
          unit_price?: number
          sale_price?: number
          current_stock?: number
          min_stock_level?: number
          track_stock?: boolean
          is_active?: boolean
          primary_image?: string
          specifications?: Json
          product_type?: string
          has_variants?: boolean
          variant_options?: Json
          track_inventory?: boolean
          inventory_policy?: string
          total_inventory?: number
          available_inventory?: number
          weight?: number
          dimensions?: Json
          images?: Json
          featured_image?: string
          slug?: string
          tags?: Json
          meta_title?: string
          meta_description?: string
          status?: string
          is_featured?: boolean
          is_digital?: boolean
          requires_shipping?: boolean
          is_taxable?: boolean
          tax_rate?: number
          created_at?: string
          updated_at?: string
          published_at?: string
          created_by?: string
          updated_by?: string
        }
      }

      pos_mini_modular3_security_audit_logs: {
        Row: {
          id: string
          event_type: string
          user_id?: string
          session_token?: string
          ip_address?: string
          user_agent?: string
          event_data: Json
          severity: string
          message?: string
          created_at: string
        }
        Insert: {
          id?: string
          event_type: string
          user_id?: string
          session_token?: string
          ip_address?: string
          user_agent?: string
          event_data?: Json
          severity?: string
          message?: string
          created_at?: string
        }
        Update: {
          event_type?: string
          user_id?: string
          session_token?: string
          ip_address?: string
          user_agent?: string
          event_data?: Json
          severity?: string
          message?: string
          created_at?: string
        }
      }

      pos_mini_modular3_subscription_plans: {
        Row: {
          id: string
          tier: string
          name: string
          description?: string
          price_monthly: number
          price_annual: number
          max_users: number
          max_products: number
          max_warehouses?: number
          max_branches?: number
          features: Json
          is_active: boolean
          trial_days: number
          sort_order: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tier: string
          name: string
          description?: string
          price_monthly?: number
          price_annual?: number
          max_users?: number
          max_products?: number
          max_warehouses?: number
          max_branches?: number
          features?: Json
          is_active?: boolean
          trial_days?: number
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          tier?: string
          name?: string
          description?: string
          price_monthly?: number
          price_annual?: number
          max_users?: number
          max_products?: number
          max_warehouses?: number
          max_branches?: number
          features?: Json
          is_active?: boolean
          trial_days?: number
          sort_order?: number
          created_at?: string
          updated_at?: string
        }
      }

      pos_mini_modular3_user_profiles: {
        Row: {
          id: string
          business_id?: string
          full_name: string
          phone?: string
          email?: string
          avatar_url?: string
          role: string
          status: string
          permissions: Json
          login_method: string
          last_login_at?: string
          employee_id?: string
          hire_date?: string
          notes?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          business_id?: string
          full_name: string
          phone?: string
          email?: string
          avatar_url?: string
          role?: string
          status?: string
          permissions?: Json
          login_method?: string
          last_login_at?: string
          employee_id?: string
          hire_date?: string
          notes?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          full_name?: string
          phone?: string
          email?: string
          avatar_url?: string
          role?: string
          status?: string
          permissions?: Json
          login_method?: string
          last_login_at?: string
          employee_id?: string
          hire_date?: string
          notes?: string
          created_at?: string
          updated_at?: string
        }
      }
    }
    Functions: {
      pos_mini_modular3_accept_invitation: {
        Args: {
          p_invitation_token: string
          p_full_name: string
        }
        Returns: Json
      }
      
      pos_mini_modular3_add_inventory_transaction: {
        Args: {
          p_business_id: string
          p_product_id: string
          p_quantity_change: number
          p_variant_id?: string
          p_transaction_type?: string
          p_reference_type?: string
          p_reference_id?: string
          p_notes?: string
          p_unit_cost?: number
          p_created_by?: string
        }
        Returns: Json
      }

      pos_mini_modular3_auto_setup_categories: {
        Args: {
          p_business_id: string
          p_business_type?: string
        }
        Returns: Json
      }

      pos_mini_modular3_bulk_update_inventory: {
        Args: {
          p_business_id: string
          p_inventory_updates: Json
          p_updated_by?: string
        }
        Returns: Json
      }

      pos_mini_modular3_check_contact_exists: {
        Args: {
          p_contact_method: string
          p_contact_value: string
        }
        Returns: boolean
      }

      pos_mini_modular3_check_feature_access: {
        Args: {
          p_business_id: string
          p_feature_name: string
        }
        Returns: boolean
      }

      pos_mini_modular3_check_permission: {
        Args: {
          p_action: string
        }
        Returns: boolean
      }

      pos_mini_modular3_check_product_limit: {
        Args: {
          p_business_id: string
        }
        Returns: Json
      }

      pos_mini_modular3_check_usage_limit: {
        Args: {
          p_business_id: string
          p_limit_type: string
          p_current_count: number
        }
        Returns: Json
      }

      pos_mini_modular3_check_user_permission: {
        Args: {
          p_user_id: string
          p_feature_name: string
          p_action?: string
        }
        Returns: Json
      }

      pos_mini_modular3_create_business_owner: {
        Args: {
          p_user_id: string
          p_business_name: string
          p_full_name: string
          p_email?: string
        }
        Returns: Json
      }

      pos_mini_modular3_create_category: {
        Args: {
          p_name: string
          p_description?: string
          p_parent_id?: string
          p_color_code?: string
          p_icon_name?: string
          p_image_url?: string
          p_is_featured?: boolean
          p_display_order?: number
        }
        Returns: Json
      }

      pos_mini_modular3_create_complete_business_owner: {
        Args: {
          p_user_id: string
          p_email: string
          p_full_name: string
          p_business_name: string
          p_business_type?: string
          p_phone?: string
          p_address?: string
          p_tax_code?: string
        }
        Returns: Json
      }

      pos_mini_modular3_create_product: {
        Args: {
          p_name: string
          p_description?: string
          p_category_id?: string
          p_sku?: string
          p_barcode?: string
          p_unit_price?: number
          p_cost_price?: number
          p_current_stock?: number
          p_min_stock_level?: number
          p_unit_of_measure?: string
          p_track_stock?: boolean
          p_is_active?: boolean
          p_is_featured?: boolean
          p_tags?: string[]
          p_primary_image?: string
        }
        Returns: Json
      }

      pos_mini_modular3_create_product_complete: {
        Args: {
          p_product_data: Json
        }
        Returns: Json
      }

      pos_mini_modular3_create_staff_member: {
        Args: {
          p_business_id: string
          p_full_name: string
          p_phone: string
          p_password: string
          p_role?: string
          p_employee_id?: string
          p_notes?: string
        }
        Returns: Json
      }
    }
  }
}

// Type aliases for easier usage
export type BusinessType = Database['public']['Tables']['pos_mini_modular3_business_types']['Row']
export type Business = Database['public']['Tables']['pos_mini_modular3_businesses']['Row']
export type UserProfile = Database['public']['Tables']['pos_mini_modular3_user_profiles']['Row']
export type Product = Database['public']['Tables']['pos_mini_modular3_products']['Row']
export type ProductCategory = Database['public']['Tables']['pos_mini_modular3_product_categories']['Row']
export type BusinessInvitation = Database['public']['Tables']['pos_mini_modular3_business_invitations']['Row']
export type SubscriptionPlan = Database['public']['Tables']['pos_mini_modular3_subscription_plans']['Row']
export type AdminSession = Database['public']['Tables']['pos_mini_modular3_admin_sessions']['Row']
export type EnhancedUserSession = Database['public']['Tables']['pos_mini_modular3_enhanced_user_sessions']['Row']
export type FailedLoginAttempt = Database['public']['Tables']['pos_mini_modular3_failed_login_attempts']['Row']
export type SecurityAuditLog = Database['public']['Tables']['pos_mini_modular3_security_audit_logs']['Row']
export type ProductInventory = Database['public']['Tables']['pos_mini_modular3_product_inventory']['Row']
export type BackupMetadata = Database['public']['Tables']['pos_mini_modular3_backup_metadata']['Row']
export type BusinessTypeCategoryTemplate = Database['public']['Tables']['pos_mini_modular3_business_type_category_templates']['Row']

// Insert types
export type InsertBusinessType = Database['public']['Tables']['pos_mini_modular3_business_types']['Insert']
export type InsertBusiness = Database['public']['Tables']['pos_mini_modular3_businesses']['Insert']
export type InsertUserProfile = Database['public']['Tables']['pos_mini_modular3_user_profiles']['Insert']
export type InsertProduct = Database['public']['Tables']['pos_mini_modular3_products']['Insert']
export type InsertProductCategory = Database['public']['Tables']['pos_mini_modular3_product_categories']['Insert']
export type InsertBusinessInvitation = Database['public']['Tables']['pos_mini_modular3_business_invitations']['Insert']

// Update types
export type UpdateBusinessType = Database['public']['Tables']['pos_mini_modular3_business_types']['Update']
export type UpdateBusiness = Database['public']['Tables']['pos_mini_modular3_businesses']['Update']
export type UpdateUserProfile = Database['public']['Tables']['pos_mini_modular3_user_profiles']['Update']
export type UpdateProduct = Database['public']['Tables']['pos_mini_modular3_products']['Update']
export type UpdateProductCategory = Database['public']['Tables']['pos_mini_modular3_product_categories']['Update']

// =============================================
// ENUM TYPES (Business Logic)
// =============================================
export type UserRole = 
  | 'super_admin'      // System super admin
  | 'household_owner'  // Business owner
  | 'manager'          // Business manager
  | 'seller'           // Sales staff
  | 'accountant';      // Accounting staff

export type UserStatus = 'active' | 'inactive' | 'suspended';
export type ContactMethod = 'email' | 'phone';

export type BusinessTypeEnum = 
  | 'retail'     // Bán lẻ
  | 'restaurant' // Nhà hàng
  | 'service'    // Dịch vụ  
  | 'wholesale'; // Bán sỉ

export type BusinessStatusEnum = 
  | 'trial'     // Đang dùng thử
  | 'active'    // Hoạt động
  | 'suspended' // Tạm ngưng
  | 'closed';   // Đã đóng

export type SubscriptionTier = 'free' | 'basic' | 'premium' | 'enterprise';
export type SubscriptionStatus = 'trial' | 'active' | 'past_due' | 'cancelled' | 'suspended' | 'expired';

// =============================================
// SERVICE RESPONSE PATTERNS
// =============================================
export interface ServiceResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  appError?: AppError;
}

export interface DatabaseError {
  code: string;
  message: string;
  details?: string;
  hint?: string;
}

export interface AppError {
  code: string;
  userMessage: string;
  technicalMessage: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

// =============================================
// DATABASE FUNCTIONS (RPC)
// =============================================
export interface DatabaseFunctions {
  'pos_mini_modular3_super_admin_check_permission': {
    Args: Record<string, never>;
    Returns: boolean;
  };
  'pos_mini_modular3_super_admin_get_business_registration_stats': {
    Args: Record<string, never>;
    Returns: {
      total_businesses: number;
      active_businesses: number;
      trial_businesses: number;
      total_users: number;
      total_owners: number;
      total_staff: number;
    };
  };
  'pos_mini_modular3_super_admin_create_complete_business': {
    Args: {
      p_business_name: string;
      p_contact_method: string;
      p_contact_value: string;
      p_owner_full_name: string;
      p_business_type?: string;
      p_subscription_tier?: string;
      p_set_password?: string | null;
      p_is_active?: boolean;
    };
    Returns: {
      success: boolean;
      business_id?: string;
      business_name?: string;
      business_code?: string;
      business_status?: string;
      subscription_tier?: string;
      user_created?: boolean;
      user_id?: string;
      message?: string;
      error?: string;
    };
  };
  'generate_business_code': {
    Args: Record<string, never>;
    Returns: string;
  };
  'pos_mini_modular3_create_business_with_auth_simple': {
    Args: {
      p_business_name: string;
      p_contact_method: ContactMethod;
      p_contact_value: string;
      p_owner_name: string;
      p_business_type: BusinessTypeEnum;
      p_subscription_tier: SubscriptionTier;
      p_business_status: BusinessStatusEnum;
      p_subscription_status: SubscriptionStatus;
      p_password?: string | null;
      p_created_by_admin?: string | null;
    };
    Returns: {
      success: boolean;
      business_id?: string;
      user_id?: string;
      business_name?: string;
      business_code?: string;
      contact_method?: ContactMethod;
      contact_value?: string;
      auth_email?: string;
      password_set?: boolean;
      login_ready?: boolean;
      message?: string;
      error?: string;
    };
  };
  'get_default_business_settings': {
    Args: {
      p_business_type: BusinessTypeEnum;
      p_subscription_tier: SubscriptionTier;
    };
    Returns: {
      trial_days: number;
      max_users: number;
      max_products: number;
      features: string[];
      currency: string;
      timezone: string;
      language: string;
    };
  };
}

export type DatabaseFunctionName = keyof DatabaseFunctions;

export type DatabaseFunctionParams<T extends DatabaseFunctionName> = 
  DatabaseFunctions[T]['Args'];

export type DatabaseFunctionResult<T extends DatabaseFunctionName> = 
  DatabaseFunctions[T]['Returns'];
