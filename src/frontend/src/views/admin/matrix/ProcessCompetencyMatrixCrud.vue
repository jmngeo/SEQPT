<script setup>
import { ref, onMounted } from 'vue';
import axios from '@/api/axios';

// State variables
const competencies = ref([]);
const selectedCompetencyId = ref(null);
const processes = ref([]);
const processCompetencyMatrix = ref({});

// Fetch competencies for the dropdown
const fetchCompetencies = async () => {
  try {
    const response = await axios.get('/competencies');
    competencies.value = response.data;
  } catch (error) {
    console.error('Error fetching competencies:', error);
  }
};

// Fetch processes and process-competency matrix for the selected competency
const fetchProcessCompetencyMatrix = async () => {
  if (!selectedCompetencyId.value) return;

  try {
    const response = await axios.get(`/process_competency_matrix/${selectedCompetencyId.value}`);
    processes.value = response.data.processes;

    // Initialize the matrix with existing values or set to null if uninitialized
    processCompetencyMatrix.value = processes.value.reduce((matrix, process) => {
      const entry = response.data.matrix.find(e => e.iso_process_id === process.id);
      matrix[process.id] = (entry && entry.process_competency_value !== -100) ? entry.process_competency_value : null;
      return matrix;
    }, {});
  } catch (error) {
    console.error('Error fetching process-competency matrix:', error);
  }
};

// Save the process-competency matrix to the backend
const saveProcessCompetencyMatrix = async () => {
  const filteredMatrix = {};
  for (const [processId, value] of Object.entries(processCompetencyMatrix.value)) {
    if (value !== null) {
      filteredMatrix[processId] = value; // Only include if a selection has been made
    }
  }

  try {
    await axios.put('/process_competency_matrix/bulk', {
      competency_id: selectedCompetencyId.value,
      matrix: filteredMatrix
    });
    alert("Changes saved successfully!");
  } catch (error) {
    console.error('Error saving process-competency matrix:', error);
    alert("Error saving changes. Please try again.");
  }
};

// Fetch competencies on component mount
onMounted(() => {
  fetchCompetencies();
});
</script>

<template>
  <div class="matrix-crud-container">
    <div class="matrix-content">
      <h1 class="matrix-title">Configure Process-Competency Matrix</h1>

      <!-- Empty state -->
      <el-alert
        v-if="competencies.length === 0"
        title="No Data Available"
        type="info"
        description="Please populate the database with competencies and processes data first. These CRUD features are from Derik's original implementation."
        :closable="false"
        style="margin-bottom: 20px; max-width: 800px;"
      />

      <!-- Dropdown to select a competency -->
      <el-select
        v-model="selectedCompetencyId"
        placeholder="Select Competency"
        @change="fetchProcessCompetencyMatrix"
        style="width: 100%; max-width: 500px; margin-bottom: 20px;"
        size="large"
      >
        <el-option
          v-for="competency in competencies"
          :key="competency.id"
          :label="competency.competency_name"
          :value="competency.id"
        />
      </el-select>

      <!-- List of processes with radio buttons for process_competency_value if a competency is selected -->
      <div v-if="selectedCompetencyId && processes.length > 0" class="process-list">
        <div
          v-for="process in processes"
          :key="process.id"
          class="process-item"
        >
          <span class="process-name">{{ process.name }}</span>
          <el-radio-group v-model="processCompetencyMatrix[process.id]" class="process-radio">
            <el-radio :label="0">0</el-radio>
            <el-radio :label="1">1</el-radio>
            <el-radio :label="2">2</el-radio>
          </el-radio-group>
        </div>
      </div>

      <!-- Save button -->
      <el-button
        v-if="selectedCompetencyId && processes.length > 0"
        type="primary"
        size="large"
        @click="saveProcessCompetencyMatrix"
        style="margin-top: 24px;"
      >
        Save Changes
      </el-button>
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
  max-width: 900px;
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

.process-list {
  width: 100%;
  max-width: 800px;
  background-color: var(--se-bg-primary);
  border-radius: var(--se-border-radius-base);
  padding: var(--se-spacing-lg);
  margin-bottom: var(--se-spacing-lg);
  box-shadow: var(--se-shadow-base);
}

.process-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--se-spacing-base);
  margin-bottom: var(--se-spacing-sm);
  background-color: var(--se-bg-secondary);
  border-radius: var(--se-border-radius-base);
  border: 1px solid var(--se-border-lighter);
  transition: all 0.3s ease;
}

.process-item:hover {
  border-color: var(--se-primary);
  box-shadow: var(--se-shadow-light);
}

.process-item:last-child {
  margin-bottom: 0;
}

.process-name {
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-secondary);
  color: var(--se-text-primary);
  flex: 1;
}

.process-radio {
  display: flex;
  gap: var(--se-spacing-sm);
}
</style>
