<template>
  <div class="pyramid-level-view">
    <!-- Mini Pyramid Navigation -->
    <MiniPyramidNav
      v-model="activeLevel"
      :level-counts="levelTrainingCounts"
      @change="onLevelChange"
    />

    <!-- Level Content -->
    <div class="level-content-wrapper">
      <LevelContentView
        :level="activeLevel"
        :competencies="currentLevelCompetencies"
        :pathway="pathway"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import MiniPyramidNav from './MiniPyramidNav.vue'
import LevelContentView from './LevelContentView.vue'

const props = defineProps({
  strategyData: {
    type: Object,
    required: true
  },
  pyramidData: {
    type: Object,
    default: null
  },
  pathway: {
    type: String,
    default: 'ROLE_BASED'
  },
  tttData: {
    type: Array,
    default: null
  },
  tttEnabled: {
    type: Boolean,
    default: false
  }
})

// State
const activeLevel = ref(1)

// Get all unique competencies (should be 16 or 18)
const allUniqueCompetencies = computed(() => {
  const competencyMap = new Map()

  // First, try to get from pyramid data (has all competencies per level)
  if (props.pyramidData?.levels) {
    Object.values(props.pyramidData.levels).forEach(levelData => {
      levelData.competencies?.forEach(comp => {
        if (!competencyMap.has(comp.competency_id)) {
          competencyMap.set(comp.competency_id, {
            competency_id: comp.competency_id,
            competency_name: comp.competency_name,
            target_level: comp.target_level || 0
          })
        }
      })
    })
  }

  // Also include from trainable_competencies
  const trainable = props.strategyData?.trainable_competencies || []
  trainable.forEach(comp => {
    if (!competencyMap.has(comp.competency_id)) {
      competencyMap.set(comp.competency_id, {
        competency_id: comp.competency_id,
        competency_name: comp.competency_name,
        target_level: comp.target_level || 0
      })
    }
  })

  return Array.from(competencyMap.values())
})

// Get competencies for a specific level - returns ALL competencies with proper status
const getCompetenciesForLevel = (level) => {
  // SPECIAL CASE: Level 6 with TTT enabled - use TTT data
  if (level === 6 && props.tttEnabled && props.tttData && props.tttData.length > 0) {
    return props.tttData
  }

  // If we have pyramid data with proper structure, use it directly
  if (props.pyramidData?.levels?.[level]?.competencies) {
    return props.pyramidData.levels[level].competencies
  }

  // Fallback: build competency list for this level from trainable_competencies
  const trainable = props.strategyData?.trainable_competencies || []
  const trainableMap = new Map()
  trainable.forEach(comp => {
    trainableMap.set(comp.competency_id, comp)
  })

  // Create full list with all competencies
  return allUniqueCompetencies.value.map(baseComp => {
    const trainedComp = trainableMap.get(baseComp.competency_id)
    const targetLevel = trainedComp?.target_level || baseComp.target_level || 0

    // Determine if this competency needs training at THIS level
    const needsTrainingAtThisLevel = targetLevel === level && trainedComp

    if (needsTrainingAtThisLevel) {
      // Active - needs training at this level
      return {
        ...trainedComp,
        status: 'training_required',
        grayed_out: false
      }
    } else {
      // Grayed - either achieved or different target level
      return {
        competency_id: baseComp.competency_id,
        competency_name: baseComp.competency_name,
        target_level: targetLevel,
        status: targetLevel > level ? 'not_targeted' : 'achieved',
        grayed_out: true,
        message: targetLevel === 0
          ? 'Not targeted by selected strategies'
          : targetLevel > level
            ? `Target is Level ${targetLevel}`
            : `Already at Level ${level} or higher`
      }
    }
  })
}

// Helper to check if a competency has a skill gap that needs training
// Must match the logic in LevelContentView.hasSkillGap
const hasSkillGap = (c, level) => {
  // TTT competencies are always active
  if (c.is_ttt === true) {
    const hasObjective = typeof c.learning_objective === 'string'
      ? c.learning_objective.length > 0
      : c.learning_objective?.objective_text?.length > 0
    return hasObjective
  }

  // Must have status 'training_required' explicitly
  if (c.status !== 'training_required') {
    return false
  }

  // Must NOT be grayed out
  if (c.grayed_out === true) {
    return false
  }

  // Must have a learning objective with actual text
  const hasObjective = typeof c.learning_objective === 'string'
    ? c.learning_objective.length > 0
    : c.learning_objective?.objective_text?.length > 0

  if (!hasObjective) {
    return false
  }

  // Must have a positive gap (current < target)
  const currentLevel = c.current_level ?? 0
  const targetLevel = c.target_level ?? level
  if (currentLevel >= targetLevel) {
    return false
  }

  return true
}

// Count competencies needing training at each level
const levelTrainingCounts = computed(() => {
  const counts = { 1: 0, 2: 0, 4: 0, 6: 0 }

  if (props.pyramidData?.levels) {
    // Use pyramid data if available - use same logic as LevelContentView
    Object.entries(props.pyramidData.levels).forEach(([level, levelData]) => {
      const lvl = parseInt(level)
      if (counts[lvl] !== undefined) {
        counts[lvl] = levelData.competencies?.filter(c => hasSkillGap(c, lvl)).length || 0
      }
    })
  } else {
    // Fallback: count from trainable_competencies
    const trainable = props.strategyData?.trainable_competencies || []
    trainable.forEach(comp => {
      const level = comp.target_level
      if (counts[level] !== undefined && hasSkillGap(comp, level)) {
        counts[level]++
      }
    })
  }

  // SPECIAL: If TTT enabled, Level 6 gets TTT competency count
  if (props.tttEnabled && props.tttData && props.tttData.length > 0) {
    counts[6] = props.tttData.filter(c => hasSkillGap(c, 6)).length
  }

  return counts
})

const currentLevelCompetencies = computed(() => {
  return getCompetenciesForLevel(activeLevel.value)
})

// Methods
const onLevelChange = (level) => {
  activeLevel.value = level
}

// Auto-select first level with training needed
const findFirstLevelWithTraining = () => {
  for (const level of [1, 2, 4, 6]) {
    if (levelTrainingCounts.value[level] > 0) {
      return level
    }
  }
  return 1
}

// Initialize to first level with content
onMounted(() => {
  activeLevel.value = findFirstLevelWithTraining()
})

// Watch for data changes
watch(() => props.strategyData, () => {
  activeLevel.value = findFirstLevelWithTraining()
}, { deep: true })

watch(() => props.pyramidData, () => {
  activeLevel.value = findFirstLevelWithTraining()
}, { deep: true })
</script>

<style scoped>
.pyramid-level-view {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Level Content Wrapper */
.level-content-wrapper {
  min-height: 300px;
}
</style>
