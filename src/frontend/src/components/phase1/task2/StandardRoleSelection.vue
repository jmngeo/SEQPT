<template>
  <el-card class="role-selection-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Map Your Organization's Roles to SE Role Clusters</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Your organization has defined SE processes. Map your company-specific roles to the standard SE role clusters below.
          You can add multiple roles per cluster and customize their names.
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
      <template #default>
        <div>
          <strong>Instructions:</strong>
          <ul style="margin: 8px 0 0 0; padding-left: 20px;">
            <li>Expand each SE role cluster to add your organization's roles that fit into that cluster</li>
            <li>You can add multiple company roles under the same cluster (e.g., "Senior Developer" and "Junior Developer" under "Specialist Developer")</li>
            <li>Customize role names to match your organization's nomenclature</li>
            <li>If you have roles that don't fit any cluster, add them in the "Other Roles" section at the bottom</li>
          </ul>
        </div>
      </template>
    </el-alert>

    <!-- Selection summary -->
    <div class="selection-summary">
      <div class="summary-item">
        <el-icon :size="20" color="#409EFF"><OfficeBuilding /></el-icon>
        <span><strong>Total Company Roles:</strong> {{ totalRolesCount }}</span>
      </div>
      <div class="summary-item">
        <el-icon :size="20" color="#67C23A"><Check /></el-icon>
        <span><strong>Clusters Used:</strong> {{ usedClustersCount }} / {{ SE_ROLE_CLUSTERS.length }}</span>
      </div>
    </div>

    <!-- Role clusters grouped by category -->
    <div class="role-clusters-section">
      <div
        v-for="category in roleCategories"
        :key="category"
        class="role-category-section"
      >
        <el-divider content-position="left">
          <h3 class="category-title">
            <el-icon :size="18"><Briefcase /></el-icon>
            {{ category }}
          </h3>
        </el-divider>

        <div
          v-for="cluster in getRolesByCategory(category)"
          :key="cluster.id"
          class="cluster-item"
        >
          <!-- Cluster Card -->
          <el-card :class="['cluster-card', { 'has-roles': clusterRoles[cluster.id]?.length > 0 }]">
            <!-- Cluster Header (Always Visible) -->
            <div class="cluster-header" @click="toggleCluster(cluster.id)">
              <div class="cluster-info">
                <div class="cluster-name-row">
                  <el-icon :size="16" :color="clusterRoles[cluster.id]?.length > 0 ? '#67C23A' : '#909399'">
                    <component :is="clusterRoles[cluster.id]?.length > 0 ? 'Check' : 'Plus'" />
                  </el-icon>
                  <h4>{{ cluster.name }}</h4>
                  <el-tag v-if="clusterRoles[cluster.id]?.length > 0" size="small" type="success">
                    {{ clusterRoles[cluster.id].length }} {{ clusterRoles[cluster.id].length === 1 ? 'role' : 'roles' }}
                  </el-tag>
                </div>
                <p class="cluster-description">{{ cluster.description }}</p>
              </div>
              <el-icon class="expand-icon" :class="{ 'is-expanded': expandedClusters.has(cluster.id) }">
                <ArrowDown />
              </el-icon>
            </div>

            <!-- Cluster Content (Expandable) -->
            <el-collapse-transition>
              <div v-show="expandedClusters.has(cluster.id)" class="cluster-content">
                <el-divider style="margin: 12px 0" />

                <!-- Added Roles List -->
                <div v-if="clusterRoles[cluster.id]?.length > 0" class="added-roles-list">
                  <div
                    v-for="(role, index) in clusterRoles[cluster.id]"
                    :key="`cluster-${cluster.id}-role-${index}`"
                    class="role-item-card"
                  >
                    <div class="role-item-content">
                      <div class="role-number">{{ index + 1 }}</div>
                      <div class="role-input-group">
                        <el-input
                          v-model="role.orgRoleName"
                          placeholder="Enter your organization's role name"
                          size="default"
                          class="role-name-input"
                        >
                          <template #prepend>Role Name</template>
                        </el-input>
                        <div class="input-hint">
                          This role will be mapped to the <strong>{{ cluster.name }}</strong> cluster
                        </div>
                      </div>
                      <el-button
                        type="danger"
                        :icon="Delete"
                        circle
                        size="small"
                        @click="removeRole(cluster.id, index)"
                        title="Remove this role"
                      />
                    </div>
                  </div>
                </div>

                <!-- Empty State -->
                <div v-else class="empty-state">
                  <el-icon :size="32" color="#C0C4CC"><FolderOpened /></el-icon>
                  <p>No roles added to this cluster yet</p>
                </div>

                <!-- Add Role Button -->
                <el-button
                  type="primary"
                  :icon="Plus"
                  size="default"
                  plain
                  @click="addRoleToCluster(cluster.id, cluster.name, cluster.description)"
                  class="add-role-btn"
                >
                  Add Role to {{ cluster.name }}
                </el-button>
              </div>
            </el-collapse-transition>
          </el-card>
        </div>
      </div>
    </div>

    <!-- Custom Roles Section (Roles not in 14 standard clusters) -->
    <el-divider content-position="left">
      <h3 class="category-title">
        <el-icon :size="18"><Plus /></el-icon>
        Other Roles (Not in Standard Clusters)
      </h3>
    </el-divider>

    <el-card class="custom-roles-section">
      <template #header>
        <div class="custom-roles-header">
          <div>
            <h4>Custom Roles</h4>
            <p style="color: #909399; font-size: 13px; margin: 4px 0 0 0;">
              Add roles from your organization that don't fit into the 14 standard SE role clusters above
            </p>
          </div>
          <el-tag v-if="customRoles.length > 0" type="warning" size="default">
            {{ customRoles.length }} custom {{ customRoles.length === 1 ? 'role' : 'roles' }}
          </el-tag>
        </div>
      </template>

      <!-- Custom Roles List -->
      <div v-if="customRoles.length > 0" class="custom-roles-list">
        <div
          v-for="(role, index) in customRoles"
          :key="`custom-role-${index}`"
          class="custom-role-item"
        >
          <div class="custom-role-content">
            <div class="role-number">{{ index + 1 }}</div>
            <div class="role-input-group-vertical">
              <el-input
                v-model="role.orgRoleName"
                placeholder="Enter custom role name (e.g., 'Data Analyst')"
                size="default"
              >
                <template #prepend>Role Name</template>
              </el-input>
              <el-input
                v-model="role.description"
                placeholder="Brief description of this role's responsibilities"
                type="textarea"
                :rows="2"
                size="default"
                style="margin-top: 8px;"
              >
                <template #prepend>Description</template>
              </el-input>
            </div>
            <el-button
              type="danger"
              :icon="Delete"
              circle
              size="small"
              @click="removeCustomRole(index)"
              title="Remove this custom role"
            />
          </div>
        </div>
      </div>

      <!-- Empty State for Custom Roles -->
      <div v-else class="empty-state">
        <el-icon :size="32" color="#C0C4CC"><FolderOpened /></el-icon>
        <p>No custom roles added yet</p>
      </div>

      <!-- Add Custom Role Button -->
      <el-button
        type="warning"
        :icon="Plus"
        size="default"
        plain
        @click="addCustomRole"
        class="add-custom-role-btn"
      >
        Add Custom Role
      </el-button>
    </el-card>

    <!-- Validation message -->
    <el-alert
      v-if="showValidation && totalRolesCount === 0"
      type="error"
      :closable="false"
      show-icon
      style="margin-top: 20px;"
    >
      Please add at least one role to continue.
    </el-alert>

    <!-- Actions -->
    <div class="step-actions" style="margin-top: 32px;">
      <el-button
        size="large"
        @click="handleBack"
      >
        <el-icon><ArrowLeft /></el-icon>
        Back
      </el-button>
      <el-button
        type="primary"
        size="large"
        :disabled="totalRolesCount === 0"
        :loading="saving"
        @click="handleContinue"
      >
        Continue to Role-Process Matrix
        <el-icon><ArrowRight /></el-icon>
      </el-button>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { SE_ROLE_CLUSTERS } from '@/data/seRoleClusters'
import { rolesApi } from '@/api/phase1'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import {
  Plus,
  Delete,
  Check,
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  OfficeBuilding,
  Briefcase,
  FolderOpened
} from '@element-plus/icons-vue'

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

// Cluster roles: { clusterId: [{ orgRoleName, standardRoleId, standardRoleName, standard_role_description }] }
const clusterRoles = ref({})

// Custom roles: [{ orgRoleName, description }]
const customRoles = ref([])

// Expanded clusters
const expandedClusters = ref(new Set())

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

// Total roles count
const totalRolesCount = computed(() => {
  const clusterCount = Object.values(clusterRoles.value)
    .reduce((sum, roles) => sum + roles.length, 0)
  return clusterCount + customRoles.value.length
})

// Used clusters count
const usedClustersCount = computed(() => {
  return Object.values(clusterRoles.value)
    .filter(roles => roles && roles.length > 0).length
})

// Toggle cluster expansion
const toggleCluster = (clusterId) => {
  if (expandedClusters.value.has(clusterId)) {
    expandedClusters.value.delete(clusterId)
  } else {
    expandedClusters.value.add(clusterId)
  }
}

// Add role to cluster
const addRoleToCluster = (clusterId, clusterName, clusterDescription) => {
  if (!clusterRoles.value[clusterId]) {
    clusterRoles.value[clusterId] = []
  }

  clusterRoles.value[clusterId].push({
    orgRoleName: '',
    standardRoleId: clusterId,
    standardRoleName: clusterName,
    standard_role_description: clusterDescription
  })
}

// Remove role from cluster
const removeRole = (clusterId, index) => {
  clusterRoles.value[clusterId].splice(index, 1)
  if (clusterRoles.value[clusterId].length === 0) {
    delete clusterRoles.value[clusterId]
  }
}

// Add custom role
const addCustomRole = () => {
  customRoles.value.push({
    orgRoleName: '',
    description: ''
  })
}

// Remove custom role
const removeCustomRole = (index) => {
  customRoles.value.splice(index, 1)
}

const handleBack = () => {
  emit('back')
}

const handleContinue = async () => {
  if (totalRolesCount.value === 0) {
    showValidation.value = true
    return
  }

  // Validate that all roles have names
  let hasEmptyNames = false

  // Check cluster roles
  Object.values(clusterRoles.value).forEach(roles => {
    roles.forEach(role => {
      if (!role.orgRoleName || role.orgRoleName.trim() === '') {
        hasEmptyNames = true
      }
    })
  })

  // Check custom roles
  customRoles.value.forEach(role => {
    if (!role.orgRoleName || role.orgRoleName.trim() === '') {
      hasEmptyNames = true
    }
  })

  if (hasEmptyNames) {
    ElMessage.warning('Please fill in all role names before continuing')
    return
  }

  saving.value = true
  try {
    // Prepare roles data
    const rolesToSave = []

    // Add cluster-mapped roles
    Object.values(clusterRoles.value).forEach(roles => {
      roles.forEach(role => {
        rolesToSave.push({
          standardRoleId: role.standardRoleId,
          standardRoleName: role.standardRoleName,
          standard_role_description: role.standard_role_description,
          orgRoleName: role.orgRoleName.trim(),
          identificationMethod: 'STANDARD',
          participatingInTraining: true
        })
      })
    })

    // Add custom roles (not mapped to standard clusters)
    customRoles.value.forEach(role => {
      rolesToSave.push({
        standardRoleId: null, // No standard role mapping
        standardRoleName: null,
        standard_role_description: role.description?.trim() || null,
        orgRoleName: role.orgRoleName.trim(),
        identificationMethod: 'CUSTOM', // Mark as custom
        participatingInTraining: true
      })
    })

    console.log('[StandardRoleSelection] Saving roles:', rolesToSave)

    // Save to database (with maturity_id for pathway detection)
    const response = await rolesApi.save(
      authStore.organizationId,
      props.maturityId,
      rolesToSave,
      'STANDARD'
    )

    console.log('[StandardRoleSelection] Saved:', response)

    // SMART-MERGE: Handle matrix initialization based on what changed
    if (!response.is_update || response.roles_changed) {
      // New organization OR roles were modified - initialize/update matrix
      console.log('[StandardRoleSelection] Matrix update needed:', {
        pathway_changed: response.pathway_changed,
        smart_merge: response.smart_merge_enabled,
        change_summary: response.change_summary
      })

      try {
        // Determine which roles need matrix initialization
        const rolesToInitialize = response.smart_merge_enabled
          ? response.roles_to_add  // Only new roles
          : response.roles  // All roles (full reset)

        // Only call initializeMatrix if there are roles to initialize
        if (rolesToInitialize && rolesToInitialize.length > 0) {
          const matrixResponse = await rolesApi.initializeMatrix(
            authStore.organizationId,
            rolesToInitialize,
            response.smart_merge_enabled  // Pass smart_merge flag
          )
          console.log('[StandardRoleSelection] Matrix initialized:', matrixResponse)
        } else {
          console.log('[StandardRoleSelection] No new roles to initialize - skipping matrix init')
        }

        // Show appropriate message based on what happened
        if (response.pathway_changed) {
          ElMessage.warning({
            message: `Pathway changed! Role-process matrix has been reset. Please re-configure all ${response.count} roles.`,
            duration: 6000
          })
        } else if (response.smart_merge_enabled) {
          const { unchanged, added, removed } = response.change_summary
          if (added === 0 && removed > 0) {
            // Only deletions
            ElMessage.success({
              message: `Smart merge complete: ${removed} roles removed, ${unchanged} roles preserved with matrix data intact!`,
              duration: 6000
            })
          } else {
            // Mix of additions/removals
            ElMessage.success({
              message: `Smart merge complete: ${unchanged} roles preserved, ${added} added, ${removed} removed. Only new roles need matrix configuration!`,
              duration: 6000
            })
          }
        } else {
          ElMessage.success(`Saved ${response.count} roles and initialized matrix!`)
        }
      } catch (matrixError) {
        console.error('[StandardRoleSelection] Matrix initialization failed:', matrixError)
        ElMessage.warning('Roles saved but matrix initialization failed. You can still edit the matrix manually.')
      }
    } else {
      // No changes to roles - preserve existing matrix
      console.log('[StandardRoleSelection] No role changes - matrix preserved')
      ElMessage.success(`Using existing ${response.count} roles (matrix preserved)`)
    }

    // Emit completion with selected roles
    emit('complete', {
      roles: response.roles,
      count: response.count
    })
  } catch (error) {
    console.error('[StandardRoleSelection] Save failed:', error)
    ElMessage.error('Failed to save roles. Please try again.')
  } finally {
    saving.value = false
  }
}

// Load existing roles if provided
onMounted(() => {
  if (props.existingRoles && props.existingRoles.roles && props.existingRoles.roles.length > 0) {
    console.log('[StandardRoleSelection] Loading existing roles:', props.existingRoles)

    // Separate cluster-mapped and custom roles
    props.existingRoles.roles.forEach(role => {
      if (role.standardRoleId && role.identificationMethod === 'STANDARD') {
        // Cluster-mapped role
        if (!clusterRoles.value[role.standardRoleId]) {
          clusterRoles.value[role.standardRoleId] = []
        }

        clusterRoles.value[role.standardRoleId].push({
          orgRoleName: role.orgRoleName || '',
          standardRoleId: role.standardRoleId,
          standardRoleName: role.standardRoleName,
          standard_role_description: role.standard_role_description
        })

        // Auto-expand clusters that have roles
        expandedClusters.value.add(role.standardRoleId)
      } else if (role.identificationMethod === 'CUSTOM') {
        // Custom role
        customRoles.value.push({
          orgRoleName: role.orgRoleName || '',
          description: role.standard_role_description || ''
        })
      }
    })

    console.log('[StandardRoleSelection] Loaded cluster roles:', clusterRoles.value)
    console.log('[StandardRoleSelection] Loaded custom roles:', customRoles.value)
  }
})
</script>

<style scoped>
.role-selection-container {
  max-width: 1200px;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

/* Selection Summary */
.selection-summary {
  display: flex;
  gap: 24px;
  padding: 16px 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
  border-radius: 8px;
  margin-bottom: 24px;
  border: 1px solid #e4e7ed;
}

.summary-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #606266;
}

/* Role Categories */
.role-category-section {
  margin-bottom: 32px;
}

.category-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin: 0;
}

/* Cluster Item */
.cluster-item {
  margin-bottom: 16px;
}

.cluster-card {
  transition: all 0.3s ease;
  border: 2px solid #e4e7ed;
}

.cluster-card.has-roles {
  border-color: #67C23A;
  background-color: #f0f9ff;
}

.cluster-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

/* Cluster Header */
.cluster-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.cluster-info {
  flex: 1;
}

.cluster-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.cluster-name-row h4 {
  margin: 0;
  font-size: 16px;
  color: #303133;
  font-weight: 600;
}

.cluster-description {
  font-size: 13px;
  color: #909399;
  margin: 4px 0 0 24px;
  line-height: 1.5;
}

.expand-icon {
  transition: transform 0.3s ease;
  font-size: 18px;
  color: #909399;
}

.expand-icon.is-expanded {
  transform: rotate(180deg);
}

/* Cluster Content */
.cluster-content {
  padding-top: 8px;
}

/* Added Roles List */
.added-roles-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 16px;
}

.role-item-card {
  background-color: #ffffff;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  padding: 12px;
  transition: all 0.2s ease;
}

.role-item-card:hover {
  border-color: #409EFF;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.15);
}

.role-item-content {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.role-number {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background-color: #409EFF;
  color: white;
  border-radius: 50%;
  font-size: 13px;
  font-weight: 600;
  flex-shrink: 0;
  margin-top: 4px;
}

.role-input-group {
  flex: 1;
}

.role-name-input {
  width: 100%;
}

.input-hint {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  margin-left: 12px;
  line-height: 1.4;
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 32px;
  color: #909399;
  text-align: center;
}

.empty-state p {
  margin: 8px 0 0 0;
  font-size: 14px;
}

/* Add Role Button */
.add-role-btn {
  width: 100%;
  margin-top: 8px;
}

/* Custom Roles Section */
.custom-roles-section {
  margin-bottom: 24px;
  border: 2px dashed #E6A23C;
}

.custom-roles-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.custom-roles-header h4 {
  margin: 0;
  font-size: 16px;
  color: #303133;
}

.custom-roles-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 16px;
}

.custom-role-item {
  background-color: #fef8f0;
  border: 1px solid #f5dab1;
  border-radius: 6px;
  padding: 16px;
}

.custom-role-content {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.role-input-group-vertical {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.add-custom-role-btn {
  width: 100%;
}

/* Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}
</style>
