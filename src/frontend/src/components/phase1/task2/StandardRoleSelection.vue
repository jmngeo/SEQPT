<template>
  <el-card class="role-selection-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Select SE Roles in Your Organization</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Your organization has defined SE processes. Please identify which roles
          participate in or are affected by the SE training program.
        </p>
      </div>
    </template>

    <!-- Info alert -->
    <el-alert
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    >
      Select from the 14 standard SE role clusters below. You can customize
      the role names to match your organization's nomenclature.
    </el-alert>

    <!-- Select All / Deselect All -->
    <div class="selection-toolbar">
      <div class="selection-count">
        <strong>Roles selected:</strong> {{ selectedRoleIds.length }} / {{ SE_ROLE_CLUSTERS.length }}
      </div>
      <div class="selection-actions">
        <el-button
          text
          size="small"
          @click="selectAll"
        >
          Select All
        </el-button>
        <el-button
          text
          size="small"
          @click="deselectAll"
        >
          Deselect All
        </el-button>
      </div>
    </div>

    <!-- Role list grouped by category -->
    <div
      v-for="category in roleCategories"
      :key="category"
      class="role-category"
    >
      <el-divider></el-divider>
      <h3 class="category-title">{{ category }}</h3>

      <div
        v-for="role in getRolesByCategory(category)"
        :key="role.id"
        class="role-item"
      >
        <!-- Role checkbox -->
        <el-checkbox
          v-model="selectedRoleIds"
          :value="role.id"
          class="role-checkbox"
        >
          <div class="role-info">
            <strong>{{ role.name }}</strong>
            <div class="role-description">
              {{ role.description }}
            </div>
          </div>
        </el-checkbox>

        <!-- Organization-specific name input (shown when selected) -->
        <el-collapse-transition>
          <div v-if="selectedRoleIds.includes(role.id)" class="custom-name-input">
            <el-input
              v-model="customNames[role.id]"
              :placeholder="`Your organization's name for ${role.name}`"
              clearable
              size="default"
            >
              <template #prepend>Organization Name (Optional)</template>
            </el-input>
            <div class="input-hint">
              Leave blank to use the standard name
            </div>
          </div>
        </el-collapse-transition>
      </div>
    </div>

    <!-- Validation message -->
    <el-alert
      v-if="showValidation && selectedRoleIds.length === 0"
      type="error"
      :closable="false"
      show-icon
      style="margin-top: 20px;"
    >
      Please select at least one role to continue.
    </el-alert>

    <!-- Actions -->
    <div class="step-actions" style="margin-top: 32px;">
      <el-button
        @click="handleBack"
      >
        Back to Maturity Assessment
      </el-button>
      <el-button
        type="primary"
        :disabled="selectedRoleIds.length === 0"
        :loading="saving"
        @click="handleContinue"
      >
        Continue to Target Group Size
      </el-button>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { SE_ROLE_CLUSTERS } from '@/data/seRoleClusters'
import { rolesApi } from '@/api/phase1'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  maturityId: {
    type: Number,
    required: true
  },
  existingRoles: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['complete', 'back'])

const authStore = useAuthStore()
const selectedRoleIds = ref([])
const customNames = ref({})
const showValidation = ref(false)
const saving = ref(false)

// Get unique categories
const roleCategories = computed(() => {
  const categories = [...new Set(SE_ROLE_CLUSTERS.map(r => r.category))]
  return categories
})

// Get roles by category
const getRolesByCategory = (category) => {
  return SE_ROLE_CLUSTERS.filter(r => r.category === category)
}

// Select/Deselect all
const selectAll = () => {
  selectedRoleIds.value = SE_ROLE_CLUSTERS.map(r => r.id)
}

const deselectAll = () => {
  selectedRoleIds.value = []
  customNames.value = {}
}

const handleBack = () => {
  emit('back')
}

const handleContinue = async () => {
  if (selectedRoleIds.value.length === 0) {
    showValidation.value = true
    return
  }

  saving.value = true
  try {
    // Prepare roles data
    const rolesToSave = selectedRoleIds.value.map(roleId => {
      const role = SE_ROLE_CLUSTERS.find(r => r.id === roleId)
      return {
        standardRoleId: roleId,
        standardRoleName: role.name,
        standard_role_description: role.description,  // Include description
        orgRoleName: customNames.value[roleId] || null,
        identificationMethod: 'STANDARD',
        participatingInTraining: true
      }
    })

    // Save to database
    const response = await rolesApi.save(
      authStore.organizationId,
      props.maturityId,
      rolesToSave,
      'STANDARD'
    )

    console.log('[StandardRoleSelection] Saved:', response)

    // Emit completion with selected roles
    // IMPORTANT: response.roles contains the actual array, not response.data
    emit('complete', {
      roles: response.roles,
      count: response.count
    })
  } catch (error) {
    console.error('[StandardRoleSelection] Save failed:', error)
    alert('Failed to save roles. Please try again.')
  } finally {
    saving.value = false
  }
}

// Load existing roles if provided
onMounted(() => {
  if (props.existingRoles && props.existingRoles.roles && props.existingRoles.roles.length > 0) {
    console.log('[StandardRoleSelection] Loading existing roles:', props.existingRoles)

    // Use Set to prevent duplicate role IDs
    const uniqueRoleIds = new Set()

    // Pre-fill selected role IDs and custom names
    props.existingRoles.roles.forEach(role => {
      if (role.standardRoleId) {
        // Only add if not already present (prevents duplicates from database)
        if (!uniqueRoleIds.has(role.standardRoleId)) {
          uniqueRoleIds.add(role.standardRoleId)
          selectedRoleIds.value.push(role.standardRoleId)

          // If there's an organization-specific name, store it (prefer first occurrence)
          if (role.orgRoleName && !customNames.value[role.standardRoleId]) {
            customNames.value[role.standardRoleId] = role.orgRoleName
          }
        } else {
          console.warn(`[StandardRoleSelection] DUPLICATE DETECTED: Role ID ${role.standardRoleId} (${role.standardRoleName}) already loaded - skipping duplicate`)
        }
      }
    })

    console.log('[StandardRoleSelection] Pre-filled', selectedRoleIds.value.length, 'unique roles')
  }
})
</script>

<style scoped>
.role-selection-container {
  max-width: 1000px;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.selection-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 12px 16px;
  background-color: #f5f7fa;
  border-radius: 4px;
}

.selection-count {
  font-size: 14px;
  color: #606266;
}

.selection-actions {
  display: flex;
  gap: 8px;
}

.role-category {
  margin-bottom: 32px;
}

.category-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  margin: 16px 0;
}

.role-item {
  margin-bottom: 24px;
}

.role-checkbox {
  width: 100%;
}

.role-checkbox :deep(.el-checkbox__label) {
  width: 100%;
  color: #303133;
}

.role-info {
  width: 100%;
}

.role-info strong {
  font-size: 15px;
  color: #303133;
  display: block;
  margin-bottom: 4px;
}

.role-description {
  font-size: 13px;
  color: #909399;
  line-height: 1.5;
  margin-top: 4px;
}

.custom-name-input {
  margin-left: 24px;
  margin-top: 12px;
}

.input-hint {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  margin-left: 12px;
}

.step-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}
</style>
