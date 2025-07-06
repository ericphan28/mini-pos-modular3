<a href="https://demo-nextjs-with-supabase.vercel.app/">
  <img alt="POS Mini Modular - Hệ thống quản lý bán hàng cho hộ kinh doanh Việt Nam" src="https://demo-nextjs-with-supabase.vercel.app/opengraph-image.png">
  <h1 align="center">POS Mini Modular</h1>
</a>

<p align="center">
 Hệ thống quản lý bán hàng hiện đại được thiết kế đặc biệt cho các hộ kinh doanh tại Việt Nam
</p>

<p align="center">
  <a href="#tính-năng"><strong>Tính năng</strong></a> ·
  <a href="#demo"><strong>Demo</strong></a> ·
  <a href="#triển-khai-lên-vercel"><strong>Triển khai lên Vercel</strong></a> ·
  <a href="#clone-và-chạy-local"><strong>Clone và chạy local</strong></a> ·
  <a href="#phản-hồi-và-báo-lỗi"><strong>Phản hồi và báo lỗi</strong></a>
  <a href="#thêm-ví-dụ-supabase"><strong>Thêm ví dụ</strong></a>
</p>
<br/>

## Tính năng

- Hoạt động trên toàn bộ stack [Next.js](https://nextjs.org)
  - App Router
  - Pages Router  
  - Middleware
  - Client
  - Server
  - Hoạt động hoàn hảo!
- supabase-ssr. Package để cấu hình Supabase Auth sử dụng cookies
- Xác thực bằng mật khẩu thông qua [Supabase UI Library](https://supabase.com/ui/docs/nextjs/password-based-auth)
- Styling với [Tailwind CSS](https://tailwindcss.com)
- Components với [shadcn/ui](https://ui.shadcn.com/)
- Tùy chọn triển khai với [Supabase Vercel Integration và Vercel deploy](#deploy-your-own)
  - Environment variables tự động được gán cho Vercel project

## Demo

Bạn có thể xem demo hoạt động đầy đủ tại [demo-nextjs-with-supabase.vercel.app](https://demo-nextjs-with-supabase.vercel.app/).

## Triển khai lên Vercel

Triển khai Vercel sẽ hướng dẫn bạn tạo tài khoản và dự án Supabase.

Sau khi cài đặt Supabase integration, tất cả environment variables liên quan sẽ được gán cho project để triển khai hoạt động đầy đủ.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fvercel%2Fnext.js%2Ftree%2Fcanary%2Fexamples%2Fwith-supabase&project-name=nextjs-with-supabase&repository-name=nextjs-with-supabase&demo-title=nextjs-with-supabase&demo-description=This+starter+configures+Supabase+Auth+to+use+cookies%2C+making+the+user%27s+session+available+throughout+the+entire+Next.js+app+-+Client+Components%2C+Server+Components%2C+Route+Handlers%2C+Server+Actions+and+Middleware.&demo-url=https%3A%2F%2Fdemo-nextjs-with-supabase.vercel.app%2F&external-id=https%3A%2F%2Fgithub.com%2Fvercel%2Fnext.js%2Ftree%2Fcanary%2Fexamples%2Fwith-supabase&demo-image=https%3A%2F%2Fdemo-nextjs-with-supabase.vercel.app%2Fopengraph-image.png)

The above will also clone the Starter kit to your GitHub, you can clone that locally and develop locally.

If you wish to just develop locally and not deploy to Vercel, [follow the steps below](#clone-and-run-locally).

## Clone and run locally

1. You'll first need a Supabase project which can be made [via the Supabase dashboard](https://database.new)

2. Create a Next.js app using the Supabase Starter template npx command

   ```bash
   npx create-next-app --example with-supabase with-supabase-app
   ```

   ```bash
   yarn create next-app --example with-supabase with-supabase-app
   ```

   ```bash
   pnpm create next-app --example with-supabase with-supabase-app
   ```

3. Use `cd` to change into the app's directory

   ```bash
   cd with-supabase-app
   ```

4. Rename `.env.example` to `.env.local` and update the following:

   ```
   NEXT_PUBLIC_SUPABASE_URL=[INSERT SUPABASE PROJECT URL]
   NEXT_PUBLIC_SUPABASE_ANON_KEY=[INSERT SUPABASE PROJECT API ANON KEY]
   ```

   Both `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` can be found in [your Supabase project's API settings](https://supabase.com/dashboard/project/_?showConnect=true)

5. You can now run the Next.js local development server:

   ```bash
   npm run dev
   ```

   The starter kit should now be running on [localhost:3000](http://localhost:3000/).

6. This template comes with the default shadcn/ui style initialized. If you instead want other ui.shadcn styles, delete `components.json` and [re-install shadcn/ui](https://ui.shadcn.com/docs/installation/next)

> Check out [the docs for Local Development](https://supabase.com/docs/guides/getting-started/local-development) to also run Supabase locally.

## Feedback and issues

Please file feedback and issues over on the [Supabase GitHub org](https://github.com/supabase/supabase/issues/new/choose).

## More Supabase examples

- [Next.js Subscription Payments Starter](https://github.com/vercel/nextjs-subscription-payments)
- [Cookie-based Auth and the Next.js 13 App Router (free course)](https://youtube.com/playlist?list=PL5S4mPUpp4OtMhpnp93EFSo42iQ40XjbF)
- [Supabase Auth and the Next.js App Router](https://github.com/supabase/supabase/tree/master/examples/auth/nextjs)
