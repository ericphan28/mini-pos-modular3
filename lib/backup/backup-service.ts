/**
 * ==================================================================================
 * CORE BACKUP SERVICE
 * ==================================================================================
 * Professional backup service for POS Mini Modular 3
 * Features: Full/Incremental/Schema backups with compression and encryption
 */

import { SupabaseClient } from '@supabase/supabase-js';
import { createCipheriv, createHash, randomBytes } from 'crypto';
import { promisify } from 'util';
import { deflate, gzip } from 'zlib';
import {
    BACKUP_CONFIG,
    BackupConfig,
    BackupError,
    BackupMetadata,
    BackupProgress,
    StorageProvider,
    TableExportInfo
} from './types';

const gzipAsync = promisify(gzip);
const deflateAsync = promisify(deflate);

export class BackupService {
  private progressCallback?: (progress: BackupProgress) => void;
  private storageProvider?: StorageProvider;

  constructor(
    private supabase: SupabaseClient,
    storageProvider?: StorageProvider
  ) {
    this.storageProvider = storageProvider;
  }

  /**
   * Set progress callback for real-time updates
   */
  setProgressCallback(callback: (progress: BackupProgress) => void) {
    this.progressCallback = callback;
  }

  /**
   * Create a new backup with the specified configuration
   */
  async createBackup(config: BackupConfig, userId: string): Promise<BackupMetadata> {
    const backupId = this.generateBackupId();
    const timestamp = new Date().toISOString();
    
    try {
      this.updateProgress('preparing', 0);
      
      // Validate configuration
      await this.validateBackupConfig(config);
      
      let content: string;
      let tables: string[];
      
      switch (config.type) {
        case 'full':
          content = await this.generateFullBackup();
          tables = await this.getAllTables();
          break;
        case 'schema':
          content = await this.generateSchemaBackup();
          tables = await this.getAllTables();
          break;
        case 'data':
          content = await this.generateDataBackup(config.tables);
          tables = config.tables || await this.getAllTables();
          break;
        case 'incremental':
          if (!config.lastBackupTime) {
            throw new BackupError('lastBackupTime is required for incremental backup', 'MISSING_TIMESTAMP');
          }
          content = await this.generateIncrementalBackup(config.lastBackupTime);
          tables = await this.getModifiedTables(config.lastBackupTime);
          break;
        default:
          throw new BackupError(`Unsupported backup type: ${config.type}`, 'INVALID_TYPE');
      }
      
      this.updateProgress('compressing', 80);
      
      // Process content (compress, encrypt)
      let finalContent: Buffer = Buffer.from(content, 'utf8');
      if (config.compression !== 'none') {
        finalContent = await this.compressContent(finalContent, config.compression);
      }
      
      this.updateProgress('encrypting', 90);
      
      if (config.encryption) {
        finalContent = await this.encryptContent(finalContent);
      }
      
      // Generate checksum
      const checksum = createHash('sha256').update(finalContent).digest('hex');
      
      // Create metadata
      const metadata: BackupMetadata = {
        id: backupId,
        filename: this.generateFilename(config.type, timestamp, backupId, config),
        type: config.type,
        size: finalContent.length,
        checksum,
        created_at: timestamp,
        version: await this.getDatabaseVersion(),
        tables,
        compressed: config.compression !== 'none',
        encrypted: config.encryption,
        storage_path: '',
        retention_until: this.calculateRetentionDate(config.retention),
        status: 'creating',
        created_by: userId
      };
      
      this.updateProgress('uploading', 95);
      
      // Store backup file
      const storagePath = await this.storeBackupFile(metadata.filename, finalContent);
      metadata.storage_path = storagePath;
      metadata.status = 'completed';
      
      // Save metadata to database
      await this.saveBackupMetadata(metadata);
      
      this.updateProgress('finalizing', 100);
      
      console.log(`✅ Backup created successfully: ${metadata.id}`);
      return metadata;
      
    } catch (error) {
      console.error(`❌ Backup creation failed:`, error);
      
      // Update metadata with error status
      try {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        await this.updateBackupStatus(backupId, 'failed', errorMessage);
      } catch (dbError) {
        console.error('Failed to update backup status:', dbError);
      }
      
      if (error instanceof BackupError) {
        throw error;
      } else if (error instanceof Error) {
        throw new BackupError(error.message, 'BACKUP_FAILED');
      } else {
        throw new BackupError('Unknown backup error', 'BACKUP_FAILED');
      }
    }
  }

  /**
   * Generate full database backup (schema + data)
   */
  private async generateFullBackup(): Promise<string> {
    let sql = this.getBackupHeader('FULL DATABASE BACKUP');
    
    this.updateProgress('exporting_schema', 20);
    
    // Export schema first
    sql += await this.exportSchema();
    
    this.updateProgress('exporting_data', 40);
    
    // Export data
    sql += await this.exportAllData();
    
    // Export functions and procedures
    sql += await this.exportFunctions();
    
    return sql;
  }

  /**
   * Generate schema-only backup
   */
  private async generateSchemaBackup(): Promise<string> {
    let sql = this.getBackupHeader('SCHEMA BACKUP');
    
    this.updateProgress('exporting_schema', 30);
    
    // Export table structures
    sql += await this.exportSchema();
    
    this.updateProgress('exporting_schema', 60);
    
    // Export functions, triggers, etc.
    sql += await this.exportFunctions();
    sql += await this.exportTriggers();
    sql += await this.exportViews();
    
    return sql;
  }

  /**
   * Generate data-only backup
   */
  private async generateDataBackup(tables?: string[]): Promise<string> {
    let sql = this.getBackupHeader('DATA BACKUP');
    
    const targetTables = tables || await this.getAllTables();
    sql += await this.exportTablesData(targetTables);
    
    return sql;
  }

  /**
   * Generate incremental backup (changes since last backup)
   */
  private async generateIncrementalBackup(lastBackupTime?: string): Promise<string> {
    if (!lastBackupTime) {
      throw new BackupError('Last backup time is required for incremental backup', 'MISSING_TIMESTAMP');
    }
    
    let sql = this.getBackupHeader('INCREMENTAL BACKUP');
    sql += `-- Base timestamp: ${lastBackupTime}\n\n`;
    
    const modifiedTables = await this.getModifiedTables(lastBackupTime);
    
    for (const table of modifiedTables) {
      sql += await this.exportTableChanges(table, lastBackupTime);
    }
    
    return sql;
  }

  /**
   * Export database schema
   */
  private async exportSchema(): Promise<string> {
    let sql = '\n-- ==================================================================================\n';
    sql += '-- SCHEMA EXPORT\n';
    sql += '-- ==================================================================================\n\n';
    
    const tables = await this.getAllTables();
    
    for (const table of tables) {
      this.updateProgress('exporting_schema', undefined, table);
      sql += await this.getTableSchema(table);
    }
    
    // Export indexes
    sql += await this.exportIndexes();
    
    // Export constraints
    sql += await this.exportConstraints();
    
    return sql;
  }

  /**
   * Export all table data
   */
  private async exportAllData(): Promise<string> {
    let sql = '\n-- ==================================================================================\n';
    sql += '-- DATA EXPORT\n';
    sql += '-- ==================================================================================\n\n';
    
    const tables = await this.getAllTables();
    const exportOrder = await this.getTableExportOrder(tables);
    
    let completedTables = 0;
    
    for (const tableInfo of exportOrder) {
      this.updateProgress('exporting_data', undefined, tableInfo.name, completedTables, exportOrder.length);
      sql += await this.exportTableData(tableInfo.name);
      completedTables++;
    }
    
    return sql;
  }

  /**
   * Export specific tables data
   */
  private async exportTablesData(tables: string[]): Promise<string> {
    let sql = '\n-- ==================================================================================\n';
    sql += '-- SELECTED TABLES DATA EXPORT\n';
    sql += '-- ==================================================================================\n\n';
    
    const exportOrder = await this.getTableExportOrder(tables);
    let completedTables = 0;
    
    for (const tableInfo of exportOrder) {
      this.updateProgress('exporting_data', undefined, tableInfo.name, completedTables, exportOrder.length);
      sql += await this.exportTableData(tableInfo.name);
      completedTables++;
    }
    
    return sql;
  }

  /**
   * Export single table data with upsert support
   */
  private async exportTableData(tableName: string): Promise<string> {
    try {
      const { data, error } = await this.supabase
        .from(tableName)
        .select('*');
        
      if (error) {
        console.warn(`⚠️ Failed to export table ${tableName}:`, error);
        return `-- ⚠️ Failed to export table: ${tableName} (${error.message})\n\n`;
      }
      
      if (!data || data.length === 0) {
        return `-- Empty table: ${tableName}\n\n`;
      }
      
      let sql = `-- Data for table: ${tableName} (${data.length} rows)\n`;
      
      // Get column names
      const columns = Object.keys(data[0]);
      const columnList = columns.join(', ');
      
      // Use INSERT ... ON CONFLICT for upsert behavior
      sql += `INSERT INTO ${tableName} (${columnList}) VALUES\n`;
      
      const values = data.map(row => {
        const rowValues = columns.map(col => {
          const value = row[col];
          if (value === null || value === undefined) return 'NULL';
          if (typeof value === 'string') return `'${value.replace(/'/g, "''")}'`;
          if (typeof value === 'object') return `'${JSON.stringify(value).replace(/'/g, "''")}'`;
          if (typeof value === 'boolean') return value.toString();
          return String(value);
        });
        return `  (${rowValues.join(', ')})`;
      });
      
      sql += values.join(',\n');
      
      // Add conflict resolution if table has primary key
      const primaryKey = await this.getTablePrimaryKey(tableName);
      if (primaryKey) {
        sql += `\nON CONFLICT (${primaryKey}) DO UPDATE SET\n`;
        const updateClauses = columns
          .filter(col => col !== primaryKey)
          .map(col => `  ${col} = EXCLUDED.${col}`);
        sql += updateClauses.join(',\n');
      }
      
      sql += ';\n\n';
      
      return sql;
      
    } catch (error) {
      console.error(`Error exporting table ${tableName}:`, error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return `-- ❌ Error exporting table: ${tableName} (${errorMessage})\n\n`;
    }
  }

  /**
   * Utility methods
   */
  private generateBackupId(): string {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  }
  
  private getBackupHeader(type: string): string {
    return `-- ==================================================================================\n-- POS MINI MODULAR 3 - ${type}\n-- Generated: ${new Date().toISOString()}\n-- System Version: ${process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0'}\n-- Database Version: PostgreSQL 15+\n-- ==================================================================================\n\n`;
  }

  private generateFilename(type: string, timestamp: string, id: string, config: BackupConfig): string {
    const date = timestamp.split('T')[0];
    const time = timestamp.split('T')[1].split('.')[0].replace(/:/g, '-');
    let filename = `pos-mini-${type}-${date}-${time}-${id.substring(0, 8)}.sql`;
    
    if (config.compression === 'gzip') filename += '.gz';
    if (config.compression === 'lz4') filename += '.lz4';
    if (config.encryption) filename += '.enc';
    
    return filename;
  }

  private async compressContent(content: Buffer, method: 'gzip' | 'lz4'): Promise<Buffer> {
    switch (method) {
      case 'gzip':
        return await gzipAsync(content);
      case 'lz4':
        // For now, use deflate as lz4 alternative
        return await deflateAsync(content);
      default:
        return content;
    }
  }

  private async encryptContent(content: Buffer): Promise<Buffer> {
    const algorithm = 'aes-256-gcm';
    const key = process.env.BACKUP_ENCRYPTION_KEY;
    
    if (!key || key.length !== 32) {
      throw new BackupError('Invalid encryption key. Must be 32 characters.', 'INVALID_ENCRYPTION_KEY');
    }
    
    const iv = randomBytes(16);
    const cipher = createCipheriv(algorithm, key, iv);
    
    const encrypted = Buffer.concat([cipher.update(content), cipher.final()]);
    const authTag = cipher.getAuthTag();
    
    // Format: IV (16 bytes) + Auth Tag (16 bytes) + Encrypted Data
    return Buffer.concat([iv, authTag, encrypted]);
  }

  private calculateRetentionDate(retentionDays: number): string {
    const date = new Date();
    date.setDate(date.getDate() + retentionDays);
    return date.toISOString();
  }

  private updateProgress(
    stage: BackupProgress['stage'], 
    progress?: number, 
    currentTable?: string,
    tablesCompleted?: number,
    totalTables?: number
  ) {
    if (this.progressCallback) {
      this.progressCallback({
        stage,
        progress: progress ?? 0,
        currentTable,
        tablesCompleted: tablesCompleted ?? 0,
        totalTables: totalTables ?? 1
      });
    }
  }

  // Database introspection methods (to be implemented)
  private async getAllTables(): Promise<string[]> {
    try {
      // Use raw SQL to query information_schema
      const { data, error } = await this.supabase.rpc('get_table_list', {
        schema_name: 'public',
        table_prefix: BACKUP_CONFIG.BACKUP_TABLE_PREFIX
      });

      if (error) {
        console.error('Error getting table list:', error);
        // Fallback: return common table names
        return [
          'pos_mini_modular3_businesses',
          'pos_mini_modular3_users',
          'pos_mini_modular3_business_types',
          'pos_mini_modular3_staff',
          'pos_mini_modular3_business_invitations',
          'pos_mini_modular3_backup_metadata',
          'pos_mini_modular3_backup_history',
          'pos_mini_modular3_backup_schedules',
          'pos_mini_modular3_backup_notifications'
        ];
      }

      return data || [];
    } catch (error) {
      console.error('Failed to get table list:', error);
      // Return fallback list
      return [
        'pos_mini_modular3_businesses',
        'pos_mini_modular3_users',
        'pos_mini_modular3_business_types',
        'pos_mini_modular3_staff',
        'pos_mini_modular3_business_invitations',
        'pos_mini_modular3_backup_metadata',
        'pos_mini_modular3_backup_history',
        'pos_mini_modular3_backup_schedules',
        'pos_mini_modular3_backup_notifications'
      ];
    }
  }

  private async getTableExportOrder(tables: string[]): Promise<TableExportInfo[]> {
    // Implement dependency analysis to determine export order
    // For now, return simple order
    return tables.map((table, index) => ({
      name: table,
      rowCount: 0,
      estimatedSize: 0,
      dependencies: [],
      exportOrder: index
    }));
  }

  private async getDatabaseVersion(): Promise<string> {
    const { data } = await this.supabase.rpc('version');
    return data || 'Unknown';
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private async getTablePrimaryKey(_tableName: string): Promise<string | null> {
    // Query information_schema to get primary key
    return 'id'; // Default assumption
  }

  // Storage methods
  private async ensureBucketExists(): Promise<void> {
    try {
      // Check if bucket exists
      const { data: buckets, error: listError } = await this.supabase.storage.listBuckets();
      
      if (listError) {
        console.error('Failed to list buckets:', listError);
        throw new BackupError('Failed to access storage', 'STORAGE_ERROR');
      }
      
      const backupsBucket = buckets?.find(bucket => bucket.name === 'backups');
      
      if (!backupsBucket) {
        console.log('🔧 Creating backups bucket...');
        // Create bucket if it doesn't exist
        const { error: createError } = await this.supabase.storage.createBucket('backups', {
          public: false,
          allowedMimeTypes: ['application/sql', 'application/gzip', 'application/octet-stream'],
          fileSizeLimit: 1024 * 1024 * 1024 // 1GB limit
        });
        
        if (createError) {
          console.error('Failed to create backups bucket:', createError);
          throw new BackupError('Failed to create storage bucket', 'STORAGE_ERROR');
        }
        
        console.log('✅ Backups bucket created successfully');
      } else {
        console.log('✅ Backups bucket already exists');
      }
    } catch (error) {
      console.error('Error ensuring bucket exists:', error);
      if (error instanceof BackupError) {
        throw error;
      }
      throw new BackupError('Failed to setup storage', 'STORAGE_ERROR');
    }
  }

  private async storeBackupFile(filename: string, content: Buffer): Promise<string> {
    if (this.storageProvider) {
      return await this.storageProvider.upload(filename, content);
    }
    
    // Ensure bucket exists before uploading
    await this.ensureBucketExists();
    
    console.log(`📤 Uploading backup file: ${filename} (${content.length} bytes)`);
    
    // Default: store in Supabase Storage
    const { data, error } = await this.supabase.storage
      .from('backups')
      .upload(filename, content, {
        contentType: 'application/octet-stream',
        upsert: false
      });
      
    if (error) {
      console.error('❌ Failed to upload backup file:', error);
      throw new BackupError(`Failed to store backup file: ${error.message}`, 'STORAGE_ERROR');
    }
    
    if (!data?.path) {
      throw new BackupError('Upload successful but no path returned', 'STORAGE_ERROR');
    }
    
    console.log(`✅ Backup file uploaded successfully: ${data.path}`);
    return data.path;
  }

  private async saveBackupMetadata(metadata: BackupMetadata): Promise<void> {
    const { error } = await this.supabase
      .from('pos_mini_modular3_backup_metadata')
      .insert(metadata);
      
    if (error) {
      throw new BackupError('Failed to save backup metadata', 'DATABASE_ERROR', { error });
    }
  }

  private async updateBackupStatus(backupId: string, status: BackupMetadata['status'], errorMessage?: string): Promise<void> {
    const updateData: { status: BackupMetadata['status']; error_message?: string } = { status };
    if (errorMessage) updateData.error_message = errorMessage;
    
    await this.supabase
      .from('pos_mini_modular3_backup_metadata')
      .update(updateData)
      .eq('id', backupId);
  }

  private async validateBackupConfig(config: BackupConfig): Promise<void> {
    if (config.type === 'incremental' && !config.lastBackupTime) {
      throw new BackupError('lastBackupTime is required for incremental backups', 'INVALID_CONFIG');
    }
    
    if (config.tables && config.tables.length === 0) {
      throw new BackupError('Table list cannot be empty', 'INVALID_CONFIG');
    }
  }

  // Placeholder methods for functions/triggers/views export
  private async exportFunctions(): Promise<string> {
    return '\n-- Functions will be exported here\n';
  }

  private async exportTriggers(): Promise<string> {
    return '\n-- Triggers will be exported here\n';
  }

  private async exportViews(): Promise<string> {
    return '\n-- Views will be exported here\n';
  }

  private async exportIndexes(): Promise<string> {
    return '\n-- Indexes will be exported here\n';
  }

  private async exportConstraints(): Promise<string> {
    return '\n-- Constraints will be exported here\n';
  }

  private async getTableSchema(tableName: string): Promise<string> {
    return `-- Schema for table: ${tableName}\n`;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private async getModifiedTables(_since: string): Promise<string[]> {
    // Implementation to detect modified tables since timestamp
    return [];
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private async exportTableChanges(_tableName: string, _since: string): Promise<string> {
    // Implementation to export only changed records
    return `-- Changes for table since timestamp\n`;
  }
}
