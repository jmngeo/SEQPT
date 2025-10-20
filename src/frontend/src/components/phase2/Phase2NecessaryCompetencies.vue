<template>
  <el-card class="phase2-competencies step-card">
    <template #header>
      <div class="card-header">
        <h2>Necessary Competencies for Selected Roles</h2>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Based on your role selection, the following {{ competencies.length }} competencies are required.
        </p>
      </div>
    </template>

    <!-- Selected roles summary -->
    <div class="roles-summary">
      <h3>Selected Roles ({{ selectedRoles.length }})</h3>
      <div class="roles-list">
        <el-tag
          v-for="role in selectedRoles"
          :key="role.phase1RoleId"
          type="primary"
          size="large"
          class="role-tag"
        >
          {{ role.orgRoleName || role.standardRoleName }}
        </el-tag>
      </div>
    </div>

    <el-divider />

    <!-- Info alert -->
    <el-alert
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 24px;"
    >
      <template #title>
        Dynamic Assessment
      </template>
      You will only be assessed on these {{ competencies.length }} competencies
      (instead of all 16), reducing assessment time and fatigue.
    </el-alert>

    <!-- Competencies grouped by area -->
    <div
      v-for="area in competencyAreas"
      :key="area"
      class="competency-area-section"
    >
      <div class="area-header">
        <h3>{{ area }}</h3>
        <el-tag size="small">
          {{ competenciesByArea[area].length }} competencies
        </el-tag>
      </div>

      <el-table
        :data="competenciesByArea[area]"
        style="width: 100%; margin-top: 12px;"
        stripe
      >
        <el-table-column label="Competency" min-width="300">
          <template #default="{ row }">
            <div class="competency-name">
              <strong>{{ row.competencyName }}</strong>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="Required Level" width="180" align="center">
          <template #default="{ row }">
            <el-tag :type="getLevelColor(row.requiredLevel)" size="large">
              Level {{ row.requiredLevel }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="Proficiency" width="200" align="center">
          <template #default="{ row }">
            <div class="level-name">
              {{ getLevelName(row.requiredLevel) }}
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- Summary statistics -->
    <div class="statistics-section">
      <h3>Assessment Summary</h3>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M9 2h6a2 2 0 012 2v16a2 2 0 01-2 2H9a2 2 0 01-2-2V4a2 2 0 012-2z" opacity="0.3"/>
              <path d="M9 2a2 2 0 00-2 2v16a2 2 0 002 2h6a2 2 0 002-2V4a2 2 0 00-2-2H9zm3 15a1 1 0 100 2 1 1 0 000-2z"/>
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ competencies.length }}</div>
            <div class="stat-label">Total Competencies</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3 4h18v2H3V4zm0 7h18v2H3v-2zm0 7h18v2H3v-2z" opacity="0.3"/>
              <path d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm0 7a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1v-2z"/>
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ competencyAreas.length }}</div>
            <div class="stat-label">Competency Areas</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="12" cy="12" r="10" opacity="0.3"/>
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">~{{ estimatedTime }} min</div>
            <div class="stat-label">Estimated Time</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3z" opacity="0.3"/>
              <path d="M8 5a3 3 0 100 6 3 3 0 000-6zm8 0a3 3 0 100 6 3 3 0 000-6zM8 13c-2.67 0-8 1.34-8 4v3h16v-3c0-2.66-5.33-4-8-4zm8 0c-.29 0-.62.02-.97.05C16.19 13.89 17 14.9 17 16v3h7v-3c0-2.66-5.33-4-8-4z"/>
            </svg>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ selectedRoles.length }}</div>
            <div class="stat-label">Selected Roles</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="step-actions">
      <el-button @click="handleBack">
        <el-icon class="el-icon--left"><ArrowLeft /></el-icon>
        Back to Role Selection
      </el-button>
      <el-button
        type="primary"
        size="large"
        @click="handleStartAssessment"
      >
        Start Competency Assessment
        <el-icon class="el-icon--right"><ArrowRight /></el-icon>
      </el-button>
    </div>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import { ArrowLeft, ArrowRight } from '@element-plus/icons-vue'
import { toast } from 'vue3-toastify'

const props = defineProps({
  competencies: {
    type: Array,
    required: true,
    default: () => []
  },
  selectedRoles: {
    type: Array,
    required: true,
    default: () => []
  },
  organizationId: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['next', 'back'])

/**
 * Get unique competency areas
 */
const competencyAreas = computed(() => {
  const areas = new Set(props.competencies.map(c => c.competencyArea))
  return Array.from(areas).sort()
})

/**
 * Group competencies by area
 */
const competenciesByArea = computed(() => {
  const grouped = {}
  props.competencies.forEach(comp => {
    if (!grouped[comp.competencyArea]) {
      grouped[comp.competencyArea] = []
    }
    grouped[comp.competencyArea].push(comp)
  })
  return grouped
})

/**
 * Estimated assessment time (2 minutes per competency)
 */
const estimatedTime = computed(() => {
  return Math.ceil(props.competencies.length * 2)
})

/**
 * Get competency level name
 */
const getLevelName = (level) => {
  const mapping = {
    0: 'Not Relevant',
    1: 'Know',
    2: 'Understand',
    4: 'Apply',
    6: 'Master'
  }
  return mapping[level] || 'Unknown'
}

/**
 * Get color for level tag
 */
const getLevelColor = (level) => {
  if (level >= 6) return 'danger'
  if (level >= 4) return 'warning'
  if (level >= 2) return 'success'
  return 'info'
}

/**
 * Start competency assessment (proceed to Task 2)
 */
const handleStartAssessment = () => {
  console.log('[Phase2] Starting assessment for', props.competencies.length, 'competencies')
  toast.info('Starting competency assessment...')

  emit('next', {
    competencies: props.competencies,
    selectedRoles: props.selectedRoles,
    organizationId: props.organizationId
  })
}

/**
 * Go back to role selection
 */
const handleBack = () => {
  emit('back')
}
</script>

<style scoped>
.phase2-competencies {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

/* Roles summary */
.roles-summary {
  margin-bottom: 20px;
}

.roles-summary h3 {
  font-size: 16px;
  color: #606266;
  margin-bottom: 12px;
}

.roles-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.role-tag {
  font-size: 14px;
  padding: 8px 16px;
}

/* Competency area sections */
.competency-area-section {
  margin-bottom: 32px;
}

.area-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.area-header h3 {
  margin: 0;
  font-size: 18px;
  color: #409eff;
}

.competency-name {
  font-size: 14px;
}

.level-name {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

/* Statistics */
.statistics-section {
  margin-top: 32px;
  padding: 24px;
  background: #f8f9fa;
  border-radius: 8px;
}

.statistics-section h3 {
  font-size: 18px;
  color: #303133;
  margin-bottom: 20px;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 20px;
}

.stat-card {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.stat-card:hover {
  border-color: #409eff;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
  transform: translateY(-2px);
}

.stat-icon {
  width: 48px;
  height: 48px;
  background: #f0f7ff;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #409eff;
}

.stat-icon svg {
  width: 28px;
  height: 28px;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 4px;
  line-height: 1;
}

.stat-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
  line-height: 1.4;
}

/* Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 32px;
  padding-top: 20px;
  border-top: 1px solid #dcdfe6;
}

/* Responsive */
@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .step-actions {
    flex-direction: column;
    gap: 12px;
  }

  .step-actions button {
    width: 100%;
  }
}
</style>
