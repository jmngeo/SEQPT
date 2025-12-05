import axios from './axios'

export const authApi = {
  // Authentication endpoints - Using MVP auth system
  login: (credentials) => {
    // MVP /api/mvp/auth/login endpoint: POST {username, password} -> {access_token, user}
    return axios.post('/api/mvp/auth/login', {
      username: credentials.usernameOrEmail,
      password: credentials.password
    })
  },

  // Admin registration - creates organization and admin user
  registerAdmin: (userData) => {
    return axios.post('/api/mvp/auth/register-admin', {
      username: userData.username,
      password: userData.password,
      organization_name: userData.organizationName,
      organization_size: userData.organizationSize
    })
  },

  // Employee registration - joins existing organization with code
  registerEmployee: (userData) => {
    return axios.post('/api/mvp/auth/register-employee', {
      username: userData.username,
      password: userData.password,
      organization_code: userData.organizationCode
    })
  },

  // Verify organization code
  verifyOrganizationCode: (code) => {
    return axios.get(`/api/organization/verify-code/${code}`)
  },

  logout: () => {
    // Simple logout - no server-side session to clear
    return Promise.resolve({ data: { success: true } })
  },

  // Removed: refresh() and verify() - not used in Derik's simple auth system

  // Profile management
  getProfile: () => {
    return axios.get('/api/auth/profile')
  },

  updateProfile: (profileData) => {
    return axios.put('/api/auth/profile', {
      first_name: profileData.firstName,
      last_name: profileData.lastName,
      organization: profileData.organization,
      role: profileData.role
    })
  },

  changePassword: (passwordData) => {
    return axios.post('/api/auth/change-password', {
      current_password: passwordData.currentPassword,
      new_password: passwordData.newPassword
    })
  },

  // Admin endpoints
  getUsers: (params = {}) => {
    return axios.get('/api/auth/admin/users', { params })
  },

  updateUser: (userId, userData) => {
    return axios.put(`/api/auth/admin/users/${userId}`, userData)
  }
}