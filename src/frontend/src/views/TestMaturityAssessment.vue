<template>
  <div class="test-maturity-page">
    <div class="page-header">
      <h1>Phase 1 Task 1: Maturity Assessment - Test Page</h1>
      <p class="subtitle">Test the new maturity assessment implementation</p>
    </div>

    <!-- Show Assessment or Results -->
    <div v-if="!showResults">
      <MaturityAssessment
        :existing-data="existingAnswers"
        @maturity-calculated="handleMaturityCalculated"
        @data-changed="handleDataChanged"
      />
    </div>

    <div v-else>
      <MaturityResults
        :results="calculatedResults"
        @back-to-assessment="resetAssessment"
        @proceed-to-task2="handleProceedToTask2"
      />
    </div>

    <!-- Debug Panel -->
    <el-card v-if="showDebug" class="debug-panel" shadow="never">
      <template #header>
        <div class="debug-header">
          <h3>Debug Information</h3>
          <el-button size="small" @click="showDebug = !showDebug">
            {{ showDebug ? 'Hide' : 'Show' }} Debug
          </el-button>
        </div>
      </template>

      <div class="debug-content">
        <h4>Current Answers:</h4>
        <pre>{{ JSON.stringify(currentAnswers, null, 2) }}</pre>

        <h4>Calculated Results:</h4>
        <pre>{{ JSON.stringify(calculatedResults, null, 2) }}</pre>

        <h4>Saved to Database:</h4>
        <p>{{ savedToDatabase ? 'Yes' : 'No' }}</p>
        <pre v-if="savedData">{{ JSON.stringify(savedData, null, 2) }}</pre>
      </div>
    </el-card>

    <!-- Control Panel -->
    <el-card class="control-panel" shadow="never">
      <div class="controls">
        <el-button @click="loadExistingAssessment">Load Existing Assessment</el-button>
        <el-button @click="saveToDatabase" :disabled="!calculatedResults" :loading="saving">
          Save to Database
        </el-button>
        <el-button @click="showDebug = !showDebug">
          {{ showDebug ? 'Hide' : 'Show' }} Debug
        </el-button>
        <el-button type="danger" @click="clearAll">Clear All</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { ElMessage } from 'element-plus';
import MaturityAssessment from '../components/phase1/task1/MaturityAssessment.vue';
import MaturityResults from '../components/phase1/task1/MaturityResults.vue';
import phase1Api from '../api/phase1.js';
import { useAuthStore } from '../stores/auth';

const authStore = useAuthStore();

// State
const showResults = ref(false);
const showDebug = ref(true);
const currentAnswers = ref(null);
const calculatedResults = ref(null);
const existingAnswers = ref(null);
const savedToDatabase = ref(false);
const savedData = ref(null);
const saving = ref(false);

// Get organization ID from auth store
const orgId = computed(() => authStore.organizationId);

// Handlers
const handleDataChanged = (data) => {
  currentAnswers.value = data;
  console.log('[DEBUG] Answers changed:', data);
};

const handleMaturityCalculated = async ({ answers, results }) => {
  console.log('[DEBUG] Maturity calculated:', { answers, results });
  currentAnswers.value = answers;
  calculatedResults.value = results;
  showResults.value = true;

  // Auto-save to database if org ID is available
  if (orgId.value) {
    try {
      saving.value = true;
      const response = await phase1Api.maturity.save(orgId.value, answers, results);
      savedToDatabase.value = true;
      savedData.value = response.data;
      ElMessage.success('Assessment automatically saved to database');
    } catch (error) {
      console.error('[ERROR] Failed to auto-save:', error);
      ElMessage.warning('Assessment not saved - you can save manually');
    } finally {
      saving.value = false;
    }
  }
};

const resetAssessment = () => {
  showResults.value = false;
};

const handleProceedToTask2 = (results) => {
  console.log('[DEBUG] Proceeding to Task 2 with results:', results);
  ElMessage.info('Task 2 not yet implemented - staying on this page');
};

const loadExistingAssessment = async () => {
  if (!orgId.value) {
    ElMessage.warning('No organization ID available. Please log in first.');
    return;
  }

  try {
    const response = await phase1Api.maturity.get(orgId.value);

    if (response.exists && response.data) {
      existingAnswers.value = response.data.answers;
      calculatedResults.value = response.data.results;
      currentAnswers.value = response.data.answers;
      savedToDatabase.value = true;
      savedData.value = response.data;
      showResults.value = true;
      ElMessage.success('Loaded existing assessment from database');
    } else {
      ElMessage.info('No existing assessment found for this organization');
    }
  } catch (error) {
    console.error('[ERROR] Failed to load assessment:', error);
    ElMessage.error('Failed to load existing assessment');
  }
};

const saveToDatabase = async () => {
  if (!orgId.value) {
    ElMessage.warning('No organization ID available');
    return;
  }

  if (!currentAnswers.value || !calculatedResults.value) {
    ElMessage.warning('No assessment data to save');
    return;
  }

  try {
    saving.value = true;
    const response = await phase1Api.maturity.save(
      orgId.value,
      currentAnswers.value,
      calculatedResults.value
    );

    savedToDatabase.value = true;
    savedData.value = response.data;
    ElMessage.success('Assessment saved successfully!');
  } catch (error) {
    console.error('[ERROR] Failed to save assessment:', error);
    ElMessage.error('Failed to save assessment to database');
  } finally {
    saving.value = false;
  }
};

const clearAll = () => {
  showResults.value = false;
  currentAnswers.value = null;
  calculatedResults.value = null;
  existingAnswers.value = null;
  savedToDatabase.value = false;
  savedData.value = null;
  ElMessage.info('All data cleared');
};
</script>

<style scoped>
.test-maturity-page {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
}

.page-header h1 {
  margin: 0 0 10px 0;
  color: #303133;
  font-size: 32px;
}

.subtitle {
  margin: 0;
  color: #606266;
  font-size: 16px;
}

.debug-panel {
  margin-top: 30px;
  background: #f9fafb;
}

.debug-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.debug-header h3 {
  margin: 0;
}

.debug-content h4 {
  margin: 20px 0 10px 0;
  color: #303133;
}

.debug-content pre {
  background: #282c34;
  color: #abb2bf;
  padding: 15px;
  border-radius: 6px;
  overflow-x: auto;
  font-size: 13px;
  line-height: 1.5;
}

.control-panel {
  margin-top: 20px;
  background: #f0f9ff;
}

.controls {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
  justify-content: center;
}
</style>
