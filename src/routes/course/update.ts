// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import {
  updateCourseBodySchema,
  updateCourseParamsSchema,
} from '@/schema/course/create-course.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { Course } from '@/types/course'

// ** Utils
import { formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Create route for updating courses
export const updateCourseRoute = new Hono()

/**
 * Update an existing course
 * PUT /courses/:id
 */
updateCourseRoute.put(
  '/',
  zValidator('param', updateCourseParamsSchema),
  zValidator('json', updateCourseBodySchema),
  async (c) => {
    try {
      const { id } = c.req.valid('param')
      const body = c.req.valid('json')

      // Mock update (in real app, this would update in database)
      const updatedCourse: Course = {
        id,
        title: body.title || 'Updated Course',
        description: body.description || 'Updated description',
        instructor: body.instructor || 'Updated Instructor',
        duration: body.duration || 30,
        level: body.level || 'beginner',
        created: '2024-01-01', // Would come from database
        updated: new Date().toISOString(),
      }

      logger.info('Course updated successfully', { courseId: id })

      return c.json(
        formatResponse({
          success: true,
          message: 'Course updated successfully',
          data: updatedCourse,
        })
      )
    } catch (error) {
      logger.error('Error updating course', error)

      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Internal server error',
      })

      return c.json(errorResponse, 500)
    }
  }
)
