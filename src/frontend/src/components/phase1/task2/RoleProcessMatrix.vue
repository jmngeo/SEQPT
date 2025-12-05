<template>
  <el-card class="role-process-matrix-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Define Role-Process Relationships</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Define how each role in your organization relates to the Systems Engineering processes.
          This helps determine competency requirements for each role.
        </p>
      </div>
    </template>

    <!-- Baseline values info -->
    <el-alert
      type="success"
      :closable="false"
      show-icon
      style="margin-bottom: 16px;"
    >
      <template #default>
        <div>
          <strong>Smart Initialized Values</strong>
          <p style="margin: 8px 0 0 0; font-size: 13px; line-height: 1.5;">
            <strong>SE Cluster Roles:</strong> Initialized with baseline involvement values from <strong>Könemann et al.</strong><br/>
            <strong>Custom Roles:</strong> AI-generated intelligent starting values based on role description and context.<br/>
            <strong>All values are editable</strong> - review and adjust them to match your organization's structure.
          </p>
        </div>
      </template>
    </el-alert>

    <!-- Info alert with involvement scale -->
    <el-alert
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    >
      <template #default>
        <div>
          <strong>Process Involvement Scale (0-3):</strong>
          <ul style="margin: 8px 0 0 0; padding-left: 20px;">
            <li><strong>0</strong> = Not involved | <strong>1</strong> = Supports | <strong>2</strong> = Performs/Responsible | <strong>3</strong> = Leads/Accountable</li>
            <li>Values represent the level of involvement each role has in SE processes</li>
            <li><em>Optional RACI Guidelines:</em> Each process ideally has one role with value 2 and at most one with value 3</li>
            <li>You can save and continue even if guidelines aren't strictly followed</li>
          </ul>
        </div>
      </template>
    </el-alert>


    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <el-icon class="is-loading" :size="40"><Loading /></el-icon>
      <p>Loading processes and matrix data...</p>
    </div>

    <!-- Matrix Content -->
    <div v-else-if="roles.length > 0 && processes.length > 0">
      <!-- Role Summary -->
      <div class="role-summary">
        <div class="summary-item">
          <el-icon :size="20" color="#409EFF"><User /></el-icon>
          <span><strong>Roles:</strong> {{ roles.length }}</span>
        </div>
        <div class="summary-item">
          <el-icon :size="20" color="#67C23A"><List /></el-icon>
          <span><strong>Processes:</strong> {{ processes.length }}</span>
        </div>
        <div v-if="changedCellsCount > 0" class="summary-item">
          <el-icon :size="20" color="#E6A23C"><Edit /></el-icon>
          <span><strong>Changes:</strong> {{ changedCellsCount }} cells modified</span>
        </div>
      </div>

      <!-- Matrix Table: TRANSPOSED - Processes as Rows, Roles as Columns -->
      <div class="matrix-table-container">
        <el-table
          :data="processes"
          border
          stripe
          style="width: 100%"
          :header-cell-style="{ background: '#f5f7fa', fontWeight: 'bold' }"
          :row-class-name="getProcessRowClass"
          max-height="600"
        >
          <!-- Process Column (Fixed Left) -->
          <el-table-column
            label="SE Process"
            width="250"
            fixed
          >
            <template #default="{ row }">
              <div class="process-cell">
                <div class="process-name">{{ row.name }}</div>
                <!-- Validation Icons -->
                <div v-if="getProcessValidation(row.id).isValid" class="validation-icon valid">
                  <el-icon color="#67C23A"><CircleCheck /></el-icon>
                </div>
                <div v-else class="validation-icon invalid">
                  <el-tooltip :content="getProcessValidation(row.id).message" placement="right">
                    <el-icon color="#F56C6C"><CircleClose /></el-icon>
                  </el-tooltip>
                </div>
              </div>
            </template>
          </el-table-column>

          <!-- Role Columns (Dynamic) -->
          <el-table-column
            v-for="role in roles"
            :key="role.id"
            :width="140"
            align="center"
          >
            <template #header>
              <div class="role-header">
                <div class="role-header-name">{{ role.orgRoleName || role.role_name }}</div>
                <div v-if="role.standardRoleName" class="role-header-cluster">
                  ({{ role.standardRoleName }})
                </div>
                <div v-else-if="role.identification_method === 'CUSTOM'" class="role-header-badge">
                  <el-tag size="small" type="warning">Custom</el-tag>
                </div>
              </div>
            </template>
            <template #default="{ row: process }">
              <el-input-number
                v-model="matrix[process.id][role.id]"
                :min="0"
                :max="3"
                :step="1"
                size="small"
                controls-position="right"
                :class="{ 'cell-changed': isCellChanged(process.id, role.id) }"
                @change="updateCellValue(process.id, role.id)"
                style="width: 100%"
              />
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- Legend -->
      <div class="legend-section">
        <el-divider content-position="left">
          <strong>Legend & RACI Values</strong>
        </el-divider>
        <div class="legend-items">
          <div class="legend-item">
            <el-tag size="small" type="info">0</el-tag>
            <span>Not Involved</span>
          </div>
          <div class="legend-item">
            <el-tag size="small" type="success">1</el-tag>
            <span>Supports (provides assistance)</span>
          </div>
          <div class="legend-item">
            <el-tag size="small" type="warning">2</el-tag>
            <span>Responsible (executes tasks) - <strong>Required: Exactly 1 per process</strong></span>
          </div>
          <div class="legend-item">
            <el-tag size="small" type="danger">3</el-tag>
            <span>Accountable/Designs (owns and decides) - <strong>Max: 1 per process</strong></span>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="empty-state">
      <el-icon :size="48" color="#C0C4CC"><Warning /></el-icon>
      <p>No roles or processes available. Please complete the previous steps.</p>
    </div>

    <!-- Actions -->
    <div class="step-actions" style="margin-top: 32px;">
      <el-button
        size="large"
        @click="handleBack"
      >
        <el-icon><ArrowLeft /></el-icon>
        Back to Role Selection
      </el-button>
      <el-button
        type="primary"
        size="large"
        :loading="saving"
        :disabled="roles.length === 0"
        @click="handleSave"
      >
        Save & Continue
        <el-icon><ArrowRight /></el-icon>
      </el-button>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import axios from '@/api/axios'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Loading,
  User,
  List,
  Edit,
  Warning,
  ArrowLeft,
  ArrowRight,
  CircleCheck,
  CircleClose
} from '@element-plus/icons-vue'

const props = defineProps({
  maturityId: {
    type: Number,
    required: true
  },
  roles: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()
const loading = ref(false)
const saving = ref(false)
const roles = ref([])
const processes = ref([])
const matrix = ref({}) // { processId: { roleId: value } }
const originalMatrix = ref({}) // Track original values for change detection
const changedCells = ref(new Set()) // Track which cells have been changed

// Changed cells count
const changedCellsCount = computed(() => changedCells.value.size)

// RACI Validation Functions
const validateProcess = (processId) => {
  if (!matrix.value[processId]) {
    return {
      hasResponsible: false,
      responsibleCount: 0,
      accountableCount: 0,
      isValid: false,
      message: 'No data for this process'
    }
  }

  const values = roles.value.map(role => matrix.value[processId][role.id] || 0)
  const responsibleCount = values.filter(v => v === 2).length
  const accountableCount = values.filter(v => v === 3).length

  const hasResponsible = responsibleCount === 1
  const validAccountable = accountableCount <= 1
  const isValid = hasResponsible && validAccountable

  let message = ''
  if (!hasResponsible) {
    if (responsibleCount === 0) {
      message = 'Missing Responsible role (need exactly 1 role with value 2)'
    } else {
      message = `Multiple Responsible roles (${responsibleCount} found, need exactly 1)`
    }
  } else if (!validAccountable) {
    message = `Multiple Accountable roles (${accountableCount} found, max is 1)`
  } else {
    message = 'Valid'
  }

  return {
    hasResponsible,
    responsibleCount,
    accountableCount,
    isValid,
    message
  }
}

const getProcessValidation = (processId) => {
  return validateProcess(processId)
}

// Validation computed properties
const processValidations = computed(() => {
  const validations = {}
  processes.value.forEach(process => {
    validations[process.id] = validateProcess(process.id)
  })
  return validations
})

const allProcessesValid = computed(() => {
  return Object.values(processValidations.value).every(v => v.isValid)
})

const invalidProcessCount = computed(() => {
  return Object.values(processValidations.value).filter(v => !v.isValid).length
})

const processesWithoutResponsible = computed(() => {
  return processes.value.filter(p =>
    processValidations.value[p.id] && !processValidations.value[p.id].hasResponsible
  )
})

const processesWithMultipleResponsible = computed(() => {
  return processes.value.filter(p =>
    processValidations.value[p.id] && processValidations.value[p.id].responsibleCount > 1
  )
})

const processesWithMultipleAccountable = computed(() => {
  return processes.value.filter(p =>
    processValidations.value[p.id] && processValidations.value[p.id].accountableCount > 1
  )
})

// Row class for validation highlighting
const getProcessRowClass = ({ row }) => {
  const validation = getProcessValidation(row.id)
  if (!validation.isValid) {
    return 'invalid-process-row'
  }
  return ''
}

// Check if a cell has been changed
const isCellChanged = (processId, roleId) => {
  return changedCells.value.has(`${processId}-${roleId}`)
}

// Update cell value and track changes
const updateCellValue = (processId, roleId) => {
  const newValue = matrix.value[processId][roleId]

  // Check if value differs from original
  if (originalMatrix.value[processId][roleId] !== newValue) {
    changedCells.value.add(`${processId}-${roleId}`)
  } else {
    changedCells.value.delete(`${processId}-${roleId}`)
  }
}

// Fetch roles and processes
const fetchRolesAndProcesses = async () => {
  try {
    loading.value = true

    // Fetch processes
    const processResponse = await axios.get('/api/roles-and-processes')
    console.log('[RoleProcessMatrix] API Response:', processResponse.data)

    // Handle both possible response structures
    processes.value = processResponse.data.processes || processResponse.data.se_processes || []

    // Use roles from props (already saved with IDs from database)
    roles.value = props.roles

    console.log('[RoleProcessMatrix] Roles:', roles.value)
    console.log('[RoleProcessMatrix] Processes:', processes.value)

    if (!processes.value || processes.value.length === 0) {
      console.warn('[RoleProcessMatrix] No processes loaded')
      ElMessage.warning('No processes found')
    }
  } catch (error) {
    console.error('[RoleProcessMatrix] Error fetching data:', error)
    ElMessage.error('Failed to load processes')
  } finally {
    loading.value = false
  }
}

// Fetch existing matrix values for all roles
const fetchMatrixValues = async () => {
  if (!authStore.organizationId || roles.value.length === 0) return

  // Guard against undefined processes
  if (!processes.value || processes.value.length === 0) {
    console.error('[RoleProcessMatrix] Cannot fetch matrix: processes not loaded')
    ElMessage.error('Cannot load matrix: processes data missing')
    return
  }

  try {
    loading.value = true
    const matrixData = {}
    const originalData = {}

    // Initialize matrix structure: matrix[processId][roleId] = value
    processes.value.forEach(process => {
      matrixData[process.id] = {}
      originalData[process.id] = {}

      // Initialize all cells to 0
      roles.value.forEach(role => {
        matrixData[process.id][role.id] = 0
        originalData[process.id][role.id] = 0
      })
    })

    // Fetch matrix for each role and populate
    for (const role of roles.value) {
      try {
        console.log(`[RoleProcessMatrix] Fetching matrix for role ID ${role.id} (${role.orgRoleName})`)
        const response = await axios.get(
          `/api/role-process-matrix/${authStore.organizationId}/${role.id}`
        )

        console.log(`[RoleProcessMatrix] Received ${response.data.length} entries for role ${role.id}`)

        // Populate matrix with fetched values
        response.data.forEach(entry => {
          const processId = entry.iso_process_id
          const value = entry.role_process_value
          if (matrixData[processId]) {
            matrixData[processId][role.id] = value
            originalData[processId][role.id] = value
          }
        })

        // Log first few values for debugging
        if (response.data.length > 0) {
          console.log(`[RoleProcessMatrix] Sample values for role ${role.id}:`,
            response.data.slice(0, 3).map(e => `Process ${e.iso_process_id}=${e.role_process_value}`).join(', '))
        }
      } catch (error) {
        console.error(`[RoleProcessMatrix] Error fetching matrix for role ${role.id}:`, error)
        // Continue with zeros for this role
      }
    }

    matrix.value = matrixData
    originalMatrix.value = JSON.parse(JSON.stringify(originalData))
    changedCells.value.clear()

    console.log('[RoleProcessMatrix] Matrix loaded:', matrix.value)
  } catch (error) {
    console.error('[RoleProcessMatrix] Error fetching matrix:', error)
    ElMessage.error('Failed to load existing matrix values')
  } finally {
    loading.value = false
  }
}

// Save matrix values
const handleSave = async () => {
  saving.value = true
  try {
    // Save each role's matrix separately (API expects one role at a time)
    for (const role of roles.value) {
      // Prepare matrix for this role: { processId: value }
      const roleMatrix = {}
      processes.value.forEach(process => {
        roleMatrix[process.id] = matrix.value[process.id][role.id]
      })

      // Call API for this role
      await axios.put('/api/role-process-matrix/bulk', {
        organization_id: authStore.organizationId,
        role_cluster_id: role.id,
        matrix: roleMatrix
      })

      console.log(`[RoleProcessMatrix] Saved matrix for role ${role.id}`)
    }

    ElMessage.success('Role-process matrix saved successfully!')

    // Reset change tracking
    originalMatrix.value = JSON.parse(JSON.stringify(matrix.value))
    changedCells.value.clear()

    // Emit completion
    emit('complete', {
      matrixSaved: true
    })
  } catch (error) {
    console.error('[RoleProcessMatrix] Save failed:', error)
    ElMessage.error('Failed to save matrix. Please try again.')
  } finally {
    saving.value = false
  }
}

const handleBack = () => {
  if (changedCells.value.size > 0) {
    ElMessageBox.confirm(
      'You have unsaved changes. Are you sure you want to go back?',
      'Unsaved Changes',
      {
        confirmButtonText: 'Go Back',
        cancelButtonText: 'Stay',
        type: 'warning'
      }
    ).then(() => {
      emit('back')
    }).catch(() => {
      // User cancelled, stay on page
    })
  } else {
    emit('back')
  }
}

// Initialize
onMounted(async () => {
  console.log('[RoleProcessMatrix] Mounted with roles:', props.roles)
  await fetchRolesAndProcesses()
  await fetchMatrixValues()
})
</script>

<style scoped>
.role-process-matrix-container {
  max-width: 100%;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

/* Validation Summary */
.validation-summary {
  margin-bottom: 20px;
}

/* Loading */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #909399;
}

.loading-container p {
  margin-top: 16px;
  font-size: 14px;
}

/* Role Summary */
.role-summary {
  display: flex;
  gap: 24px;
  padding: 16px 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
  border-radius: 8px;
  margin-bottom: 24px;
  border: 1px solid #e4e7ed;
}

.summary-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #606266;
}

/* Matrix Table */
.matrix-table-container {
  margin-bottom: 24px;
  overflow-x: auto;
  overflow-y: visible;
  position: relative;
}

/* Force scrollbar to always be visible */
.matrix-table-container::-webkit-scrollbar {
  height: 12px;
  -webkit-appearance: none;
}

.matrix-table-container::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 6px;
}

.matrix-table-container::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 6px;
}

.matrix-table-container::-webkit-scrollbar-thumb:hover {
  background: #555;
}

/* Process Cell */
.process-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
  position: relative;
  padding-right: 28px; /* Space for validation icon */
  min-height: 36px; /* Ensure enough height for icon */
}

.process-name {
  font-weight: 500;
  color: #303133;
  font-size: 13px;
  line-height: 1.4;
  word-wrap: break-word;
}

.validation-icon {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  right: 4px;
  flex-shrink: 0;
  line-height: 1;
}

/* Role Header */
.role-header {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: center;
  padding: 8px 4px;
}

.role-header-name {
  font-weight: 600;
  font-size: 13px;
  color: #303133;
  text-align: center;
  word-wrap: break-word;
  line-height: 1.3;
}

.role-header-cluster {
  font-size: 11px;
  color: #606266;
  text-align: center;
  line-height: 1.2;
}

.role-header-badge {
  margin-top: 2px;
}

/* Changed cell highlighting */
.cell-changed :deep(.el-input-number__decrease),
.cell-changed :deep(.el-input-number__increase) {
  background-color: #FFF7E6 !important;
}

.cell-changed :deep(input) {
  background-color: #FFF7E6 !important;
}

/* Invalid row highlighting */
:deep(.invalid-process-row) {
  background-color: #FEF0F0 !important;
}

:deep(.invalid-process-row:hover) {
  background-color: #FDE2E2 !important;
}

/* Legend */
.legend-section {
  margin-top: 24px;
}

.legend-items {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #606266;
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #909399;
  text-align: center;
}

.empty-state p {
  margin-top: 16px;
  font-size: 14px;
}

/* Step Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #e4e7ed;
}
</style>
