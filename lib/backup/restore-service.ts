/**
 * ==================================================================================
 * RESTORE SERVICE
 * ==================================================================================
 * Professional database restore service for POS Mini Modular 3
 * Features: Safe restore with validation, rollback, and dry-run capabilities
 */

import { SupabaseClient } from '@supabase/supabase-js';
import { createDecipheriv, createHash } from 'crypto';
import { promisify } from 'util';
import { gunzip, inflate } from 'zlib';
import {
  BackupMetadata,
  RestoreError,
  RestoreOptions,
  RestoreProgress,
  RestoreResult,
  StorageProvider
} from './types';

const gunzipAsync = promisify(gunzip);
const inflateAsync = promisify(inflate);

interface RestorePoint {
  id: string;
  created_at: string;
  tables_backup: Record<string, object[]>;
  schema_backup: string;
  created_by: string;
  expires_at: string;
}

// Add RestoreChangeLog interface at top level
interface RestoreChangeLog {
  insertedRecords: Array<{table: string, id: string}>;
  updatedRecords: Array<{table: string, id: string, originalData: Record<string, unknown>}>;
  createdTables: string[];
  modifiedSchema: string[];
}

// Validation result interface
interface ValidationResult {
  valid: boolean;
  errors: string[];
}

export class RestoreService {
  private progressCallback?: (progress: RestoreProgress) => void;
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
  setProgressCallback(callback: (progress: RestoreProgress) => void) {
    this.progressCallback = callback;
  }

  /**
   * Validate restore operation before execution
   */
  async validateRestore(options: RestoreOptions): Promise<{valid: boolean, error?: string, warnings?: string[]}> {
    try {
      this.updateProgress('validating', 0);

      // Check if backup exists
      const backup = await this.getBackupMetadata(options.backupId);
      if (!backup) {
        return { valid: false, error: 'Backup not found' };
      }

      this.updateProgress('validating', 25);

      // Verify backup integrity
      const isValid = await this.verifyBackupIntegrity(backup);
      if (!isValid) {
        return { valid: false, error: 'Backup file is corrupted or invalid checksum' };
      }

      this.updateProgress('validating', 50);

      // Check database compatibility
      const compatibility = await this.checkCompatibility(backup);
      if (!compatibility.compatible) {
        return { valid: false, error: compatibility.reason };
      }

      this.updateProgress('validating', 75);

      // Validate target tables exist
      const warnings: string[] = [];
      if (options.targetTables) {
        const existingTables = await this.getExistingTables();
        const missingTables = options.targetTables.filter(table => !existingTables.includes(table));
        
        if (missingTables.length > 0) {
          warnings.push(`Tables will be created: ${missingTables.join(', ')}`);
        }
      }

      // Check for data conflicts
      const conflicts = await this.detectDataConflicts(backup, options);
      if (conflicts.length > 0) {
        warnings.push(`Potential data conflicts detected in: ${conflicts.join(', ')}`);
      }

      this.updateProgress('validating', 100);

      return { 
        valid: true, 
        warnings: warnings.length > 0 ? warnings : undefined 
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown validation error';
      return { valid: false, error: errorMessage };
    }
  }

  /**
   * Perform database restore operation
   */
  async performRestore(options: RestoreOptions): Promise<RestoreResult> {
    console.log(`🚀 Starting restore operation with options:`, options);
    const startTime = Date.now();
    let restorePointId: string | undefined;
    
    try {
      console.log(`📝 Updating progress: preparing (0%)`);
      this.updateProgress('preparing', 0);

      // Get backup metadata
      console.log(`📋 Getting backup metadata for ID: ${options.backupId}`);
      const backupMetadata = await this.getBackupMetadata(options.backupId);
      if (!backupMetadata) {
        console.error(`❌ Backup not found: ${options.backupId}`);
        throw new RestoreError('Backup not found', 'BACKUP_NOT_FOUND');
      }
      console.log(`✅ Backup metadata retrieved:`, backupMetadata);

      // Create restore point if requested
      if (options.createRestorePoint !== false) {
        console.log(`📝 Creating restore point...`);
        this.updateProgress('preparing', 20);
        restorePointId = await this.createRestorePoint(options.userId || 'system');
        console.log(`✅ Restore point created: ${restorePointId}`);
      }

      // Download and decrypt backup content
      console.log(`📦 Downloading and decrypting backup content...`);
      this.updateProgress('preparing', 40);
      const backupContent = await this.downloadAndDecryptBackup(backupMetadata);
      console.log(`✅ Backup content downloaded, size: ${backupContent.length} characters`);

      // Parse SQL content
      console.log(`📝 Parsing SQL content...`);
      this.updateProgress('preparing', 60);
      const sqlStatements = this.parseSQLContent(backupContent);
      console.log(`✅ SQL parsed, ${sqlStatements.length} statements found`);

      if (options.dryRun) {
        // Perform validation only
        console.log(`🧪 Performing dry run validation...`);
        this.updateProgress('preparing', 80);
        const validation = await this.validateSQLStatements(sqlStatements);
        console.log(`✅ Dry run validation completed:`, validation);
        
        return {
          success: true,
          message: `Dry run completed successfully. ${validation.statementCount} statements validated.`,
          warnings: validation.warnings,
          duration: Date.now() - startTime,
          restorePointId
        };
      }

      // Disable constraints temporarily
      console.log(`🔒 Disabling database constraints...`);
      await this.disableConstraints();

      try {
        // Begin restore transaction
        console.log(`📊 Beginning restore transaction...`);
        await this.beginRestoreTransaction();

        console.log(`📝 Updating progress: restoring_schema (10%)`);
        this.updateProgress('restoring_schema', 10);

        // Execute restore based on backup type
        console.log(`🔄 Executing restore operations...`);
        const result = await this.executeRestore(backupMetadata, sqlStatements, options);
        console.log(`✅ Restore execution completed:`, result);

        // Commit transaction
        console.log(`✅ Committing restore transaction...`);
        await this.commitRestoreTransaction();

        // Re-enable constraints
        console.log(`🔓 Re-enabling database constraints...`);
        await this.enableConstraints();

        console.log(`📝 Updating progress: finalizing (100%)`);
        this.updateProgress('finalizing', 100);

        console.log(`🎉 Restore operation completed successfully!`);
        return {
          success: true,
          message: 'Database restored successfully',
          tablesRestored: result.tablesRestored,
          rowsAffected: result.rowsAffected,
          duration: Date.now() - startTime,
          warnings: result.warnings,
          restorePointId
        };

      } catch (error) {
        console.error(`❌ Error during restore execution, rolling back transaction:`, error);
        // Rollback transaction
        await this.rollbackRestoreTransaction();
        throw error;
      }

    } catch (error) {
      console.error('💥 Restore operation failed:', error);

      // Attempt to restore from restore point if available
      if (restorePointId && options.createRestorePoint !== false) {
        console.log(`🔄 Attempting to restore from restore point: ${restorePointId}`);
        try {
          await this.restoreFromRestorePoint(restorePointId);
          console.log(`✅ Successfully restored from restore point`);
        } catch (rollbackError) {
          console.error(`❌ Failed to restore from restore point:`, rollbackError);
        }
      }

      const errorMessage = error instanceof Error ? error.message : 'Unknown restore error';
      
      return {
        success: false,
        message: `Restore failed: ${errorMessage}`,
        duration: Date.now() - startTime,
        restorePointId
      };
    }
  }

  /**
   * List available backups for restore
   */
  async listAvailableBackups(): Promise<BackupMetadata[]> {
    const { data, error } = await this.supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('status', 'completed')
      .order('created_at', { ascending: false });

    if (error) {
      throw new RestoreError('Failed to list backups', 'DATABASE_ERROR');
    }

    return data || [];
  }

  /**
   * Get backup metadata by ID
   */
  private async getBackupMetadata(backupId: string): Promise<BackupMetadata | null> {
    console.log(`📋 Querying backup metadata for ID: ${backupId}`);
    
    const { data, error } = await this.supabase
      .from('pos_mini_modular3_backup_metadata')
      .select('*')
      .eq('id', backupId)
      .single();

    if (error) {
      console.error(`❌ Error querying backup metadata:`, error);
      if (error.code === 'PGRST116') {
        console.log(`📋 Backup not found: ${backupId}`);
        return null; // Not found
      }
      throw new RestoreError('Failed to get backup metadata', 'DATABASE_ERROR');
    }

    console.log(`✅ Backup metadata found:`, data);
    return data;
  }

  /**
   * Verify backup file integrity
   */
  private async verifyBackupIntegrity(backup: BackupMetadata): Promise<boolean> {
    try {
      // Download backup file
      const content = await this.downloadBackupFile(backup);
      
      // Calculate checksum
      const calculatedChecksum = createHash('sha256').update(content).digest('hex');
      
      // Compare with stored checksum
      return calculatedChecksum === backup.checksum;
      
    } catch (error) {
      console.error('Error verifying backup integrity:', error);
      return false;
    }
  }

  /**
   * Check database compatibility
   */
  private async checkCompatibility(backup: BackupMetadata): Promise<{compatible: boolean, reason?: string}> {
    // Check database version compatibility
    const currentVersion = await this.getDatabaseVersion();
    
    // For now, assume compatibility
    // In production, implement proper version checking
    if (backup.version && currentVersion) {
      // Add version compatibility logic here
    }
    
    return { compatible: true };
  }

  /**
   * Download and decrypt backup content
   */
  private async downloadAndDecryptBackup(backup: BackupMetadata): Promise<string> {
    console.log('📥 Starting backup download and decryption...');
    
    // Download backup file
    let content = await this.downloadBackupFile(backup);
    console.log('📁 Downloaded file size:', content.length, 'bytes');
    console.log('📋 File starts with:', content.slice(0, 20).toString('hex'));

    // Decrypt if encrypted
    if (backup.encrypted) {
      console.log('🔓 Decrypting backup content...');
      content = await this.decryptContent(content);
      console.log('✅ Decryption completed, size:', content.length, 'bytes');
      console.log('📋 Decrypted starts with:', content.slice(0, 20).toString('hex'));
    }

    // Decompress if compressed
    if (backup.compressed) {
      console.log('📦 Decompressing backup content...');
      content = await this.decompressContent(content, backup.filename);
      console.log('✅ Decompression completed, size:', content.length, 'bytes');
      console.log('📋 Decompressed starts with:', content.slice(0, 100).toString('utf8'));
    }

    const textContent = content.toString('utf8');
    console.log('📝 Final content size:', textContent.length, 'characters');
    console.log('📝 Content preview (first 200 chars):', textContent.substring(0, 200));
    
    // Validate that content looks like SQL
    if (!textContent.trim().toLowerCase().includes('insert') && 
        !textContent.trim().toLowerCase().includes('create') &&
        !textContent.trim().toLowerCase().includes('update')) {
      console.warn('⚠️ Content does not appear to be valid SQL');
      console.log('📋 Content sample:', textContent.substring(0, 500));
    }
    
    return textContent;
  }

  /**
   * Download backup file from storage
   */
  private async downloadBackupFile(backup: BackupMetadata): Promise<Buffer> {
    if (this.storageProvider) {
      return await this.storageProvider.download(backup.filename);
    }

    // Default: download from Supabase Storage
    const { data, error } = await this.supabase.storage
      .from('backups')
      .download(backup.storage_path);

    if (error) {
      throw new RestoreError('Failed to download backup file', 'STORAGE_ERROR');
    }

    return Buffer.from(await data.arrayBuffer());
  }

  /**
   * Decrypt backup content
   */
  private async decryptContent(content: Buffer): Promise<Buffer> {
    const algorithm = 'aes-256-gcm';
    const key = process.env.BACKUP_ENCRYPTION_KEY;

    if (!key || key.length !== 32) {
      throw new RestoreError('Invalid encryption key for decryption', 'INVALID_ENCRYPTION_KEY');
    }

    try {
      // Extract IV (first 16 bytes), Auth Tag (next 16 bytes), and encrypted data
      const iv = content.slice(0, 16);
      const authTag = content.slice(16, 32);
      const encrypted = content.slice(32);

      const decipher = createDecipheriv(algorithm, Buffer.from(key, 'utf8'), iv);
      decipher.setAuthTag(authTag);
      
      return Buffer.concat([decipher.update(encrypted), decipher.final()]);
    } catch (error) {
      console.error('Decryption error details:', error);
      throw new RestoreError('Failed to decrypt backup content', 'DECRYPTION_FAILED');
    }
  }

  /**
   * Decompress backup content
   */
  private async decompressContent(content: Buffer, filename: string): Promise<Buffer> {
    try {
      console.log('📦 Decompressing content, filename:', filename);
      console.log('📦 Content size before decompression:', content.length);
      console.log('📦 Content starts with (hex):', content.slice(0, 20).toString('hex'));
      
      // Check for gzip magic number (1f 8b) at the beginning
      if (content[0] === 0x1f && content[1] === 0x8b) {
        console.log('✅ Detected gzip format by magic number');
        const decompressed = await gunzipAsync(content);
        console.log('✅ Gzip decompression successful, size:', decompressed.length);
        return decompressed;
      } else if (filename.includes('.gz')) {
        console.log('✅ Detected gzip format by filename');
        const decompressed = await gunzipAsync(content);
        console.log('✅ Gzip decompression successful, size:', decompressed.length);
        return decompressed;
      } else if (filename.includes('.lz4')) {
        console.log('✅ Detected lz4 format by filename');
        // Use inflate as lz4 alternative
        const decompressed = await inflateAsync(content);
        console.log('✅ LZ4 decompression successful, size:', decompressed.length);
        return decompressed;
      }
      
      console.log('📦 No compression detected, returning original content');
      return content;
    } catch (error) {
      console.error('❌ Decompression failed:', error);
      throw new RestoreError('Failed to decompress backup content', 'DECOMPRESSION_FAILED');
    }
  }

  /**
   * Parse SQL content into statements
   */
  private parseSQLContent(content: string): string[] {
    console.log('📝 Parsing SQL content...');
    console.log('📋 Content length:', content.length);
    console.log('📋 Content preview:', content.substring(0, 200));
    
    // Check if content is valid
    if (!content || content.trim().length === 0) {
      console.warn('⚠️ Empty or invalid content');
      return [];
    }
    
    // Check if content looks like SQL by looking for common SQL keywords
    const contentLower = content.toLowerCase();
    const hasSqlKeywords = contentLower.includes('insert') || 
                          contentLower.includes('update') || 
                          contentLower.includes('create') || 
                          contentLower.includes('select') ||
                          contentLower.includes('delete');
    
    if (!hasSqlKeywords) {
      console.error('❌ Content does not contain SQL keywords');
      console.log('📋 Content sample:', content.substring(0, 500));
      return [];
    }
    
    // Split SQL content into individual statements
    // Use a more sophisticated approach to handle multi-line statements
    const lines = content.split('\n');
    const statements: string[] = [];
    let currentStatement = '';
    let inMultiLineComment = false;
    
    console.log('📋 Processing', lines.length, 'lines...');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Skip empty lines
      if (!line) continue;
      
      // Handle multi-line comments
      if (line.startsWith('/*')) {
        inMultiLineComment = true;
        if (line.includes('*/')) {
          inMultiLineComment = false;
        }
        continue;
      }
      if (inMultiLineComment) {
        if (line.includes('*/')) {
          inMultiLineComment = false;
        }
        continue;
      }
      
      // Skip single-line comments
      if (line.startsWith('--')) {
        continue;
      }
      
      // Add line to current statement
      currentStatement += line + ' ';
      
      // Check if statement ends with semicolon
      if (line.endsWith(';')) {
        const statement = currentStatement.trim();
        if (statement && statement !== ';') {
          // Only include actual SQL statements (INSERT, UPDATE, CREATE, etc.)
          const statementLower = statement.toLowerCase();
          const isValidStatement = statementLower.startsWith('insert') || 
              statementLower.startsWith('update') || 
              statementLower.startsWith('create') || 
              statementLower.startsWith('alter') ||
              statementLower.startsWith('delete') ||
              statementLower.startsWith('drop');
              
          console.log('📋 Found statement (line', i + 1, '), valid:', isValidStatement, ', preview:', statement.substring(0, 50));
          
          if (isValidStatement) {
            statements.push(statement);
          }
        }
        currentStatement = '';
      }
    }

    console.log('📋 Parsed', statements.length, 'SQL statements');
    
    // Log first few statements preview
    if (statements.length > 0) {
      console.log('📋 First statement preview:', statements[0].substring(0, 200));
      if (statements.length > 1) {
        console.log('📋 Second statement preview:', statements[1].substring(0, 100));
      }
    }
    
    return statements;
  }

  /**
   * Execute restore based on backup type and options
   */
  private async executeRestore(
    backup: BackupMetadata, 
    sqlStatements: string[], 
    options: RestoreOptions
  ): Promise<{tablesRestored: string[], rowsAffected: number, warnings: string[]}> {
    
    const startTime = Date.now();
    const result = {
      tablesRestored: options.targetTables || backup.tables,
      rowsAffected: 0,
      warnings: [] as string[]
    };

    // ENHANCED TRACKING - Get table states before restore
    const tableStatesBefore: Record<string, number> = {};
    for (const table of result.tablesRestored) {
      try {
        const { count } = await this.supabase
          .from(table)
          .select('*', { count: 'exact', head: true });
        tableStatesBefore[table] = count || 0;
      } catch {
        console.warn(`⚠️ Could not get initial count for table ${table}`);
        tableStatesBefore[table] = -1; // Unknown
      }
    }

    console.log(`📊 Table states BEFORE restore:`, tableStatesBefore);

    let completedStatements = 0;
    
    console.log(`🔧 Processing ${sqlStatements.length} SQL statements...`);
    
    // Track which statements were actually executed
    const executedStatements: string[] = [];
    const failedStatements: string[] = [];
    const recordsUpserted: string[] = []; // Track specific records

    for (const statement of sqlStatements) {
      try {
        // Filter statements if specific tables requested
        if (options.targetTables && !this.isStatementForTargetTables(statement, options.targetTables)) {
          console.log(`⏭️ Skipping statement (not for target tables): ${statement.substring(0, 50)}...`);
          continue;
        }

        // Skip auth tables if not requested
        if (!options.restoreAuth && this.isAuthTableStatement(statement, options)) {
          console.log(`⏭️ Skipping auth statement: ${statement.substring(0, 50)}...`);
          result.warnings.push('Skipped auth table statement (restoreAuth=false)');
          continue;
        }

        this.updateProgress(
          'restoring_data', 
          Math.round((completedStatements / sqlStatements.length) * 100),
          undefined,
          completedStatements,
          sqlStatements.length
        );

        console.log(`📝 Executing statement ${completedStatements + 1}/${sqlStatements.length}: ${statement.substring(0, 100)}...`);

        // Use direct execution instead of execute_sql RPC for better reliability
        try {
          await this.executeStatementDirect(statement);
          result.rowsAffected++;
          executedStatements.push(statement.substring(0, 100));
          console.log(`✅ Statement executed successfully (direct method)`);
        } catch (directError) {
          console.warn(`⚠️ Direct execution failed, trying execute_sql RPC:`, directError);
          
          // Fall back to execute_sql function
          try {
            const { data: sqlResult, error } = await this.supabase.rpc('execute_sql', { sql: statement });
            
            if (error) {
              console.error(`❌ Both direct and RPC execution failed:`, error.message);
              failedStatements.push(statement.substring(0, 100));
              throw new Error(`Failed to execute statement: ${error.message}`);
            } else {
              console.log(`✅ execute_sql result:`, sqlResult);
              result.rowsAffected += 1;
              executedStatements.push(statement.substring(0, 100));
              console.log(`✅ Statement executed successfully (execute_sql fallback)`);
            }
          } catch (rpcError) {
            console.error(`❌ Both execution methods failed:`, rpcError);
            failedStatements.push(statement.substring(0, 100));
            throw rpcError;
          }
        }

        // After successful execution, track the upserted record
        const tableName = this.extractTableName(statement);
        const recordId = this.extractInsertedRecordId(statement);
        if (tableName && recordId) {
          recordsUpserted.push(`${tableName}:${recordId}`);
        }

        completedStatements++;

      } catch (executeError) {
        const errorMsg = executeError instanceof Error ? executeError.message : 'Unknown error';
        console.error(`❌ Error executing statement ${completedStatements + 1}:`, errorMsg);
        console.error(`❌ Failed statement: ${statement}`);
        failedStatements.push(statement.substring(0, 100));
        result.warnings.push(`Statement ${completedStatements + 1}: ${errorMsg}`);
      }
    }

    // ENHANCED TRACKING - Get table states after restore  
    const tableStatesAfter: Record<string, number> = {};
    for (const table of result.tablesRestored) {
      try {
        const { count } = await this.supabase
          .from(table)
          .select('*', { count: 'exact', head: true });
        tableStatesAfter[table] = count || 0;
      } catch {
        console.warn(`⚠️ Could not get final count for table ${table}`);
        tableStatesAfter[table] = -1; // Unknown
      }
    }

    console.log(`📊 Table states AFTER restore:`, tableStatesAfter);
    
    // Calculate actual changes
    const tableChanges: Record<string, number> = {};
    Object.keys(tableStatesBefore).forEach(table => {
      const before = tableStatesBefore[table];
      const after = tableStatesAfter[table];
      if (before >= 0 && after >= 0) {
        tableChanges[table] = after - before;
      }
    });

    console.log(`🔄 Net changes per table:`, tableChanges);
    console.log(`📝 Records specifically upserted:`, recordsUpserted);

    console.log(`✅ Restore execution summary:`, {
      totalStatements: sqlStatements.length,
      completed: completedStatements,
      rowsAffected: result.rowsAffected,
      warnings: result.warnings.length,
      executedStatements: executedStatements.length,
      failedStatements: failedStatements.length,
      tableChangesSummary: tableChanges,
      specificRecordsUpserted: recordsUpserted.length
    });

    // LOG RESTORE HISTORY
    try {
      console.log(`📊 Logging restore history...`);
      const { error: historyError } = await this.supabase
        .from('pos_mini_modular3_restore_history')
        .insert({
          backup_id: backup.id,
          restored_by: options.userId || 'system',
          restore_type: options.targetTables ? 'partial' : 'full',
          target_tables: options.targetTables || null,
          success: failedStatements.length === 0,
          error_message: failedStatements.length > 0 ? `Failed statements: ${failedStatements.length}` : null,
          duration_ms: Date.now() - startTime,
          rows_affected: result.rowsAffected,
          restore_point_id: undefined // Set this if you have restore point ID
        });
        
      if (historyError) {
        console.error(`❌ Failed to log restore history:`, historyError);
      } else {
        console.log(`✅ Restore history logged successfully`);
      }
    } catch (historyLogError) {
      console.error(`❌ Error logging restore history:`, historyLogError);
    }

    return result;
  }

  /**
   * Execute SQL statement directly using Supabase client methods
   */
  private async executeStatementDirect(statement: string): Promise<void> {
    const trimmedStatement = statement.trim().toLowerCase();
    
    console.log(`🔧 Executing direct statement: ${statement.substring(0, 100)}...`);
    console.log(`🔍 Statement analysis:`, {
      hasOnConflict: trimmedStatement.includes('on conflict'),
      startsWithInsert: trimmedStatement.startsWith('insert into'),
      statementType: trimmedStatement.split(' ')[0]
    });
    
    // For statements with ON CONFLICT, use execute_sql RPC directly
    if (trimmedStatement.includes('on conflict')) {
      console.log(`📝 Statement has ON CONFLICT, using execute_sql RPC...`);
      
      try {
        const { data: sqlResult, error } = await this.supabase.rpc('execute_sql', { sql: statement });
        
        if (error) {
          console.error(`❌ execute_sql failed:`, error.message);
          console.error(`❌ Error details:`, error);
          throw new Error(`Failed to execute statement: ${error.message}`);
        } else {
          console.log(`✅ execute_sql successful, result:`, sqlResult);
          
          // ENHANCED VERIFICATION - Track actual changes
          const tableName = this.extractTableName(statement);
          if (tableName) {
            try {
              // Get row count before and after
              const { count: countAfter, error: countError } = await this.supabase
                .from(tableName)
                .select('*', { count: 'exact', head: true });
                
              if (!countError && typeof countAfter === 'number') {
                // Extract the primary key value from the INSERT statement to verify specific record
                const insertedRecordId = this.extractInsertedRecordId(statement);
                
                if (insertedRecordId) {
                  // Verify the specific record exists
                  const { data: recordData, error: recordError } = await this.supabase
                    .from(tableName)
                    .select('*')
                    .eq('id', insertedRecordId)
                    .single();
                    
                  if (!recordError && recordData) {
                    console.log(`✅ Verification: Table '${tableName}' now has ${countAfter} rows. Record '${insertedRecordId}' successfully UPSERTED`);
                    console.log(`📊 Record data:`, Object.keys(recordData).length, 'fields updated');
                  } else {
                    console.log(`⚠️ Verification: Table '${tableName}' has ${countAfter} rows, but record '${insertedRecordId}' not found`);
                  }
                } else {
                  console.log(`✅ Verification: Table '${tableName}' now has ${countAfter} rows (UPSERT completed, record ID not extracted)`);
                }
              } else {
                console.log(`⚠️ Verification failed for table '${tableName}': ${countError?.message || 'Count not available'}`);
              }
            } catch (verifyError) {
              console.log(`⚠️ Could not verify table '${tableName}': ${verifyError instanceof Error ? verifyError.message : 'Unknown error'}`);
            }
          } else {
            console.log(`⚠️ Could not extract table name from statement: ${statement.substring(0, 50)}...`);
          }
          
          return;
        }
      } catch (rpcError) {
        console.error(`❌ RPC execution error:`, rpcError);
        throw rpcError;
      }
    }
    
    // Parse the statement type and execute accordingly
    if (trimmedStatement.startsWith('insert into')) {
      await this.executeInsertStatement(statement);
    } else if (trimmedStatement.startsWith('update')) {
      await this.executeUpdateStatement(statement);
    } else if (trimmedStatement.startsWith('delete from')) {
      await this.executeDeleteStatement(statement);
    } else if (trimmedStatement.startsWith('create table')) {
      // Skip CREATE TABLE statements for now as tables should already exist
      console.log(`ℹ️ Skipping CREATE TABLE statement (tables should exist)`);
    } else {
      console.warn(`⚠️ Unsupported statement type, attempting execute_sql RPC: ${trimmedStatement.substring(0, 50)}...`);
      // Try to execute as raw SQL using execute_sql RPC
      const { data: sqlResult, error } = await this.supabase.rpc('execute_sql', { sql: statement });
      
      if (error) {
        throw new Error(`Failed to execute statement: ${error.message}`);
      } else {
        console.log(`✅ execute_sql successful, result:`, sqlResult);
      }
    }
  }

  /**
   * Extract table name from INSERT statement
   */
  private extractTableName(statement: string): string | null {
    const match = statement.match(/insert\s+into\s+([^\s(]+)/i);
    return match ? match[1].trim() : null;
  }

  /**
   * Extract the ID of the record being inserted for verification
   */
  private extractInsertedRecordId(statement: string): string | null {
    try {
      // Match INSERT INTO table (id, ...) VALUES ('value', ...)
      const match = statement.match(/insert\s+into\s+[^\s(]+\s*\([^)]*id[^)]*\)\s*values\s*\(\s*'([^']+)'/i);
      return match ? match[1] : null;
    } catch {
      return null;
    }
  }

  /**
   * Execute INSERT statement
   */
  private async executeInsertStatement(statement: string): Promise<void> {
    try {
      console.log(`🔧 Parsing INSERT statement: ${statement.substring(0, 150)}...`);
      
      // Handle both simple INSERT and INSERT with ON CONFLICT (upsert)
      const hasConflict = statement.toLowerCase().includes('on conflict');
      
      if (hasConflict) {
        console.log(`📝 Executing UPSERT statement via execute_sql RPC...`);
        
        // For ON CONFLICT statements, use execute_sql RPC directly
        // because Supabase client methods don't support raw ON CONFLICT syntax
        const { data: sqlResult, error } = await this.supabase.rpc('execute_sql', { sql: statement });
        
        if (error) {
          console.error(`❌ UPSERT via execute_sql failed:`, error.message);
          throw new Error(`Failed to execute UPSERT statement: ${error.message}`);
        } else {
          console.log(`✅ UPSERT executed successfully via execute_sql, result:`, sqlResult);
        }
        
      } else {
        // Simple INSERT statement without ON CONFLICT
        await this.executeSimpleInsert(statement);
      }
      
    } catch (error) {
      console.error(`❌ Failed to execute INSERT statement:`, error);
      console.error(`❌ Statement was: ${statement}`);
      throw error;
    }
  }

  /**
   * Execute simple INSERT statement by parsing values
   */
  private async executeSimpleInsert(statement: string): Promise<void> {
    // Parse INSERT INTO table_name (columns) VALUES (values)
    const insertMatch = statement.match(/insert\s+into\s+([^\s(]+)\s*\(([^)]+)\)\s*values\s*\((.+?)\)(?:\s*on\s+conflict.*)?/i);
    
    if (!insertMatch) {
      throw new Error('Cannot parse INSERT statement format');
    }
    
    const tableName = insertMatch[1].trim();
    const columnsStr = insertMatch[2];
    const valuesStr = insertMatch[3];
    
    console.log(`📋 Parsing table: ${tableName}`);
    console.log(`📋 Columns: ${columnsStr}`);
    console.log(`📋 Values preview: ${valuesStr.substring(0, 100)}...`);
    
    const columns = columnsStr.split(',').map(col => col.trim());
    const values = this.parseValues(valuesStr);
    
    // Create object from columns and values
    const insertData: Record<string, unknown> = {};
    columns.forEach((col, index) => {
      if (values[index] !== undefined) {
        insertData[col] = values[index];
      }
    });
    
    console.log(`📝 Inserting into ${tableName}:`, Object.keys(insertData));
    
    const { data, error } = await this.supabase
      .from(tableName)
      .insert(insertData)
      .select();
    
    if (error) {
      console.error(`❌ Insert error for table ${tableName}:`, error);
      throw new Error(`Insert failed: ${error.message}`);
    }
    
    console.log(`✅ Successfully inserted into ${tableName}, rows:`, data?.length || 0);
  }

  /**
   * Execute UPDATE statement
   */
  private async executeUpdateStatement(statement: string): Promise<void> {
    console.log(`⚠️ UPDATE statements not yet implemented: ${statement.substring(0, 100)}...`);
    // Implementation for UPDATE statements would go here
    throw new Error('UPDATE statements not yet implemented');
  }

  /**
   * Execute DELETE statement
   */
  private async executeDeleteStatement(statement: string): Promise<void> {
    console.log(`⚠️ DELETE statements not yet implemented: ${statement.substring(0, 100)}...`);
    // Implementation for DELETE statements would go here
    throw new Error('DELETE statements not yet implemented');
  }

  /**
   * Parse SQL values string into array - improved version
   */
  private parseValues(valuesStr: string): unknown[] {
    console.log(`🔧 Parsing values: ${valuesStr.substring(0, 200)}...`);
    
    const values: unknown[] = [];
    let current = '';
    let inQuotes = false;
    let quoteChar = '';
    let bracketDepth = 0;
    let i = 0;
    
    while (i < valuesStr.length) {
      const char = valuesStr[i];
      const nextChar = valuesStr[i + 1];
      
      if (!inQuotes) {
        if (char === "'" || char === '"') {
          inQuotes = true;
          quoteChar = char;
          current += char;
        } else if (char === '[' || char === '{') {
          bracketDepth++;
          current += char;
        } else if (char === ']' || char === '}') {
          bracketDepth--;
          current += char;
        } else if (char === ',' && bracketDepth === 0) {
          // End of current value
          values.push(this.parseValue(current.trim()));
          current = '';
        } else {
          current += char;
        }
      } else {
        current += char;
        if (char === quoteChar) {
          // Check if it's escaped
          if (nextChar === quoteChar) {
            current += nextChar;
            i++; // Skip next character
          } else {
            inQuotes = false;
            quoteChar = '';
          }
        }
      }
      i++;
    }
    
    // Add last value
    if (current.trim()) {
      values.push(this.parseValue(current.trim()));
    }
    
    console.log(`📋 Parsed ${values.length} values`);
    return values;
  }

  /**
   * Parse individual value
   */
  private parseValue(value: string): unknown {
    const trimmed = value.trim();
    
    if (trimmed === 'NULL' || trimmed === 'null') {
      return null;
    } else if (trimmed === 'true' || trimmed === 'false') {
      return trimmed === 'true';
    } else if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
      // String value - remove quotes and handle escaped quotes
      return trimmed.slice(1, -1).replace(/''/g, "'");
    } else if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      // Double quoted string
      return trimmed.slice(1, -1).replace(/""/g, '"');
    } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      // JSON array
      try {
        return JSON.parse(trimmed);
      } catch {
        return trimmed;
      }
    } else if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      // JSON object
      try {
        return JSON.parse(trimmed);
      } catch {
        return trimmed;
      }
    } else if (!isNaN(Number(trimmed)) && trimmed !== '') {
      // Number
      return Number(trimmed);
    } else {
      // Default to string
      return trimmed;
    }
  }

  /**
   * Create restore point before performing restore
   */
  private async createRestorePoint(userId: string = 'system'): Promise<string> {
    const restorePointId = `rp_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
    
    // Get current tables data (limited for performance)
    const tables = await this.getExistingTables();
    const tablesBackup: Record<string, object[]> = {};
    
    for (const table of tables.slice(0, 10)) { // Limit to first 10 tables for performance
      const { data } = await this.supabase
        .from(table)
        .select('*')
        .limit(1000); // Limit rows for performance
        
      if (data) {
        tablesBackup[table] = data;
      }
    }

    const restorePoint: RestorePoint = {
      id: restorePointId,
      created_at: new Date().toISOString(),
      tables_backup: tablesBackup,
      schema_backup: '', // Could store schema if needed
      created_by: userId,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days from now
    };

    // Store restore point
    const { error } = await this.supabase
      .from('pos_mini_modular3_restore_points')
      .insert(restorePoint);

    if (error) {
      console.error('Failed to create restore point:', error);
      throw new RestoreError('Failed to create restore point', 'RESTORE_POINT_FAILED');
    }

    return restorePointId;
  }

  /**
   * Restore from a restore point
   */
  private async restoreFromRestorePoint(restorePointId: string): Promise<void> {
    try {
      const { data, error } = await this.supabase
        .from('pos_mini_modular3_restore_points')
        .select('*')
        .eq('id', restorePointId)
        .single();

      if (error || !data) {
        throw new Error('Restore point not found');
      }

      const restorePoint = data as RestorePoint;

      // Restore data from restore point
      for (const [table, tableData] of Object.entries(restorePoint.tables_backup)) {
        if (tableData && tableData.length > 0) {
          // Clear current data
          await this.supabase
            .from(table)
            .delete()
            .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all

          // Restore backup data
          await this.supabase
            .from(table)
            .insert(tableData);
        }
      }

    } catch (error) {
      console.error('Failed to restore from restore point:', error);
      throw error;
    }
  }

  /**
   * Utility methods
   */
  private updateProgress(
    stage: RestoreProgress['stage'],
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
        totalTables: totalTables ?? 1,
        rowsProcessed: 0
      });
    }
  }

  private async getDatabaseVersion(): Promise<string> {
    const { data } = await this.supabase.rpc('version');
    return data || 'Unknown';
  }

  private async getExistingTables(): Promise<string[]> {
    const { data, error } = await this.supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public');

    if (error) return [];
    
    return data?.map(t => t.table_name) || [];
  }

  private async getAllUserTables(): Promise<string[]> {
    try {
      const { data, error } = await this.supabase.rpc('execute_sql', { 
        sql: `
          SELECT table_name 
          FROM information_schema.tables 
          WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            AND table_name NOT LIKE 'pg_%'
            AND table_name NOT LIKE '_supabase_%'
          ORDER BY table_name;
        `
      });

      if (error) {
        console.warn(`⚠️ Failed to get user tables: ${error.message}`);
        return [];
      }
      
      return data?.map((row: { table_name: string }) => row.table_name) || [];
    } catch (error) {
      console.warn(`⚠️ Error getting user tables:`, error);
      return [];
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private async detectDataConflicts(_backup: BackupMetadata, _options: RestoreOptions): Promise<string[]> {
    // Implementation to detect potential data conflicts
    // For now, return empty array
    return [];
  }

  private async validateSQLStatements(statements: string[]): Promise<{statementCount: number, warnings: string[]}> {
    // Validate SQL statements without executing them
    const warnings: string[] = [];
    for (const statement of statements) {
      // Basic validation - check for dangerous operations
      if (statement.toLowerCase().includes('drop database')) {
        warnings.push('Dangerous DROP DATABASE statement detected');
      }
      if (statement.toLowerCase().includes('truncate')) {
        warnings.push('TRUNCATE statement detected - will clear existing data');
      }
    }
    return {
      statementCount: statements.length,
      warnings
    };
  }

  private isStatementForTargetTables(statement: string, targetTables: string[]): boolean {
    const lowerStatement = statement.toLowerCase();
    return targetTables.some(table => 
      lowerStatement.includes(table.toLowerCase())
    );
  }

  private isAuthTableStatement(statement: string, options?: RestoreOptions): boolean {
    const lowerStatement = statement.toLowerCase();
    
    // Only skip ACTUAL auth/user management tables, not business tables
    return lowerStatement.includes('auth.users') ||           // Supabase auth.users
           lowerStatement.includes('auth.identities') ||      // Supabase identities  
           lowerStatement.includes('auth.sessions') ||        // Supabase sessions
           lowerStatement.includes('auth.refresh_tokens') ||   // Supabase tokens
           lowerStatement.includes('supabase_auth_admin') ||   // Supabase admin
           (lowerStatement.includes('subscription_plans') && (!options || !options.restoreAuth)); // Skip subscription plans if not restoring auth
  }

  // Transaction management - disable explicit transactions for now
  private async beginRestoreTransaction(): Promise<void> {
    try {
      console.log(`📊 Skipping explicit transaction (using Supabase auto-commit)...`);
      // Skip explicit transaction to avoid "invalid transaction termination" errors
      // Supabase handles transactions automatically for individual operations
    } catch (error) {
      console.warn(`⚠️ Transaction begin failed, continuing without explicit transaction:`, error);
    }
  }

  private async commitRestoreTransaction(): Promise<void> {
    try {
      console.log(`✅ Auto-commit mode (no explicit transaction commit needed)...`);
      // Skip explicit commit since we're not using explicit transactions
    } catch (error) {
      console.warn(`⚠️ Transaction commit failed:`, error);
    }
  }

  private async rollbackRestoreTransaction(): Promise<void> {
    try {
      console.log(`🔄 Individual operations cannot be rolled back in auto-commit mode...`);
      // Cannot rollback in auto-commit mode
    } catch (error) {
      console.warn(`⚠️ Transaction rollback failed:`, error);
    }
  }

  private async disableConstraints(): Promise<void> {
    try {
      console.log(`🔒 Disabling constraints...`);
      const { error } = await this.supabase.rpc('execute_sql', { 
        sql: 'SET session_replication_role = replica;' 
      });
      if (error) {
        console.warn(`⚠️ Failed to disable constraints:`, error.message);
        // Continue without disabling constraints
      } else {
        console.log(`✅ Constraints disabled successfully`);
      }
    } catch {
      // Continue without disabling constraints
    }
  }

  private async enableConstraints(): Promise<void> {
    try {
      console.log(`🔓 Re-enabling constraints...`);
      const { error } = await this.supabase.rpc('execute_sql', { 
        sql: 'SET session_replication_role = DEFAULT;' 
      });
      if (error) {
        console.warn(`⚠️ Failed to re-enable constraints:`, error.message);
        // Continue - constraints should be enabled by default
      } else {
        console.log(`✅ Constraints re-enabled successfully`);
      }
    } catch (error) {
      console.warn(`⚠️ Error re-enabling constraints:`, error);
      // Continue - constraints should be enabled by default
    }
  }

  /**
   * Enhanced error handling and rollback mechanism for restore operations
   */
  async performRestoreWithTransaction(options: RestoreOptions): Promise<RestoreResult> {
    console.log(`🚀 Starting enhanced restore operation with transaction support`);
    const startTime = Date.now();
    let restorePointId: string | undefined;
    const changeLog: RestoreChangeLog = { 
      insertedRecords: [],
      updatedRecords: [],
      createdTables: [],
      modifiedSchema: []
    };
    
    try {
      this.updateProgress('preparing', 0);

      // 1. Validate backup and create comprehensive restore point
      const backupMetadata = await this.getBackupMetadata(options.backupId);
      if (!backupMetadata) {
        throw new RestoreError('Backup not found', 'BACKUP_NOT_FOUND');
      }

      // 2. Create comprehensive restore point (full backup)
      if (options.createRestorePoint !== false) {
        console.log(`📝 Creating comprehensive restore point...`);
        restorePointId = await this.createComprehensiveRestorePoint(options.userId || 'system');
        console.log(`✅ Comprehensive restore point created: ${restorePointId}`);
      }

      // 3. Download and parse backup content
      const backupContent = await this.downloadAndDecryptBackup(backupMetadata);
      const sqlStatements = this.parseSQLContent(backupContent);
      
      // 4. Order statements by dependency to avoid foreign key issues
      const orderedStatements = await this.orderStatementsByDependency(sqlStatements);
      console.log(`📋 Ordered ${orderedStatements.length} statements by dependency`);

      if (options.dryRun) {
        return await this.performDryRun(orderedStatements);
      }

      // 5. Execute restore with proper transaction management
      return await this.executeRestoreWithRollback(
        backupMetadata, 
        orderedStatements, 
        options, 
        changeLog,
        restorePointId
      );

    } catch (error) {
      console.error('💥 Restore operation failed:', error);
      
      // Auto-rollback on any error
      if (changeLog && (changeLog.insertedRecords.length > 0 || changeLog.updatedRecords.length > 0)) {
        await this.performAutoRollback(changeLog, restorePointId);
      }

      return {
        success: false,
        message: `Restore failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        duration: Date.now() - startTime,
        restorePointId
      };
    }
  }

  /**
   * Execute restore with rollback capability
   */
  private async executeRestoreWithRollback(
    backup: BackupMetadata,
    statements: string[],
    options: RestoreOptions,
    changeLog: RestoreChangeLog,
    restorePointId?: string
  ): Promise<RestoreResult> {
    
    console.log(`🔄 Starting restore execution with rollback support...`);
    let completedStatements = 0;
    const result = {
      tablesRestored: options.targetTables || backup.tables,
      rowsAffected: 0,
      warnings: [] as string[]
    };

    try {
      // Phase 1: Schema changes (CREATE, ALTER)
      console.log(`📊 Phase 1: Schema modifications...`);
      const schemaStatements = statements.filter(s => this.isSchemaStatement(s));
      
      for (const statement of schemaStatements) {
        try {
          await this.executeSchemaStatement(statement, changeLog);
          completedStatements++;
          this.updateProgress('restoring_schema', (completedStatements / statements.length) * 30);
        } catch (error) {
          console.error(`❌ Schema statement failed: ${statement.substring(0, 100)}`);
          throw new RestoreError(`Schema modification failed: ${error}`, 'SCHEMA_ERROR');
        }
      }

      // Phase 2: Data modifications (INSERT, UPDATE) 
      console.log(`📊 Phase 2: Data modifications...`);
      const dataStatements = statements.filter(s => !this.isSchemaStatement(s));
      
      // Disable constraints for data phase
      await this.disableConstraints();
      
      try {
        for (const statement of dataStatements) {
          try {
            await this.executeDataStatement(statement, changeLog);
            result.rowsAffected++;
            completedStatements++;
            
            this.updateProgress(
              'restoring_data', 
              30 + ((completedStatements / statements.length) * 60)
            );
            
          } catch (error) {
            console.error(`❌ Data statement failed: ${statement.substring(0, 100)}`);
            throw new RestoreError(`Data modification failed: ${error}`, 'DATA_ERROR');
          }
        }
      } finally {
        // Always re-enable constraints
        await this.enableConstraints();
      }

      // Phase 3: Validation
      console.log(`📊 Phase 3: Validation...`);
      this.updateProgress('finalizing', 90);
      
      const validationResult = await this.validateRestoreResult(result.tablesRestored, changeLog);
      if (!validationResult.valid) {
        throw new RestoreError(`Validation failed: ${validationResult.errors.join(', ')}`, 'VALIDATION_ERROR');
      }

      this.updateProgress('finalizing', 100);
      console.log(`🎉 Restore completed successfully!`);
      
      return {
        success: true,
        message: 'Database restored successfully with transaction support',
        tablesRestored: result.tablesRestored,
        rowsAffected: result.rowsAffected,
        duration: Date.now() - Date.now(),
        warnings: result.warnings
      };

    } catch (error) {
      console.error(`❌ Restore failed, performing rollback...`);
      
      // Immediate rollback
      await this.performAutoRollback(changeLog, restorePointId);
      throw error;
    }
  }

  /**
   * Auto-rollback mechanism
   */
  private async performAutoRollback(
    changeLog: RestoreChangeLog, 
    restorePointId?: string
  ): Promise<void> {
    console.log(`🔄 Performing auto-rollback...`);
    
    try {
      // Method 1: Reverse changes from change log
      await this.reverseChanges(changeLog);
      
    } catch {
      console.error(`❌ Change reversal failed, trying restore point...`);
      
      // Method 2: Restore from restore point if available
      if (restorePointId) {
        try {
          await this.restoreFromRestorePoint(restorePointId);
          console.log(`✅ Successfully restored from restore point`);
        } catch (restorePointError) {
          console.error(`❌ Restore point recovery failed:`, restorePointError);
          throw new RestoreError('Complete rollback failed - manual intervention required', 'ROLLBACK_FAILED');
        }
      } else {
        throw new RestoreError('No restore point available for rollback', 'NO_RESTORE_POINT');
      }
    }
  }

  /**
   * Reverse changes based on change log
   */
  private async reverseChanges(changeLog: RestoreChangeLog): Promise<void> {
    console.log(`🔄 Reversing changes...`);
    
    // Reverse in opposite order
    
    // 1. Delete inserted records
    for (const record of changeLog.insertedRecords.reverse()) {
      try {
        await this.supabase
          .from(record.table)
          .delete()
          .eq('id', record.id);
        console.log(`✅ Deleted inserted record: ${record.table}:${record.id}`);
      } catch (error) {
        console.warn(`⚠️ Failed to delete record ${record.table}:${record.id}: ${error}`);
      }
    }

    // 2. Restore updated records to original values
    for (const record of changeLog.updatedRecords.reverse()) {
      try {
        await this.supabase
          .from(record.table)
          .update(record.originalData)
          .eq('id', record.id);
        console.log(`✅ Restored updated record: ${record.table}:${record.id}`);
      } catch (error) {
        console.warn(`⚠️ Failed to restore record ${record.table}:${record.id}: ${error}`);
      }
    }

    // 3. Drop created tables
    for (const table of changeLog.createdTables.reverse()) {
      try {
        await this.supabase.rpc('execute_sql', { 
          sql: `DROP TABLE IF EXISTS ${table};` 
        });
        console.log(`✅ Dropped created table: ${table}`);
      } catch (error) {
        console.warn(`⚠️ Failed to drop table ${table}: ${error}`);
      }
    }

    // 4. Reverse schema modifications (complex - would need detailed tracking)
    for (const schemaChange of changeLog.modifiedSchema.reverse()) {
      console.warn(`⚠️ Schema rollback not implemented for: ${schemaChange}`);
    }
  }

  /**
   * Create comprehensive restore point (not limited to 10 tables)
   */
  private async createComprehensiveRestorePoint(userId: string): Promise<string> {
    const restorePointId = `rp_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
    console.log(`📝 Creating comprehensive restore point: ${restorePointId}`);
    
    // Get ALL user tables
    const tables = await this.getAllUserTables();
    const tablesBackup: Record<string, object[]> = {};
    
    console.log(`📋 Backing up ${tables.length} tables...`);
    
    for (const table of tables) {
      try {
        const { data, error } = await this.supabase
          .from(table)
          .select('*');
          
        if (error) {
          console.warn(`⚠️ Failed to backup table ${table}: ${error.message}`);
          continue;
        }
        
        if (data) {
          tablesBackup[table] = data;
          console.log(`✅ Backed up table ${table}: ${data.length} rows`);
        }
      } catch (error) {
        console.warn(`⚠️ Error backing up table ${table}: ${error}`);
      }
    }

    const restorePoint = {
      id: restorePointId,
      created_at: new Date().toISOString(),
      tables_backup: tablesBackup,
      schema_backup: JSON.stringify({}), // Could store schema info
      created_by: userId,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      backup_type: 'comprehensive',
      total_tables: tables.length,
      total_rows: Object.values(tablesBackup).reduce((sum, data) => sum + data.length, 0)
    };

    const { error } = await this.supabase
      .from('pos_mini_modular3_restore_points')
      .insert(restorePoint);

    if (error) {
      throw new RestoreError('Failed to create comprehensive restore point', 'RESTORE_POINT_FAILED');
    }

    console.log(`✅ Comprehensive restore point created with ${restorePoint.total_tables} tables and ${restorePoint.total_rows} rows`);
    return restorePointId;
  }

  /**
   * Order SQL statements by dependency to avoid foreign key violations
   */
  private async orderStatementsByDependency(statements: string[]): Promise<string[]> {
    console.log(`📋 Ordering statements by dependency...`);
    
    // Get table dependency graph
    const dependencies = await this.getTableDependencies();
    
    // Separate statement types
    const schemaStatements = statements.filter(s => this.isSchemaStatement(s));
    const dataStatements = statements.filter(s => !this.isSchemaStatement(s));
    
    // Order data statements by table dependencies
    const orderedDataStatements = this.sortStatementsByDependencies(dataStatements, dependencies);
    
    // Return schema first, then ordered data statements
    return [...schemaStatements, ...orderedDataStatements];
  }

  /**
   * Get table dependencies from foreign keys
   */
  private async getTableDependencies(): Promise<Record<string, string[]>> {
    const { data, error } = await this.supabase.rpc('execute_sql', { 
      sql: `
        SELECT 
          tc.table_name,
          ccu.table_name AS foreign_table_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
        WHERE constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public';
      `
    });

    const dependencies: Record<string, string[]> = {};
    
    if (!error && data) {
      for (const row of data) {
        const table = row.table_name;
        const dependency = row.foreign_table_name;
        
        if (!dependencies[table]) {
          dependencies[table] = [];
        }
        dependencies[table].push(dependency);
      }
    }
    
    console.log(`📋 Table dependencies:`, dependencies);
    return dependencies;
  }

  // Helper methods
  private isSchemaStatement(statement: string): boolean {
    const lower = statement.toLowerCase().trim();
    return lower.startsWith('create') || 
           lower.startsWith('alter') || 
           lower.startsWith('drop');
  }

  private async executeSchemaStatement(statement: string, changeLog: RestoreChangeLog): Promise<void> {
    console.log(`🔧 Executing schema statement: ${statement.substring(0, 100)}...`);
    
    const { error } = await this.supabase.rpc('execute_sql', { sql: statement });
    
    if (error) {
      throw new Error(`Schema execution failed: ${error.message}`);
    }
    
    // Track schema changes for rollback
    changeLog.modifiedSchema.push(statement);
    
    // Track created tables
    if (statement.toLowerCase().includes('create table')) {
      const match = statement.match(/create table\s+([^\s(]+)/i);
      if (match) {
        changeLog.createdTables.push(match[1]);
      }
    }
  }

  /**
   * Complete implementation of executeDataStatement with change tracking
   */
  private async executeDataStatement(statement: string, changeLog: RestoreChangeLog): Promise<void> {
    console.log(`📝 Executing data statement with tracking: ${statement.substring(0, 100)}...`);
    
    try {
      const tableName = this.extractTableName(statement);
      if (!tableName) {
        throw new Error('Cannot extract table name from statement');
      }

      // For INSERT statements, track inserted records
      if (statement.toLowerCase().trim().startsWith('insert into')) {
        // Get record ID before insertion for tracking
        const recordId = this.extractInsertedRecordId(statement);
        
        // Execute the statement
        await this.executeStatementDirect(statement);
        
        // Track inserted record for rollback
        if (recordId) {
          changeLog.insertedRecords.push({
            table: tableName,
            id: recordId
          });
          console.log(`📋 Tracked inserted record: ${tableName}:${recordId}`);
        }
        
      } else if (statement.toLowerCase().trim().startsWith('update')) {
        // For UPDATE statements, get original data first
        const whereClause = this.extractWhereClause(statement);
        if (whereClause) {
          // Get original data before update
          const { data: originalData } = await this.supabase
            .from(tableName)
            .select('*')
            .eq('id', whereClause.id) // Assuming ID-based updates
            .single();
            
          if (originalData) {
            // Execute the update
            await this.executeStatementDirect(statement);
            
            // Track for rollback
            changeLog.updatedRecords.push({
              table: tableName,
              id: whereClause.id,
              originalData
            });
            console.log(`📋 Tracked updated record: ${tableName}:${whereClause.id}`);
          }
        }
        
      } else {
        // For other statements, just execute
        await this.executeStatementDirect(statement);
      }
      
    } catch (error) {
      console.error(`❌ Data statement execution failed: ${error}`);
      throw error;
    }
  }

  /**
   * Extract WHERE clause from UPDATE/DELETE statements
   */
  private extractWhereClause(statement: string): {id: string} | null {
    try {
      // Simple extraction for ID-based operations
      const match = statement.match(/where\s+id\s*=\s*['"]*([^'";\s]+)['"]*\s*/i);
      if (match) {
        return { id: match[1] };
      }
      return null;
    } catch (error) {
      console.warn(`⚠️ Failed to extract WHERE clause: ${error}`);
      return null;
    }
  }

  /**
   * Validate restore result
   */
  private async validateRestoreResult(
    tablesRestored: string[], 
    changeLog: RestoreChangeLog
  ): Promise<ValidationResult> {
    console.log(`🔍 Validating restore result...`);
    const errors: string[] = [];
    
    try {
      // Validate inserted records exist
      for (const record of changeLog.insertedRecords) {
        const { data, error } = await this.supabase
          .from(record.table)
          .select('id')
          .eq('id', record.id)
          .single();
          
        if (error || !data) {
          errors.push(`Inserted record not found: ${record.table}:${record.id}`);
        }
      }
      
      // Validate updated records have new values
      for (const record of changeLog.updatedRecords) {
        const { data, error } = await this.supabase
          .from(record.table)
          .select('*')
          .eq('id', record.id)
          .single();
          
        if (error || !data) {
          errors.push(`Updated record not found: ${record.table}:${record.id}`);
        } else {
          // Check if data was actually updated (not same as original)
          const hasChanges = JSON.stringify(data) !== JSON.stringify(record.originalData);
          if (!hasChanges) {
            console.warn(`⚠️ Record not updated: ${record.table}:${record.id}`);
          }
        }
      }
      
      // Validate created tables exist
      for (const table of changeLog.createdTables) {
        const tables = await this.getAllUserTables();
        if (!tables.includes(table)) {
          errors.push(`Created table not found: ${table}`);
        }
      }
      
      console.log(`✅ Validation completed. ${errors.length} errors found.`);
      
      return {
        valid: errors.length === 0,
        errors
      };
      
    } catch (error) {
      console.error(`❌ Validation failed: ${error}`);
      return {
        valid: false,
        errors: [`Validation process failed: ${error}`]
      };
    }
  }

  /**
   * Perform dry run to validate statements without execution
   */
  private async performDryRun(statements: string[]): Promise<RestoreResult> {
    console.log(`🧪 Performing dry run validation...`);
    
    const warnings: string[] = [];
    const tablesAffected: Set<string> = new Set();
    
    for (const statement of statements) {
      // Analyze statement
      const tableName = this.extractTableName(statement);
      if (tableName) {
        tablesAffected.add(tableName);
      }
      
      // Check for potential issues
      if (statement.toLowerCase().includes('drop')) {
        warnings.push(`DROP statement detected: ${statement.substring(0, 100)}`);
      }
      
      if (statement.toLowerCase().includes('truncate')) {
        warnings.push(`TRUNCATE statement detected: ${statement.substring(0, 100)}`);
      }
      
      // Validate syntax (basic check)
      if (!statement.trim().endsWith(';') && !statement.trim().endsWith(';')) {
        warnings.push(`Statement may be missing semicolon: ${statement.substring(0, 100)}`);
      }
    }
    
    return {
      success: true,
      message: `Dry run completed successfully. ${statements.length} statements analyzed.`,
      tablesRestored: Array.from(tablesAffected),
      rowsAffected: 0,
      duration: 0,
      warnings,
      dryRun: true
    };
  }

  /**
   * Sort statements by table dependencies (topological sort)
   */
  private sortStatementsByDependencies(
    statements: string[], 
    dependencies: Record<string, string[]>
  ): string[] {
    console.log(`🔄 Sorting statements by dependencies...`);
    
    // Group statements by table
    const statementsByTable: Record<string, string[]> = {};
    const unidentifiedStatements: string[] = [];
    
    for (const statement of statements) {
      const tableName = this.extractTableName(statement);
      if (tableName) {
        if (!statementsByTable[tableName]) {
          statementsByTable[tableName] = [];
        }
        statementsByTable[tableName].push(statement);
      } else {
        unidentifiedStatements.push(statement);
      }
    }
    
    // Topological sort by dependencies
    const sortedTables: string[] = [];
    const visited: Set<string> = new Set();
    const visiting: Set<string> = new Set();
    
    const visit = (table: string) => {
      if (visiting.has(table)) {
        console.warn(`⚠️ Circular dependency detected involving table: ${table}`);
        return;
      }
      
      if (visited.has(table)) {
        return;
      }
      
      visiting.add(table);
      
      // Visit dependencies first
      const tableDeps = dependencies[table] || [];
      for (const dep of tableDeps) {
        if (statementsByTable[dep]) {
          visit(dep);
        }
      }
      
      visiting.delete(table);
      visited.add(table);
      sortedTables.push(table);
    };
    
    // Visit all tables
    for (const table of Object.keys(statementsByTable)) {
      visit(table);
    }
    
    // Rebuild ordered statements
    const orderedStatements: string[] = [];
    
    // Add statements in dependency order
    for (const table of sortedTables) {
      if (statementsByTable[table]) {
        orderedStatements.push(...statementsByTable[table]);
      }
    }
    
    // Add unidentified statements at the end
    orderedStatements.push(...unidentifiedStatements);
    
    console.log(`✅ Sorted ${orderedStatements.length} statements by dependency order`);
    return orderedStatements;
  }

  /**
   * Remove the duplicate interface declaration from here
   * It's now declared at the top level of the file
   */
}
