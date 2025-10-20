<template>
  <div class="user-management">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><User /></el-icon> User Management</h1>
        <p>Manage platform users, roles, and permissions</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateUser = true">
          <el-icon><Plus /></el-icon>
          Add User
        </el-button>
        <el-button @click="exportUsers">
          <el-icon><Download /></el-icon>
          Export
        </el-button>
      </div>
    </div>

    <div class="management-container">
      <!-- Filters and Search -->
      <el-card class="filters-card">
        <el-row :gutter="20">
          <el-col :span="6">
            <el-select v-model="filters.role" placeholder="Filter by Role" clearable>
              <el-option label="All Roles" value=""></el-option>
              <el-option label="Admin" value="admin"></el-option>
              <el-option label="Instructor" value="instructor"></el-option>
              <el-option label="Student" value="student"></el-option>
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-select v-model="filters.status" placeholder="Filter by Status" clearable>
              <el-option label="All Status" value=""></el-option>
              <el-option label="Active" value="active"></el-option>
              <el-option label="Inactive" value="inactive"></el-option>
              <el-option label="Pending" value="pending"></el-option>
            </el-select>
          </el-col>
          <el-col :span="12">
            <el-input
              v-model="filters.search"
              placeholder="Search users..."
              prefix-icon="Search"
              clearable
            ></el-input>
          </el-col>
        </el-row>
      </el-card>

      <!-- Users Table -->
      <el-card class="users-table-card">
        <el-table :data="filteredUsers" style="width: 100%" stripe>
          <el-table-column prop="name" label="Name" width="200">
            <template #default="scope">
              <div class="user-info">
                <el-avatar :size="32" :src="scope.row.avatar">
                  {{ scope.row.name.charAt(0) }}
                </el-avatar>
                <div class="user-details">
                  <div class="user-name">{{ scope.row.name }}</div>
                  <div class="user-email">{{ scope.row.email }}</div>
                </div>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="role" label="Role" width="120">
            <template #default="scope">
              <el-tag :type="getRoleType(scope.row.role)">
                {{ scope.row.role }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="organization" label="Organization" width="180" />

          <el-table-column prop="status" label="Status" width="100">
            <template #default="scope">
              <el-tag :type="getStatusType(scope.row.status)" size="small">
                {{ scope.row.status }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="lastLogin" label="Last Login" width="150">
            <template #default="scope">
              {{ formatDate(scope.row.lastLogin) }}
            </template>
          </el-table-column>

          <el-table-column prop="assessments" label="Assessments" width="120" align="center" />

          <el-table-column label="Actions" width="180">
            <template #default="scope">
              <el-button size="small" @click="editUser(scope.row)">
                Edit
              </el-button>
              <el-button
                size="small"
                :type="scope.row.status === 'active' ? 'warning' : 'success'"
                @click="toggleUserStatus(scope.row)"
              >
                {{ scope.row.status === 'active' ? 'Deactivate' : 'Activate' }}
              </el-button>
              <el-button size="small" type="danger" @click="deleteUser(scope.row)">
                Delete
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-wrapper">
          <el-pagination
            v-model:current-page="currentPage"
            :page-size="pageSize"
            :total="filteredUsers.length"
            layout="prev, pager, next, jumper, total"
          />
        </div>
      </el-card>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced User Management</h2>
          <p>Comprehensive user administration system for the SE-QPT platform.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Bulk user operations (import/export, bulk edit)</li>
              <li>Advanced user analytics and activity tracking</li>
              <li>Role-based permission management system</li>
              <li>User onboarding workflows and automation</li>
              <li>Single Sign-On (SSO) integration</li>
              <li>User lifecycle management and archiving</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>

    <!-- Create/Edit User Dialog -->
    <el-dialog v-model="showCreateUser" title="Create New User" width="600px">
      <el-form :model="userForm" label-width="120px">
        <el-form-item label="Name" required>
          <el-input v-model="userForm.name" />
        </el-form-item>
        <el-form-item label="Email" required>
          <el-input v-model="userForm.email" type="email" />
        </el-form-item>
        <el-form-item label="Role" required>
          <el-select v-model="userForm.role" placeholder="Select role">
            <el-option label="Admin" value="admin"></el-option>
            <el-option label="Instructor" value="instructor"></el-option>
            <el-option label="Student" value="student"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Organization">
          <el-input v-model="userForm.organization" />
        </el-form-item>
        <el-form-item label="Department">
          <el-input v-model="userForm.department" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateUser = false">Cancel</el-button>
        <el-button type="primary" @click="createUser">Create User</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { User, Plus, Download, Search } from '@element-plus/icons-vue'

const showCreateUser = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)

const filters = ref({
  role: '',
  status: '',
  search: ''
})

const userForm = ref({
  name: '',
  email: '',
  role: '',
  organization: '',
  department: ''
})

// Sample users data
const users = ref([
  {
    id: 1,
    name: 'Dr. Sarah Johnson',
    email: 'sarah.johnson@company.com',
    role: 'admin',
    organization: 'Aerospace Systems Corp',
    status: 'active',
    lastLogin: new Date('2024-09-20'),
    assessments: 12,
    avatar: ''
  },
  {
    id: 2,
    name: 'John Smith',
    email: 'john.smith@company.com',
    role: 'student',
    organization: 'Tech Solutions Inc',
    status: 'active',
    lastLogin: new Date('2024-09-19'),
    assessments: 8,
    avatar: ''
  },
  {
    id: 3,
    name: 'Emily Davis',
    email: 'emily.davis@university.edu',
    role: 'instructor',
    organization: 'University Systems',
    status: 'active',
    lastLogin: new Date('2024-09-18'),
    assessments: 15,
    avatar: ''
  },
  {
    id: 4,
    name: 'Michael Brown',
    email: 'michael.brown@company.com',
    role: 'student',
    organization: 'Engineering Corp',
    status: 'inactive',
    lastLogin: new Date('2024-09-10'),
    assessments: 3,
    avatar: ''
  }
])

const filteredUsers = computed(() => {
  return users.value.filter(user => {
    const matchesRole = !filters.value.role || user.role === filters.value.role
    const matchesStatus = !filters.value.status || user.status === filters.value.status
    const matchesSearch = !filters.value.search ||
      user.name.toLowerCase().includes(filters.value.search.toLowerCase()) ||
      user.email.toLowerCase().includes(filters.value.search.toLowerCase())

    return matchesRole && matchesStatus && matchesSearch
  })
})

const getRoleType = (role) => {
  const roleMap = {
    'admin': 'danger',
    'instructor': 'warning',
    'student': 'info'
  }
  return roleMap[role] || 'info'
}

const getStatusType = (status) => {
  const statusMap = {
    'active': 'success',
    'inactive': 'info',
    'pending': 'warning'
  }
  return statusMap[status] || 'info'
}

const formatDate = (date) => {
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const editUser = (user) => {
  // Implement edit user functionality
  console.log('Edit user:', user)
}

const toggleUserStatus = async (user) => {
  try {
    const action = user.status === 'active' ? 'deactivate' : 'activate'
    await ElMessageBox.confirm(
      `Are you sure you want to ${action} this user?`,
      'Confirm Action',
      {
        confirmButtonText: action.charAt(0).toUpperCase() + action.slice(1),
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    user.status = user.status === 'active' ? 'inactive' : 'active'
    ElMessage.success(`User ${action}d successfully`)
  } catch {
    // User cancelled
  }
}

const deleteUser = async (user) => {
  try {
    await ElMessageBox.confirm(
      'This will permanently delete the user. Continue?',
      'Delete User',
      {
        confirmButtonText: 'Delete',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    const index = users.value.findIndex(u => u.id === user.id)
    if (index > -1) {
      users.value.splice(index, 1)
      ElMessage.success('User deleted successfully')
    }
  } catch {
    // User cancelled
  }
}

const createUser = () => {
  // Validate and create user
  const newUser = {
    id: users.value.length + 1,
    ...userForm.value,
    status: 'pending',
    lastLogin: new Date(),
    assessments: 0,
    avatar: ''
  }

  users.value.push(newUser)
  showCreateUser.value = false
  
  // Reset form
  userForm.value = {
    name: '',
    email: '',
    role: '',
    organization: '',
    department: ''
  }

  ElMessage.success('User created successfully')
}

const exportUsers = () => {
  ElMessage.info('Export functionality will be available soon')
}
</script>

<style scoped>
.user-management {
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

.filters-card {
  margin-bottom: 24px;
}

.users-table-card {
  margin-bottom: 32px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-details {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: 600;
  color: #303133;
}

.user-email {
  font-size: 12px;
  color: #909399;
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