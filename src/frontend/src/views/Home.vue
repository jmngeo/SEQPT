<template>
  <div class="home-page">
    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-content">
        <div class="hero-text">
          <div class="mvp-badge">MVP Beta Version</div>
          <h1 class="hero-title">SE-QPT Platform</h1>
          <h2 class="hero-subtitle">Systems Engineering Qualification Planning Tool</h2>
          <p class="hero-description">
            <strong>SE Career Development</strong><br>
            Transform your systems engineering journey with our 4-phase qualification planning methodology.
            Experience personalized learning objectives generated through cutting-edge RAG-LLM technology, tailored to your organization's context.
          </p>

          <div class="value-highlights">
            <div class="highlight-item">
              <strong>🎯 Personalized</strong> - AI-driven learning paths
            </div>
            <div class="highlight-item">
              <strong>🏢 Context-Aware</strong> - Company-specific objectives
            </div>
            <div class="highlight-item">
              <strong>📊 INCOSE-Based</strong> - 16 core competencies
            </div>
          </div>

          <div class="hero-actions" v-if="!authStore.isAuthenticated">
            <div class="auth-buttons">
              <router-link to="/auth/login" class="btn-primary">
                Sign In
              </router-link>
              <router-link to="/auth/register" class="btn-primary">
                Register
              </router-link>
            </div>
          </div>

          <div class="hero-actions" v-else>
            <router-link to="/app/dashboard" class="btn-primary">
              Go to Dashboard
            </router-link>
          </div>
        </div>

        <div class="hero-visual">
          <div class="workflow-diagram">
            <div class="phase-circle" v-for="(phase, index) in phases" :key="index">
              <div class="phase-number">{{ index + 1 }}</div>
              <div class="phase-name">{{ phase.name }}</div>
            </div>
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const phases = ref([
  { name: 'Analysis' },
  { name: 'Requirements' },
  { name: 'Pre-concept' },
  { name: 'Detailed concept' }
])

</script>

<style scoped>
.home-page {
  min-height: 100vh;
  overflow-x: hidden;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
}

/* Hero Section */
.hero-section {
  color: white;
  min-height: 100vh;
  padding: 120px 0 80px 0;
  position: relative;
  display: flex;
  align-items: center;
}

.hero-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
}

.mvp-badge {
  background: rgba(255, 255, 255, 0.2);
  color: #ffffff;
  padding: 8px 20px;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: 600;
  display: inline-block;
  margin-bottom: 20px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  backdrop-filter: blur(10px);
}

.hero-title {
  font-size: 3.5rem;
  font-weight: 700;
  margin-bottom: 16px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.hero-subtitle {
  font-size: 1.5rem;
  font-weight: 400;
  margin-bottom: 24px;
  opacity: 0.9;
}

.hero-description {
  font-size: 1.1rem;
  line-height: 1.6;
  margin-bottom: 24px;
  opacity: 0.9;
}

.value-highlights {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 32px;
}

.highlight-item {
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.9);
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-actions {
  display: flex;
  gap: 16px;
  align-items: center;
  flex-direction: column;
}

.auth-buttons {
  display: flex;
  gap: 12px;
  align-items: center;
}

.auth-buttons-large {
  display: flex;
  gap: 16px;
  align-items: center;
  justify-content: center;
}

.btn-primary, .btn-secondary, .btn-primary-large {
  padding: 14px 28px;
  border-radius: 8px;
  font-weight: 600;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  transition: all 0.3s ease;
}

.btn-primary, .btn-primary-large {
  background: #fff;
  color: #1e3c72;
}

.btn-primary:hover, .btn-primary-large:hover {
  background: #f8f9fa;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.btn-secondary {
  background: transparent;
  color: white;
  border: 2px solid rgba(255, 255, 255, 0.3);
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.5);
}

.btn-primary-large {
  padding: 18px 36px;
  font-size: 1.1rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

.workflow-diagram {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  justify-content: center;
  align-items: center;
  gap: 24px;
  max-width: 500px;
  margin: 0 auto;
}

.phase-circle {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.2) 0%, rgba(255, 255, 255, 0.1) 100%);
  backdrop-filter: blur(20px);
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-radius: 24px;
  width: 200px;
  height: 120px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  padding: 12px;
  position: relative;
  overflow: hidden;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.5);
}

.phase-circle::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
  transition: left 0.6s ease;
}

.phase-circle:hover::before {
  left: 100%;
}

.phase-circle:hover {
  transform: translateY(-8px) scale(1.05);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.3) 0%, rgba(255, 255, 255, 0.2) 100%);
  border-color: rgba(255, 255, 255, 0.6);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.2),
    0 0 0 1px rgba(255, 255, 255, 0.3),
    inset 0 1px 0 rgba(255, 255, 255, 0.6);
  animation: float-hover 1s ease-in-out infinite;
}

@keyframes float-hover {
  0%, 100% {
    transform: translateY(-8px) scale(1.05);
  }
  50% {
    transform: translateY(-12px) scale(1.05);
  }
}

.phase-circle:nth-child(1):hover {
  background: linear-gradient(135deg, rgba(74, 144, 226, 0.4) 0%, rgba(74, 144, 226, 0.2) 100%);
  box-shadow:
    0 16px 48px rgba(74, 144, 226, 0.4),
    0 0 0 1px rgba(74, 144, 226, 0.5),
    inset 0 1px 0 rgba(255, 255, 255, 0.6);
}

.phase-circle:nth-child(2):hover {
  background: linear-gradient(135deg, rgba(52, 211, 153, 0.4) 0%, rgba(52, 211, 153, 0.2) 100%);
  box-shadow:
    0 16px 48px rgba(52, 211, 153, 0.4),
    0 0 0 1px rgba(52, 211, 153, 0.5),
    inset 0 1px 0 rgba(255, 255, 255, 0.6);
}

.phase-circle:nth-child(3):hover {
  background: linear-gradient(135deg, rgba(251, 146, 60, 0.4) 0%, rgba(251, 146, 60, 0.2) 100%);
  box-shadow:
    0 16px 48px rgba(251, 146, 60, 0.4),
    0 0 0 1px rgba(251, 146, 60, 0.5),
    inset 0 1px 0 rgba(255, 255, 255, 0.6);
}

.phase-circle:nth-child(4):hover {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.4) 0%, rgba(168, 85, 247, 0.2) 100%);
  box-shadow:
    0 16px 48px rgba(168, 85, 247, 0.4),
    0 0 0 1px rgba(168, 85, 247, 0.5),
    inset 0 1px 0 rgba(255, 255, 255, 0.6);
}

.phase-number {
  font-size: 2.5rem;
  font-weight: 800;
  margin-bottom: 4px;
  background: linear-gradient(135deg, #ffffff 0%, rgba(255, 255, 255, 0.8) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  transition: all 0.3s ease;
}

.phase-circle:hover .phase-number {
  transform: scale(1.1);
  text-shadow: 0 4px 20px rgba(255, 255, 255, 0.5);
}

.phase-name {
  font-size: 0.95rem;
  font-weight: 600;
  line-height: 1.2;
  hyphens: auto;
  word-break: break-word;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
  letter-spacing: 0.5px;
  transition: all 0.3s ease;
}

.phase-circle:hover .phase-name {
  transform: translateY(2px);
  letter-spacing: 1px;
}


/* Responsive Design */
@media (max-width: 768px) {
  .hero-content {
    grid-template-columns: 1fr;
    gap: 40px;
    text-align: center;
  }

  .hero-title {
    font-size: 2.5rem;
  }

  .hero-actions {
    justify-content: center;
  }

  .auth-buttons {
    flex-direction: column;
    gap: 8px;
    width: 100%;
  }

  .auth-buttons-large {
    flex-direction: column;
    gap: 12px;
    width: 100%;
  }

  .value-highlights {
    align-items: center;
    text-align: center;
  }

  .highlight-item {
    justify-content: center;
  }

  .workflow-diagram {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .phase-circle {
    width: 280px;
    height: 100px;
  }
}
</style>