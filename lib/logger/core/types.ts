export interface LogLevel {
  readonly value: number;
  readonly name: string;
  readonly color?: string;
}

export interface LogCategory {
  readonly name: string;
  readonly description: string;
  readonly emoji: string;
}

export interface LogContext {
  readonly user_id?: string;
  readonly business_id?: string;
  readonly session_id?: string;
  readonly request_id?: string;
  readonly ip_address?: string;
  readonly user_agent?: string;
  readonly timestamp: string;
}

export interface LogEntry {
  readonly timestamp: string;
  readonly level: string;
  readonly category: string;
  readonly event: string;
  readonly message: string;
  readonly context: LogContext;
  readonly data?: Record<string, unknown>;
  readonly error?: {
    readonly name: string;
    readonly message: string;
    readonly stack?: string;
  };
  readonly trace_id?: string;
  readonly duration_ms?: number;
}

export interface LogTransport {
  log(entry: LogEntry): Promise<void>;
  logBatch?(entries: readonly LogEntry[]): Promise<void>;
  flush?(): Promise<void>;
  close?(): Promise<void>;
}

export interface LoggerConfig {
  readonly level: string;
  readonly environment: 'development' | 'staging' | 'production';
  readonly transports: readonly LogTransport[];
  readonly enablePerformanceTracking: boolean;
  readonly enableContextInjection: boolean;
  readonly enableDataMasking: boolean;
  readonly bufferSize?: number;
  readonly flushInterval?: number;
}

export interface BufferedLoggerConfig extends LoggerConfig {
  readonly maxBufferSize: number;
  readonly flushIntervalMs: number;
}
