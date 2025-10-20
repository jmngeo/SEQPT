<template>
  <div class="basic-company-context">
    <el-card class="context-card">
      <template #header>
        <div class="card-header">
          <h3>Basic Company Context (Q6)</h3>
          <p class="header-subtitle">
            Provide basic company information for standardized learning objectives
          </p>
        </div>
      </template>

      <el-form
        :model="basicContextForm"
        :rules="basicContextRules"
        ref="basicContextFormRef"
        label-width="200px"
        @submit.prevent="handleSubmit"
      >
        <!-- Company Overview -->
        <div class="section-divider">
          <h4>Company Overview</h4>
        </div>

        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="Company Name" prop="companyName" required>
              <el-input
                v-model="basicContextForm.companyName"
                placeholder="Enter your company name"
              />
            </el-form-item>
          </el-col>

          <el-col :span="12">
            <el-form-item label="Industry Domain" prop="industryDomain" required>
              <el-select
                v-model="basicContextForm.industryDomain"
                placeholder="Select industry domain"
                style="width: 100%"
              >
                <el-option label="Aerospace & Defense" value="aerospace" />
                <el-option label="Automotive" value="automotive" />
                <el-option label="Healthcare & Medical Devices" value="healthcare" />
                <el-option label="Telecommunications" value="telecom" />
                <el-option label="Energy & Utilities" value="energy" />
                <el-option label="Manufacturing" value="manufacturing" />
                <el-option label="Software & IT" value="software" />
                <el-option label="Transportation" value="transportation" />
                <el-option label="Other" value="other" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="Organization Size" prop="organizationSize" required>
              <el-select
                v-model="basicContextForm.organizationSize"
                placeholder="Select organization size"
                style="width: 100%"
              >
                <el-option label="Small (< 50 employees)" value="small" />
                <el-option label="Medium (50-500 employees)" value="medium" />
                <el-option label="Large (500-5000 employees)" value="large" />
                <el-option label="Enterprise (> 5000 employees)" value="enterprise" />
              </el-select>
            </el-form-item>
          </el-col>

          <el-col :span="12">
            <el-form-item label="Current SE Maturity" prop="currentMaturity">
              <el-select
                v-model="basicContextForm.currentMaturity"
                placeholder="Select current maturity"
                style="width: 100%"
              >
                <el-option label="Initial (No formal SE)" value="initial" />
                <el-option label="Developing (Some SE practices)" value="developing" />
                <el-option label="Defined (Established SE)" value="defined" />
                <el-option label="Managed (Measured SE)" value="managed" />
                <el-option label="Optimized (Continuous improvement)" value="optimized" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- Compliance & Standards -->
        <div class="section-divider">
          <h4>Standards & Compliance</h4>
        </div>

        <el-form-item label="Compliance Standards" prop="complianceStandards">
          <el-checkbox-group v-model="basicContextForm.complianceStandards">
            <el-checkbox label="ISO 15288" value="iso15288">ISO 15288 (Systems Lifecycle)</el-checkbox>
            <el-checkbox label="ISO 26262" value="iso26262">ISO 26262 (Automotive Safety)</el-checkbox>
            <el-checkbox label="DO-178C" value="do178c">DO-178C (Aviation Software)</el-checkbox>
            <el-checkbox label="IEC 61508" value="iec61508">IEC 61508 (Functional Safety)</el-checkbox>
            <el-checkbox label="CMMI" value="cmmi">CMMI (Process Maturity)</el-checkbox>
            <el-checkbox label="Agile/Scrum" value="agile">Agile/Scrum Framework</el-checkbox>
            <el-checkbox label="Other" value="other">Other Standards</el-checkbox>
          </el-checkbox-group>
        </el-form-item>

        <!-- Learning Priorities -->
        <div class="section-divider">
          <h4>Learning Focus Areas</h4>
        </div>

        <el-form-item label="Primary Learning Focus" prop="learningFocus">
          <el-select
            v-model="basicContextForm.learningFocus"
            placeholder="Select primary focus area"
            style="width: 100%"
          >
            <el-option label="Requirements Engineering" value="requirements" />
            <el-option label="System Architecture & Design" value="architecture" />
            <el-option label="Verification & Validation" value="verification" />
            <el-option label="Configuration Management" value="configuration" />
            <el-option label="Risk Management" value="risk" />
            <el-option label="Project Management" value="project" />
            <el-option label="SE Process Improvement" value="process" />
            <el-option label="General SE Awareness" value="general" />
          </el-select>
        </el-form-item>

        <el-form-item label="Secondary Focus Areas" prop="secondaryFocus">
          <el-checkbox-group v-model="basicContextForm.secondaryFocus">
            <el-checkbox label="Requirements Engineering" value="requirements" />
            <el-checkbox label="System Architecture & Design" value="architecture" />
            <el-checkbox label="Verification & Validation" value="verification" />
            <el-checkbox label="Configuration Management" value="configuration" />
            <el-checkbox label="Risk Management" value="risk" />
            <el-checkbox label="Project Management" value="project" />
            <el-checkbox label="SE Process Improvement" value="process" />
          </el-checkbox-group>
        </el-form-item>

        <!-- Additional Context -->
        <div class="section-divider">
          <h4>Additional Information</h4>
        </div>

        <el-form-item label="Target Audience" prop="targetAudience">
          <el-select
            v-model="basicContextForm.targetAudience"
            placeholder="Select target audience"
            style="width: 100%"
          >
            <el-option label="Engineers (Technical)" value="engineers" />
            <el-option label="Managers (Leadership)" value="managers" />
            <el-option label="Mixed (Technical + Management)" value="mixed" />
            <el-option label="New Hires" value="new_hires" />
            <el-option label="Experienced Staff" value="experienced" />
          </el-select>
        </el-form-item>

        <el-form-item label="Learning Goals" prop="learningGoals">
          <el-input
            v-model="basicContextForm.learningGoals"
            type="textarea"
            :rows="3"
            placeholder="Describe your organization's main learning goals and objectives..."
          />
        </el-form-item>

        <!-- Action Buttons -->
        <div class="form-actions">
          <el-button @click="handlePrevious" size="large">
            <el-icon><ArrowLeft /></el-icon>
            Previous Step
          </el-button>

          <el-button
            type="primary"
            @click="handleSubmit"
            size="large"
            :loading="isSubmitting"
          >
            Continue to Objectives
            <el-icon><ArrowRight /></el-icon>
          </el-button>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, defineEmits } from 'vue'
import { ElMessage } from 'element-plus'
import { ArrowLeft, ArrowRight } from '@element-plus/icons-vue'

const emit = defineEmits(['previous', 'submit'])

const isSubmitting = ref(false)
const basicContextFormRef = ref()

const basicContextForm = reactive({
  companyName: '',
  industryDomain: '',
  organizationSize: '',
  currentMaturity: '',
  complianceStandards: [],
  learningFocus: '',
  secondaryFocus: [],
  targetAudience: '',
  learningGoals: ''
})

const basicContextRules = {
  companyName: [
    { required: true, message: 'Please enter company name', trigger: 'blur' }
  ],
  industryDomain: [
    { required: true, message: 'Please select industry domain', trigger: 'change' }
  ],
  organizationSize: [
    { required: true, message: 'Please select organization size', trigger: 'change' }
  ],
  learningFocus: [
    { required: true, message: 'Please select primary learning focus', trigger: 'change' }
  ],
  targetAudience: [
    { required: true, message: 'Please select target audience', trigger: 'change' }
  ]
}

const handlePrevious = () => {
  emit('previous')
}

const handleSubmit = async () => {
  try {
    await basicContextFormRef.value.validate()

    isSubmitting.value = true

    // Emit form data
    emit('submit', {
      contextType: 'basic',
      basicContext: basicContextForm
    })

    ElMessage.success('Basic company context collected successfully')

  } catch (error) {
    console.error('Form validation failed:', error)
    ElMessage.error('Please fill in all required fields')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<style scoped>
.basic-company-context {
  max-width: 900px;
  margin: 0 auto;
}

.context-card {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-radius: 8px;
}

.card-header {
  text-align: center;
}

.card-header h3 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 24px;
  font-weight: 600;
}

.header-subtitle {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.section-divider {
  margin: 32px 0 24px 0;
  padding-bottom: 8px;
  border-bottom: 2px solid #E4E7ED;
}

.section-divider h4 {
  margin: 0;
  color: #409EFF;
  font-size: 16px;
  font-weight: 600;
}

.form-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #E4E7ED;
}

.el-checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.el-checkbox {
  margin-right: 0;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #303133;
}

:deep(.el-input__wrapper) {
  border-radius: 6px;
}

:deep(.el-select .el-input__wrapper) {
  border-radius: 6px;
}

:deep(.el-textarea__inner) {
  border-radius: 6px;
}
</style>