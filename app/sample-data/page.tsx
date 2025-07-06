/**
 * ==================================================================================
 * SAMPLE DATA INSERTION PAGE
 * ==================================================================================
 * Trang để thêm dữ liệu mẫu vào database để test export SQL
 */

'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { Database, Plus, RefreshCw } from 'lucide-react';
import { useState } from 'react';

interface SampleDataResult {
  table_name: string;
  row_count: number;
}

export default function SampleDataPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<SampleDataResult[] | null>(null);
  const { toast } = useToast();

  const insertSampleData = async () => {
    try {
      setIsLoading(true);
      setResult(null);

      const response = await fetch('/api/admin/sample-data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();

      if (data.success) {
        setResult(data.result);
        
        toast({
          title: '✅ Đã thêm dữ liệu mẫu thành công!',
          description: `Đã thêm dữ liệu vào ${data.result.length} bảng`,
        });
      } else {
        toast({
          title: '❌ Lỗi thêm dữ liệu mẫu',
          description: data.error,
          variant: 'destructive'
        });
      }

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
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
            <Database className="h-5 w-5" />
            Thêm Dữ Liệu Mẫu
          </CardTitle>
          <CardDescription>
            Thêm dữ liệu mẫu vào database để test tính năng export SQL
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button 
              onClick={insertSampleData}
              disabled={isLoading}
              className="flex items-center gap-2"
            >
              <Plus className="h-4 w-4" />
              {isLoading ? 'Đang thêm dữ liệu...' : 'Thêm Dữ Liệu Mẫu'}
            </Button>

            <Button 
              variant="outline"
              onClick={() => window.location.href = '/test-export-sql'}
              className="flex items-center gap-2"
            >
              <RefreshCw className="h-4 w-4" />
              Test Export SQL
            </Button>
          </div>

          {result && (
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <h3 className="font-semibold mb-2">Kết quả thêm dữ liệu:</h3>
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2">Tên Bảng</th>
                      <th className="text-right py-2">Số Dòng</th>
                    </tr>
                  </thead>
                  <tbody>
                    {result.map((row, index) => (
                      <tr key={index} className="border-b">
                        <td className="py-2 font-mono">{row.table_name}</td>
                        <td className="py-2 text-right">{row.row_count}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <h3 className="font-semibold mb-2">📋 Dữ liệu sẽ được thêm:</h3>
            <ul className="text-sm space-y-1">
              <li>• <strong>Business Types:</strong> 3 loại cửa hàng (nhỏ, vừa, lớn)</li>
              <li>• <strong>User Profiles:</strong> 3 user (super admin, owner, staff)</li>
              <li>• <strong>Businesses:</strong> 2 cửa hàng mẫu</li>
              <li>• <strong>Subscription Plans:</strong> 2 gói dịch vụ</li>
              <li>• <strong>Subscription History:</strong> 2 lịch sử đăng ký</li>
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
