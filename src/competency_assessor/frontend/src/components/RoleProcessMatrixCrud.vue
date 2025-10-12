<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

// Reactive data for organizations, roles, processes, and matrix
const organizations = ref([]);
const roles = ref([]);
const processes = ref([]);
const selectedOrganizationId = ref(null);
const selectedRoleId = ref(null);
const roleProcessMatrix = ref({});
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Fetch all available organizations
const fetchOrganizations = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/organizations`);
    organizations.value = response.data;
  } catch (error) {
    console.error('Error fetching organizations:', error);
  }
};

// Fetch roles and processes based on the selected organization
const fetchRolesAndProcesses = async () => {
  if (!selectedOrganizationId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/roles_and_processes`);
    roles.value = response.data.roles;
    processes.value = response.data.processes;
  } catch (error) {
    console.error('Error fetching roles and processes:', error);
  }
};

// Fetch role-process matrix for the selected role and organization
const fetchRoleProcessMatrix = async () => {
  if (!selectedOrganizationId.value || !selectedRoleId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/role_process_matrix/${selectedOrganizationId.value}/${selectedRoleId.value}`);
    roleProcessMatrix.value = processes.value.reduce((matrix, process) => {
      const entry = response.data.find(e => e.iso_process_id === process.id);
      matrix[process.id] = entry ? entry.role_process_value : 0;  // Default to 0 if not set
      return matrix;
    }, {});
  } catch (error) {
    console.error('Error fetching role-process matrix:', error);
  }
};

// Save the role-process matrix for the selected organization and role
const saveRoleProcessMatrix = async () => {
  if (!selectedOrganizationId.value || !selectedRoleId.value) return;

  const filteredMatrix = {};
  for (const [processId, value] of Object.entries(roleProcessMatrix.value)) {
    if (value !== null) {
      filteredMatrix[processId] = value;  // Only include if a selection has been made
    }
  }

  try {
    await axios.put(`${API_BASE_URL}/role_process_matrix/bulk`, {
      organization_id: selectedOrganizationId.value,
      role_cluster_id: selectedRoleId.value,
      matrix: filteredMatrix
    });
    alert("Changes saved successfully!");
  } catch (error) {
    console.error('Error saving role-process matrix:', error);
    alert("Error saving changes. Please try again.");
  }
};

// Fetch organizations on component mount
onMounted(() => {
  fetchOrganizations();
});
</script>

<template>
  <v-app>
    <v-container fluid class="d-flex flex-column justify-center align-center" style="height: auto; background-color: #121212;">
      <h1 class="admin-panel-text">Configure Role-Process Matrix</h1>

      <!-- Dropdown to select an organization -->
      <v-select
        v-model="selectedOrganizationId"
        :items="organizations"
        item-title="organization_name"
        item-value="id"
        label="Select Organization"
        @update:modelValue="fetchRolesAndProcesses"
        dense
        outlined
        style="width: 500px; margin-bottom: 30px;"
        class="custom-select"
      ></v-select>

      <!-- Dropdown to select a role -->
      <v-select
        v-if="selectedOrganizationId"
        v-model="selectedRoleId"
        :items="roles"
        item-title="name"
        item-value="id"
        label="Select Role"
        @update:modelValue="fetchRoleProcessMatrix"
        dense
        outlined
        style="width: 500px; margin-bottom: 30px;"
        class="custom-select"
      ></v-select>

      <!-- List of processes with radio buttons for role_process_value if a role is selected -->
      <v-list v-if="selectedRoleId" class="process-list">
        <v-list-item
          v-for="process in processes"
          :key="process.id"
          class="process-list-item"
        >
          <v-list-item-content>
            <v-list-item-title>{{ process.name }}</v-list-item-title>
          </v-list-item-content>
          <v-list-item-action class="radio-group-container">
            <v-radio-group
              v-model="roleProcessMatrix[process.id]"
              class="radio-group"
              row
            >
              <v-row>
                <v-col cols="auto" class="text-center radio-col">
                  <v-radio :value="0" color="primary">
                    <span class="radio-label">0</span> <!-- Label under the button -->
                  </v-radio>
                </v-col>
                <v-col cols="auto" class="text-center radio-col">
                  <v-radio :value="1" color="primary">
                    <span class="radio-label">1</span>
                  </v-radio>
                </v-col>
                <v-col cols="auto" class="text-center radio-col">
                  <v-radio :value="2" color="primary">
                    <span class="radio-label">2</span>
                  </v-radio>
                </v-col>
                <v-col cols="auto" class="text-center radio-col">
                  <v-radio :value="3" color="primary">
                    <span class="radio-label">3</span>
                  </v-radio>
                </v-col>
              </v-row>
            </v-radio-group>
          </v-list-item-action>
        </v-list-item>
      </v-list>

      <!-- Save button -->
      <v-btn
        v-if="selectedRoleId"
        @click="saveRoleProcessMatrix"
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

.radio-group-container {
  display: flex;
  align-items: center;
}

.radio-group {
  display: flex;
  align-items: center;
  justify-content: start;
  padding-left: 20px; /* Add padding to create space on the left side */
}

.radio-col {
  padding-left: 10px; /* Add padding to separate each column */
}

.radio-label {
  color: white;
  font-size: 0.8rem;
  margin-top: -5px; /* Adjust to bring label closer to the button */
}
</style>
