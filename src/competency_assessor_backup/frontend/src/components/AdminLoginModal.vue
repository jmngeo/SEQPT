<script setup>
import { ref, defineProps, defineEmits, watch } from 'vue';
import axios from 'axios';

const props = defineProps(['isVisible']); // Accept isVisible prop
const emit = defineEmits(['close', 'success']);
const localIsVisible = ref(props.isVisible); // Local copy of isVisible prop

const username = ref('');
const password = ref('');
const errorMessage = ref('');
// Load the API base URL from the environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Watch for changes in the isVisible prop and update localIsVisible
watch(() => props.isVisible, (newVal) => {
  localIsVisible.value = newVal;
});

const closeModal = () => {
  emit('close'); // Notify parent to close the modal
};

const authenticateAdmin = async () => {
  try {
    const response = await axios.post(`${API_BASE_URL}/login`, {
      username: username.value,
      password: password.value,
    });

    if (response.data.success) {
      emit('success'); // Notify parent of success
    } else {
      errorMessage.value = response.data.message;
    }
  } catch (error) {
    if (error.response) {
      // Non-2xx responses fall here
      if (error.response.status === 401) {
        errorMessage.value = error.response.data.message || 'Invalid username or password';
      } else {
        errorMessage.value = error.response.data.message || 'An error occurred. Please try again.';
      }
    } else {
      console.error('Error during login:', error);
      errorMessage.value = 'A network error occurred. Please try again.';
    }
  }
};

</script>

<template>
<v-dialog v-model="localIsVisible" max-width="400">
  <v-card>
    <v-card-title class="text-h5">Admin Login</v-card-title>
    <v-card-text>
      <v-text-field v-model="username" label="Username" outlined dense></v-text-field>
      <v-text-field v-model="password" label="Password" outlined dense type="password"></v-text-field>
      <v-alert v-if="errorMessage" type="error" dense>{{ errorMessage }}</v-alert>
    </v-card-text>
    <v-card-actions>
      <v-btn text @click="closeModal">Cancel</v-btn>
      <v-btn color="primary" @click="authenticateAdmin">Login</v-btn>
    </v-card-actions>
  </v-card>
</v-dialog>
</template>

<style scoped>
.login-card {
  background-color: #070707; /* Dark theme background */
  color: white; /* Text color */
  border-radius: 12px; /* Slightly curved corners */
  box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.5); /* Subtle shadow */
}

.input-field {
  margin-bottom: 16px; /* Space between inputs */
  background-color: #2e2e2e; /* Slightly lighter background for inputs */
  border-radius: 8px; /* Rounded input fields */
}

.input-field .v-input__control {
  color: white; /* Text color inside inputs */
}

.error-alert {
  margin-top: 16px; /* Space above the alert */
  color: #ff5252; /* Error text color */
  background-color: #2e1e1e; /* Error alert background */
  border-radius: 8px; /* Rounded alert box */
}

.v-btn {
  border-radius: 8px; /* Rounded buttons */
}

.v-btn[color="primary"] {
  background-color: #2ba3c8; /* Professional blue shade */
}

.v-btn[color="grey"] {
  color: #c0c0c0; /* Grey button text */
}
</style>
