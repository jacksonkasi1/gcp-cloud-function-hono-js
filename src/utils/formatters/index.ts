// Utility functions for formatting data
import type { PaginationParams, PaginationMeta } from '../../types/common.js'

/**
 * Validates and normalizes pagination parameters
 */
export function validatePagination(page?: string, limit?: string): PaginationParams {
  const parsedPage = Number.parseInt(page || '1', 10)
  const parsedLimit = Number.parseInt(limit || '10', 10)

  if (Number.isNaN(parsedPage) || parsedPage < 1) {
    throw new Error('Page must be a positive integer')
  }

  if (Number.isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 100) {
    throw new Error('Limit must be between 1 and 100')
  }

  return {
    page: parsedPage,
    limit: parsedLimit
  }
}

/**
 * Calculates pagination metadata
 */
export function calculatePagination(
  page: number,
  limit: number,
  total: number
): PaginationMeta {
  return {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit)
  }
}

/**
 * Validates email format
 */
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

/**
 * Validates name format
 */
export function validateName(name: string): boolean {
  return name.length >= 2 && name.length <= 100
}

/**
 * Sanitizes string input by trimming whitespace
 */
export function sanitizeString(input: string): string {
  return input.trim()
}

/**
 * Formats response with timestamp
 */
export function formatResponse<T>(data: T): T & { timestamp: string } {
  return {
    ...data,
    timestamp: new Date().toISOString()
  }
}

/**
 * Generates a random ID (for demo purposes)
 */
export function generateId(): number {
  return Math.floor(Math.random() * 10000)
}

/**
 * Converts request size string to bytes
 */
export function parseRequestSize(sizeStr: string): number {
  const match = sizeStr.match(/^(\d+)(mb|kb|b)?$/i)
  if (!match || !match[1]) {
    throw new Error('Invalid request size format')
  }

  const value = Number.parseInt(match[1], 10)
  const unit = (match[2] || 'b').toLowerCase()

  switch (unit) {
    case 'mb':
      return value * 1024 * 1024
    case 'kb':
      return value * 1024
    default:
      return value
  }
}