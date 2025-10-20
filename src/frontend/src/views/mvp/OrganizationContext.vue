<template>
  <div class="organization-context-page">
    <div class="page-container">
      <div class="page-header">
        <h1 class="page-title">
          <el-icon><OfficeBuilding /></el-icon>
          Organization Context
        </h1>
        <p class="page-description">
          View your organization's SE-QPT assessment results and selected qualification approach
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="loading-container" v-loading="loading">
        <div class="loading-content">
          <p>Loading organization context...</p>
        </div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="error-container">
        <el-alert
          title="Error loading organization context"
          :description="error"
          type="error"
          show-icon
          :closable="false"
        />
      </div>

      <!-- Organization Context Content -->
      <div v-else class="content-container">
        <!-- Organization Overview -->
        <el-card class="organization-overview-card">
          <template #header>
            <div class="card-header">
              <h2>
                <el-icon><OfficeBuilding /></el-icon>
                Organization Overview
              </h2>
            </div>
          </template>

          <div class="org-details-grid">
            <div class="detail-item">
              <div class="detail-label">Organization Name</div>
              <div class="detail-value">{{ organizationData.name || 'Not Available' }}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Organization Size</div>
              <div class="detail-value">{{ getOrganizationSizeLabel(organizationData.size) }}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Total Employees</div>
              <div class="detail-value">{{ dashboardData.statistics?.total_users || 0 }}</div>
            </div>
            <div class="detail-item">
              <div class="detail-label">Completed Assessments</div>
              <div class="detail-value">
                {{ dashboardData.statistics?.completed_assessments || 0 }} / {{ dashboardData.statistics?.total_users || 0 }}
              </div>
            </div>
          </div>
        </el-card>

        <!-- Maturity Assessment Results (Phase 1) -->
        <el-card class="maturity-assessment-card">
          <template #header>
            <div class="card-header">
              <h2>
                <el-icon><TrendCharts /></el-icon>
                Organizational Maturity Assessment
              </h2>
              <p class="header-subtitle">Phase 1 results completed by organizational admin</p>
            </div>
          </template>

          <div v-if="!maturityAssessment" class="no-assessment">
            <el-alert
              title="Maturity assessment not yet completed"
              description="Your organization admin has not yet completed the maturity assessment."
              type="warning"
              show-icon
              :closable="false"
            />
          </div>

          <div v-else class="maturity-content">
            <!-- Maturity Level Display -->
            <div class="maturity-overview">
              <div class="maturity-badge">
                <el-progress
                  type="circle"
                  :percentage="Math.round((maturityAssessment.overall_score || 0) * 20)"
                  :width="100"
                  :stroke-width="8"
                  :color="getMaturityColor(maturityAssessment.overall_score)"
                >
                  <template #default="{ percentage }">
                    <span class="progress-text">{{ getMaturityLevel(maturityAssessment.overall_score) }}</span>
                  </template>
                </el-progress>
              </div>
              <div class="maturity-details">
                <h3 class="maturity-level-title">{{ getMaturityLevel(maturityAssessment.overall_score) }} Level</h3>
                <p class="maturity-score">Overall Score: {{ (maturityAssessment.overall_score || 0).toFixed(2) }}/5.0</p>
                <p class="completion-date">Completed: {{ formatDate(maturityAssessment.completed_at) }}</p>
              </div>
            </div>

            <!-- Detailed Scores -->
            <div class="scores-grid">
              <div class="score-item">
                <div class="score-label">Scope Score</div>
                <div class="score-value">{{ (maturityAssessment.scope_score || 0).toFixed(2) }}/5.0</div>
                <el-progress
                  :percentage="Math.round((maturityAssessment.scope_score || 0) * 20)"
                  color="#409eff"
                  :stroke-width="6"
                />
              </div>
              <div class="score-item">
                <div class="score-label">Process Score</div>
                <div class="score-value">{{ (maturityAssessment.process_score || 0).toFixed(2) }}/5.0</div>
                <el-progress
                  :percentage="Math.round((maturityAssessment.process_score || 0) * 20)"
                  color="#67c23a"
                  :stroke-width="6"
                />
              </div>
            </div>
          </div>
        </el-card>

        <!-- Selected Qualification Archetype -->
        <el-card class="archetype-card">
          <template #header>
            <div class="card-header">
              <h2>
                <el-icon><Guide /></el-icon>
                Qualification Approach
              </h2>
              <p class="header-subtitle">Selected archetype based on organizational maturity</p>
            </div>
          </template>

          <div v-if="!organizationData.selected_archetype" class="no-archetype">
            <el-alert
              title="Qualification archetype not yet selected"
              description="Your organization admin has not yet selected a qualification archetype."
              type="warning"
              show-icon
              :closable="false"
            />
          </div>

          <div v-else class="archetype-content">
            <div class="archetype-selection">
              <div class="archetype-badge">
                <el-tag type="primary" size="large" effect="dark">
                  <el-icon><CircleCheck /></el-icon>
                  {{ formatArchetypeName(organizationData.selected_archetype) }}
                </el-tag>
              </div>
              <div class="archetype-description">
                <p>{{ getArchetypeDescription(organizationData.selected_archetype) }}</p>
              </div>

              <!-- Archetype Characteristics -->
              <div class="archetype-characteristics">
                <h4>Key Characteristics:</h4>
                <ul>
                  <li v-for="characteristic in getArchetypeCharacteristics(organizationData.selected_archetype)"
                      :key="characteristic">
                    <el-icon><Check /></el-icon>
                    {{ characteristic }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </el-card>

        <!-- Next Steps for Employees -->
        <el-card class="next-steps-card">
          <template #header>
            <div class="card-header">
              <h2>
                <el-icon><Guide /></el-icon>
                Your Next Steps
              </h2>
            </div>
          </template>

          <div class="steps-container">
            <el-steps direction="vertical" :active="1">
              <el-step title="Complete Role Mapping Assessment" description="Help us understand your current role and responsibilities">
                <template #icon>
                  <el-icon><User /></el-icon>
                </template>
              </el-step>
              <el-step title="Complete Competency Assessment" description="Evaluate your current SE competency levels">
                <template #icon>
                  <el-icon><DocumentChecked /></el-icon>
                </template>
              </el-step>
              <el-step title="Receive Personalized Learning Plan" description="Get customized learning objectives based on your assessment results">
                <template #icon>
                  <el-icon><Trophy /></el-icon>
                </template>
              </el-step>
            </el-steps>

            <div class="action-buttons">
              <el-button type="primary" size="large" @click="$router.push('/app/phases/2')">
                <el-icon><Right /></el-icon>
                Start Phase 2 Assessments
              </el-button>
            </div>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '../../api/axios'
import {
  OfficeBuilding,
  TrendCharts,
  Guide,
  CircleCheck,
  Check,
  User,
  DocumentChecked,
  Trophy,
  Right
} from '@element-plus/icons-vue'

const loading = ref(true)
const error = ref('')
const organizationData = ref({})
const dashboardData = ref({})
const maturityAssessment = ref(null)

// Add function to get organization size label
const getOrganizationSizeLabel = (size) => {
  const sizeMap = {
    small: 'Small (< 100 employees)',
    medium: 'Medium (100-1000 employees)',
    large: 'Large (1000-10000 employees)',
    enterprise: 'Enterprise (> 10000 employees)'
  }
  return sizeMap[size] || size || 'Not specified'
}

// Maturity level functions updated for SE-QPT scoring
const getMaturityLevel = (score) => {
  if (!score && score !== 0) return 'Not Assessed'

  const percentage = score * 20 // Convert 0-5 scale to 0-100
  if (percentage >= 80) return 'Optimizing'
  if (percentage >= 60) return 'Defined'
  if (percentage >= 40) return 'Managed'
  if (percentage >= 20) return 'Performed'
  return 'Initial'
}

const getMaturityColor = (score) => {
  if (!score && score !== 0) return '#909399'

  const percentage = score * 20
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 60) return '#409eff'
  if (percentage >= 40) return '#e6a23c'
  if (percentage >= 20) return '#f56c6c'
  return '#f56c6c'
}

const formatArchetypeName = (archetype) => {
  return archetype || 'Not Selected'
}

const getArchetypeDescription = (archetype) => {
  const descriptions = {
    'Common Basic Understanding': 'Create shared SE awareness across all organizational stakeholders.',
    'Needs-based Project-oriented Training': 'Role-specific training tailored to project contexts and requirements.',
    'Continuous Support': 'Ongoing coaching and improvement support for advanced SE practices.',
    'SE for Managers': 'Executive-level SE understanding and strategic change management.',
    'Orientation in Pilot Project': 'Focused SE implementation through targeted pilot projects.'
  }
  return descriptions[archetype] || 'This archetype focuses on building appropriate SE capabilities for your organization.'
}

const getArchetypeCharacteristics = (archetype) => {
  const characteristics = {
    'Common Basic Understanding': [
      'Broad organizational awareness',
      'Standardized learning objectives',
      'Low customization level',
      'Foundation building focus'
    ],
    'Needs-based Project-oriented Training': [
      'Role-specific training approach',
      'High customization level',
      'Project-focused application',
      'Company-specific learning objectives'
    ],
    'Continuous Support': [
      'Ongoing coaching model',
      'High customization level',
      'Continuous improvement focus',
      'Advanced competency development'
    ],
    'SE for Managers': [
      'Management-focused content',
      'Strategic SE implementation',
      'Low customization level',
      'Executive-level understanding'
    ],
    'Orientation in Pilot Project': [
      'Pilot project approach',
      'High customization level',
      'Focused implementation',
      'Practical experience focus'
    ]
  }
  return characteristics[archetype] || [
    'Tailored to organizational needs',
    'Systematic capability building',
    'Progressive skill development'
  ]
}

const formatDate = (dateString) => {
  if (!dateString) return 'Unknown'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const loadOrganizationContext = async () => {
  try {
    loading.value = true

    // Get organization dashboard data using configured axios
    const dashboardResponse = await axios.get('/api/organization/dashboard')
    dashboardData.value = dashboardResponse.data
    organizationData.value = dashboardResponse.data.organization
    maturityAssessment.value = dashboardResponse.data.maturity_assessment

  } catch (err) {
    console.error('Error loading organization context:', err)
    error.value = err.response?.data?.error || 'Failed to load organization context'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadOrganizationContext()
})
</script>

<style scoped>
.organization-context-page {
  min-height: 100vh;
  background-color: #f5f7fa;
  padding: 24px;
}

.page-container {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
  text-align: center;
}

.page-title {
  font-size: 2rem;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.page-description {
  font-size: 1rem;
  color: #6c757d;
  margin: 0;
  line-height: 1.6;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
  flex-direction: column;
  gap: 16px;
}

.loading-content {
  text-align: center;
  color: #6c757d;
}

.error-container {
  margin-bottom: 24px;
}

.content-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* Card Headers */
.card-header {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.card-header h2 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
  color: #2c3e50;
  font-weight: 600;
  font-size: 1.2rem;
}

.header-subtitle {
  margin: 0;
  color: #6c757d;
  font-size: 0.9rem;
}

/* Organization Overview */
.organization-overview-card {
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.org-details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.detail-label {
  font-size: 0.9rem;
  color: #6c757d;
  font-weight: 500;
}

.detail-value {
  font-size: 1.1rem;
  color: #2c3e50;
  font-weight: 600;
}

/* Maturity Assessment */
.maturity-assessment-card {
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.no-assessment {
  padding: 16px;
}

.maturity-content {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.maturity-overview {
  display: flex;
  align-items: center;
  gap: 32px;
  justify-content: center;
  flex-wrap: wrap;
}

.maturity-badge {
  flex-shrink: 0;
}

.progress-text {
  font-size: 0.8rem;
  font-weight: 600;
  color: #2c3e50;
}

.maturity-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
  text-align: center;
}

.maturity-level-title {
  margin: 0;
  color: #2c3e50;
  font-size: 1.3rem;
  font-weight: 600;
}

.maturity-score {
  margin: 0;
  color: #6c757d;
  font-size: 1rem;
}

.completion-date {
  margin: 0;
  color: #909399;
  font-size: 0.9rem;
}

.scores-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
}

.score-item {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.score-label {
  font-size: 0.9rem;
  color: #6c757d;
  font-weight: 500;
}

.score-value {
  font-size: 1.5rem;
  color: #2c3e50;
  font-weight: 600;
}

/* Archetype Card */
.archetype-card {
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.no-archetype {
  padding: 16px;
}

.archetype-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.archetype-selection {
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.archetype-badge {
  margin-bottom: 16px;
}

.archetype-description {
  max-width: 600px;
  margin: 0 auto;
}

.archetype-description p {
  margin: 0;
  color: #6c757d;
  line-height: 1.6;
  font-size: 1rem;
}

.archetype-characteristics {
  text-align: left;
  max-width: 500px;
  margin: 0 auto;
}

.archetype-characteristics h4 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-weight: 600;
  font-size: 1rem;
}

.archetype-characteristics ul {
  margin: 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.archetype-characteristics li {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #6c757d;
  line-height: 1.4;
}

/* Next Steps Card */
.next-steps-card {
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.steps-container {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.action-buttons {
  display: flex;
  justify-content: center;
  padding-top: 16px;
}

/* Responsive Design */
@media (max-width: 768px) {
  .organization-context-page {
    padding: 16px;
  }

  .page-title {
    font-size: 1.5rem;
  }

  .org-details-grid {
    grid-template-columns: 1fr;
  }

  .maturity-overview {
    flex-direction: column;
    text-align: center;
  }

  .scores-grid {
    grid-template-columns: 1fr;
  }

  .archetype-characteristics {
    max-width: 100%;
  }
}
</style>