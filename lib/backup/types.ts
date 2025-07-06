/**
 * ==================================================================================
 * BACKUP/RESTORE SYSTEM TYPES
 * ==================================================================================
 * Professional backup and restore system for POS Mini Modular 3
 * Created: July 3, 2025
 */

export interface BackupConfig {
  type: 'full' | 'incremental' | 'schema' | 'data';
  compression: 'gzip' | 'lz4' | 'none';
  encryption: boolean;
  retention: number; // days
  schedule?: string; // cron expression
  tables?: string[]; // specific tables for selective backup
  excludeTables?: string[]; // tables to exclude
  lastBackupTime?: string; // for incremental backups
}

export interface BackupMetadata {
  id: string;
  filename: string;
  type: BackupConfig['type'];
  size: number; // bytes
  checksum: string; // SHA256 hash
  created_at: string;
  version: string; // database version
  tables: string[];
  compressed: boolean;
  encrypted: boolean;
  storage_path: string;
  retention_until: string;
  status: 'creating' | 'completed' | 'failed' | 'expired';
  error_message?: string;
  created_by: string; // user ID
}

export interface RestoreOptions {
  backupId: string;
  targetTables?: string[]; // specific tables to restore
  restoreAuth?: boolean; // whether to restore auth tables
  dryRun?: boolean; // validate only, don't execute
  pointInTime?: string; // for point-in-time recovery
  overwriteExisting?: boolean;
  createRestorePoint?: boolean;
  userId?: string; // Add userId field
}

export interface RestoreResult {
  success: boolean;
  message: string;
  tablesRestored?: string[];
  rowsAffected?: number;
  duration?: number; // milliseconds
  warnings?: string[];
  restorePointId?: string;
  dryRun?: boolean; // indicates if this was a dry run operation
}

export interface BackupHealthReport {
  lastBackup: string | null;
  lastSuccessfulBackup: string | null;
  missedBackups: number;
  corruptedBackups: string[];
  storageUsage: {
    totalSize: number;
    availableSpace: number;
    oldestBackup: string;
    newestBackup: string;
  };
  warnings: string[];
  errors: string[];
  recommendations: string[];
}

export interface BackupProgress {
  stage: 'preparing' | 'exporting_schema' | 'exporting_data' | 'compressing' | 'encrypting' | 'uploading' | 'finalizing';
  progress: number; // 0-100
  currentTable?: string;
  tablesCompleted: number;
  totalTables: number;
  estimatedTimeRemaining?: number; // seconds
}

export interface RestoreProgress {
  stage: 'validating' | 'preparing' | 'restoring_schema' | 'restoring_data' | 'finalizing';
  progress: number; // 0-100
  currentTable?: string;
  tablesCompleted: number;
  totalTables: number;
  rowsProcessed: number;
  estimatedTimeRemaining?: number; // seconds
}

export interface TableExportInfo {
  name: string;
  rowCount: number;
  estimatedSize: number;
  dependencies: string[];
  exportOrder: number;
}

export interface BackupSchedule {
  id: string;
  name: string;
  config: BackupConfig;
  cronExpression: string;
  enabled: boolean;
  lastRun?: string;
  nextRun: string;
  failureCount: number;
  lastError?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

// Storage provider types
export interface StorageProvider {
  name: string;
  upload(filename: string, content: Buffer): Promise<string>;
  download(filename: string): Promise<Buffer>;
  delete(filename: string): Promise<void>;
  list(prefix?: string): Promise<StorageFile[]>;
  getUrl(filename: string): Promise<string>;
  getSize(filename: string): Promise<number>;
}

export interface StorageFile {
  name: string;
  size: number;
  lastModified: string;
  url?: string;
}

// Notification types
export interface BackupNotification {
  type: 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: string;
  backupId?: string;
  details?: Record<string, unknown>;
}

// Database schema types
export interface TableSchema {
  name: string;
  columns: ColumnInfo[];
  indexes: IndexInfo[];
  constraints: ConstraintInfo[];
  triggers: TriggerInfo[];
}

export interface ColumnInfo {
  name: string;
  type: string;
  nullable: boolean;
  default?: string;
  isPrimaryKey: boolean;
  isForeignKey: boolean;
  references?: {
    table: string;
    column: string;
  };
}

export interface IndexInfo {
  name: string;
  columns: string[];
  unique: boolean;
  type: string;
}

export interface ConstraintInfo {
  name: string;
  type: 'PRIMARY KEY' | 'FOREIGN KEY' | 'UNIQUE' | 'CHECK';
  definition: string;
}

export interface TriggerInfo {
  name: string;
  event: string;
  timing: 'BEFORE' | 'AFTER';
  definition: string;
}

// Error types
export class BackupError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'BackupError';
  }
}

export class RestoreError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'RestoreError';
  }
}

// Configuration constants
export const BACKUP_CONFIG = {
  MAX_FILE_SIZE: 1024 * 1024 * 1024, // 1GB
  DEFAULT_RETENTION_DAYS: 30,
  MAX_CONCURRENT_OPERATIONS: 3,
  COMPRESSION_LEVEL: 6,
  ENCRYPTION_ALGORITHM: 'aes-256-gcm',
  CHUNK_SIZE: 1024 * 1024, // 1MB chunks for large operations
  BACKUP_TABLE_PREFIX: 'pos_mini_modular3_',
  EXCLUDED_TABLES: [
    'auth.users',
    'auth.sessions', 
    'storage.objects',
    '_realtime_'
  ],
  SYSTEM_TABLES: [
    'pos_mini_modular3_businesses',
    'pos_mini_modular3_user_profiles',
    'pos_mini_modular3_subscription_plans',
    'pos_mini_modular3_business_types'
  ]
} as const;
