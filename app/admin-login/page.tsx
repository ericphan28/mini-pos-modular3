import SuperAdminLoginForm from '@/components/super-admin/login-form';
import SuperAdminStats from '@/components/super-admin/login-stats';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'POS Mini Modular 3 - Super Admin Portal',
  description: 'Secure administrative access for POS Mini Modular 3 Vietnam system',
  robots: {
    index: false,
    follow: false,
  },
};

export default function SuperAdminLoginPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-gray-50 to-blue-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <div className="flex min-h-screen">
        {/* Left Side - Stats Panel */}
        <div className="hidden lg:flex lg:w-1/2 bg-emerald-600 dark:bg-emerald-700 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-600 to-emerald-800 opacity-90"></div>
          
          {/* Background Pattern */}
          <div className="absolute inset-0 opacity-10">
            <svg className="w-full h-full" viewBox="0 0 100 100" fill="none">
              <defs>
                <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
                  <path d="M 10 0 L 0 0 0 10" fill="none" stroke="white" strokeWidth="0.5"/>
                </pattern>
              </defs>
              <rect width="100" height="100" fill="url(#grid)" />
            </svg>
          </div>

          <div className="relative z-10 flex flex-col justify-center px-12 text-white">
            {/* Logo & Title */}
            <div className="mb-12">
              <div className="w-20 h-20 bg-white/20 rounded-2xl flex items-center justify-center mb-6">
                <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <h1 className="text-4xl font-bold mb-4">POS Mini Modular 3</h1>
              <p className="text-emerald-100 text-lg leading-relaxed">
                Hệ thống quản lý bán hàng đa doanh nghiệp cho thị trường Việt Nam
              </p>
            </div>

            {/* System Stats */}
            <SuperAdminStats />

            {/* Features */}
            <div className="space-y-4">
              <div className="flex items-center text-emerald-100">
                <svg className="w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Multi-tenant Architecture với RLS Security
              </div>
              <div className="flex items-center text-emerald-100">
                <svg className="w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Subscription Management (Free/Basic/Premium)
              </div>
              <div className="flex items-center text-emerald-100">
                <svg className="w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Enterprise-grade Audit Logging
              </div>
              <div className="flex items-center text-emerald-100">
                <svg className="w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Real-time Business Analytics
              </div>
            </div>
          </div>
        </div>

        {/* Right Side - Login Form */}
        <div className="w-full lg:w-1/2 flex items-center justify-center p-4">
          <div className="w-full max-w-md space-y-6">
            {/* Header */}
            <div className="text-center mb-8">
              <div className="mx-auto w-16 h-16 bg-emerald-600 rounded-xl flex items-center justify-center mb-4 shadow-lg lg:hidden">
                <svg 
                  className="w-8 h-8 text-white" 
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path 
                    strokeLinecap="round" 
                    strokeLinejoin="round" 
                    strokeWidth={2} 
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" 
                  />
                </svg>
              </div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                Super Admin Portal
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Secure access for system administrators
              </p>
            </div>

            {/* Login Form */}
            <SuperAdminLoginForm />

            {/* Footer */}
            <div className="mt-8 text-center">
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
                Protected by enterprise-grade security
              </p>
              <div className="flex items-center justify-center mt-2 space-x-4 text-xs text-gray-400">
                <span className="flex items-center">
                  <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                  </svg>
                  SSL Encrypted
                </span>
                <span className="flex items-center">
                  <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Audit Logged
                </span>
                <span className="flex items-center">
                  <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clipRule="evenodd" />
                  </svg>
                  RLS Protected
                </span>
              </div>
              
              {/* Version Info */}
              <div className="mt-4 text-xs text-gray-400">
                POS Mini Modular 3 Vietnam • Version 3.0.0
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
