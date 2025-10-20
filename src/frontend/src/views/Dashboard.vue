<template>
  <div class="dashboard">
    <!-- Welcome Header -->
    <div class="dashboard-header">
      <div class="welcome-section">
        <h1 class="welcome-title">Welcome back, {{ authStore.userName }}!</h1>
        <p class="welcome-subtitle">Continue your systems engineering qualification journey</p>
        <div v-if="authStore.isAdmin && organizationCode" class="org-code-badge">
          <el-tag type="info" size="large" effect="plain">
            <span style="font-weight: 600;">Organization Code:</span>
            <span style="font-family: monospace; margin-left: 8px; font-size: 16px; font-weight: bold;">{{ organizationCode }}</span>
          </el-tag>
          <el-tooltip content="Share this code with employees to join your organization" placement="right">
            <el-icon style="margin-left: 8px; cursor: help;"><QuestionFilled /></el-icon>
          </el-tooltip>
        </div>
      </div>

      <div class="quick-actions">
        <el-button type="primary" @click="startNewAssessment">
          <el-icon><Plus /></el-icon>
          New Assessment
        </el-button>
      </div>
    </div>

    <!-- Progress Overview -->
    <div class="progress-overview">
      <el-row :gutter="24">
        <el-col :span="6">
          <el-card class="progress-card">
            <div class="progress-content">
              <div class="progress-icon assessments">
                <el-icon size="32"><DocumentChecked /></el-icon>
              </div>
              <div class="progress-stats">
                <div class="progress-number">{{ assessmentStore.totalAssessments }}</div>
                <div class="progress-label">Total Assessments</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="progress-card">
            <div class="progress-content">
              <div class="progress-icon completed">
                <el-icon size="32"><SuccessFilled /></el-icon>
              </div>
              <div class="progress-stats">
                <div class="progress-number">{{ assessmentStore.completedAssessments.length }}</div>
                <div class="progress-label">Completed</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="progress-card">
            <div class="progress-content">
              <div class="progress-icon plans">
                <el-icon size="32"><Calendar /></el-icon>
              </div>
              <div class="progress-stats">
                <div class="progress-number">{{ qualificationPlans.length }}</div>
                <div class="progress-label">Active Plans</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="progress-card">
            <div class="progress-content">
              <div class="progress-icon rate">
                <el-icon size="32"><TrendCharts /></el-icon>
              </div>
              <div class="progress-stats">
                <div class="progress-number">{{ Math.round(assessmentStore.completionRate) }}%</div>
                <div class="progress-label">Completion Rate</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Main Content Grid -->
    <div class="dashboard-grid">
      <el-row :gutter="24">
        <!-- Left Column -->
        <el-col :span="16">
          <!-- Current Assessment -->
          <el-card class="section-card" v-if="currentAssessment">
            <template #header>
              <div class="card-header">
                <h3>Current Assessment</h3>
                <el-tag :type="getStatusType(currentAssessment.status)">
                  {{ currentAssessment.status }}
                </el-tag>
              </div>
            </template>

            <div class="current-assessment">
              <div class="assessment-info">
                <h4>{{ currentAssessment.type }} Assessment</h4>
                <p>Phase {{ currentAssessment.phase }} • {{ currentAssessment.organization }}</p>

                <div class="progress-section">
                  <div class="progress-header">
                    <span>Progress</span>
                    <span>{{ currentAssessment.progress }}%</span>
                  </div>
                  <el-progress
                    :percentage="currentAssessment.progress"
                    :color="getProgressColor(currentAssessment.progress)"
                  />
                </div>
              </div>

              <div class="assessment-actions">
                <el-button
                  type="primary"
                  @click="continueAssessment(currentAssessment)"
                  v-if="currentAssessment.status !== 'completed'"
                >
                  Continue Assessment
                </el-button>
                <el-button
                  @click="viewResults(currentAssessment)"
                  v-if="currentAssessment.status === 'completed'"
                >
                  View Results
                </el-button>
              </div>
            </div>
          </el-card>

          <!-- Role-Based SE-QPT Workflow -->
          <el-card class="section-card">
            <template #header>
              <div class="card-header">
                <h3>{{ workflowTitle }}</h3>
                <el-tag :type="authStore.isAdmin ? 'danger' : 'success'">
                  {{ authStore.isAdmin ? 'Admin' : 'Employee' }}
                </el-tag>
              </div>
            </template>

            <!-- Admin Workflow: Phase 1 Setup + Admin Competency Assessment -->
            <div v-if="authStore.isAdmin" class="admin-workflow">
              <div class="workflow-description">
                <el-alert
                  title="Admin Complete Journey"
                  description="As an organizational admin, complete all phases: prepare SE training foundation (Phase 1), identify requirements and competencies (Phase 2), create macro plan (Phase 3), and develop detailed implementation (Phase 4)."
                  type="info"
                  :closable="false"
                  show-icon
                />
              </div>

              <div class="phases-navigation">
                <div
                  v-for="(phase, index) in adminPhases"
                  :key="index"
                  class="phase-card"
                  :class="{ completed: phase.completed, active: phase.active, disabled: phase.disabled }"
                  @click="!phase.disabled && navigateToPhase(phase.route)"
                >
                  <div class="phase-indicator">
                    <div class="phase-number">{{ index + 1 }}</div>
                    <el-icon v-if="phase.completed" class="completion-icon">
                      <SuccessFilled />
                    </el-icon>
                  </div>

                  <div class="phase-content">
                    <h4 class="phase-title">{{ phase.title }}</h4>
                    <p class="phase-description">{{ phase.description }}</p>

                    <div class="phase-progress" v-if="phase.progress !== undefined">
                      <el-progress
                        :percentage="phase.progress"
                        :show-text="false"
                        :stroke-width="4"
                      />
                    </div>
                  </div>

                  <div class="phase-arrow">
                    <el-icon><ArrowRight /></el-icon>
                  </div>
                </div>
              </div>
            </div>

            <!-- Employee Workflow: Organization Context + Personal Assessments -->
            <div v-else class="employee-workflow">
              <div class="workflow-description">
                <el-alert
                  title="Employee Journey"
                  description="View your organization's SE training preparation (Phase 1), then complete your personal competency assessments (Phases 2-4)."
                  type="success"
                  :closable="false"
                  show-icon
                />
              </div>

              <div class="phases-navigation">
                <div
                  v-for="(phase, index) in employeePhases"
                  :key="index"
                  class="phase-card"
                  :class="{ completed: phase.completed, active: phase.active, disabled: phase.disabled }"
                  @click="!phase.disabled && navigateToPhase(phase.route)"
                >
                  <div class="phase-indicator">
                    <div class="phase-number">{{ index + 1 }}</div>
                    <el-icon v-if="phase.completed" class="completion-icon">
                      <SuccessFilled />
                    </el-icon>
                  </div>

                  <div class="phase-content">
                    <h4 class="phase-title">{{ phase.title }}</h4>
                    <p class="phase-description">{{ phase.description }}</p>

                    <div class="phase-progress" v-if="phase.progress !== undefined">
                      <el-progress
                        :percentage="phase.progress"
                        :show-text="false"
                        :stroke-width="4"
                      />
                    </div>
                  </div>

                  <div class="phase-arrow">
                    <el-icon><ArrowRight /></el-icon>
                  </div>
                </div>
              </div>
            </div>
          </el-card>

        </el-col>

        <!-- Right Column -->
        <el-col :span="8">
          <!-- Quick Stats -->
          <el-card class="section-card">
            <template #header>
              <h3>Competency Overview</h3>
            </template>

            <div class="competency-overview">
              <div v-if="competencyStats.length > 0">
                <div
                  v-for="competency in competencyStats.slice(0, 5)"
                  :key="competency.name"
                  class="competency-item"
                >
                  <div class="competency-info">
                    <span class="competency-name">{{ competency.name }}</span>
                    <span class="competency-score">{{ competency.score }}/5</span>
                  </div>
                  <el-progress
                    :percentage="(competency.score / 5) * 100"
                    :show-text="false"
                    :stroke-width="6"
                    :color="getCompetencyColor(competency.score)"
                  />
                </div>

                <el-button type="text" @click="viewAllCompetencies" class="view-all-btn">
                  View All Competencies →
                </el-button>
              </div>

              <div v-else class="no-competencies">
                <el-icon size="48" class="empty-icon"><User /></el-icon>
                <p>Complete Phase 2 to identify competencies and view your profile</p>
              </div>
            </div>
          </el-card>

          <!-- Learning Objectives -->
          <el-card class="section-card">
            <template #header>
              <h3>Learning Objectives</h3>
            </template>

            <div class="learning-objectives">
              <div v-if="learningObjectives.length > 0">
                <div
                  v-for="objective in learningObjectives.slice(0, 3)"
                  :key="objective.id"
                  class="objective-item"
                >
                  <div class="objective-content">
                    <p class="objective-text">{{ objective.text }}</p>
                    <div class="objective-meta">
                      <el-tag size="small" type="info">{{ objective.competency }}</el-tag>
                      <span class="objective-quality">{{ Math.round(objective.quality * 100) }}% quality</span>
                    </div>
                  </div>
                </div>

                <el-button type="text" @click="viewAllObjectives" class="view-all-btn">
                  View All Objectives →
                </el-button>
              </div>

              <div v-else class="no-objectives">
                <el-icon size="48" class="empty-icon"><Aim /></el-icon>
                <p>Learning objectives will be generated during Phase 2 (Identify Requirements and Competencies)</p>
              </div>
            </div>
          </el-card>

          <!-- Next Steps -->
          <el-card class="section-card">
            <template #header>
              <h3>Recommended Next Steps</h3>
            </template>

            <div class="next-steps">
              <div
                v-for="step in nextSteps"
                :key="step.id"
                class="next-step-item"
                @click="executeStep(step)"
              >
                <div class="step-icon" :class="step.type">
                  <el-icon>
                    <component :is="step.icon" />
                  </el-icon>
                </div>

                <div class="step-content">
                  <div class="step-title">{{ step.title }}</div>
                  <div class="step-description">{{ step.description }}</div>
                </div>

                <div class="step-arrow">
                  <el-icon><ArrowRight /></el-icon>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAssessmentStore } from '@/stores/assessment'
import { usePhaseProgression } from '@/composables/usePhaseProgression'
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'

dayjs.extend(relativeTime)

// Stores and router
const router = useRouter()
const authStore = useAuthStore()
const assessmentStore = useAssessmentStore()

// Phase progression - must be initialized at top level for reactivity
const { canAccessPhase, getPhaseStatus, getPhaseTitle, getPhaseDescription, checkPhaseCompletion } = usePhaseProgression()

// State
const qualificationPlans = ref([])
const competencyStats = ref([])
const learningObjectives = ref([])
const nextSteps = ref([])
const organizationCode = ref(null)
const phaseDataLoaded = ref(false) // Track when phase completion data is loaded

// Computed
const currentAssessment = computed(() => {
  return assessmentStore.inProgressAssessments[0] || null
})

// Role-based workflow computed properties
const workflowTitle = computed(() => {
  return authStore.isAdmin ? 'Admin Complete Workflow' : 'Employee Assessment Journey'
})

const adminPhases = computed(() => {
  // Force re-computation when phase data is loaded
  console.log('[Dashboard] Computing adminPhases, phaseDataLoaded:', phaseDataLoaded.value)
  if (!phaseDataLoaded.value) return []

  console.log('[Dashboard] Computing adminPhases with canAccessPhase(2):', canAccessPhase(2))

  return [
    {
      title: getPhaseTitle(1),
      description: getPhaseDescription(1),
      completed: getPhaseStatus(1) === 'completed',
      active: getPhaseStatus(1) === 'available',
      progress: 0,
      route: '/app/phases/1',
      disabled: false
    },
    {
      title: getPhaseTitle(2),
      description: getPhaseDescription(2),
      completed: getPhaseStatus(2) === 'completed',
      active: getPhaseStatus(2) === 'available',
      progress: 0,
      route: '/app/phases/2',
      disabled: !canAccessPhase(2)
    },
    {
      title: getPhaseTitle(3),
      description: getPhaseDescription(3),
      completed: getPhaseStatus(3) === 'completed',
      active: getPhaseStatus(3) === 'available',
      progress: undefined,
      route: '/app/phases/3',
      disabled: !canAccessPhase(3)
    },
    {
      title: getPhaseTitle(4),
      description: getPhaseDescription(4),
      completed: getPhaseStatus(4) === 'completed',
      active: getPhaseStatus(4) === 'available',
      progress: undefined,
      route: '/app/phases/4',
      disabled: !canAccessPhase(4)
    }
  ]
})

const employeePhases = computed(() => {
  // Force re-computation when phase data is loaded
  if (!phaseDataLoaded.value) return []

  return [
    {
      title: 'Organization SE Training Preparation',
      description: 'View organizational SE maturity, identified roles, and training strategy',
      completed: getPhaseStatus(1) === 'completed',
      active: getPhaseStatus(1) === 'available',
      progress: undefined,
      route: '/app/phases/1',
      disabled: false
    },
    {
      title: getPhaseTitle(2),
      description: getPhaseDescription(2),
      completed: getPhaseStatus(2) === 'completed',
      active: getPhaseStatus(2) === 'available',
      progress: 0,
      route: '/app/phases/2',
      disabled: !canAccessPhase(2)
    },
    {
      title: getPhaseTitle(3),
      description: getPhaseDescription(3),
      completed: getPhaseStatus(3) === 'completed',
      active: getPhaseStatus(3) === 'available',
      progress: undefined,
      route: '/app/phases/3',
      disabled: !canAccessPhase(3)
    },
    {
      title: getPhaseTitle(4),
      description: getPhaseDescription(4),
      completed: getPhaseStatus(4) === 'completed',
      active: getPhaseStatus(4) === 'available',
      progress: undefined,
      route: '/app/phases/4',
      disabled: !canAccessPhase(4)
    }
  ]
})

// Methods
const startNewAssessment = () => {
  // Both admin and employee go to Phase 1
  router.push('/app/phases/1')
}


const continueAssessment = (assessment) => {
  router.push(`/app/assessments/${assessment.uuid}/take`)
}

const viewResults = (assessment) => {
  router.push(`/app/assessments/${assessment.uuid}`)
}

const navigateToPhase = (route) => {
  if (route && !route.includes('undefined')) {
    router.push(route)
  }
}


const viewAllCompetencies = () => {
  router.push('/app/competencies')
}

const viewAllObjectives = () => {
  router.push('/app/objectives')
}

const executeStep = (step) => {
  router.push(step.route)
}

const getStatusType = (status) => {
  const statusMap = {
    pending: 'info',
    in_progress: 'warning',
    completed: 'success',
    error: 'danger'
  }
  return statusMap[status] || 'info'
}

const getProgressColor = (progress) => {
  if (progress < 30) return '#f56c6c'
  if (progress < 70) return '#e6a23c'
  return '#67c23a'
}

const getCompetencyColor = (score) => {
  if (score < 2) return '#f56c6c'
  if (score < 3.5) return '#e6a23c'
  return '#67c23a'
}


const loadDashboardData = async () => {
  // Load assessments
  // TODO: Temporarily disabled for MVP - await assessmentStore.fetchAssessments()

  // Initialize empty arrays - real data will come from actual assessments
  competencyStats.value = []
  learningObjectives.value = []

  // Refresh phase completion status (especially important for employees)
  console.log('[Dashboard] onMounted - starting phase check')
  phaseDataLoaded.value = false

  await checkPhaseCompletion()
  console.log('[Dashboard] onMounted - phase check complete, setting phaseDataLoaded to true')
  phaseDataLoaded.value = true // Trigger computed properties to update

  // Fetch organization code from localStorage (stored during registration)
  // This works for both admin and employee users
  const storedOrgCode = localStorage.getItem('user_organization_code')
  if (storedOrgCode) {
    organizationCode.value = storedOrgCode
  }

  // Set up next steps based on user role and actual progress
  if (authStore.isAdmin) {
    nextSteps.value = [
      {
        id: 1,
        title: 'Prepare SE Training',
        description: 'Assess maturity, identify roles, and select strategy',
        icon: 'DocumentChecked',
        type: 'assessment',
        route: '/app/phases/1'
      },
      {
        id: 2,
        title: 'Manage Organization',
        description: 'View and manage organizational settings',
        icon: 'Setting',
        type: 'profile',
        route: '/app/admin/organization'
      }
    ]
  } else {
    nextSteps.value = [
      {
        id: 1,
        title: 'View SE Training Preparation',
        description: 'Review organizational maturity, roles, and strategy',
        icon: 'OfficeBuilding',
        type: 'exploration',
        route: '/app/phases/1'
      },
      {
        id: 2,
        title: 'Identify Competencies',
        description: 'Define competencies and learning objectives',
        icon: 'User',
        type: 'assessment',
        route: '/app/phases/2'
      }
    ]
  }
}

// Lifecycle
onMounted(() => {
  loadDashboardData()
})
</script>

<style scoped>
.dashboard {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
}

.welcome-title {
  font-size: 2rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
}

.welcome-subtitle {
  color: #6c757d;
  font-size: 1.1rem;
}

.quick-actions {
  display: flex;
  gap: 12px;
}

.progress-overview {
  margin-bottom: 32px;
}

.progress-card {
  text-align: center;
}

.progress-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.progress-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.progress-icon.assessments {
  background: linear-gradient(135deg, #409eff, #337ecc);
}

.progress-icon.completed {
  background: linear-gradient(135deg, #67c23a, #529b2e);
}

.progress-icon.plans {
  background: linear-gradient(135deg, #e6a23c, #cf9236);
}

.progress-icon.rate {
  background: linear-gradient(135deg, #f56c6c, #dd6161);
}

.progress-stats {
  text-align: left;
}

.progress-number {
  font-size: 2rem;
  font-weight: 700;
  color: #2c3e50;
  line-height: 1;
}

.progress-label {
  color: #6c757d;
  font-size: 0.9rem;
  margin-top: 4px;
}

.dashboard-grid {
  gap: 24px;
}

.section-card {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  margin: 0;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.current-assessment {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 24px;
}

.assessment-info {
  flex: 1;
}

.assessment-info h4 {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
}

.assessment-info p {
  margin: 0 0 20px 0;
  color: #6c757d;
}

.progress-section {
  margin-top: 16px;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #6c757d;
}

.workflow-description {
  margin-bottom: 24px;
}

.phases-navigation {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.phase-card {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 20px;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.phase-card:hover {
  border-color: #409eff;
  background: #f8f9fa;
}

.phase-card.completed {
  border-color: #67c23a;
  background: #f0f9f2;
}

.phase-card.active {
  border-color: #409eff;
  background: #ecf5ff;
}

.phase-card.disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: #f5f5f5;
}

.phase-card.disabled:hover {
  border-color: #e9ecef;
  background: #f5f5f5;
}

.phase-indicator {
  position: relative;
  flex-shrink: 0;
}

.phase-number {
  width: 48px;
  height: 48px;
  background: #e9ecef;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: #6c757d;
}

.phase-card.active .phase-number {
  background: #409eff;
  color: white;
}

.phase-card.completed .phase-number {
  background: #67c23a;
  color: white;
}

.completion-icon {
  position: absolute;
  top: -4px;
  right: -4px;
  background: white;
  border-radius: 50%;
  color: #67c23a;
  font-size: 20px;
}

.phase-content {
  flex: 1;
}

.phase-title {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
}

.phase-description {
  margin: 0 0 12px 0;
  color: #6c757d;
  font-size: 0.9rem;
}

.phase-progress {
  margin-top: 12px;
}

.phase-arrow {
  color: #6c757d;
  flex-shrink: 0;
}


.competency-overview,
.learning-objectives {
  min-height: 200px;
}

.competency-item {
  margin-bottom: 20px;
}

.competency-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.competency-name {
  font-weight: 500;
  color: #2c3e50;
  font-size: 0.9rem;
}

.competency-score {
  font-weight: 600;
  color: #409eff;
  font-size: 0.9rem;
}

.objective-item {
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e9ecef;
}

.objective-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.objective-text {
  font-size: 0.9rem;
  color: #2c3e50;
  margin-bottom: 8px;
  line-height: 1.4;
}

.objective-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.objective-quality {
  font-size: 0.8rem;
  color: #6c757d;
}

.next-steps {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.next-step-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.next-step-item:hover {
  border-color: #409eff;
  background: #f8f9fa;
}

.step-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  flex-shrink: 0;
}

.step-icon.assessment {
  background: #409eff;
}

.step-icon.profile {
  background: #67c23a;
}

.step-icon.exploration {
  background: #e6a23c;
}

.step-content {
  flex: 1;
}

.step-title {
  font-weight: 500;
  color: #2c3e50;
  margin-bottom: 4px;
  font-size: 0.9rem;
}

.step-description {
  font-size: 0.8rem;
  color: #6c757d;
}

.step-arrow {
  color: #6c757d;
  flex-shrink: 0;
}

.view-all-btn {
  margin-top: 16px;
  color: #409eff;
  font-size: 0.9rem;
}

.no-competencies,
.no-objectives {
  text-align: center;
  padding: 40px 20px;
  color: #6c757d;
}

.empty-icon {
  color: #c0c4cc;
  margin-bottom: 16px;
}

.no-competencies p,
.no-objectives p {
  margin-bottom: 16px;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .dashboard {
    padding: 16px;
  }

  .dashboard-header {
    flex-direction: column;
    gap: 20px;
    align-items: stretch;
  }

  .quick-actions {
    justify-content: center;
  }

  .current-assessment {
    flex-direction: column;
    gap: 16px;
  }

  .progress-content {
    flex-direction: column;
    gap: 12px;
  }

  .progress-stats {
    text-align: center;
  }
}
</style>