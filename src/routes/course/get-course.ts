import type { Context } from 'hono'
import type { CoursesResponse, Course } from '../../types/course.js'
import type { ErrorResponse } from '../../types/common.js'
import { validatePagination, calculatePagination, formatResponse } from '../../utils/formatters/index.js'
import { logger } from '../../utils/logs/logger.js'

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
    updated: '2024-01-15'
  },
  {
    id: 2,
    title: 'Advanced Node.js',
    description: 'Master advanced Node.js concepts and patterns',
    instructor: 'Jane Doe',
    duration: 60,
    level: 'advanced',
    created: '2024-02-01',
    updated: '2024-02-05'
  },
  {
    id: 3,
    title: 'React Fundamentals',
    description: 'Build modern web applications with React',
    instructor: 'Bob Wilson',
    duration: 50,
    level: 'intermediate',
    created: '2024-03-01',
    updated: '2024-03-10'
  }
]

/**
 * Get courses with pagination and filtering
 */
export async function getCourses(c: Context) {
  try {
    const pageParam = c.req.query('page')
    const limitParam = c.req.query('limit')
    const levelFilter = c.req.query('level') as Course['level'] | undefined

    // Validate pagination parameters
    const { page, limit } = validatePagination(pageParam, limitParam)

    // Filter courses by level if specified
    let filteredCourses = mockCourses
    if (levelFilter && ['beginner', 'intermediate', 'advanced'].includes(levelFilter)) {
      filteredCourses = mockCourses.filter(course => course.level === levelFilter)
    }

    const startIndex = (page - 1) * limit
    const endIndex = startIndex + limit
    const paginatedCourses = filteredCourses.slice(startIndex, endIndex)

    const response: CoursesResponse = formatResponse({
      success: true,
      data: paginatedCourses,
      pagination: calculatePagination(page, limit, filteredCourses.length)
    })

    logger.info('Courses retrieved successfully', {
      page,
      limit,
      level: levelFilter,
      total: filteredCourses.length,
      returned: paginatedCourses.length
    })

    return c.json(response)
  } catch (error) {
    logger.error('Error retrieving courses', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    })
    
    return c.json(errorResponse, 400)
  }
}

/**
 * Get single course by ID
 */
export async function getCourseById(c: Context) {
  try {
    const id = Number.parseInt(c.req.param('id'), 10)
    
    if (Number.isNaN(id)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid course ID'
      })
      return c.json(errorResponse, 400)
    }

    const course = mockCourses.find(c => c.id === id)
    
    if (!course) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Course not found'
      })
      return c.json(errorResponse, 404)
    }

    logger.info('Course retrieved successfully', { courseId: id })

    return c.json(formatResponse({
      success: true,
      data: course
    }))
  } catch (error) {
    logger.error('Error retrieving course', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error'
    })
    
    return c.json(errorResponse, 500)
  }
}