<template>
  <div class="derik-competency-bridge">
    <!-- Role-Based Assessment Integration -->
    <div v-if="mode === 'role-based' && !showCompetencySurvey" class="role-based-assessment">
      <div class="assessment-header">
        <h3>Role-Based Competency Assessment</h3>
        <p>Select the SE roles that best match your current or target position. The system will assess competencies specific to these roles.</p>
      </div>

      <div class="roles-grid">
        <div
          v-for="role in roles"
          :key="role.id"
          class="role-card"
          :class="{ selected: isRoleSelected(role.id) }"
          @click="toggleRoleSelection(role)"
        >
          <div class="role-header">
            <h4 class="role-name">{{ role.name }}</h4>
            <el-icon v-if="isRoleSelected(role.id)" class="selected-icon"><Check /></el-icon>
          </div>
          <p class="role-description">{{ role.description }}</p>
        </div>
      </div>

      <div class="selected-roles" v-if="selectedRoles.length > 0">
        <h4>Selected Roles ({{ selectedRoles.length }})</h4>
        <div class="selected-roles-list">
          <el-tag
            v-for="role in selectedRoles"
            :key="role.id"
            closable
            @close="removeRole(role.id)"
            size="large"
            type="primary"
          >
            {{ role.name }}
          </el-tag>
        </div>
      </div>

      <div class="assessment-actions">
        <el-button @click="$emit('back')" size="large">
          Previous
        </el-button>
        <el-button
          type="primary"
          @click="startRoleBasedAssessment"
          :disabled="selectedRoles.length === 0"
          :loading="loading"
          size="large"
        >
          Start Competency Assessment ({{ selectedRoles.length }} roles)
        </el-button>
      </div>
    </div>

    <!-- Task-Based Assessment Integration -->
    <div v-else-if="mode === 'task-based' && !showCompetencySurvey" class="task-based-assessment">
      <div class="assessment-header">
        <h3>Task-Based Competency Assessment</h3>
        <p>Describe your current job tasks and responsibilities. Our AI system will analyze them to identify relevant SE processes and competencies.</p>
      </div>

      <el-form :model="taskForm" :rules="taskRules" ref="taskFormRef" label-width="200px">
        <el-form-item label="Tasks you are responsible for" prop="responsibleTasks" required>
          <el-input
            v-model="taskForm.responsibleTasks"
            type="textarea"
            :rows="5"
            placeholder="Please describe the primary tasks for which you are responsible."
          />
        </el-form-item>

        <el-form-item label="Tasks that you support" prop="supportingTasks">
          <el-input
            v-model="taskForm.supportingTasks"
            type="textarea"
            :rows="5"
            placeholder="Please describe tasks you provide support for."
          />
        </el-form-item>

        <el-form-item label="Tasks and processes that you define or design" prop="designingTasks">
          <el-input
            v-model="taskForm.designingTasks"
            type="textarea"
            :rows="5"
            placeholder="Please describe tasks and processes you are involved in defining or designing."
          />
        </el-form-item>
      </el-form>

      <!-- Loading Indicator - Derik's Style -->
      <el-card v-if="analyzing" class="loading-card">
        <div class="loading-message">{{ loadingMessage }}</div>
        <el-progress :percentage="100" :show-text="false" :indeterminate="true" />
      </el-card>

      <!-- Analysis Results - Derik's Format -->
      <el-card v-if="!analyzing && analysisResults && analysisResults.processes && analysisResults.processes.length" class="results-card">
        <template #header>
          <div class="results-title">Identified ISO Processes</div>
        </template>

        <el-table :data="analysisResults.processes" style="width: 100%">
          <el-table-column prop="process_name" label="Process Name" class-name="process-name" />
          <el-table-column prop="involvement" label="Involvement" class-name="involvement" />
        </el-table>

        <div class="button-container">
          <el-button
            type="success"
            size="large"
            @click="proceedToSurvey"
            class="proceed-button"
          >
            Proceed to Survey
          </el-button>
        </div>
      </el-card>

      <!-- Next Button - Only show when not loading and no results -->
      <div v-if="!analyzing && !analysisResults" class="assessment-actions">
        <el-button @click="$emit('back')" size="large">
          Previous
        </el-button>
        <el-button
          type="primary"
          @click="analyzeTaskDescription"
          :loading="analyzing"
          :disabled="!isTaskFormValid"
          size="large"
        >
          <el-icon><MagicStick /></el-icon>
          Analyze Tasks
        </el-button>
      </div>
    </div>

    <!-- Full Competency Assessment Integration -->
    <div v-else-if="mode === 'full-competency'" class="full-competency-assessment">
      <div class="assessment-header">
        <h3>Full Competency Assessment</h3>
        <p>Complete assessment across all 16 INCOSE Systems Engineering competencies. This comprehensive evaluation will:</p>
        <ul>
          <li>Analyze your competency profile across all SE domains</li>
          <li>Suggest the most suitable SE roles based on your strengths</li>
          <li>Identify potential career development paths</li>
          <li>Generate personalized learning objectives</li>
        </ul>

        <el-alert
          title="Assessment Duration"
          description="This comprehensive assessment typically takes 15-20 minutes to complete."
          type="info"
          show-icon
          :closable="false"
        />
      </div>

      <div class="assessment-actions">
        <el-button @click="$emit('back')" size="large">
          Previous
        </el-button>
        <el-button
          type="primary"
          @click="startFullAssessment"
          :loading="loading"
          size="large"
        >
          Start Full Competency Assessment
        </el-button>
      </div>
    </div>

    <!-- Competency Survey Display - Derik's Exact Format -->
    <div v-if="showCompetencySurvey" class="competency-survey">
      <!-- Submission Loading Overlay -->
      <el-card v-if="submitting" class="submission-overlay">
        <div class="submission-content">
          <div class="loading-spinner">
            <el-progress type="circle" :percentage="100" :indeterminate="true" :width="80" />
          </div>
          <h3 class="submission-title">Processing Your Assessment</h3>
          <p class="submission-message">{{ submissionMessage }}</p>
          <el-progress :percentage="100" :show-text="false" :indeterminate="true" class="submission-progress" />
          <p class="submission-note">This may take 10-30 seconds as we generate personalized feedback using AI...</p>
        </div>
      </el-card>

      <div class="survey-header">
        <h3>Systems Engineering Competency Assessment Survey</h3>

        <!-- Show progress but NO competency name mentioned -->
        <div v-if="currentCompetencyIndex < competencies.length">
          <h4 class="question-number">
            Question {{ currentCompetencyIndex + 1 }} of {{ competencies.length }}
          </h4>
          <p class="question-text">
            To which of these groups do you identify yourself?
          </p>
        </div>
      </div>

      <!-- Group Selection Cards - Derik's Format -->
      <div class="indicator-group-wrapper" v-if="currentIndicatorsByLevel.length > 0">
        <div class="level-cards-container">
          <!-- Groups 1-4: Show actual indicators from competency levels -->
          <el-card
            v-for="(levelGroup, index) in currentIndicatorsByLevel"
            :key="index"
            class="indicator-card"
            :class="{ 'selected': selectedGroups.includes(index + 1) }"
            @click="selectGroup(index + 1)"
            shadow="hover"
          >
            <div class="card-content">
              <div class="group-header">
                <strong class="group-title">Group {{ index + 1 }}</strong>
              </div>
              <hr class="separator-line">

              <!-- Display all indicators for this level -->
              <div class="indicators-list">
                <div
                  v-for="(indicator, i) in levelGroup.indicators"
                  :key="i"
                  class="indicator-item"
                >
                  <p class="indicator-text">{{ indicator.indicator_en }}</p>
                  <hr v-if="i < levelGroup.indicators.length - 1" class="separator-line">
                </div>
              </div>
              <hr class="separator-line">
            </div>
          </el-card>

          <!-- Group 5: "You do not see yourselves in any of these groups" -->
          <el-card
            class="indicator-card none-option"
            :class="{ 'selected': selectedGroups.includes(5) }"
            @click="selectGroup(5)"
            shadow="hover"
          >
            <div class="card-content">
              <div class="group-header">
                <strong class="group-title">Group 5</strong>
              </div>
              <hr class="separator-line">
              <p class="indicator-text">You do not see yourselves in any of these groups.</p>
              <hr class="separator-line">
            </div>
          </el-card>
        </div>
      </div>

      <!-- Navigation Buttons - Derik's Style -->
      <div class="navigation-buttons">
        <el-button
          @click="goBack"
          color="#1976d2"
          size="large"
        >
          Back
        </el-button>

        <el-button
          v-if="currentCompetencyIndex < competencies.length - 1"
          @click="proceedToNext"
          :disabled="selectedGroups.length === 0"
          color="#4CAF50"
          size="large"
        >
          Next
        </el-button>

        <el-button
          v-else
          @click="proceedToNext"
          :disabled="selectedGroups.length === 0"
          color="#4CAF50"
          :loading="loading"
          size="large"
        >
          Submit Survey
        </el-button>
      </div>

      <!-- Submit Modal -->
      <el-dialog
        v-model="showSubmitModal"
        title="End of Survey"
        width="500px"
      >
        <p>You have reached the end of the survey. Do you want to submit or go back?</p>
        <template #footer>
          <span class="dialog-footer">
            <el-button @click="showSubmitModal = false">Go Back</el-button>
            <el-button type="primary" @click="submitSurvey">Submit</el-button>
          </span>
        </template>
      </el-dialog>

      <!-- Cancel Survey Confirmation Modal -->
      <el-dialog
        v-model="showCancelModal"
        title="Cancel Assessment?"
        width="500px"
      >
        <p>Are you sure you want to cancel this assessment? All your progress will be lost and you'll return to role selection.</p>
        <template #footer>
          <span class="dialog-footer">
            <el-button @click="showCancelModal = false">Continue Assessment</el-button>
            <el-button type="warning" @click="cancelSurvey">Cancel Assessment</el-button>
          </span>
        </template>
      </el-dialog>
    </div>

    <!-- Active Assessment Display -->
    <div v-if="showAssessment" class="active-assessment">
      <iframe
        :src="assessmentUrl"
        class="assessment-iframe"
        @load="onAssessmentLoad"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Check, MagicStick, ArrowLeft, ArrowRight } from '@element-plus/icons-vue'

// Props
const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: (value) => ['role-based', 'task-based', 'full-competency'].includes(value)
  }
})

// Emits
const emit = defineEmits(['back', 'completed'])

// State
const loading = ref(false)
const analyzing = ref(false)
const roles = ref([])
const selectedRoles = ref([])
const analysisResults = ref(null)
const showAssessment = ref(false)
const assessmentUrl = ref('')
const taskFormRef = ref()
const showCompetencySurvey = ref(false)
const competencies = ref([])
const currentCompetencyIndex = ref(0)
const competencyResponses = ref({})
const currentIndicatorsByLevel = ref([])
const selectedGroups = ref([])
const showSubmitModal = ref(false)
const showCancelModal = ref(false) // Confirmation modal for returning to role selection
const allCompetencyData = ref({}) // Cache for all competency indicators
const loadingMessage = ref('') // Progress messages during analysis
const taskBasedUsername = ref('') // Store username for task-based assessments
const submitting = ref(false) // Track submission state
const submissionMessage = ref('') // Progress messages during submission

// Task form - Derik's structure
const taskForm = ref({
  responsibleTasks: '',
  supportingTasks: '',
  designingTasks: ''
})

const taskRules = {
  responsibleTasks: [
    { required: true, message: 'Tasks you are responsible for is required', trigger: 'blur' }
  ]
}

// Computed - Derik's validation logic
const isTaskFormValid = computed(() => {
  // At least one field must have meaningful content (not just default values)
  const hasResponsibleTasks = taskForm.value.responsibleTasks.trim() &&
                              taskForm.value.responsibleTasks.trim() !== 'Not responsible for any tasks'
  const hasSupportingTasks = taskForm.value.supportingTasks.trim() &&
                             taskForm.value.supportingTasks.trim() !== 'Not supporting any tasks'
  const hasDesigningTasks = taskForm.value.designingTasks.trim() &&
                            taskForm.value.designingTasks.trim() !== 'Not designing any tasks'

  return hasResponsibleTasks || hasSupportingTasks || hasDesigningTasks
})

// Methods
const isRoleSelected = (roleId) => {
  return selectedRoles.value.some(role => role.id === roleId)
}

const toggleRoleSelection = (role) => {
  const index = selectedRoles.value.findIndex(r => r.id === role.id)

  if (index === -1) {
    selectedRoles.value.push({ id: role.id, name: role.name })
  } else {
    selectedRoles.value.splice(index, 1)
  }
}

const removeRole = (roleId) => {
  const index = selectedRoles.value.findIndex(r => r.id === roleId)
  if (index !== -1) {
    selectedRoles.value.splice(index, 1)
  }
}

const loadRoles = async () => {
  try {
    loading.value = true
    // Use SE-QPT's backend API endpoint
    const response = await fetch('http://localhost:5003/roles')

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    // Backend returns array directly, not wrapped in {roles: [...]}
    roles.value = Array.isArray(data) ? data : (data.roles || [])
  } catch (error) {
    ElMessage.error('Failed to load roles')
    console.error('Error loading roles:', error)
  } finally {
    loading.value = false
  }
}

// Simulate progress messages during processing - Derik's exact logic
const simulateProgress = () => {
  const messages = [
    'Analyzing your tasks and responsibilities...',
    'Understanding your involvement in different ISO processes...',
    'Leveraging our AI model to map your tasks to ISO standards...',
    'Finalizing the ISO processes you are performing...'
  ]

  let index = 0
  loadingMessage.value = messages[index]

  const interval = setInterval(() => {
    index++
    if (index < messages.length) {
      loadingMessage.value = messages[index]
    } else {
      clearInterval(interval)
    }
  }, 7000) // Update message every 7 seconds

  return interval
}

// Set default values if fields are empty - Derik's validation logic
const setDefaultValues = () => {
  if (!taskForm.value.responsibleTasks.trim()) {
    taskForm.value.responsibleTasks = 'Not responsible for any tasks'
  }
  if (!taskForm.value.supportingTasks.trim()) {
    taskForm.value.supportingTasks = 'Not supporting any tasks'
  }
  if (!taskForm.value.designingTasks.trim()) {
    taskForm.value.designingTasks = 'Not designing any tasks'
  }
}

// Validate input before analysis - Derik's validation logic
const validateTaskInput = () => {
  setDefaultValues()
  const allDefaults = [
    taskForm.value.responsibleTasks.trim(),
    taskForm.value.supportingTasks.trim(),
    taskForm.value.designingTasks.trim()
  ].every(task =>
    task === 'Not responsible for any tasks' ||
    task === 'Not supporting any tasks' ||
    task === 'Not designing any tasks'
  )

  if (allDefaults) {
    ElMessage.warning('Please provide at least one valid task description.')
    return false
  }

  return true
}

const analyzeTaskDescription = async () => {
  if (!validateTaskInput()) return

  try {
    analyzing.value = true
    loadingMessage.value = '' // Reset loading message

    // Start progress simulation
    const progressInterval = simulateProgress()

    // Create tasks object in Derik's format
    const tasksResponsibilities = {
      responsible_for: taskForm.value.responsibleTasks.split('\n').map(task => task.trim()).filter(task => task),
      supporting: taskForm.value.supportingTasks.split('\n').map(task => task.trim()).filter(task => task),
      designing: taskForm.value.designingTasks.split('\n').map(task => task.trim()).filter(task => task)
    }

    // Generate and store username for this task-based assessment
    taskBasedUsername.value = `seqpt_user_${Date.now()}`

    // Prepare payload matching Derik's format
    const payload = {
      username: taskBasedUsername.value,
      organizationId: 1,
      tasks: tasksResponsibilities
    }

    // Call Derik's /findProcesses endpoint with correct payload format
    const response = await fetch('http://localhost:5003/findProcesses', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)  // ✅ Use the correctly formatted payload
    })

    // Clear progress interval
    clearInterval(progressInterval)

    if (response.ok) {
      const result = await response.json()

      // Backend returns { status: "success", processes: [...] }
      // Processes already have the correct format: { process_name, involvement }
      const processes = result.processes || []

      analysisResults.value = {
        processes: processes,
        taskContext: tasksResponsibilities
      }

      ElMessage.success('Task analysis completed successfully!')

    } else if (response.status === 400) {
      const errorData = await response.json()
      ElMessage.error(errorData.error || 'Invalid task descriptions. Please provide more detailed information.')
    } else {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

  } catch (error) {
    console.error('Task analysis error:', error)
    ElMessage.error('An unexpected error occurred. Please check your input or try again later.')
  } finally {
    analyzing.value = false
    loadingMessage.value = ''
  }
}

const startRoleBasedAssessment = async () => {
  try {
    loading.value = true

    // Load competencies for selected roles
    await loadCompetenciesForRoles()

  } catch (error) {
    ElMessage.error('Failed to start role-based assessment')
    console.error('Error starting assessment:', error)
  } finally {
    loading.value = false
  }
}

const loadCompetenciesForRoles = async () => {
  try {
    // Get organization_id from logged-in user
    const userData = localStorage.getItem('user')
    let organization_id = 1  // Fallback
    if (userData) {
      try {
        const user = JSON.parse(userData)
        organization_id = user.organization_id || 1
      } catch (e) {
        console.warn('Could not parse user data:', e)
      }
    }

    // Get competencies for the selected roles using Derik's API format
    const response = await fetch('http://localhost:5003/get_required_competencies_for_roles', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify({
        role_ids: selectedRoles.value.map(role => role.id),
        organization_id: organization_id,  // Use dynamic organization_id
        user_name: `seqpt_user_${Date.now()}`,
        survey_type: 'known_roles'
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    competencies.value = data.competencies || []

    console.log('Loaded competencies:', competencies.value)

    if (competencies.value.length > 0) {
      await loadAllCompetencyData() // Load all indicators at once for fast transitions
      console.log('All competency data loaded:', allCompetencyData.value)
      setCurrentCompetencyData() // Set indicators for the first competency
      console.log('Current indicators by level:', currentIndicatorsByLevel.value)
      showCompetencySurvey.value = true
      ElMessage.success(`Loaded ${competencies.value.length} competencies for assessment`)
    } else {
      console.error('No competencies loaded!')
      ElMessage.error('No competencies found for the selected roles')
    }

  } catch (error) {
    ElMessage.error('Failed to load competencies')
    console.error('Error loading competencies:', error)
  }
}


// Proceed directly to survey - Derik's logic
const proceedToSurvey = async () => {
  try {
    loading.value = true

    // Load all 16 competencies for task-based assessment
    const competencyResponse = await fetch('http://localhost:5003/competencies')
    if (!competencyResponse.ok) {
      throw new Error('Failed to load competencies')
    }
    const competencyData = await competencyResponse.json()

    // Backend returns array directly, not wrapped in {competencies: [...]}
    // Transform to match the expected format with competency_id
    competencies.value = Array.isArray(competencyData)
      ? competencyData.map(comp => ({
          competency_id: comp.id,
          name: comp.competency_name,
          category: comp.competency_area
        }))
      : (competencyData.competencies || []).map(comp => ({
          competency_id: comp.id,
          name: comp.competency_name || comp.name,
          category: comp.competency_area || comp.category
        }))

    if (competencies.value.length > 0) {
      await loadAllCompetencyData() // Load all indicators at once for fast transitions
      setCurrentCompetencyData() // Set indicators for the first competency
      showCompetencySurvey.value = true
      ElMessage.success(`Starting task-based assessment with ${competencies.value.length} competencies`)
    }

  } catch (error) {
    ElMessage.error('Failed to start competency survey')
    console.error('Error starting survey:', error)
  } finally {
    loading.value = false
  }
}

const startTaskBasedAssessment = async () => {
  // This function is now replaced by proceedToSurvey for direct transition
  await proceedToSurvey()
}

const startFullAssessment = async () => {
  try {
    loading.value = true

    // Load all competencies first
    const competencyResponse = await fetch('http://localhost:5003/competencies')
    if (!competencyResponse.ok) {
      throw new Error('Failed to load competencies')
    }
    const competencyData = await competencyResponse.json()

    // Backend returns array directly, not wrapped in {competencies: [...]}
    // Transform to match the expected format with competency_id
    competencies.value = Array.isArray(competencyData)
      ? competencyData.map(comp => ({
          competency_id: comp.id,
          name: comp.competency_name,
          category: comp.competency_area
        }))
      : (competencyData.competencies || []).map(comp => ({
          competency_id: comp.id,
          name: comp.competency_name || comp.name,
          category: comp.competency_area || comp.category
        }))

    if (competencies.value.length > 0) {
      await loadAllCompetencyData() // Load all indicators at once for fast transitions
      setCurrentCompetencyData() // Set indicators for the first competency
      showCompetencySurvey.value = true
      ElMessage.success(`Starting full assessment with ${competencies.value.length} competencies`)
    }

  } catch (error) {
    ElMessage.error('Failed to start full competency assessment')
    console.error('Error starting assessment:', error)
  } finally {
    loading.value = false
  }
}

const onAssessmentLoad = () => {
  // Handle assessment iframe load
  console.log('Assessment loaded')
}

const getCategoryType = (category) => {
  const typeMap = {
    'Core Competencies': 'danger',
    'Professional Skills': 'primary',
    'Social and Self-Competencies': 'warning',
    'Management Competencies': 'success',
    'Management Skills': 'success'
  }
  return typeMap[category] || 'info'
}

// Load all competency indicators at once for fast transitions
const loadAllCompetencyData = async () => {
  try {
    loading.value = true

    console.log('Loading indicators for competencies:', competencies.value)

    // Fetch indicators for each competency individually
    const indicatorPromises = competencies.value.map(async (comp) => {
      console.log(`Fetching indicators for competency ${comp.competency_id}`)
      const response = await fetch(`http://localhost:5003/get_competency_indicators_for_competency/${comp.competency_id}`)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const data = await response.json()
      console.log(`Received indicators for competency ${comp.competency_id}:`, data)
      return { competency_id: comp.competency_id, data }
    })

    const results = await Promise.all(indicatorPromises)
    console.log('All indicator results:', results)

    // Transform to expected format: { competency_id: { level: [indicators...] } }
    const competencyData = {}
    results.forEach(({ competency_id, data }) => {
      competencyData[competency_id] = {}
      data.forEach(levelGroup => {
        competencyData[competency_id][levelGroup.level] = levelGroup.indicators
      })
    })

    console.log('Transformed competency data:', competencyData)
    allCompetencyData.value = competencyData

  } catch (error) {
    console.error('Error loading all competency indicators:', error)
    ElMessage.error('Failed to load competency indicators')
  } finally {
    loading.value = false
  }
}

// Set current competency data from cache (instant)
const setCurrentCompetencyData = () => {
  if (currentCompetencyIndex.value >= competencies.value.length) return

  const competencyId = competencies.value[currentCompetencyIndex.value].competency_id
  const competencyData = allCompetencyData.value[competencyId]

  if (competencyData) {
    // Transform data to array format for template
    currentIndicatorsByLevel.value = []
    for (let level = 1; level <= 4; level++) {
      if (competencyData[level]) {
        currentIndicatorsByLevel.value.push({
          level: level,
          indicators: competencyData[level]
        })
      }
    }
    restoreSelection() // Restore the selection for the current competency
  } else {
    console.warn(`No cached data found for competency ${competencyId}`)
    ElMessage.warning('Competency data not found. Please refresh.')
  }
}

// Legacy function kept for compatibility but now uses cached data
const fetchIndicators = async () => {
  setCurrentCompetencyData()
}

// Handle user selection of a group - Derik's exact logic
const selectGroup = (groupNumber) => {
  if (groupNumber === 5) {
    // If "None of these" (group 5) is selected, deselect all others
    selectedGroups.value = [5]
  } else {
    if (selectedGroups.value.includes(groupNumber)) {
      // If the group is already selected, deselect it
      selectedGroups.value = selectedGroups.value.filter(group => group !== groupNumber)
    } else {
      // Add the selected group to the list
      selectedGroups.value.push(groupNumber)

      // If any group other than "None of these" is selected, remove group 5 from selections
      selectedGroups.value = selectedGroups.value.filter(group => group !== 5)
    }
  }
}

// Proceed to the next competency - Derik's exact logic
const proceedToNext = () => {
  if (selectedGroups.value.length === 0) {
    ElMessage.warning("Please select at least one group to proceed.")
    return
  }

  // Store the selected groups in competency responses
  if (!competencyResponses.value[competencies.value[currentCompetencyIndex.value].competency_id]) {
    competencyResponses.value[competencies.value[currentCompetencyIndex.value].competency_id] = {}
  }
  competencyResponses.value[competencies.value[currentCompetencyIndex.value].competency_id].selectedGroups = [...selectedGroups.value]

  // Move to the next competency or finish the survey
  if (currentCompetencyIndex.value < competencies.value.length - 1) {
    currentCompetencyIndex.value++
    setCurrentCompetencyData() // Use cached data for instant transition - restoreSelection is called within
  } else {
    showSubmitModal.value = true // Show submit modal
  }
}

// Handle user going back to the previous competency - Derik's exact logic
const goBack = () => {
  if (currentCompetencyIndex.value > 0) {
    currentCompetencyIndex.value--
    setCurrentCompetencyData() // Use cached data for instant transition
    // restoreSelection is already called within setCurrentCompetencyData
  } else {
    // At first question - show confirmation to return to role selection
    showCancelModal.value = true
  }
}

// Reset survey state and return to role selection
const cancelSurvey = () => {
  // Reset all survey state
  currentCompetencyIndex.value = 0
  competencyResponses.value = {}
  selectedGroups.value = []
  currentIndicatorsByLevel.value = []
  showCancelModal.value = false
  showCompetencySurvey.value = false

  ElMessage.info('Assessment cancelled. You can select different roles or restart.')
}

// Restore user's previously selected groups for the current competency - Derik's logic
const restoreSelection = () => {
  const currentCompetencyId = competencies.value[currentCompetencyIndex.value]?.competency_id
  if (currentCompetencyId && competencyResponses.value[currentCompetencyId]) {
    selectedGroups.value = competencyResponses.value[currentCompetencyId].selectedGroups || []
  } else {
    selectedGroups.value = []
  }
}

// Simulate submission progress messages
const simulateSubmissionProgress = () => {
  const messages = [
    'Submitting your assessment...',
    'Saving your competency scores...',
    'Generating personalized AI feedback...',
    'Finalizing your results...'
  ]

  let index = 0
  submissionMessage.value = messages[index]

  const interval = setInterval(() => {
    index++
    if (index < messages.length) {
      submissionMessage.value = messages[index]
    } else {
      clearInterval(interval)
    }
  }, 5000) // Update message every 5 seconds

  return interval
}

// Handle survey submission - Derik's exact logic
const submitSurvey = async () => {
  try {
    loading.value = true
    submitting.value = true
    submissionMessage.value = 'Submitting your assessment...'

    // Start progress messages
    const progressInterval = simulateSubmissionProgress()

    // Step 1: Determine username based on assessment mode
    let username
    if (props.mode === 'task-based' && taskBasedUsername.value) {
      // Reuse username from task analysis for task-based assessments
      username = taskBasedUsername.value
      console.log('Using task-based username:', username)
    } else {
      // Create a new survey user for role-based and full-competency assessments
      const newUserResponse = await fetch('http://localhost:5003/new_survey_user', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      })

      if (!newUserResponse.ok) {
        throw new Error('Failed to create survey user')
      }

      const userData = await newUserResponse.json()
      username = userData.username
      console.log('Created survey user:', username)
    }

    // Step 2: Prepare competency scores using Derik's scoring logic
    const competencyScores = Object.entries(competencyResponses.value).map(([competencyId, response]) => {
      // Extract the maximum value from the selected groups
      const maxGroup = Math.max(...(response.selectedGroups || []))
      let score = 0

      if (maxGroup === 1) score = 1  // kennen
      else if (maxGroup === 2) score = 2  // verstehen
      else if (maxGroup === 3) score = 4  // anwenden
      else if (maxGroup === 4) score = 6  // beherrschen
      else score = 0  // None of these

      return {
        competencyId: parseInt(competencyId),
        score: score
      }
    })

    // Step 3: Determine survey_type based on assessment mode
    let surveyType = 'known_roles'  // Default
    if (props.mode === 'task-based') {
      surveyType = 'unknown_roles'  // Task-based uses UnknownRoleCompetencyMatrix
    } else if (props.mode === 'full-competency') {
      surveyType = 'all_roles'  // Full assessment suggests roles
    }
    // role-based remains 'known_roles'

    // Step 4: Get admin_user_id, organization_id and admin user name from localStorage (from login)
    const userData = localStorage.getItem('user')
    let admin_user_id = null
    let organization_id = 1  // Fallback to default organization
    let adminUserName = 'SE-QPT User'  // Fallback if localStorage data is unavailable
    if (userData) {
      try {
        const user = JSON.parse(userData)
        admin_user_id = user.id
        organization_id = user.organization_id || 1  // Use user's org_id or fallback to 1
        // Use actual logged-in admin user's name instead of hardcoded value
        adminUserName = user.username || user.name || `User ${user.id}` || 'SE-QPT User'
      } catch (e) {
        console.warn('Could not parse user data from localStorage:', e)
      }
    }

    // Step 5: Prepare survey data
    const surveyData = {
      organization_id: organization_id,  // Use logged-in user's organization_id
      full_name: adminUserName,  // Use actual admin user name from localStorage
      username: username,  // Use the generated username
      tasks_responsibilities: analysisResults.value?.taskContext || 'SE-QPT Assessment',
      selected_roles: selectedRoles.value.map(role => ({
        id: role.id,
        name: role.name
      })),
      competency_scores: competencyScores,
      survey_type: surveyType,  // ✅ Dynamic based on mode
      admin_user_id: admin_user_id  // NEW: Pass logged-in user ID for assessment tracking
    }

    console.log('Submitting survey data:', surveyData)

    // Step 6: Submit to Derik's API
    const response = await fetch('http://localhost:5003/submit_survey', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(surveyData)
    })

    // Clear progress interval after submission completes
    clearInterval(progressInterval)

    if (response.ok) {
      const responseData = await response.json()
      const assessment_id = responseData.assessment_id  // NEW: Capture assessment ID from response

      submissionMessage.value = 'Assessment completed successfully!'
      ElMessage.success('Survey submitted successfully!')

      // Small delay to show final message before navigating
      await new Promise(resolve => setTimeout(resolve, 500))

      emit('completed', {
        type: surveyType,  // ✅ Match backend expectations dynamically
        selectedRoles: selectedRoles.value,
        competencyScores: competencyScores,
        surveyData: surveyData,
        assessment_id: assessment_id,  // NEW: Pass assessment ID for persistent result URLs
        username: username  // Pass username for result fetching
      })
    } else {
      const errorData = await response.json()
      console.error('Submit survey error:', errorData)
      throw new Error(errorData.error || 'Failed to submit survey')
    }

  } catch (error) {
    console.error('Error submitting survey:', error)
    ElMessage.error(`Failed to submit survey: ${error.message}`)
  } finally {
    loading.value = false
    submitting.value = false
    submissionMessage.value = ''
    showSubmitModal.value = false
  }
}

// Lifecycle
onMounted(() => {
  if (props.mode === 'role-based') {
    loadRoles()
  }
})
</script>

<style scoped>
.derik-competency-bridge {
  max-width: 1000px;
  margin: 0 auto;
}

.assessment-header {
  text-align: center;
  margin-bottom: 2rem;
}

.assessment-header h3 {
  color: #303133;
  margin-bottom: 1rem;
}

.assessment-header p {
  color: #606266;
  margin-bottom: 1rem;
}

.assessment-header ul {
  text-align: left;
  max-width: 600px;
  margin: 0 auto 1.5rem;
}

.assessment-header li {
  margin-bottom: 0.5rem;
  color: #606266;
}

.roles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.role-card {
  border: 2px solid #EBEEF5;
  border-radius: 8px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  background: white;
}

.role-card:hover {
  border-color: #409EFF;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.2);
}

.role-card.selected {
  border-color: #409EFF;
  background: #F0F7FF;
}

.role-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.role-name {
  margin: 0;
  color: #303133;
  font-size: 16px;
}

.selected-icon {
  color: #409EFF;
  font-size: 20px;
}

.role-description {
  color: #606266;
  margin: 0;
  font-size: 14px;
}

.selected-roles {
  background: #F8F9FA;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 2rem;
}

.selected-roles h4 {
  margin: 0 0 1rem 0;
  color: #303133;
}

.selected-roles-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.analysis-results {
  margin: 2rem 0;
}

.analysis-content {
  margin-top: 1rem;
}

.analysis-section {
  margin-bottom: 1rem;
}

.analysis-section h5 {
  margin: 0 0 0.5rem 0;
  color: #303133;
}

.process-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.assessment-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
  padding: 1.5rem;
  background: #F8F9FA;
  border-radius: 8px;
}

.assessment-iframe {
  width: 100%;
  height: 600px;
  border: 1px solid #EBEEF5;
  border-radius: 8px;
}

@media (max-width: 768px) {
  .roles-grid {
    grid-template-columns: 1fr;
  }

  .assessment-actions {
    flex-direction: column;
    gap: 1rem;
  }

  .selected-roles-list {
    flex-direction: column;
  }
}

/* Competency Survey Styles - Derik's Format with Element Plus Theme */
.competency-survey {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
  position: relative;
}

/* Submission Loading Overlay */
.submission-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(5px);
}

.submission-overlay :deep(.el-card__body) {
  padding: 3rem;
}

.submission-content {
  text-align: center;
  max-width: 500px;
  background: white;
  padding: 2rem;
  border-radius: 12px;
}

.loading-spinner {
  margin-bottom: 2rem;
  display: flex;
  justify-content: center;
}

.submission-title {
  color: #303133;
  font-size: 1.8rem;
  margin: 0 0 1rem 0;
  font-weight: 600;
}

.submission-message {
  color: #409eff;
  font-size: 1.2rem;
  margin: 1rem 0;
  font-weight: 500;
  min-height: 1.5rem;
}

.submission-progress {
  margin: 1.5rem 0;
}

.submission-note {
  color: #909399;
  font-size: 0.9rem;
  margin: 1rem 0 0 0;
  font-style: italic;
}

.survey-header {
  text-align: center;
  margin-bottom: 2rem;
}

.survey-header h3 {
  color: #303133;
  font-size: 2rem;
  margin-bottom: 1rem;
}

.question-number {
  color: #303133;
  font-size: 1.5rem;
  margin-bottom: 1rem;
}

.question-text {
  color: #606266;
  font-size: 1.2rem;
  margin-bottom: 2rem;
}

/* Outer wrapper for all indicator cards */
.indicator-group-wrapper {
  background: #F8F9FA;
  border: 1px solid #EBEEF5;
  border-radius: 12px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.level-cards-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1rem;
  width: 100%;
}

/* Individual indicator cards */
.indicator-card {
  cursor: pointer;
  transition: all 0.3s ease;
  border: 2px solid #DCDFE6 !important;
  min-height: 300px;
  display: flex;
  flex-direction: column;
  background: white;
}

.indicator-card:hover {
  transform: scale(1.02);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
  border-color: #409EFF !important;
}

.indicator-card.selected {
  border: 3px solid #4CAF50 !important;
  box-shadow: 0 4px 20px rgba(76, 175, 80, 0.4);
  background: #F8FFF8;
}

.indicator-card.none-option.selected {
  border-color: #E6A23C !important;
  box-shadow: 0 4px 20px rgba(230, 162, 60, 0.4);
  background: #FDF6EC;
}

.card-content {
  padding: 1.5rem;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.group-header {
  text-align: center;
  margin-bottom: 1rem;
}

.group-title {
  color: #303133;
  font-size: 1.1rem;
  font-weight: bold;
  text-transform: uppercase;
}

/* Styling for separator lines */
.separator-line {
  border: 0;
  height: 1px;
  background: #4CAF50;
  margin: 0.75rem 0;
  width: 100%;
}

.indicators-list {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.indicator-item {
  margin-bottom: 0.5rem;
}

.indicator-text {
  color: #606266;
  font-size: 0.9rem;
  line-height: 1.4;
  text-align: left;
  margin: 0.5rem 0;
}

/* Navigation buttons */
.navigation-buttons {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
}

.navigation-buttons .el-button {
  color: white;
  border: none;
  padding: 0.75rem 2rem;
  font-size: 1rem;
}

/* Back button styling */
.navigation-buttons .el-button:first-child {
  background-color: #1976d2;
}

.navigation-buttons .el-button:first-child:hover {
  background-color: #1565c0;
}

/* Next/Submit button styling */
.navigation-buttons .el-button:last-child {
  background-color: #4CAF50;
}

.navigation-buttons .el-button:last-child:hover {
  background-color: #45a049;
}

.navigation-buttons .el-button:disabled {
  background-color: #DCDFE6;
  color: #909399;
}

/* Submit modal styling */
.el-dialog {
  background-color: white;
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
}

/* Task-Based Assessment Styles - Updated Theme */
.loading-card {
  width: 400px;
  margin: 20px auto;
  padding: 20px;
  background-color: var(--el-color-primary-light-9, #ecf5ff);
  color: var(--el-text-color-primary, #303133);
  border-radius: 10px;
  text-align: center;
  border: 1px solid var(--el-color-primary-light-5, #a0cfff);
}

.loading-message {
  font-size: 1.2rem;
  margin-bottom: 20px;
  color: var(--el-color-primary, #409eff);
  font-weight: 600;
}

.results-card {
  width: 600px;
  margin: 20px auto;
  padding: 20px;
  background-color: var(--el-bg-color, #ffffff);
  color: var(--el-text-color-primary, #303133);
  border-radius: 10px;
  border: 1px solid var(--el-border-color, #DCDFE6);
}

.results-card .el-card__header {
  background-color: var(--el-fill-color-light, #f5f7fa);
  border-bottom: 1px solid var(--el-border-color, #DCDFE6);
}

.results-title {
  font-size: 1.5rem;
  margin-bottom: 10px;
  color: var(--el-color-primary, #409eff);
  text-align: center;
  font-weight: bold;
}

/* Table styling */
.results-card .el-table {
  background-color: var(--el-bg-color, #ffffff);
}

.results-card .el-table th {
  background-color: var(--el-fill-color-light, #f5f7fa);
  color: var(--el-text-color-primary, #303133);
  font-weight: bold;
  border-bottom: 1px solid var(--el-border-color, #DCDFE6);
}

.results-card .el-table td {
  background-color: var(--el-bg-color, #ffffff);
  border-bottom: 1px solid var(--el-border-color-lighter, #E4E7ED);
  color: var(--el-text-color-regular, #606266);
}

.results-card .el-table .process-name {
  color: var(--el-text-color-primary, #303133);
  padding: 5px 10px;
  font-weight: 500;
}

.results-card .el-table .involvement {
  color: var(--el-color-success, #67c23a);
  font-weight: bold;
  padding: 5px 10px;
}

.button-container {
  text-align: center;
  margin-top: 20px;
}

.proceed-button {
  background-color: #4CAF50 !important;
  color: white !important;
  border: none !important;
  border-radius: 30px;
  padding: 15px 20px;
  font-size: 1.2rem;
  text-transform: uppercase;
  max-width: 300px;
  height: 50px !important;
}

.proceed-button:hover {
  background-color: #45a049 !important;
}

@media (max-width: 768px) {
  .level-cards-container {
    grid-template-columns: 1fr;
  }

  .navigation-buttons {
    flex-direction: column;
    gap: 1rem;
  }

  .survey-header h3 {
    font-size: 1.5rem;
  }

  .question-number {
    font-size: 1.2rem;
  }

  .indicator-group-wrapper {
    padding: 1rem;
  }

  .loading-card,
  .results-card {
    width: 95%;
    margin: 20px auto;
  }
}
</style>