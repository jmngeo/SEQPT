<template>
  <div class="take-assessment">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><DocumentChecked /></el-icon> Take Assessment</h1>
        <p>Complete your competency assessment to generate personalized qualification plans</p>
      </div>
      <div class="header-actions">
        <el-button @click="goBack">
          <el-icon><ArrowLeft /></el-icon>
          Back to Assessments
        </el-button>
      </div>
    </div>

    <div class="assessment-container">
      <!-- Questionnaire Selection -->
      <QuestionnaireSelector
        v-if="!selectedQuestionnaire"
        @questionnaire-selected="handleQuestionnaireSelected"
        @view-results="handleViewResults"
        @view-details="handleViewDetails"
      />

      <!-- Active Questionnaire -->
      <QuestionnaireComponent
        v-else-if="selectedQuestionnaire"
        :questionnaire-id="selectedQuestionnaire.id"
        :show-scores="false"
        @completed="handleQuestionnaireCompleted"
        @error="handleQuestionnaireError"
      />

      <!-- Results View -->
      <div v-else-if="showResults" class="results-container">
        <el-card class="results-card">
          <template #header>
            <div class="results-header">
              <h2>Assessment Results</h2>
              <el-button @click="goBackToSelection" icon="ArrowLeft">
                Back to Selection
              </el-button>
            </div>
          </template>

          <div class="results-content">
            <el-result
              icon="success"
              title="Assessment Completed Successfully!"
              sub-title="Your responses have been recorded and analyzed."
            >
              <template #extra>
                <div class="results-actions">
                  <el-button type="primary" @click="viewDetailedResults">
                    View Detailed Results
                  </el-button>
                  <el-button @click="downloadReport">
                    Download Report
                  </el-button>
                  <el-button @click="viewRecommendations">
                    View Recommendations
                  </el-button>
                </div>
              </template>
            </el-result>

            <!-- Quick Results Preview -->
            <div v-if="completedResponse" class="quick-results">
              <h3>Quick Overview</h3>
              <div class="result-stats">
                <div class="stat-item">
                  <span class="stat-label">Completion Time:</span>
                  <span class="stat-value">{{ formatDuration(completedResponse.duration) }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">Questions Answered:</span>
                  <span class="stat-value">{{ completedResponse.total_questions }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">Status:</span>
                  <el-tag type="success">Completed</el-tag>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </div>
    </div>

    <!-- Details Dialog -->
    <el-dialog
      v-model="showDetailsDialog"
      title="Questionnaire Details"
      width="50%"
      :before-close="handleDetailsClose"
    >
      <div v-if="selectedQuestionnaireDetails" class="details-content">
        <h3>{{ selectedQuestionnaireDetails.title }}</h3>
        <p class="description">{{ selectedQuestionnaireDetails.description }}</p>

        <div class="details-info">
          <div class="info-row">
            <strong>Type:</strong>
            <span>{{ getTypeLabel(selectedQuestionnaireDetails.questionnaire_type) }}</span>
          </div>
          <div class="info-row">
            <strong>Phase:</strong>
            <span>{{ getPhaseLabel(selectedQuestionnaireDetails.phase) }}</span>
          </div>
          <div class="info-row">
            <strong>Estimated Duration:</strong>
            <span>{{ selectedQuestionnaireDetails.estimated_duration_minutes || 'N/A' }} minutes</span>
          </div>
          <div class="info-row">
            <strong>Number of Questions:</strong>
            <span>{{ selectedQuestionnaireDetails.question_count }}</span>
          </div>
        </div>

        <div class="sample-questions" v-if="selectedQuestionnaireDetails.questions">
          <h4>Sample Questions:</h4>
          <ul>
            <li
              v-for="(question, index) in selectedQuestionnaireDetails.questions.slice(0, 3)"
              :key="question.id"
            >
              <strong>Q{{ question.question_number }}:</strong> {{ question.question_text }}
            </li>
          </ul>
          <p v-if="selectedQuestionnaireDetails.questions.length > 3" class="more-questions">
            ... and {{ selectedQuestionnaireDetails.questions.length - 3 }} more questions
          </p>
        </div>
      </div>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showDetailsDialog = false">Close</el-button>
          <el-button
            type="primary"
            @click="startQuestionnaireFromDetails"
            v-if="selectedQuestionnaireDetails"
          >
            Start This Assessment
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { DocumentChecked, ArrowLeft } from '@element-plus/icons-vue'
import QuestionnaireSelector from '@/components/common/QuestionnaireSelector.vue'
import QuestionnaireComponent from '@/components/common/QuestionnaireComponent.vue'
import { assessmentApi } from '@/api/assessment'

const router = useRouter()
const route = useRoute()

// Reactive data
const selectedQuestionnaire = ref(null)
const selectedQuestionnaireDetails = ref(null)
const completedResponse = ref(null)
const showResults = ref(false)
const showDetailsDialog = ref(false)

// Methods
const handleQuestionnaireSelected = (questionnaire) => {
  selectedQuestionnaire.value = questionnaire
}

const handleQuestionnaireCompleted = (response) => {
  completedResponse.value = response
  selectedQuestionnaire.value = null
  showResults.value = true
  ElMessage.success('Assessment completed successfully!')
}

const handleQuestionnaireError = (error) => {
  ElMessage.error('Error during assessment: ' + error.message)
}

const handleViewResults = async (questionnaireId) => {
  try {
    // Implementation would fetch and display results
    ElMessage.info('Results viewing functionality to be implemented')
  } catch (error) {
    ElMessage.error('Failed to load results')
  }
}

const handleViewDetails = async (questionnaire) => {
  try {
    const response = await assessmentApi.getQuestionnaire(questionnaire.id)
    selectedQuestionnaireDetails.value = response.data.questionnaire
    showDetailsDialog.value = true
  } catch (error) {
    ElMessage.error('Failed to load questionnaire details')
  }
}

const handleDetailsClose = () => {
  showDetailsDialog.value = false
  selectedQuestionnaireDetails.value = null
}

const startQuestionnaireFromDetails = () => {
  selectedQuestionnaire.value = selectedQuestionnaireDetails.value
  showDetailsDialog.value = false
}

const goBack = () => {
  if (selectedQuestionnaire.value) {
    selectedQuestionnaire.value = null
  } else if (showResults.value) {
    showResults.value = false
  } else {
    router.push('/app/assessments')
  }
}

const goBackToSelection = () => {
  showResults.value = false
  selectedQuestionnaire.value = null
}

const viewDetailedResults = () => {
  if (completedResponse.value) {
    router.push(`/app/assessments/results/${completedResponse.value.uuid}`)
  }
}

const downloadReport = () => {
  ElMessage.info('Download functionality to be implemented')
}

const viewRecommendations = () => {
  router.push('/app/recommendations')
}

const getTypeLabel = (type) => {
  const labels = {
    'maturity_assessment': 'Maturity Assessment',
    'competency_assessment': 'Competency Assessment',
    'context_analysis': 'Context Analysis',
    'role_mapping': 'Role Mapping'
  }
  return labels[type] || type
}

const getPhaseLabel = (phase) => {
  const labels = {
    'phase1': 'Phase 1: Analysis',
    'phase2': 'Phase 2: Requirements',
    'phase3': 'Phase 3: Pre-Concept',
    'phase4': 'Phase 4: Concept'
  }
  return labels[phase] || phase
}

const formatDuration = (minutes) => {
  if (!minutes) return 'N/A'
  if (minutes < 60) return `${minutes} minutes`
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return `${hours}h ${mins}m`
}

// Check for direct questionnaire ID in route
onMounted(() => {
  if (route.params.questionnaireId) {
    const questionnaireId = parseInt(route.params.questionnaireId)
    selectedQuestionnaire.value = { id: questionnaireId }
  }
})
</script>

<style scoped>
.take-assessment {
  padding: 24px;
  background-color: #f5f7fa;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 24px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.header-content h1 {
  margin: 0;
  color: #303133;
  font-size: 28px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-content p {
  margin: 8px 0 0 0;
  color: #606266;
  font-size: 16px;
}

.assessment-container {
  max-width: 1200px;
  margin: 0 auto;
}

.results-container {
  margin-top: 24px;
}

.results-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.results-header h2 {
  margin: 0;
  color: #303133;
  font-size: 24px;
}

.results-content {
  padding: 24px 0;
}

.results-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: center;
  margin-top: 24px;
}

.quick-results {
  margin-top: 32px;
  padding: 24px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.quick-results h3 {
  color: #303133;
  margin-bottom: 16px;
  font-size: 18px;
}

.result-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.stat-label {
  color: #606266;
  font-size: 14px;
}

.stat-value {
  color: #303133;
  font-weight: 600;
}

.details-content {
  padding: 16px 0;
}

.details-content h3 {
  color: #303133;
  margin-bottom: 12px;
  font-size: 20px;
}

.description {
  color: #606266;
  font-size: 16px;
  line-height: 1.6;
  margin-bottom: 24px;
}

.details-info {
  margin-bottom: 24px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-row:last-child {
  border-bottom: none;
}

.info-row strong {
  color: #303133;
  font-size: 14px;
}

.info-row span {
  color: #606266;
  font-size: 14px;
}

.sample-questions {
  margin-top: 24px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.sample-questions h4 {
  color: #303133;
  margin-bottom: 12px;
  font-size: 16px;
}

.sample-questions ul {
  margin: 0;
  padding-left: 20px;
}

.sample-questions li {
  margin-bottom: 8px;
  color: #606266;
  font-size: 14px;
  line-height: 1.5;
}

.more-questions {
  margin-top: 12px;
  color: #909399;
  font-size: 13px;
  font-style: italic;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

@media (max-width: 768px) {
  .take-assessment {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    gap: 16px;
    text-align: center;
  }

  .results-header {
    flex-direction: column;
    gap: 16px;
    text-align: center;
  }

  .results-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .result-stats {
    grid-template-columns: 1fr;
  }

  .info-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }

  .dialog-footer {
    flex-direction: column;
  }
}
</style>