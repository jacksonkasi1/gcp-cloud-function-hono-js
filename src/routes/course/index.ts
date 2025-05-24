// ** Core Packages
import { Hono } from 'hono'

import { createCourseRoute } from './create'
// ** Routes
import { getCoursesRoute } from './get'
import { getCourseByIdRoute } from './get-by-id'
import { updateCourseRoute } from './update'

/**
 * Course management routes
 * Provides endpoints for listing, retrieving, creating, and updating courses
 */
export const courseRoutes = new Hono()

// Mount specific routes first to ensure they are matched before the :id parameter routes
courseRoutes.route('/', createCourseRoute)
courseRoutes.route('/', getCoursesRoute)

// Register the ID-based routes
courseRoutes.route('/:id', getCourseByIdRoute)
courseRoutes.route('/:id', updateCourseRoute)
