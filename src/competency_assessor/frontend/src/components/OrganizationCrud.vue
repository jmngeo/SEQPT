<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

// Reactive data for organizations
const organizations = ref([]);
const newOrganizationName = ref('');
const newOrganizationKey = ref(''); // Organization Key field
const organizationKeyError = ref(''); // To store error messages for the key
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Function to fetch existing organizations from the backend API
const fetchOrganizations = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/organizations`);
    organizations.value = response.data;
  } catch (error) {
    console.error('Error fetching organizations:', error);
  }
};

// Function to check if the organization key already exists
const checkOrganizationKey = async () => {
  if (!newOrganizationKey.value) return;

  try {
    // Call the backend endpoint to check if the key already exists
    const response = await axios.post(`${API_BASE_URL}/check_organization_key`, {
      organization_public_key: newOrganizationKey.value,
    });

    if (response.data.exists) {
      organizationKeyError.value = 'Organization key already exists. Please choose a different key.';
    } else {
      organizationKeyError.value = '';
    }
  } catch (error) {
    console.error('Error checking organization key:', error);
  }
};

// Function to create a new organization
const createOrganization = async () => {
  if (!newOrganizationName.value || !newOrganizationKey.value) {
    alert('Organization name and key are required');
    return;
  }

  if (organizationKeyError.value) {
    alert(organizationKeyError.value);
    return;
  }

  try {
    await axios.post(`${API_BASE_URL}/organization`, {
      organization_name: newOrganizationName.value,
      organization_public_key: newOrganizationKey.value,
    });
    newOrganizationName.value = '';  // Clear the input field
    newOrganizationKey.value = '';   // Clear the key field
    fetchOrganizations();  // Refresh the list after adding
  } catch (error) {
    console.error('Error creating organization:', error);
  }
};

// Function to delete an organization
const deleteOrganization = async (id) => {
  try {
    await axios.delete(`${API_BASE_URL}/organization/${id}`);
    fetchOrganizations();  // Refresh the list after deletion
  } catch (error) {
    console.error('Error deleting organization:', error);
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
      <h1 class="admin-panel-text">Manage Organizations</h1>

      <!-- Form to add a new organization -->
      <v-form class="mt-5 d-flex flex-column add-organization-form" @submit.prevent="createOrganization">
        <v-row>
          <v-col cols="12">
            <v-text-field
              v-model="newOrganizationName"
              label="Enter Organization Name"
              outlined
              dense
              style="width: 100%; margin-bottom: 20px;"
              required
            ></v-text-field>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12">
            <v-text-field
              v-model="newOrganizationKey"
              label="Enter Organization Key"
              outlined
              dense
              style="width: 100%; margin-bottom: 20px;"
              required
              @input="checkOrganizationKey"
              :error="organizationKeyError !== ''"
            ></v-text-field>
          </v-col>
        </v-row>

        <v-row v-if="organizationKeyError">
          <v-col cols="12">
            <p class="error-message">{{ organizationKeyError }}</p>
          </v-col>
        </v-row>

        <v-row>
          <v-col cols="12" class="d-flex justify-center">
            <v-btn @click="createOrganization" color="success" dark>Create Organization</v-btn>
          </v-col>
        </v-row>
      </v-form>

      <!-- Existing Organizations List -->
      <h2 class="mt-10">Existing Organizations</h2>
      <div class="organization-list">
        <v-row class="organization-list-header" align="center">
          <!-- Column Headers -->
          <v-col cols="4">
            <h3 class="column-header">Organization Name</h3>
          </v-col>
          <v-col cols="4">
            <h3 class="column-header">Organization Key</h3>
          </v-col>
          <v-col cols="4">
            <h3 class="column-header">Actions</h3>
          </v-col>
        </v-row>

        <!-- Organization Data Rows -->
        <v-row
          v-for="organization in organizations"
          :key="organization.id"
          class="organization-list-item"
          align="center"
        >
          <v-col cols="4">
            <div class="organization-name">{{ organization.organization_name }}</div>
          </v-col>
          <v-col cols="4">
            <div class="organization-key">{{ organization.organization_public_key }}</div>
          </v-col>
          <v-col cols="4">
            <v-btn color="error" dark @click="deleteOrganization(organization.id)">Delete</v-btn>
          </v-col>
        </v-row>
      </div>

      <!-- No organizations available message -->
      <v-row v-if="organizations.length === 0" class="mt-5">
        <v-col>
          <p>No organizations available.</p>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<style scoped>
.admin-panel-text {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 30px;
}

.add-organization-form {
  min-width: 400px;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
  background-color: #2a2a2a;
  padding: 15px;
  border-radius: 8px;
}

.organization-list {
  width: 100%;
  max-width: 600px; /* Limit the width to avoid full screen */
  margin-left: auto;
  margin-right: auto;
  margin-top: 20px;
}

.organization-list-header {
  background-color: #333333;
  padding: 10px;
  border-radius: 8px;
  margin-bottom: 10px;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.organization-list-item {
  background-color: #2a2a2a;
  margin-bottom: 10px;
  padding: 10px;
  border-radius: 8px;
  color: white;
  transition: box-shadow 0.3s ease;
  max-width: 600px; /* Limit the width */
  margin-left: auto; /* Center horizontally */
  margin-right: auto; /* Center horizontally */
}

.organization-list-item:hover {
  box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.4);
}

.organization-name,
.organization-key {
  color: white;
  font-size: 1.1rem;
}

.column-header {
  color: #2ba3c8;
  font-size: 1.2rem;
  font-weight: bold;
  text-align: left;
}

.error-message {
  color: #e57373;
  font-size: 1rem;
}

.v-select .v-input__control {
  color: white;
}

.v-input--is-focused .v-input__control {
  border-color: #2ba3c8;
}
</style>
