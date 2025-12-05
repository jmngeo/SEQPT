<template>
  <div class="phase2-new-flow">
    <!-- Loading state -->
    <el-card v-if="isLoadingMaturity" class="loading-message">
      <div style="text-align: center; padding: 40px;">
        <el-icon class="is-loading" :size="40"><Loading /></el-icon>
        <p style="margin-top: 16px;">Loading Phase 1 maturity data...</p>
      </div>
    </el-card>

    <!-- Main content -->
    <Phase2TaskFlowContainer
      v-else-if="organizationId && maturityLevel !== null"
      :organization-id="organizationId"
      :employee-name="employeeName"
      :maturity-level="maturityLevel"
      @complete="handleComplete"
      @back="handleBack"
    />

    <!-- No organization message -->
    <el-card v-else class="no-org-message">
      <el-alert
        title="No Organization Selected"
        description="Please select or create an organization to access Phase 2 competency assessment."
        type="warning"
        show-icon
        :closable="false"
      />
      <div class="actions">
        <el-button type="primary" @click="goToDashboard">
          Go to Dashboard
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import { Loading } from '@element-plus/icons-vue'
import axios from '@/api/axios'
import Phase2TaskFlowContainer from '@/components/phase2/Phase2TaskFlowContainer.vue'

const router = useRouter()
const authStore = useAuthStore()

// State for maturity level
const maturityLevel = ref(null)
const isLoadingMaturity = ref(false)

// State for checking existing assessments
const checkingExistingAssessment = ref(false)

// Get organizationId from auth store or route params
const organizationId = computed(() => {
  // Try to get from route params first
  const routeOrgId = parseInt(router.currentRoute.value.query.orgId)
  if (routeOrgId) return routeOrgId

  // Fallback to user's organization
  return authStore.user?.organization_id || null
})

const employeeName = computed(() => {
  return authStore.user?.name || authStore.user?.username || 'User'
})

// Check for existing completed assessment and auto-redirect
const checkExistingAssessment = async () => {
  if (!organizationId.value) return

  try {
    checkingExistingAssessment.value = true

    // Check if there's a query param to skip auto-redirect (for creating new assessments)
    if (router.currentRoute.value.query.new === 'true' || router.currentRoute.value.query.fresh === 'true') {
      console.log('[Phase2] Skip auto-redirect: creating new assessment')
      return
    }

    // Fetch latest assessment for this organization/user
    const response = await axios.get(`/api/latest_competency_overview`, {
      params: { organization_id: organizationId.value }
    })

    if (response.data && response.data.assessment_id) {
      const assessmentId = response.data.assessment_id
      console.log('[Phase2] Found existing completed assessment:', assessmentId)

      // Auto-redirect to latest results
      ElMessage.info('Redirecting to your latest assessment results...')
      router.replace(`/app/assessments/${assessmentId}/results`)
    } else {
      console.log('[Phase2] No existing completed assessment found')
    }
  } catch (error) {
    console.error('[Phase2] Error checking existing assessment:', error)
    // Continue to normal flow on error
  } finally {
    checkingExistingAssessment.value = false
  }
}

// Fetch maturity level from Phase 1
const fetchMaturityLevel = async () => {
  if (!organizationId.value) return

  try {
    isLoadingMaturity.value = true
    const response = await axios.get(`/api/phase1/maturity/${organizationId.value}/latest`)

    if (response.data.exists && response.data.data) {
      const results = response.data.data.results || {}
      const strategyInputs = results.strategyInputs || {}
      maturityLevel.value = strategyInputs.seProcessesValue || 5 // Default to 5 if not found (role-based pathway)

      console.log('[Phase2NewFlow] Fetched maturity level:', maturityLevel.value)
    } else {
      // No maturity assessment found - default to role-based pathway
      maturityLevel.value = 5
      console.log('[Phase2NewFlow] No maturity assessment found, defaulting to maturity level 5 (role-based)')
    }
  } catch (error) {
    console.error('[Phase2NewFlow] Error fetching maturity level:', error)
    // Default to role-based pathway on error
    maturityLevel.value = 5
  } finally {
    isLoadingMaturity.value = false
  }
}

const handleComplete = (assessmentData) => {
  ElMessage.success('Phase 2 competency assessment completed!')
  console.log('Assessment data:', assessmentData)

  // Navigate to persistent results URL
  if (assessmentData && assessmentData.assessmentId) {
    router.push(`/app/assessments/${assessmentData.assessmentId}/results`)
  } else {
    // Fallback to dashboard if no assessment ID
    router.push('/app/dashboard')
  }
}

const handleBack = () => {
  router.push('/app/phases/1')
}

const goToDashboard = () => {
  router.push('/app/dashboard')
}

onMounted(async () => {
  console.log('[Phase2NewFlow] Mounted with organizationId:', organizationId.value)

  // First check for existing completed assessment
  await checkExistingAssessment()

  // If not redirected, fetch maturity level and continue with normal flow
  await fetchMaturityLevel()
})
</script>

<style scoped>
.phase2-new-flow {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.no-org-message {
  max-width: 600px;
  margin: 100px auto;
  text-align: center;
}

.actions {
  margin-top: 24px;
}
</style>
