<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const roles = ref([]);
const API_BASE_URL = process.env.VUE_APP_API_URL;

const fetchRoles = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/roles`);
    roles.value = response.data;
  } catch (error) {
    console.error('Error fetching roles:', error);
  }
};

onMounted(() => {
  fetchRoles();
});
</script>

<template>
  <v-app>
    <v-container>
      <!-- Page Title -->
      <h1 class="text-h5 font-weight-bold mt-5">Role Clusters</h1>
      <v-divider class="my-4"></v-divider>

      <!-- Button to refresh the list of roles -->
      <v-btn color="primary" class="mb-5" @click="fetchRoles">
        Refresh Roles
      </v-btn>

      <!-- If we have roles, display them with headers -->
      <template v-if="roles.length">
        <!-- Column Headers -->
        <v-row class="mb-2 font-weight-bold">
          <v-col cols="4">Name</v-col>
          <v-col cols="8">Description</v-col>
        </v-row>
        <v-divider class="mb-4"></v-divider>

        <!-- Display each role in its own row -->
        <v-row dense v-for="role in roles" :key="role.id" class="mb-2">
          <v-col cols="4">
            {{ role.name }}
          </v-col>
          <v-col cols="8">
            {{ role.description }}
          </v-col>
        </v-row>
      </template>

      <!-- Otherwise, show a message if no roles are available -->
      <template v-else>
        <v-row>
          <v-col cols="12">
            <v-alert type="info" border="left" color="blue lighten-4">
              No role clusters available.
            </v-alert>
          </v-col>
        </v-row>
      </template>
    </v-container>
  </v-app>
</template>

<style scoped>
.v-application {
  font-family: 'Roboto', sans-serif;
}
</style>
