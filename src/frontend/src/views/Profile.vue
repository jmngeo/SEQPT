<template>
  <div class="profile">
    <div class="page-header">
      <div class="header-content">
        <h1><el-icon><User /></el-icon> User Profile</h1>
        <p>Manage your personal information and competency profile</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="editMode = !editMode">
          <el-icon><Edit /></el-icon>
          {{ editMode ? 'Cancel' : 'Edit Profile' }}
        </el-button>
      </div>
    </div>

    <div class="profile-container">
      <el-row :gutter="24">
        <!-- Personal Information -->
        <el-col :span="8">
          <el-card class="profile-card">
            <div class="profile-header">
              <div class="avatar-section">
                <el-avatar :size="80" :src="userProfile.avatar">
                  {{ userProfile.name.charAt(0) }}
                </el-avatar>
                <el-button v-if="editMode" text @click="changeAvatar">
                  Change Photo
                </el-button>
              </div>
              <div class="profile-info">
                <h2>{{ userProfile.name }}</h2>
                <p class="role">{{ userProfile.role }}</p>
                <p class="organization">{{ userProfile.organization }}</p>
              </div>
            </div>

            <el-divider />

            <div class="profile-details">
              <div class="detail-item">
                <label>Email:</label>
                <span>{{ userProfile.email }}</span>
              </div>
              <div class="detail-item">
                <label>Department:</label>
                <span>{{ userProfile.department }}</span>
              </div>
              <div class="detail-item">
                <label>Experience:</label>
                <span>{{ userProfile.experience }} years</span>
              </div>
              <div class="detail-item">
                <label>Location:</label>
                <span>{{ userProfile.location }}</span>
              </div>
              <div class="detail-item">
                <label>Joined:</label>
                <span>{{ formatDate(userProfile.joinedDate) }}</span>
              </div>
            </div>

            <el-divider />

            <div class="profile-stats">
              <div class="stat-item">
                <div class="stat-value">{{ userProfile.stats.completedAssessments }}</div>
                <div class="stat-label">Assessments</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">{{ userProfile.stats.qualificationPlans }}</div>
                <div class="stat-label">Qualification Plans</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">{{ userProfile.stats.learningHours }}</div>
                <div class="stat-label">Learning Hours</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <!-- Competency Profile -->
        <el-col :span="16">
          <el-card class="competency-card">
            <div class="card-header">
              <h2><el-icon><Cpu /></el-icon> Competency Profile</h2>
              <el-button text @click="$router.push('/app/assessments')">
                <el-icon><DocumentChecked /></el-icon>
                Take Assessment
              </el-button>
            </div>

            <div class="competency-overview">
              <div class="overall-score">
                <el-progress
                  type="circle"
                  :percentage="overallCompetencyScore"
                  :width="120"
                  :stroke-width="10"
                  :color="getScoreColor(overallCompetencyScore)"
                >
                  <span class="score-text">{{ overallCompetencyScore }}%</span>
                </el-progress>
                <div class="score-info">
                  <h3>Overall Competency</h3>
                  <p>Based on latest assessment</p>
                </div>
              </div>

              <div class="competency-breakdown">
                <div
                  v-for="competency in userProfile.competencies"
                  :key="competency.id"
                  class="competency-item"
                >
                  <div class="competency-info">
                    <h4>{{ competency.name }}</h4>
                    <div class="competency-level">
                      Level {{ competency.currentLevel }}/5
                      <el-tag
                        v-if="competency.growth > 0"
                        type="success"
                        size="small"
                        class="growth-tag"
                      >
                        +{{ competency.growth }}
                      </el-tag>
                    </div>
                  </div>
                  <div class="competency-progress">
                    <el-progress
                      :percentage="(competency.currentLevel / 5) * 100"
                      :stroke-width="8"
                      :color="getCompetencyColor(competency.currentLevel)"
                    />
                  </div>
                </div>
              </div>
            </div>

            <el-divider />

            <!-- Learning Goals -->
            <div class="learning-goals-section">
              <h3><el-icon><Aim /></el-icon> Learning Goals</h3>
              <div class="goals-grid">
                <div
                  v-for="goal in userProfile.learningGoals"
                  :key="goal.id"
                  class="goal-item"
                >
                  <div class="goal-info">
                    <h4>{{ goal.title }}</h4>
                    <p>{{ goal.description }}</p>
                    <div class="goal-meta">
                      <span><el-icon><Calendar /></el-icon> {{ goal.targetDate }}</span>
                      <span><el-icon><Medal /></el-icon> {{ goal.targetLevel }}</span>
                    </div>
                  </div>
                  <div class="goal-progress">
                    <el-progress
                      type="circle"
                      :percentage="goal.progress"
                      :width="60"
                      :stroke-width="6"
                    />
                  </div>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Edit Profile Modal -->
      <el-dialog
        v-model="showEditDialog"
        title="Edit Profile"
        width="600px"
        @close="editMode = false"
      >
        <el-form :model="editForm" label-width="120px">
          <el-form-item label="Name">
            <el-input v-model="editForm.name" />
          </el-form-item>
          <el-form-item label="Role">
            <el-input v-model="editForm.role" />
          </el-form-item>
          <el-form-item label="Organization">
            <el-input v-model="editForm.organization" />
          </el-form-item>
          <el-form-item label="Department">
            <el-input v-model="editForm.department" />
          </el-form-item>
          <el-form-item label="Experience">
            <el-input-number v-model="editForm.experience" :min="0" :max="50" />
          </el-form-item>
          <el-form-item label="Location">
            <el-input v-model="editForm.location" />
          </el-form-item>
          <el-form-item label="Bio">
            <el-input
              v-model="editForm.bio"
              type="textarea"
              :rows="4"
              placeholder="Tell us about yourself..."
            />
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="showEditDialog = false">Cancel</el-button>
          <el-button type="primary" @click="saveProfile">Save Changes</el-button>
        </template>
      </el-dialog>

      <!-- Features Placeholder -->
      <el-card class="features-placeholder">
        <div class="placeholder-content">
          <h2>Advanced Profile Features</h2>
          <p>This comprehensive profile system will provide advanced user management and tracking capabilities.</p>

          <div class="feature-list">
            <h3>Features to be implemented:</h3>
            <ul>
              <li>Competency progression tracking and analytics</li>
              <li>Learning pathway recommendations based on profile</li>
              <li>Peer comparison and benchmarking</li>
              <li>Achievement badges and certifications</li>
              <li>Professional network integration</li>
              <li>Customizable competency frameworks</li>
            </ul>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { User, Edit, Cpu, DocumentChecked, Aim, Calendar, Medal } from '@element-plus/icons-vue'

const router = useRouter()

const editMode = ref(false)
const showEditDialog = ref(false)

// Watch editMode to show/hide dialog
watch(editMode, (newValue) => {
  showEditDialog.value = newValue
})

const userProfile = ref({
  name: "Dr. Sarah Johnson",
  email: "sarah.johnson@company.com",
  role: "Senior Systems Engineer",
  organization: "Aerospace Systems Corp",
  department: "Systems Engineering",
  experience: 8,
  location: "California, USA",
  joinedDate: new Date('2023-01-15'),
  avatar: "",
  bio: "Passionate systems engineer with expertise in aerospace systems design and verification.",
  stats: {
    completedAssessments: 12,
    qualificationPlans: 3,
    learningHours: 145
  },
  competencies: [
    {
      id: 1,
      name: "Systems Thinking",
      currentLevel: 4,
      growth: 1
    },
    {
      id: 2,
      name: "Requirements Engineering",
      currentLevel: 3,
      growth: 0
    },
    {
      id: 3,
      name: "System Architecture",
      currentLevel: 2,
      growth: 2
    },
    {
      id: 4,
      name: "Verification & Validation",
      currentLevel: 3,
      growth: 1
    },
    {
      id: 5,
      name: "Risk Management",
      currentLevel: 3,
      growth: 0
    },
    {
      id: 6,
      name: "System Integration",
      currentLevel: 2,
      growth: 1
    }
  ],
  learningGoals: [
    {
      id: 1,
      title: "Master System Architecture",
      description: "Advance to expert level in system architecture design",
      progress: 65,
      targetDate: "Dec 2024",
      targetLevel: "Level 5"
    },
    {
      id: 2,
      title: "Leadership Development",
      description: "Develop technical leadership and team management skills",
      progress: 30,
      targetDate: "Mar 2025",
      targetLevel: "Level 4"
    },
    {
      id: 3,
      title: "Agile Systems Engineering",
      description: "Learn agile methodologies for systems engineering",
      progress: 80,
      targetDate: "Oct 2024",
      targetLevel: "Level 4"
    }
  ]
})

const editForm = ref({
  name: userProfile.value.name,
  role: userProfile.value.role,
  organization: userProfile.value.organization,
  department: userProfile.value.department,
  experience: userProfile.value.experience,
  location: userProfile.value.location,
  bio: userProfile.value.bio
})

const overallCompetencyScore = computed(() => {
  const totalLevels = userProfile.value.competencies.reduce((sum, comp) => sum + comp.currentLevel, 0)
  const maxLevels = userProfile.value.competencies.length * 5
  return Math.round((totalLevels / maxLevels) * 100)
})

const getScoreColor = (score) => {
  if (score < 40) return '#f56c6c'
  if (score < 70) return '#e6a23c'
  return '#67c23a'
}

const getCompetencyColor = (level) => {
  const colors = ['#f56c6c', '#e6a23c', '#409eff', '#67c23a', '#67c23a']
  return colors[level - 1] || '#f56c6c'
}

const formatDate = (date) => {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const changeAvatar = () => {
  // Implement avatar change functionality
  console.log('Change avatar functionality')
}

const saveProfile = () => {
  // Update user profile with form data
  Object.assign(userProfile.value, editForm.value)
  showEditDialog.value = false
  editMode.value = false

  // Here you would typically save to the store/API
  console.log('Profile saved:', userProfile.value)
}
</script>

<style scoped>
.profile {
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

.profile-container {
  max-width: 1200px;
  margin: 0 auto;
}

.profile-header {
  text-align: center;
  margin-bottom: 24px;
}

.avatar-section {
  margin-bottom: 16px;
}

.profile-info h2 {
  margin: 0 0 8px 0;
  color: #303133;
}

.role {
  color: #409eff;
  font-weight: 600;
  margin: 0 0 4px 0;
}

.organization {
  color: #606266;
  margin: 0;
}

.profile-details {
  margin-bottom: 24px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.detail-item label {
  font-weight: 600;
  color: #303133;
}

.detail-item span {
  color: #606266;
}

.profile-stats {
  display: flex;
  justify-content: space-around;
  text-align: center;
}

.stat-item .stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #409eff;
}

.stat-item .stat-label {
  color: #606266;
  font-size: 14px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.card-header h2 {
  margin: 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 12px;
}

.competency-overview {
  display: flex;
  gap: 32px;
  margin-bottom: 24px;
}

.overall-score {
  display: flex;
  align-items: center;
  gap: 20px;
}

.score-text {
  font-size: 18px;
  font-weight: bold;
}

.score-info h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.score-info p {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.competency-breakdown {
  flex: 1;
  display: grid;
  gap: 16px;
}

.competency-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
}

.competency-info h4 {
  margin: 0 0 4px 0;
  color: #303133;
  font-size: 14px;
}

.competency-level {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #909399;
}

.growth-tag {
  font-size: 10px;
}

.competency-progress {
  min-width: 150px;
}

.learning-goals-section h3 {
  margin: 0 0 16px 0;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 8px;
}

.goals-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.goal-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f0f9ff;
  border-radius: 8px;
  border-left: 4px solid #409eff;
}

.goal-info h4 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 14px;
}

.goal-info p {
  margin: 0 0 8px 0;
  color: #606266;
  font-size: 13px;
}

.goal-meta {
  display: flex;
  gap: 16px;
  font-size: 12px;
  color: #909399;
}

.goal-meta span {
  display: flex;
  align-items: center;
  gap: 4px;
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