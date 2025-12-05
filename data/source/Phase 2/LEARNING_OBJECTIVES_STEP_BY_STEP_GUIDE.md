# Learning Objectives Generation - Step-by-Step Guide
**Date**: November 7, 2025
**Purpose**: Clear step-by-step explanation of the complete algorithm
**Audience**: Implementation team, thesis documentation

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Pathway Selection](#pathway-selection)
3. [Task-Based Pathway (5 Steps)](#task-based-pathway-5-steps)
4. [Role-Based Pathway (8 Steps)](#role-based-pathway-8-steps)
5. [Key Concepts Explained](#key-concepts-explained)
6. [Complete Examples](#complete-examples)

---

## System Overview

### What This System Does

Generates customized learning objectives for organizations based on their competency assessment results and selected training strategies.

**Input:**
- Competency assessment results (from Phase 2 Task 2)
- Selected training strategies (from Phase 1)
- Role definitions (if organization has them)
- Company PMT context (Processes, Methods, Tools - if needed)

**Output:**
- Learning objectives for each strategy
- Validation results (for role-based pathway)
- Recommendations and priorities
- Training duration estimates

---

### Two Different Pathways

The system automatically chooses between two pathways based on organization maturity:

| Aspect | Task-Based | Role-Based |
|--------|-----------|------------|
| **When Used** | Maturity level 1-2 | Maturity level 3-5 |
| **Organization Type** | No defined SE roles | Has defined SE roles |
| **Complexity** | Simple | Complex |
| **Steps** | 5 | 8 |
| **Validation** | No | Yes |
| **Output Depth** | Basic objectives | Full validation + priorities |

---

## Pathway Selection

### How the System Decides

**Step 1:** Fetch the organization's maturity level from Phase 1 assessment
```
API Call: GET /api/phase1/maturity/{org_id}/latest
Extract: results.strategyInputs.seProcessesValue
```

**Step 2:** Apply threshold
```
MATURITY_THRESHOLD = 3

If maturity_level >= 3:
    → Use ROLE-BASED pathway
Else:
    → Use TASK-BASED pathway
```

**Example:**
- Organization 28 has maturity_level = 4
- Decision: 4 >= 3 → Use ROLE-BASED pathway

---

## Task-Based Pathway (5 Steps)

**Used for:** Organizations without defined SE roles (low maturity)

**Key Principle:** Simple 2-way comparison between current levels and strategy targets

---

### Step 1: Get Latest Assessments

**What it does:**
Retrieves the most recent competency assessment for each user who has completed Phase 2 Task 2.

**How:**
```sql
SELECT DISTINCT ON (user_id)
  user_id, competency_id, score, submitted_at
FROM user_se_competency_survey_results
WHERE organization_id = {org_id}
  AND role = 'unknown_roles'
  AND is_test = FALSE
ORDER BY user_id, submitted_at DESC
```

**Example Result:**
```
User 101: Completed assessment on Nov 1
User 102: Completed assessment on Nov 3
User 103: Completed assessment on Nov 2
Total: 3 users
```

**If no assessments found:** Return error "No assessment data available"

---

### Step 2: Get Selected Strategies

**What it does:**
Retrieves which training strategies the organization selected in Phase 1.

**How:**
```sql
SELECT strategy_name, description
FROM organization_strategy
WHERE organization_id = {org_id}
```

**Example Result:**
```
Strategy: "Common basic understanding"
Description: "Foundational SE knowledge for all team members"
```

---

### Step 3: Calculate Current Levels

**What it does:**
For each of the 16 competencies, calculate the organization's current level using the MEDIAN of all user scores.

**Why median?**
- Robust to outliers
- If one user scored 0 and others scored 2-3, median gives a realistic middle value
- More accurate than average for small datasets

**How:**
```python
For each competency (1-16):
    1. Get all user scores for this competency
    2. Filter out None/NULL values
    3. Calculate median
    4. Store as current_level
```

**Example - Decision Management (Competency 11):**
```
User 101: Level 0
User 102: Level 1
User 103: Level 2

Sorted: [0, 1, 2]
Median: 1

Current Level = 1
```

---

### Step 4: Compare Current vs Target

**What it does:**
For each competency and each selected strategy, perform a 2-way comparison.

**The Comparison:**
```
Current Level (from Step 3)
vs
Archetype Target (from strategy template)

If Current < Target:
    → Training needed (gap exists)
Else:
    → Target achieved (no training needed)
```

**Example:**
```
Competency: Decision Management (ID 11)
Current Level: 1
Strategy: "Common basic understanding"
Archetype Target: 2

Comparison: 1 < 2
Result: Training needed
Gap: 2 - 1 = 1 level
```

**Special Case - Core Competencies:**
Core competencies (IDs: 1, 4, 5, 6) cannot be directly trained.
- Systems Thinking (1)
- Lifecycle Consideration (4)
- Customer/Value Orientation (5)
- Systems Modelling and Analysis (6)

These are added to output with explanatory note but no learning objective.

---

### Step 5: Generate Learning Objectives

**What it does:**
For each competency requiring training, retrieve the appropriate learning objective template.

**How:**
```python
1. Load template file: se_qpt_learning_objectives_template_latest.json
2. For each competency with gap:
   a. Get competency name
   b. Get target level
   c. Retrieve template: templates[competency_name][target_level]
   d. Use template text as-is (NO customization in task-based)
```

**Example:**
```
Competency: Decision Management
Target Level: 2

Template Retrieved:
"Participants learn about decision support methods such as trade
studies and can apply simple decision matrices."

Output:
{
  "competency_id": 11,
  "competency_name": "Decision Management",
  "current_level": 1,
  "target_level": 2,
  "gap": 1,
  "status": "training_required",
  "learning_objective": "Participants learn about decision support
                         methods such as trade studies and can
                         apply simple decision matrices."
}
```

**Build Final Output:**
```json
{
  "pathway": "TASK_BASED",
  "organization_id": 28,
  "total_users_assessed": 3,
  "aggregation_method": "median",
  "learning_objectives_by_strategy": {
    "Common basic understanding": {
      "core_competencies": [...],
      "trainable_competencies": [...]
    }
  }
}
```

---

## Role-Based Pathway (8 Steps)

**Used for:** Organizations with defined SE roles (high maturity)

**Key Principle:** 3-way comparison with validation layer

**Overview:**
1. Get data
2. Analyze each role (classify scenarios)
3. Aggregate by user distribution
4. Find best-fit strategy per competency
5. Validate strategy adequacy
6. Make strategic recommendations
7. Generate objectives structure
8. Generate learning objective text

---

### Step 1: Get Data

**What it does:**
Fetches all required data in parallel for efficient processing.

**Data Retrieved:**

**A. Latest Assessments:**
```sql
SELECT DISTINCT ON (user_id)
  user_id, role_cluster_id, competency_id, score
FROM user_se_competency_survey_results
WHERE organization_id = {org_id}
  AND role_cluster_id IS NOT NULL
  AND is_test = FALSE
ORDER BY user_id, submitted_at DESC
```

**B. Organization Roles:**
```sql
SELECT role_cluster_id, role_name
FROM user_defined_role_clusters
WHERE organization_id = {org_id}
```

**C. Selected Strategies:**
```sql
SELECT strategy_name, description
FROM organization_strategy
WHERE organization_id = {org_id}
```

**D. PMT Context (if exists):**
```sql
SELECT processes, methods, tools, industry
FROM organization_pmt_context
WHERE organization_id = {org_id}
ORDER BY updated_at DESC
LIMIT 1
```

**Example Result:**
```
Users: 5 users with assessments
Roles: SE Manager, Systems Engineer
Strategies: "SE for managers", "Needs-based project-oriented training"
PMT: Available (JIRA, ISO 26262, Automotive)
```

**PMT Check:**
If selected strategies include "Needs-based project-oriented training" or "Continuous support":
- PMT is REQUIRED
- If not available: Return error "PMT context required"

---

### Step 2: Analyze Each Role

**What it does:**
For each role, calculate current competency levels and classify into scenarios for each strategy.

**Process:**

**For each role:**

1. **Get users in this role**
   ```
   Filter assessments where role_cluster_id = this_role
   ```

2. **For each competency:**

   a. **Calculate current level (median of users in this role)**
   ```python
   user_scores = [user.score for user in users_in_role]
   current_level = median(user_scores)
   ```

   b. **Get role requirement**
   ```sql
   SELECT role_competency_value
   FROM role_competency_matrix
   WHERE role_cluster_id = {role_id}
     AND competency_id = {comp_id}
   ```

   c. **For each selected strategy:**
      - Get archetype target from template
      - Perform 3-way comparison
      - Classify into scenario

**The 4 Scenarios:**

**Scenario A: Normal Training**
- **Condition:** Current < Archetype ≤ Role
- **Meaning:** User needs training, strategy is appropriate
- **Action:** Generate learning objective
- **Example:** Current=2, Archetype=4, Role=6

**Scenario B: Strategy Insufficient**
- **Condition:** Archetype ≤ Current < Role
- **Meaning:** Strategy doesn't reach role requirements
- **Action:** Flag as gap, count users
- **Example:** Current=5, Archetype=4, Role=6

**Scenario C: Over-Training**
- **Condition:** Archetype > Role
- **Meaning:** Strategy exceeds role needs
- **Action:** Flag as potential waste
- **Example:** Current=2, Archetype=6, Role=4

**Scenario D: Targets Achieved**
- **Condition:** Current ≥ Both targets
- **Meaning:** No training needed
- **Action:** Mark as achieved
- **Example:** Current=6, Archetype=4, Role=4

**Example - Decision Management:**
```
Role: SE Manager (2 users)
  User 201: Level 2
  User 202: Level 4
  Current Level (median): 3

Strategy: "SE for managers"
  Archetype Target: 4
  Role Requirement: 6

  Classification:
    Current (3) < Archetype (4) ≤ Role (6)
    → Scenario A (Normal Training)

Output stored:
{
  "role_id": 1,
  "role_name": "SE Manager",
  "competency_11": {
    "current_level": 3,
    "by_strategy": {
      "SE for managers": {
        "archetype_target": 4,
        "role_requirement": 6,
        "scenario": "A"
      }
    }
  }
}
```

**Why "by_strategy" structure?**
Each role-competency pair can have different scenarios for different strategies. Storing by strategy allows comparison later.

---

### Step 3: Aggregate by User Distribution

**What it does:**
Count how many users fall into each scenario for each competency and strategy.

**Why?**
Different roles may have different scenarios. We need to know how many total users are affected.

**Process:**

For each competency and strategy:

1. **Initialize scenario sets** (use sets to handle multi-role users)
   ```python
   scenario_sets = {
       'A': set(),  # User IDs in Scenario A
       'B': set(),  # User IDs in Scenario B
       'C': set(),  # User IDs in Scenario C
       'D': set()   # User IDs in Scenario D
   }
   ```

2. **For each role:**
   ```python
   Get scenario for this role-competency-strategy
   Add all user IDs from this role to appropriate scenario set
   ```

3. **Count unique users** (sets automatically handle duplicates)
   ```python
   scenario_A_count = len(scenario_sets['A'])
   scenario_B_count = len(scenario_sets['B'])
   # etc.
   ```

4. **Calculate percentages**
   ```python
   total_users = sum of all scenario counts
   scenario_A_percentage = (scenario_A_count / total_users) × 100
   ```

**Example - Decision Management:**
```
Strategy: "SE for managers"

Role 1 (SE Manager, 2 users): Scenario A
  → Add users [201, 202] to scenario_sets['A']

Role 2 (Systems Engineer, 3 users): Scenario D
  → Add users [203, 204, 205] to scenario_sets['D']

Result:
  scenario_sets['A'] = {201, 202}
  scenario_sets['D'] = {203, 204, 205}

Counts:
  Scenario A: 2 users (40%)
  Scenario B: 0 users (0%)
  Scenario C: 0 users (0%)
  Scenario D: 3 users (60%)
  Total: 5 users
```

**Output Structure:**
```json
{
  "competency_11": {
    "competency_name": "Decision Management",
    "by_strategy": {
      "SE for managers": {
        "total_users": 5,
        "scenario_A_count": 2,
        "scenario_B_count": 0,
        "scenario_C_count": 0,
        "scenario_D_count": 3,
        "scenario_A_percentage": 40.0,
        "scenario_B_percentage": 0.0,
        "scenario_C_percentage": 0.0,
        "scenario_D_percentage": 60.0,
        "users_by_scenario": {
          "A": [201, 202],
          "D": [203, 204, 205]
        }
      }
    }
  }
}
```

---

### Step 4: Cross-Strategy Coverage (Best-Fit Algorithm)

**What it does:**
For each competency, determine which selected strategy BEST serves the organization.

**Why not just pick highest target?**
- A strategy with target=6 might over-train 90% of users
- A strategy with target=4 might serve 80% perfectly
- Best-fit algorithm balances serving majority vs. minimizing gaps

**The Best-Fit Algorithm:**

**For each competency:**

1. **Calculate fit score for EACH selected strategy**
   ```
   Fit Score = (A% × 1.0) + (D% × 1.0) + (B% × -2.0) + (C% × -0.5)

   Where:
   - A% = Percentage of users in Scenario A (good - need training)
   - D% = Percentage of users in Scenario D (good - already met)
   - B% = Percentage of users in Scenario B (bad - strategy insufficient)
   - C% = Percentage of users in Scenario C (minor issue - over-training)
   ```

2. **Pick strategy with HIGHEST fit score**

3. **Get max role requirement** across all roles for this competency

4. **Check if best-fit strategy is sufficient**
   ```
   If best_fit_target >= max_role_requirement:
       has_real_gap = FALSE
   Else:
       has_real_gap = TRUE
       gap_size = max_role_requirement - best_fit_target
   ```

5. **Get Scenario B from best-fit strategy ONLY**
   ```
   scenario_B_count = best_fit_strategy.scenario_B_count
   scenario_B_percentage = best_fit_strategy.scenario_B_percentage
   ```

6. **Classify gap severity**
   ```
   If scenario_B_percentage > 60%: severity = "critical"
   Else if scenario_B_percentage > 20%: severity = "significant"
   Else if scenario_B_percentage > 0%: severity = "minor"
   Else: severity = "none"
   ```

**Example:**

3 strategies available for Decision Management:

**Strategy A: "SE for managers" (target = 2)**
```
Scenarios: A=25%, B=75%, C=0%, D=0%
Fit Score = (25 × 1.0) + (0 × 1.0) + (75 × -2.0) + (0 × -0.5)
          = 25 + 0 - 150 + 0
          = -125
Normalized = -125 / 100 = -1.25
```

**Strategy B: "Needs-based project-oriented training" (target = 4)**
```
Scenarios: A=70%, B=20%, C=10%, D=0%
Fit Score = (70 × 1.0) + (0 × 1.0) + (20 × -2.0) + (10 × -0.5)
          = 70 + 0 - 40 - 5
          = 25
Normalized = 25 / 100 = +0.25
```

**Strategy C: "Advanced training" (target = 6)**
```
Scenarios: A=12.5%, B=0%, C=87.5%, D=0%
Fit Score = (12.5 × 1.0) + (0 × 1.0) + (0 × -2.0) + (87.5 × -0.5)
          = 12.5 + 0 - 0 - 43.75
          = -31.25
Normalized = -31.25 / 100 = -0.31
```

**Best Fit: Strategy B (+0.25)**

**Max Role Requirement: 6**

**Check Coverage:**
```
Best-fit target (4) >= Max requirement (6)?
NO → has_real_gap = TRUE
gap_size = 6 - 4 = 2
```

**Scenario B from best-fit:**
```
Strategy B has 20% users in Scenario B
20% > 0% and < 20% → severity = "minor"
```

Wait, 20% should be "significant" (20-60%). Let me correct:
```
20% >= 20% → severity = "significant"
```

**Output:**
```json
{
  "competency_11": {
    "competency_name": "Decision Management",
    "max_role_requirement": 6,
    "best_fit_strategy": "Needs-based project-oriented training",
    "best_fit_score": 0.25,
    "all_strategy_fit_scores": {
      "SE for managers": {"fit_score": -1.25, "target_level": 2},
      "Needs-based project-oriented training": {"fit_score": 0.25, "target_level": 4},
      "Advanced training": {"fit_score": -0.31, "target_level": 6}
    },
    "has_real_gap": true,
    "gap_size": 2,
    "scenario_B_count": 8,
    "scenario_B_percentage": 20.0,
    "users_with_real_gap": [15, 16, 17, 18, 19, 20, 21, 22],
    "gap_severity": "significant"
  }
}
```

---

### Step 5: Strategy Validation

**What it does:**
Aggregate gap severities across ALL 16 competencies to determine if selected strategies are adequate.

**Process:**

1. **Categorize all competencies**
   ```python
   For each competency:
       Get gap_severity from Step 4

       If severity == "critical":
           Add to critical_gaps list
       Else if severity == "significant":
           Add to significant_gaps list
       Else if severity == "minor":
           Add to minor_gaps list
       Else:
           Add to well_covered list
   ```

2. **Count competencies with gaps**
   ```python
   total_competencies = 16
   competencies_with_gaps = len(critical_gaps) + len(significant_gaps) + len(minor_gaps)
   ```

3. **Calculate total gap percentage**
   ```python
   gap_percentage = (competencies_with_gaps / 16) × 100
   ```

4. **Determine validation status**
   ```python
   # Critical check first
   If len(critical_gaps) >= 3:
       status = "CRITICAL"
       severity = "critical"
       requires_revision = TRUE

   # Then check gap percentage
   Else if gap_percentage > 40:
       status = "INADEQUATE"
       severity = "high"
       requires_revision = TRUE

   Else if gap_percentage > 20:
       status = "ACCEPTABLE"
       severity = "moderate"
       requires_revision = FALSE

   Else if gap_percentage > 0:
       status = "GOOD"
       severity = "low"
       requires_revision = FALSE

   Else:
       status = "EXCELLENT"
       severity = "none"
       requires_revision = FALSE
   ```

**Example:**
```
Out of 16 competencies:
- Competency 3: 5% gap (minor)
- Competency 11: 25% gap (significant)
- Other 14: 0% gap (well-covered)

Categorization:
  critical_gaps = []
  significant_gaps = [11]
  minor_gaps = [3]
  well_covered = [2, 7, 8, 9, 10, 12, 13, 14, 15, 16]

Calculation:
  competencies_with_gaps = 0 + 1 + 1 = 2
  gap_percentage = (2 / 16) × 100 = 12.5%

Decision:
  len(critical_gaps) >= 3? NO (0 < 3)
  gap_percentage > 40? NO (12.5 < 40)
  gap_percentage > 20? NO (12.5 < 20)
  gap_percentage > 0? YES (12.5 > 0)

  → status = "GOOD"
  → severity = "low"
  → requires_revision = FALSE
```

**Output:**
```json
{
  "status": "GOOD",
  "severity": "low",
  "message": "Minor gaps in 2 competencies, manageable with Phase 3 module selection",
  "gap_percentage": 12.5,
  "competency_breakdown": {
    "critical_gaps": [],
    "significant_gaps": [11],
    "minor_gaps": [3],
    "well_covered": [2, 7, 8, 9, 10, 12, 13, 14, 15, 16]
  },
  "total_users_with_gaps": 8,
  "strategies_adequate": true,
  "requires_strategy_revision": false,
  "recommendation_level": "PROCEED_AS_PLANNED"
}
```

**Validation Thresholds Summary:**

| Gap % | Status | Severity | Requires Revision | Action |
|-------|--------|----------|-------------------|--------|
| 0% | EXCELLENT | none | NO | Proceed as planned |
| 0-20% | GOOD | low | NO | Phase 3 module selection |
| 20-40% | ACCEPTABLE | moderate | NO | Supplementary modules needed |
| >40% | INADEQUATE | high | YES | Must add new strategy |
| 3+ critical | CRITICAL | critical | YES | Urgent strategy revision |

---

### Step 6: Strategic Decisions

**What it does:**
Based on validation results, make holistic recommendations.

**Decision Logic:**

**If status = "EXCELLENT" or "GOOD":**
```python
overall_action = "PROCEED_AS_PLANNED"
overall_message = "Selected strategies are well-aligned with organizational needs"

For each competency with minor or significant gap:
    Add to supplementary_module_guidance:
    {
      "competency_id": comp_id,
      "competency_name": comp_name,
      "guidance": "Select advanced modules during Phase 3 to cover Level X requirements",
      "affected_users": scenario_B_count,
      "current_best_strategy": best_fit_strategy,
      "required_level": max_role_requirement
    }

suggested_strategy_additions = []  # Empty
```

**If status = "ACCEPTABLE":**
```python
overall_action = "PROCEED_WITH_CAUTION"
overall_message = "Some gaps detected. Consider supplementary modules or additional strategy."

Generate supplementary_module_guidance (same as above)

# Optionally suggest complementary strategy
If majority of gaps are in similar domain:
    Suggest strategy that covers those domains
```

**If status = "INADEQUATE" or "CRITICAL":**
```python
overall_action = "REVISE_STRATEGY_SELECTION"
overall_message = "Significant gaps detected. Recommend adding strategies."

# Find which strategy would best fill the gaps
For each available strategy (not yet selected):
    Calculate how many gaps it would fill
    Rank strategies by coverage

Recommend top 1-2 strategies:
suggested_strategy_additions = [
    {
      "strategy_name": recommended_strategy,
      "rationale": "Covers gaps in X, Y, Z competencies",
      "competencies_addressed": [list of IDs],
      "expected_gap_reduction": "X% → Y%",
      "requires_pmt": true/false
    }
]
```

**Example (GOOD status):**
```json
{
  "overall_action": "PROCEED_AS_PLANNED",
  "overall_message": "Selected strategies are well-aligned with organizational needs",

  "per_competency_details": {
    "11": {
      "competency_name": "Decision Management",
      "scenario_B_percentage": 20.0,
      "scenario_B_count": 8,
      "has_real_gap": true,
      "gap_severity": "significant",
      "best_fit_strategy": "Needs-based project-oriented training",
      "max_requirement": 6
    }
  },

  "suggested_strategy_additions": [],

  "supplementary_module_guidance": [
    {
      "competency_id": 11,
      "competency_name": "Decision Management",
      "guidance": "Select advanced modules during Phase 3 to cover Level 6 requirements",
      "affected_users": 8,
      "current_best_strategy": "Needs-based project-oriented training",
      "current_target_level": 4,
      "required_level": 6
    }
  ]
}
```

**Example (INADEQUATE status):**
```json
{
  "overall_action": "REVISE_STRATEGY_SELECTION",
  "overall_message": "Significant gaps detected in 8 competencies (50%). Recommend adding 'Continuous support' strategy.",

  "suggested_strategy_additions": [
    {
      "strategy_name": "Continuous support",
      "rationale": "Covers gaps in Verification, Validation, Testing, and Integration competencies",
      "competencies_addressed": [15, 16, 17, 18],
      "expected_gap_reduction": "50% → 18%",
      "requires_pmt": true,
      "pmt_available": false
    }
  ],

  "supplementary_module_guidance": []
}
```

---

### Step 7: Generate Objectives Structure

**What it does:**
Create the complete output structure with all validation context, ready for text generation.

**Process:**

For each selected strategy:

1. **Initialize structure**
   ```python
   strategy_obj = {
       "strategy_name": strategy.name,
       "priority": "PRIMARY",  # All selected strategies are primary
       "core_competencies": [],
       "trainable_competencies": []
   }
   ```

2. **Add core competencies** (IDs: 1, 4, 5, 6)
   ```python
   For each core competency:
       core_obj = {
           "competency_id": comp_id,
           "competency_name": comp_name,
           "current_level": current_level,
           "target_level": archetype_target,
           "status": "not_directly_trainable",
           "note": "This core competency develops indirectly through training in other competencies."
       }
       Add to core_competencies
   ```

3. **Add trainable competencies**
   ```python
   For each trainable competency (not core):

       # Get data from previous steps
       current_level = from Step 3
       target_level = archetype_target for this strategy
       max_role_requirement = from Step 4
       best_fit_strategy = from Step 4
       scenario_distribution = from Step 3
       gap_severity = from Step 4

       # Calculate gap
       gap = target_level - current_level

       # Determine status
       If gap > 0:
           status = "training_required"

           # Count users requiring training
           users_requiring_training = scenario_A_count + scenario_B_count

           trainable_obj = {
               "competency_id": comp_id,
               "competency_name": comp_name,
               "current_level": current_level,
               "target_level": target_level,
               "max_role_requirement": max_role_requirement,
               "gap": gap,
               "status": status,
               "comparison_type": "3-way",
               "scenario_distribution": {
                   "A": scenario_A_percentage,
                   "B": scenario_B_percentage,
                   "C": scenario_C_percentage,
                   "D": scenario_D_percentage
               },
               "gap_severity": gap_severity,
               "users_requiring_training": users_requiring_training
           }
       Else:
           status = "target_achieved"
           trainable_obj = {
               "competency_id": comp_id,
               "competency_name": comp_name,
               "current_level": current_level,
               "target_level": target_level,
               "gap": 0,
               "status": "target_achieved",
               "note": "Both archetype and role targets achieved. No training needed."
           }

       Add to trainable_competencies
   ```

4. **Store structure**
   ```python
   objectives_structure[strategy.name] = strategy_obj
   ```

**Example Output:**
```json
{
  "SE for managers": {
    "strategy_name": "SE for managers",
    "priority": "PRIMARY",

    "core_competencies": [
      {
        "competency_id": 1,
        "competency_name": "Systems Thinking",
        "current_level": 2,
        "target_level": 4,
        "status": "not_directly_trainable",
        "note": "This core competency develops indirectly through training in other competencies."
      }
    ],

    "trainable_competencies": [
      {
        "competency_id": 11,
        "competency_name": "Decision Management",
        "current_level": 3,
        "target_level": 4,
        "max_role_requirement": 6,
        "gap": 1,
        "status": "training_required",
        "comparison_type": "3-way",
        "scenario_distribution": {
          "A": 40.0,
          "B": 0.0,
          "C": 0.0,
          "D": 60.0
        },
        "gap_severity": "none",
        "users_requiring_training": 2
      },
      {
        "competency_id": 7,
        "competency_name": "Communication",
        "current_level": 4,
        "target_level": 4,
        "gap": 0,
        "status": "target_achieved",
        "note": "Both archetype and role targets achieved. No training needed."
      }
    ]
  }
}
```

---

### Step 8: Generate Learning Objective Text

**What it does:**
Generate the actual SMART-compliant learning objective text for each competency requiring training.

**Two Approaches:**

---

#### Approach 1: Template As-Is (No Customization)

**Used for:**
- SE for managers
- Common basic understanding
- Train the SE-trainer
- Certification archetype
- Advanced technical training (any strategy NOT in deep-customization list)

**Process:**
```python
1. Load template file
2. Get template for competency and target level:
   template = templates[competency_name][str(target_level)]
3. Use template text exactly as-is
4. No LLM involved
5. No PMT customization
```

**Example:**
```
Competency: Decision Management
Target Level: 4

Template Retrieved:
"Participants are able to prepare decisions for their relevant scopes
or make them themselves and document the decision-making process
accordingly."

Output:
{
  "competency_id": 11,
  "learning_objective": "Participants are able to prepare decisions
                         for their relevant scopes or make them
                         themselves and document the decision-making
                         process accordingly.",
  "base_template": "[same as above]"
}
```

---

#### Approach 2: Deep Customization with LLM

**Used for:**
- Needs-based project-oriented training
- Continuous support

**Requirements:**
- PMT context MUST be available
- Template may have PMT breakdown structure

**Process:**

1. **Get template (may have PMT breakdown)**
   ```python
   template_data = templates[competency_name][str(target_level)]

   If template_data is dict:
       base_template = template_data['base_template']
       pmt_breakdown = template_data['pmt_breakdown']
   Else:
       base_template = template_data
       pmt_breakdown = None
   ```

2. **Build LLM prompt**
   ```python
   prompt = f"""
   You are customizing a Systems Engineering learning objective for Phase 2.

   Base Template:
   {base_template}

   Company Context:
   - Tools: {pmt_context.tools}
   - Processes: {pmt_context.processes}
   - Industry: {pmt_context.industry}

   {if pmt_breakdown exists:}
   Expected PMT Coverage:
   - Process: {pmt_breakdown['process']}
   - Method: {pmt_breakdown['method']}
   - Tool: {pmt_breakdown['tool']}

   Instructions (CRITICAL - follow exactly):
   1. KEEP the template structure exactly (do not change sentence structure)
   2. REPLACE generic tool/process names with company-specific ones
   3. DO NOT add timeframes (e.g., "At the end of...")
   4. DO NOT add "so that" benefit statements
   5. DO NOT add "by doing X" demonstration methods
   6. Keep it as a capability statement (what participants can do)
   7. Maximum 2 sentences
   8. If no relevant PMT to add, return the template unchanged

   Example:
   Original: "Participants are able to manage requirements using a
              requirements database."
   Customized: "Participants are able to manage requirements using
                DOORS according to ISO 29148 process."

   Generate the PMT-customized objective (template structure only):
   """
   ```

3. **Call LLM API**
   ```python
   response = openai.ChatCompletion.create(
       model="gpt-4",
       messages=[{"role": "user", "content": prompt}],
       temperature=0.3,
       max_tokens=200
   )

   customized_text = response.choices[0].message.content.strip()
   ```

4. **Validate response**
   ```python
   If not validate_template_structure(customized_text, base_template):
       # LLM added Phase 3 elements or changed structure
       # Fallback to template
       customized_text = base_template
   ```

**Validation Checks:**
```python
def validate_template_structure(customized, original):
    # Check length
    if len(customized) < 30 or len(customized) > 400:
        return False

    # Must have action verbs
    action_verbs = ['able to', 'can', 'will', 'understand',
                    'know', 'apply', 'demonstrate', 'evaluate']
    if not any(verb in customized.lower() for verb in action_verbs):
        return False

    # Must NOT have Phase 3 elements
    phase_3_indicators = [
        'at the end of',
        'so that',
        'in order to',
        'by conducting',
        'by creating',
        'by performing'
    ]
    if any(indicator in customized.lower() for indicator in phase_3_indicators):
        return False  # Reject - added Phase 3 elements

    return True
```

**Example:**
```
Input:
  Base Template: "Participants are able to prepare decisions for
                  their relevant scopes or make them themselves and
                  document the decision-making process accordingly."
  PMT: tools="JIRA, Confluence", processes="ISO 26262"

LLM Output:
  "Participants are able to prepare decisions for their relevant
   scopes using JIRA decision logs and document the decision-making
   process according to ISO 26262 requirements."

Validation: PASS ✓

Final Output:
{
  "competency_id": 11,
  "learning_objective": "Participants are able to prepare decisions
                         for their relevant scopes using JIRA decision
                         logs and document the decision-making process
                         according to ISO 26262 requirements.",
  "base_template": "Participants are able to prepare decisions for
                    their relevant scopes or make them themselves and
                    document the decision-making process accordingly.",
  "pmt_breakdown": {
    "process": "ISO 26262 decision documentation",
    "method": "Trade-off analysis, decision matrices",
    "tool": "JIRA (decision tracking), Confluence (documentation)"
  }
}
```

---

**Calculate Training Priority:**

For each competency requiring training:

```python
def calculate_training_priority(gap, max_role_requirement, scenario_B_percentage):
    # Normalize to 0-10 scale
    gap_score = (gap / 6.0) * 10
    role_score = (max_role_requirement / 6.0) * 10
    urgency_score = (scenario_B_percentage / 100.0) * 10

    # Weighted combination
    priority = (gap_score * 0.4) + (role_score * 0.3) + (urgency_score * 0.3)

    return round(priority, 2)
```

**Example:**
```
Gap: 1 level
Max Role Requirement: 6
Scenario B %: 0%

Calculations:
  gap_score = (1 / 6.0) * 10 = 1.67
  role_score = (6 / 6.0) * 10 = 10.0
  urgency_score = (0 / 100.0) * 10 = 0.0

Priority = (1.67 * 0.4) + (10.0 * 0.3) + (0.0 * 0.3)
         = 0.67 + 3.0 + 0.0
         = 3.67
```

---

**Calculate Summary Statistics:**

For each strategy:

```python
def calculate_strategy_summary(core_comps, trainable_comps):
    requiring_training = [c for c in trainable_comps
                          if c['status'] == 'training_required']
    targets_achieved = [c for c in trainable_comps
                        if c['status'] == 'target_achieved']

    # Average gap
    gaps = [c['gap'] for c in requiring_training]
    avg_gap = sum(gaps) / len(gaps) if gaps else 0

    # Total gap
    total_gap = sum(gaps)

    # Estimate duration (2 weeks per level)
    estimated_weeks = total_gap * 2

    return {
        "total_competencies": len(core_comps) + len(trainable_comps),
        "core_competencies_count": len(core_comps),
        "trainable_competencies_count": len(trainable_comps),
        "competencies_requiring_training": len(requiring_training),
        "competencies_targets_achieved": len(targets_achieved),
        "average_competency_gap": round(avg_gap, 2),
        "total_gap_levels": total_gap,
        "estimated_training_duration_weeks": estimated_weeks,
        "estimated_training_duration_readable":
            f"{estimated_weeks} weeks ({estimated_weeks // 4} months)"
    }
```

---

**Sort by Priority:**

```python
# Sort trainable competencies by priority (highest first)
trainable_comps.sort(key=lambda x: x.get('training_priority', 0), reverse=True)
```

---

**Final Assembly:**

```python
objectives_with_text[strategy_name] = {
    "strategy_name": strategy_name,
    "priority": "PRIMARY",
    "core_competencies": core_comps_with_text,
    "trainable_competencies": trainable_comps_with_text,  # Sorted by priority
    "summary": summary_stats
}
```

**Complete Output Structure:**
```json
{
  "Needs-based project-oriented training": {
    "strategy_name": "Needs-based project-oriented training",
    "priority": "PRIMARY",

    "core_competencies": [...],

    "trainable_competencies": [
      {
        "competency_id": 11,
        "competency_name": "Decision Management",
        "current_level": 3,
        "target_level": 4,
        "max_role_requirement": 6,
        "gap": 1,
        "status": "training_required",
        "training_priority": 3.67,
        "learning_objective": "Participants are able to prepare decisions
                               for their relevant scopes using JIRA decision
                               logs and document the decision-making process
                               according to ISO 26262 requirements.",
        "base_template": "[original template]",
        "pmt_breakdown": {...},
        "comparison_type": "3-way",
        "scenario_distribution": {...},
        "gap_severity": "none",
        "users_requiring_training": 2
      }
    ],

    "summary": {
      "total_competencies": 16,
      "core_competencies_count": 4,
      "trainable_competencies_count": 12,
      "competencies_requiring_training": 8,
      "competencies_targets_achieved": 4,
      "average_competency_gap": 1.6,
      "total_gap_levels": 13,
      "estimated_training_duration_weeks": 26,
      "estimated_training_duration_readable": "26 weeks (6 months)"
    }
  }
}
```

---

## Key Concepts Explained

### 1. Why Median Instead of Average?

**Problem with average:**
```
User 1: Level 0 (new hire, outlier)
User 2: Level 3
User 3: Level 3
User 4: Level 3

Average = (0 + 3 + 3 + 3) / 4 = 2.25
```
The average is pulled down by the outlier, not representative of most users.

**Median:**
```
Sorted: [0, 3, 3, 3]
Median = (3 + 3) / 2 = 3
```
Median correctly reflects the typical user level.

---

### 2. Why 3-Way Comparison?

**In task-based (2-way):**
```
Current vs Archetype Target only
```
Simple but doesn't account for role-specific needs.

**In role-based (3-way):**
```
Current vs Archetype Target vs Role Requirement
```
Identifies situations where:
- Strategy is appropriate (Scenario A)
- Strategy is insufficient for role (Scenario B)
- Strategy over-trains for role (Scenario C)
- No training needed (Scenario D)

---

### 3. What is Scenario B and Why Does it Matter?

**Scenario B:** Users where the selected strategy doesn't reach their role requirements.

**Example:**
```
Role: Senior Systems Engineer
Role Requirement: Level 6

Selected Strategy: "SE for managers"
Archetype Target: Level 4

User's Current Level: 5

Comparison:
  Archetype (4) ≤ Current (5) < Role (6)
  → Scenario B

Problem: User already exceeds the strategy target (4) but hasn't
         reached role requirement (6). Training with this strategy
         won't help them.

Solution: Either select supplementary modules in Phase 3, or add
          a higher-level strategy.
```

**Why it's critical:**
- High Scenario B % (>60%) indicates selected strategies are fundamentally inadequate
- Moderate Scenario B % (20-60%) indicates need for supplementary modules
- Low Scenario B % (<20%) is manageable in Phase 3

---

### 4. Best-Fit vs Highest Target

**Scenario:**
Organization has users at various levels, needs training for Decision Management.

**Available strategies:**
- Strategy A: target=2
- Strategy B: target=4
- Strategy C: target=6

**OLD approach:** Pick Strategy C (highest target=6)

**Result:**
```
Users at Level 2-3: Need training to reach 6 (over-training)
Users at Level 4-5: Need training to reach 6 (appropriate)
Users at Level 6: Already there (no training needed)

Distribution:
  Scenario A: 10% (appropriate)
  Scenario C: 85% (over-training!)
  Scenario D: 5% (already met)

Cost: Massive waste of resources training 85% of users beyond needs
```

**NEW approach (best-fit):** Calculate fit scores

```
Strategy A: (15 * 1) + (0 * 1) + (75 * -2) + (0 * -0.5) = -135
Strategy B: (70 * 1) + (10 * 1) + (15 * -2) + (5 * -0.5) = 47.5
Strategy C: (10 * 1) + (5 * 1) + (0 * -2) + (85 * -0.5) = -27.5

Best: Strategy B (fit score = 47.5)
```

**Result:**
```
Strategy B chosen with target=4
  Scenario A: 70% (appropriate training)
  Scenario B: 15% (some gaps - handle in Phase 3)
  Scenario C: 5% (minor over-training)
  Scenario D: 10% (already met)

Benefit: Serves 70% perfectly, minimal waste, manageable gaps
```

---

### 5. PMT Context - What and Why

**PMT = Processes, Methods, Tools**

**What:**
Company-specific information about how they work.

**Example:**
```json
{
  "processes": "ISO 26262 (automotive safety), V-model for development",
  "methods": "Agile with 2-week sprints, Requirements traceability",
  "tools": "DOORS (requirements), JIRA (project management), SysML (modeling)",
  "industry": "Automotive embedded systems",
  "additional_context": "Focus on ADAS and autonomous driving"
}
```

**Why needed:**
Makes learning objectives specific to the company instead of generic.

**Example transformation:**

**Generic template:**
```
"Participants are able to manage requirements using a requirements
management tool."
```

**With PMT customization:**
```
"Participants are able to manage requirements using DOORS according
to ISO 29148 process for automotive ADAS systems."
```

**When required:**
Only for these 2 strategies:
1. Needs-based project-oriented training
2. Continuous support

**Phase 2 vs Phase 3:**
- Phase 2: Only PMT references (tool/process names)
- Phase 3: Full SMART (+ timeframes, demonstrations, benefits)

---

### 6. Validation Status Meanings

**EXCELLENT (0% gaps):**
- All selected strategies perfectly cover all competencies
- No action needed
- Proceed to Phase 3

**GOOD (0-20% gaps):**
- Tiny gaps in 1-3 competencies
- Affecting very few users
- Action: Normal Phase 3 module selection (standard catalog handles it)

**ACCEPTABLE (20-40% gaps):**
- Notable gaps in 4-6 competencies
- Some competencies have significant Scenario B %
- Action: Deliberately select advanced/supplementary modules in Phase 3

**INADEQUATE (>40% gaps):**
- Major gaps in 7+ competencies
- Selected strategies fundamentally insufficient
- Action: MUST add new strategy (go back to Phase 1)

**CRITICAL (3+ competencies with >60% Scenario B):**
- Systematic failure across multiple competencies
- Most users not covered by strategies
- Action: Urgent strategy revision required

---

## Complete Examples

### Task-Based Example

**Organization:** Small SE consulting firm
**Maturity Level:** 2 (Managed)
**Users:** 3
**Roles:** None defined (all "unknown_roles")
**Strategy:** "Common basic understanding"

**Step 1:** Get assessments
```
User 101: Completed Nov 1
User 102: Completed Nov 3
User 103: Completed Nov 2
```

**Step 2:** Get strategy
```
Strategy: "Common basic understanding"
```

**Step 3:** Calculate current levels
```
Decision Management (Competency 11):
  User 101: 0
  User 102: 1
  User 103: 2

  Median: 1
```

**Step 4:** Compare
```
Current: 1
Target: 2
Gap: 1
Status: training_required
```

**Step 5:** Generate objective
```
Template for Level 2:
"Participants learn about decision support methods such as trade
studies and can apply simple decision matrices."
```

**Output:**
```json
{
  "pathway": "TASK_BASED",
  "organization_id": 15,
  "total_users_assessed": 3,
  "aggregation_method": "median",
  "learning_objectives_by_strategy": {
    "Common basic understanding": {
      "trainable_competencies": [
        {
          "competency_id": 11,
          "competency_name": "Decision Management",
          "current_level": 1,
          "target_level": 2,
          "gap": 1,
          "status": "training_required",
          "learning_objective": "Participants learn about decision support
                                 methods such as trade studies and can
                                 apply simple decision matrices."
        }
      ]
    }
  }
}
```

---

### Role-Based Complete Example

**Organization:** TechCorp Systems GmbH
**Maturity Level:** 4 (Quantitatively Managed)
**Users:** 5
**Roles:** SE Manager (2 users), Systems Engineer (3 users)
**Strategies:** "SE for managers", "Needs-based project-oriented training"
**PMT:** Available (JIRA, ISO 26262, Automotive)

---

**Step 1:** Get data
```
Users:
  201, 202: SE Manager
  203, 204, 205: Systems Engineer

Strategies:
  "SE for managers"
  "Needs-based project-oriented training"

PMT: {tools: "JIRA, DOORS", processes: "ISO 26262"}
```

---

**Step 2:** Analyze roles

**Decision Management (Competency 11):**

**Role 1: SE Manager**
```
Users: 201 (Level 2), 202 (Level 4)
Current (median): 3

Strategy "SE for managers":
  Archetype: 4
  Role Req: 6
  Scenario: Current(3) < Arch(4) ≤ Role(6) → A
```

**Role 2: Systems Engineer**
```
Users: 203, 204, 205 (all Level 4)
Current (median): 4

Strategy "SE for managers":
  Archetype: 4
  Role Req: 4
  Scenario: Current(4) >= Both → D
```

---

**Step 3:** Aggregate

**Strategy "SE for managers":**
```
Scenario A: Users [201, 202] = 2 users (40%)
Scenario D: Users [203, 204, 205] = 3 users (60%)
Total: 5 users
```

---

**Step 4:** Best-fit

**Calculate fit score:**
```
Fit = (40 * 1) + (60 * 1) + (0 * -2) + (0 * -0.5)
    = 40 + 60 = 100

Normalized: 100 / 100 = 1.0
```

**Max role requirement:** 6

**Coverage check:**
```
Best-fit target (4) >= Max req (6)? NO
has_real_gap = TRUE, but...
Scenario B = 0%
Gap severity: none
```

---

**Step 5:** Validation

**All 16 competencies:**
```
Gaps found: 0 competencies
Gap %: 0%

Status: EXCELLENT
```

---

**Step 6:** Decisions
```
Action: PROCEED_AS_PLANNED
Message: "Selected strategies perfectly aligned"
Recommendations: None
```

---

**Step 7:** Structure
```json
{
  "SE for managers": {
    "trainable_competencies": [
      {
        "competency_id": 11,
        "current_level": 3,
        "target_level": 4,
        "gap": 1,
        "status": "training_required",
        "users_requiring_training": 2
      }
    ]
  }
}
```

---

**Step 8:** Text generation

**For "SE for managers"** (no customization):
```
Template: "Participants are able to prepare decisions for their
           relevant scopes or make them themselves and document
           the decision-making process accordingly."

Output: [same as template]
Priority: 3.67
```

**For "Needs-based project"** (deep customization):
```
Template: [same as above]
PMT: JIRA, ISO 26262

LLM Output: "Participants are able to prepare decisions for their
             relevant scopes using JIRA decision logs and document
             the decision-making process according to ISO 26262
             requirements."

Priority: 3.67
```

---

**Final Output:**
```json
{
  "pathway": "ROLE_BASED",
  "organization_id": 28,
  "strategy_validation": {
    "status": "EXCELLENT",
    "gap_percentage": 0
  },
  "learning_objectives_by_strategy": {
    "SE for managers": {
      "trainable_competencies": [
        {
          "competency_id": 11,
          "learning_objective": "Participants are able to prepare
                                 decisions for their relevant scopes
                                 or make them themselves and document
                                 the decision-making process accordingly.",
          "training_priority": 3.67
        }
      ]
    },
    "Needs-based project-oriented training": {
      "trainable_competencies": [
        {
          "competency_id": 11,
          "learning_objective": "Participants are able to prepare
                                 decisions for their relevant scopes
                                 using JIRA decision logs and document
                                 the decision-making process according
                                 to ISO 26262 requirements.",
          "training_priority": 3.67,
          "pmt_breakdown": {
            "process": "ISO 26262 decision documentation",
            "tool": "JIRA (decision tracking)"
          }
        }
      ]
    }
  }
}
```

---

*End of Step-by-Step Guide*
*For visual flowcharts, see: LEARNING_OBJECTIVES_ALGORITHM_SUMMARY.md*
*For complete specification, see: LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md*
