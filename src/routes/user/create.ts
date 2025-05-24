// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { createUserBodySchema } from '@/schema/user/create-user.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { CreateUserResponse, User } from '@/types/user'

// ** Utils
import { formatResponse, generateId } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Create route for creating users
export const createUserRoute = new Hono()

/**
 * Create a new user
 * POST /users
 */
createUserRoute.post('/', zValidator('json', createUserBodySchema), async (c) => {
  try {
    const { name, email } = c.req.valid('json')

    // Create new user (mock implementation)
    const newUser: User = {
      id: generateId(),
      name,
      email,
      created: new Date().toISOString(),
    }

    const response: CreateUserResponse = formatResponse({
      success: true,
      message: 'User created successfully',
      data: newUser,
    })

    logger.info('User created successfully', {
      userId: newUser.id,
      email: newUser.email,
    })

    return c.json(response, 201)
  } catch (error) {
    logger.error('Error creating user', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
