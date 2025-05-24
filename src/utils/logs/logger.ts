// ** Config
import { env } from "@/config/environment";

// ** Types
import type { LogLevel } from "@/types/common";

interface LoggerConfig {
  prettyPrint?: boolean;
  colors?: boolean;
}

// Enhanced logging utility with structured logging and pretty printing
export class Logger {
  private static instance: Logger;
  private logLevel: LogLevel;
  private config: LoggerConfig;

  // ANSI color codes for pretty printing
  private colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
  };

  private levelColors = {
    debug: this.colors.gray,
    info: this.colors.blue,
    warn: this.colors.yellow,
    error: this.colors.red,
  };

  private constructor(config: LoggerConfig = {}) {
    this.logLevel = env.LOG_LEVEL;
    this.config = {
      prettyPrint: env.NODE_ENV === "development",
      colors: env.NODE_ENV === "development" && typeof process !== 'undefined',
      ...config
    };
  }

  public static getInstance(config?: LoggerConfig): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(config);
    }
    return Logger.instance;
  }

  public configure(config: Partial<LoggerConfig>): void {
    this.config = { ...this.config, ...config };
  }

  private shouldLog(level: LogLevel): boolean {
    const levels: LogLevel[] = ["debug", "info", "warn", "error"];
    const currentLevelIndex = levels.indexOf(this.logLevel);
    const requestedLevelIndex = levels.indexOf(level);
    return requestedLevelIndex >= currentLevelIndex;
  }

  private colorize(text: string, color: string): string {
    if (!this.config.colors) return text;
    return `${color}${text}${this.colors.reset}`;
  }

  private formatTimestamp(): string {
    const timestamp = new Date().toISOString();
    if (this.config.prettyPrint) {
      return this.colorize(timestamp, this.colors.dim);
    }
    return timestamp;
  }

  private formatLevel(level: LogLevel): string {
    const levelText = level.toUpperCase().padEnd(5);
    if (this.config.prettyPrint && this.config.colors) {
      return this.colorize(`[${levelText}]`, this.levelColors[level]);
    }
    return `[${levelText}]`;
  }

  private formatMessage(
    level: LogLevel,
    message: string,
    meta?: Record<string, unknown>
  ): string {
    const timestamp = this.formatTimestamp();
    const levelFormatted = this.formatLevel(level);
    
    if (this.config.prettyPrint) {
      let output = `${timestamp} ${levelFormatted} ${message}`;
      
      if (meta && Object.keys(meta).length > 0) {
        output += '\n';
        if (this.config.colors) {
          output += this.colorize('📋 Metadata:', this.colors.cyan);
        } else {
          output += '📋 Metadata:';
        }
        output += '\n' + this.prettyPrintObject(meta, 1);
      }
      
      return output;
    } else {
      // Compact format for production
      const baseMessage = `[${new Date().toISOString()}] [${level.toUpperCase()}] ${message}`;
      if (meta && Object.keys(meta).length > 0) {
        return `${baseMessage} ${JSON.stringify(meta)}`;
      }
      return baseMessage;
    }
  }

  private prettyPrintObject(obj: Record<string, unknown>, indent: number = 0): string {
    const spaces = '  '.repeat(indent);
    let result = '';
    
    for (const [key, value] of Object.entries(obj)) {
      const keyFormatted = this.config.colors 
        ? this.colorize(key, this.colors.green) 
        : key;
      
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        result += `${spaces}${keyFormatted}:\n`;
        result += this.prettyPrintObject(value as Record<string, unknown>, indent + 1);
      } else if (Array.isArray(value)) {
        result += `${spaces}${keyFormatted}: [${value.join(', ')}]\n`;
      } else {
        const valueFormatted = this.config.colors && typeof value === 'string'
          ? this.colorize(`"${value}"`, this.colors.yellow)
          : String(value);
        result += `${spaces}${keyFormatted}: ${valueFormatted}\n`;
      }
    }
    
    return result;
  }

  public debug(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog("debug")) {
      console.debug(this.formatMessage("debug", message, meta));
    }
  }

  public info(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog("info")) {
      console.info(this.formatMessage("info", message, meta));
    }
  }

  public warn(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog("warn")) {
      console.warn(this.formatMessage("warn", message, meta));
    }
  }

  public error(
    message: string,
    error?: Error | unknown,
    meta?: Record<string, unknown>
  ): void {
    if (this.shouldLog("error")) {
      const errorMeta = { ...meta };

      if (error instanceof Error) {
        errorMeta.error = {
          name: error.name,
          message: error.message,
          stack: env.NODE_ENV === "development" ? error.stack : undefined,
        };
      } else if (error) {
        errorMeta.error = error;
      }

      console.error(this.formatMessage("error", message, errorMeta));
    }
  }

  public request(
    method: string,
    path: string,
    statusCode: number,
    duration?: number
  ): void {
    const meta = {
      method,
      path,
      statusCode,
      duration: duration ? `${duration}ms` : undefined,
    };

    const emoji = statusCode >= 400 ? '❌' : '✅';
    const messagePrefix = this.config.prettyPrint ? `${emoji} ` : '';

    if (statusCode >= 400) {
      this.warn(`${messagePrefix}HTTP ${statusCode} - ${method} ${path}`, meta);
    } else {
      this.info(`${messagePrefix}HTTP ${statusCode} - ${method} ${path}`, meta);
    }
  }

  // New utility methods for pretty logging
  public success(message: string, meta?: Record<string, unknown>): void {
    const emoji = this.config.prettyPrint ? '✨ ' : '';
    this.info(`${emoji}${message}`, meta);
  }

  public failure(message: string, error?: Error | unknown, meta?: Record<string, unknown>): void {
    const emoji = this.config.prettyPrint ? '💥 ' : '';
    this.error(`${emoji}${message}`, error, meta);
  }

  public performance(operation: string, duration: number, meta?: Record<string, unknown>): void {
    const emoji = this.config.prettyPrint ? '⚡ ' : '';
    const performanceMeta = {
      ...meta,
      operation,
      duration: `${duration}ms`,
      performance: duration > 1000 ? 'slow' : duration > 100 ? 'moderate' : 'fast'
    };
    
    if (duration > 1000) {
      this.warn(`${emoji}Slow operation: ${operation}`, performanceMeta);
    } else {
      this.info(`${emoji}Operation completed: ${operation}`, performanceMeta);
    }
  }
}

// Export singleton instance
export const logger = Logger.getInstance();

// Legacy compatibility exports
export const log = {
  debug: (message: string, ...args: unknown[]) =>
    logger.debug(message, { args }),
  info: (message: string, ...args: unknown[]) => logger.info(message, { args }),
  warn: (message: string, ...args: unknown[]) => logger.warn(message, { args }),
  error: (message: string, ...args: unknown[]) =>
    logger.error(message, args[0] as Error, { additionalArgs: args.slice(1) }),
};

// Pretty logging convenience exports
export const plog = {
  success: (message: string, meta?: Record<string, unknown>) => logger.success(message, meta),
  failure: (message: string, error?: Error | unknown, meta?: Record<string, unknown>) => 
    logger.failure(message, error, meta),
  perf: (operation: string, duration: number, meta?: Record<string, unknown>) => 
    logger.performance(operation, duration, meta),
};