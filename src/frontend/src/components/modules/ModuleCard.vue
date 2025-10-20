<template>
  <el-card
    class="module-card"
    :class="{
      'recommended': isRecommended,
      'enrolled': isEnrolled
    }"
    shadow="hover"
  >
    <!-- Card Header -->
    <template #header>
      <div class="card-header">
        <div class="module-info">
          <div class="module-title">
            <h3>{{ module.name }}</h3>
            <span class="module-code">{{ module.module_code }}</span>
          </div>
          <div class="badges">
            <el-tag
              :type="getCategoryTagType(module.category)"
              size="small"
              effect="plain"
            >
              {{ module.category }}
            </el-tag>
            <el-tag
              :type="getDifficultyTagType(module.difficulty_level)"
              size="small"
            >
              {{ getDifficultyLabel(module.difficulty_level) }}
            </el-tag>
            <el-tag
              v-if="isRecommended"
              type="warning"
              size="small"
              effect="dark"
            >
              <el-icon><Star /></el-icon>
              Recommended
            </el-tag>
            <el-tag
              v-if="isEnrolled"
              type="success"
              size="small"
              effect="plain"
            >
              <el-icon><Check /></el-icon>
              Enrolled
            </el-tag>
          </div>
        </div>
      </div>
    </template>

    <!-- Card Content -->
    <div class="card-content">
      <p class="module-definition">{{ module.definition }}</p>

      <!-- Competency Information -->
      <div v-if="module.competency" class="competency-info">
        <div class="competency-item">
          <el-icon><Document /></el-icon>
          <span>{{ module.competency.name }}</span>
        </div>
      </div>

      <!-- Module Stats -->
      <div class="module-stats">
        <div class="stat-item">
          <el-icon><Clock /></el-icon>
          <span>{{ module.total_duration_hours || 'N/A' }} hours</span>
        </div>
        <div class="stat-item">
          <el-icon><TrendCharts /></el-icon>
          <span>{{ getDifficultyLabel(module.difficulty_level) }}</span>
        </div>
        <div class="stat-item" v-if="module.version">
          <el-icon><Flag /></el-icon>
          <span>v{{ module.version }}</span>
        </div>
      </div>

      <!-- Prerequisites -->
      <div v-if="module.prerequisites?.length > 0" class="prerequisites">
        <h4><el-icon><Link /></el-icon> Prerequisites:</h4>
        <div class="prerequisite-tags">
          <el-tag
            v-for="prereq in module.prerequisites"
            :key="prereq"
            size="small"
            type="info"
            effect="plain"
          >
            {{ prereq }}
          </el-tag>
        </div>
      </div>

      <!-- Overview -->
      <div v-if="module.overview" class="module-overview">
        <el-collapse accordion>
          <el-collapse-item title="Industry Relevance" name="overview">
            <p>{{ module.overview }}</p>
          </el-collapse-item>
        </el-collapse>
      </div>
    </div>

    <!-- Card Actions -->
    <template #footer>
      <div class="card-actions">
        <el-button
          v-if="!isEnrolled"
          type="primary"
          @click="$emit('enroll', module)"
          :disabled="!canEnroll"
          icon="Plus"
        >
          Enroll
        </el-button>
        <el-button
          v-else
          type="success"
          @click="viewProgress"
          icon="TrendCharts"
        >
          View Progress
        </el-button>
        <el-button
          @click="$emit('view-details', module)"
          icon="ZoomIn"
        >
          Details
        </el-button>
        <el-dropdown @command="handleDropdownAction" placement="bottom-end">
          <el-button icon="MoreFilled" />
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="share">
                <el-icon><Share /></el-icon>
                Share Module
              </el-dropdown-item>
              <el-dropdown-item command="bookmark">
                <el-icon><Star /></el-icon>
                Add to Wishlist
              </el-dropdown-item>
              <el-dropdown-item command="compare">
                <el-icon><ScaleToOriginal /></el-icon>
                Compare Similar
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </template>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Star, Check, Document, Clock, TrendCharts, Flag, Link, Plus, ZoomIn,
  MoreFilled, Share, ScaleToOriginal
} from '@element-plus/icons-vue'

const props = defineProps({
  module: {
    type: Object,
    required: true
  },
  isRecommended: {
    type: Boolean,
    default: false
  },
  isEnrolled: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['enroll', 'view-details'])

const router = useRouter()

// Computed properties
const canEnroll = computed(() => {
  // Check if prerequisites are met
  if (!props.module.prerequisites?.length) return true
  // In a real implementation, you'd check if the user has completed prerequisites
  return true
})

// Methods
const getCategoryTagType = (category) => {
  const typeMap = {
    'Core Competencies': 'primary',
    'Professional Skills': 'success',
    'Social and Self-Competencies': 'warning',
    'Management Competencies': 'danger'
  }
  return typeMap[category] || 'info'
}

const getDifficultyTagType = (difficulty) => {
  const typeMap = {
    'beginner': 'success',
    'intermediate': 'warning',
    'advanced': 'danger'
  }
  return typeMap[difficulty] || 'info'
}

const getDifficultyLabel = (difficulty) => {
  const labelMap = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced'
  }
  return labelMap[difficulty] || difficulty
}

const viewProgress = () => {
  router.push(`/app/modules/progress/${props.module.module_code}`)
}

const handleDropdownAction = (command) => {
  switch (command) {
    case 'share':
      // Copy module URL to clipboard
      const moduleUrl = `${window.location.origin}/app/modules/${props.module.module_code}`
      navigator.clipboard?.writeText(moduleUrl)
      ElMessage.success('Module URL copied to clipboard!')
      break
    case 'bookmark':
      ElMessage.info('Wishlist functionality to be implemented')
      break
    case 'compare':
      ElMessage.info('Module comparison functionality to be implemented')
      break
  }
}
</script>

<style scoped>
.module-card {
  transition: all 0.3s ease;
  border: 2px solid transparent;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.module-card:hover {
  border-color: #409eff;
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.1);
}

.module-card.recommended {
  background: linear-gradient(135deg, #fff7e6 0%, #ffffff 100%);
  border-color: #e6a23c;
}

.module-card.enrolled {
  background: linear-gradient(135deg, #f0f9ff 0%, #ffffff 100%);
  border-color: #67c23a;
}

.card-header {
  padding: 0;
}

.module-info {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.module-title {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.module-title h3 {
  margin: 0;
  color: #303133;
  font-size: 18px;
  line-height: 1.4;
  flex: 1;
}

.module-code {
  background: #f0f2f5;
  color: #606266;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.badges {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0;
}

.module-definition {
  color: #606266;
  font-size: 14px;
  line-height: 1.6;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.competency-info {
  background: #f8f9fa;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
}

.competency-item {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #606266;
  font-size: 14px;
}

.module-stats {
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #909399;
  font-size: 13px;
}

.prerequisites {
  margin-top: 8px;
}

.prerequisites h4 {
  color: #303133;
  font-size: 14px;
  margin: 0 0 8px 0;
  display: flex;
  align-items: center;
  gap: 6px;
}

.prerequisite-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.module-overview {
  margin-top: 8px;
}

.module-overview :deep(.el-collapse-item__header) {
  font-size: 14px;
  font-weight: 500;
  color: #606266;
  border: none;
  background: #f8f9fa;
  border-radius: 4px;
  padding: 8px 12px;
}

.module-overview :deep(.el-collapse-item__content) {
  padding: 12px 0 0 0;
}

.module-overview p {
  color: #606266;
  font-size: 13px;
  line-height: 1.5;
  margin: 0;
}

.card-actions {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
  padding: 0;
}

.card-actions .el-button {
  flex: 1;
}

.card-actions .el-dropdown {
  margin-left: auto;
}

@media (max-width: 768px) {
  .module-title {
    flex-direction: column;
    align-items: stretch;
  }

  .module-stats {
    flex-direction: column;
    gap: 8px;
  }

  .card-actions {
    flex-direction: column;
    gap: 8px;
  }

  .card-actions .el-button {
    width: 100%;
  }
}
</style>