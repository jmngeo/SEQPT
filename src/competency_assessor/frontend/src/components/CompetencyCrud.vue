<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';

const competencies = ref([]);
// Load the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// New Competency form data
const newCompetency = ref({
  competency_area: '',
  competency_name: '',
  description: '',
  why_it_matters: ''
});

// Fetch all competencies
const fetchCompetencies = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/competencies`);
    competencies.value = response.data;
  } catch (error) {
    console.error('Error fetching competencies:', error);
  }
};

// Create a new competency
const createCompetency = async () => {
  try {
    await axios.post(`${API_BASE_URL}/competencies`, newCompetency.value);
    fetchCompetencies(); // Refresh the competencies list after adding
    // Reset the form fields after submission
    newCompetency.value = {
      competency_area: '',
      competency_name: '',
      description: '',
      why_it_matters: ''
    };
  } catch (error) {
    console.error('Error creating competency:', error);
  }
};

// Delete a competency
const deleteCompetency = async (id) => {
  try {
    await axios.delete(`${API_BASE_URL}/competencies/${id}`);
    fetchCompetencies(); // Refresh competencies after deletion
  } catch (error) {
    console.error('Error deleting competency:', error);
  }
};

// Group competencies by their competency area
const groupedCompetencies = computed(() => {
  return competencies.value.reduce((groups, competency) => {
    const area = competency.competency_area;
    if (!groups[area]) {
      groups[area] = [];
    }
    groups[area].push(competency);
    return groups;
  }, {});
});

// Call fetchCompetencies when the component is mounted
onMounted(() => {
  fetchCompetencies();
});
</script>

<template>
  <v-app>
    <v-container>
      <h1>Manage Competencies</h1>
      <h2 class="mt-10">Add New Competency</h2>
      <!-- Form to create a new competency -->
      <v-form class="mt-5">
        <v-text-field v-model="newCompetency.competency_area" label="Competency Area" required></v-text-field>
        <v-text-field v-model="newCompetency.competency_name" label="Competency Name" required></v-text-field>
        <v-text-field v-model="newCompetency.description" label="Description" required></v-text-field>
        <v-text-field v-model="newCompetency.why_it_matters" label="Why It Matters" required></v-text-field>

        <!-- Button to create competency -->
        <v-btn @click="createCompetency" color="success">Create Competency</v-btn>
      </v-form>

      <!-- Heading for existing competencies -->
      <h2 class="mt-10">Existing Competencies</h2>

      <!-- Button to refresh the list of competencies -->
      <v-btn @click="fetchCompetencies" color="primary" class="mb-4">Refresh Competencies</v-btn>

      <!-- Display grouped competencies by competency area -->
      <template v-for="(competenciesList, area) in groupedCompetencies" :key="area">
        <h3 class="mt-5">{{ area }}</h3> <!-- Competency Area Header -->
        <v-row>
          <v-col v-for="competency in competenciesList" :key="competency.id" cols="12" sm="6" md="4">
            <v-card>
              <v-card-title>{{ competency.competency_name }}</v-card-title>
              <v-card-subtitle>{{ competency.description }}</v-card-subtitle>
              <v-card-actions>
                <v-btn color="primary">Edit</v-btn>
                <v-btn color="error" @click="deleteCompetency(competency.id)">Delete</v-btn>
              </v-card-actions>
            </v-card>
          </v-col>
        </v-row>
      </template>

      <!-- No competencies available message -->
      <v-row v-if="Object.keys(groupedCompetencies).length === 0">
        <v-col>
          <p>No competencies available.</p>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<style scoped>
/* Additional styles if needed */
</style>
