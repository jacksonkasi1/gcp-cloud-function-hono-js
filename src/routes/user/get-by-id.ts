// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { getUserByIdParamsSchema } from '@/schema/user/get-user.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { User } from '@/types/user'

// ** Utils
import { formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Mock user data for demonstration
const mockUsers: User[] = [
  { id: 1, name: 'John Doe', email: 'john@example.com', created: '2024-01-15' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', created: '2024-02-20' },
  { id: 3, name: 'Bob Johnson', email: 'bob@example.com', created: '2024-03-10' },
  { id: 4, name: 'Alice Brown', email: 'alice@example.com', created: '2024-04-05' },
  { id: 5, name: 'Charlie Wilson', email: 'charlie@example.com', created: '2024-05-12' },
]

// Create route for getting a single user
export const getUserByIdRoute = new Hono()

/**
 * Get a single user by ID
 * GET /users/:id
 */
getUserByIdRoute.get('/', zValidator('param', getUserByIdParamsSchema), async (c) => {
  try {
    const { id } = c.req.valid('param')

    const user = mockUsers.find((u) => u.id === id)

    if (!user) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'User not found',
      })
      return c.json(errorResponse, 404)
    }

    logger.info('User retrieved successfully', { userId: id })

    return c.json(
      formatResponse({
        success: true,
        data: user,
      })
    )
  } catch (error) {
    logger.error('Error retrieving user', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
