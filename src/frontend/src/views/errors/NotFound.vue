<template>
  <div class="not-found">
    <div class="error-container">
      <div class="error-content">
        <div class="error-illustration">
          <el-icon size="120" class="error-icon"><WarningFilled /></el-icon>
        </div>

        <div class="error-details">
          <h1 class="error-code">404</h1>
          <h2 class="error-title">Page Not Found</h2>
          <p class="error-description">
            Sorry, the page you are looking for doesn't exist or has been moved.
            Please check the URL or use the navigation menu to find what you're looking for.
          </p>
        </div>

        <div class="error-actions">
          <el-button type="primary" size="large" @click="goHome">
            <el-icon><HomeFilled /></el-icon>
            Go to Home
          </el-button>
          <el-button size="large" @click="goBack">
            <el-icon><ArrowLeft /></el-icon>
            Go Back
          </el-button>
          <el-button size="large" @click="$router.push('/app/dashboard')">
            <el-icon><Monitor /></el-icon>
            Dashboard
          </el-button>
        </div>

        <div class="helpful-links">
          <h3>Helpful Links</h3>
          <div class="links-grid">
            <router-link to="/app/assessments" class="help-link">
              <el-icon><DocumentChecked /></el-icon>
              <span>Take Assessment</span>
            </router-link>
            <router-link to="/app/plans" class="help-link">
              <el-icon><Collection /></el-icon>
              <span>Qualification Plans</span>
            </router-link>
            <router-link to="/app/objectives" class="help-link">
              <el-icon><Aim /></el-icon>
              <span>Learning Objectives</span>
            </router-link>
            <router-link to="/app/profile" class="help-link">
              <el-icon><User /></el-icon>
              <span>User Profile</span>
            </router-link>
          </div>
        </div>

        <div class="contact-support">
          <p>Still can't find what you're looking for?</p>
          <el-button text type="primary" @click="contactSupport">
            <el-icon><Service /></el-icon>
            Contact Support
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  WarningFilled, HomeFilled, ArrowLeft, Monitor, DocumentChecked,
  Collection, Aim, User, Service
} from '@element-plus/icons-vue'

const router = useRouter()

const goHome = () => {
  router.push('/')
}

const goBack = () => {
  router.go(-1)
}

const contactSupport = () => {
  ElMessage.info('Support contact functionality will be available soon')
}
</script>

<style scoped>
.not-found {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.error-container {
  max-width: 600px;
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
  margin: 0 0 40px 0;
}

.error-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 48px;
}

.helpful-links {
  margin-bottom: 40px;
}

.helpful-links h3 {
  color: #303133;
  margin: 0 0 20px 0;
  font-size: 18px;
}

.links-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 16px;
}

.help-link {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 20px;
  border: 2px solid #e4e7ed;
  border-radius: 12px;
  text-decoration: none;
  color: #606266;
  transition: all 0.3s ease;
}

.help-link:hover {
  border-color: #409eff;
  color: #409eff;
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(64, 158, 255, 0.1);
}

.help-link .el-icon {
  font-size: 24px;
}

.help-link span {
  font-size: 14px;
  font-weight: 500;
}

.contact-support {
  border-top: 1px solid #e4e7ed;
  padding-top: 32px;
}

.contact-support p {
  color: #909399;
  margin: 0 0 16px 0;
  font-size: 14px;
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

  .links-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>