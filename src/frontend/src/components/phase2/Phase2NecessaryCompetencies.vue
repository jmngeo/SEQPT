<template>
  <el-card class="phase2-competencies step-card">
    <template #header>
      <div class="card-header">
        <h2>{{ pageTitle }}</h2>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          {{ pageDescription }}
        </p>
      </div>
    </template>

    <!-- Loading state -->
    <div v-if="loading" style="text-align: center; padding: 40px;">
      <el-icon class="is-loading" :size="40" color="#409eff">
        <Loading />
      </el-icon>
      <p style="margin-top: 16px; color: #606266;">Loading competencies...</p>
    </div>

    <!-- Error state -->
    <el-alert
      v-if="error"
      type="error"
      :closable="false"
      show-icon
      style="margin-bottom: 24px;"
    >
      <template #title>Error Loading Competencies</template>
      {{ error }}
    </el-alert>

    <!-- Content (only show when loaded and no error) -->
    <template v-if="!loading && !error">
      <!-- Selected roles summary (role-based only) -->
      <div v-if="pathway === 'ROLE_BASED'" class="roles-summary">
        <h3>Selected Roles ({{ selectedRoles.length }})</h3>
        <div class="roles-list">
          <el-tag
            v-for="role in selectedRoles"
            :key="role.id"
            type="primary"
            size="large"
            class="role-tag"
          >
            {{ role.orgRoleName || role.standardRoleName }}
          </el-tag>
        </div>
      </div>

      <!-- Task-based context summary -->
      <div v-if="pathway === 'TASK_BASED'" class="task-summary">
        <el-alert
          type="success"
          :closable="false"
          show-icon
          style="margin-bottom: 24px;"
        >
          <template #title>Task-Based Assessment</template>
          Competencies determined based on your task analysis and ISO process involvement.
        </el-alert>
      </div>

    <!-- Summary header -->
    <div class="summary-header">
      <div class="summary-stat">
        <span class="summary-value">{{ competencies.length }}</span>
        <span class="summary-label">Total Competencies</span>
      </div>
      <div class="summary-stat">
        <span class="summary-value">{{ competencyAreas.length }}</span>
        <span class="summary-label">Competency Areas</span>
      </div>
      <div v-if="pathway === 'ROLE_BASED'" class="summary-stat">
        <span class="summary-value">{{ selectedRoles.length }}</span>
        <span class="summary-label">Selected Roles</span>
      </div>
    </div>

    <el-divider style="margin: 24px 0" />

    <!-- Competencies grid view -->
    <div class="competencies-overview">
      <div
        v-for="area in competencyAreas"
        :key="area"
        class="area-group"
      >
        <h3 class="area-title">
          {{ area }}
          <span class="area-count">({{ competenciesByArea[area].length }})</span>
        </h3>

        <div class="competency-grid">
          <div
            v-for="comp in competenciesByArea[area]"
            :key="comp.competencyId"
            class="competency-card"
          >
            <div class="competency-card-content">
              <div class="competency-card-name">{{ comp.competencyName }}</div>
              <div v-if="comp.description" class="competency-card-description">
                {{ comp.description }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

      <!-- Actions -->
      <div class="step-actions">
        <el-button @click="handleBack">
          <el-icon class="el-icon--left"><ArrowLeft /></el-icon>
          {{ backButtonText }}
        </el-button>
        <el-button
          type="primary"
          size="large"
          @click="handleStartAssessment"
        >
          Start Competency Assessment
          <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
    </template>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ArrowLeft, ArrowRight, Loading } from '@element-plus/icons-vue'
import { toast } from 'vue3-toastify'
import axios from 'axios'

const props = defineProps({
  pathway: {
    type: String,
    required: true,
    validator: (value) => ['ROLE_BASED', 'TASK_BASED'].includes(value)
  },
  selectedRoles: {
    type: Array,
    default: () => []
  },
  username: {
    type: String,
    default: ''
  },
  organizationId: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['next', 'back'])

// State
const loading = ref(false)
const error = ref(null)
const competencies = ref([])

/**
 * Fetch competencies based on pathway
 */
const fetchCompetencies = async () => {
  loading.value = true
  error.value = null

  try {
    console.log('[Phase2NecessaryCompetencies] Fetching competencies for pathway:', props.pathway)

    if (props.pathway === 'TASK_BASED') {
      // Task-based: fetch from unknown_role_competency_matrix
      console.log('[Phase2NecessaryCompetencies] Task-based: using username:', props.username)

      const response = await axios.post('/api/get_required_competencies_for_roles', {
        survey_type: 'unknown_roles',
        user_name: props.username,
        organization_id: props.organizationId
      })

      console.log('[Phase2NecessaryCompetencies] Task-based response:', response.data)

      // Transform to expected format
      competencies.value = response.data.competencies.map(c => ({
        competencyId: c.competency_id,
        competencyName: c.competency_name,
        competencyArea: c.category,
        description: c.description,
        requiredLevel: c.max_value
      }))
    } else {
      // Role-based: fetch from role_competency_matrix
      console.log('[Phase2NecessaryCompetencies] Role-based: using role IDs:', props.selectedRoles.map(r => r.id))

      const response = await axios.post('/api/get_required_competencies_for_roles', {
        survey_type: 'known_roles',
        role_ids: props.selectedRoles.map(r => r.id),
        organization_id: props.organizationId
      })

      console.log('[Phase2NecessaryCompetencies] Role-based response:', response.data)

      // Transform to expected format
      competencies.value = response.data.competencies.map(c => ({
        competencyId: c.competency_id,
        competencyName: c.competency_name,
        competencyArea: c.category,
        description: c.description,
        requiredLevel: c.max_value
      }))
    }

    if (competencies.value.length === 0) {
      error.value = 'No competencies found for your selection. Please go back and try again.'
    } else {
      console.log('[Phase2NecessaryCompetencies] Loaded', competencies.value.length, 'competencies')
    }
  } catch (err) {
    console.error('[Phase2NecessaryCompetencies] Error fetching competencies:', err)
    error.value = err.response?.data?.message || err.message || 'Failed to load competencies. Please try again.'
    toast.error('Failed to load competencies')
  } finally {
    loading.value = false
  }
}

/**
 * Dynamic page title
 */
const pageTitle = computed(() => {
  if (props.pathway === 'TASK_BASED') {
    return 'Necessary Competencies for Your Tasks'
  }
  return 'Necessary Competencies for Selected Roles'
})

/**
 * Dynamic page description
 */
const pageDescription = computed(() => {
  if (props.pathway === 'TASK_BASED') {
    return `Based on your task analysis, the following ${competencies.value.length} competencies are required.`
  }
  return `Based on your role selection, the following ${competencies.value.length} competencies are required.`
})

/**
 * Dynamic back button text
 */
const backButtonText = computed(() => {
  if (props.pathway === 'TASK_BASED') {
    return 'Back to Task Input'
  }
  return 'Back to Role Selection'
})

/**
 * Get unique competency areas
 */
const competencyAreas = computed(() => {
  const areas = new Set(competencies.value.map(c => c.competencyArea))
  return Array.from(areas).sort()
})

/**
 * Group competencies by area
 */
const competenciesByArea = computed(() => {
  const grouped = {}
  competencies.value.forEach(comp => {
    if (!grouped[comp.competencyArea]) {
      grouped[comp.competencyArea] = []
    }
    grouped[comp.competencyArea].push(comp)
  })
  return grouped
})

/**
 * Estimated assessment time (2 minutes per competency)
 */
const estimatedTime = computed(() => {
  return Math.ceil(competencies.value.length * 2)
})

/**
 * Get competency level name
 */
const getLevelName = (level) => {
  const mapping = {
    0: 'Not Relevant',
    1: 'Know',
    2: 'Understand',
    4: 'Apply',
    6: 'Master'
  }
  return mapping[level] || 'Unknown'
}

/**
 * Get color for level tag
 */
const getLevelColor = (level) => {
  if (level >= 6) return 'danger'
  if (level >= 4) return 'warning'
  if (level >= 2) return 'success'
  return 'info'
}

/**
 * Start competency assessment (proceed to Task 2)
 */
const handleStartAssessment = () => {
  console.log('[Phase2] Starting assessment for', competencies.value.length, 'competencies')
  toast.info('Starting competency assessment...')

  emit('next', {
    competencies: competencies.value,
    selectedRoles: props.selectedRoles,
    organizationId: props.organizationId,
    pathway: props.pathway,
    username: props.username
  })
}

/**
 * Go back to previous step
 */
const handleBack = () => {
  emit('back')
}

/**
 * Fetch competencies when component mounts
 */
onMounted(() => {
  console.log('[Phase2NecessaryCompetencies] Component mounted, pathway:', props.pathway)
  fetchCompetencies()
})
</script>

<style scoped>
.phase2-competencies {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

/* Roles summary */
.roles-summary {
  margin-bottom: 20px;
}

.roles-summary h3 {
  font-size: 16px;
  color: #606266;
  margin-bottom: 12px;
}

.roles-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.role-tag {
  font-size: 14px;
  padding: 8px 16px;
}

/* Summary header */
.summary-header {
  display: flex;
  justify-content: center;
  gap: 48px;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 8px;
  margin-bottom: 24px;
  border: 1px solid #e4e7ed;
}

.summary-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.summary-value {
  font-size: 32px;
  font-weight: 700;
  color: #409eff;
  line-height: 1;
}

.summary-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
  text-align: center;
}

/* Competencies overview */
.competencies-overview {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.area-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.area-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin: 0;
  padding-bottom: 8px;
  border-bottom: 1px solid #dcdfe6;
}

.area-count {
  font-size: 14px;
  font-weight: 500;
  color: #909399;
  margin-left: 8px;
}

/* Competency grid */
.competency-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
}

/* Competency cards - matching role-card style */
.competency-card {
  border: 2px solid #EBEEF5;
  border-radius: 8px;
  padding: 1.5rem;
  background: white;
  display: flex;
  flex-direction: column;
  min-height: 140px;
  transition: all 0.3s ease;
  cursor: default;
}

.competency-card:hover {
  border-color: #409EFF;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.2);
}

.competency-card-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
  height: 100%;
}

.competency-card-name {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  line-height: 1.4;
  word-wrap: break-word;
}

.competency-card-description {
  font-size: 12px;
  color: #606266;
  line-height: 1.5;
  word-wrap: break-word;
  flex: 1;
}

/* Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 32px;
  padding-top: 20px;
  border-top: 1px solid #dcdfe6;
}

/* Responsive */
@media (max-width: 768px) {
  .summary-header {
    flex-wrap: wrap;
    gap: 16px;
  }

  .summary-stat {
    min-width: calc(50% - 8px);
  }

  .summary-value {
    font-size: 24px;
  }

  .competency-grid {
    grid-template-columns: 1fr;
  }

  .step-actions {
    flex-direction: column;
    gap: 12px;
  }

  .step-actions button {
    width: 100%;
  }
}
</style>
