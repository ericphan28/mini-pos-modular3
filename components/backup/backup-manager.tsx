/**
 * ==================================================================================
 * MODERN BACKUP MANAGER COMPONENT
 * ==================================================================================
 * Professional backup and restore interface for Super Admin
 */

'use client';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { useToast } from '@/hooks/use-toast';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';
import {
    AlertTriangle,
    Calendar,
    CheckCircle,
    Clock,
    Database,
    Download,
    FileText,
    HardDrive,
    RefreshCw,
    Shield,
    Zap
} from 'lucide-react';

import { useCallback, useEffect, useState } from 'react';

interface BackupMetadata {
  id: string;
  filename: string;
  type: 'full' | 'incremental' | 'schema' | 'data';
  size: number;
  created_at: string;
  compressed: boolean;
  encrypted: boolean;
  status: 'creating' | 'completed' | 'failed' | 'expired';
  created_by: string;
}

interface BackupProgress {
  stage: string;
  progress: number;
  currentTable?: string;
  tablesCompleted: number;
  totalTables: number;
}

export function BackupManager() {
  const [backups, setBackups] = useState<BackupMetadata[]>([]);
  const [isCreating, setIsCreating] = useState(false);
  const [progress, setProgress] = useState<BackupProgress | null>(null);
  // Removed unused: selectedBackupType, setSelectedBackupType
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  // useCallback to ensure stable reference for useEffect dependency
  const fetchBackups = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/admin/backup');
      const data = await response.json();
      if (data.success) {
        setBackups(data.backups);
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      toast({
        title: 'Lỗi tải danh sách backup',
        description: error instanceof Error ? error.message : 'Không thể tải danh sách backup',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchBackups();
  }, [fetchBackups]);

  const createBackup = async (type: 'full' | 'incremental' | 'schema' | 'data', lastBackupTime?: string) => {
    try {
      setIsCreating(true);
      setProgress({
        stage: 'preparing',
        progress: 0,
        tablesCompleted: 0,
        totalTables: 1
      });

      const response = await fetch('/api/admin/backup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          type,
          compression: 'gzip',
          encryption: true,
          retention: 30,
          lastBackupTime: lastBackupTime
        })
      });

      const data = await response.json();

      if (data.success) {
        toast({
          title: '✅ Backup thành công!',
          description: `Backup ${type} đã được tạo thành công`,
        });
        
        await fetchBackups(); // Refresh list
      } else {
        throw new Error(data.error);
      }

    } catch (error) {
      toast({
        title: '❌ Lỗi tạo backup',
        description: error instanceof Error ? error.message : 'Không thể tạo backup',
        variant: 'destructive'
      });
    } finally {
      setIsCreating(false);
      setProgress(null);
    }
  };

  const exportSQLScript = async () => {
    try {
      setIsCreating(true);
      setProgress({
        stage: 'exporting_sql',
        progress: 10,
        tablesCompleted: 0,
        totalTables: 1
      });

      console.log('🚀 Starting Export SQL API call...');

      const response = await fetch('/api/admin/backup/export-sql', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          includeSchema: true,
          includeData: true,
          format: 'supabase' // Format tối ưu cho Supabase SQL Editor
        })
      });

      console.log('📊 Response status:', response.status);
      console.log('📊 Response headers:', Object.fromEntries(response.headers.entries()));

      setProgress(prev => prev ? { ...prev, progress: 50 } : null);

      // Check content type
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const textResponse = await response.text();
        console.error('❌ Response is not JSON:', textResponse.substring(0, 500));
        throw new Error(`Server returned ${contentType || 'unknown content type'}: ${textResponse.substring(0, 200)}...`);
      }

      const data = await response.json();
      console.log('📋 Export SQL Response:', { 
        success: data.success, 
        error: data.error, 
        scriptLength: data.sqlScript?.length,
        exportInfo: data.exportInfo 
      });

      setProgress(prev => prev ? { ...prev, progress: 80 } : null);

      if (data.success) {
        // Create and download SQL file
        const sqlContent = data.sqlScript;
        const blob = new Blob([sqlContent], { type: 'text/sql;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `pos-mini-backup-${new Date().toISOString().slice(0, 19).replace(/[:.]/g, '-')}.sql`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

        setProgress(prev => prev ? { ...prev, progress: 100 } : null);

        console.log('✅ SQL Export completed successfully!');
        console.log(`📄 Script details:`, {
          size: `${sqlContent.length} characters`,
          lines: sqlContent.split('\n').length,
          preview: sqlContent.substring(0, 300) + '...'
        });

        toast({
          title: '✅ Export SQL thành công!',
          description: `File SQL đã được tải xuống (${Math.round(sqlContent.length/1024)} KB). Bạn có thể chạy trực tiếp trong Supabase SQL Editor.`,
        });
      } else {
        console.error('❌ Export SQL failed:', data.error);
        throw new Error(data.error);
      }

    } catch (error) {
      console.error('💥 Export SQL error:', error);
      toast({
        title: '❌ Lỗi export SQL',
        description: error instanceof Error ? error.message : 'Không thể export SQL script',
        variant: 'destructive'
      });
    } finally {
      setIsCreating(false);
      setProgress(null);
    }
  };

  const downloadBackup = async (backup: BackupMetadata) => {
    try {
      const response = await fetch(`/api/admin/backup/${backup.id}/download`);
      const data = await response.json();

      if (data.success) {
        // Open download URL in new tab
        window.open(data.downloadUrl, '_blank');
        
        toast({
          title: '⬇️ Tải xuống bắt đầu',
          description: `File: ${backup.filename}`,
        });
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      toast({
        title: 'Lỗi tải xuống',
        description: error instanceof Error ? error.message : 'Không thể tải xuống backup',
        variant: 'destructive'
      });
    }
  };

  const deleteBackup = async (backup: BackupMetadata) => {
    if (!window.confirm(`Bạn có chắc chắn muốn xóa backup này?\n${backup.filename}`)) return;
    
    console.log(`🗑️ Deleting backup:`, backup);
    
    try {
      const response = await fetch(`/api/admin/backup/${backup.id}`, {
        method: 'DELETE',
      });
      
      console.log(`📡 Delete API response status:`, response.status);
      
      const data = await response.json();
      console.log(`📡 Delete API response data:`, data);
      
      if (data.success) {
        toast({
          title: '🗑️ Đã xóa backup',
          description: `Backup ${backup.filename} đã được xóa.`,
        });
        await fetchBackups();
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('❌ Delete backup error:', error);
      toast({
        title: 'Lỗi xóa backup',
        description: error instanceof Error ? error.message : 'Không thể xóa backup',
        variant: 'destructive'
      });
    }
  };

  const formatFileSize = (bytes: number): string => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round((bytes / Math.pow(1024, i)) * 100) / 100 + ' ' + sizes[i];
  };

  // Removed unused: getTypeColor, getStatusColor

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-3">
            <Database className="w-8 h-8 text-blue-600" />
            Quản lý Backup & Restore
          </h1>
          <p className="text-muted-foreground mt-1">
            Backup và khôi phục database một cách an toàn và chuyên nghiệp
          </p>
        </div>
        <Button onClick={fetchBackups} variant="outline" size="sm">
          <RefreshCw className="w-4 h-4 mr-2" />
          Làm mới
        </Button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/20 rounded-lg">
                <Database className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Tổng Backup</p>
                <p className="text-2xl font-bold">{backups.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 dark:bg-green-900/20 rounded-lg">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Thành công</p>
                <p className="text-2xl font-bold">
                  {backups.filter(b => b.status === 'completed').length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/20 rounded-lg">
                <HardDrive className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Dung lượng</p>
                <p className="text-2xl font-bold">
                  {formatFileSize(backups.reduce((sum, b) => sum + b.size, 0))}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 dark:bg-orange-900/20 rounded-lg">
                <Clock className="w-5 h-5 text-orange-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Backup cuối</p>
                <p className="text-sm font-semibold">
                  {backups.length > 0 
                    ? formatDistanceToNow(new Date(backups[0].created_at), { 
                        addSuffix: true, 
                        locale: vi 
                      })
                    : 'Chưa có'
                  }
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Create Backup Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-blue-600" />
            Tạo Backup Mới
          </CardTitle>
          <CardDescription>
            Chọn loại backup phù hợp với nhu cầu của bạn
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Progress Indicator */}
          {isCreating && progress && (
            <div className="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-blue-700 dark:text-blue-300">
                  {progress.stage === 'exporting_sql' ? 'Đang export SQL...' : `Đang tạo backup... (${progress.stage})`}
                </span>
                <span className="text-sm text-blue-600 dark:text-blue-400">
                  {progress.progress}%
                </span>
              </div>
              <Progress value={progress.progress} className="mb-2" />
              {progress.currentTable && (
                <p className="text-xs text-blue-600 dark:text-blue-400">
                  Đang xử lý: {progress.currentTable} ({progress.tablesCompleted}/{progress.totalTables})
                </p>
              )}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <BackupTypeCard 
              type="full"
              title="Full Backup"
              description="Backup toàn bộ database (schema + data)"
              icon={<Database className="w-8 h-8 text-blue-600" />}
              recommended
              onClick={() => createBackup('full')}
              disabled={isCreating}
            />
            
            <BackupTypeCard 
              type="incremental"
              title="Incremental Backup"
              description="Chỉ backup dữ liệu thay đổi"
              icon={<Clock className="w-8 h-8 text-green-600" />}
              onClick={() => createBackup('incremental', backups[0]?.created_at)}
              disabled={isCreating}
            />
            
            <BackupTypeCard 
              type="schema"
              title="Schema Only"
              description="Chỉ backup cấu trúc database"
              icon={<Shield className="w-8 h-8 text-purple-600" />}
              onClick={() => createBackup('schema')}
              disabled={isCreating}
            />
            
            <BackupTypeCard 
              type="data"
              title="Data Only"
              description="Chỉ backup dữ liệu tables"
              icon={<FileText className="w-8 h-8 text-orange-600" />}
              onClick={() => createBackup('data')}
              disabled={isCreating}
            />

            <BackupTypeCard 
              type="sql"
              title="Export SQL"
              description="Tạo file SQL cho Supabase Editor"
              icon={<FileText className="w-8 h-8 text-indigo-600" />}
              onClick={exportSQLScript}
              disabled={isCreating}
              special
            />
          </div>

          {/* SQL Export Usage Guide */}
          <div className="mt-6 p-4 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800">
            <div className="flex items-start gap-3">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg mt-1">
                <FileText className="w-5 h-5 text-indigo-600" />
              </div>
              <div className="flex-1">
                <h3 className="text-sm font-semibold text-indigo-800 dark:text-indigo-200 mb-2">
                  💡 Cách sử dụng Export SQL
                </h3>
                <div className="text-sm text-indigo-700 dark:text-indigo-300 space-y-2">
                  <p>
                    <strong>Export SQL</strong> tạo file .sql có thể chạy trực tiếp trong Supabase SQL Editor:
                  </p>
                  <ul className="list-disc ml-4 space-y-1">
                    <li>File chứa toàn bộ cấu trúc tables (CREATE TABLE) và dữ liệu (INSERT)</li>
                    <li>Sử dụng UPSERT pattern (ON CONFLICT) để tránh lỗi duplicate</li>
                    <li>Có transaction wrapper để đảm bảo tính toàn vẹn dữ liệu</li>
                    <li>Chạy an toàn trong môi trường production</li>
                  </ul>
                  <p className="text-xs mt-2 opacity-75">
                    Lưu ý: File SQL được tạo theo format của Supabase PostgreSQL
                  </p>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Backup History */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="w-5 h-5" />
            Lịch sử Backup
          </CardTitle>
          <CardDescription>
            Danh sách các backup đã tạo và trạng thái của chúng
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="h-16 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
                </div>
              ))}
            </div>
          ) : backups.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <Database className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>Chưa có backup nào được tạo</p>
              <p className="text-sm">Hãy tạo backup đầu tiên để bảo vệ dữ liệu của bạn</p>
            </div>
          ) : (
            <div className="space-y-3">
              {backups.map((backup) => (
                <BackupHistoryItem
                  key={backup.id}
                  backup={backup}
                  onDownload={() => downloadBackup(backup)}
                  onDelete={() => deleteBackup(backup)}
                  formatFileSize={formatFileSize}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// Helper Components
interface BackupTypeCardProps {
  type: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  recommended?: boolean;
  onClick: () => void;
  disabled?: boolean;
  special?: boolean;
}

function BackupTypeCard({ title, description, icon, recommended, onClick, disabled, special }: BackupTypeCardProps) {
  return (
    <Card className={`cursor-pointer transition-all duration-200 hover:shadow-md ${disabled ? 'opacity-50' : 'hover:border-blue-300'} ${recommended ? 'ring-2 ring-blue-500 ring-opacity-20' : ''} ${special ? 'ring-2 ring-indigo-500 ring-opacity-30 bg-gradient-to-br from-indigo-50 to-purple-50 dark:from-indigo-900/20 dark:to-purple-900/20' : ''}`}>
      <CardContent className="p-4" onClick={!disabled ? onClick : undefined}>
        <div className="text-center space-y-3">
          <div className="flex justify-center">
            {icon}
          </div>
          <div>
            <h3 className="font-semibold text-sm flex items-center justify-center gap-2">
              {title}
              {recommended && (
                <Badge variant="secondary" className="text-xs">Khuyến nghị</Badge>
              )}
            </h3>
            <p className="text-xs text-muted-foreground mt-1">
              {description}
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface BackupHistoryItemProps {
  backup: BackupMetadata;
  onDownload: () => void;
  onDelete: () => void;
  formatFileSize: (bytes: number) => string;
}

function BackupHistoryItem({ backup, onDownload, onDelete, formatFileSize }: BackupHistoryItemProps) {
  return (
    <div className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800/50">
      <div className="flex items-center gap-4">
        <div className={`w-3 h-3 rounded-full ${backup.type === 'full' ? 'bg-blue-500' : backup.type === 'incremental' ? 'bg-green-500' : backup.type === 'schema' ? 'bg-purple-500' : 'bg-orange-500'}`}></div>
        <div>
          <div className="flex items-center gap-2">
            <span className="font-medium text-sm">{backup.filename}</span>
            <Badge variant="outline" className="text-xs">
              {backup.type}
            </Badge>
            {backup.encrypted && (
              <Shield className="w-3 h-3 text-green-600" />
            )}
          </div>
          <div className="flex items-center gap-4 text-xs text-muted-foreground mt-1">
            <span>{formatDistanceToNow(new Date(backup.created_at), { addSuffix: true, locale: vi })}</span>
            <span>{formatFileSize(backup.size)}</span>
            <span className={getStatusColor(backup.status)}>
              {backup.status === 'completed' ? 'Hoàn thành' : 
               backup.status === 'creating' ? 'Đang tạo' :
               backup.status === 'failed' ? 'Thất bại' : 'Hết hạn'}
            </span>
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        {backup.status === 'completed' && (
          <>
            <Button
              size="sm"
              variant="outline"
              onClick={onDownload}
            >
              <Download className="w-4 h-4 mr-1" />
              Tải xuống
            </Button>
            <Button
              size="sm"
              variant="destructive"
              onClick={onDelete}
            >
              Xóa
            </Button>
          </>
        )}
        {backup.status === 'failed' && (
          <AlertTriangle className="w-4 h-4 text-red-500" />
        )}
      </div>
    </div>
  );
}

function getStatusColor(status: string): string {
  switch (status) {
    case 'completed': return 'text-green-600';
    case 'creating': return 'text-blue-600';
    case 'failed': return 'text-red-600';
    case 'expired': return 'text-gray-600';
    default: return 'text-gray-600';
  }
}
