/**
 * Enhanced session logging utility with server-side visibility
 * Provides comprehensive logging for session management operations
 */
export class SessionLogger {
  generateTraceId(): string {
    return `trace_${Date.now()}_${Math.random().toString(36).substring(2)}`;
  }

  private formatLogMessage(level: string, message: string, context: Record<string, unknown> = {}): string {
    const timestamp = new Date().toISOString();
    const contextStr = Object.keys(context).length > 0 ? JSON.stringify(context, null, 2) : '';
    return `\n🔐 [${level}] ${timestamp} - ${message}${contextStr ? '\n   📄 Context: ' + contextStr : ''}`;
  }

  info(message: string, context: Record<string, unknown> = {}): void {
    const logMessage = this.formatLogMessage('SESSION_INFO', message, context);
    console.log(logMessage);
  }

  error(message: string, context: Record<string, unknown> = {}): void {
    const logMessage = this.formatLogMessage('SESSION_ERROR', message, context);
    console.error(logMessage);
  }

  debug(message: string, context: Record<string, unknown> = {}): void {
    if (process.env.NODE_ENV === 'development') {
      const logMessage = this.formatLogMessage('SESSION_DEBUG', message, context);
      console.debug(logMessage);
    }
  }

  warn(message: string, context: Record<string, unknown> = {}): void {
    const logMessage = this.formatLogMessage('SESSION_WARN', message, context);
    console.warn(logMessage);
  }

  // Special logout logging with enhanced visibility
  logLogout(message: string, context: Record<string, unknown> = {}): void {
    console.log('\n🚪 =================== LOGOUT EVENT ===================');
    console.log(`📅 ${new Date().toISOString()}`);
    console.log(`🔐 ${message}`);
    
    if (Object.keys(context).length > 0) {
      console.log('📋 Logout Details:');
      Object.entries(context).forEach(([key, value]) => {
        console.log(`   • ${key}: ${JSON.stringify(value)}`);
      });
    }
    
    console.log('🚪 =====================================================\n');
  }
}

export const sessionLogger = new SessionLogger();
