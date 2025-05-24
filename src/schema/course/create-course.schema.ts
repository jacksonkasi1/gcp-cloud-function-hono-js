import { z } from 'zod'

// Schema for creating a new course
export const createCourseBodySchema = z.object({
  title: z
    .string()
    .min(3, 'Title must be at least 3 characters')
    .max(100, 'Title must not exceed 100 characters')
    .trim(),
  description: z
    .string()
    .min(10, 'Description must be at least 10 characters')
    .max(500, 'Description must not exceed 500 characters')
    .trim(),
  instructor: z
    .string()
    .min(2, 'Instructor name must be at least 2 characters')
    .max(50, 'Instructor name must not exceed 50 characters')
    .trim(),
  duration: z
    .number()
    .int('Duration must be a whole number')
    .min(1, 'Duration must be at least 1 hour')
    .max(200, 'Duration must not exceed 200 hours'),
  level: z.enum(['beginner', 'intermediate', 'advanced'], {
    errorMap: () => ({ message: 'Level must be beginner, intermediate, or advanced' }),
  }),
})

// Schema for updating course
export const updateCourseBodySchema = z.object({
  title: z
    .string()
    .min(3, 'Title must be at least 3 characters')
    .max(100, 'Title must not exceed 100 characters')
    .trim()
    .optional(),
  description: z
    .string()
    .min(10, 'Description must be at least 10 characters')
    .max(500, 'Description must not exceed 500 characters')
    .trim()
    .optional(),
  instructor: z
    .string()
    .min(2, 'Instructor name must be at least 2 characters')
    .max(50, 'Instructor name must not exceed 50 characters')
    .trim()
    .optional(),
  duration: z
    .number()
    .int('Duration must be a whole number')
    .min(1, 'Duration must be at least 1 hour')
    .max(200, 'Duration must not exceed 200 hours')
    .optional(),
  level: z
    .enum(['beginner', 'intermediate', 'advanced'], {
      errorMap: () => ({ message: 'Level must be beginner, intermediate, or advanced' }),
    })
    .optional(),
})

// Schema for update course params
export const updateCourseParamsSchema = z.object({
  id: z.string().regex(/^\d+$/, 'ID must be a valid number').transform(Number),
})

// Type exports
export type CreateCourseBody = z.infer<typeof createCourseBodySchema>
export type UpdateCourseBody = z.infer<typeof updateCourseBodySchema>
export type UpdateCourseParams = z.infer<typeof updateCourseParamsSchema>
