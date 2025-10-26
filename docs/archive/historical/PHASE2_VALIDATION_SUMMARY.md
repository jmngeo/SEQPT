# Phase 2 Validation Summary

**Date:** 2025-10-20
**Purpose:** Validate existing implementation and clarify Phase 2 requirements

---

## Question 1: Dynamic Role-Competency Matrix Calculation

### Status: ✓ CONFIRMED - Already Implemented

**Finding:** The role-competency matrix is dynamically calculated whenever either the role-process or process-competency matrices are updated.

### Implementation Details:

#### 1. Stored Procedure
**File:** `src/competency_assessor/create_stored_procedure.sql`

```sql
CREATE OR REPLACE PROCEDURE public.update_role_competency_matrix(IN _organization_id integer)
```

**How it works:**
- Deletes existing role-competency entries for the organization
- Calculates new values using: `role_process_value × process_competency_value`
- Applies mapping rules for valid competency levels (0, 1, 2, 3, 4, 6)
- Uses MAX() to handle multiple process paths to same competency
- Inserts calculated values into `role_competency_matrix` table

#### 2. Automatic Triggers

**When Role-Process Matrix is Updated:**
```python
# File: src/competency_assessor/app/routes.py
# Endpoint: PUT /role_process_matrix/bulk

@main.route('/role_process_matrix/bulk', methods=['PUT'])
def bulk_update_role_process_matrix():
    # ... update role_process_matrix entries ...
    db.session.commit()

    # AUTOMATICALLY recalculate role-competency matrix
    db.session.execute(
        text('CALL update_role_competency_matrix(:org_id);'),
        {'org_id': organization_id}
    )
    db.session.commit()
```

**When Process-Competency Matrix is Updated:**
```python
# File: src/competency_assessor/app/routes.py
# Endpoint: PUT /process_competency_matrix/bulk

@main.route('/process_competency_matrix/bulk', methods=['PUT'])
def bulk_update_process_competency_matrix():
    # ... update process_competency_matrix entries ...
    db.session.commit()

    # AUTOMATICALLY recalculate for ALL organizations
    organizations = Organization.query.all()
    for org in organizations:
        db.session.execute(
            text('CALL update_role_competency_matrix(:org_id);'),
            {'org_id': org.id}
        )
    db.session.commit()
```

### Calculation Formula

```
role_competency_value = MAX(role_process_value × process_competency_value)

WHERE:
- role_process_value ∈ {-100, 0, 1, 2, 3} (from role_process_matrix)
- process_competency_value ∈ {-100, 0, 1, 2, 3} (from process_competency_matrix)
- result ∈ {-100, 0, 1, 2, 3, 4, 6} (competency level)

Mapping:
  0 → 0 (not relevant)
  1 → 1 (apply - basic)
  2 → 2 (understand)
  3 → 3 (apply - intermediate)
  4 → 4 (apply - advanced)
  6 → 6 (master)
  other → -100 (invalid)
```

### Conclusion

**✓ No changes needed for Phase 2 implementation**

The existing infrastructure already supports:
- Dynamic calculation when matrices change
- Organization-specific role-competency values
- Proper handling of competency level scale (0, 1, 2, 3, 4, 6)

For Phase 2, we can **directly query** the `role_competency_matrix` table to get necessary competencies for selected roles.

---

## Question 2: Task 1 UI Design

### Requirement: Grid-like Structure for Identified SE Roles

**UI Design Specifications:**

#### View: Phase2RoleSelection.vue

**Layout:**
```
┌────────────────────────────────────────────────────────────┐
│  Identified SE Roles for [Organization Name]               │
│  Select the roles you want to assess:                      │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ☐ Systems    │  │ ☐ Developer  │  │ ☐ V&V        │     │
│  │   Engineer   │  │              │  │   Employee   │     │
│  │              │  │              │  │              │     │
│  │ Standard     │  │ Standard     │  │ Custom:      │     │
│  │ Role         │  │ Role         │  │ QA Engineer  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ☐ Project    │  │ ☐ Quality    │  │ ☐ Customer   │     │
│  │   Manager    │  │   Manager    │  │   Rep        │     │
│  │              │  │              │  │              │     │
│  │ Standard     │  │ Standard     │  │ Standard     │     │
│  │ Role         │  │ Role         │  │ Role         │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│        [Cancel]              [Calculate Competencies →]    │
└────────────────────────────────────────────────────────────┘
```

**Features:**
- Responsive grid (3-4 columns on desktop, 1-2 on mobile)
- Each role as a card with checkbox
- Display both `standard_role_name` and `org_role_name` (if customized)
- Visual indicator for task-based vs. standard identification method
- Multi-select capability
- Disabled state if no Phase 1 roles exist

**Sample Data Structure:**
```json
{
  "organizationId": 1,
  "organizationName": "ACME Corp",
  "identifiedRoles": [
    {
      "id": 101,
      "standardRoleId": 6,
      "standardRoleName": "System engineer",
      "orgRoleName": null,
      "identificationMethod": "STANDARD",
      "participatingInTraining": true
    },
    {
      "id": 102,
      "standardRoleId": 7,
      "standardRoleName": "Developer",
      "orgRoleName": "Software Developer",
      "identificationMethod": "TASK_BASED",
      "confidenceScore": 85.5,
      "participatingInTraining": true
    }
  ]
}
```

**Implementation Notes:**
- Use Vuetify `v-card` with `v-checkbox`
- Use `v-row` and `v-col` for responsive grid
- Filter out roles with `participatingInTraining = false`
- Sort by `standardRoleId` or alphabetically

---

## Question 3: Learning Objectives Templates

### Status: Awaiting JSON File

**Location Confirmed:**
- JSON file containing learning objectives templates
- Path: `data/source/questionnaires/phase2/se_qpt_learning_objectives_template.json` ✓

**Expected Structure (tentative):**
```json
{
  "learning_objectives_framework": {
    "bloom_taxonomy_levels": [
      "Remember", "Understand", "Apply", "Analyze", "Evaluate", "Create"
    ],
    "competency_level_mapping": {
      "1": "Understand",
      "2": "Apply",
      "3": "Analyze",
      "4": "Evaluate",
      "6": "Create"
    }
  },
  "templates": [
    {
      "competency_id": 1,
      "competency_name": "Systemic thinking",
      "level_1_objectives": [...],
      "level_2_objectives": [...],
      "level_3_objectives": [...],
      "level_4_objectives": [...],
      "level_6_objectives": [...]
    }
  ]
}
```

**Integration Plan:**
- Load templates in Task 3 LLM prompt generation
- Use as guide for generating targeted learning objectives
- Ensure consistency across different competency assessments

---

## Competency Level Scale Reference

**Source:** `data/processed/role_competency_matrix_corrected.json`

```
Scale: 0=not relevant, 1=apply, 2=understand, 3/4=apply, 6=master

Detailed Mapping:
  0 = Not Relevant (competency not required for this role)
  1 = Apply (Basic) - Can perform with guidance
  2 = Understand - Comprehends concepts and principles
  3 = Apply (Intermediate) - Can perform independently
  4 = Apply (Advanced) - Can perform complex tasks
  6 = Master - Expert level, can teach others
```

**Note:** Values 3 and 4 are both "apply" but at different proficiency levels.

---

## Database Tables Confirmed for Phase 2

### Input Tables (Phase 1 Output)
- `organization` - Organization details with Phase 1 completion flag
- `phase1_roles` - Identified SE roles per organization
- `phase1_maturity` - Maturity assessment results
- `phase1_target_group` - Target group size information
- `phase1_strategies` - Selected qualification strategies

### Calculation Tables (Matrix Infrastructure)
- `role_process_matrix` - Editable per organization
- `process_competency_matrix` - Global, rarely edited
- `role_competency_matrix` - Auto-calculated, read-only for users

### Assessment Tables (Phase 2 Data Storage)
- `competency_assessment` - Master assessment record
  - Stores `selected_roles` (Task 1)
  - Stores `learning_objectives` (Task 3)
- `user_se_competency_survey_results` - Individual answers (Task 2)
- `user_competency_survey_feedback` - LLM feedback (Task 2)
- `admin_user` - Admin and employee users
- `app_user` - Legacy user records (may be deprecated)

### Reference Tables
- `competency` - 16 SE competencies
- `competency_indicators` - Level-specific indicators
- `role_cluster` - 14 standard SE roles
- `iso_processes` - 30 ISO/IEC 15288 processes

---

## Implementation Readiness Checklist

### ✓ Confirmed Ready
- [x] Role-Competency Matrix dynamic calculation
- [x] Database schema supports Phase 2 workflow
- [x] Existing LLM feedback generation (can be enhanced)
- [x] Assessment tracking infrastructure
- [x] Organization and user management

### ⚠ Needs Implementation
- [ ] Task 1: Role selection API and UI
- [ ] Task 1: Necessary competencies calculation endpoint
- [ ] Task 2: Dynamic survey generation (filtered competencies)
- [ ] Task 2: Gap analysis calculation
- [ ] Task 2: Enhanced LLM feedback with role context
- [ ] Task 3: Employee assessment aggregation
- [ ] Task 3: LLM learning objectives generation
- [ ] Task 3: Admin dashboard for viewing all assessments
- [ ] Frontend views for all three tasks

### 📋 User Input Status
- [x] Learning objectives templates JSON file ✓ `data/source/questionnaires/phase2/se_qpt_learning_objectives_template.json`
- [x] Confirmation on UI design preferences ✓ Grid layout approved
- [x] Priority for implementation phases ✓ Phase A → B → C → D

---

## Next Steps

1. **User provides learning objectives template JSON**
2. **Review and approve Task 1 UI design**
3. **Begin Phase A Implementation (Task 1)**
   - Backend: Role selection and competency calculation
   - Frontend: Grid-based role selection view
   - Frontend: Necessary competencies display

**Estimated Timeline:**
- Phase A (Task 1): 1-2 weeks
- Phase B (Task 2): 2-3 weeks
- Phase C (Task 3): 2-3 weeks
- Phase D (Testing): 1 week

**Total: 6-9 weeks**

---

**Document Status:** VALIDATED v1.1
**Last Updated:** 2025-10-20
**Ready to Proceed:** All prerequisites met ✓ - Ready for Phase A Implementation
