import { Hono } from 'hono'
import { getCourses, getCourseById } from './get-course.js'
import { createCourse, updateCourse } from './create-course.js'

// Create course routes
const courseRoutes = new Hono()

// Course routes
courseRoutes.get('/', getCourses)
courseRoutes.get('/:id', getCourseById)
courseRoutes.post('/', createCourse)
courseRoutes.put('/:id', updateCourse)

export { courseRoutes }