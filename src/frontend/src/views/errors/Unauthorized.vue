<template>
  <div class="unauthorized">
    <div class="error-container">
      <div class="error-content">
        <div class="error-illustration">
          <el-icon size="120" class="error-icon"><Lock /></el-icon>
        </div>

        <div class="error-details">
          <h1 class="error-code">401</h1>
          <h2 class="error-title">Access Denied</h2>
          <p class="error-description">
            You don't have permission to access this resource. This could be because:
          </p>
          <ul class="error-reasons">
            <li>You need to log in to access this page</li>
            <li>Your session has expired</li>
            <li>You don't have the required permissions</li>
            <li>This area is restricted to administrators only</li>
          </ul>
        </div>

        <div class="error-actions">
          <el-button type="primary" size="large" @click="login" v-if="!isAuthenticated">
            <el-icon><Key /></el-icon>
            Log In
          </el-button>
          <el-button type="primary" size="large" @click="refreshAuth" v-else>
            <el-icon><Refresh /></el-icon>
            Refresh Session
          </el-button>
          <el-button size="large" @click="goHome">
            <el-icon><HomeFilled /></el-icon>
            Go to Home
          </el-button>
          <el-button size="large" @click="goBack">
            <el-icon><ArrowLeft /></el-icon>
            Go Back
          </el-button>
        </div>

        <div class="access-levels">
          <h3>Access Levels</h3>
          <div class="levels-grid">
            <div class="level-item">
              <el-icon><User /></el-icon>
              <div class="level-info">
                <div class="level-name">Student</div>
                <div class="level-description">Access to assessments and learning materials</div>
              </div>
            </div>
            <div class="level-item">
              <el-icon><Reading /></el-icon>
              <div class="level-info">
                <div class="level-name">Instructor</div>
                <div class="level-description">Create and manage learning content</div>
              </div>
            </div>
            <div class="level-item">
              <el-icon><Setting /></el-icon>
              <div class="level-info">
                <div class="level-name">Administrator</div>
                <div class="level-description">Full system access and configuration</div>
              </div>
            </div>
          </div>
        </div>

        <div class="help-section">
          <h3>Need Help?</h3>
          <p>If you believe you should have access to this resource:</p>
          <div class="help-actions">
            <el-button text type="primary" @click="requestAccess">
              <el-icon><Message /></el-icon>
              Request Access
            </el-button>
            <el-button text type="primary" @click="contactAdmin">
              <el-icon><Service /></el-icon>
              Contact Administrator
            </el-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Lock, Key, Refresh, HomeFilled, ArrowLeft, User, Reading, Setting,
  Message, Service
} from '@element-plus/icons-vue'

const router = useRouter()

// This would typically come from your auth store
const isAuthenticated = computed(() => {
  // Replace with actual auth check
  return false
})

const login = () => {
  router.push({
    name: 'Login',
    query: { redirect: router.currentRoute.value.fullPath }
  })
}

const refreshAuth = async () => {
  try {
    // Implement auth refresh logic
    ElMessage.info('Refreshing authentication...')
    // After successful refresh, redirect to intended page
  } catch (error) {
    ElMessage.error('Failed to refresh authentication')
  }
}

const goHome = () => {
  router.push('/')
}

const goBack = () => {
  router.go(-1)
}

const requestAccess = () => {
  ElMessage.info('Access request functionality will be available soon')
}

const contactAdmin = () => {
  ElMessage.info('Admin contact functionality will be available soon')
}
</script>

<style scoped>
.unauthorized {
  min-height: 100vh;
  background: linear-gradient(135deg, #f56c6c 0%, #e6a23c 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.error-container {
  max-width: 650px;
  width: 100%;
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.error-content {
  padding: 60px 40px;
  text-align: center;
}

.error-illustration {
  margin-bottom: 32px;
}

.error-icon {
  color: #f56c6c;
  opacity: 0.8;
}

.error-code {
  font-size: 72px;
  font-weight: bold;
  color: #303133;
  margin: 0 0 16px 0;
  line-height: 1;
}

.error-title {
  font-size: 32px;
  color: #303133;
  margin: 0 0 16px 0;
  font-weight: 600;
}

.error-description {
  font-size: 16px;
  color: #606266;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.error-reasons {
  text-align: left;
  max-width: 400px;
  margin: 0 auto 40px auto;
  color: #606266;
  line-height: 1.6;
}

.error-reasons li {
  margin-bottom: 8px;
}

.error-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 48px;
}

.access-levels {
  margin-bottom: 40px;
}

.access-levels h3 {
  color: #303133;
  margin: 0 0 24px 0;
  font-size: 18px;
}

.levels-grid {
  display: grid;
  gap: 16px;
  text-align: left;
}

.level-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #f8f9fa;
}

.level-item .el-icon {
  font-size: 24px;
  color: #409eff;
}

.level-name {
  font-weight: 600;
  color: #303133;
  margin-bottom: 4px;
}

.level-description {
  font-size: 14px;
  color: #606266;
}

.help-section {
  border-top: 1px solid #e4e7ed;
  padding-top: 32px;
}

.help-section h3 {
  color: #303133;
  margin: 0 0 12px 0;
  font-size: 18px;
}

.help-section p {
  color: #606266;
  margin: 0 0 20px 0;
  font-size: 14px;
}

.help-actions {
  display: flex;
  justify-content: center;
  gap: 24px;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .error-content {
    padding: 40px 24px;
  }

  .error-code {
    font-size: 56px;
  }

  .error-title {
    font-size: 24px;
  }

  .error-actions {
    flex-direction: column;
    align-items: center;
  }

  .help-actions {
    flex-direction: column;
    align-items: center;
    gap: 12px;
  }
}
</style>"