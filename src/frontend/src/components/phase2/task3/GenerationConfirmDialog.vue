<template>
  <el-dialog
    v-model="visible"
    title="Generate Learning Objectives"
    width="480px"
    :close-on-click-modal="false"
  >
    <div class="confirmation-content">
      <div class="confirmation-icon">
        <el-icon :size="48" color="#409EFF"><MagicStick /></el-icon>
      </div>

      <p class="confirmation-message">
        Are you ready to generate learning objectives based on the completed competency assessments and selected training strategies?
      </p>

      <el-alert
        v-if="needsPMT && !hasPMT"
        type="error"
        :closable="false"
        show-icon
      >
        <template #title>PMT Context Required</template>
        <p>
          Please fill in the Company Context (PMT) form before generating objectives.
        </p>
      </el-alert>

      <p class="note">
        This process may take a few moments. You can regenerate objectives later if needed.
      </p>
    </div>

    <template #footer>
      <el-button @click="handleCancel">Cancel</el-button>
      <el-button
        type="primary"
        @click="handleConfirm"
        :disabled="needsPMT && !hasPMT"
      >
        <el-icon><MagicStick /></el-icon>
        Generate Objectives
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'
import { MagicStick } from '@element-plus/icons-vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  assessmentStats: {
    type: Object,
    default: null
  },
  strategiesCount: {
    type: Number,
    default: 0
  },
  needsPMT: {
    type: Boolean,
    default: false
  },
  hasPMT: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

// Computed
const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

// Methods
const handleConfirm = () => {
  emit('confirm')
}

const handleCancel = () => {
  visible.value = false
  emit('cancel')
}
</script>

<style scoped>
.confirmation-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  text-align: center;
  padding: 8px 0;
}

.confirmation-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 80px;
  height: 80px;
  background: #ecf5ff;
  border-radius: 50%;
}

.confirmation-message {
  font-size: 15px;
  color: var(--el-text-color-primary);
  line-height: 1.6;
  margin: 0;
}

.note {
  color: var(--el-text-color-secondary);
  font-size: 13px;
  line-height: 1.5;
  margin: 0;
}

.el-alert {
  width: 100%;
  text-align: left;
}
</style>
