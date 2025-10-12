<script setup>
import { ref, onMounted, watch, computed, nextTick } from 'vue';
import axios from 'axios';
import { Radar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  RadarController,
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler
} from 'chart.js';

// Register chart.js components
ChartJS.register(
  Title,
  Tooltip,
  Legend,
  RadarController,
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler
);

// State variables
const organizations = ref([]);
const selectedOrganizationId = ref(null);
const users = ref([]);
const selectedUsernames = ref([]);
const selectAll = ref(false);
const userScores = ref([]);
const maxScores = ref([]);
const selectedAreas = ref([]);
const chartData = ref(null);
const isLoading = ref(false);
const feedbackData = ref([]);
const allAreas = ref([]); // Store all competency areas
//ad the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;
// Fetch all available organizations
const fetchOrganizations = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/organizations`);
    if (response.status === 200) {
      organizations.value = response.data;
    } else {
      alert('Failed to fetch organizations');
    }
  } catch (error) {
    console.error('Error fetching organizations:', error);
  }
};

// Fetch users based on the selected organization
const fetchUsers = async () => {
  if (!selectedOrganizationId.value) return;

  try {
    const response = await axios.get(`${API_BASE_URL}/organization_users`, {
      params: { organization_id: selectedOrganizationId.value }
    });
    if (response.status === 200) {
      users.value = response.data;
      selectedUsernames.value = [];
      selectAll.value = false;
      await nextTick();
    } else {
      alert('Failed to fetch users');
    }
  } catch (error) {
    console.error('Error fetching users:', error);
  }
};

// Fetch competency data based on selected usernames
const fetchCompetencyData = async () => {
  if (selectedUsernames.value.length === 0 || !selectedOrganizationId.value) {
    chartData.value = null;
    feedbackData.value = [];
    return;
  }

  try {
    isLoading.value = true;

    const response = await axios.get(`${API_BASE_URL}/get_user_competency_results_admin`, {
      params: {
        organization_id: selectedOrganizationId.value,
        usernames: selectedUsernames.value
      },
      paramsSerializer: params => {
        return Object.keys(params)
          .map(key => {
            if (Array.isArray(params[key])) {
              return params[key].map(val => `${encodeURIComponent(key)}=${encodeURIComponent(val)}`).join('&');
            }
            return `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`;
          })
          .join('&');
      }
    });

    if (response.status === 200) {
      const { user_scores, max_scores, feedback_list } = response.data;

      userScores.value = user_scores || [];
      maxScores.value = max_scores || [];
      feedbackData.value = feedback_list.flat() || [];

      // Populate all competency areas
      allAreas.value = [...new Set(userScores.value.map(score => score.competency_area))];
      
      // Select all areas initially
      selectedAreas.value = [...allAreas.value];
      updateChartData();
    } else {
      alert('Failed to fetch competency results');
    }
  } catch (error) {
    console.error('Error fetching competency results:', error);
  } finally {
    isLoading.value = false;
  }
};

// Computed properties and methods
const filteredUserScores = computed(() =>
  userScores.value.filter(score => selectedAreas.value.includes(score.competency_area))
);

const filteredMaxScores = computed(() =>
  maxScores.value.filter(score => filteredUserScores.value.some(userScore => userScore.competency_id === score.competency_id))
);

const updateChartData = () => {
  if (filteredUserScores.value.length > 0 && filteredMaxScores.value.length > 0) {
    const competencyLabels = filteredUserScores.value.map(score => score.competency_name);
    const userData = filteredUserScores.value.map(score => score.score);
    const maxData = filteredMaxScores.value.map(score => score.max_score);

    chartData.value = {
      labels: competencyLabels,
      datasets: [
        {
          label: 'User Score',
          backgroundColor: 'rgba(76, 175, 80, 0.2)',
          borderColor: 'rgba(76, 175, 80, 1)',
          pointBackgroundColor: 'rgba(76, 175, 80, 1)',
          data: userData
        },
        {
          label: 'Required Score',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          borderColor: 'rgba(255, 99, 132, 1)',
          pointBackgroundColor: 'rgba(255, 99, 132, 1)',
          data: maxData
        }
      ]
    };
  } else {
    chartData.value = null;
  }
};

// Handle select all users
const toggleSelectAllUsers = () => {
  if (selectAll.value) {
    selectedUsernames.value = users.value.map(user => user.username);
  } else {
    selectedUsernames.value = [];
  }
};

const toggleAreaSelection = (area) => {
  if (selectedAreas.value.includes(area)) {
    selectedAreas.value = selectedAreas.value.filter(a => a !== area);
  } else {
    selectedAreas.value.push(area);
  }

  // Ensure chart updates properly
  updateChartData();
};


// Watchers
watch(selectAll, (newVal) => {
  toggleSelectAllUsers();
});

onMounted(() => {
  fetchOrganizations();
});

watch(
  selectedUsernames,
  (newVal) => {
    if (newVal && newVal.length > 0) {
      fetchCompetencyData();
    } else {
      chartData.value = null;
    }
  },
  { deep: true }
);
</script>

<template>
  <v-app>
    <v-container fluid class="layout-container">
      <!-- Sidebar for User Selection -->
      <v-sheet elevation="3" class="sidebar">
        <h2 class="section-heading">Users</h2>

        <!-- Select Organization -->
        <v-select
          v-model="selectedOrganizationId"
          :items="organizations"
          item-title="organization_name"
          item-value="id"
          label="Select Organization"
          @update:modelValue="fetchUsers"
          dense
          outlined
          class="custom-select"
        ></v-select>

        <!-- Select All Users -->
        <v-checkbox
          v-if="users.length > 0"
          v-model="selectAll"
          label="Select All Users"
          class="custom-checkbox"
        ></v-checkbox>

        <!-- User List -->
        <div class="user-list" v-if="selectedOrganizationId">
          <v-checkbox
            v-for="user in users"
            :key="user.username"
            v-model="selectedUsernames"
            :label="user.name"
            :value="user.username"
            class="custom-checkbox reduced-line-spacing"
          ></v-checkbox>
        </div>
      </v-sheet>

      <!-- Main Content -->
      <div class="main-content">
        <!-- Radar Chart Section -->
        <v-sheet elevation="3" class="chart-section">
          <h1 class="chart-title">SE Competency Assessment Results</h1>
          <div v-if="selectedUsernames.length === 0" class="placeholder-message">Please select user(s) to show the results.</div>

          <!-- Competency Area Selection -->
          <div class="legend-container" v-if="userScores.length > 0">
            <h3 class="legend-title">Select Competency Areas:</h3>
            <v-row class="justify-center">
              <v-col
                v-for="area in allAreas"
                :key="area"
                cols="auto"
                class="d-flex justify-center"
              >
                <v-chip
                  :color="selectedAreas.includes(area) ? '#ECB365' : 'grey'"
                  outlined
                  @click="toggleAreaSelection(area)"
                >
                  {{ area }}
                </v-chip>
              </v-col>
            </v-row>
          </div>


          <v-progress-circular v-if="isLoading" indeterminate color="primary"></v-progress-circular>
          <Radar v-else-if="chartData" :data="chartData" :options="chartOptions" />
        </v-sheet>

        <!-- Feedback Section -->
        <v-sheet elevation="3" class="feedback-section">
          <h3 class="feedback-title">Competency Feedback</h3>
          <div v-if="selectedUsernames.length !== 1" class="placeholder-message">
            Please select only one user to view the feedback.
          </div>
          <div v-else>
            <div v-for="feedbackArea in feedbackData" :key="feedbackArea.competency_area" class="competency-feedback-group">
              <h4 class="competency-area-title">{{ feedbackArea.competency_area }}</h4>
              <div v-for="feedback in feedbackArea.feedbacks" :key="feedback.competency_name" class="individual-feedback">
                <h5 class="feedback-competency-name">{{ feedback.competency_name }}</h5>
                <p class="feedback-text"><strong>User Strengths:</strong> {{ feedback.user_strengths || 'N/A' }}</p>
                <p class="feedback-text"><strong>Improvement Areas:</strong> {{ feedback.improvement_areas || 'N/A' }}</p>
              </div>
            </div>
          </div>
        </v-sheet>
      </div>
    </v-container>
  </v-app>
</template>

<script>
// Chart options for Radar chart
const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  scales: {
    r: {
      min: 0,               // Force the minimum value to 0
      beginAtZero: true,    // Ensure the scale starts at 0
      ticks: {
        stepSize: 1,        // Increment the ticks by 1
        precision: 0,       // Ensure whole numbers
        color: '#ffffff',   // Set tick label color
        backdropColor: 'transparent', // Remove background behind tick labels
      },
      grid: {
        color: 'rgba(255, 255, 255, 0.2)', // Style grid lines
      },
      angleLines: {
        display: true,           // Enable the center-to-edge lines
        color: 'rgba(255, 255, 255, 0.2)', // Set the color of the lines
        lineWidth: 1,            // Set the line width (adjust as needed)
      },
      pointLabels: {
        color: '#ffffff',        // Set label color
        font: {
          size: 14,             // Adjust font size for labels
        },
      },
    }
  },
  plugins: {
    legend: {
      position: 'bottom',
      align: 'center',
      labels: {
        color: '#ffffff',
        boxWidth: 20,
        padding: 10,
        font: {
          size: 14
        }
      }
    }
  },
  layout: {
    padding: {
      bottom: 100
    }
  }
};



</script>

<style scoped>
.layout-container {
  display: flex;
  height: 100vh;
  padding: 20px;
  background-color: #121212;
  gap: 20px;
  overflow: auto;
}

.sidebar {
  width: 15%;
  background-color: #1e1e1e;
  padding: 20px;
  border-radius: 16px;
  overflow-y: auto;
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
}

.section-heading {
  color: #ffffff;
  font-family: 'Roboto', sans-serif;
  font-size: 1.5rem;
  margin-bottom: 20px;
}

.user-list {
  max-height: 70vh;
  overflow-y: auto;
}

.custom-checkbox {
  margin-bottom: 5px;
}

.reduced-line-spacing {
  margin-bottom: 5px !important;
}

.main-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 85%;
}

.chart-section, .feedback-section {
  background-color: #1e1e1e;
  padding: 20px;
  border-radius: 16px;
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
  overflow: hidden;
}

.chart-section {
  height: 70vh;
}

.chart-title {
  color: #ffffff;
  font-family: 'Roboto', sans-serif;
  font-size: 2rem;
  text-align: center;
  margin-bottom: 20px;
}

.legend-container {
  margin-bottom: 20px;
  text-align: center;
}

.feedback-section {
  height: 40vh;
  overflow-y: auto;
}

.feedback-title {
  font-size: 2rem;
  font-family: 'Poppins', sans-serif;
  font-weight: bold;
  text-align: center;
  margin-bottom: 20px;
  color: #ffcc00;
}

.competency-feedback-group {
  margin-bottom: 25px;
}

.competency-area-title {
  font-size: 1.5rem;
  font-weight: bold;
  font-family: 'Poppins', sans-serif;
  margin-bottom: 15px;
  color: #00bcd4;
}

.individual-feedback {
  margin-bottom: 20px;
  padding: 15px;
  border-radius: 8px;
  background-color: #383838;
  box-shadow: 0px 2px 10px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease-in-out;
}

.individual-feedback:hover {
  transform: scale(1.02);
  box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.5);
  background-color: #454545;
}

.v-progress-circular {
  margin-top: 30px;
}

.placeholder-message {
  color: #c0c0c0;
  font-size: 1.2rem;
  text-align: center;
  margin-top: 20px;
}
</style>
