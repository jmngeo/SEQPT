// Vitest setup file
import { vi } from 'vitest'

// Mock window.matchMedia (used by Element Plus)
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

// Global test utilities
global.console = {
  ...console,
  // Uncomment to suppress console.log in tests:
  // log: vi.fn(),
  error: console.error,
  warn: console.warn,
  info: vi.fn(),
  debug: vi.fn(),
}
