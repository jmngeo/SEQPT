<script setup>
import { ref } from 'vue';
import axios from 'axios';
import { useRouter } from 'vue-router';

// State for the task description and the role clusters result
const taskDescription = ref('');
const roleClusters = ref([]);
const errorMessage = ref(null);
const router = useRouter(); // Vue router instance
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// Function to call the API and identify the role
const findRole = async () => {
  try {
    // Reset previous results
    roleClusters.value = [];
    errorMessage.value = null;

    const response = await axios.post(`${API_BASE_URL}/identify_role`, {
      task_description: taskDescription.value,
    });

    if (response.data.role_clusters) {
      roleClusters.value = response.data.role_clusters;
    } else {
      errorMessage.value = "No role clusters could be identified for your tasks.";
    }
  } catch (error) {
    console.error('Error identifying role:', error);
    errorMessage.value = 'An error occurred while identifying your role. Please try again later.';
  }
};

// Function to start the competency assessment survey
const startSurvey = () => {
  if (roleClusters.value.length > 0) {
    router.push('/competencySurvey'); // Replace with the actual route for your survey page
  } else {
    alert('No roles identified. Please try again.');
  }
};
</script>

<template>
  <v-app>
    <v-container fluid class="d-flex flex-column align-center justify-center mt-5 main-container">
      <h1 class="role-selection-title">Enter Your Tasks and Responsibilities</h1>
      <p class="role-selection-subtitle">Let our AI model help match you to an appropriate role profile(s).</p>

      <!-- Task Description Input -->
      <v-row justify="center">
        <v-col cols="12" sm="8" md="6" class="d-flex justify-center">
          <v-textarea
            v-model="taskDescription"
            label="Describe your tasks and responsibilities"
            rows="6"
            outlined
            style="background-color: #2e2e2e; color: white; border-radius: 8px; min-height: 300px; min-width: 600px; width: 100%; height: auto;"
            class="custom-textarea"
          ></v-textarea>
        </v-col>
      </v-row>

      <!-- Find Role Button -->
      <v-row justify="center" class="mt-3">
        <v-col cols="12" sm="8" md="6" class="d-flex justify-center">
          <v-btn
            class="custom-btn"
            @click="findRole"
          >
            Find Role
          </v-btn>
        </v-col>
      </v-row>

      <!-- Display Identified Roles -->
      <v-row justify="center" class="mt-5">
        <v-col cols="12" sm="8" md="6" class="d-flex flex-column align-center">
          <v-card v-if="roleClusters.length > 0" class="selected-roles-card">
            <v-card-title class="selected-roles-title">Identified Roles:</v-card-title>
            <v-card-text>
              <v-list>
                <v-list-item v-for="cluster in roleClusters" :key="cluster">
                  <v-list-item-content>{{ cluster }}</v-list-item-content>
                </v-list-item>
              </v-list>
            </v-card-text>
          </v-card>

          <!-- Error Message -->
          <div v-if="errorMessage" class="error-message">
            {{ errorMessage }}
          </div>

          <!-- Start Survey Button -->
          <v-btn
            v-if="roleClusters.length > 0"
            class="start-survey-btn mt-4"
            @click="startSurvey"
          >
            START COMPETENCY ASSESSMENT SURVEY
          </v-btn>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<style scoped>
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  background-color: #121212;
}

.v-app {
  min-height: 100vh;
  background-color: #121212;
}

.main-container {
  background-color: inherit;
  padding: 20px;
}

.role-selection-title {
  font-family: 'Open Sans', sans-serif;
  font-size: 2.5rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 10px;
  color: white;
}

.role-selection-subtitle {
  font-family: 'Roboto', sans-serif;
  font-size: 1.2rem;
  text-align: center;
  margin-bottom: 30px;
  color: white;
}

.custom-textarea {
  background-color: #2e2e2e;
  color: white;
  border-radius: 8px;
  padding: 10px;
  width: 100%;
  max-width: 600px;
  min-height: 300px;
}

.custom-btn {
  background-color: #1dd0e0 !important;
  color: white !important;
  border-radius: 20px !important;
  padding: 15px 35px !important;
  font-size: 1.2rem !important;
  min-width: 200px !important;
  text-align: center !important;
  
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  height: 50px !important;
}

.selected-roles-card {
  background-color: #2e2e2e;
  padding: 30px;
  border-radius: 12px;
  color: white;
  margin-bottom: 20px;
  min-width: 500px;
  max-width: 600px;
}

.selected-roles-title {
  font-size: 1.8rem;
  font-family: 'Open Sans', sans-serif;
  margin-bottom: 20px;
}

.start-survey-btn {
  background-color: #4CAF50 !important;
  color: white !important;
  border-radius: 30px;
  padding: 15px 20px;
  font-size: 1.2rem;
  text-transform: uppercase;
  display: flex;
  align-items: center;
  justify-content: center;
  width: auto;
  max-width: 600px;
  min-width: 300px;
  height: 50px !important;
}

.error-message {
  color: #ff6b6b;
  font-size: 1.2rem;
  text-align: center;
}
</style>
