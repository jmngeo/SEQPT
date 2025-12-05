<template>
  <div class="phase2-task-flow">
    <!-- Phase 2 Header -->
    <div class="phase2-header">
      <h1>Phase 2: {{ headerTitle }}</h1>
      <p>{{ headerDescription }}</p>
    </div>

    <!-- Step Indicator (Dynamic based on pathway and user role) -->
    <div class="step-indicator">
      <el-steps :active="currentStepIndex" align-center finish-status="success">
        <el-step
          v-for="(step, index) in stepTitles"
          :key="index"
          :title="step.title"
          :description="step.description"
        />
      </el-steps>
    </div>

    <!-- Step Content -->
    <div class="step-content">
      <!-- Step 1a: Task Input (Task-Based Pathway) -->
      <DerikTaskSelector
        v-if="currentStep === 'task-input'"
        :organization-id="organizationId"
        :username="taskBasedUsername"
        @tasksAnalyzed="handleTasksAnalyzed"
      />

      <!-- Step 1b: Role Selection (Role-Based Pathway) -->
      <Phase2RoleSelection
        v-else-if="currentStep === 'role-selection'"
        :organization-id="organizationId"
        @next="handleRolesSelected"
        @back="handleBack"
      />

      <!-- Step 2: Necessary Competencies Display (Both Pathways) -->
      <Phase2NecessaryCompetencies
        v-else-if="currentStep === 'necessary-competencies'"
        :competencies="necessaryCompetencies"
        :selected-roles="selectedRoles"
        :organization-id="organizationId"
        :pathway="pathway"
        :username="taskBasedUsername"
        @next="handleStartAssessment"
        @back="handleBackToRoleSelection"
      />

      <!-- Step 3: Competency Assessment (Task 2) -->
      <Phase2CompetencyAssessment
        v-else-if="currentStep === 'assessment'"
        :assessment-id="assessmentId"
        :competencies="necessaryCompetencies"
        :organization-id="organizationId"
        @complete="handleAssessmentComplete"
        @back="handleBackToCompetencies"
      />

      <!-- Step 4: Assessment Results (with Radar Chart & LLM Feedback) -->
      <CompetencyResults
        v-else-if="currentStep === 'results'"
        :assessment-data="assessmentResults"
        @continue="handleContinue"
        @back="handleBackToAssessment"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { phase2Task2Api } from '@/api/phase2'
import { toast } from 'vue3-toastify'
import DerikTaskSelector from './DerikTaskSelector.vue'
import Phase2RoleSelection from './Phase2RoleSelection.vue'
import Phase2NecessaryCompetencies from './Phase2NecessaryCompetencies.vue'
import Phase2CompetencyAssessment from './Phase2CompetencyAssessment.vue'
import CompetencyResults from './CompetencyResults.vue' // Use existing component with radar chart & LLM feedback

const router = useRouter()

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  employeeName: {
    type: String,
    default: ''
  },
  maturityLevel: {
    type: Number,
    default: 5 // Default to role-based pathway
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()

// Check if user is admin
const isAdmin = computed(() => authStore.isAdmin)

// Maturity threshold constant (from RoleIdentification.vue line 146)
const MATURITY_THRESHOLD = 3

// Determine assessment pathway based on maturity level
const pathway = computed(() => {
  const isTaskBased = props.maturityLevel < MATURITY_THRESHOLD
  console.log('[Phase2 Flow] Maturity level:', props.maturityLevel, 'Pathway:', isTaskBased ? 'TASK_BASED' : 'ROLE_BASED')
  return isTaskBased ? 'TASK_BASED' : 'ROLE_BASED'
})

// Dynamic header based on user role
const headerTitle = computed(() => {
  if (isAdmin.value) {
    return 'Identify Competency Requirements'
  }
  return 'Competency Assessment'
})

const headerDescription = computed(() => {
  if (isAdmin.value) {
    return 'Assess competencies and generate learning objectives for your organization'
  }
  return 'Identify necessary competencies and assess current competency levels'
})

// State
const currentStep = ref(pathway.value === 'TASK_BASED' ? 'task-input' : 'role-selection')
const selectedRoles = ref([])
const necessaryCompetencies = ref([])
const assessmentId = ref(null)
const assessmentResults = ref(null)
const assessmentSummary = ref(null)

// Generate username for task-based pathway (needs to be available before API call)
const taskBasedUsername = ref(pathway.value === 'TASK_BASED' ? (() => {
  const timestamp = Date.now()
  const randomId = Math.random().toString(36).substring(7)
  return `phase2_task_${props.organizationId}_${timestamp}_${randomId}`
})() : null)

// Computed
const currentStepIndex = computed(() => {
  // Different step sequences based on pathway and user role
  let steps
  if (pathway.value === 'TASK_BASED') {
    steps = isAdmin.value
      ? ['task-input', 'necessary-competencies', 'assessment', 'results', 'learning-objectives']
      : ['task-input', 'necessary-competencies', 'assessment', 'results']
  } else {
    steps = isAdmin.value
      ? ['role-selection', 'necessary-competencies', 'assessment', 'results', 'learning-objectives']
      : ['role-selection', 'necessary-competencies', 'assessment', 'results']
  }
  return steps.indexOf(currentStep.value)
})

// Step titles for the indicator
const stepTitles = computed(() => {
  const baseSteps = pathway.value === 'TASK_BASED'
    ? [
        { title: 'Describe Tasks', description: 'Describe your responsibilities' },
        { title: 'Review Competencies', description: 'See necessary competencies' },
        { title: 'Self-Assessment', description: 'Rate your competencies' },
        { title: 'Results', description: 'View gaps and strengths' }
      ]
    : [
        { title: 'Select Roles', description: 'Choose identified SE roles' },
        { title: 'Review Competencies', description: 'See necessary competencies' },
        { title: 'Self-Assessment', description: 'Rate your competencies' },
        { title: 'Results', description: 'View gaps and strengths' }
      ]

  // Add Learning Objectives step for admins
  if (isAdmin.value) {
    baseSteps.push({ title: 'Learning Objectives', description: 'Generate training objectives' })
  }

  return baseSteps
})

/**
 * Handle roles selected from Task 1 Step 1
 */
const handleRolesSelected = (data) => {
  console.log('[Phase2 Flow] Roles selected:', data)

  selectedRoles.value = data.selectedRoles
  necessaryCompetencies.value = data.competencies

  // Move to Step 2: Show necessary competencies
  currentStep.value = 'necessary-competencies'
}

/**
 * Handle start assessment from Task 1 Step 2
 * @param {Object} data - Data emitted from Phase2NecessaryCompetencies containing competencies
 */
const handleStartAssessment = async (data) => {
  try {
    console.log('[Phase2 Flow] Starting assessment...')
    console.log('[Phase2 Flow] Received data:', data)
    console.log('[Phase2 Flow] Task-based username:', taskBasedUsername.value)
    console.log('[Phase2 Flow] Pathway:', pathway.value)

    // Store competencies from the emitted data (IMPORTANT for task-based pathway!)
    if (data && data.competencies) {
      necessaryCompetencies.value = data.competencies
      console.log('[Phase2 Flow] Set necessary competencies:', necessaryCompetencies.value.length)
    }

    // Call backend to create assessment
    const response = await phase2Task2Api.startAssessment(
      props.organizationId,
      authStore.user?.id || 1,
      props.employeeName || authStore.user?.name || 'Test User',
      selectedRoles.value.map(r => r.id),
      necessaryCompetencies.value,
      'phase2_employee',
      taskBasedUsername.value  // Pass task-based username for task-based pathway
    )

    if (response.success) {
      assessmentId.value = response.assessment_id
      console.log('[Phase2 Flow] Assessment created with ID:', assessmentId.value)

      toast.success('Assessment started successfully')

      // Move to Step 3: Show assessment
      currentStep.value = 'assessment'
    }
  } catch (error) {
    console.error('[Phase2 Flow] Error starting assessment:', error)
    toast.error('Failed to start assessment')
  }
}

/**
 * Handle assessment completion
 */
const handleAssessmentComplete = (data) => {
  console.log('[Phase2 Flow] Assessment complete:', data)

  assessmentResults.value = data.results
  assessmentSummary.value = data.summary

  // Move to Step 4: Show results
  currentStep.value = 'results'
}

/**
 * Handle continue from results (complete Phase 2)
 */
const handleContinue = () => {
  emit('complete', {
    assessmentId: assessmentId.value,
    results: assessmentResults.value,
    summary: assessmentSummary.value
  })
}

/**
 * Navigation: Back handlers
 */
const handleBack = () => {
  emit('back')
}

const handleBackToRoleSelection = () => {
  currentStep.value = 'role-selection'
}

const handleBackToCompetencies = () => {
  currentStep.value = 'necessary-competencies'
}

const handleBackToAssessment = () => {
  // Not recommended, but allow if needed
  currentStep.value = 'assessment'
}

/**
 * Handle tasks analyzed from Task-Based Pathway
 */
const handleTasksAnalyzed = async (data) => {
  console.log('[Phase2 Flow] Tasks analyzed:', data)
  console.log('[Phase2 Flow] Task-based username:', taskBasedUsername.value)

  // The competencies will be fetched by Phase2NecessaryCompetencies component
  // Move to Step 2: Show necessary competencies
  currentStep.value = 'necessary-competencies'
}

/**
 * Note: Pathway switching removed
 * Pathway is determined by Phase 1 Question 2 (SE processes/roles maturity)
 * - If Q2 < 3: No roles defined → Task-based pathway (locked)
 * - If Q2 >= 3: Roles defined → Role-based pathway (locked)
 */
</script>

<style scoped>
.phase2-task-flow {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.phase2-header {
  margin-bottom: 32px;
  text-align: center;
}

.phase2-header h1 {
  margin: 0 0 8px 0;
  font-size: 28px;
  color: #303133;
}

.phase2-header p {
  margin: 0;
  font-size: 16px;
  color: #606266;
}

.step-indicator {
  margin-bottom: 32px;
}

.step-content {
  min-height: 400px;
}

/* Responsive */
@media (max-width: 768px) {
  .phase2-task-flow {
    padding: 16px;
  }

  .phase2-header h1 {
    font-size: 22px;
  }

  .phase2-header p {
    font-size: 14px;
  }
}
</style>
