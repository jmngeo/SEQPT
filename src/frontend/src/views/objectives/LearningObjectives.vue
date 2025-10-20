<template>
  <div class="learning-objectives">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Aim /></el-icon> Learning Objectives</h1>
        <p>Track and manage your personalized learning objectives across all qualification plans</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="$router.push('/app/objectives/generate')">
          <el-icon><MagicStick /></el-icon>
          Generate New Objectives
        </el-button>
        <el-button @click="$router.push('/app/objectives/rag')">
          <el-icon><Cpu /></el-icon>
          RAG-LLM Generation
        </el-button>
      </div>
    </div>

    <div class="objectives-container">
      <!-- Filters and Search -->
      <el-card class="filters-card">
        <div class="filters-section">
          <el-row :gutter="20">
            <el-col :span="6">
              <el-select v-model="filters.status" placeholder="Filter by Status" clearable>
                <el-option label="All Status" value=""></el-option>
                <el-option label="Active" value="active"></el-option>
                <el-option label="Completed" value="completed"></el-option>
                <el-option label="In Progress" value="in_progress"></el-option>
                <el-option label="Pending" value="pending"></el-option>
              </el-select>
            </el-col>
            <el-col :span="6">
              <el-select v-model="filters.competency" placeholder="Filter by Competency" clearable>
                <el-option label="All Competencies" value=""></el-option>
                <el-option label="Systems Thinking" value="systems_thinking"></el-option>
                <el-option label="Requirements Engineering" value="requirements"></el-option>
                <el-option label="Architecture Design" value="architecture"></el-option>
                <el-option label="Verification & Validation" value="verification"></el-option>
              </el-select>
            </el-col>
            <el-col :span="6">
              <el-select v-model="filters.priority" placeholder="Filter by Priority" clearable>
                <el-option label="All Priorities" value=""></el-option>
                <el-option label="High" value="high"></el-option>
                <el-option label="Medium" value="medium"></el-option>
                <el-option label="Low" value="low"></el-option>
              </el-select>
            </el-col>
            <el-col :span="6">
              <el-input
                v-model="filters.search"
                placeholder="Search objectives..."
                prefix-icon="Search"
                clearable
              ></el-input>
            </el-col>
          </el-row>
        </div>
      </el-card>

      <!-- Objectives Grid -->
      <div class="objectives-grid">
        <div
          v-for="objective in filteredObjectives"
          :key="objective.id"
          class="objective-card"
        >
          <el-card>
            <div class="objective-header">
              <div class="objective-title">
                <h3>{{ objective.title }}</h3>
                <div class="objective-meta">
                  <el-tag :type="getStatusType(objective.status)" size="small">
                    {{ objective.status }}
                  </el-tag>
                  <el-tag :type="getPriorityType(objective.priority)" size="small">
                    {{ objective.priority }} Priority
                  </el-tag>
                </div>
              </div>
              <div class="objective-progress">
                <el-progress
                  type="circle"
                  :percentage="objective.progress"
                  :width="60"
                  :stroke-width="6"
                  :color="getProgressColor(objective.progress)"
                />
              </div>
            </div>

            <div class="objective-content">
              <p class="objective-description">{{ objective.description }}</p>

              <div class="objective-details">
                <div class="detail-item">
                  <el-icon><Collection /></el-icon>
                  <span>{{ objective.competency }}</span>
                </div>
                <div class="detail-item">
                  <el-icon><Calendar /></el-icon>
                  <span>Due: {{ formatDate(objective.dueDate) }}</span>
                </div>
                <div class="detail-item">
                  <el-icon><Clock /></el-icon>
                  <span>{{ objective.estimatedHours }}h estimated</span>
                </div>
              </div>

              <!-- Learning Resources -->
              <div class="resources-section" v-if="objective.resources.length > 0">
                <h4>Learning Resources</h4>
                <div class="resources-list">
                  <el-tag
                    v-for="resource in objective.resources"
                    :key="resource"
                    size="small"
                    class="resource-tag"
                  >
                    {{ resource }}
                  </el-tag>
                </div>
              </div>

              <!-- Sub-objectives -->
              <div class="sub-objectives" v-if="objective.subObjectives.length > 0">
                <h4>Sub-objectives</h4>
                <div class="sub-objectives-list">
                  <div
                    v-for="subObj in objective.subObjectives"
                    :key="subObj.id"
                    class="sub-objective-item"
                  >
                    <el-checkbox
                      v-model="subObj.completed"
                      @change="updateSubObjective(objective.id, subObj.id, $event)"
                    >
                      {{ subObj.title }}
                    </el-checkbox>
                  </div>
                </div>
              </div>

              <div class="objective-actions">
                <el-button
                  v-if="objective.status === 'pending'"
                  type="primary"
                  @click="startObjective(objective.id)"
                >
                  Start Learning
                </el-button>
                <el-button
                  v-else-if="objective.status === 'in_progress'"
                  type="primary"
                  @click="continueObjective(objective.id)"
                >
                  Continue
                </el-button>
                <el-button
                  v-else-if="objective.status === 'completed'"
                  @click="reviewObjective(objective.id)"
                >
                  Review
                </el-button>

                <el-button text @click="editObjective(objective.id)">
                  Edit
                </el-button>
                <el-button text type="danger" @click="deleteObjective(objective.id)">
                  Delete
                </el-button>
              </div>
            </div>
          </el-card>
        </div>

        <!-- Empty State -->
        <div v-if="filteredObjectives.length === 0" class="empty-state">
          <el-card>
            <div class="empty-content">
              <el-icon size="64" class="empty-icon"><Aim /></el-icon>
              <h3>No Learning Objectives Found</h3>
              <p>Create your first learning objective to start tracking your progress</p>
              <el-button type="primary" @click="$router.push('/app/objectives/generate')">
                <el-icon><MagicStick /></el-icon>
                Generate Learning Objectives
              </el-button>
            </div>
          </el-card>
        </div>
      </div>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Learning Objectives Management</h2>
          <p>This comprehensive learning objectives system will provide advanced tracking and management capabilities.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>AI-powered objective generation based on competency gaps</li>
              <li>Adaptive learning path recommendations</li>
              <li>Progress tracking with milestone notifications</li>
              <li>Integration with qualification plans and assessments</li>
              <li>Collaborative objective sharing and peer reviews</li>
              <li>Analytics and insights on learning patterns</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Aim, MagicStick, Cpu, Collection, Calendar, Clock, Search } from '@element-plus/icons-vue'

const router = useRouter()

const filters = ref({
  status: '',
  competency: '',
  priority: '',
  search: ''
})

// Sample objectives data
const objectives = ref([
  {
    id: 1,
    title: "Master Systems Architecture Patterns",
    description: "Learn and apply common architectural patterns in systems engineering",
    status: "in_progress",
    priority: "high",
    competency: "Architecture Design",
    progress: 65,
    dueDate: new Date('2024-10-15'),
    estimatedHours: 24,
    resources: ["Design Patterns Book", "Architecture Workshop", "Case Studies"],
    subObjectives: [
      { id: 1, title: "Study MVC Pattern", completed: true },
      { id: 2, title: "Implement Layered Architecture", completed: true },
      { id: 3, title: "Design Microservices Architecture", completed: false },
      { id: 4, title: "Create Architecture Documentation", completed: false }
    ]
  },
  {
    id: 2,
    title: "Requirements Elicitation Techniques",
    description: "Develop proficiency in various requirements gathering methods",
    status: "completed",
    priority: "medium",
    competency: "Requirements Engineering",
    progress: 100,
    dueDate: new Date('2024-09-30'),
    estimatedHours: 16,
    resources: ["Requirements Engineering Guide", "Interview Templates"],
    subObjectives: [
      { id: 1, title: "Learn Stakeholder Analysis", completed: true },
      { id: 2, title: "Practice Interview Techniques", completed: true },
      { id: 3, title: "Create Requirements Templates", completed: true }
    ]
  },
  {
    id: 3,
    title: "Verification and Validation Strategies",
    description: "Understand V&V processes and quality assurance methodologies",
    status: "pending",
    priority: "high",
    competency: "Verification & Validation",
    progress: 0,
    dueDate: new Date('2024-11-30'),
    estimatedHours: 32,
    resources: ["V&V Standards", "Testing Frameworks", "Quality Metrics"],
    subObjectives: [
      { id: 1, title: "Study V&V Standards", completed: false },
      { id: 2, title: "Design Test Strategies", completed: false },
      { id: 3, title: "Implement Quality Gates", completed: false }
    ]
  }
])

const filteredObjectives = computed(() => {
  return objectives.value.filter(objective => {
    const matchesStatus = !filters.value.status || objective.status === filters.value.status
    const matchesCompetency = !filters.value.competency ||
      objective.competency.toLowerCase().includes(filters.value.competency.toLowerCase())
    const matchesPriority = !filters.value.priority || objective.priority === filters.value.priority
    const matchesSearch = !filters.value.search ||
      objective.title.toLowerCase().includes(filters.value.search.toLowerCase()) ||
      objective.description.toLowerCase().includes(filters.value.search.toLowerCase())

    return matchesStatus && matchesCompetency && matchesPriority && matchesSearch
  })
})

const getStatusType = (status) => {
  const statusMap = {
    'active': 'success',
    'completed': 'success',
    'in_progress': 'warning',
    'pending': 'info'
  }
  return statusMap[status] || 'info'
}

const getPriorityType = (priority) => {
  const priorityMap = {
    'high': 'danger',
    'medium': 'warning',
    'low': 'info'
  }
  return priorityMap[priority] || 'info'
}

const getProgressColor = (percentage) => {
  if (percentage < 30) return '#f56c6c'
  if (percentage < 70) return '#e6a23c'
  return '#67c23a'
}

const formatDate = (date) => {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const updateSubObjective = (objectiveId, subObjectiveId, completed) => {
  const objective = objectives.value.find(o => o.id === objectiveId)
  if (objective) {
    const subObj = objective.subObjectives.find(s => s.id === subObjectiveId)
    if (subObj) {
      subObj.completed = completed
      // Update overall progress based on completed sub-objectives
      const completedCount = objective.subObjectives.filter(s => s.completed).length
      objective.progress = Math.round((completedCount / objective.subObjectives.length) * 100)

      // Update status if all sub-objectives are completed
      if (completedCount === objective.subObjectives.length) {
        objective.status = 'completed'
      } else if (completedCount > 0) {
        objective.status = 'in_progress'
      }
    }
  }
}

const startObjective = (objectiveId) => {
  const objective = objectives.value.find(o => o.id === objectiveId)
  if (objective) {
    objective.status = 'in_progress'
  }
}

const continueObjective = (objectiveId) => {
  // Navigate to learning resources or next step
  router.push(`/app/learning/objectives/${objectiveId}`)
}

const reviewObjective = (objectiveId) => {
  // Navigate to objective review interface
  router.push(`/app/learning/objectives/${objectiveId}/review`)
}

const editObjective = (objectiveId) => {
  // Navigate to objective editing interface
  router.push(`/app/objectives/${objectiveId}/edit`)
}

const deleteObjective = (objectiveId) => {
  objectives.value = objectives.value.filter(o => o.id !== objectiveId)
}
</script>

<style scoped>
.learning-objectives {
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

.objectives-container {
  max-width: 1200px;
  margin: 0 auto;
}

.filters-card {
  margin-bottom: 24px;
}

.objectives-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.objective-card {
  height: fit-content;
}

.objective-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.objective-title h3 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 18px;
}

.objective-meta {
  display: flex;
  gap: 8px;
}

.objective-description {
  color: #606266;
  margin-bottom: 16px;
  line-height: 1.5;
}

.objective-details {
  margin-bottom: 16px;
}

.detail-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  color: #909399;
  font-size: 14px;
}

.resources-section, .sub-objectives {
  margin-bottom: 16px;
}

.resources-section h4, .sub-objectives h4 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 14px;
  font-weight: 600;
}

.resources-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.resource-tag {
  background: #f0f9ff;
  border-color: #409eff;
}

.sub-objectives-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sub-objective-item {
  font-size: 14px;
}

.objective-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
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