import { z } from 'zod'

// Schema for getting course by ID
export const getCourseByIdParamsSchema = z.object({
  id: z.string().regex(/^\d+$/, 'ID must be a valid number').transform(Number),
})

// Schema for courses query parameters with filtering
export const getCoursesQuerySchema = z.object({
  page: z.string().optional().default('1').transform(Number),
  limit: z.string().optional().default('10').transform(Number),
  level: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
})

// Type exports
export type GetCourseByIdParams = z.infer<typeof getCourseByIdParamsSchema>
export type GetCoursesQuery = z.infer<typeof getCoursesQuerySchema>
