import { Hono } from 'hono'
import { getUsers, getUserById } from './get-user.js'
import { createUser, updateUser } from './user-profile.js'

// Create user routes
const userRoutes = new Hono()

// User routes
userRoutes.get('/', getUsers)
userRoutes.get('/:id', getUserById)
userRoutes.post('/', createUser)
userRoutes.put('/:id', updateUser)

export { userRoutes }