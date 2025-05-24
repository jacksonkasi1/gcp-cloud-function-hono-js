import type { Context } from 'hono'
import type { UsersResponse, User } from '../../types/user.js'
import type { ErrorResponse } from '../../types/common.js'
import { validatePagination, calculatePagination, formatResponse } from '../../utils/formatters/index.js'
import { logger } from '../../utils/logs/logger.js'

// Mock user data for demonstration
const mockUsers: User[] = [
  { id: 1, name: 'John Doe', email: 'john@example.com', created: '2024-01-15' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', created: '2024-02-20' },
  { id: 3, name: 'Bob Johnson', email: 'bob@example.com', created: '2024-03-10' },
  { id: 4, name: 'Alice Brown', email: 'alice@example.com', created: '2024-04-05' },
  { id: 5, name: 'Charlie Wilson', email: 'charlie@example.com', created: '2024-05-12' }
]

/**
 * Get users with pagination
 */
export async function getUsers(c: Context) {
  try {
    const pageParam = c.req.query('page')
    const limitParam = c.req.query('limit')

    // Validate pagination parameters
    const { page, limit } = validatePagination(pageParam, limitParam)

    const startIndex = (page - 1) * limit
    const endIndex = startIndex + limit
    const paginatedUsers = mockUsers.slice(startIndex, endIndex)

    const response: UsersResponse = formatResponse({
      success: true,
      data: paginatedUsers,
      pagination: calculatePagination(page, limit, mockUsers.length)
    })

    logger.info('Users retrieved successfully', {
      page,
      limit,
      total: mockUsers.length,
      returned: paginatedUsers.length
    })

    return c.json(response)
  } catch (error) {
    logger.error('Error retrieving users', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    })
    
    return c.json(errorResponse, 400)
  }
}

/**
 * Get single user by ID
 */
export async function getUserById(c: Context) {
  try {
    const id = Number.parseInt(c.req.param('id'), 10)
    
    if (Number.isNaN(id)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid user ID'
      })
      return c.json(errorResponse, 400)
    }

    const user = mockUsers.find(u => u.id === id)
    
    if (!user) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'User not found'
      })
      return c.json(errorResponse, 404)
    }

    logger.info('User retrieved successfully', { userId: id })

    return c.json(formatResponse({
      success: true,
      data: user
    }))
  } catch (error) {
    logger.error('Error retrieving user', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error'
    })
    
    return c.json(errorResponse, 500)
  }
}