import { EnhancedAuthTest } from '@/components/auth/enhanced-auth-test';

export default function Page() {
  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Enhanced Auth System Test
          </h1>
          <p className="text-gray-600">
            Test và debug hệ thống xác thực nâng cao POS Mini Modular 3
          </p>
        </div>
        
        <EnhancedAuthTest />
      </div>
    </div>
  );
}
