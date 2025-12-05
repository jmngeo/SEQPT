# 8-Step Role-Based Algorithm - Deep Dive Analysis

**Date**: November 6, 2025
**Purpose**: Comprehensive validation of the complete algorithm against design specification
**Reference**: `LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

---

## Executive Summary

### Critical Bugs Found

1. ❌ **Scenario Distribution Chart Mislabeling** (CRITICAL)
   - **What it shows**: COMPETENCY counts (e.g., "10 competencies")
   - **What it says**: "users"
   - **What it should show**: USER percentages/counts per scenario
   - **Impact**: Misleading data visualization - users think only 10 of 21 users are counted

2. ❌ **Frontend Recalculates Scenario Distribution** (DESIGN VIOLATION)
   - Backend provides per-competency user distributions
   - Frontend throws this away and recalculates for whole strategy
   - Loses granular per-competency user distribution data
   - Design says: Show individual user scenarios per competency

3. ⚠️ **Missing Design Elements** (INCOMPLETE)
   - No display of users_by_scenario (which users are in Scenario B)
   - No cross-strategy comparison visualization
   - No best-fit strategy indication
   - Missing validation recommendations in UI

---

## Design Specification (from v4.1)

### What the 8-Step Algorithm Should Produce

**Step 3 Output**: `competency_scenario_distributions`
```json
{
  "11": {
    "competency_name": "Decision Management",
    "by_strategy": {
      "Needs-based project-oriented training": {
        "total_users": 40,
        "scenario_A_count": 30,
        "scenario_B_count": 3,
        "scenario_C_count": 2,
        "scenario_D_count": 5,
        "scenario_A_percentage": 75.0,
        "scenario_B_percentage": 7.5,
        "users_by_scenario": {
          "A": [1, 2, 3, ...],  // USER IDs
          "B": [35, 36, 37],
          "C": [30, 31],
          "D": [40, 41, 42, 43, 44]
        }
      }
    }
  }
}
```

**Step 4 Output**: `cross_strategy_coverage`
```json
{
  "11": {
    "competency_name": "Decision Management",
    "max_role_requirement": 6,
    "best_fit_strategy": "Needs-based project-oriented training",
    "best_fit_score": 0.65,
    "all_strategy_fit_scores": {...},
    "has_real_gap": true,
    "gap_size": 2,
    "scenario_B_count": 3,
    "scenario_B_percentage": 7.5,
    "users_with_real_gap": [35, 36, 37],  // USER IDs
    "gap_severity": "minor"
  }
}
```

---

## Current Implementation Status

### Step 1: Get Latest Assessments and Roles ✅ CORRECT

**Backend**: `role_based_pathway_fixed.py:245-293`

**What it does**:
```python
def get_latest_assessments_per_user(org_id, survey_type='known_roles'):
    query = """
    SELECT DISTINCT ON (ua.user_id)
        ua.id as assessment_id,
        ua.user_id,
        ua.username,
        ua.organization_id
    FROM user_assessment ua
    WHERE ua.organization_id = %s
      AND ua.survey_type = %s
      AND ua.created_at IS NOT NULL
    ORDER BY ua.user_id, ua.created_at DESC
    """
```

**Validation**: ✅ CORRECT
- Uses DISTINCT ON to get latest per user
- Returns user_id (FK to users table) correctly
- Org 29 test: Returns 21 unique users

### Step 2: Analyze All Roles (Per-Competency Scenario Classification) ⚠️ PARTIAL

**Backend**: `role_based_pathway_fixed.py:296-559`

**What it should do** (Design lines 590-605):
```python
for strategy in selected_strategies:
    for role in organization_roles:
        role_analyses[role.id][strategy.id] = {
            'competencies': {}
        }
        for competency in all_16_competencies:
            # Calculate current level (median for this role)
            # Get archetype target
            # Get role requirement
            # Classify scenario
            # Store users_by_scenario (list of user IDs)
```

**What it actually does**:
- ✅ Iterates per-strategy correctly
- ✅ Calculates median per role
- ✅ Classifies scenarios correctly
- ❌ **MISSING**: Does NOT store `users_by_scenario` (user ID lists)
- ❌ **MISSING**: Does NOT return nested `by_strategy` structure

**Current Output Structure**:
```python
{
    'role_id': role_id,
    'role_name': role_name,
    'user_count': len(users_in_role),
    'competency_scenarios': {
        '7': {
            'current_level': 3,
            'scenario': 'A',
            'gap': 1
            # MISSING: users_by_scenario
        }
    }
}
```

**Design Requirement** (lines 1236-1277):
```json
{
  "11": {
    "competency_name": "Decision Management",
    "by_strategy": {
      "Strategy Name": {
        "users_by_scenario": {
          "A": [1, 2, 3],
          "B": [35, 36],
          "D": [40, 41]
        }
      }
    }
  }
}
```

### Step 3: Aggregate by User Distribution ❌ INCORRECT

**Backend**: `role_based_pathway_fixed.py:562-684`

**What it should do** (Design lines 607-609):
```python
# Aggregate by counting users in each scenario
# For each competency + strategy combination:
#   Count users in Scenario A, B, C, D
#   Calculate percentages
```

**What it actually does**:
```python
for comp_id, comp_name in all_16_competencies:
    comp_distribution = {
        'competency_name': comp_name,
        'by_strategy': {}  # ✅ Good - per-strategy breakdown
    }

    for strategy in selected_strategies:
        user_scenario_counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0}

        for role_analysis in role_analyses:
            comp_data = role_analysis['competency_scenarios'].get(comp_id)
            if comp_data:
                scenario = comp_data['scenario']
                user_scenario_counts[scenario] += role_analysis['user_count']  # ❓
```

**POTENTIAL BUG**: Uses `role_analysis['user_count']` which is the total users in that role. But what if a user is in multiple roles? This could double-count users!

**Design says** (lines 607-609):
- Use SETS to avoid double-counting multi-role users
- Track individual user IDs, then count unique IDs

**Current code does NOT use sets** - it adds up user_count per role, which can double-count.

### Step 4: Cross-Strategy Coverage Check (Best-Fit) ⚠️ INCOMPLETE

**Backend**: `role_based_pathway_fixed.py:687-834`

**What it should do** (Design lines 610-619, 669-676):
- Calculate fit scores for each strategy using formula:
  - Scenario A: +1.0 (good)
  - Scenario D: +1.0 (perfect)
  - Scenario B: -2.0 (bad - strategy insufficient)
  - Scenario C: -0.5 (over-training)
- Select best-fit strategy per competency
- Identify users with real gaps (Scenario B users of best-fit strategy)

**What it actually does**:
- ❓ **NEEDS VERIFICATION**: Does it calculate fit scores?
- ❓ **NEEDS VERIFICATION**: Does it select best-fit strategy?
- ❌ **MISSING**: Does NOT return `users_with_real_gap` (user ID list)

**Location**: Need to inspect code at lines 687-834

### Step 5-7: Validation, Decisions, Objectives ⏸️ NOT YET ANALYZED

Will analyze after fixing Steps 2-4.

### Step 8: Learning Objective Text Generation ⏸️ NOT YET ANALYZED

Will analyze after fixing Steps 2-7.

---

## Bugs Summary

### 1. User Counting Issue (Step 3)

**Problem**: May double-count users who have multiple roles

**Evidence**:
- Code uses `role_analysis['user_count']` and sums across roles
- Doesn't use Python sets to track unique user IDs
- Design explicitly says to use sets (line 608)

**Fix Required**:
```python
# WRONG (current):
user_scenario_counts[scenario] += role_analysis['user_count']

# CORRECT (should be):
users_in_scenario_A = set()
for role_analysis in role_analyses:
    for user_id in role_analysis['users_in_scenario_A']:
        users_in_scenario_A.add(user_id)
user_scenario_counts['A'] = len(users_in_scenario_A)
```

### 2. Missing users_by_scenario Lists (Step 2)

**Problem**: Algorithm doesn't track WHICH users are in each scenario

**Impact**:
- Can't show "Users in Scenario B: [Alice, Bob, Carol]"
- Can't validate which users need supplementary training
- Can't generate user-specific recommendations

**Fix Required**:
Add to Step 2 output:
```python
'users_by_scenario': {
    'A': [user_id1, user_id2, ...],
    'B': [user_id3],
    'C': [],
    'D': [user_id4, user_id5]
}
```

### 3. Frontend Scenario Distribution Mislabeling (Critical UX Bug)

**Problem**: Chart shows "N users" but N is actually number of COMPETENCIES

**Current Flow**:
1. Backend returns per-competency user percentages
2. Frontend `calculateStrategyScenarioDistribution()` counts competencies
3. Chart displays competency count as "users"

**Example**:
- Strategy has 12 trainable competencies
- 10 competencies need training (Scenario A)
- 2 competencies already met (Scenario D)
- Chart shows: "10 users" (WRONG - it's 10 competencies!)

**Fix Required**:
Option A: Use backend's per-competency user distributions
Option B: Aggregate backend data correctly to show total users per scenario across ALL competencies
Option C: Change chart label to "competencies" not "users"

---

## Data Flow Analysis

### Backend → Frontend Data Flow

**Backend Returns**:
```json
{
  "learning_objectives_by_strategy": {
    "34": {
      "trainable_competencies": [
        {
          "competency_id": 7,
          "scenario": "Scenario B",
          "scenario_distribution": {
            "A": 0,
            "B": 95.23,  // PERCENTAGES of users in this competency
            "C": 0,
            "D": 4.76
          }
        }
      ]
    }
  }
}
```

**Frontend LearningObjectivesView.vue**:
```javascript
const objectivesByStrategy = computed(() => {
  for (const [strategyId, strategyData] of Object.entries(strategies)) {
    strategiesWithScenarios[strategyId] = {
      ...strategyData,
      scenario_distribution: calculateStrategyScenarioDistribution(strategyData)  // ❌ OVERWRITES!
    }
  }
})

const calculateStrategyScenarioDistribution = (strategyData) => {
  const scenarioCounts = {'Scenario A': 0, 'Scenario B': 0, ...}

  strategyData.trainable_competencies.forEach(comp => {
    const scenario = comp.scenario
    scenarioCounts[scenario]++  // ❌ Counting COMPETENCIES not USERS!
  })

  return scenarioCounts  // ❌ Returns: {'Scenario A': 10, 'Scenario B': 2} - competency counts!
}
```

**Frontend ScenarioDistributionChart.vue**:
```javascript
label: {
  show: true,
  formatter: '{b}\n{c} users'  // ❌ WRONG LABEL!
}
```

**Result**: "10 users" is displayed, but it's actually "10 competencies in Scenario A"

---

## Design vs Implementation Matrix

| Step | Design Requirement | Implementation Status | Issue |
|------|-------------------|----------------------|-------|
| 1 | Get latest assessments per user | ✅ CORRECT | None |
| 2 | Per-role per-strategy per-competency analysis | ⚠️ PARTIAL | Missing users_by_scenario lists |
| 2 | Nested by_strategy structure | ❌ MISSING | Flat structure returned |
| 3 | Count unique users per scenario (use sets) | ❌ INCORRECT | May double-count multi-role users |
| 3 | Per-competency per-strategy aggregation | ✅ CORRECT | Structure correct |
| 4 | Calculate fit scores | ❓ UNKNOWN | Need to inspect code |
| 4 | Select best-fit strategy | ❓ UNKNOWN | Need to inspect code |
| 4 | Track users_with_real_gap | ❌ MISSING | Not returned |
| 5-7 | Validation & decisions | ⏸️ NOT YET ANALYZED | - |
| 8 | Text generation | ⏸️ NOT YET ANALYZED | - |
| Frontend | Display per-competency user distribution | ❌ INCORRECT | Shows competency counts as "users" |
| Frontend | Show users_by_scenario lists | ❌ MISSING | Data not available |
| Frontend | Indicate best-fit strategy | ❌ MISSING | Not visualized |

---

## Test Data Requirements

To properly test the algorithm, we need organizations with:

### Test Org 1: Multi-Role Users (Test Step 3 user counting)
- 10 users
- 3 roles (e.g., "Architect", "Developer", "Tester")
- 5 users have SINGLE role
- 5 users have MULTIPLE roles (e.g., Architect + Developer)
- 2 strategies selected
- **Expected**: Unique user counting (total should be 10, not 15)

### Test Org 2: All Scenario Combinations (Test Step 2 classification)
- 12 users across 3 roles
- 2 strategies with different targets
- Design competency scores to trigger ALL scenarios:
  - **Scenario A**: Current < Target ≤ Role (e.g., current=1, target=2, role=4)
  - **Scenario B**: Target ≤ Current < Role (e.g., current=3, target=2, role=6)
  - **Scenario C**: Target > Role (e.g., current=2, target=6, role=4)
  - **Scenario D**: Current ≥ Both (e.g., current=4, target=4, role=4)
- **Expected**: All 4 scenarios represented in results

### Test Org 3: Best-Fit Strategy Selection (Test Step 4)
- 15 users in 2 roles
- 3 strategies with varying fit scores
- Design so:
  - Strategy A has high Scenario B percentage (bad fit)
  - Strategy B has high Scenario A percentage (good fit)
  - Strategy C has high Scenario C percentage (over-training)
- **Expected**: Strategy B selected as best-fit

### Test Org 4: Validation Edge Cases (Test Step 5)
- 20 users
- 2 strategies insufficient for multiple competencies
- **Expected**: Validation status = "INADEQUATE"
- **Expected**: Recommendations to add strategies

---

## Next Steps

1. ✅ **Document current bugs** (this document)
2. **Fix Step 3**: Implement unique user counting with sets
3. **Fix Step 2**: Add users_by_scenario tracking
4. **Verify Step 4**: Inspect best-fit calculation code
5. **Fix Frontend**: Correct scenario distribution display
6. **Create Test Data**: Implement 4 test organizations
7. **Validate Algorithm**: Run comprehensive tests
8. **Update Design**: Document any deviations or improvements

---

## Files to Inspect/Modify

### Backend
- `src/backend/app/services/role_based_pathway_fixed.py:562-684` - Fix Step 3 user counting
- `src/backend/app/services/role_based_pathway_fixed.py:296-559` - Add users_by_scenario to Step 2
- `src/backend/app/services/role_based_pathway_fixed.py:687-834` - Verify Step 4 fit scores

### Frontend
- `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue:289-313` - Fix calculateStrategyScenarioDistribution()
- `src/frontend/src/components/phase2/task3/ScenarioDistributionChart.vue:150` - Fix label from "users" to correct unit
- `src/frontend/src/components/phase2/task3/CompetencyCard.vue` - Add users_by_scenario display

### Test Data
- Create: `create_test_org_multirol.py` - Multi-role user counting test
- Create: `create_test_org_all_scenarios.py` - All 4 scenarios test
- Create: `create_test_org_bestfit.py` - Best-fit strategy test
- Create: `create_test_org_validation.py` - Validation edge cases test

---

**Status**: Phase 1 analysis COMPLETE - Critical bugs identified
**Next**: Inspect Step 4 code + Create test data
