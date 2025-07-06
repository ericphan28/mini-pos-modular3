import { ShoppingCart, Package, BarChart3, Users, Smartphone, Zap } from "lucide-react";

export function FeaturesSection() {
  const features = [
    {
      icon: Zap,
      title: "Bán hàng nhanh chóng",
      description: "Giao diện đơn giản, tốc độ xử lý nhanh cho mọi giao dịch. Quét mã vạch và thanh toán chỉ trong vài giây.",
      color: "from-yellow-400 to-orange-500"
    },
    {
      icon: Package,
      title: "Quản lý kho thông minh",
      description: "Theo dõi tồn kho realtime, cảnh báo hết hàng tự động, quản lý nhập xuất một cách khoa học.",
      color: "from-purple-400 to-purple-600"
    },
    {
      icon: BarChart3,
      title: "Báo cáo chi tiết",
      description: "Dashboard trực quan với biểu đồ thời gian thực. Phân tích doanh thu, lợi nhuận theo ngày/tháng/năm.",
      color: "from-blue-400 to-blue-600"
    },
    {
      icon: Users,
      title: "CRM khách hàng",
      description: "Lưu trữ thông tin khách hàng, lịch sử mua hàng, chương trình khuyến mãi và tích điểm thông minh.",
      color: "from-green-400 to-green-600"
    },
    {
      icon: Smartphone,
      title: "Đa nền tảng",
      description: "Hoạt động mượt mà trên máy tính, tablet và điện thoại. Đồng bộ dữ liệu real-time mọi lúc mọi nơi.",
      color: "from-pink-400 to-rose-500"
    },
    {
      icon: ShoppingCart,
      title: "POS hiện đại",
      description: "Giao diện POS trực quan, hỗ trợ nhiều phương thức thanh toán, in hóa đơn tự động và quản lý ca làm việc.",
      color: "from-indigo-400 to-indigo-600"
    }
  ];

  return (
    <section className="py-24 bg-gradient-to-b from-muted/50 to-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300 px-4 py-2 rounded-full text-sm font-medium mb-6">
            ✨ Tính năng nổi bật
          </div>
          <h2 className="text-4xl md:text-5xl font-bold text-foreground mb-6">
            Được thiết kế đặc biệt cho
            <br />
            <span className="bg-gradient-to-r from-primary to-emerald-600 bg-clip-text text-transparent">
              hộ kinh doanh Việt Nam
            </span>
          </h2>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
            Tất cả tính năng cần thiết để quản lý cửa hàng hiệu quả, 
            từ bán hàng đến quản lý kho, khách hàng và báo cáo chi tiết.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {features.map((feature, index) => (
            <div 
              key={index} 
              className="group bg-card rounded-2xl p-8 shadow-sm hover:shadow-xl transition-all duration-300 border border-border hover:border-border hover:-translate-y-1"
            >
              <div className={`w-14 h-14 bg-gradient-to-r ${feature.color} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300`}>
                <feature.icon className="w-7 h-7 text-white" />
              </div>
              <h3 className="text-xl font-bold text-foreground mb-4 group-hover:text-primary transition-colors">
                {feature.title}
              </h3>
              <p className="text-muted-foreground leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        {/* CTA Section */}
        <div className="text-center mt-16">
          <div className="bg-gradient-to-r from-primary to-emerald-600 rounded-3xl p-12 text-white max-w-4xl mx-auto">
            <h3 className="text-3xl font-bold mb-4">
              Sẵn sàng bắt đầu?
            </h3>
            <p className="text-green-100 text-lg mb-8 max-w-2xl mx-auto">
              Tham gia cùng hàng nghìn hộ kinh doanh đã tin tương và sử dụng POS Mini Modular
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="bg-white text-green-600 px-8 py-4 rounded-xl font-semibold hover:bg-gray-50 transition-colors">
                Dùng thử miễn phí
              </button>
              <button className="border-2 border-green-400 text-white px-8 py-4 rounded-xl font-semibold hover:bg-green-500 transition-colors">
                Xem demo
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
