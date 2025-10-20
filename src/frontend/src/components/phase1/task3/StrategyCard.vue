<template>
  <v-card
    :class="[
      'strategy-card',
      { 'strategy-selected': isSelected },
      { 'strategy-recommended': isRecommended },
      { 'strategy-disabled': disabled }
    ]"
    elevation="2"
    @click="handleCardClick"
  >
    <!-- Recommended Badge -->
    <div v-if="isRecommended" class="recommendation-badge">
      <v-chip color="success" size="small" variant="flat">
        <v-icon start>mdi-check-circle</v-icon>
        Recommended
      </v-chip>
    </div>

    <!-- Card Header -->
    <v-card-title class="card-header-section">
      <div class="header-left">
        <v-checkbox
          :model-value="isSelected"
          :disabled="disabled"
          @update:model-value="handleToggle"
          color="primary"
          density="compact"
          hide-details
        />
        <div class="strategy-title-wrapper">
          <h3 class="strategy-name">{{ strategy.name }}</h3>
          <v-chip
            :color="getCategoryColor(strategy.category)"
            size="small"
            variant="tonal"
            class="category-chip"
          >
            {{ getCategoryLabel(strategy.category) }}
          </v-chip>
        </div>
      </div>
    </v-card-title>

    <!-- Card Content -->
    <v-card-text>
      <!-- Description -->
      <p class="strategy-description">{{ strategy.description }}</p>

      <!-- Details Grid -->
      <div class="strategy-details-grid">
        <!-- Qualification Level -->
        <div class="detail-item">
          <div class="detail-label">
            <v-icon size="small" class="detail-icon">mdi-school</v-icon>
            Qualification Level
          </div>
          <div class="detail-value">{{ strategy.qualificationLevel }}</div>
        </div>

        <!-- Target Audience -->
        <div class="detail-item">
          <div class="detail-label">
            <v-icon size="small" class="detail-icon">mdi-account-group</v-icon>
            Target Audience
          </div>
          <div class="detail-value">{{ strategy.targetAudience }}</div>
        </div>

        <!-- Duration -->
        <div class="detail-item">
          <div class="detail-label">
            <v-icon size="small" class="detail-icon">mdi-clock-outline</v-icon>
            Duration
          </div>
          <div class="detail-value">{{ strategy.duration }}</div>
        </div>

        <!-- Group Size -->
        <div class="detail-item">
          <div class="detail-label">
            <v-icon size="small" class="detail-icon">mdi-account-multiple</v-icon>
            Group Size
          </div>
          <div class="detail-value">{{ formatGroupSize(strategy.groupSize) }}</div>
        </div>

        <!-- Suitable Phase -->
        <div class="detail-item full-width">
          <div class="detail-label">
            <v-icon size="small" class="detail-icon">mdi-timeline-outline</v-icon>
            Suitable Phase
          </div>
          <div class="detail-value">{{ strategy.suitablePhase }}</div>
        </div>
      </div>

      <!-- Key Benefits -->
      <div v-if="strategy.benefits && strategy.benefits.length > 0" class="benefits-section">
        <h4 class="section-title">
          <v-icon size="small" color="success">mdi-check-circle</v-icon>
          Key Benefits
        </h4>
        <ul class="benefits-list">
          <li v-for="(benefit, index) in strategy.benefits.slice(0, 3)" :key="index">
            {{ benefit }}
          </li>
        </ul>
      </div>
    </v-card-text>

    <!-- Card Actions -->
    <v-card-actions v-if="showViewDetails">
      <v-btn
        variant="text"
        color="primary"
        size="small"
        @click.stop="$emit('view-details', strategy)"
      >
        <v-icon start>mdi-information-outline</v-icon>
        View Full Details
      </v-btn>
    </v-card-actions>
  </v-card>
</template>

<script setup>
import { STRATEGY_CATEGORIES } from '@/data/seTrainingStrategies'

// Props
const props = defineProps({
  strategy: {
    type: Object,
    required: true
  },
  isSelected: {
    type: Boolean,
    default: false
  },
  isRecommended: {
    type: Boolean,
    default: false
  },
  disabled: {
    type: Boolean,
    default: false
  },
  showViewDetails: {
    type: Boolean,
    default: false
  }
})

// Emits
const emit = defineEmits(['toggle', 'view-details'])

// Methods
const handleCardClick = () => {
  if (!props.disabled) {
    emit('toggle', props.strategy.id)
  }
}

const handleToggle = (value) => {
  if (!props.disabled) {
    emit('toggle', props.strategy.id)
  }
}

const getCategoryColor = (category) => {
  const categoryInfo = STRATEGY_CATEGORIES[category]
  return categoryInfo ? categoryInfo.color : 'grey'
}

const getCategoryLabel = (category) => {
  const categoryInfo = STRATEGY_CATEGORIES[category]
  return categoryInfo ? categoryInfo.label : category
}

const formatGroupSize = (groupSize) => {
  if (!groupSize) return 'N/A'

  const { min, max, optimal } = groupSize

  if (optimal) {
    return optimal
  }

  if (max === 'Unlimited') {
    return `${min}+ participants`
  }

  return `${min}-${max} participants`
}
</script>

<style scoped>
.strategy-card {
  position: relative;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 2px solid transparent;
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: #ffffff !important;
  color: #212121 !important;
  color-scheme: light !important;
}

.strategy-card:hover:not(.strategy-disabled) {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15) !important;
}

.strategy-card.strategy-selected {
  border-color: #1976D2;
  background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%);
  box-shadow: 0 4px 12px rgba(25, 118, 210, 0.2) !important;
}

.strategy-card.strategy-recommended {
  box-shadow: 0 0 0 3px rgba(76, 175, 80, 0.2);
}

.strategy-card.strategy-disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.recommendation-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 1;
}

.card-header-section {
  padding: 16px;
  background: linear-gradient(135deg, #f5f5f5 0%, #ffffff 100%);
  border-bottom: 1px solid #e0e0e0;
}

.header-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  width: 100%;
}

.strategy-title-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.strategy-name {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #212121;
  line-height: 1.3;
}

.category-chip {
  align-self: flex-start;
}

.strategy-description {
  margin: 0 0 20px 0;
  color: #616161;
  line-height: 1.6;
  font-size: 0.95rem;
}

.strategy-details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-item.full-width {
  grid-column: 1 / -1;
}

.detail-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.75rem;
  color: #757575;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-icon {
  color: #9E9E9E;
}

.detail-value {
  font-size: 0.95rem;
  color: #212121;
  font-weight: 500;
  padding-left: 22px;
}

.benefits-section {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #e0e0e0;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px 0;
  font-size: 0.9rem;
  font-weight: 600;
  color: #2E7D32;
}

.benefits-list {
  margin: 0;
  padding-left: 24px;
  color: #616161;
}

.benefits-list li {
  margin-bottom: 6px;
  line-height: 1.5;
  font-size: 0.9rem;
}

.benefits-list li:last-child {
  margin-bottom: 0;
}

/* Responsive adjustments */
@media (max-width: 600px) {
  .strategy-details-grid {
    grid-template-columns: 1fr;
  }

  .detail-item.full-width {
    grid-column: 1;
  }
}
</style>
