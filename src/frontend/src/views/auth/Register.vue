<template>
  <div class="register-form">
    <!-- Registration Type Tabs -->
    <el-tabs v-model="registrationType" class="registration-tabs">
        <el-tab-pane label="Admin Registration" name="admin">
          <el-form
            ref="adminFormRef"
            :model="adminForm"
            :rules="adminRules"
            label-position="top"
            size="large"
            @submit.prevent="handleAdminRegister"
          >
            <el-form-item label="Username" prop="username">
              <el-input
                v-model="adminForm.username"
                placeholder="Choose a unique username"
                size="large"
              />
            </el-form-item>

            <el-form-item label="Password" prop="password">
              <el-input
                v-model="adminForm.password"
                type="password"
                placeholder="Choose a strong password"
                size="large"
                show-password
              />
            </el-form-item>

            <el-form-item label="Confirm Password" prop="confirmPassword">
              <el-input
                v-model="adminForm.confirmPassword"
                type="password"
                placeholder="Re-enter your password"
                size="large"
                show-password
              />
            </el-form-item>

            <el-form-item label="Organization Name" prop="organizationName">
              <el-input
                v-model="adminForm.organizationName"
                placeholder="Enter your organization name"
                size="large"
              />
            </el-form-item>

            <el-form-item label="Organization Size" prop="organizationSize">
              <el-select
                v-model="adminForm.organizationSize"
                placeholder="Select organization size"
                size="large"
                style="width: 100%"
              >
                <el-option label="Small (< 100 employees)" value="small" />
                <el-option label="Medium (100-1000 employees)" value="medium" />
                <el-option label="Large (1000-10000 employees)" value="large" />
                <el-option label="Enterprise (> 10000 employees)" value="enterprise" />
              </el-select>
            </el-form-item>

            <el-alert
              v-if="authStore.error"
              :title="authStore.error"
              type="error"
              show-icon
              :closable="false"
              class="mb-4"
            />

            <el-form-item>
              <el-button
                type="primary"
                size="large"
                native-type="submit"
                :loading="loading"
                style="width: 100%"
              >
                <span v-if="loading">Creating Account...</span>
                <span v-else>Create Admin Account</span>
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="Employee Registration" name="employee">
          <el-form
            ref="employeeFormRef"
            :model="employeeForm"
            :rules="employeeRules"
            label-position="top"
            size="large"
            @submit.prevent="handleEmployeeRegister"
          >
            <el-form-item label="Username" prop="username">
              <el-input
                v-model="employeeForm.username"
                placeholder="Choose a unique username"
                size="large"
              />
            </el-form-item>

            <el-form-item label="Password" prop="password">
              <el-input
                v-model="employeeForm.password"
                type="password"
                placeholder="Choose a strong password"
                size="large"
                show-password
              />
            </el-form-item>

            <el-form-item label="Confirm Password" prop="confirmPassword">
              <el-input
                v-model="employeeForm.confirmPassword"
                type="password"
                placeholder="Re-enter your password"
                size="large"
                show-password
              />
            </el-form-item>

            <el-form-item label="Organization Code" prop="organizationCode">
              <el-input
                v-model="employeeForm.organizationCode"
                placeholder="Enter organization code from your admin"
                size="large"
                @blur="handleOrgCodeBlur"
              >
                <template #suffix>
                  <el-icon v-if="orgCodeVerifying" class="is-loading">
                    <Loading />
                  </el-icon>
                  <el-icon v-else-if="orgCodeValid" style="color: #67c23a">
                    <CircleCheck />
                  </el-icon>
                  <el-icon v-else-if="orgCodeChecked && !orgCodeValid" style="color: #f56c6c">
                    <CircleClose />
                  </el-icon>
                </template>
              </el-input>
              <div v-if="orgCodeValid && organizationName" class="org-name-display">
                <el-icon><OfficeBuilding /></el-icon>
                <span>{{ organizationName }}</span>
              </div>
            </el-form-item>

            <el-alert
              v-if="authStore.error"
              :title="authStore.error"
              type="error"
              show-icon
              :closable="false"
              class="mb-4"
            />

            <el-form-item>
              <el-button
                type="primary"
                size="large"
                native-type="submit"
                :loading="loading"
                :disabled="!orgCodeValid"
                style="width: 100%"
              >
                <span v-if="loading">Creating Account...</span>
                <span v-else>Create Employee Account</span>
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'
import {
  UserFilled,
  Loading,
  CircleCheck,
  CircleClose,
  OfficeBuilding
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const registrationType = ref('admin')
const loading = ref(false)

// Admin form
const adminFormRef = ref(null)
const adminForm = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  organizationName: '',
  organizationSize: ''
})

const validatePasswordMatch = (rule, value, callback) => {
  if (value !== adminForm.password) {
    callback(new Error('Passwords do not match'))
  } else {
    callback()
  }
}

const adminRules = {
  username: [
    { required: true, message: 'Username is required', trigger: 'blur' },
    { min: 3, message: 'Username must be at least 3 characters', trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Password is required', trigger: 'blur' },
    { min: 6, message: 'Password must be at least 6 characters', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: 'Please confirm your password', trigger: 'blur' },
    { validator: validatePasswordMatch, trigger: 'blur' }
  ],
  organizationName: [
    { required: true, message: 'Organization name is required', trigger: 'blur' }
  ],
  organizationSize: [
    { required: true, message: 'Organization size is required', trigger: 'change' }
  ]
}

// Employee form
const employeeFormRef = ref(null)
const employeeForm = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  organizationCode: ''
})

const orgCodeVerifying = ref(false)
const orgCodeValid = ref(false)
const orgCodeChecked = ref(false)
const organizationName = ref('')

const validateEmployeePasswordMatch = (rule, value, callback) => {
  if (value !== employeeForm.password) {
    callback(new Error('Passwords do not match'))
  } else {
    callback()
  }
}

const employeeRules = {
  username: [
    { required: true, message: 'Username is required', trigger: 'blur' },
    { min: 3, message: 'Username must be at least 3 characters', trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Password is required', trigger: 'blur' },
    { min: 6, message: 'Password must be at least 6 characters', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: 'Please confirm your password', trigger: 'blur' },
    { validator: validateEmployeePasswordMatch, trigger: 'blur' }
  ],
  organizationCode: [
    { required: true, message: 'Organization code is required', trigger: 'blur' }
  ]
}

// Handlers
const handleAdminRegister = async () => {
  if (!adminFormRef.value) return

  await adminFormRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true
    try {
      const result = await authStore.registerAdmin({
        username: adminForm.username,
        password: adminForm.password,
        organizationName: adminForm.organizationName,
        organizationSize: adminForm.organizationSize
      })

      if (result.success) {
        toast.success('Admin registration successful! Please log in.')
        router.push('/auth/login')
      }
    } catch (error) {
      console.error('Admin registration failed:', error)
    } finally {
      loading.value = false
    }
  })
}

const handleEmployeeRegister = async () => {
  if (!employeeFormRef.value) return

  await employeeFormRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true
    try {
      const result = await authStore.registerEmployee({
        username: employeeForm.username,
        password: employeeForm.password,
        organizationCode: employeeForm.organizationCode
      })

      if (result.success) {
        toast.success('Registration successful! Please log in.')
        router.push('/auth/login')
      }
    } catch (error) {
      console.error('Employee registration failed:', error)
    } finally {
      loading.value = false
    }
  })
}

const handleOrgCodeBlur = async () => {
  if (!employeeForm.organizationCode) {
    orgCodeChecked.value = false
    orgCodeValid.value = false
    organizationName.value = ''
    return
  }

  orgCodeVerifying.value = true
  orgCodeChecked.value = true

  try {
    const result = await authStore.verifyOrgCode(employeeForm.organizationCode)
    orgCodeValid.value = result.valid
    organizationName.value = result.organization_name || ''
  } catch (error) {
    orgCodeValid.value = false
    organizationName.value = ''
  } finally {
    orgCodeVerifying.value = false
  }
}

</script>

<style scoped>
.register-form {
  width: 100%;
}

.registration-tabs {
  margin-bottom: 0;
}

.mb-4 {
  margin-bottom: 16px;
}

.org-name-display {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding: 8px 12px;
  background: #f0f9ff;
  border-radius: 4px;
  color: #409eff;
  font-size: 14px;
}
</style>
