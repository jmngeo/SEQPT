# Algorithm Explanation Card - Issues and Next Steps
**Date:** November 9, 2025
**Status:** Component Created but Data Mapping Issues

---

## What Was Implemented

### Components Created

1. **AlgorithmExplanationCard.vue** - Main expandable component
   - Location: `src/frontend/src/components/phase2/task3/AlgorithmExplanationCard.vue`
   - Shows processing overview, algorithm steps, validation results
   - Supports both Task-Based and Role-Based pathways
   - Supports Dual-Track processing display

2. **AlgorithmStep.vue** - Individual step display component
   - Location: `src/frontend/src/components/phase2/task3/AlgorithmStep.vue`
   - Expandable details for each algorithm step
   - Data visualization (scenario counts, best-fit distribution)
   - Color-coded steps with icons

3. **ValidationResultsDetail.vue** - Validation display component
   - Location: `src/frontend/src/components/phase2/task3/ValidationResultsDetail.vue`
   - Status indicators, metrics, competency breakdown
   - Recommendations display

4. **Integration** - Added to LearningObjectivesView.vue
   - Location: `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue`
   - Line 59-64: Component integration
   - Line 224: Import statement

---

## Issues Found

### 1. Incorrect Data Extraction

**Observed Output:**
```
Processing Overview
- Total Users: 0 (WRONG - should show actual user count)
- Aggregation Method: Median (CORRECT)
- Gap-Based Strategies: 6 (showing strategy IDs instead of count)
- Expert Strategies: 1 (CORRECT)

Processing Metrics
- Competencies Analyzed: 0 (WRONG - should show 16)
- Objectives Generated: 112 (CORRECT)
- PMT Customization: 0 (WRONG - should show actual count)
```

**Root Cause:**
The component is receiving `props.objectives` but trying to extract data from `props.data`. The data structure mapping is incorrect.

### 2. Pathway Detection Issue

**Observed:**
- Component shows "Task-Based Pathway" in tag
- But also shows "Strategy Classification (Dual-Track Processing)"
- This is contradictory - dual-track is only for Role-Based

**Expected:**
- Should detect pathway from `normalizedData.pathway`
- Should be "ROLE_BASED" or "ROLE_BASED_DUAL_TRACK"

### 3. Strategy Display Issue

**Gap-Based Strategies showing:**
```
12, 13, 14, 16, 17, 18
```
These are strategy IDs, not strategy names.

**Expected:**
```
Common basic understanding
SE for managers
Orientation in pilot project
... (actual strategy names)
```

---

## Data Structure Analysis

### Current Component Props
```vue
<AlgorithmExplanationCard
  v-if="normalizedData"
  :pathway="normalizedData.pathway"
  :data="props.objectives"  // <-- This is the full API response
/>
```

### API Response Structure
```javascript
{
  pathway: "ROLE_BASED",  // or "TASK_BASED"
  total_users_assessed: 45,
  aggregation_method: "median_per_role_with_user_distribution",

  // Dual-track structure
  gap_based_training: {
    strategy_count: 6,
    learning_objectives_by_strategy: {
      "12": { strategy_name: "Common basic understanding", ... },
      "13": { strategy_name: "SE for managers", ... },
      ...
    },
    competency_scenario_distributions: { ... },
    cross_strategy_coverage: { ... },
    strategy_validation: { ... },
    strategic_decisions: { ... }
  },

  expert_development: {
    strategy_count: 1,
    learning_objectives_by_strategy: {
      "19": { strategy_name: "Train the trainer", ... }
    }
  },

  // OR single-track structure
  learning_objectives_by_strategy: { ... },
  strategy_validation: { ... },
  ...
}
```

### Component's Current Data Extraction (WRONG)
```javascript
const totalUsers = computed(() => props.data.total_users_assessed || 0)
// props.data is undefined, so this returns 0
```

### Correct Data Extraction (FIX NEEDED)
```javascript
const totalUsers = computed(() => {
  // Direct access to the objectives prop
  return props.data.total_users_assessed || 0
})
```

---

## Fixes Needed

### Fix 1: Correct Data Access Pattern

**File:** `AlgorithmExplanationCard.vue`

**Current (Wrong):**
```javascript
const totalUsers = computed(() => props.data.total_users_assessed || 0)
```

**Fix:**
```javascript
// props.data IS the objectives object, access directly
const totalUsers = computed(() => props.data.total_users_assessed || 0)
```

The prop is named `data` but contains the full objectives response. Need to verify the prop structure matches.

### Fix 2: Strategy Names Extraction

**Current (Wrong):**
```javascript
const gapBasedStrategies = computed(() => {
  if (props.data.gap_based_training) {
    return Object.keys(props.data.gap_based_training.learning_objectives_by_strategy || {})
  }
  return Object.keys(props.data.learning_objectives_by_strategy || {})
})
// Returns: ["12", "13", "14", ...] (IDs)
```

**Fix:**
```javascript
const gapBasedStrategies = computed(() => {
  let strategiesObj = {}

  if (props.data.gap_based_training) {
    strategiesObj = props.data.gap_based_training.learning_objectives_by_strategy || {}
  } else {
    strategiesObj = props.data.learning_objectives_by_strategy || {}
  }

  // Extract strategy names from the objects
  return Object.values(strategiesObj).map(s => s.strategy_name)
})
// Returns: ["Common basic understanding", "SE for managers", ...]
```

### Fix 3: Pathway Detection

**Current:**
```javascript
// Uses normalizedData.pathway from parent
:pathway="normalizedData.pathway"
```

**Issue:**
The pathway value might be getting set incorrectly. Need to check:
1. What value is being passed?
2. Is dual-track setting pathway to TASK_BASED incorrectly?

**Debug:**
```javascript
console.log('Pathway received:', props.pathway)
console.log('Has dual-track:', isDualTrack.value)
console.log('Full data:', props.data)
```

### Fix 4: Competencies Analyzed

**Current (Wrong):**
```javascript
const competenciesAnalyzed = computed(() => {
  if (props.pathway === 'TASK_BASED') {
    return 16 // All 16 competencies
  }

  const distributions = props.data.competency_scenario_distributions ||
                       props.data.gap_based_training?.competency_scenario_distributions || {}
  return Object.keys(distributions).length
})
// Returns 0 because distributions is undefined
```

**Fix:**
Need to ensure correct path to competency_scenario_distributions based on data structure.

---

## Testing Plan

### Step 1: Add Debug Logging
```javascript
// In AlgorithmExplanationCard.vue, in setup()
console.log('=== AlgorithmExplanationCard Debug ===')
console.log('Props received:', JSON.stringify(props, null, 2))
console.log('Pathway:', props.pathway)
console.log('Data keys:', Object.keys(props.data))
console.log('isDualTrack:', isDualTrack.value)
console.log('totalUsers:', totalUsers.value)
console.log('gapBasedStrategies:', gapBasedStrategies.value)
```

### Step 2: Test with Real Data
1. Navigate to Phase 2 Task 3 results page
2. Generate learning objectives for an organization
3. Expand the Algorithm Processing Details card
4. Check browser console for debug output
5. Verify displayed values match API response

### Step 3: Fix Data Extraction
Based on debug output, update computed properties to access data correctly.

### Step 4: Test All Pathways
- Test Task-Based pathway (no roles)
- Test Role-Based pathway (with roles)
- Test Dual-Track pathway (with expert strategy)

---

## Files Modified

### New Files Created
1. `src/frontend/src/components/phase2/task3/AlgorithmExplanationCard.vue` (621 lines)
2. `src/frontend/src/components/phase2/task3/AlgorithmStep.vue` (310 lines)
3. `src/frontend/src/components/phase2/task3/ValidationResultsDetail.vue` (247 lines)

### Existing Files Modified
1. `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue`
   - Line 59-64: Added AlgorithmExplanationCard component
   - Line 224: Added import statement

---

## Known Working Parts

✅ Component compilation successful
✅ HMR (Hot Module Reload) working
✅ Element Plus icons loading correctly
✅ Expandable/collapsible UI working
✅ Component structure and layout correct
✅ Dual-track detection logic (isDualTrack computed property)
✅ Strategy count extraction for expert strategies

---

## Known Broken Parts

❌ Total Users showing 0
❌ Competencies Analyzed showing 0
❌ PMT Customization count showing 0
❌ Strategy names showing IDs instead of names
❌ Pathway might be incorrectly set to TASK_BASED
❌ Algorithm steps not showing any data

---

## Next Session Action Items

### Priority 1: Debug Data Flow
1. Add console.log statements to see what data is being received
2. Verify `props.data` structure matches API response
3. Check if `normalizedData.pathway` is correct value

### Priority 2: Fix Data Extraction
1. Fix `totalUsers` extraction
2. Fix `gapBasedStrategies` to return names not IDs
3. Fix `expertStrategies` to return names not IDs
4. Fix `competenciesAnalyzed` calculation
5. Fix `pmtCustomizationCount` calculation

### Priority 3: Fix Step Data
1. Fix step1Data - ensure totalUsers is populated
2. Fix step2Data - ensure roles are extracted correctly
3. Fix step3Data - ensure scenario counts are calculated
4. Fix step4Data - ensure best-fit distribution is built
5. Fix step5Data - ensure validation data is extracted
6. Fix step6Data - ensure strategic decisions are extracted
7. Fix step7Data - ensure strategy count is correct
8. Fix step8Data - ensure PMT counts are correct

### Priority 4: Test End-to-End
1. Test with organization that has Role-Based pathway
2. Test with organization that has Task-Based pathway
3. Test with organization that has Dual-Track processing
4. Verify all data displays correctly

---

## Code Snippets for Next Session

### Quick Fix Template
```javascript
// File: AlgorithmExplanationCard.vue
// Line: ~338-345

// BEFORE (WRONG)
const totalUsers = computed(() => props.data.total_users_assessed || 0)

// AFTER (CORRECT) - Verify props.data is the objectives object
const totalUsers = computed(() => {
  console.log('[totalUsers] Checking props.data:', props.data?.total_users_assessed)
  return props.data?.total_users_assessed || 0
})
```

### Strategy Names Fix
```javascript
// File: AlgorithmExplanationCard.vue
// Line: ~366-371

// BEFORE (WRONG)
const gapBasedStrategies = computed(() => {
  if (props.data.gap_based_training) {
    return Object.keys(props.data.gap_based_training.learning_objectives_by_strategy || {})
  }
  return Object.keys(props.data.learning_objectives_by_strategy || {})
})

// AFTER (CORRECT)
const gapBasedStrategies = computed(() => {
  let strategiesObj = {}

  if (props.data.gap_based_training) {
    strategiesObj = props.data.gap_based_training.learning_objectives_by_strategy || {}
  } else {
    strategiesObj = props.data.learning_objectives_by_strategy || {}
  }

  // Extract strategy names, not IDs
  const names = Object.values(strategiesObj)
    .map(s => s.strategy_name || 'Unknown')
    .filter(name => name !== 'Unknown')

  console.log('[gapBasedStrategies] Extracted:', names)
  return names
})
```

---

## API Response Example (for Reference)

```json
{
  "pathway": "ROLE_BASED",
  "total_users_assessed": 45,
  "aggregation_method": "median_per_role_with_user_distribution",
  "maturity_level": 3,
  "maturity_description": "Defined",
  "completion_rate": 100,

  "gap_based_training": {
    "strategy_count": 6,
    "learning_objectives_by_strategy": {
      "12": {
        "strategy_id": 12,
        "strategy_name": "Common basic understanding",
        "trainable_competencies": [ ... ],
        "not_trainable_competencies": [ ... ]
      },
      "13": {
        "strategy_id": 13,
        "strategy_name": "SE for managers",
        "trainable_competencies": [ ... ]
      }
    },
    "competency_scenario_distributions": {
      "1": {
        "competency_id": 1,
        "competency_name": "Systems Thinking",
        "by_strategy": {
          "12": {
            "scenario_A_count": 20,
            "scenario_B_count": 5,
            "scenario_C_count": 2,
            "scenario_D_count": 18
          }
        }
      }
    },
    "cross_strategy_coverage": { ... },
    "validation": {
      "strategy_validation": {
        "status": "GOOD",
        "gap_percentage": 15.5,
        "strategies_adequate": true
      }
    },
    "strategic_decisions": { ... }
  },

  "expert_development": {
    "strategy_count": 1,
    "learning_objectives_by_strategy": {
      "19": {
        "strategy_id": 19,
        "strategy_name": "Train the trainer",
        "trainable_competencies": [ ... ]
      }
    }
  }
}
```

---

## Session Summary

**What was accomplished:**
- Created comprehensive Algorithm Explanation Card component
- Fixed Element Plus icon import issues
- Successfully integrated into LearningObjectivesView
- Component compiles and renders

**What needs fixing:**
- Data extraction from props is incorrect
- Strategy names showing as IDs
- Several computed values returning 0
- Need to add debug logging

**Estimated time to fix:** 1-2 hours
- 30 min: Add debug logging and identify exact data structure
- 30 min: Fix all computed properties to extract data correctly
- 30 min: Test with all pathway types and verify

---

**End of Document**
