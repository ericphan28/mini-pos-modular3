'use client';

import { createClient } from '@/lib/supabase/client';
import { useEffect, useState } from 'react';

interface TestResult {
  test: string;
  success: boolean;
  data?: unknown;
  error?: unknown;
}

export default function TestMigrationsPage() {
  const [results, setResults] = useState<TestResult[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    testMigrations();
  }, []);

  const testMigrations = async () => {
    const supabase = createClient();
    const testResults: TestResult[] = [];

    console.log('🧪 [MIGRATION-TEST] Starting migration tests...');

    // Test 1: Check if enhanced auth function exists
    try {
      console.log('🧪 [TEST-1] Testing enhanced auth function...');
      const result = await supabase.rpc('pos_mini_modular3_get_user_with_business_complete', { 
        p_user_id: '00000000-0000-0000-0000-000000000000' 
      });
      
      testResults.push({
        test: 'Enhanced Auth Function (004)',
        success: true,
        data: result.data,
        error: result.error
      });
      
      console.log('✅ [TEST-1] Enhanced auth function exists!', result);
    } catch (error) {
      testResults.push({
        test: 'Enhanced Auth Function (004)',
        success: false,
        error: error
      });
      
      console.error('❌ [TEST-1] Enhanced auth function failed:', error);
    }

    // Test 2: Check if auth access functions exist (005)
    try {
      console.log('🧪 [TEST-2] Testing auth access functions...');
      const result = await supabase.rpc('pos_mini_modular3_get_all_tables_info');
      
      testResults.push({
        test: 'Auth Access Functions (005)',
        success: true,
        data: result.data,
        error: result.error
      });
      
      console.log('✅ [TEST-2] Auth access functions exist!', result);
    } catch (error) {
      testResults.push({
        test: 'Auth Access Functions (005)',
        success: false,
        error: error
      });
      
      console.error('❌ [TEST-2] Auth access functions failed:', error);
    }

    // Test 3: Check if product management tables exist (006)
    try {
      console.log('🧪 [TEST-3] Testing product management tables...');
      const result = await supabase
        .from('pos_mini_modular3_product_categories')
        .select('id')
        .limit(1);
      
      testResults.push({
        test: 'Product Management Tables (006)',
        success: true,
        data: `Table exists, ${result.data?.length || 0} records`,
        error: result.error
      });
      
      console.log('✅ [TEST-3] Product management tables exist!', result);
    } catch (error) {
      testResults.push({
        test: 'Product Management Tables (006)',
        success: false,
        error: error
      });
      
      console.error('❌ [TEST-3] Product management tables failed:', error);
    }

    // Test 4: Check if product functions exist (007)
    try {
      console.log('🧪 [TEST-4] Testing product functions...');
      const result = await supabase.rpc('pos_mini_modular3_create_category', {
        p_name: 'test-category-' + Date.now(),
        p_description: 'Test category for migration verification'
      });
      
      testResults.push({
        test: 'Product Functions (007)',
        success: true,
        data: result.data,
        error: result.error
      });
      
      console.log('✅ [TEST-4] Product functions exist!', result);
    } catch (error) {
      testResults.push({
        test: 'Product Functions (007)',
        success: false,
        error: error
      });
      
      console.error('❌ [TEST-4] Product functions failed:', error);
    }

    // Test 5: Check current user
    try {
      console.log('🧪 [TEST-5] Testing current user...');
      const { data: userData, error: userError } = await supabase.auth.getUser();
      
      testResults.push({
        test: 'Current User Session',
        success: !userError && !!userData.user,
        data: userData.user ? { id: userData.user.id, email: userData.user.email } : null,
        error: userError
      });
      
      console.log('✅ [TEST-5] Current user:', { user: userData.user, error: userError });
    } catch (error) {
      testResults.push({
        test: 'Current User Session',
        success: false,
        error: error
      });
      
      console.error('❌ [TEST-5] Current user failed:', error);
    }

    setResults(testResults);
    setLoading(false);
    
    console.log('🏁 [MIGRATION-TEST] All tests completed!', testResults);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold mb-8">Testing Migrations...</h1>
          <div className="animate-pulse">Loading...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold mb-8">Migration Test Results</h1>
        
        <div className="space-y-4">
          {results.map((result, index) => (
            <div
              key={index}
              className={`p-4 rounded-lg border-2 ${
                result.success 
                  ? 'bg-green-50 border-green-300 shadow-sm' 
                  : 'bg-red-50 border-red-300 shadow-sm'
              }`}
            >
              <div className="flex items-center gap-3 mb-3">
                <span className={`text-2xl ${result.success ? 'text-green-600' : 'text-red-600'}`}>
                  {result.success ? '✅' : '❌'}
                </span>
                <h3 className={`font-semibold text-lg ${result.success ? 'text-green-800' : 'text-red-800'}`}>
                  {result.test}
                </h3>
              </div>
              
              {result.data && (
                <div className="mb-3">
                  <strong className="text-gray-700 text-sm uppercase tracking-wide">Data:</strong>
                  <pre className="text-xs bg-white border border-gray-200 p-3 rounded mt-2 overflow-auto max-h-40 font-mono">
                    {typeof result.data === 'string' ? result.data : JSON.stringify(result.data, null, 2)}
                  </pre>
                </div>
              )}
              
              {result.error && (
                <div>
                  <strong className="text-red-700 text-sm uppercase tracking-wide">Error:</strong>
                  <pre className="text-xs bg-red-50 border border-red-200 p-3 rounded mt-2 overflow-auto max-h-40 font-mono">
                    {typeof result.error === 'string' ? result.error : JSON.stringify(result.error, null, 2)}
                  </pre>
                </div>
              )}
            </div>
          ))}
        </div>
        
        {/* Diagnosis Section */}
        {results.length > 0 && (
          <div className="mt-8">
            <div className="p-6 bg-yellow-50 border-2 border-yellow-300 rounded-lg">
              <h3 className="font-bold text-yellow-800 mb-4 text-xl">🔍 Diagnosis & Solution</h3>
              
              {/* Check for USER_PROFILE_NOT_FOUND */}
              {results.some(r => 
                r.test.includes('Enhanced Auth Function') && 
                typeof r.data === 'object' && 
                r.data && 
                'error' in (r.data as Record<string, unknown>) &&
                (r.data as Record<string, unknown>).error === 'USER_PROFILE_NOT_FOUND'
              ) && (
                <div className="mb-4 p-4 bg-orange-50 border border-orange-200 rounded">
                  <h4 className="font-semibold text-orange-800 mb-2">❌ Missing User Profile</h4>
                  <p className="text-orange-700 text-sm mb-3">
                    User exists in auth.users but no profile in pos_mini_modular3_user_profiles table.
                  </p>
                  <div className="bg-orange-100 p-3 rounded font-mono text-xs">
                    <strong>Fix:</strong> Create user profile or redirect to signup
                  </div>
                </div>
              )}
              
              {/* Check if all migrations passed */}
              {results.every(r => r.success) && (
                <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded">
                  <h4 className="font-semibold text-green-800 mb-2">✅ All Migrations Working</h4>
                  <p className="text-green-700 text-sm">
                    All database functions are deployed and working correctly.
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
        
        <div className="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <h3 className="font-medium text-blue-800 mb-2">Next Steps:</h3>
          <ul className="text-sm text-blue-700 space-y-1">
            <li>• If USER_PROFILE_NOT_FOUND: User needs to complete signup process</li>
            <li>• If migrations fail: Run the corresponding migration in Supabase SQL Editor</li>
            <li>• Check browser console for detailed error logs</li>
            <li>• Migration files are in: supabase/migrations/</li>
            <li>• Test login after all issues are resolved</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
