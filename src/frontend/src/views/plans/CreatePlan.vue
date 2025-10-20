<template>
  <div class="create-plan">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Plus /></el-icon> Create Qualification Plan</h1>
        <p>Generate a personalized qualification plan based on your competency assessment</p>
      </div>
      <div class="header-actions">
        <el-button @click="$router.push('/app/plans')">
          <el-icon><ArrowLeft /></el-icon>
          Back to Plans
        </el-button>
      </div>
    </div>

    <div class="create-container">
      <div class="create-steps">
        <el-steps :active="currentStep" finish-status="success" align-center>
          <el-step title="Assessment" description="Complete competency assessment"></el-step>
          <el-step title="Archetype" description="Select role archetype"></el-step>
          <el-step title="Preferences" description="Set learning preferences"></el-step>
          <el-step title="Generation" description="Generate qualification plan"></el-step>
        </el-steps>
      </div>

      <div class="step-content">
        <!-- Step 1: Assessment -->
        <el-card v-if="currentStep === 0" class="step-card">
          <h2><el-icon><DocumentChecked /></el-icon> Competency Assessment</h2>
          <p>Before creating a qualification plan, you need to complete a competency assessment.</p>

          <div class="assessment-status">
            <div class="status-item">
              <el-icon size="20"><CircleCheck /></el-icon>
              <span>Phase 1: Maturity Assessment</span>
              <el-tag type="success">Completed</el-tag>
            </div>
            <div class="status-item">
              <el-icon size="20"><CircleCheck /></el-icon>
              <span>Phase 2: Competency Assessment</span>
              <el-tag type="success">Completed</el-tag>
            </div>
          </div>

          <div class="step-actions">
            <el-button type="primary" @click="nextStep">
              Continue to Archetype Selection
            </el-button>
            <el-button @click="$router.push('/app/assessments')">
              View Assessment Results
            </el-button>
          </div>
        </el-card>

        <!-- Step 2: Archetype Selection -->
        <el-card v-if="currentStep === 1" class="step-card">
          <h2><el-icon><User /></el-icon> Role Archetype Selection</h2>
          <p>Select the role archetype that best matches your career goals.</p>

          <div class="archetype-grid">
            <div
              v-for="archetype in archetypes"
              :key="archetype.id"
              class="archetype-card"
              :class="{ active: selectedArchetype === archetype.id }"
              @click="selectedArchetype = archetype.id"
            >
              <div class="archetype-icon">
                <el-icon size="32">
                  <component :is="archetype.icon" />
                </el-icon>
              </div>
              <h3>{{ archetype.name }}</h3>
              <p>{{ archetype.description }}</p>
              <div class="archetype-skills">
                <el-tag v-for="skill in archetype.keySkills" :key="skill" size="small">
                  {{ skill }}
                </el-tag>
              </div>
            </div>
          </div>

          <div class="step-actions">
            <el-button @click="previousStep">Previous</el-button>
            <el-button type="primary" @click="nextStep" :disabled="!selectedArchetype">
              Continue to Preferences
            </el-button>
          </div>
        </el-card>

        <!-- Step 3: Learning Preferences -->
        <el-card v-if="currentStep === 2" class="step-card">
          <h2><el-icon><Setting /></el-icon> Learning Preferences</h2>
          <p>Customize your qualification plan based on your learning preferences and constraints.</p>

          <div class="preferences-form">
            <el-form :model="preferences" label-width="180px">
              <el-form-item label="Learning Duration">
                <el-select v-model="preferences.duration" placeholder="Select duration">
                  <el-option label="3-6 months" value="short"></el-option>
                  <el-option label="6-12 months" value="medium"></el-option>
                  <el-option label="12+ months" value="long"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Weekly Time Commitment">
                <el-select v-model="preferences.timeCommitment" placeholder="Select time commitment">
                  <el-option label="5-10 hours/week" value="light"></el-option>
                  <el-option label="10-20 hours/week" value="moderate"></el-option>
                  <el-option label="20+ hours/week" value="intensive"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Learning Style">
                <el-checkbox-group v-model="preferences.learningStyle">
                  <el-checkbox label="theoretical">Theoretical Foundations</el-checkbox>
                  <el-checkbox label="practical">Hands-on Practice</el-checkbox>
                  <el-checkbox label="projects">Project-based Learning</el-checkbox>
                  <el-checkbox label="certification">Certification Prep</el-checkbox>
                </el-checkbox-group>
              </el-form-item>

              <el-form-item label="Focus Areas">
                <el-checkbox-group v-model="preferences.focusAreas">
                  <el-checkbox label="requirements">Requirements Engineering</el-checkbox>
                  <el-checkbox label="architecture">System Architecture</el-checkbox>
                  <el-checkbox label="verification">Verification & Validation</el-checkbox>
                  <el-checkbox label="management">Program Management</el-checkbox>
                </el-checkbox-group>
              </el-form-item>
            </el-form>
          </div>

          <div class="step-actions">
            <el-button @click="previousStep">Previous</el-button>
            <el-button type="primary" @click="nextStep">
              Generate Plan
            </el-button>
          </div>
        </el-card>

        <!-- Step 4: Plan Generation -->
        <el-card v-if="currentStep === 3" class="step-card">
          <div class="generation-content">
            <div v-if="generating" class="generating">
              <el-icon size="64" class="loading-icon"><Loading /></el-icon>
              <h2>Generating Your Qualification Plan</h2>
              <p>AI is analyzing your assessment results and preferences to create a personalized plan...</p>
              <el-progress :percentage="generationProgress" :stroke-width="8" />
            </div>

            <div v-else class="generation-complete">
              <el-icon size="64" class="success-icon"><SuccessFilled /></el-icon>
              <h2>Qualification Plan Generated!</h2>
              <p>Your personalized qualification plan has been created successfully.</p>

              <div class="plan-summary">
                <div class="summary-item">
                  <strong>{{ generatedPlan.modules }}</strong> Learning Modules
                </div>
                <div class="summary-item">
                  <strong>{{ generatedPlan.duration }}</strong> weeks duration
                </div>
                <div class="summary-item">
                  <strong>{{ generatedPlan.competencies }}</strong> Competencies covered
                </div>
              </div>

              <div class="step-actions">
                <el-button type="primary" @click="viewGeneratedPlan">
                  View Your Plan
                </el-button>
                <el-button @click="startPlan">
                  Start Learning
                </el-button>
              </div>
            </div>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  Plus, ArrowLeft, DocumentChecked, CircleCheck, User, Setting,
  Loading, SuccessFilled, Cpu, Management, Tools
} from '@element-plus/icons-vue'

const router = useRouter()

const currentStep = ref(0)
const selectedArchetype = ref(null)
const generating = ref(false)
const generationProgress = ref(0)

const preferences = ref({
  duration: '',
  timeCommitment: '',
  learningStyle: [],
  focusAreas: []
})

const archetypes = ref([
  {
    id: 'architect',
    name: 'System Architect',
    description: 'Focus on system design, architecture patterns, and technical leadership',
    icon: 'Cpu',
    keySkills: ['Architecture Design', 'Technical Leadership', 'Integration']
  },
  {
    id: 'requirements',
    name: 'Requirements Engineer',
    description: 'Specialize in requirements analysis, elicitation, and management',
    icon: 'Management',
    keySkills: ['Requirements Analysis', 'Stakeholder Management', 'Traceability']
  },
  {
    id: 'verification',
    name: 'V&V Engineer',
    description: 'Expert in verification, validation, and quality assurance',
    icon: 'Tools',
    keySkills: ['Testing Strategy', 'Quality Assurance', 'Risk Management']
  }
])

const generatedPlan = ref({
  modules: 8,
  duration: 16,
  competencies: 12
})

const nextStep = () => {
  if (currentStep.value < 3) {
    currentStep.value++
    if (currentStep.value === 3) {
      generatePlan()
    }
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const generatePlan = async () => {
  generating.value = true
  generationProgress.value = 0

  // Simulate plan generation process
  const interval = setInterval(() => {
    generationProgress.value += 10
    if (generationProgress.value >= 100) {
      clearInterval(interval)
      setTimeout(() => {
        generating.value = false
      }, 1000)
    }
  }, 300)
}

const viewGeneratedPlan = () => {
  // Navigate to the generated plan (simulate with plan ID)
  router.push('/app/plans/new-plan-123')
}

const startPlan = () => {
  // Navigate to the first module in the plan
  router.push('/app/plans/new-plan-123')
}
</script>

<style scoped>
.create-plan {
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

.create-container {
  max-width: 1000px;
  margin: 0 auto;
}

.create-steps {
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

.assessment-status {
  margin: 24px 0;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  padding: 12px;
  background: #f0f9ff;
  border-radius: 6px;
}

.archetype-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin: 24px 0;
}

.archetype-card {
  padding: 24px;
  border: 2px solid #e4e7ed;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
}

.archetype-card:hover {
  border-color: #409eff;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.1);
}

.archetype-card.active {
  border-color: #409eff;
  background: #f0f9ff;
}

.archetype-icon {
  color: #409eff;
  margin-bottom: 16px;
}

.archetype-card h3 {
  margin: 0 0 12px 0;
  color: #303133;
}

.archetype-card p {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.archetype-skills {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}

.preferences-form {
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

.generation-content h2 {
  color: #303133;
  margin-bottom: 12px;
}

.generation-content p {
  color: #606266;
  margin-bottom: 24px;
  font-size: 16px;
}

.plan-summary {
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

.step-actions {
  margin-top: 32px;
  text-align: center;
}

.step-actions .el-button {
  margin: 0 8px;
}
</style>