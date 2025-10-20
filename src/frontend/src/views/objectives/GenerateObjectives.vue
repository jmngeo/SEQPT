<template>
  <div class="generate-objectives">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><MagicStick /></el-icon> Generate Learning Objectives</h1>
        <p>Create personalized learning objectives based on your competency assessment and career goals</p>
      </div>
      <div class="header-actions">
        <el-button @click="$router.push('/app/objectives')">
          <el-icon><ArrowLeft /></el-icon>
          Back to Objectives
        </el-button>
      </div>
    </div>

    <div class="generation-container">
      <!-- Generation Steps -->
      <div class="generation-steps">
        <el-steps :active="currentStep" finish-status="success" align-center>
          <el-step title="Assessment" description="Review competency results"></el-step>
          <el-step title="Goals" description="Define learning goals"></el-step>
          <el-step title="Preferences" description="Set learning preferences"></el-step>
          <el-step title="Generation" description="AI generates objectives"></el-step>
          <el-step title="Review" description="Review and customize"></el-step>
        </el-steps>
      </div>

      <!-- Step Content -->
      <div class="step-content">
        <!-- Step 1: Assessment Review -->
        <el-card v-if="currentStep === 0" class="step-card">
          <h2><el-icon><DocumentChecked /></el-icon> Competency Assessment Review</h2>
          <p>Review your competency assessment results to identify learning opportunities.</p>

          <div class="competency-results">
            <div
              v-for="competency in competencyResults"
              :key="competency.id"
              class="competency-item"
            >
              <div class="competency-info">
                <h3>{{ competency.name }}</h3>
                <p>{{ competency.description }}</p>
                <div class="competency-level">
                  Current Level: <strong>{{ competency.currentLevel }}/5</strong>
                  <span class="gap-indicator" v-if="competency.gap > 0">
                    (Gap: {{ competency.gap }} levels)
                  </span>
                </div>
              </div>
              <div class="competency-progress">
                <el-progress
                  type="circle"
                  :percentage="(competency.currentLevel / 5) * 100"
                  :width="80"
                  :stroke-width="8"
                  :color="getCompetencyColor(competency.currentLevel)"
                />
              </div>
            </div>
          </div>

          <div class="step-actions">
            <el-button type="primary" @click="nextStep">
              Continue to Goal Setting
            </el-button>
          </div>
        </el-card>

        <!-- Step 2: Learning Goals -->
        <el-card v-if="currentStep === 1" class="step-card">
          <h2><el-icon><Aim /></el-icon> Define Learning Goals</h2>
          <p>Specify your learning goals and target competency levels.</p>

          <div class="goals-form">
            <el-form :model="learningGoals" label-width="200px">
              <el-form-item label="Primary Career Goal">
                <el-select v-model="learningGoals.careerGoal" placeholder="Select your career goal">
                  <el-option label="Systems Architect" value="architect"></el-option>
                  <el-option label="Requirements Engineer" value="requirements"></el-option>
                  <el-option label="V&V Engineer" value="verification"></el-option>
                  <el-option label="Program Manager" value="management"></el-option>
                  <el-option label="Technical Lead" value="technical_lead"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Time Frame">
                <el-select v-model="learningGoals.timeFrame" placeholder="Select time frame">
                  <el-option label="3 months" value="3"></el-option>
                  <el-option label="6 months" value="6"></el-option>
                  <el-option label="12 months" value="12"></el-option>
                  <el-option label="18+ months" value="18"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Focus Areas">
                <el-checkbox-group v-model="learningGoals.focusAreas">
                  <el-checkbox label="systems_thinking">Systems Thinking</el-checkbox>
                  <el-checkbox label="requirements">Requirements Engineering</el-checkbox>
                  <el-checkbox label="architecture">System Architecture</el-checkbox>
                  <el-checkbox label="verification">Verification & Validation</el-checkbox>
                  <el-checkbox label="integration">System Integration</el-checkbox>
                  <el-checkbox label="management">Program Management</el-checkbox>
                </el-checkbox-group>
              </el-form-item>

              <el-form-item label="Target Competency Level">
                <el-radio-group v-model="learningGoals.targetLevel">
                  <el-radio :label="3">Intermediate (Level 3)</el-radio>
                  <el-radio :label="4">Advanced (Level 4)</el-radio>
                  <el-radio :label="5">Expert (Level 5)</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Specific Goals">
                <el-input
                  v-model="learningGoals.specificGoals"
                  type="textarea"
                  :rows="4"
                  placeholder="Describe any specific learning goals or objectives you have..."
                />
              </el-form-item>
            </el-form>
          </div>

          <div class="step-actions">
            <el-button @click="previousStep">Previous</el-button>
            <el-button type="primary" @click="nextStep" :disabled="!learningGoals.careerGoal">
              Continue to Preferences
            </el-button>
          </div>
        </el-card>

        <!-- Step 3: Learning Preferences -->
        <el-card v-if="currentStep === 2" class="step-card">
          <h2><el-icon><Setting /></el-icon> Learning Preferences</h2>
          <p>Customize how your learning objectives will be structured and delivered.</p>

          <div class="preferences-form">
            <el-form :model="preferences" label-width="200px">
              <el-form-item label="Learning Style">
                <el-checkbox-group v-model="preferences.learningStyle">
                  <el-checkbox label="theoretical">Theoretical Learning</el-checkbox>
                  <el-checkbox label="practical">Hands-on Practice</el-checkbox>
                  <el-checkbox label="project_based">Project-based</el-checkbox>
                  <el-checkbox label="collaborative">Collaborative Learning</el-checkbox>
                </el-checkbox-group>
              </el-form-item>

              <el-form-item label="Objective Granularity">
                <el-radio-group v-model="preferences.granularity">
                  <el-radio label="high">High-level objectives (fewer, broader)</el-radio>
                  <el-radio label="medium">Medium granularity (balanced)</el-radio>
                  <el-radio label="detailed">Detailed objectives (many, specific)</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Weekly Time Commitment">
                <el-select v-model="preferences.timeCommitment" placeholder="Select time commitment">
                  <el-option label="5-10 hours/week" value="light"></el-option>
                  <el-option label="10-20 hours/week" value="moderate"></el-option>
                  <el-option label="20+ hours/week" value="intensive"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Assessment Preferences">
                <el-checkbox-group v-model="preferences.assessmentTypes">
                  <el-checkbox label="quizzes">Regular Quizzes</el-checkbox>
                  <el-checkbox label="projects">Project Assignments</el-checkbox>
                  <el-checkbox label="peer_review">Peer Reviews</el-checkbox>
                  <el-checkbox label="self_assessment">Self-Assessment</el-checkbox>
                </el-checkbox-group>
              </el-form-item>

              <el-form-item label="Resource Types">
                <el-checkbox-group v-model="preferences.resourceTypes">
                  <el-checkbox label="readings">Technical Reading</el-checkbox>
                  <el-checkbox label="videos">Video Content</el-checkbox>
                  <el-checkbox label="workshops">Interactive Workshops</el-checkbox>
                  <el-checkbox label="case_studies">Case Studies</el-checkbox>
                </el-checkbox-group>
              </el-form-item>
            </el-form>
          </div>

          <div class="step-actions">
            <el-button @click="previousStep">Previous</el-button>
            <el-button type="primary" @click="nextStep">
              Generate Objectives
            </el-button>
          </div>
        </el-card>

        <!-- Step 4: AI Generation -->
        <el-card v-if="currentStep === 3" class="step-card">
          <div class="generation-content">
            <div v-if="generating" class="generating">
              <el-icon size="64" class="loading-icon"><Loading /></el-icon>
              <h2>AI is Generating Your Learning Objectives</h2>
              <p>Analyzing your competency gaps, goals, and preferences to create personalized objectives...</p>

              <div class="generation-steps-detail">
                <div class="generation-step" :class="{ active: generationStep >= 1 }">
                  <el-icon><Check /></el-icon>
                  <span>Analyzing competency gaps</span>
                </div>
                <div class="generation-step" :class="{ active: generationStep >= 2 }">
                  <el-icon><Check /></el-icon>
                  <span>Mapping to learning resources</span>
                </div>
                <div class="generation-step" :class="{ active: generationStep >= 3 }">
                  <el-icon><Check /></el-icon>
                  <span>Creating objective structure</span>
                </div>
                <div class="generation-step" :class="{ active: generationStep >= 4 }">
                  <el-icon><Check /></el-icon>
                  <span>Optimizing learning path</span>
                </div>
              </div>

              <el-progress :percentage="generationProgress" :stroke-width="8" />
            </div>

            <div v-else class="generation-complete">
              <el-icon size="64" class="success-icon"><SuccessFilled /></el-icon>
              <h2>Learning Objectives Generated!</h2>
              <p>{{ generatedObjectives.length }} personalized learning objectives have been created for you.</p>

              <div class="generation-summary">
                <div class="summary-item">
                  <strong>{{ generatedObjectives.length }}</strong> Objectives
                </div>
                <div class="summary-item">
                  <strong>{{ estimatedWeeks }}</strong> weeks estimated
                </div>
                <div class="summary-item">
                  <strong>{{ totalHours }}</strong> hours total
                </div>
              </div>

              <div class="step-actions">
                <el-button type="primary" @click="nextStep">
                  Review Objectives
                </el-button>
              </div>
            </div>
          </div>
        </el-card>

        <!-- Step 5: Review Generated Objectives -->
        <el-card v-if="currentStep === 4" class="step-card">
          <h2><el-icon><View /></el-icon> Review Generated Objectives</h2>
          <p>Review and customize your generated learning objectives before saving them.</p>

          <div class="objectives-review">
            <div
              v-for="(objective, index) in generatedObjectives"
              :key="index"
              class="objective-preview"
            >
              <div class="objective-header">
                <el-checkbox v-model="objective.selected">
                  <h3>{{ objective.title }}</h3>
                </el-checkbox>
                <el-tag :type="getPriorityType(objective.priority)" size="small">
                  {{ objective.priority }} Priority
                </el-tag>
              </div>

              <p class="objective-description">{{ objective.description }}</p>

              <div class="objective-meta">
                <span><el-icon><Collection /></el-icon> {{ objective.competency }}</span>
                <span><el-icon><Clock /></el-icon> {{ objective.estimatedHours }}h</span>
                <span><el-icon><Calendar /></el-icon> {{ objective.duration }} weeks</span>
              </div>

              <div class="sub-objectives-preview" v-if="objective.subObjectives.length > 0">
                <h4>Sub-objectives:</h4>
                <ul>
                  <li v-for="subObj in objective.subObjectives" :key="subObj">{{ subObj }}</li>
                </ul>
              </div>
            </div>
          </div>

          <div class="step-actions">
            <el-button @click="previousStep">Previous</el-button>
            <el-button @click="regenerateObjectives">
              <el-icon><Refresh /></el-icon>
              Regenerate
            </el-button>
            <el-button type="primary" @click="saveObjectives">
              <el-icon><Check /></el-icon>
              Save Selected Objectives
            </el-button>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  MagicStick, ArrowLeft, DocumentChecked, Aim, Setting, Loading,
  SuccessFilled, View, Check, Collection, Clock, Calendar, Refresh
} from '@element-plus/icons-vue'

const router = useRouter()

const currentStep = ref(0)
const generating = ref(false)
const generationStep = ref(0)
const generationProgress = ref(0)

const competencyResults = ref([
  {
    id: 1,
    name: "Systems Thinking",
    description: "Holistic understanding of complex systems",
    currentLevel: 2,
    targetLevel: 4,
    gap: 2
  },
  {
    id: 2,
    name: "Requirements Engineering",
    description: "Requirements analysis and management",
    currentLevel: 3,
    targetLevel: 4,
    gap: 1
  },
  {
    id: 3,
    name: "System Architecture",
    description: "Architectural design and patterns",
    currentLevel: 1,
    targetLevel: 4,
    gap: 3
  },
  {
    id: 4,
    name: "Verification & Validation",
    description: "Testing and quality assurance",
    currentLevel: 2,
    targetLevel: 3,
    gap: 1
  }
])

const learningGoals = ref({
  careerGoal: '',
  timeFrame: '',
  focusAreas: [],
  targetLevel: 4,
  specificGoals: ''
})

const preferences = ref({
  learningStyle: [],
  granularity: 'medium',
  timeCommitment: '',
  assessmentTypes: [],
  resourceTypes: []
})

const generatedObjectives = ref([])

const estimatedWeeks = computed(() => {
  return Math.max(...generatedObjectives.value.map(obj => obj.duration || 0))
})

const totalHours = computed(() => {
  return generatedObjectives.value.reduce((total, obj) => total + (obj.estimatedHours || 0), 0)
})

const nextStep = () => {
  if (currentStep.value < 4) {
    currentStep.value++
    if (currentStep.value === 3) {
      generateObjectives()
    }
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const generateObjectives = async () => {
  generating.value = true
  generationStep.value = 0
  generationProgress.value = 0

  // Simulate AI generation process
  const steps = ['Analyzing competency gaps', 'Mapping to learning resources', 'Creating objective structure', 'Optimizing learning path']

  for (let i = 0; i < steps.length; i++) {
    setTimeout(() => {
      generationStep.value = i + 1
      generationProgress.value = ((i + 1) / steps.length) * 100

      if (i === steps.length - 1) {
        setTimeout(() => {
          generating.value = false
          populateGeneratedObjectives()
        }, 1000)
      }
    }, (i + 1) * 1500)
  }
}

const populateGeneratedObjectives = () => {
  generatedObjectives.value = [
    {
      title: "Master Systems Architecture Fundamentals",
      description: "Develop foundational understanding of system architecture principles and design patterns",
      priority: "high",
      competency: "System Architecture",
      estimatedHours: 24,
      duration: 6,
      selected: true,
      subObjectives: [
        "Study architectural patterns (MVC, Layered, Microservices)",
        "Practice architectural documentation",
        "Design simple system architectures",
        "Review case studies of successful architectures"
      ]
    },
    {
      title: "Advanced Requirements Engineering Techniques",
      description: "Enhance skills in requirements elicitation, analysis, and management",
      priority: "medium",
      competency: "Requirements Engineering",
      estimatedHours: 18,
      duration: 4,
      selected: true,
      subObjectives: [
        "Master stakeholder analysis techniques",
        "Practice requirements elicitation methods",
        "Learn requirements traceability management",
        "Study requirements validation approaches"
      ]
    },
    {
      title: "Systems Thinking and Complexity Management",
      description: "Develop holistic thinking approaches for complex systems",
      priority: "high",
      competency: "Systems Thinking",
      estimatedHours: 20,
      duration: 5,
      selected: true,
      subObjectives: [
        "Understand systems theory principles",
        "Practice systems modeling techniques",
        "Study emergent behavior in systems",
        "Apply systems thinking to real scenarios"
      ]
    },
    {
      title: "Verification and Validation Strategies",
      description: "Learn comprehensive V&V approaches and quality assurance methods",
      priority: "medium",
      competency: "Verification & Validation",
      estimatedHours: 22,
      duration: 6,
      selected: true,
      subObjectives: [
        "Study V&V standards and best practices",
        "Design comprehensive test strategies",
        "Implement quality gates and metrics",
        "Practice risk-based testing approaches"
      ]
    }
  ]
}

const regenerateObjectives = () => {
  currentStep.value = 3
  generateObjectives()
}

const saveObjectives = () => {
  const selectedObjectives = generatedObjectives.value.filter(obj => obj.selected)
  // Here you would typically save to the store/API
  router.push('/app/objectives')
}

const getCompetencyColor = (level) => {
  const colors = ['#f56c6c', '#e6a23c', '#409eff', '#67c23a', '#67c23a']
  return colors[level - 1] || '#f56c6c'
}

const getPriorityType = (priority) => {
  const priorityMap = {
    'high': 'danger',
    'medium': 'warning',
    'low': 'info'
  }
  return priorityMap[priority] || 'info'
}
</script>

<style scoped>
.generate-objectives {
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

.generation-container {
  max-width: 1000px;
  margin: 0 auto;
}

.generation-steps {
  margin-bottom: 32px;
}

.step-card {
  min-height: 500px;
}

.step-card h2 {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #303133;
  margin-bottom: 16px;
}

.competency-results {
  display: grid;
  gap: 16px;
  margin: 24px 0;
}

.competency-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #409eff;
}

.competency-info h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.competency-info p {
  margin: 0 0 8px 0;
  color: #606266;
}

.competency-level {
  font-size: 14px;
  color: #909399;
}

.gap-indicator {
  color: #f56c6c;
  font-weight: 600;
}

.goals-form, .preferences-form {
  margin: 24px 0;
}

.generation-content {
  text-align: center;
  padding: 60px 40px;
}

.loading-icon {
  color: #409eff;
  margin-bottom: 24px;
  animation: spin 2s linear infinite;
}

.success-icon {
  color: #67c23a;
  margin-bottom: 24px;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.generation-steps-detail {
  margin: 32px 0;
}

.generation-step {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  color: #909399;
  transition: color 0.3s ease;
}

.generation-step.active {
  color: #67c23a;
}

.generation-summary {
  display: flex;
  justify-content: center;
  gap: 40px;
  margin: 32px 0;
}

.summary-item {
  text-align: center;
  color: #606266;
}

.summary-item strong {
  display: block;
  font-size: 24px;
  color: #409eff;
  margin-bottom: 4px;
}

.objectives-review {
  margin: 24px 0;
}

.objective-preview {
  padding: 20px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  margin-bottom: 16px;
  background: white;
}

.objective-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.objective-header h3 {
  margin: 0;
  color: #303133;
}

.objective-description {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.objective-meta {
  display: flex;
  gap: 20px;
  margin-bottom: 16px;
  font-size: 14px;
  color: #909399;
}

.objective-meta span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.sub-objectives-preview h4 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 14px;
}

.sub-objectives-preview ul {
  margin: 0;
  padding-left: 20px;
  color: #606266;
}

.sub-objectives-preview li {
  margin-bottom: 4px;
}

.step-actions {
  margin-top: 32px;
  text-align: center;
}

.step-actions .el-button {
  margin: 0 8px;
}
</style>