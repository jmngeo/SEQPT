<template>
  <div class="reports">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><DataAnalysis /></el-icon> Reports & Analytics</h1>
        <p>Generate comprehensive reports and analytics for the SE-QPT platform</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="generateReport">
          <el-icon><DocumentAdd /></el-icon>
          Generate Report
        </el-button>
        <el-button @click="exportReports">
          <el-icon><Download /></el-icon>
          Export
        </el-button>
      </div>
    </div>

    <div class="reports-container">
      <!-- Report Categories -->
      <div class="report-categories">
        <el-row :gutter="24">
          <el-col :span="8">
            <el-card class="category-card" @click="activeCategory = 'user'">
              <div class="category-content">
                <el-icon size="48" class="category-icon user"><User /></el-icon>
                <h3>User Analytics</h3>
                <p>User engagement, progress, and performance metrics</p>
                <div class="category-stats">
                  <span>{{ reportStats.userReports }} reports available</span>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card class="category-card" @click="activeCategory = 'assessment'">
              <div class="category-content">
                <el-icon size="48" class="category-icon assessment"><DocumentChecked /></el-icon>
                <h3>Assessment Reports</h3>
                <p>Assessment results, trends, and competency analysis</p>
                <div class="category-stats">
                  <span>{{ reportStats.assessmentReports }} reports available</span>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card class="category-card" @click="activeCategory = 'system'">
              <div class="category-content">
                <el-icon size="48" class="category-icon system"><Monitor /></el-icon>
                <h3>System Reports</h3>
                <p>Platform usage, performance, and operational metrics</p>
                <div class="category-stats">
                  <span>{{ reportStats.systemReports }} reports available</span>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- Available Reports -->
      <el-card class="reports-list-card">
        <div class="card-header">
          <h2>Available Reports</h2>
          <div class="header-filters">
            <el-select v-model="reportFilter" placeholder="Filter by type">
              <el-option label="All Reports" value=""></el-option>
              <el-option label="User Reports" value="user"></el-option>
              <el-option label="Assessment Reports" value="assessment"></el-option>
              <el-option label="System Reports" value="system"></el-option>
            </el-select>
          </div>
        </div>

        <div class="reports-grid">
          <div
            v-for="report in filteredReports"
            :key="report.id"
            class="report-item"
          >
            <div class="report-content">
              <div class="report-header">
                <h4>{{ report.title }}</h4>
                <el-tag :type="getReportType(report.category)" size="small">
                  {{ report.category }}
                </el-tag>
              </div>
              <p class="report-description">{{ report.description }}</p>
              <div class="report-meta">
                <span><el-icon><Clock /></el-icon> {{ report.lastGenerated }}</span>
                <span><el-icon><Download /></el-icon> {{ report.downloads }} downloads</span>
              </div>
              <div class="report-actions">
                <el-button size="small" @click="generateSpecificReport(report)">
                  Generate
                </el-button>
                <el-button size="small" @click="viewReport(report)">
                  View
                </el-button>
                <el-button size="small" @click="scheduleReport(report)">
                  Schedule
                </el-button>
              </div>
            </div>
          </div>
        </div>
      </el-card>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced Reporting & Analytics</h2>
          <p>Comprehensive reporting system for the SE-QPT platform with advanced analytics capabilities.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Interactive dashboard with real-time metrics</li>
              <li>Custom report builder with drag-and-drop interface</li>
              <li>Automated report scheduling and distribution</li>
              <li>Advanced data visualization and charting</li>
              <li>Predictive analytics and trend analysis</li>
              <li>Integration with external BI tools</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  DataAnalysis, DocumentAdd, Download, User, DocumentChecked, Monitor, Clock
} from '@element-plus/icons-vue'

const activeCategory = ref('user')
const reportFilter = ref('')

const reportStats = ref({
  userReports: 12,
  assessmentReports: 8,
  systemReports: 6
})

// Sample reports data
const reports = ref([
  {
    id: 1,
    title: 'User Engagement Summary',
    description: 'Overview of user activity, login patterns, and engagement metrics',
    category: 'user',
    lastGenerated: '2 days ago',
    downloads: 45
  },
  {
    id: 2,
    title: 'Competency Assessment Results',
    description: 'Detailed analysis of assessment outcomes and competency levels',
    category: 'assessment',
    lastGenerated: '1 day ago',
    downloads: 67
  },
  {
    id: 3,
    title: 'Platform Performance Metrics',
    description: 'System uptime, response times, and performance indicators',
    category: 'system',
    lastGenerated: '3 hours ago',
    downloads: 23
  },
  {
    id: 4,
    title: 'Learning Progress Report',
    description: 'Individual and group learning progress across qualification plans',
    category: 'user',
    lastGenerated: '5 days ago',
    downloads: 89
  },
  {
    id: 5,
    title: 'Assessment Validity Analysis',
    description: 'Statistical analysis of assessment reliability and validity',
    category: 'assessment',
    lastGenerated: '1 week ago',
    downloads: 34
  }
])

const filteredReports = computed(() => {
  if (!reportFilter.value) return reports.value
  return reports.value.filter(report => report.category === reportFilter.value)
})

const getReportType = (category) => {
  const categoryMap = {
    'user': 'primary',
    'assessment': 'success',
    'system': 'warning'
  }
  return categoryMap[category] || 'info'
}

const generateReport = () => {
  ElMessage.info('Report generation functionality will be available soon')
}

const generateSpecificReport = (report) => {
  ElMessage.success(`Generating ${report.title}...`)
}

const viewReport = (report) => {
  ElMessage.info(`Viewing ${report.title}`)
}

const scheduleReport = (report) => {
  ElMessage.info(`Scheduling ${report.title}`)
}

const exportReports = () => {
  ElMessage.info('Report export functionality will be available soon')
}
</script>

<style scoped>
.reports {
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

.reports-container {
  max-width: 1200px;
  margin: 0 auto;
}

.report-categories {
  margin-bottom: 32px;
}

.category-card {
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  text-align: center;
  height: 200px;
}

.category-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.category-content {
  padding: 20px;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.category-icon {
  margin-bottom: 16px;
}

.category-icon.user {
  color: #409eff;
}

.category-icon.assessment {
  color: #67c23a;
}

.category-icon.system {
  color: #e6a23c;
}

.category-content h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.category-content p {
  color: #606266;
  margin-bottom: 12px;
  font-size: 14px;
}

.category-stats {
  color: #909399;
  font-size: 12px;
}

.reports-list-card {
  margin-bottom: 32px;
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
}

.reports-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.report-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 20px;
  background: white;
  transition: box-shadow 0.2s ease;
}

.report-item:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.report-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.report-header h4 {
  margin: 0;
  color: #303133;
}

.report-description {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.report-meta {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
  font-size: 12px;
  color: #909399;
}

.report-meta span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.report-actions {
  display: flex;
  gap: 8px;
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