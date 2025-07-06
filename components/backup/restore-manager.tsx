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
    CheckCircle,
    Clock,
    Database,
    FileText,
    HardDrive,
    Play,
    RefreshCw,
    Shield
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

interface RestoreProgress {
  stage: string;
  progress: number;
  currentTable?: string;
  tablesCompleted: number;
  totalTables: number;
}

export default function RestoreManager() {
  const [backups, setBackups] = useState<BackupMetadata[]>([]);
  const [loading, setLoading] = useState(true);
  const [restoringId, setRestoringId] = useState<string | null>(null);
  const [restoreProgress, setRestoreProgress] = useState<RestoreProgress | null>(null);
  const [selectedBackup, setSelectedBackup] = useState<BackupMetadata | null>(null);
  const { toast } = useToast();

  // useCallback to ensure stable reference for useEffect dependency
  const fetchBackups = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/admin/backup');
      const data = await response.json();
      if (data.success) {
        setBackups(data.backups.filter((b: BackupMetadata) => b.status === 'completed'));
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

  const validateRestore = async (backupId: string) => {
    try {
      console.log(`🔍 Starting restore validation for backup ID: ${backupId}`);
      
      const response = await fetch('/api/admin/restore', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ backupId })
      });
      
      console.log(`📡 Validation API response status: ${response.status}`);
      
      const data = await response.json();
      console.log(`📡 Validation API response data:`, data);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${data.error || 'Validation failed'}`);
      }
      
      return data;
    } catch (error) {
      console.error('❌ Validation error:', error);
      throw error;
    }
  };

  const performRestore = async (backupId: string) => {
    try {
      console.log(`🔄 Starting restore operation for backup ID: ${backupId}`);
      
      const response = await fetch('/api/admin/restore', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          backupId, 
          confirmDangerous: true,
          createRestorePoint: true,
          userId: 'system' // You can get this from user context if available
        })
      });
      
      console.log(`📡 Restore API response status: ${response.status}`);
      
      const data = await response.json();
      console.log(`📡 Restore API response data:`, data);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${data.error || 'Restore failed'}`);
      }
      
      return data;
    } catch (error) {
      console.error('❌ Restore error:', error);
      throw error;
    }
  };

  const handleRestore = async (backup: BackupMetadata) => {
    if (!confirm(`⚠️ CẢNH BÁO: Bạn có chắc chắn muốn restore backup "${backup.filename}"?\n\nViệc này sẽ ghi đè toàn bộ dữ liệu hiện tại!`)) {
      return;
    }

    console.log(`🚀 Starting restore process for backup:`, backup);
    setRestoringId(backup.id);
    setSelectedBackup(backup);
    
    try {
      // Step 1: Validate restore
      console.log(`🔍 Step 1: Validating backup...`);
      setRestoreProgress({
        stage: 'Đang validate backup...',
        progress: 10,
        tablesCompleted: 0,
        totalTables: 1
      });

      const validation = await validateRestore(backup.id);
      console.log(`✅ Validation result:`, validation);
      
      if (!validation.valid) {
        throw new Error(validation.error || 'Backup validation failed');
      }

      if (validation.warnings && validation.warnings.length > 0) {
        console.log(`⚠️ Validation warnings:`, validation.warnings);
        const continueRestore = confirm(
          `Warnings detected:\n${validation.warnings.join('\n')}\n\nContinue with restore?`
        );
        if (!continueRestore) {
          console.log(`❌ User cancelled restore due to warnings`);
          return;
        }
      }

      // Step 2: Perform restore
      console.log(`🔄 Step 2: Performing restore...`);
      setRestoreProgress({
        stage: 'Đang thực hiện restore...',
        progress: 50,
        tablesCompleted: 0,
        totalTables: 1
      });

      const result = await performRestore(backup.id);
      console.log(`✅ Restore result:`, result);
      
      if (result.success) {
        console.log(`🎉 Restore completed successfully!`);
        setRestoreProgress({
          stage: 'Hoàn thành',
          progress: 100,
          tablesCompleted: 1,
          totalTables: 1
        });

        toast({
          title: '✅ Restore thành công!',
          description: `Database đã được khôi phục từ backup "${backup.filename}"`,
        });

        // Auto-hide progress after 3 seconds
        setTimeout(() => {
          setRestoreProgress(null);
        }, 3000);

      } else {
        console.error(`❌ Restore failed with result:`, result);
        throw new Error(result.error || 'Restore operation failed');
      }

    } catch (error) {
      console.error('💥 Restore process failed:', error);
      toast({
        title: '❌ Lỗi restore',
        description: error instanceof Error ? error.message : 'Không thể restore backup',
        variant: 'destructive'
      });
    } finally {
      console.log(`🏁 Restore process finished`);
      setRestoringId(null);
    }
  };

  const formatFileSize = (bytes: number): string => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round((bytes / Math.pow(1024, i)) * 100) / 100 + ' ' + sizes[i];
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'full': return <Database className="w-5 h-5 text-blue-600" />;
      case 'incremental': return <Clock className="w-5 h-5 text-green-600" />;
      case 'schema': return <Shield className="w-5 h-5 text-purple-600" />;
      case 'data': return <FileText className="w-5 h-5 text-orange-600" />;
      default: return <HardDrive className="w-5 h-5 text-gray-600" />;
    }
  };

  const getTypeColor = (type: string): string => {
    switch (type) {
      case 'full': return 'bg-blue-500';
      case 'incremental': return 'bg-green-500';
      case 'schema': return 'bg-purple-500';
      case 'data': return 'bg-orange-500';
      default: return 'bg-gray-500';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-3">
            <Database className="w-8 h-8 text-green-600" />
            Database Restore
          </h1>
          <p className="text-muted-foreground mt-1">
            Khôi phục database từ backup một cách an toàn và chuyên nghiệp
          </p>
        </div>
        <Button onClick={fetchBackups} variant="outline" size="sm">
          <RefreshCw className="w-4 h-4 mr-2" />
          Làm mới
        </Button>
      </div>

      {/* Warning Notice */}
      <Card className="border-orange-200 bg-orange-50 dark:bg-orange-900/20">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-orange-600 mt-0.5" />
            <div>
              <h3 className="font-semibold text-orange-800 dark:text-orange-200">
                ⚠️ Cảnh báo quan trọng
              </h3>
              <p className="text-sm text-orange-700 dark:text-orange-300 mt-1">
                Restore sẽ ghi đè toàn bộ dữ liệu hiện tại. Hãy đảm bảo bạn đã backup dữ liệu hiện tại trước khi thực hiện.
                Hệ thống sẽ tự động tạo restore point để có thể rollback nếu cần.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Restore Progress */}
      {restoringId && restoreProgress && (
        <Card className="border-blue-200 bg-blue-50 dark:bg-blue-900/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-blue-700 dark:text-blue-300">
                {restoreProgress.stage}
              </span>
              <span className="text-sm text-blue-600 dark:text-blue-400">
                {restoreProgress.progress}%
              </span>
            </div>
            <Progress value={restoreProgress.progress} className="mb-2" />
            {selectedBackup && (
              <p className="text-xs text-blue-600 dark:text-blue-400">
                Restoring: {selectedBackup.filename}
              </p>
            )}
          </CardContent>
        </Card>
      )}

      {/* Backup List */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Available Backups
          </CardTitle>
          <CardDescription>
            Chọn backup để khôi phục database
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="h-20 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
                </div>
              ))}
            </div>
          ) : backups.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <Database className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>Không có backup nào để restore</p>
              <p className="text-sm">Hãy tạo backup trước khi sử dụng tính năng restore</p>
            </div>
          ) : (
            <div className="space-y-3">
              {backups.map((backup) => (
                <div 
                  key={backup.id}
                  className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800/50"
                >
                  <div className="flex items-center gap-4">
                    <div className={`w-3 h-3 rounded-full ${getTypeColor(backup.type)}`}></div>
                    
                    <div className="flex items-center gap-2">
                      {getTypeIcon(backup.type)}
                    </div>
                    
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
                        <span className="flex items-center gap-1">
                          <CheckCircle className="w-3 h-3 text-green-600" />
                          Hoàn thành
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Button 
                      size="sm" 
                      variant="outline"
                      onClick={() => handleRestore(backup)}
                      disabled={restoringId === backup.id}
                      className="text-green-600 border-green-600 hover:bg-green-50"
                    >
                      {restoringId === backup.id ? (
                        <>
                          <RefreshCw className="w-4 h-4 mr-1 animate-spin" />
                          Restoring...
                        </>
                      ) : (
                        <>
                          <Play className="w-4 h-4 mr-1" />
                          Restore
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
