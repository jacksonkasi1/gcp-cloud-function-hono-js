// ** Core Packages
import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger as honoLogger } from 'hono/logger'
import { prettyJSON } from 'hono/pretty-json'

// ** Routes
import { routes } from '@/routes'

// ** Config
import { env, isDevelopment, isProduction } from '@/config/environment'

// ** Types
import type { ErrorResponse } from '@/types/common'

import { parseRequestSize } from '@/utils/formatters'
// ** Utils
import { logger } from '@/utils/logs/logger'

// Initialize Hono app with TypeScript support
const app = new Hono()

// Load environment-specific configuration
const loadEnvironmentConfig = () => {
  try {
    if (isDevelopment) {
      logger.info('Loading development environment configuration')
    } else if (isProduction) {
      logger.info('Loading production environment configuration')
    }

    logger.info('Environment configuration loaded', {
      environment: env.NODE_ENV,
      corsOrigins: env.CORS_ORIGINS.join(', ') || 'None configured',
      logLevel: env.LOG_LEVEL,
    })
  } catch (error) {
    logger.error('Failed to load environment configuration', error)
    throw error
  }
}

// Middleware setup
app.use('*', honoLogger())
app.use('*', prettyJSON())

// CORS configuration with environment-specific origins
app.use(
  '*',
  cors({
    // biome-ignore lint/correctness/noUnusedVariables: Context parameter required by Hono CORS interface
    origin: (origin, c) => {
      // Allow requests without origin (e.g., mobile apps, curl, Postman)
      if (!origin) return origin

      // In development, allow configured localhost origins
      if (isDevelopment) {
        return env.CORS_ORIGINS.includes(origin) ? origin : null
      }

      // In production, be more restrictive
      if (isProduction) {
        if (env.CORS_ORIGINS.length === 0) {
          logger.warn('No CORS origins configured for production environment')
          return null
        }
        return env.CORS_ORIGINS.includes(origin) ? origin : null
      }

      return null
    },
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    exposeHeaders: ['X-Total-Count', 'X-Page-Count'],
    credentials: true,
    maxAge: isDevelopment ? 0 : 86400, // 24 hours in production, no cache in development
  })
)

// Request validation middleware
app.use('*', async (c, next) => {
  const contentLength = c.req.header('content-length')
  if (contentLength) {
    const maxSize = parseRequestSize(env.MAX_REQUEST_SIZE)
    if (Number.parseInt(contentLength, 10) > maxSize) {
      const errorResponse: ErrorResponse = {
        success: false,
        error: `Request too large. Maximum size: ${env.MAX_REQUEST_SIZE}`,
        timestamp: new Date().toISOString(),
      }
      return c.json(errorResponse, 413)
    }
  }
  return await next()
})

// Request logging middleware
app.use('*', async (c, next) => {
  const start = Date.now()
  await next()
  const duration = Date.now() - start

  logger.request(c.req.method, c.req.path, c.res.status, duration)
})

// Mount all routes
app.route('/', routes)

// Error handling middleware
app.onError((err, c) => {
  logger.error('Application error', err, {
    path: c.req.path,
    method: c.req.method,
  })

  const errorResponse: ErrorResponse = {
    success: false,
    error: isDevelopment ? err.message : 'Internal server error',
    timestamp: new Date().toISOString(),
  }
  return c.json(errorResponse, 500)
})

// 404 handler
app.notFound((c) => {
  const errorResponse: ErrorResponse = {
    success: false,
    error: 'Route not found',
    timestamp: new Date().toISOString(),
  }

  logger.warn('404 - Route not found', { path: c.req.path, method: c.req.method })
  return c.json(errorResponse, 404)
})

// Initialize environment configuration
loadEnvironmentConfig()

// For Cloud Functions/Cloud Run, export the app.fetch function
export default app.fetch

// For local development, start the server
if (isDevelopment && !process.env.FUNCTION_TARGET && !process.env.K_SERVICE) {
  serve({
    fetch: app.fetch,
    port: 8080
  }, (info) => {
    logger.info('🚀 Development server running', {
      url: `http://localhost:${info.port}`,
      healthCheck: `http://localhost:${info.port}/health`,
      corsOrigins: env.CORS_ORIGINS.join(', '),
      logLevel: env.LOG_LEVEL,
    })
  })
}
