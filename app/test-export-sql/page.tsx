/**
 * ==================================================================================
 * TEST EXPORT SQL PAGE
 * ==================================================================================
 * Trang test để kiểm tra tính năng export SQL
 */

'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { Download, FileText } from 'lucide-react';
import { useState } from 'react';

export default function TestExportSQLPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const { toast } = useToast();

  const testExportSQL = async () => {
    try {
      setIsLoading(true);
      setResult(null);

      console.log('🚀 Starting export SQL test...');

      const response = await fetch('/api/admin/backup/export-sql', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          includeSchema: true,
          includeData: true,
          format: 'supabase'
        })
      });

      console.log('📊 Response status:', response.status);
      console.log('📊 Response headers:', Object.fromEntries(response.headers.entries()));

      // Check if response is actually JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const textResponse = await response.text();
        console.error('❌ Response is not JSON:', textResponse.substring(0, 500));
        throw new Error(`Server returned ${contentType || 'unknown content type'}: ${textResponse.substring(0, 200)}...`);
      }

      const data = await response.json();
      console.log('📋 Response data:', { success: data.success, error: data.error, scriptLength: data.sqlScript?.length });

      if (data.success) {
        setResult(`✅ Export thành công!\n📋 Script length: ${data.sqlScript.length} characters\n\nPreview:\n${data.sqlScript.substring(0, 500)}...`);
        
        toast({
          title: '✅ Export SQL thành công!',
          description: `Đã tạo SQL script với ${data.sqlScript.length} ký tự`,
        });

        // Download file
        const blob = new Blob([data.sqlScript], { type: 'text/sql;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `test-export-${new Date().toISOString().slice(0, 19).replace(/[:.]/g, '-')}.sql`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

      } else {
        setResult(`❌ Export failed: ${data.error}`);
        toast({
          title: '❌ Lỗi export SQL',
          description: data.error,
          variant: 'destructive'
        });
      }

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error('💥 Request failed:', error);
      setResult(`💥 Request failed: ${errorMsg}`);
      toast({
        title: '❌ Lỗi kết nối',
        description: errorMsg,
        variant: 'destructive'
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="container mx-auto p-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Test Export SQL
          </CardTitle>
          <CardDescription>
            Kiểm tra tính năng export SQL script
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button 
            onClick={testExportSQL}
            disabled={isLoading}
            className="flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            {isLoading ? 'Đang export...' : 'Test Export SQL'}
          </Button>

          {result && (
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <h3 className="font-semibold mb-2">Kết quả:</h3>
              <pre className="text-sm whitespace-pre-wrap overflow-auto max-h-96">
                {result}
              </pre>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
