import axios from 'axios'
import { toast } from 'vue3-toastify'

// Create axios instance
const instance = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor
instance.interceptors.request.use(
  (config) => {
    // Add auth token to requests
    const token = localStorage.getItem('se_qpt_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
instance.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Handle 401 errors (token expired)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        // Try to refresh token
        const refreshToken = localStorage.getItem('se_qpt_refresh_token')
        if (refreshToken) {
          const response = await instance.post('/auth/refresh', {}, {
            headers: {
              Authorization: `Bearer ${refreshToken}`
            }
          })

          if (response.data.access_token) {
            // Update stored token
            localStorage.setItem('se_qpt_token', response.data.access_token)

            // Update request header and retry
            originalRequest.headers.Authorization = `Bearer ${response.data.access_token}`
            return instance(originalRequest)
          }
        }
      } catch (refreshError) {
        console.error('Token refresh failed:', refreshError)
      }

      // If refresh failed, clear auth and redirect to login
      localStorage.removeItem('se_qpt_token')
      localStorage.removeItem('se_qpt_refresh_token')

      // Only show toast if not already on login page
      if (!window.location.pathname.includes('/auth/login')) {
        toast.error('Session expired. Please login again.')
        window.location.href = '/auth/login'
      }
    }

    // Handle 403 errors (insufficient permissions)
    if (error.response?.status === 403) {
      toast.error('You do not have permission to perform this action.')
    }

    // Handle 404 errors
    if (error.response?.status === 404) {
      toast.error('Resource not found.')
    }

    // Handle 500 errors
    if (error.response?.status >= 500) {
      toast.error('Server error. Please try again later.')
    }

    // Handle network errors
    if (error.code === 'NETWORK_ERROR' || error.message === 'Network Error') {
      toast.error('Network error. Please check your connection.')
    }

    // Handle timeout errors
    if (error.code === 'ECONNABORTED' || error.message.includes('timeout')) {
      toast.error('Request timeout. Please try again.')
    }

    return Promise.reject(error)
  }
)

// Make axios available globally for auth store
if (typeof window !== 'undefined') {
  window.axios = instance
}

export default instance