<template>
  <div class="phase-two">
    <!-- Phase Header -->
    <div class="phase-header">
      <div class="phase-indicator">
        <div class="phase-number">2</div>
        <div class="phase-title">
          <h1>Phase 2: Competency Assessment & RAG Objectives</h1>
          <p>Assess your competencies across 16 INCOSE domains and generate AI-powered learning objectives</p>
        </div>
      </div>

      <div class="phase-progress">
        <el-progress
          :percentage="overallProgress"
          :color="progressColor"
          :stroke-width="8"
        />
        <span class="progress-text">{{ overallProgress }}% Complete</span>
      </div>
    </div>

    <!-- Phase Steps -->
    <div class="phase-steps">
      <el-steps :active="currentStep" align-center finish-status="success">
        <el-step title="Assessment Type" description="Select pathway & context" />
        <el-step title="Role/Task Selection" description="Define assessment scope" />
        <el-step title="Assessment Results" description="Review competency analysis" />
        <el-step title="Company Context" description="PMT job environment details" />
        <el-step title="RAG Objectives" description="Generate customized learning goals" />
        <el-step title="Review Results" description="Validate and confirm" />
      </el-steps>
    </div>

    <!-- Step Content -->
    <div class="step-content">
      <!-- Step 1: Assessment Type & Context Selection -->
      <el-card v-if="currentStep === 0" class="step-card">
        <template #header>
          <h3>Assessment Configuration</h3>
        </template>

        <div class="assessment-configuration">
          <!-- Assessment Pathway Selection -->
          <div class="pathway-selection">
            <h4>Choose Assessment Pathway</h4>
            <div class="pathway-options">
              <div
                class="pathway-card"
                :class="{ selected: selectedPathway === 'role-based' }"
                @click="selectPathway('role-based')"
              >
                <el-icon size="32"><Briefcase /></el-icon>
                <h5>Role-Based Assessment</h5>
                <p>Select from 14 predefined SE role clusters and assess competencies required for your target role(s).</p>
                <ul>
                  <li>Choose from established role clusters</li>
                  <li>Get role-specific competency requirements</li>
                  <li>Compare current vs required levels</li>
                </ul>
              </div>

              <div
                class="pathway-card"
                :class="{ selected: selectedPathway === 'task-based' }"
                @click="selectPathway('task-based')"
              >
                <el-icon size="32"><List /></el-icon>
                <h5>Task-Based Assessment</h5>
                <p>Describe your job tasks and responsibilities. AI will map them to ISO processes and derive competency requirements.</p>
                <ul>
                  <li>Input job tasks and responsibilities</li>
                  <li>AI maps tasks to ISO 15288 processes</li>
                  <li>System derives competency requirements</li>
                </ul>
              </div>

              <div
                class="pathway-card"
                :class="{ selected: selectedPathway === 'full-competency' }"
                @click="selectPathway('full-competency')"
              >
                <el-icon size="32"><DataBoard /></el-icon>
                <h5>Full Competency Assessment</h5>
                <p>Assess all 16 SE competencies. System will suggest best-matching roles based on your competency profile.</p>
                <ul>
                  <li>Comprehensive competency evaluation</li>
                  <li>AI suggests suitable roles</li>
                  <li>Discover potential career paths</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div class="step-actions">
          <el-button type="primary" @click="nextStep" :disabled="!selectedPathway" :loading="loading">
            Continue with {{ getPathwayLabel() }}
          </el-button>
        </div>
      </el-card>

      <!-- Step 2: Role/Task Selection (Based on Pathway) -->
      <el-card v-if="currentStep === 1" class="step-card">
        <template #header>
          <h3>{{ getStep2Title() }}</h3>
        </template>

        <!-- Derik's Competency Assessment Integration -->
        <DerikCompetencyBridge
          v-if="selectedPathway"
          :mode="selectedPathway"
          @back="previousStep"
          @completed="onCompetencyAssessmentCompleted"
        />

        <!-- Role-Based Pathway (Original - Hidden) -->
        <div v-if="false && selectedPathway === 'role-based'" class="role-selection">
          <div class="selection-intro">
            <p>Select one or more roles from the 14 predefined SE role clusters. You can select multiple roles if your position involves responsibilities from different clusters.</p>
          </div>

          <div class="roles-grid">
            <div
              v-for="role in roles"
              :key="role.id"
              class="role-card"
              :class="{ selected: selectedRoles.includes(role.id) }"
              @click="toggleRole(role.id)"
            >
              <div class="role-header">
                <h4 class="role-name">{{ role.name }}</h4>
                <div class="role-level">
                  <el-tag :type="getLevelType(role.career_level)" size="small">
                    {{ role.career_level }}
                  </el-tag>
                </div>
              </div>

              <p class="role-description">{{ role.description }}</p>

              <div class="role-focus">
                <strong>Primary Focus:</strong> {{ role.primary_focus }}
              </div>

              <div class="role-responsibilities">
                <strong>Key Responsibilities:</strong>
                <ul>
                  <li v-for="resp in role.typical_responsibilities.slice(0, 3)" :key="resp">
                    {{ resp }}
                  </li>
                </ul>
              </div>

              <div class="selection-indicator" v-if="selectedRoles.includes(role.id)">
                <el-icon><Check /></el-icon>
              </div>
            </div>
          </div>

          <div class="selected-roles-summary" v-if="selectedRoles.length > 0">
            <el-alert
              :title="`${selectedRoles.length} role(s) selected`"
              :description="`Assessment will cover competencies required for: ${getSelectedRoleNames()}`"
              type="info"
              show-icon
              :closable="false"
            />
          </div>
        </div>


        <!-- Full Competency Pathway -->
        <div v-else-if="selectedPathway === 'full-competency'" class="full-competency-intro">
          <div class="intro-content">
            <el-icon size="64" class="intro-icon"><DataBoard /></el-icon>
            <h4>Comprehensive SE Competency Assessment</h4>
            <p>You will be assessed across all 16 INCOSE Systems Engineering competencies. Based on your responses, our system will:</p>
            <ul>
              <li>Analyze your competency profile</li>
              <li>Suggest the most suitable SE roles for your skills</li>
              <li>Identify potential career development paths</li>
              <li>Generate personalized learning objectives</li>
            </ul>
            <el-alert
              title="Assessment Length"
              description="This comprehensive assessment typically takes 15-20 minutes to complete."
              type="info"
              show-icon
              :closable="false"
            />
          </div>
        </div>

        <!-- Step actions - Hidden when using DerikCompetencyBridge -->
        <div v-if="!selectedPathway" class="step-actions">
          <el-button @click="previousStep">Previous</el-button>
          <el-button
            type="primary"
            @click="nextStep"
            :disabled="!canProceedFromStep2"
            :loading="loading"
          >
            Continue to Assessment
          </el-button>
        </div>
      </el-card>

      <!-- Step 3: Competency Assessment Results -->
      <el-card v-if="currentStep === 2" class="step-card">
        <template #header>
          <h3>Competency Assessment Results</h3>
        </template>

        <CompetencyResults
          v-if="competencyResponse"
          :assessment-data="competencyResponse"
          @continue="nextStep"
          @back="previousStep"
        />

        <div v-else class="no-results-message">
          <el-alert
            title="No Assessment Results"
            description="Please complete the competency assessment first."
            type="warning"
            :closable="false"
            show-icon
          />
          <div class="step-actions">
            <el-button @click="previousStep">Back to Assessment</el-button>
          </div>
        </div>
      </el-card>

      <!-- Step 4: Company Context Input (Conditional Q5/Q6) -->
      <el-card v-if="currentStep === 3" class="step-card">
        <template #header>
          <h3>{{ getContextStepTitle() }}</h3>
          <p class="context-subtitle">{{ getContextStepDescription() }}</p>
        </template>

        <!-- High Customization: Extended PMT Data Collection (Q5) -->
        <JobContextInput
          v-if="isHighCustomizationArchetype()"
          :qualification-archetype="getQualificationArchetype()"
          @context-submitted="onJobContextSubmitted"
          @back="previousStep"
        />

        <!-- Low Customization: Basic Company Context (Q6) -->
        <BasicCompanyContext
          v-else
          @submit="onBasicContextSubmitted"
          @previous="previousStep"
        />
      </el-card>

      <!-- Step 5: Enhanced RAG Objectives Generation -->
      <el-card v-if="currentStep === 4" class="step-card">
        <template #header>
          <div class="card-header">
            <h3>AI-Generated Learning Objectives</h3>
            <el-button
              type="primary"
              @click="regenerateObjectives"
              :loading="generating"
              size="small"
            >
              <el-icon><Refresh /></el-icon>
              Regenerate
            </el-button>
          </div>
        </template>

        <div class="objectives-generation">
          <div v-if="generating" class="generation-loading">
            <el-icon class="loading-spinner" size="48"><Loading /></el-icon>
            <h4>Generating Personalized Learning Objectives...</h4>
            <p>Our RAG-LLM system is creating company-specific objectives based on your assessment.</p>
            <div class="generation-steps">
              <div class="generation-step" :class="{ active: generationStep >= 1 }">
                <el-icon><Check /></el-icon>
                Analyzing competency gaps
              </div>
              <div class="generation-step" :class="{ active: generationStep >= 2 }">
                <el-icon><Loading /></el-icon>
                Retrieving relevant templates
              </div>
              <div class="generation-step" :class="{ active: generationStep >= 3 }">
                <el-icon><Plus /></el-icon>
                Generating objectives
              </div>
              <div class="generation-step" :class="{ active: generationStep >= 4 }">
                <el-icon><Check /></el-icon>
                Validating SMART criteria
              </div>
            </div>
          </div>

          <div v-else-if="generatedObjectives.length > 0" class="objectives-results">
            <div class="results-summary">
              <el-alert
                :title="`Generated ${generatedObjectives.length} learning objectives`"
                :description="`Average quality score: ${averageQualityScore.toFixed(1)}% (≥85% threshold)`"
                :type="averageQualityScore >= 85 ? 'success' : 'warning'"
                show-icon
                :closable="false"
              />
            </div>

            <div class="objectives-list">
              <div
                v-for="(objective, index) in generatedObjectives"
                :key="objective.id"
                class="objective-item"
                :class="{ 'high-quality': objective.quality_score >= 0.85 }"
              >
                <div class="objective-header">
                  <div class="objective-meta">
                    <el-tag type="info" size="small">{{ objective.competency_name }}</el-tag>
                    <el-tag
                      :type="objective.quality_score >= 0.85 ? 'success' : 'warning'"
                      size="small"
                    >
                      {{ Math.round(objective.quality_score * 100) }}% Quality
                    </el-tag>
                    <el-tag
                      :type="objective.smart_score >= 0.85 ? 'success' : 'warning'"
                      size="small"
                    >
                      {{ Math.round(objective.smart_score * 100) }}% SMART
                    </el-tag>
                  </div>

                  <div class="objective-actions">
                    <el-button
                      type="text"
                      @click="editObjective(index)"
                      size="small"
                    >
                      <el-icon><Edit /></el-icon>
                    </el-button>
                    <el-button
                      type="text"
                      @click="removeObjective(index)"
                      size="small"
                    >
                      <el-icon><Delete /></el-icon>
                    </el-button>
                  </div>
                </div>

                <div class="objective-content">
                  <p class="objective-text">{{ objective.objective_text }}</p>
                </div>

                <div class="objective-details">
                  <div class="detail-row">
                    <strong>Target Role:</strong> {{ objective.target_role_name }}
                  </div>
                  <div class="detail-row">
                    <strong>Archetype:</strong> {{ objective.archetype_name }}
                  </div>
                  <div class="detail-row" v-if="objective.company_context">
                    <strong>Company Context:</strong> Applied
                  </div>
                </div>
              </div>
            </div>

            <!-- Add Custom Objective -->
            <div class="add-objective-section">
              <el-button type="dashed" @click="showAddObjective = true" style="width: 100%">
                <el-icon><Plus /></el-icon>
                Add Custom Learning Objective
              </el-button>

              <el-dialog
                v-model="showAddObjective"
                title="Add Custom Learning Objective"
                width="600px"
              >
                <el-form :model="customObjective" label-width="120px">
                  <el-form-item label="Competency">
                    <el-select v-model="customObjective.competency_id" style="width: 100%">
                      <el-option
                        v-for="comp in availableCompetencies"
                        :key="comp.id"
                        :label="comp.name"
                        :value="comp.id"
                      />
                    </el-select>
                  </el-form-item>

                  <el-form-item label="Objective Text">
                    <el-input
                      v-model="customObjective.text"
                      type="textarea"
                      :rows="4"
                      placeholder="Write a specific, measurable learning objective..."
                    />
                  </el-form-item>
                </el-form>

                <template #footer>
                  <el-button @click="showAddObjective = false">Cancel</el-button>
                  <el-button type="primary" @click="addCustomObjective">Add Objective</el-button>
                </template>
              </el-dialog>
            </div>
          </div>

          <div v-else class="no-objectives">
            <el-icon size="64" class="empty-icon"><Plus /></el-icon>
            <h4>No objectives generated yet</h4>
            <p>Complete the competency assessment to generate personalized learning objectives.</p>
          </div>
        </div>

        <div class="step-actions">
          <el-button @click="previousStep">Previous</el-button>
          <el-button
            type="primary"
            @click="nextStep"
            :disabled="generatedObjectives.length === 0"
            :loading="loading"
          >
            Continue to Review
          </el-button>
        </div>
      </el-card>

      <!-- Step 6: Review Results -->
      <el-card v-if="currentStep === 5" class="step-card">
        <template #header>
          <h3>Phase 2 Review & Results</h3>
        </template>

        <div class="results-review">
          <el-row :gutter="24">
            <el-col :span="12">
              <div class="review-section">
                <h4>Selected Role</h4>
                <div class="role-summary">
                  <h5>{{ selectedRoleDetails?.name }}</h5>
                  <p>{{ selectedRoleDetails?.description }}</p>
                  <el-tag :type="getLevelType(selectedRoleDetails?.career_level)">
                    {{ selectedRoleDetails?.career_level }}
                  </el-tag>
                </div>
              </div>

              <div class="review-section">
                <h4>Competency Assessment Summary</h4>
                <div class="competency-summary">
                  <div v-if="competencyResponse">
                    <div class="assessment-summary">
                      <div class="assessment-status">
                        <el-tag type="success" size="large">
                          <el-icon><Check /></el-icon>
                          Completed
                        </el-tag>
                      </div>
                      <div class="response-details">
                        <p><strong>Assessment ID:</strong> {{ competencyResponse.id }}</p>
                        <p><strong>Completed:</strong> {{ new Date(competencyResponse.completed_at || Date.now()).toLocaleDateString() }}</p>
                        <p><strong>Questions Answered:</strong> {{ Object.keys(competencyResponse.responses || {}).length }}</p>
                      </div>
                    </div>
                  </div>
                  <div v-else>
                    <el-alert
                      title="Assessment Not Completed"
                      description="Please complete the competency assessment to see summary."
                      type="warning"
                      :closable="false"
                    />
                  </div>
                </div>
              </div>
            </el-col>

            <el-col :span="12">
              <div class="review-section">
                <h4>Generated Learning Objectives</h4>
                <div class="objectives-summary">
                  <div class="objectives-overview">
                    <div class="overview-stat">
                      <span class="stat-value">{{ generatedObjectives.length }}</span>
                      <span class="stat-label">Total Objectives</span>
                    </div>
                    <div class="overview-stat">
                      <span class="stat-value">{{ Math.round(averageQualityScore) }}%</span>
                      <span class="stat-label">Avg Quality Score</span>
                    </div>
                    <div class="overview-stat">
                      <span class="stat-value">{{ highQualityObjectives }}</span>
                      <span class="stat-label">High Quality (≥85%)</span>
                    </div>
                  </div>

                  <div class="top-objectives">
                    <h5>Top Learning Objectives:</h5>
                    <div
                      v-for="objective in generatedObjectives.slice(0, 3)"
                      :key="objective.id"
                      class="top-objective"
                    >
                      <div class="objective-preview">
                        <span class="objective-text-preview">{{ objective.objective_text }}</span>
                        <el-tag type="success" size="small">
                          {{ Math.round(objective.quality_score * 100) }}%
                        </el-tag>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </el-col>

            <el-col :span="24">
              <div class="review-section">
                <h4>AI Analysis Results</h4>
                <div class="ai-analysis-summary" v-if="derikAnalysis">
                  <el-row :gutter="16">
                    <el-col :span="12">
                      <div class="analysis-item">
                        <h5>Identified ISO Processes</h5>
                        <div class="process-list">
                          <el-tag
                            v-for="process in derikAnalysis.identified_processes"
                            :key="process"
                            type="info"
                            size="small"
                          >
                            {{ process }}
                          </el-tag>
                        </div>
                      </div>
                    </el-col>
                    <el-col :span="12">
                      <div class="analysis-item">
                        <h5>Role Similarity Analysis</h5>
                        <p>
                          <strong>{{ derikAnalysis.similar_role }}</strong>
                          ({{ Math.round(derikAnalysis.similarity_score * 100) }}% match)
                        </p>
                      </div>
                    </el-col>
                  </el-row>
                </div>
              </div>
            </el-col>
          </el-row>
        </div>

        <div class="completion-message">
          <el-alert
            title="Phase 2 Complete!"
            description="You have successfully completed the competency assessment and AI-generated learning objectives. Click 'Complete Phase 2' to proceed to Phase 3: Module Selection."
            type="success"
            show-icon
            :closable="false"
          />
        </div>

        <div class="step-actions">
          <el-button @click="previousStep">Previous</el-button>
          <el-button type="success" @click="completePhase" :loading="loading">
            <el-icon><Check /></el-icon>
            Complete Phase 2
          </el-button>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { Check, Refresh, Loading, Edit, Delete, Plus, User, OfficeBuilding, Briefcase, List, DataBoard, MagicStick } from '@element-plus/icons-vue'
import { assessmentApi } from '@/api/assessment'
import axios from '@/api/axios'
import QuestionnaireComponent from '@/components/common/QuestionnaireComponent.vue'
import CompetencyAssessment from '@/components/assessment/CompetencyAssessment.vue'
import DerikCompetencyBridge from '@/components/assessment/DerikCompetencyBridge.vue'
import CompetencyResults from '@/components/phase2/CompetencyResults.vue'
import JobContextInput from '@/components/phase2/JobContextInput.vue'
import BasicCompanyContext from '@/components/phase2/BasicCompanyContext.vue'

const router = useRouter()
const authStore = useAuthStore()

// State
const currentStep = ref(0)
const loading = ref(false)
const analyzing = ref(false)
const generating = ref(false)
const generationStep = ref(0)

// Pathway selection
const selectedPathway = ref(null)
const selectedRole = ref(null)
const roles = ref([])
const roleCompetencyMatrix = ref([])
const currentAssessment = ref(null)
const jobFormRef = ref()


const jobForm = ref({
  jobTitle: '',
  company: '',
  description: '',
  technologies: '',
  industryContext: ''
})

const jobRules = {
  jobTitle: [
    { required: true, message: 'Job title is required', trigger: 'blur' }
  ],
  description: [
    { required: true, message: 'Job description is required', trigger: 'blur' },
    { min: 100, message: 'Job description should be at least 100 characters', trigger: 'blur' }
  ]
}

const derikAnalysis = ref(null)
const competencyQuestionnaire = ref(null)
const competencyCompleted = ref(false)
const competencyResponse = ref(null)
const generatedObjectives = ref([])
const showAddObjective = ref(false)
const customObjective = ref({
  competency_id: null,
  text: ''
})

// New state for enhanced flow
const jobContextData = ref(null)
const qualificationArchetype = ref(null)

const industryOptions = [
  { value: 'aerospace', label: 'Aerospace & Defense' },
  { value: 'automotive', label: 'Automotive' },
  { value: 'healthcare', label: 'Healthcare & Medical Devices' },
  { value: 'telecommunications', label: 'Telecommunications' },
  { value: 'energy', label: 'Energy & Utilities' },
  { value: 'manufacturing', label: 'Manufacturing' },
  { value: 'software', label: 'Software & IT' },
  { value: 'transportation', label: 'Transportation' },
  { value: 'other', label: 'Other' }
]

// Computed properties
const overallProgress = computed(() => {
  return Math.round((currentStep.value / 5) * 100)
})

const progressColor = computed(() => {
  if (overallProgress.value < 30) return '#f56c6c'
  if (overallProgress.value < 70) return '#e6a23c'
  return '#67c23a'
})

const selectedRoleDetails = computed(() => {
  return roles.value.find(r => r.id === selectedRole.value)
})


const averageQualityScore = computed(() => {
  if (generatedObjectives.value.length === 0) return 0
  return generatedObjectives.value.reduce((sum, obj) => sum + (obj.quality_score * 100), 0) / generatedObjectives.value.length
})

const highQualityObjectives = computed(() => {
  return generatedObjectives.value.filter(obj => obj.quality_score >= 0.85).length
})

const availableCompetencies = computed(() => {
  // Mock data for now since we're using questionnaire component
  return []
})

// Pathway computed properties
const canProceedFromStep2 = computed(() => {
  if (selectedPathway.value === 'role-based') {
    return selectedRole.value !== null
  } else if (selectedPathway.value === 'task-based') {
    return true // DerikCompetencyBridge handles task-based logic
  } else if (selectedPathway.value === 'full-competency') {
    return true
  }
  return false
})


// Methods
const selectPathway = (pathway) => {
  selectedPathway.value = pathway

  // Reset any previous selections when switching pathways
  if (pathway !== 'role-based') {
    selectedRole.value = null
  }
}

const getPathwayLabel = () => {
  const labels = {
    'role-based': 'Role-Based Assessment',
    'task-based': 'Task-Based Assessment',
    'full-competency': 'Full Competency Assessment'
  }
  return labels[selectedPathway.value] || 'Assessment'
}

const getStep2Title = () => {
  const titles = {
    'role-based': 'SE Role Selection',
    'task-based': 'Task Description Analysis',
    'full-competency': 'Full Competency Assessment'
  }
  return titles[selectedPathway.value] || 'Competency Assessment'
}

const nextStep = async () => {
  if (currentStep.value === 0 && selectedPathway.value) {
    // Move from pathway selection to assessment
    currentStep.value++
  } else if (currentStep.value === 1) {
    // DerikCompetencyBridge handles assessment completion
    // This will be called by onCompetencyAssessmentCompleted
    currentStep.value++
  } else if (currentStep.value === 2 && competencyResponse.value) {
    // Move from results to job context
    currentStep.value++
  } else if (currentStep.value === 3 && jobContextData.value) {
    // Move from job context to RAG objectives
    currentStep.value++
    await generateObjectives()
  } else if (currentStep.value === 4 && generatedObjectives.value.length > 0) {
    // Move from objectives to review
    currentStep.value++
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const selectRole = async (roleId) => {
  selectedRole.value = roleId

  // Create assessment for this role
  try {
    const response = await fetch('/api/assessments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify({
        phase: 2,
        assessment_type: 'competency_assessment',
        title: `Competency Assessment - Phase 2`,
        description: 'SE-QPT Phase 2 competency self-assessment',
        results: { selected_role_id: roleId }
      })
    })

    if (response.ok) {
      const data = await response.json()
      currentAssessment.value = data.assessment
    }
  } catch (error) {
    console.error('Failed to create assessment:', error)
    // Continue anyway - we can work without database persistence for demo
    currentAssessment.value = { id: Date.now(), selected_role_id: roleId }
  }
}

const getLevelType = (level) => {
  const levelMap = {
    'Entry-level': 'info',
    'Mid-level': 'warning',
    'Senior': 'success',
    'Executive': 'danger',
    'External': 'info'
  }
  return levelMap[level] || 'info'
}

const getImportanceType = (importance) => {
  const importanceMap = {
    'High': 'danger',
    'Medium': 'warning',
    'Low': 'info'
  }
  return importanceMap[importance] || 'info'
}

const getJobTitlePlaceholder = () => {
  if (selectedPathway.value === 'role-based') {
    return selectedRoleDetails.value ?
           `e.g., Senior ${selectedRoleDetails.value.name}` :
           'Enter your job title'
  } else if (selectedPathway.value === 'task-based') {
    return 'Enter your job title'
  } else {
    return 'Enter your job title'
  }
}

const analyzeJobDescription = async () => {
  try {
    analyzing.value = true

    // For now, create mock analysis to allow progression
    derikAnalysis.value = {
      identified_processes: ['Requirements Analysis', 'System Architecture', 'Verification'],
      similar_role: 'Systems Engineer',
      similarity_score: 0.85,
      reasoning: 'High similarity based on job description analysis'
    }

    ElMessage.success('Job description analyzed successfully!')
  } catch (error) {
    ElMessage.error('Failed to analyze job description')
  } finally {
    analyzing.value = false
  }
}

const loadRoles = async () => {
  try {
    // Use axios which is already configured with correct base URL
    const response = await axios.get('/roles')
    const data = response.data
    // Backend returns an array directly, not {roles: [...]}
    roles.value = Array.isArray(data) ? data : (data.roles || [])
  } catch (error) {
    console.error('Failed to load roles from API:', error)

    // Fallback to mock roles for demo
    roles.value = [
      {
        id: 1,
        name: 'Systems Engineer',
        description: 'Core systems engineering role focusing on technical systems development',
        career_level: 'Senior',
        primary_focus: 'Technical system design and integration',
        typical_experience_years: 8,
        typical_responsibilities: [
          'Lead technical system architecture design',
          'Coordinate system integration activities',
          'Interface with stakeholders on technical requirements',
          'Manage technical risk and trade-offs'
        ]
      },
      {
        id: 2,
        name: 'Requirements Engineer',
        description: 'Specializes in requirements engineering and management processes',
        career_level: 'Mid-Level',
        primary_focus: 'Requirements analysis and management',
        typical_experience_years: 5,
        typical_responsibilities: [
          'Elicit and analyze stakeholder requirements',
          'Maintain requirements traceability',
          'Manage requirements changes and baselines',
          'Facilitate requirements validation'
        ]
      }
    ]
  }
}

const loadRoleCompetencyMatrix = async () => {
  try {
    // Mock role competency matrix
    roleCompetencyMatrix.value = [
      {
        role_id: selectedRole.value,
        competency_id: 1,
        competency_name: 'Requirements Engineering',
        required_level: 4,
        importance_level: 'High'
      },
      {
        role_id: selectedRole.value,
        competency_id: 2,
        competency_name: 'System Architecture',
        required_level: 3,
        importance_level: 'Medium'
      }
    ]
  } catch (error) {
    ElMessage.error('Failed to load role competency matrix')
  }
}

const loadCompetencyQuestionnaire = async () => {
  try {
    loading.value = true
    const response = await assessmentApi.getQuestionnaire(3) // Competency Assessment
    competencyQuestionnaire.value = response.data.questionnaire
  } catch (error) {
    ElMessage.error('Failed to load competency assessment questionnaire')
  } finally {
    loading.value = false
  }
}

const onCompetencyCompleted = (response) => {
  competencyCompleted.value = true
  competencyResponse.value = response
  ElMessage.success('Competency assessment completed!')
}

const onCompetencyProgress = (progress) => {
  // Handle progress updates if needed
}

const generateObjectives = async () => {
  try {
    generating.value = true
    generationStep.value = 0

    // Simulate generation steps
    const steps = [
      { step: 1, delay: 1000 },
      { step: 2, delay: 1500 },
      { step: 3, delay: 2000 },
      { step: 4, delay: 1000 }
    ]

    for (const { step, delay } of steps) {
      await new Promise(resolve => setTimeout(resolve, delay))
      generationStep.value = step
    }

    // Call the enhanced public RAG learning objectives endpoint
    // Fallback to original endpoint for now - enhanced endpoint to be debugged
    const response = await fetch('/api/public/phase2/generate-objectives', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        assessment_data: competencyResponse.value || {},
        job_context: jobContextData.value || {
          companyName: 'Technology Company',
          industryDomain: 'Software Development',
          developmentProcess: ['Agile'],
          designMethods: ['Object-oriented design'],
          developmentTools: 'Git, IDE'
        },
        archetype_info: getQualificationArchetype() || {
          name: 'Blended Learning',
          characteristics: { uses_standardized: true, uses_company_specific: true }
        },
        target_role: selectedRoleDetails.value?.name || 'Systems Engineer',
        priority_competencies: [] // Could be derived from competency assessment
      })
    })

    if (response.ok) {
      const data = await response.json()
      generatedObjectives.value = data.objectives || []
      ElMessage.success(`Generated ${generatedObjectives.value.length} learning objectives using RAG-LLM`)
    } else {
      throw new Error('Failed to generate objectives from RAG system')
    }
  } catch (error) {
    ElMessage.error('Failed to generate learning objectives')
    // Mock objectives for demo
    generateMockObjectives()
  } finally {
    generating.value = false
    generationStep.value = 0
  }
}

const generateMockObjectives = () => {
  const mockObjectives = [
    {
      id: 1,
      objective_text: 'Develop proficiency in stakeholder requirements elicitation techniques within aerospace domain context',
      competency_name: 'Requirements Engineering',
      target_role_name: selectedRoleDetails.value?.name,
      archetype_name: 'Blended Learning',
      quality_score: 0.89,
      smart_score: 0.92,
      company_context: true
    },
    {
      id: 2,
      objective_text: 'Master system interface definition and management for complex automotive systems',
      competency_name: 'System Architecture and Design',
      target_role_name: selectedRoleDetails.value?.name,
      archetype_name: 'Blended Learning',
      quality_score: 0.91,
      smart_score: 0.88,
      company_context: true
    },
    {
      id: 3,
      objective_text: 'Implement effective verification planning processes for software-intensive systems',
      competency_name: 'Integration, Verification and Validation',
      target_role_name: selectedRoleDetails.value?.name,
      archetype_name: 'Blended Learning',
      quality_score: 0.87,
      smart_score: 0.85,
      company_context: true
    }
  ]

  generatedObjectives.value = mockObjectives
}

const regenerateObjectives = async () => {
  await generateObjectives()
}

const editObjective = (index) => {
  // Implement objective editing
  ElMessage.info('Objective editing functionality coming soon!')
}

const removeObjective = (index) => {
  generatedObjectives.value.splice(index, 1)
  ElMessage.success('Objective removed')
}

const addCustomObjective = () => {
  if (customObjective.value.competency_id && customObjective.value.text) {
    const competency = competencies.value.find(c => c.id === customObjective.value.competency_id)

    generatedObjectives.value.push({
      id: Date.now(),
      objective_text: customObjective.value.text,
      competency_name: competency?.name,
      target_role_name: selectedRoleDetails.value?.name,
      archetype_name: 'Custom',
      quality_score: 0.75, // Default for custom objectives
      smart_score: 0.70,
      company_context: false
    })

    customObjective.value = { competency_id: null, text: '' }
    showAddObjective.value = false
    ElMessage.success('Custom objective added!')
  }
}

// Handler for Derik's competency assessment completion
const onCompetencyAssessmentCompleted = async (assessmentData) => {
  try {
    loading.value = true

    // Store the competency assessment results
    competencyResponse.value = assessmentData
    competencyCompleted.value = true

    // Create current assessment object for Step 3
    currentAssessment.value = {
      id: Date.now(),
      type: assessmentData.type,
      selectedRoles: assessmentData.selectedRoles || [],
      results: assessmentData.results || {},
      createdAt: new Date()
    }

    // Update current assessment state based on assessment type
    if (assessmentData.type === 'role-based') {
      selectedRole.value = assessmentData.selectedRoles[0]?.id || null
      console.log('Selected role ID:', selectedRole.value)
      console.log('Available roles:', roles.value.length)
      ElMessage.success(`Role-based assessment completed for ${assessmentData.selectedRoles.length} role(s)`)
    } else if (assessmentData.type === 'task-based') {
      // For task-based assessment, we might not have a specific role ID
      // but we should still create a virtual role representation
      ElMessage.success('Task-based assessment completed successfully')
    } else if (assessmentData.type === 'full-competency') {
      ElMessage.success('Full competency assessment completed successfully')
    }

    // Navigate to persistent results URL instead of showing inline
    // This enables bookmarking, sharing, and proper history tracking
    if (assessmentData.assessment_id) {
      console.log('[NAVIGATION] Redirecting to persistent results URL:', `/app/assessments/${assessmentData.assessment_id}/results`)
      router.push({
        name: 'AssessmentResults',
        params: { id: assessmentData.assessment_id }
      })
    } else {
      // Fallback: Show results inline if assessment_id is missing
      console.warn('[NAVIGATION] No assessment_id found, showing results inline')
      currentStep.value = 2
    }

  } catch (error) {
    ElMessage.error('Failed to process competency assessment results')
    console.error('Assessment completion error:', error)
  } finally {
    loading.value = false
  }
}

const completePhase = async () => {
  try {
    loading.value = true

    // Store phase data for next phase
    const phaseData = {
      selectedRole: selectedRoleDetails.value,
      jobDescription: jobForm.value,
      derikAnalysis: derikAnalysis.value,
      competencyAssessment: competencyResponse.value,
      generatedObjectives: generatedObjectives.value
    }

    // Store in localStorage for now
    localStorage.setItem('se-qpt-phase2-data', JSON.stringify(phaseData))

    ElMessage.success('Phase 2 completed successfully!')
    router.push('/app/phases/3')
  } catch (error) {
    ElMessage.error('Failed to complete Phase 2')
  } finally {
    loading.value = false
  }
}

// Helper function to get user-specific localStorage data
const getUserSpecificPhase1Data = () => {
  const userId = authStore.user?.id
  if (!userId) {
    console.warn('No user ID available for localStorage access')
    return {}
  }

  try {
    const userSpecificData = localStorage.getItem(`se-qpt-phase1-data-user-${userId}`)
    if (userSpecificData) {
      return JSON.parse(userSpecificData)
    }

    // Fallback to old key for backward compatibility (but don't use it for new users)
    const oldData = localStorage.getItem('se-qpt-phase1-data')
    if (oldData) {
      console.warn('Using legacy localStorage key - data may not be user-specific')
      return JSON.parse(oldData)
    }
  } catch (error) {
    console.error('Error reading Phase 1 data from localStorage:', error)
  }

  return {}
}

// New methods for enhanced flow
const getQualificationArchetype = () => {
  // Get qualification archetype from Phase 1 data
  const phase1Data = getUserSpecificPhase1Data()
  return phase1Data.selectedArchetype || {
    name: 'Common Basic Understanding',
    customization_level: 'low',
    characteristics: {
      uses_standardized: true,
      uses_company_specific: false,
      learning_style: 'standardized'
    }
  }
}

const isHighCustomizationArchetype = () => {
  const archetype = getQualificationArchetype()

  // Updated SE-QPT logic: Check for 90% customization level (high maturity)
  if (archetype.customization_level === '90%') {
    return true
  }

  // Backward compatibility: Check for legacy 'high' level
  if (archetype.customization_level === 'high') {
    return true
  }

  // Check for dual selection (low maturity) - should use basic context (Q6)
  if (archetype.isDual || archetype.customization_level === '10%') {
    return false
  }

  // Legacy archetype name-based check for backward compatibility
  const highCustomizationArchetypes = ['Continuous Support', 'Needs-based Project-oriented Training']
  return highCustomizationArchetypes.includes(archetype.name) ||
         highCustomizationArchetypes.includes(archetype.primary)
}

const getContextStepTitle = () => {
  const archetype = getQualificationArchetype()

  if (isHighCustomizationArchetype()) {
    return 'Company Context (Q5) - Extended PMT Data Collection (90% Customization)'
  } else if (archetype.isDual) {
    return 'Company Context (Q6) - Basic Information for Dual Archetype (10% Customization)'
  } else {
    return 'Company Context (Q6) - Basic Company Information'
  }
}

const getContextStepDescription = () => {
  const archetype = getQualificationArchetype()

  if (isHighCustomizationArchetype()) {
    return 'Provide detailed Process, Methods, and Tools information for highly customized learning objectives (90% company-specific)'
  } else if (archetype.isDual) {
    return `Provide basic company information for dual archetype processing: ${archetype.primary} + ${archetype.secondary} (10% customization each)`
  } else {
    return 'Provide basic company information for standardized learning objectives'
  }
}

const onJobContextSubmitted = async (contextData) => {
  try {
    loading.value = true

    // Store the job context data
    jobContextData.value = contextData

    ElMessage.success('Company context captured successfully!')

    // Move to RAG objectives generation
    currentStep.value = 4

    // Generate enhanced learning objectives
    await generateObjectives()

  } catch (error) {
    ElMessage.error('Failed to process company context')
    console.error('Job context error:', error)
  } finally {
    loading.value = false
  }
}

const onBasicContextSubmitted = async (contextData) => {
  try {
    loading.value = true

    // Transform basic context data to match expected format
    const transformedData = {
      contextType: 'basic',
      company_info: {
        name: contextData.basicContext.companyName,
        industry: contextData.basicContext.industryDomain,
        size: contextData.basicContext.organizationSize
      },
      basic_context: contextData.basicContext,
      archetype: getQualificationArchetype()
    }

    // Store the basic context data
    jobContextData.value = transformedData

    ElMessage.success('Basic company context captured successfully!')

    // Move to RAG objectives generation
    currentStep.value = 4

    // Generate standardized learning objectives
    await generateObjectives()

  } catch (error) {
    ElMessage.error('Failed to process basic company context')
    console.error('Basic context error:', error)
  } finally {
    loading.value = false
  }
}

// Lifecycle
onMounted(async () => {
  await loadRoles()

  // Load qualification archetype from Phase 1
  qualificationArchetype.value = getQualificationArchetype()
})
</script>

<style scoped>
.phase-two {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.phase-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  padding: 24px;
  background: linear-gradient(135deg, #67c23a 0%, #529b2e 100%);
  border-radius: 12px;
  color: white;
}

.phase-indicator {
  display: flex;
  align-items: center;
  gap: 24px;
}

.phase-number {
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.2);
  border: 3px solid rgba(255, 255, 255, 0.4);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 700;
  color: white;
}

.phase-title h1 {
  margin: 0 0 8px 0;
  font-size: 2rem;
  font-weight: 600;
}

.phase-title p {
  margin: 0;
  opacity: 0.9;
  font-size: 1.1rem;
}

.phase-progress {
  text-align: right;
  min-width: 200px;
}

.progress-text {
  display: block;
  margin-top: 8px;
  font-weight: 500;
}

.phase-steps {
  margin-bottom: 32px;
}

.step-card {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.step-actions {
  display: flex;
  gap: 16px;
  justify-content: flex-end;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e9ecef;
}

/* Assessment Configuration Styles */
.assessment-configuration {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.context-selection h4,
.pathway-selection h4 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-weight: 600;
  font-size: 1.1rem;
}

.context-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px;
  text-align: center;
}

.context-option span {
  font-weight: 500;
  color: #2c3e50;
}

.context-option p {
  margin: 0;
  font-size: 12px;
  color: #6c757d;
}

.pathway-options {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin-top: 20px;
}

.pathway-card {
  position: relative;
  padding: 24px;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
  background: white;
}

.pathway-card:hover {
  border-color: #67c23a;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.pathway-card.selected {
  border-color: #67c23a;
  background: #f0f9f2;
}

.pathway-card .el-icon {
  color: #67c23a;
  margin-bottom: 16px;
}

.pathway-card h5 {
  margin: 0 0 12px 0;
  color: #2c3e50;
  font-weight: 600;
  font-size: 1.1rem;
}

.pathway-card p {
  margin: 0 0 16px 0;
  color: #6c757d;
  font-size: 14px;
  line-height: 1.5;
}

.pathway-card ul {
  margin: 0;
  padding: 0;
  list-style: none;
  text-align: left;
}

.pathway-card li {
  position: relative;
  padding-left: 20px;
  margin-bottom: 8px;
  font-size: 13px;
  color: #6c757d;
}

.pathway-card li::before {
  content: "✓";
  position: absolute;
  left: 0;
  color: #67c23a;
  font-weight: bold;
}

/* Task Input Styles */
.task-input-section {
  max-width: 800px;
  margin: 0 auto;
}

.task-intro {
  margin-bottom: 32px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  text-align: center;
}

.task-analysis {
  margin-top: 24px;
}

.full-competency-intro {
  text-align: center;
  max-width: 600px;
  margin: 0 auto;
}

.intro-content {
  padding: 40px 20px;
}

.intro-icon {
  color: #67c23a;
  margin-bottom: 24px;
}

.intro-content h4 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-size: 1.3rem;
}

.intro-content p {
  margin: 0 0 20px 0;
  color: #6c757d;
  line-height: 1.6;
}

.intro-content ul {
  text-align: left;
  margin: 0 0 24px 0;
  padding-left: 20px;
}

.intro-content li {
  margin-bottom: 8px;
  color: #6c757d;
}

.selected-roles-summary {
  margin-top: 24px;
}

/* Role Selection Styles */
.selection-intro {
  margin-bottom: 32px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.roles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.role-card {
  position: relative;
  padding: 24px;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  background: white;
}

.role-card:hover {
  border-color: #67c23a;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.role-card.selected {
  border-color: #67c23a;
  background: #f0f9f2;
  position: relative;
}

.role-card.selected::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border: 2px solid #67c23a;
  border-radius: 12px;
  pointer-events: none;
  box-shadow: 0 0 0 2px rgba(103, 194, 58, 0.2);
}

.role-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.role-name {
  margin: 0;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.role-description {
  margin: 0 0 16px 0;
  color: #6c757d;
  line-height: 1.5;
}

.role-focus {
  margin-bottom: 16px;
  font-size: 0.9rem;
}

.role-responsibilities ul {
  margin: 8px 0 0 0;
  padding-left: 20px;
  color: #6c757d;
}

.role-responsibilities li {
  margin-bottom: 4px;
  font-size: 0.9rem;
}

.selection-indicator {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 32px;
  height: 32px;
  background: #67c23a;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

/* Competency Requirements */
.competency-requirements {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.competency-requirement {
  padding: 16px;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  background: #f8f9fa;
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
}

.required-level {
  font-size: 0.9rem;
  color: #6c757d;
}

/* Job Description Styles */
.description-intro {
  margin-bottom: 24px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.derik-analysis {
  margin-top: 24px;
}

.analysis-results {
  margin-top: 16px;
}

.analysis-section {
  margin-bottom: 16px;
}

.analysis-section h5 {
  margin: 0 0 8px 0;
  font-weight: 600;
  color: #2c3e50;
}

.process-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

/* Competency Assessment Styles */
.assessment-intro {
  margin-bottom: 32px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.assessment-progress {
  display: flex;
  align-items: center;
  gap: 16px;
}

.category-section {
  margin-bottom: 40px;
}

.category-title {
  margin: 0 0 24px 0;
  color: #2c3e50;
  font-size: 1.3rem;
  font-weight: 600;
  padding-bottom: 12px;
  border-bottom: 2px solid #e9ecef;
}

.competency-item {
  margin-bottom: 32px;
  padding: 24px;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  background: white;
}

.competency-item.high-priority {
  border-color: #e6a23c;
  background: #fdf6ec;
}

.competency-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.competency-info {
  flex: 1;
  margin-right: 24px;
}

.competency-name {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
  display: flex;
  align-items: center;
  gap: 12px;
}

.competency-description {
  margin: 0;
  color: #6c757d;
  line-height: 1.5;
}

.competency-rating {
  text-align: center;
  min-width: 200px;
}

.rating-labels {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.8rem;
  color: #6c757d;
}

.competency-indicators {
  margin-top: 16px;
}

.competency-indicators h6 {
  margin: 0 0 8px 0;
  font-weight: 600;
  color: #2c3e50;
  font-size: 0.9rem;
}

.indicators-list {
  margin: 0;
  padding-left: 20px;
  color: #6c757d;
}

.indicators-list li {
  margin-bottom: 4px;
  font-size: 0.85rem;
}

.gap-indicator {
  margin-top: 12px;
}

.gap-bar {
  padding: 8px 12px;
  border-radius: 6px;
  text-align: center;
  font-size: 0.8rem;
  font-weight: 500;
}

.gap-bar.no-gap {
  background: #f0f9f2;
  color: #67c23a;
}

.gap-bar.small-gap {
  background: #fdf6ec;
  color: #e6a23c;
}

.gap-bar.medium-gap {
  background: #fef0f0;
  color: #f56c6c;
}

.gap-bar.large-gap {
  background: #f5f5f5;
  color: #909399;
}

/* Assessment Summary */
.summary-stats {
  padding: 20px;
}

.stat-item {
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 2rem;
  font-weight: 700;
  color: #67c23a;
  margin-bottom: 4px;
}

.stat-label {
  color: #6c757d;
  font-size: 0.9rem;
}

/* Objectives Generation Styles */
.generation-loading {
  text-align: center;
  padding: 60px 20px;
}

.loading-spinner {
  color: #67c23a;
  margin-bottom: 24px;
  animation: spin 1s linear infinite;
}

.generation-loading h4 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-size: 1.3rem;
}

.generation-loading p {
  margin: 0 0 32px 0;
  color: #6c757d;
}

.generation-steps {
  display: flex;
  justify-content: center;
  gap: 32px;
  flex-wrap: wrap;
}

.generation-step {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px;
  border-radius: 8px;
  opacity: 0.3;
  transition: opacity 0.3s ease;
}

.generation-step.active {
  opacity: 1;
  background: #f0f9f2;
  color: #67c23a;
}

.generation-step i {
  font-size: 24px;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.objectives-results {
  margin-top: 24px;
}

.results-summary {
  margin-bottom: 24px;
}

.objectives-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 32px;
}

.objective-item {
  padding: 24px;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  background: white;
}

.objective-item.high-quality {
  border-color: #67c23a;
  background: #f0f9f2;
}

.objective-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.objective-meta {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.objective-actions {
  display: flex;
  gap: 8px;
}

.objective-content {
  margin-bottom: 16px;
}

.objective-text {
  margin: 0;
  font-size: 1rem;
  line-height: 1.6;
  color: #2c3e50;
}

.objective-details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
  padding-top: 16px;
  border-top: 1px solid #e9ecef;
}

.detail-row {
  font-size: 0.9rem;
  color: #6c757d;
}

.detail-row strong {
  color: #2c3e50;
}

.add-objective-section {
  margin-top: 32px;
}

.no-objectives {
  text-align: center;
  padding: 60px 20px;
  color: #6c757d;
}

.empty-icon {
  color: #c0c4cc;
  margin-bottom: 16px;
}

/* Review Styles */
.results-review {
  margin-bottom: 32px;
}

.review-section {
  margin-bottom: 32px;
}

.review-section h4 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-weight: 600;
  font-size: 1.1rem;
  padding-bottom: 8px;
  border-bottom: 2px solid #e9ecef;
}

.role-summary h5 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-weight: 600;
}

.role-summary p {
  margin: 0 0 12px 0;
  color: #6c757d;
}

.summary-stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.summary-stat {
  text-align: center;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.objectives-overview {
  display: flex;
  justify-content: space-around;
  margin-bottom: 24px;
}

.overview-stat {
  text-align: center;
}

.top-objectives h5 {
  margin: 0 0 16px 0;
  color: #2c3e50;
  font-weight: 600;
}

.top-objective {
  margin-bottom: 12px;
}

.objective-preview {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
}

.objective-text-preview {
  flex: 1;
  font-size: 0.9rem;
  color: #2c3e50;
}

.ai-analysis-summary {
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.analysis-item h5 {
  margin: 0 0 12px 0;
  color: #2c3e50;
  font-weight: 600;
}

.process-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.completion-message {
  margin-bottom: 32px;
}

.assessment-summary {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.assessment-status {
  display: flex;
  justify-content: center;
}

.response-details {
  background: #f8f9fa;
  padding: 16px;
  border-radius: 6px;
  border: 1px solid #e9ecef;
}

.response-details p {
  margin: 8px 0;
  font-size: 14px;
}

.response-details p:last-child {
  margin-bottom: 0;
}

/* New components styles */
.no-results-message {
  text-align: center;
  padding: 40px 20px;
}

.no-results-message .step-actions {
  margin-top: 24px;
}

@media (max-width: 768px) {
  .phase-two {
    padding: 16px;
  }

  .phase-header {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .phase-indicator {
    flex-direction: column;
    text-align: center;
    gap: 16px;
  }

  .phase-title h1 {
    font-size: 1.5rem;
  }

  .roles-grid {
    grid-template-columns: 1fr;
  }

  .competency-header {
    flex-direction: column;
    gap: 16px;
  }

  .competency-rating {
    min-width: auto;
  }

  .generation-steps {
    flex-direction: column;
    gap: 16px;
  }

  .summary-stats-grid {
    grid-template-columns: 1fr;
  }

  .objectives-overview {
    flex-direction: column;
    gap: 16px;
  }
}

.context-subtitle {
  margin: 8px 0 0 0;
  color: #606266;
  font-size: 14px;
  font-weight: 400;
  text-align: center;
}
</style>