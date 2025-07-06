# POS Mini Modular

Hệ thống quản lý bán hàng hiện đại cho các hộ kinh doanh tại Việt Nam với kiến trúc modular và mô hình freemium.

## 🌟 Trạng thái dự án

✅ **Phase 1: Hoàn thành** - Core Infrastructure & Authentication
- ✅ Khởi tạo Next.js project với TypeScript
- ✅ Cấu hình Supabase authentication
- ✅ Thiết kế UI/UX theo phong cách Supabase
- ✅ Đăng nhập/đăng ký bằng email hoặc số điện thoại
- ✅ Dashboard cơ bản với layout responsive
- ✅ Middleware bảo mật và route protection

🚧 **Phase 2: Đang phát triển** - Business Logic
- 🔄 Business onboarding và profile management
- 🔄 Product CRUD operations
- 🔄 Inventory management
- 🔄 POS interface

📋 **Phase 3: Kế hoạch** - Advanced Features
- ⏳ Subscription management
- ⏳ Multi-branch support
- ⏳ Reporting và analytics
- ⏳ E-invoice integration

## 🎨 UI/UX Design

Dự án được thiết kế với:
- **Design System**: Supabase-inspired với màu xanh lá chủ đạo
- **Responsive**: Hoạt động tối ưu trên desktop, tablet và mobile
- **Accessibility**: Tuân thủ WCAG 2.1 guidelines
- **Vietnamese First**: Tối ưu cho người dùng Việt Nam

## 🔐 Authentication Features

- **Đa phương thức đăng nhập**: Email hoặc số điện thoại
- **Smart Detection**: Tự động nhận diện email/phone từ input
- **Real-time Validation**: Kiểm tra định dạng trong khi gõ
- **Secure Session**: JWT tokens với Supabase Auth
- **Route Protection**: Middleware bảo vệ các trang cần authentication

## 🏗️ Tech Stack

- **Frontend**: Next.js 15 với App Router, TypeScript, Tailwind CSS
- **Backend**: Supabase (Auth, Database, Storage, Edge Functions)
- **UI Components**: shadcn/ui với Radix UI primitives
- **State Management**: Zustand + TanStack React Query
- **Form Handling**: React Hook Form + Zod validation
- **Styling**: Tailwind CSS với Supabase design tokens

## 🌟 Subscription Tiers (Kế hoạch)

### Gói Miễn phí
- ✅ Quản lý sản phẩm (tối đa 50 sản phẩm)
- ✅ Bán hàng cơ bản
- ✅ Báo cáo đơn giản
- ✅ Quản lý 3 người dùng
- ✅ Hỗ trợ qua email

### Gói Cơ bản (199,000₫/tháng)
- ✅ Tất cả tính năng miễn phí
- ✅ Quản lý sản phẩm không giới hạn
- ✅ Quản lý kho hàng
- ✅ Quản lý khách hàng
- ✅ Báo cáo nâng cao
- ✅ Tối đa 10 người dùng

### Gói Nâng cao (499,000₫/tháng)
- ✅ Tất cả tính năng gói Cơ bản
- ✅ Quản lý nhiều chi nhánh
- ✅ Hóa đơn điện tử
- ✅ Tích hợp thanh toán
- ✅ API không giới hạn
- ✅ Tối đa 50 người dùng
- ✅ Hỗ trợ 24/7

## 🚀 Cài đặt và chạy dự án

### Yêu cầu hệ thống
- Node.js 18+ 
- npm hoặc yarn
- Tài khoản Supabase

### Cài đặt dependencies
```bash
npm install
```

### Cấu hình environment
Tạo file `.env.local` dựa trên `.env.example`:

```bash
cp .env.example .env.local
```

Cập nhật các biến môi trường trong `.env.local` với thông tin từ Supabase project:

```env
# Supabase Configuration (Required)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url_here
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Application Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME="POS Mini Modular"
```

**Lưu ý**: Bạn có thể tìm thông tin Supabase URL và ANON KEY tại: 
[https://supabase.com/dashboard/project/_/settings/api](https://supabase.com/dashboard/project/_/settings/api)

### Chạy ở môi trường development
```bash
npm run dev
```

Truy cập [http://localhost:3000](http://localhost:3000) để xem ứng dụng.

### Build cho production
```bash
npm run build
npm start
```

## 📁 Cấu trúc dự án

```
src/
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Authentication routes
│   │   ├── login/         # Trang đăng nhập
│   │   └── register/      # Trang đăng ký
│   ├── (dashboard)/       # Main dashboard routes
│   │   ├── dashboard/     # Trang tổng quan
│   │   ├── products/      # Quản lý sản phẩm
│   │   ├── orders/        # Quản lý đơn hàng
│   │   ├── reports/       # Báo cáo
│   │   └── settings/      # Cài đặt
│   └── (super-admin)/     # Super admin panel
│       └── admin/         # Panel quản trị hệ thống
├── components/            # Reusable components
│   ├── ui/               # Base UI components (shadcn/ui)
│   ├── features/         # Feature-specific components
│   └── feature-gates/    # Subscription gating components
├── lib/                  # Utility functions and configurations
│   ├── supabase/         # Supabase client và utilities
│   ├── auth/             # Authentication context
│   └── providers/        # React providers
├── types/                # TypeScript type definitions
├── stores/               # Zustand stores
└── hooks/                # Custom React hooks
```

## 👥 Xác thực người dùng

### Phương thức đăng nhập
- **Email**: name@example.com + mật khẩu
- **Số điện thoại**: 0901234567 + mật khẩu
- Hỗ trợ định dạng: 0901234567, +84901234567, 84901234567

### Đăng ký tài khoản
- Chọn đăng ký bằng email hoặc số điện thoại
- Email: Cần xác thực qua email
- Số điện thoại: Có thể sử dụng ngay sau đăng ký

### Phân quyền người dùng
- **Super Admin**: Quản lý toàn bộ hệ thống
- **Household Owner**: Chủ hộ kinh doanh, quản lý cửa hàng  
- **Seller**: Nhân viên bán hàng, tạo đơn hàng
- **Accountant**: Nhân viên kế toán, quản lý tài chính

## 🎯 Implementation Status

### ✅ Đã hoàn thành (Week 1)
- [x] Khởi tạo Next.js project với TypeScript
- [x] Cài đặt và cấu hình shadcn/ui
- [x] Setup Supabase client (browser & server)
- [x] Cấu hình authentication middleware
- [x] Tạo auth context và providers
- [x] Layout cơ bản cho auth và dashboard
- [x] Trang login cơ bản
- [x] Dashboard home page
- [x] TypeScript types definition
- [x] Project structure setup

### 🔄 Đang triển khai (Week 2)
- [ ] Database schema implementation
- [ ] User registration flow
- [ ] Business onboarding
- [ ] Product management CRUD
- [ ] Basic POS interface

### 📋 Sắp tới
- [ ] Customer management
- [ ] Order processing
- [ ] Inventory tracking
- [ ] Subscription system
- [ ] Super admin panel
- [ ] Reporting & analytics

## 🛠️ Development

### Scripts
```bash
npm run dev        # Start development server
npm run build      # Build for production
npm run start      # Start production server
npm run lint       # Run ESLint
npm run type-check # Run TypeScript check
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## 📄 License

Dự án này được cấp phép theo [MIT License](LICENSE).

## 📞 Hỗ trợ

- Email: support@posmodular.com
- Documentation: [docs.posmodular.com](https://docs.posmodular.com)
- Issues: [GitHub Issues](https://github.com/your-username/pos-mini-modular/issues)

## 📱 Trang và tính năng hiện tại

### 🏠 Landing Page (/)
- ✅ Hero section với branding Supabase-style
- ✅ Feature showcase với icons và descriptions
- ✅ CTA buttons cho đăng ký và đăng nhập
- ✅ Responsive design cho mọi device

### 🔐 Authentication Pages
- ✅ **Login Page** (/login)
  - Đăng nhập bằng email hoặc số điện thoại
  - Smart detection và validation real-time
  - Visual indicators cho input type
  - Remember me và forgot password links
  
- ✅ **Register Page** (/register)
  - Đăng ký với email hoặc phone
  - Business information collection
  - Password confirmation
  - Terms acceptance checkbox

### 🎛️ Dashboard Layout
- ✅ **Top Navigation Bar**
  - Logo và branding
  - Navigation menu (desktop)
  - User avatar dropdown với profile/settings/logout
  
- ✅ **Main Dashboard** (/dashboard)
  - Statistics cards với icons và animations
  - Quick action items với progress tracking
  - Recent activity feed
  - Feature cards cho các module tương lai
  
- ✅ **Mobile Navigation**
  - Bottom tab bar cho mobile
  - Responsive breakpoints
  - Touch-friendly interface

### 🧪 Development Tools
- ✅ **TestConnection Component**
  - Real-time Supabase connection status
  - Environment variables validation
  - Debug information display

## 🎨 Design System

### Color Palette (Supabase-inspired)
```css
/* Primary Colors */
--primary: oklch(0.646 0.222 142);     /* Supabase Green */
--primary-foreground: oklch(0.985 0 0); /* White */

/* Background Colors */
--background: oklch(1 0 0);             /* Pure White */
--foreground: oklch(0.145 0 0);         /* Near Black */

/* UI Colors */
--muted: oklch(0.97 0 0);              /* Light Gray */
--border: oklch(0.922 0 0);            /* Border Gray */
--card: oklch(1 0 0);                  /* Card Background */
```

### Typography
- **Font Family**: Inter (system fallback)
- **Font Weights**: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)
- **Line Heights**: Optimized for Vietnamese text

### Spacing & Layout
- **Container**: Max-width với responsive padding
- **Grid System**: CSS Grid với responsive breakpoints
- **Shadows**: Subtle elevation với Supabase-style shadows
