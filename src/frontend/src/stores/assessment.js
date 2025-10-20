import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { assessmentApi } from '@/api/assessment'
import { toast } from 'vue3-toastify'

export const useAssessmentStore = defineStore('assessment', () => {
  // State
  const assessments = ref([])
  const currentAssessment = ref(null)
  const loading = ref(false)
  const error = ref(null)
  const analytics = ref(null)

  // Getters
  const completedAssessments = computed(() =>
    assessments.value.filter(a => a.status === 'completed')
  )

  const inProgressAssessments = computed(() =>
    assessments.value.filter(a => a.status === 'in_progress')
  )

  const pendingAssessments = computed(() =>
    assessments.value.filter(a => a.status === 'pending')
  )

  const totalAssessments = computed(() => assessments.value.length)

  const completionRate = computed(() => {
    if (totalAssessments.value === 0) return 0
    return (completedAssessments.value.length / totalAssessments.value) * 100
  })

  // Actions
  const fetchAssessments = async () => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.getAssessments()
      assessments.value = response.data.assessments || []

      return { success: true }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to fetch assessments'
      error.value = message
      console.error('Fetch assessments error:', err)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const fetchAssessment = async (assessmentUuid) => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.getAssessment(assessmentUuid)
      currentAssessment.value = response.data.assessment

      return { success: true, assessment: response.data.assessment }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to fetch assessment'
      error.value = message
      console.error('Fetch assessment error:', err)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const createAssessment = async (assessmentData) => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.createAssessment(assessmentData)

      // Add to local state
      if (response.data.assessment) {
        const newAssessment = {
          id: response.data.assessment.id,
          uuid: response.data.assessment.uuid,
          type: response.data.assessment.type,
          phase: response.data.assessment.phase,
          status: 'pending',
          progress: 0,
          ...assessmentData,
          started_at: new Date().toISOString()
        }
        assessments.value.unshift(newAssessment)
      }

      toast.success('Assessment created successfully!')
      return { success: true, assessment: response.data.assessment }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to create assessment'
      error.value = message
      toast.error(message)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const updateAssessment = async (assessmentUuid, updateData) => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.updateAssessment(assessmentUuid, updateData)

      // Update local state
      const index = assessments.value.findIndex(a => a.uuid === assessmentUuid)
      if (index !== -1) {
        assessments.value[index] = { ...assessments.value[index], ...updateData }
      }

      if (currentAssessment.value?.uuid === assessmentUuid) {
        currentAssessment.value = { ...currentAssessment.value, ...updateData }
      }

      return { success: true }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to update assessment'
      error.value = message
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const deleteAssessment = async (assessmentUuid) => {
    try {
      loading.value = true
      error.value = null

      await assessmentApi.deleteAssessment(assessmentUuid)

      // Remove from local state
      assessments.value = assessments.value.filter(a => a.uuid !== assessmentUuid)

      if (currentAssessment.value?.uuid === assessmentUuid) {
        currentAssessment.value = null
      }

      toast.success('Assessment deleted successfully!')
      return { success: true }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to delete assessment'
      error.value = message
      toast.error(message)
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const fetchAnalytics = async () => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.getAnalytics()
      analytics.value = response.data.analytics

      return { success: true, analytics: response.data.analytics }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to fetch analytics'
      error.value = message
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const fetchRecommendations = async (assessmentId) => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.getRecommendations(assessmentId)
      return { success: true, recommendations: response.data.recommendations }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to fetch recommendations'
      error.value = message
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const exportAssessment = async (assessmentId) => {
    try {
      loading.value = true
      error.value = null

      const response = await assessmentApi.exportAssessment(assessmentId)
      return { success: true, exportData: response.data.export_data }
    } catch (err) {
      const message = err.response?.data?.error || 'Failed to export assessment'
      error.value = message
      return { success: false, error: message }
    } finally {
      loading.value = false
    }
  }

  const clearCurrentAssessment = () => {
    currentAssessment.value = null
  }

  const clearError = () => {
    error.value = null
  }

  // Helper methods
  const getAssessmentByUuid = (uuid) => {
    return assessments.value.find(a => a.uuid === uuid) || null
  }

  const getAssessmentsByPhase = (phase) => {
    return assessments.value.filter(a => a.phase === phase)
  }

  const getAssessmentsByStatus = (status) => {
    return assessments.value.filter(a => a.status === status)
  }

  return {
    // State
    assessments,
    currentAssessment,
    loading,
    error,
    analytics,

    // Getters
    completedAssessments,
    inProgressAssessments,
    pendingAssessments,
    totalAssessments,
    completionRate,

    // Actions
    fetchAssessments,
    fetchAssessment,
    createAssessment,
    updateAssessment,
    deleteAssessment,
    fetchAnalytics,
    fetchRecommendations,
    exportAssessment,
    clearCurrentAssessment,
    clearError,

    // Helpers
    getAssessmentByUuid,
    getAssessmentsByPhase,
    getAssessmentsByStatus
  }
})