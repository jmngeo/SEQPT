<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from '@/api/axios';

// State variables
const competencies = ref([]);
const processes = ref([]);
const processCompetencyMatrix = ref({}); // { competencyId: { processId: value } }
const originalMatrix = ref({}); // Track original values for change detection
const changedCells = ref(new Set()); // Track which cells have been changed
const loading = ref(false);
const saving = ref(false);

// Fetch competencies and processes
const fetchCompetenciesAndProcesses = async () => {
  try {
    loading.value = true;

    // Fetch competencies
    const compResponse = await axios.get('/api/competencies');
    competencies.value = compResponse.data;

    // Fetch processes
    const rolesProcessesResponse = await axios.get('/api/roles-and-processes');
    processes.value = rolesProcessesResponse.data.processes;
  } catch (error) {
    console.error('Error fetching competencies and processes:', error);
  } finally {
    loading.value = false;
  }
};

// Fetch process-competency matrix for ALL competencies
const fetchAllProcessCompetencyMatrices = async () => {
  try {
    loading.value = true;
    const matrixData = {};
    const originalData = {};

    // Fetch matrix for each competency
    for (const competency of competencies.value) {
      const response = await axios.get(`/api/process-competency-matrix/${competency.id}`);

      matrixData[competency.id] = {};
      originalData[competency.id] = {};

      processes.value.forEach(process => {
        const entry = response.data.matrix.find(e => e.iso_process_id === process.id);
        const value = (entry && entry.process_competency_value !== -100)
          ? entry.process_competency_value
          : 0;
        matrixData[competency.id][process.id] = value;
        originalData[competency.id][process.id] = value;
      });
    }

    processCompetencyMatrix.value = matrixData;
    originalMatrix.value = JSON.parse(JSON.stringify(originalData));
    changedCells.value.clear();
  } catch (error) {
    console.error('Error fetching process-competency matrices:', error);
  } finally {
    loading.value = false;
  }
};

// Check if a cell has been changed
const isCellChanged = (competencyId, processId) => {
  return changedCells.value.has(`${competencyId}-${processId}`);
};

// Update cell value and track changes
const updateCellValue = (competencyId, processId, newValue) => {
  processCompetencyMatrix.value[competencyId][processId] = newValue;

  // Check if value differs from original
  if (originalMatrix.value[competencyId][processId] !== newValue) {
    changedCells.value.add(`${competencyId}-${processId}`);
  } else {
    changedCells.value.delete(`${competencyId}-${processId}`);
  }
};

// Get cell class for styling
const getCellClass = (competencyId, processId) => {
  return isCellChanged(competencyId, processId) ? 'cell-changed' : '';
};

// Value options for dropdown (just numbers, legend shows meaning)
const valueOptions = [
  { value: 0, label: '0' },
  { value: 1, label: '1' },
  { value: 2, label: '2' }
];

// Check if there are unsaved changes
const hasUnsavedChanges = computed(() => changedCells.value.size > 0);

// Get organization count (for warning message)
const organizationCount = ref(0);
const fetchOrganizationCount = async () => {
  try {
    // This would be a new endpoint, but for now we'll estimate
    organizationCount.value = 10; // Placeholder
  } catch (error) {
    console.error('Error fetching organization count:', error);
  }
};

// Save all changes to the process-competency matrix
const saveAllChanges = async () => {
  if (!hasUnsavedChanges.value) return;

  // Confirm with user due to global impact
  const confirmed = confirm(
    `WARNING: Process-Competency Matrix is GLOBAL!\n\n` +
    `Changes will affect ALL organizations in the system.\n` +
    `Role-Competency matrices will be recalculated for ALL organizations.\n\n` +
    `Are you sure you want to proceed?`
  );

  if (!confirmed) return;

  try {
    saving.value = true;

    // Save matrix for each competency that has changes
    const competenciesToUpdate = new Set();
    changedCells.value.forEach(cellKey => {
      const [competencyId] = cellKey.split('-');
      competenciesToUpdate.add(parseInt(competencyId));
    });

    for (const competencyId of competenciesToUpdate) {
      await axios.put('/api/process-competency-matrix/bulk', {
        competency_id: competencyId,
        matrix: processCompetencyMatrix.value[competencyId]
      });
    }

    // Update original matrix to current values
    originalMatrix.value = JSON.parse(JSON.stringify(processCompetencyMatrix.value));

    // Clear changed cells after successful save
    changedCells.value.clear();

    alert(
      `Changes saved successfully!\n\n` +
      `Role-Competency Matrix has been automatically recalculated for ALL organizations.`
    );
  } catch (error) {
    console.error('Error saving process-competency matrix:', error);
    alert("Error saving changes. Please try again.");
  } finally {
    saving.value = false;
  }
};

// Reset all changes
const resetChanges = () => {
  if (confirm('Are you sure you want to discard all unsaved changes?')) {
    processCompetencyMatrix.value = JSON.parse(JSON.stringify(originalMatrix.value));
    changedCells.value.clear();
  }
};

// Initialize on component mount
onMounted(async () => {
  // Fetch competencies and processes
  await fetchCompetenciesAndProcesses();

  // Fetch organization count for warning
  await fetchOrganizationCount();

  // Fetch all matrices
  if (competencies.value.length > 0 && processes.value.length > 0) {
    await fetchAllProcessCompetencyMatrices();
  }
});
</script>

<template>
  <div class="matrix-crud-container">
    <div class="matrix-content">
      <h1 class="matrix-title">Process-Competency Matrix</h1>

      <!-- IMPORTANT: Global warning -->
      <div class="warning-banner">
        <div class="banner-header warning">
          <span class="warning-icon">⚠</span>
          <strong>WARNING: GLOBAL MATRIX - Affects ALL Organizations</strong>
        </div>
        <div class="banner-body warning">
          <p>
            <strong>This matrix is standardized and should NOT be changed without careful consideration.</strong>
          </p>
          <p>
            Based on established Systems Engineering standards (Könemann et al.), this matrix defines which competencies are required for each ISO/IEC 15288 process.
            Modified cells are highlighted in yellow during editing.
          </p>
          <p class="critical-warning">
            Changes affect ALL organizations and trigger recalculation of all Role-Competency matrices.
          </p>
        </div>
      </div>

      <!-- Legend -->
      <div class="legend-container">
        <div class="legend-title">Value Legend:</div>
        <div class="legend-items">
          <div class="legend-item">
            <span class="legend-value">0</span>
            <span class="legend-label">Not Useful</span>
          </div>
          <div class="legend-item">
            <span class="legend-value">1</span>
            <span class="legend-label">Useful</span>
          </div>
          <div class="legend-item">
            <span class="legend-value">2</span>
            <span class="legend-label">Necessary</span>
          </div>
        </div>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="loading-container">
        <div class="loading-spinner"></div>
        <p>Loading matrix data...</p>
      </div>

      <!-- Excel-style grid -->
      <div v-else-if="competencies.length > 0 && processes.length > 0" class="matrix-grid-container">
        <div class="matrix-grid-wrapper">
          <table class="matrix-grid">
            <thead>
              <tr>
                <th class="corner-cell">
                  <div class="corner-content">
                    <span class="corner-label-top">Competencies →</span>
                    <span class="corner-label-bottom">Processes ↓</span>
                  </div>
                </th>
                <th
                  v-for="competency in competencies"
                  :key="competency.id"
                  class="header-cell competency-header"
                >
                  <div class="header-content">{{ competency.name }}</div>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="process in processes" :key="process.id">
                <td class="header-cell process-header">
                  <div class="header-content">{{ process.name }}</div>
                </td>
                <td
                  v-for="competency in competencies"
                  :key="`${competency.id}-${process.id}`"
                  class="data-cell"
                  :class="getCellClass(competency.id, process.id)"
                >
                  <el-select
                    :model-value="processCompetencyMatrix[competency.id]?.[process.id]"
                    @change="(val) => updateCellValue(competency.id, process.id, val)"
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
            type="danger"
            size="large"
            :disabled="!hasUnsavedChanges || saving"
            :loading="saving"
            @click="saveAllChanges"
          >
            Save All Changes ({{ changedCells.size }} cells modified) - AFFECTS ALL ORGS
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
        <div v-if="hasUnsavedChanges" class="change-summary critical">
          <span class="warning-icon">⚠</span>
          <span>{{ changedCells.size }} cell(s) modified - Will affect ALL organizations</span>
        </div>
      </div>

      <!-- Empty state -->
      <el-alert
        v-else-if="!loading"
        title="No Data Available"
        type="info"
        description="No competencies or processes found. Please ensure database is populated."
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
  min-width: 200px;
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

.competency-header {
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

.competency-header .header-content {
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
  min-width: 200px;
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

.change-summary.critical {
  background-color: #ffebee;
  border-color: #f44336;
  color: #c62828;
}

.warning-icon {
  font-size: 18px;
  line-height: 1;
}

.warning-banner {
  width: 100%;
  max-width: 1200px;
  margin-bottom: 20px;
  padding: 16px;
  background-color: #fff3e0;
  border: 2px solid #ff9800;
  border-radius: var(--se-border-radius-base);
  font-family: var(--se-font-family);
}

.banner-header.warning {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #e65100;
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-secondary);
  margin-bottom: 12px;
}

.banner-body.warning {
  color: #e65100;
  font-size: var(--se-font-size-base);
  line-height: 1.6;
  font-family: var(--se-font-family);
}

.banner-body.warning p {
  margin: 0 0 8px 0;
}

.banner-body.warning p:last-child {
  margin-bottom: 0;
}

.critical-warning {
  color: #d32f2f;
  font-weight: 600;
}
</style>
