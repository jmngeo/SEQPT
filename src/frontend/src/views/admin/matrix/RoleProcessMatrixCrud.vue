<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from '@/api/axios';

// Reactive data for roles, processes, and matrix
const organizationId = ref(null);
const organizationName = ref('');
const roles = ref([]);
const processes = ref([]);
const roleProcessMatrix = ref({}); // { roleId: { processId: value } }
const originalMatrix = ref({}); // Track original values for change detection
const changedCells = ref(new Set()); // Track which cells have been changed
const loading = ref(false);
const saving = ref(false);

// Get admin's organization from localStorage
const getAdminOrganization = () => {
  const orgId = localStorage.getItem('user_organization_id');
  const orgName = localStorage.getItem('user_organization_name');

  if (!orgId) {
    console.error('No organization found for admin. Please login again.');
    return false;
  }

  organizationId.value = parseInt(orgId);
  organizationName.value = orgName || 'Your Organization';
  return true;
};

// Fetch roles and processes
const fetchRolesAndProcesses = async () => {
  try {
    loading.value = true;
    const response = await axios.get('/roles_and_processes');
    roles.value = response.data.roles;
    processes.value = response.data.processes;
  } catch (error) {
    console.error('Error fetching roles and processes:', error);
  } finally {
    loading.value = false;
  }
};

// Fetch role-process matrix for ALL roles in the organization
const fetchAllRoleProcessMatrices = async () => {
  if (!organizationId.value) return;

  try {
    loading.value = true;
    const matrixData = {};
    const originalData = {};

    // Fetch matrix for each role
    for (const role of roles.value) {
      const response = await axios.get(`/role_process_matrix/${organizationId.value}/${role.id}`);

      matrixData[role.id] = {};
      originalData[role.id] = {};

      processes.value.forEach(process => {
        const entry = response.data.find(e => e.iso_process_id === process.id);
        const value = entry ? entry.role_process_value : 0;
        matrixData[role.id][process.id] = value;
        originalData[role.id][process.id] = value;
      });
    }

    roleProcessMatrix.value = matrixData;
    originalMatrix.value = JSON.parse(JSON.stringify(originalData));
    changedCells.value.clear();
  } catch (error) {
    console.error('Error fetching role-process matrices:', error);
  } finally {
    loading.value = false;
  }
};

// Check if a cell has been changed
const isCellChanged = (roleId, processId) => {
  return changedCells.value.has(`${roleId}-${processId}`);
};

// Update cell value and track changes
const updateCellValue = (roleId, processId, newValue) => {
  roleProcessMatrix.value[roleId][processId] = newValue;

  // Check if value differs from original
  if (originalMatrix.value[roleId][processId] !== newValue) {
    changedCells.value.add(`${roleId}-${processId}`);
  } else {
    changedCells.value.delete(`${roleId}-${processId}`);
  }
};

// Get cell class for styling
const getCellClass = (roleId, processId) => {
  return isCellChanged(roleId, processId) ? 'cell-changed' : '';
};

// Value options for dropdown (just numbers, legend shows meaning)
const valueOptions = [
  { value: 0, label: '0' },
  { value: 1, label: '1' },
  { value: 2, label: '2' },
  { value: 3, label: '3' }
];

// Check if there are unsaved changes
const hasUnsavedChanges = computed(() => changedCells.value.size > 0);

// Save all changes to the role-process matrix
const saveAllChanges = async () => {
  if (!organizationId.value || !hasUnsavedChanges.value) return;

  try {
    saving.value = true;

    // Save matrix for each role that has changes
    const rolesToUpdate = new Set();
    changedCells.value.forEach(cellKey => {
      const [roleId] = cellKey.split('-');
      rolesToUpdate.add(parseInt(roleId));
    });

    for (const roleId of rolesToUpdate) {
      await axios.put('/role_process_matrix/bulk', {
        organization_id: organizationId.value,
        role_cluster_id: roleId,
        matrix: roleProcessMatrix.value[roleId]
      });
    }

    // Update original matrix to current values
    originalMatrix.value = JSON.parse(JSON.stringify(roleProcessMatrix.value));

    // Clear changed cells after successful save
    changedCells.value.clear();

    alert(`Changes saved successfully!\n\nRole-Competency Matrix has been automatically recalculated for your organization.`);
  } catch (error) {
    console.error('Error saving role-process matrix:', error);
    alert("Error saving changes. Please try again.");
  } finally {
    saving.value = false;
  }
};

// Reset all changes
const resetChanges = () => {
  if (confirm('Are you sure you want to discard all unsaved changes?')) {
    roleProcessMatrix.value = JSON.parse(JSON.stringify(originalMatrix.value));
    changedCells.value.clear();
  }
};

// Initialize on component mount
onMounted(async () => {
  // Get admin's organization
  if (!getAdminOrganization()) {
    alert('No organization found. Please login again.');
    return;
  }

  // Fetch roles and processes
  await fetchRolesAndProcesses();

  // Fetch all matrices
  if (roles.value.length > 0) {
    await fetchAllRoleProcessMatrices();
  }
});
</script>

<template>
  <div class="matrix-crud-container">
    <div class="matrix-content">
      <h1 class="matrix-title">Role-Process Matrix</h1>

      <!-- Organization info -->
      <div v-if="organizationId" class="info-banner">
        <div class="banner-header">
          <span class="info-icon">ℹ</span>
          <strong>Organization-Specific Matrix:</strong> {{ organizationName }}
        </div>
        <div class="banner-body">
          This matrix is organization-specific and only affects <strong>{{ organizationName }}</strong>.
          Modified cells are highlighted in yellow. After saving, the Role-Competency Matrix will be automatically recalculated.
        </div>
      </div>

      <!-- Legend -->
      <div class="legend-container">
        <div class="legend-title">Value Legend:</div>
        <div class="legend-items">
          <div class="legend-item">
            <span class="legend-value">0</span>
            <span class="legend-label">Not Relevant</span>
          </div>
          <div class="legend-item">
            <span class="legend-value">1</span>
            <span class="legend-label">Supporting</span>
          </div>
          <div class="legend-item">
            <span class="legend-value">2</span>
            <span class="legend-label">Responsible</span>
          </div>
          <div class="legend-item">
            <span class="legend-value">3</span>
            <span class="legend-label">Designing</span>
          </div>
        </div>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="loading-container">
        <div class="loading-spinner"></div>
        <p>Loading matrix data...</p>
      </div>

      <!-- Excel-style grid -->
      <div v-else-if="roles.length > 0 && processes.length > 0" class="matrix-grid-container">
        <div class="matrix-grid-wrapper">
          <table class="matrix-grid">
            <thead>
              <tr>
                <th class="corner-cell">
                  <div class="corner-content">
                    <span class="corner-label-top">Roles →</span>
                    <span class="corner-label-bottom">Processes ↓</span>
                  </div>
                </th>
                <th
                  v-for="role in roles"
                  :key="role.id"
                  class="header-cell role-header"
                >
                  <div class="header-content">{{ role.name }}</div>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="process in processes" :key="process.id">
                <td class="header-cell process-header">
                  <div class="header-content">{{ process.name }}</div>
                </td>
                <td
                  v-for="role in roles"
                  :key="`${role.id}-${process.id}`"
                  class="data-cell"
                  :class="getCellClass(role.id, process.id)"
                >
                  <el-select
                    :model-value="roleProcessMatrix[role.id]?.[process.id]"
                    @change="(val) => updateCellValue(role.id, process.id, val)"
                    placeholder="Select"
                    size="small"
                    class="cell-select"
                  >
                    <el-option
                      v-for="option in valueOptions"
                      :key="option.value"
                      :label="option.label"
                      :value="option.value"
                    />
                  </el-select>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Action buttons -->
        <div class="action-buttons">
          <el-button
            type="primary"
            size="large"
            :disabled="!hasUnsavedChanges || saving"
            :loading="saving"
            @click="saveAllChanges"
          >
            Save All Changes ({{ changedCells.size }} cells modified)
          </el-button>
          <el-button
            size="large"
            :disabled="!hasUnsavedChanges || saving"
            @click="resetChanges"
          >
            Reset Changes
          </el-button>
        </div>

        <!-- Change summary -->
        <div v-if="hasUnsavedChanges" class="change-summary">
          <span class="warning-icon">⚠</span>
          <span>{{ changedCells.size }} cell(s) modified and not yet saved</span>
        </div>
      </div>

      <!-- Empty state -->
      <el-alert
        v-else-if="!loading"
        title="No Data Available"
        type="warning"
        description="No roles or processes found. Please ensure database is populated."
        :closable="false"
        style="margin-top: 20px; max-width: 800px;"
      />
    </div>
  </div>
</template>

<style scoped>
.matrix-crud-container {
  min-height: 100vh;
  padding: var(--se-spacing-xl);
  background-color: var(--se-bg-secondary);
}

.matrix-content {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.matrix-title {
  font-size: var(--se-font-size-extra-large);
  font-weight: var(--se-font-weight-primary);
  color: var(--se-text-primary);
  margin-bottom: var(--se-spacing-xl);
  text-align: center;
}

.legend-container {
  width: 100%;
  max-width: 1200px;
  padding: var(--se-spacing-base);
  margin-bottom: var(--se-spacing-lg);
  background-color: var(--se-bg-primary);
  border-radius: var(--se-border-radius-base);
  border: 1px solid var(--se-border-lighter);
}

.legend-title {
  font-weight: var(--se-font-weight-secondary);
  color: var(--se-text-secondary);
  margin-bottom: var(--se-spacing-sm);
  font-size: var(--se-font-size-small);
}

.legend-items {
  display: flex;
  gap: var(--se-spacing-lg);
  flex-wrap: wrap;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: var(--se-spacing-xs);
}

.legend-value {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  background-color: var(--se-primary);
  color: white;
  border-radius: 4px;
  font-weight: var(--se-font-weight-secondary);
  font-size: var(--se-font-size-small);
}

.legend-label {
  color: var(--se-text-primary);
  font-size: var(--se-font-size-small);
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--se-spacing-base);
  padding: var(--se-spacing-xl);
  color: var(--se-text-secondary);
  font-family: var(--se-font-family);
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--se-border-lighter);
  border-top-color: var(--se-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.matrix-grid-container {
  width: 100%;
  max-width: 1400px;
  margin-bottom: var(--se-spacing-lg);
}

.matrix-grid-wrapper {
  overflow-x: auto;
  background-color: var(--se-bg-primary);
  border-radius: var(--se-border-radius-base);
  box-shadow: var(--se-shadow-base);
  margin-bottom: var(--se-spacing-lg);
}

.matrix-grid {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--se-font-size-small);
}

.corner-cell {
  background-color: #f8f9fa;
  border: 1px solid var(--se-border-lighter);
  padding: var(--se-spacing-sm);
  font-weight: var(--se-font-weight-secondary);
  position: sticky;
  left: 0;
  z-index: 3;
  min-width: 180px;
}

.corner-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.corner-label-top,
.corner-label-bottom {
  font-size: 11px;
  color: var(--se-text-secondary);
  font-weight: normal;
}

.header-cell {
  background-color: #f8f9fa;
  border: 1px solid var(--se-border-lighter);
  padding: var(--se-spacing-sm);
  font-weight: var(--se-font-weight-secondary);
  text-align: center;
}

.role-header {
  position: sticky;
  top: 0;
  z-index: 2;
  min-width: 80px;
  max-width: 80px;
  height: 250px;
  padding: 0;
  vertical-align: bottom;
  position: relative;
}

.role-header .header-content {
  writing-mode: vertical-lr;
  transform: rotate(180deg);
  white-space: normal;
  word-wrap: break-word;
  overflow-wrap: break-word;
  height: 100%;
  width: 80px;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 4px;
  text-align: center;
}

.process-header {
  position: sticky;
  left: 0;
  z-index: 1;
  text-align: left;
  min-width: 180px;
  background-color: #e9ecef;
}

.header-content {
  font-size: var(--se-font-size-small);
  color: var(--se-text-primary);
  line-height: 1.3;
}

.data-cell {
  border: 1px solid var(--se-border-lighter);
  padding: 4px;
  text-align: center;
  background-color: white;
  transition: all 0.2s ease;
}

.data-cell:hover {
  background-color: #f0f7ff;
}

.data-cell.cell-changed {
  background-color: #fff3cd;
  border-color: #ffc107;
  box-shadow: inset 0 0 0 1px #ffc107;
}

.data-cell.cell-changed:hover {
  background-color: #ffe9a0;
}

.cell-select {
  width: 100%;
}

.cell-select :deep(.el-input__wrapper) {
  box-shadow: none;
  background-color: transparent;
  padding: 2px 8px;
}

.cell-select :deep(.el-input__inner) {
  text-align: center;
  font-size: var(--se-font-size-small);
}

.action-buttons {
  display: flex;
  gap: var(--se-spacing-base);
  justify-content: center;
  margin-top: var(--se-spacing-lg);
}

.change-summary {
  display: flex;
  align-items: center;
  gap: var(--se-spacing-sm);
  justify-content: center;
  margin-top: var(--se-spacing-base);
  padding: var(--se-spacing-sm) var(--se-spacing-base);
  background-color: #fff3cd;
  border: 1px solid #ffc107;
  border-radius: var(--se-border-radius-base);
  color: #856404;
  font-size: var(--se-font-size-base);
  font-family: var(--se-font-family);
}

.warning-icon {
  font-size: 18px;
  line-height: 1;
}

.info-banner {
  width: 100%;
  max-width: 1200px;
  margin-bottom: 20px;
  padding: 16px;
  background-color: #e3f2fd;
  border: 1px solid #2196f3;
  border-radius: var(--se-border-radius-base);
  font-family: var(--se-font-family);
}

.banner-header {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #1976d2;
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-secondary);
  margin-bottom: 8px;
}

.info-icon {
  font-size: 20px;
  line-height: 1;
}

.banner-body {
  color: #0d47a1;
  font-size: var(--se-font-size-base);
  line-height: 1.6;
  font-family: var(--se-font-family);
}
</style>
