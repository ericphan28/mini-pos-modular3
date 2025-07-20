'use client';

import { useState } from 'react';
import { useAuth } from '@/lib/auth/auth-context';
import { useStaffPermissions, useProductPermissions } from '@/hooks/use-permission';
import { useSyncStatus, usePermissionSync } from '@/lib/permissions/permission-sync';

export default function PermissionTestPage() {
  const { 
    isAuthenticated, 
    sessionData, 
    isLoading,
    login,
    hasPermission,
    hasFeatureAccess,
    canAccessRoute,
    getUserPermissions,
    getSubscriptionLimits,
    permissionCache,
    permissionLoading
  } = useAuth();

  const [email, setEmail] = useState('cym_sunset@yahoo.com');
  const [password, setPassword] = useState('');
  const [testResults, setTestResults] = useState<string[]>([]);
  const [isTestRunning, setIsTestRunning] = useState(false);

  // Permission hooks
  const staffPermissions = useStaffPermissions();
  const productPermissions = useProductPermissions();
  
  // Feature access simulation
  const featureAccess = {
    staff: hasFeatureAccess('staff'),
    product: hasFeatureAccess('product'), 
    financial: hasFeatureAccess('financial'),
    pos: hasFeatureAccess('pos')
  };
  
  // Sync status
  const syncStatus = useSyncStatus();
  const { isSyncing, performManualSync } = usePermissionSync();

  const addTestResult = (message: string) => {
    setTestResults(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  const handleLogin = async () => {
    if (!password) {
      addTestResult('❌ Please enter password');
      return;
    }

    try {
      setIsTestRunning(true);
      addTestResult('🔐 Starting authentication...');
      
      await login(email, password);
      addTestResult('✅ Authentication successful!');
      
      // Wait for permission cache to load
      setTimeout(() => {
        runPermissionTests();
      }, 2000);
      
    } catch (error) {
      addTestResult(`❌ Login failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setIsTestRunning(false);
    }
  };

  const runPermissionTests = () => {
    addTestResult('🧪 Running permission tests...');

    // Test basic session data
    if (sessionData) {
      addTestResult(`✅ Session loaded: ${sessionData.user.email}`);
      addTestResult(`✅ Business: ${sessionData.business.name} (${sessionData.business.subscriptionTier})`);
      addTestResult(`✅ Role: ${sessionData.permissions.role}`);
      addTestResult(`✅ Features: ${sessionData.permissions.features.length} (${sessionData.permissions.features.join(', ')})`);
      addTestResult(`✅ Permissions: ${sessionData.permissions.permissions.length} total`);
      
      // DEBUG: Print actual permissions from session
      addTestResult(`🔍 DEBUG - Raw permissions from session:`);
      sessionData.permissions.permissions.slice(0, 10).forEach(perm => {
        addTestResult(`   ${perm}`);
      });
      if (sessionData.permissions.permissions.length > 10) {
        addTestResult(`   ... and ${sessionData.permissions.permissions.length - 10} more`);
      }
    }

    // Test permission cache
    if (permissionCache) {
      addTestResult('✅ Permission cache loaded');
      const userPerms = getUserPermissions();
      addTestResult(`✅ User permissions: ${Object.keys(userPerms).length} features`);
      
      const limits = getSubscriptionLimits();
      addTestResult(`✅ Subscription limits: ${Object.keys(limits).length} limits`);
    } else {
      addTestResult('⚠️ Permission cache not yet loaded');
    }

    // Test individual permissions
    const testPermissions = [
      'staff_view',
      'staff_create', 
      'staff_edit',
      'staff_delete',
      'product_view',
      'product_create',
      'financial_view',
      'report_view',
      'pos_access'
    ];

    testPermissions.forEach(permission => {
      const result = hasPermission(permission);
      addTestResult(`${result ? '✅' : '❌'} Permission ${permission}: ${result ? 'ALLOWED' : 'DENIED'}`);
    });

    // Test feature access
    const testFeatures = ['staff', 'product', 'financial', 'report', 'pos', 'inventory', 'customer'];
    testFeatures.forEach(feature => {
      const result = hasFeatureAccess(feature);
      addTestResult(`${result ? '✅' : '❌'} Feature ${feature}: ${result ? 'ACCESSIBLE' : 'RESTRICTED'}`);
    });

    // Test route access
    const testRoutes = ['/dashboard', '/staff', '/products', '/financial', '/reports', '/pos'];
    testRoutes.forEach(route => {
      const result = canAccessRoute(route);
      addTestResult(`${result ? '✅' : '❌'} Route ${route}: ${result ? 'ACCESSIBLE' : 'RESTRICTED'}`);
    });

    // Test hook results
    addTestResult('🎣 Testing permission hooks:');
    addTestResult(`Staff permissions: View=${staffPermissions.canViewStaff}, Create=${staffPermissions.canCreateStaff}, Edit=${staffPermissions.canEditStaff}, Delete=${staffPermissions.canDeleteStaff}`);
    addTestResult(`Product permissions: View=${productPermissions.canViewProducts}, Create=${productPermissions.canCreateProducts}, Edit=${productPermissions.canEditProducts}, Delete=${productPermissions.canDeleteProducts}`);
    addTestResult(`Feature access: Staff=${featureAccess.staff}, Product=${featureAccess.product}, Financial=${featureAccess.financial}`);

    addTestResult('🎉 Permission tests completed!');
  };

  const clearResults = () => {
    setTestResults([]);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p>Loading authentication state...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-6xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-6">
            🔒 Permission System Test Dashboard
          </h1>

          {!isAuthenticated ? (
            <div className="mb-8 p-6 bg-blue-50 rounded-lg border border-blue-200">
              <h2 className="text-lg font-semibold text-blue-900 mb-4">
                Login to Test Permission System
              </h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="cym_sunset@yahoo.com"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Password
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                
                <button
                  onClick={handleLogin}
                  disabled={isTestRunning}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isTestRunning ? 'Testing...' : 'Login & Test Permission System'}
                </button>
              </div>
            </div>
          ) : (
            <div className="mb-8 p-6 bg-green-50 rounded-lg border border-green-200">
              <h2 className="text-lg font-semibold text-green-900 mb-2">
                ✅ Authenticated as {sessionData?.user.email}
              </h2>
              <p className="text-green-700">
                Business: {sessionData?.business.name} ({sessionData?.business.subscriptionTier})
              </p>
              <p className="text-green-700">
                Role: {sessionData?.permissions.role}
              </p>
              
              <div className="mt-4 flex gap-2">
                <button
                  onClick={runPermissionTests}
                  className="bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700"
                >
                  🧪 Run Permission Tests
                </button>
                
                <button
                  onClick={performManualSync}
                  disabled={isSyncing}
                  className="bg-purple-600 text-white py-2 px-4 rounded-md hover:bg-purple-700 disabled:opacity-50"
                >
                  {isSyncing ? '🔄 Syncing...' : '🔄 Manual Sync'}
                </button>
              </div>
            </div>
          )}

          {/* System Status */}
          <div className="mb-6 p-4 bg-gray-50 rounded-lg">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">System Status</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div>
                <span className="font-medium">Authentication:</span>
                <span className={`ml-2 ${isAuthenticated ? 'text-green-600' : 'text-red-600'}`}>
                  {isAuthenticated ? '✅ Active' : '❌ Not Active'}
                </span>
              </div>
              <div>
                <span className="font-medium">Permission Cache:</span>
                <span className={`ml-2 ${permissionCache ? 'text-green-600' : 'text-yellow-600'}`}>
                  {permissionCache ? '✅ Loaded' : '⏳ Loading'}
                </span>
              </div>
              <div>
                <span className="font-medium">Permission Loading:</span>
                <span className={`ml-2 ${permissionLoading ? 'text-yellow-600' : 'text-green-600'}`}>
                  {permissionLoading ? '⏳ Loading' : '✅ Ready'}
                </span>
              </div>
              <div>
                <span className="font-medium">Sync Status:</span>
                <span className={`ml-2 ${syncStatus.isActive ? 'text-green-600' : 'text-gray-600'}`}>
                  {syncStatus.isActive ? '✅ Active' : '⏸️ Inactive'}
                </span>
              </div>
            </div>
          </div>

          {/* Test Results */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-lg font-semibold text-gray-900">Test Results</h3>
              {testResults.length > 0 && (
                <button
                  onClick={clearResults}
                  className="text-sm text-gray-600 hover:text-gray-800"
                >
                  Clear Results
                </button>
              )}
            </div>
            
            <div className="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm max-h-96 overflow-y-auto">
              {testResults.length === 0 ? (
                <p className="text-gray-500">No test results yet. Login and run tests to see results here.</p>
              ) : (
                testResults.map((result, index) => (
                  <div key={index} className="mb-1">
                    {result}
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Hook Examples */}
          {isAuthenticated && (
            <div className="mt-8 p-6 bg-blue-50 rounded-lg">
              <h3 className="text-lg font-semibold text-blue-900 mb-4">
                🎣 Live Hook Examples
              </h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-sm">
                <div className="bg-white p-3 rounded border">
                  <h4 className="font-medium mb-2">Staff Permissions</h4>
                  <div className="space-y-1">
                    <div>View: {staffPermissions.canViewStaff ? '✅' : '❌'}</div>
                    <div>Create: {staffPermissions.canCreateStaff ? '✅' : '❌'}</div>
                    <div>Edit: {staffPermissions.canEditStaff ? '✅' : '❌'}</div>
                    <div>Delete: {staffPermissions.canDeleteStaff ? '✅' : '❌'}</div>
                  </div>
                </div>
                
                <div className="bg-white p-3 rounded border">
                  <h4 className="font-medium mb-2">Product Permissions</h4>
                  <div className="space-y-1">
                    <div>View: {productPermissions.canViewProducts ? '✅' : '❌'}</div>
                    <div>Create: {productPermissions.canCreateProducts ? '✅' : '❌'}</div>
                    <div>Edit: {productPermissions.canEditProducts ? '✅' : '❌'}</div>
                    <div>Delete: {productPermissions.canDeleteProducts ? '✅' : '❌'}</div>
                  </div>
                </div>
                
                <div className="bg-white p-3 rounded border">
                  <h4 className="font-medium mb-2">Feature Access</h4>
                  <div className="space-y-1">
                    <div>Staff: {featureAccess.staff ? '✅' : '❌'}</div>
                    <div>Product: {featureAccess.product ? '✅' : '❌'}</div>
                    <div>Financial: {featureAccess.financial ? '✅' : '❌'}</div>
                    <div>POS: {featureAccess.pos ? '✅' : '❌'}</div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
