<template>
  <div class="questionnaire-component">
    <!-- Header -->
    <div class="questionnaire-header">
      <h2>{{ questionnaire?.title || 'Loading...' }}</h2>
      <p class="description">{{ questionnaire?.description }}</p>

      <div class="progress-section" v-if="questionnaire">
        <div class="progress-info">
          <span>Progress: {{ Math.round(progress) }}%</span>
          <span>Question {{ currentQuestionIndex + 1 }} of {{ questionnaire.questions.length }}</span>
        </div>
        <el-progress
          :percentage="progress"
          :stroke-width="8"
          :show-text="false"
        />
      </div>
    </div>

    <!-- Question Content -->
    <div class="question-container" v-if="currentQuestion">
      <el-card class="question-card">
        <div class="question-header">
          <span class="question-number">Q{{ currentQuestion.question_number }}</span>
          <span class="section-badge" v-if="currentQuestion.section">
            {{ currentQuestion.section }}
          </span>
          <span class="required-badge" v-if="currentQuestion.is_required">Required</span>
        </div>

        <div class="question-content">
          <h3 class="question-text">{{ currentQuestion.question_text }}</h3>
          <p class="help-text" v-if="currentQuestion.help_text">
            {{ currentQuestion.help_text }}
          </p>
        </div>

        <!-- Answer Options -->
        <div class="answer-section">
          <!-- Multiple Choice / Single Choice -->
          <el-radio-group
            v-if="currentQuestion.question_type === 'multiple_choice' || currentQuestion.question_type === 'single_choice'"
            v-model="currentAnswer"
            class="answer-options"
            @change="handleAnswerChange"
          >
            <el-radio
              v-for="option in currentQuestion.options"
              :key="option.id"
              :value="option.option_value"
              class="answer-option"
            >
              <span class="option-text">{{ option.option_text }}</span>
              <span class="option-score" v-if="showScores">({{ option.score_value }} pts)</span>
            </el-radio>
          </el-radio-group>

          <!-- Scale -->
          <div v-else-if="currentQuestion.question_type === 'scale'" class="scale-answer">
            <el-slider
              v-model="currentAnswer"
              :min="1"
              :max="6"
              :step="1"
              :marks="scaleMarks"
              show-stops
              @change="handleAnswerChange"
            />
            <div class="scale-labels">
              <span>Novice (1)</span>
              <span>Master/Teacher (6)</span>
            </div>
          </div>

          <!-- Text -->
          <el-input
            v-else-if="currentQuestion.question_type === 'text'"
            v-model="currentTextAnswer"
            type="textarea"
            :rows="4"
            placeholder="Please provide your answer..."
            @input="handleTextAnswerChange"
          />
        </div>

        <!-- Question Navigation -->
        <div class="navigation-buttons">
          <el-button
            @click="previousQuestion"
            :disabled="currentQuestionIndex === 0"
            icon="ArrowLeft"
          >
            Previous
          </el-button>

          <el-button
            type="primary"
            @click="nextQuestion"
            :disabled="!canProceed || completed"
            :loading="saving"
            icon="ArrowRight"
          >
            {{ completed ? 'Completed' : (isLastQuestion ? 'Complete' : 'Next') }}
          </el-button>
        </div>
      </el-card>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="loading-container">
      <el-skeleton :rows="8" animated />
    </div>

    <!-- Error State -->
    <el-alert
      v-if="error"
      :title="error"
      type="error"
      show-icon
      :closable="false"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, ArrowRight } from '@element-plus/icons-vue'
import { assessmentApi } from '@/api/assessment'

const props = defineProps({
  questionnaireId: {
    type: Number,
    required: true
  },
  showScores: {
    type: Boolean,
    default: false
  },
  maturityResponses: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['completed', 'error'])

// Reactive data
const questionnaire = ref(null)
const questionnaireResponse = ref(null)
const currentQuestionIndex = ref(0)
const answers = ref({})
const textAnswers = ref({})
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const completed = ref(false)

// Computed properties
const currentQuestion = computed(() => {
  if (!questionnaire.value || currentQuestionIndex.value >= questionnaire.value.questions.length) {
    return null
  }
  return questionnaire.value.questions[currentQuestionIndex.value]
})

const currentAnswer = computed({
  get() {
    // CRITICAL: Don't use || null because 0 is a valid answer but falsy
    // This was causing the first option (value: 0) to appear unselected
    const value = answers.value[currentQuestion.value?.id]
    return value !== undefined ? value : null
  },
  set(value) {
    if (currentQuestion.value) {
      answers.value[currentQuestion.value.id] = value
    }
  }
})

const currentTextAnswer = computed({
  get() {
    return textAnswers.value[currentQuestion.value?.id] || ''
  },
  set(value) {
    if (currentQuestion.value) {
      textAnswers.value[currentQuestion.value.id] = value
    }
  }
})

const progress = computed(() => {
  if (!questionnaire.value) return 0
  // Calculate progress based on answered questions, not current question index
  const totalQuestions = questionnaire.value.questions.length
  const answeredQuestions = Object.keys(answers.value).length + Object.keys(textAnswers.value).length
  return (answeredQuestions / totalQuestions) * 100
})

const isLastQuestion = computed(() => {
  return currentQuestionIndex.value === questionnaire.value?.questions.length - 1
})

const canProceed = computed(() => {
  if (!currentQuestion.value) return false

  if (currentQuestion.value.is_required) {
    if (currentQuestion.value.question_type === 'text') {
      return currentTextAnswer.value.trim().length > 0
    } else {
      return currentAnswer.value !== null && currentAnswer.value !== undefined
    }
  }

  return true
})

const scaleMarks = computed(() => ({
  1: 'Novice',
  2: 'Adv. Beginner',
  3: 'Competent',
  4: 'Proficient',
  5: 'Expert',
  6: 'Master'
}))

// Methods
const loadQuestionnaire = async () => {
  try {
    loading.value = true

    // For archetype selection (questionnaire 2), pass MAT_04 to filter questions
    const params = {}
    if (props.questionnaireId === 2 && props.maturityResponses?.MAT_04 !== undefined) {
      params.mat_04 = props.maturityResponses.MAT_04
      console.log('[QUESTIONNAIRE COMPONENT] Loading with MAT_04:', params.mat_04)
    }

    const response = await assessmentApi.getQuestionnaire(props.questionnaireId, params)
    questionnaire.value = response.data // API returns questionnaire directly

    console.log('[QUESTIONNAIRE COMPONENT] Loaded', questionnaire.value.questions?.length, 'questions')
  } catch (err) {
    error.value = 'Failed to load questionnaire'
    emit('error', err)
  } finally {
    loading.value = false
  }
}

const startQuestionnaire = async () => {
  try {
    const response = await assessmentApi.startQuestionnaire(props.questionnaireId)
    questionnaireResponse.value = response.data.questionnaire_response
  } catch (err) {
    error.value = 'Failed to start questionnaire'
    emit('error', err)
  }
}

const handleAnswerChange = async () => {
  if (!questionnaireResponse.value || !currentQuestion.value) return

  try {
    saving.value = true
    const selectedOption = currentQuestion.value.options.find(
      option => option.option_value === currentAnswer.value
    )

    await assessmentApi.submitAnswer(questionnaireResponse.value.uuid, {
      questionId: currentQuestion.value.id,
      questionResponse: currentAnswer.value,
      scoreValue: selectedOption?.score_value || currentAnswer.value
    })
  } catch (err) {
    ElMessage.error('Failed to save answer')
  } finally {
    saving.value = false
  }
}

const handleTextAnswerChange = async () => {
  if (!questionnaireResponse.value || !currentQuestion.value) return

  try {
    saving.value = true
    await assessmentApi.submitAnswer(questionnaireResponse.value.uuid, {
      questionId: currentQuestion.value.id,
      textResponse: currentTextAnswer.value
    })
  } catch (err) {
    ElMessage.error('Failed to save answer')
  } finally {
    saving.value = false
  }
}

const nextQuestion = async () => {
  if (isLastQuestion.value) {
    await completeQuestionnaire()
  } else {
    currentQuestionIndex.value++
  }
}

const previousQuestion = () => {
  if (currentQuestionIndex.value > 0) {
    currentQuestionIndex.value--
  }
}

const completeQuestionnaire = async () => {
  try {
    const confirmed = await ElMessageBox.confirm(
      'Are you sure you want to complete this questionnaire? You cannot modify answers after completion.',
      'Complete Questionnaire',
      {
        confirmButtonText: 'Complete',
        cancelButtonText: 'Cancel',
        type: 'warning',
      }
    )

    if (confirmed) {
      saving.value = true
      await assessmentApi.completeQuestionnaire(questionnaireResponse.value.uuid)
      completed.value = true

      // Calculate total score using RMS (Root Mean Square) algorithm for maturity assessment
      let totalScore = 0

      // Check if this is the maturity assessment questionnaire
      if (props.questionnaireId === 1) {
        // Maturity Assessment: Use RMS algorithm from updated-se-qpt-questionnaires.md
        // Overall_Maturity = √[(F² + O² + P² + I²) / 4]

        // Define section mappings
        const sections = {
          fundamentals: ['MAT_01', 'MAT_02', 'MAT_03'],
          organization: ['MAT_04', 'MAT_05', 'MAT_06', 'MAT_07'],
          process_capability: ['MAT_08', 'MAT_09', 'MAT_10'],
          infrastructure: ['MAT_11', 'MAT_12']
        }

        // Calculate weighted average for each section
        const calculateSectionScore = (questionIds) => {
          let weightedSum = 0
          let totalWeight = 0

          questionIds.forEach(qId => {
            const question = questionnaire.value.questions.find(q => q.id === qId)
            if (question && answers.value[qId] !== undefined) {
              const value = answers.value[qId]
              const weight = question.weight || 1.0
              weightedSum += value * weight
              totalWeight += weight
            }
          })

          return totalWeight > 0 ? weightedSum / totalWeight : 0
        }

        const F = calculateSectionScore(sections.fundamentals)
        const O = calculateSectionScore(sections.organization)
        const P = calculateSectionScore(sections.process_capability)
        const I = calculateSectionScore(sections.infrastructure)

        // Root Mean Square: √[(F² + O² + P² + I²) / 4]
        totalScore = Math.sqrt((F * F + O * O + P * P + I * I) / 4)

        console.log('Maturity Scores:', { F, O, P, I, Overall: totalScore })
      } else {
        // For other questionnaires, use simple sum
        Object.keys(answers.value).forEach(questionId => {
          const question = questionnaire.value.questions.find(q => q.id === questionId)
          if (question) {
            const selectedOption = question.options.find(opt => opt.option_value === answers.value[questionId])
            if (selectedOption) {
              totalScore += selectedOption.score_value || 0
            }
          }
        })
      }

      // Build complete response with answers and score
      const completeResponse = {
        ...questionnaireResponse.value,
        responses: { ...answers.value, ...textAnswers.value },
        total_score: totalScore,
        completed_at: new Date().toISOString(),
        questionnaire_id: props.questionnaireId
      }

      ElMessage.success('Questionnaire completed successfully!')
      emit('completed', completeResponse)
    }
  } catch (err) {
    if (err !== 'cancel') {
      ElMessage.error('Failed to complete questionnaire')
    }
  } finally {
    saving.value = false
  }
}

// Lifecycle
onMounted(async () => {
  await loadQuestionnaire()
  await startQuestionnaire()
})
</script>

<style scoped>
.questionnaire-component {
  max-width: 800px;
  margin: 0 auto;
  padding: 24px;
}

.questionnaire-header {
  margin-bottom: 32px;
  text-align: center;
}

.questionnaire-header h2 {
  color: #303133;
  margin-bottom: 12px;
  font-size: 28px;
}

.description {
  color: #606266;
  font-size: 16px;
  margin-bottom: 24px;
  line-height: 1.6;
}

.progress-section {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.progress-info {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
  font-size: 14px;
  color: #606266;
}

.question-card {
  margin-bottom: 24px;
}

.question-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.question-number {
  background: #409eff;
  color: white;
  padding: 4px 12px;
  border-radius: 16px;
  font-weight: bold;
  font-size: 14px;
}

.section-badge {
  background: #f0f9ff;
  color: #1890ff;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 12px;
  border: 1px solid #d1ecf1;
}

.required-badge {
  background: #fef0f0;
  color: #f56c6c;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 12px;
  border: 1px solid #fde2e2;
}

.question-content {
  margin-bottom: 24px;
}

.question-text {
  color: #303133;
  font-size: 18px;
  margin-bottom: 8px;
  line-height: 1.6;
}

.help-text {
  color: #909399;
  font-size: 14px;
  font-style: italic;
  line-height: 1.5;
}

.answer-section {
  margin-bottom: 32px;
}

.answer-options {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: stretch;
}

.answer-option {
  padding: 20px;
  border: 2px solid #e4e7ed;
  border-radius: 12px;
  transition: all 0.3s ease;
  cursor: pointer;
  background-color: #ffffff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  min-height: 60px;
  display: flex;
  align-items: center;
  text-align: left;
  width: 100%;
}

.answer-option:hover {
  border-color: #409eff;
  background-color: #f0f9ff;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
}

.answer-option.is-checked {
  border-color: #409eff;
  background-color: #f0f9ff;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
}

.option-text {
  font-size: 16px;
  color: #303133;
  line-height: 1.6;
  word-wrap: break-word;
  word-break: break-word;
  hyphens: auto;
  flex: 1;
  text-align: left;
  max-width: 100%;
}

.option-score {
  color: #909399;
  font-size: 14px;
  margin-left: 12px;
  white-space: nowrap;
  align-self: flex-start;
  margin-top: 2px;
}

.scale-answer {
  padding: 24px;
  background: #f8f9fa;
  border-radius: 8px;
}

.scale-labels {
  display: flex;
  justify-content: space-between;
  margin-top: 16px;
  font-size: 14px;
  color: #606266;
}

.navigation-buttons {
  display: flex;
  justify-content: space-between;
  margin-top: 24px;
}

.loading-container {
  padding: 40px;
}

@media (max-width: 768px) {
  .questionnaire-component {
    padding: 16px;
  }

  .progress-info {
    flex-direction: column;
    gap: 8px;
    text-align: center;
  }

  .question-header {
    justify-content: center;
  }

  .navigation-buttons {
    flex-direction: column;
    gap: 12px;
  }

  .answer-option {
    padding: 16px;
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .option-text {
    font-size: 15px;
  }

  .option-score {
    margin-left: 0;
    margin-top: 0;
    align-self: flex-end;
  }
}
</style>