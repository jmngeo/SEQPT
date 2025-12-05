<template>
  <el-card class="role-selection-container step-card">
    <template #header>
      <div class="card-header">
        <h3>Identify Your Organization's Roles</h3>
        <p style="color: #606266; font-size: 14px; margin-top: 8px;">
          Upload or enter role descriptions for all roles that you want to include in your SE training program. AI will automatically map them to SE role clusters where applicable.
        </p>
      </div>
    </template>

    <!-- ========================================
         INPUT SECTION: AI-Powered Role Mapping
         ======================================== -->
    <div class="input-section">
      <h3 class="section-title">
        <el-icon :size="20"><Upload /></el-icon>
        Step 1: Input Your Roles
      </h3>

      <RoleUploadMapper
        :organization-id="organizationId"
        @cancel="() => {}"
        @mapping-complete="handleMappingComplete"
      />
    </div>

    <!-- ========================================
         OUTPUT SECTION: Identified Roles
         ======================================== -->
    <div v-if="hasIdentifiedRoles" class="output-section">
      <el-divider />

      <div class="section-header">
        <h3 class="section-title">
          <el-icon :size="20"><SuccessFilled /></el-icon>
          Step 2: Review Identified Roles
        </h3>
        <div class="summary-stats">
          <el-tag type="success" size="large">{{ totalRolesCount }} Total Roles</el-tag>
          <el-tag type="primary" size="large">{{ mappedRolesCount }} Mapped to Clusters</el-tag>
          <el-tag type="warning" size="large">{{ customRoles.length }} Custom Roles</el-tag>
        </div>
      </div>

      <!-- SE Role Clusters Info Box -->
      <el-collapse v-model="showRoleClustersInfo" class="role-clusters-info-collapse">
        <el-collapse-item name="info">
          <template #title>
            <div class="info-collapse-title">
              <el-icon :size="18" color="#409EFF"><InfoFilled /></el-icon>
              <span>What are the 14 SE Role Clusters?</span>
            </div>
          </template>
          <div class="role-clusters-info-content">
            <p class="info-intro">
              The 14 Systems Engineering (SE) role clusters were identified by K&ouml;nemann et al. in their paper
              "Identification of stakeholder-specific Systems Engineering competencies for industry" (IEEE SysCon, 2022).
              These clusters represent standard role archetypes found in systems engineering organizations, providing a framework
              for competency-based qualification planning.
            </p>
            <div class="clusters-grid">
              <div
                v-for="cluster in SE_ROLE_CLUSTERS"
                :key="cluster.id"
                class="cluster-info-card"
              >
                <div class="cluster-info-header">
                  <span class="cluster-number">{{ cluster.id }}</span>
                  <span class="cluster-name">{{ cluster.name }}</span>
                </div>
                <p class="cluster-info-description">{{ cluster.description }}</p>
              </div>
            </div>
          </div>
        </el-collapse-item>
      </el-collapse>

      <!-- Mapped Roles (grouped by cluster) -->
      <div v-if="mappedRolesCount > 0" class="mapped-roles-section">
        <h4 class="subsection-title">Identified Roles</h4>

        <div class="roles-grid">
          <div
            v-for="role in allMappedRoles"
            :key="role.id"
            class="role-card mapped-role"
          >
            <div class="role-card-header">
              <el-icon :size="20" color="#67C23A"><Check /></el-icon>
              <span class="role-title">{{ role.orgRoleName }}</span>
              <el-button
                type="danger"
                :icon="Delete"
                circle
                size="small"
                @click="removeRole(role)"
                class="delete-btn"
              />
            </div>

            <div class="cluster-badge">
              <el-tag type="success" effect="plain">
                SE Role Cluster: {{ role.standardRoleName }}
              </el-tag>
            </div>

            <div v-if="role.standard_role_description" class="cluster-description">
              {{ truncateDescription(role.standard_role_description, 120) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Custom Roles (not mapped to clusters) -->
      <div v-if="customRoles.length > 0" class="custom-roles-section">
        <h4 class="subsection-title">Custom Roles (Not Mapped to Standard Clusters)</h4>

        <div class="roles-grid">
          <div
            v-for="(role, index) in customRoles"
            :key="`custom-${index}`"
            class="role-card custom-role"
          >
            <div class="role-card-header">
              <el-icon :size="20" color="#E6A23C"><User /></el-icon>
              <span class="role-title">{{ role.orgRoleName }}</span>
              <el-button
                type="danger"
                :icon="Delete"
                circle
                size="small"
                @click="removeCustomRole(index)"
                class="delete-btn"
              />
            </div>

            <div class="cluster-badge">
              <el-tag type="warning" effect="plain">
                Custom Role
              </el-tag>
            </div>

            <div v-if="role.description" class="role-description">
              {{ role.description }}
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <el-empty
        v-if="totalRolesCount === 0"
        description="No roles identified yet. Use the input section above to add roles."
        :image-size="120"
      />
    </div>

    <!-- Initial Empty State -->
    <el-empty
      v-else
      description="Upload a document or manually enter roles to get started"
      :image-size="150"
    >
      <el-button type="primary" :icon="ArrowUp" @click="scrollToTop">
        Go to Input Section
      </el-button>
    </el-empty>

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
      <el-button size="large" @click="handleBack">
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

    <!-- Role Mapping Review Dialog -->
    <el-dialog
      v-model="showMappingReview"
      title="Review AI Mapping Results"
      width="1200px"
      :close-on-click-modal="false"
      class="mapping-review-dialog"
    >
      <RoleMappingReview
        v-if="showMappingReview"
        :organization-id="organizationId"
        :mapping-result="mappingResult"
        @back="showMappingReview = false"
        @finish="handleMappingReviewFinish"
      />
    </el-dialog>

    <!-- AI Matrix Generation Dialog -->
    <el-dialog
      v-model="showAIGenerationDialog"
      title="Generating Baseline Values"
      width="500px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="false"
      center
    >
      <div style="text-align: center; padding: 20px 0;">
        <el-icon :size="64" color="#409EFF" class="is-loading">
          <Loading />
        </el-icon>
        <h3 style="margin-top: 20px; margin-bottom: 12px;">Generating AI-Powered Baseline Values</h3>
        <p style="color: #606266; line-height: 1.6;">
          Our AI is analyzing your {{ customRoleCount }} custom {{ customRoleCount === 1 ? 'role' : 'roles' }}
          and generating intelligent baseline process involvement values.
        </p>
        <p style="color: #909399; font-size: 13px; margin-top: 12px;">
          This may take 5-15 seconds...
        </p>
      </div>
    </el-dialog>
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
  ArrowLeft,
  ArrowRight,
  Upload,
  SuccessFilled,
  Warning,
  ArrowUp,
  Loading,
  InfoFilled,
  User
} from '@element-plus/icons-vue'

// Import AI Mapping components
import RoleUploadMapper from './RoleUploadMapper.vue'
import RoleMappingReview from './RoleMappingReview.vue'

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

// Data structure: cluster roles organized by cluster ID
const clusterRoles = ref({})

// Custom roles: [{ orgRoleName, description }]
const customRoles = ref([])

const showValidation = ref(false)
const saving = ref(false)

// AI Mapping state
const showMappingReview = ref(false)
const mappingResult = ref(null)
const organizationId = computed(() => authStore.user?.organization_id || null)

// AI Matrix Generation state
const showAIGenerationDialog = ref(false)
const customRoleCount = ref(0)

// Role clusters info collapse state (closed by default)
const showRoleClustersInfo = ref([])

// Computed: All mapped roles (flatten clusterRoles object)
const allMappedRoles = computed(() => {
  const roles = []
  Object.entries(clusterRoles.value).forEach(([clusterId, clusterRolesList]) => {
    clusterRolesList.forEach(role => {
      roles.push({
        ...role,
        id: `${clusterId}-${role.orgRoleName}` // Unique ID
      })
    })
  })
  return roles
})

// Computed: Total roles count
const totalRolesCount = computed(() => {
  return allMappedRoles.value.length + customRoles.value.length
})

// Computed: Mapped roles count
const mappedRolesCount = computed(() => {
  return allMappedRoles.value.length
})

// Computed: Has any identified roles
const hasIdentifiedRoles = computed(() => {
  return totalRolesCount.value > 0
})

// Truncate description
const truncateDescription = (description, maxLength = 100) => {
  if (!description) return ''
  if (description.length <= maxLength) return description
  return description.substring(0, maxLength) + '...'
}

// Get confidence color
const getConfidenceColor = (confidence) => {
  if (confidence >= 0.8) return '#67C23A'
  if (confidence >= 0.6) return '#E6A23C'
  return '#F56C6C'
}

// Scroll to top
const scrollToTop = () => {
  // Try scrolling the main container first
  const container = document.querySelector('.role-selection-container')
  if (container) {
    container.scrollIntoView({ behavior: 'smooth', block: 'start' })
  } else {
    // Fallback to window scroll
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

// Remove mapped role
const removeRole = (role) => {
  const clusterId = role.standardRoleId
  if (clusterRoles.value[clusterId]) {
    const index = clusterRoles.value[clusterId].findIndex(
      r => r.orgRoleName === role.orgRoleName
    )
    if (index !== -1) {
      clusterRoles.value[clusterId].splice(index, 1)
      if (clusterRoles.value[clusterId].length === 0) {
        delete clusterRoles.value[clusterId]
      }
    }
  }
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
    ElMessage.error('Please provide names for all roles before continuing')
    return
  }

  saving.value = true

  try {
    // Build roles array
    const rolesToSave = []

    // Add cluster-mapped roles
    Object.entries(clusterRoles.value).forEach(([clusterId, roles]) => {
      roles.forEach(role => {
        rolesToSave.push({
          standardRoleId: parseInt(clusterId),
          standardRoleName: role.standardRoleName,
          standard_role_description: role.standard_role_description,
          orgRoleName: role.orgRoleName.trim(),
          identificationMethod: 'STANDARD',
          participatingInTraining: true
        })
      })
    })

    // Add custom roles
    customRoles.value.forEach(role => {
      rolesToSave.push({
        standardRoleId: null,
        standardRoleName: null,
        standard_role_description: role.description?.trim() || null,
        orgRoleName: role.orgRoleName.trim(),
        identificationMethod: 'CUSTOM',
        participatingInTraining: true
      })
    })

    console.log('[StandardRoleSelection] Saving roles:', rolesToSave)

    // Save to database
    const response = await rolesApi.save(
      authStore.organizationId,
      props.maturityId,
      rolesToSave,
      'STANDARD'
    )

    console.log('[StandardRoleSelection] Saved:', response)

    // Handle matrix initialization
    if (!response.is_update || response.roles_changed) {
      console.log('[StandardRoleSelection] Matrix update needed:', {
        pathway_changed: response.pathway_changed,
        smart_merge: response.smart_merge_enabled,
        change_summary: response.change_summary
      })

      try {
        const rolesToInitialize = response.smart_merge_enabled
          ? response.roles_to_add
          : response.roles

        if (rolesToInitialize && rolesToInitialize.length > 0) {
          // Check if there are custom roles that will trigger AI generation
          const customRolesInBatch = rolesToInitialize.filter(r => r.identificationMethod === 'CUSTOM')

          if (customRolesInBatch.length > 0) {
            customRoleCount.value = customRolesInBatch.length
            showAIGenerationDialog.value = true
          }

          const matrixResponse = await rolesApi.initializeMatrix(
            authStore.organizationId,
            rolesToInitialize,
            response.smart_merge_enabled
          )
          console.log('[StandardRoleSelection] Matrix initialized:', matrixResponse)

          // Hide AI generation dialog
          showAIGenerationDialog.value = false
        } else {
          console.log('[StandardRoleSelection] No new roles to initialize - skipping matrix init')
        }

        if (response.pathway_changed) {
          ElMessage.warning({
            message: `Pathway changed! Role-process matrix has been reset. Please re-configure all ${response.count} roles.`,
            duration: 6000
          })
        } else if (response.smart_merge_enabled) {
          const { unchanged, added, removed } = response.change_summary
          if (added === 0 && removed > 0) {
            ElMessage.success({
              message: `Smart merge complete: ${removed} roles removed, ${unchanged} roles preserved with matrix data intact!`,
              duration: 6000
            })
          } else {
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
        showAIGenerationDialog.value = false // Hide dialog on error
        ElMessage.warning('Roles saved but matrix initialization failed. You can still edit the matrix manually.')
      }
    } else {
      console.log('[StandardRoleSelection] No role changes - matrix preserved')
      ElMessage.success(`Using existing ${response.count} roles (matrix preserved)`)
    }

    // Emit completion
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

// AI Mapping handlers
const handleMappingComplete = (result) => {
  console.log('[AI Mapping] Mapping complete:', result)
  mappingResult.value = result
  showMappingReview.value = true
}

const handleMappingReviewFinish = async (reviewData) => {
  console.log('[AI Mapping] Review finished:', reviewData)

  try {
    // Clear existing roles
    clusterRoles.value = {}
    customRoles.value = []

    // Process confirmed mappings from reviewData
    const confirmedSet = new Set(reviewData.confirmed)

    if (!mappingResult.value || !mappingResult.value.results) {
      console.error('[AI Mapping] No mapping results available')
      ElMessage.error('No mapping results available')
      return
    }

    // Create a map of cluster IDs to descriptions for quick lookup
    const clusterDescriptionMap = {}
    SE_ROLE_CLUSTERS.forEach(cluster => {
      clusterDescriptionMap[cluster.id] = cluster.description
    })

    let confirmedCount = 0
    let customRoleCount = 0

    // Iterate through original mapping results
    mappingResult.value.results.forEach(roleMapping => {
      const roleTitle = roleMapping.role_title
      const roleDescription = roleMapping.role_description || ''

      // Filter mappings to only >= 80% confidence (same as RoleMappingReview)
      const highConfidenceMappings = roleMapping.mappings.filter(m => m.confidence_score >= 80)

      let hasConfirmedMapping = false

      // Check each HIGH CONFIDENCE cluster mapping for this role
      highConfidenceMappings.forEach(mapping => {
        const key = `${roleTitle}:${mapping.cluster_name}`

        // If this mapping was confirmed
        if (confirmedSet.has(key)) {
          const clusterId = mapping.cluster_id

          if (clusterId) {
            // Mapped to a cluster
            if (!clusterRoles.value[clusterId]) {
              clusterRoles.value[clusterId] = []
            }

            clusterRoles.value[clusterId].push({
              orgRoleName: roleTitle,
              standardRoleId: clusterId,
              standardRoleName: mapping.cluster_name,
              standard_role_description: clusterDescriptionMap[clusterId] || '',
              confidence: mapping.confidence_score / 100 // Convert percentage to decimal
            })

            confirmedCount++
            hasConfirmedMapping = true
          }
        }
      })

      // If no confirmed mappings and not marked as custom, treat as custom role
      if (!hasConfirmedMapping) {
        customRoles.value.push({
          orgRoleName: roleTitle,
          description: roleDescription
        })
        customRoleCount++
      }
    })

    console.log('[AI Mapping] Populated cluster roles:', clusterRoles.value)
    console.log('[AI Mapping] Populated custom roles:', customRoles.value)

    const totalRoles = confirmedCount + customRoleCount
    if (totalRoles > 0) {
      const messages = []
      if (confirmedCount > 0) messages.push(`${confirmedCount} mapped to SE clusters`)
      if (customRoleCount > 0) messages.push(`${customRoleCount} custom role(s)`)
      ElMessage.success(`Successfully imported ${totalRoles} role(s): ${messages.join(', ')}!`)
    } else {
      ElMessage.warning('No roles were imported')
    }
  } catch (error) {
    console.error('[AI Mapping] Error processing mappings:', error)
    ElMessage.error('Failed to process AI mappings')
  }

  showMappingReview.value = false
}

// Load existing roles if provided
onMounted(() => {
  if (props.existingRoles && props.existingRoles.roles && props.existingRoles.roles.length > 0) {
    console.log('[StandardRoleSelection] Loading existing roles:', props.existingRoles)

    props.existingRoles.roles.forEach(role => {
      if (role.standardRoleId && role.identificationMethod === 'STANDARD') {
        if (!clusterRoles.value[role.standardRoleId]) {
          clusterRoles.value[role.standardRoleId] = []
        }

        clusterRoles.value[role.standardRoleId].push({
          orgRoleName: role.orgRoleName || '',
          standardRoleId: role.standardRoleId,
          standardRoleName: role.standardRoleName,
          standard_role_description: role.standard_role_description
        })
      } else if (role.identificationMethod === 'CUSTOM') {
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
  max-width: 1400px;
  margin: 0 auto;
}

.card-header h3 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

/* Input Section */
.input-section {
  background: #f8f9fa;
  padding: 24px;
  border-radius: 8px;
  border: 2px dashed #409EFF;
  margin-bottom: 32px;
}

/* Output Section */
.output-section {
  margin-top: 32px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.summary-stats {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

/* Section Titles */
.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
  color: #303133;
  margin: 0 0 16px 0;
  font-weight: 600;
}

.subsection-title {
  font-size: 16px;
  color: #606266;
  margin: 24px 0 16px 0;
  font-weight: 600;
}

/* Roles Grid */
.roles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

/* Role Card */
.role-card {
  background: white;
  border: 2px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  transition: all 0.3s ease;
}

.role-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.role-card.mapped-role {
  border-left: 4px solid #67C23A;
}

.role-card.custom-role {
  border-left: 4px solid #E6A23C;
}

.role-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.role-title {
  flex: 1;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.delete-btn {
  opacity: 0;
  transition: opacity 0.3s ease;
}

.role-card:hover .delete-btn {
  opacity: 1;
}

.cluster-badge {
  margin-bottom: 12px;
}

.cluster-description,
.role-description {
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
  margin-bottom: 12px;
}

.confidence-indicator {
  margin-top: 12px;
}

.confidence-label {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  display: block;
}

/* Sections */
.mapped-roles-section,
.custom-roles-section {
  margin-bottom: 32px;
}

/* Actions */
.step-actions {
  display: flex;
  justify-content: space-between;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

/* SE Role Clusters Info Box */
.role-clusters-info-collapse {
  margin-bottom: 24px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
}

.role-clusters-info-collapse :deep(.el-collapse-item__header) {
  background: #f5f7fa;
  padding: 12px 16px;
  font-size: 14px;
  height: auto;
  line-height: 1.5;
}

.role-clusters-info-collapse :deep(.el-collapse-item__content) {
  padding: 0;
}

.info-collapse-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 500;
  color: #303133;
}

.role-clusters-info-content {
  padding: 20px;
  background: #fafbfc;
}

.info-intro {
  color: #606266;
  line-height: 1.7;
  margin-bottom: 20px;
  padding: 12px 16px;
  background: white;
  border-radius: 6px;
  border-left: 3px solid #409EFF;
}

.clusters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}

.cluster-info-card {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  padding: 12px 14px;
  transition: all 0.2s ease;
}

.cluster-info-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.cluster-info-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.cluster-number {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  background: #409EFF;
  color: white;
  border-radius: 50%;
  font-size: 11px;
  font-weight: 600;
  flex-shrink: 0;
}

.cluster-name {
  font-weight: 600;
  color: #303133;
  font-size: 13px;
  flex: 1;
}

.cluster-info-description {
  font-size: 12px;
  color: #606266;
  line-height: 1.5;
  margin: 0;
}
</style>
