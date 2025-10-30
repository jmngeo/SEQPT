<template>
  <el-card class="target-group-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Training Target Group Size</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          How large is the target group for the SE training project?
          This helps determine appropriate training formats and resource allocation.
        </p>
      </div>
    </template>

    <!-- Target group size options as clickable cards -->
    <div class="target-size-options">
      <el-card
        v-for="size in TARGET_GROUP_SIZES"
        :key="size.id"
        :class="['size-option-card', { 'selected': selectedSize === size.id }]"
        shadow="hover"
        @click="selectSize(size.id)"
      >
        <!-- Radio button and label inline -->
        <div class="size-option-inline">
          <el-radio :model-value="selectedSize" :value="size.id" @click.stop />
          <span class="size-label">{{ size.label }}</span>
        </div>
      </el-card>
    </div>

    <!-- Validation message -->
    <el-alert
      v-if="showValidation && !selectedSize"
      type="error"
      :closable="false"
      show-icon
      style="margin-top: 20px;"
    >
      Please select a target group size to continue.
    </el-alert>

    <!-- Actions -->
    <div class="step-actions" style="margin-top: 32px;">
      <el-button @click="handleBack">
        Back
      </el-button>
      <el-button
        type="primary"
        :disabled="!selectedSize"
        :loading="saving"
        @click="handleContinue"
      >
        Continue to Role Selection
      </el-button>
    </div>
  </el-card>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { TARGET_GROUP_SIZES } from '@/data/seRoleClusters'
import { targetGroupApi } from '@/api/phase1'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  rolesCount: {
    type: Number,
    required: true
  },
  maturityId: {
    type: Number,
    required: true
  },
  existingTargetGroup: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()
const selectedSize = ref(null)
const showValidation = ref(false)
const saving = ref(false)

const selectSize = (sizeId) => {
  selectedSize.value = sizeId
  showValidation.value = false
}

const handleBack = () => {
  emit('back')
}

const handleContinue = async () => {
  if (!selectedSize.value) {
    showValidation.value = true
    return
  }

  saving.value = true
  try {
    // Get selected size data
    const sizeData = TARGET_GROUP_SIZES.find(s => s.id === selectedSize.value)

    // Save to database
    const response = await targetGroupApi.save(
      authStore.organizationId,
      props.maturityId,
      sizeData
    )

    console.log('[TargetGroupSize] Saved:', response)

    // Emit completion with size data
    emit('complete', {
      sizeData,
      targetGroupId: response.id
    })
  } catch (error) {
    console.error('[TargetGroupSize] Save failed:', error)
    alert('Failed to save target group size. Please try again.')
  } finally {
    saving.value = false
  }
}

// Load existing target group if provided
onMounted(() => {
  if (props.existingTargetGroup) {
    console.log('[TargetGroupSize] Loading existing target group:', props.existingTargetGroup)

    // Extract size_range from various possible structures
    let sizeRange = null
    if (props.existingTargetGroup.size_range) {
      sizeRange = props.existingTargetGroup.size_range
    } else if (props.existingTargetGroup.sizeData && props.existingTargetGroup.sizeData.range) {
      sizeRange = props.existingTargetGroup.sizeData.range
    }

    if (sizeRange) {
      // Find matching size option based on size_range
      const matchingSize = TARGET_GROUP_SIZES.find(
        size => size.range === sizeRange
      )

      if (matchingSize) {
        selectedSize.value = matchingSize.id
        console.log('[TargetGroupSize] Pre-filled size:', matchingSize.label)
      } else {
        console.warn('[TargetGroupSize] Could not find matching size for range:', sizeRange)
      }
    } else {
      console.warn('[TargetGroupSize] No size_range found in existingTargetGroup')
    }
  }
})
</script>

<style scoped>
.target-group-container {
  max-width: 900px;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.target-size-options {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.size-option-card {
  position: relative;
  cursor: pointer;
  transition: all 0.2s ease;
  border: 1px solid #e4e7ed;
  padding: 0;
}

.size-option-card:hover {
  border-color: #409eff;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.12);
  transform: translateY(-1px);
}

.size-option-card.selected {
  border-color: #409eff;
  background: linear-gradient(to right, #f0f7ff 0%, #ffffff 100%);
  box-shadow: 0 2px 12px rgba(64, 158, 255, 0.15);
}

.size-option-card :deep(.el-card__body) {
  padding: 14px 20px;
}

.size-option-inline {
  display: flex;
  align-items: center;
  gap: 12px;
}

.size-option-inline :deep(.el-radio) {
  margin: 0;
}

.size-option-inline :deep(.el-radio__label) {
  display: none;
}

.size-label {
  font-size: 15px;
  font-weight: 500;
  color: #303133;
  cursor: pointer;
  user-select: none;
}

.step-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

/* Responsive */
@media (max-width: 768px) {
  .target-group-container {
    margin: 0;
  }

  .size-option-card :deep(.el-card__body) {
    padding: 12px 16px;
  }

  .size-label {
    font-size: 14px;
  }

  .step-actions {
    flex-direction: column;
    gap: 12px;
  }

  .step-actions .el-button {
    width: 100%;
  }
}
</style>
