<template>
  <div class="system-config">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Setting /></el-icon> System Configuration</h1>
        <p>Configure system settings, parameters, and platform behavior</p>
      </div>
      <div class="header-actions">
        <el-button @click="resetToDefaults">
          <el-icon><RefreshLeft /></el-icon>
          Reset to Defaults
        </el-button>
        <el-button type="primary" @click="saveConfiguration">
          <el-icon><Check /></el-icon>
          Save Configuration
        </el-button>
      </div>
    </div>

    <div class="config-container">
      <el-row :gutter="24">
        <!-- Configuration Navigation -->
        <el-col :span="6">
          <el-card class="config-nav">
            <el-menu v-model="activeSection" mode="vertical">
              <el-menu-item index="general">
                <el-icon><Tools /></el-icon>
                <span>General Settings</span>
              </el-menu-item>
              <el-menu-item index="assessment">
                <el-icon><DocumentChecked /></el-icon>
                <span>Assessment Config</span>
              </el-menu-item>
              <el-menu-item index="ai">
                <el-icon><Cpu /></el-icon>
                <span>AI/LLM Settings</span>
              </el-menu-item>
              <el-menu-item index="notifications">
                <el-icon><Bell /></el-icon>
                <span>Notifications</span>
              </el-menu-item>
              <el-menu-item index="security">
                <el-icon><Lock /></el-icon>
                <span>Security</span>
              </el-menu-item>
              <el-menu-item index="integrations">
                <el-icon><Link /></el-icon>
                <span>Integrations</span>
              </el-menu-item>
            </el-menu>
          </el-card>
        </el-col>

        <!-- Configuration Content -->
        <el-col :span="18">
          <!-- General Settings -->
          <el-card v-if="activeSection === 'general'" class="config-card">
            <div class="section-header">
              <h2><el-icon><Tools /></el-icon> General Settings</h2>
            </div>

            <el-form :model="config.general" label-width="200px">
              <el-form-item label="Platform Name">
                <el-input v-model="config.general.platformName" />
              </el-form-item>
              <el-form-item label="Default Language">
                <el-select v-model="config.general.defaultLanguage">
                  <el-option label="English" value="en"></el-option>
                  <el-option label="German" value="de"></el-option>
                  <el-option label="French" value="fr"></el-option>
                </el-select>
              </el-form-item>
              <el-form-item label="Session Timeout (minutes)">
                <el-input-number v-model="config.general.sessionTimeout" :min="15" :max="480" />
              </el-form-item>
              <el-form-item label="Max File Upload Size (MB)">
                <el-input-number v-model="config.general.maxFileSize" :min="1" :max="100" />
              </el-form-item>
              <el-form-item label="Enable User Registration">
                <el-switch v-model="config.general.enableRegistration" />
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Assessment Configuration -->
          <el-card v-if="activeSection === 'assessment'" class="config-card">
            <div class="section-header">
              <h2><el-icon><DocumentChecked /></el-icon> Assessment Configuration</h2>
            </div>

            <el-form :model="config.assessment" label-width="250px">
              <el-form-item label="Default Assessment Duration (min)">
                <el-input-number v-model="config.assessment.defaultDuration" :min="15" :max="180" />
              </el-form-item>
              <el-form-item label="Auto-save Interval (seconds)">
                <el-input-number v-model="config.assessment.autoSaveInterval" :min="30" :max="300" />
              </el-form-item>
              <el-form-item label="Max Retake Attempts">
                <el-input-number v-model="config.assessment.maxRetakes" :min="1" :max="10" />
              </el-form-item>
              <el-form-item label="Passing Score (%)">
                <el-input-number v-model="config.assessment.passingScore" :min="50" :max="100" />
              </el-form-item>
              <el-form-item label="Enable Immediate Feedback">
                <el-switch v-model="config.assessment.immediateFeedback" />
              </el-form-item>
              <el-form-item label="Randomize Question Order">
                <el-switch v-model="config.assessment.randomizeQuestions" />
              </el-form-item>
            </el-form>
          </el-card>

          <!-- AI/LLM Settings -->
          <el-card v-if="activeSection === 'ai'" class="config-card">
            <div class="section-header">
              <h2><el-icon><Cpu /></el-icon> AI/LLM Settings</h2>
            </div>

            <el-form :model="config.ai" label-width="200px">
              <el-form-item label="LLM Provider">
                <el-select v-model="config.ai.provider">
                  <el-option label="OpenAI GPT-4" value="openai-gpt4"></el-option>
                  <el-option label="Anthropic Claude" value="anthropic-claude"></el-option>
                  <el-option label="Local Model" value="local"></el-option>
                </el-select>
              </el-form-item>
              <el-form-item label="API Endpoint">
                <el-input v-model="config.ai.endpoint" />
              </el-form-item>
              <el-form-item label="Temperature">
                <el-slider v-model="config.ai.temperature" :min="0" :max="1" :step="0.1" show-input />
              </el-form-item>
              <el-form-item label="Max Tokens">
                <el-input-number v-model="config.ai.maxTokens" :min="100" :max="4000" />
              </el-form-item>
              <el-form-item label="Enable RAG">
                <el-switch v-model="config.ai.enableRAG" />
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Features Placeholder for other sections -->
          <el-card v-if="activeSection === 'notifications'" class="config-card">
            <div class="placeholder-section">
              <el-icon size="64"><Bell /></el-icon>
              <h2>Notification Settings</h2>
              <p>Configure email, SMS, and push notification settings</p>
              <div class="coming-soon">Coming Soon</div>
            </div>
          </el-card>

          <el-card v-if="activeSection === 'security'" class="config-card">
            <div class="placeholder-section">
              <el-icon size="64"><Lock /></el-icon>
              <h2>Security Configuration</h2>
              <p>Manage authentication, authorization, and security policies</p>
              <div class="coming-soon">Coming Soon</div>
            </div>
          </el-card>

          <el-card v-if="activeSection === 'integrations'" class="config-card">
            <div class="placeholder-section">
              <el-icon size="64"><Link /></el-icon>
              <h2>External Integrations</h2>
              <p>Configure connections to external systems and APIs</p>
              <div class="coming-soon">Coming Soon</div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced System Configuration</h2>
          <p>Comprehensive system configuration management for the SE-QPT platform.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Environment-specific configuration management</li>
              <li>Configuration validation and rollback capabilities</li>
              <li>Real-time configuration updates without restarts</li>
              <li>Configuration audit logging and change tracking</li>
              <li>Advanced security and compliance settings</li>
              <li>Integration with external configuration stores</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Setting, RefreshLeft, Check, Tools, DocumentChecked, Cpu, Bell, Lock, Link
} from '@element-plus/icons-vue'

const activeSection = ref('general')

const config = reactive({
  general: {
    platformName: 'SE-QPT Platform',
    defaultLanguage: 'en',
    sessionTimeout: 120,
    maxFileSize: 10,
    enableRegistration: true
  },
  assessment: {
    defaultDuration: 60,
    autoSaveInterval: 60,
    maxRetakes: 3,
    passingScore: 70,
    immediateFeedback: false,
    randomizeQuestions: true
  },
  ai: {
    provider: 'openai-gpt4',
    endpoint: 'https://api.openai.com/v1',
    temperature: 0.7,
    maxTokens: 2000,
    enableRAG: true
  }
})

const saveConfiguration = async () => {
  try {
    // Here you would typically save to the API
    ElMessage.success('Configuration saved successfully!')
    console.log('Configuration saved:', config)
  } catch (error) {
    ElMessage.error('Failed to save configuration')
  }
}

const resetToDefaults = async () => {
  try {
    await ElMessageBox.confirm(
      'This will reset all configuration to default values. Continue?',
      'Reset Configuration',
      {
        confirmButtonText: 'Reset',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    // Reset to default values
    Object.assign(config.general, {
      platformName: 'SE-QPT Platform',
      defaultLanguage: 'en',
      sessionTimeout: 120,
      maxFileSize: 10,
      enableRegistration: true
    })

    Object.assign(config.assessment, {
      defaultDuration: 60,
      autoSaveInterval: 60,
      maxRetakes: 3,
      passingScore: 70,
      immediateFeedback: false,
      randomizeQuestions: true
    })

    Object.assign(config.ai, {
      provider: 'openai-gpt4',
      endpoint: 'https://api.openai.com/v1',
      temperature: 0.7,
      maxTokens: 2000,
      enableRAG: true
    })

    ElMessage.success('Configuration reset to defaults')
  } catch {
    // User cancelled
  }
}
</script>

<style scoped>
.system-config {
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

.config-container {
  max-width: 1200px;
  margin: 0 auto;
}

.config-nav {
  position: sticky;
  top: 24px;
}

.config-nav .el-menu {
  border: none;
}

.config-card {
  min-height: 500px;
}

.section-header {
  margin-bottom: 32px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e4e7ed;
}

.section-header h2 {
  margin: 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 12px;
}

.placeholder-section {
  text-align: center;
  padding: 80px 40px;
  color: #909399;
}

.placeholder-section h2 {
  margin: 16px 0 8px 0;
  color: #606266;
}

.placeholder-section p {
  margin: 0 0 16px 0;
}

.coming-soon {
  display: inline-block;
  padding: 8px 16px;
  background: #f0f9ff;
  color: #409eff;
  border-radius: 20px;
  font-size: 14px;
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
</style>"