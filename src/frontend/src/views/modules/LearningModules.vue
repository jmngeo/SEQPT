<template>
  <div class="learning-modules">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Reading /></el-icon> Learning Modules</h1>
        <p>Explore and enroll in SE competency learning modules tailored to your needs</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="getRecommendations" :loading="loadingRecommendations">
          <el-icon><MagicStick /></el-icon>
          Get Recommendations
        </el-button>
        <el-button @click="viewEnrollments">
          <el-icon><User /></el-icon>
          My Enrollments
        </el-button>
      </div>
    </div>

    <!-- Filter and Search Section -->
    <div class="filter-section">
      <el-card class="filter-card">
        <div class="filters-row">
          <el-input
            v-model="searchQuery"
            placeholder="Search modules..."
            prefix-icon="Search"
            @input="handleSearch"
            class="search-input"
          />

          <el-select
            v-model="selectedCategory"
            placeholder="Category"
            clearable
            @change="loadModules"
            class="filter-select"
          >
            <el-option label="All Categories" value="" />
            <el-option label="Core Competencies" value="Core Competencies" />
            <el-option label="Professional Skills" value="Professional Skills" />
            <el-option label="Social and Self-Competencies" value="Social and Self-Competencies" />
            <el-option label="Management Competencies" value="Management Competencies" />
          </el-select>

          <el-select
            v-model="selectedDifficulty"
            placeholder="Difficulty"
            clearable
            @change="loadModules"
            class="filter-select"
          >
            <el-option label="All Levels" value="" />
            <el-option label="Beginner" value="beginner" />
            <el-option label="Intermediate" value="intermediate" />
            <el-option label="Advanced" value="advanced" />
          </el-select>

          <el-button @click="resetFilters" icon="Refresh">
            Reset
          </el-button>
        </div>
      </el-card>
    </div>

    <!-- Recommended Modules Section -->
    <div v-if="recommendations.length > 0" class="recommendations-section">
      <el-card class="recommendations-card">
        <template #header>
          <div class="section-header">
            <h2><el-icon><Star /></el-icon> Recommended for You</h2>
            <p>Based on your competency assessment results</p>
          </div>
        </template>

        <div class="modules-grid">
          <ModuleCard
            v-for="module in recommendations"
            :key="module.id"
            :module="module"
            :is-recommended="true"
            @enroll="handleEnroll"
            @view-details="handleViewDetails"
          />
        </div>
      </el-card>
    </div>

    <!-- All Modules Section -->
    <div class="modules-section">
      <el-card class="modules-card">
        <template #header>
          <div class="section-header">
            <h2><el-icon><Notebook /></el-icon> All Learning Modules</h2>
            <div class="module-stats">
              <span>{{ filteredModules.length }} modules found</span>
              <span v-if="searchQuery || selectedCategory || selectedDifficulty">
                ({{ modules.length }} total)
              </span>
            </div>
          </div>
        </template>

        <!-- Loading State -->
        <div v-if="loading" class="loading-container">
          <el-skeleton :rows="6" animated />
        </div>

        <!-- Modules Grid -->
        <div v-else-if="filteredModules.length > 0" class="modules-grid">
          <ModuleCard
            v-for="module in paginatedModules"
            :key="module.id"
            :module="module"
            @enroll="handleEnroll"
            @view-details="handleViewDetails"
          />
        </div>

        <!-- Empty State -->
        <el-empty
          v-else
          description="No modules found"
          image-size="120"
        >
          <el-button type="primary" @click="resetFilters">
            Clear Filters
          </el-button>
        </el-empty>

        <!-- Pagination -->
        <div v-if="filteredModules.length > pageSize" class="pagination-container">
          <el-pagination
            v-model:current-page="currentPage"
            :page-size="pageSize"
            :total="filteredModules.length"
            layout="prev, pager, next, jumper, total"
            @current-change="handlePageChange"
          />
        </div>
      </el-card>
    </div>

    <!-- Module Details Dialog -->
    <ModuleDetailsDialog
      v-model:visible="showDetailsDialog"
      :module="selectedModule"
      @enroll="handleEnroll"
      @close="selectedModule = null"
    />

    <!-- Error State -->
    <el-alert
      v-if="error"
      :title="error"
      type="error"
      show-icon
      :closable="true"
      @close="error = ''"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Reading, MagicStick, User, Star, Notebook, Search, Refresh } from '@element-plus/icons-vue'
import { assessmentApi } from '@/api/assessment'
import ModuleCard from '@/components/modules/ModuleCard.vue'
import ModuleDetailsDialog from '@/components/modules/ModuleDetailsDialog.vue'

const router = useRouter()

// Reactive data
const modules = ref([])
const recommendations = ref([])
const selectedModule = ref(null)
const searchQuery = ref('')
const selectedCategory = ref('')
const selectedDifficulty = ref('')
const currentPage = ref(1)
const pageSize = ref(12)
const loading = ref(false)
const loadingRecommendations = ref(false)
const showDetailsDialog = ref(false)
const error = ref('')

// Computed properties
const filteredModules = computed(() => {
  let filtered = [...modules.value]

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(module =>
      module.name.toLowerCase().includes(query) ||
      module.definition.toLowerCase().includes(query) ||
      module.competency?.name.toLowerCase().includes(query)
    )
  }

  if (selectedCategory.value) {
    filtered = filtered.filter(module => module.category === selectedCategory.value)
  }

  if (selectedDifficulty.value) {
    filtered = filtered.filter(module => module.difficulty_level === selectedDifficulty.value)
  }

  return filtered
})

const paginatedModules = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredModules.value.slice(start, end)
})

// Methods
const loadModules = async () => {
  try {
    loading.value = true
    const params = {}
    if (selectedCategory.value) params.category = selectedCategory.value
    if (selectedDifficulty.value) params.difficulty = selectedDifficulty.value

    const response = await assessmentApi.getLearningModules(params)
    modules.value = response.data.modules
  } catch (err) {
    error.value = 'Failed to load learning modules'
    ElMessage.error('Failed to load learning modules')
  } finally {
    loading.value = false
  }
}

const getRecommendations = async () => {
  try {
    loadingRecommendations.value = true
    const response = await assessmentApi.getModuleRecommendations()

    if (response.data.recommendations) {
      recommendations.value = response.data.recommendations
      ElMessage.success('Recommendations updated based on your competency profile!')
    } else {
      ElMessage.info('Complete a competency assessment to get personalized recommendations')
    }
  } catch (err) {
    if (err.response?.status === 404) {
      ElMessage.info('Complete a competency assessment first to get personalized recommendations')
    } else {
      ElMessage.error('Failed to get recommendations')
    }
  } finally {
    loadingRecommendations.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
}

const resetFilters = () => {
  searchQuery.value = ''
  selectedCategory.value = ''
  selectedDifficulty.value = ''
  currentPage.value = 1
  loadModules()
}

const handleEnroll = async (module) => {
  try {
    const enrollmentData = {
      target_level: 3, // Default to competent level
      learning_priority: 'medium',
      completion_timeline_weeks: 12
    }

    await assessmentApi.enrollInModule(module.module_code, enrollmentData)
    ElMessage.success(`Successfully enrolled in ${module.name}!`)
  } catch (err) {
    if (err.response?.status === 409) {
      ElMessage.warning('You are already enrolled in this module')
    } else {
      ElMessage.error('Failed to enroll in module')
    }
  }
}

const handleViewDetails = (module) => {
  selectedModule.value = module
  showDetailsDialog.value = true
}

const viewEnrollments = () => {
  router.push('/app/modules/enrollments')
}

const handlePageChange = (page) => {
  currentPage.value = page
  // Scroll to top of modules section
  document.querySelector('.modules-section').scrollIntoView({ behavior: 'smooth' })
}

// Lifecycle
onMounted(() => {
  loadModules()
})
</script>

<style scoped>
.learning-modules {
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

.header-actions {
  display: flex;
  gap: 12px;
}

.filter-section {
  margin-bottom: 24px;
}

.filter-card {
  border: none;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.filters-row {
  display: flex;
  gap: 16px;
  align-items: center;
  flex-wrap: wrap;
}

.search-input {
  flex: 1;
  min-width: 200px;
}

.filter-select {
  min-width: 150px;
}

.recommendations-section {
  margin-bottom: 32px;
}

.recommendations-card {
  border: 2px solid #409eff;
  background: linear-gradient(135deg, #f0f9ff 0%, #ffffff 100%);
}

.modules-section {
  margin-bottom: 24px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.section-header h2 {
  margin: 0;
  color: #303133;
  font-size: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-header p {
  margin: 4px 0 0 0;
  color: #606266;
  font-size: 14px;
}

.module-stats {
  color: #909399;
  font-size: 14px;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 24px;
  margin-top: 24px;
}

.loading-container {
  padding: 40px;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e4e7ed;
}

@media (max-width: 768px) {
  .learning-modules {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    gap: 16px;
    text-align: center;
  }

  .header-actions {
    width: 100%;
    justify-content: center;
  }

  .filters-row {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input,
  .filter-select {
    min-width: auto;
  }

  .section-header {
    flex-direction: column;
    text-align: center;
    gap: 8px;
  }

  .modules-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
}
</style>