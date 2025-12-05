<template>
  <div class="home-page">
    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-content">
        <div class="hero-text">
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
          <div class="phases-container">
            <div
              v-for="(phase, index) in phases"
              :key="index"
              class="phase-card-modern"
              :class="`phase-color-${index + 1}`"
            >
              <div class="phase-header">
                <div class="phase-number-badge">{{ index + 1 }}</div>
                <div class="phase-icon">{{ phase.icon }}</div>
              </div>
              <div class="phase-body">
                <h3 class="phase-title">{{ phase.name }}</h3>
                <p class="phase-description">{{ phase.description }}</p>
              </div>
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
  {
    name: 'Foundation & Strategy',
    description: 'Assess SE maturity and select training approach',
    icon: '🎯'
  },
  {
    name: 'Competency Assessment',
    description: 'Define competencies and learning objectives',
    icon: '📊'
  },
  {
    name: 'Learning Design',
    description: 'Select modules and qualification formats',
    icon: '📚'
  },
  {
    name: 'Implementation Planning',
    description: 'Create detailed implementation roadmap',
    icon: '🚀'
  }
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

.phases-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
  max-width: 480px;
  margin: 0 auto;
}

.phase-card-modern {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  padding: 16px 20px;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
}

.phase-card-modern:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.4);
  transform: translateX(8px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.2);
}

.phase-card-modern.phase-color-1:hover {
  border-color: rgba(102, 126, 234, 0.6);
  box-shadow: 0 12px 32px rgba(102, 126, 234, 0.3);
}

.phase-card-modern.phase-color-2:hover {
  border-color: rgba(240, 147, 251, 0.6);
  box-shadow: 0 12px 32px rgba(240, 147, 251, 0.3);
}

.phase-card-modern.phase-color-3:hover {
  border-color: rgba(79, 172, 254, 0.6);
  box-shadow: 0 12px 32px rgba(79, 172, 254, 0.3);
}

.phase-card-modern.phase-color-4:hover {
  border-color: rgba(67, 233, 123, 0.6);
  box-shadow: 0 12px 32px rgba(67, 233, 123, 0.3);
}

.phase-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.phase-number-badge {
  width: 32px;
  height: 32px;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  font-weight: 700;
  color: white;
  flex-shrink: 0;
  transition: all 0.3s ease;
}

.phase-card-modern:hover .phase-number-badge {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.1);
}

.phase-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
  transition: all 0.3s ease;
}

.phase-card-modern:hover .phase-icon {
  transform: scale(1.1) rotate(5deg);
}

.phase-body {
  padding-left: 44px;
}

.phase-title {
  font-size: 1rem;
  font-weight: 700;
  color: white;
  margin: 0 0 6px 0;
  line-height: 1.3;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.phase-description {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.85);
  margin: 0;
  line-height: 1.4;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
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

  .phases-container {
    max-width: 100%;
    padding: 0;
    gap: 16px;
  }

  .phase-card-modern {
    padding: 14px 16px;
  }

  .phase-card-modern:hover {
    transform: translateX(4px);
  }

  .phase-title {
    font-size: 0.95rem;
  }

  .phase-description {
    font-size: 0.8rem;
  }

  .phase-body {
    padding-left: 0;
    margin-top: 10px;
  }

  .phase-icon {
    font-size: 1.3rem;
  }

  .phase-number-badge {
    width: 28px;
    height: 28px;
    font-size: 0.85rem;
  }
}
</style>