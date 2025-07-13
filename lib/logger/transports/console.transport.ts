import type { LogEntry, LogTransport } from '../core/types';
import { LOG_CATEGORIES, PERFORMANCE_THRESHOLDS } from '../core/constants';

export class ConsoleTransport implements LogTransport {
  private readonly isDevelopment: boolean;

  constructor(environment: string = 'development') {
    this.isDevelopment = environment === 'development';
  }

  public async log(entry: LogEntry): Promise<void> {
    if (this.isDevelopment) {
      this.logDevelopmentFormat(entry);
    } else {
      this.logProductionFormat(entry);
    }
  }

  private logDevelopmentFormat(entry: LogEntry): void {
    const category = LOG_CATEGORIES[entry.category as keyof typeof LOG_CATEGORIES];
    const emoji = category?.emoji || '📝';
    const timestamp = new Date(entry.timestamp).toLocaleTimeString('vi-VN');
    
    const levelColors = {
      ERROR: '\x1b[31m', // Red
      WARN: '\x1b[33m',  // Yellow
      INFO: '\x1b[36m',  // Cyan
      DEBUG: '\x1b[90m', // Gray
    };
    
    const reset = '\x1b[0m';
    const bold = '\x1b[1m';
    const dim = '\x1b[2m';
    const color = levelColors[entry.level as keyof typeof levelColors] || '';
    
    // Main log line
    console.log(
      `${emoji} ${bold}[${entry.category}]${reset} ${color}${timestamp}${reset} | ${entry.message}`
    );
    
    // Context information
    if (entry.context.user_id) {
      console.log(`   ${dim}└─ User: ${entry.context.user_id}${reset}`);
    }
    
    if (entry.context.business_id) {
      console.log(`   ${dim}└─ Business: ${entry.context.business_id}${reset}`);
    }

    if (entry.context.request_id) {
      console.log(`   ${dim}└─ Request: ${entry.context.request_id}${reset}`);
    }
    
    // Performance information
    if (entry.duration_ms !== undefined) {
      const perfColor = this.getPerformanceColor(entry.duration_ms);
      console.log(`   ${dim}└─ Duration: ${perfColor}${entry.duration_ms}ms${reset}`);
    }
    
    // Data payload
    if (entry.data && Object.keys(entry.data).length > 0) {
      console.log(`   ${dim}└─ Data:${reset}`, this.formatData(entry.data));
    }
    
    // Error information
    if (entry.error) {
      console.log(`   ${dim}└─ Error: ${color}${entry.error.message}${reset}`);
      if (entry.error.stack && this.isDevelopment) {
        const stackLines = entry.error.stack.split('\n').slice(1, 4); // Show top 3 stack frames
        stackLines.forEach(line => {
          console.log(`     ${dim}${line.trim()}${reset}`);
        });
      }
    }

    // Trace ID for debugging
    if (entry.trace_id) {
      console.log(`   ${dim}└─ Trace: ${entry.trace_id}${reset}`);
    }

    console.log(); // Empty line for readability
  }

  private logProductionFormat(entry: LogEntry): void {
    // Simple JSON format for production
    const productionEntry = {
      timestamp: entry.timestamp,
      level: entry.level,
      category: entry.category,
      event: entry.event,
      message: entry.message,
      ...(entry.context.user_id && { user_id: entry.context.user_id }),
      ...(entry.context.business_id && { business_id: entry.context.business_id }),
      ...(entry.duration_ms && { duration_ms: entry.duration_ms }),
      ...(entry.data && { data: entry.data }),
      ...(entry.error && { error: entry.error.message }),
    };

    console.log(JSON.stringify(productionEntry));
  }

  private getPerformanceColor(duration: number): string {
    if (duration < PERFORMANCE_THRESHOLDS.FAST) return '\x1b[32m'; // Green
    if (duration < PERFORMANCE_THRESHOLDS.NORMAL) return '\x1b[33m'; // Yellow
    if (duration < PERFORMANCE_THRESHOLDS.SLOW) return '\x1b[31m'; // Red
    return '\x1b[35m'; // Magenta for critical
  }

  private formatData(data: Record<string, unknown>): Record<string, unknown> {
    // Format data for better readability in development
    const formatted: Record<string, unknown> = {};
    
    for (const [key, value] of Object.entries(data)) {
      if (typeof value === 'string' && value.length > 100) {
        formatted[key] = `${value.substring(0, 97)}...`;
      } else if (Array.isArray(value) && value.length > 5) {
        formatted[key] = [...value.slice(0, 5), `... và ${value.length - 5} mục khác`];
      } else {
        formatted[key] = value;
      }
    }
    
    return formatted;
  }

  public async logBatch(entries: readonly LogEntry[]): Promise<void> {
    for (const entry of entries) {
      await this.log(entry);
    }
  }

  public async flush(): Promise<void> {
    // Console doesn't need flushing
  }

  public async close(): Promise<void> {
    // Console doesn't need closing
  }
}
