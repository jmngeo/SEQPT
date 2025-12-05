# Learning Objectives Generation - Flowcharts & Data Flow (v4.1)
**Date**: November 4, 2025
**Purpose**: Visual representation of complete algorithm with example data at each step

---

## Table of Contents
1. [High-Level Overview](#high-level-overview)
2. [Pathway Decision Flow](#pathway-decision-flow)
3. [Task-Based Pathway (Detailed)](#task-based-pathway-detailed)
4. [Role-Based Pathway (Detailed)](#role-based-pathway-detailed)
5. [Step-by-Step Data Flow](#step-by-step-data-flow)
6. [PMT Context Decision Flow](#pmt-context-decision-flow)
7. [Cross-Strategy Coverage Logic](#cross-strategy-coverage-logic)
8. [Validation Decision Tree](#validation-decision-tree)

---

## High-Level Overview

```mermaid
graph TB
    Start([Admin: Generate Learning Objectives])
    Confirm{Admin Confirms:<br/>All Users Assessed?}
    PathCheck{Organization<br/>Has Roles?}
    TaskPath[Task-Based Pathway<br/>2-Way Comparison]
    RolePath[Role-Based Pathway<br/>3-Way Comparison + Validation]
    Output[Learning Objectives Generated]

    Start --> Confirm
    Confirm -->|No| Wait[Wait for Assessments]
    Wait --> Start
    Confirm -->|Yes| PathCheck
    PathCheck -->|No Roles<br/>Low Maturity| TaskPath
    PathCheck -->|Has Roles<br/>High Maturity| RolePath
    TaskPath --> Output
    RolePath --> Output

    style Start fill:#e1f5ff
    style Output fill:#c8e6c9
    style TaskPath fill:#fff9c4
    style RolePath fill:#ffccbc
```

**Key Decision**: Organization maturity determines pathway
- **Low Maturity**: No SE roles defined → Simple 2-way comparison
- **High Maturity**: Defined roles → Complex validation with 8 steps

---

## Pathway Decision Flow

```mermaid
graph TB
    A[Start: generate_learning_objectives org_id=28]
    B[Get Maturity Level<br/>from Phase 1 Assessment]
    C{maturity_level >= 3?<br/>MATURITY_THRESHOLD}
    D[Pathway: TASK_BASED<br/>Low Maturity]
    E[Pathway: ROLE_BASED<br/>High Maturity]
    F[Call: generate_task_based_objectives]
    G[Call: generate_role_based_objectives]
    H[Return: Learning Objectives]

    A --> B
    B --> C
    C -->|No, < 3| D
    C -->|Yes, >= 3| E
    D --> F
    E --> G
    F --> H
    G --> H

    style A fill:#e1f5ff
    style D fill:#fff9c4
    style E fill:#ffccbc
    style H fill:#c8e6c9
```

**Example Data**:
```python
# Input
org_id = 28

# Phase 1 Maturity Assessment
response = get('/api/phase1/maturity/28/latest')
maturity_level = response.data.results.strategyInputs.seProcessesValue
# maturity_level = 4

# Decision Logic (from Phase2TaskFlowContainer.vue:103)
MATURITY_THRESHOLD = 3
pathway = "ROLE_BASED" if maturity_level >= 3 else "TASK_BASED"

# Result
pathway = "ROLE_BASED"  # Because 4 >= 3
```

**Implementation Reference**:
- **Frontend**: `Phase2TaskFlowContainer.vue:103-109` determines pathway
- **Maturity Fetch**: `PhaseTwo.vue:114-121` fetches from Phase 1
- **Threshold**: `MATURITY_THRESHOLD = 3` (consistent with RoleIdentification.vue:146)

---

## Task-Based Pathway (Detailed)

```mermaid
graph TB
    A[Start: generate_task_based_objectives<br/>org_id=28]
    B[Step 1: Get Latest Assessments<br/>Survey Type: unknown_roles]
    C[Step 2: Get Selected Strategies]
    D[For Each Strategy Loop]
    E[For Each Competency Loop]
    F{Is Core<br/>Competency?<br/>IDs: 1,4,5,6}
    G[Add to Core List<br/>with note]
    H[Calculate Median<br/>Current Level]
    I[Get Archetype Target<br/>from Strategy]
    J{Current < Target?}
    K[Get Template<br/>No Customization]
    L[Add to Trainable<br/>Status: training_required]
    M[Add to Trainable<br/>Status: target_achieved]
    N[Return Objectives<br/>by Strategy]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F -->|Yes| G
    G --> E
    F -->|No| H
    H --> I
    I --> J
    J -->|Yes| K
    K --> L
    L --> E
    J -->|No| M
    M --> E
    E -->|All Done| D
    D -->|All Done| N

    style A fill:#e1f5ff
    style F fill:#ffe082
    style J fill:#ffe082
    style N fill:#c8e6c9
```

**Example Data Flow**:

### Input (Step 1-2):
```json
{
  "org_id": 28,
  "user_assessments": [
    {"user_id": 1, "competency_11_score": 2},
    {"user_id": 2, "competency_11_score": 2},
    {"user_id": 3, "competency_11_score": 3}
  ],
  "selected_strategies": ["SE for managers"]
}
```

### Processing (Step 3-5):
```python
# For Competency 11 (Decision Management)
current_scores = [2, 2, 3]
current_level = median([2, 2, 3]) = 2

archetype_target = 4  # From "SE for managers"

# Comparison
gap = 4 - 2 = 2  # Training needed
```

### Output:
```json
{
  "pathway": "TASK_BASED",
  "learning_objectives_by_strategy": {
    "SE for managers": {
      "trainable_competencies": [
        {
          "competency_id": 11,
          "competency_name": "Decision Management",
          "current_level": 2,
          "target_level": 4,
          "gap": 2,
          "status": "training_required",
          "learning_objective": "Participants are able to prepare decisions for their relevant scopes..."
        }
      ]
    }
  }
}
```

---

## Role-Based Pathway (Detailed)

```mermaid
graph TB
    A[Start: generate_role_based_objectives<br/>org_id=28]
    B[Step 1: Get Data<br/>Assessments + Roles + Strategies]
    C[Step 2: Analyze All Roles<br/>Per-Strategy Scenario Classification]
    D[Step 3: Aggregate by User Distribution<br/>Count Users per Scenario per Strategy]
    E[Step 4: Cross-Strategy Coverage<br/>Check if Multiple Strategies Cover Gaps]
    F[Step 5: Strategy Validation<br/>Aggregate Scenario B Across Competencies]
    G[Step 6: Strategic Decisions<br/>Holistic Recommendations]
    H[Step 7: Generate Objectives Structure<br/>With Validation Context]
    I[Step 8: Generate Objective Text<br/>PMT Customization if Needed]
    J{PMT Available<br/>& Deep Strategy?}
    K[LLM Deep Customize<br/>PMT-only]
    L[Use Template As-Is<br/>No Customization]
    M[Calculate Priorities<br/>& Statistics]
    N[Return Complete<br/>Learning Objectives]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J -->|Yes| K
    J -->|No| L
    K --> M
    L --> M
    M --> N

    style A fill:#e1f5ff
    style C fill:#ffccbc
    style D fill:#ffccbc
    style E fill:#ce93d8
    style F fill:#ce93d8
    style G fill:#ce93d8
    style I fill:#fff9c4
    style N fill:#c8e6c9
```

**Legend**:
- 🔵 Blue: Start/End
- 🟠 Orange: Role Analysis (Steps 2-3)
- 🟣 Purple: Validation Layer (Steps 4-6)
- 🟡 Yellow: Text Generation (Step 8)
- 🟢 Green: Output

---

## Step-by-Step Data Flow

### Step 1: Get Data

```mermaid
graph LR
    A[Input: org_id=28]
    B[Query: Latest Assessments]
    C[Query: Organization Roles]
    D[Query: Selected Strategies]
    E[Output: Combined Data]

    A --> B
    A --> C
    A --> D
    B --> E
    C --> E
    D --> E
```

**Example Data**:
```python
# Input
org_id = 28

# Output
{
  "user_assessments": [
    {
      "user_id": 1,
      "selected_roles": [1, 2],  # Multi-role user
      "competency_scores": {"11": 2, "7": 3, ...}
    },
    {
      "user_id": 2,
      "selected_roles": [1],
      "competency_scores": {"11": 2, "7": 4, ...}
    }
  ],
  "organization_roles": [
    {"id": 1, "name": "Software Engineer"},
    {"id": 2, "name": "System Architect"},
    {"id": 3, "name": "Project Manager"}
  ],
  "selected_strategies": [
    {"name": "Needs-based project-oriented training"},
    {"name": "SE for managers"}
  ]
}
```

---

### Step 2: Analyze All Roles

```mermaid
graph TB
    A[For Each Role]
    B[Get Users in This Role]
    C[For Each Competency]
    D[Calculate Median<br/>Current Level for Role]
    E[Get Role Requirement<br/>from Matrix]
    F[For Each Strategy]
    G[Get Archetype Target]
    H[3-Way Comparison<br/>classify_gap_scenario]
    I{Current < Archetype ≤ Role?}
    J{Archetype ≤ Current < Role?}
    K{Archetype > Role?}
    L[Scenario A<br/>Normal Training]
    M[Scenario B<br/>Strategy Insufficient]
    N[Scenario C<br/>Over-Training]
    O[Scenario D<br/>Targets Met]
    P[Store in by_strategy]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I -->|Yes| L
    I -->|No| J
    J -->|Yes| M
    J -->|No| K
    K -->|Yes| N
    K -->|No| O
    L --> P
    M --> P
    N --> P
    O --> P
    P --> F
    F -->|Next Strategy| G
    F -->|Done| C
    C -->|Next Competency| D
    C -->|Done| A

    style L fill:#c8e6c9
    style M fill:#ffcdd2
    style N fill:#fff9c4
    style O fill:#b3e5fc
```

**Example Data**:

**Input**:
```python
role_id = 1  # Software Engineer
users_in_role = [User(1), User(2), User(3)]
competency_id = 11  # Decision Management
strategy = "Needs-based project-oriented training"
```

**Processing**:
```python
# User scores for competency 11
user_scores = [2, 2, 3]
current_level = median([2, 2, 3]) = 2

# Role requirement
role_requirement = 6  # Software Engineer needs level 6

# Archetype target
archetype_target = 4  # From strategy

# 3-Way Comparison
current = 2
archetype = 4
role = 6

# Check: current < archetype <= role?
# 2 < 4 <= 6? YES → Scenario A
```

**Output**:
```json
{
  "role_analyses": {
    "1": {  // Role ID
      "role_name": "Software Engineer",
      "user_count": 3,
      "competencies": {
        "11": {  // Competency ID
          "current_level": 2,
          "role_requirement": 6,
          "user_ids": [1, 2, 3],
          "by_strategy": {
            "Needs-based project-oriented training": {
              "archetype_target": 4,
              "scenario": "A"
            },
            "SE for managers": {
              "archetype_target": 2,
              "scenario": "D"  // Already achieved
            }
          }
        }
      }
    }
  }
}
```

---

### Step 3: Aggregate by User Distribution

```mermaid
graph TB
    A[For Each Competency]
    B[For Each Strategy]
    C[Initialize Scenario Sets<br/>A, B, C, D = empty sets]
    D[For Each Role]
    E[Get Scenario for<br/>This Role-Strategy]
    F[Add User IDs to<br/>Scenario Set]
    G[Count Unique Users<br/>per Scenario]
    H[Calculate Percentages]
    I[Store Distribution]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> D
    D -->|All Roles Done| G
    G --> H
    H --> I
    I --> B
    B -->|Next Strategy| C
    B -->|Done| A

    style C fill:#e1f5ff
    style F fill:#fff9c4
    style G fill:#ffccbc
```

**Example Data**:

**Input** (from Step 2):
```python
competency_id = 11
strategy = "Needs-based project-oriented training"

# From role analyses
Role 1 (Software Engineer, 5 users): Scenario A
Role 2 (System Architect, 3 users): Scenario A
Role 3 (Project Manager, 2 users): Scenario D
```

**Processing**:
```python
# Aggregate users by scenario
scenario_sets = {
    'A': {1, 2, 3, 4, 5, 6, 7, 8},  # 8 users from roles 1 & 2
    'B': set(),                      # 0 users
    'C': set(),                      # 0 users
    'D': {9, 10}                     # 2 users from role 3
}

total_users = 10
percentages = {
    'A': 80.0,  # 8/10
    'B': 0.0,
    'C': 0.0,
    'D': 20.0   # 2/10
}
```

**Output**:
```json
{
  "competency_scenario_distributions": {
    "11": {
      "competency_name": "Decision Management",
      "by_strategy": {
        "Needs-based project-oriented training": {
          "total_users": 10,
          "scenario_A_count": 8,
          "scenario_B_count": 0,
          "scenario_C_count": 0,
          "scenario_D_count": 2,
          "scenario_A_percentage": 80.0,
          "scenario_B_percentage": 0.0,
          "scenario_C_percentage": 0.0,
          "scenario_D_percentage": 20.0,
          "users_by_scenario": {
            "A": [1,2,3,4,5,6,7,8],
            "B": [],
            "C": [],
            "D": [9,10]
          }
        }
      }
    }
  }
}
```

---

### Step 4: Cross-Strategy Coverage Check (BEST-FIT ALGORITHM)

**CRITICAL**: Don't just pick highest target! Pick strategy that best fits organization.

```mermaid
graph TB
    A[For Each Competency]
    B[For Each Strategy]
    C[Count Users by Scenario<br/>A, B, C, D]
    D[Calculate Fit Score<br/>A×1 + D×1 + B×-2 + C×-0.5]
    E[Normalize Score<br/>÷ total users]
    F[Store Fit Score]
    G{All Strategies<br/>Evaluated?}
    H[Pick Strategy with<br/>HIGHEST FIT SCORE]
    I[Get Max Role Requirement]
    J{Best-Fit Target<br/>>= Requirement?}
    K[has_real_gap = FALSE<br/>Strategy sufficient!]
    L[has_real_gap = TRUE<br/>Gap exists]
    M[Get Scenario B from<br/>Best-Fit Strategy]
    N[Classify Gap Severity]
    O[Store Coverage Data<br/>with All Fit Scores]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G -->|No| B
    G -->|Yes| H
    H --> I
    I --> J
    J -->|Yes| K
    J -->|No| L
    K --> M
    L --> M
    M --> N
    N --> O
    O --> A

    style H fill:#fff9c4
    style D fill:#ffccbc
    style J fill:#ffe082
    style K fill:#c8e6c9
    style L fill:#ffcdd2
```

**Example Data**:

**Input**:
```python
competency_id = 11
selected_strategies = [
  {"name": "Needs-based project", "target": 4},
  {"name": "SE for managers", "target": 2},
  {"name": "Advanced training", "target": 6}
]
max_role_requirement = 6
total_users = 40
```

**Processing - Calculate Fit Scores**:
```python
# Strategy 1: "Needs-based project" (target 4)
scenario_counts = {"A": 28, "B": 8, "C": 4, "D": 0}
fit_score = (28×1.0 + 0×1.0 + 8×-2.0 + 4×-0.5) / 40
fit_score = (28 + 0 - 16 - 2) / 40 = 10/40 = +0.25 ✅ BEST!

# Strategy 2: "SE for managers" (target 2)
scenario_counts = {"A": 10, "B": 30, "C": 0, "D": 0}
fit_score = (10×1.0 + 0×1.0 + 30×-2.0 + 0×-0.5) / 40
fit_score = (10 + 0 - 60 - 0) / 40 = -50/40 = -1.25 ❌ TOO LOW

# Strategy 3: "Advanced training" (target 6)
scenario_counts = {"A": 5, "B": 0, "C": 35, "D": 0}
fit_score = (5×1.0 + 0×1.0 + 0×-2.0 + 35×-0.5) / 40
fit_score = (5 + 0 - 0 - 17.5) / 40 = -12.5/40 = -0.31 ❌ OVER-TRAINING!

# Pick best: "Needs-based project" (score +0.25)
# Even though "Advanced training" reaches requirement (6),
# it over-trains 87.5% of users!
```

**Key Insight**:
- OLD logic would pick "Advanced training" (highest target = 6)
- NEW logic picks "Needs-based project" (best fit = +0.25)
- Result: Serve 70% perfectly (Scenario A), avoid massive over-training

**Output**:
```json
{
  "cross_strategy_coverage": {
    "11": {
      "competency_name": "Decision Management",
      "max_role_requirement": 6,
      "best_fit_strategy": "Needs-based project",
      "best_fit_score": 0.25,
      "all_strategy_fit_scores": {
        "Needs-based project": {
          "fit_score": 0.25,
          "scenario_counts": {"A": 28, "B": 8, "C": 4, "D": 0},
          "scenario_A_percentage": 70.0,
          "scenario_B_percentage": 20.0,
          "scenario_C_percentage": 10.0,
          "target_level": 4,
          "total_users": 40
        },
        "SE for managers": {
          "fit_score": -1.25,
          "scenario_counts": {"A": 10, "B": 30, "C": 0, "D": 0},
          "scenario_A_percentage": 25.0,
          "scenario_B_percentage": 75.0,
          "target_level": 2,
          "total_users": 40
        },
        "Advanced training": {
          "fit_score": -0.31,
          "scenario_counts": {"A": 5, "B": 0, "C": 35, "D": 0},
          "scenario_A_percentage": 12.5,
          "scenario_C_percentage": 87.5,
          "target_level": 6,
          "total_users": 40
        }
      },
      "has_real_gap": true,
      "gap_size": 2,
      "scenario_B_count": 8,
      "scenario_B_percentage": 30.0,
      "users_with_real_gap": [15, 16, 17],
      "gap_severity": "significant"
    }
  }
}
```

---

### Step 5: Strategy-Level Validation

```mermaid
graph TB
    A[Categorize All Competencies]
    B[For Each Competency<br/>Check gap_severity]
    C{Severity?}
    D[Add to critical_gaps<br/>scenario_B > 60%]
    E[Add to significant_gaps<br/>scenario_B 20-60%]
    F[Add to minor_gaps<br/>scenario_B < 20%]
    G[Add to well_covered]
    H[Calculate Total Gaps]
    I[Calculate Gap Percentage]
    J{Critical >= 3<br/>OR Gap % > 40?}
    K[Status: CRITICAL/INADEQUATE<br/>requires_strategy_revision = TRUE]
    L{Gap % > 20?}
    M[Status: ACCEPTABLE<br/>requires_revision = FALSE]
    N{Gap % > 0?}
    O[Status: GOOD<br/>strategies_adequate = TRUE]
    P[Status: EXCELLENT<br/>strategies_adequate = TRUE]
    Q[Return Validation Results]

    A --> B
    B --> C
    C -->|critical| D
    C -->|significant| E
    C -->|minor| F
    C -->|none| G
    D --> B
    E --> B
    F --> B
    G --> B
    B -->|All Done| H
    H --> I
    I --> J
    J -->|Yes| K
    J -->|No| L
    L -->|Yes| M
    L -->|No| N
    N -->|Yes| O
    N -->|No| P
    K --> Q
    M --> Q
    O --> Q
    P --> Q

    style K fill:#ffcdd2
    style M fill:#fff9c4
    style O fill:#c8e6c9
    style P fill:#a5d6a7
```

**Example Data**:

**Input** (from Step 4):
```python
# Gap severities for all 16 competencies
cross_strategy_coverage = {
  11: {"gap_severity": "significant"},
  15: {"gap_severity": "minor"},
  7: {"gap_severity": "none"},
  10: {"gap_severity": "none"},
  # ... rest
}
```

**Processing**:
```python
# Categorize
critical_gaps = []              # None with >60%
significant_gaps = [11]         # 1 competency
minor_gaps = [15]               # 1 competency
well_covered = [7, 10, ...]     # 14 competencies

# Metrics
total_competencies = 16
total_gaps = 0 + 1 + 1 = 2
gap_percentage = 2/16 * 100 = 12.5%

# Decision
critical_count = 0
gap_percentage = 12.5

# Check: critical >= 3 OR gap% > 40? NO
# Check: gap% > 20? NO
# Check: gap% > 0? YES
status = "GOOD"
```

**Output**:
```json
{
  "strategy_validation": {
    "status": "GOOD",
    "severity": "low",
    "message": "Minor gaps in 2 competencies, manageable with Phase 3 module selection",
    "gap_percentage": 12.5,
    "competency_breakdown": {
      "critical_gaps": [],
      "significant_gaps": [11],
      "minor_gaps": [15],
      "over_training": [],
      "well_covered": [2,3,7,8,9,10,12,13,14,16]
    },
    "total_users_with_gaps": 8,
    "strategies_adequate": true,
    "requires_strategy_revision": false,
    "recommendation_level": "PROCEED_AS_PLANNED"
  }
}
```

---

### Step 6: Strategic Decisions

```mermaid
graph TB
    A[Check Validation Status]
    B{strategies_adequate?}
    C[overall_action =<br/>PROCEED_AS_PLANNED]
    D{requires_revision?}
    E[overall_action =<br/>ADD_STRATEGY]
    F[overall_action =<br/>SUPPLEMENTARY_MODULES]
    G[Find Best Strategy<br/>to Fill Gaps]
    H[Create Module Guidance<br/>for Minor Gaps]
    I[Compile Per-Competency Details]
    J[Return Recommendations]

    A --> B
    B -->|Yes| C
    B -->|No| D
    C --> H
    D -->|Yes| E
    D -->|No| F
    E --> G
    F --> H
    G --> I
    H --> I
    I --> J

    style C fill:#c8e6c9
    style E fill:#ffcdd2
    style F fill:#fff9c4
```

**Example Data**:

**Input**:
```python
strategy_validation = {
  "strategies_adequate": True,
  "requires_strategy_revision": False,
  "gap_percentage": 12.5,
  "competency_breakdown": {
    "minor_gaps": [11, 15]
  }
}
```

**Processing**:
```python
# Decision logic
if strategies_adequate:  # True
    action = "PROCEED_AS_PLANNED"

    # Generate guidance for minor gaps
    for comp_id in minor_gaps:
        guidance.append({
            "competency_id": comp_id,
            "guidance": "Select advanced modules during Phase 3",
            "affected_users": scenario_B_count
        })
```

**Output**:
```json
{
  "strategic_decisions": {
    "overall_action": "PROCEED_AS_PLANNED",
    "overall_message": "Selected strategies are well-aligned with organizational needs",
    "per_competency_details": {
      "11": {
        "competency_name": "Decision Management",
        "scenario_B_percentage": 30.0,
        "scenario_B_count": 3,
        "has_real_gap": true,
        "gap_severity": "significant",
        "best_covering_strategy": "Needs-based project",
        "max_coverage": 4,
        "max_requirement": 6
      }
    },
    "suggested_strategy_additions": [],
    "supplementary_module_guidance": [
      {
        "competency_id": 11,
        "competency_name": "Decision Management",
        "guidance": "Select advanced modules during Phase 3",
        "affected_users": 3
      }
    ]
  }
}
```

---

### Step 8: Generate Objective Text

```mermaid
graph TB
    A[For Each Strategy]
    B[For Each Competency]
    C{Is Core<br/>Competency?}
    D[Get Template<br/>Add Note]
    E{Status =<br/>target_achieved?}
    F[Skip Text Generation]
    G[Get Template<br/>Full Data]
    H{Strategy Needs<br/>Deep Customization?<br/>AND PMT Available?}
    I[LLM Deep Customize<br/>PMT-only]
    J[Use Template As-Is]
    K[Calculate Priority<br/>Multi-factor Formula]
    L[Calculate Summary Stats]
    M[Return Objectives<br/>with Text]

    A --> B
    B --> C
    C -->|Yes| D
    D --> B
    C -->|No| E
    E -->|Yes| F
    F --> B
    E -->|No| G
    G --> H
    H -->|Yes| I
    H -->|No| J
    I --> K
    J --> K
    K --> B
    B -->|All Done| L
    L --> A
    A -->|All Done| M

    style I fill:#ffccbc
    style J fill:#c8e6c9
```

**Example Data**:

**Input**:
```python
competency_id = 11
strategy = "Needs-based project-oriented training"
current_level = 2
target_level = 4
max_role_requirement = 6
gap = 2
scenario_B_percentage = 30.0

# PMT Context (available)
pmt_context = {
  "tools": "JIRA, Confluence",
  "processes": "ISO 26262",
  "industry": "Automotive"
}

# Template
template = "Participants are able to prepare decisions for their relevant scopes or make them themselves and document the decision-making process accordingly."

# Strategy requires deep customization?
requires_deep = True  # "Needs-based project" is in deep list
```

**Processing**:
```python
# LLM Prompt (simplified)
prompt = """
Base Template: {template}
Company Context:
- Tools: JIRA, Confluence
- Processes: ISO 26262

Instructions:
1. KEEP template structure
2. REPLACE generic tool/process names with company-specific
3. DO NOT add timeframes, benefits, demonstrations

Generate PMT-customized objective:
"""

# LLM Response
customized = "Participants are able to prepare decisions for their relevant scopes using JIRA decision logs and document the decision-making process according to ISO 26262 requirements."

# Calculate Priority
priority = (gap * 0.4) + (max_role_req * 0.3) + (scenario_B% * 0.3)
priority = (2 * 0.4) + (6 * 0.3) + (30 * 0.3)
priority = 0.8 + 1.8 + 9.0 = 11.6
# Normalized to 0-10 scale
priority = 4.25
```

**Output**:
```json
{
  "learning_objectives_by_strategy": {
    "Needs-based project-oriented training": {
      "strategy_name": "Needs-based project-oriented training",
      "priority": "PRIMARY",
      "trainable_competencies": [
        {
          "competency_id": 11,
          "competency_name": "Decision Management",
          "current_level": 2,
          "target_level": 4,
          "max_role_requirement": 6,
          "gap": 2,
          "status": "training_required",
          "training_priority": 4.25,
          "learning_objective": "Participants are able to prepare decisions for their relevant scopes using JIRA decision logs and document the decision-making process according to ISO 26262 requirements.",
          "base_template": "Participants are able to prepare decisions for their relevant scopes or make them themselves and document the decision-making process accordingly.",
          "comparison_type": "3-way",
          "scenario_distribution": {
            "A": 70.0,
            "B": 30.0,
            "C": 0.0,
            "D": 0.0
          },
          "gap_severity": "significant",
          "users_requiring_training": 10
        }
      ],
      "summary": {
        "total_competencies": 16,
        "competencies_requiring_training": 8,
        "average_competency_gap": 1.6,
        "estimated_training_duration_weeks": 26
      }
    }
  }
}
```

---

## PMT Context Decision Flow

```mermaid
graph TB
    A{Organization Has<br/>Selected Strategies?}
    B[Check Strategy Names]
    C{Any Strategy in:<br/>- Needs-based project<br/>- Continuous support}
    D[PMT Required = TRUE<br/>Show PMT Form]
    E[PMT Required = FALSE<br/>PMT Optional]
    F{Validation Recommends<br/>New Strategy?}
    G[Check Recommended Strategy]
    H{Recommended in:<br/>- Needs-based project<br/>- Continuous support}
    I[Request PMT Before<br/>Adding Strategy]
    J[Add Strategy<br/>No PMT Needed]
    K{Text Generation:<br/>Deep Customization<br/>Strategy?}
    L[Use PMT for<br/>LLM Customization]
    M[Use Template As-Is<br/>No PMT Needed]

    A -->|Yes| B
    B --> C
    C -->|Yes| D
    C -->|No| E
    D --> F
    E --> F
    F -->|Yes| G
    G --> H
    H -->|Yes| I
    H -->|No| J
    I --> K
    J --> K
    F -->|No| K
    K -->|Yes| L
    K -->|No| M

    style D fill:#ffccbc
    style I fill:#ffcdd2
    style L fill:#fff9c4
    style M fill:#c8e6c9
```

**Example Scenarios**:

### Scenario 1: PMT Required from Start
```python
selected_strategies = ["Needs-based project-oriented training"]
→ PMT Required = TRUE
→ Admin must provide PMT before generating objectives
```

### Scenario 2: PMT Not Required Initially
```python
selected_strategies = ["SE for managers", "Common basic understanding"]
→ PMT Required = FALSE
→ Can generate objectives without PMT
→ Uses templates as-is (no customization)
```

### Scenario 3: PMT Required After Validation
```python
# Initial
selected_strategies = ["SE for managers"]
PMT Required = FALSE

# After validation
validation_recommends = "Continuous support"
→ New Strategy Requires PMT!
→ Request PMT from admin
→ Regenerate with new strategy + PMT
```

---

## Cross-Strategy Coverage Logic (BEST-FIT)

**Key Change**: Use fit scores, not just highest target!

```mermaid
graph TB
    A[Competency: Decision Management<br/>40 users total]
    B[Strategy A: target 2<br/>Strategy B: target 4<br/>Strategy C: target 6]
    C[Calculate Fit Scores<br/>Based on Scenarios]
    D[Strategy A: -1.25<br/>25% A, 75% B worst!]
    E[Strategy B: +0.25<br/>70% A, 20% B, 10% C BEST!]
    F[Strategy C: -0.31<br/>12.5% A, 87.5% C over-train!]
    G[Pick Best Fit<br/>Strategy B score +0.25]
    H[Max Role Requirement: 6]
    I{Strategy B Target<br/>4 >= 6?}
    J[has_real_gap = FALSE<br/>Sufficient!]
    K[has_real_gap = TRUE<br/>Gap = 2 levels]
    L[Get Scenario B from<br/>Strategy B ONLY]
    M[8 users in Scenario B<br/>20% of users]
    N[Gap Severity:<br/>20% = significant]

    A --> B
    B --> C
    C --> D
    C --> E
    C --> F
    D --> G
    E --> G
    F --> G
    G --> H
    H --> I
    I -->|Yes| J
    I -->|No| K
    J --> L
    K --> L
    L --> M
    M --> N

    style E fill:#c8e6c9
    style D fill:#ffcdd2
    style F fill:#fff9c4
    style G fill:#fff9c4
    style K fill:#ffcdd2
```

**Why Best-Fit Matters**:

**OLD Logic (Pick Highest Target)**:
```
Strategy A: target 2 (too low)
Strategy B: target 4 (moderate)
Strategy C: target 6 (highest) ← PICK THIS!

Result: Strategy C over-trains 87.5% of users (Scenario C)
Cost: Wasted training time/money for 35 out of 40 users
```

**NEW Logic (Pick Best Fit Score)**:
```
Strategy A: fit score -1.25 (75% gaps - worst!)
Strategy B: fit score +0.25 (70% perfect fit - BEST!) ← PICK THIS!
Strategy C: fit score -0.31 (87.5% over-training)

Result: Strategy B serves 70% perfectly (Scenario A)
Benefit: Optimal training for majority, minimal waste
```

**Key Insight**:
- Highest target ≠ Best strategy!
- Strategy must FIT the organization's actual role requirements
- Over-training wastes resources just like under-training creates gaps
- Fit score balances: serving majority + minimizing gaps + avoiding waste

---

## Validation Decision Tree

### Understanding the Validation Metrics

Before looking at the decision tree, let's understand what each metric means:

#### 1. Gap Severity Per Competency (Step 4 Output)

Each of the 16 competencies gets classified by **how many users have gaps** in the best-fit strategy:

| Severity | Scenario B % | Meaning | Example |
|----------|-------------|---------|---------|
| **Critical** | > 60% | MOST users have gaps | 25 out of 40 users (62.5%) need higher than best strategy provides |
| **Significant** | 20-60% | MANY users have gaps | 12 out of 40 users (30%) need higher |
| **Minor** | 0-20% | FEW users have gaps | 3 out of 40 users (7.5%) need higher |
| **None** | 0% | No gaps | Best strategy covers everyone! |

#### 2. "Critical Gaps >= 3?" Check

**Question**: Are there **3 or more competencies** where >60% of users have gaps?

**Why This Matters**:
- If **1-2 competencies** are critical → Isolated issue, might be specific roles
- If **3+ competencies** are critical → SYSTEMATIC FAILURE, strategy fundamentally wrong!

**Example - CRITICAL Status**:
```
Out of 16 competencies:
- Competency 7: 65% of users have gaps (critical)
- Competency 11: 70% of users have gaps (critical)
- Competency 15: 62% of users have gaps (critical)
- Competency 3: 25% of users have gaps (significant)
- Rest: covered

→ 3 critical gaps detected!
→ STATUS: CRITICAL
→ Action: ADD NEW STRATEGY (urgent!)
```

#### 3. Total Gap % Calculation

**Formula**:
```
Total Gap % = (Competencies with ANY gaps / Total 16 competencies) × 100
```

**ANY gaps** means: critical OR significant OR minor (>0% Scenario B)

**Examples**:

| Competencies with Gaps | Calculation | Total Gap % |
|------------------------|-------------|-------------|
| 0 out of 16 | (0/16) × 100 | 0% → EXCELLENT |
| 2 out of 16 | (2/16) × 100 | 12.5% → GOOD |
| 4 out of 16 | (4/16) × 100 | 25% → ACCEPTABLE |
| 7 out of 16 | (7/16) × 100 | 43.75% → INADEQUATE |
| 10 out of 16 | (10/16) × 100 | 62.5% → INADEQUATE |

#### 4. Three Levels of Phase 3 Recommendations

There are actually **THREE different recommendations**, not just two:

| Gap % | Status | Recommendation | What It Means |
|-------|--------|---------------|---------------|
| 0-20% | GOOD | "Phase 3 Modules" | Normal module selection |
| 20-40% | ACCEPTABLE | "Consider Supplementary" | Deliberate advanced selection |
| >40% | INADEQUATE | "Add New Strategy" | Go back to Phase 1 |

Let's break down the difference:

---

#### 4a. Gap % 0-20% → "Phase 3 Modules" (STATUS: GOOD)

**Example**: 2 competencies have gaps (12.5%)

```
Competency 7: 8% users have gap (minor - only 3 out of 40 users)
Competency 11: 15% users have gap (minor - only 6 out of 40 users)
Other 14 competencies: No gaps
```

**Analysis**:
- ✅ Selected strategies are **working well**
- ✅ Gaps are **tiny** and affect **very few users**
- ✅ Only **1-2 competencies** affected
- 📍 **Type of gaps**: All "minor" severity (<20% of users per competency)

**Recommendation**: **Normal Phase 3 Module Selection**
```
Message to Admin:
"Your selected strategies are well-aligned! During Phase 3 module
selection, the standard catalog should handle these minor gaps naturally.
No special action required."

What Admin Does in Phase 3:
- Just browse the module catalog normally
- Select modules based on training duration, format, availability
- The standard module offerings will naturally cover these small gaps
- No need to specifically search for "advanced" versions
```

**User Experience**:
- 👍 Proceed as normal
- 👍 No warnings or special alerts
- 👍 Green status indicator

---

#### 4b. Gap % 20-40% → "Consider Supplementary" (STATUS: ACCEPTABLE)

**Example**: 4 competencies have gaps (25%)

```
Competency 2: 35% users have gap (significant - 14 out of 40 users)
Competency 7: 15% users have gap (minor - 6 out of 40 users)
Competency 11: 45% users have gap (significant - 18 out of 40 users)
Competency 15: 20% users have gap (significant - 8 out of 40 users)
Other 12 competencies: No gaps
```

**Analysis**:
- ⚠️ Strategies are **mostly okay** but have **notable gaps**
- ⚠️ Gaps affect **significant portion** of users in some competencies
- ⚠️ **2-4 significant severity** gaps (20-60% of users per competency)
- 📍 More widespread than "GOOD" status

**Recommendation**: **Deliberate Supplementary Content Selection**
```
Message to Admin:
"Your strategies are acceptable but have gaps in 4 competencies.
During Phase 3, you MUST specifically select advanced/supplementary
modules for these competencies:

- Competency 2 (Decision Management): Select 'Advanced Decision Workshop'
- Competency 7 (Requirements): Select 'Expert Requirements Course'
- Competency 11 (Architecture): Select 'Complex Systems Design'
- Competency 15 (Integration): Select 'Advanced Integration Module'

For the other 12 competencies, standard modules are fine."

What Admin Does in Phase 3:
- ⚠️ MUST deliberately search for advanced/supplementary content
- ⚠️ Cannot just pick standard modules - need to upgrade 4 competencies
- ⚠️ Specifically told which competencies need advanced content
- ⚠️ May need to check if advanced modules are available in catalog
```

**User Experience**:
- ⚠️ Yellow warning status
- ⚠️ Explicit list of competencies requiring advanced modules
- ⚠️ Admin must acknowledge and plan for supplementary content

---

#### 4c. Gap % > 40% → "Add New Strategy" (STATUS: INADEQUATE)

**Example**: 8 competencies have gaps (50%)

```
Competency 2: 40% users have gap (significant)
Competency 7: 35% users have gap (significant)
Competency 9: 55% users have gap (significant)
Competency 11: 70% users have gap (critical!)
Competency 13: 25% users have gap (significant)
Competency 15: 65% users have gap (critical!)
Competency 16: 45% users have gap (significant)
Competency 4: 20% users have gap (significant)
Other 8 competencies: No gaps
```

**Analysis**:
- ❌ Gaps are **WIDESPREAD** across **HALF** of competencies
- ❌ Many gaps affect **MAJORITY** of users (2 critical >60%)
- ❌ Selected strategies are **FUNDAMENTALLY INSUFFICIENT**
- 📍 **Root cause**: Wrong strategy selected in Phase 1!

**Recommendation**: **Add New Training Strategy**
```
Message to Admin:
"INADEQUATE: Your selected strategies have major gaps in 50% of
competencies. You MUST go back to Phase 1 and add a new training
strategy to your selection.

Recommended action:
1. Return to Phase 1 strategy selection
2. Add 'Continuous Support' or 'Advanced Technical Training'
3. Regenerate learning objectives with the new strategy
4. The new strategy should target levels 4-6 for these competencies

Affected competencies: 2, 7, 9, 11, 13, 15, 16, 4"

What Admin Does:
- ❌ CANNOT proceed to Phase 3 as-is
- ❌ MUST modify Phase 1 selections
- ❌ Add entirely new training strategy to organization
- ❌ Regenerate all learning objectives from scratch
```

**User Experience**:
- 🔴 Red critical status
- 🔴 Blocked from proceeding to Phase 3
- 🔴 Must revise Phase 1 strategy selection

---

#### Summary: Three-Level Comparison

| Aspect | 0-20% (GOOD) | 20-40% (ACCEPTABLE) | >40% (INADEQUATE) |
|--------|-------------|-------------------|------------------|
| **# Competencies** | 1-3 | 4-6 | 7+ |
| **Gap Types** | All minor (<20% users) | Mix of significant + minor | Many significant + critical |
| **Status Color** | 🟢 Green | 🟡 Yellow | 🔴 Red |
| **Urgency** | Low | Medium | High |
| **Action Location** | Phase 3 | Phase 3 | Phase 1 |
| **Admin Effort** | None (automatic) | Moderate (select advanced) | High (revise strategies) |
| **Message Tone** | "All good!" | "Needs attention" | "Critical - must fix" |
| **Can Proceed?** | ✅ Yes, automatic | ⚠️ Yes, but with care | ❌ No, must go back |
| **Module Selection** | Browse normally | Deliberately pick advanced | N/A - must add strategy first |
| **Cost/Impact** | None | Low (module swap) | High (full regeneration) |

**Key Decision Factor**: How widespread and severe are the gaps?
- **Tiny gaps in few places** → Just proceed normally
- **Notable gaps in some places** → Be deliberate about advanced content
- **Major gaps everywhere** → Your whole strategy is wrong!

```mermaid
graph TB
    A[Count Competencies<br/>by Gap Severity]
    B{Critical Gaps<br/>>= 3?}
    C[STATUS: CRITICAL<br/>Severity: critical<br/>Revision: REQUIRED]
    D{Total Gap %<br/>> 40%?}
    E[STATUS: INADEQUATE<br/>Severity: high<br/>Revision: REQUIRED]
    F{Total Gap %<br/>> 20%?}
    G[STATUS: ACCEPTABLE<br/>Severity: moderate<br/>Revision: NOT REQUIRED]
    H{Total Gap %<br/>> 0%?}
    I[STATUS: GOOD<br/>Severity: low<br/>Revision: NOT REQUIRED]
    J[STATUS: EXCELLENT<br/>Severity: none<br/>Revision: NOT REQUIRED]
    K[Recommend:<br/>Add New Strategy]
    L[Recommend:<br/>Consider Supplementary]
    M[Recommend:<br/>Phase 3 Modules]
    N[Recommend:<br/>Proceed As Planned]

    A --> B
    B -->|Yes| C
    B -->|No| D
    D -->|Yes| E
    D -->|No| F
    F -->|Yes| G
    F -->|No| H
    H -->|Yes| I
    H -->|No| J
    C --> K
    E --> K
    G --> L
    I --> M
    J --> N

    style C fill:#c62828
    style E fill:#ff5722
    style G fill:#fff9c4
    style I fill:#c8e6c9
    style J fill:#a5d6a7
```

**Example Decision Paths**:

### Path 1: Excellent
```
Input:
- critical_gaps = 0
- significant_gaps = 0
- minor_gaps = 0
- gap_percentage = 0%

Decision:
- Critical >= 3? NO
- Gap% > 40%? NO
- Gap% > 20%? NO
- Gap% > 0%? NO
→ STATUS: EXCELLENT
→ PROCEED AS PLANNED
```

### Path 2: Good (Minor Gaps)
```
Input:
- critical_gaps = 0
- significant_gaps = 0
- minor_gaps = 2
- gap_percentage = 12.5%

Decision:
- Critical >= 3? NO
- Gap% > 40%? NO
- Gap% > 20%? NO
- Gap% > 0%? YES
→ STATUS: GOOD
→ Phase 3 module guidance
```

### Path 3: Critical
```
Input:
- critical_gaps = 5
- significant_gaps = 3
- minor_gaps = 1
- gap_percentage = 56.25%

Decision:
- Critical >= 3? YES
→ STATUS: CRITICAL
→ Urgent strategy addition required
```

---

## Complete Data Flow Example

### Initial Input
```json
{
  "org_id": 28,
  "organization_name": "TechCorp Systems GmbH",
  "admin_confirmed_assessments_complete": true
}
```

### Step 1 Output
```json
{
  "user_assessments": 40,
  "organization_roles": 3,
  "selected_strategies": 2
}
```

### Steps 2-3 Output
```json
{
  "competency_scenario_distributions": {
    "11": {
      "by_strategy": {
        "Needs-based project": {
          "scenario_A_percentage": 70.0,
          "scenario_B_percentage": 30.0
        }
      }
    }
  }
}
```

### Step 4 Output
```json
{
  "cross_strategy_coverage": {
    "11": {
      "has_real_gap": true,
      "gap_severity": "significant"
    }
  }
}
```

### Step 5 Output
```json
{
  "strategy_validation": {
    "status": "GOOD",
    "gap_percentage": 12.5,
    "strategies_adequate": true
  }
}
```

### Step 6 Output
```json
{
  "strategic_decisions": {
    "overall_action": "PROCEED_AS_PLANNED",
    "supplementary_module_guidance": [...]
  }
}
```

### Final Output
```json
{
  "pathway": "ROLE_BASED",
  "learning_objectives_by_strategy": {
    "Needs-based project": {
      "trainable_competencies": [
        {
          "competency_id": 11,
          "learning_objective": "PMT-customized capability statement",
          "training_priority": 4.25
        }
      ]
    }
  }
}
```

---

## Summary: Key Data Transformations

### Transformation 1: Assessments → Current Levels
```
Raw Scores: [2, 2, 3, 1, 2] → Median: 2
```

### Transformation 2: Role Analysis → Scenarios
```
Current=2, Archetype=4, Role=6 → Scenario A (Normal)
Current=3, Archetype=2, Role=6 → Scenario B (Insufficient)
```

### Transformation 3: Scenarios → User Counts
```
Role1: Scenario A, 5 users
Role2: Scenario A, 3 users
→ Total: Scenario A, 8 users (80%)
```

### Transformation 4: User Counts → Coverage
```
Strategy A: 15 users in Scenario B
Strategy B (best): 3 users in Scenario B
→ Real gap: 3 users (not 15!)
```

### Transformation 5: Coverage → Validation
```
Competency 1: significant gap
Competency 2: minor gap
Competency 3-16: no gap
→ Overall: 12.5% gap = GOOD status
```

### Transformation 6: Validation → Decisions
```
Status: GOOD
Gap %: 12.5
→ Action: PROCEED_AS_PLANNED
→ Guidance: Phase 3 supplementary modules
```

### Transformation 7: Decisions + Templates → Final Objectives
```
Template: "Participants are able to..."
+ PMT: "JIRA", "ISO 26262"
→ "Participants are able to... using JIRA... according to ISO 26262"
```

---

*End of Flowcharts Document*
*All flowcharts use example data from Organization ID 28*
*Visual representations match v4.1 algorithm specification*
