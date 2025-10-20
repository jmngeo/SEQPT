<template>
  <div class="job-context-input">
    <div class="context-header">
      <h2 class="section-title">Company Context & Job Environment</h2>
      <p class="section-description">
        Provide details about your company's processes, methods, and tools to generate
        <strong>customized learning objectives</strong> aligned with your specific work environment.
      </p>
    </div>

    <!-- Phase 1 Archetype Display -->
    <el-card class="archetype-card" v-if="selectedArchetype">
      <template #header>
        <div class="archetype-header">
          <el-icon size="24" color="#409eff"><Trophy /></el-icon>
          <span>Selected Qualification Archetype</span>
        </div>
      </template>
      <div class="archetype-content">
        <el-tag type="primary" size="large">{{ selectedArchetype.name }}</el-tag>
        <p class="archetype-description">{{ selectedArchetype.description }}</p>
        <div class="archetype-note">
          <el-alert
            title="Learning Objectives Customization"
            :description="getArchetypeCustomizationNote()"
            type="info"
            show-icon
            :closable="false"
          />
        </div>
      </div>
    </el-card>

    <!-- PMT Input Form -->
    <el-form :model="contextForm" :rules="contextRules" ref="contextFormRef" label-width="200px">
      <!-- Company Information -->
      <el-card class="form-section">
        <template #header>
          <h3 class="section-heading">Company Information</h3>
        </template>

        <el-form-item label="Company Name" prop="companyName">
          <el-input
            v-model="contextForm.companyName"
            placeholder="Enter your company name"
            size="large"
          />
        </el-form-item>

        <el-form-item label="Industry Domain" prop="industryDomain">
          <el-select
            v-model="contextForm.industryDomain"
            placeholder="Select your industry domain"
            size="large"
            style="width: 100%"
          >
            <el-option
              v-for="industry in industryOptions"
              :key="industry.value"
              :label="industry.label"
              :value="industry.value"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="Organization Size" prop="organizationSize">
          <el-select
            v-model="contextForm.organizationSize"
            placeholder="Select organization size"
            size="large"
            style="width: 100%"
          >
            <el-option label="Startup (1-50 employees)" value="startup" />
            <el-option label="Small (51-200 employees)" value="small" />
            <el-option label="Medium (201-1000 employees)" value="medium" />
            <el-option label="Large (1001-5000 employees)" value="large" />
            <el-option label="Enterprise (5000+ employees)" value="enterprise" />
          </el-select>
        </el-form-item>
      </el-card>

      <!-- Process Information -->
      <el-card class="form-section">
        <template #header>
          <div class="section-header">
            <h3 class="section-heading">Processes (P)</h3>
            <p class="section-subtitle">Standard operating procedures and workflows</p>
          </div>
        </template>

        <el-form-item label="Development Process" prop="developmentProcess">
          <el-select
            v-model="contextForm.developmentProcess"
            placeholder="Select your development process"
            size="large"
            style="width: 100%"
            multiple
            collapse-tags
            collapse-tags-tooltip
          >
            <el-option label="Agile/Scrum" value="agile" />
            <el-option label="Waterfall" value="waterfall" />
            <el-option label="DevOps" value="devops" />
            <el-option label="V-Model" value="v-model" />
            <el-option label="Spiral" value="spiral" />
            <el-option label="Lean" value="lean" />
            <el-option label="SAFe" value="safe" />
            <el-option label="Custom/Hybrid" value="custom" />
          </el-select>
        </el-form-item>

        <el-form-item label="Quality Processes" prop="qualityProcesses">
          <el-input
            v-model="contextForm.qualityProcesses"
            type="textarea"
            :rows="3"
            placeholder="Describe your quality assurance processes, review procedures, testing protocols..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Compliance Standards" prop="complianceStandards">
          <el-select
            v-model="contextForm.complianceStandards"
            placeholder="Select applicable standards"
            size="large"
            style="width: 100%"
            multiple
            collapse-tags
            collapse-tags-tooltip
          >
            <el-option label="ISO 15288 (Systems Engineering)" value="iso15288" />
            <el-option label="ISO 9001 (Quality Management)" value="iso9001" />
            <el-option label="DO-178C (Avionics)" value="do178c" />
            <el-option label="IEC 61508 (Functional Safety)" value="iec61508" />
            <el-option label="CMMI" value="cmmi" />
            <el-option label="FDA (Medical Devices)" value="fda" />
            <el-option label="AUTOSAR (Automotive)" value="autosar" />
            <el-option label="None/Other" value="other" />
          </el-select>
        </el-form-item>
      </el-card>

      <!-- Methods Information -->
      <el-card class="form-section">
        <template #header>
          <div class="section-header">
            <h3 class="section-heading">Methods (M)</h3>
            <p class="section-subtitle">Engineering practices and methodologies</p>
          </div>
        </template>

        <el-form-item label="Design Methods" prop="designMethods">
          <el-checkbox-group v-model="contextForm.designMethods">
            <el-checkbox label="model-based" border>Model-Based Design</el-checkbox>
            <el-checkbox label="oop" border>Object-Oriented Design</el-checkbox>
            <el-checkbox label="functional" border>Functional Design</el-checkbox>
            <el-checkbox label="domain-driven" border>Domain-Driven Design</el-checkbox>
            <el-checkbox label="microservices" border>Microservices Architecture</el-checkbox>
            <el-checkbox label="service-oriented" border>Service-Oriented Architecture</el-checkbox>
          </el-checkbox-group>
        </el-form-item>

        <el-form-item label="Requirements Methods" prop="requirementsMethods">
          <el-input
            v-model="contextForm.requirementsMethods"
            type="textarea"
            :rows="3"
            placeholder="Describe your requirements gathering methods: user stories, use cases, interviews, workshops..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Testing Methods" prop="testingMethods">
          <el-checkbox-group v-model="contextForm.testingMethods">
            <el-checkbox label="unit" border>Unit Testing</el-checkbox>
            <el-checkbox label="integration" border>Integration Testing</el-checkbox>
            <el-checkbox label="system" border>System Testing</el-checkbox>
            <el-checkbox label="acceptance" border>Acceptance Testing</el-checkbox>
            <el-checkbox label="automated" border>Automated Testing</el-checkbox>
            <el-checkbox label="performance" border>Performance Testing</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-card>

      <!-- Tools Information -->
      <el-card class="form-section">
        <template #header>
          <div class="section-header">
            <h3 class="section-heading">Tools (T)</h3>
            <p class="section-subtitle">Software tools and platforms used in your organization</p>
          </div>
        </template>

        <el-form-item label="Development Tools" prop="developmentTools">
          <el-input
            v-model="contextForm.developmentTools"
            type="textarea"
            :rows="2"
            placeholder="e.g., Visual Studio, IntelliJ, Eclipse, MATLAB/Simulink..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Collaboration Tools" prop="collaborationTools">
          <el-input
            v-model="contextForm.collaborationTools"
            type="textarea"
            :rows="2"
            placeholder="e.g., Jira, Confluence, SharePoint, Slack, Microsoft Teams..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Modeling Tools" prop="modelingTools">
          <el-input
            v-model="contextForm.modelingTools"
            type="textarea"
            :rows="2"
            placeholder="e.g., Enterprise Architect, MagicDraw, Cameo, Visio, Lucidchart..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Testing Tools" prop="testingTools">
          <el-input
            v-model="contextForm.testingTools"
            type="textarea"
            :rows="2"
            placeholder="e.g., Selenium, Jest, PyTest, Jenkins, SonarQube..."
            size="large"
          />
        </el-form-item>
      </el-card>

      <!-- Additional Context -->
      <el-card class="form-section">
        <template #header>
          <div class="section-header">
            <h3 class="section-heading">Additional Context</h3>
            <p class="section-subtitle">Specific challenges or focus areas</p>
          </div>
        </template>

        <el-form-item label="Key Challenges" prop="keyChallenges">
          <el-input
            v-model="contextForm.keyChallenges"
            type="textarea"
            :rows="3"
            placeholder="Describe current challenges or areas where improvement is needed..."
            size="large"
          />
        </el-form-item>

        <el-form-item label="Learning Priorities" prop="learningPriorities">
          <el-checkbox-group v-model="contextForm.learningPriorities">
            <el-checkbox label="technical" border>Technical Skills</el-checkbox>
            <el-checkbox label="leadership" border>Leadership Development</el-checkbox>
            <el-checkbox label="communication" border>Communication Skills</el-checkbox>
            <el-checkbox label="process" border>Process Improvement</el-checkbox>
            <el-checkbox label="innovation" border>Innovation & Creativity</el-checkbox>
            <el-checkbox label="compliance" border>Compliance & Standards</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-card>
    </el-form>

    <!-- Actions -->
    <div class="actions">
      <el-button @click="$emit('back')" size="large">
        Previous
      </el-button>
      <el-button @click="saveAsDraft" size="large" type="info">
        <el-icon><Document /></el-icon>
        Save as Draft
      </el-button>
      <el-button
        type="primary"
        @click="proceedToObjectives"
        :disabled="!isFormValid"
        size="large"
      >
        Generate Customized Learning Objectives
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Trophy,
  Document
} from '@element-plus/icons-vue'

// Props
const props = defineProps({
  competencyResults: {
    type: Object,
    required: true
  },
  selectedArchetype: {
    type: Object,
    default: null
  }
})

// Emits
const emit = defineEmits(['back', 'continue'])

// State
const contextFormRef = ref()
const contextForm = ref({
  companyName: '',
  industryDomain: '',
  organizationSize: '',
  developmentProcess: [],
  qualityProcesses: '',
  complianceStandards: [],
  designMethods: [],
  requirementsMethods: '',
  testingMethods: [],
  developmentTools: '',
  collaborationTools: '',
  modelingTools: '',
  testingTools: '',
  keyChallenges: '',
  learningPriorities: []
})

// Form validation rules
const contextRules = {
  companyName: [
    { required: true, message: 'Company name is required', trigger: 'blur' }
  ],
  industryDomain: [
    { required: true, message: 'Please select industry domain', trigger: 'change' }
  ],
  organizationSize: [
    { required: true, message: 'Please select organization size', trigger: 'change' }
  ]
}

// Industry options
const industryOptions = [
  { label: 'Aerospace & Defense', value: 'aerospace' },
  { label: 'Automotive', value: 'automotive' },
  { label: 'Healthcare & Medical Devices', value: 'healthcare' },
  { label: 'Telecommunications', value: 'telecom' },
  { label: 'Energy & Utilities', value: 'energy' },
  { label: 'Manufacturing', value: 'manufacturing' },
  { label: 'Financial Services', value: 'financial' },
  { label: 'Technology & Software', value: 'technology' },
  { label: 'Government & Public Sector', value: 'government' },
  { label: 'Transportation', value: 'transportation' },
  { label: 'Consumer Electronics', value: 'electronics' },
  { label: 'Other', value: 'other' }
]

// Computed
const isFormValid = computed(() => {
  return contextForm.value.companyName &&
         contextForm.value.industryDomain &&
         contextForm.value.organizationSize
})

// Methods
const getArchetypeCustomizationNote = () => {
  if (!props.selectedArchetype) return ''

  const notes = {
    'Blended Learning': 'Learning objectives will combine standardized frameworks with company-specific practices',
    'Formal Training': 'Learning objectives will focus on industry standards and formal certification paths',
    'On-the-Job Learning': 'Learning objectives will emphasize practical, hands-on experiences within your company context',
    'Mentoring Program': 'Learning objectives will include mentorship opportunities and knowledge transfer activities',
    'Project-Based': 'Learning objectives will be aligned with real project scenarios and deliverables',
    'Continuous Learning': 'Learning objectives will focus on ongoing skill development and adaptation'
  }

  return notes[props.selectedArchetype.name] || 'Learning objectives will be customized based on your archetype selection'
}

const saveAsDraft = () => {
  // Save to localStorage for now
  localStorage.setItem('seqpt_job_context_draft', JSON.stringify(contextForm.value))
  ElMessage.success('Context saved as draft')
}

const loadDraft = () => {
  const draft = localStorage.getItem('seqpt_job_context_draft')
  if (draft) {
    try {
      const parsedDraft = JSON.parse(draft)
      contextForm.value = { ...contextForm.value, ...parsedDraft }
      ElMessage.info('Draft loaded')
    } catch (error) {
      console.error('Failed to load draft:', error)
    }
  }
}

const proceedToObjectives = async () => {
  try {
    const valid = await contextFormRef.value.validate()
    if (!valid) return

    const contextData = {
      company: {
        name: contextForm.value.companyName,
        industry: contextForm.value.industryDomain,
        size: contextForm.value.organizationSize
      },
      processes: {
        development: contextForm.value.developmentProcess,
        quality: contextForm.value.qualityProcesses,
        compliance: contextForm.value.complianceStandards
      },
      methods: {
        design: contextForm.value.designMethods,
        requirements: contextForm.value.requirementsMethods,
        testing: contextForm.value.testingMethods
      },
      tools: {
        development: contextForm.value.developmentTools,
        collaboration: contextForm.value.collaborationTools,
        modeling: contextForm.value.modelingTools,
        testing: contextForm.value.testingTools
      },
      additional: {
        challenges: contextForm.value.keyChallenges,
        priorities: contextForm.value.learningPriorities
      },
      archetype: props.selectedArchetype
    }

    emit('continue', {
      competencyResults: props.competencyResults,
      jobContext: contextData
    })

  } catch (error) {
    console.error('Form validation failed:', error)
  }
}

// Lifecycle
onMounted(() => {
  loadDraft()
})
</script>

<style scoped>
.job-context-input {
  max-width: 1000px;
  margin: 0 auto;
  padding: 20px;
}

.context-header {
  text-align: center;
  margin-bottom: 30px;
}

.section-title {
  font-size: 1.8rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
}

.section-description {
  color: #6c7b7f;
  margin-bottom: 20px;
  font-size: 1.1rem;
  line-height: 1.6;
}

.archetype-card {
  margin-bottom: 30px;
  border: 2px solid #409eff;
}

.archetype-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: #409eff;
}

.archetype-content {
  text-align: center;
}

.archetype-description {
  margin: 15px 0;
  color: #6c7b7f;
  font-style: italic;
}

.archetype-note {
  margin-top: 15px;
}

.form-section {
  margin-bottom: 30px;
}

.section-header {
  text-align: center;
}

.section-heading {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 1.3rem;
}

.section-subtitle {
  margin: 0;
  color: #6c7b7f;
  font-size: 0.95rem;
}

.actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 30px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

@media (max-width: 768px) {
  .actions {
    flex-direction: column;
    gap: 15px;
  }

  .job-context-input {
    padding: 10px;
  }
}
</style>