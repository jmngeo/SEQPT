/**
 * Phase 2 Task 3 Composable
 * State management and business logic for Learning Objectives Generation
 */

import { ref, computed, customRef, watch } from 'vue'
import { phase2Task3Api } from '@/api/phase2'

// Create a composable instance counter to track re-creations
let instanceCounter = 0

export const usePhase2Task3 = (organizationId) => {
  // Track this instance
  const instanceId = ++instanceCounter
  console.log(`[usePhase2Task3] NEW INSTANCE CREATED: #${instanceId} for org ${organizationId}`)

  // State
  const isLoading = ref(false)
  const assessmentStats = ref(null)
  const selectedStrategiesCount = ref(0)  // Keep for backward compatibility

  // CRITICAL FIX: Use a plain JavaScript variable instead of ref
  // This avoids Vue reactivity issues that were causing the array to be empty
  let selectedStrategiesArray = []
  console.log(`[usePhase2Task3 #${instanceId}] Initialized selectedStrategiesArray:`, selectedStrategiesArray)

  const pmtContext = ref(null)
  const validationResults = ref(null)
  const learningObjectives = ref(null)
  const prerequisites = ref(null)
  const pathway = ref(null)
  const error = ref(null)

  // Computed
  const hasObjectives = computed(() => {
    return learningObjectives.value !== null &&
           Object.keys(learningObjectives.value).length > 0
  })

  const isReadyToGenerate = computed(() => {
    if (!prerequisites.value) return false
    return prerequisites.value.readyToGenerate === true
  })

  const needsPMT = computed(() => {
    if (!prerequisites.value) return false
    return prerequisites.value.needsPMT === true
  })

  const hasPMT = computed(() => {
    if (!prerequisites.value) return false
    return prerequisites.value.hasPMT === true
  })

  // Methods

  /**
   * Fetch all data needed for dashboard
   */
  const fetchData = async () => {
    try {
      isLoading.value = true
      error.value = null

      // Fetch prerequisites and assessment stats
      // Don't throw error - handle validation failures gracefully
      let prerequisitesResponse = null
      try {
        prerequisitesResponse = await fetchPrerequisites()
      } catch (err) {
        console.warn('[usePhase2Task3] Prerequisites check failed:', err)
        // Error state already set in fetchPrerequisites
      }

      // Only fetch objectives if they exist (without triggering generation)
      // Check the has_generated_objectives flag from prerequisites
      if (prerequisitesResponse?.has_generated_objectives) {
        console.log('[usePhase2Task3] Objectives exist, fetching them...')
        try {
          await fetchObjectives()
        } catch (err) {
          console.log('[usePhase2Task3] Failed to fetch existing objectives:', err.message)
        }
      } else {
        console.log('[usePhase2Task3] No objectives exist yet. Waiting for user to generate.')
      }

      // Fetch PMT context if it exists
      try {
        await fetchPMTContext()
      } catch (err) {
        // It's okay if PMT doesn't exist yet
        console.log('[usePhase2Task3] No PMT context found')
      }

    } catch (err) {
      console.error('[usePhase2Task3] Error fetching data:', err)
      error.value = err.message || 'Failed to load data'
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Fetch prerequisites check
   */
  let fetchPrerequisitesCallCount = 0

  const fetchPrerequisites = async () => {
    try {
      fetchPrerequisitesCallCount++
      console.log(`[usePhase2Task3 #${instanceId}] ============ fetchPrerequisites CALLED (Call #${fetchPrerequisitesCallCount}) ============`)
      console.trace('Called from:')

      const response = await phase2Task3Api.validatePrerequisites(organizationId)

      console.log('[usePhase2Task3] Raw prerequisites response:', response)

      // Handle two possible response structures:
      // 1. Valid response with completion_stats object
      // 2. Error response with direct fields
      const stats = response.completion_stats || {}
      const hasCompletionStats = Object.keys(stats).length > 0

      assessmentStats.value = {
        totalUsers: stats.total_users || 0,
        usersWithAssessments: stats.users_with_assessments || 0,
        completionRate: response.completion_rate || 0,
        organizationName: stats.organization_name || ''
      }

      // Determine pathway from response (may not be present in error response)
      pathway.value = response.pathway || 'ROLE_BASED'

      // Determine if assessments exist based on response type
      let hasAssessments = false
      if (hasCompletionStats) {
        hasAssessments = (stats.users_with_assessments || 0) > 0
      } else {
        // In error response, check if error is about strategies (not assessments)
        hasAssessments = response.error && !response.error.toLowerCase().includes('assessment')
      }

      // Determine if PMT is needed based on selected strategies
      // Deep customization strategies that require PMT context
      // Note: Check case-insensitive and handle variations in naming
      const selectedStrategies = response.selected_strategies || []
      const needsPMT = selectedStrategies.some(strategy => {
        const strategyName = (strategy.name || strategy).toLowerCase()
        // Check for "needs-based" with or without comma, and "continuous support"
        return strategyName.includes('needs-based') && strategyName.includes('project') ||
               strategyName.includes('continuous support')
      })

      // Check if PMT context exists
      const hasPMT = response.has_pmt_context || false

      // Build prerequisites object
      prerequisites.value = {
        hasAssessments: hasAssessments,
        hasStrategies: (response.selected_strategies_count || 0) > 0,
        needsPMT: needsPMT,  // Fixed: Now properly determined from selected strategies
        hasPMT: hasPMT,      // Fixed: Now from API response
        readyToGenerate: response.ready_to_generate || false,
        message: response.note || response.error || buildPrerequisitesMessage(response)
      }

      // Store strategy count and array from prerequisites response
      selectedStrategiesCount.value = response.selected_strategies_count || 0

      // CRITICAL FIX: Store in plain variable instead of ref
      const rawStrategies = response.selected_strategies || []
      console.log(`[usePhase2Task3 #${instanceId}] BEFORE ASSIGNMENT - rawStrategies:`, rawStrategies)

      selectedStrategiesArray = JSON.parse(JSON.stringify(rawStrategies))
      console.log(`[usePhase2Task3 #${instanceId}] AFTER ASSIGNMENT - selectedStrategiesArray:`, selectedStrategiesArray)
      console.log(`[usePhase2Task3 #${instanceId}] AFTER ASSIGNMENT - Length:`, selectedStrategiesArray.length)

      console.log('[usePhase2Task3] Prerequisites:', prerequisites.value)
      console.log('[usePhase2Task3] Pathway:', pathway.value)
      console.log('[usePhase2Task3] Assessment stats:', assessmentStats.value)
      console.log(`[usePhase2Task3 #${instanceId}] DEBUG: Selected strategies count:`, selectedStrategiesCount.value)
      console.log(`[usePhase2Task3 #${instanceId}] ============ fetchPrerequisites END - selectedStrategiesArray:`, selectedStrategiesArray)

      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error fetching prerequisites:', err)

      // Set default error state
      prerequisites.value = {
        hasAssessments: false,
        hasStrategies: false,
        needsPMT: false,
        hasPMT: false,
        readyToGenerate: false,
        message: 'Failed to check prerequisites. Please try again.'
      }

      throw err
    }
  }

  /**
   * Build prerequisites message
   */
  const buildPrerequisitesMessage = (response) => {
    const stats = response.completion_stats || {}
    const hasAssessments = (stats.users_with_assessments || 0) > 0
    const hasStrategies = (response.selected_strategies_count || 0) > 0
    const valid = response.valid || false

    if (!hasAssessments) {
      return 'No assessments completed yet. Please complete at least one assessment.'
    }

    if (!hasStrategies) {
      return 'No learning strategies selected. Please select strategies in Phase 1.'
    }

    if (!valid) {
      return response.error || 'Prerequisites not met. Please check requirements.'
    }

    return 'All prerequisites met. Ready to generate learning objectives!'
  }

  /**
   * Fetch PMT context
   */
  const fetchPMTContext = async () => {
    try {
      const response = await phase2Task3Api.getPMTContext(organizationId)

      if (response.success && response.data) {
        pmtContext.value = response.data
        console.log('[usePhase2Task3] PMT context loaded')
      } else {
        pmtContext.value = null
      }

      return response
    } catch (err) {
      console.log('[usePhase2Task3] PMT context not found:', err.message)
      pmtContext.value = null
      throw err
    }
  }

  /**
   * Save PMT context
   */
  const savePMTContext = async (pmtData) => {
    try {
      const response = await phase2Task3Api.savePMTContext(organizationId, pmtData)

      if (response.success) {
        pmtContext.value = response.data
        // Refresh prerequisites to update PMT status
        await fetchPrerequisites()
      }

      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error saving PMT context:', err)
      throw err
    }
  }

  /**
   * Run quick validation check
   */
  const runValidation = async () => {
    try {
      const response = await phase2Task3Api.runQuickValidation(organizationId)

      if (response.success) {
        // Extract and transform validation data from backend (snake_case) to frontend (camelCase)
        const backendValidation = response.validation || {}
        const backendRecommendations = response.recommendations || {}

        // Transform to component-expected format
        validationResults.value = {
          status: backendValidation.status || 'UNKNOWN',
          message: backendValidation.message || 'No validation message available',
          gapPercentage: backendValidation.gap_percentage,
          competenciesWithGaps: calculateCompetenciesWithGaps(backendValidation.competency_breakdown),
          usersAffected: backendValidation.total_users_with_gaps,
          severity: backendValidation.severity,
          strategiesAdequate: backendValidation.strategies_adequate,
          requiresStrategyRevision: backendValidation.requires_strategy_revision,
          recommendationLevel: backendValidation.recommendation_level,
          // Transform recommendations array
          recommendations: transformRecommendations(backendRecommendations)
        }

        console.log('[usePhase2Task3] Validation results (transformed):', validationResults.value)
      }

      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error running validation:', err)
      throw err
    }
  }

  /**
   * Calculate competencies with gaps from competency_breakdown
   */
  const calculateCompetenciesWithGaps = (competencyBreakdown) => {
    if (!competencyBreakdown) return 0

    const criticalGaps = competencyBreakdown.critical_gaps?.length || 0
    const significantGaps = competencyBreakdown.significant_gaps?.length || 0
    const minorGaps = competencyBreakdown.minor_gaps?.length || 0

    return criticalGaps + significantGaps + minorGaps
  }

  /**
   * Transform recommendations from backend format to component format
   */
  const transformRecommendations = (backendRecommendations) => {
    const recommendations = []

    // Overall message
    if (backendRecommendations.overall_message) {
      recommendations.push({
        type: 'info',
        message: backendRecommendations.overall_message,
        action: null
      })
    }

    // Suggested strategy additions
    if (backendRecommendations.suggested_strategy_additions?.length > 0) {
      backendRecommendations.suggested_strategy_additions.forEach(suggestion => {
        recommendations.push({
          type: 'warning',
          message: `Consider adding strategy: ${suggestion}`,
          action: 'add_strategy',
          actionLabel: 'Add Strategy',
          data: { strategyName: suggestion }
        })
      })
    }

    // Supplementary module guidance
    if (backendRecommendations.supplementary_module_guidance?.length > 0) {
      recommendations.push({
        type: 'info',
        message: 'Some competencies may benefit from supplementary modules. See details in results view.',
        action: null
      })
    }

    return recommendations
  }

  /**
   * Generate learning objectives
   */
  const generateObjectives = async (options = {}) => {
    try {
      // Debug: Check what we have before mapping
      console.log(`[usePhase2Task3 #${instanceId}] DEBUG: selectedStrategiesArray before mapping:`, selectedStrategiesArray)
      console.log(`[usePhase2Task3 #${instanceId}] DEBUG: Is array?`, Array.isArray(selectedStrategiesArray))
      console.log(`[usePhase2Task3 #${instanceId}] DEBUG: Length:`, selectedStrategiesArray.length)

      if (selectedStrategiesArray.length === 0) {
        throw new Error('No strategies selected - at least one strategy is required')
      }

      // Prepare request with selected strategies and PMT context
      const requestData = {
        ...options,
        selected_strategies: selectedStrategiesArray.map(s => ({
          strategy_id: s.id,
          strategy_name: s.name
        }))
      }

      console.log('[usePhase2Task3] DEBUG: Request data being sent:', requestData)

      // Add PMT context if it exists (unless explicitly disabled in options)
      if (pmtContext.value && !options.ignorePMT) {
        requestData.pmt_context = pmtContext.value
      }

      const response = await phase2Task3Api.generateObjectives(organizationId, requestData)

      if (response.success) {
        learningObjectives.value = response
        console.log('[usePhase2Task3] Learning objectives generated:', response)
        console.log('[usePhase2Task3] Objectives data structure:', JSON.stringify(response, null, 2))

        // Refresh only prerequisites to update status, but NOT objectives
        // (objectives are already set from generation response)
        await fetchPrerequisites()
      } else {
        throw new Error(response.error || 'Failed to generate learning objectives')
      }

      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error generating objectives:', err)

      // Extract user-friendly error message
      let errorMessage = 'Failed to generate learning objectives'

      if (err.response?.data?.error) {
        errorMessage = err.response.data.error
      } else if (err.message) {
        errorMessage = err.message
      }

      throw new Error(errorMessage)
    }
  }

  /**
   * Fetch existing learning objectives
   */
  const fetchObjectives = async (regenerate = false) => {
    try {
      const response = await phase2Task3Api.getObjectives(organizationId, regenerate)

      if (response.success && response.data) {
        learningObjectives.value = response.data
        console.log('[usePhase2Task3] Learning objectives loaded')
      } else {
        learningObjectives.value = null
      }

      return response
    } catch (err) {
      console.log('[usePhase2Task3] No existing objectives found')
      learningObjectives.value = null
      throw err
    }
  }

  /**
   * Export learning objectives
   */
  const exportObjectives = async (format, filters = {}) => {
    try {
      const response = await phase2Task3Api.exportObjectives(organizationId, format, filters)
      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error exporting objectives:', err)
      throw err
    }
  }

  /**
   * Add a recommended strategy
   * @param {String} strategyName - Name of strategy to add
   * @param {Object} pmtContext - PMT context (required if strategy needs it)
   * @param {Boolean} regenerate - Whether to regenerate objectives
   * @returns {Promise} Updated objectives if regenerate=true
   */
  const addRecommendedStrategy = async (strategyName, pmtContext = null, regenerate = true) => {
    try {
      const response = await phase2Task3Api.addRecommendedStrategy(
        organizationId,
        strategyName,
        pmtContext,
        regenerate
      )

      if (response.success) {
        console.log('[usePhase2Task3] Strategy added successfully:', strategyName)

        // If objectives were regenerated, update local state
        if (regenerate && response.regenerated_objectives) {
          learningObjectives.value = response.regenerated_objectives
        }

        // Refresh prerequisites to update strategy count
        await fetchPrerequisites()
      }

      return response
    } catch (err) {
      console.error('[usePhase2Task3] Error adding strategy:', err)

      // Extract user-friendly error message
      let errorMessage = 'Failed to add strategy'

      if (err.response?.data?.error) {
        errorMessage = err.response.data.error
      } else if (err.message) {
        errorMessage = err.message
      }

      throw new Error(errorMessage)
    }
  }

  /**
   * Refresh all data
   */
  const refreshData = async () => {
    return await fetchData()
  }

  // Return public API
  return {
    // State
    isLoading,
    assessmentStats,
    selectedStrategiesCount,  // Keep for backward compatibility
    pmtContext,
    validationResults,
    learningObjectives,
    prerequisites,
    pathway,
    error,

    // Computed
    hasObjectives,
    isReadyToGenerate,
    needsPMT,
    hasPMT,

    // Methods
    fetchData,
    fetchPrerequisites,
    fetchPMTContext,
    savePMTContext,
    runValidation,
    generateObjectives,
    fetchObjectives,
    exportObjectives,
    addRecommendedStrategy,
    refreshData
  }
}
