<template>
  <div class="phase2-task-flow">
    <!-- Phase 2 Header -->
    <div class="phase2-header">
      <h1>Phase 2: Competency Assessment</h1>
      <p>Identify necessary competencies and assess current competency levels</p>
    </div>

    <!-- Step Indicator -->
    <div class="step-indicator">
      <el-steps :active="currentStepIndex" align-center finish-status="success">
        <el-step title="Select Roles" description="Choose identified SE roles" />
        <el-step title="Review Competencies" description="See necessary competencies" />
        <el-step title="Self-Assessment" description="Rate your competencies" />
        <el-step title="Results" description="View gaps and strengths" />
      </el-steps>
    </div>

    <!-- Step Content -->
    <div class="step-content">
      <!-- Step 1: Role Selection (Task 1 Part 1) -->
      <Phase2RoleSelection
        v-if="currentStep === 'role-selection'"
        :organization-id="organizationId"
        @next="handleRolesSelected"
        @back="handleBack"
      />

      <!-- Step 2: Necessary Competencies Display (Task 1 Part 2) -->
      <Phase2NecessaryCompetencies
        v-else-if="currentStep === 'necessary-competencies'"
        :competencies="necessaryCompetencies"
        :selected-roles="selectedRoles"
        :organization-id="organizationId"
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
import { useAuthStore } from '@/stores/auth'
import { phase2Task2Api } from '@/api/phase2'
import { toast } from 'vue3-toastify'
import Phase2RoleSelection from './Phase2RoleSelection.vue'
import Phase2NecessaryCompetencies from './Phase2NecessaryCompetencies.vue'
import Phase2CompetencyAssessment from './Phase2CompetencyAssessment.vue'
import CompetencyResults from './CompetencyResults.vue' // Use existing component with radar chart & LLM feedback

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  employeeName: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()

// State
const currentStep = ref('role-selection')
const selectedRoles = ref([])
const necessaryCompetencies = ref([])
const assessmentId = ref(null)
const assessmentResults = ref(null)
const assessmentSummary = ref(null)

// Computed
const currentStepIndex = computed(() => {
  const steps = ['role-selection', 'necessary-competencies', 'assessment', 'results']
  return steps.indexOf(currentStep.value)
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
 */
const handleStartAssessment = async () => {
  try {
    console.log('[Phase2 Flow] Starting assessment...')

    // Call backend to create assessment
    const response = await phase2Task2Api.startAssessment(
      props.organizationId,
      authStore.user?.id || 1,
      props.employeeName || authStore.user?.name || 'Test User',
      selectedRoles.value.map(r => r.id),
      necessaryCompetencies.value,
      'phase2_employee'
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
