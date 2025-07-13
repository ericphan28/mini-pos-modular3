import type { LogEntry, LoggerConfig, LogContext, LogTransport } from './types';
import { LOG_LEVELS } from './constants';

export class LoggerService {
  protected config: LoggerConfig;
  protected context: Partial<LogContext> = {};

  constructor(config: LoggerConfig) {
    this.config = config;
  }

  public setContext(context: Partial<LogContext>): void {
    this.context = { ...this.context, ...context };
  }

  public clearContext(): void {
    this.context = {};
  }

  public async log(
    level: keyof typeof LOG_LEVELS,
    category: string,
    event: string,
    message: string,
    data?: Record<string, unknown>,
    error?: Error
  ): Promise<void> {
    const logLevel = LOG_LEVELS[level];
    const configLevel = LOG_LEVELS[this.config.level as keyof typeof LOG_LEVELS];

    if (!logLevel || !configLevel || logLevel.value > configLevel.value) {
      return;
    }

    const entry = this.createLogEntry(level, category, event, message, data, error);
    await this.writeToTransports(entry);
  }

  public async info(
    category: string,
    event: string,
    message: string,
    data?: Record<string, unknown>
  ): Promise<void> {
    await this.log('INFO', category, event, message, data);
  }

  public async warn(
    category: string,
    event: string,
    message: string,
    data?: Record<string, unknown>
  ): Promise<void> {
    await this.log('WARN', category, event, message, data);
  }

  public async error(
    category: string,
    event: string,
    message: string,
    error?: Error,
    data?: Record<string, unknown>
  ): Promise<void> {
    await this.log('ERROR', category, event, message, data, error);
  }

  public async debug(
    category: string,
    event: string,
    message: string,
    data?: Record<string, unknown>
  ): Promise<void> {
    await this.log('DEBUG', category, event, message, data);
  }

  public async performance<T>(
    category: string,
    event: string,
    operation: () => Promise<T>,
    context?: Record<string, unknown>
  ): Promise<T> {
    if (!this.config.enablePerformanceTracking) {
      return await operation();
    }

    const startTime = Date.now();
    const traceId = this.generateTraceId();
    
    // Log operation start
    await this.debug(
      category,
      `${event}_STARTED`,
      `Bắt đầu thực hiện: ${event}`,
      { ...context, trace_id: traceId }
    );
    
    try {
      const result = await operation();
      const duration = Date.now() - startTime;
      
      await this.info(
        category,
        `${event}_COMPLETED`,
        `Hoàn thành thực hiện: ${event}`,
        {
          ...context,
          duration_ms: duration,
          success: true,
          trace_id: traceId,
          performance_level: this.getPerformanceLevel(duration),
        }
      );
      
      return result;
    } catch (error: unknown) {
      const duration = Date.now() - startTime;
      const errorObj = error instanceof Error ? error : new Error('Unknown error');
      
      await this.error(
        category,
        `${event}_FAILED`,
        `Thất bại thực hiện: ${event}`,
        errorObj,
        {
          ...context,
          duration_ms: duration,
          success: false,
          trace_id: traceId,
        }
      );
      
      throw error;
    }
  }

  protected createLogEntry(
    level: keyof typeof LOG_LEVELS,
    category: string,
    event: string,
    message: string,
    data?: Record<string, unknown>,
    error?: Error
  ): LogEntry {
    const logLevel = LOG_LEVELS[level];
    
    return {
      timestamp: new Date().toISOString(),
      level: logLevel.name,
      category,
      event,
      message,
      context: {
        ...this.context,
        timestamp: new Date().toISOString(),
      },
      data: this.config.enableDataMasking ? this.maskSensitiveData(data) : data,
      error: error ? {
        name: error.name,
        message: error.message,
        stack: this.config.environment === 'development' ? error.stack : undefined,
      } : undefined,
      trace_id: this.generateTraceId(),
    };
  }

  protected async writeToTransports(entry: LogEntry): Promise<void> {
    const promises = this.config.transports.map(async (transport: LogTransport) => {
      try {
        await transport.log(entry);
      } catch (error: unknown) {
        // Fallback để tránh logger crash app
        if (this.config.environment === 'development') {
          console.error('Logger transport failed:', error);
        }
      }
    });

    await Promise.allSettled(promises);
  }

  protected generateTraceId(): string {
    return `trace_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  protected getPerformanceLevel(duration: number): string {
    if (duration < 100) return 'FAST';
    if (duration < 500) return 'NORMAL';
    if (duration < 1000) return 'SLOW';
    return 'CRITICAL';
  }

  protected maskSensitiveData(data?: Record<string, unknown>): Record<string, unknown> | undefined {
    if (!data) return data;

    const sensitiveKeys = ['password', 'token', 'secret', 'key', 'auth', 'credential'];
    const masked = { ...data };

    for (const [key, value] of Object.entries(masked)) {
      const lowerKey = key.toLowerCase();
      if (sensitiveKeys.some(sensitive => lowerKey.includes(sensitive))) {
        masked[key] = '***MASKED***';
      } else if (typeof value === 'string' && this.isEmail(value)) {
        masked[key] = this.maskEmail(value);
      } else if (typeof value === 'string' && this.isPhone(value)) {
        masked[key] = this.maskPhone(value);
      }
    }

    return masked;
  }

  private isEmail(value: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  }

  private isPhone(value: string): boolean {
    return /^[\+]?[0-9\s\-\(\)]{8,}$/.test(value);
  }

  private maskEmail(email: string): string {
    const [username, domain] = email.split('@');
    const maskedUsername = username.length > 3 ? 
      username.substring(0, 3) + '***' : 
      '***';
    return `${maskedUsername}@${domain}`;
  }

  private maskPhone(phone: string): string {
    const cleaned = phone.replace(/\D/g, '');
    if (cleaned.length < 6) return '***';
    
    const start = cleaned.substring(0, 3);
    const end = cleaned.substring(cleaned.length - 3);
    return `${start}***${end}`;
  }

  public async flush(): Promise<void> {
    const promises = this.config.transports
      .filter((transport): transport is LogTransport & { flush: () => Promise<void> } => 
        transport.flush !== undefined
      )
      .map((transport) => transport.flush());
    
    await Promise.allSettled(promises);
  }

  public async close(): Promise<void> {
    await this.flush();
    
    const promises = this.config.transports
      .filter((transport): transport is LogTransport & { close: () => Promise<void> } => 
        transport.close !== undefined
      )
      .map((transport) => transport.close());
    
    await Promise.allSettled(promises);
  }
}
