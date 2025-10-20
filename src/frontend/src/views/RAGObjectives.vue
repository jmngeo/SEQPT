<template>
  <div class="rag-objectives">
    <div class="page-header">
      <div class="header-content">
        <h1><i class="el-icon-magic-stick"></i> RAG-LLM Objective Generation</h1>
        <p>Generate company-specific SMART learning objectives using AI-powered contextual analysis</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showTutorial">
          <i class="el-icon-question"></i> How it works
        </el-button>
      </div>
    </div>

    <el-row :gutter="20">
      <!-- Left Panel: Context & Configuration -->
      <el-col :span="8">
        <el-card class="context-panel">
          <template #header>
            <span><i class="el-icon-setting"></i> Context Configuration</span>
          </template>

          <!-- Company Context Section -->
          <div class="context-section">
            <h4>Company Context</h4>
            <el-form :model="contextForm" label-width="120px" size="small">
              <el-form-item label="Company">
                <el-select
                  v-model="contextForm.companyId"
                  placeholder="Select company"
                  @change="loadCompanyContext"
                  filterable
                >
                  <el-option
                    v-for="company in companies"
                    :key="company.id"
                    :label="company.name"
                    :value="company.id"
                  ></el-option>
                </el-select>
              </el-form-item>
              <el-form-item label="Department">
                <el-input
                  v-model="contextForm.department"
                  placeholder="e.g., Systems Engineering"
                ></el-input>
              </el-form-item>
              <el-form-item label="Project Type">
                <el-select v-model="contextForm.projectType" placeholder="Select type">
                  <el-option label="Automotive Systems" value="automotive"></el-option>
                  <el-option label="Aerospace Systems" value="aerospace"></el-option>
                  <el-option label="Medical Devices" value="medical"></el-option>
                  <el-option label="Industrial Automation" value="industrial"></el-option>
                  <el-option label="Software Systems" value="software"></el-option>
                  <el-option label="Defense Systems" value="defense"></el-option>
                </el-select>
              </el-form-item>
            </el-form>
          </div>

          <!-- Context Extraction -->
          <div class="context-section">
            <div class="section-header">
              <h4>PMT Context Extraction</h4>
              <el-button
                type="text"
                @click="extractContext"
                :loading="extracting"
                size="small"
              >
                <i class="el-icon-refresh"></i> Extract
              </el-button>
            </div>
            <div v-if="extractedContext" class="extracted-context">
              <el-collapse v-model="activeCollapse" accordion>
                <el-collapse-item title="Processes" name="processes">
                  <el-tag
                    v-for="process in extractedContext.processes"
                    :key="process"
                    class="context-tag"
                  >
                    {{ process }}
                  </el-tag>
                </el-collapse-item>
                <el-collapse-item title="Methods" name="methods">
                  <el-tag
                    v-for="method in extractedContext.methods"
                    :key="method"
                    class="context-tag"
                    type="success"
                  >
                    {{ method }}
                  </el-tag>
                </el-collapse-item>
                <el-collapse-item title="Tools" name="tools">
                  <el-tag
                    v-for="tool in extractedContext.tools"
                    :key="tool"
                    class="context-tag"
                    type="warning"
                  >
                    {{ tool }}
                  </el-tag>
                </el-collapse-item>
              </el-collapse>
            </div>
          </div>

          <!-- RAG Configuration -->
          <div class="context-section">
            <h4>RAG Configuration</h4>
            <el-form :model="ragConfig" label-width="120px" size="small">
              <el-form-item label="Temperature">
                <el-slider
                  v-model="ragConfig.temperature"
                  :min="0"
                  :max="1"
                  :step="0.1"
                  show-input
                  :input-size="'small'"
                ></el-slider>
              </el-form-item>
              <el-form-item label="Max Tokens">
                <el-input-number
                  v-model="ragConfig.maxTokens"
                  :min="100"
                  :max="2000"
                  :step="100"
                  size="small"
                ></el-input-number>
              </el-form-item>
              <el-form-item label="Retrieval Top-K">
                <el-input-number
                  v-model="ragConfig.topK"
                  :min="3"
                  :max="10"
                  size="small"
                ></el-input-number>
              </el-form-item>
              <el-form-item label="Quality Threshold">
                <el-slider
                  v-model="ragConfig.qualityThreshold"
                  :min="70"
                  :max="95"
                  :step="5"
                  show-input
                  :input-size="'small'"
                ></el-slider>
              </el-form-item>
            </el-form>
          </div>
        </el-card>

        <!-- Generation Status -->
        <el-card class="status-panel">
          <template #header>
            <span><i class="el-icon-data-line"></i> Generation Status</span>
          </template>
          <div class="status-content">
            <div class="status-item">
              <span class="status-label">Vector DB Status:</span>
              <el-tag :type="vectorDbStatus === 'ready' ? 'success' : 'warning'">
                {{ vectorDbStatus }}
              </el-tag>
            </div>
            <div class="status-item">
              <span class="status-label">Context Quality:</span>
              <el-progress
                :percentage="contextQuality"
                :stroke-width="6"
                :text-inside="false"
              ></el-progress>
              <span class="quality-score">{{ contextQuality }}%</span>
            </div>
            <div class="status-item">
              <span class="status-label">Generated Objectives:</span>
              <span class="objective-count">{{ generatedObjectives.length }}</span>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- Right Panel: Generation & Results -->
      <el-col :span="16">
        <!-- Input Section -->
        <el-card class="input-panel">
          <template #header>
            <span><i class="el-icon-edit"></i> Objective Generation Input</span>
          </template>

          <el-form :model="generationForm" label-width="140px">
            <el-form-item label="Target Role">
              <el-select
                v-model="generationForm.targetRole"
                placeholder="Select target role"
                filterable
              >
                <el-option
                  v-for="role in availableRoles"
                  :key="role"
                  :label="role"
                  :value="role"
                ></el-option>
              </el-select>
            </el-form-item>
            <el-form-item label="Competency Focus">
              <el-select
                v-model="generationForm.competencies"
                multiple
                placeholder="Select competencies to focus on"
                collapse-tags
              >
                <el-option
                  v-for="comp in competencies"
                  :key="comp.id"
                  :label="comp.name"
                  :value="comp.id"
                ></el-option>
              </el-select>
            </el-form-item>
            <el-form-item label="Job Description">
              <el-input
                v-model="generationForm.jobDescription"
                type="textarea"
                :rows="4"
                placeholder="Paste job description or provide context about the role requirements..."
              ></el-input>
            </el-form-item>
            <el-form-item label="Learning Goals">
              <el-input
                v-model="generationForm.learningGoals"
                type="textarea"
                :rows="3"
                placeholder="Describe specific learning goals or outcomes desired..."
              ></el-input>
            </el-form-item>
            <el-form-item label="Objective Count">
              <el-slider
                v-model="generationForm.objectiveCount"
                :min="3"
                :max="10"
                show-stops
                :marks="{ 3: '3', 5: '5', 7: '7', 10: '10' }"
              ></el-slider>
            </el-form-item>
          </el-form>

          <div class="generation-actions">
            <el-button
              type="primary"
              size="large"
              @click="generateObjectives"
              :loading="generating"
              :disabled="!canGenerate"
            >
              <i class="el-icon-magic-stick"></i>
              Generate SMART Objectives
            </el-button>
            <el-button @click="clearForm">Clear</el-button>
          </div>
        </el-card>

        <!-- Results Section -->
        <el-card v-if="generatedObjectives.length > 0" class="results-panel">
          <template #header>
            <div class="results-header">
              <span><i class="el-icon-document"></i> Generated Objectives</span>
              <div class="results-actions">
                <el-button type="text" @click="regenerateAll" :loading="generating">
                  <i class="el-icon-refresh"></i> Regenerate All
                </el-button>
                <el-button type="text" @click="exportObjectives">
                  <i class="el-icon-download"></i> Export
                </el-button>
              </div>
            </div>
          </template>

          <div class="objectives-list">
            <div
              v-for="(objective, index) in generatedObjectives"
              :key="index"
              class="objective-item"
              :class="{ 'validated': objective.validated, 'selected': selectedObjectives.includes(index) }"
            >
              <div class="objective-header">
                <div class="objective-meta">
                  <el-checkbox
                    v-model="selectedObjectives"
                    :label="index"
                    @change="updateSelection"
                  ></el-checkbox>
                  <el-tag
                    :type="getSmartScoreType(objective.smartScore)"
                    size="small"
                  >
                    SMART: {{ objective.smartScore }}%
                  </el-tag>
                  <el-tag
                    v-if="objective.validated"
                    type="success"
                    size="small"
                  >
                    Validated
                  </el-tag>
                </div>
                <div class="objective-actions">
                  <el-button
                    type="text"
                    @click="editObjective(index)"
                    size="small"
                  >
                    <i class="el-icon-edit"></i>
                  </el-button>
                  <el-button
                    type="text"
                    @click="regenerateObjective(index)"
                    :loading="objective.regenerating"
                    size="small"
                  >
                    <i class="el-icon-refresh"></i>
                  </el-button>
                  <el-button
                    type="text"
                    @click="removeObjective(index)"
                    size="small"
                  >
                    <i class="el-icon-delete"></i>
                  </el-button>
                </div>
              </div>

              <div class="objective-content">
                <div v-if="objective.editing" class="objective-editor">
                  <el-input
                    v-model="objective.editText"
                    type="textarea"
                    :rows="3"
                    @blur="saveObjectiveEdit(index)"
                    @keyup.enter.ctrl="saveObjectiveEdit(index)"
                  ></el-input>
                  <div class="editor-actions">
                    <el-button type="primary" size="small" @click="saveObjectiveEdit(index)">
                      Save
                    </el-button>
                    <el-button size="small" @click="cancelObjectiveEdit(index)">
                      Cancel
                    </el-button>
                  </div>
                </div>
                <div v-else class="objective-text">
                  {{ objective.text }}
                </div>

                <div class="objective-details">
                  <div class="smart-breakdown">
                    <span class="smart-label">SMART Analysis:</span>
                    <div class="smart-criteria">
                      <el-tag
                        v-for="criterion in objective.smartAnalysis"
                        :key="criterion.name"
                        :type="criterion.score >= 80 ? 'success' : criterion.score >= 60 ? 'warning' : 'danger'"
                        size="mini"
                        :title="`${criterion.name}: ${criterion.feedback}`"
                      >
                        {{ criterion.name.charAt(0) }}: {{ criterion.score }}%
                      </el-tag>
                    </div>
                  </div>

                  <div class="context-relevance">
                    <span class="context-label">Context Relevance:</span>
                    <el-rate
                      v-model="objective.contextRelevance"
                      :max="5"
                      disabled
                      show-score
                      text-color="#ff9900"
                    ></el-rate>
                  </div>

                  <div class="related-competencies">
                    <span class="comp-label">Related Competencies:</span>
                    <el-tag
                      v-for="comp in objective.relatedCompetencies"
                      :key="comp"
                      size="mini"
                      class="comp-tag"
                    >
                      {{ comp }}
                    </el-tag>
                  </div>
                </div>

                <div v-if="objective.ragSources" class="rag-sources">
                  <el-collapse>
                    <el-collapse-item title="RAG Sources" name="sources">
                      <div
                        v-for="source in objective.ragSources"
                        :key="source.id"
                        class="source-item"
                      >
                        <div class="source-header">
                          <span class="source-title">{{ source.title }}</span>
                          <el-tag type="info" size="mini">{{ source.relevance }}%</el-tag>
                        </div>
                        <div class="source-content">{{ source.excerpt }}</div>
                      </div>
                    </el-collapse-item>
                  </el-collapse>
                </div>
              </div>
            </div>
          </div>

          <div v-if="selectedObjectives.length > 0" class="batch-actions">
            <el-button
              type="primary"
              @click="validateSelected"
              :loading="validating"
            >
              Validate Selected ({{ selectedObjectives.length }})
            </el-button>
            <el-button @click="exportSelected">
              Export Selected
            </el-button>
            <el-button
              type="danger"
              @click="removeSelected"
            >
              Remove Selected
            </el-button>
          </div>
        </el-card>

        <!-- Validation Panel -->
        <el-card v-if="validationResults.length > 0" class="validation-panel">
          <template #header>
            <span><i class="el-icon-success"></i> Validation Results</span>
          </template>
          <div class="validation-summary">
            <div class="validation-stats">
              <div class="stat">
                <div class="stat-value">{{ validationResults.filter(r => r.passed).length }}</div>
                <div class="stat-label">Passed</div>
              </div>
              <div class="stat">
                <div class="stat-value">{{ validationResults.filter(r => !r.passed).length }}</div>
                <div class="stat-label">Failed</div>
              </div>
              <div class="stat">
                <div class="stat-value">{{ averageQualityScore }}%</div>
                <div class="stat-label">Avg Quality</div>
              </div>
            </div>
          </div>

          <div class="validation-details">
            <div
              v-for="result in validationResults"
              :key="result.objectiveIndex"
              class="validation-item"
              :class="{ 'passed': result.passed }"
            >
              <div class="validation-header">
                <el-icon :class="result.passed ? 'el-icon-success' : 'el-icon-error'"></el-icon>
                <span class="validation-title">Objective {{ result.objectiveIndex + 1 }}</span>
                <el-tag :type="result.passed ? 'success' : 'danger'">
                  {{ result.qualityScore }}% Quality
                </el-tag>
              </div>
              <div class="validation-feedback">
                <ul>
                  <li
                    v-for="feedback in result.feedback"
                    :key="feedback"
                    :class="{ 'positive': feedback.includes('✓'), 'negative': feedback.includes('✗') }"
                  >
                    {{ feedback }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Tutorial Dialog -->
    <el-dialog
      v-model="tutorialVisible"
      title="RAG-LLM Objective Generation Guide"
      width="60%"
      :before-close="closeTutorial"
    >
      <div class="tutorial-content">
        <el-steps :active="tutorialStep" direction="vertical">
          <el-step title="Context Setup" description="Configure company and project context">
            <template #description>
              <div class="tutorial-step">
                <p>Start by selecting your company and providing context about your department and project type. This helps the AI understand your specific environment.</p>
                <ul>
                  <li>Select your company from the dropdown</li>
                  <li>Specify the department (e.g., Systems Engineering)</li>
                  <li>Choose the relevant project type</li>
                </ul>
              </div>
            </template>
          </el-step>
          <el-step title="PMT Extraction" description="Extract Processes, Methods, and Tools">
            <template #description>
              <div class="tutorial-step">
                <p>The system will extract relevant Processes, Methods, and Tools from your company context to ensure objectives are aligned with your organization's practices.</p>
              </div>
            </template>
          </el-step>
          <el-step title="Objective Generation" description="Generate SMART learning objectives">
            <template #description>
              <div class="tutorial-step">
                <p>Provide input for objective generation and let the AI create context-specific SMART objectives.</p>
                <ul>
                  <li>Select target role and competencies</li>
                  <li>Provide job description context</li>
                  <li>Specify learning goals</li>
                  <li>Choose number of objectives to generate</li>
                </ul>
              </div>
            </template>
          </el-step>
          <el-step title="Validation & Refinement" description="Validate and refine generated objectives">
            <template #description>
              <div class="tutorial-step">
                <p>Review, edit, and validate the generated objectives to ensure they meet SMART criteria and quality thresholds.</p>
              </div>
            </template>
          </el-step>
        </el-steps>
      </div>
      <template #footer>
        <div class="tutorial-actions">
          <el-button @click="tutorialStep = Math.max(0, tutorialStep - 1)" :disabled="tutorialStep === 0">
            Previous
          </el-button>
          <el-button
            type="primary"
            @click="tutorialStep = Math.min(3, tutorialStep + 1)"
            :disabled="tutorialStep === 3"
          >
            Next
          </el-button>
          <el-button @click="closeTutorial">Close</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/api/axios'

export default {
  name: 'RAGObjectives',
  setup() {
    // Reactive data
    const extracting = ref(false)
    const generating = ref(false)
    const validating = ref(false)
    const tutorialVisible = ref(false)
    const tutorialStep = ref(0)
    const activeCollapse = ref(['processes'])

    // Context configuration
    const contextForm = ref({
      companyId: '',
      department: '',
      projectType: ''
    })

    const ragConfig = ref({
      temperature: 0.7,
      maxTokens: 500,
      topK: 5,
      qualityThreshold: 85
    })

    // Generation form
    const generationForm = ref({
      targetRole: '',
      competencies: [],
      jobDescription: '',
      learningGoals: '',
      objectiveCount: 5
    })

    // Data
    const companies = ref([
      { id: 1, name: 'AutoTech Motors GmbH' },
      { id: 2, name: 'Aerospace Systems Corp' },
      { id: 3, name: 'MedDevice Innovations' }
    ])

    const availableRoles = ref([
      'System Engineer', 'Requirements Engineer', 'System Architect',
      'Verification & Validation Engineer', 'Project Manager',
      'Product Manager', 'Quality Manager', 'Test Engineer'
    ])

    const competencies = ref([
      { id: 1, name: 'Systems Thinking' },
      { id: 2, name: 'Requirements Engineering' },
      { id: 3, name: 'System Architecture' },
      { id: 4, name: 'Verification & Validation' },
      { id: 5, name: 'Risk Management' },
      { id: 6, name: 'Configuration Management' }
    ])

    const extractedContext = ref(null)
    const vectorDbStatus = ref('ready')
    const contextQuality = ref(78)
    const generatedObjectives = ref([])
    const selectedObjectives = ref([])
    const validationResults = ref([])

    // Computed properties
    const canGenerate = computed(() => {
      return contextForm.value.companyId &&
             generationForm.value.targetRole &&
             generationForm.value.competencies.length > 0 &&
             generationForm.value.jobDescription.trim().length > 0
    })

    const averageQualityScore = computed(() => {
      if (validationResults.value.length === 0) return 0
      const total = validationResults.value.reduce((sum, result) => sum + result.qualityScore, 0)
      return Math.round(total / validationResults.value.length)
    })

    // Methods
    const loadCompanyContext = async () => {
      if (!contextForm.value.companyId) return

      extracting.value = true
      try {
        const response = await axios.get(`/api/companies/${contextForm.value.companyId}/context`)
        extractedContext.value = response.data
        contextQuality.value = response.data.quality || 78
        ElMessage.success('Company context loaded successfully')
      } catch (error) {
        console.error('Error loading company context:', error)
        ElMessage.error('Failed to load company context')
      } finally {
        extracting.value = false
      }
    }

    const extractContext = async () => {
      extracting.value = true
      try {
        const response = await axios.post('/api/rag/extract-context', {
          company: contextForm.value.companyId,
          department: contextForm.value.department,
          projectType: contextForm.value.projectType
        })

        extractedContext.value = response.data
        contextQuality.value = response.data.quality || 85
        ElMessage.success('PMT context extracted successfully')
      } catch (error) {
        console.error('Error extracting context:', error)
        ElMessage.error('Failed to extract context')
      } finally {
        extracting.value = false
      }
    }

    const generateObjectives = async () => {
      generating.value = true
      try {
        const response = await axios.post('/api/rag/generate-objectives', {
          context: {
            company: contextForm.value.companyId,
            department: contextForm.value.department,
            projectType: contextForm.value.projectType,
            extractedContext: extractedContext.value
          },
          input: generationForm.value,
          config: ragConfig.value
        })

        generatedObjectives.value = response.data.objectives.map(obj => ({
          ...obj,
          editing: false,
          editText: obj.text,
          regenerating: false
        }))

        ElMessage.success(`Generated ${response.data.objectives.length} SMART objectives`)
      } catch (error) {
        console.error('Error generating objectives:', error)
        ElMessage.error('Failed to generate objectives')
      } finally {
        generating.value = false
      }
    }

    const regenerateObjective = async (index) => {
      generatedObjectives.value[index].regenerating = true
      try {
        const response = await axios.post('/api/rag/regenerate-objective', {
          index,
          context: extractedContext.value,
          input: generationForm.value,
          currentObjective: generatedObjectives.value[index]
        })

        generatedObjectives.value[index] = {
          ...response.data,
          editing: false,
          editText: response.data.text,
          regenerating: false
        }

        ElMessage.success('Objective regenerated successfully')
      } catch (error) {
        console.error('Error regenerating objective:', error)
        ElMessage.error('Failed to regenerate objective')
      } finally {
        generatedObjectives.value[index].regenerating = false
      }
    }

    const regenerateAll = async () => {
      await generateObjectives()
    }

    const editObjective = (index) => {
      generatedObjectives.value[index].editing = true
      generatedObjectives.value[index].editText = generatedObjectives.value[index].text
    }

    const saveObjectiveEdit = async (index) => {
      const objective = generatedObjectives.value[index]

      try {
        const response = await axios.post('/api/rag/validate-objective', {
          text: objective.editText
        })

        objective.text = objective.editText
        objective.smartScore = response.data.smartScore
        objective.smartAnalysis = response.data.smartAnalysis
        objective.editing = false
        objective.validated = false

        ElMessage.success('Objective updated and re-validated')
      } catch (error) {
        console.error('Error saving objective:', error)
        ElMessage.error('Failed to save objective')
      }
    }

    const cancelObjectiveEdit = (index) => {
      const objective = generatedObjectives.value[index]
      objective.editText = objective.text
      objective.editing = false
    }

    const removeObjective = (index) => {
      generatedObjectives.value.splice(index, 1)
      selectedObjectives.value = selectedObjectives.value
        .filter(i => i !== index)
        .map(i => i > index ? i - 1 : i)
    }

    const validateSelected = async () => {
      if (selectedObjectives.value.length === 0) return

      validating.value = true
      try {
        const objectivesToValidate = selectedObjectives.value.map(index => ({
          index,
          text: generatedObjectives.value[index].text
        }))

        const response = await axios.post('/api/rag/validate-objectives', {
          objectives: objectivesToValidate,
          threshold: ragConfig.value.qualityThreshold
        })

        validationResults.value = response.data.results

        // Update validation status for objectives
        response.data.results.forEach(result => {
          const objective = generatedObjectives.value[result.objectiveIndex]
          objective.validated = result.passed
          objective.validationScore = result.qualityScore
        })

        ElMessage.success(`Validated ${selectedObjectives.value.length} objectives`)
      } catch (error) {
        console.error('Error validating objectives:', error)
        ElMessage.error('Failed to validate objectives')
      } finally {
        validating.value = false
      }
    }

    const exportObjectives = async () => {
      try {
        const response = await axios.post('/api/rag/export-objectives', {
          objectives: generatedObjectives.value,
          format: 'json'
        }, { responseType: 'blob' })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', 'rag-objectives.json')
        document.body.appendChild(link)
        link.click()
        link.remove()

        ElMessage.success('Objectives exported successfully')
      } catch (error) {
        console.error('Error exporting objectives:', error)
        ElMessage.error('Failed to export objectives')
      }
    }

    const exportSelected = () => {
      const selected = selectedObjectives.value.map(index => generatedObjectives.value[index])
      const dataStr = JSON.stringify(selected, null, 2)
      const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr)

      const exportFileDefaultName = 'selected-objectives.json'
      const linkElement = document.createElement('a')
      linkElement.setAttribute('href', dataUri)
      linkElement.setAttribute('download', exportFileDefaultName)
      linkElement.click()
    }

    const removeSelected = () => {
      ElMessageBox.confirm(
        `Are you sure you want to remove ${selectedObjectives.value.length} selected objectives?`,
        'Confirm Removal',
        {
          confirmButtonText: 'Remove',
          cancelButtonText: 'Cancel',
          type: 'warning'
        }
      ).then(() => {
        const indicesToRemove = [...selectedObjectives.value].sort((a, b) => b - a)
        indicesToRemove.forEach(index => {
          generatedObjectives.value.splice(index, 1)
        })
        selectedObjectives.value = []
        ElMessage.success('Selected objectives removed')
      }).catch(() => {
        // User cancelled
      })
    }

    const clearForm = () => {
      generationForm.value = {
        targetRole: '',
        competencies: [],
        jobDescription: '',
        learningGoals: '',
        objectiveCount: 5
      }
      generatedObjectives.value = []
      selectedObjectives.value = []
      validationResults.value = []
    }

    const updateSelection = () => {
      // Handle selection change
    }

    const showTutorial = () => {
      tutorialVisible.value = true
      tutorialStep.value = 0
    }

    const closeTutorial = () => {
      tutorialVisible.value = false
    }

    const getSmartScoreType = (score) => {
      if (score >= 85) return 'success'
      if (score >= 70) return 'warning'
      return 'danger'
    }

    // Lifecycle
    onMounted(() => {
      // Initialize vector DB status check
      vectorDbStatus.value = 'ready'
    })

    return {
      extracting,
      generating,
      validating,
      tutorialVisible,
      tutorialStep,
      activeCollapse,
      contextForm,
      ragConfig,
      generationForm,
      companies,
      availableRoles,
      competencies,
      extractedContext,
      vectorDbStatus,
      contextQuality,
      generatedObjectives,
      selectedObjectives,
      validationResults,
      canGenerate,
      averageQualityScore,
      loadCompanyContext,
      extractContext,
      generateObjectives,
      regenerateObjective,
      regenerateAll,
      editObjective,
      saveObjectiveEdit,
      cancelObjectiveEdit,
      removeObjective,
      validateSelected,
      exportObjectives,
      exportSelected,
      removeSelected,
      clearForm,
      updateSelection,
      showTutorial,
      closeTutorial,
      getSmartScoreType
    }
  }
}
</script>

<style scoped>
.rag-objectives {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  color: white;
}

.header-content h1 {
  margin: 0;
  font-size: 2.2em;
}

.header-content p {
  margin: 5px 0 0 0;
  opacity: 0.9;
}

/* Context Panel */
.context-panel {
  margin-bottom: 20px;
}

.context-section {
  margin-bottom: 25px;
  padding-bottom: 20px;
  border-bottom: 1px solid #f0f0f0;
}

.context-section:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.context-section h4 {
  margin: 0 0 15px 0;
  color: #2c3e50;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.extracted-context {
  margin-top: 15px;
}

.context-tag {
  margin: 3px 5px 3px 0;
}

/* Status Panel */
.status-panel {
  margin-bottom: 20px;
}

.status-content {
  display: grid;
  gap: 15px;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-label {
  font-weight: 500;
  color: #666;
}

.quality-score {
  margin-left: 10px;
  font-weight: bold;
  color: #2c3e50;
}

.objective-count {
  font-size: 1.2em;
  font-weight: bold;
  color: #667eea;
}

/* Input Panel */
.input-panel {
  margin-bottom: 20px;
}

.generation-actions {
  display: flex;
  gap: 15px;
  margin-top: 20px;
  justify-content: center;
}

/* Results Panel */
.results-panel {
  margin-bottom: 20px;
}

.results-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.results-actions {
  display: flex;
  gap: 10px;
}

.objectives-list {
  display: grid;
  gap: 20px;
}

.objective-item {
  border: 2px solid #f0f0f0;
  border-radius: 12px;
  padding: 20px;
  transition: all 0.3s ease;
}

.objective-item:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.1);
}

.objective-item.selected {
  border-color: #667eea;
  background: #f8f9ff;
}

.objective-item.validated {
  border-color: #27ae60;
  background: #f8fff8;
}

.objective-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.objective-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.objective-actions {
  display: flex;
  gap: 5px;
}

.objective-content {
  margin-bottom: 15px;
}

.objective-text {
  font-size: 16px;
  line-height: 1.6;
  color: #2c3e50;
  margin-bottom: 15px;
}

.objective-editor {
  margin-bottom: 15px;
}

.editor-actions {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.objective-details {
  display: grid;
  gap: 15px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
}

.smart-breakdown {
  display: flex;
  align-items: center;
  gap: 10px;
}

.smart-label,
.context-label,
.comp-label {
  font-weight: 500;
  color: #666;
  min-width: 120px;
}

.smart-criteria {
  display: flex;
  gap: 5px;
  flex-wrap: wrap;
}

.context-relevance {
  display: flex;
  align-items: center;
  gap: 10px;
}

.related-competencies {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.comp-tag {
  margin: 2px;
}

.rag-sources {
  margin-top: 15px;
}

.source-item {
  margin-bottom: 10px;
  padding: 10px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
}

.source-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 5px;
}

.source-title {
  font-weight: 500;
  color: #2c3e50;
}

.source-content {
  font-size: 14px;
  color: #666;
  line-height: 1.4;
}

.batch-actions {
  display: flex;
  gap: 15px;
  justify-content: center;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
}

/* Validation Panel */
.validation-panel {
  margin-bottom: 20px;
}

.validation-summary {
  margin-bottom: 20px;
}

.validation-stats {
  display: flex;
  justify-content: space-around;
  text-align: center;
}

.stat {
  flex: 1;
}

.stat-value {
  font-size: 2em;
  font-weight: bold;
  color: #667eea;
}

.stat-label {
  color: #7f8c8d;
  margin-top: 5px;
}

.validation-details {
  display: grid;
  gap: 15px;
}

.validation-item {
  padding: 15px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
}

.validation-item.passed {
  border-color: #27ae60;
  background: #f8fff8;
}

.validation-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.validation-title {
  font-weight: 500;
  color: #2c3e50;
  flex: 1;
}

.validation-feedback ul {
  margin: 0;
  padding-left: 20px;
}

.validation-feedback li {
  margin-bottom: 5px;
}

.validation-feedback li.positive {
  color: #27ae60;
}

.validation-feedback li.negative {
  color: #e74c3c;
}

/* Tutorial */
.tutorial-content {
  max-height: 500px;
  overflow-y: auto;
}

.tutorial-step {
  padding: 10px;
}

.tutorial-step p {
  margin-bottom: 10px;
  line-height: 1.6;
}

.tutorial-step ul {
  margin: 10px 0;
  padding-left: 20px;
}

.tutorial-actions {
  display: flex;
  justify-content: center;
  gap: 15px;
}

/* Responsive Design */
@media (max-width: 1200px) {
  .rag-objectives .el-row {
    flex-direction: column;
  }

  .rag-objectives .el-col {
    max-width: 100%;
  }
}

/* Animation */
.objective-item {
  animation: fadeInUp 0.3s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>