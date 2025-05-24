// ** Core Packages
import { Hono } from 'hono'

import { createUserRoute } from './create'
// ** Routes
import { getUsersRoute } from './get'
import { getUserByIdRoute } from './get-by-id'
import { updateUserRoute } from './update'

/**
 * User management routes
 * Provides endpoints for listing, retrieving, creating, and updating users
 */
export const userRoutes = new Hono()

// Mount specific routes first to ensure they are matched before the :id parameter routes
userRoutes.route('/', createUserRoute)
userRoutes.route('/', getUsersRoute)

// Register the ID-based routes
userRoutes.route('/:id', getUserByIdRoute)
userRoutes.route('/:id', updateUserRoute)
