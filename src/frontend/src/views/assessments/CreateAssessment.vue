<template>
  <div class="create-assessment-page">
    <div class="page-header">
      <h1>Create New Assessment</h1>
      <p>Start your SE competency or maturity evaluation</p>
    </div>

    <div class="form-container">
      <form @submit.prevent="handleSubmit" class="assessment-form">
        <div class="form-section">
          <h3>Assessment Details</h3>
          <div class="form-group">
            <label for="type">Assessment Type</label>
            <select id="type" v-model="form.type" class="form-input" required>
              <option value="">Select assessment type</option>
              <option value="competency">Competency Assessment</option>
              <option value="maturity">Maturity Assessment</option>
              <option value="comprehensive">Comprehensive Assessment</option>
            </select>
          </div>
          <div class="form-group">
            <label for="phase">Phase</label>
            <select id="phase" v-model="form.phase" class="form-input" required>
              <option value="1">Phase 1: Maturity Assessment</option>
              <option value="2">Phase 2: Competency Assessment</option>
              <option value="3">Phase 3: Module Selection</option>
              <option value="4">Phase 4: Cohort Formation</option>
            </select>
          </div>
        </div>

        <div class="form-section">
          <h3>Organization Information</h3>
          <div class="form-group">
            <label for="organization_name">Organization Name</label>
            <input
              id="organization_name"
              v-model="form.organization_name"
              type="text"
              class="form-input"
              placeholder="Enter organization name"
              required
            />
          </div>
          <div class="form-group">
            <label for="industry_domain">Industry Domain</label>
            <select id="industry_domain" v-model="form.industry_domain" class="form-input">
              <option value="">Select industry domain</option>
              <option value="aerospace">Aerospace & Defense</option>
              <option value="automotive">Automotive</option>
              <option value="healthcare">Healthcare & Medical Devices</option>
              <option value="energy">Energy & Utilities</option>
              <option value="telecommunications">Telecommunications</option>
              <option value="manufacturing">Manufacturing</option>
              <option value="software">Software & IT</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="form-group">
            <label for="organization_size">Organization Size</label>
            <select id="organization_size" v-model="form.organization_size" class="form-input">
              <option value="">Select organization size</option>
              <option value="small">Small (1-50 employees)</option>
              <option value="medium">Medium (51-500 employees)</option>
              <option value="large">Large (501-5000 employees)</option>
              <option value="enterprise">Enterprise (5000+ employees)</option>
            </select>
          </div>
        </div>

        <div class="form-actions">
          <router-link to="/app/assessments" class="btn btn-secondary">
            Cancel
          </router-link>
          <button type="submit" class="btn btn-primary" :disabled="loading">
            {{ loading ? 'Creating...' : 'Create Assessment' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const loading = ref(false)

const form = reactive({
  type: '',
  phase: '1',
  organization_name: '',
  industry_domain: '',
  organization_size: ''
})

const handleSubmit = async () => {
  loading.value = true
  try {
    // TODO: Implement actual API call
    console.log('Creating assessment:', form)
    
    // Simulate API call
    setTimeout(() => {
      router.push('/app/assessments')
      loading.value = false
    }, 1000)
  } catch (error) {
    console.error('Failed to create assessment:', error)
    loading.value = false
  }
}
</script>

<style scoped>
.create-assessment-page {
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
  text-align: center;
}

.page-header h1 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.page-header p {
  color: #6c757d;
}

.form-container {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}

.form-section {
  margin-bottom: 2rem;
}

.form-section:last-of-type {
  margin-bottom: 1rem;
}

.form-section h3 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #e9ecef;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #2c3e50;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  padding-top: 1rem;
  border-top: 1px solid #e9ecef;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #5a6fd8;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>