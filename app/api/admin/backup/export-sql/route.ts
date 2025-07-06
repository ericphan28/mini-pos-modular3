/**
 * ==================================================================================
 * EXPORT SQL API ENDPOINT
 * ==================================================================================
 * API endpoint để export database thành SQL script có thể chạy trực tiếp trong Supabase SQL Editor
 */

import { createClient } from '@/lib/supabase/server';
import type { SupabaseClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

interface ExportSQLRequest {
  includeSchema?: boolean;
  includeData?: boolean;
  format?: 'supabase' | 'standard';
  selectedTables?: string[];
}

export async function GET() {
  return NextResponse.json({
    status: 'OK',
    endpoint: '/api/admin/backup/export-sql',
    method: 'POST',
    description: 'Export database to SQL script'
  });
}

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Parse request body safely
    let body: ExportSQLRequest;
    try {
      body = await request.json();
    } catch (parseError) {
      console.log('❌ JSON parse error:', parseError);
      return NextResponse.json({ error: 'Invalid JSON in request body' }, { status: 400 });
    }

    const { 
      includeSchema = true, 
      includeData = true, 
      format = 'supabase',
      selectedTables 
    } = body;

    console.log(`🚀 Starting SQL export`);
    console.log(`📋 Options:`, { includeSchema, includeData, format, selectedTables });

    const sqlExporter = new SQLExporter(supabase);
    const sqlScript = await sqlExporter.exportToSQL({
      includeSchema,
      includeData,
      format,
      selectedTables: selectedTables || []
    });

    console.log(`✅ SQL export completed, script length: ${sqlScript.length} characters`);

    return NextResponse.json({
      success: true,
      sqlScript,
      exportInfo: {
        timestamp: new Date().toISOString(),
        includeSchema,
        includeData,
        format
      }
    });

  } catch (error) {
    console.error('❌ SQL export failed:', error);
    
    // Ensure we always return proper JSON
    const errorMessage = error instanceof Error ? error.message : 'Export SQL failed';
    
    return NextResponse.json({
      success: false,
      error: errorMessage
    }, { 
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

/**
 * SQL Exporter Class
 * Handles the generation of SQL scripts optimized for Supabase
 */
class SQLExporter {
  constructor(private supabase: SupabaseClient) {}

  async exportToSQL(options: Required<ExportSQLRequest>): Promise<string> {
    const { includeSchema, includeData, format, selectedTables } = options;
    
    let sqlScript = '';

    // Header comment
    sqlScript += this.generateHeader(format);

    // Get all user tables
    const tables = await this.getUserTables(selectedTables);
    console.log(`📋 Found ${tables.length} tables to export:`, tables);

    if (includeSchema) {
      console.log(`🏗️ Exporting schema...`);
      sqlScript += await this.exportSchema(tables);
    }

    if (includeData) {
      console.log(`📊 Exporting data...`);
      sqlScript += await this.exportData(tables);
    }

    // Footer
    sqlScript += this.generateFooter(format);

    return sqlScript;
  }

  private generateHeader(format: string): string {
    const timestamp = new Date().toISOString();
    
    return `-- ==================================================================================
-- POS MINI MODULAR 3 - DATABASE EXPORT
-- ==================================================================================
-- Generated: ${timestamp}
-- Format: ${format.toUpperCase()}
-- Target: Supabase PostgreSQL Database
-- 
-- Instructions:
-- 1. Copy this entire script
-- 2. Open Supabase Dashboard > SQL Editor
-- 3. Create a new query
-- 4. Paste and run this script
-- 
-- This script creates tables and inserts data with conflict resolution
-- ==================================================================================

`;
  }

  private generateFooter(format: string): string {
    return `
-- ==================================================================================
-- EXPORT COMPLETED SUCCESSFULLY
-- ==================================================================================
-- Script generated for POS Mini Modular 3
-- Format: ${format.toUpperCase()}
-- 
-- All tables and data have been exported with upsert logic
-- Existing data will be updated, new data will be inserted
-- 
-- If you encounter any issues:
-- 1. Check that all required extensions are enabled
-- 2. Ensure you have proper permissions for the target schema
-- 3. Verify table names match your database schema
-- 
-- Support: Contact your system administrator
-- ==================================================================================
`;
  }

  private async getUserTables(selectedTables?: string[]): Promise<string[]> {
    try {
      console.log('🔍 Detecting tables using information_schema like pg_dump...');
      
      // Sử dụng information_schema như pg_dump để tự động detect tables
      const { data: schemaData, error: schemaError } = await this.supabase
        .rpc('pos_mini_modular3_get_all_tables_info');

      if (schemaError) {
        console.warn('⚠️ Could not use RPC, falling back to manual detection');
        return this.fallbackTableDetection(selectedTables);
      }

      if (schemaData && Array.isArray(schemaData)) {
        const detectedTables = schemaData
          .filter((table: { schema_name: string; table_name: string }) => {
            // Include public schema tables và auth.users
            return (table.schema_name === 'public' && table.table_name.startsWith('pos_mini_modular3_')) ||
                   (table.schema_name === 'auth' && table.table_name === 'users');
          })
          .map((table: { schema_name: string; table_name: string }) => 
            table.schema_name === 'auth' ? `auth.${table.table_name}` : table.table_name
          );

        console.log(`📋 Auto-detected ${detectedTables.length} tables:`, detectedTables);
        
        // Filter by selected tables if provided
        if (selectedTables && selectedTables.length > 0) {
          const filteredTables = detectedTables.filter((table: string) => selectedTables.includes(table));
          console.log(`📋 Filtered to ${filteredTables.length} selected tables:`, filteredTables);
          return filteredTables;
        }
        
        return detectedTables;
      }

      return this.fallbackTableDetection(selectedTables);
    } catch (error) {
      console.error(`❌ Error getting tables from information_schema:`, error);
      return this.fallbackTableDetection(selectedTables);
    }
  }

  private async fallbackTableDetection(selectedTables?: string[]): Promise<string[]> {
    console.log('🔄 Using fallback manual table detection...');
    
    // Include auth.users và core tables
    const knownTables = [
      // Auth schema - QUAN TRỌNG!
      'auth.users',
      
      // Public schema - POS system tables
      'pos_mini_modular3_user_profiles',
      'pos_mini_modular3_business_types', 
      'pos_mini_modular3_businesses',
      'pos_mini_modular3_business_invitations',
      'pos_mini_modular3_subscription_plans',
      'pos_mini_modular3_subscription_history',
      'pos_mini_modular3_backup_metadata',
      'pos_mini_modular3_backup_downloads',
      'pos_mini_modular3_backup_notifications',
      'pos_mini_modular3_backup_schedules',
      'pos_mini_modular3_restore_history',
      'pos_mini_modular3_restore_points'
    ];

    const allTables: string[] = [];

    // Check each table
    for (const table of knownTables) {
      try {
        if (table.startsWith('auth.')) {
          // Special handling for auth schema
          try {
            const { error } = await this.supabase.auth.admin.listUsers();
            
            if (!error) {
              allTables.push('auth.users');
              console.log(`✅ Found auth table: ${table}`);
            }
          } catch {
            console.log(`⚠️ Cannot access auth.users, might need RLS policy`);
          }
        } else {
          // Regular public schema tables
          const { data: tableData, error } = await this.supabase
            .from(table)
            .select('*', { count: 'exact', head: true });
          
          if (!error) {
            allTables.push(table);
            console.log(`✅ Found table: ${table} (${tableData.length || 0} rows)`);
          }
        }
      } catch (error) {
        console.error('Export error:', error);
      }
    }
    
    console.log(`📋 Found ${allTables.length} accessible tables total`);
    
    // Filter by selected tables if provided
    if (selectedTables && selectedTables.length > 0) {
      const filteredTables = allTables.filter((table: string) => selectedTables.includes(table));
      console.log(`📋 Filtered to ${filteredTables.length} selected tables:`, filteredTables);
      return filteredTables;
    }
    
    return allTables;
  }

  private async exportSchema(tables: string[]): Promise<string> {
    let schemaSQL = `
-- ==================================================================================
-- SCHEMA EXPORT
-- ==================================================================================

`;

    for (const table of tables) {
      try {
        console.log(`🏗️ Exporting schema for table: ${table}`);
        
        // Lấy thông tin cột từ bảng thực tế
        const { data: sampleData } = await this.supabase
          .from(table)
          .select('*')
          .limit(1);

        if (sampleData && sampleData.length > 0) {
          const sample = sampleData[0];
          const columns = Object.keys(sample);
          
          // Tạo CREATE TABLE statement cơ bản
          schemaSQL += `-- Table: ${table}\n`;
          schemaSQL += `CREATE TABLE IF NOT EXISTS ${table} (\n`;
          
          const columnDefinitions = columns.map(col => {
            const value = sample[col];
            let dataType = 'TEXT'; // Default
            
            if (col === 'id') {
              dataType = 'UUID PRIMARY KEY DEFAULT gen_random_uuid()';
            } else if (col.includes('_at') || col.includes('date')) {
              dataType = 'TIMESTAMPTZ';
            } else if (typeof value === 'number') {
              if (Number.isInteger(value)) {
                dataType = 'INTEGER';
              } else {
                dataType = 'DECIMAL';
              }
            } else if (typeof value === 'boolean') {
              dataType = 'BOOLEAN';
            } else if (typeof value === 'object' && value !== null) {
              dataType = 'JSONB';
            } else if (col.includes('email')) {
              dataType = 'VARCHAR(255)';
            }
            
            return `  ${col} ${dataType}`;
          });
          
          schemaSQL += columnDefinitions.join(',\n');
          schemaSQL += '\n);\n\n';
          
          // Thêm RLS policies cơ bản
          schemaSQL += `-- Enable RLS for ${table}\n`;
          schemaSQL += `ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;\n\n`;
          
        } else {
          // Nếu không có data, tạo schema cơ bản
          schemaSQL += `-- Table: ${table} (empty - basic schema)\n`;
          schemaSQL += `CREATE TABLE IF NOT EXISTS ${table} (\n`;
          schemaSQL += `  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n`;
          schemaSQL += `  created_at TIMESTAMPTZ DEFAULT NOW(),\n`;
          schemaSQL += `  updated_at TIMESTAMPTZ DEFAULT NOW()\n`;
          schemaSQL += `);\n\n`;
          schemaSQL += `ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;\n\n`;
        }

      } catch (error) {
        console.error(`❌ Error exporting schema for ${table}:`, error);
        schemaSQL += `-- Error: Could not export schema for table ${table}\n`;
        // Tạo schema cơ bản làm fallback
        schemaSQL += `CREATE TABLE IF NOT EXISTS ${table} (\n`;
        schemaSQL += `  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n`;
        schemaSQL += `  created_at TIMESTAMPTZ DEFAULT NOW()\n`;
        schemaSQL += `);\n\n`;
      }
    }

    return schemaSQL;
  }

  private async exportData(tables: string[]): Promise<string> {
    let dataSQL = `
-- ==================================================================================
-- DATA EXPORT (pg_dump style)
-- ==================================================================================

`;

    for (const table of tables) {
      try {
        console.log(`📊 Exporting data for table: ${table}`);
        
        let tableData;
        let dataError;

        // Special handling for auth schema tables
        if (table.startsWith('auth.')) {
          const authTable = table.replace('auth.', '');
          console.log(`🔐 Accessing auth schema table: ${authTable}`);
          
          // Try to access auth.users via RPC or direct query
          if (authTable === 'users') {
            try {
              // Method 1: Try RPC function if available
              const { data: rpcData, error: rpcError } = await this.supabase
                .rpc('pos_mini_modular3_get_auth_users');
              
              if (!rpcError && rpcData) {
                tableData = rpcData;
                dataError = null;
              } else {
                // Method 2: Try direct access (might need service role)
                const { data: directData, error: directError } = await this.supabase
                  .from('users')
                  .select('*');
                
                tableData = directData;
                dataError = directError;
              }
            } catch (authErr) {
              console.warn(`⚠️ Cannot access auth.users: ${authErr}`);
              dataSQL += `-- Error: Cannot access auth.users table - requires service role key or RPC function\n`;
              dataSQL += `-- Please ensure you have proper permissions to access auth schema\n\n`;
              continue;
            }
          }
        } else {
          // Regular public schema tables
          const { data: publicTableData, error } = await this.supabase
            .from(table)
            .select('*');
          
          tableData = publicTableData;
          dataError = error;
        }

        if (dataError) {
          console.warn(`⚠️ Failed to get data for ${table}: ${dataError.message}`);
          dataSQL += `-- Error: Could not export data for table ${table} - ${dataError.message}\n\n`;
          continue;
        }

        if (!tableData || tableData.length === 0) {
          dataSQL += `-- Table ${table} is empty\n\n`;
          continue;
        }

        dataSQL += `-- Data for table: ${table} (${tableData.length} rows)\n`;
        
        // Get columns from first row
        const columns = Object.keys(tableData[0]);
        
        // Generate pg_dump style COPY statement or INSERT statements
        const insertStatements = this.generateInsertStatements(table, columns, tableData);
        dataSQL += insertStatements;

        dataSQL += '\n';

      } catch (error) {
        console.error(`❌ Error exporting data for ${table}:`, error);
        dataSQL += `-- Error: Could not export data for table ${table} - ${error instanceof Error ? error.message : 'Unknown error'}\n\n`;
      }
    }

    return dataSQL;
  }

  private generateInsertStatements(
    table: string, 
    columns: string[], 
    data: Record<string, unknown>[]
  ): string {
    let sql = '';
    
    const columnsList = columns.join(', ');
    
    // Generate INSERT statements with proper escaping for Supabase
    for (const row of data) {
      const values = columns.map(col => {
        const value = row[col];
        
        if (value === null || value === undefined) {
          return 'NULL';
        }
        
        if (typeof value === 'string') {
          // Proper SQL string escaping for Supabase
          const escaped = value
            .replace(/\\/g, '\\\\')    // Escape backslashes first
            .replace(/'/g, "''")       // Escape single quotes
            .replace(/\n/g, '\\n')     // Escape newlines
            .replace(/\r/g, '\\r')     // Escape carriage returns
            .replace(/\t/g, '\\t')     // Escape tabs
            .replace(/\0/g, '\\0');    // Escape null bytes
          return `'${escaped}'`;
        }
        
        if (typeof value === 'boolean') {
          return value ? 'true' : 'false';
        }
        
        if (typeof value === 'number') {
          return value.toString();
        }
        
        if (typeof value === 'object' && value !== null) {
          // JSON objects - properly escape for JSONB
          const jsonStr = JSON.stringify(value)
            .replace(/\\/g, '\\\\')
            .replace(/'/g, "''");
          return `'${jsonStr}'::jsonb`;
        }
        
        if (value instanceof Date) {
          return `'${value.toISOString()}'::timestamptz`;
        }
        
        // Handle string dates
        if (typeof value === 'string' && value.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)) {
          return `'${value}'::timestamptz`;
        }
        
        // Fallback for other types
        return `'${String(value).replace(/'/g, "''")}'`;
      });

      // Generate clean INSERT statement compatible with Supabase SQL Editor
      sql += `INSERT INTO ${table} (${columnsList}) VALUES (${values.join(', ')})`;
      
      // Add ON CONFLICT clause for upsert behavior if table has id column
      if (columns.includes('id')) {
        sql += `\n  ON CONFLICT (id) DO UPDATE SET\n`;
        const updateClauses = columns
          .filter(col => col !== 'id' && col !== 'created_at') // Don't update id and created_at
          .map(col => `    ${col} = EXCLUDED.${col}`)
          .join(',\n');
        
        if (updateClauses) {
          sql += updateClauses;
        } else {
          // If no columns to update, just do nothing
          sql = sql.replace('DO UPDATE SET\n', 'DO NOTHING');
        }
      } else {
        // If no id column, use DO NOTHING to avoid duplicates
        sql += '\n  ON CONFLICT DO NOTHING';
      }
      
      sql += ';\n';
    }

    return sql;
  }
}
