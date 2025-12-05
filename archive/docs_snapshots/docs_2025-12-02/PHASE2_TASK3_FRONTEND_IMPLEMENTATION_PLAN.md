# Phase 2 Task 3 - Frontend UI Implementation Plan
**Date**: November 5, 2025
**Status**: Ready for Implementation
**Backend Status**: ✅ Complete and Tested (93.8% test pass rate)

---

## Executive Summary

This plan outlines the complete frontend implementation for **Phase 2 Task 3: Learning Objectives Generation**. The backend is fully implemented and tested. This plan focuses on creating the admin-facing UI components to:

1. Monitor assessment completion across the organization
2. Provide/update PMT (Processes, Methods, Tools) context when needed
3. Generate learning objectives via AI-powered algorithm
4. Review and validate generated objectives with rich visualizations
5. Export results in multiple formats (PDF, Excel, JSON)

---

## 1. Current State Analysis

### ✅ Backend Implementation (COMPLETE)

**Service Files**:
- `pathway_determination.py` - Main orchestrator, routes to correct pathway
- `task_based_pathway.py` - 2-way comparison for low-maturity orgs (maturity < 3)
- `role_based_pathway_fixed.py` - 8-step algorithm for high-maturity orgs (maturity ≥ 3)
- `learning_objectives_text_generator.py` - Template retrieval + LLM customization

**API Endpoints** (in `routes.py`):
- `POST /api/phase2/learning-objectives/generate` - Generate objectives
- `GET /api/phase2/learning-objectives/<org_id>` - Retrieve objectives
- `GET/PATCH /api/phase2/learning-objectives/<org_id>/pmt-context` - Manage PMT
- `GET /api/phase2/learning-objectives/<org_id>/validation` - Quick validation check

**Testing Status**:
- 48 comprehensive tests
- 93.8% pass rate (45/48 tests passed)
- Production-ready

### ❌ Frontend Implementation (MISSING)

**What Exists**:
- Phase 2 Task 1 (Role/Task Selection) ✅
- Phase 2 Task 2 (Competency Assessment) ✅
- Phase progression system ✅
- Element Plus UI framework ✅
- Vue 3 Composition API ✅

**What's Missing**:
- Phase 2 Task 3 components (all new)
- API integration in `phase2.js` (placeholder exists)
- Route for Phase 2 Task 3 admin view
- Admin dashboard entry point

---

## 2. Design Reference

**Primary Source**: `LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

**Key Design Elements**:
- **Two Pathways**: Task-based (simple) vs Role-based (complex with validation)
- **PMT Context**: Conditional form for 2 specific strategies requiring deep customization
- **Validation Layer**: Holistic strategy adequacy check before generation
- **Rich Output**: Strategy tabs, competency cards, scenario distributions, priorities
- **Export**: PDF, Excel, JSON formats

**UI Sections** (from design lines 1662-1861):
1. Assessment completion monitoring
2. Pre-generation validation (optional quick check)
3. PMT context form (conditional)
4. Generation confirmation dialog
5. Results dashboard with strategy tabs
6. Competency detail cards with visualizations
7. Validation summary card
8. Export dialog
9. Strategy addition flow (for recommendations)

---

## 3. Technical Architecture

### 3.1 Component Structure

```
src/frontend/src/
├── components/
│   └── phase2/
│       └── task3/                          [NEW]
│           ├── Phase2Task3Dashboard.vue    [Main container]
│           ├── AssessmentMonitor.vue       [Completion tracking]
│           ├── PMTContextForm.vue          [Company context input]
│           ├── ValidationSummaryCard.vue   [Strategy validation results]
│           ├── LearningObjectivesView.vue  [Results display]
│           ├── StrategyTabPanel.vue        [Per-strategy objectives]
│           ├── CompetencyCard.vue          [Individual competency details]
│           ├── ScenarioDistributionChart.vue [Visualization]
│           ├── ExportDialog.vue            [Export options]
│           └── GenerationConfirmDialog.vue [Admin confirmation]
├── views/
│   └── phases/
│       └── Phase2Task3Admin.vue            [NEW - Admin view]
├── api/
│   └── phase2.js                           [UPDATE - Add Task 3 APIs]
└── router/
    └── index.js                            [UPDATE - Add Task 3 route]
```

### 3.2 Data Flow

```
1. Admin navigates to Phase 2 Task 3 Dashboard
   └─> Fetch completion stats, strategies, PMT status

2. Admin monitors assessment completion
   └─> Real-time progress: X/Y users completed

3. Admin optionally runs pre-validation check
   └─> GET /validation → Shows quick strategy adequacy

4. If PMT needed: Admin fills PMT form
   └─> PATCH /pmt-context → Saves company context

5. Admin clicks "Generate Learning Objectives"
   └─> Confirmation dialog: "Are assessments complete?"
   └─> POST /generate → Backend runs algorithm

6. Results displayed in rich dashboard
   └─> Strategy tabs
   └─> Competency cards with priorities
   └─> Validation results
   └─> Scenario distributions

7. Admin exports results
   └─> GET /export?format=pdf/excel/json
```

### 3.3 State Management

Using **Vue 3 Composition API** with composables (consistent with existing codebase):

```javascript
// composables/usePhase2Task3.js [NEW]
export const usePhase2Task3 = (organizationId) => {
  const assessmentStats = ref(null)
  const selectedStrategies = ref([])
  const pmtContext = ref(null)
  const validationResults = ref(null)
  const learningObjectives = ref(null)
  const isLoading = ref(false)

  // Methods...
  return {
    assessmentStats,
    selectedStrategies,
    pmtContext,
    validationResults,
    learningObjectives,
    isLoading,
    fetchAssessmentStats,
    fetchStrategies,
    fetchPMTContext,
    runValidation,
    generateObjectives,
    exportObjectives
  }
}
```

---

## 4. Component Specifications

### 4.1 Phase2Task3Dashboard.vue (Main Container)

**Purpose**: Admin entry point for Task 3, orchestrates the entire flow

**Props**:
- `organizationId` (Number, required)

**Features**:
- Tab-based layout: "Monitor" | "Generate" | "Results" (if generated)
- Step indicator showing progress
- Context-aware actions (e.g., show PMT form only if needed)

**Layout**:
```vue
<template>
  <div class="phase2-task3-dashboard">
    <el-page-header @back="goBack">
      <template #content>
        <span>Phase 2 Task 3: Learning Objectives Generation</span>
      </template>
    </el-page-header>

    <el-tabs v-model="activeTab">
      <!-- Tab 1: Assessment Monitoring -->
      <el-tab-pane label="Monitor Assessments" name="monitor">
        <AssessmentMonitor :organization-id="organizationId" />
      </el-tab-pane>

      <!-- Tab 2: Generation -->
      <el-tab-pane label="Generate Objectives" name="generate">
        <!-- Prerequisites check -->
        <!-- PMT form (if needed) -->
        <!-- Generation button -->
      </el-tab-pane>

      <!-- Tab 3: Results (shown only after generation) -->
      <el-tab-pane
        v-if="objectivesGenerated"
        label="View Results"
        name="results"
      >
        <LearningObjectivesView
          :objectives="learningObjectives"
          :organization-id="organizationId"
        />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>
```

**API Calls**:
- On mount: Fetch assessment stats, strategies, check if objectives exist
- Reactive: Auto-refresh stats every 30 seconds (while on monitor tab)

---

### 4.2 AssessmentMonitor.vue

**Purpose**: Real-time tracking of organization-wide assessment completion

**Features**:
- Progress bar: X of Y users completed
- User list with completion status
- Filter by role (for role-based pathway)
- Export user list to CSV
- Refresh button

**UI Design**:
```vue
<el-card class="assessment-monitor">
  <template #header>
    <div class="card-header">
      <span>Assessment Completion Status</span>
      <el-button @click="refresh" :icon="Refresh">Refresh</el-button>
    </div>
  </template>

  <!-- Overall Progress -->
  <div class="progress-section">
    <div class="stats-row">
      <el-statistic title="Total Users" :value="stats.totalUsers" />
      <el-statistic title="Completed" :value="stats.completed" />
      <el-statistic title="Completion Rate" :value="stats.rate" suffix="%" />
    </div>
    <el-progress
      :percentage="stats.rate"
      :color="progressColor"
      :status="progressStatus"
    />
  </div>

  <!-- User List -->
  <el-table :data="userList" stripe>
    <el-table-column prop="name" label="User" />
    <el-table-column prop="role" label="Role" v-if="isRoleBased" />
    <el-table-column label="Status">
      <template #default="scope">
        <el-tag :type="scope.row.completed ? 'success' : 'warning'">
          {{ scope.row.completed ? 'Completed' : 'Pending' }}
        </el-tag>
      </template>
    </el-table-column>
    <el-table-column prop="completedAt" label="Completed At" />
  </el-table>
</el-card>
```

**Data Source**:
```javascript
// From existing endpoint (used in pathway_determination.py)
GET /api/organization/<org_id>/completion-stats
```

---

### 4.3 PMTContextForm.vue

**Purpose**: Collect company Processes, Methods, Tools context

**Conditional Display**:
- Show ONLY if selected strategies include:
  - "Needs-based project-oriented training"
  - "Continuous support"

**Form Fields**:
```vue
<el-form :model="pmtForm" label-position="top">
  <el-form-item
    label="Processes"
    required
    help="SE processes used (e.g., ISO 26262, V-model, Agile)"
  >
    <el-input
      v-model="pmtForm.processes"
      type="textarea"
      :rows="3"
      placeholder="e.g., ISO 26262 for automotive safety, V-model for development"
    />
  </el-form-item>

  <el-form-item label="Methods">
    <el-input
      v-model="pmtForm.methods"
      type="textarea"
      :rows="3"
      placeholder="e.g., Agile with 2-week sprints, requirements traceability"
    />
  </el-form-item>

  <el-form-item label="Tools" required>
    <el-input
      v-model="pmtForm.tools"
      type="textarea"
      :rows="3"
      placeholder="e.g., DOORS for requirements, JIRA for project management"
    />
  </el-form-item>

  <el-form-item label="Industry Context">
    <el-input
      v-model="pmtForm.industry"
      placeholder="e.g., Automotive embedded systems, Medical devices"
    />
  </el-form-item>

  <el-form-item label="Additional Context">
    <el-input
      v-model="pmtForm.additionalContext"
      type="textarea"
      :rows="2"
      placeholder="Any other relevant company-specific information"
    />
  </el-form-item>

  <el-form-item>
    <el-button type="primary" @click="savePMT">Save PMT Context</el-button>
    <el-button @click="saveForLater">Save for Later</el-button>
  </el-form-item>
</el-form>
```

**API**:
```javascript
// Save
PATCH /api/phase2/learning-objectives/<org_id>/pmt-context

// Load existing
GET /api/phase2/learning-objectives/<org_id>/pmt-context
```

**Validation**:
- At least one of `processes` or `tools` must be filled
- Show warning if incomplete

---

### 4.4 GenerationConfirmDialog.vue

**Purpose**: Admin confirmation before generation

**Trigger**: User clicks "Generate Learning Objectives" button

**Dialog Content**:
```vue
<el-dialog
  v-model="visible"
  title="Confirm Generation"
  width="600px"
>
  <div class="confirmation-content">
    <el-alert
      type="warning"
      :closable="false"
      show-icon
    >
      <template #title>
        Important: Assessment Completion Check
      </template>
      <p>
        Have all necessary employees completed their competency assessments?
      </p>
    </el-alert>

    <div class="stats-summary">
      <p><strong>Current Completion:</strong> {{ completionRate }}%</p>
      <p><strong>Users Completed:</strong> {{ usersCompleted }} / {{ totalUsers }}</p>
      <p><strong>Selected Strategies:</strong> {{ strategyCount }}</p>
      <p v-if="needsPMT && !hasPMT" class="warning-text">
        ⚠️ PMT context required but not provided
      </p>
    </div>

    <p class="note">
      Once generated, learning objectives can be regenerated, but this may
      take a few moments to process.
    </p>
  </div>

  <template #footer>
    <el-button @click="visible = false">Cancel</el-button>
    <el-button
      type="primary"
      @click="confirmGeneration"
      :disabled="needsPMT && !hasPMT"
      :loading="isGenerating"
    >
      Yes, Generate Objectives
    </el-button>
  </template>
</el-dialog>
```

---

### 4.5 LearningObjectivesView.vue (Results Dashboard)

**Purpose**: Display generated learning objectives with rich visualizations

**Layout**:
```vue
<template>
  <div class="learning-objectives-view">
    <!-- Validation Summary (Top) -->
    <ValidationSummaryCard
      v-if="objectives.validationResults"
      :validation="objectives.validationResults"
      :organization-id="organizationId"
    />

    <!-- Pathway Info -->
    <el-alert
      :type="pathwayType"
      :title="pathwayTitle"
      :description="pathwayDescription"
      show-icon
      :closable="false"
    />

    <!-- Action Bar -->
    <div class="action-bar">
      <el-button-group>
        <el-button @click="showExportDialog">
          <el-icon><Download /></el-icon>
          Export Results
        </el-button>
        <el-button @click="regenerate" v-if="canRegenerate">
          <el-icon><Refresh /></el-icon>
          Regenerate
        </el-button>
      </el-button-group>
    </div>

    <!-- Strategy Tabs -->
    <el-tabs v-model="activeStrategy" type="border-card">
      <el-tab-pane
        v-for="strategy in strategies"
        :key="strategy.id"
        :label="strategy.name"
        :name="strategy.id"
      >
        <StrategyTabPanel
          :strategy="strategy"
          :objectives="getObjectivesForStrategy(strategy.id)"
        />
      </el-tab-pane>
    </el-tabs>

    <!-- Export Dialog -->
    <ExportDialog
      v-model="exportDialogVisible"
      :organization-id="organizationId"
    />
  </div>
</template>
```

**Props**:
- `objectives` (Object, required) - Full learning objectives structure
- `organizationId` (Number, required)

**Computed Properties**:
- `pathwayType` - 'info' for task-based, 'success' for role-based
- `strategies` - List of strategies from objectives
- `hasValidationIssues` - Boolean for validation warnings

---

### 4.6 ValidationSummaryCard.vue

**Purpose**: Display strategy validation results prominently

**Design** (from design doc lines 1793-1815):
```vue
<el-card class="validation-summary-card" :class="statusClass">
  <template #header>
    <div class="card-header">
      <span>Strategy Validation Results</span>
      <el-tag :type="statusTagType" size="large">
        {{ validation.status }}
      </el-tag>
    </div>
  </template>

  <div class="validation-content">
    <!-- Status Message -->
    <el-alert
      :type="alertType"
      :title="validation.message"
      :closable="false"
      show-icon
    />

    <!-- Metrics -->
    <div class="metrics-row">
      <el-statistic
        title="Gap Percentage"
        :value="validation.gapPercentage"
        suffix="%"
      />
      <el-statistic
        title="Competencies with Gaps"
        :value="`${gapsCount} / 16`"
      />
      <el-statistic
        title="Users Affected"
        :value="validation.usersAffected"
      />
    </div>

    <!-- Recommendations (if any) -->
    <div v-if="hasRecommendations" class="recommendations">
      <h4>Recommendations</h4>
      <el-alert
        v-for="(rec, index) in recommendations"
        :key="index"
        :type="rec.type"
        :title="rec.message"
        show-icon
      >
        <el-button
          v-if="rec.action"
          type="primary"
          size="small"
          @click="handleRecommendation(rec)"
        >
          {{ rec.actionLabel }}
        </el-button>
      </el-alert>
    </div>
  </div>
</el-card>
```

**Status Types**:
- `EXCELLENT` - Green, no gaps
- `GOOD` - Blue, minor gaps manageable
- `ACCEPTABLE` - Yellow, some gaps but supplementary modules can help
- `INADEQUATE` - Red, strategy revision recommended

---

### 4.7 StrategyTabPanel.vue

**Purpose**: Display objectives for one strategy

**Layout**:
```vue
<template>
  <div class="strategy-tab-panel">
    <!-- Summary Statistics Card -->
    <el-card class="summary-card">
      <el-descriptions :column="3" border>
        <el-descriptions-item label="Total Competencies">
          {{ summary.totalCompetencies }}
        </el-descriptions-item>
        <el-descriptions-item label="Requiring Training">
          {{ summary.competenciesRequiringTraining }}
        </el-descriptions-item>
        <el-descriptions-item label="Targets Achieved">
          {{ summary.competenciesTargetsAchieved }}
        </el-descriptions-item>
        <el-descriptions-item label="Average Gap">
          {{ summary.averageCompetencyGap }} levels
        </el-descriptions-item>
        <el-descriptions-item label="Estimated Duration">
          {{ summary.estimatedTrainingDurationReadable }}
        </el-descriptions-item>
        <el-descriptions-item label="PMT Customization">
          <el-tag :type="strategy.pmtCustomizationApplied ? 'success' : 'info'">
            {{ strategy.pmtCustomizationApplied ? 'Applied' : 'Not Required' }}
          </el-tag>
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- Core Competencies (Collapsible) -->
    <el-collapse v-model="activeCollapse">
      <el-collapse-item
        name="core"
        title="Core Competencies (Not Directly Trainable)"
      >
        <el-alert
          type="info"
          :closable="false"
          show-icon
        >
          These competencies develop indirectly through training in other competencies.
        </el-alert>
        <div class="core-competencies-list">
          <el-tag
            v-for="comp in objectives.coreCompetencies"
            :key="comp.competencyId"
            size="large"
          >
            {{ comp.competencyName }}
          </el-tag>
        </div>
      </el-collapse-item>
    </el-collapse>

    <!-- Trainable Competencies (Sorted by Priority) -->
    <div class="trainable-competencies">
      <h3>Learning Objectives (by Priority)</h3>
      <CompetencyCard
        v-for="comp in sortedCompetencies"
        :key="comp.competencyId"
        :competency="comp"
      />
    </div>
  </div>
</template>
```

---

### 4.8 CompetencyCard.vue

**Purpose**: Rich display of individual competency with objective, priority, and visualizations

**Design** (from design doc lines 1817-1862):
```vue
<el-card class="competency-card" :class="statusClass">
  <template #header>
    <div class="card-header">
      <div class="title-section">
        <h4>{{ competency.competencyName }}</h4>
        <el-tag :type="statusType" size="small">
          {{ competency.status }}
        </el-tag>
      </div>
      <div class="badges">
        <el-tag
          v-if="competency.trainingPriority"
          type="danger"
          effect="dark"
          size="large"
        >
          Priority: {{ competency.trainingPriority }}
        </el-tag>
      </div>
    </div>
  </template>

  <!-- Level Visualization -->
  <div class="level-comparison">
    <div class="level-bar">
      <span class="label">Current: {{ competency.currentLevel }}</span>
      <el-progress
        :percentage="levelPercentage(competency.currentLevel)"
        :color="currentColor"
      />
    </div>
    <div class="level-bar">
      <span class="label">Target: {{ competency.targetLevel }}</span>
      <el-progress
        :percentage="levelPercentage(competency.targetLevel)"
        :color="targetColor"
      />
    </div>
    <div v-if="competency.maxRoleRequirement" class="level-bar">
      <span class="label">Max Role Requirement: {{ competency.maxRoleRequirement }}</span>
      <el-progress
        :percentage="levelPercentage(competency.maxRoleRequirement)"
        :color="roleColor"
      />
    </div>
  </div>

  <!-- Learning Objective (Main Content) -->
  <div class="learning-objective">
    <el-alert
      type="success"
      :closable="false"
      show-icon
    >
      <template #title>Learning Objective</template>
      <p class="objective-text">{{ competency.learningObjective }}</p>
    </el-alert>
  </div>

  <!-- PMT Breakdown (if available) -->
  <div v-if="competency.pmtBreakdown" class="pmt-breakdown">
    <el-descriptions title="PMT Context" :column="1" border size="small">
      <el-descriptions-item label="Process">
        {{ competency.pmtBreakdown.process }}
      </el-descriptions-item>
      <el-descriptions-item label="Method">
        {{ competency.pmtBreakdown.method }}
      </el-descriptions-item>
      <el-descriptions-item label="Tool">
        {{ competency.pmtBreakdown.tool }}
      </el-descriptions-item>
    </el-descriptions>
  </div>

  <!-- Meta Information -->
  <div class="meta-info">
    <el-tag>Gap: {{ competency.gap }} levels</el-tag>
    <el-tag>Users Requiring Training: {{ competency.usersRequiringTraining }}</el-tag>
    <el-tag v-if="competency.comparison">
      Comparison: {{ competency.comparisonType }}
    </el-tag>
  </div>

  <!-- Scenario Distribution Chart (Role-Based Only) -->
  <ScenarioDistributionChart
    v-if="competency.scenarioDistribution"
    :distribution="competency.scenarioDistribution"
  />

  <!-- Note (if any) -->
  <el-alert
    v-if="competency.note"
    type="warning"
    :closable="false"
  >
    {{ competency.note }}
  </el-alert>
</el-card>
```

**Status Colors**:
- `training_required` - Blue (primary)
- `target_achieved` - Green (success)
- `supplementary_recommended` - Yellow (warning)

---

### 4.9 ScenarioDistributionChart.vue

**Purpose**: Visualize user distribution across 4 scenarios (A, B, C, D)

**Chart Type**: Horizontal bar chart or pie chart

**Data Structure**:
```javascript
{
  A: 75.0,  // Percentage
  B: 7.5,
  C: 5.0,
  D: 12.5
}
```

**Implementation** (using ECharts or Chart.js):
```vue
<template>
  <div class="scenario-chart">
    <h5>User Distribution by Scenario</h5>
    <div ref="chartContainer" style="height: 200px;"></div>
    <div class="scenario-legend">
      <el-tag type="success">Scenario A: Normal training ({{ distribution.A }}%)</el-tag>
      <el-tag type="warning">Scenario B: Strategy insufficient ({{ distribution.B }}%)</el-tag>
      <el-tag type="info">Scenario C: Over-training ({{ distribution.C }}%)</el-tag>
      <el-tag>Scenario D: Target achieved ({{ distribution.D }}%)</el-tag>
    </div>
  </div>
</template>

<script setup>
import * as echarts from 'echarts'
import { onMounted, ref } from 'vue'

// Chart initialization...
</script>
```

---

### 4.10 ExportDialog.vue

**Purpose**: Allow admin to export results in multiple formats

**UI**:
```vue
<el-dialog v-model="visible" title="Export Learning Objectives" width="500px">
  <el-form :model="exportForm">
    <el-form-item label="Format">
      <el-radio-group v-model="exportForm.format">
        <el-radio label="pdf">
          <el-icon><Document /></el-icon>
          PDF Report
        </el-radio>
        <el-radio label="excel">
          <el-icon><Document /></el-icon>
          Excel Workbook
        </el-radio>
        <el-radio label="json">
          <el-icon><Document /></el-icon>
          JSON Data
        </el-radio>
      </el-radio-group>
    </el-form-item>

    <el-form-item label="Strategy Filter (Optional)">
      <el-select v-model="exportForm.strategy" clearable>
        <el-option
          v-for="strategy in strategies"
          :key="strategy.id"
          :label="strategy.name"
          :value="strategy.name"
        />
      </el-select>
    </el-form-item>

    <el-form-item>
      <el-checkbox v-model="exportForm.includeValidation">
        Include Validation Results
      </el-checkbox>
    </el-form-item>
  </el-form>

  <template #footer>
    <el-button @click="visible = false">Cancel</el-button>
    <el-button type="primary" @click="handleExport" :loading="isExporting">
      <el-icon><Download /></el-icon>
      Download {{ exportForm.format.toUpperCase() }}
    </el-button>
  </template>
</el-dialog>
```

**API Call**:
```javascript
// Triggers file download
GET /api/phase2/learning-objectives/<org_id>/export
  ?format=<pdf|excel|json>
  &strategy=<strategy_name>
  &include_validation=<true|false>
```

---

## 5. API Integration (phase2.js)

**Update**: `src/frontend/src/api/phase2.js`

```javascript
/**
 * Phase 2 Task 3: Formulate Learning Objectives APIs (Admin Only)
 */
export const phase2Task3Api = {
  /**
   * Check prerequisites for learning objectives generation
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Validation result
   */
  validatePrerequisites: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/prerequisites`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to validate prerequisites:', error);
      throw error;
    }
  },

  /**
   * Quick validation check (without full generation)
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Strategy validation results
   */
  runQuickValidation: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/validation`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to run validation:', error);
      throw error;
    }
  },

  /**
   * Get PMT context for organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} PMT context data
   */
  getPMTContext: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/pmt-context`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch PMT context:', error);
      throw error;
    }
  },

  /**
   * Save/update PMT context
   * @param {Number} orgId - Organization ID
   * @param {Object} pmtData - PMT context data
   * @returns {Promise} Updated PMT context
   */
  savePMTContext: async (orgId, pmtData) => {
    try {
      const response = await axiosInstance.patch(
        `/api/phase2/learning-objectives/${orgId}/pmt-context`,
        pmtData
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to save PMT context:', error);
      throw error;
    }
  },

  /**
   * Generate learning objectives
   * @param {Number} orgId - Organization ID
   * @param {Object} options - Generation options
   * @returns {Promise} Generated learning objectives
   */
  generateObjectives: async (orgId, options = {}) => {
    try {
      const response = await axiosInstance.post(
        '/api/phase2/learning-objectives/generate',
        {
          organization_id: orgId,
          ...options
        }
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to generate objectives:', error);
      throw error;
    }
  },

  /**
   * Get existing learning objectives
   * @param {Number} orgId - Organization ID
   * @param {Boolean} regenerate - Force regeneration
   * @returns {Promise} Learning objectives
   */
  getObjectives: async (orgId, regenerate = false) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}`,
        {
          params: { regenerate }
        }
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch objectives:', error);
      throw error;
    }
  },

  /**
   * Export learning objectives
   * @param {Number} orgId - Organization ID
   * @param {String} format - 'pdf' | 'excel' | 'json'
   * @param {Object} filters - Optional filters
   * @returns {Promise} File download
   */
  exportObjectives: async (orgId, format, filters = {}) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/export`,
        {
          params: {
            format,
            ...filters
          },
          responseType: 'blob' // For file download
        }
      );

      // Trigger download
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `learning_objectives_org_${orgId}.${format}`);
      document.body.appendChild(link);
      link.click();
      link.remove();

      return { success: true };
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to export objectives:', error);
      throw error;
    }
  }
};
```

---

## 6. Router Configuration

**Add Route**: `src/frontend/src/router/index.js`

```javascript
{
  path: 'phases/2/admin/learning-objectives',
  name: 'Phase2Task3Admin',
  component: () => import('@/views/phases/Phase2Task3Admin.vue'),
  meta: {
    title: 'Phase 2 Task 3: Learning Objectives Generation',
    requiresAdmin: true,
    phase: 2
  },
  beforeEnter: async (to, from, next) => {
    // Check if user is admin
    const authStore = useAuthStore()
    if (!authStore.isAdmin) {
      ElMessage.error('Admin access required')
      next('/app/dashboard')
      return
    }

    // Check if Phase 2 Task 2 is complete (assessments exist)
    const { checkPhaseCompletion, canAccessPhase } = usePhaseProgression()
    await checkPhaseCompletion()
    if (canAccessPhase(2)) {
      next()
    } else {
      ElMessage.warning('Please complete Phase 2 assessments first')
      next('/app/phases/2')
    }
  }
}
```

---

## 7. Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Set up basic structure and API integration

- [ ] Create component directory structure
- [ ] Implement `phase2Task3Api` in `phase2.js`
- [ ] Add router configuration
- [ ] Create `Phase2Task3Admin.vue` main view skeleton
- [ ] Create composable `usePhase2Task3.js` for state management
- [ ] Test API connectivity with backend

**Deliverables**:
- Empty component files
- Working API calls (test with console.log)
- Route accessible at `/app/phases/2/admin/learning-objectives`

---

### Phase 2: Monitoring & Prerequisites (Week 1-2)
**Goal**: Build assessment monitoring and prerequisite checking

- [ ] Implement `AssessmentMonitor.vue`
  - [ ] Fetch completion stats
  - [ ] Display progress bar and user list
  - [ ] Add refresh functionality
  - [ ] Add role filtering (for role-based)
- [ ] Implement prerequisite validation
  - [ ] Check assessment completion
  - [ ] Check strategies selected
  - [ ] Check PMT status
- [ ] Add to main dashboard

**Deliverables**:
- Working assessment monitoring
- Clear prerequisite status display
- Admin can see readiness for generation

---

### Phase 3: PMT Context (Week 2)
**Goal**: Enable PMT input for deep customization strategies

- [ ] Implement `PMTContextForm.vue`
  - [ ] Form fields (processes, methods, tools, industry)
  - [ ] Validation (at least one of processes/tools required)
  - [ ] Save/update functionality
  - [ ] Load existing PMT context
- [ ] Add conditional display logic
  - [ ] Show only if strategy requires PMT
  - [ ] Show warning if needed but missing
- [ ] Integrate into main dashboard

**Deliverables**:
- Working PMT form
- Saves to backend
- Loads existing data
- Validates input

---

### Phase 4: Generation Flow (Week 2-3)
**Goal**: Implement generation confirmation and execution

- [ ] Implement `GenerationConfirmDialog.vue`
  - [ ] Show completion stats
  - [ ] Check PMT availability
  - [ ] Admin confirmation required
- [ ] Add generation button to dashboard
- [ ] Handle generation API call
  - [ ] Loading state
  - [ ] Error handling
  - [ ] Success notification
- [ ] Store results in component state

**Deliverables**:
- Working generation flow
- Clear loading indicators
- Error messages if prerequisites missing
- Success confirmation

---

### Phase 5: Results Display - Basic (Week 3)
**Goal**: Display generated objectives in simple list format

- [ ] Implement `LearningObjectivesView.vue` skeleton
- [ ] Add strategy tabs
- [ ] Implement `StrategyTabPanel.vue` basic version
  - [ ] Summary statistics
  - [ ] List of competencies
- [ ] Display pathway information
- [ ] Add refresh/regenerate button

**Deliverables**:
- Basic results display
- Strategy tabs working
- Summary statistics visible
- Can see all competencies

---

### Phase 6: Results Display - Rich (Week 3-4)
**Goal**: Add rich visualizations and details

- [ ] Implement `CompetencyCard.vue`
  - [ ] Level visualization (progress bars)
  - [ ] Learning objective text
  - [ ] PMT breakdown (if available)
  - [ ] Priority badge
  - [ ] Meta information
  - [ ] Status tags
- [ ] Add sorting by priority
- [ ] Add collapsible core competencies section
- [ ] Polish UI/UX with colors and spacing

**Deliverables**:
- Rich competency cards
- Visual level comparisons
- PMT context displayed
- Professional UI design

---

### Phase 7: Validation Display (Week 4)
**Goal**: Show strategy validation results

- [ ] Implement `ValidationSummaryCard.vue`
  - [ ] Status badge (EXCELLENT/GOOD/ACCEPTABLE/INADEQUATE)
  - [ ] Gap percentage and metrics
  - [ ] Validation message
  - [ ] Recommendations (if any)
- [ ] Add to top of results view
- [ ] Handle different validation statuses with appropriate colors
- [ ] Add action buttons for recommendations (if applicable)

**Deliverables**:
- Validation summary card
- Clear status indication
- Recommendations displayed
- Color-coded severity

---

### Phase 8: Scenario Visualization (Week 4)
**Goal**: Add scenario distribution charts (role-based only)

- [ ] Implement `ScenarioDistributionChart.vue`
  - [ ] Choose chart library (ECharts or Chart.js)
  - [ ] Horizontal bar chart or pie chart
  - [ ] Legend with scenario explanations
  - [ ] Color coding (A: green, B: yellow, C: blue, D: gray)
- [ ] Add to `CompetencyCard.vue`
- [ ] Show only for role-based pathway

**Deliverables**:
- Working scenario charts
- Visual distribution of users
- Conditional display (role-based only)

---

### Phase 9: Export Functionality (Week 4-5)
**Goal**: Enable export in multiple formats

- [ ] Implement `ExportDialog.vue`
  - [ ] Format selection (PDF, Excel, JSON)
  - [ ] Optional strategy filter
  - [ ] Include validation toggle
- [ ] Implement export API call
  - [ ] Blob response handling
  - [ ] Automatic file download
  - [ ] File naming
- [ ] Add export button to results view

**Deliverables**:
- Working export dialog
- PDF/Excel/JSON downloads
- Correct file naming
- Error handling

---

### Phase 10: Polish & Testing (Week 5)
**Goal**: Refine UI/UX and fix bugs

- [ ] Add loading skeletons
- [ ] Improve error messages
- [ ] Add tooltips and help text
- [ ] Mobile responsiveness check
- [ ] Cross-browser testing
- [ ] Accessibility improvements (ARIA labels, keyboard navigation)
- [ ] Performance optimization (large datasets)
- [ ] Add empty states
- [ ] Add success/error animations

**Deliverables**:
- Polished UI
- Clear user feedback
- Responsive design
- Tested across browsers

---

### Phase 11: Integration Testing (Week 5-6)
**Goal**: End-to-end testing with real data

- [ ] Test task-based pathway
  - [ ] Low-maturity organization
  - [ ] 2-way comparison display
  - [ ] Simple output verification
- [ ] Test role-based pathway
  - [ ] High-maturity organization
  - [ ] 3-way comparison display
  - [ ] Validation results
  - [ ] Scenario distributions
- [ ] Test PMT context flow
  - [ ] With deep-customization strategy
  - [ ] Without deep-customization strategy
  - [ ] PMT missing warning
- [ ] Test edge cases
  - [ ] No assessments completed
  - [ ] No strategies selected
  - [ ] All targets already achieved
  - [ ] Large organizations (100+ users)
- [ ] Test exports
  - [ ] All formats (PDF, Excel, JSON)
  - [ ] With filters
  - [ ] Large datasets

**Deliverables**:
- Comprehensive test report
- Bug fixes
- Performance tuning
- Documentation

---

## 8. Design System & Styling

### 8.1 Color Palette (Consistent with Element Plus)

```css
/* Status Colors */
--color-success: #67C23A;    /* Green - Target achieved, EXCELLENT */
--color-warning: #E6A23C;    /* Yellow - Scenario B, ACCEPTABLE */
--color-danger: #F56C6C;     /* Red - INADEQUATE, high priority */
--color-info: #909399;       /* Gray - Scenario D, informational */
--color-primary: #409EFF;    /* Blue - Normal training (Scenario A) */

/* Scenario-Specific Colors */
--scenario-a: var(--color-primary);   /* Normal training */
--scenario-b: var(--color-warning);   /* Strategy insufficient */
--scenario-c: var(--color-info);      /* Over-training */
--scenario-d: var(--color-success);   /* Target achieved */

/* Priority Colors */
--priority-high: #F56C6C;     /* 7-10 */
--priority-medium: #E6A23C;   /* 4-6 */
--priority-low: #909399;      /* 0-3 */
```

### 8.2 Typography

```css
/* Headings */
h1 { font-size: 28px; font-weight: 600; }
h2 { font-size: 24px; font-weight: 600; }
h3 { font-size: 20px; font-weight: 500; }
h4 { font-size: 18px; font-weight: 500; }
h5 { font-size: 16px; font-weight: 500; }

/* Body */
body { font-size: 14px; line-height: 1.6; }

/* Learning Objectives (Special) */
.objective-text {
  font-size: 15px;
  line-height: 1.8;
  font-weight: 400;
}
```

### 8.3 Spacing

```css
/* Consistent spacing scale */
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;
--space-xl: 32px;

/* Card padding */
.el-card { padding: var(--space-lg); }

/* Competency card spacing */
.competency-card {
  margin-bottom: var(--space-lg);
}
```

### 8.4 Component-Specific Styles

**Validation Summary Card**:
```css
.validation-summary-card.excellent {
  border-left: 4px solid var(--color-success);
}
.validation-summary-card.good {
  border-left: 4px solid var(--color-primary);
}
.validation-summary-card.acceptable {
  border-left: 4px solid var(--color-warning);
}
.validation-summary-card.inadequate {
  border-left: 4px solid var(--color-danger);
}
```

**Competency Card**:
```css
.competency-card {
  transition: box-shadow 0.3s ease;
}
.competency-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.priority-badge {
  font-size: 18px;
  padding: 8px 16px;
}
```

**Level Progress Bars**:
```css
.level-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.level-bar .label {
  min-width: 150px;
  font-weight: 500;
}
```

---

## 9. Error Handling & Edge Cases

### 9.1 No Assessments Completed

**Scenario**: Organization has 0 completed assessments

**UI Response**:
- Show empty state with message
- Disable "Generate" button
- Display: "No assessments completed yet. Please complete at least one assessment before generating learning objectives."
- Provide link to Phase 2 assessment

### 9.2 No Strategies Selected

**Scenario**: Organization has not selected any strategies in Phase 1

**UI Response**:
- Show alert: "No learning strategies selected"
- Disable "Generate" button
- Provide link to Phase 1 strategy selection

### 9.3 PMT Required But Missing

**Scenario**: Strategy requires PMT but not provided

**UI Response**:
- Show warning banner
- Disable "Generate" button until PMT is saved
- Open PMT form automatically
- Message: "PMT context required for selected strategies. Please provide company information."

### 9.4 Generation API Error

**Scenario**: Backend returns error during generation

**UI Response**:
- Display error message in dialog
- Allow retry
- Log error details to console
- Show user-friendly message:
  - "Service temporarily unavailable. Please try again."
  - "Invalid data. Please check prerequisites."

### 9.5 Large Organizations (Performance)

**Scenario**: 100+ users with assessments

**UI Response**:
- Add loading skeleton
- Show progress indicator during generation
- Paginate user list in assessment monitor
- Virtual scrolling for competency cards (if > 50 cards)

### 9.6 All Targets Already Achieved

**Scenario**: Organization already meets all competency targets

**UI Response**:
- Display success message
- Show list of achieved competencies
- Message: "Congratulations! All competency targets are already achieved. No training objectives needed."
- Suggest Phase 3 (module selection for continuous learning)

---

## 10. Accessibility (WCAG 2.1 AA)

### 10.1 Keyboard Navigation

- All interactive elements (buttons, tabs, inputs) must be keyboard accessible
- Logical tab order
- Focus indicators visible
- Esc key closes dialogs

### 10.2 Screen Reader Support

- Add ARIA labels to complex components
- Announce dynamic content changes (generation complete, etc.)
- Proper heading hierarchy (h1 → h2 → h3)
- Alt text for charts (or text alternative)

### 10.3 Color Contrast

- Ensure 4.5:1 contrast ratio for text
- 3:1 for UI components
- Don't rely solely on color (use icons + text)

### 10.4 Focus Management

- When dialog opens, focus first input
- When dialog closes, return focus to trigger element
- Trap focus within modals

---

## 11. Testing Strategy

### 11.1 Unit Tests (Vitest)

**Test Files** (create for each component):
- `AssessmentMonitor.spec.js`
- `PMTContextForm.spec.js`
- `CompetencyCard.spec.js`
- `ValidationSummaryCard.spec.js`
- etc.

**What to Test**:
- Component rendering
- Props validation
- Event emission
- Computed properties
- API mocking

### 11.2 Integration Tests

**Scenarios**:
1. Complete flow: Monitor → PMT → Generate → View Results
2. Task-based pathway end-to-end
3. Role-based pathway end-to-end
4. Export functionality
5. Error handling

### 11.3 Manual Testing Checklist

**Pre-Generation**:
- [ ] Assessment monitor shows correct completion stats
- [ ] PMT form saves and loads correctly
- [ ] Validation runs and displays results
- [ ] Generation disabled when prerequisites missing

**Generation**:
- [ ] Confirmation dialog appears
- [ ] Loading state visible
- [ ] Success message shown
- [ ] Results automatically displayed

**Results Display**:
- [ ] Strategy tabs work correctly
- [ ] Competency cards display all information
- [ ] Scenario charts render (role-based)
- [ ] Validation summary shows correct status
- [ ] Export works for all formats

**Edge Cases**:
- [ ] No assessments: Error message displayed
- [ ] No strategies: Error message displayed
- [ ] PMT missing: Warning displayed and form shown
- [ ] All targets achieved: Success message shown
- [ ] Large organization (100+ users): Performance acceptable

---

## 12. Documentation

### 12.1 User Documentation

**Create**: `docs/user-guide/phase2-task3-admin-guide.md`

**Contents**:
- Overview of Phase 2 Task 3
- Step-by-step instructions
- Screenshots of each screen
- Explanation of validation statuses
- Interpretation of scenario distributions
- Export options guide
- Troubleshooting common issues

### 12.2 Developer Documentation

**Create**: `docs/developer/phase2-task3-technical-guide.md`

**Contents**:
- Component architecture diagram
- Data flow explanation
- API integration guide
- State management patterns
- Extending/customizing components
- Testing guidelines

### 12.3 Code Comments

- JSDoc comments for all exported functions
- Prop documentation with type and description
- Inline comments for complex logic

---

## 13. Performance Considerations

### 13.1 Lazy Loading

```javascript
// Lazy load components not needed immediately
const ScenarioDistributionChart = defineAsyncComponent(() =>
  import('./ScenarioDistributionChart.vue')
)
```

### 13.2 Virtualization

For organizations with many competencies (>50):
```javascript
// Use virtual scrolling
import { VirtualList } from 'vue-virtual-scroller'
```

### 13.3 Debouncing

For search/filter inputs:
```javascript
import { debounce } from 'lodash-es'

const searchCompetencies = debounce((query) => {
  // Filter logic
}, 300)
```

### 13.4 Caching

- Cache generated objectives in component state
- Don't refetch unless explicitly requested
- Use localStorage for PMT form drafts

---

## 14. Success Criteria

The implementation will be considered successful when:

### 14.1 Functional Requirements

- [ ] Admin can monitor assessment completion in real-time
- [ ] Admin can input PMT context for relevant strategies
- [ ] Admin can generate learning objectives with confirmation
- [ ] Generated objectives display correctly for both pathways
- [ ] Validation results show appropriate status and recommendations
- [ ] Competency cards display all information with correct formatting
- [ ] Scenario distributions visualize correctly (role-based)
- [ ] Export works for all 3 formats (PDF, Excel, JSON)
- [ ] All API endpoints integrate correctly
- [ ] Error handling works for all edge cases

### 14.2 Quality Requirements

- [ ] UI is responsive (desktop, tablet, mobile)
- [ ] Loading states are clear and informative
- [ ] Error messages are user-friendly
- [ ] No console errors or warnings
- [ ] WCAG 2.1 AA compliance
- [ ] Cross-browser compatibility (Chrome, Firefox, Edge, Safari)
- [ ] Performance is acceptable for large datasets (100+ users)

### 14.3 User Experience Requirements

- [ ] Workflow is intuitive and self-explanatory
- [ ] Visual design is consistent with existing app
- [ ] Feedback is immediate and clear
- [ ] Help text is available where needed
- [ ] Success states are celebratory
- [ ] Error states provide actionable guidance

---

## 15. Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1: Foundation | 1 week | API integration, routing, skeleton |
| Phase 2: Monitoring | 1 week | Assessment monitor working |
| Phase 3: PMT Context | 1 week | PMT form complete |
| Phase 4: Generation | 1 week | Generation flow working |
| Phase 5: Results Basic | 1 week | Simple results display |
| Phase 6: Results Rich | 1 week | Rich competency cards |
| Phase 7: Validation | 1 week | Validation card complete |
| Phase 8: Scenarios | 1 week | Scenario charts working |
| Phase 9: Export | 1 week | Export functionality |
| Phase 10: Polish | 1 week | UI/UX refinement |
| Phase 11: Testing | 1 week | Full integration testing |

**Total Estimated Duration**: 11 weeks (~3 months)

**Can be accelerated** with parallel development of independent components:
- Monitoring + PMT (parallel)
- Results Basic + Validation (parallel)
- Rich Cards + Scenarios (parallel)

**Realistic aggressive timeline**: 6-7 weeks with focused development

---

## 16. Dependencies

### 16.1 External Libraries

**Required**:
- `element-plus` - Already installed (UI framework)
- `@element-plus/icons-vue` - Already installed (icons)
- `vue-router` - Already installed (routing)
- `axios` - Already installed (API calls)

**To Install**:
- `echarts` or `chart.js` - For scenario distribution charts
  ```bash
  npm install echarts
  # OR
  npm install chart.js vue-chartjs
  ```

**Optional** (for enhanced features):
- `vue-virtual-scroller` - For large datasets
- `lodash-es` - For utility functions
- `date-fns` - For date formatting

### 16.2 Backend Dependencies

**Status**: ✅ All backend dependencies complete

**Verified Endpoints**:
- POST `/api/phase2/learning-objectives/generate`
- GET `/api/phase2/learning-objectives/<org_id>`
- GET/PATCH `/api/phase2/learning-objectives/<org_id>/pmt-context`
- GET `/api/phase2/learning-objectives/<org_id>/validation`

---

## 17. Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Backend API changes | High | Low | Use versioned API endpoints, clear contracts |
| Large dataset performance | Medium | Medium | Implement virtual scrolling, pagination |
| Complex validation logic | Medium | Low | Use composables to separate concerns |
| Export generation failure | Medium | Low | Implement retry logic, fallback to JSON |
| PMT form abandonment | Low | Medium | Auto-save drafts to localStorage |
| Chart library issues | Low | Low | Have fallback text representation |

---

## 18. Next Steps

### Immediate Actions (This Week)

1. **Review and Approve Plan** ✅ (You are here)
2. **Set up Development Environment**
   - Create feature branch: `feature/phase2-task3-frontend`
   - Install required dependencies (echarts)
3. **Start Phase 1 Implementation**
   - Create component directory structure
   - Implement API integration in `phase2.js`
   - Add router configuration
   - Create main view skeleton

### Questions to Resolve

1. **Chart Library Preference**: ECharts vs Chart.js?
   - Recommendation: **ECharts** (more features, better for complex charts)

2. **Export Implementation**: Backend or Frontend?
   - Recommendation: **Backend** (already implemented in routes.py)

3. **State Management**: Pinia store or composable?
   - Recommendation: **Composable** (consistent with current codebase)

4. **Mobile Priority**: Full mobile support or desktop-first?
   - Recommendation: **Desktop-first** (admin tool), tablet-friendly, basic mobile support

---

## 19. Conclusion

This comprehensive plan provides a complete roadmap for implementing the Phase 2 Task 3 frontend UI. The backend is production-ready and tested. The frontend will be built using existing patterns and technologies in the codebase (Vue 3, Element Plus, Composition API).

**Key Strengths of This Plan**:
- ✅ Phased approach allows incremental delivery
- ✅ Comprehensive component specifications
- ✅ Clear API integration strategy
- ✅ Rich visualizations for admin insights
- ✅ Robust error handling
- ✅ Performance considerations
- ✅ Testing strategy included
- ✅ Accessibility compliance
- ✅ Documentation requirements

**Estimated Effort**: 6-11 weeks depending on parallelization and focus level

**Ready to Start**: Yes - all prerequisites are met

---

**Document Version**: 1.0
**Last Updated**: November 5, 2025
**Author**: Claude (AI Assistant)
**Reviewed By**: [Pending]
