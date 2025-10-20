<template>
  <div class="plan-details">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Document /></el-icon> {{ plan.title }}</h1>
        <p>{{ plan.description }}</p>
      </div>
      <div class="header-actions">
        <el-button @click="$router.push('/app/plans')">
          <el-icon><ArrowLeft /></el-icon>
          Back to Plans
        </el-button>
        <el-button type="primary" @click="continueLearning">
          <el-icon><VideoPlay /></el-icon>
          Continue Learning
        </el-button>
      </div>
    </div>

    <div class="plan-container">
      <!-- Progress Overview -->
      <div class="progress-section">
        <el-row :gutter="24">
          <el-col :span="8">
            <el-card class="progress-card">
              <div class="progress-content">
                <div class="progress-circle">
                  <el-progress
                    type="circle"
                    :percentage="plan.overallProgress"
                    :width="80"
                    :stroke-width="8"
                  />
                </div>
                <div class="progress-info">
                  <h3>Overall Progress</h3>
                  <p>{{ plan.completedModules }}/{{ plan.totalModules }} modules completed</p>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card class="stats-card">
              <div class="stat-item">
                <el-icon size="24"><Clock /></el-icon>
                <div>
                  <div class="stat-value">{{ plan.timeSpent }}h</div>
                  <div class="stat-label">Time Spent</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card class="stats-card">
              <div class="stat-item">
                <el-icon size="24"><Trophy /></el-icon>
                <div>
                  <div class="stat-value">{{ plan.competenciesGained }}</div>
                  <div class="stat-label">Competencies Gained</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- Learning Path -->
      <el-card class="learning-path-card">
        <div class="card-header">
          <h2><el-icon><Guide /></el-icon> Learning Path</h2>
          <el-tag :type="getStatusType(plan.status)">{{ plan.status }}</el-tag>
        </div>

        <div class="learning-path">
          <div class="timeline">
            <div
              v-for="(module, index) in plan.modules"
              :key="module.id"
              class="timeline-item"
              :class="getModuleClass(module.status)"
            >
              <div class="timeline-marker">
                <el-icon>
                  <component :is="getModuleIcon(module.status)" />
                </el-icon>
              </div>
              <div class="timeline-content">
                <el-card class="module-card" :class="getModuleClass(module.status)">
                  <div class="module-header">
                    <h3>{{ module.title }}</h3>
                    <el-tag :type="getModuleStatusType(module.status)" size="small">
                      {{ module.status }}
                    </el-tag>
                  </div>
                  <p class="module-description">{{ module.description }}</p>

                  <div class="module-stats">
                    <span><el-icon><Clock /></el-icon> {{ module.duration }} hours</span>
                    <span><el-icon><Collection /></el-icon> {{ module.lessons }} lessons</span>
                    <span><el-icon><DocumentChecked /></el-icon> {{ module.assessments }} assessments</span>
                  </div>

                  <div class="module-progress" v-if="module.status !== 'Locked'">
                    <el-progress
                      :percentage="module.progress"
                      :stroke-width="6"
                      :show-text="false"
                    />
                    <span class="progress-text">{{ module.progress }}% complete</span>
                  </div>

                  <div class="module-actions">
                    <el-button
                      v-if="module.status === 'In Progress'"
                      type="primary"
                      @click="continueModule(module.id)"
                    >
                      Continue
                    </el-button>
                    <el-button
                      v-else-if="module.status === 'Available'"
                      @click="startModule(module.id)"
                    >
                      Start Module
                    </el-button>
                    <el-button
                      v-else-if="module.status === 'Completed'"
                      @click="reviewModule(module.id)"
                    >
                      Review
                    </el-button>
                    <el-button
                      v-else
                      disabled
                    >
                      Locked
                    </el-button>

                    <el-button text @click="viewModuleDetails(module.id)">
                      Details
                    </el-button>
                  </div>
                </el-card>
              </div>
            </div>
          </div>
        </div>
      </el-card>

      <!-- Competency Mapping -->
      <el-card class="competency-card">
        <div class="card-header">
          <h2><el-icon><Cpu /></el-icon> Competency Development</h2>
        </div>

        <div class="competency-grid">
          <div
            v-for="competency in plan.competencies"
            :key="competency.id"
            class="competency-item"
          >
            <div class="competency-info">
              <h4>{{ competency.name }}</h4>
              <p>{{ competency.description }}</p>
            </div>
            <div class="competency-progress">
              <el-progress
                :percentage="competency.progress"
                :stroke-width="8"
                :color="getCompetencyColor(competency.progress)"
              />
              <span class="level">Level {{ competency.currentLevel }}/{{ competency.targetLevel }}</span>
            </div>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  Document, ArrowLeft, VideoPlay, Clock, Trophy, Guide, Collection,
  DocumentChecked, Cpu, CircleCheck, Loading, Lock
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()

// Sample plan data
const plan = ref({
  id: route.params.uuid,
  title: "Systems Architecture Specialist Track",
  description: "Comprehensive qualification plan focusing on systems architecture and design principles",
  status: "Active",
  overallProgress: 45,
  completedModules: 3,
  totalModules: 8,
  timeSpent: 67,
  competenciesGained: 8,
  modules: [
    {
      id: 1,
      title: "Systems Thinking Fundamentals",
      description: "Introduction to systems thinking principles and methodologies",
      status: "Completed",
      progress: 100,
      duration: 12,
      lessons: 8,
      assessments: 2
    },
    {
      id: 2,
      title: "Requirements Engineering",
      description: "Comprehensive requirements analysis and management techniques",
      status: "Completed",
      progress: 100,
      duration: 15,
      lessons: 10,
      assessments: 3
    },
    {
      id: 3,
      title: "System Architecture Design",
      description: "Architectural patterns and design principles for complex systems",
      status: "In Progress",
      progress: 60,
      duration: 18,
      lessons: 12,
      assessments: 4
    },
    {
      id: 4,
      title: "Integration and Testing",
      description: "System integration strategies and testing methodologies",
      status: "Available",
      progress: 0,
      duration: 14,
      lessons: 9,
      assessments: 3
    },
    {
      id: 5,
      title: "Verification & Validation",
      description: "V&V processes and quality assurance techniques",
      status: "Locked",
      progress: 0,
      duration: 16,
      lessons: 11,
      assessments: 4
    }
  ],
  competencies: [
    {
      id: 1,
      name: "Systems Thinking",
      description: "Ability to view systems holistically",
      progress: 85,
      currentLevel: 3,
      targetLevel: 4
    },
    {
      id: 2,
      name: "Requirements Analysis",
      description: "Skills in analyzing and managing requirements",
      progress: 70,
      currentLevel: 3,
      targetLevel: 4
    },
    {
      id: 3,
      name: "Architecture Design",
      description: "Capability to design system architectures",
      progress: 45,
      currentLevel: 2,
      targetLevel: 4
    }
  ]
})

const getStatusType = (status) => {
  const statusMap = {
    'Active': 'success',
    'Planning': 'warning',
    'Completed': 'info',
    'On Hold': 'danger'
  }
  return statusMap[status] || 'info'
}

const getModuleClass = (status) => {
  return {
    'completed': status === 'Completed',
    'in-progress': status === 'In Progress',
    'available': status === 'Available',
    'locked': status === 'Locked'
  }
}

const getModuleIcon = (status) => {
  const iconMap = {
    'Completed': 'CircleCheck',
    'In Progress': 'Loading',
    'Available': 'VideoPlay',
    'Locked': 'Lock'
  }
  return iconMap[status] || 'VideoPlay'
}

const getModuleStatusType = (status) => {
  const statusMap = {
    'Completed': 'success',
    'In Progress': 'warning',
    'Available': 'info',
    'Locked': 'info'
  }
  return statusMap[status] || 'info'
}

const getCompetencyColor = (percentage) => {
  if (percentage < 30) return '#f56c6c'
  if (percentage < 70) return '#e6a23c'
  return '#67c23a'
}

const continueLearning = () => {
  // Find the current module in progress or next available
  const currentModule = plan.value.modules.find(m => m.status === 'In Progress')
  if (currentModule) {
    continueModule(currentModule.id)
  } else {
    const nextModule = plan.value.modules.find(m => m.status === 'Available')
    if (nextModule) {
      startModule(nextModule.id)
    }
  }
}

const startModule = (moduleId) => {
  // Navigate to module learning interface
  router.push(`/app/learning/modules/${moduleId}`)
}

const continueModule = (moduleId) => {
  // Navigate to module learning interface
  router.push(`/app/learning/modules/${moduleId}`)
}

const reviewModule = (moduleId) => {
  // Navigate to module review interface
  router.push(`/app/learning/modules/${moduleId}/review`)
}

const viewModuleDetails = (moduleId) => {
  // Navigate to detailed module information
  router.push(`/app/learning/modules/${moduleId}/details`)
}
</script>

<style scoped>
.plan-details {
  padding: 24px;
  background-color: #f5f7fa;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 24px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.header-content h1 {
  margin: 0;
  color: #303133;
  font-size: 28px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-content p {
  margin: 8px 0 0 0;
  color: #606266;
  font-size: 16px;
}

.plan-container {
  max-width: 1200px;
  margin: 0 auto;
}

.progress-section {
  margin-bottom: 24px;
}

.progress-card .progress-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.progress-info h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.progress-info p {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.stats-card .stat-item {
  display: flex;
  align-items: center;
  gap: 12px;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #409eff;
}

.stat-label {
  color: #606266;
  font-size: 14px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.card-header h2 {
  margin: 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 12px;
}

.learning-path {
  position: relative;
}

.timeline {
  position: relative;
}

.timeline::before {
  content: '';
  position: absolute;
  left: 30px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: #e4e7ed;
}

.timeline-item {
  position: relative;
  margin-bottom: 32px;
}

.timeline-marker {
  position: absolute;
  left: 18px;
  top: 20px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: white;
  border: 2px solid #e4e7ed;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.timeline-item.completed .timeline-marker {
  border-color: #67c23a;
  background: #67c23a;
  color: white;
}

.timeline-item.in-progress .timeline-marker {
  border-color: #e6a23c;
  background: #e6a23c;
  color: white;
}

.timeline-item.available .timeline-marker {
  border-color: #409eff;
  background: #409eff;
  color: white;
}

.timeline-content {
  margin-left: 70px;
}

.module-card {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.module-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.module-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.module-header h3 {
  margin: 0;
  color: #303133;
}

.module-description {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.module-stats {
  display: flex;
  gap: 20px;
  margin-bottom: 16px;
  font-size: 14px;
  color: #909399;
}

.module-stats span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.module-progress {
  margin-bottom: 16px;
}

.progress-text {
  margin-left: 8px;
  font-size: 12px;
  color: #909399;
}

.module-actions {
  display: flex;
  gap: 12px;
}

.competency-grid {
  display: grid;
  gap: 20px;
}

.competency-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.competency-info h4 {
  margin: 0 0 4px 0;
  color: #303133;
}

.competency-info p {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.competency-progress {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
  min-width: 200px;
}

.level {
  font-size: 12px;
  color: #909399;
}
</style>