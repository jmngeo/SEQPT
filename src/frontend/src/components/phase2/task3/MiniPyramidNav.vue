<template>
  <div class="mini-pyramid-nav">
    <!-- Mini Pyramid Visual -->
    <div class="pyramid-container">
      <div
        v-for="level in levels"
        :key="level.value"
        class="pyramid-level"
        :class="[
          `level-${level.value}`,
          { 'active': activeLevel === level.value },
          { 'has-items': levelCounts[level.value] > 0 },
          { 'empty': levelCounts[level.value] === 0 }
        ]"
        :style="{ '--level-color': level.color }"
        @click="selectLevel(level.value)"
      >
        <div class="level-content">
          <span class="level-name">{{ level.shortName }}</span>
          <span class="level-count" v-if="levelCounts[level.value] > 0">
            {{ levelCounts[level.value] }}
          </span>
        </div>
      </div>
    </div>

    <!-- Level Tabs -->
    <div class="level-tabs">
      <button
        v-for="level in levels"
        :key="level.value"
        class="level-tab"
        :class="{ 'active': activeLevel === level.value }"
        :style="{ '--tab-color': level.color }"
        @click="selectLevel(level.value)"
      >
        <!-- Per Ulf's meeting 28.11.2025: Remove level numbers, just show names -->
        <span class="tab-name">{{ level.name }}</span>
        <span class="tab-badge" v-if="levelCounts[level.value] > 0">
          {{ levelCounts[level.value] }}
        </span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  modelValue: {
    type: Number,
    default: 1
  },
  levelCounts: {
    type: Object,
    default: () => ({ 1: 0, 2: 0, 4: 0, 6: 0 })
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

// Note: Level 6 (Mastering SE) is excluded from display per Ulf's meeting 28.11.2025
// TTT and Level 6 handling is deferred to backlog - see BACKLOG.md items #14, #15
const levels = [
  { value: 1, name: 'Knowing SE', shortName: 'Knowing', color: '#1976D2' },
  { value: 2, name: 'Understanding SE', shortName: 'Understanding', color: '#388E3C' },
  { value: 4, name: 'Applying SE', shortName: 'Applying', color: '#F57C00' }
]

const activeLevel = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const selectLevel = (level) => {
  activeLevel.value = level
  emit('change', level)
}
</script>

<style scoped>
.mini-pyramid-nav {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 16px 20px;
  background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  border-radius: 12px;
  border: 1px solid #e9ecef;
}

/* Mini Pyramid Visual */
.pyramid-container {
  display: flex;
  flex-direction: column-reverse;
  align-items: center;
  flex-shrink: 0;
}

.pyramid-level {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

/* Level 6 removed per Ulf's meeting 28.11.2025 - keeping style for reference */
.pyramid-level.level-6 {
  width: 70px;
  height: 34px;
  background: linear-gradient(135deg, #e1bee7 0%, #ce93d8 100%);
  clip-path: polygon(20% 0%, 80% 0%, 100% 100%, 0% 100%);
  margin-bottom: -2px;
}

/* Adjusted sizes to accommodate text labels like "Knowing", "Understanding", "Applying" */
.pyramid-level.level-4 {
  width: 100px;
  height: 38px;
  background: linear-gradient(135deg, #ffe0b2 0%, #ffcc80 100%);
  clip-path: polygon(10% 0%, 90% 0%, 100% 100%, 0% 100%);
  margin-bottom: -2px;
}

.pyramid-level.level-2 {
  width: 140px;
  height: 38px;
  background: linear-gradient(135deg, #c8e6c9 0%, #a5d6a7 100%);
  clip-path: polygon(7% 0%, 93% 0%, 100% 100%, 0% 100%);
  margin-bottom: -2px;
}

.pyramid-level.level-1 {
  width: 180px;
  height: 38px;
  background: linear-gradient(135deg, #bbdefb 0%, #90caf9 100%);
  clip-path: polygon(4% 0%, 96% 0%, 100% 100%, 0% 100%);
}

.pyramid-level:hover {
  filter: brightness(1.1);
  transform: scale(1.03);
}

.pyramid-level.active {
  filter: brightness(1.15);
  transform: scale(1.05);
  z-index: 10;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

.pyramid-level.empty {
  opacity: 0.4;
}

.pyramid-level.empty:hover {
  opacity: 0.6;
}

.level-content {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  font-weight: 600;
  color: #333;
  pointer-events: none;
  text-align: center;
}

.level-name {
  font-weight: 600;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  white-space: nowrap;
}

.level-count {
  background: rgba(255,255,255,0.85);
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 9px;
  font-weight: 700;
  min-width: 16px;
  text-align: center;
}

/* Level Tabs */
.level-tabs {
  display: flex;
  gap: 8px;
  flex: 1;
}

.level-tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 12px 16px;
  background: white;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

.level-tab:hover {
  border-color: var(--tab-color);
  background: #fafafa;
}

.level-tab.active {
  border-color: var(--tab-color);
  background: linear-gradient(to bottom, white, #f8f9fa);
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.level-tab.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--tab-color);
  border-radius: 0 0 6px 6px;
}

.tab-level {
  font-size: 11px;
  font-weight: 500;
  color: #909399;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.level-tab.active .tab-level {
  color: var(--tab-color);
}

.tab-name {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}

.tab-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  background: #909399;
  color: white;
  font-size: 11px;
  font-weight: 600;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.level-tab.active .tab-badge {
  background: var(--tab-color);
}

/* Responsive */
@media (max-width: 900px) {
  .mini-pyramid-nav {
    flex-direction: column;
    gap: 16px;
  }

  .level-tabs {
    width: 100%;
    flex-wrap: wrap;
  }

  .level-tab {
    min-width: calc(50% - 4px);
    flex: none;
  }
}

@media (max-width: 480px) {
  .level-tab {
    min-width: 100%;
  }

  .pyramid-container {
    transform: scale(0.85);
  }
}
</style>
