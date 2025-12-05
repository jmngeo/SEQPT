<template>
  <div class="phase2-task3-admin-view">
    <!-- Loading state while fetching organization -->
    <el-card v-if="isLoadingOrg" class="loading-card">
      <div style="text-align: center; padding: 40px;">
        <el-icon class="is-loading" :size="40"><Loading /></el-icon>
        <p style="margin-top: 16px;">Loading organization data...</p>
      </div>
    </el-card>

    <!-- Main dashboard -->
    <Phase2Task3Dashboard
      v-else-if="organizationId"
      :organization-id="organizationId"
    />

    <!-- No organization error -->
    <el-card v-else class="error-card">
      <el-alert
        title="No Organization Found"
        description="Please select an organization from your dashboard first."
        type="error"
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
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import { Loading } from '@element-plus/icons-vue'
import Phase2Task3Dashboard from '@/components/phase2/task3/Phase2Task3Dashboard.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// State
const isLoadingOrg = ref(false)

// Get organizationId from route query or auth store
const organizationId = computed(() => {
  // Try route query first
  const routeOrgId = parseInt(route.query.orgId)
  if (routeOrgId && !isNaN(routeOrgId)) {
    return routeOrgId
  }

  // Fallback to user's organization
  return authStore.user?.organization_id || null
})

// Methods
const goToDashboard = () => {
  router.push('/app/dashboard')
}

// Check admin permissions
const checkAdminPermissions = () => {
  if (!authStore.isAdmin) {
    ElMessage.error('Admin access required for Phase 2 Task 3')
    router.push('/app/dashboard')
    return false
  }
  return true
}

// Lifecycle
onMounted(async () => {
  console.log('[Phase2Task3Admin] Mounted')
  console.log('[Phase2Task3Admin] Organization ID:', organizationId.value)

  // Check admin permissions
  if (!checkAdminPermissions()) {
    return
  }

  // Verify organization exists
  if (!organizationId.value) {
    ElMessage.warning('No organization selected')
  }
})
</script>

<style scoped>
.phase2-task3-admin-view {
  min-height: 100vh;
  background: var(--el-bg-color-page);
}

.loading-card,
.error-card {
  max-width: 600px;
  margin: 100px auto;
}

.error-card .actions {
  margin-top: 24px;
  text-align: center;
}
</style>
