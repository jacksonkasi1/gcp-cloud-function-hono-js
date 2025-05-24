import { z } from 'zod'

// Schema for getting user by ID
export const getUserByIdParamsSchema = z.object({
  id: z.string().regex(/^\d+$/, 'ID must be a valid number').transform(Number),
})

// Schema for pagination query parameters
export const getUsersQuerySchema = z.object({
  page: z.string().optional().default('1').transform(Number),
  limit: z.string().optional().default('10').transform(Number),
})

// Type exports
export type GetUserByIdParams = z.infer<typeof getUserByIdParamsSchema>
export type GetUsersQuery = z.infer<typeof getUsersQuerySchema>
