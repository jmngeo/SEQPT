<template>
  <div class="assessments-page">
    <div class="page-header">
      <h1>My Assessments</h1>
      <p>Track your SE competency and maturity assessments</p>
      <router-link to="/app/assessments/create" class="btn btn-primary">
        <span class="icon">➕</span>
        Create New Assessment
      </router-link>
    </div>

    <div class="assessments-grid">
      <div class="assessment-card" v-for="assessment in assessments" :key="assessment.id">
        <div class="card-header">
          <h3>{{ assessment.type }}</h3>
          <span class="status-badge" :class="assessment.status">{{ assessment.status }}</span>
        </div>
        <div class="card-content">
          <p><strong>Organization:</strong> {{ assessment.organization }}</p>
          <p><strong>Progress:</strong> {{ assessment.progress }}%</p>
          <p><strong>Started:</strong> {{ formatDate(assessment.started_at) }}</p>
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: assessment.progress + '%' }"></div>
          </div>
        </div>
        <div class="card-actions">
          <router-link :to="`/app/assessments/${assessment.uuid}`" class="btn btn-secondary">
            View Details
          </router-link>
          <router-link 
            v-if="assessment.status === 'in-progress'" 
            :to="`/app/assessments/${assessment.uuid}/take`" 
            class="btn btn-primary"
          >
            Continue
          </router-link>
        </div>
      </div>

      <!-- Empty state -->
      <div v-if="assessments.length === 0" class="empty-state">
        <div class="empty-icon">📊</div>
        <h3>No assessments yet</h3>
        <p>Create your first SE assessment to get started</p>
        <router-link to="/app/assessments/create" class="btn btn-primary">
          Create Assessment
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const assessments = ref([
  {
    id: 1,
    uuid: 'assess-001',
    type: 'Competency Assessment',
    status: 'completed',
    progress: 100,
    organization: 'Demo Organization',
    started_at: '2024-01-15T10:00:00Z'
  },
  {
    id: 2,
    uuid: 'assess-002',
    type: 'Maturity Assessment',
    status: 'in-progress',
    progress: 65,
    organization: 'Demo Organization',
    started_at: '2024-01-20T14:30:00Z'
  }
])

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString()
}

onMounted(() => {
  // TODO: Load assessments from API
  console.log('Loading assessments...')
})
</script>

<style scoped>
.assessments-page {
  padding: 2rem;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.page-header div {
  flex: 1;
}

.page-header h1 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.page-header p {
  margin: 0;
  color: #6c757d;
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

.btn-primary:hover {
  background: #5a6fd8;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
}

.assessments-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 2rem;
}

.assessment-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: transform 0.3s;
}

.assessment-card:hover {
  transform: translateY(-5px);
}

.card-header {
  background: #f8f9fa;
  padding: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  margin: 0;
  color: #2c3e50;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-badge.completed {
  background: #d4edda;
  color: #155724;
}

.status-badge.in-progress {
  background: #fff3cd;
  color: #856404;
}

.status-badge.pending {
  background: #e2e3e5;
  color: #6c757d;
}

.card-content {
  padding: 1.5rem;
}

.card-content p {
  margin: 0 0 0.5rem 0;
  color: #6c757d;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
  margin-top: 1rem;
}

.progress-fill {
  height: 100%;
  background: #667eea;
  transition: width 0.3s;
}

.card-actions {
  padding: 1rem 1.5rem;
  background: #f8f9fa;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 4rem 2rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.empty-state p {
  color: #6c757d;
  margin-bottom: 2rem;
}
</style>