import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api/auth'
import { toast } from 'vue3-toastify'

/**
 * SE-QPT Auth Store - Using Derik's simple localStorage-based authentication
 * No JWT tokens, no server-side sessions - just simple localStorage flags
 */
export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Getters
  const isAuthenticated = computed(() => {
    // Check localStorage flag (Derik's pattern)
    return localStorage.getItem('isAdminAuthenticated') === 'true'
  })

  const isAdmin = computed(() => {
    // Check if user has admin role
    return isAuthenticated.value && user.value?.role === 'admin'
  })

  const userName = computed(() => {
    if (!user.value) return ''
    return user.value.username || ''
  })

  const userId = computed(() => {
    if (!user.value) return null
    return user.value.id || null
  })

  const organizationId = computed(() => {
    // Get organization ID from localStorage (set during login)
    const orgId = localStorage.getItem('user_organization_id')
    return orgId ? parseInt(orgId, 10) : null
  })

  const organizationName = computed(() => {
    return localStorage.getItem('user_organization_name') || ''
  })

  const organizationCode = computed(() => {
    return localStorage.getItem('user_organization_code') || ''
  })

  // Actions
  const setAuth = (userData) => {
    user.value = userData
    // Store auth flag (Derik's pattern)
    localStorage.setItem('isAdminAuthenticated', 'true')
    localStorage.setItem('user', JSON.stringify(userData))
  }

  const clearAuth = () => {
    user.value = null
    error.value = null

    // Clear localStorage (Derik's pattern)
    localStorage.removeItem('isAdminAuthenticated')
    localStorage.removeItem('user')

    // Clear SE-QPT related data to prevent cross-user contamination
    localStorage.removeItem('se-qpt-phase1-data')
    localStorage.removeItem('se-qpt-phase2-data')

    // Remove all user-specific SE-QPT keys
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('se-qpt-') && key.includes('-user-')) {
        localStorage.removeItem(key)
      }
    })
  }

  const login = async (credentials) => {
    try {
      loading.value = true
      error.value = null

      const response = await authApi.login(credentials)

      // Derik's response format: {success: true/false, message: "...", organization: {...}}
      if (response.data.success) {
        // Store user data
        const userData = {
          id: response.data.user?.id,  // Store user ID
          username: response.data.user?.username || credentials.usernameOrEmail,
          role: response.data.user?.role || 'employee'  // Get role from backend
        }
        setAuth(userData)

        // Store organization data if available
        if (response.data.organization) {
          localStorage.setItem('user_organization_code', response.data.organization.code)
          localStorage.setItem('user_organization_id', response.data.organization.id)
          localStorage.setItem('user_organization_name', response.data.organization.name)
        }

        toast.success('Login successful!')
        return { success: true }
      } else {
        throw new Error(response.data.message || 'Login failed')
      }
    } catch (err) {
      const message = err.response?.data?.message || err.message || 'Login failed'
      error.value = message
      toast.error(message)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const registerAdmin = async (userData) => {
    try {
      loading.value = true
      error.value = null

      const response = await authApi.registerAdmin(userData)

      if (response.data.success) {
        // Store organization code for this user
        localStorage.setItem('user_organization_code', response.data.organization_code)
        toast.success(response.data.message)
        return {
          success: true,
          organizationCode: response.data.organization_code
        }
      } else {
        throw new Error(response.data.message || 'Admin registration failed')
      }
    } catch (err) {
      const message = err.response?.data?.message || err.message || 'Admin registration failed'
      error.value = message
      toast.error(message)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const registerEmployee = async (userData) => {
    try {
      loading.value = true
      error.value = null

      const response = await authApi.registerEmployee(userData)

      if (response.data.success) {
        // Store organization code that was used for registration
        localStorage.setItem('user_organization_code', userData.organizationCode)
        toast.success(response.data.message)
        return {
          success: true,
          organizationName: response.data.organization_name
        }
      } else {
        throw new Error(response.data.message || 'Employee registration failed')
      }
    } catch (err) {
      const message = err.response?.data?.message || err.message || 'Employee registration failed'
      error.value = message
      toast.error(message)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const verifyOrgCode = async (code) => {
    try {
      const response = await authApi.verifyOrganizationCode(code)
      return response.data
    } catch (err) {
      return { valid: false, message: 'Verification failed' }
    }
  }

  const logout = async () => {
    clearAuth()
    toast.success('Logged out successfully')
    // Redirect to login page
    window.location.href = '/auth/login'
  }

  const checkAuth = async () => {
    // Simple check: is the localStorage flag set?
    if (localStorage.getItem('isAdminAuthenticated') === 'true') {
      // Restore user data from localStorage
      const storedUser = localStorage.getItem('user')
      if (storedUser) {
        user.value = JSON.parse(storedUser)
      }
      return true
    }
    return false
  }

  // Initialize auth state
  const initialize = async () => {
    // Restore auth state from localStorage
    await checkAuth()
  }

  return {
    // State
    user,
    loading,
    error,

    // Getters
    isAuthenticated,
    isAdmin,
    userName,
    userId,
    organizationId,
    organizationName,
    organizationCode,

    // Actions
    login,
    registerAdmin,
    registerEmployee,
    verifyOrgCode,
    logout,
    checkAuth,
    initialize,
    setAuth,
    clearAuth
  }
})
