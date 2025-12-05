<template>
  <div class="role-mapping-review">
    <el-alert type="info" :closable="false" class="mb-4">
      <template #title>Review AI Mapping Results</template>
      Review the AI analysis results for {{ mappingResult?.total_roles || 0 }} role(s). Confirm the mappings you want to use, or skip to add roles as custom roles.
    </el-alert>

    <!-- Loading State -->
    <el-skeleton v-if="loading" :rows="5" animated />

    <!-- Mapping Results -->
    <el-collapse v-if="!loading && mappingResult" class="mapping-collapse">
      <el-collapse-item
        v-for="(roleMapping, index) in mappingResult.results"
        :key="index"
        :name="index"
      >
        <template #title>
          <div class="collapse-title">
            <div>
              <el-icon :size="20"><User /></el-icon>
              <strong class="ml-2">{{ roleMapping.role_title }}</strong>
            </div>
            <el-tag
              :type="getFilteredMappings(roleMapping).length > 0 ? 'success' : 'warning'"
              size="small"
            >
              {{ getFilteredMappings(roleMapping).length > 0 ? `${getFilteredMappings(roleMapping).length} cluster mapping(s)` : 'No cluster match' }}
            </el-tag>
          </div>
        </template>

        <div class="collapse-content">
          <!-- Overall Analysis -->
          <el-alert type="info" :closable="false" class="mb-3">
            <strong>AI Analysis:</strong> {{ roleMapping.overall_analysis }}
          </el-alert>

          <!-- Cluster Mappings (filtered to >= 80% confidence) -->
          <div v-if="getFilteredMappings(roleMapping).length > 0" class="mappings-list">
            <el-card
              v-for="(mapping, mIndex) in getFilteredMappings(roleMapping)"
              :key="mIndex"
              :class="[
                'mapping-card mb-3',
                { 'mapping-confirmed': isConfirmed(roleMapping.role_title, mapping) },
                { 'mapping-rejected': isRejected(roleMapping.role_title, mapping) }
              ]"
              shadow="hover"
            >
              <div class="mapping-header">
                <div class="mapping-title">
                  <el-icon :size="18" :color="mapping.is_primary ? '#409EFF' : '#909399'">
                    <StarFilled v-if="mapping.is_primary" />
                    <Star v-else />
                  </el-icon>
                  <strong class="ml-2">{{ mapping.cluster_name }}</strong>
                  <el-tag
                    v-if="isConfirmed(roleMapping.role_title, mapping)"
                    type="success"
                    size="small"
                    class="ml-2"
                  >
                    <el-icon><Check /></el-icon> Confirmed
                  </el-tag>
                  <el-tag
                    v-if="isRejected(roleMapping.role_title, mapping)"
                    type="danger"
                    size="small"
                    class="ml-2"
                  >
                    <el-icon><Close /></el-icon> Rejected
                  </el-tag>
                </div>
                <div class="mapping-actions">
                  <el-button
                    type="success"
                    :icon="Check"
                    circle
                    size="small"
                    :disabled="isConfirmed(roleMapping.role_title, mapping)"
                    @click="confirmMapping(roleMapping.role_title, mapping)"
                  />
                  <el-button
                    type="danger"
                    :icon="Close"
                    circle
                    size="small"
                    :disabled="isRejected(roleMapping.role_title, mapping)"
                    @click="rejectMapping(roleMapping.role_title, mapping)"
                  />
                </div>
              </div>

              <div class="mapping-reasoning mt-2">
                <strong>Reasoning:</strong> {{ mapping.reasoning }}
              </div>

              <!-- Matched Responsibilities -->
              <div v-if="mapping.matched_responsibilities?.length" class="mt-2">
                <el-tag
                  v-for="(resp, rIndex) in mapping.matched_responsibilities"
                  :key="rIndex"
                  size="small"
                  class="mr-1 mb-1"
                  effect="plain"
                >
                  {{ resp }}
                </el-tag>
              </div>
            </el-card>
          </div>

          <!-- No cluster mappings found -->
          <el-empty
            v-else
            description="This role could not be mapped to any SE role cluster. It will be added as a custom role."
            :image-size="100"
          />
        </div>
      </el-collapse-item>
    </el-collapse>

    <!-- Empty State -->
    <el-empty v-if="!loading && !mappingResult" description="No mapping results to review" />

    <!-- Action Buttons -->
    <div class="review-actions mt-4">
      <el-button @click="emit('back')">
        <el-icon class="mr-1"><ArrowLeft /></el-icon>
        Back
      </el-button>
      <el-button
        type="primary"
        @click="finishReview"
      >
        <el-icon class="mr-1"><Select /></el-icon>
        Finish Review ({{ confirmedMappings.size }} confirmed)
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'
import {
  User,
  StarFilled,
  Star,
  Check,
  Close,
  ArrowLeft,
  Select
} from '@element-plus/icons-vue'

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  mappingResult: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['back', 'finish'])

// Reactive state
const loading = ref(false)
const confirmedMappings = ref(new Set())
const rejectedMappings = ref(new Set())

// Auto-select first mapping for each role
const autoSelectFirstMappings = () => {
  if (!props.mappingResult || !props.mappingResult.results) return

  props.mappingResult.results.forEach(roleMapping => {
    const filteredMappings = roleMapping.mappings.filter(m => m.confidence_score >= 80)
    if (filteredMappings.length > 0) {
      const firstMapping = filteredMappings[0]
      const key = `${roleMapping.role_title}:${firstMapping.cluster_name}`
      confirmedMappings.value.add(key)
    }
  })
}

// Watch for mappingResult changes and auto-select
watch(() => props.mappingResult, (newValue) => {
  if (newValue) {
    autoSelectFirstMappings()
  }
}, { immediate: true })

// Also auto-select on mount
onMounted(() => {
  autoSelectFirstMappings()
})

// Computed
const hasConfirmedMappings = computed(() => {
  return confirmedMappings.value.size > 0
})

// Methods
const getPrimaryMapping = (roleMapping) => {
  return roleMapping.mappings.find(m => m.is_primary) || roleMapping.mappings[0]
}

const getConfidenceType = (score) => {
  if (score >= 80) return 'success'
  if (score >= 60) return ''
  if (score >= 40) return 'warning'
  return 'danger'
}

// Filter mappings to only show >= 80% confidence
const getFilteredMappings = (roleMapping) => {
  return roleMapping.mappings.filter(m => m.confidence_score >= 80)
}

// Check if a mapping is confirmed
const isConfirmed = (roleTitle, mapping) => {
  const key = `${roleTitle}:${mapping.cluster_name}`
  return confirmedMappings.value.has(key)
}

// Check if a mapping is rejected
const isRejected = (roleTitle, mapping) => {
  const key = `${roleTitle}:${mapping.cluster_name}`
  return rejectedMappings.value.has(key)
}

const confirmMapping = async (roleTitle, mapping) => {
  try {
    const key = `${roleTitle}:${mapping.cluster_name}`

    if (confirmedMappings.value.has(key)) {
      ElMessage.info('Mapping already confirmed')
      return
    }

    // Radio button behavior: when confirming a mapping for a role,
    // remove any other confirmed mappings for the SAME role
    const keysToRemove = []
    confirmedMappings.value.forEach(existingKey => {
      // Check if this confirmed mapping belongs to the same role
      if (existingKey.startsWith(`${roleTitle}:`)) {
        keysToRemove.push(existingKey)
      }
    })

    // Remove all other confirmed mappings for this role
    keysToRemove.forEach(k => confirmedMappings.value.delete(k))

    // Add the new mapping
    confirmedMappings.value.add(key)
    rejectedMappings.value.delete(key)

    ElMessage.success(`Confirmed: ${roleTitle} → ${mapping.cluster_name}`)
  } catch (error) {
    console.error('Error confirming mapping:', error)
    ElMessage.error('Error confirming mapping: ' + (error.response?.data?.error || error.message))
  }
}

const rejectMapping = async (roleTitle, mapping) => {
  try {
    const key = `${roleTitle}:${mapping.cluster_name}`

    if (rejectedMappings.value.has(key)) {
      ElMessage.info('Mapping already rejected')
      return
    }

    rejectedMappings.value.add(key)
    confirmedMappings.value.delete(key)

    ElMessage.warning(`Rejected: ${roleTitle} → ${mapping.cluster_name}`)
  } catch (error) {
    console.error('Error rejecting mapping:', error)
    ElMessage.error('Error rejecting mapping: ' + (error.response?.data?.error || error.message))
  }
}

const finishReview = () => {
  emit('finish', {
    confirmed: Array.from(confirmedMappings.value),
    rejected: Array.from(rejectedMappings.value)
  })
}
</script>

<style scoped>
.role-mapping-review {
  padding: 8px;
}

.collapse-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding-right: 12px;
}

.mapping-card {
  background: #fafafa;
  transition: all 0.3s ease;
}

.mapping-card.mapping-confirmed {
  background: #f0f9ff;
  border-left: 4px solid #67C23A;
}

.mapping-card.mapping-rejected {
  background: #fef0f0;
  border-left: 4px solid #F56C6C;
  opacity: 0.7;
}

.mapping-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.mapping-title {
  display: flex;
  align-items: center;
  flex: 1;
}

.mapping-actions {
  display: flex;
  gap: 8px;
}

.mapping-reasoning {
  color: #606266;
  line-height: 1.6;
}

.review-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

.ml-1 {
  margin-left: 4px;
}

.ml-2 {
  margin-left: 8px;
}

.mr-1 {
  margin-right: 4px;
}

.mb-1 {
  margin-bottom: 4px;
}

.mb-3 {
  margin-bottom: 12px;
}

.mb-4 {
  margin-bottom: 16px;
}

.mt-2 {
  margin-top: 8px;
}

.mt-4 {
  margin-top: 16px;
}
</style>
