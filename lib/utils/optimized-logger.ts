type LogLevel = 'info' | 'success' | 'warn' | 'error' | 'debug';

interface LogEntry {
  readonly level: LogLevel;
  readonly step: string;
  readonly message: string;
  readonly data?: string;
  readonly timestamp: string;
}

interface LogConfig {
  readonly maxDataSize: number;
  readonly enabledLevels: readonly LogLevel[];
  readonly enableInProduction: boolean;
  readonly batchSize: number;
  readonly batchDelay: number;
}

export class OptimizedTerminalLogger {
  private readonly config: LogConfig = {
    maxDataSize: 500, // Max 500 chars for data
    enabledLevels: ['info', 'success', 'warn', 'error'],
    enableInProduction: false,
    batchSize: 5, // Giảm xuống 5 để batch nhanh hơn
    batchDelay: 50, // Giảm xuống 50ms để responsive hơn
  };

  private logQueue: LogEntry[] = [];
  private batchTimeout: NodeJS.Timeout | null = null;
  private isProduction: boolean;

  constructor() {
    this.isProduction = typeof window !== 'undefined' 
      ? window.location.hostname !== 'localhost' 
      : process.env.NODE_ENV === 'production';
  }

  private shouldLog(level: LogLevel): boolean {
    if (!this.config.enableInProduction && this.isProduction) {
      return level === 'error' || level === 'warn'; // Only errors in production
    }
    return this.config.enabledLevels.includes(level);
  }

  private truncateData(data: unknown): string {
    if (!data) return '';
    
    let dataStr: string;
    try {
      dataStr = typeof data === 'string' ? data : JSON.stringify(data);
    } catch (_error: unknown) {
      dataStr = '[Circular or non-serializable data]';
    }
    
    if (dataStr.length > this.config.maxDataSize) {
      return dataStr.substring(0, this.config.maxDataSize) + '...[truncated]';
    }
    
    return dataStr;
  }

  public info(step: string, message: string, data?: unknown): void {
    if (!this.shouldLog('info')) return;
    this.addToQueue('info', step, message, data);
  }

  public success(step: string, message: string, data?: unknown): void {
    if (!this.shouldLog('success')) return;
    this.addToQueue('success', step, message, data);
  }

  public warn(step: string, message: string, data?: unknown): void {
    if (!this.shouldLog('warn')) return;
    this.addToQueue('warn', step, message, data);
  }

  public error(step: string, message: string, data?: unknown): void {
    if (!this.shouldLog('error')) return;
    this.addToQueue('error', step, message, data);
  }

  public debug(step: string, message: string, data?: unknown): void {
    if (!this.shouldLog('debug')) return;
    this.addToQueue('debug', step, message, data);
  }

  private addToQueue(level: LogLevel, step: string, message: string, data?: unknown): void {
    const truncatedData = this.truncateData(data);
    
    this.logQueue.push({
      level,
      step,
      message,
      data: truncatedData,
      timestamp: new Date().toISOString(),
    });
    
    // Auto-flush if queue is full
    if (this.logQueue.length >= this.config.batchSize) {
      this.flushLogs();
      return;
    }
    
    // Schedule batch flush
    if (this.batchTimeout) {
      clearTimeout(this.batchTimeout);
    }
    
    this.batchTimeout = setTimeout(() => {
      this.flushLogs();
    }, this.config.batchDelay);
  }

  private flushLogs(): void {
    if (this.logQueue.length === 0) return;
    
    const logsToSend = [...this.logQueue];
    this.logQueue = [];
    
    if (this.batchTimeout) {
      clearTimeout(this.batchTimeout);
      this.batchTimeout = null;
    }
    
    // Try API first, fallback to console
    this.sendToAPI(logsToSend).catch(() => {
      this.fallbackToConsole(logsToSend);
    });
  }

  private async sendToAPI(logs: readonly LogEntry[]): Promise<void> {
    if (typeof window === 'undefined') {
      throw new Error('Cannot send to API from server side');
    }
    
    const response = await fetch('/api/terminal-log-batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ logs }),
    });
    
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`);
    }
  }

  private fallbackToConsole(logs: readonly LogEntry[]): void {
    logs.forEach(log => {
      const emoji = this.getLevelEmoji(log.level);
      const timestamp = new Date(log.timestamp).toLocaleTimeString('vi-VN');
      
      console.log(
        `${emoji} [${timestamp}] ${log.step.toUpperCase()}: ${log.message}`,
        log.data || ''
      );
    });
  }

  private getLevelEmoji(level: LogLevel): string {
    switch (level) {
      case 'success': return '✅';
      case 'error': return '❌';
      case 'warn': return '⚠️';
      case 'debug': return '🔍';
      default: return '🔵';
    }
  }

  public forceFlush(): void {
    this.flushLogs();
  }

  public clear(): void {
    this.logQueue = [];
    if (this.batchTimeout) {
      clearTimeout(this.batchTimeout);
      this.batchTimeout = null;
    }
  }
}

// Export singleton instance
export const optimizedLogger = new OptimizedTerminalLogger();
