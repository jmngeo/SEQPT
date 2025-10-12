<!-- AdminLogin.vue -->
<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()
const username = ref('')
const password = ref('')
const errorMessage = ref('')

const handleLogin = async () => {
  try {
    const response = await axios.post(`${process.env.VUE_APP_API_URL}/login`, {
      username: username.value,
      password: password.value,
    })
    if (response.data.success) {
      // Set an authentication flag that the router guard will check
      localStorage.setItem('isAdminAuthenticated', 'true')
      // Redirect to the admin dashboard; ensure the route here matches your router config.
      router.push('/adminPanel')
    } else {
      errorMessage.value = response.data.message
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.message || 'Login failed'
  }
}

</script>

<template>
  <v-app>
    <v-container class="d-flex flex-column justify-center align-center" style="height: 100vh;">
      <!-- Increase the max-width from 400px to 600px -->
      <v-card class="pa-5" style="min-width: 250px; max-width: 600px">
        <v-card-title class="text-h5">Admin Login</v-card-title>
        <v-card-text>
          <v-text-field v-model="username" label="Username" outlined dense></v-text-field>
          <v-text-field v-model="password" label="Password" outlined dense type="password"></v-text-field>
          <v-alert v-if="errorMessage" type="error" dense>{{ errorMessage }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-btn color="primary" @click="handleLogin">Login</v-btn>
        </v-card-actions>
      </v-card>
    </v-container>
  </v-app>
</template>
