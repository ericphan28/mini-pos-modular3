// lib/utils/terminal-logger.ts
interface LogEntry {
  timestamp: string;
  level: 'INFO' | 'SUCCESS' | 'WARN' | 'ERROR' | 'DEBUG';
  step: string;
  message: string;
  data?: unknown;
}

class TerminalLogger {
  private logBuffer: LogEntry[] = [];

  private formatLogEntry(entry: LogEntry): string {
    const icon = {
      INFO: '🔵',
      SUCCESS: '✅', 
      WARN: '⚠️',
      ERROR: '❌',
      DEBUG: '🔍'
    }[entry.level];

    const dataStr = entry.data ? JSON.stringify(entry.data, null, 2) : '';
    return `${icon} [${entry.timestamp}] ${entry.step}: ${entry.message}${dataStr ? '\n' + dataStr : ''}`;
  }

  private async sendToTerminal(entry: LogEntry): Promise<void> {
    try {
      // Gửi log đến API endpoint để in ra terminal
      await fetch('/api/terminal-log', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          formatted: this.formatLogEntry(entry),
          raw: entry
        })
      });
    } catch (error) {
      // Fallback to console if API fails
      console.warn('Terminal log failed, fallback to console:', error);
      console.log(this.formatLogEntry(entry));
    }
  }

  info(step: string, message: string, data?: unknown): void {
    const entry: LogEntry = {
      timestamp: new Date().toLocaleTimeString('vi-VN'),
      level: 'INFO',
      step,
      message,
      data
    };
    this.logBuffer.push(entry);
    this.sendToTerminal(entry);
  }

  success(step: string, message: string, data?: unknown): void {
    const entry: LogEntry = {
      timestamp: new Date().toLocaleTimeString('vi-VN'),
      level: 'SUCCESS',
      step,
      message,
      data
    };
    this.logBuffer.push(entry);
    this.sendToTerminal(entry);
  }

  warn(step: string, message: string, data?: unknown): void {
    const entry: LogEntry = {
      timestamp: new Date().toLocaleTimeString('vi-VN'),
      level: 'WARN',
      step,
      message,
      data
    };
    this.logBuffer.push(entry);
    this.sendToTerminal(entry);
  }

  error(step: string, message: string, data?: unknown): void {
    const entry: LogEntry = {
      timestamp: new Date().toLocaleTimeString('vi-VN'),
      level: 'ERROR',
      step,
      message,
      data
    };
    this.logBuffer.push(entry);
    this.sendToTerminal(entry);
  }

  debug(step: string, message: string, data?: unknown): void {
    const entry: LogEntry = {
      timestamp: new Date().toLocaleTimeString('vi-VN'),
      level: 'DEBUG',
      step,
      message,
      data
    };
    this.logBuffer.push(entry);
    this.sendToTerminal(entry);
  }

  // Get all logs for debugging
  getLogs(): LogEntry[] {
    return [...this.logBuffer];
  }

  // Clear log buffer
  clearLogs(): void {
    this.logBuffer = [];
  }
}

export const terminalLogger = new TerminalLogger();
