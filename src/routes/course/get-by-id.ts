// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { getCourseByIdParamsSchema } from '@/schema/course/get-course.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { Course } from '@/types/course'

// ** Utils
import { formatResponse } from '@/utils/formatters'
import { logger } from '@/utils/logs/logger'

// Mock course data for demonstration
const mockCourses: Course[] = [
  {
    id: 1,
    title: 'Introduction to TypeScript',
    description: 'Learn the basics of TypeScript programming',
    instructor: 'John Smith',
    duration: 40,
    level: 'beginner',
    created: '2024-01-10',
    updated: '2024-01-15',
  },
  {
    id: 2,
    title: 'Advanced Node.js',
    description: 'Master advanced Node.js concepts and patterns',
    instructor: 'Jane Doe',
    duration: 60,
    level: 'advanced',
    created: '2024-02-01',
    updated: '2024-02-05',
  },
  {
    id: 3,
    title: 'React Fundamentals',
    description: 'Build modern web applications with React',
    instructor: 'Bob Wilson',
    duration: 50,
    level: 'intermediate',
    created: '2024-03-01',
    updated: '2024-03-10',
  },
]

// Create route for getting a single course
export const getCourseByIdRoute = new Hono()

/**
 * Get a single course by ID
 * GET /courses/:id
 */
getCourseByIdRoute.get('/', zValidator('param', getCourseByIdParamsSchema), async (c) => {
  try {
    const { id } = c.req.valid('param')

    const course = mockCourses.find((c) => c.id === id)

    if (!course) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Course not found',
      })
      return c.json(errorResponse, 404)
    }

    logger.info('Course retrieved successfully', { courseId: id })

    return c.json(
      formatResponse({
        success: true,
        data: course,
      })
    )
  } catch (error) {
    logger.error('Error retrieving course', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
