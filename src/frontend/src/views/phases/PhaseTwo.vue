<template>
  <div class="phase2-new-flow">
    <Phase2TaskFlowContainer
      v-if="organizationId"
      :organization-id="organizationId"
      :employee-name="employeeName"
      @complete="handleComplete"
      @back="handleBack"
    />
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
import Phase2TaskFlowContainer from '@/components/phase2/Phase2TaskFlowContainer.vue'

const router = useRouter()
const authStore = useAuthStore()

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

const handleComplete = (assessmentData) => {
  ElMessage.success('Phase 2 competency assessment completed!')
  console.log('Assessment data:', assessmentData)

  // Navigate to results or next phase
  router.push('/app/dashboard')
}

const handleBack = () => {
  router.push('/app/phases/1')
}

const goToDashboard = () => {
  router.push('/app/dashboard')
}

onMounted(() => {
  console.log('[Phase2NewFlow] Mounted with organizationId:', organizationId.value)
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
