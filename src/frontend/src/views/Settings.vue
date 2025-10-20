<template>
  <div class="settings">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><Setting /></el-icon> Settings</h1>
        <p>Customize your SE-QPT platform experience and preferences</p>
      </div>
    </div>

    <div class="settings-container">
      <el-row :gutter="24">
        <!-- Settings Navigation -->
        <el-col :span="6">
          <el-card class="settings-nav">
            <el-menu
              v-model="activeSection"
              mode="vertical"
              class="settings-menu"
            >
              <el-menu-item index="general">
                <el-icon><User /></el-icon>
                <span>General</span>
              </el-menu-item>
              <el-menu-item index="notifications">
                <el-icon><Bell /></el-icon>
                <span>Notifications</span>
              </el-menu-item>
              <el-menu-item index="learning">
                <el-icon><Reading /></el-icon>
                <span>Learning Preferences</span>
              </el-menu-item>
              <el-menu-item index="privacy">
                <el-icon><Lock /></el-icon>
                <span>Privacy & Security</span>
              </el-menu-item>
              <el-menu-item index="assessments">
                <el-icon><DocumentChecked /></el-icon>
                <span>Assessment Settings</span>
              </el-menu-item>
              <el-menu-item index="integrations">
                <el-icon><Link /></el-icon>
                <span>Integrations</span>
              </el-menu-item>
              <el-menu-item index="advanced">
                <el-icon><Tools /></el-icon>
                <span>Advanced</span>
              </el-menu-item>
            </el-menu>
          </el-card>
        </el-col>

        <!-- Settings Content -->
        <el-col :span="18">
          <!-- General Settings -->
          <el-card v-if="activeSection === 'general'" class="settings-card">
            <div class="section-header">
              <h2><el-icon><User /></el-icon> General Settings</h2>
              <p>Manage your basic account preferences and display settings</p>
            </div>

            <el-form :model="settings.general" label-width="200px">
              <el-form-item label="Language">
                <el-select v-model="settings.general.language">
                  <el-option label="English" value="en"></el-option>
                  <el-option label="German" value="de"></el-option>
                  <el-option label="French" value="fr"></el-option>
                  <el-option label="Spanish" value="es"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Timezone">
                <el-select v-model="settings.general.timezone">
                  <el-option label="UTC-8 (Pacific)" value="PST"></el-option>
                  <el-option label="UTC-5 (Eastern)" value="EST"></el-option>
                  <el-option label="UTC+0 (GMT)" value="GMT"></el-option>
                  <el-option label="UTC+1 (CET)" value="CET"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Theme">
                <el-radio-group v-model="settings.general.theme">
                  <el-radio label="light">Light</el-radio>
                  <el-radio label="dark">Dark</el-radio>
                  <el-radio label="auto">Auto (System)</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Date Format">
                <el-select v-model="settings.general.dateFormat">
                  <el-option label="MM/DD/YYYY" value="US"></el-option>
                  <el-option label="DD/MM/YYYY" value="EU"></el-option>
                  <el-option label="YYYY-MM-DD" value="ISO"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Auto-save Progress">
                <el-switch v-model="settings.general.autoSave" />
                <span class="setting-description">Automatically save your progress during assessments</span>
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Notification Settings -->
          <el-card v-if="activeSection === 'notifications'" class="settings-card">
            <div class="section-header">
              <h2><el-icon><Bell /></el-icon> Notification Settings</h2>
              <p>Control how and when you receive notifications</p>
            </div>

            <el-form :model="settings.notifications" label-width="250px">
              <el-form-item label="Email Notifications">
                <el-switch v-model="settings.notifications.email.enabled" />
              </el-form-item>

              <div v-if="settings.notifications.email.enabled" class="notification-subsection">
                <el-form-item label="Assessment Reminders">
                  <el-switch v-model="settings.notifications.email.assessmentReminders" />
                </el-form-item>

                <el-form-item label="Learning Plan Updates">
                  <el-switch v-model="settings.notifications.email.planUpdates" />
                </el-form-item>

                <el-form-item label="Competency Achievements">
                  <el-switch v-model="settings.notifications.email.achievements" />
                </el-form-item>

                <el-form-item label="Weekly Progress Summary">
                  <el-switch v-model="settings.notifications.email.weeklyProgress" />
                </el-form-item>
              </div>

              <el-form-item label="Browser Notifications">
                <el-switch v-model="settings.notifications.browser.enabled" />
              </el-form-item>

              <div v-if="settings.notifications.browser.enabled" class="notification-subsection">
                <el-form-item label="Real-time Updates">
                  <el-switch v-model="settings.notifications.browser.realTime" />
                </el-form-item>

                <el-form-item label="Learning Reminders">
                  <el-switch v-model="settings.notifications.browser.reminders" />
                </el-form-item>
              </div>

              <el-form-item label="Notification Frequency">
                <el-select v-model="settings.notifications.frequency">
                  <el-option label="Immediate" value="immediate"></el-option>
                  <el-option label="Daily Digest" value="daily"></el-option>
                  <el-option label="Weekly Digest" value="weekly"></el-option>
                </el-select>
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Learning Preferences -->
          <el-card v-if="activeSection === 'learning'" class="settings-card">
            <div class="section-header">
              <h2><el-icon><Reading /></el-icon> Learning Preferences</h2>
              <p>Customize your learning experience and content delivery</p>
            </div>

            <el-form :model="settings.learning" label-width="250px">
              <el-form-item label="Preferred Learning Style">
                <el-checkbox-group v-model="settings.learning.preferredStyles">
                  <el-checkbox label="visual">Visual Learning</el-checkbox>
                  <el-checkbox label="auditory">Auditory Learning</el-checkbox>
                  <el-checkbox label="kinesthetic">Hands-on Practice</el-checkbox>
                  <el-checkbox label="reading">Reading/Writing</el-checkbox>
                </el-checkbox-group>
              </el-form-item>

              <el-form-item label="Content Difficulty">
                <el-radio-group v-model="settings.learning.contentDifficulty">
                  <el-radio label="beginner">Beginner-friendly</el-radio>
                  <el-radio label="intermediate">Intermediate</el-radio>
                  <el-radio label="advanced">Advanced</el-radio>
                  <el-radio label="adaptive">Adaptive (Auto-adjust)</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Session Duration">
                <el-select v-model="settings.learning.sessionDuration">
                  <el-option label="15-30 minutes" value="short"></el-option>
                  <el-option label="30-60 minutes" value="medium"></el-option>
                  <el-option label="60+ minutes" value="long"></el-option>
                  <el-option label="Flexible" value="flexible"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Learning Reminders">
                <el-switch v-model="settings.learning.reminders.enabled" />
              </el-form-item>

              <div v-if="settings.learning.reminders.enabled" class="notification-subsection">
                <el-form-item label="Reminder Time">
                  <el-time-picker
                    v-model="settings.learning.reminders.time"
                    format="HH:mm"
                  />
                </el-form-item>

                <el-form-item label="Reminder Frequency">
                  <el-checkbox-group v-model="settings.learning.reminders.frequency">
                    <el-checkbox label="monday">Monday</el-checkbox>
                    <el-checkbox label="tuesday">Tuesday</el-checkbox>
                    <el-checkbox label="wednesday">Wednesday</el-checkbox>
                    <el-checkbox label="thursday">Thursday</el-checkbox>
                    <el-checkbox label="friday">Friday</el-checkbox>
                    <el-checkbox label="saturday">Saturday</el-checkbox>
                    <el-checkbox label="sunday">Sunday</el-checkbox>
                  </el-checkbox-group>
                </el-form-item>
              </div>

              <el-form-item label="Adaptive Learning">
                <el-switch v-model="settings.learning.adaptiveLearning" />
                <span class="setting-description">AI adjusts content based on your progress</span>
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Privacy & Security -->
          <el-card v-if="activeSection === 'privacy'" class="settings-card">
            <div class="section-header">
              <h2><el-icon><Lock /></el-icon> Privacy & Security</h2>
              <p>Manage your privacy settings and account security</p>
            </div>

            <el-form :model="settings.privacy" label-width="250px">
              <el-form-item label="Profile Visibility">
                <el-radio-group v-model="settings.privacy.profileVisibility">
                  <el-radio label="private">Private</el-radio>
                  <el-radio label="organization">Organization Only</el-radio>
                  <el-radio label="public">Public</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Share Progress Data">
                <el-switch v-model="settings.privacy.shareProgressData" />
                <span class="setting-description">Allow anonymized data for research</span>
              </el-form-item>

              <el-form-item label="Two-Factor Authentication">
                <el-switch v-model="settings.privacy.twoFactorAuth" />
                <el-button v-if="!settings.privacy.twoFactorAuth" type="primary" size="small">
                  Setup 2FA
                </el-button>
              </el-form-item>

              <el-form-item label="Session Timeout">
                <el-select v-model="settings.privacy.sessionTimeout">
                  <el-option label="30 minutes" value="30"></el-option>
                  <el-option label="1 hour" value="60"></el-option>
                  <el-option label="4 hours" value="240"></el-option>
                  <el-option label="8 hours" value="480"></el-option>
                </el-select>
              </el-form-item>

              <el-divider />

              <div class="privacy-actions">
                <h3>Data Management</h3>
                <p>Manage your personal data and privacy rights</p>

                <div class="action-buttons">
                  <el-button @click="exportData">
                    <el-icon><Download /></el-icon>
                    Export My Data
                  </el-button>
                  <el-button @click="showDeleteAccount = true" type="danger">
                    <el-icon><Delete /></el-icon>
                    Delete Account
                  </el-button>
                </div>
              </div>
            </el-form>
          </el-card>

          <!-- Assessment Settings -->
          <el-card v-if="activeSection === 'assessments'" class="settings-card">
            <div class="section-header">
              <h2><el-icon><DocumentChecked /></el-icon> Assessment Settings</h2>
              <p>Configure your assessment and evaluation preferences</p>
            </div>

            <el-form :model="settings.assessments" label-width="250px">
              <el-form-item label="Assessment Mode">
                <el-radio-group v-model="settings.assessments.mode">
                  <el-radio label="standard">Standard</el-radio>
                  <el-radio label="adaptive">Adaptive</el-radio>
                  <el-radio label="comprehensive">Comprehensive</el-radio>
                </el-radio-group>
              </el-form-item>

              <el-form-item label="Auto-submit on Time">
                <el-switch v-model="settings.assessments.autoSubmit" />
                <span class="setting-description">Automatically submit when time expires</span>
              </el-form-item>

              <el-form-item label="Show Immediate Feedback">
                <el-switch v-model="settings.assessments.immediateFeedback" />
              </el-form-item>

              <el-form-item label="Retake Policy">
                <el-select v-model="settings.assessments.retakePolicy">
                  <el-option label="Unlimited" value="unlimited"></el-option>
                  <el-option label="3 attempts" value="3"></el-option>
                  <el-option label="1 attempt only" value="1"></el-option>
                </el-select>
              </el-form-item>

              <el-form-item label="Assessment Reminders">
                <el-switch v-model="settings.assessments.reminders" />
              </el-form-item>
            </el-form>
          </el-card>

          <!-- Placeholder for other sections -->
          <el-card v-if="activeSection === 'integrations'" class="settings-card">
            <div class="placeholder-section">
              <el-icon size="64"><Link /></el-icon>
              <h2>Integrations</h2>
              <p>Connect with external tools and services</p>
              <div class="coming-soon">Coming Soon</div>
            </div>
          </el-card>

          <el-card v-if="activeSection === 'advanced'" class="settings-card">
            <div class="placeholder-section">
              <el-icon size="64"><Tools /></el-icon>
              <h2>Advanced Settings</h2>
              <p>Advanced configuration options for power users</p>
              <div class="coming-soon">Coming Soon</div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Save Actions -->
      <div class="save-actions">
        <el-button @click="resetSettings">Reset to Defaults</el-button>
        <el-button type="primary" @click="saveSettings">
          <el-icon><Check /></el-icon>
          Save Settings
        </el-button>
      </div>

      <!-- Delete Account Dialog -->
      <el-dialog
        v-model="showDeleteAccount"
        title="Delete Account"
        width="500px"
        :show-close="false"
      >
        <el-alert type="warning" show-icon :closable="false">
          <template #title>Warning: This action cannot be undone</template>
          Deleting your account will permanently remove all your data, including assessments, learning progress, and qualification plans.
        </el-alert>

        <div style="margin: 20px 0;">
          <p>To confirm, please type "DELETE" in the field below:</p>
          <el-input v-model="deleteConfirmation" placeholder="Type DELETE to confirm" />
        </div>

        <template #footer>
          <el-button @click="showDeleteAccount = false">Cancel</el-button>
          <el-button
            type="danger"
            :disabled="deleteConfirmation !== 'DELETE'"
            @click="deleteAccount"
          >
            Delete Account
          </el-button>
        </template>
      </el-dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Setting, User, Bell, Reading, Lock, DocumentChecked, Link, Tools,
  Download, Delete, Check
} from '@element-plus/icons-vue'

const activeSection = ref('general')
const showDeleteAccount = ref(false)
const deleteConfirmation = ref('')

const settings = reactive({
  general: {
    language: 'en',
    timezone: 'PST',
    theme: 'light',
    dateFormat: 'US',
    autoSave: true
  },
  notifications: {
    email: {
      enabled: true,
      assessmentReminders: true,
      planUpdates: true,
      achievements: true,
      weeklyProgress: false
    },
    browser: {
      enabled: true,
      realTime: true,
      reminders: false
    },
    frequency: 'immediate'
  },
  learning: {
    preferredStyles: ['visual', 'kinesthetic'],
    contentDifficulty: 'intermediate',
    sessionDuration: 'medium',
    reminders: {
      enabled: true,
      time: new Date(2024, 0, 1, 9, 0), // 9:00 AM
      frequency: ['monday', 'wednesday', 'friday']
    },
    adaptiveLearning: true
  },
  privacy: {
    profileVisibility: 'organization',
    shareProgressData: true,
    twoFactorAuth: false,
    sessionTimeout: '240'
  },
  assessments: {
    mode: 'standard',
    autoSubmit: true,
    immediateFeedback: false,
    retakePolicy: '3',
    reminders: true
  }
})

const saveSettings = () => {
  // Here you would typically save to the store/API
  ElMessage.success('Settings saved successfully!')
  console.log('Settings saved:', settings)
}

const resetSettings = async () => {
  try {
    await ElMessageBox.confirm(
      'This will reset all settings to their default values. Continue?',
      'Reset Settings',
      {
        confirmButtonText: 'Reset',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }
    )

    // Reset to default values
    Object.assign(settings.general, {
      language: 'en',
      timezone: 'PST',
      theme: 'light',
      dateFormat: 'US',
      autoSave: true
    })

    // Reset other sections similarly...
    ElMessage.success('Settings reset to defaults')
  } catch {
    // User cancelled
  }
}

const exportData = () => {
  // Implement data export functionality
  ElMessage.info('Data export feature will be available soon')
}

const deleteAccount = () => {
  if (deleteConfirmation.value === 'DELETE') {
    // Implement account deletion
    ElMessage.success('Account deletion process initiated')
    showDeleteAccount.value = false
  }
}
</script>

<style scoped>
.settings {
  padding: 24px;
  background-color: #f5f7fa;
  min-height: 100vh;
}

.page-header {
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

.settings-container {
  max-width: 1200px;
  margin: 0 auto;
}

.settings-nav {
  position: sticky;
  top: 24px;
}

.settings-menu {
  border: none;
}

.settings-menu .el-menu-item {
  height: 48px;
  line-height: 48px;
}

.settings-card {
  min-height: 500px;
}

.section-header {
  margin-bottom: 32px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e4e7ed;
}

.section-header h2 {
  margin: 0 0 8px 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-header p {
  margin: 0;
  color: #606266;
}

.setting-description {
  margin-left: 12px;
  font-size: 12px;
  color: #909399;
}

.notification-subsection {
  margin-left: 24px;
  padding-left: 24px;
  border-left: 2px solid #e4e7ed;
}

.privacy-actions {
  margin-top: 32px;
  padding-top: 24px;
}

.privacy-actions h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.privacy-actions p {
  margin: 0 0 16px 0;
  color: #606266;
}

.action-buttons {
  display: flex;
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

.save-actions {
  margin-top: 32px;
  text-align: center;
  padding: 24px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.save-actions .el-button {
  margin: 0 8px;
}
</style>