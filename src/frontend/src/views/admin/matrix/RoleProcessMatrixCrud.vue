<script setup>
import { ref, onMounted } from 'vue';
import axios from '@/api/axios';

// Reactive data for roles, processes, and matrix
const organizationId = ref(null);
const organizationName = ref('');
const roles = ref([]);
const processes = ref([]);
const selectedRoleId = ref(null);
const roleProcessMatrix = ref({});

// Get admin's organization from localStorage
const getAdminOrganization = () => {
  const orgId = localStorage.getItem('user_organization_id');
  const orgName = localStorage.getItem('user_organization_name');

  if (!orgId) {
    console.error('No organization found for admin. Please login again.');
    return false;
  }

  organizationId.value = parseInt(orgId);
  organizationName.value = orgName || 'Your Organization';
  return true;
};

// Fetch roles and processes
const fetchRolesAndProcesses = async () => {
  try {
    const response = await axios.get('/roles_and_processes');
    roles.value = response.data.roles;
    processes.value = response.data.processes;
  } catch (error) {
    console.error('Error fetching roles and processes:', error);
  }
};

// Fetch role-process matrix for the selected role and organization
const fetchRoleProcessMatrix = async () => {
  if (!organizationId.value || !selectedRoleId.value) return;

  try {
    const response = await axios.get(`/role_process_matrix/${organizationId.value}/${selectedRoleId.value}`);
    roleProcessMatrix.value = processes.value.reduce((matrix, process) => {
      const entry = response.data.find(e => e.iso_process_id === process.id);
      matrix[process.id] = entry ? entry.role_process_value : 0;  // Default to 0 if not set
      return matrix;
    }, {});
  } catch (error) {
    console.error('Error fetching role-process matrix:', error);
  }
};

// Save the role-process matrix for the admin's organization and selected role
const saveRoleProcessMatrix = async () => {
  if (!organizationId.value || !selectedRoleId.value) return;

  const filteredMatrix = {};
  for (const [processId, value] of Object.entries(roleProcessMatrix.value)) {
    if (value !== null) {
      filteredMatrix[processId] = value;  // Only include if a selection has been made
    }
  }

  try {
    await axios.put('/role_process_matrix/bulk', {
      organization_id: organizationId.value,
      role_cluster_id: selectedRoleId.value,
      matrix: filteredMatrix
    });
    alert("Changes saved successfully! Role-Competency Matrix has been recalculated.");
  } catch (error) {
    console.error('Error saving role-process matrix:', error);
    alert("Error saving changes. Please try again.");
  }
};

// Initialize on component mount
onMounted(async () => {
  // Get admin's organization
  if (!getAdminOrganization()) {
    alert('No organization found. Please login again.');
    return;
  }

  // Fetch roles and processes
  await fetchRolesAndProcesses();
});
</script>

<template>
  <div class="matrix-crud-container">
    <div class="matrix-content">
      <h1 class="matrix-title">Configure Role-Process Matrix</h1>

      <!-- Organization info (read-only) -->
      <div v-if="organizationId" class="org-info">
        <label class="org-label">Organization:</label>
        <span class="org-name">{{ organizationName }}</span>
      </div>

      <!-- Dropdown to select a role -->
      <el-select
        v-if="organizationId"
        v-model="selectedRoleId"
        placeholder="Select Role"
        @change="fetchRoleProcessMatrix"
        style="width: 100%; max-width: 500px; margin-bottom: 20px;"
        size="large"
      >
        <el-option
          v-for="role in roles"
          :key="role.id"
          :label="role.name"
          :value="role.id"
        />
      </el-select>

      <el-alert
        v-if="organizationId && roles.length === 0"
        title="No Roles Available"
        type="warning"
        description="No roles found in the database. Please add role data first."
        :closable="false"
        style="margin-bottom: 20px; max-width: 800px;"
      />

      <!-- List of processes with radio buttons for role_process_value if a role is selected -->
      <div v-if="selectedRoleId && processes.length > 0" class="process-list">
        <div
          v-for="process in processes"
          :key="process.id"
          class="process-item"
        >
          <span class="process-name">{{ process.name }}</span>
          <el-radio-group v-model="roleProcessMatrix[process.id]" class="process-radio">
            <el-radio :label="0">0</el-radio>
            <el-radio :label="1">1</el-radio>
            <el-radio :label="2">2</el-radio>
            <el-radio :label="3">3</el-radio>
          </el-radio-group>
        </div>
      </div>

      <!-- Save button -->
      <el-button
        v-if="selectedRoleId && processes.length > 0"
        type="primary"
        size="large"
        @click="saveRoleProcessMatrix"
        style="margin-top: 24px;"
      >
        Save Changes
      </el-button>
    </div>
  </div>
</template>

<style scoped>
.matrix-crud-container {
  min-height: 100vh;
  padding: var(--se-spacing-xl);
  background-color: var(--se-bg-secondary);
}

.matrix-content {
  max-width: 900px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.matrix-title {
  font-size: var(--se-font-size-extra-large);
  font-weight: var(--se-font-weight-primary);
  color: var(--se-text-primary);
  margin-bottom: var(--se-spacing-xl);
  text-align: center;
}

.org-info {
  width: 100%;
  max-width: 500px;
  padding: var(--se-spacing-base);
  margin-bottom: var(--se-spacing-lg);
  background-color: var(--se-bg-primary);
  border-radius: var(--se-border-radius-base);
  border: 1px solid var(--se-border-lighter);
  display: flex;
  align-items: center;
  gap: var(--se-spacing-sm);
}

.org-label {
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-secondary);
  color: var(--se-text-secondary);
}

.org-name {
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-primary);
  color: var(--se-primary);
}

.process-list {
  width: 100%;
  max-width: 800px;
  background-color: var(--se-bg-primary);
  border-radius: var(--se-border-radius-base);
  padding: var(--se-spacing-lg);
  margin-bottom: var(--se-spacing-lg);
  box-shadow: var(--se-shadow-base);
}

.process-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--se-spacing-base);
  margin-bottom: var(--se-spacing-sm);
  background-color: var(--se-bg-secondary);
  border-radius: var(--se-border-radius-base);
  border: 1px solid var(--se-border-lighter);
  transition: all 0.3s ease;
}

.process-item:hover {
  border-color: var(--se-primary);
  box-shadow: var(--se-shadow-light);
}

.process-item:last-child {
  margin-bottom: 0;
}

.process-name {
  font-size: var(--se-font-size-base);
  font-weight: var(--se-font-weight-secondary);
  color: var(--se-text-primary);
  flex: 1;
}

.process-radio {
  display: flex;
  gap: var(--se-spacing-sm);
}
</style>
