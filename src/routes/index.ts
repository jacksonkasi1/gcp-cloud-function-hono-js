// ** Core Packages
import { Hono } from 'hono'
import type { Context } from 'hono'

import { courseRoutes } from './course'
// ** Routes
import { userRoutes } from './user'

// ** Config
import { env } from '@/config/environment'

// ** Types
import type { HealthResponse } from '@/types/common'

// ** Utils
import { formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Create main routes
const routes = new Hono()

// Health check route with environment information
routes.get('/health', (c: Context) => {
  const response: HealthResponse = formatResponse({
    status: 'healthy',
    version: env.FUNCTION_VERSION || '1.0.0',
    region: env.FUNCTION_REGION || 'local',
    memory: env.FUNCTION_MEMORY || '1GB',
    environment: env.NODE_ENV,
    cors_origins: env.CORS_ORIGINS,
  })

  logger.info('Health check requested')
  return c.json(response)
})

// Root route with API documentation
routes.get('/', (c: Context) => {
  const response = formatResponse({
    message: 'GCP TypeScript Hono.js Serverless API',
    version: '2.0.0',
    environment: env.NODE_ENV,
    cors_enabled: true,
    cors_origins: env.CORS_ORIGINS,
    endpoints: [
      'GET /health - Health check with environment info',
      'GET /api/users?page=1&limit=10 - Get users list with pagination',
      'GET /api/users/:id - Get user by ID',
      'POST /api/users - Create new user (requires name and email)',
      'PUT /api/users/:id - Update user by ID',
      'GET /api/courses?page=1&limit=10&level=beginner - Get courses with optional filtering',
      'GET /api/courses/:id - Get course by ID',
      'POST /api/courses - Create new course',
      'PUT /api/courses/:id - Update course by ID',
    ],
  })

  logger.info('Root endpoint accessed')
  return c.json(response)
})

// Mount sub-routes
routes.route('/api/users', userRoutes)
routes.route('/api/courses', courseRoutes)

export { routes }
