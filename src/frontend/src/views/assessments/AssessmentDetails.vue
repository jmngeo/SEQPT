<template>
  <div class="assessment-details-page">
    <div class="page-header">
      <h1>Assessment Details</h1>
      <p>View assessment results and progress</p>
    </div>
    <div class="content-placeholder">
      <div class="placeholder-icon">📊</div>
      <h3>Assessment Details Coming Soon</h3>
      <p>This page will show detailed assessment results and analytics.</p>
      <router-link to="/app/assessments" class="btn btn-primary">Back to Assessments</router-link>
    </div>
  </div>
</template>

<script setup>
// Placeholder component for assessment details
</script>

<style scoped>
.assessment-details-page {
  padding: 2rem;
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

.content-placeholder {
  text-align: center;
  padding: 4rem 2rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.placeholder-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.content-placeholder h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.content-placeholder p {
  color: #6c757d;
  margin-bottom: 2rem;
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
  background: #667eea;
  color: white;
  transition: all 0.3s;
}

.btn:hover {
  background: #5a6fd8;
}
</style>