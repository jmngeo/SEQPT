<template>
  <el-dialog
    v-model="visible"
    :title="`Add Recommended Strategy: ${strategyName}`"
    width="700px"
    :close-on-click-modal="false"
  >
    <div class="add-strategy-content">
      <!-- Rationale -->
      <el-alert
        type="info"
        :closable="false"
        show-icon
      >
        <template #title>
          Why is this strategy recommended?
        </template>
        <p v-if="rationale">
          {{ rationale }}
        </p>
        <p v-else>
          The validation analysis identified gaps in competency coverage that this strategy would address.
          Adding this strategy will help ensure comprehensive training coverage for your organization.
        </p>
      </el-alert>

      <!-- Gap Summary (if provided) -->
      <div v-if="gapSummary" class="gap-summary">
        <h4>Coverage Gaps</h4>
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item
            v-if="gapSummary.competenciesAffected"
            label="Competencies Affected"
          >
            {{ gapSummary.competenciesAffected }}
          </el-descriptions-item>
          <el-descriptions-item
            v-if="gapSummary.usersAffected"
            label="Users Affected"
          >
            {{ gapSummary.usersAffected }}
          </el-descriptions-item>
          <el-descriptions-item
            v-if="gapSummary.gapPercentage !== undefined"
            label="Gap Percentage"
          >
            {{ gapSummary.gapPercentage }}%
          </el-descriptions-item>
        </el-descriptions>
      </div>

      <!-- PMT Context Form (Conditional) -->
      <div v-if="requiresPMT" class="pmt-section">
        <el-divider />

        <el-alert
          type="warning"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        >
          <template #title>PMT Context Required</template>
          <p>
            This strategy requires PMT (Processes, Methods, Tools) context for deep customization.
            Please provide your company's PMT information below.
          </p>
        </el-alert>

        <el-form
          ref="pmtFormRef"
          :model="pmtFormData"
          :rules="pmtRules"
          label-position="top"
        >
          <el-form-item label="Processes" prop="processes">
            <el-input
              v-model="pmtFormData.processes"
              type="textarea"
              :rows="2"
              placeholder="e.g., ISO 26262, V-model, Agile development process"
            />
            <span class="help-text">
              SE processes used in your organization
            </span>
          </el-form-item>

          <el-form-item label="Methods" prop="methods">
            <el-input
              v-model="pmtFormData.methods"
              type="textarea"
              :rows="2"
              placeholder="e.g., Scrum, requirements traceability, trade-off analysis"
            />
            <span class="help-text">
              Methods and techniques employed
            </span>
          </el-form-item>

          <el-form-item label="Tools" prop="tools" required>
            <el-input
              v-model="pmtFormData.tools"
              type="textarea"
              :rows="2"
              placeholder="e.g., DOORS, JIRA, Enterprise Architect"
            />
            <span class="help-text">
              Tool landscape and software used
            </span>
          </el-form-item>

          <el-form-item label="Industry Context" prop="industry">
            <el-input
              v-model="pmtFormData.industry"
              placeholder="e.g., Automotive embedded systems, Medical devices"
            />
            <span class="help-text">
              Your industry domain or sector
            </span>
          </el-form-item>

          <el-form-item label="Additional Context" prop="additionalContext">
            <el-input
              v-model="pmtFormData.additionalContext"
              type="textarea"
              :rows="2"
              placeholder="Any other relevant company-specific information"
            />
          </el-form-item>
        </el-form>
      </div>

      <!-- Info Note -->
      <p class="note">
        Adding this strategy will regenerate your learning objectives to include
        coverage from this additional training approach.
      </p>
    </div>

    <template #footer>
      <el-button @click="handleCancel" :disabled="isAdding">
        Cancel
      </el-button>
      <el-button
        type="primary"
        @click="handleAddStrategy"
        :loading="isAdding"
      >
        Add Strategy and Regenerate
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  strategyName: {
    type: String,
    required: true
  },
  organizationId: {
    type: Number,
    required: true
  },
  rationale: {
    type: String,
    default: ''
  },
  gapSummary: {
    type: Object,
    default: null
  },
  existingPMTContext: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update:modelValue', 'added', 'cancelled'])

// Refs
const pmtFormRef = ref(null)
const isAdding = ref(false)

// PMT Form Data
const pmtFormData = ref({
  processes: '',
  methods: '',
  tools: '',
  industry: '',
  additionalContext: ''
})

// Computed
const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const requiresPMT = computed(() => {
  const deepCustomizationStrategies = [
    'Needs-based project-oriented training',
    'Continuous support'
  ]
  return deepCustomizationStrategies.includes(props.strategyName)
})

// PMT Validation Rules
const pmtRules = {
  tools: [
    {
      validator: (rule, value, callback) => {
        if (!value && !pmtFormData.value.processes) {
          callback(new Error('At least one of Processes or Tools must be filled'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ],
  processes: [
    {
      validator: (rule, value, callback) => {
        if (!value && !pmtFormData.value.tools) {
          callback(new Error('At least one of Processes or Tools must be filled'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

// Methods
const loadExistingPMT = () => {
  if (props.existingPMTContext) {
    pmtFormData.value = {
      processes: props.existingPMTContext.processes || '',
      methods: props.existingPMTContext.methods || '',
      tools: props.existingPMTContext.tools || '',
      industry: props.existingPMTContext.industry || '',
      additionalContext: props.existingPMTContext.additionalContext || ''
    }
    console.log('[AddStrategyDialog] Loaded existing PMT context')
  }
}

const handleAddStrategy = async () => {
  try {
    // Validate PMT form if required
    if (requiresPMT.value && pmtFormRef.value) {
      await pmtFormRef.value.validate()
    }

    isAdding.value = true

    // Prepare data to emit
    const strategyData = {
      strategyName: props.strategyName,
      pmtContext: requiresPMT.value ? pmtFormData.value : null
    }

    console.log('[AddStrategyDialog] Adding strategy:', strategyData)

    // Emit to parent component which will call the composable's addRecommendedStrategy method
    emit('added', strategyData)

    // Note: The parent component will handle the actual API call and close the dialog
    // We don't close here to allow parent to handle success/error states
  } catch (error) {
    if (error?.errors) {
      ElMessage.error('Please fill in required PMT fields')
    } else {
      console.error('[AddStrategyDialog] Validation error:', error)
      ElMessage.error('Please fill in required fields')
    }
    isAdding.value = false
  }
}

const handleCancel = () => {
  visible.value = false
  emit('cancelled')
  // Reset form
  resetForm()
}

const resetForm = () => {
  if (pmtFormRef.value) {
    pmtFormRef.value.resetFields()
  }
  pmtFormData.value = {
    processes: '',
    methods: '',
    tools: '',
    industry: '',
    additionalContext: ''
  }
  isAdding.value = false
}

// Watch for dialog visibility to reset form when opened
watch(visible, (newVal) => {
  if (newVal) {
    loadExistingPMT()
  } else {
    // Reset loading state when dialog closes
    isAdding.value = false
  }
})

// Watch for existing PMT context changes
watch(() => props.existingPMTContext, () => {
  if (visible.value) {
    loadExistingPMT()
  }
}, { deep: true })
</script>

<style scoped>
.add-strategy-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.gap-summary h4 {
  margin-bottom: 12px;
  font-size: 15px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.pmt-section {
  margin-top: 8px;
}

.help-text {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  display: block;
  margin-top: 4px;
}

.note {
  color: var(--el-text-color-secondary);
  font-size: 13px;
  line-height: 1.6;
  margin: 0;
  padding: 12px;
  background-color: var(--el-fill-color-light);
  border-radius: 4px;
}
</style>
