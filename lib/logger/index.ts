import { LoggerService } from './core/logger.service';
import { ConsoleTransport } from './transports/console.transport';
import { BusinessLogger } from './categories/business.logger';
import { AuthLogger } from './categories/auth.logger';
import type { LoggerConfig } from './core/types';

// Environment detection
const getEnvironment = (): 'development' | 'staging' | 'production' => {
  if (typeof window !== 'undefined') {
    // Client-side detection
    if (window.location.hostname === 'localhost' || window.location.hostname.includes('127.0.0.1')) {
      return 'development';
    }
    if (window.location.hostname.includes('staging') || window.location.hostname.includes('dev')) {
      return 'staging';
    }
    return 'production';
  } else {
    // Server-side detection
    const nodeEnv = process.env.NODE_ENV;
    if (nodeEnv === 'production') return 'production';
    if (process.env.VERCEL_ENV === 'preview' || process.env.NODE_ENV?.includes('staging')) return 'staging';
    return 'development';
  }
};

const environment = getEnvironment();
const logLevel = process.env.NEXT_PUBLIC_LOG_LEVEL || 
  process.env.LOG_LEVEL || 
  (environment === 'production' ? 'INFO' : 'DEBUG');

// Create console transport
const consoleTransport = new ConsoleTransport(environment);

// Default configuration
const defaultConfig: LoggerConfig = {
  level: logLevel,
  environment,
  transports: [consoleTransport],
  enablePerformanceTracking: true,
  enableContextInjection: true,
  enableDataMasking: environment === 'production',
};

// Create logger instance
const loggerService = new LoggerService(defaultConfig);

// Category loggers
export const businessLogger = new BusinessLogger(loggerService);
export const authLogger = new AuthLogger(loggerService);

// Core logger for direct usage
export const logger = loggerService;

// Convenience functions for quick logging
export const logInfo = (category: string, event: string, message: string, data?: Record<string, unknown>): Promise<void> => {
  return logger.info(category, event, message, data);
};

export const logError = (category: string, event: string, message: string, error?: Error, data?: Record<string, unknown>): Promise<void> => {
  return logger.error(category, event, message, error, data);
};

export const logWarn = (category: string, event: string, message: string, data?: Record<string, unknown>): Promise<void> => {
  return logger.warn(category, event, message, data);
};

export const logDebug = (category: string, event: string, message: string, data?: Record<string, unknown>): Promise<void> => {
  return logger.debug(category, event, message, data);
};

// Performance tracking helper
export const trackPerformance = async <T>(
  category: string,
  operation: string,
  fn: () => Promise<T>,
  context?: Record<string, unknown>
): Promise<T> => {
  return await logger.performance(category, operation, fn, context);
};

// Context helpers
export const setLoggerContext = (context: Partial<{ 
  user_id: string; 
  business_id: string; 
  session_id: string; 
  request_id: string; 
  ip_address: string; 
  user_agent: string 
}>): void => {
  logger.setContext(context);
};

export const clearLoggerContext = (): void => {
  logger.clearContext();
};

// Graceful shutdown helper
export const shutdownLogger = async (): Promise<void> => {
  try {
    await logger.close();
  } catch (error: unknown) {
    console.error('Error during logger shutdown:', error);
  }
};

// Types export for external usage
export type { LogEntry, LogContext, LoggerConfig, LogTransport } from './core/types';
export { LOG_CATEGORIES, LOG_LEVELS, VIETNAMESE_BUSINESS_EVENTS } from './core/constants';

// Logger class exports for advanced usage
export { LoggerService } from './core/logger.service';
export { ConsoleTransport } from './transports/console.transport';
export { BusinessLogger } from './categories/business.logger';
export { AuthLogger } from './categories/auth.logger';
