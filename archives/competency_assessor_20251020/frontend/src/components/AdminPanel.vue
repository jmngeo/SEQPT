<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

const navigateToCompetency = () => {
  router.push('/competencyCrud');
};

const navigateToCompetencyIndicator = () => {
  router.push('/competencyIndicatorCrud');
};

const navigateToRoleProcessMatrix = () => {
  router.push('/roleProcessMatrixCrud');
};

const navigateToProcessCompetencyMatrix = () => {
  router.push('/processCompetencyMatrixCrud');
};

const navigateToRoleCompetencyMatrix = () => {
  router.push('/roleCompetencyMatrixView');
};

const navigateToOrganizationCrud = () => {
  router.push('/OrganizationCrud');
};

const navigateToSurveyResultsAdmin = () => {
  router.push('/surveyResultsAdmin');
};

const navigateToISOProcess = () => {
  router.push('/ISOProcess');
};

const navigateToRoleClusters = () => {
  router.push('/RoleClusters');
};
</script>

<template>
  <v-app>
    <v-container
      fluid
      class="d-flex flex-column justify-center align-center"
      style="height: 100vh; background-color: #121212;">
      
      <h1 class="admin-panel-text">
        Admin Panel
      </h1>

      <!-- List for Stacked Options -->
      <v-list dense class="stacked-list">
        <!-- Manage Competencies -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToCompetency">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Manage Competencies</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- Manage Competency Indicators -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToCompetencyIndicator">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Manage Competency Indicators</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- View ISO Processes -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToISOProcess">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">View ISO Processes</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- View Role Clusters -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToRoleClusters">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">View Role Clusters</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- Configure Role Process Matrix -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToRoleProcessMatrix">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Configure Role Process Matrix</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- Configure Process Competency Matrix -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToProcessCompetencyMatrix" >
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Configure Process Competency Matrix</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
        
        <!-- Configure Role Competency Matrix -->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToRoleCompetencyMatrix">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">View Role Competency Matrix</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- Configure Organizations-->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToOrganizationCrud">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Manage Organizations</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

        <!-- Configure Survey Results-->
        <v-list-item class="clickable-card stacked-list-item" @click="navigateToSurveyResultsAdmin">
          <v-list-item-content>
            <v-list-item-title class="list-item-title">Survey Results</v-list-item-title>
          </v-list-item-content>
        </v-list-item>

      </v-list>
    </v-container>
  </v-app>
</template>

<style scoped>
.admin-panel-text {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 3rem;
  text-align: center;
  margin-bottom: 50px;
}

.stacked-list {
  width: 100%;
  max-width: 500px; /* Limit the width of the list */
  background-color: transparent; /* or set to #121212 to match the overall container */
  padding: 0; /* Remove default padding if needed */
}

.stacked-list-item {
  background-color: #2ba3c8;
  color: white;
  margin-bottom: 10px; /* Adjust margin as needed or set it to 0 for no gap */
  border-radius: 10px;
  transition: box-shadow 0.3s ease;
}

.stacked-list-item:hover {
  box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.4);
}

.list-item-title {
  font-size: 1.25rem;
  text-align: center;
  font-weight: bold;
  font-family: 'Roboto', sans-serif;
}

.clickable-card {
  cursor: pointer;
  padding: 1px;
}
</style>
