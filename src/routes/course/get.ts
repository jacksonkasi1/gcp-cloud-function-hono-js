// ** Core Packages
import { Hono } from 'hono'

// ** Third Party
import { zValidator } from '@hono/zod-validator'

// ** Schema
import { getCoursesQuerySchema } from '@/schema/course/get-course.schema'

import type { ErrorResponse } from '@/types/common'
// ** Types
import type { Course, CoursesResponse } from '@/types/course'

// ** Utils
import { calculatePagination, formatResponse } from '@/utils/formatters'
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

// Create route for getting courses
export const getCoursesRoute = new Hono()

/**
 * Get courses with pagination and filtering
 * GET /courses
 */
getCoursesRoute.get('/', zValidator('query', getCoursesQuerySchema), async (c) => {
  try {
    const { page, limit, level } = c.req.valid('query')

    // Filter courses by level if specified
    let filteredCourses = mockCourses
    if (level) {
      filteredCourses = mockCourses.filter((course) => course.level === level)
    }

    const startIndex = (page - 1) * limit
    const endIndex = startIndex + limit
    const paginatedCourses = filteredCourses.slice(startIndex, endIndex)

    const response: CoursesResponse = formatResponse({
      success: true,
      data: paginatedCourses,
      pagination: calculatePagination(page, limit, filteredCourses.length),
    })

    logger.info('Courses retrieved successfully', {
      page,
      limit,
      level,
      total: filteredCourses.length,
      returned: paginatedCourses.length,
    })

    return c.json(response)
  } catch (error) {
    logger.error('Error retrieving courses', error)

    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error',
    })

    return c.json(errorResponse, 500)
  }
})
