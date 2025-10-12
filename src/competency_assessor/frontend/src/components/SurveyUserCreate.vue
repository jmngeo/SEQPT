<script setup>
import { ref, onMounted, watch } from 'vue';
import axios from 'axios';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/useUserStore';

const router = useRouter();
const userStore = useUserStore();

// Reactive data for user details
const organizationType = ref(null);
const selectedOrganizationId = ref(null);
const organizationKey = ref('');
const organizationError = ref('');
const isFetchingOrganizationId = ref(false); // Loading state for fetching organization ID

// API Base URL from environment variable
const API_BASE_URL = process.env.VUE_APP_API_URL;

// Retry wrapper for API calls
const retry = async (fn, retries = 3, delay = 1000) => {
  let attempt = 0;
  while (attempt < retries) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === retries - 1) throw error;
      attempt++;
      await new Promise(res => setTimeout(res, delay)); // Wait before retrying
    }
  }
};

// Debounce function to delay API calls while typing
const debounce = (fn, delay) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn(...args), delay);
  };
};

// Debounced version of fetchOrganizationByKey with a 500ms delay
const debouncedFetchOrganizationKey = debounce(() => {
  // Only call if there is some key value
  if (organizationKey.value && organizationKey.value.trim() !== '') {
    fetchOrganizationByKey();
  }
}, 500);

// Watch for changes to the organization key:
// Clear error messages and trigger the debounced key check
watch(organizationKey, () => {
  if (organizationError.value) {
    organizationError.value = '';
  }
  debouncedFetchOrganizationKey();
});

// Function to fetch individual organization ID
const fetchIndividualOrganizationId = async () => {
  isFetchingOrganizationId.value = true; // Start loading
  try {
    console.log('Fetching using backend hosted in:', API_BASE_URL);
    const response = await retry(
      () => axios.get(`${API_BASE_URL}/get_individual_organization_id`),
      3,
      1000
    );
    selectedOrganizationId.value = response.data.id;
    organizationError.value = '';
  } catch (error) {
    console.error('Error fetching Individual organization ID:', error);
    organizationError.value =
      'An error occurred while fetching the organization ID. Please try again.';
  } finally {
    isFetchingOrganizationId.value = false; // End loading
  }
};

// Function to check if the organization key exists and fetch the organization details
const fetchOrganizationByKey = async () => {
  if (!organizationKey.value || organizationKey.value.trim() === '') {
    setTimeout(() => {
      organizationError.value = 'Organization key cannot be empty';
    }, 500); // Delay error message
    return;
  }

  try {
    const response = await axios.post(`${API_BASE_URL}/get_organization_by_key`, {
      organization_public_key: organizationKey.value,
    });

    if (response.data.exists) {
      selectedOrganizationId.value = response.data.id;
      organizationError.value = '';
    } else {
      selectedOrganizationId.value = null;
      setTimeout(() => {
        organizationError.value = 'Invalid organization key. Please enter a valid key.';
      }, 500);
    }
  } catch (error) {
    console.error('Error fetching organization by key:', error);
    setTimeout(() => {
      organizationError.value = 'An error occurred while verifying the organization key.';
    }, 500);
  }
};

// Function to validate user details before proceeding
const validateUserDetails = () => {
  if (organizationError.value) {
    alert('Please fix the errors before proceeding.');
    return false;
  }

  if (!selectedOrganizationId.value) {
    alert('Organization details are required. Please fill in all details.');
    return false;
  }

  return true;
};

// Function to proceed to the survey
const proceedToSurvey = async () => {
  if (!validateUserDetails()) return;

  try {
    // Call the backend to create the user. No username is sent; it will be auto-generated.
    const response = await axios.post(`${API_BASE_URL}/new_survey_user`, {});

    if (response.status === 201) {
      // Set default values for tasks
      const tasksResponsibilities = {
        responsible_for: 'Not Applicable',
        supporting: 'Not Applicable',
        designing_and_improving: 'Not Applicable',
      };

      // Use the auto-generated username for both username and fullName in the Pinia store.
      userStore.setUserDetails({
        organizationId: selectedOrganizationId.value,
        fullName: response.data.username, // fullName is set as the generated username
        username: response.data.username,
        tasksResponsibilities: tasksResponsibilities,
      });

      // Navigate to the role selection page
      router.push('/surveyTypeSelection');
    }
  } catch (error) {
    console.error('An error occurred while creating the user:', error);
    alert('An unexpected error occurred. Please try again.');
  }
};

// Handle organization type change
const handleOrganizationTypeChange = () => {
  if (organizationType.value === 'Individual') {
    fetchIndividualOrganizationId();
  } else if (organizationType.value === 'Organization') {
    selectedOrganizationId.value = null;
    organizationKey.value = ''; // Clear the organization key when changing type
  }
};

// Fetch organizations on component mount
onMounted(() => {
  // Fetch individual organization ID if required
});
</script>

<template>
  <v-app>
    <v-container
      fluid
      class="d-flex flex-column justify-center align-center"
      style="height: auto; background-color: #121212;"
    >
      <h1 class="form-heading">Please Fill Your Details</h1>

      <!-- Radio Buttons to select Organization Type -->
      <v-radio-group
        v-model="organizationType"
        label="Are you an Individual or part of an Organization?"
        row
        class="mt-3 mb-3"
        @change="handleOrganizationTypeChange"
      >
        <v-radio label="Individual" value="Individual"></v-radio>
        <v-radio label="Organization" value="Organization"></v-radio>
      </v-radio-group>

      <!-- Input field for Organization Key (only for Organization) -->
      <v-text-field
        v-if="organizationType === 'Organization'"
        v-model="organizationKey"
        label="Enter Organization Key"
        outlined
        dense
        style="width: 400px; margin-bottom: 20px;"
        :error="organizationError !== ''"
      ></v-text-field>
      <p v-if="organizationError" class="error-message">{{ organizationError }}</p>

      <!-- The full name input field is removed -->

      <!-- Proceed button -->
      <v-btn
        @click="proceedToSurvey"
        :loading="isFetchingOrganizationId"
        color="success"
        dark
      >
        Proceed to Survey
      </v-btn>
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

.custom-select,
.v-text-field,
.v-textarea {
  background-color: #2a2a2a;
  color: white;
}

.v-input__control {
  color: white;
}

.error-message {
  color: #e57373; /* Red for error messages */
  font-size: 0.9rem;
  margin-bottom: 10px;
}
</style>
