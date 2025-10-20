<template>
  <div class="pro-con-comparison">
    <!-- Header -->
    <div class="comparison-header">
      <h3>Secondary Strategy Options - Pros & Cons Comparison</h3>
      <p>Compare the three available secondary strategies to help you make an informed decision. Select your preferred strategy from the Strategy Profile Cards above.</p>
    </div>

    <!-- Comparison Grid -->
    <div class="comparison-grid">
      <v-card
        v-for="strategyId in strategyOptions"
        :key="strategyId"
        class="comparison-card"
        elevation="2"
      >

        <!-- Strategy Name & Description -->
        <v-card-title class="strategy-name">
          {{ getStrategyName(strategyId) }}
        </v-card-title>

        <v-card-subtitle class="strategy-tagline">
          {{ getStrategyTagline(strategyId) }}
        </v-card-subtitle>

        <v-card-text>
          <!-- Pros Section -->
          <div class="pros-section">
            <h4 class="section-title pros-title">
              <v-icon size="small" color="success">mdi-plus-circle</v-icon>
              Pros
            </h4>
            <ul class="comparison-list">
              <li v-for="(pro, index) in getProCon(strategyId).pros" :key="`pro-${index}`" class="pro-item">
                <v-icon size="x-small" color="success">mdi-check</v-icon>
                {{ pro }}
              </li>
            </ul>
          </div>

          <!-- Cons Section -->
          <div class="cons-section">
            <h4 class="section-title cons-title">
              <v-icon size="small" color="error">mdi-minus-circle</v-icon>
              Cons
            </h4>
            <ul class="comparison-list">
              <li v-for="(con, index) in getProCon(strategyId).cons" :key="`con-${index}`" class="con-item">
                <v-icon size="x-small" color="error">mdi-close</v-icon>
                {{ con }}
              </li>
            </ul>
          </div>

          <!-- Best For -->
          <div class="best-for-section">
            <h4 class="section-title">
              <v-icon size="small" color="info">mdi-target</v-icon>
              Best For
            </h4>
            <p class="best-for-text">{{ getProCon(strategyId).bestFor }}</p>
          </div>
        </v-card-text>

        <!-- Info Footer -->
        <v-card-actions class="card-actions info-footer">
          <v-chip color="info" variant="outlined" size="small">
            <v-icon start size="small">mdi-information</v-icon>
            Select from Strategy Cards above
          </v-chip>
        </v-card-actions>
      </v-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { STRATEGY_PRO_CON } from '@/data/seTrainingStrategies'

// Props
const props = defineProps({
  strategies: {
    type: Array,
    required: true,
    validator: (value) => value.length === 3 // Must be exactly 3 strategies
  },
  modelValue: {
    type: String,
    default: null
  }
})

// Emits
const emit = defineEmits(['select', 'update:modelValue'])

// State
const strategyOptions = computed(() => props.strategies)
const selectedStrategy = ref(props.modelValue)

// Methods
const handleSelect = (strategyId) => {
  selectedStrategy.value = strategyId
  emit('select', strategyId)
  emit('update:modelValue', strategyId)
}

const getStrategyName = (strategyId) => {
  const proCon = STRATEGY_PRO_CON[strategyId]
  return proCon ? proCon.name : strategyId
}

const getStrategyTagline = (strategyId) => {
  const proCon = STRATEGY_PRO_CON[strategyId]
  return proCon ? proCon.tagline : ''
}

const getProCon = (strategyId) => {
  return STRATEGY_PRO_CON[strategyId] || {
    name: strategyId,
    tagline: '',
    pros: [],
    cons: [],
    bestFor: ''
  }
}
</script>

<style scoped>
.pro-con-comparison {
  width: 100%;
  padding: 24px 0;
}

.comparison-header {
  text-align: center;
  margin-bottom: 32px;
}

.comparison-header h3 {
  margin: 0 0 12px 0;
  font-size: 1.5rem;
  font-weight: 600;
  color: #2c3e50;
}

.comparison-header p {
  margin: 0;
  font-size: 1rem;
  color: #6c757d;
  max-width: 700px;
  margin: 0 auto;
  line-height: 1.6;
}

.comparison-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
}

.comparison-card {
  position: relative;
  border: 2px solid #e0e0e0;
  display: flex;
  flex-direction: column;
  background-color: #ffffff !important;
  color: #212121 !important;
  color-scheme: light !important;
}

.strategy-name {
  font-size: 1.2rem !important;
  font-weight: 600;
  color: #212121;
  padding-bottom: 8px;
}

.strategy-tagline {
  color: #616161;
  font-size: 0.9rem;
  padding-bottom: 16px;
}

.pros-section,
.cons-section {
  margin-bottom: 20px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px 0;
  font-size: 0.95rem;
  font-weight: 600;
}

.pros-title {
  color: #2E7D32;
}

.cons-title {
  color: #C62828;
}

.comparison-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.comparison-list li {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 10px;
  line-height: 1.5;
  font-size: 0.9rem;
  color: #424242;
}

.comparison-list li:last-child {
  margin-bottom: 0;
}

.pro-item {
  color: #1B5E20;
}

.con-item {
  color: #B71C1C;
}

.best-for-section {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #e0e0e0;
}

.best-for-section .section-title {
  color: #1565C0;
}

.best-for-text {
  margin: 0;
  color: #616161;
  line-height: 1.6;
  font-size: 0.9rem;
}

.card-actions {
  margin-top: auto;
  padding: 16px;
}

.info-footer {
  justify-content: center;
  background-color: #f5f5f5;
  border-top: 1px solid #e0e0e0;
}

.help-alert,
.confirmation-alert {
  margin-top: 24px;
}

/* Responsive adjustments */
@media (max-width: 960px) {
  .comparison-grid {
    grid-template-columns: 1fr;
  }
}

@media (min-width: 961px) and (max-width: 1400px) {
  .comparison-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
