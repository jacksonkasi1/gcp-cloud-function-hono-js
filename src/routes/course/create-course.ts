import type { Context } from 'hono'
import type { CreateCourseRequest, CreateCourseResponse, Course } from '../../types/course.js'
import type { ErrorResponse } from '../../types/common.js'
import { sanitizeString, formatResponse, generateId } from '../../utils/formatters/index.js'
import { logger } from '../../utils/logs/logger.js'

/**
 * Validates course creation request
 */
function validateCourseRequest(body: CreateCourseRequest): string | null {
  if (!body.title || body.title.length < 3 || body.title.length > 100) {
    return 'Title must be between 3 and 100 characters'
  }

  if (!body.description || body.description.length < 10 || body.description.length > 500) {
    return 'Description must be between 10 and 500 characters'
  }

  if (!body.instructor || body.instructor.length < 2 || body.instructor.length > 50) {
    return 'Instructor name must be between 2 and 50 characters'
  }

  if (!body.duration || body.duration < 1 || body.duration > 200) {
    return 'Duration must be between 1 and 200 hours'
  }

  if (!['beginner', 'intermediate', 'advanced'].includes(body.level)) {
    return 'Level must be beginner, intermediate, or advanced'
  }

  return null
}

/**
 * Create a new course
 */
export async function createCourse(c: Context) {
  try {
    const body = await c.req.json() as CreateCourseRequest

    // Basic validation
    if (!body || typeof body !== 'object') {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid request body'
      })
      return c.json(errorResponse, 400)
    }

    // Validate course data
    const validationError = validateCourseRequest(body)
    if (validationError) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: validationError
      })
      return c.json(errorResponse, 400)
    }

    // Create new course (mock implementation)
    const newCourse: Course = {
      id: generateId(),
      title: sanitizeString(body.title),
      description: sanitizeString(body.description),
      instructor: sanitizeString(body.instructor),
      duration: body.duration,
      level: body.level,
      created: new Date().toISOString(),
      updated: new Date().toISOString()
    }

    const response: CreateCourseResponse = formatResponse({
      success: true,
      message: 'Course created successfully',
      data: newCourse
    })

    logger.info('Course created successfully', {
      courseId: newCourse.id,
      title: newCourse.title,
      instructor: newCourse.instructor
    })

    return c.json(response, 201)
  } catch (error) {
    logger.error('Error creating course', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Invalid JSON payload or internal server error'
    })
    
    return c.json(errorResponse, 400)
  }
}

/**
 * Update an existing course
 */
export async function updateCourse(c: Context) {
  try {
    const id = Number.parseInt(c.req.param('id'), 10)
    
    if (Number.isNaN(id)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Invalid course ID'
      })
      return c.json(errorResponse, 400)
    }

    const body = await c.req.json() as Partial<CreateCourseRequest>

    // Validate fields if provided
    if (body.title && (body.title.length < 3 || body.title.length > 100)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Title must be between 3 and 100 characters'
      })
      return c.json(errorResponse, 400)
    }

    if (body.description && (body.description.length < 10 || body.description.length > 500)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Description must be between 10 and 500 characters'
      })
      return c.json(errorResponse, 400)
    }

    if (body.level && !['beginner', 'intermediate', 'advanced'].includes(body.level)) {
      const errorResponse: ErrorResponse = formatResponse({
        success: false,
        error: 'Level must be beginner, intermediate, or advanced'
      })
      return c.json(errorResponse, 400)
    }

    // Mock update (in real app, this would update in database)
    const updatedCourse: Course = {
      id,
      title: body.title ? sanitizeString(body.title) : 'Updated Course',
      description: body.description ? sanitizeString(body.description) : 'Updated description',
      instructor: body.instructor ? sanitizeString(body.instructor) : 'Updated Instructor',
      duration: body.duration || 30,
      level: body.level || 'beginner',
      created: '2024-01-01', // Would come from database
      updated: new Date().toISOString()
    }

    logger.info('Course updated successfully', { courseId: id })

    return c.json(formatResponse({
      success: true,
      message: 'Course updated successfully',
      data: updatedCourse
    }))
  } catch (error) {
    logger.error('Error updating course', error)
    
    const errorResponse: ErrorResponse = formatResponse({
      success: false,
      error: 'Internal server error'
    })
    
    return c.json(errorResponse, 500)
  }
}