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
  const token = ref(null)
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
    token.value = null
    error.value = null

    // Clear localStorage (Derik's pattern)
    localStorage.removeItem('isAdminAuthenticated')
    localStorage.removeItem('user')
    localStorage.removeItem('se_qpt_token')

    // Clear organization data
    localStorage.removeItem('user_organization_code')
    localStorage.removeItem('user_organization_id')
    localStorage.removeItem('user_organization_name')

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

      // Backend returns: { access_token, user, organization }
      if (response.data.access_token && response.data.user) {
        // Store authentication data
        token.value = response.data.access_token
        localStorage.setItem('se_qpt_token', response.data.access_token)

        // Set user authentication (sets isAdminAuthenticated flag)
        setAuth(response.data.user)

        // Store organization data if available
        if (response.data.organization) {
          localStorage.setItem('user_organization_id', response.data.organization.id)
          localStorage.setItem('user_organization_name', response.data.organization.name)
          // Organization code (for inviting employees)
          const orgCode = response.data.organization.organization_code || response.data.organization.code
          if (orgCode) {
            localStorage.setItem('user_organization_code', orgCode)
          }
        } else if (response.data.user.organization_id) {
          // Fallback: just store organization ID if org details not included
          localStorage.setItem('user_organization_id', response.data.user.organization_id)
        }

        toast.success('Login successful!')
        return { success: true }
      } else {
        throw new Error('Login failed - invalid response from server')
      }
    } catch (err) {
      const message = err.response?.data?.error || err.message || 'Login failed'
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

      // Backend returns: { access_token, user, organization, organization_code }
      if (response.data.access_token) {
        // Store authentication data
        token.value = response.data.access_token
        localStorage.setItem('se_qpt_token', response.data.access_token)

        // Set user authentication (sets isAdminAuthenticated flag)
        setAuth(response.data.user)

        // Store organization data
        if (response.data.organization) {
          localStorage.setItem('user_organization_code', response.data.organization_code)
          localStorage.setItem('user_organization_id', response.data.organization.id)
          localStorage.setItem('user_organization_name', response.data.organization.name)
        }

        toast.success('Admin account created successfully!')
        return {
          success: true,
          organizationCode: response.data.organization_code
        }
      } else {
        throw new Error('Registration failed - no access token received')
      }
    } catch (err) {
      const message = err.response?.data?.error || err.message || 'Admin registration failed'
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

      // Backend returns: { access_token, user, organization }
      if (response.data.access_token) {
        // Store authentication data
        token.value = response.data.access_token
        localStorage.setItem('se_qpt_token', response.data.access_token)

        // Set user authentication (sets isAdminAuthenticated flag)
        setAuth(response.data.user)

        // Store organization data
        if (response.data.organization) {
          localStorage.setItem('user_organization_code', userData.organizationCode)
          localStorage.setItem('user_organization_id', response.data.organization.id)
          localStorage.setItem('user_organization_name', response.data.organization.name)
        }

        toast.success('Employee account created successfully!')
        return {
          success: true,
          organizationName: response.data.organization?.name
        }
      } else {
        throw new Error('Registration failed - no access token received')
      }
    } catch (err) {
      const message = err.response?.data?.error || err.message || 'Employee registration failed'
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
    token,
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
