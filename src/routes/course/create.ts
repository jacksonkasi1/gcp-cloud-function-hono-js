// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { createCourseBodySchema } from '@/schema/course/create-course.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { Course, CreateCourseResponse } from '@/types/course'

// ** Utils
import { formatResponse, generateId } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Create route for creating courses
export const createCourseRoute = new Hono()

/**
 * Create a new course
 * POST /courses
 */
createCourseRoute.post('/', zValidator('json', createCourseBodySchema), async (c) => {
  try {
    const { title, description, instructor, duration, level } = c.req.valid('json')

    // Create new course (mock implementation)
    const newCourse: Course = {
      id: generateId(),
      title,
      description,
      instructor,
      duration,
      level,
      created: new Date().toISOString(),
      updated: new Date().toISOString(),
    }

    const response: CreateCourseResponse = formatResponse({
      success: true,
      message: 'Course created successfully',
      data: newCourse,
    })

    logger.info('Course created successfully', {
      courseId: newCourse.id,
      title: newCourse.title,
      instructor: newCourse.instructor,
    })

    return c.json(response, 201)
  } catch (error) {
    logger.error('Error creating course', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
