<template>
  <div class="phase-three">
    <div class="phase-header">
      <div class="phase-indicator">
        <div class="phase-number">3</div>
        <div class="phase-title">
          <h1>Phase 3: Macro Planning</h1>
          <p>Select learning modules and qualification formats</p>
        </div>
      </div>
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: `${(currentStep / totalSteps) * 100}%` }"></div>
      </div>
    </div>

    <div class="step-indicator">
      <div
        v-for="step in totalSteps"
        :key="step"
        class="step-dot"
        :class="{
          'active': step === currentStep,
          'completed': step < currentStep
        }"
      >
        {{ step }}
      </div>
    </div>

    <!-- Step 1: Competency Gap Analysis -->
    <div v-if="currentStep === 1" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-data-analysis"></i> Competency Gap Analysis</h2>
        <p>Review your competency assessment results to identify qualification priorities</p>
      </div>

      <div class="gap-analysis">
        <el-card class="analysis-summary">
          <template #header>
            <span>Assessment Summary</span>
          </template>
          <div class="summary-stats">
            <div class="stat-item">
              <div class="stat-value">{{ assessmentData.totalCompetencies }}</div>
              <div class="stat-label">Total Competencies</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ assessmentData.averageScore }}%</div>
              <div class="stat-label">Average Score</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ gapAnalysis.criticalGaps }}</div>
              <div class="stat-label">Critical Gaps</div>
            </div>
          </div>
        </el-card>

        <el-card class="competency-gaps">
          <template #header>
            <span>Competency Gaps by Priority</span>
          </template>
          <div class="gap-list">
            <div
              v-for="gap in gapAnalysis.gaps"
              :key="gap.competency_id"
              class="gap-item"
              :class="gap.priority"
            >
              <div class="gap-info">
                <h4>{{ gap.competency_name }}</h4>
                <p>{{ gap.description }}</p>
                <div class="gap-details">
                  <span class="current-level">Current: Level {{ gap.current_level }}</span>
                  <span class="target-level">Target: Level {{ gap.target_level }}</span>
                </div>
              </div>
              <div class="gap-priority">
                <el-tag :type="getPriorityType(gap.priority)">
                  {{ gap.priority.toUpperCase() }}
                </el-tag>
              </div>
            </div>
          </div>
        </el-card>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep" :disabled="currentStep === 1">Previous</el-button>
        <el-button type="primary" @click="nextStep">Continue to Module Selection</el-button>
      </div>
    </div>

    <!-- Step 2: Module Selection -->
    <div v-if="currentStep === 2" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-collection"></i> Qualification Module Selection</h2>
        <p>Select modules that address your competency gaps and align with your learning objectives</p>
      </div>

      <div class="module-selection">
        <div class="selection-filters">
          <el-row :gutter="20">
            <el-col :span="8">
              <el-select v-model="filters.priority" placeholder="Filter by Priority">
                <el-option label="All Priorities" value=""></el-option>
                <el-option label="Critical" value="critical"></el-option>
                <el-option label="High" value="high"></el-option>
                <el-option label="Medium" value="medium"></el-option>
              </el-select>
            </el-col>
            <el-col :span="8">
              <el-select v-model="filters.format" placeholder="Filter by Format">
                <el-option label="All Formats" value=""></el-option>
                <el-option label="Online" value="online"></el-option>
                <el-option label="In-Person" value="in-person"></el-option>
                <el-option label="Hybrid" value="hybrid"></el-option>
              </el-select>
            </el-col>
            <el-col :span="8">
              <el-select v-model="filters.duration" placeholder="Filter by Duration">
                <el-option label="All Durations" value=""></el-option>
                <el-option label="Short (≤ 2 days)" value="short"></el-option>
                <el-option label="Medium (3-5 days)" value="medium"></el-option>
                <el-option label="Long (> 5 days)" value="long"></el-option>
              </el-select>
            </el-col>
          </el-row>
        </div>

        <div class="modules-grid">
          <div
            v-for="module in filteredModules"
            :key="module.id"
            class="module-card"
            :class="{ 'selected': selectedModules.includes(module.id) }"
            @click="toggleModule(module.id)"
          >
            <div class="module-header">
              <h4>{{ module.title }}</h4>
              <el-tag :type="getPriorityType(module.priority)">{{ module.priority }}</el-tag>
            </div>
            <div class="module-content">
              <p>{{ module.description }}</p>
              <div class="module-details">
                <div class="detail-item">
                  <i class="el-icon-time"></i>
                  <span>{{ module.duration }}</span>
                </div>
                <div class="detail-item">
                  <i class="el-icon-location"></i>
                  <span>{{ module.format }}</span>
                </div>
                <div class="detail-item">
                  <i class="el-icon-star"></i>
                  <span>{{ module.competencies.length }} competencies</span>
                </div>
              </div>
              <div class="competency-tags">
                <el-tag
                  v-for="comp in module.competencies.slice(0, 3)"
                  :key="comp"
                  size="small"
                >
                  {{ comp }}
                </el-tag>
                <span v-if="module.competencies.length > 3" class="more-competencies">
                  +{{ module.competencies.length - 3 }} more
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="selection-summary">
          <el-card>
            <template #header>
              <span>Selected Modules ({{ selectedModules.length }})</span>
            </template>
            <div v-if="selectedModules.length === 0" class="empty-selection">
              <p>No modules selected yet. Choose modules that address your competency gaps.</p>
            </div>
            <div v-else class="selected-summary">
              <div class="summary-stats">
                <div class="stat">
                  <strong>{{ totalDuration }}</strong> total training days
                </div>
                <div class="stat">
                  <strong>{{ coveragePercentage }}%</strong> gap coverage
                </div>
              </div>
            </div>
          </el-card>
        </div>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button
          type="primary"
          @click="nextStep"
          :disabled="selectedModules.length === 0"
        >
          Continue to Format Optimization
        </el-button>
      </div>
    </div>

    <!-- Step 3: Format Optimization -->
    <div v-if="currentStep === 3" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-setting"></i> Training Format Optimization</h2>
        <p>Optimize training formats based on your preferences, schedule, and organizational constraints</p>
      </div>

      <div class="format-optimization">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="preferences-card">
              <template #header>
                <span>Learning Preferences</span>
              </template>
              <el-form :model="preferences" label-width="140px">
                <el-form-item label="Preferred Format">
                  <el-radio-group v-model="preferences.format">
                    <el-radio label="online">Online</el-radio>
                    <el-radio label="in-person">In-Person</el-radio>
                    <el-radio label="hybrid">Hybrid</el-radio>
                    <el-radio label="flexible">Flexible</el-radio>
                  </el-radio-group>
                </el-form-item>
                <el-form-item label="Time Availability">
                  <el-select v-model="preferences.timeAvailability" placeholder="Select availability">
                    <el-option label="Full-time blocks" value="full-time"></el-option>
                    <el-option label="Part-time (evenings)" value="part-time"></el-option>
                    <el-option label="Weekends only" value="weekends"></el-option>
                    <el-option label="Flexible schedule" value="flexible"></el-option>
                  </el-select>
                </el-form-item>
                <el-form-item label="Learning Pace">
                  <el-slider
                    v-model="preferences.pace"
                    :min="1"
                    :max="5"
                    show-stops
                    :format-tooltip="formatPaceTooltip"
                  ></el-slider>
                </el-form-item>
                <el-form-item label="Group Size">
                  <el-radio-group v-model="preferences.groupSize">
                    <el-radio label="individual">Individual</el-radio>
                    <el-radio label="small">Small Group (3-8)</el-radio>
                    <el-radio label="large">Large Group (9+)</el-radio>
                  </el-radio-group>
                </el-form-item>
              </el-form>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card class="constraints-card">
              <template #header>
                <span>Organizational Constraints</span>
              </template>
              <el-form :model="constraints" label-width="140px">
                <el-form-item label="Budget Range">
                  <el-select v-model="constraints.budget" placeholder="Select budget range">
                    <el-option label="< €5,000" value="low"></el-option>
                    <el-option label="€5,000 - €15,000" value="medium"></el-option>
                    <el-option label="> €15,000" value="high"></el-option>
                  </el-select>
                </el-form-item>
                <el-form-item label="Timeline">
                  <el-date-picker
                    v-model="constraints.timeline"
                    type="daterange"
                    range-separator="to"
                    start-placeholder="Start date"
                    end-placeholder="End date"
                  ></el-date-picker>
                </el-form-item>
                <el-form-item label="Location">
                  <el-input v-model="constraints.location" placeholder="Preferred location"></el-input>
                </el-form-item>
                <el-form-item label="Travel Restrictions">
                  <el-switch v-model="constraints.noTravel" active-text="No travel allowed"></el-switch>
                </el-form-item>
              </el-form>
            </el-card>
          </el-col>
        </el-row>

        <el-card class="optimization-results">
          <template #header>
            <span>Optimized Training Plan</span>
            <el-button
              type="text"
              @click="generateOptimizedPlan"
              :loading="optimizing"
              style="float: right;"
            >
              <i class="el-icon-refresh"></i> Re-optimize
            </el-button>
          </template>
          <div v-if="optimizedPlan.length === 0" class="empty-plan">
            <el-button type="primary" @click="generateOptimizedPlan" :loading="optimizing">
              Generate Optimized Plan
            </el-button>
          </div>
          <div v-else class="plan-timeline">
            <div
              v-for="(item, index) in optimizedPlan"
              :key="index"
              class="timeline-item"
            >
              <div class="timeline-marker"></div>
              <div class="timeline-content">
                <h4>{{ item.title }}</h4>
                <p>{{ item.description }}</p>
                <div class="timeline-details">
                  <span class="timeline-date">{{ formatDate(item.startDate) }} - {{ formatDate(item.endDate) }}</span>
                  <span class="timeline-format">{{ item.format }}</span>
                  <span class="timeline-duration">{{ item.duration }}</span>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button
          type="primary"
          @click="nextStep"
          :disabled="optimizedPlan.length === 0"
        >
          Continue to Review
        </el-button>
      </div>
    </div>

    <!-- Step 4: Review & Confirmation -->
    <div v-if="currentStep === 4" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-document"></i> Review & Confirmation</h2>
        <p>Review your qualification plan before proceeding to Phase 4</p>
      </div>

      <div class="review-content">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="review-summary">
              <template #header>
                <span>Plan Summary</span>
              </template>
              <div class="summary-item">
                <strong>Selected Modules:</strong> {{ selectedModules.length }}
              </div>
              <div class="summary-item">
                <strong>Total Duration:</strong> {{ totalDuration }} days
              </div>
              <div class="summary-item">
                <strong>Competency Coverage:</strong> {{ coveragePercentage }}%
              </div>
              <div class="summary-item">
                <strong>Preferred Format:</strong> {{ preferences.format }}
              </div>
              <div class="summary-item">
                <strong>Timeline:</strong> {{ formatDateRange(constraints.timeline) }}
              </div>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card class="review-objectives">
              <template #header>
                <span>Learning Objectives Alignment</span>
              </template>
              <div
                v-for="objective in alignedObjectives"
                :key="objective.id"
                class="objective-item"
              >
                <div class="objective-text">{{ objective.text }}</div>
                <div class="objective-coverage">
                  <el-progress
                    :percentage="objective.coverage"
                    :stroke-width="6"
                    text-inside
                  ></el-progress>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-card class="plan-confirmation">
          <template #header>
            <span>Qualification Plan Confirmation</span>
          </template>
          <el-checkbox v-model="confirmations.planReviewed">
            I have reviewed the qualification plan and selected modules
          </el-checkbox>
          <el-checkbox v-model="confirmations.objectivesAligned">
            The plan aligns with my learning objectives and competency gaps
          </el-checkbox>
          <el-checkbox v-model="confirmations.constraintsConsidered">
            Organizational constraints and preferences have been considered
          </el-checkbox>
          <el-checkbox v-model="confirmations.readyToProceed">
            I am ready to proceed to Phase 4 (Cohort Formation)
          </el-checkbox>
        </el-card>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button
          type="success"
          @click="completePhase"
          :disabled="!allConfirmationsChecked"
          :loading="completing"
        >
          Complete Phase 3
        </el-button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import axios from '@/api/axios'

export default {
  name: 'PhaseThree',
  setup() {
    const router = useRouter()
    const currentStep = ref(1)
    const totalSteps = 4
    const optimizing = ref(false)
    const completing = ref(false)

    // Assessment data from Phase 2
    const assessmentData = ref({
      totalCompetencies: 16,
      averageScore: 68,
      roleId: null
    })

    // Gap analysis results
    const gapAnalysis = ref({
      criticalGaps: 4,
      gaps: []
    })

    // Available modules
    const availableModules = ref([])
    const selectedModules = ref([])

    // Filters for module selection
    const filters = ref({
      priority: '',
      format: '',
      duration: ''
    })

    // Learning preferences
    const preferences = ref({
      format: 'hybrid',
      timeAvailability: 'flexible',
      pace: 3,
      groupSize: 'small'
    })

    // Organizational constraints
    const constraints = ref({
      budget: 'medium',
      timeline: null,
      location: '',
      noTravel: false
    })

    // Optimized plan
    const optimizedPlan = ref([])

    // Aligned objectives
    const alignedObjectives = ref([])

    // Confirmations
    const confirmations = ref({
      planReviewed: false,
      objectivesAligned: false,
      constraintsConsidered: false,
      readyToProceed: false
    })

    // Computed properties
    const filteredModules = computed(() => {
      return availableModules.value.filter(module => {
        if (filters.value.priority && module.priority !== filters.value.priority) return false
        if (filters.value.format && module.format !== filters.value.format) return false
        if (filters.value.duration && module.durationCategory !== filters.value.duration) return false
        return true
      })
    })

    const totalDuration = computed(() => {
      return availableModules.value
        .filter(module => selectedModules.value.includes(module.id))
        .reduce((total, module) => total + module.durationDays, 0)
    })

    const coveragePercentage = computed(() => {
      const coveredGaps = gapAnalysis.value.gaps.filter(gap => {
        return availableModules.value
          .filter(module => selectedModules.value.includes(module.id))
          .some(module => module.competencies.includes(gap.competency_name))
      }).length
      return Math.round((coveredGaps / gapAnalysis.value.gaps.length) * 100)
    })

    const allConfirmationsChecked = computed(() => {
      return Object.values(confirmations.value).every(Boolean)
    })

    // Methods
    const loadAssessmentData = async () => {
      try {
        const response = await axios.get('/api/assessments/latest')
        assessmentData.value = response.data
        await loadGapAnalysis()
      } catch (error) {
        console.error('Error loading assessment data:', error)
        ElMessage.error('Failed to load assessment data')
      }
    }

    const loadGapAnalysis = async () => {
      try {
        const response = await axios.post('/api/assessments/gap-analysis', {
          assessment_id: assessmentData.value.id
        })
        gapAnalysis.value = response.data
      } catch (error) {
        console.error('Error loading gap analysis:', error)
        ElMessage.error('Failed to analyze competency gaps')
      }
    }

    const loadAvailableModules = async () => {
      try {
        const response = await axios.get('/api/modules', {
          params: {
            gaps: gapAnalysis.value.gaps.map(g => g.competency_id)
          }
        })
        availableModules.value = response.data
      } catch (error) {
        console.error('Error loading modules:', error)
        ElMessage.error('Failed to load qualification modules')
      }
    }

    const toggleModule = (moduleId) => {
      const index = selectedModules.value.indexOf(moduleId)
      if (index > -1) {
        selectedModules.value.splice(index, 1)
      } else {
        selectedModules.value.push(moduleId)
      }
    }

    const generateOptimizedPlan = async () => {
      optimizing.value = true
      try {
        const response = await axios.post('/api/optimization/plan', {
          selectedModules: selectedModules.value,
          preferences: preferences.value,
          constraints: constraints.value
        })
        optimizedPlan.value = response.data.timeline
        alignedObjectives.value = response.data.objectives
        ElMessage.success('Training plan optimized successfully')
      } catch (error) {
        console.error('Error optimizing plan:', error)
        ElMessage.error('Failed to optimize training plan')
      } finally {
        optimizing.value = false
      }
    }

    const nextStep = () => {
      if (currentStep.value < totalSteps) {
        currentStep.value++
        if (currentStep.value === 3 && optimizedPlan.value.length === 0) {
          generateOptimizedPlan()
        }
      }
    }

    const previousStep = () => {
      if (currentStep.value > 1) {
        currentStep.value--
      }
    }

    const completePhase = async () => {
      completing.value = true
      try {
        await axios.post('/api/phases/3/complete', {
          selectedModules: selectedModules.value,
          optimizedPlan: optimizedPlan.value,
          preferences: preferences.value,
          constraints: constraints.value
        })

        // Store completion data for phase progression
        const phaseData = {
          selectedModules: selectedModules.value,
          optimizedPlan: optimizedPlan.value,
          preferences: preferences.value,
          constraints: constraints.value,
          completedAt: new Date().toISOString()
        }
        localStorage.setItem('se-qpt-phase3-data', JSON.stringify(phaseData))

        ElMessage.success('Phase 3 completed successfully!')
        router.push('/app/phases/4')
      } catch (error) {
        console.error('Error completing phase:', error)
        ElMessage.error('Failed to complete Phase 3')
      } finally {
        completing.value = false
      }
    }

    // Utility methods
    const getPriorityType = (priority) => {
      const types = {
        critical: 'danger',
        high: 'warning',
        medium: 'info',
        low: 'success'
      }
      return types[priority] || 'info'
    }

    const formatPaceTooltip = (value) => {
      const paces = {
        1: 'Very Slow',
        2: 'Slow',
        3: 'Moderate',
        4: 'Fast',
        5: 'Very Fast'
      }
      return paces[value]
    }

    const formatDate = (date) => {
      if (!date) return ''
      return new Date(date).toLocaleDateString()
    }

    const formatDateRange = (range) => {
      if (!range || !range[0] || !range[1]) return 'Not specified'
      return `${formatDate(range[0])} - ${formatDate(range[1])}`
    }

    // Lifecycle
    onMounted(async () => {
      await loadAssessmentData()
      await loadAvailableModules()
    })

    return {
      currentStep,
      totalSteps,
      optimizing,
      completing,
      assessmentData,
      gapAnalysis,
      availableModules,
      selectedModules,
      filters,
      preferences,
      constraints,
      optimizedPlan,
      alignedObjectives,
      confirmations,
      filteredModules,
      totalDuration,
      coveragePercentage,
      allConfirmationsChecked,
      toggleModule,
      generateOptimizedPlan,
      nextStep,
      previousStep,
      completePhase,
      getPriorityType,
      formatPaceTooltip,
      formatDate,
      formatDateRange
    }
  }
}
</script>

<style scoped>
.phase-three {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.phase-header {
  text-align: center;
  margin-bottom: 30px;
}

.phase-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin-bottom: 20px;
}

.phase-number {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: linear-gradient(135deg, #FF7043 0%, #F4511E 100%);
  box-shadow: 0 4px 12px rgba(244, 81, 30, 0.25);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: bold;
}

.phase-title h1 {
  margin: 0;
  color: #2c3e50;
}

.phase-title p {
  margin: 5px 0 0 0;
  color: #7f8c8d;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: #ecf0f1;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
  transition: width 0.3s ease;
}

.step-indicator {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-bottom: 40px;
}

.step-dot {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid #bdc3c7;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  transition: all 0.3s ease;
}

.step-dot.active {
  border-color: #667eea;
  background: #667eea;
  color: white;
}

.step-dot.completed {
  border-color: #27ae60;
  background: #27ae60;
  color: white;
}

.step-content {
  margin-bottom: 40px;
}

.step-header {
  text-align: center;
  margin-bottom: 30px;
}

.step-header h2 {
  color: #2c3e50;
  margin-bottom: 10px;
}

.step-actions {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 40px;
}

/* Gap Analysis Styles */
.gap-analysis {
  display: grid;
  gap: 20px;
}

.analysis-summary .summary-stats {
  display: flex;
  justify-content: space-around;
  text-align: center;
}

.stat-item {
  flex: 1;
}

.stat-value {
  font-size: 2em;
  font-weight: bold;
  color: #667eea;
}

.stat-label {
  color: #7f8c8d;
  margin-top: 5px;
}

.gap-list {
  display: grid;
  gap: 15px;
}

.gap-item {
  display: flex;
  align-items: center;
  padding: 15px;
  border: 1px solid #ecf0f1;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.gap-item:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.gap-item.critical {
  border-left: 4px solid #e74c3c;
}

.gap-item.high {
  border-left: 4px solid #f39c12;
}

.gap-item.medium {
  border-left: 4px solid #3498db;
}

.gap-info {
  flex: 1;
}

.gap-info h4 {
  margin: 0 0 5px 0;
  color: #2c3e50;
}

.gap-info p {
  margin: 0 0 10px 0;
  color: #7f8c8d;
  font-size: 14px;
}

.gap-details {
  display: flex;
  gap: 15px;
  font-size: 12px;
}

.gap-details span {
  padding: 2px 8px;
  background: #f8f9fa;
  border-radius: 4px;
}

/* Module Selection Styles */
.module-selection {
  display: grid;
  gap: 20px;
}

.selection-filters {
  margin-bottom: 20px;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.module-card {
  border: 2px solid #ecf0f1;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.module-card:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.1);
}

.module-card.selected {
  border-color: #667eea;
  background: #f8f9ff;
}

.module-header {
  display: flex;
  justify-content: between;
  align-items: center;
  margin-bottom: 15px;
}

.module-header h4 {
  margin: 0;
  color: #2c3e50;
  flex: 1;
}

.module-content p {
  color: #7f8c8d;
  margin-bottom: 15px;
  line-height: 1.5;
}

.module-details {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
}

.detail-item {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 14px;
  color: #7f8c8d;
}

.competency-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  align-items: center;
}

.more-competencies {
  font-size: 12px;
  color: #7f8c8d;
  margin-left: 5px;
}

/* Format Optimization Styles */
.format-optimization {
  display: grid;
  gap: 20px;
}

.optimization-results {
  margin-top: 20px;
}

.empty-plan {
  text-align: center;
  padding: 40px;
}

.plan-timeline {
  position: relative;
  padding-left: 30px;
}

.timeline-item {
  position: relative;
  margin-bottom: 30px;
  padding-left: 30px;
}

.timeline-marker {
  position: absolute;
  left: -8px;
  top: 5px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #667eea;
  border: 3px solid white;
  box-shadow: 0 0 0 2px #667eea;
}

.timeline-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 21px;
  bottom: -30px;
  width: 2px;
  background: #ecf0f1;
}

.timeline-item:last-child::before {
  display: none;
}

.timeline-content h4 {
  margin: 0 0 5px 0;
  color: #2c3e50;
}

.timeline-content p {
  margin: 0 0 10px 0;
  color: #7f8c8d;
}

.timeline-details {
  display: flex;
  gap: 15px;
  font-size: 14px;
}

.timeline-details span {
  padding: 2px 8px;
  background: #f8f9fa;
  border-radius: 4px;
  color: #7f8c8d;
}

/* Review Styles */
.review-content {
  margin-bottom: 30px;
}

.summary-item {
  margin-bottom: 10px;
  padding: 8px 0;
  border-bottom: 1px solid #ecf0f1;
}

.objective-item {
  margin-bottom: 15px;
}

.objective-text {
  margin-bottom: 8px;
  color: #2c3e50;
}

.plan-confirmation {
  margin-top: 20px;
}

.plan-confirmation .el-checkbox {
  display: block;
  margin-bottom: 15px;
}
</style>