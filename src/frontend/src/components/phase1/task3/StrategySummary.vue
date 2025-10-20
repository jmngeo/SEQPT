<template>
  <el-card class="strategy-summary-card" shadow="hover">
    <template #header>
      <div class="summary-header">
        <h3>
          <el-icon><Document /></el-icon>
          Selected Training Strategies
        </h3>
        <el-tag v-if="strategies && strategies.length > 0" type="success" size="large">
          {{ strategies.length }} {{ strategies.length === 1 ? 'Strategy' : 'Strategies' }} Selected
        </el-tag>
      </div>
    </template>

    <div v-if="!strategies || strategies.length === 0" class="empty-state">
      <el-empty
        description="No strategies selected yet"
        :image-size="120"
      >
        <el-icon><InfoFilled /></el-icon>
        <p>Strategies will appear here once you make a selection</p>
      </el-empty>
    </div>

    <div v-else class="summary-content">
      <!-- Target Group Info (Simplified) -->
      <div v-if="targetGroupData" class="target-group-info">
        <div class="info-item">
          <div class="info-label">
            <el-icon><UserFilled /></el-icon>
            Target Group Size
          </div>
          <div class="info-value">
            {{ targetGroupData.size_range }} people
          </div>
        </div>
      </div>

      <el-divider v-if="targetGroupData" />

      <!-- Strategies List (Simplified) -->
      <div class="strategies-simple-list">
        <h4 class="simple-list-title">Selected Strategies:</h4>
        <ul class="simple-strategies-ul">
          <li
            v-for="(strategy, index) in sortedStrategies"
            :key="`strategy-${index}`"
            class="simple-strategy-item"
          >
            {{ strategy.strategyName }}
          </li>
        </ul>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import {
  Document,
  InfoFilled,
  UserFilled
} from '@element-plus/icons-vue'

// Props
const props = defineProps({
  strategies: {
    type: Array,
    default: () => []
  },
  targetGroupData: {
    type: Object,
    default: null
  },
  userPreference: {
    type: String,
    default: null
  }
})

// Computed
const sortedStrategies = computed(() => {
  if (!props.strategies) return []

  const priorityOrder = { PRIMARY: 1, SECONDARY: 2, SUPPLEMENTARY: 3 }

  return [...props.strategies].sort((a, b) => {
    return (priorityOrder[a.priority] || 99) - (priorityOrder[b.priority] || 99)
  })
})

// No additional methods needed for simplified display
</script>

<style scoped>
.strategy-summary-card {
  border-radius: 12px;
}

.summary-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.summary-header h3 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.empty-state {
  padding: 40px 20px;
  text-align: center;
}

.empty-state p {
  margin-top: 12px;
  color: #909399;
}

.summary-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Target Group Info (Simplified) */
.target-group-info {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.info-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.85rem;
  color: #909399;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 1rem;
  color: #2c3e50;
  font-weight: 500;
}

/* Strategies Simple List */
.strategies-simple-list {
  padding: 16px 20px;
}

.simple-list-title {
  margin: 0 0 12px 0;
  font-size: 1rem;
  font-weight: 600;
  color: #2c3e50;
}

.simple-strategies-ul {
  margin: 0;
  padding-left: 24px;
  list-style-type: disc;
}

.simple-strategy-item {
  margin-bottom: 8px;
  font-size: 1rem;
  color: #2c3e50;
  line-height: 1.6;
}

.simple-strategy-item:last-child {
  margin-bottom: 0;
}

/* Responsive adjustments */
@media (max-width: 600px) {
  .summary-header {
    flex-direction: column;
    gap: 12px;
    align-items: flex-start;
  }
}
</style>
