<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/useUserStore'; // Import the Pinia store

const router = useRouter();
const userStore = useUserStore();

const roles = ref([]);
const selectedRoles = ref([]);
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// Fetch roles data from backend
onMounted(async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/roles`);
    roles.value = response.data;
  } catch (error) {
    console.error('Error fetching roles:', error);
  }
});

// Function to handle role selection
const toggleRoleSelection = (role) => {
  const index = selectedRoles.value.findIndex(
    (selectedRole) => selectedRole.id === role.id
  );

  // If the role is not selected, add it; otherwise, remove it
  if (index === -1) {
    selectedRoles.value.push({ id: role.id, name: role.name });
  } else {
    selectedRoles.value.splice(index, 1);
  }
};

// Function to delete a selected role
const deleteRole = (roleId) => {
  const index = selectedRoles.value.findIndex(
    (selectedRole) => selectedRole.id === roleId
  );
  if (index !== -1) {
    selectedRoles.value.splice(index, 1);
  }
};

// Function to start the competency assessment survey
const startSurvey = () => {
  if (selectedRoles.value.length > 0) {
    // Update Pinia store with selected roles and set survey type
    userStore.setSelectedRoles([...selectedRoles.value]);
    userStore.surveyType = 'known_roles';

    // Proceed to the survey component
    router.push('/competencySurvey');
  } else {
    alert('Please select at least one role to proceed to the survey.');
  }
};

// Function to navigate to FindRole component
const unknownRoleSurvey = () => {
  userStore.surveyType = 'unknown_roles';
  router.push('/findProcesses');
};

// Function to start the "Complete Survey"
// const startCompleteSurvey = () => {
//   userStore.surveyType = 'all_roles';
//   router.push('/competencySurvey');
// };
</script>


<template>
  <v-app>
    <v-container
      fluid
      class="d-flex flex-column align-center justify-center mt-5 main-container"
    >
      <h1 class="role-selection-title">Please select your role at work</h1>

      <v-row align="center" justify="left" class="g-4">
        <!-- Roles Cards -->
        <v-col
          v-for="role in roles"
          :key="role.id"
          cols="12"
          sm="6"
          md="4"
          lg="4"
          class="d-flex align-center justify-center mb-4"
        >
        <v-card
          class="role-card"
          :class="{ 'role-card-selected': selectedRoles.some((selectedRole) => selectedRole.id === role.id) }"
          @click="toggleRoleSelection(role)"
        >
          <div class="card-header">
            <v-card-title class="role-title">
              {{ role.name }}
              <!-- Check icon for selected roles -->
              <v-icon
                v-if="selectedRoles.some((selectedRole) => selectedRole.id === role.id)"
                color="white"
                class="ml-2"
                >mdi-check-circle</v-icon
              >
            </v-card-title>
          </div>
          <v-card-text class="role-description scrollable-text">
            {{ role.description }}
          </v-card-text>
        </v-card>
        </v-col>

        <!-- Can't Find Role Card -->
        <v-col cols="12" sm="6" md="4" lg="4" class="d-flex align-center justify-center mb-4">
          <v-card class="task-card" @click="unknownRoleSurvey">
            <v-card-title class="task-card-title">Can't Find Your Role?</v-card-title>
            <v-card-text class="task-card-text">
              Let our <span class="ai-highlight">AI</span> model map you to the most appropriate role based on your tasks and responsibilities.
            </v-card-text>
          </v-card>
        </v-col>

      </v-row>

      <!-- Selected Roles and Proceed Button -->
      <v-row justify="center" class="mt-5">
        <v-col cols="12" sm="8" md="6" class="d-flex flex-column align-center">
          <v-card v-if="selectedRoles.length > 0" class="selected-roles-card">
            <v-card-title class="selected-roles-title centered-title">
              Selected Roles
            </v-card-title>
            <v-card-text>
              <!-- Display selected roles -->
              <v-row
                v-for="role in selectedRoles"
                :key="role.id"
                class="selected-role-row d-flex align-center justify-space-between mb-2"
              >
                <v-col cols="6" class="selected-role-text">{{ role.name }}</v-col>
                <v-col cols="3" style="text-align: right;">
                  <v-btn icon small color="red" @click="deleteRole(role.id)">
                    <v-icon x-small>mdi-delete</v-icon>
                  </v-btn>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Proceed Button -->
          <v-btn class="start-survey-btn" @click="startSurvey">
            Proceed to Survey
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
}

.role-selection-title {
  font-family: 'Roboto', sans-serif;
  font-size: 3.5rem;
  font-weight: 900;
  text-align: center;
  margin-bottom: 50px;
  color: #f0f0f0;
  text-shadow: 3px 3px 8px rgba(0, 0, 0, 0.5);
}

.role-card {
  padding: 0;
  transition: box-shadow 0.3s ease, transform 0.3s ease;
  color: white;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 100%;
  max-width: 350px;
  height: 250px;  /* Uniform height for cards */
  background-color: #2e2e2e;
  border-radius: 8px;
  cursor: pointer;
  border: 2px solid transparent; /* Default border */
}

.centered-title {
  display: flex;
  justify-content: center;
  align-items: center;
  text-align: center; /* Align text in the center */
  width: 100%; /* Ensure full width to center within the card */
}

.card-header {
  background-color: #2ba3c8; /* A bright blue that contrasts well with dark theme */
  padding: 10px;
  border-radius: 8px 8px 0 0; /* Only top corners rounded */
}


.role-card-selected .card-header {
  background-color: #4fbb37 !important; /* Light green color to indicate selection */
  border: 3px solid #ffffff; /* Optional: Add a border if needed for emphasis */
  box-shadow: 0px 6px 20px #4fbb37; /* Optional: Add a shadow for better visibility */
}

.role-card:hover {
  box-shadow: 0px 4px 12px rgba(255, 255, 255, 0.5);
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

.task-card-selected {
  background-color: #acc124f7 !important; /* Light green color to indicate selection */
  border: 3px solid #ffffff; /* White border to make the card stand out */
  box-shadow: 0px 6px 20px #14c944; /* Bright shadow to stand out */
}

.text-center {
  font-weight: bold;
  font-size: 1.2rem;
  font-family: 'Roboto', sans-serif;
  text-align: center;
  color: white;
  word-wrap: break-word;
  padding: 10px 20px; /* Spacing for better alignment */
}

.task-card-title {
  font-weight: bold;
  font-size: 1.4rem; /* Slightly reduced font size for better fit */
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
  word-spacing: -0.1em;
}

.text-center,
.role-title {
  font-weight: bold;
  font-size: 1.2rem;
  font-family: 'Open Sans', sans-serif;
  text-align: center;
  color: white;
  word-wrap: break-word;
}

.scrollable-text {
  overflow-y: auto;
  max-height: 150px;  /* Set the max height for scrollability */
  padding: 10px;
  font-size: 1rem;
  font-family: 'Roboto', sans-serif;
  text-align: justify;
  word-spacing: -0.1em;
  hyphens: auto;
}

.selected-roles-card {
  background-color: #2e2e2e;
  padding: 30px;
  border-radius: 12px;
  color: white;
  margin-bottom: 20px;
  min-width: 600px;
  max-width: 700px;
}

.table-header {
  color: #43e298;
  font-weight: bold;
}

.selected-roles-title {
  font-size: 1.8rem;
  font-family: 'Roboto', sans-serif;
  margin-bottom: 20px;
}

.selected-role-text {
  font-size: 1.3rem;  /* Increased the font size */
  font-weight: bold;  /* Made it bold */
  color: #ffffff;  /* Bright color to stand out */
}

.parent-container {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  margin: 0 auto;
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
  max-width: 600px;
  min-width: 300px;
  height: 50px !important;
}
</style>
