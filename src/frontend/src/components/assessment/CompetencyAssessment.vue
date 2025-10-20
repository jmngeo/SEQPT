<template>
  <div class="competency-assessment">
    <div class="assessment-header">
      <h3>{{ questionnaire.role?.name }} - Competency Assessment</h3>
      <p>Rate your current competency level for each indicator. This assessment will help identify your strengths and development areas.</p>

      <div class="progress-info">
        <el-progress
          :percentage="progressPercentage"
          :color="progressColor"
          :stroke-width="8"
        />
        <span class="progress-text">
          {{ answeredQuestions }} / {{ totalQuestions }} completed
        </span>
      </div>
    </div>

    <div class="assessment-content" v-loading="loading">
      <div v-if="questionnaire.competencies && questionnaire.competencies.length > 0">
        <div
          v-for="(competency, compIndex) in questionnaire.competencies"
          :key="competency.id"
          class="competency-section"
        >
          <div class="competency-header">
            <h4>{{ competency.name }}</h4>
            <el-tag :type="getCategoryType(competency.category)" size="small">
              {{ competency.category }}
            </el-tag>
          </div>

          <p class="competency-description">{{ competency.description }}</p>

          <div class="indicators-container">
            <div
              v-for="(indicator, indIndex) in competency.indicators"
              :key="`${competency.code}_${indIndex}`"
              class="indicator-item"
            >
              <div class="indicator-question">
                <h5>{{ indicator }}</h5>
                <p class="rating-instruction">Rate your current ability level:</p>
              </div>

              <div class="rating-scale">
                <el-radio-group
                  v-model="responses[competency.code][`indicator_${indIndex}`]"
                  @change="updateProgress"
                  size="large"
                >
                  <el-radio-button
                    v-for="(label, value) in questionnaire.scale"
                    :key="value"
                    :value="parseInt(value)"
                    :label="parseInt(value)"
                  >
                    <div class="rating-option">
                      <span class="rating-number">{{ value }}</span>
                      <span class="rating-label">{{ label.split(' - ')[0] }}</span>
                    </div>
                  </el-radio-button>
                </el-radio-group>
              </div>

              <div class="rating-descriptions">
                <div
                  v-for="(label, value) in questionnaire.scale"
                  :key="`desc_${value}`"
                  class="rating-description"
                >
                  <strong>{{ value }}:</strong> {{ label }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="no-data">
        <el-empty description="No competency assessment available" />
      </div>
    </div>

    <div class="assessment-actions" v-if="questionnaire.competencies?.length > 0">
      <el-button @click="$emit('back')" size="large">
        Previous
      </el-button>

      <el-button
        type="primary"
        @click="submitAssessment"
        :disabled="!canSubmit"
        :loading="submitting"
        size="large"
      >
        {{ submitting ? 'Submitting...' : 'Complete Assessment' }}
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'

// Props
const props = defineProps({
  assessmentId: {
    type: Number,
    required: true
  },
  selectedRole: {
    type: Object,
    default: () => ({})
  }
})

// Emits
const emit = defineEmits(['completed', 'back'])

// Reactive state
const loading = ref(false)
const submitting = ref(false)
const questionnaire = ref({})
const responses = reactive({})
const startTime = ref(null)

// Computed properties
const totalQuestions = computed(() => {
  if (!questionnaire.value.competencies) return 0
  return questionnaire.value.competencies.reduce((total, comp) => total + comp.indicators.length, 0)
})

const answeredQuestions = computed(() => {
  let count = 0
  Object.keys(responses).forEach(competencyCode => {
    Object.values(responses[competencyCode]).forEach(response => {
      if (response !== null && response !== undefined) count++
    })
  })
  return count
})

const progressPercentage = computed(() => {
  if (totalQuestions.value === 0) return 0
  return Math.round((answeredQuestions.value / totalQuestions.value) * 100)
})

const progressColor = computed(() => {
  const percentage = progressPercentage.value
  if (percentage < 25) return '#F56C6C'
  if (percentage < 50) return '#E6A23C'
  if (percentage < 75) return '#409EFF'
  return '#67C23A'
})

const canSubmit = computed(() => {
  return answeredQuestions.value === totalQuestions.value
})

// Methods
const getCategoryType = (category) => {
  const typeMap = {
    'Core': 'danger',
    'Technical': 'primary',
    'Management': 'warning',
    'Professional': 'success'
  }
  return typeMap[category] || 'info'
}

const initializeResponses = () => {
  if (!questionnaire.value.competencies) return

  questionnaire.value.competencies.forEach(competency => {
    responses[competency.code] = {}
    competency.indicators.forEach((indicator, index) => {
      responses[competency.code][`indicator_${index}`] = null
    })
  })
}

const loadQuestionnaire = async () => {
  if (!props.assessmentId) return

  try {
    loading.value = true
    const response = await fetch(`/api/competency/assessment/${props.assessmentId}/competency-questionnaire`, {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    questionnaire.value = data
    initializeResponses()
    startTime.value = new Date()

  } catch (error) {
    console.error('Failed to load competency questionnaire:', error)
    ElMessage.error('Failed to load competency assessment')
  } finally {
    loading.value = false
  }
}

const updateProgress = () => {
  // Progress is automatically updated via computed property
}

const submitAssessment = async () => {
  if (!canSubmit.value) {
    ElMessage.warning('Please complete all competency ratings before submitting')
    return
  }

  try {
    submitting.value = true

    const completionTime = startTime.value ? Math.round((new Date() - startTime.value) / 1000 / 60) : 0

    const response = await fetch(`/api/competency/assessment/${props.assessmentId}/submit-responses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify({
        responses: responses,
        completion_time: completionTime
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const result = await response.json()

    ElMessage.success('Competency assessment completed successfully!')

    // Emit completion event with results
    emit('completed', {
      assessmentId: props.assessmentId,
      results: result.results,
      responses: responses,
      questionnaire: questionnaire.value
    })

  } catch (error) {
    console.error('Failed to submit competency assessment:', error)
    ElMessage.error('Failed to submit assessment. Please try again.')
  } finally {
    submitting.value = false
  }
}

// Watchers
watch(() => props.assessmentId, (newId) => {
  if (newId) {
    loadQuestionnaire()
  }
})

// Lifecycle
onMounted(() => {
  if (props.assessmentId) {
    loadQuestionnaire()
  }
})
</script>

<style scoped>
.competency-assessment {
  max-width: 1000px;
  margin: 0 auto;
}

.assessment-header {
  text-align: center;
  margin-bottom: 2rem;
}

.assessment-header h3 {
  color: #303133;
  margin-bottom: 0.5rem;
}

.assessment-header p {
  color: #606266;
  margin-bottom: 1.5rem;
}

.progress-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.progress-text {
  font-size: 14px;
  color: #909399;
}

.competency-section {
  background: #fff;
  border: 1px solid #EBEEF5;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.competency-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.competency-header h4 {
  margin: 0;
  color: #303133;
}

.competency-description {
  color: #606266;
  font-style: italic;
  margin-bottom: 1.5rem;
}

.indicators-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.indicator-item {
  border-left: 3px solid #409EFF;
  padding-left: 1rem;
  background: #F8F9FA;
  border-radius: 4px;
  padding: 1rem;
}

.indicator-question h5 {
  margin: 0 0 0.5rem 0;
  color: #303133;
  font-size: 16px;
}

.rating-instruction {
  color: #606266;
  font-size: 14px;
  margin: 0 0 1rem 0;
}

.rating-scale {
  margin-bottom: 1rem;
}

.rating-scale .el-radio-group {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.rating-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0.5rem;
}

.rating-number {
  font-weight: bold;
  font-size: 18px;
}

.rating-label {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.rating-descriptions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.5rem;
  font-size: 12px;
  color: #606266;
  background: #F5F7FA;
  padding: 1rem;
  border-radius: 4px;
  margin-top: 1rem;
}

.rating-description {
  padding: 0.25rem;
}

.assessment-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
  padding: 1.5rem;
  background: #F8F9FA;
  border-radius: 8px;
}

.no-data {
  text-align: center;
  padding: 3rem;
}

@media (max-width: 768px) {
  .rating-descriptions {
    grid-template-columns: 1fr;
  }

  .assessment-actions {
    flex-direction: column;
    gap: 1rem;
  }

  .competency-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style>