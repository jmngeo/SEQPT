# Phase 2 Algorithm - Data Model Relationships
**Created**: 2025-11-04
**Purpose**: Clarify relationships between roles, strategies, and Phase 1 vs Phase 2 data

---

## Quick Reference: Key Questions Answered

### Q1: Which roles does Phase 2 algorithm use?
**Answer**: `organization_roles` (user-defined roles from Phase 1 Task 2)
**NOT**: `role_cluster` (14 standard INCOSE reference roles)

### Q2: Are Learning Strategies redundant with Phase 1 Archetypes?
**Answer**: NO! They're at different levels of abstraction:
- **Phase 1 Archetype**: High-level qualification philosophy (e.g., "Certification")
- **Phase 2 Learning Strategy**: Specific training programs (e.g., "CSEP Prep Course")

---

## Data Model Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PHASE 1: SETUP                                  │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│   role_cluster       │         │   organization       │
│  (Standard Roles)    │         │                      │
│  ┌────────────────┐  │         │  selected_archetype  │
│  │ 14 INCOSE      │  │         │    "Certification"   │
│  │ Reference Roles│  │         └──────────────────────┘
│  └────────────────┘  │                    │
└──────────────────────┘                    │
          │ optional                        │
          │ reference                       │
          ↓                                 ↓
┌──────────────────────┐         ┌──────────────────────┐
│ organization_roles   │         │  Phase 1 Output:     │
│  (User-Defined)      │         │  "We need            │
│  ┌────────────────┐  │         │   certification-     │
│  │ Org's actual   │  │         │   based training"    │
│  │ roles created  │  │         └──────────────────────┘
│  │ in Phase 1     │  │
│  │ Task 2         │  │
│  └────────────────┘  │
└──────────────────────┘
          │
          │ Used by Phase 2!
          ↓

┌─────────────────────────────────────────────────────────────────────────┐
│                         PHASE 2: ANALYSIS                               │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  learning_strategy (Phase 2 Specific Training Programs)         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Examples:                                                 │   │
│  │ - "CSEP Foundation Course" (targets levels 1-2)          │   │
│  │ - "CSEP Advanced Course" (targets levels 2-4)            │   │
│  │ - "CSEP Expert Certification" (targets levels 4-6)       │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
          │
          │ linked via
          ↓
┌──────────────────────────────────────────────────────────────────┐
│  strategy_competency (What each strategy trains)                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ "Foundation Course trains Systems Thinking to level 2"   │   │
│  │ "Advanced Course trains Systems Thinking to level 4"     │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘

          ↓ Phase 2 Algorithm Analyzes

┌──────────────────────────────────────────────────────────────────┐
│  Output: User-specific learning recommendations                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ "User A: Foundation Course → Advanced Course"            │   │
│  │ "User B: Already meets requirements"                     │   │
│  │ "User C: Advanced Course only"                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Detailed Table Relationships

### 1. Role Tables (Confusing but Critical!)

```
┌────────────────────────────────────────────────────────────────────────┐
│ Table: role_cluster (Standard Reference - READ ONLY)                  │
│ ────────────────────────────────────────────────────────────────────  │
│ Purpose: 14 INCOSE standard role definitions                          │
│ Examples: "Systems Engineer", "Requirements Engineer"                 │
│ Used by: Phase 1 (selection reference only)                           │
│ Used by Phase 2: NO                                                   │
└────────────────────────────────────────────────────────────────────────┘
          ↓ (optional reference via standard_role_cluster_id)
┌────────────────────────────────────────────────────────────────────────┐
│ Table: organization_roles (Organization-Specific - PHASE 2 USES THIS!)│
│ ────────────────────────────────────────────────────────────────────  │
│ Purpose: Roles defined by organization in Phase 1 Task 2              │
│ Examples:                                                              │
│   - "Senior Systems Engineer" (based on standard role 1)              │
│   - "Embedded SW Developer" (custom, no standard mapping)             │
│ Created: Phase 1 Task 2                                               │
│ Used by Phase 2: YES ✅                                                │
└────────────────────────────────────────────────────────────────────────┘
          ↓ (referenced by role_competency_matrix.role_cluster_id)
┌────────────────────────────────────────────────────────────────────────┐
│ Table: role_competency_matrix (CONFUSING FIELD NAME!)                 │
│ ────────────────────────────────────────────────────────────────────  │
│ ⚠️  Column name: role_cluster_id (MISLEADING!)                        │
│ ✅ Actually references: organization_roles.id                          │
│                                                                        │
│ Why: FK was changed from role_cluster → organization_roles in         │
│      migration 002 (Oct 2025) but column name kept for compatibility  │
│                                                                        │
│ Purpose: Maps each organization role → required competency levels     │
│ Example: "Senior Systems Engineer" requires "Systems Thinking" = 4    │
└────────────────────────────────────────────────────────────────────────┘
```

### 2. Strategy Tables (Phase 1 vs Phase 2)

```
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Archetype (High-Level Philosophy)                            │
│ ────────────────────────────────────────────────────────────────────  │
│ Table: organization.selected_archetype                                 │
│ Examples:                                                              │
│   - "SE_for_Managers"                                                  │
│   - "Certification"                                                    │
│   - "Common_Understanding"                                             │
│   - "Continuous_Support"                                               │
│                                                                        │
│ Purpose: Defines WHAT TYPE of qualification approach org needs         │
│ Granularity: Very high level                                          │
│ Used by: Guides selection of Phase 2 strategies                       │
└────────────────────────────────────────────────────────────────────────┘
          ↓ (guides selection)
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Learning Strategies (Specific Programs)                      │
│ ────────────────────────────────────────────────────────────────────  │
│ Table: learning_strategy                                               │
│ Examples (for "Certification" archetype):                              │
│   - "INCOSE CSEP Foundation Course"                                    │
│   - "INCOSE CSEP Advanced Course"                                      │
│   - "INCOSE CSEP Expert Certification"                                 │
│                                                                        │
│ Examples (for "SE_for_Managers" archetype):                            │
│   - "Executive SE Overview Workshop"                                   │
│   - "SE Leadership Training"                                           │
│                                                                        │
│ Purpose: Defines SPECIFIC training programs org will use               │
│ Granularity: Detailed (includes competency targets per program)        │
│ Used by: Phase 2 algorithm for gap analysis and recommendations       │
└────────────────────────────────────────────────────────────────────────┘
          ↓ (linked via strategy_competency)
┌────────────────────────────────────────────────────────────────────────┐
│ Table: strategy_competency                                             │
│ ────────────────────────────────────────────────────────────────────  │
│ Purpose: Defines target competency levels for each strategy            │
│ Example:                                                               │
│   strategy_id=1 (CSEP Foundation), competency_id=1, target_level=2    │
│   → "Foundation course trains Systems Thinking to level 2"             │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Real-World Example Flow

### Scenario: TechCorp needs certification training

#### Phase 1 Setup:
1. **Organization Profile**: TechCorp (ID: 28)
2. **Archetype Selection**: "Certification" (selected based on maturity assessment)
3. **Role Definition** (Task 2):
   - Role 1: "Senior Systems Engineer" (based on standard role 1, customized)
   - Role 2: "Requirements Specialist" (based on standard role 3, customized)
   - Role 3: "Technical Project Manager" (based on standard role 7, customized)

#### Phase 2 Strategy Definition:
Based on "Certification" archetype, organization creates:
1. **Strategy A**: "CSEP Foundation Workshop"
   - Target: Bring everyone to awareness/supervised level (1-2)
   - Duration: 3 days

2. **Strategy B**: "CSEP Advanced Training"
   - Target: Bring experienced engineers to independent level (2-4)
   - Duration: 2 weeks

3. **Strategy C**: "CSEP Expert Certification"
   - Target: Prepare senior engineers for certification (4-6)
   - Duration: 3 months

#### Phase 2 Algorithm Analysis:
```
Input:
- 50 employees with current competency levels (from assessments)
- 3 roles with required competency levels
- 2 selected strategies (A and B)

Algorithm analyzes:
1. For each user:
   - Current level: 1 (awareness)
   - Required level: 4 (independent)
   - Gap: 3 levels

2. Matches users to strategies:
   - Users at level 0-1: Strategy A → Strategy B
   - Users at level 2-3: Strategy B only
   - Users at level 4+: No training needed

Output:
- 15 users need Strategy A only
- 20 users need Strategy A → B
- 10 users need Strategy B only
- 5 users already meet requirements
```

---

## Field Name Mapping Reference

**For developers working with the algorithm:**

| Algorithm Code Uses | Actual DB Column | Note |
|---------------------|------------------|------|
| `role_id` | `role_cluster_id` | Confusing! Actually references organization_roles |
| `required_level` | `role_competency_value` | Different name in DB |
| `assessment_complete` | `completed_at IS NOT NULL` | Boolean vs timestamp |
| `strategy.name` | `strategy.strategy_name` | Added prefix for clarity |
| `user.selected_roles` | `user.selected_role_objects` | Property added for compatibility |

---

## Database Compatibility Aliases

**File**: `models.py` (lines 955-987)

```python
# These aliases make the algorithm code cleaner
Role = OrganizationRoles  # ✅ Uses org-specific roles
RoleCompetency = RoleCompetencyMatrix  # Maps roles → competencies
CompetencyScore = UserCompetencySurveyResult  # User assessment results
```

---

## Key Takeaways for Thesis Documentation

1. **Phase 1 vs Phase 2 are complementary, not redundant**
   - Phase 1: Strategic (what approach?)
   - Phase 2: Tactical (which specific programs?)

2. **Role usage is correct but naming is confusing**
   - Algorithm uses organization-specific roles (correct!)
   - Field name `role_cluster_id` is legacy (misleading but kept for compatibility)

3. **Data flow is unidirectional**
   - Phase 1 → creates organization_roles
   - Phase 2 → uses organization_roles (not role_cluster)
   - Phase 1 archetype → guides Phase 2 strategy selection

4. **Practical implication**
   - Each organization's Phase 2 analysis is customized to THEIR roles
   - Not based on abstract standard roles
   - This allows for organizational specificity and context

---

## For Thesis Advisor Review

**Key Points to Emphasize:**

1. The system supports **two levels of customization**:
   - Phase 1: Organizations define their own roles (not forced to use standard 14)
   - Phase 2: Organizations define their own training programs (not forced to use standard templates)

2. The algorithm is **organization-context-aware**:
   - Analyzes gaps based on the organization's actual role definitions
   - Recommends strategies based on the organization's actual training capabilities

3. The naming confusion (`role_cluster_id`) is a **technical debt artifact**:
   - Kept for backward compatibility with existing data
   - Does not affect algorithm correctness
   - Could be refactored in future major version

---

**End of Documentation**

For questions or clarifications, see:
- `models.py` lines 119-987 (model definitions and aliases)
- `role_based_pathway_fixed.py` lines 27-51 (algorithm documentation)
- Integration test results: `test_integration_result_org28.json`
