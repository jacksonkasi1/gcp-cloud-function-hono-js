// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { updateUserBodySchema, updateUserParamsSchema } from '@/schema/user/create-user.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { User } from '@/types/user'

// ** Utils
import { formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Create route for updating users
export const updateUserRoute = new Hono()

/**
 * Update an existing user
 * PUT /users/:id
 */
updateUserRoute.put(
  '/',
  zValidator('param', updateUserParamsSchema),
  zValidator('json', updateUserBodySchema),
  async (c) => {
    try {
      const { id } = c.req.valid('param')
      const body = c.req.valid('json')

      // Mock update (in real app, this would update in database)
      const updatedUser: User = {
        id,
        name: body.name || 'Updated User',
        email: body.email || 'updated@example.com',
        created: '2024-01-01', // Would come from database
      }

      logger.info('User updated successfully', { userId: id })

      return c.json(
        formatResponse({
          success: true,
          message: 'User updated successfully',
          data: updatedUser,
        })
      )
    } catch (error) {
      logger.error('Error updating user', error)

      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Internal server error',
      })

      return c.json(errorResponse, 500)
    }
  }
)
