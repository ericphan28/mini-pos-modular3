
export default async function BusinessesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Sử dụng layout chung - không cần duplicate logic
  return <>{children}</>;
}