import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()

// Health check route
app.get('/health', (c) => {
  return c.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.FUNCTION_VERSION || '1.0.0',
    region: process.env.FUNCTION_REGION || 'asia-south1',
    memory: process.env.FUNCTION_MEMORY || '1GB'
  })
})

// User management API route
app.get('/api/users', (c) => {
  // Mock user data for demonstration
  const users = [
    { id: 1, name: 'John Doe', email: 'john@example.com', created: '2024-01-15' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com', created: '2024-02-20' },
    { id: 3, name: 'Bob Johnson', email: 'bob@example.com', created: '2024-03-10' }
  ]

  const page = Number.parseInt(c.req.query('page') || '1')
  const limit = Number.parseInt(c.req.query('limit') || '10')
  const startIndex = (page - 1) * limit
  const endIndex = startIndex + limit

  const paginatedUsers = users.slice(startIndex, endIndex)

  return c.json({
    success: true,
    data: paginatedUsers,
    pagination: {
      page,
      limit,
      total: users.length,
      totalPages: Math.ceil(users.length / limit)
    },
    timestamp: new Date().toISOString()
  })
})

// Create user endpoint
app.post('/api/users', async (c) => {
  try {
    const body = await c.req.json()
    
    // Basic validation
    if (!body.name || !body.email) {
      return c.json({
        success: false,
        error: 'Name and email are required fields',
        timestamp: new Date().toISOString()
      }, 400)
    }

    // Mock user creation (in real app, this would save to database)
    const newUser = {
      id: Math.floor(Math.random() * 10000),
      name: body.name,
      email: body.email,
      created: new Date().toISOString()
    }

    return c.json({
      success: true,
      message: 'User created successfully',
      data: newUser,
      timestamp: new Date().toISOString()
    }, 201)
  } catch (error) {
    return c.json({
      success: false,
      error: 'Invalid JSON payload',
      timestamp: new Date().toISOString()
    }, 400)
  }
})

// Root route
app.get('/', (c) => {
  return c.json({
    message: 'GCP Hono.js Serverless API',
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api/users - Get users list with pagination',
      'POST /api/users - Create new user'
    ],
    timestamp: new Date().toISOString()
  })
})

// Error handling middleware
app.onError((err, c) => {
  console.error('Application error:', err)
  return c.json({
    success: false,
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  }, 500)
})

// 404 handler
app.notFound((c) => {
  return c.json({
    success: false,
    error: 'Route not found',
    timestamp: new Date().toISOString()
  }, 404)
})

// For Cloud Functions, we need to export the app.fetch function
export default app.fetch

// For local development
if (process.env.NODE_ENV !== 'production') {
  const port = Number.parseInt(process.env.PORT || '8080')
  
  serve({
    fetch: app.fetch,
    port: port
  }, (info) => {
    console.log(`🚀 Server is running on http://localhost:${info.port}`)
    console.log(`📍 Health check: http://localhost:${info.port}/health`)
    console.log(`👥 Users API: http://localhost:${info.port}/api/users`)
  })
}