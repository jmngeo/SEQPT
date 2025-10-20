<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

// State variables
const competencies = ref([]);
const selectedCompetencyId = ref(null);
const processes = ref([]);
const processCompetencyMatrix = ref({});
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// Fetch competencies for the dropdown
const fetchCompetencies = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/competencies`);
    competencies.value = response.data;
  } catch (error) {
    console.error('Error fetching competencies:', error);
  }
};

// Fetch processes and process-competency matrix for the selected competency
const fetchProcessCompetencyMatrix = async () => {
  if (!selectedCompetencyId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/process_competency_matrix/${selectedCompetencyId.value}`);
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
    await axios.put(`${API_BASE_URL}/process_competency_matrix/bulk`, {
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
  <v-app>
    <v-container fluid class="d-flex flex-column justify-center align-center" style="height: auto; background-color: #121212;">
      <h1 class="admin-panel-text">Configure Process-Competency Matrix</h1>

      <!-- Dropdown to select a competency -->
      <v-select
        v-model="selectedCompetencyId"
        :items="competencies"
        item-title="competency_name"
        item-value="id"
        label="Select Competency"
        @update:modelValue="fetchProcessCompetencyMatrix"
        dense
        outlined
        style="width: 500px; margin-bottom: 30px;"
        class="custom-select"
      ></v-select>

      <!-- List of processes with radio buttons for process_competency_value if a competency is selected -->
      <v-list v-if="selectedCompetencyId" class="process-list">
        <v-list-item
          v-for="process in processes"
          :key="process.id"
          class="process-list-item"
        >
          <v-list-item-content>
            <v-list-item-title>{{ process.name }}</v-list-item-title>
          </v-list-item-content>
          <v-list-item-action class="radio-group-container">
            <!-- Radio buttons for selecting value 0, 1, 2, 3 arranged horizontally -->
            <v-radio-group
              v-model="processCompetencyMatrix[process.id]"
              class="radio-group"
              :mandatory="false"
              row
            >
              <v-radio :label="0" :value="0" color="primary"></v-radio>
              <v-radio :label="1" :value="1" color="primary"></v-radio>
              <v-radio :label="2" :value="2" color="primary"></v-radio>
            </v-radio-group>
          </v-list-item-action>
        </v-list-item>
      </v-list>

      <!-- Save button -->
      <v-btn
        v-if="selectedCompetencyId"
        @click="saveProcessCompetencyMatrix"
        color="success"
        class="mt-5"
      >
        Save Changes
      </v-btn>
    </v-container>
  </v-app>
</template>

<style scoped>
.admin-panel-text {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 3rem;
  text-align: center;
  margin-bottom: 50px;
}

.process-list {
  width: 100%;
  max-width: 600px;
  background-color: #1e1e1e;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 30px;
}

.process-list-item {
  background-color: #2a2a2a;
  margin-bottom: 10px;
  padding: 10px;
  border-radius: 8px;
  color: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
  transition: box-shadow 0.3s ease;
}

.process-list-item:hover {
  box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.4);
}

.v-select .v-input__control {
  color: white;
}

.v-input--is-focused .v-input__control {
  border-color: #2ba3c8;
}

.v-list-item-title {
  color: white;
}

.radio-group {
  display: flex;
  align-items: center;
  justify-content: start; /* Align items to the left */
}

.radio-group-container {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.v-radio {
  margin-right: 10px;
  color: white;
}
</style>
