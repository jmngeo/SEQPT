<template>
  <div class="derik-role-selector">
    <h2 class="section-title">Role-Based Assessment</h2>
    <p class="section-description">Select the SE roles that best match your current or target position</p>

    <div v-if="loading" class="loading-container">
      <el-loading element-loading-text="Loading roles..." />
    </div>

    <div v-else class="roles-grid">
      <div
        v-for="role in roles"
        :key="role.id"
        class="role-card"
        :class="{ 'role-card-selected': isRoleSelected(role.id) }"
        @click="toggleRoleSelection(role)"
      >
        <div class="card-header">
          <div class="role-title">
            {{ role.name }}
            <el-icon v-if="isRoleSelected(role.id)" class="check-icon">
              <Check />
            </el-icon>
          </div>
        </div>
        <div class="role-description">
          {{ role.description }}
        </div>
      </div>

      <!-- Task-based alternative card -->
      <div
        class="task-card"
        @click="$emit('switchToTaskBased')"
      >
        <div class="task-card-title">Can't Find Your Role?</div>
        <div class="task-card-text">
          Let our <span class="ai-highlight">AI</span> model map you to the most appropriate role based on your tasks and responsibilities.
        </div>
      </div>
    </div>

    <!-- Selected roles display -->
    <div v-if="selectedRoles.length > 0" class="selected-roles-section">
      <h3>Selected Roles</h3>
      <div class="selected-roles-list">
        <el-tag
          v-for="role in selectedRoles"
          :key="role.id"
          type="success"
          closable
          @close="removeRole(role.id)"
          class="role-tag"
        >
          {{ role.name }}
        </el-tag>
      </div>
    </div>

    <div class="actions">
      <el-button
        type="primary"
        :disabled="selectedRoles.length === 0"
        @click="proceedToAssessment"
        size="large"
      >
        Proceed to Competency Assessment ({{ selectedRoles.length }} role{{ selectedRoles.length === 1 ? '' : 's' }} selected)
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Check } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const emit = defineEmits(['rolesSelected', 'switchToTaskBased'])

// State
const roles = ref([])
const selectedRoles = ref([])
const loading = ref(false)

// Methods
const loadRoles = async () => {
  loading.value = true
  try {
    const response = await fetch('/api/competency/public/roles')
    if (response.ok) {
      const data = await response.json()
      roles.value = data.roles || []
      console.log('Loaded roles:', roles.value.length)
    } else {
      throw new Error('Failed to fetch roles')
    }
  } catch (error) {
    console.error('Failed to load roles:', error)
    ElMessage.error('Failed to load SE roles. Please try again.')
  } finally {
    loading.value = false
  }
}

const isRoleSelected = (roleId) => {
  return selectedRoles.value.some(role => role.id === roleId)
}

const toggleRoleSelection = (role) => {
  const index = selectedRoles.value.findIndex(selectedRole => selectedRole.id === role.id)

  if (index === -1) {
    // Add role
    selectedRoles.value.push({
      id: role.id,
      name: role.name,
      description: role.description
    })
  } else {
    // Remove role
    selectedRoles.value.splice(index, 1)
  }
}

const removeRole = (roleId) => {
  const index = selectedRoles.value.findIndex(role => role.id === roleId)
  if (index !== -1) {
    selectedRoles.value.splice(index, 1)
  }
}

const proceedToAssessment = () => {
  if (selectedRoles.value.length === 0) {
    ElMessage.warning('Please select at least one role to proceed.')
    return
  }

  emit('rolesSelected', {
    type: 'role-based',
    roles: selectedRoles.value
  })
}

// Lifecycle
onMounted(() => {
  loadRoles()
})
</script>

<style scoped>
.derik-role-selector {
  padding: 20px;
}

.section-title {
  font-size: 1.8rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
}

.section-description {
  color: #6c7b7f;
  margin-bottom: 30px;
  font-size: 1.1rem;
}

.loading-container {
  min-height: 200px;
  position: relative;
}

.roles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.role-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  overflow: hidden;
  border: 2px solid transparent;
}

.role-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.role-card-selected {
  border-color: #67c23a;
  box-shadow: 0 4px 16px rgba(103, 194, 58, 0.3);
}

.card-header {
  background: linear-gradient(135deg, #409eff, #3788d8);
  color: white;
  padding: 16px;
  position: relative;
}

.role-card-selected .card-header {
  background: linear-gradient(135deg, #67c23a, #5daf34);
}

.role-title {
  font-weight: 600;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.check-icon {
  font-size: 1.5rem;
}

.role-description {
  padding: 16px;
  color: #5c6b75;
  line-height: 1.6;
  font-size: 0.95rem;
}

.task-card {
  background: linear-gradient(135deg, #f0f9ff, #e0f2fe);
  border: 2px dashed #67c23a;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-height: 200px;
}

.task-card:hover {
  background: linear-gradient(135deg, #e6f7ff, #bae7ff);
  transform: translateY(-2px);
}

.task-card-title {
  font-weight: 600;
  font-size: 1.3rem;
  color: #1890ff;
  margin-bottom: 12px;
}

.task-card-text {
  color: #5c6b75;
  line-height: 1.6;
}

.ai-highlight {
  color: #f56c6c;
  font-weight: 600;
}

.selected-roles-section {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 30px;
}

.selected-roles-section h3 {
  margin: 0 0 15px 0;
  color: #2c3e50;
  font-size: 1.2rem;
}

.selected-roles-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.role-tag {
  font-size: 0.95rem;
  padding: 8px 12px;
}

.actions {
  text-align: center;
}
</style>