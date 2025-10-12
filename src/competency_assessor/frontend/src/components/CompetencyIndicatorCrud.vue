<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const competencies = ref([]); // Reactive data for competencies
const selectedCompetencyId = ref(null); // Stores the ID of the selected competency
const competencyIndicators = ref([]); // Stores indicators for the selected competency, grouped by level
const groupedIndicators = ref({}); // Store grouped indicators by proficiency levels
const indicatorsExist = ref(false); // Track whether there are existing indicators

// New Indicator form data
const newIndicator = ref({
  level: '',
  indicator_en: '',
  indicator_de: ''
});


// Predefined proficiency levels for the dropdown
const proficiencyLevels = [
  'verstehen',  // Understanding
  'beherrschen', // Mastery
  'kennen',      // Knowledge
  'anwenden'     // Application
];
// Load the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Fetch competencies for the dropdown
const fetchCompetencies = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/competencies`);
    competencies.value = response.data; // Store the fetched competencies
    console.log(competencies.value); // Inspect the structure in the console
  } catch (error) {
    console.error('Error fetching competencies:', error);
  }
};

// Fetch indicators for the selected competency and group them by proficiency level
const fetchIndicators = async () => {
  if (!selectedCompetencyId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/competency_indicators/${selectedCompetencyId.value}`);
    competencyIndicators.value = response.data;
    
    // Check if there are any indicators for the selected competency
    indicatorsExist.value = competencyIndicators.value.length > 0;

    // Group the indicators by proficiency level
    groupIndicatorsByLevel();
  } catch (error) {
    console.error('Error fetching competency indicators:', error);
  }
};

// Group the fetched indicators by proficiency level
const groupIndicatorsByLevel = () => {
  groupedIndicators.value = competencyIndicators.value.reduce((groups, indicator) => {
    const level = indicator.level;
    if (!groups[level]) {
      groups[level] = [];
    }
    groups[level].push({
      id: indicator.id,
      indicator_en: indicator.indicator_en,
      indicator_de: indicator.indicator_de
    });
    return groups;
  }, {});
};


// Create a new indicator
const createIndicator = async () => {
  if (!selectedCompetencyId.value) return;

  try {
    await axios.post(`${API_BASE_URL}/competency_indicators`, {
      competency_id: selectedCompetencyId.value,
      level: newIndicator.value.level,
      indicator_en: newIndicator.value.indicator_en,
      indicator_de: newIndicator.value.indicator_de
    });
    fetchIndicators(); // Refresh the indicators list after adding
    // Reset form fields after submission
    newIndicator.value = {
      level: '',
      indicator_en: '',
      indicator_de: ''
    };
  } catch (error) {
    console.error('Error creating competency indicator:', error);
  }
};

// Delete an indicator
const deleteIndicator = async (id) => {
  try {
    await axios.delete(`${API_BASE_URL}/competency_indicators/${id}`);
    fetchIndicators(); // Refresh the indicators list after deletion
  } catch (error) {
    console.error('Error deleting competency indicator:', error);
  }
};

// Fetch competencies on component mount
onMounted(() => {
  fetchCompetencies();
});
</script>
<template>
  <v-app>
    <v-container>
      <h1>Manage Competency Indicators</h1>

      <!-- Dropdown to select an existing competency -->
      <v-select
        v-model="selectedCompetencyId"
        :items="competencies"
        item-title="competency_name"
        item-value="id"
        label="Select Competency"
        @update:modelValue="fetchIndicators"
      ></v-select>

      <!-- If there are existing indicators, show them grouped by proficiency level -->
      <div v-if="indicatorsExist">
        <h2 class="mt-10">Existing Indicators</h2>

        <!-- Iterate over each group of proficiency levels with an inner scroll -->
        <div v-for="(indicators, level) in groupedIndicators" :key="level" class="indicator-group">
          <h3>{{ level }}</h3> <!-- Proficiency Level Header -->

          <!-- Scrollable container for each proficiency level -->
          <div class="scrollable-indicators">
            <v-row>
              <!-- Modify the `cols` to take up more space for wider cards -->
              <v-col v-for="indicator in indicators" :key="indicator.id" cols="12" sm="12" md="6">
                <v-card class="wider-card">
                  <v-card-subtitle class="wrapped-text">
                    <strong>EN:</strong> {{ indicator.indicator_en }} <br> <br>
                    <strong>DE:</strong> {{ indicator.indicator_de }}
                  </v-card-subtitle>
                  <v-card-actions>
                    <v-btn color="error" @click="deleteIndicator(indicator.id)">Delete</v-btn>
                  </v-card-actions>
                </v-card>
              </v-col>
            </v-row>
          </div>
        </div>
      </div>

      <!-- If no indicators exist, show a message -->
      <v-row v-if="!indicatorsExist && selectedCompetencyId">
        <v-col>
          <p>No indicators available for this competency.</p>
        </v-col>
      </v-row>

      <!-- Form to add a new indicator (always visible when a competency is selected) -->
      <v-form v-if="selectedCompetencyId" class="mt-5">
        <h2>Add a New Competency Indicator</h2>
        <!-- Dropdown for proficiency levels -->
        <v-select
          v-model="newIndicator.level"
          :items="proficiencyLevels"
          label="Proficiency Level"
          required
        ></v-select>
        <v-text-field v-model="newIndicator.indicator_en" label="Indicator (English)" required></v-text-field>
        <v-text-field v-model="newIndicator.indicator_de" label="Indicator (German)" required></v-text-field>
        <v-btn @click="createIndicator" color="success">Add Indicator</v-btn>
      </v-form>
    </v-container>
  </v-app>
</template>

<style scoped>
/* Add your styles here if needed */

/* Add this class to ensure text wrapping and add padding */
.wrapped-text {
  white-space: normal;
  word-wrap: break-word;
  padding-top: 10px; /* Optional padding */
  max-height: none; /* Remove height constraint */
  overflow: visible; /* Show all text without cutting off */
}

/* Scrollable area for each proficiency level group */
.scrollable-indicators {
  max-height: 300px; /* Adjust the height as needed */
  overflow-y: auto; /* Enable vertical scrolling */
  padding: 10px;
  border: 1px solid #ccc; /* Optional: Add border to indicate the scrollable area */
  border-radius: 5px;
  width: 70%; /* Reduce width to make the scrollable box narrower */
  margin-bottom: 20px;
}

.indicator-group {
  margin-bottom: 30px; /* Spacing between different proficiency groups */
}

/* Modify `v-card` width */
.wider-card {
  width: 100%; /* Expand to take up full available width */
  padding: 15px; /* Add padding to the card */
  background-color: #2a2a2a; /* Maintain the consistent dark theme */
}

.v-col {
  flex-basis: 100%; /* Ensure each card takes up more space horizontally */
  max-width: 100%; /* Prevent shrinking */
}

.v-card-actions {
  display: flex;
  justify-content: flex-end; /* Align the delete button to the right */
}
</style>
