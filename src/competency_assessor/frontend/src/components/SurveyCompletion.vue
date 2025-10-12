<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

// Function to handle "View Results" button click
const viewResults = () => {
  // Redirect to the survey results page
  router.push('/surveyResults');
};
</script>

<template>
  <v-app>
    <v-container fluid class="d-flex flex-column justify-center align-center completion-container">
      <v-sheet elevation="3" class="completion-card">
        <v-icon color="success" size="96" class="success-icon">mdi-check-circle</v-icon>
        <h1 class="completion-heading">Congratulations!</h1>
        <p class="completion-text">
          You have successfully completed the Systems Engineering Competency Assessment Survey.
        </p>
        <v-btn @click="viewResults" color="success" dark class="view-results-button">
          Click Here to View Your Results
        </v-btn>
      </v-sheet>
    </v-container>
  </v-app>
</template>

<style scoped>
/* Overall container to ensure component fills viewport height */
.completion-container {
  height: 100vh;
  background-color: #121212;
  padding: 20px;
}

/* Card style for the completion modal */
.completion-card {
  background-color: #1e1e1e;
  padding: 40px;
  border-radius: 16px;
  max-width: 600px;
  text-align: center;
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

/* Icon style for success check */
.success-icon {
  margin-bottom: 20px;
}

/* Style for the congratulations heading */
.completion-heading {
  color: #4CAF50;
  font-family: 'Roboto', sans-serif;
  font-size: 2.5rem;
  margin-bottom: 20px;
}

/* Text style for completion message */
.completion-text {
  color: #c0c0c0;
  font-family: 'Roboto', sans-serif;
  font-size: 1.2rem;
  margin-bottom: 30px;
}

/* Button to view results - centered text */
.view-results-button {
  background-color: #4CAF50 !important;
  color: white !important;
  font-family: 'Roboto', sans-serif;
  font-weight: bold;
  font-size: 1.2rem;
  padding: 20px 25px;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  display: flex;
  align-items: center; /* Vertical centering */
  justify-content: center; /* Horizontal centering */
}

/* Hover effect for button */
.view-results-button:hover {
  transform: scale(1.05);
  box-shadow: 0px 4px 12px rgba(76, 175, 80, 0.4);
}
</style>
