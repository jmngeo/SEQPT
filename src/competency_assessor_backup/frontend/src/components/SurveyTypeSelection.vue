<script setup>
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/useUserStore'; // Import Pinia store

const router = useRouter();
const userStore = useUserStore();

// Function to handle role-based survey selection
const selectRoleBasedSurvey = () => {
  userStore.surveyType = 'known_roles'; // Set survey type in Pinia store
  router.push('/roleSelectionPage'); // Navigate to the role selection component
};

// Function to handle full survey selection
const selectFullSurvey = () => {
  userStore.surveyType = 'all_roles'; // Set survey type in Pinia store
  router.push('/competencySurvey'); // Navigate to the competency survey component
};
</script>

<template>
  <v-app>
    <v-container
      fluid
      class="d-flex flex-column align-center justify-center mt-5 main-container"
    >
      <h1 class="survey-selection-title">Choose Your Survey Type</h1>

      <v-row align="center" justify="center" class="g-4">
        <!-- Option 1: Role-Based Survey -->
        <v-col cols="12" sm="8" md="6" lg="4">
          <v-card class="task-card" @click="selectRoleBasedSurvey">
            <v-card-title class="task-card-title">
              Assess Your Systems Engineering Competency
            </v-card-title>
            <v-card-text class="task-card-text">
              Based on your role at work.
            </v-card-text>
          </v-card>
        </v-col>

        <!-- Option 2: Full Survey -->
        <v-col cols="12" sm="8" md="6" lg="4">
          <v-card class="task-card" @click="selectFullSurvey">
            <v-card-title class="task-card-title">Take the Full Survey</v-card-title>
            <v-card-text class="task-card-text">
              Let us find the ideal role for you.
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<style scoped>
/* General styles for the component */
.survey-selection-title {
  font-family: 'Roboto', sans-serif;
  font-size: 3.5rem;
  font-weight: 900;
  text-align: center;
  margin-bottom: 50px;
  color: #f0f0f0;
  text-shadow: 3px 3px 8px rgba(0, 0, 0, 0.5);
}

.task-card {
  padding: 0;
  transition: box-shadow 0.3s ease, transform 0.3s ease;
  color: white;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 100%;
  max-width: 350px;
  height: 250px; /* Uniform height for cards */
  background: linear-gradient(135deg, #2e2e2e, #232323); /* Matching dark gradient */
  border-radius: 8px;
  cursor: pointer;
  border: 2px solid transparent; /* Default border */
}

.task-card:hover {
  box-shadow: 0px 6px 12px rgba(255, 255, 255, 0.5);
  transform: scale(1.05); /* Add slight scaling on hover */
}

.task-card-title {
  font-weight: bold;
  font-size: 1.4rem;
  text-transform: uppercase;
  text-align: center;
  color: #ffc107; /* Bright yellow shade */
  margin-top: 15px;
  padding: 0 10px; /* Add padding for proper spacing */
  word-wrap: break-word; /* Allow words to wrap to the next line */
  overflow-wrap: break-word; /* Break long words if necessary */
  white-space: normal; /* Allow text to wrap onto multiple lines */
  line-height: 1.4; /* Add spacing between lines for readability */
}

.task-card-text {
  font-size: 1rem;
  text-align: center;
  color: #cfcfcf; /* Subtle contrast for text */
  padding: 10px 20px;
}
</style>
