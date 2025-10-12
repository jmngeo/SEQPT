<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const processes = ref([]);
const API_BASE_URL = process.env.VUE_APP_API_URL;

const fetchProcesses = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/iso_processes`);
    processes.value = response.data;
  } catch (error) {
    console.error('Error fetching ISO processes:', error);
  }
};

onMounted(() => {
  fetchProcesses();
});
</script>

<template>
  <!-- The dark prop on v-app ensures the dark theme is applied -->
  <v-app dark>
    <v-container>
      <!-- Page Title -->
      <h1 class="text-h5 font-weight-bold mt-5">ISO Processes</h1>
      <v-divider class="my-4"></v-divider>

      <!-- Refresh Button -->
      <v-btn color="primary" class="mb-5" @click="fetchProcesses">
        Refresh Processes
      </v-btn>

      <!-- If processes exist, show the headers and the list -->
      <template v-if="processes.length">
        <!-- Column Headers -->
        <v-row class="mb-2 font-weight-bold">
          <v-col cols="4">Name</v-col>
          <v-col cols="8">Description</v-col>
        </v-row>
        <v-divider class="mb-4"></v-divider>

        <!-- Each ISO Process Row with alternating shading -->
        <v-card
          v-for="(process, index) in processes"
          :key="process.id"
          class="mb-3 pa-3"
          dark
          :class="index % 2 === 0 ? 'grey darken-3' : 'grey darken-4'"
        >
          <v-row align="center">
            <v-col cols="4">
              <strong>{{ process.name }}</strong>
            </v-col>
            <v-col cols="8">
              <span>{{ process.description }}</span>
            </v-col>
          </v-row>
        </v-card>
      </template>

      <!-- If no processes are available, show an alert -->
      <template v-else>
        <v-row>
          <v-col cols="12">
            <v-alert type="info" border="left" color="blue lighten-4">
              No ISO processes available.
            </v-alert>
          </v-col>
        </v-row>
      </template>
    </v-container>
  </v-app>
</template>

<style scoped>
/* Ensure the application font is consistent with your design */
.v-application {
  font-family: 'Roboto', sans-serif;
}
</style>
