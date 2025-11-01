<template>
  <div class="strategy-selection">
    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="6" animated />
    </div>

    <!-- Error State -->
    <el-alert
      v-else-if="error"
      type="error"
      :title="error"
      show-icon
      :closable="false"
    >
      <el-button @click="initializeStrategies" type="primary" size="small">
        Retry
      </el-button>
    </el-alert>

    <!-- Main Content -->
    <div v-else class="strategy-content">
      <!-- Introduction -->
      <div class="strategy-intro">
        <h2>Training Strategy Selection</h2>
        <p>
          Based on your organization's maturity assessment and target group size,
          we've recommended training strategies that best fit your needs.
        </p>
      </div>

      <!-- Strategy Profile Cards Section (Renamed) -->
      <el-card class="strategy-profile-card" shadow="hover">
        <template #header>
          <h3>
            <el-icon><MagicStick /></el-icon>
            Strategy Profile Cards
          </h3>
        </template>

        <!-- Info about strategy selection -->
        <el-alert
          type="info"
          :closable="false"
          show-icon
          class="selection-info-alert"
        >
          <div class="selection-info-content">
            <p>
              The system has <strong>recommended and pre-selected strategies</strong> based on your maturity assessment. You can modify the selection or explore additional strategies below.
            </p>
            <p style="margin-top: 12px;">
              <strong>Need help understanding why these strategies were recommended?</strong> Scroll down to the <em>"Our Recommendation Rationale"</em> section below to learn the reasoning behind our strategy selection and how it aligns with your organization's maturity profile.
            </p>
          </div>
        </el-alert>

        <!-- Recommended Strategies Section -->
        <div class="recommended-section">
          <div class="section-header">
            <h4 class="section-title">
              <el-icon color="#4CAF50"><CircleCheck /></el-icon>
              Recommended Strategies
            </h4>
            <p class="section-subtitle">
              These strategies are tailored to your organization's current maturity level and have been pre-selected for you.
            </p>
          </div>

          <div class="strategies-grid">
            <StrategyCard
              v-for="strategy in recommendedStrategyList"
              :key="strategy.id"
              :strategy="strategy"
              :is-selected="isStrategySelected(strategy.id)"
              :is-recommended="true"
              :disabled="false"
              :show-view-details="false"
              @toggle="handleStrategyToggle"
            />
          </div>
        </div>

        <!-- Additional Strategies Section -->
        <div v-if="additionalStrategyList.length > 0" class="additional-section">
          <div class="section-header">
            <h4 class="section-title">
              <el-icon color="#757575"><MoreFilled /></el-icon>
              Additional Strategies
            </h4>
            <p v-if="!showAllStrategies" class="section-subtitle">
              The recommended strategies above are best suited for your maturity level. Additional strategies are available but may not align with your current organizational context.
            </p>
            <p v-else class="section-subtitle">
              All strategies are now available for selection. Consider the recommended strategies above as they are best suited for your maturity level.
            </p>
          </div>

          <!-- Enable Additional Strategies Button -->
          <div v-if="!showAllStrategies" class="enable-additional-container">
            <el-button
              type="default"
              size="large"
              @click="showAllStrategies = true"
              plain
            >
              <el-icon><Unlock /></el-icon>
              Show All Strategies
            </el-button>
            <p class="enable-hint">
              Click to view and select from all available training strategies
            </p>
          </div>

          <!-- Additional Strategy Cards (disabled unless showAllStrategies is true) -->
          <div v-else class="strategies-grid">
            <div
              v-for="strategy in additionalStrategyList"
              :key="strategy.id"
              :id="`strategy-card-${strategy.id}`"
            >
              <StrategyCard
                :strategy="strategy"
                :is-selected="isStrategySelected(strategy.id)"
                :is-recommended="false"
                :disabled="false"
                :show-view-details="false"
                @toggle="handleStrategyToggle"
              />
            </div>
          </div>
        </div>
      </el-card>

      <!-- Our Recommendation Rationale Card -->
      <el-card v-if="decisionPath && decisionPath.length > 0" class="decision-path-card" shadow="hover">
        <template #header>
          <h3>
            <el-icon><Connection /></el-icon>
            Our Recommendation Rationale
          </h3>
        </template>

        <!-- Enhanced Decision Timeline -->
        <el-timeline class="decision-timeline">
          <el-timeline-item
            v-for="(step, index) in enhancedDecisionPath"
            :key="index"
            :timestamp="`Step ${step.step}`"
            placement="top"
          >
            <el-card>
              <h4>{{ step.title }}</h4>
              <p class="timeline-explanation">{{ step.explanation }}</p>

              <!-- Special handling for user choice required -->
              <div v-if="step.requiresUserChoice" class="user-choice-required">
                <el-alert
                  type="warning"
                  :closable="false"
                  show-icon
                >
                  <template #title>Your Decision Required</template>
                  <p>Since SE processes and roles maturity is not yet established in your organization, please select your preferred secondary strategy from the three options below. Review the pros and cons to make an informed decision.</p>
                </el-alert>
                <div class="strategy-options-list">
                  <h5>Available Secondary Strategies:</h5>
                  <ul>
                    <li v-for="(option, idx) in step.options" :key="idx">
                      <strong>{{ getStrategyNameById(option) }}</strong> - {{ getStrategyBestFor(option) }}
                    </li>
                  </ul>
                  <p class="scroll-hint">
                    <el-icon><ArrowDown /></el-icon>
                    Scroll down to compare the pros and cons of each strategy
                  </p>
                </div>
              </div>

            </el-card>
          </el-timeline-item>
        </el-timeline>
      </el-card>

      <!-- Pro-Con Comparison (only for low maturity) -->
      <div v-if="requiresUserChoice" class="pro-con-section">
        <ProConComparison
          :strategies="['common_understanding', 'orientation_pilot', 'certification']"
          v-model="userPreference"
          @select="handleSecondarySelection"
        />
      </div>

      <!-- Strategy Summary -->
      <StrategySummary
        :strategies="selectedStrategiesForDisplay"
        :target-group-data="props.targetGroupData"
        :user-preference="userPreference"
      />

      <!-- Action Buttons -->
      <div class="action-buttons">
        <el-button @click="handleBack" size="large">
          <el-icon><ArrowLeft /></el-icon>
          Back to Role Identification
        </el-button>

        <div style="flex: 1"></div>

        <el-button
          type="primary"
          size="large"
          @click="handleConfirm"
          :disabled="!canProceed"
          :loading="saving"
        >
          Confirm Strategy Selection
          <el-icon><ArrowRight /></el-icon>
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  MagicStick,
  Connection,
  ArrowLeft,
  ArrowRight,
  ArrowDown,
  CircleCheck,
  MoreFilled,
  Unlock
} from '@element-plus/icons-vue'
import { strategyApi } from '@/api/phase1'
import { useAuthStore } from '@/stores/auth'
import StrategyCard from './StrategyCard.vue'
import ProConComparison from './ProConComparison.vue'
import StrategySummary from './StrategySummary.vue'

// Props
const props = defineProps({
  maturityData: {
    type: Object,
    required: true
  },
  targetGroupData: {
    type: Object,
    required: true
  },
  rolesData: {
    type: Array,
    default: () => []
  },
  existingStrategies: {
    type: Object,
    default: null
  }
})

// Emits
const emit = defineEmits(['complete', 'back'])

// Composables
const authStore = useAuthStore()

// State
const loading = ref(false)
const saving = ref(false)
const error = ref(null)
const allStrategies = ref([])
const recommendedStrategies = ref([])
const selectedStrategies = ref([])
const decisionPath = ref([])
const reasoning = ref(null)
const requiresUserChoice = ref(false)
const userPreference = ref(null)
const showAllStrategies = ref(false) // Controls whether additional strategies are enabled

// Computed
// Separate recommended strategies from all strategies
const recommendedStrategyIds = computed(() => {
  return new Set(recommendedStrategies.value.map(s => s.strategy))
})

const recommendedStrategyList = computed(() => {
  return allStrategies.value.filter(s => recommendedStrategyIds.value.has(s.id))
})

const additionalStrategyList = computed(() => {
  return allStrategies.value.filter(s => !recommendedStrategyIds.value.has(s.id))
})

const selectedStrategiesForDisplay = computed(() => {
  // If user selected a secondary strategy, add it to the list
  if (requiresUserChoice.value && userPreference.value) {
    // Check if the user-selected strategy already exists in the array (by ID, not priority)
    const alreadyExists = selectedStrategies.value.some(s => s.strategy === userPreference.value)
    if (!alreadyExists) {
      // Add the user-selected secondary strategy
      return [
        ...selectedStrategies.value,
        {
          strategy: userPreference.value,
          strategyName: getStrategyNameById(userPreference.value),
          priority: 'SECONDARY',
          reason: 'Selected by user as secondary training strategy',
          userSelected: true,
          autoRecommended: false
        }
      ]
    }
  }

  return selectedStrategies.value
})

const canProceed = computed(() => {
  // Must have at least one strategy selected
  // Users can now manually select strategies from Strategy Profile Cards
  if (!selectedStrategies.value || selectedStrategies.value.length === 0) {
    return false
  }

  // Pro-Con cards are now informational only
  // Users manually select strategies from Strategy Profile Cards section
  // No need to check userPreference anymore

  return true
})

// Enhanced decision path with narrative explanations
const enhancedDecisionPath = computed(() => {
  if (!decisionPath.value || decisionPath.value.length === 0) {
    return []
  }

  return decisionPath.value.map((step, index) => {
    const enhanced = {
      step: step.step,
      title: step.decision,
      explanation: step.reason,
      options: step.options || null,
      requiresUserChoice: false
    }

    // Enhance based on strategy type
    const decision = step.decision.toLowerCase()

    // Train-the-Trainer
    if (decision.includes('train-the-trainer') || decision.includes('train the trainer')) {
      enhanced.title = 'Why Train-the-Trainer?'
      enhanced.explanation = `The "Train the Trainer" strategy is always chosen first for organizations with large target groups. This multiplier approach enables scalable knowledge transfer. You have two options: train internal employees as expert trainers for long-term, cost-effective training (ideal for sustained qualification programs), or engage external trainers who bring immediate SE expertise that can be adapted to your company context (ideal for short-term qualification measures).`
    }
    // SE for Managers
    else if (decision.includes('se for managers') || decision.includes('managers')) {
      enhanced.title = 'Why SE for Managers First?'
      enhanced.explanation = `When SE processes and roles are not yet established (maturity level "Not available" or "Ad hoc/undefined"), your organization is in the motivation phase of SE introduction. At this stage, management buy-in is essential. The "SE for Managers" strategy is selected first because managers are the enablers for SE implementation projects. Only when company management is convinced of SE can a holistic introduction be guaranteed across the organization.`
    }
    // User selects secondary strategy
    else if (step.options && step.options.length > 0) {
      enhanced.title = 'Select Your Secondary Strategy'
      enhanced.explanation = `After introducing SE to managers, you must decide on the next phase of your SE qualification journey. Since processes and roles are not yet fully established, you can choose between three paths based on your organizational priorities:`
      enhanced.requiresUserChoice = true
    }
    // Needs-based Project-oriented Training
    else if (decision.includes('needs-based') || decision.includes('project-oriented')) {
      enhanced.title = 'Why Needs-based Project-oriented Training?'
      enhanced.explanation = `Your organization has defined and established SE processes and roles (maturity level "Individually controlled" or higher), but SE is not yet widely deployed (rollout scope is "Not available" or "Individual area"). This indicates that while you have the foundation in place, SE needs broader application. The "Needs-based Project-oriented Training" strategy allows the majority of employees in selected projects to apply and experience SE in real-world scenarios, expanding SE adoption organically.`
    }
    // Continuous Support
    else if (decision.includes('continuous support')) {
      enhanced.title = 'Why Continuous Support?'
      enhanced.explanation = `Your organization has both established SE processes/roles AND broad deployment across multiple areas or company-wide (rollout scope "Development area", "Company wide", or "Value chain"). At this maturity level, SE is already being practiced. "Continuous Support" is recommended to onboard remaining employees, provide refresher training for experienced practitioners, and maintain SE excellence as your practices evolve.`
    }

    return enhanced
  })
})

// Methods
const initializeStrategies = async () => {
  try {
    loading.value = true
    error.value = null

    console.log('[StrategySelection] Initializing with data:', {
      maturity: props.maturityData,
      targetGroup: props.targetGroupData,
      hasExistingStrategies: !!props.existingStrategies
    })

    // Step 1: Fetch all strategy definitions
    const definitionsResponse = await strategyApi.getDefinitions()
    allStrategies.value = definitionsResponse.strategies

    console.log('[StrategySelection] Loaded', allStrategies.value.length, 'strategy definitions')

    // Step 2: Calculate recommended strategies based on current maturity and target group data
    // (Always calculate to show recommendations, but may be overridden by existing selections)

    // Transform maturityData to backend expected format (snake_case)
    const transformedMaturityData = {
      rollout_scope: props.maturityData.strategyInputs?.rolloutScopeValue ?? 0,
      se_processes: props.maturityData.strategyInputs?.seProcessesValue ?? 0,
      se_mindset: props.maturityData.strategyInputs?.seMindsetValue ?? 0,
      knowledge_base: props.maturityData.strategyInputs?.knowledgeBaseValue ?? 0,
      final_score: props.maturityData.finalScore ?? 0,
      maturity_level: props.maturityData.maturityLevel ?? 1
    }

    console.log('[StrategySelection] Transformed maturity data:', transformedMaturityData)

    const calculationResponse = await strategyApi.calculate(
      transformedMaturityData,
      props.targetGroupData
    )

    recommendedStrategies.value = calculationResponse.strategies
    decisionPath.value = calculationResponse.decisionPath || []
    reasoning.value = calculationResponse.reasoning || null
    requiresUserChoice.value = calculationResponse.requiresUserChoice || false

    // Step 3: Check if user has previously saved strategies
    if (props.existingStrategies && props.existingStrategies.strategies && props.existingStrategies.strategies.length > 0) {
      // User has existing selections - restore them
      console.log('[StrategySelection] Restoring existing user selections:', {
        count: props.existingStrategies.count,
        strategies: props.existingStrategies.strategies.map(s => s.strategyName)
      })

      selectedStrategies.value = props.existingStrategies.strategies

      // Restore user preference if exists
      if (props.existingStrategies.userPreference) {
        userPreference.value = props.existingStrategies.userPreference
        console.log('[StrategySelection] Restored user preference:', userPreference.value)
      }

      ElMessage.success('Loaded your previously selected strategies')
    } else {
      // No existing selections - use freshly calculated recommendations
      console.log('[StrategySelection] No existing selections - using fresh recommendations')
      selectedStrategies.value = [...calculationResponse.strategies]
    }

    console.log('[StrategySelection] Initialization complete:', {
      recommendedCount: recommendedStrategies.value.length,
      selectedCount: selectedStrategies.value.length,
      requiresUserChoice: requiresUserChoice.value,
      strategies: selectedStrategies.value.map(s => s.strategyName)
    })

  } catch (err) {
    console.error('[StrategySelection] Failed to initialize:', err)
    error.value = 'Failed to load training strategies. Please try again.'
    ElMessage.error('Failed to load training strategies')
  } finally {
    loading.value = false
  }
}

const isStrategySelected = (strategyId) => {
  return selectedStrategies.value.some(s => s.strategy === strategyId) ||
         (requiresUserChoice.value && userPreference.value === strategyId)
}

const isStrategyRecommended = (strategyId) => {
  return recommendedStrategies.value.some(s => s.strategy === strategyId && s.autoRecommended)
}

const handleStrategyToggle = (strategyId) => {
  console.log('[StrategySelection] Strategy toggle:', strategyId)

  // Check if strategy is currently selected
  const isCurrentlySelected = isStrategySelected(strategyId)

  if (isCurrentlySelected) {
    // Deselect: Remove from selectedStrategies array
    selectedStrategies.value = selectedStrategies.value.filter(s => s.strategy !== strategyId)

    // Also clear userPreference if this is the selected secondary strategy
    if (requiresUserChoice.value && userPreference.value === strategyId) {
      userPreference.value = null
      console.log('[StrategySelection] User preference cleared - pro-con will reappear')
    }

    console.log('[StrategySelection] Strategy deselected:', strategyId)
  } else {
    // Select: Add to selectedStrategies
    const strategyDefinition = allStrategies.value.find(s => s.id === strategyId)
    if (strategyDefinition) {
      selectedStrategies.value.push({
        strategy: strategyId,
        strategyName: strategyDefinition.name,
        priority: 'SUPPLEMENTARY', // User-selected strategies default to supplementary
        reason: 'Manually selected by user to meet specific organizational needs',
        userSelected: true,
        autoRecommended: false
      })
      console.log('[StrategySelection] Strategy selected:', strategyId)
    }
  }
}

const handleSecondarySelection = (strategyId) => {
  console.log('[StrategySelection] Secondary strategy selected:', strategyId)
  userPreference.value = strategyId

  // Auto-unlock Additional Strategies section
  if (!showAllStrategies.value) {
    showAllStrategies.value = true
    console.log('[StrategySelection] Auto-unlocked Additional Strategies section')
  }

  // Auto-select the chosen strategy card if not already selected
  if (!isStrategySelected(strategyId)) {
    handleStrategyToggle(strategyId)
    console.log('[StrategySelection] Auto-selected strategy card:', strategyId)
  }

  // Scroll to the selected strategy card
  setTimeout(() => {
    const cardElement = document.getElementById(`strategy-card-${strategyId}`)
    if (cardElement) {
      cardElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
      console.log('[StrategySelection] Scrolled to strategy card:', strategyId)
    }
  }, 300) // Small delay to ensure DOM has updated with unlocked cards
}

const getStrategyNameById = (strategyId) => {
  const strategy = allStrategies.value.find(s => s.id === strategyId)
  return strategy ? strategy.name : strategyId
}

const getStrategyBestFor = (strategyId) => {
  const bestForMap = {
    'common_understanding': 'Best for ensuring all stakeholders have a shared foundation of SE knowledge',
    'orientation_pilot': 'Best for learning SE through real-world project application with coaching support',
    'certification': 'Best for creating certified SE experts and specialists within your organization'
  }
  return bestForMap[strategyId] || ''
}

const getRecommendationType = (type) => {
  const typeMap = {
    CRITICAL: 'danger',
    IMPORTANT: 'warning',
    SUGGESTED: 'info'
  }
  return typeMap[type] || 'info'
}

const handleBack = () => {
  emit('back')
}

const handleConfirm = async () => {
  try {
    saving.value = true

    // Validate maturity data has an ID
    if (!props.maturityData.id) {
      ElMessage.error('Maturity assessment ID not found. Please complete maturity assessment first.')
      return
    }

    // Prepare strategies for save
    const strategiesToSave = selectedStrategiesForDisplay.value.map(s => ({
      strategy: s.strategy,
      strategyName: s.strategyName,
      priority: s.priority,
      reason: s.reason,
      userSelected: s.userSelected || false,
      autoRecommended: s.autoRecommended || false,
      warning: s.warning || null
    }))

    console.log('[StrategySelection] Saving strategies:', {
      orgId: authStore.organizationId,
      maturityId: props.maturityData.id,
      count: strategiesToSave.length,
      userPreference: userPreference.value
    })

    // Save to backend
    const saveResponse = await strategyApi.save(
      authStore.organizationId,
      props.maturityData.id,
      strategiesToSave,
      decisionPath.value,
      userPreference.value
    )

    console.log('[StrategySelection] Save successful:', saveResponse)

    ElMessage.success(`${saveResponse.count} training ${saveResponse.count === 1 ? 'strategy' : 'strategies'} selected successfully!`)

    // Emit complete event with all data
    emit('complete', {
      strategies: saveResponse.strategies,
      count: saveResponse.count,
      userPreference: userPreference.value,
      decisionPath: decisionPath.value,
      reasoning: reasoning.value
    })

  } catch (err) {
    console.error('[StrategySelection] Failed to save:', err)
    ElMessage.error('Failed to save strategy selection. Please try again.')
  } finally {
    saving.value = false
  }
}

// Lifecycle
onMounted(() => {
  initializeStrategies()
})
</script>

<style scoped>
.strategy-selection {
  width: 100%;
  max-width: 1400px;
  margin: 0 auto;
}

.loading-container {
  padding: 40px;
}

.strategy-content {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.strategy-intro {
  text-align: center;
  margin-bottom: 8px;
}

.strategy-intro h2 {
  margin: 0 0 12px 0;
  font-size: 1.8rem;
  font-weight: 600;
  color: #2c3e50;
}

.strategy-intro p {
  margin: 0;
  font-size: 1.05rem;
  color: #6c757d;
  max-width: 800px;
  margin: 0 auto;
  line-height: 1.6;
}

.strategy-profile-card h3,
.decision-path-card h3 {
  margin: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.selection-info-alert {
  margin-bottom: 24px;
}

.selection-info-content p {
  margin: 8px 0;
  line-height: 1.6;
  font-size: 0.95rem;
}

.selection-info-content p:first-child {
  margin-top: 0;
}

.selection-info-content p:last-child {
  margin-bottom: 0;
}

.reasoning-alert {
  margin-bottom: 24px;
}

.rationale-intro {
  margin: 0 0 16px 0;
  font-size: 1rem;
  font-weight: 500;
  color: #2c3e50;
}

.reasoning-content {
  margin-top: 12px;
}

.reasoning-factors {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 16px;
}

.factor {
  padding: 12px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 6px;
  font-size: 0.95rem;
}

.factor strong {
  color: #1976D2;
  margin-right: 6px;
}

.recommendations-list {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.recommendations-list h4 {
  margin: 0 0 12px 0;
  font-size: 0.95rem;
  font-weight: 600;
  color: #2c3e50;
}

.recommendations-list ul {
  margin: 0;
  padding-left: 24px;
}

.recommendations-list li {
  margin-bottom: 8px;
  line-height: 1.6;
}

.recommended-section {
  margin-bottom: 48px;
}

.additional-section {
  margin-top: 48px;
  padding-top: 32px;
  border-top: 2px dashed #e0e0e0;
}

.section-header {
  margin-bottom: 24px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
}

.section-subtitle {
  margin: 0;
  font-size: 0.95rem;
  color: #6c757d;
  line-height: 1.6;
  max-width: 900px;
}

.enable-additional-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 32px;
  background: linear-gradient(135deg, #f5f5f5 0%, #fafafa 100%);
  border: 2px dashed #bdbdbd;
  border-radius: 12px;
  text-align: center;
}

.enable-hint {
  margin: 0;
  font-size: 0.9rem;
  color: #757575;
  font-style: italic;
}

.strategies-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 24px;
  margin-top: 20px;
}

.pro-con-section {
  margin: 32px 0;
}

.decision-path-card {
  margin-top: 0;
}

.decision-timeline {
  margin-top: 20px;
}

.decision-path-card h4 {
  margin: 0 0 8px 0;
  font-size: 1rem;
  font-weight: 600;
  color: #2c3e50;
}

.decision-path-card p {
  margin: 0;
  color: #6c757d;
  line-height: 1.5;
}

.decision-options {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #e0e0e0;
}

.decision-options ul {
  margin: 8px 0 0 0;
  padding-left: 20px;
}

.decision-options li {
  margin-bottom: 4px;
}

.timeline-explanation {
  font-size: 0.95rem;
  line-height: 1.7;
  color: #495057;
  margin-bottom: 16px;
}

.user-choice-required {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 2px solid #ffc107;
}

.user-choice-required .el-alert {
  margin-bottom: 16px;
}

.strategy-options-list {
  margin-top: 16px;
}

.strategy-options-list h5 {
  margin: 0 0 12px 0;
  font-size: 0.95rem;
  font-weight: 600;
  color: #2c3e50;
}

.strategy-options-list ul {
  margin: 0 0 16px 0;
  padding-left: 24px;
}

.strategy-options-list li {
  margin-bottom: 10px;
  line-height: 1.6;
  font-size: 0.95rem;
}

.strategy-options-list li strong {
  color: #1976D2;
}

.scroll-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 16px 0 0 0;
  padding: 12px;
  background: #fff3cd;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  color: #856404;
}

.scroll-hint .el-icon {
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-10px);
  }
  60% {
    transform: translateY(-5px);
  }
}

.action-buttons {
  display: flex;
  gap: 16px;
  justify-content: space-between;
  align-items: center;
  padding-top: 24px;
  border-top: 2px solid #e9ecef;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .strategies-grid {
    grid-template-columns: 1fr;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-buttons > div {
    display: none;
  }
}
</style>
