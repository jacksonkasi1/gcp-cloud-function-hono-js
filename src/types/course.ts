// Course-related type definitions
export interface Course {
  id: number
  title: string
  description: string
  instructor: string
  duration: number // in hours
  level: 'beginner' | 'intermediate' | 'advanced'
  created: string
  updated: string
}

export interface CreateCourseRequest {
  title: string
  description: string
  instructor: string
  duration: number
  level: 'beginner' | 'intermediate' | 'advanced'
}

export interface CreateCourseResponse {
  success: boolean
  message: string
  data: Course
  timestamp: string
}

export interface CoursesResponse {
  success: boolean
  data: Course[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
  timestamp: string
}

export interface CourseValidationError {
  field: string
  message: string
}
