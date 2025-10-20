<template>
  <el-card class="task-based-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Describe Your Organization's Job Profiles</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Since your SE processes are still developing, please describe the job profiles
          that exist in your organization. The system will analyze these and map them to
          appropriate SE roles.
        </p>
      </div>
    </template>

    <!-- Show job profile input if not mapped yet -->
    <div v-if="!mappingResults">
      <!-- Job profiles -->
      <div
        v-for="(profile, index) in jobProfiles"
        :key="index"
        class="job-profile-card"
      >
        <el-card shadow="hover">
          <template #header>
            <div class="profile-card-header">
              <h4>Job Profile #{{ index + 1 }}</h4>
              <el-button
                v-if="jobProfiles.length > 1"
                type="danger"
                text
                :icon="'Delete'"
                @click="removeProfile(index)"
              >
                Remove
              </el-button>
            </div>
          </template>

          <!-- Job Title -->
          <el-form-item label="Job Title *" style="margin-bottom: 20px;">
            <el-input
              v-model="profile.title"
              placeholder="e.g., Senior Software Developer"
              clearable
            />
          </el-form-item>

          <!-- Tasks - Responsible For -->
          <el-form-item label="Responsible For *" style="margin-bottom: 20px;">
            <el-input
              v-model="profile.tasks.responsible_for"
              type="textarea"
              :rows="5"
              placeholder="List tasks this role is primarily responsible for (one per line)&#10;e.g., Developing software modules&#10;Writing unit tests&#10;Creating technical documentation"
            />
            <div class="form-hint">
              REQUIRED: List 2-3 tasks this role is directly responsible for executing
            </div>
          </el-form-item>

          <!-- Tasks - Supporting -->
          <el-form-item label="Supporting *" style="margin-bottom: 20px;">
            <el-input
              v-model="profile.tasks.supporting"
              type="textarea"
              :rows="5"
              placeholder="List tasks this role supports or assists with (one per line)&#10;e.g., Code reviews for team members&#10;Helping junior developers troubleshoot issues&#10;Supporting integration testing"
            />
            <div class="form-hint">
              REQUIRED: List 1-2 tasks this role supports or assists others with
            </div>
          </el-form-item>

          <!-- Tasks - Designing -->
          <el-form-item label="Designing/Improving *" style="margin-bottom: 20px;">
            <el-input
              v-model="profile.tasks.designing"
              type="textarea"
              :rows="5"
              placeholder="List tasks this role designs or improves (one per line)&#10;e.g., Software architecture design&#10;Defining design patterns and standards&#10;Process improvement initiatives"
            />
            <div class="form-hint">
              REQUIRED: List 1-2 tasks this role designs, plans, or improves
            </div>
          </el-form-item>

          <!-- Department -->
          <el-form-item label="Department/Area">
            <el-select
              v-model="profile.department"
              placeholder="Select department"
              style="width: 100%;"
            >
              <el-option
                v-for="dept in departments"
                :key="dept"
                :label="dept"
                :value="dept"
              />
            </el-select>
          </el-form-item>
        </el-card>
      </div>

      <!-- Add another profile button -->
      <el-button
        type="primary"
        plain
        @click="addNewProfile"
        style="margin-top: 16px; margin-bottom: 24px;"
      >
        <el-icon style="margin-right: 4px;"><Plus /></el-icon>
        Add Another Job Profile
      </el-button>

      <!-- Profile summary and map button -->
      <el-card shadow="never" style="background-color: #f5f7fa; margin-top: 24px;">
        <div style="margin-bottom: 12px;">
          <strong>Total Job Profiles Added:</strong> {{ jobProfiles.length }}
        </div>
        <div style="font-size: 13px; color: #909399; margin-bottom: 16px;">
          The AI will analyze the tasks you've described and map each job profile
          to the most appropriate SE role cluster(s).
        </div>
        <div style="display: flex; justify-content: space-between;">
          <el-button @click="handleBack">
            Back to Maturity Assessment
          </el-button>
          <el-button
            type="primary"
            :loading="mapping"
            :disabled="!canMap"
            @click="mapProfilesToRoles"
          >
            Map to SE Roles
          </el-button>
        </div>
      </el-card>
    </div>

    <!-- Show mapping results if available -->
    <div v-else>
      <el-alert
        type="success"
        :closable="false"
        show-icon
        style="margin-bottom: 20px;"
      >
        AI analysis complete! Review the suggested role mappings below.
      </el-alert>

      <div
        v-for="(result, index) in mappingResults"
        :key="index"
        class="mapping-result-card"
      >
        <el-card shadow="hover">
          <template #header>
            <h4>{{ result.jobTitle }}</h4>
          </template>

          <div style="margin-bottom: 16px;">
            <div style="margin-bottom: 8px;">
              <strong>Suggested SE Role:</strong> {{ result.suggestedRole.name }}
            </div>
            <div style="font-size: 13px; color: #909399; margin-bottom: 12px;">
              {{ result.suggestedRole.description }}
            </div>
            <el-tag
              :type="getConfidenceType(result.confidence)"
              size="default"
            >
              Confidence: {{ result.confidence }}%
            </el-tag>
          </div>

          <el-divider></el-divider>

          <!-- Custom organization name -->
          <el-form-item label="Organization-specific role name" style="margin-bottom: 16px;">
            <el-input
              v-model="result.orgRoleName"
              placeholder="Customize this role name for your organization"
              clearable
            />
            <div class="form-hint">
              This will be used in reports and displays
            </div>
          </el-form-item>

          <!-- Option to change role -->
          <el-form-item label="Change to different SE role (if needed)">
            <el-select
              v-model="result.selectedRoleId"
              placeholder="Select role"
              style="width: 100%;"
            >
              <el-option
                v-for="role in SE_ROLE_CLUSTERS"
                :key="role.id"
                :label="role.name"
                :value="role.id"
              />
            </el-select>
            <div class="form-hint">
              The AI suggested the best match, but you can change it
            </div>
          </el-form-item>
        </el-card>
      </div>

      <!-- Actions -->
      <div style="display: flex; justify-content: space-between; margin-top: 24px;">
        <el-button @click="resetMapping">
          Start Over
        </el-button>
        <el-button
          type="primary"
          :loading="saving"
          @click="saveAndContinue"
        >
          Save and Continue
        </el-button>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Plus } from '@element-plus/icons-vue'
import { SE_ROLE_CLUSTERS } from '@/data/seRoleClusters'
import { rolesApi } from '@/api/phase1'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  maturityId: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()
const jobProfiles = ref([createEmptyProfile()])
const mappingResults = ref(null)
const mapping = ref(false)
const saving = ref(false)

const departments = [
  'Engineering',
  'Development',
  'Production',
  'Quality',
  'Management',
  'Support',
  'Service',
  'Other'
]

// Create empty profile
function createEmptyProfile() {
  return {
    title: '',
    tasks: {
      responsible_for: '',
      supporting: '',
      designing: ''
    },
    department: ''
  }
}

// Add new profile
const addNewProfile = () => {
  jobProfiles.value.push(createEmptyProfile())
}

// Remove profile
const removeProfile = (index) => {
  jobProfiles.value.splice(index, 1)
}

// Check if we can map - ALL THREE task categories are required
const canMap = computed(() => {
  return jobProfiles.value.some(p =>
    p.title.trim() !== '' &&
    p.tasks.responsible_for.trim() !== '' &&
    p.tasks.supporting.trim() !== '' &&
    p.tasks.designing.trim() !== ''
  )
})

// Get confidence tag type
const getConfidenceType = (confidence) => {
  if (confidence >= 80) return 'success'
  if (confidence >= 65) return 'warning'
  return 'danger'
}

// Handle back
const handleBack = () => {
  emit('back')
}

// Map profiles to roles using AI
const mapProfilesToRoles = async () => {
  mapping.value = true
  try {
    const results = []

    for (const profile of jobProfiles.value) {
      if (!profile.title.trim()) continue

      // Prepare tasks in format expected by /findProcesses
      const tasks = {
        responsible_for: profile.tasks.responsible_for.split('\n').filter(t => t.trim()),
        supporting: profile.tasks.supporting.split('\n').filter(t => t.trim()),
        designing: profile.tasks.designing.split('\n').filter(t => t.trim())
      }

      // VALIDATE: All three task categories are required by backend LLM
      if (tasks.responsible_for.length === 0 || tasks.supporting.length === 0 || tasks.designing.length === 0) {
        console.warn('[TaskBasedMapping] Skipping profile with incomplete task categories:', profile.title)

        const missingCategories = []
        if (tasks.responsible_for.length === 0) missingCategories.push('Responsible For')
        if (tasks.supporting.length === 0) missingCategories.push('Supporting')
        if (tasks.designing.length === 0) missingCategories.push('Designing/Improving')

        alert(`Cannot process "${profile.title}":\n\nMissing required task categories: ${missingCategories.join(', ')}\n\nAll three task categories (Responsible For, Supporting, and Designing/Improving) must have meaningful content for the AI to accurately map roles.`)
        mapping.value = false
        return
      }

      // Validate minimum task count (at least 2 tasks per category recommended)
      if (tasks.responsible_for.length < 2 || tasks.supporting.length < 1 || tasks.designing.length < 1) {
        console.warn('[TaskBasedMapping] Profile has minimal task content:', profile.title)
      }

      // Create username for this profile (temporary)
      const username = `phase1_temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

      // Call /findProcesses to map tasks to ISO processes
      console.log('[TaskBasedMapping] Mapping tasks for:', profile.title)
      const processResponse = await rolesApi.mapTasksToProcesses(
        username,
        authStore.organizationId,
        tasks
      )

      console.log('[TaskBasedMapping] Process mapping result:', processResponse)

      // Get role suggestion from backend using process matching
      console.log('[TaskBasedMapping] Getting role suggestion for:', username)
      const roleSuggestion = await rolesApi.suggestRoleFromProcesses(
        username,
        authStore.organizationId
      )

      console.log('[TaskBasedMapping] Role suggestion:', roleSuggestion)

      results.push({
        jobTitle: profile.title,
        tasks: tasks,
        department: profile.department,
        processMapping: processResponse,
        suggestedRole: roleSuggestion.suggestedRole,
        selectedRoleId: roleSuggestion.suggestedRole.id,
        orgRoleName: profile.title, // Default to job title
        confidence: roleSuggestion.confidence
      })
    }

    mappingResults.value = results
    console.log('[TaskBasedMapping] Mapping complete:', results)
  } catch (error) {
    console.error('[TaskBasedMapping] Mapping failed:', error)

    // Show more helpful error message
    let errorMessage = 'Failed to map job profiles to SE roles.\n\n'

    if (error.response && error.response.status === 400) {
      errorMessage += 'VALIDATION ERROR: The backend LLM requires ALL THREE task categories to have meaningful content.\n\n'
      errorMessage += 'Please ensure each job profile includes:\n'
      errorMessage += '• "Responsible For": 2-3 detailed tasks (what this role directly executes)\n'
      errorMessage += '• "Supporting": 1-2 detailed tasks (what this role helps others with)\n'
      errorMessage += '• "Designing/Improving": 1-2 detailed tasks (what this role plans or improves)\n\n'
      errorMessage += 'Empty categories or single-word entries will be rejected by the AI.\n\n'
      errorMessage += 'All three categories are MANDATORY for accurate role mapping.'
    } else {
      errorMessage += 'Error: ' + (error.message || 'Unknown error occurred')
    }
    alert(errorMessage)
  } finally {
    mapping.value = false
  }
}

// Reset mapping
const resetMapping = () => {
  mappingResults.value = null
  jobProfiles.value = [createEmptyProfile()]
}

// Save and continue
const saveAndContinue = async () => {
  saving.value = true
  try {
    // Prepare roles data
    const rolesToSave = mappingResults.value.map(result => {
      const selectedRole = SE_ROLE_CLUSTERS.find(r => r.id === result.selectedRoleId)
      return {
        standardRoleId: result.selectedRoleId,
        standardRoleName: selectedRole.name,
        orgRoleName: result.orgRoleName,
        jobDescription: result.jobTitle,
        mainTasks: result.tasks,
        isoProcesses: result.processMapping,
        identificationMethod: 'TASK_BASED',
        confidenceScore: result.confidence,
        participatingInTraining: true
      }
    })

    // Save to database
    const response = await rolesApi.save(
      authStore.organizationId,
      props.maturityId,
      rolesToSave,
      'TASK_BASED'
    )

    console.log('[TaskBasedMapping] Saved:', response)

    // Emit completion
    emit('complete', {
      roles: response.data,
      count: rolesToSave.length
    })
  } catch (error) {
    console.error('[TaskBasedMapping] Save failed:', error)
    alert('Failed to save roles. Please try again.')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.task-based-container {
  max-width: 1000px;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.job-profile-card {
  margin-bottom: 24px;
}

.job-profile-card :deep(.el-card) {
  border: 2px solid #e4e7ed;
  transition: all 0.3s ease;
}

.job-profile-card :deep(.el-card:hover) {
  border-color: #409eff;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.1);
}

.profile-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.profile-card-header h4 {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #303133;
}

/* Uniform input styling */
.job-profile-card :deep(.el-input__wrapper) {
  min-height: 40px;
  box-shadow: 0 0 0 1px #dcdfe6 inset;
  transition: all 0.3s;
}

.job-profile-card :deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #c0c4cc inset;
}

.job-profile-card :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #409eff inset !important;
}

/* Textarea uniform styling */
.job-profile-card :deep(.el-textarea__inner) {
  min-height: 120px !important;
  padding: 12px;
  font-size: 14px;
  line-height: 1.6;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  transition: all 0.3s;
  resize: vertical;
}

.job-profile-card :deep(.el-textarea__inner:hover) {
  border-color: #c0c4cc;
}

.job-profile-card :deep(.el-textarea__inner:focus) {
  border-color: #409eff;
  outline: none;
}

/* Custom scrollbar for textarea - Light blue instead of black */
.job-profile-card :deep(.el-textarea__inner::-webkit-scrollbar) {
  width: 8px;
  height: 8px;
}

.job-profile-card :deep(.el-textarea__inner::-webkit-scrollbar-track) {
  background: #f5f7fa;
  border-radius: 4px;
}

.job-profile-card :deep(.el-textarea__inner::-webkit-scrollbar-thumb) {
  background: #b3d8ff;
  border-radius: 4px;
  transition: background 0.3s;
}

.job-profile-card :deep(.el-textarea__inner::-webkit-scrollbar-thumb:hover) {
  background: #79bbff;
}

.job-profile-card :deep(.el-textarea__inner::-webkit-scrollbar-thumb:active) {
  background: #409eff;
}

/* Firefox scrollbar */
.job-profile-card :deep(.el-textarea__inner) {
  scrollbar-width: thin;
  scrollbar-color: #b3d8ff #f5f7fa;
}

/* Select dropdown uniform styling */
.job-profile-card :deep(.el-select) {
  width: 100%;
}

.job-profile-card :deep(.el-select .el-input__wrapper) {
  min-height: 40px;
}

/* Form items alignment */
.job-profile-card :deep(.el-form-item) {
  display: flex;
  flex-direction: column;
  align-items: stretch;
}

/* Form labels */
.job-profile-card :deep(.el-form-item__label) {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
  margin-bottom: 8px;
  text-align: left;
  line-height: 1.5;
}

.job-profile-card :deep(.el-form-item__content) {
  display: flex;
  flex-direction: column;
  align-items: stretch;
}

.form-hint {
  font-size: 12px;
  color: #909399;
  margin-top: 6px;
  line-height: 1.5;
  padding-left: 2px;
}

.mapping-result-card {
  margin-bottom: 24px;
}

.mapping-result-card :deep(.el-card) {
  border: 2px solid #e4e7ed;
  transition: all 0.3s ease;
}

.mapping-result-card :deep(.el-card:hover) {
  border-color: #67c23a;
  box-shadow: 0 4px 12px rgba(103, 194, 58, 0.1);
}

.mapping-result-card h4 {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #303133;
}

/* Mapping results input styling */
.mapping-result-card :deep(.el-input__wrapper),
.mapping-result-card :deep(.el-select .el-input__wrapper) {
  min-height: 40px;
  box-shadow: 0 0 0 1px #dcdfe6 inset;
}

.mapping-result-card :deep(.el-input__wrapper:hover),
.mapping-result-card :deep(.el-select .el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #c0c4cc inset;
}

.mapping-result-card :deep(.el-input__wrapper.is-focus),
.mapping-result-card :deep(.el-select .el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #409eff inset !important;
}
</style>
