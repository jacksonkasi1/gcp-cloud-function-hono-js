// Common type definitions used across the application
export interface HealthResponse {
  status: string
  timestamp: string
  version: string
  region: string
  memory: string
  environment: string
  cors_origins: string[]
}

export interface ErrorResponse {
  success: false
  error: string
  timestamp: string
}

export interface ApiResponse<T = unknown> {
  success: boolean
  data?: T
  message?: string
  timestamp: string
}

export interface PaginationParams {
  page: number
  limit: number
}

export interface PaginationMeta {
  page: number
  limit: number
  total: number
  totalPages: number
}

export type LogLevel = 'debug' | 'info' | 'warn' | 'error'

export type Environment = 'development' | 'production'