import type { Context } from 'hono'
import type { CreateUserRequest, CreateUserResponse, User } from '../../types/user.js'
import type { ErrorResponse } from '../../types/common.js'
import { validateEmail, validateName, sanitizeString, formatResponse, generateId } from '../../utils/formatters/index.js'
import { logger } from '../../utils/logs/logger.js'

/**
 * Create a new user
 */
export async function createUser(c: Context) {
  try {
    const body = await c.req.json() as CreateUserRequest

    // Basic validation
    if (!body || typeof body !== 'object') {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid request body'
      })
      return c.json(errorResponse, 400)
    }

    if (!body.name || !body.email) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Name and email are required fields'
      })
      return c.json(errorResponse, 400)
    }

    // Validate name
    if (!validateName(body.name)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Name must be between 2 and 100 characters'
      })
      return c.json(errorResponse, 400)
    }

    // Validate email
    if (!validateEmail(body.email)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid email format'
      })
      return c.json(errorResponse, 400)
    }

    // Create new user (mock implementation)
    const newUser: User = {
      id: generateId(),
      name: sanitizeString(body.name),
      email: sanitizeString(body.email.toLowerCase()),
      created: new Date().toISOString()
    }

    const response: CreateUserResponse = formatResponse({
      success: true,
      message: 'User created successfully',
      data: newUser
    })

    logger.info('User created successfully', {
      userId: newUser.id,
      email: newUser.email
    })

    return c.json(response, 201)
  } catch (error) {
    logger.error('Error creating user', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Invalid JSON payload or internal server error'
    })
    
    return c.json(errorResponse, 400)
  }
}

/**
 * Update user profile
 */
export async function updateUser(c: Context) {
  try {
    const id = Number.parseInt(c.req.param('id'), 10)
    
    if (Number.isNaN(id)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid user ID'
      })
      return c.json(errorResponse, 400)
    }

    const body = await c.req.json() as Partial<CreateUserRequest>

    // Validate fields if provided
    if (body.name && !validateName(body.name)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Name must be between 2 and 100 characters'
      })
      return c.json(errorResponse, 400)
    }

    if (body.email && !validateEmail(body.email)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid email format'
      })
      return c.json(errorResponse, 400)
    }

    // Mock update (in real app, this would update in database)
    const updatedUser: User = {
      id,
      name: body.name ? sanitizeString(body.name) : 'Updated User',
      email: body.email ? sanitizeString(body.email.toLowerCase()) : 'updated@example.com',
      created: '2024-01-01' // Would come from database
    }

    logger.info('User updated successfully', { userId: id })

    return c.json(formatResponse({
      success: true,
      message: 'User updated successfully',
      data: updatedUser
    }))
  } catch (error) {
    logger.error('Error updating user', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error'
    })
    
    return c.json(errorResponse, 500)
  }
}