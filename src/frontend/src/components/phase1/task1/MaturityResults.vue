<template>
  <div class="maturity-results">
    <el-card class="results-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <h2>SE Maturity Assessment Results</h2>
          <p class="subtitle">Your organization's Systems Engineering maturity profile</p>
        </div>
      </template>

      <!-- Simplified: Overall Maturity Score Only -->
      <div class="overall-score-section">
        <div class="score-display">
          <div class="score-circle" :style="{ borderColor: results.maturityColor }">
            <div class="score-value" :style="{ color: results.maturityColor }">
              {{ results.finalScore }}
            </div>
            <div class="score-max">/100</div>
          </div>

          <div class="score-details">
            <h3 class="maturity-level" :style="{ color: results.maturityColor }">
              Level {{ results.maturityLevel }}: {{ results.maturityName }}
            </h3>
            <p class="maturity-description">{{ results.maturityDescription }}</p>
          </div>
        </div>

        <!-- Maturity Level Progress Bar -->
        <div class="level-progress">
          <el-progress
            :percentage="(results.finalScore / 100) * 100"
            :color="results.maturityColor"
            :stroke-width="12"
            :show-text="false"
          />
          <div class="level-markers">
            <span
              v-for="level in maturityLevels"
              :key="level.level"
              class="level-marker"
              :class="{ 'active': results.maturityLevel >= level.level }"
              :style="{ left: `${(level.scoreRange.min / 100) * 100}%` }"
            >
              L{{ level.level }}
            </span>
          </div>
        </div>
      </div>

      <!-- Assessment Scope Clarification -->
      <div class="assessment-scope-note">
        <div class="scope-header">
          <strong>About This Assessment</strong>
        </div>
        <p>
          This maturity assessment evaluates your organization based on <strong>4 crucial fields of action</strong> specifically relevant for
          <strong>Systems Engineering Qualification Planning</strong>: Rollout Scope, SE Processes & Roles, SE Mindset, and Knowledge Base.
        </p>
        <p>
          <strong>Important:</strong> There are many other fields of action and dimensions for assessing organizational maturity that are not included
          in this assessment. Therefore, this result is tailored specifically for SE qualification planning purposes and
          <strong>does not represent the overall maturity level of your organization</strong>. It reflects maturity only in the context of
          the specific fields of action measured here.
        </p>
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons">
        <el-button size="large" @click="emit('back-to-assessment')">
          Retake Assessment
        </el-button>
        <el-button
          type="primary"
          size="large"
          @click="proceedToNextTask"
        >
          Continue to Roles & Responsibilities
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup>
// Props
const props = defineProps({
  results: {
    type: Object,
    required: true
  }
});

// Emits
const emit = defineEmits(['back-to-assessment', 'proceed-to-task2']);

// Data
const maturityLevels = [
  { level: 1, name: 'Initial', scoreRange: { min: 0, max: 20 } },
  { level: 2, name: 'Developing', scoreRange: { min: 20, max: 40 } },
  { level: 3, name: 'Defined', scoreRange: { min: 40, max: 60 } },
  { level: 4, name: 'Managed', scoreRange: { min: 60, max: 80 } },
  { level: 5, name: 'Optimized', scoreRange: { min: 80, max: 100 } }
];

// Methods
const proceedToNextTask = () => {
  emit('proceed-to-task2', props.results);
};
</script>

<style scoped>
.maturity-results {
  max-width: 1000px;
  margin: 0 auto;
  padding: 20px;
}

.results-card {
  margin-bottom: 20px;
}

.card-header {
  text-align: center;
}

.card-header h2 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 22px;
  font-weight: 600;
}

.subtitle {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

/* Overall Score Section */
.overall-score-section {
  margin: 24px 0;
}

.score-display {
  display: flex;
  align-items: center;
  gap: 32px;
  padding: 28px 32px;
  background: linear-gradient(135deg, #f8f9fb 0%, #eceff4 100%);
  border-radius: 12px;
  margin-bottom: 24px;
}

.score-circle {
  flex-shrink: 0;
  width: 140px;
  height: 140px;
  border: 8px solid #409EFF;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.score-value {
  font-size: 40px;
  font-weight: 700;
  color: #409EFF;
  line-height: 1;
}

.score-max {
  font-size: 18px;
  color: #909399;
  margin-top: 2px;
}

.score-details {
  flex: 1;
}

.maturity-level {
  margin: 0 0 12px 0;
  font-size: 24px;
  font-weight: 600;
}

.maturity-description {
  margin: 0;
  color: #606266;
  font-size: 15px;
  line-height: 1.6;
}

.level-progress {
  position: relative;
  margin-top: 20px;
}

.level-markers {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
  position: relative;
}

.level-marker {
  font-size: 12px;
  color: #909399;
  font-weight: bold;
}

.level-marker.active {
  color: #67C23A;
}

/* Assessment Scope Clarification */
.assessment-scope-note {
  margin: 24px 0;
  padding: 20px 24px;
  background: linear-gradient(135deg, #fff8e1 0%, #fffbf0 100%);
  border-left: 4px solid #ff9800;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(255, 152, 0, 0.1);
}

.scope-header {
  margin-bottom: 12px;
  color: #e65100;
  font-size: 16px;
}

.scope-header strong {
  font-weight: 600;
}

.assessment-scope-note p {
  margin: 0 0 12px 0;
  color: #5d4037;
  font-size: 14px;
  line-height: 1.7;
}

.assessment-scope-note p:last-child {
  margin-bottom: 0;
}

.assessment-scope-note strong {
  color: #d84315;
  font-weight: 600;
}

/* Action Buttons */
.action-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #DCDFE6;
}

/* Info Note */
.info-note {
  margin-top: 20px;
}

/* Responsive */
@media (max-width: 768px) {
  .maturity-results {
    padding: 12px;
  }

  .card-header h2 {
    font-size: 20px;
  }

  .subtitle {
    font-size: 13px;
  }

  .score-display {
    flex-direction: column;
    text-align: center;
    padding: 24px 20px;
    gap: 20px;
  }

  .score-circle {
    width: 120px;
    height: 120px;
    border-width: 6px;
  }

  .score-value {
    font-size: 36px;
  }

  .score-max {
    font-size: 16px;
  }

  .maturity-level {
    font-size: 20px;
  }

  .maturity-description {
    font-size: 14px;
  }

  .assessment-scope-note {
    padding: 16px 18px;
  }

  .scope-header {
    font-size: 15px;
  }

  .assessment-scope-note p {
    font-size: 13px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-buttons button {
    width: 100%;
  }
}
</style>
