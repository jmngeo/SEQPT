<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { useUserStore } from '@/stores/useUserStore';

const router = useRouter();
const userStore = useUserStore();

// Reactive variables for tasks and responsibilities
const tasksResponsibleFor = ref('');
const tasksYouSupport = ref('');
const tasksDefineAndImprove = ref('');
const loadingMessage = ref('');
const isLoading = ref(false); // Track loading state
const processResult = ref(null); // Store the response from the backend
const showErrorPopup = ref(false); // Control popup visibility
const errorMessage = ref(''); // Store error message for invalid tasks
const showValidationPopup = ref(false); // Control validation popup visibility
const validationMessage = ref(''); // Store validation error message
// Add the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Ensure default values for empty inputs
const setDefaultValues = () => {
  if (!tasksResponsibleFor.value.trim()) {
    tasksResponsibleFor.value = 'Not responsible for any tasks';
  }
  if (!tasksYouSupport.value.trim()) {
    tasksYouSupport.value = 'Not supporting any tasks';
  }
  if (!tasksDefineAndImprove.value.trim()) {
    tasksDefineAndImprove.value = 'Not designing any tasks';
  }
};

// Validate the fields before proceeding
const validateInput = () => {
  setDefaultValues();
  const allDefaults = [
    tasksResponsibleFor.value.trim(),
    tasksYouSupport.value.trim(),
    tasksDefineAndImprove.value.trim()
  ].every(task =>
    task === 'Not responsible for any tasks' ||
    task === 'Not supporting any tasks' ||
    task === 'Not designing any tasks'
  );

  if (allDefaults) {
    validationMessage.value = 'Please provide at least one valid task description.';
    showValidationPopup.value = true;
    return false;
  }

  return true;
};

// Simulate progress messages during processing
const simulateProgress = () => {
  const messages = [
    'Analyzing your tasks and responsibilities...',
    'Understanding your involvement in different ISO processes...',
    'Leveraging our AI model to map your tasks to ISO standards...',
    'Finalizing the ISO processes you are performing...'
  ];

  let index = 0;
  loadingMessage.value = messages[index];

  const interval = setInterval(() => {
    index++;
    if (index < messages.length) {
      loadingMessage.value = messages[index];
    } else {
      clearInterval(interval);
    }
  }, 7000); // Update message every 7 seconds
};

// Computed property to filter out processes with "Not performing" involvement
const filteredProcessResult = computed(() => {
  return processResult.value ? processResult.value.filter(process => process.involvement !== "Not performing") : [];
});

// Handle the Next button click
const proceedToNext = async () => {
  if (!validateInput()) return;

  errorMessage.value = ''; // Reset error message

  // Create a combined JSON-like object for tasks as lists
  const tasksResponsibilities = {
    responsible_for: tasksResponsibleFor.value.split('\n').map(task => task.trim()).filter(task => task),
    supporting: tasksYouSupport.value.split('\n').map(task => task.trim()).filter(task => task),
    designing: tasksDefineAndImprove.value.split('\n').map(task => task.trim()).filter(task => task),
  };

  // Prepare the payload for the backend, including username and organizationId
  const payload = {
    username: userStore.username,
    organizationId: userStore.organizationId,
    tasks: tasksResponsibilities
  };

  // Store the tasks in the Pinia store
  userStore.setUserDetails({
    ...userStore.$state,
    tasksResponsibilities,
  });

  // Call the backend to find processes
  try {
    isLoading.value = true;
    simulateProgress(); // Start showing progress messages

    const response = await axios.post(`${API_BASE_URL}/findProcesses`, payload);

    if (response.status === 200) {
      processResult.value = response.data.processes; // Store the backend result
    } else {
      alert('An error occurred while identifying processes. Please try again.');
    }
  } catch (error) {
    if (error.response && error.response.status === 400 && error.response.data.status === 'invalid_tasks') {
      errorMessage.value = error.response.data.message; // Display backend error message
      showErrorPopup.value = true; // Show the error popup
    } else {
      alert('An unexpected error occurred. Please check your input or try again later.');
    }
  } finally {
    isLoading.value = false; // Stop loading
  }
};

// Proceed to the survey
const proceedToSurvey = () => {
  router.push('/competencySurvey');
};
</script>

<template>
  <v-app>
    <v-container fluid class="d-flex flex-column justify-center align-center" style="height: auto; background-color: #121212;">
      <h1 class="form-heading">Describe Your Tasks and Responsibilities</h1>
      <p class="instructions">Please provide detailed and accurate descriptions of your tasks and responsibilities in the following fields.</p>

      <!-- Textarea for Tasks Responsible For -->
      <v-textarea
        v-model="tasksResponsibleFor"
        label="Tasks you are responsible for"
        outlined
        dense
        rows="5"
        style="width: 400px; margin-bottom: 20px;"
        hint="Please describe the primary tasks for which you are responsible."
      ></v-textarea>

      <!-- Textarea for Tasks You Support -->
      <v-textarea
        v-model="tasksYouSupport"
        label="Tasks that you support"
        outlined
        dense
        rows="5"
        style="width: 400px; margin-bottom: 20px;"
        hint="Please describe tasks you provide support for."
      ></v-textarea>

      <!-- Textarea for Tasks and Processes You Define and Improve -->
      <v-textarea
        v-model="tasksDefineAndImprove"
        label="Tasks and processes that you define or design"
        outlined
        dense
        rows="5"
        style="width: 400px; margin-bottom: 20px;"
        hint="Please describe tasks and processes you are involved in defining or designing."
      ></v-textarea>

      <!-- Validation Popup -->
      <v-dialog v-model="showValidationPopup" persistent max-width="500">
        <v-card class="validation-popup">
          <v-card-title class="popup-title">Validation Error</v-card-title>
          <v-card-text class="popup-message">{{ validationMessage }}</v-card-text>
          <v-card-actions>
            <v-btn class="popup-button" color="primary" dark @click="showValidationPopup = false">OK</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- Error Popup -->
      <v-dialog v-model="showErrorPopup" persistent max-width="500">
        <v-card class="error-popup">
          <v-card-title class="popup-title">Invalid Tasks</v-card-title>
          <v-card-text class="popup-message">{{ errorMessage }}</v-card-text>
          <v-card-actions>
            <v-btn class="popup-button" color="primary" dark @click="showErrorPopup = false">OK</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- Loading Indicator -->
      <v-card v-if="isLoading" class="loading-card" outlined>
        <v-card-text class="loading-message">{{ loadingMessage }}</v-card-text>
        <v-progress-linear indeterminate color="primary"></v-progress-linear>
      </v-card>

      <!-- Results Section -->
      <v-card v-if="!isLoading && filteredProcessResult.length" class="results-card" outlined>
        <v-card-title class="results-title">Identified ISO Processes</v-card-title>
        <v-card-text>
          <v-simple-table dense>
            <thead>
              <tr>
                <th class="table-header">Process Name</th>
                <th class="table-header">Involvement</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="process in filteredProcessResult" :key="process.process_name">
                <td class="process-name">{{ process.process_name }}</td>
                <td class="involvement">{{ process.involvement }}</td>
              </tr>
            </tbody>
          </v-simple-table>
        </v-card-text>
        <div class="button-container">
          <v-btn class="proceed-button" color="success" dark @click="proceedToSurvey">
            Proceed to Survey
          </v-btn>
        </div>
      </v-card>

      <!-- Next Button -->
      <v-btn v-if="!isLoading && !processResult" class="next-button" color="success" dark @click="proceedToNext">
        Next
      </v-btn>
    </v-container>
  </v-app>
</template>


<style scoped>
.form-heading {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 20px;
}

.instructions {
  color: #c0c0c0;
  font-size: 1.2rem;
  text-align: center;
  margin-bottom: 30px;
}

.next-button {
  background-color: #4CAF50 !important;
  color: white !important;
  border-radius: 30px;
  padding: 15px 20px;
  font-size: 1.2rem;
  text-transform: uppercase;
  display: flex;
  align-items: center;
  justify-content: center;
  max-width: 200px;
  height: 50px !important;
}

.loading-card {
  width: 400px;
  margin-top: 20px;
  padding: 20px;
  background-color: #1e1e1e;
  color: white;
  border-radius: 10px;
  text-align: center;
}

.loading-message {
  font-size: 1.2rem;
  margin-bottom: 20px;
}

.results-card {
  width: 600px;
  margin-top: 20px;
  padding: 20px;
  background-color: #1e1e1e;
  color: white;
  border-radius: 10px;
}

.results-title {
  font-size: 1.5rem;
  margin-bottom: 10px;
  color: #43e298;
  text-align: center;
}

.table-header {
  color: #3579d3;
  font-weight: bold;
  text-align: left;
}

.process-name {
  color: white;
  padding: 5px 10px;
}

.involvement {
  color: #43e298;
  font-weight: bold;
  padding: 5px 10px;
}

.button-container {
  text-align: center;
  margin-top: 20px;
}

.proceed-button {
  background-color: #4CAF50 !important;
  color: white !important;
  border-radius: 30px;
  padding: 15px 20px;
  font-size: 1.2rem;
  text-transform: uppercase;
  max-width: 300px;
  height: 50px !important;
}

.error-popup {
  background-color: #1e1e1e;
  color: white;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
  transition: transform 0.3s, box-shadow 0.3s;
}

.error-popup:hover {
  transform: scale(1.02);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}

.popup-title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #ff4d4d;
  margin-bottom: 10px;
}

.popup-message {
  font-size: 1.2rem;
  color: #c0c0c0;
}

.popup-button {
  border-radius: 10px;
  transition: background-color 0.3s;
}

.popup-button:hover {
  background-color: #3579d3;
}

.validation-popup {
  background-color: #1e1e1e;
  color: white;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
  transition: transform 0.3s, box-shadow 0.3s;
}

.validation-popup:hover {
  transform: scale(1.02);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}
</style>
