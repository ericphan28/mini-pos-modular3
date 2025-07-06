/**
 * ==================================================================================
 * DEBUG AUTHENTICATION PAGE
 * ==================================================================================
 * Trang để debug authentication và kiểm tra user status
 */

'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Database, Shield, User } from 'lucide-react';
import { useState } from 'react';

interface AuthDebugResult {
  isAuthenticated: boolean;
  user?: {
    id: string;
    email: string;
    role?: string;
  };
  error?: string;
}

export default function DebugAuthPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [authResult, setAuthResult] = useState<AuthDebugResult | null>(null);
  const [apiHealthResult, setApiHealthResult] = useState<string | null>(null);

  const checkAuth = async () => {
    try {
      setIsLoading(true);
      
      const response = await fetch('/api/auth/user', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();
      
      setAuthResult({
        isAuthenticated: !!data.user,
        user: data.user,
        error: data.error
      });

    } catch (error) {
      setAuthResult({
        isAuthenticated: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const checkApiHealth = async () => {
    try {
      setIsLoading(true);
      
      const response = await fetch('/api/admin/backup/export-sql', {
        method: 'GET'
      });

      const data = await response.json();
      setApiHealthResult(JSON.stringify(data, null, 2));

    } catch (error) {
      setApiHealthResult(`Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Debug Authentication
          </CardTitle>
          <CardDescription>
            Kiểm tra trạng thái authentication và API health
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button 
              onClick={checkAuth}
              disabled={isLoading}
              className="flex items-center gap-2"
            >
              <User className="h-4 w-4" />
              Kiểm tra Auth
            </Button>

            <Button 
              onClick={checkApiHealth}
              disabled={isLoading}
              variant="outline"
              className="flex items-center gap-2"
            >
              <Database className="h-4 w-4" />
              Kiểm tra API Health
            </Button>
          </div>

          {authResult && (
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <h3 className="font-semibold mb-2">🔐 Authentication Status:</h3>
              <pre className="text-sm whitespace-pre-wrap overflow-auto max-h-48">
                {JSON.stringify(authResult, null, 2)}
              </pre>
            </div>
          )}

          {apiHealthResult && (
            <div className="mt-4 p-4 bg-green-50 rounded-lg">
              <h3 className="font-semibold mb-2">🏥 API Health:</h3>
              <pre className="text-sm whitespace-pre-wrap overflow-auto max-h-48">
                {apiHealthResult}
              </pre>
            </div>
          )}

          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <h3 className="font-semibold mb-2">📋 Debug Steps:</h3>
            <ol className="text-sm space-y-1 list-decimal list-inside">
              <li>Kiểm tra authentication status trước</li>
              <li>Nếu chưa auth, đăng nhập tại <a href="/auth/login" className="text-blue-600 underline">/auth/login</a></li>
              <li>Kiểm tra API health sau khi đăng nhập</li>
              <li>Test export SQL tại <a href="/test-export-sql" className="text-blue-600 underline">/test-export-sql</a></li>
            </ol>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
