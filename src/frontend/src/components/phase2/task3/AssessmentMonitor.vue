<template>
  <el-card class="assessment-monitor">
    <template #header>
      <div class="card-header">
        <h3 class="section-heading">Assessment Completion Status</h3>
        <el-button @click="handleRefresh" :icon="Refresh" :loading="isRefreshing">
          Refresh
        </el-button>
      </div>
    </template>

    <!-- Loading State -->
    <div v-if="isLoading" style="text-align: center; padding: 40px;">
      <el-icon class="is-loading" :size="32"><Loading /></el-icon>
      <p style="margin-top: 16px;">Loading assessment data...</p>
    </div>

    <!-- Content -->
    <div v-else-if="stats">
      <!-- Overall Progress -->
      <div class="progress-section">
        <div class="stats-row">
          <el-statistic title="Total Users" :value="stats.totalUsers" />
          <el-statistic title="Completed Assessments" :value="stats.usersWithAssessments" />
          <el-statistic
            title="Completion Rate"
            :value="stats.completionRate"
            suffix="%"
            :value-style="{ color: progressColor }"
          />
        </div>
        <el-progress
          :percentage="stats.completionRate"
          :color="progressColor"
          :status="progressStatus"
          style="margin-top: 16px;"
        />

        <!-- Info Note -->
        <div class="info-note">
          <el-icon :size="16" color="#909399"><InfoFilled /></el-icon>
          <span>
            You can generate learning objectives at any time. If additional users complete their assessments later,
            simply return to this page via the <strong>Objectives</strong> menu to regenerate updated objectives.
          </span>
        </div>
      </div>

      <!-- User Assessment Details - Collapsible -->
      <el-collapse v-model="expandedSections" class="user-details-collapse" style="margin-top: 24px;">
        <el-collapse-item title="User Assessment Details" name="users">
          <template #title>
            <div class="collapse-header">
              <span class="collapse-title">User Assessment Details</span>
              <el-tag size="small" type="info" style="margin-left: 8px;">{{ userList.length }} users</el-tag>
            </div>
          </template>
          <el-table
            :data="userList"
            stripe
            size="small"
            :default-sort="{ prop: 'completed_at', order: 'descending' }"
            v-loading="isLoadingUsers"
          >
            <el-table-column
              prop="username"
              label="User"
              sortable
              min-width="200"
            />
            <el-table-column
              label="Status"
              width="100"
              align="center"
            >
              <template #default="scope">
                <el-tag
                  :type="scope.row.status === 'completed' ? 'success' : 'warning'"
                  effect="light"
                  size="small"
                >
                  {{ scope.row.status === 'completed' ? 'Completed' : 'Pending' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column
              prop="completed_at"
              label="Completed At"
              sortable
              width="180"
              align="center"
            >
              <template #default="scope">
                {{ formatDate(scope.row.completed_at) }}
              </template>
            </el-table-column>
          </el-table>
        </el-collapse-item>
      </el-collapse>
    </div>

    <!-- Empty State -->
    <el-empty v-else description="No assessment data available" />
  </el-card>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { Refresh, Loading, InfoFilled } from '@element-plus/icons-vue'
import { phase2Task3Api } from '@/api/phase2'

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  pathway: {
    type: String,
    default: null
  },
  assessmentStats: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['refresh'])

// State
const stats = ref(null)
const userList = ref([])
const isLoading = ref(false)
const isRefreshing = ref(false)
const isLoadingUsers = ref(false)
const expandedSections = ref([])  // Start collapsed

// Computed
const progressColor = computed(() => {
  const rate = stats.value?.completionRate || 0
  if (rate >= 80) return '#67C23A' // Green
  if (rate >= 50) return '#E6A23C' // Yellow
  return '#F56C6C' // Red
})

const progressStatus = computed(() => {
  const rate = stats.value?.completionRate || 0
  if (rate >= 80) return 'success'
  if (rate >= 50) return 'warning'
  return 'exception'
})

// Methods
const fetchStats = async () => {
  try {
    isLoading.value = true
    // Use stats from prop if available
    if (props.assessmentStats) {
      stats.value = props.assessmentStats
    } else {
      // Fallback to empty stats
      stats.value = {
        totalUsers: 0,
        usersWithAssessments: 0,
        completionRate: 0,
        organizationName: 'Organization'
      }
    }
    console.log('[AssessmentMonitor] Stats fetched:', stats.value)

    // Fetch detailed user list
    await fetchUserList()
  } catch (error) {
    console.error('[AssessmentMonitor] Error fetching stats:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchUserList = async () => {
  try {
    isLoadingUsers.value = true
    const response = await phase2Task3Api.getAssessmentUsers(props.organizationId)

    if (response.success && response.users) {
      userList.value = response.users
      console.log('[AssessmentMonitor] User list loaded:', userList.value.length, 'users')
    } else {
      userList.value = []
    }
  } catch (error) {
    console.error('[AssessmentMonitor] Error fetching user list:', error)
    userList.value = []
  } finally {
    isLoadingUsers.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '—'
  const date = new Date(dateString)
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const handleRefresh = async () => {
  try {
    isRefreshing.value = true
    await fetchStats()
    emit('refresh')
  } finally {
    isRefreshing.value = false
  }
}

// Watch for changes to assessmentStats prop
watch(() => props.assessmentStats, (newStats) => {
  if (newStats) {
    stats.value = newStats
    console.log('[AssessmentMonitor] Stats updated from prop:', newStats)
  }
}, { immediate: true, deep: true })

// Lifecycle
onMounted(async () => {
  await fetchStats()
})
</script>

<style scoped>
.assessment-monitor {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-heading {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.progress-section {
  padding: 16px;
}

.stats-row {
  display: flex;
  gap: 48px;
  margin-bottom: 16px;
}

/* User Details Collapse */
.user-details-collapse {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
}

.user-details-collapse :deep(.el-collapse-item__header) {
  background: #f8f9fa;
  padding: 0 16px;
  font-size: 14px;
  font-weight: 500;
}

.user-details-collapse :deep(.el-collapse-item__content) {
  padding: 16px;
}

.collapse-header {
  display: flex;
  align-items: center;
}

.collapse-title {
  font-weight: 600;
  color: #606266;
}

/* Info Note */
.info-note {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-top: 20px;
  padding: 14px 16px;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
}

.info-note .el-icon {
  flex-shrink: 0;
  margin-top: 2px;
}

.info-note strong {
  color: #409EFF;
}
</style>
