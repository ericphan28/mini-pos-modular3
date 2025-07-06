import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Disable automatic trailing slash redirects
  trailingSlash: false,
  // Disable automatic redirect for trailing slash
  skipTrailingSlashRedirect: true,
  // Chỉ cho phép các biến môi trường được phép sử dụng ở client-side
  env: {
    // KHÔNG thêm SUPABASE_SERVICE_ROLE_KEY vào đây để tránh lộ thông tin nhạy cảm
  },
  serverRuntimeConfig: {
    // Các biến chỉ có trên server-side
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  },
  publicRuntimeConfig: {
    // Các biến public có thể dùng ở cả client-side
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  },
};

export default nextConfig;
