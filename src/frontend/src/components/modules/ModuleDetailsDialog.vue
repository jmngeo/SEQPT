<template>
  <el-dialog
    :model-value="visible"
    @update:model-value="$emit('update:visible', $event)"
    :title="module?.name || 'Module Details'"
    width="80%"
    :before-close="handleClose"
    class="module-details-dialog"
  >
    <div v-if="module" class="module-details">
      <!-- Module Header -->
      <div class="module-header">
        <div class="header-content">
          <h2>{{ module.name }}</h2>
          <span class="module-code">{{ module.module_code }}</span>
          <div class="header-badges">
            <el-tag :type="getCategoryTagType(module.category)" effect="plain">
              {{ module.category }}
            </el-tag>
            <el-tag :type="getDifficultyTagType(module.difficulty_level)">
              {{ getDifficultyLabel(module.difficulty_level) }}
            </el-tag>
          </div>
        </div>
      </div>

      <!-- Module Overview -->
      <div class="module-overview">
        <h3><el-icon><Document /></el-icon> Overview</h3>
        <p class="definition">{{ module.definition }}</p>
        <div v-if="module.overview" class="industry-relevance">
          <h4>Industry Relevance:</h4>
          <p>{{ module.overview }}</p>
        </div>
      </div>

      <!-- Module Information -->
      <div class="module-info">
        <div class="info-grid">
          <div class="info-item">
            <strong>Duration:</strong>
            <span>{{ module.total_duration_hours || 'N/A' }} hours</span>
          </div>
          <div class="info-item">
            <strong>Difficulty:</strong>
            <span>{{ getDifficultyLabel(module.difficulty_level) }}</span>
          </div>
          <div class="info-item">
            <strong>Version:</strong>
            <span>{{ module.version || 'N/A' }}</span>
          </div>
          <div class="info-item" v-if="module.competency">
            <strong>Competency:</strong>
            <span>{{ module.competency.name }}</span>
          </div>
        </div>
      </div>

      <!-- Prerequisites and Dependencies -->
      <div v-if="module.prerequisites?.length > 0 || module.dependencies?.length > 0" class="requirements">
        <h3><el-icon><Link /></el-icon> Requirements</h3>
        <div v-if="module.prerequisites?.length > 0" class="prerequisites">
          <h4>Prerequisites:</h4>
          <div class="requirement-tags">
            <el-tag
              v-for="prereq in module.prerequisites"
              :key="prereq"
              type="warning"
              effect="plain"
            >
              {{ prereq }}
            </el-tag>
          </div>
        </div>
        <div v-if="module.dependencies?.length > 0" class="dependencies">
          <h4>Dependencies:</h4>
          <div class="requirement-tags">
            <el-tag
              v-for="dep in module.dependencies"
              :key="dep"
              type="info"
              effect="plain"
            >
              {{ dep }}
            </el-tag>
          </div>
        </div>
      </div>

      <!-- Level Content (if detailed data available) -->
      <div v-if="detailedModule?.level_contents" class="level-contents">
        <h3><el-icon><TrendCharts /></el-icon> Learning Levels</h3>
        <el-tabs v-model="activeLevel" type="border-card">
          <el-tab-pane
            v-for="(content, level) in detailedModule.level_contents"
            :key="level"
            :label="getLevelLabel(level)"
            :name="level"
          >
            <div class="level-detail">
              <div class="level-info">
                <div class="level-stat">
                  <strong>Duration:</strong>
                  <span>{{ content.hours || 'N/A' }} hours</span>
                </div>
              </div>

              <div v-if="content.objectives?.length > 0" class="objectives">
                <h4>Learning Objectives:</h4>
                <ul>
                  <li v-for="objective in content.objectives" :key="objective">
                    {{ objective }}
                  </li>
                </ul>
              </div>

              <div v-if="content.topics?.length > 0" class="topics">
                <h4>Topics Covered:</h4>
                <div class="topic-tags">
                  <el-tag
                    v-for="topic in content.topics"
                    :key="topic"
                    type="primary"
                    effect="plain"
                    size="small"
                  >
                    {{ topic }}
                  </el-tag>
                </div>
              </div>

              <div v-if="content.assessments?.length > 0" class="assessments">
                <h4>Assessment Methods:</h4>
                <ul>
                  <li v-for="assessment in content.assessments" :key="assessment">
                    {{ assessment }}
                  </li>
                </ul>
              </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </div>

      <!-- Industry Adaptations -->
      <div v-if="detailedModule?.industry_adaptations" class="industry-adaptations">
        <h3><el-icon><OfficeBuilding /></el-icon> Industry Adaptations</h3>
        <el-collapse accordion>
          <el-collapse-item
            v-for="(adaptation, industry) in detailedModule.industry_adaptations"
            :key="industry"
            :title="getIndustryLabel(industry)"
            :name="industry"
          >
            <ul v-if="Array.isArray(adaptation)">
              <li v-for="item in adaptation" :key="item">{{ item }}</li>
            </ul>
            <p v-else>{{ adaptation }}</p>
          </el-collapse-item>
        </el-collapse>
      </div>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="loading-state">
      <el-skeleton :rows="8" animated />
    </div>

    <!-- Dialog Footer -->
    <template #footer>
      <div class="dialog-footer">
        <el-button @click="handleClose">Close</el-button>
        <el-button
          type="primary"
          @click="handleEnroll"
          :disabled="!module"
          icon="Plus"
        >
          Enroll in Module
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Document, Link, TrendCharts, OfficeBuilding, Plus
} from '@element-plus/icons-vue'
import { assessmentApi } from '@/api/assessment'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  module: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update:visible', 'enroll', 'close'])

// Reactive data
const detailedModule = ref(null)
const loading = ref(false)
const activeLevel = ref('level_1_content')

// Watch for module changes to load detailed data
watch(() => props.module, async (newModule) => {
  if (newModule && props.visible) {
    await loadModuleDetails(newModule.module_code)
  }
}, { immediate: true })

watch(() => props.visible, async (visible) => {
  if (visible && props.module && !detailedModule.value) {
    await loadModuleDetails(props.module.module_code)
  }
})

// Methods
const loadModuleDetails = async (moduleCode) => {
  if (!moduleCode) return

  try {
    loading.value = true
    const response = await assessmentApi.getLearningModule(moduleCode)
    detailedModule.value = response.data.module

    // Set the first available level as active
    const levels = Object.keys(detailedModule.value.level_contents || {})
    if (levels.length > 0) {
      activeLevel.value = levels[0]
    }
  } catch (err) {
    ElMessage.error('Failed to load module details')
  } finally {
    loading.value = false
  }
}

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

const getLevelLabel = (level) => {
  const labelMap = {
    'level_1_content': 'Level 1: Remember',
    'level_2_content': 'Level 2: Understand',
    'level_3_4_content': 'Level 3-4: Apply & Analyze',
    'level_5_6_content': 'Level 5-6: Evaluate & Create'
  }
  return labelMap[level] || level
}

const getIndustryLabel = (industry) => {
  const labelMap = {
    'aerospace': 'Aerospace & Defense',
    'automotive': 'Automotive',
    'healthcare': 'Healthcare & Medical Devices'
  }
  return labelMap[industry] || industry.charAt(0).toUpperCase() + industry.slice(1)
}

const handleClose = () => {
  detailedModule.value = null
  emit('update:visible', false)
  emit('close')
}

const handleEnroll = () => {
  if (props.module) {
    emit('enroll', props.module)
    handleClose()
  }
}
</script>

<style scoped>
.module-details-dialog :deep(.el-dialog) {
  border-radius: 12px;
}

.module-details-dialog :deep(.el-dialog__header) {
  background: linear-gradient(135deg, #409eff 0%, #67c23a 100%);
  color: white;
  border-radius: 12px 12px 0 0;
}

.module-details-dialog :deep(.el-dialog__title) {
  color: white;
  font-size: 20px;
  font-weight: 600;
}

.module-details-dialog :deep(.el-dialog__headerbtn .el-dialog__close) {
  color: white;
  font-size: 20px;
}

.module-details {
  max-height: 70vh;
  overflow-y: auto;
  padding: 24px;
}

.module-header {
  margin-bottom: 32px;
  padding-bottom: 24px;
  border-bottom: 2px solid #e4e7ed;
}

.header-content h2 {
  margin: 0 0 12px 0;
  color: #303133;
  font-size: 24px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.module-code {
  display: inline-block;
  background: #f0f2f5;
  color: #606266;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 16px;
}

.header-badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.module-overview {
  margin-bottom: 32px;
}

.module-overview h3 {
  color: #303133;
  font-size: 18px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.definition {
  color: #606266;
  font-size: 16px;
  line-height: 1.6;
  margin-bottom: 20px;
}

.industry-relevance h4 {
  color: #303133;
  font-size: 14px;
  margin-bottom: 8px;
}

.industry-relevance p {
  color: #606266;
  font-size: 14px;
  line-height: 1.5;
  margin: 0;
}

.module-info {
  margin-bottom: 32px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
}

.info-item strong {
  color: #303133;
  font-size: 14px;
}

.info-item span {
  color: #606266;
  font-size: 14px;
}

.requirements {
  margin-bottom: 32px;
}

.requirements h3 {
  color: #303133;
  font-size: 18px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.prerequisites,
.dependencies {
  margin-bottom: 16px;
}

.prerequisites h4,
.dependencies h4 {
  color: #303133;
  font-size: 14px;
  margin-bottom: 8px;
}

.requirement-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.level-contents {
  margin-bottom: 32px;
}

.level-contents h3 {
  color: #303133;
  font-size: 18px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.level-detail {
  padding: 16px 0;
}

.level-info {
  margin-bottom: 20px;
  padding: 12px;
  background: #f0f2f5;
  border-radius: 6px;
}

.level-stat {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.objectives,
.topics,
.assessments {
  margin-bottom: 20px;
}

.objectives h4,
.topics h4,
.assessments h4 {
  color: #303133;
  font-size: 14px;
  margin-bottom: 12px;
}

.objectives ul,
.assessments ul {
  margin: 0;
  padding-left: 20px;
}

.objectives li,
.assessments li {
  margin-bottom: 8px;
  color: #606266;
  font-size: 14px;
  line-height: 1.5;
}

.topic-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.industry-adaptations {
  margin-bottom: 24px;
}

.industry-adaptations h3 {
  color: #303133;
  font-size: 18px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.loading-state {
  padding: 40px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 24px;
  border-top: 1px solid #e4e7ed;
  margin: 0 -24px -24px -24px;
  background: #f8f9fa;
}

@media (max-width: 768px) {
  .module-details-dialog :deep(.el-dialog) {
    width: 95% !important;
    margin: 20px auto !important;
  }

  .module-details {
    padding: 16px;
    max-height: 60vh;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }

  .dialog-footer {
    flex-direction: column;
    gap: 8px;
  }
}
</style>