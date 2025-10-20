<template>
  <div class="competency-results">
    <div v-if="loading" class="loading-container">
      <el-loading
        element-loading-text="Analyzing your assessment results..."
        element-loading-background="rgba(0, 0, 0, 0.8)"
      />
      <div class="progress-messages">
        <p class="loading-message">Our AI is generating a personalized assessment for you.</p>
      </div>
    </div>

    <div v-else class="results-content">
      <!-- Results Header -->
      <div class="results-header">
        <h2 class="results-title">Your SE Competency Assessment Results</h2>
        <p class="results-subtitle">
          Based on your responses across {{ competencyData.length }} competency areas
        </p>
      </div>

      <!-- Assessment Summary -->
      <div class="summary-cards">
        <el-card class="summary-card">
          <div class="summary-item">
            <div class="summary-icon">
              <el-icon size="32" color="#67c23a"><TrophyBase /></el-icon>
            </div>
            <div class="summary-content">
              <h3>Overall Score</h3>
              <p class="summary-value">{{ overallScore.toFixed(1) }}%</p>
              <p class="summary-desc">{{ getScoreDescription(overallScore) }}</p>
            </div>
          </div>
        </el-card>

        <el-card class="summary-card">
          <div class="summary-item">
            <div class="summary-icon">
              <el-icon size="32" color="#409eff"><DataBoard /></el-icon>
            </div>
            <div class="summary-content">
              <h3>Competencies Assessed</h3>
              <p class="summary-value">{{ competencyData.length }}</p>
              <p class="summary-desc">Across {{ uniqueAreas.length }} areas</p>
            </div>
          </div>
        </el-card>

        <el-card class="summary-card" v-if="recommendedRole">
          <div class="summary-item">
            <div class="summary-icon">
              <el-icon size="32" color="#e6a23c"><UserFilled /></el-icon>
            </div>
            <div class="summary-content">
              <h3>Best Match Role</h3>
              <p class="summary-value">{{ recommendedRole.name }}</p>
              <p class="summary-desc">{{ Math.round(recommendedRole.matchScore * 100) }}% match</p>
            </div>
          </div>
        </el-card>
      </div>

      <!-- Competency Areas Selection -->
      <el-card class="chart-section">
        <template #header>
          <div class="chart-header">
            <h3>Competency Overview</h3>
            <p>Select competency areas to view detailed results</p>
          </div>
        </template>

        <div class="area-selection">
          <div class="area-chips">
            <el-tag
              v-for="area in uniqueAreas"
              :key="area"
              :type="selectedAreas.includes(area) ? 'primary' : 'info'"
              :effect="selectedAreas.includes(area) ? 'dark' : 'plain'"
              @click="toggleAreaSelection(area)"
              class="area-chip"
              size="large"
            >
              {{ area }}
            </el-tag>
          </div>
        </div>

        <!-- Radar Chart -->
        <div class="chart-container">
          <div v-if="chartData && filteredCompetencyData.length > 0" class="radar-chart">
            <Radar :data="chartData" :options="chartOptions" />
          </div>
          <div v-else class="chart-placeholder">
            <el-icon size="64" color="#c0c4cc"><DataBoard /></el-icon>
            <p>Select competency areas to view radar chart</p>
            <p class="chart-note">Visual representation of your competency levels across selected areas</p>
          </div>
        </div>
      </el-card>

      <!-- Detailed Competency Results -->
      <el-card class="competency-details">
        <template #header>
          <h3>Detailed Competency Analysis</h3>
        </template>

        <div class="competency-areas">
          <div
            v-for="area in filteredAreas"
            :key="area.name"
            class="area-section"
          >
            <div class="area-header">
              <h4 class="area-title">{{ area.name }}</h4>
              <el-tag :type="getAreaScoreType(area.averageScore)" size="large">
                {{ area.averageScore.toFixed(1) }}% Average
              </el-tag>
            </div>

            <div class="competencies-grid">
              <div
                v-for="competency in area.competencies"
                :key="competency.id"
                class="competency-item"
              >
                <div class="competency-header">
                  <h5 class="competency-name">{{ competency.name }}</h5>
                </div>

                <!-- Competency Levels Display -->
                <div class="competency-levels">
                  <div class="level-info">
                    <span class="level-label">Your Level:</span>
                    <span class="level-value current-level">{{ competency.scoreText }}</span>
                  </div>
                  <div class="level-info">
                    <span class="level-label">Required Level:</span>
                    <span class="level-value required-level">{{ competency.requiredText }}</span>
                  </div>
                  <div class="level-info">
                    <span class="level-label">Status:</span>
                    <el-tag
                      :type="competency.status === 'exceeded' ? 'success' : (competency.status === 'met' ? 'success' : 'warning')"
                      :effect="competency.status === 'below' ? 'dark' : 'light'"
                      size="small"
                    >
                      {{ competency.status === 'exceeded' ? 'Exceeded' : (competency.status === 'met' ? 'Met' : 'Below Target') }}
                    </el-tag>
                  </div>
                </div>

                <div class="competency-progress">
                  <el-progress
                    :percentage="competency.percentage > 100 ? 100 : competency.percentage"
                    :color="getProgressColor(competency.percentage)"
                    :stroke-width="8"
                  />
                  <p class="progress-label">
                    {{ competency.percentage }}% of required level
                    <span v-if="competency.percentage > 100" class="exceeded-note">
                      ({{ competency.percentage - 100 }}% above target)
                    </span>
                  </p>
                </div>

                <div class="competency-feedback">
                  <div v-if="competency.strengths" class="feedback-section">
                    <p class="feedback-label">Strengths:</p>
                    <p class="feedback-text">{{ competency.strengths }}</p>
                  </div>
                  <div v-if="competency.improvements" class="feedback-section">
                    <p class="feedback-label">
                      {{ competency.status === 'below' ? 'Areas for Improvement:' : 'Status:' }}
                    </p>
                    <p class="feedback-text">{{ competency.improvements }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-card>

      <!-- Action Buttons -->
      <div class="actions">
        <el-button @click="$emit('back')" size="large">
          Previous
        </el-button>
        <el-button @click="exportResults" size="large" type="info">
          <el-icon><Download /></el-icon>
          Export Results
        </el-button>
        <el-button type="primary" @click="proceedToNextStep" size="large">
          Continue to Company Context
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import axios from 'axios'
import {
  TrophyBase,
  DataBoard,
  UserFilled,
  Download
} from '@element-plus/icons-vue'
import { Radar } from 'vue-chartjs'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  RadarController,
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler
} from 'chart.js'

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  RadarController,
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler
)

const route = useRoute()

// Props - Make assessmentData optional for persistent URL mode
const props = defineProps({
  assessmentData: {
    type: Object,
    required: false,
    default: null
  }
})

// Emits
const emit = defineEmits(['back', 'continue'])

// State
const loading = ref(true)
const selectedAreas = ref([])
const competencyData = ref([])
const maxScores = ref([])
const recommendedRole = ref(null)

// Chart data for radar visualization
const chartData = ref(null)
const chartOptions = ref({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    title: {
      display: true,
      text: 'Competency Assessment Results',
      font: {
        size: 16,
        weight: 'bold'
      }
    },
    legend: {
      position: 'bottom',
      labels: {
        padding: 20,
        usePointStyle: true
      }
    },
    tooltip: {
      callbacks: {
        label: function(context) {
          return `${context.dataset.label}: ${context.parsed.r}/6 (${Math.round((context.parsed.r/6)*100)}%)`
        }
      }
    }
  },
  scales: {
    r: {
      angleLines: {
        display: true
      },
      suggestedMin: 0,
      suggestedMax: 6,
      ticks: {
        stepSize: 1,
        callback: function(value) {
          const labels = ['0', '1 - Aware', '2 - Understanding', '3', '4 - Applying', '5', '6 - Mastering']
          return labels[value] || value
        }
      },
      pointLabels: {
        font: {
          size: 11
        },
        callback: function(label) {
          // Truncate long labels
          return label.length > 20 ? label.substring(0, 17) + '...' : label
        }
      }
    }
  }
})

// Computed properties
const uniqueAreas = computed(() => {
  return [...new Set(competencyData.value.map(comp => comp.area))]
})

const filteredAreas = computed(() => {
  const areas = {}

  competencyData.value
    .filter(comp => selectedAreas.value.length === 0 || selectedAreas.value.includes(comp.area))
    .forEach(comp => {
      if (!areas[comp.area]) {
        areas[comp.area] = {
          name: comp.area,
          competencies: [],
          totalScore: 0,
          count: 0
        }
      }
      areas[comp.area].competencies.push(comp)
      areas[comp.area].totalScore += comp.percentage
      areas[comp.area].count++
    })

  // Calculate average scores for each area
  // Note: totalScore already includes uncapped percentages from line 334
  // For consistency, we'll recalculate with capped percentages
  Object.values(areas).forEach(area => {
    const cappedTotal = area.competencies.reduce((sum, comp) => {
      return sum + Math.min(comp.percentage, 100)
    }, 0)
    area.averageScore = cappedTotal / area.count
  })

  return Object.values(areas)
})

const overallScore = computed(() => {
  if (competencyData.value.length === 0) return 0
  // Cap each competency percentage at 100% for overall score calculation
  // This prevents inflated averages when users exceed requirements
  const total = competencyData.value.reduce((sum, comp) => {
    const cappedPercentage = Math.min(comp.percentage, 100)
    return sum + cappedPercentage
  }, 0)
  return total / competencyData.value.length
})

const filteredCompetencyData = computed(() => {
  return competencyData.value.filter(comp =>
    selectedAreas.value.length === 0 || selectedAreas.value.includes(comp.area)
  )
})

// Methods
const processAssessmentData = async () => {
  try {
    loading.value = true

    let user_scores, max_scores, most_similar_role, feedback_list, selectedRoles, type

    // Check if we have an assessment_id from route params (persistent URL mode)
    const assessmentId = route.params.id

    if (assessmentId) {
      // Mode 1: Fetch by assessment_id from new API endpoint (persistent URL)
      console.log('Fetching results by assessment ID:', assessmentId)

      const response = await axios.get(`http://localhost:5000/api/assessments/${assessmentId}/results`)

      const data = response.data
      user_scores = data.user_scores
      max_scores = data.max_scores
      feedback_list = data.feedback_list
      most_similar_role = [] // Not returned by this endpoint yet
      selectedRoles = [] // Not returned by this endpoint yet
      type = data.assessment_type

      console.log('Received from persistent URL API:', data)
    } else if (props.assessmentData) {
      // Mode 2: Fetch by username from old API (immediate results after submission)
      const { surveyData, selectedRoles: propRoles, type: propType } = props.assessmentData
      const username = surveyData?.username || 'test_user'

      // Get organization_id from logged-in user
      const userData = localStorage.getItem('user')
      let organization_id = 1  // Fallback
      if (userData) {
        try {
          const user = JSON.parse(userData)
          organization_id = user.organization_id || 1
        } catch (e) {
          console.warn('Could not parse user data:', e)
        }
      }

      console.log('Fetching results by username:', { username, organization_id, survey_type: propType })

      const response = await axios.get('http://localhost:5000/get_user_competency_results', {
        params: {
          username: username,
          organization_id: organization_id,
          survey_type: propType || 'known_roles'
        }
      })

      const data = response.data
      user_scores = data.user_scores
      max_scores = data.max_scores
      most_similar_role = data.most_similar_role
      feedback_list = data.feedback_list
      selectedRoles = propRoles
      type = propType

      console.log('Received from username API:', data)
    } else {
      throw new Error('No assessment ID or assessment data provided')
    }

    // Store max scores for chart
    maxScores.value = max_scores || []

    // Create feedback map for quick lookup
    const feedbackMap = {}
    if (feedback_list && feedback_list.length > 0) {
      feedback_list.forEach(areaFeedback => {
        if (areaFeedback.feedbacks) {
          areaFeedback.feedbacks.forEach(fb => {
            feedbackMap[fb.competency_name] = {
              strengths: fb.user_strengths,
              improvements: fb.improvement_areas
            }
          })
        }
      })
    }

    // Helper function to map database survey levels to display levels
    // Database stores: 0, 1, 2, 3, 4
    // Display needs: 0, 1, 2, 4, 6
    const mapDatabaseLevelToDisplay = (dbLevel) => {
      const mapping = {
        0: 0,  // Not familiar
        1: 1,  // Aware
        2: 2,  // Understanding
        3: 4,  // Applying
        4: 6   // Mastering
      }
      return mapping[dbLevel] ?? dbLevel
    }

    // Map backend data to component format
    competencyData.value = user_scores.map(score => {
      // Find the required score for this competency
      const maxScoreEntry = max_scores.find(ms => ms.competency_id === score.competency_id)
      const rawRequiredScore = maxScoreEntry?.max_score ?? 6

      // Handle both database level values (0,1,2,3,4) and display score values (0,1,2,4,6)
      // Some old assessments may have database levels, newer ones have display scores
      const requiredScore = (rawRequiredScore === 3) ? 4 : rawRequiredScore

      // Calculate percentage based on required level (can exceed 100%)
      // Special case: If required=0 (not required), show 100% to avoid division by zero
      const percentage = requiredScore === 0 ? 100 : Math.round((score.score / requiredScore) * 100)

      // Determine if user meets, exceeds, or is below required level
      // Special case: If required=0 (not required), always show as 'met' with neutral feedback
      let status = 'below'
      if (requiredScore === 0) {
        status = 'met' // Competency not required for this role
      } else if (score.score >= requiredScore) {
        status = score.score > requiredScore ? 'exceeded' : 'met'
      }

      let scoreText = 'Not assessed'

      // Get LLM-generated feedback from backend or fallback to basic text
      const feedback = feedbackMap[score.competency_name] || {}
      const strengths = feedback.strengths || ''

      // Only show improvement areas if below required level
      let improvements = ''
      if (status === 'below' && feedback.improvements && feedback.improvements !== 'N/A') {
        improvements = feedback.improvements
      } else if (status === 'met') {
        improvements = 'You have met your target competency level for this role.'
      } else if (status === 'exceeded') {
        improvements = 'You have exceeded your target competency level for this role. Excellent work!'
      }

      // Map Derik's levels to descriptive text
      switch (score.score) {
        case 0:
          scoreText = 'Not familiar'
          break
        case 1:
          scoreText = 'Aware'
          break
        case 2:
          scoreText = 'Understanding'
          break
        case 4:
          scoreText = 'Applying'
          break
        case 6:
          scoreText = 'Mastering'
          break
        default:
          scoreText = `Level ${score.score}`
      }

      // Map required score to descriptive text
      // Handle both database levels (3) and display scores (4) for "Applying"
      let requiredText = 'Not specified'
      switch (requiredScore) {
        case 0:
          requiredText = 'Not Required'
          break
        case 1:
          requiredText = 'Aware'
          break
        case 2:
          requiredText = 'Understanding'
          break
        case 3:  // Database level for Applying (legacy data)
        case 4:  // Display score for Applying
          requiredText = 'Applying'
          break
        case 6:
          requiredText = 'Mastering'
          break
        default:
          requiredText = `Level ${requiredScore}`
      }

      return {
        id: score.competency_id,
        name: score.competency_name,  // From database
        area: score.competency_area,   // From database
        score: score.score,
        percentage: percentage,
        scoreText: scoreText,
        requiredScore: requiredScore,
        requiredText: requiredText,
        status: status,
        strengths: strengths,
        improvements: improvements
      }
    })

    // Use most similar role from backend or selected roles
    if (most_similar_role && most_similar_role.length > 0) {
      recommendedRole.value = {
        name: most_similar_role[0].role_cluster_name,
        matchScore: 0.85
      }
    } else if (selectedRoles && selectedRoles.length > 0) {
      recommendedRole.value = {
        name: selectedRoles[0].name,
        matchScore: 0.85
      }
    }

    // Select all areas by default
    selectedAreas.value = [...uniqueAreas.value]

    // Generate initial chart data
    updateChartData()

  } catch (error) {
    console.error('Error fetching assessment results:', error)
    ElMessage.error('Failed to load assessment results from server')
  } finally {
    loading.value = false
  }
}

const updateChartData = () => {
  if (filteredCompetencyData.value.length === 0) {
    chartData.value = null
    return
  }

  const labels = filteredCompetencyData.value.map(comp => comp.name)
  const userData = filteredCompetencyData.value.map(comp => comp.score)

  // Get required scores from backend data (matching Derik's implementation)
  const requiredData = filteredCompetencyData.value.map(comp => {
    const maxScore = maxScores.value.find(ms => ms.competency_id === comp.id)
    // Use nullish coalescing (??) to handle 0 as a valid value
    return maxScore?.max_score ?? 6
  })

  chartData.value = {
    labels: labels,
    datasets: [
      {
        label: 'User Score',  // ✅ Match Derik's label
        backgroundColor: 'rgba(103, 194, 58, 0.2)',
        borderColor: 'rgba(103, 194, 58, 1)',
        pointBackgroundColor: 'rgba(103, 194, 58, 1)',
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
        data: userData
      },
      {
        label: 'Required Score',  // ✅ Match Derik's label
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
        borderColor: 'rgba(255, 99, 132, 1)',
        pointBackgroundColor: 'rgba(255, 99, 132, 1)',
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
        data: requiredData  // ✅ Real required scores from role matrix
      }
    ]
  }
}

const toggleAreaSelection = (area) => {
  const index = selectedAreas.value.indexOf(area)
  if (index === -1) {
    selectedAreas.value.push(area)
  } else {
    selectedAreas.value.splice(index, 1)
  }
  // Update chart data when areas are toggled
  updateChartData()
}

const getScoreType = (score) => {
  if (score >= 5) return 'success'
  if (score >= 3) return 'warning'
  return 'danger'
}

const getAreaScoreType = (score) => {
  if (score >= 70) return 'success'
  if (score >= 50) return 'warning'
  return 'danger'
}

const getProgressColor = (percentage) => {
  if (percentage >= 100) return '#67c23a'  // Green for meeting/exceeding requirements
  if (percentage >= 80) return '#95d475'   // Light green for close to meeting
  if (percentage >= 60) return '#e6a23c'   // Orange for moderate progress
  if (percentage >= 40) return '#f89c53'   // Light orange for some progress
  return '#f56c6c'                         // Red for significant gap
}

const getScoreDescription = (score) => {
  if (score >= 100) return 'Exceeding role requirements'
  if (score >= 90) return 'Meeting role requirements'
  if (score >= 80) return 'Very close to role requirements'
  if (score >= 70) return 'Good progress toward requirements'
  if (score >= 60) return 'Moderate progress toward requirements'
  if (score >= 50) return 'Some progress toward requirements'
  return 'Significant development needed'
}

const exportResults = () => {
  ElMessage.info('PDF export functionality coming soon!')
}

const proceedToNextStep = () => {
  emit('continue', {
    competencyResults: competencyData.value,
    overallScore: overallScore.value,
    recommendedRole: recommendedRole.value,
    selectedAreas: selectedAreas.value
  })
}

// Lifecycle
onMounted(() => {
  processAssessmentData()
})
</script>

<style scoped>
.competency-results {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.loading-container {
  min-height: 300px;
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.progress-messages {
  margin-top: 20px;
  text-align: center;
}

.loading-message {
  font-size: 1.1rem;
  color: #409eff;
  margin-bottom: 10px;
}

.results-header {
  text-align: center;
  margin-bottom: 30px;
}

.results-title {
  font-size: 2rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
}

.results-subtitle {
  color: #6c7b7f;
  font-size: 1.1rem;
}

.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.summary-card {
  border-radius: 12px;
  overflow: hidden;
}

.summary-item {
  display: flex;
  align-items: center;
  padding: 10px;
}

.summary-icon {
  margin-right: 20px;
}

.summary-content h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.1rem;
}

.summary-value {
  font-size: 1.8rem;
  font-weight: 600;
  color: #409eff;
  margin: 0;
}

.summary-desc {
  color: #6c7b7f;
  margin: 4px 0 0 0;
  font-size: 0.9rem;
}

.chart-section {
  margin-bottom: 30px;
}

.chart-header {
  text-align: center;
}

.chart-header h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
}

.chart-header p {
  color: #6c7b7f;
  margin: 0;
}

.area-selection {
  margin: 20px 0;
}

.area-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: center;
}

.area-chip {
  cursor: pointer;
  transition: all 0.3s ease;
}

.area-chip:hover {
  transform: translateY(-2px);
}

.chart-container {
  margin: 30px 0;
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.radar-chart {
  width: 100%;
  height: 400px;
  position: relative;
}

.chart-placeholder {
  text-align: center;
  color: #c0c4cc;
}

.chart-placeholder p {
  margin: 10px 0 0 0;
  font-size: 1.1rem;
}

.chart-note {
  font-size: 0.9rem !important;
  color: #909399 !important;
}

.competency-details {
  margin-bottom: 30px;
}

.area-section {
  margin-bottom: 30px;
}

.area-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 2px solid #f0f0f0;
}

.area-title {
  margin: 0;
  color: #2c3e50;
  font-size: 1.3rem;
}

.competencies-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
}

.competency-item {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  border-left: 4px solid #409eff;
}

.competency-header {
  margin-bottom: 15px;
}

.competency-name {
  margin: 0;
  color: #2c3e50;
  font-size: 1.1rem;
  font-weight: 600;
}

.competency-levels {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 15px;
  padding: 12px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.level-info {
  display: flex;
  align-items: center;
  gap: 6px;
}

.level-label {
  font-size: 0.85rem;
  color: #606266;
  font-weight: 500;
}

.level-value {
  font-size: 0.9rem;
  font-weight: 600;
}

.current-level {
  color: #409eff;
}

.required-level {
  color: #e6a23c;
}

.competency-progress {
  margin-bottom: 8px;
}

.progress-label {
  margin-top: 6px;
  font-size: 0.85rem;
  color: #606266;
  text-align: center;
}

.exceeded-note {
  color: #67c23a;
  font-weight: 600;
}

.competency-feedback {
  margin-top: 15px;
}

.feedback-section {
  margin-bottom: 10px;
}

.feedback-label {
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 4px 0;
  font-size: 0.9rem;
}

.feedback-text {
  color: #6c7b7f;
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.4;
}

.actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 30px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

@media (max-width: 768px) {
  .summary-cards {
    grid-template-columns: 1fr;
  }

  .competencies-grid {
    grid-template-columns: 1fr;
  }

  .actions {
    flex-direction: column;
    gap: 15px;
  }

  .area-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
}
</style>