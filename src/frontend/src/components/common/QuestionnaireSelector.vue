<template>
  <div class="questionnaire-selector">
    <div class="selector-header">
      <h2>Available Assessments</h2>
      <p>Choose a questionnaire to begin your assessment journey</p>
    </div>

    <!-- Phase Filter -->
    <div class="filter-section">
      <el-select
        v-model="selectedPhase"
        placeholder="Filter by Phase"
        clearable
        @change="filterQuestionnaires"
      >
        <el-option label="All Phases" value="" />
        <el-option label="Phase 1: Analysis" value="phase1" />
        <el-option label="Phase 2: Requirements" value="phase2" />
        <el-option label="Phase 3: Pre-Concept" value="phase3" />
        <el-option label="Phase 4: Concept" value="phase4" />
      </el-select>

      <el-select
        v-model="selectedType"
        placeholder="Filter by Type"
        clearable
        @change="filterQuestionnaires"
      >
        <el-option label="All Types" value="" />
        <el-option label="Maturity Assessment" value="maturity_assessment" />
        <el-option label="Competency Assessment" value="competency_assessment" />
        <el-option label="Context Analysis" value="context_analysis" />
        <el-option label="Role Mapping" value="role_mapping" />
      </el-select>
    </div>

    <!-- Questionnaire Cards -->
    <div class="questionnaires-grid" v-loading="loading">
      <el-card
        v-for="questionnaire in filteredQuestionnaires"
        :key="questionnaire.id"
        class="questionnaire-card"
        :class="{ 'completed': isCompleted(questionnaire.id) }"
        shadow="hover"
      >
        <!-- Card Header -->
        <template #header>
          <div class="card-header">
            <h3>{{ questionnaire.title }}</h3>
            <div class="badges">
              <el-tag :type="getPhaseTagType(questionnaire.phase)">
                {{ getPhaseLabel(questionnaire.phase) }}
              </el-tag>
              <el-tag
                v-if="isCompleted(questionnaire.id)"
                type="success"
                effect="plain"
              >
                Completed
              </el-tag>
            </div>
          </div>
        </template>

        <!-- Card Content -->
        <div class="card-content">
          <p class="description">{{ questionnaire.description }}</p>

          <div class="questionnaire-info">
            <div class="info-item">
              <el-icon><Edit /></el-icon>
              <span>{{ questionnaire.estimated_duration_minutes || 'N/A' }} minutes</span>
            </div>
            <div class="info-item">
              <el-icon><Plus /></el-icon>
              <span>{{ questionnaire.question_count }} questions</span>
            </div>
            <div class="info-item">
              <el-icon><Check /></el-icon>
              <span>{{ getTypeLabel(questionnaire.questionnaire_type) }}</span>
            </div>
          </div>

          <!-- Prerequisites -->
          <div v-if="getPrerequisites(questionnaire.id).length > 0" class="prerequisites">
            <h4>Prerequisites:</h4>
            <ul>
              <li
                v-for="prereq in getPrerequisites(questionnaire.id)"
                :key="prereq.id"
                :class="{ 'completed': isCompleted(prereq.id) }"
              >
                {{ prereq.title }}
                <el-icon v-if="isCompleted(prereq.id)" class="check-icon"><Check /></el-icon>
              </li>
            </ul>
          </div>
        </div>

        <!-- Card Actions -->
        <template #footer>
          <div class="card-actions">
            <el-button
              v-if="isCompleted(questionnaire.id)"
              type="info"
              @click="viewResults(questionnaire.id)"
              icon="Check"
            >
              View Results
            </el-button>
            <el-button
              v-else
              type="primary"
              @click="startQuestionnaire(questionnaire)"
              :disabled="!canStart(questionnaire.id)"
              icon="Plus"
            >
              {{ hasInProgress(questionnaire.id) ? 'Continue' : 'Start' }}
            </el-button>
            <el-button
              @click="viewDetails(questionnaire)"
              icon="Edit"
            >
              Details
            </el-button>
          </div>
        </template>
      </el-card>
    </div>

    <!-- Empty State -->
    <el-empty
      v-if="!loading && filteredQuestionnaires.length === 0"
      description="No questionnaires found"
    >
      <el-button type="primary" @click="resetFilters">Reset Filters</el-button>
    </el-empty>

    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="3" animated />
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
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Check, Plus, Edit } from '@element-plus/icons-vue'
import { assessmentApi } from '@/api/assessment'

const emit = defineEmits(['questionnaire-selected', 'view-results', 'view-details'])

// Reactive data
const questionnaires = ref([])
const userResponses = ref([])
const selectedPhase = ref('')
const selectedType = ref('')
const loading = ref(false)
const error = ref('')

// Computed properties
const filteredQuestionnaires = computed(() => {
  return questionnaires.value.filter(q => {
    const phaseMatch = !selectedPhase.value || q.phase === selectedPhase.value
    const typeMatch = !selectedType.value || q.questionnaire_type === selectedType.value
    return phaseMatch && typeMatch
  })
})

// Methods
const loadQuestionnaires = async () => {
  try {
    loading.value = true
    const [questionnairesRes, responsesRes] = await Promise.all([
      assessmentApi.getQuestionnaires(),
      assessmentApi.getUserResponses(getCurrentUserId())
    ])

    questionnaires.value = questionnairesRes.data.questionnaires
    userResponses.value = responsesRes.data.responses || []
  } catch (err) {
    error.value = 'Failed to load questionnaires'
    ElMessage.error('Failed to load questionnaires')
  } finally {
    loading.value = false
  }
}

const getCurrentUserId = () => {
  // Get user ID from store or token
  // This is a placeholder - implement according to your auth system
  return 1
}

const isCompleted = (questionnaireId) => {
  return userResponses.value.some(
    response => response.questionnaire_id === questionnaireId && response.status === 'completed'
  )
}

const hasInProgress = (questionnaireId) => {
  return userResponses.value.some(
    response => response.questionnaire_id === questionnaireId && response.status === 'in_progress'
  )
}

const getPrerequisites = (questionnaireId) => {
  // Define prerequisite mapping based on SE-QPT workflow
  const prerequisites = {
    2: [1], // Competency assessment requires maturity assessment
    3: [1, 2], // Context analysis requires previous phases
    4: [1, 2, 3] // Role mapping requires all previous
  }

  const prereqIds = prerequisites[questionnaireId] || []
  return questionnaires.value.filter(q => prereqIds.includes(q.id))
}

const canStart = (questionnaireId) => {
  const prerequisites = getPrerequisites(questionnaireId)
  return prerequisites.every(prereq => isCompleted(prereq.id))
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

const getPhaseTagType = (phase) => {
  const types = {
    'phase1': 'primary',
    'phase2': 'success',
    'phase3': 'warning',
    'phase4': 'danger'
  }
  return types[phase] || 'info'
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

const filterQuestionnaires = () => {
  // Filtering is handled by computed property
}

const resetFilters = () => {
  selectedPhase.value = ''
  selectedType.value = ''
}

const startQuestionnaire = (questionnaire) => {
  emit('questionnaire-selected', questionnaire)
}

const viewResults = (questionnaireId) => {
  emit('view-results', questionnaireId)
}

const viewDetails = (questionnaire) => {
  emit('view-details', questionnaire)
}

// Lifecycle
onMounted(() => {
  loadQuestionnaires()
})
</script>

<style scoped>
.questionnaire-selector {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.selector-header {
  text-align: center;
  margin-bottom: 32px;
}

.selector-header h2 {
  color: #303133;
  margin-bottom: 12px;
  font-size: 28px;
}

.selector-header p {
  color: #606266;
  font-size: 16px;
  margin-bottom: 0;
}

.filter-section {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  justify-content: center;
  flex-wrap: wrap;
}

.questionnaires-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
}

.questionnaire-card {
  transition: all 0.3s ease;
  border: 2px solid transparent;
}

.questionnaire-card:hover {
  border-color: #409eff;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.questionnaire-card.completed {
  background-color: #f0f9ff;
  border-color: #67c23a;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.card-header h3 {
  margin: 0;
  color: #303133;
  font-size: 18px;
}

.badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.card-content {
  min-height: 200px;
}

.description {
  color: #606266;
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 20px;
}

.questionnaire-info {
  margin-bottom: 20px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  color: #606266;
  font-size: 14px;
}

.prerequisites {
  margin-top: 16px;
}

.prerequisites h4 {
  color: #303133;
  font-size: 14px;
  margin-bottom: 8px;
}

.prerequisites ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.prerequisites li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 0;
  color: #909399;
  font-size: 13px;
}

.prerequisites li.completed {
  color: #67c23a;
}

.check-icon {
  color: #67c23a;
  font-size: 16px;
}

.card-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.loading-container {
  padding: 40px;
}

@media (max-width: 768px) {
  .questionnaire-selector {
    padding: 16px;
  }

  .questionnaires-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .filter-section {
    flex-direction: column;
  }

  .card-actions {
    flex-direction: column;
  }
}
</style>