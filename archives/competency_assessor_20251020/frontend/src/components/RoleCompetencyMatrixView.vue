<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

// Reactive data for organizations, roles, and competencies
const organizations = ref([]);
const roles = ref([]);
const competencies = ref([]);
const selectedOrganizationId = ref(null);
const selectedRoleId = ref(null);
const roleCompetencyMatrix = ref({});
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Function to fetch organizations
const fetchOrganizations = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/organizations`);
    organizations.value = response.data;
  } catch (error) {
    console.error('Error fetching organizations:', error);
  }
};

// Function to fetch roles based on the selected organization
const fetchRoles = async () => {
  if (!selectedOrganizationId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/roles_and_processes`);
    roles.value = response.data.roles;
  } catch (error) {
    console.error('Error fetching roles:', error);
  }
};

// Function to fetch competencies and role-competency matrix data for the selected role and organization
const fetchRoleCompetencyMatrix = async () => {
  if (!selectedOrganizationId.value || !selectedRoleId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/role_competency_matrix/${selectedOrganizationId.value}/${selectedRoleId.value}`);
    competencies.value = response.data.competencies;

    // Initialize the matrix with existing values
    roleCompetencyMatrix.value = competencies.value.reduce((matrix, competency) => {
      const entry = response.data.matrix.find(e => e.competency_id === competency.id);
      matrix[competency.id] = (entry && entry.role_competency_value !== -100) ? entry.role_competency_value : 'N/A'; // Display 'N/A' if no valid value
      return matrix;
    }, {});
  } catch (error) {
    console.error('Error fetching role-competency matrix:', error);
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
      <h1 class="admin-panel-text">View Role-Competency Matrix</h1>

      <!-- Dropdown to select an organization -->
      <v-select
        v-model="selectedOrganizationId"
        :items="organizations"
        item-title="organization_name"
        item-value="id"
        label="Select Organization"
        @update:modelValue="fetchRoles"
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
        @update:modelValue="fetchRoleCompetencyMatrix"
        dense
        outlined
        style="width: 500px; margin-bottom: 30px;"
        class="custom-select"
      ></v-select>

      <!-- Display a table of competencies and their corresponding values if a role is selected -->
      <div class="competency-table-container" v-if="selectedRoleId">
        <v-simple-table class="competency-table">
          <thead>
            <tr>
              <th class="table-header">Competency Name</th>
              <th class="table-header">Competency Level</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="competency in competencies" :key="competency.id">
              <td>{{ competency.name }}</td>
              <td>{{ roleCompetencyMatrix[competency.id] }}</td>
            </tr>
          </tbody>
        </v-simple-table>
      </div>
    </v-container>
  </v-app>
</template>

<style scoped>
/* Styles remain the same as the original component */
.admin-panel-text {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 3rem;
  text-align: center;
  margin-bottom: 50px;
}

.competency-table-container {
  width: 100%;
  max-width: 400px;
  max-height: 1000px;
  overflow-y: auto;
  background-color: #1e1e1e;
  margin-top: 20px;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.4);
}

thead {
  background-color: #2ba3c8;
}

.table-header {
  color: white;
  font-weight: bold;
  padding: 10px;
}

td {
  color: white;
  padding: 10px;
  text-align: center;
  background-color: #2a2a2a;
}

td:nth-child(1) {
  text-align: left;
}

.v-select .v-input__control {
  color: white;
  background-color: #2a2a2a;
}

.v-input--is-focused .v-input__control {
  border-color: #2ba3c8;
}
</style>
