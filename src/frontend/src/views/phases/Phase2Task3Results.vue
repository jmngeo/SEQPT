<template>
  <div class="phase2-task3-results-page">
    <!-- Page Header -->
    <el-page-header @back="handleBack">
      <template #content>
        <div class="header-content">
          <h1>Learning Objectives Results</h1>
          <p class="subtitle">Organization #{{ organizationId }}</p>
        </div>
      </template>
      <template #extra>
        <!-- Pathway tag removed as per user request -->
      </template>
    </el-page-header>

    <!-- Loading State -->
    <el-card v-if="isLoading" class="loading-card">
      <div style="text-align: center; padding: 40px;">
        <el-icon class="is-loading" :size="40"><Loading /></el-icon>
        <p style="margin-top: 16px;">Loading learning objectives...</p>
      </div>
    </el-card>

    <!-- Error State -->
    <el-card v-else-if="error" class="error-card">
      <el-alert
        title="Failed to Load Learning Objectives"
        :description="error"
        type="error"
        show-icon
        :closable="false"
      />
      <div class="actions" style="margin-top: 24px; text-align: center;">
        <el-button type="primary" @click="handleBack">
          Back to Dashboard
        </el-button>
      </div>
    </el-card>

    <!-- Results View -->
    <LearningObjectivesView
      v-else-if="objectives"
      :objectives="objectives"
      :organization-id="organizationId"
    />

    <!-- No Results State -->
    <el-card v-else class="no-results-card">
      <el-empty description="No learning objectives found">
        <el-button type="primary" @click="handleBack">
          Go to Dashboard
        </el-button>
      </el-empty>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Loading } from '@element-plus/icons-vue'
import { phase2Task3Api } from '@/api/phase2'
import LearningObjectivesView from '@/components/phase2/task3/LearningObjectivesView.vue'

const router = useRouter()
const route = useRoute()

// State
const isLoading = ref(false)
const error = ref(null)
const objectives = ref(null)

// Get organizationId from route params
const organizationId = computed(() => {
  return parseInt(route.params.orgId) || parseInt(route.query.orgId) || null
})

const pathwayTagType = computed(() => {
  return objectives.value?.pathway === 'TASK_BASED' ? 'warning' : 'success'
})

// Methods
const fetchLearningObjectives = async () => {
  if (!organizationId.value) {
    error.value = 'Organization ID is missing'
    return
  }

  isLoading.value = true
  error.value = null

  try {
    console.log('[Phase2Task3Results] Fetching objectives for org:', organizationId.value)

    // Use API wrapper with extended timeout for LLM processing
    const responseData = await phase2Task3Api.getObjectives(organizationId.value)

    // Handle NEW API structure from learning_objectives_core.py
    // New format: { success: true, data: { main_pyramid: {...} }, metadata: {...} }
    if (responseData?.success === true && responseData?.data?.main_pyramid) {
      console.log('[Phase2Task3Results] Using NEW API structure (main_pyramid)')
      objectives.value = responseData
      console.log('[Phase2Task3Results] Objectives loaded successfully')
      return
    }

    // Handle OLD API structure (backward compatibility)
    // Old format: { pathway: '...', learning_objectives_by_strategy: {...} }
    const isDualTrack = responseData && (
      responseData.pathway === 'ROLE_BASED_DUAL_TRACK' ||
      responseData.pathway === 'TASK_BASED_DUAL_TRACK' ||
      (responseData.gap_based_training && responseData.expert_development)
    )

    if (responseData && (responseData.learning_objectives_by_strategy || isDualTrack)) {
      console.log('[Phase2Task3Results] Using OLD API structure (learning_objectives_by_strategy)')
      objectives.value = responseData
      console.log('[Phase2Task3Results] Objectives loaded successfully')
    } else if (responseData.success === false) {
      // Handle error response
      error.value = responseData.message || responseData.error || 'Failed to load learning objectives'
    } else {
      error.value = 'No learning objectives data received from server'
    }
  } catch (err) {
    console.error('[Phase2Task3Results] Error fetching objectives:', err)

    // Check if it's an error response with message
    if (err.response?.data?.error || err.response?.data?.message) {
      error.value = err.response.data.error || err.response.data.message
    } else {
      error.value = err.message || 'Failed to load learning objectives'
    }

    ElMessage.error('Failed to load learning objectives')
  } finally {
    isLoading.value = false
  }
}

const handleBack = () => {
  // Navigate back to the Phase 2 Task 3 dashboard
  router.push(`/app/phases/2/admin/learning-objectives?orgId=${organizationId.value}`)
}

// Lifecycle
onMounted(async () => {
  console.log('[Phase2Task3Results] Mounted with organizationId:', organizationId.value)
  await fetchLearningObjectives()
})
</script>

<style scoped>
.phase2-task3-results-page {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
  min-height: 100vh;
  background: var(--el-bg-color-page);
}

.header-content h1 {
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 4px 0;
}

.subtitle {
  color: var(--el-text-color-secondary);
  margin: 0;
  font-size: 14px;
}

.loading-card,
.error-card,
.no-results-card {
  margin-top: 24px;
}

/* Spacing between page header and content */
:deep(.el-page-header) {
  margin-bottom: 24px;
}
</style>
