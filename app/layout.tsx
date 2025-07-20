import type { Metadata } from "next";
import { Geist } from "next/font/google";
import { ThemeProvider } from "next-themes";
import { Toaster } from "sonner";
import { AuthProvider } from "@/lib/auth";
import { PermissionProvider } from "@/components/permissions/permission-provider";
import "./globals.css";

const defaultUrl = process.env.VERCEL_URL
  ? `https://${process.env.VERCEL_URL}`
  : "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(defaultUrl),
  title: "POS Mini Modular - Hệ thống quản lý bán hàng cho hộ kinh doanh Việt Nam",
  description: "Hệ thống POS hiện đại, đơn giản và hiệu quả được thiết kế đặc biệt cho các hộ kinh doanh tại Việt Nam",
};

const geistSans = Geist({
  variable: "--font-geist-sans",
  display: "swap",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <body className={`${geistSans.className} antialiased`}>
        <AuthProvider>
          <PermissionProvider>
            <ThemeProvider
              attribute="class"
              defaultTheme="system"
              enableSystem
              disableTransitionOnChange
            >
              {children}
              <Toaster richColors position="top-right" />
            </ThemeProvider>
          </PermissionProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
