<template>
  <div class="maturity-assessment">
    <div class="assessment-header">
      <h3>Systems Engineering Maturity Assessment</h3>
      <p>Answer the following 4 questions to assess your organization's SE maturity level.</p>

      <div class="progress-info">
        <el-progress
          :percentage="progressPercentage"
          :color="progressColor"
          :stroke-width="8"
        />
        <span class="progress-text">
          {{ answeredQuestions }} / {{ totalQuestions }} completed
        </span>
      </div>
    </div>

    <div class="assessment-content">
      <!-- Question 1: Rollout Scope -->
      <div class="indicator-item">
        <div class="indicator-question">
          <h5>{{ questions[0].question }}</h5>
          <p class="rating-instruction">{{ questions[0].description }}</p>
        </div>

        <div class="rating-scale">
          <el-radio-group
            v-model="formData.rolloutScope"
            @change="onAnswerChange"
            size="large"
          >
            <el-radio-button
              v-for="option in questions[0].options"
              :key="option.value"
              :value="option.value"
              :label="option.value"
            >
              <div class="rating-option">
                <span class="rating-number">{{ option.value }}</span>
                <span class="rating-label">{{ option.label }}</span>
              </div>
            </el-radio-button>
          </el-radio-group>
        </div>

        <div class="rating-descriptions">
          <div
            v-for="option in questions[0].options"
            :key="`desc_${option.value}`"
            class="rating-description"
          >
            <strong>{{ option.label }}:</strong> {{ option.description }}
          </div>
        </div>
      </div>

      <!-- Question 2: SE Processes & Roles -->
      <div class="indicator-item">
        <div class="indicator-question">
          <h5>{{ questions[1].question }}</h5>
          <p class="rating-instruction">{{ questions[1].description }}</p>
        </div>

        <div class="rating-scale">
          <el-radio-group
            v-model="formData.seRolesProcesses"
            @change="onAnswerChange"
            size="large"
          >
            <el-radio-button
              v-for="option in questions[1].options"
              :key="option.value"
              :value="option.value"
              :label="option.value"
            >
              <div class="rating-option">
                <span class="rating-number">{{ option.value }}</span>
                <span class="rating-label">{{ option.label }}</span>
              </div>
            </el-radio-button>
          </el-radio-group>
        </div>

        <div class="rating-descriptions">
          <div
            v-for="option in questions[1].options"
            :key="`desc_${option.value}`"
            class="rating-description"
          >
            <strong>{{ option.label }}:</strong> {{ option.description }}
          </div>
        </div>
      </div>

      <!-- Question 3: SE Mindset -->
      <div class="indicator-item">
        <div class="indicator-question">
          <h5>{{ questions[2].question }}</h5>
          <p class="rating-instruction">{{ questions[2].description }}</p>
        </div>

        <div class="rating-scale">
          <el-radio-group
            v-model="formData.seMindset"
            @change="onAnswerChange"
            size="large"
          >
            <el-radio-button
              v-for="option in questions[2].options"
              :key="option.value"
              :value="option.value"
              :label="option.value"
            >
              <div class="rating-option">
                <span class="rating-number">{{ option.value }}</span>
                <span class="rating-label">{{ option.label }}</span>
              </div>
            </el-radio-button>
          </el-radio-group>
        </div>

        <div class="rating-descriptions">
          <div
            v-for="option in questions[2].options"
            :key="`desc_${option.value}`"
            class="rating-description"
          >
            <strong>{{ option.label }}:</strong> {{ option.description }}
          </div>
        </div>
      </div>

      <!-- Question 4: Knowledge Base -->
      <div class="indicator-item">
        <div class="indicator-question">
          <h5>{{ questions[3].question }}</h5>
          <p class="rating-instruction">{{ questions[3].description }}</p>
        </div>

        <div class="rating-scale">
          <el-radio-group
            v-model="formData.knowledgeBase"
            @change="onAnswerChange"
            size="large"
          >
            <el-radio-button
              v-for="option in questions[3].options"
              :key="option.value"
              :value="option.value"
              :label="option.value"
            >
              <div class="rating-option">
                <span class="rating-number">{{ option.value }}</span>
                <span class="rating-label">{{ option.label }}</span>
              </div>
            </el-radio-button>
          </el-radio-group>
        </div>

        <div class="rating-descriptions">
          <div
            v-for="option in questions[3].options"
            :key="`desc_${option.value}`"
            class="rating-description"
          >
            <strong>{{ option.label }}:</strong> {{ option.description }}
          </div>
        </div>
      </div>
    </div>

    <div class="assessment-actions">
      <el-button @click="resetForm" size="large">
        Reset
      </el-button>

      <el-button
        type="primary"
        @click="calculateMaturity"
        :disabled="!allQuestionsAnswered"
        :loading="calculating"
        size="large"
      >
        {{ calculating ? 'Calculating...' : 'Calculate Maturity' }}
      </el-button>
    </div>

    <!-- Validation Message -->
    <el-alert
      v-if="showValidationError"
      title="Please answer all 4 questions before calculating maturity"
      type="warning"
      :closable="false"
      show-icon
      style="margin-top: 20px;"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { ElMessage } from 'element-plus';
import { ImprovedMaturityCalculator } from './MaturityCalculator.js';

// Props
const props = defineProps({
  existingData: {
    type: Object,
    default: null
  }
});

// Emits
const emit = defineEmits(['maturity-calculated', 'data-changed']);

// Form data
const formData = ref({
  rolloutScope: null,
  seRolesProcesses: null,
  seMindset: null,
  knowledgeBase: null
});

// State
const calculating = ref(false);
const showValidationError = ref(false);

// Questions data - Exact labels from seqpt_maturity_complete_reference.json
const questions = [
  {
    field: 'rolloutScope',
    question: 'What is the current scope of Systems Engineering deployment in your organization?',
    description: 'This question evaluates the breadth of SE implementation across your organizational structure, from individual teams to the entire value chain including external partners.',
    options: [
      { value: 0, label: 'Not Available', description: 'SE practices are not currently implemented or used anywhere in the organization. No formal SE methods, processes, or tools are in place.' },
      { value: 1, label: 'Individual Area', description: 'Isolated pockets of SE usage exist in specific departments or teams. Implementation is sporadic and inconsistent, with individual areas adopting SE approaches based on local initiatives rather than organizational strategy.' },
      { value: 2, label: 'Development Area', description: 'SE is consistently applied throughout the engineering/development departments. While technical teams have adopted SE practices, other organizational areas have not yet integrated these approaches.' },
      { value: 3, label: 'Company Wide', description: 'SE has been successfully rolled out across all departments and functions within the organization. All relevant stakeholders understand and apply SE principles in their respective roles.' },
      { value: 4, label: 'Value Chain', description: 'SE implementation extends beyond organizational boundaries to include suppliers, partners, and customers. The entire value chain operates with integrated SE practices.' }
    ]
  },
  {
    field: 'seRolesProcesses',
    question: 'How mature are your Systems Engineering processes and associated role definitions?',
    description: 'This question assesses the formalization and optimization of SE processes and roles, ranging from ad-hoc practices to continuously optimized, quantitatively managed processes.',
    options: [
      { value: 0, label: 'Not Available', description: 'SE processes are not executed in the organization. No defined SE roles exist, and system development lacks structured approaches.' },
      { value: 1, label: 'Ad hoc / Undefined', description: 'Necessary SE tasks are performed informally without standardized processes. Success depends on individual expertise rather than organizational capability.' },
      { value: 2, label: 'Individually Controlled', description: 'Specific goals for work products and performance metrics are established, but there\'s no overarching, integrated process framework.' },
      { value: 3, label: 'Defined and Established', description: 'SE processes are formally defined, documented, and established throughout the company. Standard processes exist with clear role definitions.' },
      { value: 4, label: 'Quantitatively Predictable', description: 'SE processes are measured and controlled using quantitative parameters and metrics. Performance is predictable and variations are managed.' },
      { value: 5, label: 'Optimized', description: 'SE processes are continuously improved based on quantitative feedback and innovative practices. The organization proactively enhances processes.' }
    ]
  },
  {
    field: 'seMindset',
    question: 'How well is the Systems Engineering mindset embedded in your organizational culture?',
    description: 'This question evaluates the extent to which SE-typical ways of thinking (systemic thinking, interdisciplinary collaboration, holistic problem-solving) are internalized across your organization.',
    options: [
      { value: 0, label: 'Not Available', description: 'No evidence of systemic or interdisciplinary thinking. Teams work in silos without considering system-level implications.' },
      { value: 1, label: 'Individual / Ad hoc', description: 'SE mindset exists only in isolated individuals who champion these approaches. Not a shared organizational capability.' },
      { value: 2, label: 'Fragmented', description: 'Certain departments have successfully adopted SE thinking patterns, but implementation is inconsistent across the organization.' },
      { value: 3, label: 'Established', description: 'The fundamental SE mindset is internalized throughout the entire organization. All employees understand and apply systems thinking.' },
      { value: 4, label: 'Optimized', description: 'SE mindset is continuously promoted and refined. The organization actively invests in developing systems thinking capabilities.' }
    ]
  },
  {
    field: 'knowledgeBase',
    question: 'What is the state of your organization\'s SE-specific knowledge management system?',
    description: 'This question assesses the existence, accessibility, quality, and continuous improvement of your SE knowledge base, including documentation, best practices, and lessons learned.',
    options: [
      { value: 0, label: 'Not Available', description: 'No formal knowledge base for SE-specific expertise exists. Information is not systematically captured or shared.' },
      { value: 1, label: 'Individual / Ad hoc', description: 'Knowledge exists in individual experts\' minds and personal documentation. Information sharing is informal and reactive.' },
      { value: 2, label: 'Fragmented', description: 'Specialized SE content is documented within specific departments. Knowledge silos exist with limited cross-functional sharing.' },
      { value: 3, label: 'Established', description: 'A centralized, company-wide knowledge base for SE has been implemented. Content quality is assured and actively maintained.' },
      { value: 4, label: 'Optimized', description: 'The knowledge base is continuously enhanced through systematic capture, curation, and improvement processes with advanced features.' }
    ]
  }
];

// Computed
const totalQuestions = computed(() => 4);

const answeredQuestions = computed(() => {
  let count = 0;
  if (formData.value.rolloutScope !== null) count++;
  if (formData.value.seRolesProcesses !== null) count++;
  if (formData.value.seMindset !== null) count++;
  if (formData.value.knowledgeBase !== null) count++;
  return count;
});

const progressPercentage = computed(() => {
  return Math.round((answeredQuestions.value / totalQuestions.value) * 100);
});

const progressColor = computed(() => {
  const percentage = progressPercentage.value;
  if (percentage < 25) return '#f56c6c';
  if (percentage < 50) return '#e6a23c';
  if (percentage < 75) return '#409eff';
  return '#67c23a';
});

const allQuestionsAnswered = computed(() => {
  return formData.value.rolloutScope !== null &&
         formData.value.seRolesProcesses !== null &&
         formData.value.seMindset !== null &&
         formData.value.knowledgeBase !== null;
});

// Methods
const onAnswerChange = () => {
  showValidationError.value = false;
  emit('data-changed', formData.value);
};

const calculateMaturity = () => {
  if (!allQuestionsAnswered.value) {
    showValidationError.value = true;
    ElMessage.warning('Please answer all 4 questions before calculating');
    return;
  }

  calculating.value = true;

  try {
    // Use static method
    const results = ImprovedMaturityCalculator.calculate(formData.value);

    console.log('[MaturityAssessment] Calculated results:', results);

    emit('maturity-calculated', {
      answers: formData.value,
      results: results
    });

    ElMessage.success('Maturity assessment completed!');
  } catch (error) {
    console.error('[MaturityAssessment] Calculation error:', error);
    ElMessage.error('Failed to calculate maturity. Please try again.');
  } finally {
    calculating.value = false;
  }
};

const resetForm = () => {
  formData.value = {
    rolloutScope: null,
    seRolesProcesses: null,
    seMindset: null,
    knowledgeBase: null
  };
  showValidationError.value = false;
  emit('data-changed', formData.value);
};

// Watch for existing data
watch(() => props.existingData, (newData) => {
  if (newData) {
    formData.value = { ...newData };
  }
}, { immediate: true });

// Initialize
onMounted(() => {
  if (props.existingData) {
    formData.value = { ...props.existingData };
  }
});
</script>

<style scoped>
.maturity-assessment {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.assessment-header {
  margin-bottom: 30px;
}

.assessment-header h3 {
  margin: 0 0 10px 0;
  color: #303133;
  font-size: 24px;
  font-weight: 600;
}

.assessment-header p {
  margin: 0 0 20px 0;
  color: #606266;
  font-size: 14px;
}

.progress-info {
  margin-bottom: 10px;
}

.progress-text {
  display: block;
  margin-top: 8px;
  color: #606266;
  font-size: 14px;
  text-align: center;
}

.assessment-content {
  margin-bottom: 30px;
}

/* Indicator/Question Item - matches CompetencyAssessment */
.indicator-item {
  margin-bottom: 40px;
  padding: 24px;
  background: #f9fafb;
  border-radius: 12px;
  border: 1px solid #e4e7ed;
}

.indicator-question h5 {
  margin: 0 0 12px 0;
  color: #303133;
  font-size: 18px;
  font-weight: 600;
  line-height: 1.5;
}

.rating-instruction {
  margin: 0 0 20px 0;
  color: #606266;
  font-size: 14px;
  line-height: 1.6;
}

/* Rating Scale - Enhanced styling */
.rating-scale {
  margin-bottom: 20px;
}

.rating-scale :deep(.el-radio-group) {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.rating-scale :deep(.el-radio-button) {
  flex: 0 0 auto;
}

.rating-scale :deep(.el-radio-button__inner) {
  padding: 14px 20px;
  border-radius: 8px;
  min-width: 110px;
  border: 2px solid #dcdfe6;
  background: white;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.rating-scale :deep(.el-radio-button__inner):hover {
  border-color: #409eff;
  background: #ecf5ff;
  box-shadow: 0 4px 8px rgba(64, 158, 255, 0.15);
  transform: translateY(-1px);
}

.rating-scale :deep(.el-radio-button__original-radio:checked + .el-radio-button__inner) {
  background: linear-gradient(135deg, #409eff 0%, #66b1ff 100%);
  border-color: #409eff;
  color: white;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
}

.rating-scale :deep(.el-radio-button__original-radio:checked + .el-radio-button__inner):hover {
  background: linear-gradient(135deg, #3a8ee6 0%, #5ca3ff 100%);
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(64, 158, 255, 0.4);
}

.rating-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.rating-number {
  font-size: 18px;
  font-weight: 700;
  color: #303133;
}

.rating-scale :deep(.el-radio-button__original-radio:checked + .el-radio-button__inner) .rating-number {
  color: white;
}

.rating-label {
  font-size: 13px;
  color: #606266;
  text-align: center;
  font-weight: 500;
  line-height: 1.3;
}

.rating-scale :deep(.el-radio-button__original-radio:checked + .el-radio-button__inner) .rating-label {
  color: white;
  font-weight: 600;
}

/* Rating Descriptions - matches CompetencyAssessment */
.rating-descriptions {
  padding: 16px;
  background: white;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.rating-description {
  margin-bottom: 12px;
  color: #606266;
  font-size: 13px;
  line-height: 1.6;
}

.rating-description:last-child {
  margin-bottom: 0;
}

.rating-description strong {
  color: #303133;
  font-weight: 600;
}

/* Action Buttons */
.assessment-actions {
  display: flex;
  justify-content: flex-end;
  gap: 16px;
  padding-top: 20px;
  border-top: 2px solid #e4e7ed;
}

/* Responsive */
@media (max-width: 768px) {
  .maturity-assessment {
    padding: 16px;
  }

  .indicator-item {
    padding: 16px;
  }

  .rating-scale :deep(.el-radio-group) {
    flex-direction: column;
  }

  .rating-scale :deep(.el-radio-button__inner) {
    width: 100%;
  }

  .assessment-actions {
    flex-direction: column;
  }

  .assessment-actions button {
    width: 100%;
  }
}
</style>
