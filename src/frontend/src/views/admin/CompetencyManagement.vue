<template>
  <div class="competency-management">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Cpu /></el-icon> Competency Management</h1>
        <p>Manage competency frameworks, indicators, and assessment criteria</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateCompetency = true">
          <el-icon><Plus /></el-icon>
          Add Competency
        </el-button>
        <el-button @click="importFramework">
          <el-icon><Upload /></el-icon>
          Import Framework
        </el-button>
      </div>
    </div>

    <div class="management-container">
      <!-- Competency Framework Overview -->
      <el-card class="framework-overview">
        <div class="card-header">
          <h2><el-icon><Collection /></el-icon> Competency Framework</h2>
          <el-select v-model="selectedFramework" placeholder="Select Framework">
            <el-option label="SE-QPT Core Framework" value="core"></el-option>
            <el-option label="INCOSE Framework" value="incose"></el-option>
            <el-option label="Custom Framework" value="custom"></el-option>
          </el-select>
        </div>

        <div class="framework-stats">
          <div class="stat-item">
            <div class="stat-value">{{ frameworkStats.totalCompetencies }}</div>
            <div class="stat-label">Total Competencies</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ frameworkStats.indicators }}</div>
            <div class="stat-label">Performance Indicators</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ frameworkStats.assessments }}</div>
            <div class="stat-label">Linked Assessments</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ frameworkStats.activeUsers }}</div>
            <div class="stat-label">Active Users</div>
          </div>
        </div>
      </el-card>

      <!-- Competencies List -->
      <el-card class="competencies-card">
        <div class="card-header">
          <h2>Competencies</h2>
          <div class="header-actions">
            <el-input
              v-model="searchQuery"
              placeholder="Search competencies..."
              prefix-icon="Search"
              style="width: 250px;"
              clearable
            />
          </div>
        </div>

        <div class="competencies-tree">
          <el-tree
            :data="filteredCompetencies"
            :props="treeProps"
            node-key="id"
            :default-expand-all="true"
            class="competency-tree"
          >
            <template #default="{ node, data }">
              <div class="tree-node">
                <div class="node-content">
                  <div class="node-info">
                    <span class="node-title">{{ data.name }}</span>
                    <span class="node-description">{{ data.description }}</span>
                  </div>
                  <div class="node-meta">
                    <el-tag v-if="data.level" size="small" :type="getLevelType(data.level)">
                      Level {{ data.level }}
                    </el-tag>
                    <el-tag v-if="data.indicators" size="small" type="info">
                      {{ data.indicators }} indicators
                    </el-tag>
                  </div>
                </div>
                <div class="node-actions">
                  <el-button size="small" text @click="editCompetency(data)">
                    <el-icon><Edit /></el-icon>
                  </el-button>
                  <el-button size="small" text @click="viewIndicators(data)">
                    <el-icon><View /></el-icon>
                  </el-button>
                  <el-button size="small" text type="danger" @click="deleteCompetency(data)">
                    <el-icon><Delete /></el-icon>
                  </el-button>
                </div>
              </div>
            </template>
          </el-tree>
        </div>
      </el-card>

      <!-- Performance Indicators -->
      <el-card class="indicators-card">
        <div class="card-header">
          <h2><el-icon><DocumentChecked /></el-icon> Performance Indicators</h2>
          <el-button @click="showCreateIndicator = true">
            <el-icon><Plus /></el-icon>
            Add Indicator
          </el-button>
        </div>

        <el-table :data="performanceIndicators" style="width: 100%" stripe>
          <el-table-column prop="name" label="Indicator" width="300">
            <template #default="scope">
              <div class="indicator-info">
                <div class="indicator-name">{{ scope.row.name }}</div>
                <div class="indicator-description">{{ scope.row.description }}</div>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="competency" label="Competency" width="200" />

          <el-table-column prop="level" label="Level" width="100" align="center">
            <template #default="scope">
              <el-tag :type="getLevelType(scope.row.level)" size="small">
                Level {{ scope.row.level }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="weight" label="Weight" width="100" align="center">
            <template #default="scope">
              {{ scope.row.weight }}%
            </template>
          </el-table-column>

          <el-table-column prop="assessments" label="Assessments" width="120" align="center" />

          <el-table-column label="Actions" width="150">
            <template #default="scope">
              <el-button size="small" @click="editIndicator(scope.row)">
                Edit
              </el-button>
              <el-button size="small" type="danger" @click="deleteIndicator(scope.row)">
                Delete
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-card>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced Competency Management</h2>
          <p>Comprehensive competency framework management for the SE-QPT platform.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Dynamic competency framework creation and editing</li>
              <li>AI-powered competency gap analysis</li>
              <li>Industry-standard framework integration (INCOSE, IEEE)</li>
              <li>Competency progression pathway mapping</li>
              <li>Real-time competency assessment calibration</li>
              <li>Collaborative framework development tools</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>

    <!-- Create Competency Dialog -->
    <el-dialog v-model="showCreateCompetency" title="Create Competency" width="600px">
      <el-form :model="competencyForm" label-width="150px">
        <el-form-item label="Name" required>
          <el-input v-model="competencyForm.name" />
        </el-form-item>
        <el-form-item label="Description" required>
          <el-input v-model="competencyForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="Category">
          <el-select v-model="competencyForm.category" placeholder="Select category">
            <el-option label="Technical" value="technical"></el-option>
            <el-option label="Management" value="management"></el-option>
            <el-option label="Communication" value="communication"></el-option>
            <el-option label="Leadership" value="leadership"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Max Level">
          <el-input-number v-model="competencyForm.maxLevel" :min="1" :max="5" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateCompetency = false">Cancel</el-button>
        <el-button type="primary" @click="createCompetency">Create</el-button>
      </template>
    </el-dialog>

    <!-- Create Indicator Dialog -->
    <el-dialog v-model="showCreateIndicator" title="Create Performance Indicator" width="600px">
      <el-form :model="indicatorForm" label-width="150px">
        <el-form-item label="Name" required>
          <el-input v-model="indicatorForm.name" />
        </el-form-item>
        <el-form-item label="Description" required>
          <el-input v-model="indicatorForm.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="Competency" required>
          <el-select v-model="indicatorForm.competency" placeholder="Select competency">
            <el-option label="Systems Thinking" value="systems_thinking"></el-option>
            <el-option label="Requirements Engineering" value="requirements"></el-option>
            <el-option label="System Architecture" value="architecture"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Level">
          <el-input-number v-model="indicatorForm.level" :min="1" :max="5" />
        </el-form-item>
        <el-form-item label="Weight (%)">
          <el-input-number v-model="indicatorForm.weight" :min="0" :max="100" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateIndicator = false">Cancel</el-button>
        <el-button type="primary" @click="createIndicator">Create</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Cpu, Plus, Upload, Collection, DocumentChecked, Edit, View, Delete, Search
} from '@element-plus/icons-vue'

const selectedFramework = ref('core')
const searchQuery = ref('')
const showCreateCompetency = ref(false)
const showCreateIndicator = ref(false)

const frameworkStats = ref({
  totalCompetencies: 12,
  indicators: 48,
  assessments: 15,
  activeUsers: 347
})

const competencyForm = ref({
  name: '',
  description: '',
  category: '',
  maxLevel: 5
})

const indicatorForm = ref({
  name: '',
  description: '',
  competency: '',
  level: 1,
  weight: 20
})

const treeProps = {
  children: 'children',
  label: 'name'
}

// Sample competencies data
const competencies = ref([
  {
    id: 1,
    name: 'Systems Thinking',
    description: 'Holistic understanding of complex systems',
    category: 'technical',
    level: 5,
    indicators: 8,
    children: [
      {
        id: 11,
        name: 'System Holism',
        description: 'Understanding systems as integrated wholes',
        level: 3,
        indicators: 3
      },
      {
        id: 12,
        name: 'Emergence Recognition',
        description: 'Identifying emergent properties in systems',
        level: 4,
        indicators: 2
      }
    ]
  },
  {
    id: 2,
    name: 'Requirements Engineering',
    description: 'Requirements analysis and management',
    category: 'technical',
    level: 5,
    indicators: 12,
    children: [
      {
        id: 21,
        name: 'Requirements Elicitation',
        description: 'Gathering requirements from stakeholders',
        level: 3,
        indicators: 4
      },
      {
        id: 22,
        name: 'Requirements Analysis',
        description: 'Analyzing and refining requirements',
        level: 4,
        indicators: 5
      }
    ]
  }
])

const performanceIndicators = ref([
  {
    id: 1,
    name: 'System Boundary Definition',
    description: 'Ability to clearly define system boundaries',
    competency: 'Systems Thinking',
    level: 2,
    weight: 25,
    assessments: 3
  },
  {
    id: 2,
    name: 'Stakeholder Identification',
    description: 'Identifies all relevant stakeholders',
    competency: 'Requirements Engineering',
    level: 1,
    weight: 30,
    assessments: 5
  },
  {
    id: 3,
    name: 'Interface Analysis',
    description: 'Analyzes system interfaces comprehensively',
    competency: 'System Architecture',
    level: 3,
    weight: 20,
    assessments: 2
  }
])

const filteredCompetencies = computed(() => {
  if (!searchQuery.value) return competencies.value
  
  return competencies.value.filter(comp => 
    comp.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    comp.description.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const getLevelType = (level) => {
  const levelMap = {
    1: 'info',
    2: 'success',
    3: 'warning',
    4: 'primary',
    5: 'danger'
  }
  return levelMap[level] || 'info'
}

const editCompetency = (competency) => {
  console.log('Edit competency:', competency)
}

const viewIndicators = (competency) => {
  console.log('View indicators for:', competency)
}

const deleteCompetency = async (competency) => {
  try {
    await ElMessageBox.confirm(
      'This will permanently delete the competency. Continue?',
      'Delete Competency',
      {
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )
    ElMessage.success('Competency deleted successfully')
  } catch {
    // User cancelled
  }
}

const editIndicator = (indicator) => {
  console.log('Edit indicator:', indicator)
}

const deleteIndicator = async (indicator) => {
  try {
    await ElMessageBox.confirm(
      'This will permanently delete the performance indicator. Continue?',
      'Delete Indicator',
      {
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )
    ElMessage.success('Indicator deleted successfully')
  } catch {
    // User cancelled
  }
}

const createCompetency = () => {
  // Validate and create competency
  ElMessage.success('Competency created successfully')
  showCreateCompetency.value = false
  // Reset form
  competencyForm.value = {
    name: '',
    description: '',
    category: '',
    maxLevel: 5
  }
}

const createIndicator = () => {
  // Validate and create indicator
  ElMessage.success('Performance indicator created successfully')
  showCreateIndicator.value = false
  // Reset form
  indicatorForm.value = {
    name: '',
    description: '',
    competency: '',
    level: 1,
    weight: 20
  }
}

const importFramework = () => {
  ElMessage.info('Framework import functionality will be available soon')
}
</script>

<style scoped>
.competency-management {
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

.framework-overview {
  margin-bottom: 24px;
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
}

.framework-stats {
  display: flex;
  justify-content: space-around;
  text-align: center;
}

.stat-item .stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #409eff;
}

.stat-item .stat-label {
  color: #606266;
  font-size: 14px;
}

.competencies-card {
  margin-bottom: 24px;
}

.tree-node {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 8px 0;
}

.node-content {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.node-info {
  display: flex;
  flex-direction: column;
}

.node-title {
  font-weight: 600;
  color: #303133;
}

.node-description {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.node-meta {
  display: flex;
  gap: 8px;
}

.node-actions {
  display: flex;
  gap: 4px;
  margin-left: 16px;
}

.indicators-card {
  margin-bottom: 32px;
}

.indicator-info {
  display: flex;
  flex-direction: column;
}

.indicator-name {
  font-weight: 600;
  color: #303133;
}

.indicator-description {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
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