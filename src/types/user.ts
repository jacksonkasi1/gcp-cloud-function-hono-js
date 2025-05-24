// User-related type definitions
export interface User {
  id: number
  name: string
  email: string
  created: string
}

export interface CreateUserRequest {
  name: string
  email: string
}

export interface CreateUserResponse {
  success: boolean
  message: string
  data: User
  timestamp: string
}

export interface UsersResponse {
  success: boolean
  data: User[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
  timestamp: string
}

export interface UserValidationError {
  field: string
  message: string
}
