# 📊 Hệ thống Logger Chuyên nghiệp - POS Mini Modular 3

## 🎯 Tổng quan

Hệ thống logging enterprise-grade được thiết kế đặc biệt cho POS Mini Modular 3, hỗ trợ:
- **Multi-tenant logging** với business isolation
- **Vietnamese business context** và compliance
- **Performance monitoring** và error tracking
- **Development-friendly** console output
- **Production-ready** structured logging

## 🏗️ Kiến trúc Hệ thống

```
lib/logger/
├── core/
│   ├── types.ts              # TypeScript interfaces
│   ├── constants.ts          # Log levels, categories, events
│   └── logger.service.ts     # Core logger service
├── transports/
│   └── console.transport.ts  # Console output transport
├── categories/
│   ├── auth.logger.ts        # Authentication logging
│   └── business.logger.ts    # Business operations logging
├── utils/                    # Utility functions
└── index.ts                  # Main export file
```

## 🚀 Quick Start

### Import Logger

```typescript
import { logger, authLogger, businessLogger, setLoggerContext } from '@/lib/logger';
```

### Basic Usage

```typescript
// Set context cho multi-tenant
setLoggerContext({
  user_id: 'user_123',
  business_id: 'business_456',
  session_id: 'session_789'
});

// Basic logging
await logger.info('CATEGORY', 'EVENT', 'Message', { data: 'value' });
await logger.error('CATEGORY', 'ERROR_EVENT', 'Error message', error, { context: 'info' });
```

### Authentication Logging

```typescript
// Login attempt
await authLogger.loginAttempt({
  email: 'user@example.com',
  method: 'email',
  ip_address: '192.168.1.1',
  user_agent: navigator.userAgent
});

// Login success
await authLogger.loginSuccess({
  user_id: 'user_123',
  email: 'user@example.com',
  business_id: 'business_456',
  role: 'manager',
  login_method: 'email'
}, {
  session_id: 'session_789',
  ip_address: '192.168.1.1'
});

// Login failure
await authLogger.loginFailed({
  reason: 'Invalid credentials',
  email: 'user@example.com',
  ip_address: '192.168.1.1',
  error_code: 'AUTH_FAILED'
});
```

### Business Operations Logging

```typescript
// Product creation
await businessLogger.productCreated({
  id: 'product_123',
  name: 'Coca Cola 330ml',
  price: 15000,
  category: 'beverages'
}, {
  user_id: 'user_123',
  business_id: 'business_456'
});

// Order completion
await businessLogger.orderCompleted({
  id: 'order_123',
  total: 45000,
  items_count: 3,
  payment_method: 'cash',
  customer_id: 'customer_123'
}, userContext);

// Performance tracking
const result = await businessLogger.performanceTrack(
  'CREATE_PRODUCT',
  { business_id: 'business_456' },
  async () => {
    // Your business logic here
    return await createProductInDatabase(productData);
  }
);
```

## 📊 Log Categories

### Predefined Categories

| Category | Emoji | Description |
|----------|-------|-------------|
| AUTH | 🔐 | Authentication & Authorization |
| BUSINESS | 💼 | Business Operations |
| SECURITY | 🛡️ | Security Events |
| PERFORMANCE | ⚡ | Performance Monitoring |
| AUDIT | 📋 | Compliance & Audit Trail |
| ERROR | ❌ | Application Errors |
| USER | 👤 | User Interactions |
| SYSTEM | ⚙️ | System Health |

### Vietnamese Business Events

```typescript
VIETNAMESE_BUSINESS_EVENTS = {
  PRODUCT_CREATED: 'Tạo sản phẩm mới',
  ORDER_COMPLETED: 'Hoàn thành đơn hàng',
  PAYMENT_PROCESSED: 'Xử lý thanh toán',
  INVENTORY_UPDATED: 'Cập nhật tồn kho',
  USER_LOGIN: 'Đăng nhập người dùng',
  BUSINESS_REGISTERED: 'Đăng ký hộ kinh doanh'
  // ... more events
}
```

## 🎨 Development Experience

### Console Output Format

```
🔐 [AUTH] 14:30:25 | Đăng nhập người dùng
   └─ User: user_123
   └─ Business: business_456
   └─ Duration: 150ms
   └─ Data: { login_method: 'email', role: 'manager' }
```

### Environment Detection

- **Development**: Rich console output với colors và formatting
- **Production**: Structured JSON logging
- **Auto-detection**: Dựa trên hostname và NODE_ENV

## 🔒 Security & Privacy

### Automatic Data Masking

```typescript
// Email masking: abc***@domain.com
// Phone masking: 098****567
// Password masking: ***MASKED***
```

### Sensitive Data Protection

- Auto-detect và mask PII (email, phone, passwords)
- Environment-based masking (production only)
- Configurable masking rules

## 📈 Performance Features

### Performance Tracking

```typescript
const result = await logger.performance(
  'CATEGORY',
  'OPERATION',
  async () => {
    // Your operation here
    return await someAsyncOperation();
  }
);
```

### Performance Levels

- **FAST**: < 100ms ✅
- **NORMAL**: 100-500ms ⚠️
- **SLOW**: 500ms-1s 🐌
- **CRITICAL**: > 1s 🚨

## 🇻🇳 Vietnamese Compliance

### Legal Requirements

- **Financial logs**: 10 năm retention (Vietnamese accounting law)
- **User activity**: 2 năm (GDPR compliance)
- **Tax compliance**: Ready cho e-invoice integration
- **Audit trail**: Full business operations tracking

### Multi-tenant Support

- Business-level isolation
- User permission tracking
- Cross-business security monitoring

## 🧪 Testing & Debugging

### Test Page

Truy cập `/test-logger` để test tất cả logger functions:

- Basic logging tests
- Authentication scenarios
- Business operations
- Performance tracking
- Error scenarios

### Debug Console

```typescript
// Enable debug logging
process.env.LOG_LEVEL = 'DEBUG';

// View all logs in console
// Structured data inspection
// Performance metrics display
```

## ⚙️ Configuration

### Environment Variables

```bash
# Log level
LOG_LEVEL=DEBUG|INFO|WARN|ERROR

# Public log level (client-side)
NEXT_PUBLIC_LOG_LEVEL=INFO

# Environment detection
NODE_ENV=development|production
VERCEL_ENV=preview|production
```

### Advanced Configuration

```typescript
const customConfig: LoggerConfig = {
  level: 'INFO',
  environment: 'production',
  transports: [consoleTransport, fileTransport, databaseTransport],
  enablePerformanceTracking: true,
  enableContextInjection: true,
  enableDataMasking: true
};

const customLogger = new LoggerService(customConfig);
```

## 🔄 Integration Examples

### Login Form Integration

```typescript
// Set context
setLoggerContext({
  ip_address: req.ip,
  user_agent: req.headers['user-agent'],
  request_id: generateRequestId()
});

// Log attempt
await authLogger.loginAttempt({ email, method: 'email', ip_address, user_agent });

// Log success/failure
if (success) {
  await authLogger.loginSuccess(userData, sessionData);
} else {
  await authLogger.loginFailed({ reason, email, ip_address });
}
```

### Business Service Integration

```typescript
export class ProductService {
  async createProduct(data: ProductData, context: UserContext) {
    return await businessLogger.performanceTrack(
      'CREATE_PRODUCT',
      context,
      async () => {
        const product = await this.database.insert(data);
        await businessLogger.productCreated(product, context);
        return product;
      }
    );
  }
}
```

### Middleware Integration

```typescript
export async function middleware(request: NextRequest) {
  const startTime = Date.now();
  
  logger.setContext({
    request_id: generateId(),
    ip_address: request.ip,
    user_agent: request.headers.get('user-agent')
  });

  const response = NextResponse.next();
  
  await logger.info('SYSTEM', 'REQUEST_COMPLETED', 
    `${request.method} ${request.nextUrl.pathname}`, {
      duration_ms: Date.now() - startTime,
      status: response.status
    }
  );

  return response;
}
```

## 🚀 Roadmap & Enhancements

### Phase 1: Core (✅ Completed)
- [x] Core logger service
- [x] Console transport
- [x] Auth & Business categories
- [x] Performance tracking
- [x] Vietnamese events

### Phase 2: Advanced (🔄 In Progress)
- [ ] File transport với rotation
- [ ] Database transport với retry
- [ ] Real-time monitoring dashboard
- [ ] Alert system integration

### Phase 3: Enterprise (📋 Planned)
- [ ] Supabase transport
- [ ] External monitoring (Datadog, Sentry)
- [ ] Advanced analytics
- [ ] Compliance automation

## 🏆 Best Practices

### Development
1. Always set context trước khi log
2. Use specific categories và events
3. Include relevant data cho debugging
4. Test performance impact

### Production
1. Set appropriate log levels
2. Monitor log volume
3. Setup alerts cho critical events
4. Regular log cleanup

### Compliance
1. Mask sensitive data automatically
2. Retain logs theo legal requirements
3. Audit trail cho financial operations
4. Security event monitoring

## 🆘 Troubleshooting

### Common Issues

**Logger không hoạt động:**
```typescript
// Check imports
import { logger } from '@/lib/logger'; // ✅ Correct

// Set context
setLoggerContext({ user_id: 'test' }); // ✅ Required for multi-tenant
```

**Performance issues:**
```typescript
// Use appropriate log levels
if (process.env.NODE_ENV === 'production') {
  logger.config.level = 'INFO'; // Skip DEBUG logs
}
```

**Memory leaks:**
```typescript
// Cleanup on app shutdown
process.on('SIGTERM', async () => {
  await logger.close();
});
```

---

## 📞 Support

- **Documentation**: `/docs/logger/`
- **Test Page**: `/test-logger`
- **Examples**: `/lib/services/business.service.ts`
- **Issues**: Create ticket với logger category

Hệ thống logger này đã sẵn sàng cho production và sẽ scale cùng với POS Mini Modular 3! 🚀
