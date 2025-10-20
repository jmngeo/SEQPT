<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import { useUserStore } from '@/stores/useUserStore'; // Import Pinia store
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

// Import Pinia store
const userStore = useUserStore();

// Reactive state for storing chart data, loading state, user scores, max scores, and feedback
const chartData = ref(null);
const isLoading = ref(true);
const userScores = ref([]);
const maxScores = ref([]);
const selectedAreas = ref([]);
const feedbackData = ref([]); // Store aggregated feedback from the backend
const mostSimilarRole = ref(null); // Store the most similar role for the 'all_roles' survey type
const userMessage = ref(''); // User-friendly message about the most similar role
// Add the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Fetch competency data for the radar chart and feedback when the component mounts
onMounted(async () => {
  try {
    // Make a request to fetch user competency scores and feedback from the backend
    const response = await axios.get(`${API_BASE_URL}/get_user_competency_results`, {
      params: {
        username: userStore.username, // Get the username from Pinia store
        organization_id: userStore.organizationId, // Get the organization ID from Pinia store
        survey_type: userStore.surveyType // Get the survey type from Pinia store
      }
    });

    if (response.status === 200) {
      // Assign user scores, max scores, and feedback from API response
      userScores.value = response.data.user_scores || [];
      maxScores.value = response.data.max_scores || [];

      // Flatten feedbackData in case it's nested within an additional array
      feedbackData.value = response.data.feedback_list.flat() || [];
      // Handle most_similar_role as a list of dictionaries
      const mostSimilarRoleData = response.data.most_similar_role || [];
      mostSimilarRole.value = mostSimilarRoleData; // Store the entire list of matching roles

      console.log("User Scores:", userScores.value);
      console.log("Feedback Data:", feedbackData.value);
      console.log("Most Similar Role:", mostSimilarRole.value);
      selectedAreas.value = [...new Set(userScores.value.map(score => score.competency_area))];

      updateChartData();
      // If the survey type is 'all_roles', generate a user-friendly message
      if (userStore.surveyType === 'all_roles' && mostSimilarRole.value.length > 0) {
        const roleNames = mostSimilarRole.value.map(role => role.role_cluster_name).join(', ');
        userMessage.value = `Based on your survey answers, we have identified that your scores are mostly matching to the following roles: ${roleNames}`;
      }
    } else {
      alert("An error occurred while fetching competency results.");
    }
  } catch (error) {
    console.error('Error fetching competency results:', error);
    alert('An error occurred while fetching competency results. Please try again later.');
  } finally {
    isLoading.value = false;
  }
});

// Computed property for filtered user scores based on selected competency areas
const filteredUserScores = computed(() =>
  userScores.value.filter(score => selectedAreas.value.includes(score.competency_area))
);

// Computed property for filtered max scores based on selected competency areas
const filteredMaxScores = computed(() =>
  maxScores.value.filter(score => filteredUserScores.value.some(userScore => userScore.competency_id === score.competency_id))
);

// Update chart data based on selected competency areas
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

// Handle clicking on competency areas to filter radar chart
const toggleAreaSelection = (area) => {
  if (selectedAreas.value.includes(area)) {
    selectedAreas.value = selectedAreas.value.filter(a => a !== area);
  } else {
    selectedAreas.value.push(area);
  }
  updateChartData(); // Update the chart after changing the selection
};

// Function to generate and download the PDF
const downloadResults = async () => {
  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm', // Use millimeters for better control over print layout
    format: 'a4'
  });

  const pageWidth = doc.internal.pageSize.width; // A4 width in mm
  const pageHeight = doc.internal.pageSize.height; // A4 height in mm
  const margin = 20; // Standard margin for print-friendly documents
  const maxWidth = pageWidth - 2 * margin; // Content width inside margins
  let currentYOffset = margin; // Start content below the top margin

  const lineHeight = 7; // Line height for text
  const sectionSpacing = 10; // Space between sections
  const headerFontSize = 16;
  const normalFontSize = 12;
  const subtitleFontSize = 14;
  const highlightColor = '#4CAF50'; // Subtle green highlight for titles

  // Define survey type description
  let surveyTypeDescription = '';
  if (userStore.surveyType === 'all_roles') {
    surveyTypeDescription = 'Assessing all competencies and identifying the most suitable role.';
  } else if (userStore.surveyType === 'unknown_roles') {
    surveyTypeDescription =
      'Assessing user based on tasks performed and the required competencies to perform these tasks.';
  } else if (userStore.surveyType === 'known_roles') {
    surveyTypeDescription = 'Assessing user competency for a particular role.';
  }

  // Add Title and User Info
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(18);
  doc.setTextColor('#000000'); // Black for main title
  doc.text('Survey Results', pageWidth / 2, currentYOffset, { align: 'center' });
  currentYOffset += sectionSpacing;

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(normalFontSize);
  doc.text(`User: ${userStore.username}`, margin, currentYOffset);
  currentYOffset += lineHeight;
  doc.text(`Date: ${new Date().toLocaleString()}`, margin, currentYOffset);
  currentYOffset += lineHeight;

  // Add Survey Type
  doc.setFont('Helvetica', 'italic');
  doc.setFontSize(subtitleFontSize);
  doc.setTextColor('#333333'); // Subtle dark gray for descriptions
  doc.text(`Survey Type: ${surveyTypeDescription}`, margin, currentYOffset);
  currentYOffset += sectionSpacing;

  // Add Selected Roles for `known_roles`
  if (userStore.surveyType === 'known_roles' && userStore.selectedRoles.length > 0) {
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(headerFontSize);
    doc.setTextColor(highlightColor); // Green highlight for section title
    doc.text('Selected Roles:', margin, currentYOffset);
    currentYOffset += sectionSpacing;

    doc.setFont('Helvetica', 'normal');
    doc.setFontSize(normalFontSize);
    doc.setTextColor('#000000'); // Black for role names
    userStore.selectedRoles.forEach((role, index) => {
      doc.text(`- ${role.name}`, margin + 5, currentYOffset);
      currentYOffset += lineHeight;

      // Add new page if needed
      if (currentYOffset > pageHeight - margin) {
        doc.addPage();
        currentYOffset = margin; // Reset Y offset for the new page
      }
    });
    currentYOffset += sectionSpacing;
  }

  // If survey type is `all_roles`, add matching roles
  if (userStore.surveyType === 'all_roles' && mostSimilarRole.value.length > 0) {
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(headerFontSize);
    doc.setTextColor(highlightColor);
    doc.text('Recommended Roles:', margin, currentYOffset);
    currentYOffset += sectionSpacing;

    doc.setFont('Helvetica', 'normal');
    doc.setFontSize(normalFontSize);
    doc.setTextColor('#000000');
    mostSimilarRole.value.forEach((role) => {
      const roleText = `- ${role.role_cluster_name}`;
      const wrappedRoleText = doc.splitTextToSize(roleText, maxWidth);
      doc.text(wrappedRoleText, margin + 5, currentYOffset);
      currentYOffset += wrappedRoleText.length * lineHeight;

      // Add new page if needed
      if (currentYOffset > pageHeight - margin) {
        doc.addPage();
        currentYOffset = margin; // Reset Y offset for the new page
      }
    });

    currentYOffset += sectionSpacing;
  }

  // Add Radar Chart
  const chartElement = document.querySelector('.chart-container'); // Radar chart container
  if (chartElement) {
    const chartCanvas = await html2canvas(chartElement, {
      backgroundColor: '#ffffff' // Light theme background
    });
    const chartImage = chartCanvas.toDataURL('image/png');

    // Get original dimensions of the chart
    const originalWidth = chartElement.offsetWidth;
    const originalHeight = chartElement.offsetHeight;

    // Calculate aspect ratio and scaled dimensions
    const aspectRatio = originalHeight / originalWidth;
    const chartWidth = maxWidth; // Fit chart width inside margins
    const chartHeight = chartWidth * aspectRatio; // Scale height proportionally

    doc.addImage(chartImage, 'PNG', margin, currentYOffset, chartWidth, chartHeight);
    currentYOffset += chartHeight + sectionSpacing;
  }

  // Add Feedback Section
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(headerFontSize);
  doc.setTextColor(highlightColor);
  doc.text('Feedbacks:', margin, currentYOffset);
  currentYOffset += sectionSpacing;

  feedbackData.value.forEach((feedbackArea) => {
    // Add competency area title
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(subtitleFontSize);
    doc.setTextColor('#333333');
    doc.text(`${feedbackArea.competency_area}:`, margin, currentYOffset);
    currentYOffset += lineHeight;

    feedbackArea.feedbacks.forEach((feedback) => {
      doc.setFont('Helvetica', 'normal');
      doc.setFontSize(normalFontSize);
      doc.setTextColor('#000000');

      // Add competency name
      const competencyText = doc.splitTextToSize(`- ${feedback.competency_name}`, maxWidth);
      doc.text(competencyText, margin + 5, currentYOffset);
      currentYOffset += lineHeight * competencyText.length;

      // Add strengths
      const strengthsText = doc.splitTextToSize(`  Strengths: ${feedback.user_strengths || 'N/A'}`, maxWidth);
      doc.text(strengthsText, margin + 10, currentYOffset);
      currentYOffset += lineHeight * strengthsText.length;

      // Add improvement areas
      const improvementsText = doc.splitTextToSize(
        `  Improvements: ${feedback.improvement_areas || 'N/A'}`,
        maxWidth
      );
      doc.text(improvementsText, margin + 10, currentYOffset);
      currentYOffset += lineHeight * improvementsText.length;

      currentYOffset += lineHeight; // Add spacing after each feedback item

      // Add new page if needed
      if (currentYOffset > pageHeight - margin) {
        doc.addPage();
        currentYOffset = margin; // Reset Y offset for the new page
      }
    });

    currentYOffset += sectionSpacing; // Add spacing after each competency area
  });

  // Save the PDF
  doc.save(`Survey_Results_${userStore.username}_${Date.now()}.pdf`);
};

</script>

<template>
  <v-app>
    <v-container fluid style="min-height: 100vh; background-color: #121212;">
      <!-- Loading Section -->
      <div v-if="isLoading" class="loading-container">
        <v-progress-circular indeterminate size="70" color="primary" />
        <p class="loading-text">Analyzing your responses... Our AI is generating a personalized assessment for you.</p>
      </div>

      <!-- Main Content Section -->
      <div v-else>
        <!-- User ID Info -->
        <div class="user-id-info">
          Your survey user name id is: <strong>{{ userStore.username }}</strong>. Remember it if you need to access the results again in the future.
        </div>
        <!-- Chart Section -->
        <div class="d-flex flex-column justify-center align-center chart-section">
          <h1 class="result-heading">Your SE Competency Assessment Results</h1>

          <!-- Most Similar Role Section -->
          <v-sheet
            v-if="userStore.surveyType === 'all_roles' && mostSimilarRole.length > 0"
            elevation="3"
            class="most-similar-role-container"
          >
            <h3 class="most-similar-role-title">The Role that most fits your recorded competency levels:</h3>
            <ul class="most-similar-role-list">
              <li v-for="role in mostSimilarRole" :key="role.id" class="most-similar-role-item">
                {{ role.role_cluster_name }}
              </li>
            </ul>
          </v-sheet>

          <!-- Display radar chart and competency area selection -->
          <v-sheet elevation="3" class="chart-container">
            <div class="legend-container">
              <h3 class="legend-title">Select Competency Areas:</h3>
              <v-row class="justify-center">
                <v-col
                  v-for="area in [...new Set(userScores.map(score => score.competency_area))]"
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
            <Radar v-if="chartData" :data="chartData" :options="chartOptions" />
            <p v-else class="error-message">No data available to display.</p>
          </v-sheet>
        </div>

        <!-- Feedback Section -->
        <div class="d-flex flex-column justify-center align-center feedback-section">
          <v-sheet elevation="3" class="feedback-container-scrollable">
            <h3 class="feedback-title">Detailed Competency Feedback</h3>
            <div v-for="feedbackArea in feedbackData" :key="feedbackArea.competency_area" class="competency-feedback-group">
              <h4 class="competency-area-title">{{ feedbackArea.competency_area }}</h4>
              <div v-for="feedback in feedbackArea.feedbacks" :key="feedback.competency_name" class="individual-feedback">
                <h5 class="feedback-competency-name">{{ feedback.competency_name }}</h5>
                <p class="feedback-text"><strong>User Strengths:</strong> {{ feedback.user_strengths || 'N/A' }}</p>
                <p class="feedback-text"><strong>Improvement Areas:</strong> {{ feedback.improvement_areas || 'N/A' }}</p>
              </div>
            </div>
          </v-sheet>
        </div>
      </div>
      <!-- Download Results Button -->
      <div class="download-button-container" v-if="!isLoading">
          <v-btn color="primary" @click="downloadResults">Download Results</v-btn>
      </div>
    </v-container>
  </v-app>
</template>

<script>
// Chart options for Radar chart (unchanged)
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
        backdropColor: 'transparent', // Remove the background behind tick labels
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
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;600&display=swap');

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  color: #ffffff;
  font-family: 'Poppins', sans-serif;
  font-size: 1.5rem;
}

.loading-text {
  margin-top: 20px;
  text-align: center;
  color: #ffcc00;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
  100% {
    opacity: 1;
  }
}

.result-heading {
  color: #ffffff;
  font-family: 'Poppins', sans-serif;
  font-size: 2.8rem;
  text-align: center;
  margin-bottom: 20px;
}

/* New User ID info styling */
.user-id-info {
  color: #ffffff;
  font-family: 'Poppins', sans-serif;
  font-size: 1.2rem;
  text-align: center;
  margin-bottom: 20px;
}

.chart-container {
  background-color: #1e1e1e;
  padding: 20px;
  border-radius: 16px;
  max-width: 800px;
  width: 100%;
  height: 700px;
  overflow: hidden;
  text-align: center;
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
  margin-bottom: 40px; /* Separate chart section from feedback section */
}

.legend-container {
  margin-bottom: 20px;
  text-align: center;
}

.legend-title {
  color: #ffcc00;
  font-family: 'Poppins', sans-serif;
  font-size: 1.6rem;
  margin-bottom: 15px;
}

.feedback-container-scrollable {
  background-color: #1e1e1e;
  color: #ffffff;
  padding: 25px;
  border-radius: 16px;
  max-width: 800px;
  width: 100%;
  max-height: 500px; /* Set maximum height */
  overflow-y: auto; /* Enable vertical scroll */
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
}

.feedback-title {
  font-size: 2rem;
  font-family: 'Poppins', sans-serif;
  font-weight: bold;
  text-align: center;
  margin-bottom: 30px;
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
  color: #00bcd4; /* Highlight competency area title */
  text-align: center;
}

.individual-feedback {
  margin-bottom: 20px;
  padding: 15px;
  border-radius: 8px;
  background-color: #383838; /* Provide a subtle background to individual feedbacks */
  box-shadow: 0px 2px 10px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease-in-out;
}

.individual-feedback:hover {
  transform: scale(1.02);
  box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.5);
  background-color: #454545; /* Darken background on hover */
}

.feedback-competency-name {
  font-size: 1.4rem;
  font-family: 'Poppins', sans-serif;
  color: #ff9800;
  margin-bottom: 10px;
}

.feedback-text {
  font-size: 1.1rem;
  font-family: 'Poppins', sans-serif;
  margin: 8px 0;
  color: #d3d3d3;
}

.v-progress-circular {
  margin-top: 30px;
}

.chart-section {
  padding-bottom: 30px; /* Space between chart section and feedback section */
}

.feedback-section {
  padding-top: 20px; /* Additional padding to separate from the chart section */
}

.most-similar-role-container {
  background-color: #2e2e2e;
  color: #ffffff;
  padding: 20px;
  border-radius: 16px;
  max-width: 800px;
  width: 100%;
  margin-bottom: 20px; /* Space between this section and the radar chart */
  box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.5);
  text-align: center;
}

.most-similar-role-title {
  font-size: 1.8rem;
  font-family: 'Poppins', sans-serif;
  font-weight: bold;
  margin-bottom: 15px;
  color: #ffcc00;
}

.most-similar-role-list {
  list-style-type: none;
  padding: 0;
}

.most-similar-role-item {
  font-size: 1.3rem;
  font-family: 'Poppins', sans-serif;
  margin: 10px 0;
  color: #ffffff;
  background-color: #383838;
  padding: 10px;
  border-radius: 8px;
  box-shadow: 0px 2px 10px rgba(0, 0, 0, 0.3);
  transition: transform 0.3s ease-in-out;
}

.most-similar-role-item:hover {
  transform: scale(1.05);
  background-color: #454545;
}

.download-button-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.v-btn {
  color: #ffffff;
  background-color: #4CAF50;
  border-radius: 20px;
  padding: 10px 20px;
  text-transform: uppercase;
  font-size: 1rem;
  font-weight: bold;
}

</style>
