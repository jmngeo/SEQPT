<template>
  <div class="admin-dashboard">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Monitor /></el-icon> Admin Dashboard</h1>
        <p>System overview and key metrics for SE-QPT platform administration</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="$router.push('/admin/panel')">
          <el-icon><Setting /></el-icon>
          Admin Panel
        </el-button>
      </div>
    </div>

    <div class="dashboard-container">
      <!-- Key Metrics -->
      <div class="metrics-section">
        <el-row :gutter="24">
          <el-col :span="6">
            <el-card class="metric-card">
              <div class="metric-content">
                <div class="metric-icon users">
                  <el-icon size="32"><User /></el-icon>
                </div>
                <div class="metric-stats">
                  <div class="metric-number">{{ metrics.totalUsers }}</div>
                  <div class="metric-label">Total Users</div>
                  <div class="metric-change positive">+{{ metrics.newUsersThisWeek }} this week</div>
                </div>
              </div>
            </el-card>
          </el-col>

          <el-col :span="6">
            <el-card class="metric-card">
              <div class="metric-content">
                <div class="metric-icon assessments">
                  <el-icon size="32"><DocumentChecked /></el-icon>
                </div>
                <div class="metric-stats">
                  <div class="metric-number">{{ metrics.totalAssessments }}</div>
                  <div class="metric-label">Assessments Completed</div>
                  <div class="metric-change positive">+{{ metrics.assessmentsThisWeek }} this week</div>
                </div>
              </div>
            </el-card>
          </el-col>

          <el-col :span="6">
            <el-card class="metric-card">
              <div class="metric-content">
                <div class="metric-icon plans">
                  <el-icon size="32"><Collection /></el-icon>
                </div>
                <div class="metric-stats">
                  <div class="metric-number">{{ metrics.activePlans }}</div>
                  <div class="metric-label">Active Plans</div>
                  <div class="metric-change neutral">{{ metrics.completionRate }}% completion rate</div>
                </div>
              </div>
            </el-card>
          </el-col>

          <el-col :span="6">
            <el-card class="metric-card">
              <div class="metric-content">
                <div class="metric-icon system">
                  <el-icon size="32"><Cpu /></el-icon>
                </div>
                <div class="metric-stats">
                  <div class="metric-number">{{ metrics.systemHealth }}%</div>
                  <div class="metric-label">System Health</div>
                  <div class="metric-change positive">All systems operational</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- Charts and Analytics -->
      <el-row :gutter="24">
        <el-col :span="12">
          <el-card class="chart-card">
            <div class="card-header">
              <h2><el-icon><TrendCharts /></el-icon> User Activity</h2>
              <el-select v-model="activityPeriod" size="small">
                <el-option label="Last 7 days" value="7d"></el-option>
                <el-option label="Last 30 days" value="30d"></el-option>
                <el-option label="Last 90 days" value="90d"></el-option>
              </el-select>
            </div>
            <div class="chart-placeholder">
              <div class="chart-content">
                <div class="chart-bars">
                  <div class="bar" style="height: 60%"></div>
                  <div class="bar" style="height: 80%"></div>
                  <div class="bar" style="height: 45%"></div>
                  <div class="bar" style="height: 90%"></div>
                  <div class="bar" style="height: 70%"></div>
                  <div class="bar" style="height: 85%"></div>
                  <div class="bar" style="height: 55%"></div>
                </div>
                <p class="chart-description">User activity trends over time</p>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="12">
          <el-card class="chart-card">
            <div class="card-header">
              <h2><el-icon><PieChart /></el-icon> Competency Distribution</h2>
            </div>
            <div class="chart-placeholder">
              <div class="competency-distribution">
                <div class="competency-item">
                  <div class="competency-bar">
                    <div class="bar-fill" style="width: 85%"></div>
                  </div>
                  <span>Systems Thinking (85%)</span>
                </div>
                <div class="competency-item">
                  <div class="competency-bar">
                    <div class="bar-fill" style="width: 70%"></div>
                  </div>
                  <span>Requirements Engineering (70%)</span>
                </div>
                <div class="competency-item">
                  <div class="competency-bar">
                    <div class="bar-fill" style="width: 60%"></div>
                  </div>
                  <span>System Architecture (60%)</span>
                </div>
                <div class="competency-item">
                  <div class="competency-bar">
                    <div class="bar-fill" style="width: 75%"></div>
                  </div>
                  <span>Verification & Validation (75%)</span>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Recent Activity and System Status -->
      <el-row :gutter="24">
        <el-col :span="12">
          <el-card class="activity-card">
            <div class="card-header">
              <h2><el-icon><Clock /></el-icon> Recent Activity</h2>
              <el-button text @click="refreshActivity">
                <el-icon><Refresh /></el-icon>
                Refresh
              </el-button>
            </div>

            <div class="activity-list">
              <div
                v-for="activity in recentActivity"
                :key="activity.id"
                class="activity-item"
              >
                <div class="activity-icon" :class="activity.type">
                  <el-icon>
                    <component :is="getActivityIcon(activity.type)" />
                  </el-icon>
                </div>
                <div class="activity-content">
                  <div class="activity-description">{{ activity.description }}</div>
                  <div class="activity-time">{{ formatTime(activity.timestamp) }}</div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="12">
          <el-card class="system-status-card">
            <div class="card-header">
              <h2><el-icon><Tools /></el-icon> System Status</h2>
            </div>

            <div class="system-services">
              <div
                v-for="service in systemServices"
                :key="service.name"
                class="service-item"
              >
                <div class="service-info">
                  <div class="service-name">{{ service.name }}</div>
                  <div class="service-description">{{ service.description }}</div>
                </div>
                <div class="service-status">
                  <el-tag :type="getStatusType(service.status)" size="small">
                    {{ service.status }}
                  </el-tag>
                  <div class="service-uptime">{{ service.uptime }}</div>
                </div>
              </div>
            </div>

            <el-divider />

            <div class="quick-actions">
              <h3>Quick Actions</h3>
              <div class="action-buttons">
                <el-button size="small" @click="$router.push('/admin/users')">
                  <el-icon><User /></el-icon>
                  Manage Users
                </el-button>
                <el-button size="small" @click="$router.push('/admin/competencies')">
                  <el-icon><Cpu /></el-icon>
                  Competencies
                </el-button>
                <el-button size="small" @click="$router.push('/admin/reports')">
                  <el-icon><DataAnalysis /></el-icon>
                  View Reports
                </el-button>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced Admin Features</h2>
          <p>This comprehensive admin dashboard will provide advanced system management and analytics capabilities.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Real-time system monitoring and alerts</li>
              <li>Advanced user analytics and behavior tracking</li>
              <li>Automated report generation and scheduling</li>
              <li>System configuration management</li>
              <li>Backup and recovery management</li>
              <li>Performance optimization recommendations</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  Monitor, Setting, User, DocumentChecked, Collection, Cpu, TrendCharts,
  PieChart, Clock, Refresh, Tools, DataAnalysis, SuccessFilled, Warning, CircleClose
} from '@element-plus/icons-vue'

const router = useRouter()

const activityPeriod = ref('7d')

const metrics = ref({
  totalUsers: 1247,
  newUsersThisWeek: 23,
  totalAssessments: 3456,
  assessmentsThisWeek: 87,
  activePlans: 892,
  completionRate: 78,
  systemHealth: 99
})

const recentActivity = ref([
  {
    id: 1,
    type: 'user',
    description: 'New user registered: john.doe@company.com',
    timestamp: new Date(Date.now() - 1000 * 60 * 5) // 5 minutes ago
  },
  {
    id: 2,
    type: 'assessment',
    description: 'Assessment completed by Sarah Johnson',
    timestamp: new Date(Date.now() - 1000 * 60 * 12) // 12 minutes ago
  },
  {
    id: 3,
    type: 'plan',
    description: 'New qualification plan created',
    timestamp: new Date(Date.now() - 1000 * 60 * 25) // 25 minutes ago
  },
  {
    id: 4,
    type: 'system',
    description: 'System backup completed successfully',
    timestamp: new Date(Date.now() - 1000 * 60 * 60) // 1 hour ago
  },
  {
    id: 5,
    type: 'competency',
    description: 'Competency framework updated',
    timestamp: new Date(Date.now() - 1000 * 60 * 90) // 1.5 hours ago
  }
])

const systemServices = ref([
  {
    name: 'Web Application',
    description: 'Main SE-QPT platform',
    status: 'Operational',
    uptime: '99.9%'
  },
  {
    name: 'Database',
    description: 'PostgreSQL database cluster',
    status: 'Operational',
    uptime: '99.8%'
  },
  {
    name: 'AI/LLM Service',
    description: 'Competency analysis engine',
    status: 'Operational',
    uptime: '98.5%'
  },
  {
    name: 'File Storage',
    description: 'Document and media storage',
    status: 'Warning',
    uptime: '97.2%'
  },
  {
    name: 'Email Service',
    description: 'Notification delivery',
    status: 'Operational',
    uptime: '99.6%'
  }
])

const getActivityIcon = (type) => {
  const iconMap = {
    'user': 'User',
    'assessment': 'DocumentChecked',
    'plan': 'Collection',
    'system': 'Tools',
    'competency': 'Cpu'
  }
  return iconMap[type] || 'User'
}

const getStatusType = (status) => {
  const statusMap = {
    'Operational': 'success',
    'Warning': 'warning',
    'Error': 'danger',
    'Maintenance': 'info'
  }
  return statusMap[status] || 'info'
}

const formatTime = (timestamp) => {
  const now = new Date()
  const diff = now - timestamp
  const minutes = Math.floor(diff / (1000 * 60))
  const hours = Math.floor(diff / (1000 * 60 * 60))

  if (minutes < 60) {
    return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`
  } else {
    return `${hours} hour${hours !== 1 ? 's' : ''} ago`
  }
}

const refreshActivity = () => {
  // Simulate refreshing activity data
  console.log('Refreshing activity data...')
}
</script>

<style scoped>
.admin-dashboard {
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

.dashboard-container {
  max-width: 1400px;
  margin: 0 auto;
}

.metrics-section {
  margin-bottom: 24px;
}

.metric-card {
  height: 120px;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.metric-content {
  display: flex;
  align-items: center;
  gap: 16px;
  height: 100%;
}

.metric-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.metric-icon.users {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.metric-icon.assessments {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.metric-icon.plans {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.metric-icon.system {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.metric-number {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

.metric-label {
  color: #606266;
  font-size: 14px;
  margin-bottom: 4px;
}

.metric-change {
  font-size: 12px;
  font-weight: 500;
}

.metric-change.positive {
  color: #67c23a;
}

.metric-change.neutral {
  color: #909399;
}

.chart-card, .activity-card, .system-status-card {
  margin-bottom: 24px;
  min-height: 300px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card-header h2 {
  margin: 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
}

.chart-placeholder {
  height: 250px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f9fa;
  border-radius: 8px;
}

.chart-content {
  text-align: center;
}

.chart-bars {
  display: flex;
  align-items: end;
  gap: 8px;
  height: 120px;
  margin-bottom: 16px;
}

.bar {
  width: 20px;
  background: linear-gradient(to top, #409eff, #67c23a);
  border-radius: 2px 2px 0 0;
  transition: height 0.3s ease;
}

.chart-description {
  color: #909399;
  font-size: 14px;
  margin: 0;
}

.competency-distribution {
  width: 100%;
  padding: 20px;
}

.competency-item {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.competency-bar {
  width: 200px;
  height: 8px;
  background: #e4e7ed;
  border-radius: 4px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #409eff, #67c23a);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.activity-list {
  max-height: 300px;
  overflow-y: auto;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.activity-icon {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 16px;
}

.activity-icon.user {
  background: #409eff;
}

.activity-icon.assessment {
  background: #67c23a;
}

.activity-icon.plan {
  background: #e6a23c;
}

.activity-icon.system {
  background: #909399;
}

.activity-icon.competency {
  background: #f56c6c;
}

.activity-description {
  color: #303133;
  font-size: 14px;
}

.activity-time {
  color: #909399;
  font-size: 12px;
}

.system-services {
  margin-bottom: 20px;
}

.service-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.service-name {
  font-weight: 600;
  color: #303133;
}

.service-description {
  color: #606266;
  font-size: 13px;
}

.service-status {
  text-align: right;
}

.service-uptime {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.quick-actions h3 {
  margin: 0 0 12px 0;
  color: #303133;
  font-size: 16px;
}

.action-buttons {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.features-placeholder {
  margin-top: 32px;
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