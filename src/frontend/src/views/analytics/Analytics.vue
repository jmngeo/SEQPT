<template>
  <div class="analytics">
    <div class="page-header">
      <div class="header-content">
        <h1><i class="el-icon-data-analysis"></i> Analytics & Insights</h1>
        <p>Comprehensive analysis of SE qualification and competency development</p>
      </div>
      <div class="header-actions">
        <el-date-picker
          v-model="dateRange"
          type="datetimerange"
          range-separator="to"
          start-placeholder="Start date"
          end-placeholder="End date"
          format="YYYY-MM-DD"
          value-format="YYYY-MM-DD"
          @change="loadAnalytics"
        ></el-date-picker>
        <el-button type="primary" @click="exportAnalytics" :loading="exporting">
          <i class="el-icon-download"></i> Export Report
        </el-button>
        <el-button @click="loadAnalytics" :loading="loading">
          <i class="el-icon-refresh"></i> Refresh
        </el-button>
      </div>
    </div>

    <!-- Overview Cards -->
    <el-row :gutter="20" class="overview-section">
      <el-col :span="6">
        <el-card class="overview-card">
          <div class="card-content">
            <div class="card-icon assessment-icon">
              <i class="el-icon-document"></i>
            </div>
            <div class="card-details">
              <div class="card-value">{{ overviewStats.totalAssessments }}</div>
              <div class="card-label">Total Assessments</div>
              <div class="card-change positive">
                <i class="el-icon-top"></i> +{{ overviewStats.assessmentGrowth }}%
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="overview-card">
          <div class="card-content">
            <div class="card-icon users-icon">
              <i class="el-icon-user"></i>
            </div>
            <div class="card-details">
              <div class="card-value">{{ overviewStats.activeUsers }}</div>
              <div class="card-label">Active Users</div>
              <div class="card-change positive">
                <i class="el-icon-top"></i> +{{ overviewStats.userGrowth }}%
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="overview-card">
          <div class="card-content">
            <div class="card-icon score-icon">
              <i class="el-icon-star"></i>
            </div>
            <div class="card-details">
              <div class="card-value">{{ overviewStats.averageScore }}%</div>
              <div class="card-label">Average Score</div>
              <div class="card-change" :class="overviewStats.scoreChange >= 0 ? 'positive' : 'negative'">
                <i :class="overviewStats.scoreChange >= 0 ? 'el-icon-top' : 'el-icon-bottom'"></i>
                {{ Math.abs(overviewStats.scoreChange) }}%
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="overview-card">
          <div class="card-content">
            <div class="card-icon completion-icon">
              <i class="el-icon-check"></i>
            </div>
            <div class="card-details">
              <div class="card-value">{{ overviewStats.completionRate }}%</div>
              <div class="card-label">Completion Rate</div>
              <div class="card-change positive">
                <i class="el-icon-top"></i> +{{ overviewStats.completionGrowth }}%
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Main Analytics Grid -->
    <el-row :gutter="20" class="analytics-grid">
      <!-- Assessment Trends Chart -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="chart-header">
              <span><i class="el-icon-trend-charts"></i> Assessment Trends</span>
              <el-select v-model="trendsTimeframe" @change="loadTrends" size="small">
                <el-option label="Last 7 days" value="7d"></el-option>
                <el-option label="Last 30 days" value="30d"></el-option>
                <el-option label="Last 3 months" value="3m"></el-option>
                <el-option label="Last year" value="1y"></el-option>
              </el-select>
            </div>
          </template>
          <div class="chart-container">
            <canvas ref="trendsChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- Competency Distribution -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <div class="chart-header">
              <span><i class="el-icon-pie-chart"></i> Competency Assessment Distribution</span>
              <el-button type="text" @click="toggleCompetencyView" size="small">
                {{ competencyViewType === 'pie' ? 'Bar View' : 'Pie View' }}
              </el-button>
            </div>
          </template>
          <div class="chart-container">
            <canvas ref="competencyChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- Phase Progress -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <span><i class="el-icon-s-data"></i> SE-QPT Phase Progress</span>
          </template>
          <div class="chart-container">
            <canvas ref="phaseChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- Performance by Role -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <span><i class="el-icon-user-solid"></i> Performance by SE Role</span>
          </template>
          <div class="chart-container">
            <canvas ref="roleChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- Learning Objectives Progress -->
      <el-col :span="24">
        <el-card class="chart-card">
          <template #header>
            <div class="chart-header">
              <span><i class="el-icon-aim"></i> Learning Objectives Progress</span>
              <div class="header-controls">
                <el-select v-model="objectiveFilter" @change="loadObjectiveProgress" size="small">
                  <el-option label="All Objectives" value="all"></el-option>
                  <el-option label="RAG Generated" value="rag"></el-option>
                  <el-option label="Manual" value="manual"></el-option>
                </el-select>
                <el-select v-model="objectiveGroupBy" @change="loadObjectiveProgress" size="small">
                  <el-option label="By Competency" value="competency"></el-option>
                  <el-option label="By Role" value="role"></el-option>
                  <el-option label="By Priority" value="priority"></el-option>
                </el-select>
              </div>
            </div>
          </template>
          <div class="chart-container large">
            <canvas ref="objectiveChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- RAG-LLM Performance Metrics -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <span><i class="el-icon-magic-stick"></i> RAG-LLM Quality Metrics</span>
          </template>
          <div class="rag-metrics">
            <div class="metric-item">
              <div class="metric-label">Average SMART Score</div>
              <div class="metric-value">
                <el-progress
                  type="circle"
                  :percentage="ragMetrics.averageSmartScore"
                  :width="80"
                  :stroke-width="8"
                  color="#67C23A"
                ></el-progress>
              </div>
            </div>
            <div class="metric-item">
              <div class="metric-label">Validation Pass Rate</div>
              <div class="metric-value">
                <el-progress
                  type="circle"
                  :percentage="ragMetrics.validationPassRate"
                  :width="80"
                  :stroke-width="8"
                  color="#409EFF"
                ></el-progress>
              </div>
            </div>
            <div class="metric-item">
              <div class="metric-label">Context Relevance</div>
              <div class="metric-value">
                <el-progress
                  type="circle"
                  :percentage="ragMetrics.contextRelevance"
                  :width="80"
                  :stroke-width="8"
                  color="#E6A23C"
                ></el-progress>
              </div>
            </div>
          </div>
          <div class="chart-container">
            <canvas ref="ragChart"></canvas>
          </div>
        </el-card>
      </el-col>

      <!-- System Usage Heatmap -->
      <el-col :span="12">
        <el-card class="chart-card">
          <template #header>
            <span><i class="el-icon-date"></i> System Usage Heatmap</span>
          </template>
          <div class="heatmap-container">
            <div class="heatmap-legend">
              <span>Less</span>
              <div class="legend-scale">
                <div class="legend-item" v-for="n in 5" :key="n" :class="`intensity-${n}`"></div>
              </div>
              <span>More</span>
            </div>
            <div class="heatmap-grid">
              <div class="heatmap-days">
                <div class="day-label" v-for="day in weekDays" :key="day">{{ day }}</div>
              </div>
              <div class="heatmap-hours">
                <div
                  v-for="hour in 24"
                  :key="hour"
                  class="hour-block"
                >
                  <div class="hour-label">{{ hour - 1 }}:00</div>
                  <div class="hour-data">
                    <div
                      v-for="day in 7"
                      :key="day"
                      class="usage-cell"
                      :class="`intensity-${getUsageIntensity(day, hour - 1)}`"
                      :title="`${weekDays[day - 1]} ${hour - 1}:00 - ${usageData[day - 1][hour - 1]} assessments`"
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Detailed Tables -->
    <el-row :gutter="20" class="tables-section">
      <!-- Top Performers -->
      <el-col :span="12">
        <el-card class="table-card">
          <template #header>
            <span><i class="el-icon-trophy"></i> Top Performers</span>
          </template>
          <el-table :data="topPerformers" stripe size="small">
            <el-table-column prop="rank" label="#" width="50">
              <template #default="scope">
                <el-tag
                  :type="scope.row.rank <= 3 ? 'warning' : 'info'"
                  size="small"
                >
                  {{ scope.row.rank }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="User" min-width="120"></el-table-column>
            <el-table-column prop="role" label="Role" width="100"></el-table-column>
            <el-table-column prop="score" label="Avg Score" width="80">
              <template #default="scope">
                <span class="score-badge">{{ scope.row.score }}%</span>
              </template>
            </el-table-column>
            <el-table-column prop="assessments" label="Assessments" width="80"></el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <!-- Recent Activity -->
      <el-col :span="12">
        <el-card class="table-card">
          <template #header>
            <span><i class="el-icon-time"></i> Recent Activity</span>
          </template>
          <el-table :data="recentActivity" stripe size="small">
            <el-table-column prop="user" label="User" min-width="100"></el-table-column>
            <el-table-column prop="action" label="Activity" min-width="150">
              <template #default="scope">
                <div class="activity-item">
                  <i :class="getActivityIcon(scope.row.type)"></i>
                  <span>{{ scope.row.action }}</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="timestamp" label="Time" width="100">
              <template #default="scope">
                {{ formatRelativeTime(scope.row.timestamp) }}
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <!-- Export Dialog -->
    <el-dialog v-model="exportDialogVisible" title="Export Analytics Report" width="50%">
      <el-form :model="exportOptions" label-width="120px">
        <el-form-item label="Report Type">
          <el-radio-group v-model="exportOptions.type">
            <el-radio label="summary">Executive Summary</el-radio>
            <el-radio label="detailed">Detailed Report</el-radio>
            <el-radio label="raw">Raw Data</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="Format">
          <el-select v-model="exportOptions.format">
            <el-option label="PDF Report" value="pdf"></el-option>
            <el-option label="Excel Spreadsheet" value="xlsx"></el-option>
            <el-option label="CSV Data" value="csv"></el-option>
            <el-option label="JSON Data" value="json"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Include Charts">
          <el-switch v-model="exportOptions.includeCharts"></el-switch>
        </el-form-item>
        <el-form-item label="Date Range">
          <el-date-picker
            v-model="exportOptions.dateRange"
            type="datetimerange"
            range-separator="to"
            start-placeholder="Start date"
            end-placeholder="End date"
          ></el-date-picker>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="exportDialogVisible = false">Cancel</el-button>
          <el-button type="primary" @click="performExport" :loading="exporting">
            Generate Report
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import axios from '@/api/axios'
import {
  Chart,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'

// Register Chart.js components
Chart.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

export default {
  name: 'Analytics',
  setup() {
    // Reactive data
    const loading = ref(false)
    const exporting = ref(false)
    const exportDialogVisible = ref(false)
    const dateRange = ref([])
    const trendsTimeframe = ref('30d')
    const competencyViewType = ref('pie')
    const objectiveFilter = ref('all')
    const objectiveGroupBy = ref('competency')

    // Chart references
    const trendsChart = ref(null)
    const competencyChart = ref(null)
    const phaseChart = ref(null)
    const roleChart = ref(null)
    const objectiveChart = ref(null)
    const ragChart = ref(null)

    // Chart instances
    const charts = ref({})

    // Data
    const overviewStats = ref({
      totalAssessments: 1247,
      assessmentGrowth: 12,
      activeUsers: 342,
      userGrowth: 8,
      averageScore: 78,
      scoreChange: 3,
      completionRate: 89,
      completionGrowth: 5
    })

    const ragMetrics = ref({
      averageSmartScore: 84,
      validationPassRate: 91,
      contextRelevance: 87
    })

    const topPerformers = ref([
      { rank: 1, name: 'Sarah Johnson', role: 'System Engineer', score: 94, assessments: 12 },
      { rank: 2, name: 'Michael Chen', role: 'Requirements Eng.', score: 92, assessments: 15 },
      { rank: 3, name: 'Emma Wilson', role: 'V&V Engineer', score: 90, assessments: 9 },
      { rank: 4, name: 'David Brown', role: 'Project Manager', score: 88, assessments: 11 },
      { rank: 5, name: 'Lisa Garcia', role: 'System Architect', score: 87, assessments: 8 }
    ])

    const recentActivity = ref([
      { user: 'John Doe', action: 'Completed Phase 2 Assessment', type: 'assessment', timestamp: new Date(Date.now() - 5 * 60 * 1000) },
      { user: 'Jane Smith', action: 'Generated RAG objectives', type: 'rag', timestamp: new Date(Date.now() - 15 * 60 * 1000) },
      { user: 'Bob Wilson', action: 'Started Phase 1', type: 'phase', timestamp: new Date(Date.now() - 30 * 60 * 1000) },
      { user: 'Alice Johnson', action: 'Exported qualification plan', type: 'export', timestamp: new Date(Date.now() - 45 * 60 * 1000) },
      { user: 'Charlie Brown', action: 'Joined cohort formation', type: 'cohort', timestamp: new Date(Date.now() - 60 * 60 * 1000) }
    ])

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    const usageData = ref([
      // Mock usage data for heatmap (7 days x 24 hours)
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 10)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 10)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 10)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 10)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 10)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 8)),
      new Array(24).fill(0).map(() => Math.floor(Math.random() * 8))
    ])

    const exportOptions = ref({
      type: 'summary',
      format: 'pdf',
      includeCharts: true,
      dateRange: []
    })

    // Chart data
    const chartData = ref({
      trends: {
        labels: [],
        datasets: []
      },
      competency: {
        labels: [],
        datasets: []
      },
      phase: {
        labels: [],
        datasets: []
      },
      role: {
        labels: [],
        datasets: []
      },
      objective: {
        labels: [],
        datasets: []
      },
      rag: {
        labels: [],
        datasets: []
      }
    })

    // Methods
    const loadAnalytics = async () => {
      loading.value = true
      try {
        const params = {}
        if (dateRange.value && dateRange.value.length === 2) {
          params.startDate = dateRange.value[0]
          params.endDate = dateRange.value[1]
        }

        const response = await axios.get('/api/analytics', { params })

        // Update overview stats
        overviewStats.value = response.data.overview
        ragMetrics.value = response.data.ragMetrics

        // Load all chart data
        await Promise.all([
          loadTrends(),
          loadCompetencyDistribution(),
          loadPhaseProgress(),
          loadRolePerformance(),
          loadObjectiveProgress(),
          loadRAGMetrics()
        ])

        ElMessage.success('Analytics data loaded successfully')
      } catch (error) {
        console.error('Error loading analytics:', error)
        ElMessage.error('Failed to load analytics data')
      } finally {
        loading.value = false
      }
    }

    const loadTrends = async () => {
      try {
        const response = await axios.get('/api/analytics/trends', {
          params: { timeframe: trendsTimeframe.value }
        })

        chartData.value.trends = response.data
        await nextTick()
        renderTrendsChart()
      } catch (error) {
        console.error('Error loading trends:', error)
      }
    }

    const loadCompetencyDistribution = async () => {
      try {
        const response = await axios.get('/api/analytics/competency-distribution')
        chartData.value.competency = response.data
        await nextTick()
        renderCompetencyChart()
      } catch (error) {
        console.error('Error loading competency distribution:', error)
      }
    }

    const loadPhaseProgress = async () => {
      try {
        const response = await axios.get('/api/analytics/phase-progress')
        chartData.value.phase = response.data
        await nextTick()
        renderPhaseChart()
      } catch (error) {
        console.error('Error loading phase progress:', error)
      }
    }

    const loadRolePerformance = async () => {
      try {
        const response = await axios.get('/api/analytics/role-performance')
        chartData.value.role = response.data
        await nextTick()
        renderRoleChart()
      } catch (error) {
        console.error('Error loading role performance:', error)
      }
    }

    const loadObjectiveProgress = async () => {
      try {
        const response = await axios.get('/api/analytics/objective-progress', {
          params: {
            filter: objectiveFilter.value,
            groupBy: objectiveGroupBy.value
          }
        })
        chartData.value.objective = response.data
        await nextTick()
        renderObjectiveChart()
      } catch (error) {
        console.error('Error loading objective progress:', error)
      }
    }

    const loadRAGMetrics = async () => {
      try {
        const response = await axios.get('/api/analytics/rag-metrics')
        chartData.value.rag = response.data
        await nextTick()
        renderRAGChart()
      } catch (error) {
        console.error('Error loading RAG metrics:', error)
      }
    }

    // Chart rendering methods
    const renderTrendsChart = () => {
      if (charts.value.trends) {
        charts.value.trends.destroy()
      }

      const ctx = trendsChart.value?.getContext('2d')
      if (!ctx) return

      charts.value.trends = new Chart(ctx, {
        type: 'line',
        data: {
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
          datasets: [{
            label: 'Assessments Completed',
            data: [45, 67, 89, 78, 95, 112, 98],
            borderColor: '#409EFF',
            backgroundColor: 'rgba(64, 158, 255, 0.1)',
            fill: true,
            tension: 0.4
          }, {
            label: 'Average Score',
            data: [72, 75, 78, 74, 79, 81, 78],
            borderColor: '#67C23A',
            backgroundColor: 'rgba(103, 194, 58, 0.1)',
            fill: true,
            tension: 0.4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: false
            },
            legend: {
              position: 'bottom'
            }
          },
          scales: {
            y: {
              beginAtZero: true
            }
          }
        }
      })
    }

    const renderCompetencyChart = () => {
      if (charts.value.competency) {
        charts.value.competency.destroy()
      }

      const ctx = competencyChart.value?.getContext('2d')
      if (!ctx) return

      const data = {
        labels: ['Systems Thinking', 'Requirements Eng.', 'Architecture', 'V&V', 'Risk Mgmt', 'Config Mgmt'],
        datasets: [{
          data: [23, 18, 15, 12, 16, 11],
          backgroundColor: [
            '#FF6384',
            '#36A2EB',
            '#FFCE56',
            '#4BC0C0',
            '#9966FF',
            '#FF9F40'
          ]
        }]
      }

      charts.value.competency = new Chart(ctx, {
        type: competencyViewType.value,
        data: data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          }
        }
      })
    }

    const renderPhaseChart = () => {
      if (charts.value.phase) {
        charts.value.phase.destroy()
      }

      const ctx = phaseChart.value?.getContext('2d')
      if (!ctx) return

      charts.value.phase = new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: ['Phase 1 Complete', 'Phase 2 Complete', 'Phase 3 Complete', 'Phase 4 Complete', 'Not Started'],
          datasets: [{
            data: [45, 38, 28, 15, 12],
            backgroundColor: [
              '#67C23A',
              '#409EFF',
              '#E6A23C',
              '#F56C6C',
              '#909399'
            ]
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          }
        }
      })
    }

    const renderRoleChart = () => {
      if (charts.value.role) {
        charts.value.role.destroy()
      }

      const ctx = roleChart.value?.getContext('2d')
      if (!ctx) return

      charts.value.role = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: ['System Engineer', 'Requirements Eng.', 'V&V Engineer', 'Project Manager', 'System Architect'],
          datasets: [{
            label: 'Average Score',
            data: [85, 78, 82, 75, 88],
            backgroundColor: 'rgba(64, 158, 255, 0.8)',
            borderColor: '#409EFF',
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              max: 100
            }
          }
        }
      })
    }

    const renderObjectiveChart = () => {
      if (charts.value.objective) {
        charts.value.objective.destroy()
      }

      const ctx = objectiveChart.value?.getContext('2d')
      if (!ctx) return

      charts.value.objective = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: ['Requirements Analysis', 'System Design', 'Testing & Validation', 'Risk Assessment', 'Documentation'],
          datasets: [{
            label: 'Completed',
            data: [12, 8, 15, 6, 9],
            backgroundColor: 'rgba(103, 194, 58, 0.8)'
          }, {
            label: 'In Progress',
            data: [3, 5, 2, 4, 3],
            backgroundColor: 'rgba(230, 162, 60, 0.8)'
          }, {
            label: 'Not Started',
            data: [2, 4, 1, 3, 2],
            backgroundColor: 'rgba(144, 147, 153, 0.8)'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          },
          scales: {
            x: {
              stacked: true
            },
            y: {
              stacked: true,
              beginAtZero: true
            }
          }
        }
      })
    }

    const renderRAGChart = () => {
      if (charts.value.rag) {
        charts.value.rag.destroy()
      }

      const ctx = ragChart.value?.getContext('2d')
      if (!ctx) return

      charts.value.rag = new Chart(ctx, {
        type: 'radar',
        data: {
          labels: ['Specific', 'Measurable', 'Achievable', 'Relevant', 'Time-bound'],
          datasets: [{
            label: 'RAG Generated',
            data: [85, 82, 88, 90, 79],
            borderColor: '#409EFF',
            backgroundColor: 'rgba(64, 158, 255, 0.2)',
            pointBackgroundColor: '#409EFF'
          }, {
            label: 'Manual',
            data: [78, 75, 80, 77, 82],
            borderColor: '#67C23A',
            backgroundColor: 'rgba(103, 194, 58, 0.2)',
            pointBackgroundColor: '#67C23A'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom'
            }
          },
          scales: {
            r: {
              beginAtZero: true,
              max: 100
            }
          }
        }
      })
    }

    const toggleCompetencyView = () => {
      competencyViewType.value = competencyViewType.value === 'pie' ? 'bar' : 'pie'
      renderCompetencyChart()
    }

    const exportAnalytics = () => {
      exportDialogVisible.value = true
    }

    const performExport = async () => {
      exporting.value = true
      try {
        const response = await axios.post('/api/analytics/export', exportOptions.value, {
          responseType: 'blob'
        })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', `analytics-report.${exportOptions.value.format}`)
        document.body.appendChild(link)
        link.click()
        link.remove()

        ElMessage.success('Analytics report exported successfully')
        exportDialogVisible.value = false
      } catch (error) {
        console.error('Error exporting analytics:', error)
        ElMessage.error('Failed to export analytics report')
      } finally {
        exporting.value = false
      }
    }

    // Utility methods
    const getUsageIntensity = (day, hour) => {
      const value = usageData.value[day - 1][hour]
      if (value === 0) return 0
      if (value <= 2) return 1
      if (value <= 4) return 2
      if (value <= 6) return 3
      if (value <= 8) return 4
      return 5
    }

    const getActivityIcon = (type) => {
      const icons = {
        assessment: 'el-icon-document',
        rag: 'el-icon-magic-stick',
        phase: 'el-icon-s-data',
        export: 'el-icon-download',
        cohort: 'el-icon-user'
      }
      return icons[type] || 'el-icon-info'
    }

    const formatRelativeTime = (timestamp) => {
      const now = new Date()
      const diff = now - timestamp
      const minutes = Math.floor(diff / (1000 * 60))
      const hours = Math.floor(diff / (1000 * 60 * 60))

      if (minutes < 60) return `${minutes}m ago`
      return `${hours}h ago`
    }

    // Lifecycle
    onMounted(() => {
      loadAnalytics()
    })

    onUnmounted(() => {
      // Destroy all charts
      Object.values(charts.value).forEach(chart => {
        if (chart) chart.destroy()
      })
    })

    return {
      loading,
      exporting,
      exportDialogVisible,
      dateRange,
      trendsTimeframe,
      competencyViewType,
      objectiveFilter,
      objectiveGroupBy,
      trendsChart,
      competencyChart,
      phaseChart,
      roleChart,
      objectiveChart,
      ragChart,
      overviewStats,
      ragMetrics,
      topPerformers,
      recentActivity,
      weekDays,
      usageData,
      exportOptions,
      loadAnalytics,
      loadTrends,
      toggleCompetencyView,
      loadObjectiveProgress,
      exportAnalytics,
      performExport,
      getUsageIntensity,
      getActivityIcon,
      formatRelativeTime
    }
  }
}
</script>

<style scoped>
.analytics {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding: 25px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  color: white;
}

.header-content h1 {
  margin: 0;
  font-size: 2.2em;
}

.header-content p {
  margin: 5px 0 0 0;
  opacity: 0.9;
}

.header-actions {
  display: flex;
  gap: 15px;
  align-items: center;
}

.overview-section {
  margin-bottom: 30px;
}

.overview-card {
  border: none;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.3s ease;
}

.overview-card:hover {
  transform: translateY(-2px);
}

.card-content {
  display: flex;
  align-items: center;
  gap: 15px;
}

.card-icon {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
}

.assessment-icon {
  background: linear-gradient(135deg, #409EFF, #36A2EB);
}

.users-icon {
  background: linear-gradient(135deg, #67C23A, #4BC0C0);
}

.score-icon {
  background: linear-gradient(135deg, #E6A23C, #FFCE56);
}

.completion-icon {
  background: linear-gradient(135deg, #F56C6C, #FF6384);
}

.card-details {
  flex: 1;
}

.card-value {
  font-size: 2em;
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 5px;
}

.card-label {
  color: #7f8c8d;
  margin-bottom: 8px;
}

.card-change {
  font-size: 14px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
}

.card-change.positive {
  color: #67C23A;
}

.card-change.negative {
  color: #F56C6C;
}

.analytics-grid {
  margin-bottom: 30px;
}

.chart-card {
  margin-bottom: 20px;
  border: none;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-controls {
  display: flex;
  gap: 10px;
}

.chart-container {
  height: 300px;
  position: relative;
}

.chart-container.large {
  height: 400px;
}

.rag-metrics {
  display: flex;
  justify-content: space-around;
  margin-bottom: 20px;
  padding: 20px 0;
}

.metric-item {
  text-align: center;
}

.metric-label {
  font-size: 14px;
  color: #7f8c8d;
  margin-bottom: 10px;
}

.metric-value {
  display: flex;
  justify-content: center;
}

.heatmap-container {
  padding: 20px 0;
}

.heatmap-legend {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  margin-bottom: 20px;
  font-size: 12px;
  color: #7f8c8d;
}

.legend-scale {
  display: flex;
  gap: 2px;
}

.legend-item {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

.heatmap-grid {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.heatmap-days {
  display: flex;
  gap: 1px;
  margin-left: 50px;
}

.day-label {
  width: 30px;
  text-align: center;
  font-size: 12px;
  color: #7f8c8d;
  margin-bottom: 5px;
}

.heatmap-hours {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.hour-block {
  display: flex;
  align-items: center;
  gap: 1px;
}

.hour-label {
  width: 45px;
  font-size: 10px;
  color: #7f8c8d;
  text-align: right;
  padding-right: 5px;
}

.hour-data {
  display: flex;
  gap: 1px;
}

.usage-cell {
  width: 30px;
  height: 12px;
  border-radius: 2px;
  cursor: pointer;
}

.intensity-0 { background-color: #ebedf0; }
.intensity-1 { background-color: #c6e48b; }
.intensity-2 { background-color: #7bc96f; }
.intensity-3 { background-color: #239a3b; }
.intensity-4 { background-color: #196127; }
.intensity-5 { background-color: #0d4d15; }

.tables-section {
  margin-bottom: 30px;
}

.table-card {
  border: none;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.score-badge {
  font-weight: bold;
  color: #409EFF;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* Responsive Design */
@media (max-width: 1200px) {
  .page-header {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .header-actions {
    justify-content: center;
    flex-wrap: wrap;
  }

  .analytics-grid .el-col {
    margin-bottom: 20px;
  }
}

@media (max-width: 768px) {
  .analytics {
    padding: 10px;
  }

  .overview-section .el-col {
    margin-bottom: 15px;
  }

  .card-content {
    flex-direction: column;
    text-align: center;
  }

  .chart-container {
    height: 250px;
  }

  .rag-metrics {
    flex-direction: column;
    gap: 20px;
  }
}

/* Animation */
.overview-card {
  animation: fadeInUp 0.3s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>