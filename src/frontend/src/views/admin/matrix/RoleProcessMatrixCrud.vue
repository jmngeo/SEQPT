<template>
  <div class="admin-matrix-container">
    <!-- Header -->
    <div class="page-header">
      <h1 class="page-title">Role-Process Matrix Management</h1>
      <p class="page-subtitle">
        Manage role-process relationships for <strong>{{ organizationName }}</strong>. Changes will automatically recalculate the role-competency matrix.
      </p>
    </div>

    <!-- Matrix Content -->
    <div v-if="authStore.organizationId">
      <el-card class="matrix-card" shadow="hover">

        <!-- Loading State -->
        <div v-if="loading" class="loading-container">
          <el-icon class="is-loading" :size="40"><Loading /></el-icon>
          <p>Loading matrix data...</p>
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
                    <div class="role-header-name">{{ role.org_role_name || role.role_name }}</div>
                    <div v-if="role.standard_role_name" class="role-header-cluster">
                      ({{ role.standard_role_name }})
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

          <!-- Actions -->
          <div class="action-buttons">
            <el-button
              size="large"
              @click="handleReset"
              :disabled="changedCellsCount === 0"
            >
              <el-icon><RefreshLeft /></el-icon>
              Reset Changes
            </el-button>
            <el-button
              type="primary"
              size="large"
              :loading="saving"
              :disabled="!allProcessesValid || roles.length === 0 || changedCellsCount === 0"
              @click="handleSave"
            >
              <el-icon><Check /></el-icon>
              Save Changes ({{ changedCellsCount }} cells)
            </el-button>
          </div>
        </div>

        <!-- Empty State -->
        <div v-else class="empty-state">
          <el-icon :size="48" color="#C0C4CC"><Warning /></el-icon>
          <p>No roles found for this organization.</p>
          <p style="font-size: 13px; color: #909399; margin-top: 8px;">
            Organization must complete Phase 1 Task 2 to define roles before the matrix can be edited.
          </p>
        </div>
      </el-card>
    </div>

    <!-- No Organization State -->
    <el-empty
      v-else
      description="No organization found. Please ensure you are logged in with a valid organization account."
      :image-size="200"
    />
  </div>
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
  CircleCheck,
  CircleClose,
  Check,
  RefreshLeft
} from '@element-plus/icons-vue'

const authStore = useAuthStore()

// Data
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

// Get organization name
const organizationName = computed(() => authStore.organizationName || 'Your Organization')

// Fetch processes
const fetchProcesses = async () => {
  try {
    const processResponse = await axios.get('/roles_and_processes')
    processes.value = processResponse.data.processes
    console.log('[AdminMatrix] Processes loaded:', processes.value)
  } catch (error) {
    console.error('[AdminMatrix] Error fetching processes:', error)
    ElMessage.error('Failed to load processes')
  }
}

// Fetch roles for organization
const fetchOrganizationRoles = async () => {
  if (!authStore.organizationId) return

  try {
    loading.value = true
    const response = await axios.get(`/organization_roles/${authStore.organizationId}`)
    roles.value = response.data
    console.log('[AdminMatrix] Organization roles loaded:', roles.value)
  } catch (error) {
    console.error('[AdminMatrix] Error fetching roles:', error)
    ElMessage.error('Failed to load organization roles')
    roles.value = []
  } finally {
    loading.value = false
  }
}

// Fetch existing matrix values for all roles
const fetchMatrixValues = async () => {
  if (!authStore.organizationId || roles.value.length === 0) return

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
        console.log(`[AdminMatrix] Fetching matrix for role ID ${role.id} (${role.org_role_name})`)
        const response = await axios.get(
          `/role_process_matrix/${authStore.organizationId}/${role.id}`
        )

        console.log(`[AdminMatrix] Received ${response.data.length} entries for role ${role.id}`)

        // Populate matrix with fetched values
        response.data.forEach(entry => {
          const processId = entry.iso_process_id
          const value = entry.role_process_value
          if (matrixData[processId]) {
            matrixData[processId][role.id] = value
            originalData[processId][role.id] = value
          }
        })
      } catch (error) {
        console.error(`[AdminMatrix] Error fetching matrix for role ${role.id}:`, error)
        // Continue with zeros for this role
      }
    }

    matrix.value = matrixData
    originalMatrix.value = JSON.parse(JSON.stringify(originalData))
    changedCells.value.clear()

    console.log('[AdminMatrix] Matrix loaded successfully')
  } catch (error) {
    console.error('[AdminMatrix] Error fetching matrix:', error)
    ElMessage.error('Failed to load existing matrix values')
  } finally {
    loading.value = false
  }
}

// Save matrix values
const handleSave = async () => {
  if (!allProcessesValid.value) {
    ElMessage.error('Please fix validation errors before saving')
    return
  }

  if (changedCellsCount.value === 0) {
    ElMessage.info('No changes to save')
    return
  }

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
      await axios.put('/role_process_matrix/bulk', {
        organization_id: authStore.organizationId,
        role_cluster_id: role.id,
        matrix: roleMatrix
      })

      console.log(`[AdminMatrix] Saved matrix for role ${role.id}`)
    }

    ElMessage.success('Role-process matrix saved successfully! Role-competency matrix has been recalculated.')

    // Reset change tracking
    originalMatrix.value = JSON.parse(JSON.stringify(matrix.value))
    changedCells.value.clear()
  } catch (error) {
    console.error('[AdminMatrix] Save failed:', error)
    ElMessage.error('Failed to save matrix. Please try again.')
  } finally {
    saving.value = false
  }
}

// Reset changes
const handleReset = () => {
  if (changedCells.value.size === 0) return

  ElMessageBox.confirm(
    'Are you sure you want to discard all unsaved changes?',
    'Reset Changes',
    {
      confirmButtonText: 'Reset',
      cancelButtonText: 'Cancel',
      type: 'warning'
    }
  ).then(() => {
    matrix.value = JSON.parse(JSON.stringify(originalMatrix.value))
    changedCells.value.clear()
    ElMessage.success('Changes have been reset')
  }).catch(() => {
    // User cancelled
  })
}

// Initialize
onMounted(async () => {
  console.log('[AdminMatrix] Mounted - Organization ID:', authStore.organizationId)
  await fetchProcesses()
  await fetchOrganizationRoles()
  if (roles.value.length > 0) {
    await fetchMatrixValues()
  }
})
</script>

<style scoped>
.admin-matrix-container {
  padding: 24px;
  padding-left: 40px;
  max-width: 100%;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 24px;
  padding-left: 16px;
}

.page-title {
  margin: 0 0 8px 0;
  font-size: 28px;
  font-weight: 600;
  color: #303133;
}

.page-subtitle {
  margin: 0;
  font-size: 14px;
  color: #606266;
  line-height: 1.5;
}

.matrix-card {
  margin-bottom: 24px;
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

/* Action Buttons */
.action-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding-top: 20px;
  border-top: 1px solid #e4e7ed;
  margin-top: 24px;
}
</style>
