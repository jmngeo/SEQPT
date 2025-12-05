# Algorithm Explanation Card Enhancement Plan

**Date**: November 10, 2025
**Purpose**: Plan to enhance the frontend "Algorithm Processing Details" card to match COMPLETE_ALGORITHM_EXPLANATION.md

---

## Current State

### What the Card Currently Shows:

**Step 1**: Total users, assessment type ✅
**Step 2**: Only role requirements (what level each role needs) ❌
**Step 3**: User distribution per scenario (good, but in "Detailed Processing Data") ✅
**Step 4**: Fit scores (in "Detailed Processing Data" only) ⚠️
**Step 5**: Strategy validation ✅
**Step 6**: Strategic decisions ✅

### Missing Details:

**Step 2 Missing**:
- Median current level calculations per role per competency
- Scenario classifications (A/B/C/D) per role per competency per strategy
- Explanation of what "Required Level" means (it's the role requirement, NOT the median)

**Step 4 Missing**:
- Summary table view showing all 16 competencies at once
- Table columns: Competency Name | Best-Fit Strategy | Fit Score | Scenario B % | Gap Severity
- This should be in the main Step 4 display, not just "Detailed Processing Data"

---

## Required Backend Changes

### 1. Add Role Analysis Details to API Response

**Location**: `role_based_pathway_fixed.py` around line 1088

**Current**:
```python
'role_requirements': role_requirements_detail,  # Only role requirements
```

**Need to Add**:
```python
'role_requirements': role_requirements_detail,  #  role requirements
'role_analysis_details': role_analysis_details,  # NEW: Median calculations + scenario classifications
```

**New Function Needed**:
```python
def extract_role_analysis_details(role_analyses, organization_roles, user_assessments, selected_strategies, all_competencies):
    """
    Extract detailed role analysis data for frontend Algorithm Explanation Card

    For each role, for each competency, for each strategy:
    - Calculate median current level for users in that role
    - Show scenario classifications for each user

    Returns structure:
    {
        role_id: {
            role_name: str,
            competency_analyses: {
                competency_id: {
                    competency_name: str,
                    median_current_level: int,
                    by_strategy: {
                        strategy_name: {
                            strategy_target: int,
                            role_requirement: int,
                            scenario_classifications: {
                                user_id: 'A'|'B'|'C'|'D',
                                ...
                            },
                            scenario_counts: {A: int, B: int, C: int, D: int}
                        }
                    }
                }
            }
        }
    }
    """
```

### 2. Add Cross-Strategy Coverage Summary

**Location**: Same area in `role_based_pathway_fixed.py`

**Need to Add**:
```python
'cross_strategy_coverage_summary': coverage_summary,  # NEW: Summary table data
```

**New Function Needed**:
```python
def generate_coverage_summary(cross_strategy_coverage, all_strategy_fit_scores):
    """
    Generate summary table data for Step 4 display

    Returns array:
    [
        {
            competency_id: 1,
            competency_name: "Systems Thinking",
            best_fit_strategy: "SE for managers",
            best_fit_score: 0.71,
            scenario_B_percentage: 9.52,
            gap_severity: "minor",
            max_role_requirement: 6,
            target_level: 4
        },
        ...
    ]
    """
```

---

## Required Frontend Changes

### 1. Enhance Step 2 Display

**Location**: `AlgorithmExplanationCard.vue` line 736 (generateStep2DetailedHTML)

**Changes Needed**:

```html
<!-- Current: Only shows role requirements -->
<!-- Need to Add: -->

<h5>Step 2.1: Calculate Median Current Levels per Role</h5>
<table>
  <thead>
    <tr>
      <th>Role</th>
      <th>Competency</th>
      <th>Users in Role</th>
      <th>User Scores</th>
      <th>Median (Current Level)</th>
      <th>Role Requirement</th>
    </tr>
  </thead>
  <tbody>
    <!-- For each role, each competency -->
    <tr>
      <td>Systems Engineer</td>
      <td>Systems Thinking</td>
      <td>5</td>
      <td>[3, 2, 4, 3, 2]</td>
      <td><strong>3</strong> (median)</td>
      <td>6</td>
    </tr>
  </tbody>
</table>

<h5>Step 2.2: Classify Users into Scenarios</h5>
<!-- For each role, each competency, each strategy -->
<div class="role-analysis">
  <h6>Role: Systems Engineer | Competency: Systems Thinking</h6>

  <div class="strategy-scenarios">
    <h7>Strategy: SE for managers (target=4, role req=6)</h7>
    <table>
      <thead>
        <tr>
          <th>User ID</th>
          <th>Current Score</th>
          <th>Comparison</th>
          <th>Scenario</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>64</td>
          <td>3</td>
          <td>3 < 4 ≤ 6</td>
          <td><span class="scenario-A">Scenario A</span></td>
        </tr>
        <tr>
          <td>65</td>
          <td>2</td>
          <td>2 < 4 ≤ 6</td>
          <td><span class="scenario-A">Scenario A</span></td>
        </tr>
        <tr>
          <td>66</td>
          <td>4</td>
          <td>4 ≤ 4 < 6</td>
          <td><span class="scenario-B">Scenario B</span></td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

### 2. Add Summary Table to Step 4

**Location**: `AlgorithmExplanationCard.vue` line 959 (step4Data)

**Changes Needed**:

Add a new summary view in the main Step 4 display (not just in "Detailed Processing Data"):

```html
<h5>Step 4 Summary: Best-Fit Strategy per Competency</h5>
<el-alert type="info">
  This table shows the best-fit strategy selected for each competency based on fit score calculations.
  Fit Score Formula: (A% × 1.0) + (D% × 1.0) + (B% × -2.0) + (C% × -0.5)
</el-alert>

<el-table :data="coverageSummaryData" border stripe>
  <el-table-column prop="competency_name" label="Competency" width="200" />
  <el-table-column prop="best_fit_strategy" label="Best-Fit Strategy" width="250" />
  <el-table-column prop="best_fit_score" label="Fit Score" width="100">
    <template #default="scope">
      <el-tag :type="getFitScoreType(scope.row.best_fit_score)">
        {{ scope.row.best_fit_score.toFixed(2) }}
      </el-tag>
    </template>
  </el-table-column>
  <el-table-column prop="scenario_B_percentage" label="Scenario B %" width="120">
    <template #default="scope">
      {{ scope.row.scenario_B_percentage.toFixed(1) }}%
    </template>
  </el-table-column>
  <el-table-column prop="gap_severity" label="Gap Severity" width="120">
    <template #default="scope">
      <el-tag :type="getSeverityType(scope.row.gap_severity)">
        {{ scope.row.gap_severity }}
      </el-tag>
    </template>
  </el-table-column>
  <el-table-column label="Levels" width="150">
    <template #default="scope">
      Target: {{ scope.row.target_level }}<br/>
      Max Role Req: {{ scope.row.max_role_requirement }}
    </template>
  </el-table-column>
</el-table>
```

### 3. Add Explanation Tooltips

Add tooltips throughout to explain what each piece of data means:

```html
<el-tooltip content="This is the MEDIAN current level across all users in this role for this competency. It represents the typical competency level for this role.">
  <el-icon><QuestionFilled /></el-icon>
</el-tooltip>
```

---

## Implementation Order

### Phase 1: Backend Changes (1-2 hours)
1. Create `extract_role_analysis_details()` function
2. Create `generate_coverage_summary()` function
3. Add both to API response
4. Test with org 29 to verify data structure

### Phase 2: Frontend Step 2 Enhancement (2-3 hours)
1. Update `step2Data` computed property to extract new data
2. Create enhanced `generateStep2DetailedHTML()` with median calculations
3. Add scenario classification display per role
4. Add explanatory text and tooltips
5. Test display

### Phase 3: Frontend Step 4 Enhancement (1-2 hours)
1. Update `step4Data` to extract summary data
2. Add summary table view to main Step 4 display
3. Keep detailed view in "Detailed Processing Data" section
4. Test display

### Phase 4: Additional Enhancements (1 hour)
1. Add missing explanations from COMPLETE_ALGORITHM_EXPLANATION.md
2. Add scenario meaning tooltips
3. Add formula explanations
4. Final testing

---

## Data Structure Examples

### Role Analysis Details (Backend Response):

```json
{
  "role_analysis_details": {
    "101": {
      "role_id": 101,
      "role_name": "Systems Engineer",
      "user_count": 5,
      "competency_analyses": {
        "1": {
          "competency_id": 1,
          "competency_name": "Systems Thinking",
          "median_current_level": 3,
          "user_scores": [3, 2, 4, 3, 2],
          "by_strategy": {
            "SE for managers": {
              "strategy_id": 1,
              "strategy_target": 4,
              "role_requirement": 6,
              "scenario_classifications": {
                "64": "A",
                "65": "A",
                "66": "B",
                "67": "A",
                "68": "A"
              },
              "scenario_counts": {
                "A": 4,
                "B": 1,
                "C": 0,
                "D": 0
              },
              "scenario_percentages": {
                "A": 80.0,
                "B": 20.0,
                "C": 0.0,
                "D": 0.0
              }
            },
            "Continuous support": {
              "strategy_id": 2,
              "strategy_target": 2,
              "role_requirement": 6,
              "scenario_classifications": {
                "64": "B",
                "65": "A",
                "66": "B",
                "67": "B",
                "68": "A"
              },
              "scenario_counts": {
                "A": 2,
                "B": 3,
                "C": 0,
                "D": 0
              }
            }
          }
        }
        // ... all 16 competencies
      }
    },
    "102": {
      "role_name": "Requirements Engineer",
      // ... same structure
    }
    // ... all roles
  }
}
```

### Coverage Summary (Backend Response):

```json
{
  "cross_strategy_coverage_summary": [
    {
      "competency_id": 1,
      "competency_name": "Systems Thinking",
      "best_fit_strategy_id": 1,
      "best_fit_strategy": "SE for managers",
      "best_fit_score": 0.71,
      "scenario_B_count": 2,
      "scenario_B_percentage": 9.52,
      "gap_severity": "minor",
      "max_role_requirement": 6,
      "target_level": 4,
      "all_strategies_count": 2
    },
    {
      "competency_id": 2,
      "competency_name": "Holistic Thinking",
      "best_fit_strategy": "SE for managers",
      "best_fit_score": 0.85,
      "scenario_B_percentage": 0.0,
      "gap_severity": "none",
      "max_role_requirement": 4,
      "target_level": 4
    }
    // ... all 16 competencies
  ]
}
```

---

## Expected Result

After implementation, the "Algorithm Processing Details" card will show:

### Step 2: Analyze All Roles
- ✅ Clear explanation that this uses each role's own requirement (not max)
- ✅ Table showing median calculation per role per competency
- ✅ User scores that went into the median
- ✅ Scenario classification for each user in each role for each strategy
- ✅ Visual comparison: current vs target vs role requirement

### Step 4: Cross-Strategy Coverage
- ✅ Summary table showing all 16 competencies at a glance
- ✅ Best-fit strategy clearly indicated
- ✅ Fit scores color-coded
- ✅ Scenario B percentage (gap indicator)
- ✅ Gap severity classification
- ✅ Detailed fit score breakdown in expandable section

### Overall
- ✅ Matches the detail level in COMPLETE_ALGORITHM_EXPLANATION.md
- ✅ Clear explanations and tooltips
- ✅ Easy to understand the algorithm's decision-making process
- ✅ Complete audit trail of all calculations

---

## Next Steps

1. Confirm this plan with user
2. Implement backend changes first (adds data to API)
3. Implement frontend changes to display the data
4. Test thoroughly with org 29
5. Document the enhanced card

**Estimated Total Time**: 6-8 hours
**Complexity**: Medium-High (significant data structure changes)
**Impact**: High (major improvement in transparency and understanding)
