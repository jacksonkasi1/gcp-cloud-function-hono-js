// Environment configuration without external dependencies for Cloud Functions
export interface EnvironmentConfig {
  NODE_ENV: 'development' | 'production'
  PORT: number
  CORS_ORIGINS: string[]
  FUNCTION_VERSION: string | undefined
  FUNCTION_REGION: string | undefined
  FUNCTION_MEMORY: string | undefined
  LOG_LEVEL: 'debug' | 'info' | 'warn' | 'error'
  MAX_REQUEST_SIZE: string
}

// Environment validation
const validateEnvironment = (): EnvironmentConfig => {
  const nodeEnv = process.env.NODE_ENV as 'development' | 'production'

  if (!nodeEnv || !['development', 'production'].includes(nodeEnv)) {
    throw new Error('NODE_ENV must be either "development" or "production"')
  }

  /**
   * @see https://hono.dev/docs/getting-started/google-cloud-run#_3-hello-world
   */
  const port = Number.parseInt(process.env.PORT || '8080', 10)
  if (Number.isNaN(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be a valid port number between 1 and 65535')
  }

  return {
    NODE_ENV: nodeEnv,
    PORT: port,
    CORS_ORIGINS: getCorsOrigins(nodeEnv),
    FUNCTION_VERSION: process.env.FUNCTION_VERSION,
    FUNCTION_REGION: process.env.FUNCTION_REGION,
    FUNCTION_MEMORY: process.env.FUNCTION_MEMORY,
    LOG_LEVEL:
      (process.env.LOG_LEVEL as 'debug' | 'info' | 'warn' | 'error') || getDefaultLogLevel(nodeEnv),
    MAX_REQUEST_SIZE: process.env.MAX_REQUEST_SIZE || '10mb',
  }
}

// Get CORS origins based on environment
const getCorsOrigins = (nodeEnv: 'development' | 'production'): string[] => {
  if (nodeEnv === 'development') {
    return [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3001',
    ]
  }

  // Production CORS origins - should be configured via environment variables
  const prodOrigins = process.env.CORS_ORIGINS
  if (prodOrigins) {
    return prodOrigins.split(',').map((origin: string) => origin.trim())
  }

  // Default production origins (restrictive)
  return []
}

// Get default log level based on environment
const getDefaultLogLevel = (
  nodeEnv: 'development' | 'production'
): 'debug' | 'info' | 'warn' | 'error' => {
  return nodeEnv === 'development' ? 'debug' : 'info'
}

// Export validated environment configuration
export const env = validateEnvironment()

// Environment-specific configurations
export const isDevelopment = env.NODE_ENV === 'development'
export const isProduction = env.NODE_ENV === 'production'

// Logging utility
export const log = {
  debug: (message: string, ...args: unknown[]) => {
    if (['debug'].includes(env.LOG_LEVEL)) {
      console.debug(`[DEBUG] ${message}`, ...args)
    }
  },
  info: (message: string, ...args: unknown[]) => {
    if (['debug', 'info'].includes(env.LOG_LEVEL)) {
      console.info(`[INFO] ${message}`, ...args)
    }
  },
  warn: (message: string, ...args: unknown[]) => {
    if (['debug', 'info', 'warn'].includes(env.LOG_LEVEL)) {
      console.warn(`[WARN] ${message}`, ...args)
    }
  },
  error: (message: string, ...args: unknown[]) => {
    console.error(`[ERROR] ${message}`, ...args)
  },
}
