<template>
  <div id="app">
    <el-config-provider :locale="locale">
      <router-view />
      <FooterLink />
    </el-config-provider>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import enLocale from 'element-plus/dist/locale/en.mjs'
import FooterLink from './components/common/FooterLink.vue'

const locale = ref(enLocale)
</script>

<style>
#app {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  min-height: 100vh;
  background: #f5f7fa;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  height: 100%;
  overflow-x: hidden;
}


.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.page-header {
  background: #fff;
  padding: 20px 0;
  margin-bottom: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 8px;
}

.page-subtitle {
  color: #606266;
  font-size: 14px;
}

.card-container {
  background: #fff;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-enter-active {
  transition: all 0.3s ease-out;
}

.slide-leave-active {
  transition: all 0.3s cubic-bezier(1, 0.5, 0.8, 1);
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(20px);
  opacity: 0;
}

.se-primary {
  color: #409eff;
}

.se-success {
  color: #67c23a;
}

.se-warning {
  color: #e6a23c;
}

.se-danger {
  color: #f56c6c;
}

.se-info {
  color: #909399;
}

.text-center {
  text-align: center;
}

.text-right {
  text-align: right;
}

.mb-4 {
  margin-bottom: 16px;
}

.mb-6 {
  margin-bottom: 24px;
}

.mt-4 {
  margin-top: 16px;
}

.mt-6 {
  margin-top: 24px;
}

.w-full {
  width: 100%;
}

.flex {
  display: flex;
}

.flex-1 {
  flex: 1;
}

.items-center {
  align-items: center;
}

.justify-between {
  justify-content: space-between;
}

.justify-center {
  justify-content: center;
}

.gap-4 {
  gap: 16px;
}

.responsive-grid {
  display: grid;
  gap: 20px;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
}

@media (max-width: 768px) {
  .container {
    padding: 0 16px;
  }

  .page-title {
    font-size: 20px;
  }

  .card-container {
    padding: 16px;
  }

  .responsive-grid {
    grid-template-columns: 1fr;
  }
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
}

.error-container {
  text-align: center;
  padding: 40px;
  color: #f56c6c;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #909399;
}

.empty-state-icon {
  font-size: 64px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.progress-bar {
  background: #f0f2f5;
  border-radius: 4px;
  overflow: hidden;
  height: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #409eff, #67c23a);
  transition: width 0.3s ease;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
}

.status-pending {
  background: #fdf6ec;
  color: #e6a23c;
}

.status-active {
  background: #f0f9ff;
  color: #409eff;
}

.status-completed {
  background: #f0f9f2;
  color: #67c23a;
}

.status-error {
  background: #fef0f0;
  color: #f56c6c;
}

/* Fix Element Plus card stretching issue */
.el-card__body {
  width: auto !important;
  max-width: 100% !important;
  height: auto !important;
  display: block !important;
}

.el-card {
  width: auto !important;
  max-width: 100% !important;
  height: auto !important;
}
</style>