"use client";

import { User } from "@supabase/supabase-js";
import React, { useState } from "react";
import { SuperAdminHeader } from "./header";
import { SuperAdminMobileSidebar } from "./mobile-sidebar";
import { SuperAdminSidebar } from "./sidebar";

interface SuperAdminLayoutClientProps {
  children: React.ReactNode;
  user: User;
  profile: { full_name?: string } | null;
}

export function SuperAdminLayoutClient({ children, user, profile }: SuperAdminLayoutClientProps) {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-100 dark:from-gray-900 dark:via-purple-900 dark:to-indigo-900">
      {/* Desktop Sidebar */}
      <SuperAdminSidebar />
      
      {/* Mobile Sidebar */}
      <SuperAdminMobileSidebar 
        isOpen={isMobileMenuOpen} 
        onClose={() => setIsMobileMenuOpen(false)} 
      />
      
      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        <SuperAdminHeader 
          user={user} 
          profile={profile}
          onMobileMenuClick={() => setIsMobileMenuOpen(true)}
        />
        
        <main className="flex-1 p-4 md:p-8 pb-20 md:pb-8">
          {children}
        </main>
      </div>
    </div>
  );
}
