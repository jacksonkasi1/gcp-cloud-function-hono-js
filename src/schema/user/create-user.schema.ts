import { z } from 'zod'

// Schema for creating a new user
export const createUserBodySchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must not exceed 100 characters')
    .trim(),
  email: z.string().email('Invalid email format').toLowerCase().trim(),
})

// Schema for updating user
export const updateUserBodySchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must not exceed 100 characters')
    .trim()
    .optional(),
  email: z.string().email('Invalid email format').toLowerCase().trim().optional(),
})

// Schema for update user params
export const updateUserParamsSchema = z.object({
  id: z.string().regex(/^\d+$/, 'ID must be a valid number').transform(Number),
})

// Type exports
export type CreateUserBody = z.infer<typeof createUserBodySchema>
export type UpdateUserBody = z.infer<typeof updateUserBodySchema>
export type UpdateUserParams = z.infer<typeof updateUserParamsSchema>
