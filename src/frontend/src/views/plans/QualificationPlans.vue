<template>
  <div class="qualification-plans">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Collection /></el-icon> Qualification Plans</h1>
        <p>Manage and track your personalized systems engineering qualification plans</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="$router.push('/app/plans/create')">
          <el-icon><Plus /></el-icon>
          Create New Plan
        </el-button>
      </div>
    </div>

    <div class="plans-container">
      <div class="plans-grid">
        <!-- Sample Plan Cards -->
        <el-card class="plan-card" v-for="plan in samplePlans" :key="plan.id">
          <div class="plan-header">
            <div class="plan-title">
              <h3>{{ plan.title }}</h3>
              <el-tag :type="getPlanStatusType(plan.status)">{{ plan.status }}</el-tag>
            </div>
            <div class="plan-progress">
              <el-progress
                :percentage="plan.progress"
                :stroke-width="8"
                :color="getProgressColor(plan.progress)"
              />
            </div>
          </div>

          <div class="plan-content">
            <p class="plan-description">{{ plan.description }}</p>

            <div class="plan-stats">
              <div class="stat">
                <el-icon><Document /></el-icon>
                <span>{{ plan.modules }} Modules</span>
              </div>
              <div class="stat">
                <el-icon><Clock /></el-icon>
                <span>{{ plan.duration }} weeks</span>
              </div>
              <div class="stat">
                <el-icon><User /></el-icon>
                <span>{{ plan.archetype }}</span>
              </div>
            </div>

            <div class="plan-actions">
              <el-button type="primary" @click="viewPlanDetails(plan.id)">
                View Details
              </el-button>
              <el-button @click="continuePlan(plan.id)">
                Continue
              </el-button>
            </div>
          </div>
        </el-card>

        <!-- Empty State -->
        <el-card class="empty-state" v-if="samplePlans.length === 0">
          <div class="empty-content">
            <el-icon size="64" class="empty-icon"><Collection /></el-icon>
            <h3>No Qualification Plans</h3>
            <p>Create your first qualification plan to start your learning journey</p>
            <el-button type="primary" @click="$router.push('/app/plans/create')">
              <el-icon><Plus /></el-icon>
              Create Your First Plan
            </el-button>
          </div>
        </el-card>
      </div>

      <div class="plans-placeholder">
        <el-card>
          <div class="placeholder-content">
            <h2>Qualification Plans Management</h2>
            <p>This page will provide comprehensive qualification plan management capabilities.</p>

            <div class="feature-list">
              <h3>Features to be implemented:</h3>
              <ul>
                <li>AI-generated personalized qualification plans</li>
                <li>Module sequencing and dependency management</li>
                <li>Progress tracking and milestone monitoring</li>
                <li>Competency gap analysis and recommendations</li>
                <li>Integration with assessment results</li>
                <li>Collaborative plan sharing and reviews</li>
              </ul>
            </div>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Collection, Plus, Document, Clock, User } from '@element-plus/icons-vue'

const router = useRouter()

// Sample data for demonstration
const samplePlans = ref([
  {
    id: 1,
    title: "Systems Architecture Specialist Track",
    description: "Comprehensive plan focusing on systems architecture and design principles",
    status: "Active",
    progress: 65,
    modules: 8,
    duration: 12,
    archetype: "System Architect"
  },
  {
    id: 2,
    title: "Requirements Engineering Pathway",
    description: "Specialized track for requirements analysis and management",
    status: "Planning",
    progress: 25,
    modules: 6,
    duration: 8,
    archetype: "Requirements Engineer"
  }
])

const getPlanStatusType = (status) => {
  const statusMap = {
    'Active': 'success',
    'Planning': 'warning',
    'Completed': 'info',
    'On Hold': 'danger'
  }
  return statusMap[status] || 'info'
}

const getProgressColor = (percentage) => {
  if (percentage < 30) return '#f56c6c'
  if (percentage < 70) return '#e6a23c'
  return '#67c23a'
}

const viewPlanDetails = (planId) => {
  router.push(`/app/plans/${planId}`)
}

const continuePlan = (planId) => {
  // Navigate to the next module or assessment in the plan
  router.push(`/app/plans/${planId}`)
}
</script>

<style scoped>
.qualification-plans {
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

.plans-container {
  max-width: 1200px;
  margin: 0 auto;
}

.plans-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.plan-card {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.plan-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.plan-header {
  margin-bottom: 16px;
}

.plan-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.plan-title h3 {
  margin: 0;
  color: #303133;
  font-size: 18px;
}

.plan-description {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.plan-stats {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.stat {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #909399;
  font-size: 14px;
}

.plan-actions {
  display: flex;
  gap: 12px;
}

.empty-state {
  grid-column: 1 / -1;
}

.empty-content {
  text-align: center;
  padding: 60px 40px;
}

.empty-icon {
  color: #dcdfe6;
  margin-bottom: 24px;
}

.empty-content h3 {
  color: #303133;
  margin-bottom: 12px;
}

.empty-content p {
  color: #606266;
  margin-bottom: 24px;
}

.placeholder-content {
  text-align: center;
  padding: 40px;
}

.placeholder-content h2 {
  color: #303133;
  margin-bottom: 12px;
}

.placeholder-content p {
  color: #606266;
  margin-bottom: 24px;
}

.feature-list {
  background: #f8f9fa;
  padding: 24px;
  border-radius: 8px;
  margin: 24px auto;
  max-width: 600px;
  text-align: left;
}

.feature-list h3 {
  color: #303133;
  margin-bottom: 16px;
}

.feature-list ul {
  color: #606266;
  line-height: 1.6;
}

.feature-list li {
  margin-bottom: 8px;
}
</style>