<template>
  <el-card class="phase2-results step-card">
    <template #header>
      <div class="card-header">
        <h2>Phase 2 - Task 2: Assessment Results</h2>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Review your competency assessment results and identified development areas.
        </p>
      </div>
    </template>

    <!-- Loading state -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="8" animated />
    </div>

    <!-- Error state -->
    <el-alert
      v-else-if="error"
      type="error"
      :title="error"
      show-icon
      :closable="false"
    />

    <!-- Results display -->
    <div v-else>
      <!-- Summary statistics -->
      <div class="summary-section">
        <h3>Assessment Summary</h3>
        <div class="summary-stats">
          <div class="stat-card">
            <div class="stat-value">{{ summary.total_competencies }}</div>
            <div class="stat-label">Total Competencies Assessed</div>
          </div>
          <div class="stat-card success">
            <div class="stat-value">{{ summary.competencies_met }}</div>
            <div class="stat-label">Requirements Met</div>
          </div>
          <div class="stat-card danger">
            <div class="stat-value">{{ summary.competencies_with_gaps }}</div>
            <div class="stat-label">Development Areas</div>
          </div>
          <div class="stat-card info">
            <div class="stat-value">{{ summary.average_gap.toFixed(1) }}</div>
            <div class="stat-label">Average Gap</div>
          </div>
        </div>
      </div>

      <!-- Strengths section -->
      <div v-if="strengthsCompetencies.length > 0" class="results-section">
        <div class="section-header success-header">
          <el-icon class="section-icon"><CircleCheck /></el-icon>
          <h3>Strengths ({{ strengthsCompetencies.length }})</h3>
        </div>
        <p class="section-description">
          Competencies where you meet or exceed the required level.
        </p>

        <div class="competencies-table">
          <el-table :data="strengthsCompetencies" stripe>
            <el-table-column prop="competency_name" label="Competency" min-width="200">
              <template #default="scope">
                <div>
                  <strong>{{ scope.row.competency_name }}</strong>
                  <el-tag
                    :type="getAreaTagType(scope.row.competency_area)"
                    size="small"
                    style="margin-left: 8px;"
                  >
                    {{ scope.row.competency_area }}
                  </el-tag>
                </div>
              </template>
            </el-table-column>

            <el-table-column label="Required Level" width="140" align="center">
              <template #default="scope">
                <el-tag type="warning" size="small">
                  {{ getLevelName(scope.row.required_level) }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="Your Level" width="140" align="center">
              <template #default="scope">
                <el-tag type="success" size="small">
                  {{ getLevelName(scope.row.current_level) }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="Status" width="120" align="center">
              <template #default="scope">
                <el-tag
                  :type="scope.row.status === 'met' ? 'success' : 'primary'"
                  effect="dark"
                  size="small"
                >
                  {{ scope.row.status === 'met' ? 'Met' : 'Exceeded' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <!-- Gaps section -->
      <div v-if="gapCompetencies.length > 0" class="results-section">
        <div class="section-header danger-header">
          <el-icon class="section-icon"><WarningFilled /></el-icon>
          <h3>Development Areas ({{ gapCompetencies.length }})</h3>
        </div>
        <p class="section-description">
          Competencies where you are below the required level. Focus on these for professional development.
        </p>

        <div class="competencies-table">
          <el-table :data="gapCompetencies" stripe>
            <el-table-column prop="competency_name" label="Competency" min-width="200">
              <template #default="scope">
                <div>
                  <strong>{{ scope.row.competency_name }}</strong>
                  <el-tag
                    :type="getAreaTagType(scope.row.competency_area)"
                    size="small"
                    style="margin-left: 8px;"
                  >
                    {{ scope.row.competency_area }}
                  </el-tag>
                </div>
              </template>
            </el-table-column>

            <el-table-column label="Required Level" width="140" align="center">
              <template #default="scope">
                <el-tag type="warning" size="small">
                  {{ getLevelName(scope.row.required_level) }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="Your Level" width="140" align="center">
              <template #default="scope">
                <el-tag type="info" size="small">
                  {{ getLevelName(scope.row.current_level) }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="Gap" width="100" align="center">
              <template #default="scope">
                <span style="font-weight: 600; color: #f56c6c;">
                  {{ scope.row.gap }}
                </span>
              </template>
            </el-table-column>

            <el-table-column label="Priority" width="120" align="center">
              <template #default="scope">
                <el-tag
                  :type="scope.row.priority === 'high' ? 'danger' : 'warning'"
                  effect="dark"
                  size="small"
                >
                  {{ scope.row.priority === 'high' ? 'HIGH' : 'MEDIUM' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <!-- All competencies section (collapsible) -->
      <div class="results-section">
        <el-collapse v-model="activeCollapse">
          <el-collapse-item title="View All Competencies" name="all">
            <div class="competencies-table">
              <el-table :data="allCompetencies" stripe>
                <el-table-column prop="competency_name" label="Competency" min-width="180">
                  <template #default="scope">
                    <div>
                      <strong>{{ scope.row.competency_name }}</strong>
                      <br />
                      <el-tag
                        :type="getAreaTagType(scope.row.competency_area)"
                        size="small"
                        style="margin-top: 4px;"
                      >
                        {{ scope.row.competency_area }}
                      </el-tag>
                    </div>
                  </template>
                </el-table-column>

                <el-table-column label="Required" width="120" align="center">
                  <template #default="scope">
                    <el-tag type="warning" size="small">
                      {{ getLevelName(scope.row.required_level) }}
                    </el-tag>
                  </template>
                </el-table-column>

                <el-table-column label="Current" width="120" align="center">
                  <template #default="scope">
                    <el-tag
                      :type="getStatusTagType(scope.row.status)"
                      size="small"
                    >
                      {{ getLevelName(scope.row.current_level) }}
                    </el-tag>
                  </template>
                </el-table-column>

                <el-table-column label="Gap" width="100" align="center">
                  <template #default="scope">
                    <span :style="{ color: getGapColor(scope.row.gap), fontWeight: 600 }">
                      {{ scope.row.gap > 0 ? '+' : '' }}{{ scope.row.gap }}
                    </span>
                  </template>
                </el-table-column>

                <el-table-column label="Status" width="130" align="center">
                  <template #default="scope">
                    <el-tag
                      :type="getStatusTagType(scope.row.status)"
                      effect="dark"
                      size="small"
                    >
                      {{ getStatusLabel(scope.row.status) }}
                    </el-tag>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </el-collapse-item>
        </el-collapse>
      </div>

      <!-- Actions -->
      <div class="step-actions">
        <el-button @click="handleBack">
          Back to Assessment
        </el-button>
        <div class="action-buttons">
          <el-button @click="handlePrint">
            <el-icon class="el-icon--left"><Printer /></el-icon>
            Print Results
          </el-button>
          <el-button type="primary" @click="handleContinue">
            Continue
            <el-icon class="el-icon--right"><ArrowRight /></el-icon>
          </el-button>
        </div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  CircleCheck,
  WarningFilled,
  Printer,
  ArrowRight
} from '@element-plus/icons-vue'
import { toast } from 'vue3-toastify'

const props = defineProps({
  assessmentId: {
    type: Number,
    required: true
  },
  results: {
    type: Object,
    required: true
  },
  summary: {
    type: Object,
    default: () => ({
      total_competencies: 0,
      competencies_met: 0,
      competencies_with_gaps: 0,
      average_gap: 0
    })
  }
})

const emit = defineEmits(['continue', 'back'])

// State
const loading = ref(false)
const error = ref(null)
const activeCollapse = ref([])

// Computed properties
const allCompetencies = computed(() => {
  return props.results?.gaps || []
})

const strengthsCompetencies = computed(() => {
  return allCompetencies.value.filter(c =>
    c.status === 'met' || c.status === 'exceeded'
  )
})

const gapCompetencies = computed(() => {
  return allCompetencies.value.filter(c => c.status === 'gap')
})

const summary = computed(() => {
  if (props.summary) return props.summary

  // Calculate from results if summary not provided
  const total = allCompetencies.value.length
  const met = strengthsCompetencies.value.length
  const gaps = gapCompetencies.value.length
  const avgGap = gaps > 0
    ? allCompetencies.value.reduce((sum, c) => sum + (c.gap || 0), 0) / total
    : 0

  return {
    total_competencies: total,
    competencies_met: met,
    competencies_with_gaps: gaps,
    average_gap: avgGap
  }
})

/**
 * Get level name from numeric value
 */
const getLevelName = (level) => {
  const mapping = {
    0: 'None',
    1: 'Know',
    2: 'Understand',
    4: 'Apply',
    6: 'Master'
  }
  return mapping[level] || `Level ${level}`
}

/**
 * Get tag type based on competency area
 */
const getAreaTagType = (area) => {
  const mapping = {
    'Core': 'primary',
    'Social / Personal': 'success',
    'Management': 'warning',
    'Technical': 'danger'
  }
  return mapping[area] || 'info'
}

/**
 * Get tag type based on status
 */
const getStatusTagType = (status) => {
  const mapping = {
    'gap': 'danger',
    'met': 'success',
    'exceeded': 'primary'
  }
  return mapping[status] || 'info'
}

/**
 * Get status label
 */
const getStatusLabel = (status) => {
  const mapping = {
    'gap': 'Gap',
    'met': 'Met',
    'exceeded': 'Exceeded'
  }
  return mapping[status] || status
}

/**
 * Get color based on gap value
 */
const getGapColor = (gap) => {
  if (gap > 0) return '#f56c6c' // Red for gaps
  if (gap === 0) return '#67c23a' // Green for met
  return '#409eff' // Blue for exceeded
}

/**
 * Print results
 */
const handlePrint = () => {
  window.print()
}

/**
 * Continue to next step
 */
const handleContinue = () => {
  emit('continue')
}

/**
 * Go back to assessment
 */
const handleBack = () => {
  emit('back')
}
</script>

<style scoped>
.phase2-results {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

.loading-container {
  padding: 20px;
}

/* Summary section */
.summary-section {
  margin-bottom: 32px;
}

.summary-section h3 {
  margin: 0 0 16px 0;
  font-size: 18px;
  color: #303133;
}

.summary-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.stat-card {
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 8px;
  border-left: 4px solid #909399;
  text-align: center;
}

.stat-card.success {
  background-color: #f0f9ff;
  border-left-color: #67c23a;
}

.stat-card.danger {
  background-color: #fef0f0;
  border-left-color: #f56c6c;
}

.stat-card.info {
  background-color: #ecf5ff;
  border-left-color: #409eff;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

/* Results section */
.results-section {
  margin-bottom: 32px;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  padding: 16px;
  border-radius: 8px;
}

.success-header {
  background-color: #f0f9ff;
  border-left: 4px solid #67c23a;
}

.danger-header {
  background-color: #fef0f0;
  border-left: 4px solid #f56c6c;
}

.section-header h3 {
  margin: 0;
  font-size: 18px;
  color: #303133;
}

.section-icon {
  font-size: 24px;
}

.success-header .section-icon {
  color: #67c23a;
}

.danger-header .section-icon {
  color: #f56c6c;
}

.section-description {
  margin: 0 0 16px 0;
  color: #606266;
  font-size: 14px;
}

/* Tables */
.competencies-table {
  margin-bottom: 16px;
}

/* Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 24px;
  border-top: 1px solid #dcdfe6;
  margin-top: 32px;
}

.action-buttons {
  display: flex;
  gap: 12px;
}

/* Print styles */
@media print {
  .step-actions,
  .el-collapse {
    display: none;
  }

  .phase2-results {
    padding: 20px;
  }
}

/* Responsive */
@media (max-width: 768px) {
  .summary-stats {
    grid-template-columns: 1fr;
  }

  .step-actions {
    flex-direction: column;
    gap: 12px;
  }

  .action-buttons {
    flex-direction: column;
    width: 100%;
  }

  .action-buttons .el-button {
    width: 100%;
  }
}
</style>
