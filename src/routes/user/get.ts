// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { getUsersQuerySchema } from '@/schema/user/get-user.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { UsersResponse } from '@/types/user'
import type { User } from '@/types/user'

// ** Utils
import { calculatePagination, formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Mock user data for demonstration
const mockUsers: User[] = [
  { id: 1, name: 'John Doe', email: 'john@example.com', created: '2024-01-15' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', created: '2024-02-20' },
  { id: 3, name: 'Bob Johnson', email: 'bob@example.com', created: '2024-03-10' },
  { id: 4, name: 'Alice Brown', email: 'alice@example.com', created: '2024-04-05' },
  { id: 5, name: 'Charlie Wilson', email: 'charlie@example.com', created: '2024-05-12' },
]

// Create route for getting users
export const getUsersRoute = new Hono()

/**
 * Get users with pagination
 * GET /users
 */
getUsersRoute.get('/', zValidator('query', getUsersQuerySchema), async (c) => {
  try {
    const { page, limit } = c.req.valid('query')

    const startIndex = (page - 1) * limit
    const endIndex = startIndex + limit
    const paginatedUsers = mockUsers.slice(startIndex, endIndex)

    const response: UsersResponse = formatResponse({
      success: true,
      data: paginatedUsers,
      pagination: calculatePagination(page, limit, mockUsers.length),
    })

    logger.info('Users retrieved successfully', {
      page,
      limit,
      total: mockUsers.length,
      returned: paginatedUsers.length,
    })

    return c.json(response)
  } catch (error) {
    logger.error('Error retrieving users', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
