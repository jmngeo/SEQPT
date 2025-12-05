# Phase 2 Task 3 UI Redesign Plan
**Date**: 2025-11-08
**Status**: Implementation Ready

## Current Issues

### 1. PMT Form Not Showing
- **Location**: `usePhase2Task3.js` line 123
- **Problem**: `needsPMT` hardcoded to `false`
- **Impact**: PMT form never shows even when required strategies are selected
- **Fix**: Check selected strategies against deep-customization list

### 2. Redundant Tab Structure
- **Current**: Two tabs with overlapping content
  - Tab 1: "Monitor Assessments" - shows stats, user list
  - Tab 2: "Generate Objectives" - shows same stats in prerequisites card
- **Problem**: User sees duplicate information, confusing navigation
- **Design Reference**: v4.1 spec says single consolidated page

### 3. Missing "Completed At" Column
- **Location**: `AssessmentMonitor.vue` line 63-83
- **Problem**: Table has `formatDate()` function but doesn't use it
- **Impact**: No visibility into when users completed assessments

## New UI Structure (Single Consolidated Page)

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 2 Task 3: Learning Objectives Generation             │
│ [Back Button]                          [ROLE_BASED Pathway] │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SECTION 1: Assessment Monitoring                            │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ Overall Progress:                                            │
│ Total Users: 40  │  Completed: 35  │  Completion Rate: 87.5% │
│ [████████████████████░░░░░] 87.5%                           │
│                                                              │
│ Pathway: ROLE_BASED (High Maturity)                         │
│ Advanced 3-way comparison with validation                   │
│                                                              │
│ User Assessment Details:                                     │
│ ┌────────────────┬──────────┬────────────────────────────┐ │
│ │ User           │ Status   │ Completed At               │ │
│ ├────────────────┼──────────┼────────────────────────────┤ │
│ │ user_1         │ ✓ Done   │ Nov 7, 2025, 10:30 AM      │ │
│ │ user_2         │ ✓ Done   │ Nov 7, 2025, 11:15 AM      │ │
│ │ user_3         │ ⏳ Pending│ —                          │ │
│ └────────────────┴──────────┴────────────────────────────┘ │
│                                                              │
│ [Refresh]                                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SECTION 2: PMT Context (Conditional - Only if Needed)       │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ ⚠ Required for Selected Strategies                          │
│                                                              │
│ Your selected strategies require company context:           │
│ • Needs-based project-oriented training                     │
│                                                              │
│ [PMT Context Form - Expandable Card]                        │
│   Processes: [                              ]               │
│   Methods:   [                              ]               │
│   Tools:     [                              ] (required)    │
│   Industry:  [                              ]               │
│   Additional:[                              ]               │
│                                                              │
│   [Save PMT Context] [Save for Later]                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SECTION 3: Quick Validation (Optional - Role-Based Only)    │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ Run a quick check to validate your strategy selection       │
│ before generating full objectives.                           │
│                                                              │
│ [Check Strategy Adequacy]                                    │
│                                                              │
│ [Validation Summary Card - If Run]                           │
│   Status: ✓ GOOD                                            │
│   Gap Percentage: 12.5%                                     │
│   Recommendations: Minor gaps manageable with modules       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SECTION 4: Generate Learning Objectives                     │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ Prerequisites:                                               │
│ [✓] Assessments    [✓] Strategies    [✓] PMT Context       │
│                                                              │
│ ✓ All prerequisites met. Ready to generate!                 │
│                                                              │
│ [🪄 Generate Learning Objectives]                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SECTION 5: Results (Only After Generation)                  │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ [Results tabs and display - LearningObjectivesView]         │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Changes

### File 1: `usePhase2Task3.js`
**Changes**:
1. Fix `fetchPrerequisites()` to properly detect PMT requirement
2. Add logic to check if selected strategies include deep-customization ones

```javascript
// Line 88-152: Update fetchPrerequisites()
const fetchPrerequisites = async () => {
  try {
    const response = await phase2Task3Api.validatePrerequisites(organizationId)

    // ... existing code ...

    // CRITICAL FIX: Determine if PMT is needed based on selected strategies
    const deepCustomizationStrategies = [
      'Needs-based project-oriented training',
      'Continuous support'
    ]

    const selectedStrategies = response.selected_strategies || []
    const needsPMT = selectedStrategies.some(strategy =>
      deepCustomizationStrategies.includes(strategy.name || strategy)
    )

    // Check if PMT exists
    const hasPMT = response.has_pmt_context || false

    // Build prerequisites object
    prerequisites.value = {
      hasAssessments: hasAssessments,
      hasStrategies: (response.selected_strategies_count || 0) > 0,
      needsPMT: needsPMT,  // FIXED: Now properly determined
      hasPMT: hasPMT,      // FIXED: Now from API response
      readyToGenerate: response.ready_to_generate || false,
      message: response.note || response.error || buildPrerequisitesMessage(response)
    }

    // ... rest of code ...
  }
}
```

### File 2: `Phase2Task3Dashboard.vue`
**Changes**:
1. Remove tab structure
2. Consolidate into single scrollable page
3. Show sections conditionally based on state

```vue
<template>
  <div class="phase2-task3-dashboard">
    <!-- Page Header -->
    <el-page-header @back="handleBack">
      <!-- ... existing header ... -->
    </el-page-header>

    <!-- Loading State -->
    <el-card v-if="isLoading" class="loading-card">
      <!-- ... existing loading ... -->
    </el-card>

    <!-- Consolidated Single Page View -->
    <div v-else class="consolidated-view">

      <!-- SECTION 1: Assessment Monitoring (Always Visible) -->
      <AssessmentMonitor
        :organization-id="organizationId"
        :pathway="pathway"
        :assessment-stats="assessmentStats"
        @refresh="refreshData"
        class="section"
      />

      <!-- SECTION 2: PMT Context Form (Conditional) -->
      <PMTContextForm
        v-if="needsPMT && !hasPMT"
        :organization-id="organizationId"
        :existing-context="pmtContext"
        @saved="handlePMTSaved"
        class="section"
      />

      <!-- PMT Exists - Show Summary -->
      <el-card v-else-if="needsPMT && hasPMT" class="section pmt-summary-card">
        <template #header>
          <div class="card-header">
            <span>PMT Context</span>
            <el-tag type="success">Configured</el-tag>
          </div>
        </template>
        <p>PMT context has been configured for deep customization.</p>
        <el-button @click="showPMTEdit = true" size="small">
          Edit PMT Context
        </el-button>
      </el-card>

      <!-- SECTION 3: Quick Validation (Optional - Role-Based Only) -->
      <el-card v-if="pathway === 'ROLE_BASED'" class="section">
        <template #header>
          <span>Quick Validation Check (Optional)</span>
        </template>
        <p>Run a quick check to validate your strategy selection before generating full objectives.</p>
        <el-button @click="runQuickValidation" :loading="isValidating">
          <el-icon><Check /></el-icon>
          Check Strategy Adequacy
        </el-button>

        <ValidationSummaryCard
          v-if="validationResults"
          :validation="validationResults"
          :organization-id="organizationId"
          style="margin-top: 16px;"
          @recommendation-action="handleRecommendationAction"
        />
      </el-card>

      <!-- SECTION 4: Prerequisites & Generation -->
      <el-card class="section">
        <template #header>
          <span>Generate Learning Objectives</span>
        </template>

        <!-- Prerequisites Check -->
        <div class="prerequisites-check">
          <el-steps :active="prerequisitesStep" finish-status="success" simple>
            <el-step
              title="Assessments"
              :icon="prerequisites.hasAssessments ? SuccessFilled : CircleClose"
            />
            <el-step
              title="Strategies"
              :icon="prerequisites.hasStrategies ? SuccessFilled : CircleClose"
            />
            <el-step
              v-if="prerequisites.needsPMT"
              title="PMT Context"
              :icon="prerequisites.hasPMT ? SuccessFilled : CircleClose"
            />
          </el-steps>

          <el-alert
            :type="prerequisites.readyToGenerate ? 'success' : 'warning'"
            :closable="false"
            show-icon
            style="margin-top: 16px;"
          >
            <template #title>
              {{ prerequisites.readyToGenerate ? 'Ready to Generate' : 'Prerequisites Not Met' }}
            </template>
            <p>{{ prerequisites.message }}</p>
          </el-alert>
        </div>

        <!-- Generation Button -->
        <div class="generation-section">
          <p>Generate personalized learning objectives for your organization based on competency assessments and selected strategies.</p>
          <el-button
            type="primary"
            size="large"
            @click="showGenerationDialog"
            :disabled="!prerequisites?.readyToGenerate"
            :loading="isGenerating"
          >
            <el-icon><MagicStick /></el-icon>
            Generate Learning Objectives
          </el-button>
        </div>
      </el-card>

      <!-- SECTION 5: Results (Only if Generated) -->
      <LearningObjectivesView
        v-if="learningObjectives"
        :objectives="learningObjectives"
        :organization-id="organizationId"
        @regenerate="handleRegenerate"
        @export="handleExport"
        class="section"
      />
    </div>

    <!-- Dialogs ... -->
  </div>
</template>

<script setup>
// ... existing imports and setup ...

// Remove activeTab ref - no longer needed
// const activeTab = ref('monitor')  // DELETE THIS

// Add ref for PMT editing
const showPMTEdit = ref(false)

// ... rest of existing code ...
</script>

<style scoped>
.phase2-task3-dashboard {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.consolidated-view {
  display: flex;
  flex-direction: column;
  gap: 24px;
  margin-top: 24px;
}

.section {
  /* All sections are direct children with consistent spacing */
}

.pmt-summary-card {
  border-left: 4px solid var(--el-color-success);
}

.prerequisites-check {
  margin-bottom: 24px;
}

.generation-section {
  text-align: center;
  padding: 24px;
}

.generation-section p {
  margin-bottom: 16px;
  color: var(--el-text-color-secondary);
}
</style>
```

### File 3: `AssessmentMonitor.vue`
**Changes**:
1. Add "Completed At" column to table
2. Use the existing `formatDate()` function
3. Update API to include completion timestamps

```vue
<!-- Line 54-84: Update table structure -->
<el-table
  :data="userList"
  stripe
  style="margin-top: 12px;"
  :default-sort="{ prop: 'completed_at', order: 'descending' }"
  v-loading="isLoadingUsers"
>
  <el-table-column
    prop="username"
    label="User"
    sortable
    min-width="200"
  />
  <el-table-column
    label="Status"
    width="120"
    align="center"
  >
    <template #default="scope">
      <el-tag
        :type="scope.row.status === 'completed' ? 'success' : 'warning'"
        effect="light"
      >
        {{ scope.row.status === 'completed' ? 'Completed' : 'Pending' }}
      </el-tag>
    </template>
  </el-table-column>
  <el-table-column
    prop="completed_at"
    label="Completed At"
    sortable
    width="200"
    align="center"
  >
    <template #default="scope">
      {{ formatDate(scope.row.completed_at) }}
    </template>
  </el-table-column>
</el-table>
```

## Backend API Changes Required

### Endpoint: `GET /phase2/prerequisites/<org_id>`
**Add to response**:
```json
{
  "selected_strategies": [
    {"id": 1, "name": "Needs-based project-oriented training"},
    {"id": 2, "name": "Common basic understanding"}
  ],
  "has_pmt_context": true  // NEW FIELD
}
```

### Endpoint: `GET /phase2/task3/assessment-users/<org_id>`
**Add to each user object**:
```json
{
  "username": "user_1",
  "status": "completed",
  "completed_at": "2025-11-07T10:30:00Z"  // NEW FIELD
}
```

## Testing Checklist

- [ ] PMT form appears when "Needs-based project-oriented training" selected
- [ ] PMT form appears when "Continuous support" selected
- [ ] PMT form does NOT appear for other strategies
- [ ] PMT summary shows when PMT exists
- [ ] "Completed At" column shows in user table
- [ ] Dates are formatted correctly
- [ ] Prerequisites update when PMT is saved
- [ ] All sections flow in single page (no tabs)
- [ ] Quick validation works (role-based only)
- [ ] Generation button enabled when all prerequisites met
- [ ] Results section appears after generation

## Benefits of New Design

1. **Single Flow**: User scrolls down one page instead of switching tabs
2. **Clear Prerequisites**: Visual steps show exactly what's needed
3. **Conditional Sections**: Only show PMT when needed
4. **Better UX**: No duplicate information, clearer progression
5. **Matches Design Doc**: Aligns with v4.1 specification
6. **Completion Tracking**: "Completed At" provides audit trail

## Migration Notes

- Existing `activeTab` refs can be removed
- Tab switching logic no longer needed
- All functionality preserved, just reorganized
- No breaking changes to composable API (except fixes)
