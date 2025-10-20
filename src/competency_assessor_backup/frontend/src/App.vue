<script setup>
import { RouterView } from 'vue-router';
import FooterLink from '@/components/FooterLink.vue';
</script>

<template>
  <v-app>
    <v-main>
      <v-container fluid>
        <RouterView />
      </v-container>
    </v-main>
    <!-- Footer appears on every page -->
    <FooterLink />
  </v-app>
</template>

<style scoped>
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  background-color: #121212; /* Dark background */
}

/* Ensure that the root app container fills the full height of the viewport */
.v-app {
  min-height: 100vh;
  background-color: #121212; /* Set consistent dark background for app */
}

.v-main {
  display: flex;
  flex-direction: column;
  flex-grow: 1; /* Ensure the main content fills available space */
  justify-content: flex-start; /* Start content from the top */
  background-color: #121212;
}
</style>
