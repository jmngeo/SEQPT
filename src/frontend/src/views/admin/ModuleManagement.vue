<template>
  <div class="module-management">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Folder /></el-icon> Module Management</h1>
        <p>Manage learning modules, content, and qualification pathways</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateModule = true">
          <el-icon><Plus /></el-icon>
          Create Module
        </el-button>
        <el-button @click="importModules">
          <el-icon><Upload /></el-icon>
          Import
        </el-button>
      </div>
    </div>

    <div class="management-container">
      <!-- Module Statistics -->
      <div class="module-stats">
        <el-row :gutter="24">
          <el-col :span="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon modules">
                  <el-icon size="24"><Folder /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-value">{{ moduleStats.total }}</div>
                  <div class="stat-label">Total Modules</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon active">
                  <el-icon size="24"><VideoPlay /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-value">{{ moduleStats.active }}</div>
                  <div class="stat-label">Active Modules</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon enrollments">
                  <el-icon size="24"><User /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-value">{{ moduleStats.enrollments }}</div>
                  <div class="stat-label">Total Enrollments</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon completion">
                  <el-icon size="24"><SuccessFilled /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-value">{{ moduleStats.completionRate }}%</div>
                  <div class="stat-label">Completion Rate</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- Filters and Search -->
      <el-card class="filters-card">
        <el-row :gutter="20">
          <el-col :span="6">
            <el-select v-model="filters.category" placeholder="Filter by Category" clearable>
              <el-option label="All Categories" value=""></el-option>
              <el-option label="Systems Thinking" value="systems_thinking"></el-option>
              <el-option label="Requirements" value="requirements"></el-option>
              <el-option label="Architecture" value="architecture"></el-option>
              <el-option label="Verification" value="verification"></el-option>
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-select v-model="filters.level" placeholder="Filter by Level" clearable>
              <el-option label="All Levels" value=""></el-option>
              <el-option label="Beginner" value="beginner"></el-option>
              <el-option label="Intermediate" value="intermediate"></el-option>
              <el-option label="Advanced" value="advanced"></el-option>
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-select v-model="filters.status" placeholder="Filter by Status" clearable>
              <el-option label="All Status" value=""></el-option>
              <el-option label="Active" value="active"></el-option>
              <el-option label="Draft" value="draft"></el-option>
              <el-option label="Archived" value="archived"></el-option>
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-input
              v-model="filters.search"
              placeholder="Search modules..."
              prefix-icon="Search"
              clearable
            ></el-input>
          </el-col>
        </el-row>
      </el-card>

      <!-- Modules Table -->
      <el-card class="modules-table-card">
        <el-table :data="filteredModules" style="width: 100%" stripe>
          <el-table-column prop="title" label="Module" width="300">
            <template #default="scope">
              <div class="module-info">
                <div class="module-title">{{ scope.row.title }}</div>
                <div class="module-description">{{ scope.row.description }}</div>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="category" label="Category" width="150">
            <template #default="scope">
              <el-tag :type="getCategoryType(scope.row.category)" size="small">
                {{ scope.row.category }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="level" label="Level" width="120">
            <template #default="scope">
              <el-tag :type="getLevelType(scope.row.level)" size="small">
                {{ scope.row.level }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="duration" label="Duration" width="100" align="center">
            <template #default="scope">
              {{ scope.row.duration }}h
            </template>
          </el-table-column>

          <el-table-column prop="enrollments" label="Enrollments" width="120" align="center" />

          <el-table-column prop="rating" label="Rating" width="120" align="center">
            <template #default="scope">
              <el-rate :model-value="scope.row.rating" disabled show-score />
            </template>
          </el-table-column>

          <el-table-column prop="status" label="Status" width="100">
            <template #default="scope">
              <el-tag :type="getStatusType(scope.row.status)" size="small">
                {{ scope.row.status }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column label="Actions" width="200">
            <template #default="scope">
              <el-button size="small" @click="editModule(scope.row)">
                Edit
              </el-button>
              <el-button size="small" @click="viewModule(scope.row)">
                View
              </el-button>
              <el-button size="small" type="danger" @click="deleteModule(scope.row)">
                Delete
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-wrapper">
          <el-pagination
            v-model:current-page="currentPage"
            :page-size="pageSize"
            :total="filteredModules.length"
            layout="prev, pager, next, jumper, total"
          />
        </div>
      </el-card>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced Module Management</h2>
          <p>Comprehensive learning module management system for the SE-QPT platform.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Interactive content creation and editing tools</li>
              <li>Learning path dependency management</li>
              <li>Adaptive module sequencing algorithms</li>
              <li>Content analytics and effectiveness tracking</li>
              <li>Multi-media content support and management</li>
              <li>Collaborative module development workflows</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>

    <!-- Create Module Dialog -->
    <el-dialog v-model="showCreateModule" title="Create Learning Module" width="700px">
      <el-form :model="moduleForm" label-width="150px">
        <el-form-item label="Title" required>
          <el-input v-model="moduleForm.title" />
        </el-form-item>
        <el-form-item label="Description" required>
          <el-input v-model="moduleForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="Category" required>
          <el-select v-model="moduleForm.category" placeholder="Select category">
            <el-option label="Systems Thinking" value="systems_thinking"></el-option>
            <el-option label="Requirements" value="requirements"></el-option>
            <el-option label="Architecture" value="architecture"></el-option>
            <el-option label="Verification" value="verification"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Level" required>
          <el-select v-model="moduleForm.level" placeholder="Select level">
            <el-option label="Beginner" value="beginner"></el-option>
            <el-option label="Intermediate" value="intermediate"></el-option>
            <el-option label="Advanced" value="advanced"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Duration (hours)">
          <el-input-number v-model="moduleForm.duration" :min="1" :max="100" />
        </el-form-item>
        <el-form-item label="Prerequisites">
          <el-select v-model="moduleForm.prerequisites" multiple placeholder="Select prerequisites">
            <el-option label="Basic Systems Knowledge" value="basic_systems"></el-option>
            <el-option label="Engineering Fundamentals" value="engineering_basics"></el-option>
            <el-option label="Project Management" value="project_mgmt"></el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateModule = false">Cancel</el-button>
        <el-button type="primary" @click="createModule">Create Module</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Folder, Plus, Upload, VideoPlay, User, SuccessFilled, Search
} from '@element-plus/icons-vue'

const showCreateModule = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)

const filters = ref({
  category: '',
  level: '',
  status: '',
  search: ''
})

const moduleForm = ref({
  title: '',
  description: '',
  category: '',
  level: '',
  duration: 8,
  prerequisites: []
})

const moduleStats = ref({
  total: 45,
  active: 38,
  enrollments: 1247,
  completionRate: 78
})

// Sample modules data
const modules = ref([
  {
    id: 1,
    title: 'Systems Thinking Fundamentals',
    description: 'Introduction to systems thinking principles and methodologies',
    category: 'systems_thinking',
    level: 'beginner',
    duration: 12,
    enrollments: 156,
    rating: 4.5,
    status: 'active'
  },
  {
    id: 2,
    title: 'Advanced Requirements Engineering',
    description: 'Comprehensive requirements analysis and management techniques',
    category: 'requirements',
    level: 'advanced',
    duration: 18,
    enrollments: 89,
    rating: 4.7,
    status: 'active'
  },
  {
    id: 3,
    title: 'System Architecture Patterns',
    description: 'Common architectural patterns in systems engineering',
    category: 'architecture',
    level: 'intermediate',
    duration: 15,
    enrollments: 123,
    rating: 4.3,
    status: 'active'
  },
  {
    id: 4,
    title: 'Verification and Validation Strategies',
    description: 'V&V processes and quality assurance methodologies',
    category: 'verification',
    level: 'intermediate',
    duration: 14,
    enrollments: 67,
    rating: 4.1,
    status: 'draft'
  }
])

const filteredModules = computed(() => {
  return modules.value.filter(module => {
    const matchesCategory = !filters.value.category || module.category === filters.value.category
    const matchesLevel = !filters.value.level || module.level === filters.value.level
    const matchesStatus = !filters.value.status || module.status === filters.value.status
    const matchesSearch = !filters.value.search ||
      module.title.toLowerCase().includes(filters.value.search.toLowerCase()) ||
      module.description.toLowerCase().includes(filters.value.search.toLowerCase())

    return matchesCategory && matchesLevel && matchesStatus && matchesSearch
  })
})

const getCategoryType = (category) => {
  const categoryMap = {
    'systems_thinking': 'primary',
    'requirements': 'success',
    'architecture': 'warning',
    'verification': 'info'
  }
  return categoryMap[category] || 'info'
}

const getLevelType = (level) => {
  const levelMap = {
    'beginner': 'success',
    'intermediate': 'warning',
    'advanced': 'danger'
  }
  return levelMap[level] || 'info'
}

const getStatusType = (status) => {
  const statusMap = {
    'active': 'success',
    'draft': 'warning',
    'archived': 'info'
  }
  return statusMap[status] || 'info'
}

const editModule = (module) => {
  console.log('Edit module:', module)
}

const viewModule = (module) => {
  console.log('View module:', module)
}

const deleteModule = async (module) => {
  try {
    await ElMessageBox.confirm(
      'This will permanently delete the module. Continue?',
      'Delete Module',
      {
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    const index = modules.value.findIndex(m => m.id === module.id)
    if (index > -1) {
      modules.value.splice(index, 1)
      ElMessage.success('Module deleted successfully')
    }
  } catch {
    // User cancelled
  }
}

const createModule = () => {
  // Validate and create module
  const newModule = {
    id: modules.value.length + 1,
    ...moduleForm.value,
    enrollments: 0,
    rating: 0,
    status: 'draft'
  }

  modules.value.push(newModule)
  showCreateModule.value = false
  
  // Reset form
  moduleForm.value = {
    title: '',
    description: '',
    category: '',
    level: '',
    duration: 8,
    prerequisites: []
  }

  ElMessage.success('Module created successfully')
}

const importModules = () => {
  ElMessage.info('Module import functionality will be available soon')
}
</script>

<style scoped>
.module-management {
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

.management-container {
  max-width: 1400px;
  margin: 0 auto;
}

.module-stats {
  margin-bottom: 24px;
}

.stat-card {
  height: 100px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
  height: 100%;
}

.stat-icon {
  width: 50px;
  height: 50px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.stat-icon.modules {
  background: #409eff;
}

.stat-icon.active {
  background: #67c23a;
}

.stat-icon.enrollments {
  background: #e6a23c;
}

.stat-icon.completion {
  background: #f56c6c;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
}

.stat-label {
  color: #606266;
  font-size: 14px;
}

.filters-card {
  margin-bottom: 24px;
}

.modules-table-card {
  margin-bottom: 32px;
}

.module-info {
  display: flex;
  flex-direction: column;
}

.module-title {
  font-weight: 600;
  color: #303133;
}

.module-description {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.pagination-wrapper {
  margin-top: 20px;
  text-align: center;
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