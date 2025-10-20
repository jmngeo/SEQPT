<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/useUserStore'; // Import Pinia store

const router = useRouter();
const userStore = useUserStore();

// Reactive state to store competencies and their indicators
const competencies = ref([]);
const currentCompetencyIndex = ref(0);  // Track current competency index
const selectedGroups = ref([]);  // Track the selected groups by user (now an array)
const currentIndicatorsByLevel = ref([]); // Store indicators for the current competency grouped by level
const isLoading = ref(false); // Track the loading state
const isSubmitModalVisible = ref(false); // Track the visibility of the submit modal
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// Fetch competencies and indicators on component mount
onMounted(async () => {
  try {
    isLoading.value = true;  // Set loading state
    const response = await axios.post(`${API_BASE_URL}/get_required_competencies_for_roles`, {
      role_ids: userStore.selectedRoles.map(role => role.id),
      organization_id: userStore.organizationId,
      user_name: userStore.username,
      survey_type: userStore.surveyType
    });
    competencies.value = response.data.competencies;
    if (competencies.value.length > 0) {
      await fetchIndicators(); // Fetch indicators for the first competency
      restoreSelection(); // Restore previously saved selection if available
    }
  } catch (error) {
    console.error('Error fetching competencies:', error);
    alert('An error occurred while fetching competencies. Please refresh the page or try again later.');
  } finally {
    isLoading.value = false;  // Remove loading state
  }
});

// Fetch indicators for the current competency
const fetchIndicators = async () => {
  if (currentCompetencyIndex.value >= competencies.value.length) return;

  const competencyId = competencies.value[currentCompetencyIndex.value].competency_id;
  try {
    isLoading.value = true;  // Set loading state
    const response = await axios.get(`${API_BASE_URL}/get_competency_indicators_for_competency/${competencyId}`);
    currentIndicatorsByLevel.value = response.data;  // Store grouped indicators
    restoreSelection(); // Restore the selection for the current competency
  } catch (error) {
    console.error('Error fetching competency indicators:', error);
    alert('An error occurred while fetching competency indicators. Please try again later.');
  } finally {
    isLoading.value = false;  // Remove loading state
  }
};

// Handle user selection of a group
const selectGroup = (groupNumber) => {
  if (groupNumber === 5) {
    // If "None of these" (group 5) is selected, deselect all others
    selectedGroups.value = [5];
  } else {
    if (selectedGroups.value.includes(groupNumber)) {
      // If the group is already selected, deselect it
      selectedGroups.value = selectedGroups.value.filter(group => group !== groupNumber);
    } else {
      // Add the selected group to the list
      selectedGroups.value.push(groupNumber);

      // If any group other than "None of these" is selected, remove group 5 from selections
      selectedGroups.value = selectedGroups.value.filter(group => group !== 5);
    }
  }
};

// Proceed to the next competency
const proceedToNext = () => {
  if (selectedGroups.value.length === 0) {
    alert("Please select at least one group to proceed.");
    return;
  }

  // Store the selected groups in Pinia store
  userStore.addOrUpdateCompetencySelections({
    competencyId: competencies.value[currentCompetencyIndex.value].competency_id,
    selectedGroups: [...selectedGroups.value]
  });

  // Move to the next competency or finish the survey
  if (currentCompetencyIndex.value < competencies.value.length - 1) {
    currentCompetencyIndex.value++;
    fetchIndicators(); // Load indicators for next competency
    selectedGroups.value = []; // Reset group selection for the next competency
  } else {
    isSubmitModalVisible.value = true; // Show submit modal
  }
};

// Handle user going back to the previous competency
const goBack = () => {
  if (currentCompetencyIndex.value > 0) {
    currentCompetencyIndex.value--;
    fetchIndicators(); // Load indicators for previous competency
    restoreSelection(); // Restore the previous selection for the current competency
  }
};

// Restore user's previously selected groups for the current competency
const restoreSelection = () => {
  const currentCompetencyId = competencies.value[currentCompetencyIndex.value].competency_id;
  selectedGroups.value = userStore.getCompetencySelections(currentCompetencyId);
};

// Handle survey submission
const submitSurvey = async () => {
  try {
    // Prepare data to send to the backend
    const competencyScores = userStore.competencySelections.map(selection => {
      // Extract the maximum value from the selected groups
      const maxGroup = Math.max(...selection.selectedGroups);
      let score = 0;

      if (maxGroup === 1) score = 1;  // kennen
      else if (maxGroup === 2) score = 2;  // verstehen
      else if (maxGroup === 3) score = 4;  // anwenden
      else if (maxGroup === 4) score = 6;  // beherrschen
      else score = 0;  // None of these

      return {
        competencyId: selection.competencyId,
        score: score
      };
    });

    const surveyData = {
      organization_id: userStore.organizationId,
      full_name: userStore.fullName,
      username: userStore.username,
      tasks_responsibilities: userStore.tasksResponsibilities,
      selected_roles:
        userStore.surveyType === "known_roles"
          ? userStore.selectedRoles.map((role) => ({
              id: role.id,
              name: role.name,
            }))
          : userStore.surveyType === "unknown_roles"
          ? [{ id: 40004, name: "Unknown Role" }]
          : userStore.surveyType === "all_roles"
          ? [{ id: 70007, name: "all_roles" }]
          : [],
      competency_scores: competencyScores,
      survey_type: userStore.surveyType
    };
    
    // Make a POST request to submit the survey
    const response = await axios.post(`${API_BASE_URL}/submit_survey`, surveyData);

    if (response.status === 200) {
      //alert("Survey Submitted Successfully!");
      // Redirect to the survey completion component
      router.push('/surveyCompletion');
    } else {
      alert("An error occurred while submitting the survey.");
    }
  } catch (error) {
    console.error('Error submitting survey:', error);
    alert('An error occurred while submitting the survey. Please try again later.');
  }

  isSubmitModalVisible.value = false; // Close the modal after submission
};
</script>


<template>
  <v-app>
    <v-container fluid class="d-flex flex-column justify-center align-center" style="height: auto; background-color: #121212;">
      <h1 class="form-heading">Systems Engineering Competency Assessment Survey</h1>

      <!-- Display loading indicator -->
      <v-progress-circular v-if="isLoading" indeterminate color="primary"></v-progress-circular>

      <!-- Display current competency question -->
      <div v-if="!isLoading && currentCompetencyIndex < competencies.length">
        <h2 class="competency-title">
          Question {{ currentCompetencyIndex + 1 }} of {{ competencies.length }}
        </h2>
        <p class="question-text">
          To which of these groups do you identify yourself?
        </p>

        <!-- Outer rectangle for indicator cards -->
        <v-sheet class="indicator-group-wrapper" elevation="2">
          <v-row class="d-flex align-stretch justify-center flex-wrap">
            <!-- Display options for the competency grouped by level -->
            <v-col v-for="(levelGroup, index) in currentIndicatorsByLevel" :key="index" cols="12" md="2" class="d-flex">
              <v-card 
                class="indicator-card"
                :class="{ 'selected': selectedGroups.includes(index + 1) }"
                @click="selectGroup(index + 1)"
              >
                <v-card-text class="text-center">
                  <strong class="group-title">Group {{ index + 1 }}</strong>
                  <hr class="separator-line">
                  <div v-for="(indicator, i) in levelGroup.indicators" :key="i">
                    <p class="indicator-text">{{ indicator.indicator_en }}</p>
                    <hr v-if="i < levelGroup.indicators.length - 1" class="separator-line">
                  </div>
                  <hr class="separator-line">
                </v-card-text>
              </v-card>
            </v-col>

            <!-- Additional option for "None of these" -->
            <v-col cols="12" md="2" class="d-flex">
              <v-card 
                class="indicator-card"
                :class="{ 'selected': selectedGroups.includes(5) }"
                @click="selectGroup(5)"
              >
                <v-card-text class="text-center">
                  <strong class="group-title">Group 5</strong>
                  <hr class="separator-line">
                  <p class="indicator-text">You do not see yourselves in any of these groups.</p>
                  <hr class="separator-line">
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
        </v-sheet>

        <!-- Navigation buttons to proceed to the next question or go back -->
        <v-row class="mt-4">
          <v-col class="d-flex justify-start">
            <v-btn @click="goBack" color="primary" dark class="back-button">Back</v-btn>
          </v-col>
          <v-col class="d-flex justify-end">
            <v-btn @click="proceedToNext" color="success" dark class="next-button">Next</v-btn>
          </v-col>
        </v-row>
      </div>

      <!-- Submit Modal Dialog -->
      <v-dialog v-model="isSubmitModalVisible" max-width="500">
        <v-card class="dark-theme">
          <v-card-title class="text-h5">End of Survey</v-card-title>
          <v-card-text>
            You have reached the end of the survey. Do you want to submit or go back?
          </v-card-text>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="primary" text @click="isSubmitModalVisible = false">Go Back</v-btn>
            <v-btn color="success" dark @click="submitSurvey">Submit</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-container>
  </v-app>
</template>



<style scoped>
.form-heading {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 30px;
}

.competency-title {
  color: #f0f0f0;
  font-size: 1.8rem;
  text-align: center;
  margin-bottom: 20px;
}

.question-text {
  color: #c0c0c0;
  font-size: 1.2rem;
  text-align: center;
  margin-bottom: 40px;
}

/* Outer rectangle to wrap all indicator cards */
.indicator-group-wrapper {
  background-color: #1e1e1e;
  padding: 30px;
  border-radius: 12px;
  width: 100%;
  max-width: 1200px;
  margin-bottom: 30px;
}

/* Indicator cards styling */
.indicator-card {
  background-color: #2e2e2e;
  color: white;
  padding: 20px;
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: stretch;  /* Stretch card items uniformly */
  width: 100%;
  height: auto; /* Allow height to adapt based on content */
  min-height: 300px;
}

.indicator-card:hover {
  transform: scale(1.05);
  box-shadow: 0px 4px 12px rgba(255, 255, 255, 0.3);
}

.indicator-card.selected {
  border: 3px solid #4CAF50;
  box-shadow: 0px 4px 20px #4CAF50;
}

/* Styling for the separator line between indicators */
.separator-line {
  border: 0;
  height: 1px;
  background: #4CAF50;
  margin: 10px 0;
}

/* Group title styling */
.group-title {
  font-weight: bold;
  font-size: 1.2rem;
  text-transform: uppercase;
  margin-bottom: 10px;
  text-align: center;
}

/* Indicator text styling for consistent alignment */
.indicator-text {
  text-align: left;
  margin-bottom: 10px;
  width: 100%;
}

/* Back and Next button styling */
.back-button {
  background-color: #1976d2 !important;  /* Blue for Back */
  color: white !important;
}

.next-button {
  background-color: #4CAF50 !important;  /* Green for Next */
  color: white !important;
}

.v-card.dark-theme {
  background-color: #333;
  color: white;
}
</style>
