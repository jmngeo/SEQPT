<template>
  <div class="organization-results">
    <!-- Organization Overview Card -->
    <el-card class="results-card overview-card">
      <template #header>
        <div class="card-header">
          <h3>
            <el-icon><OfficeBuilding /></el-icon>
            Organization Overview
          </h3>
        </div>
      </template>

      <div class="organization-overview">
        <div class="org-details-grid">
          <div class="detail-item">
            <div class="detail-label">Organization Name</div>
            <div class="detail-value">{{ organizationData?.name || 'Your Organization' }}</div>
          </div>
          <div class="detail-item">
            <div class="detail-label">Organization Size</div>
            <div class="detail-value">{{ getOrganizationSizeLabel(organizationData?.size) }}</div>
          </div>
          <div class="detail-item" v-if="organizationData?.employeeCount">
            <div class="detail-label">Total Employees</div>
            <div class="detail-value">{{ organizationData.employeeCount.toLocaleString() }}</div>
          </div>
        </div>

        <div class="assessment-status">
          <div v-if="organizationData?.assessmentStatus === 'completed'" class="status-completed">
            <el-tag type="success" size="large" effect="dark">
              <el-icon><CircleCheck /></el-icon>
              Phase 1 Assessment Complete
            </el-tag>
            <p class="completion-date">
              Completed on {{ formatDate(organizationData.completedDate) }}
            </p>
          </div>

          <div v-else-if="organizationData?.assessmentStatus === 'pending'" class="status-pending">
            <el-tag type="warning" size="large" effect="dark">
              <el-icon><Clock /></el-icon>
              Assessment Pending
            </el-tag>
            <p class="status-message">{{ organizationData.message }}</p>
          </div>

          <div v-else class="status-error">
            <el-tag type="danger" size="large" effect="dark">
              <el-icon><Warning /></el-icon>
              Unable to Load Data
            </el-tag>
            <p class="status-message">{{ organizationData?.message || 'Please contact your administrator.' }}</p>
          </div>
        </div>
      </div>
    </el-card>

    <!-- Assessment Results (only show if completed) -->
    <div v-if="organizationData?.assessmentStatus === 'completed'" class="assessment-results">
      <!-- Maturity Assessment Results -->
      <el-card class="results-card maturity-card">
        <template #header>
          <div class="card-header">
            <h3>
              <el-icon><TrendCharts /></el-icon>
              Systems Engineering Maturity Level
            </h3>
          </div>
        </template>

        <div class="maturity-results">
          <div class="maturity-score-display">
            <div class="score-circle">
              <el-progress
                type="circle"
                :percentage="Math.round(organizationData.maturityScore || 0)"
                :width="120"
                :stroke-width="8"
                :color="getMaturityColor(organizationData.maturityScore)"
              />
            </div>

            <div class="score-details">
              <div class="maturity-level">
                <h4>{{ getMaturityLevel(organizationData.maturityScore) }}</h4>
                <p class="level-description">
                  {{ getMaturityLevelDescription(getMaturityLevel(organizationData.maturityScore)) }}
                </p>
              </div>

              <div class="score-breakdown">
                <div class="score-item">
                  <span class="label">Maturity Score:</span>
                  <span class="value">{{ organizationData.maturityScore.toFixed(1) }}%</span>
                </div>
                <div class="score-item">
                  <span class="label">Level:</span>
                  <span class="value">{{ getMaturityLevel(organizationData.maturityScore) }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="maturity-explanation">
            <el-alert
              :title="`${getMaturityLevel(organizationData.maturityScore)} Maturity Level`"
              :description="getMaturityExplanation(organizationData.maturityScore)"
              type="info"
              show-icon
              :closable="false"
            />
          </div>
        </div>
      </el-card>

      <!-- Training Strategy Selection Results -->
      <el-card class="results-card archetype-card">
        <template #header>
          <div class="card-header">
            <h3>
              <el-icon><Guide /></el-icon>
              Selected Training Strategy
            </h3>
          </div>
        </template>

        <div class="archetype-results">
          <div class="archetype-selection">
            <div class="archetype-badge">
              <el-tag type="primary" size="large" effect="dark">
                {{ organizationData.selectedArchetype || 'Not Selected' }}
              </el-tag>
              <!-- Display secondary strategy if it exists (dual selection) -->
              <el-tag v-if="organizationData.secondaryArchetype" type="success" size="large" effect="dark" style="margin-left: 12px;">
                {{ organizationData.secondaryArchetype }}
              </el-tag>
            </div>

            <!-- Show note about dual selection -->
            <el-alert v-if="organizationData.secondaryArchetype" type="info" :closable="false" style="margin-bottom: 16px;">
              <template #title>Dual Strategy Approach</template>
              Your organization requires both <strong>{{ organizationData.selectedArchetype }}</strong> and <strong>{{ organizationData.secondaryArchetype }}</strong> training strategies due to low maturity level.
            </el-alert>

            <div class="archetype-description">
              <p>{{ getArchetypeDescription(organizationData.selectedArchetype) }}</p>
            </div>

            <div class="archetype-characteristics">
              <h5>Key Characteristics:</h5>
              <ul>
                <li v-for="characteristic in getArchetypeCharacteristics(organizationData.selectedArchetype)"
                    :key="characteristic">
                  {{ characteristic }}
                </li>
              </ul>
            </div>
          </div>

          <div class="next-steps">
            <el-alert
              title="What's Next?"
              description="Based on your organization's maturity level and selected training strategy, you'll receive a personalized learning path in Phase 2: Identify Requirements and Competencies."
              type="success"
              show-icon
              :closable="false"
            />
          </div>
        </div>
      </el-card>
    </div>

    <!-- Action Buttons -->
    <div class="action-section">
      <div class="action-buttons">
        <el-button @click="goToDashboard">
          Return to Dashboard
        </el-button>

        <el-button v-if="organizationData?.assessmentStatus === 'completed'" type="primary" @click="proceedToPhase2">
          Proceed to Phase 2
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import {
  OfficeBuilding,
  CircleCheck,
  Clock,
  Warning,
  TrendCharts,
  Guide,
  House,
  Right
} from '@element-plus/icons-vue'

const router = useRouter()

// Props
const props = defineProps({
  organizationData: {
    type: Object,
    default: () => ({})
  }
})

// Methods
const getOrganizationSizeLabel = (value) => {
  const sizeMap = {
    small: 'Small (< 100 employees)',
    medium: 'Medium (100-1000 employees)',
    large: 'Large (1000-10000 employees)',
    enterprise: 'Enterprise (> 10000 employees)'
  }
  return sizeMap[value] || value
}

const formatDate = (dateString) => {
  if (!dateString) return 'Unknown'
  return new Date(dateString).toLocaleDateString('de-DE', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'Europe/Berlin'
  })
}

const getMaturityLevel = (score) => {
  // Check if score is null or undefined (not just falsy, because 0 is valid)
  if (score === null || score === undefined) return 'Not Assessed'

  // score is already a percentage (0-100) from the database
  const percentage = score
  if (percentage >= 80) return 'Optimizing'
  if (percentage >= 60) return 'Defined'
  if (percentage >= 40) return 'Managed'
  if (percentage >= 20) return 'Performed'
  return 'Initial'
}

const getMaturityColor = (score) => {
  // Check if score is null or undefined (not just falsy, because 0 is valid)
  if (score === null || score === undefined) return '#909399'

  // score is already a percentage (0-100) from the database
  const percentage = score
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 60) return '#409eff'
  if (percentage >= 40) return '#e6a23c'
  if (percentage >= 20) return '#f56c6c'
  return '#f56c6c'
}

const getMaturityLevelDescription = (level) => {
  const descriptions = {
    'Initial': 'Basic processes exist but are unpredictable and reactive.',
    'Performed': 'Processes are performed but often ad hoc.',
    'Managed': 'Processes are planned, monitored, and controlled.',
    'Defined': 'Processes are well-defined and standardized.',
    'Optimizing': 'Focus on continuous process improvement.',
    'Not Assessed': 'Maturity assessment has not been completed.'
  }
  return descriptions[level] || 'Assessment pending.'
}

const getMaturityExplanation = (score) => {
  const level = getMaturityLevel(score)
  const explanations = {
    'Initial': 'Your organization is beginning its SE journey. Focus on establishing basic processes and building awareness.',
    'Performed': 'SE practices exist but need more consistency. Work on standardizing successful approaches.',
    'Managed': 'Good foundation of SE practices. Focus on integration and measurement.',
    'Defined': 'Strong SE capabilities. Ready for advanced techniques and organization-wide adoption.',
    'Optimizing': 'Excellent SE maturity. Focus on innovation and continuous improvement.',
    'Not Assessed': 'Maturity assessment needs to be completed by your administrator.'
  }
  return explanations[level] || 'Assessment data unavailable.'
}

const getArchetypeDescription = (archetype) => {
  const descriptions = {
    'Common Basic Understanding': 'Create shared SE awareness across all organizational stakeholders.',
    'Needs-based Project-oriented Training': 'Role-specific training tailored to project contexts and requirements.',
    'Continuous Support': 'Ongoing coaching and improvement support for advanced SE practices.',
    'SE for Managers': 'Executive-level SE understanding and strategic change management.',
    'Orientation in Pilot Project': 'Focused SE implementation through targeted pilot projects.'
  }
  return descriptions[archetype] || 'This training strategy focuses on building appropriate SE capabilities for your organization.'
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

const goToDashboard = () => {
  router.push('/app/dashboard')
}

const proceedToPhase2 = () => {
  router.push('/app/phases/2')
}
</script>

<style scoped>
.organization-results {
  max-width: 1000px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.results-card {
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.card-header h3 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
  color: #2c3e50;
  font-weight: 600;
}

/* Organization Overview */
.organization-overview {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.org-details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  margin-bottom: 20px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.detail-label {
  font-size: 0.875rem;
  color: #909399;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-value {
  font-size: 1.125rem;
  color: #2c3e50;
  font-weight: 600;
}

.org-basic-info {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 16px;
}

.org-name {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.org-name h4 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: 600;
}

.org-stats {
  display: flex;
  gap: 24px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.stat-label {
  font-size: 0.9rem;
  color: #6c757d;
  margin-bottom: 4px;
}

.stat-value {
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.assessment-status {
  text-align: center;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.completion-date {
  margin: 8px 0 0 0;
  color: #6c757d;
  font-size: 0.9rem;
}

.status-message {
  margin: 8px 0 0 0;
  color: #6c757d;
  line-height: 1.5;
}

/* Maturity Results */
.maturity-results {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.maturity-score-display {
  display: flex;
  gap: 32px;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
}

.score-circle {
  flex-shrink: 0;
}

.score-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 300px;
}

.maturity-level h4 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.3rem;
  font-weight: 600;
}

.level-description {
  margin: 0;
  color: #6c757d;
  line-height: 1.5;
}

.score-breakdown {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.score-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #f8f9fa;
  border-radius: 6px;
}

.score-item .label {
  color: #6c757d;
  font-size: 0.9rem;
}

.score-item .value {
  color: #2c3e50;
  font-weight: 600;
}

/* Archetype Results */
.archetype-results {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.archetype-selection {
  text-align: center;
}

.archetype-badge {
  margin-bottom: 16px;
}

.archetype-description {
  margin-bottom: 20px;
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

.archetype-characteristics h5 {
  margin: 0 0 12px 0;
  color: #2c3e50;
  font-weight: 600;
}

.archetype-characteristics ul {
  margin: 0;
  padding-left: 20px;
  color: #6c757d;
}

.archetype-characteristics li {
  margin-bottom: 8px;
  line-height: 1.4;
}

/* Action Section */
.action-section {
  padding: 24px;
  background: #f8f9fa;
  border-radius: 12px;
  text-align: center;
}

.action-buttons {
  display: flex;
  gap: 16px;
  justify-content: center;
  flex-wrap: wrap;
}

/* Assessment Results Grid */
.assessment-results {
  display: grid;
  grid-template-columns: 1fr;
  gap: 24px;
}

@media (min-width: 768px) {
  .assessment-results {
    grid-template-columns: 1fr 1fr;
  }

  .maturity-score-display {
    justify-content: flex-start;
  }
}

@media (max-width: 767px) {
  .organization-results {
    padding: 0 12px;
  }

  .org-basic-info {
    flex-direction: column;
    text-align: center;
  }

  .maturity-score-display {
    flex-direction: column;
    text-align: center;
  }

  .score-details {
    max-width: 100%;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-buttons .el-button {
    width: 100%;
  }
}
</style>