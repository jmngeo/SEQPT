<template>
  <div class="assessment-history">
    <div class="history-header">
      <h2>{{ userRole === 'admin' ? 'Organization Assessment History' : 'My Assessment History' }}</h2>
      <p class="subtitle">{{ userRole === 'admin' ? 'View all assessments in your organization' : 'View and manage your past competency assessments' }}</p>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <el-icon class="is-loading" size="48"><Loading /></el-icon>
      <p>Loading your assessment history...</p>
    </div>

    <!-- Error State -->
    <el-alert
      v-else-if="error"
      type="error"
      :title="error"
      show-icon
      :closable="false"
    />

    <!-- Empty State -->
    <el-empty
      v-else-if="!loading && assessments.length === 0"
      description="No assessments found"
    >
      <template #default>
        <p class="empty-description">You haven't completed any assessments yet.</p>
        <el-button type="primary" @click="goToNewAssessment">
          Start Your First Assessment
        </el-button>
      </template>
    </el-empty>

    <!-- Assessment List -->
    <div v-else class="assessments-container">
      <div class="assessments-stats">
        <el-statistic
          title="Total Assessments"
          :value="totalAssessments"
        />
        <el-statistic
          title="Latest Assessment"
          :value="latestDate"
        />
        <div class="average-score-container">
          <div class="score-header">
            <span class="score-title">Average Competency Level</span>
            <el-tooltip placement="top" effect="dark">
              <template #content>
                <div class="tooltip-content">
                  <p><strong>Competency Level Scale:</strong></p>
                  <p>0-1: Awareness Level</p>
                  <p>1-2: Understanding Level</p>
                  <p>2-4: Application Level</p>
                  <p>4-6: Mastery Level</p>
                </div>
              </template>
              <el-icon class="info-icon"><InfoFilled /></el-icon>
            </el-tooltip>
          </div>
          <div class="score-value-container">
            <span class="score-numeric">{{ overallAverage.toFixed(1) }}<span class="score-max">/6</span></span>
            <el-tag :type="getScoreLevelColor(overallAverage)" size="large" effect="plain">
              {{ overallAverageLevel }}
            </el-tag>
          </div>
        </div>
      </div>

      <div class="assessments-grid">
        <el-card
          v-for="assessment in assessments"
          :key="assessment.id"
          class="assessment-card"
          shadow="hover"
        >
          <template #header>
            <div class="card-header">
              <div class="header-left">
                <el-tag :type="getAssessmentTypeColor(assessment.assessment_type)" size="large">
                  {{ getAssessmentTypeLabel(assessment.assessment_type) }}
                </el-tag>
                <span class="assessment-date">
                  {{ formatDate(assessment.assessment_date) }}
                </span>
              </div>
              <el-tag
                :type="getStatusColor(assessment.status)"
                effect="plain"
                round
              >
                {{ assessment.status }}
              </el-tag>
            </div>
          </template>

          <div class="card-content">
            <!-- Assessment Details -->
            <div class="assessment-details">
              <div class="detail-item">
                <span class="detail-label">Assessment ID:</span>
                <span class="detail-value">#{{ assessment.id }}</span>
              </div>

              <div class="detail-item">
                <span class="detail-label">Average Score:</span>
                <div class="score-display">
                  <el-progress
                    :percentage="(assessment.avg_score / 6) * 100"
                    :color="getScoreColor(assessment.avg_score)"
                    :show-text="false"
                  />
                  <span class="score-value">{{ assessment.avg_score.toFixed(1) }}/6</span>
                </div>
              </div>

              <div v-if="assessment.selected_roles && assessment.selected_roles.length > 0" class="detail-item">
                <span class="detail-label">Selected Roles:</span>
                <div class="roles-list">
                  <el-tag
                    v-for="role in assessment.selected_roles"
                    :key="role.id"
                    size="small"
                    type="info"
                  >
                    {{ role.name }}
                  </el-tag>
                </div>
              </div>

              <div class="detail-item">
                <span class="detail-label">Assessed User:</span>
                <span class="detail-value">{{ assessment.user_name || assessment.username }}</span>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="card-actions">
              <el-button
                type="primary"
                @click="viewAssessmentResults(assessment.id)"
                :icon="View"
              >
                View Results
              </el-button>
              <el-button
                @click="shareAssessment(assessment.id)"
                :icon="Share"
              >
                Share
              </el-button>
            </div>
          </div>
        </el-card>
      </div>

      <!-- Pagination (if needed in future) -->
      <!-- <el-pagination
        v-if="totalAssessments > pageSize"
        v-model:current-page="currentPage"
        :page-size="pageSize"
        layout="prev, pager, next"
        :total="totalAssessments"
        @current-change="handlePageChange"
      /> -->
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Loading, View, Share, InfoFilled } from '@element-plus/icons-vue'

const router = useRouter()

// State
const loading = ref(false)
const error = ref(null)
const assessments = ref([])
const totalAssessments = ref(0)
const userRole = ref('employee') // Track user role for header display

// Computed
const latestDate = computed(() => {
  if (assessments.value.length === 0) return 'N/A'
  return formatDate(assessments.value[0].assessment_date)
})

const overallAverage = computed(() => {
  if (assessments.value.length === 0) return 0
  const sum = assessments.value.reduce((acc, a) => acc + a.avg_score, 0)
  return sum / assessments.value.length
})

const overallAverageLevel = computed(() => {
  const score = overallAverage.value
  if (score < 1) return 'Awareness'
  if (score < 2) return 'Understanding'
  if (score < 4) return 'Application'
  return 'Mastery'
})

// Methods
const fetchAssessmentHistory = async () => {
  try {
    loading.value = true
    error.value = null

    // Get admin_user_id from localStorage
    const userData = localStorage.getItem('user')
    if (!userData) {
      throw new Error('User not logged in')
    }

    const user = JSON.parse(userData)
    const adminUserId = user.id

    // Fetch assessment history from backend
    const response = await fetch(`http://localhost:5000/api/users/${adminUserId}/assessments`)

    if (!response.ok) {
      throw new Error(`Failed to fetch assessments: ${response.status}`)
    }

    const data = await response.json()
    assessments.value = data.assessments || []
    totalAssessments.value = data.total_assessments || 0
    userRole.value = data.user_role || 'employee' // Get user role from response

  } catch (err) {
    console.error('Error fetching assessment history:', err)
    error.value = err.message || 'Failed to load assessment history'
    ElMessage.error(error.value)
  } finally {
    loading.value = false
  }
}

const viewAssessmentResults = (assessmentId) => {
  // Navigate to the results page with assessment ID
  router.push({
    name: 'AssessmentResults',
    params: { id: assessmentId }
  })
}

const shareAssessment = (assessmentId) => {
  // Copy assessment URL to clipboard
  const url = `${window.location.origin}/assessments/${assessmentId}/results`

  navigator.clipboard.writeText(url).then(() => {
    ElMessage.success('Assessment link copied to clipboard!')
  }).catch(() => {
    ElMessage.error('Failed to copy link')
  })
}

const goToNewAssessment = () => {
  router.push({ name: 'PhaseTwo' })
}

const getAssessmentTypeLabel = (type) => {
  const labels = {
    'known_roles': 'Role-Based',
    'unknown_roles': 'Task-Based',
    'all_roles': 'Full Competency'
  }
  return labels[type] || type
}

const getAssessmentTypeColor = (type) => {
  const colors = {
    'known_roles': 'primary',
    'unknown_roles': 'success',
    'all_roles': 'warning'
  }
  return colors[type] || 'info'
}

const getStatusColor = (status) => {
  const colors = {
    'completed': 'success',
    'in_progress': 'warning',
    'failed': 'danger'
  }
  return colors[status] || 'info'
}

const getScoreColor = (score) => {
  if (score >= 5) return '#67c23a' // Green
  if (score >= 3.5) return '#e6a23c' // Orange
  return '#f56c6c' // Red
}

const getScoreLevelColor = (score) => {
  if (score >= 4) return 'success' // Mastery - Green
  if (score >= 2) return 'warning' // Application - Orange
  if (score >= 1) return 'info' // Understanding - Blue
  return '' // Awareness - Default gray
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  const options = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }
  return date.toLocaleDateString('en-US', options)
}

// Lifecycle
onMounted(() => {
  fetchAssessmentHistory()
})
</script>

<style scoped>
.assessment-history {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.history-header {
  text-align: center;
  margin-bottom: 3rem;
}

.history-header h2 {
  color: #303133;
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #606266;
  font-size: 1rem;
}

.loading-container {
  text-align: center;
  padding: 4rem 0;
}

.loading-container p {
  margin-top: 1rem;
  color: #606266;
}

.empty-description {
  margin-bottom: 1rem;
  color: #909399;
}

.assessments-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #F8F9FA;
  border-radius: 8px;
}

.assessments-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.assessment-card {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.assessment-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.assessment-date {
  font-size: 0.9rem;
  color: #909399;
}

.card-content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.assessment-details {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.detail-label {
  font-size: 0.9rem;
  color: #909399;
  font-weight: 500;
}

.detail-value {
  color: #303133;
  font-weight: 500;
}

.score-display {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.score-display .el-progress {
  flex: 1;
}

.score-value {
  font-size: 1.1rem;
  font-weight: 600;
  color: #303133;
  min-width: 60px;
}

.roles-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.card-actions {
  display: flex;
  gap: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #EBEEF5;
}

.card-actions .el-button {
  flex: 1;
}

/* Average Score Container Styles */
.average-score-container {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.score-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.score-title {
  font-size: 0.875rem;
  color: #909399;
  font-weight: 500;
}

.info-icon {
  font-size: 1rem;
  color: #909399;
  cursor: help;
  transition: color 0.3s;
}

.info-icon:hover {
  color: #409EFF;
}

.tooltip-content {
  line-height: 1.6;
}

.tooltip-content p {
  margin: 0.25rem 0;
}

.score-value-container {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.score-numeric {
  font-size: 1.75rem;
  font-weight: 600;
  color: #303133;
}

.score-max {
  font-size: 1.25rem;
  color: #909399;
  font-weight: 500;
}

@media (max-width: 768px) {
  .assessment-history {
    padding: 1rem;
  }

  .assessments-grid {
    grid-template-columns: 1fr;
  }

  .assessments-stats {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .card-actions {
    flex-direction: column;
  }

  .score-numeric {
    font-size: 1.5rem;
  }

  .score-max {
    font-size: 1rem;
  }
}
</style>
