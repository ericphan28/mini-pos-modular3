'use client'

import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { createClient } from "@/lib/supabase/client";
import { Database, Download, Loader2, Shield } from "lucide-react";
import { useState } from "react";

// Type for Supabase client
type SupabaseClient = ReturnType<typeof createClient>;

interface DatabaseBackupClientProps {
  type: 'full' | 'schema';
}

export function DatabaseBackupClient({ type }: DatabaseBackupClientProps) {
  const [isBackingUp, setIsBackingUp] = useState(false);
  const { toast } = useToast();

  const handleBackup = async () => {
    setIsBackingUp(true);
    
    try {
      const supabase = createClient();
      
      // Get current timestamp for filename
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
      const filename = `pos-mini-${type}-backup-${timestamp}.sql`;
      
      let backupContent = '';
      
      if (type === 'full') {
        // Full backup - get both schema and data
        backupContent = await generateFullBackup(supabase);
      } else {
        // Schema only backup
        backupContent = await generateSchemaBackup(supabase);
      }
      
      // Create and download file
      const blob = new Blob([backupContent], { type: 'text/sql' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
      
      toast({
        title: "Backup thành công!",
        description: `File ${filename} đã được tải xuống`,
      });
      
    } catch {
      toast({
        title: "Lỗi backup",
        description: "Không thể tạo backup. Vui lòng thử lại.",
        variant: "destructive",
      });
    } finally {
      setIsBackingUp(false);
    }
  };
  
  const generateFullBackup = async (supabase: SupabaseClient): Promise<string> => {
    let sql = `-- ==================================================================================\n`;
    sql += `-- POS MINI MODULAR 3 - FULL DATABASE BACKUP\n`;
    sql += `-- Generated: ${new Date().toISOString()}\n`;
    sql += `-- Type: Full backup (Schema + Data)\n`;
    sql += `-- ==================================================================================\n\n`;
    
    // Add schema first
    sql += await generateSchemaBackup(supabase, false);
    
    sql += `\n-- ==================================================================================\n`;
    sql += `-- DATA EXPORT\n`;
    sql += `-- ==================================================================================\n\n`;
    
    // Export subscription plans data
    const { data: plans } = await supabase
      .from('pos_mini_modular3_subscription_plans')
      .select('*');
    
    if (plans && plans.length > 0) {
      sql += `-- Subscription Plans Data\n`;
      sql += `INSERT INTO pos_mini_modular3_subscription_plans (id, tier, name, price_monthly, max_users, features, created_at, updated_at) VALUES\n`;
      
      const planValues = plans.map(plan => 
        `('${plan.id}', '${plan.tier}', '${plan.name}', ${plan.price_monthly || 0}, ${plan.max_users}, '${JSON.stringify(plan.features || {})}', '${plan.created_at}', '${plan.updated_at}')`
      ).join(',\n');
      
      sql += planValues + '\nON CONFLICT (id) DO UPDATE SET\n';
      sql += `  tier = EXCLUDED.tier,\n`;
      sql += `  name = EXCLUDED.name,\n`;
      sql += `  price_monthly = EXCLUDED.price_monthly,\n`;
      sql += `  max_users = EXCLUDED.max_users,\n`;
      sql += `  features = EXCLUDED.features,\n`;
      sql += `  updated_at = EXCLUDED.updated_at;\n\n`;
    }
    
    // Export businesses data
    const { data: businesses } = await supabase
      .from('pos_mini_modular3_businesses')
      .select('*');
    
    if (businesses && businesses.length > 0) {
      sql += `-- Businesses Data\n`;
      sql += `INSERT INTO pos_mini_modular3_businesses (id, name, contact_person, contact_phone, contact_email, address, business_type, subscription_tier, status, business_code, max_users, created_at, updated_at) VALUES\n`;
      
      const businessValues = businesses.map(business => 
        `('${business.id}', '${business.name?.replace(/'/g, "''")}', '${business.contact_person?.replace(/'/g, "''")}', '${business.contact_phone}', '${business.contact_email}', '${business.address?.replace(/'/g, "''")}', '${business.business_type}', '${business.subscription_tier}', '${business.status}', '${business.business_code}', ${business.max_users}, '${business.created_at}', '${business.updated_at}')`
      ).join(',\n');
      
      sql += businessValues + '\nON CONFLICT (id) DO UPDATE SET\n';
      sql += `  name = EXCLUDED.name,\n`;
      sql += `  contact_person = EXCLUDED.contact_person,\n`;
      sql += `  contact_phone = EXCLUDED.contact_phone,\n`;
      sql += `  contact_email = EXCLUDED.contact_email,\n`;
      sql += `  address = EXCLUDED.address,\n`;
      sql += `  business_type = EXCLUDED.business_type,\n`;
      sql += `  subscription_tier = EXCLUDED.subscription_tier,\n`;
      sql += `  status = EXCLUDED.status,\n`;
      sql += `  max_users = EXCLUDED.max_users,\n`;
      sql += `  updated_at = EXCLUDED.updated_at;\n\n`;
    }
    
    // Export user profiles data
    const { data: users } = await supabase
      .from('pos_mini_modular3_user_profiles')
      .select('*');
    
    if (users && users.length > 0) {
      sql += `-- User Profiles Data\n`;
      sql += `INSERT INTO pos_mini_modular3_user_profiles (id, business_id, full_name, email, phone, role, status, employee_id, hire_date, last_login_at, notes, login_method, created_at, updated_at) VALUES\n`;
      
      const userValues = users.map(user => 
        `('${user.id}', ${user.business_id ? `'${user.business_id}'` : 'NULL'}, '${user.full_name?.replace(/'/g, "''")}', '${user.email}', '${user.phone}', '${user.role}', '${user.status}', ${user.employee_id ? `'${user.employee_id}'` : 'NULL'}, ${user.hire_date ? `'${user.hire_date}'` : 'NULL'}, ${user.last_login_at ? `'${user.last_login_at}'` : 'NULL'}, ${user.notes ? `'${user.notes.replace(/'/g, "''")}'` : 'NULL'}, '${user.login_method || 'email'}', '${user.created_at}', '${user.updated_at}')`
      ).join(',\n');
      
      sql += userValues + '\nON CONFLICT (id) DO UPDATE SET\n';
      sql += `  business_id = EXCLUDED.business_id,\n`;
      sql += `  full_name = EXCLUDED.full_name,\n`;
      sql += `  email = EXCLUDED.email,\n`;
      sql += `  phone = EXCLUDED.phone,\n`;
      sql += `  role = EXCLUDED.role,\n`;
      sql += `  status = EXCLUDED.status,\n`;
      sql += `  employee_id = EXCLUDED.employee_id,\n`;
      sql += `  hire_date = EXCLUDED.hire_date,\n`;
      sql += `  last_login_at = EXCLUDED.last_login_at,\n`;
      sql += `  notes = EXCLUDED.notes,\n`;
      sql += `  login_method = EXCLUDED.login_method,\n`;
      sql += `  updated_at = EXCLUDED.updated_at;\n\n`;
    }
    
    sql += `-- ==================================================================================\n`;
    sql += `-- BACKUP COMPLETED\n`;
    sql += `-- ==================================================================================\n`;
    
    return sql;
  };
  
  const generateSchemaBackup = async (supabase: SupabaseClient, includeHeader: boolean = true): Promise<string> => {
    let sql = '';
    
    if (includeHeader) {
      sql += `-- ==================================================================================\n`;
      sql += `-- POS MINI MODULAR 3 - SCHEMA BACKUP\n`;
      sql += `-- Generated: ${new Date().toISOString()}\n`;
      sql += `-- Type: Schema only (Structure + Functions)\n`;
      sql += `-- ==================================================================================\n\n`;
    }
    
    // Get functions
    try {
      const { data: functions } = await supabase.rpc('pg_get_functiondef', {
        function_oid: '(SELECT oid FROM pg_proc WHERE proname LIKE \'pos_mini_modular3_%\')'
      });
      
      if (functions) {
        sql += `-- Functions\n`;
        sql += functions;
        sql += `\n\n`;
      }
    } catch {
      // Fallback to basic schema
      sql += `-- Schema structure (manual export)\n`;
      sql += `-- Note: Functions need to be exported manually from Supabase Dashboard\n\n`;
    }
    
    // Add basic table structures (simplified)
    sql += `-- Tables Structure\n`;
    sql += `CREATE TABLE IF NOT EXISTS pos_mini_modular3_subscription_plans (\n`;
    sql += `  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,\n`;
    sql += `  tier text UNIQUE NOT NULL CHECK (tier IN ('free', 'basic', 'premium')),\n`;
    sql += `  name text NOT NULL,\n`;
    sql += `  price_monthly integer DEFAULT 0,\n`;
    sql += `  max_users integer DEFAULT 3,\n`;
    sql += `  features jsonb DEFAULT '{}',\n`;
    sql += `  created_at timestamptz DEFAULT NOW(),\n`;
    sql += `  updated_at timestamptz DEFAULT NOW()\n`;
    sql += `);\n\n`;
    
    sql += `CREATE TABLE IF NOT EXISTS pos_mini_modular3_businesses (\n`;
    sql += `  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,\n`;
    sql += `  name text NOT NULL,\n`;
    sql += `  contact_person text,\n`;
    sql += `  contact_phone text,\n`;
    sql += `  contact_email text,\n`;
    sql += `  address text,\n`;
    sql += `  business_type text DEFAULT 'retail',\n`;
    sql += `  subscription_tier text DEFAULT 'free',\n`;
    sql += `  status text DEFAULT 'active',\n`;
    sql += `  business_code text UNIQUE,\n`;
    sql += `  max_users integer DEFAULT 3,\n`;
    sql += `  created_at timestamptz DEFAULT NOW(),\n`;
    sql += `  updated_at timestamptz DEFAULT NOW()\n`;
    sql += `);\n\n`;
    
    sql += `CREATE TABLE IF NOT EXISTS pos_mini_modular3_user_profiles (\n`;
    sql += `  id uuid PRIMARY KEY,\n`;
    sql += `  business_id uuid REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,\n`;
    sql += `  full_name text NOT NULL,\n`;
    sql += `  email text,\n`;
    sql += `  phone text,\n`;
    sql += `  role text NOT NULL DEFAULT 'seller',\n`;
    sql += `  status text DEFAULT 'active',\n`;
    sql += `  employee_id text,\n`;
    sql += `  hire_date date DEFAULT CURRENT_DATE,\n`;
    sql += `  last_login_at timestamptz,\n`;
    sql += `  notes text,\n`;
    sql += `  login_method text DEFAULT 'email',\n`;
    sql += `  created_at timestamptz DEFAULT NOW(),\n`;
    sql += `  updated_at timestamptz DEFAULT NOW()\n`;
    sql += `);\n\n`;
    
    return sql;
  };

  return (
    <Button 
      onClick={handleBackup}
      disabled={isBackingUp}
      className="w-full"
      variant={type === 'full' ? 'default' : 'outline'}
    >
      {isBackingUp ? (
        <>
          <Loader2 className="w-4 h-4 mr-2 animate-spin" />
          Đang tạo backup...
        </>
      ) : (
        <>
          {type === 'full' ? (
            <Database className="w-4 h-4 mr-2" />
          ) : (
            <Shield className="w-4 h-4 mr-2" />
          )}
          <Download className="w-4 h-4 mr-2" />
          {type === 'full' ? 'Backup Full Database' : 'Backup Schema'}
        </>
      )}
    </Button>
  );
}