<template>
  <el-card class="derik-task-selector">
    <template #header>
      <div class="card-header">
        <h2 class="section-title">Task-Based Assessment</h2>
        <p class="section-description">Describe your tasks and responsibilities to automatically map to SE roles</p>
      </div>
    </template>

    <div class="task-form">
      <!-- Tasks Responsible For -->
      <div class="form-group">
        <label class="form-label">Tasks you are responsible for</label>
        <el-input
          v-model="tasksResponsibleFor"
          type="textarea"
          :rows="6"
          placeholder="Describe the primary tasks for which you are responsible..."
          class="task-input"
        />
      </div>

      <!-- Tasks You Support -->
      <div class="form-group">
        <label class="form-label">Tasks that you support</label>
        <el-input
          v-model="tasksYouSupport"
          type="textarea"
          :rows="6"
          placeholder="Describe tasks you provide support for..."
          class="task-input"
        />
      </div>

      <!-- Tasks You Define and Improve -->
      <div class="form-group">
        <label class="form-label">Tasks and processes that you define or design</label>
        <el-input
          v-model="tasksDefineAndImprove"
          type="textarea"
          :rows="6"
          placeholder="Describe tasks and processes you are involved in defining or designing..."
          class="task-input"
        />
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="loading-container">
      <el-loading
        element-loading-text="Analyzing your tasks and responsibilities..."
        element-loading-background="rgba(0, 0, 0, 0.8)"
      />
      <div class="progress-messages">
        <p class="loading-message">{{ loadingMessage }}</p>
        <el-progress
          :percentage="progressPercentage"
          :stroke-width="8"
          color="#67c23a"
        />
      </div>
    </div>

    <!-- Results Display -->
    <div v-if="!isLoading && processResult.length > 0" class="results-section">
      <h3 class="results-title">Identified ISO Processes</h3>
      <div class="processes-grid">
        <div
          v-for="process in filteredProcessResult"
          :key="process.process_name"
          class="process-card"
        >
          <div class="process-header">
            <h4 class="process-name">{{ process.process_name }}</h4>
            <el-tag
              :type="getInvolvementType(process.involvement)"
              size="small"
            >
              {{ process.involvement }}
            </el-tag>
          </div>
          <p class="process-description" v-if="process.description">
            {{ process.description }}
          </p>
        </div>
      </div>

      <!-- Role-based alternative card -->
      <!-- Commented out: Not applicable when maturity < 3 (task-based pathway required) -->
      <!--
      <div class="role-card" @click="$emit('switchToRoleBased')">
        <div class="role-card-title">Want to Select Roles Directly?</div>
        <div class="role-card-text">
          Switch to role-based selection if you prefer to choose from predefined SE roles.
        </div>
      </div>
      -->
    </div>

    <!-- Actions -->
    <div class="actions">
      <el-button
        v-if="!isLoading && processResult.length === 0"
        type="primary"
        size="large"
        @click="analyzeTasksAndProceed"
        :disabled="!hasValidInput"
      >
        Analyze Tasks & Proceed
      </el-button>

      <el-button
        v-if="!isLoading && processResult.length > 0"
        type="success"
        size="large"
        @click="proceedToAssessment"
      >
        Proceed to Competency Assessment
      </el-button>
    </div>

    <!-- Validation Dialog -->
    <el-dialog
      v-model="showValidationDialog"
      title="Validation Error"
      width="30%"
    >
      <p>{{ validationMessage }}</p>
      <template #footer>
        <el-button type="primary" @click="showValidationDialog = false">
          OK
        </el-button>
      </template>
    </el-dialog>

    <!-- Error Dialog -->
    <el-dialog
      v-model="showErrorDialog"
      title="Error"
      width="30%"
    >
      <p>{{ errorMessage }}</p>
      <template #footer>
        <el-button type="primary" @click="showErrorDialog = false">
          OK
        </el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  username: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['tasksAnalyzed'])

// State
const tasksResponsibleFor = ref('')
const tasksYouSupport = ref('')
const tasksDefineAndImprove = ref('')
const isLoading = ref(false)
const loadingMessage = ref('')
const progressPercentage = ref(0)
const processResult = ref([])
const showValidationDialog = ref(false)
const showErrorDialog = ref(false)
const validationMessage = ref('')
const errorMessage = ref('')

// Computed
const hasValidInput = computed(() => {
  return tasksResponsibleFor.value.trim() ||
         tasksYouSupport.value.trim() ||
         tasksDefineAndImprove.value.trim()
})

const filteredProcessResult = computed(() => {
  return processResult.value.filter(process =>
    process.involvement !== "Not performing"
  )
})

// Methods
const setDefaultValues = () => {
  if (!tasksResponsibleFor.value.trim()) {
    tasksResponsibleFor.value = 'Not responsible for any tasks'
  }
  if (!tasksYouSupport.value.trim()) {
    tasksYouSupport.value = 'Not supporting any tasks'
  }
  if (!tasksDefineAndImprove.value.trim()) {
    tasksDefineAndImprove.value = 'Not designing any tasks'
  }
}

const validateInput = () => {
  setDefaultValues()
  const allDefaults = [
    tasksResponsibleFor.value.trim(),
    tasksYouSupport.value.trim(),
    tasksDefineAndImprove.value.trim()
  ].every(task =>
    task === 'Not responsible for any tasks' ||
    task === 'Not supporting any tasks' ||
    task === 'Not designing any tasks'
  )

  if (allDefaults) {
    validationMessage.value = 'Please provide at least one valid task description.'
    showValidationDialog.value = true
    return false
  }

  return true
}

const simulateProgress = () => {
  const messages = [
    'Analyzing your tasks and responsibilities...',
    'Understanding your involvement in different ISO processes...',
    'Leveraging our AI model to map your tasks to ISO standards...',
    'Finalizing the ISO processes you are performing...'
  ]

  let index = 0
  let progress = 0
  loadingMessage.value = messages[index]
  progressPercentage.value = 25

  const interval = setInterval(() => {
    index++
    progress += 25

    if (index < messages.length) {
      loadingMessage.value = messages[index]
      progressPercentage.value = progress
    } else {
      clearInterval(interval)
      progressPercentage.value = 100
    }
  }, 2000) // Update every 2 seconds
}

const analyzeTasksAndProceed = async () => {
  if (!validateInput()) return

  errorMessage.value = ''

  // Create combined task description for analysis
  const taskDescription = [
    tasksResponsibleFor.value,
    tasksYouSupport.value,
    tasksDefineAndImprove.value
  ].filter(task =>
    task &&
    task !== 'Not responsible for any tasks' &&
    task !== 'Not supporting any tasks' &&
    task !== 'Not designing any tasks'
  ).join('\n\n')

  try {
    isLoading.value = true
    simulateProgress()

    console.log('[DerikTaskSelector] Calling /api/findProcesses with username:', props.username)

    // Call the /findProcesses endpoint (stores data in DB and populates competency matrix)
    const response = await fetch('/api/findProcesses', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        username: props.username,
        organizationId: props.organizationId,
        tasks: {
          responsible_for: tasksResponsibleFor.value.split('\n').filter(t => t.trim()),
          supporting: tasksYouSupport.value.split('\n').filter(t => t.trim()),
          designing: tasksDefineAndImprove.value.split('\n').filter(t => t.trim())
        }
      })
    })

    if (response.ok) {
      const data = await response.json()
      // The response format from /findProcesses is: {status: "success", processes: [{process_name, involvement}, ...]}
      processResult.value = data.processes || []
      console.log('Identified processes:', processResult.value)
      console.log('Full API response:', data)
    } else {
      throw new Error('Failed to identify processes')
    }
  } catch (error) {
    console.error('Failed to analyze tasks:', error)
    errorMessage.value = 'Failed to analyze your tasks. Please refine your task descriptions and try again.'
    showErrorDialog.value = true
  } finally {
    isLoading.value = false
    progressPercentage.value = 0
  }
}

const getInvolvementType = (involvement) => {
  switch (involvement) {
    case 'Leading': return 'danger'
    case 'Contributing': return 'warning'
    case 'Supporting': return 'info'
    default: return 'success'
  }
}

const proceedToAssessment = () => {
  if (filteredProcessResult.value.length === 0) {
    ElMessage({
      type: 'warning',
      message: 'No processes identified with your current tasks. This will result in 0 required competencies. Please refine your task descriptions and click "Analyze Tasks" again to get better results.',
      duration: 6000,
      showClose: true
    })
    // Don't return - allow user to see "0 competencies" result and go back to edit
  }

  emit('tasksAnalyzed', {
    type: 'task-based',
    tasks: {
      responsible_for: tasksResponsibleFor.value,
      supporting: tasksYouSupport.value,
      designing: tasksDefineAndImprove.value
    },
    processes: filteredProcessResult.value
  })
}
</script>

<style scoped>
.derik-task-selector {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header {
  text-align: left;
}

.card-header .section-title {
  font-size: 1.8rem;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 8px 0;
}

.card-header .section-description {
  color: #606266;
  font-size: 14px;
  margin: 0;
}

.task-form {
  margin-bottom: 30px;
}

.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
  font-size: 1rem;
}

.task-input {
  width: 100%;
}

/* Custom scrollbar styling for textareas */
.task-input :deep(textarea) {
  scrollbar-width: thin;
  scrollbar-color: #409eff #f5f7fa;
}

.task-input :deep(textarea::-webkit-scrollbar) {
  width: 8px;
}

.task-input :deep(textarea::-webkit-scrollbar-track) {
  background: #f5f7fa;
  border-radius: 4px;
}

.task-input :deep(textarea::-webkit-scrollbar-thumb) {
  background: #409eff;
  border-radius: 4px;
}

.task-input :deep(textarea::-webkit-scrollbar-thumb:hover) {
  background: #337ecc;
}

.loading-container {
  min-height: 200px;
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 40px 0;
}

.progress-messages {
  margin-top: 20px;
  text-align: center;
  width: 100%;
  max-width: 400px;
}

.loading-message {
  font-size: 1.1rem;
  color: #409eff;
  margin-bottom: 15px;
  font-weight: 500;
}

.results-section {
  margin-bottom: 30px;
}

.results-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #67c23a;
  margin-bottom: 20px;
  text-align: center;
}

.processes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.process-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 16px;
  border-left: 4px solid #67c23a;
}

.process-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.process-name {
  font-weight: 600;
  font-size: 1.1rem;
  color: #2c3e50;
  margin: 0;
  flex: 1;
  margin-right: 12px;
}

.process-description {
  color: #6c7b7f;
  font-size: 0.9rem;
  line-height: 1.4;
  margin: 0;
}

.role-card {
  background: linear-gradient(135deg, #f0f9ff, #e0f2fe);
  border: 2px dashed #409eff;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 20px;
}

.role-card:hover {
  background: linear-gradient(135deg, #e6f7ff, #bae7ff);
  transform: translateY(-2px);
}

.role-card-title {
  font-weight: 600;
  font-size: 1.2rem;
  color: #409eff;
  margin-bottom: 8px;
}

.role-card-text {
  color: #5c6b75;
  line-height: 1.6;
}

.actions {
  text-align: center;
}
</style>