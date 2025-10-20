# Phase 2 Implementation Reference Document

**Created:** 2025-10-20
**Purpose:** Comprehensive guide for Phase 2 competency assessment refactoring

---

## Phase 2 Overview

Phase 2 focuses on **Competency Assessment and Learning Objective Formulation** for organizations that have completed Phase 1.

### Tasks Summary

| Task | Name | Admin User | Employee User |
|------|------|------------|---------------|
| **Task 1** | Determine Necessary Competencies | ✓ | ✓ |
| **Task 2** | Identify Competency Gaps | ✓ | ✓ |
| **Task 3** | Formulate Learning Objectives | ✓ | ✗ |

---

## Task 1: Determine Necessary Competencies

### Objective
Calculate and present the necessary competencies with required competency levels for selected roles.

### User Flow

#### Step 1: Present Identified SE Roles
- **Data Source:** Phase 1 results stored in `phase1_roles` table
- **Display:**
  - Show all roles identified for the organization from Phase 1
  - Include both `standard_role_name` and `org_role_name` (if customized)
  - Allow selection of 1 or more roles
- **Similar To:** Existing "Role-Based Competency Assessment" view

#### Step 2: Role Selection
- **UI:** Multi-select interface (checkboxes or similar)
- **Validation:** At least 1 role must be selected
- **Action:** On confirmation, proceed to competency calculation

#### Step 3: Calculate Necessary Competencies
**Calculation Logic:**

```
For each selected role:
  1. Get role_id from phase1_roles
  2. Query role_competency_matrix WHERE:
     - role_cluster_id = selected_role_id
     - organization_id = current_org_id
  3. For each competency:
     - Get competency_id and role_competency_value
     - FILTER OUT competencies where role_competency_value = 0
  4. Aggregate results across all selected roles:
     - If multiple roles selected, take MAX(role_competency_value) for each competency
```

**Alternative: Dynamic Calculation from Matrices**
If `role_competency_matrix` is not pre-populated:

```sql
-- Calculate role-competency values dynamically
SELECT
  c.id as competency_id,
  c.competency_name,
  MAX(rpm.role_process_value * pcm.process_competency_value) as required_level
FROM competency c
JOIN process_competency_matrix pcm ON c.id = pcm.competency_id
JOIN role_process_matrix rpm ON pcm.iso_process_id = rpm.iso_process_id
WHERE rpm.role_cluster_id IN (selected_role_ids)
  AND rpm.organization_id = current_org_id
GROUP BY c.id, c.competency_name
HAVING MAX(rpm.role_process_value * pcm.process_competency_value) > 0
ORDER BY c.id;
```

#### Step 4: Present Necessary Competencies
**Display Format:**

| Competency ID | Competency Name | Required Level | Description |
|---------------|-----------------|----------------|-------------|
| 1 | Requirements Engineering | 3 | ... |
| 2 | System Architecture | 2 | ... |
| ... | ... | ... | ... |

**Important:**
- Only show competencies with `required_level > 0`
- Include competency description and "why it matters"
- Show required level clearly (1-4 scale)

### Database Tables Used
- `phase1_roles` - Source of identified roles
- `role_competency_matrix` - Role-to-competency mappings (org-specific)
- `role_process_matrix` - Role-to-process mappings (org-specific)
- `process_competency_matrix` - Process-to-competency mappings (global)
- `competency` - Competency details

### API Endpoints Needed

```python
# GET /api/phase2/identified-roles/<org_id>
# Returns: List of identified roles from Phase 1

# POST /api/phase2/calculate-competencies
# Body: { "org_id": int, "role_ids": [int, int, ...] }
# Returns: { "competencies": [{ "id", "name", "required_level", ... }] }
```

---

## Task 2: Identify Competency Gaps

### Objective
Conduct a competency assessment with **only the necessary competencies** identified in Task 1, reducing survey fatigue.

### Key Changes from Current Implementation

#### Current Implementation
- User answers **16 questions** (1 per competency)
- All 16 SE competencies are assessed

#### New Implementation
- User answers **N questions** (only for competencies from Task 1)
- Only assess competencies with `required_level > 0`
- Example: If only 8 competencies are needed, only 8 questions

### User Flow

#### Step 1: Start Assessment
- **Context:** User has completed Task 1 (role selection + competency calculation)
- **Data Available:**
  - List of necessary competencies (from Task 1)
  - Required competency levels for each

#### Step 2: Dynamic Survey Generation
**Survey Structure:**

```json
{
  "org_id": 123,
  "user_id": 456,
  "assessment_type": "phase2_competency_gap",
  "selected_roles": [1, 3, 5],
  "questions": [
    {
      "competency_id": 1,
      "competency_name": "Requirements Engineering",
      "required_level": 3,
      "question_text": "How would you rate your competency in Requirements Engineering?",
      "options": [
        { "value": 0, "label": "No knowledge" },
        { "value": 1, "label": "Basic awareness" },
        { "value": 2, "label": "Working knowledge" },
        { "value": 3, "label": "Strong competency" },
        { "value": 4, "label": "Expert level" }
      ]
    },
    // ... only questions for identified competencies
  ]
}
```

#### Step 3: Competency Assessment
- User completes survey (existing UI can be reused)
- Answers are stored in `user_se_competency_survey_results` table
- Link to `competency_assessment` table via `assessment_id`

#### Step 4: Calculate Gaps
**Gap Calculation:**

```python
for each competency:
  gap = required_level - current_level

  if gap > 0:
    status = "needs_improvement"
    priority = "high" if gap >= 2 else "medium"
  elif gap == 0:
    status = "meets_requirement"
  else:  # gap < 0
    status = "exceeds_requirement"
```

#### Step 5: Generate LLM Feedback
**Existing Implementation:** `generate_survey_feedback.py`

**Enhancement Needed:**
- Pass additional context:
  - Selected roles
  - Required competency levels
  - Gap analysis results
- Generate targeted feedback focusing on gaps

**LLM Prompt Enhancement:**

```python
context = {
    "user_roles": ["Systems Engineer", "Requirements Engineer"],
    "competency_results": [
        {
            "competency": "Requirements Engineering",
            "required_level": 3,
            "current_level": 2,
            "gap": 1,
            "status": "needs_improvement"
        },
        // ...
    ]
}

prompt = f"""
Given the following competency assessment results for a user in the roles: {roles}

Generate personalized feedback that:
1. Highlights strengths (competencies meeting or exceeding requirements)
2. Identifies gaps (competencies below required level)
3. Prioritizes development areas based on gap severity
4. Provides actionable recommendations

Results:
{json.dumps(competency_results, indent=2)}
"""
```

#### Step 6: Display Results
**Enhanced Results Page:**

```
Competency Assessment Results
=============================

Overall Progress: 75% of required competencies met

STRENGTHS:
✓ System Architecture (Level 3/3) - Meets requirement
✓ System Integration (Level 4/3) - Exceeds requirement

AREAS FOR DEVELOPMENT:
! Requirements Engineering (Level 2/3) - Gap: 1 level
! Verification & Validation (Level 1/3) - Gap: 2 levels [HIGH PRIORITY]

LLM FEEDBACK:
Based on your assessment for the roles of Systems Engineer and Requirements
Engineer, you demonstrate strong competencies in System Architecture and
Integration. However, there are opportunities to develop your skills in...
[full LLM feedback]
```

### For Employee Users: End of Phase 2
After Task 2 completion, employee users have finished their Phase 2 participation.

---

## Task 3: Formulate Learning Objectives (Admin Only)

### Objective
Aggregate all employee competency assessments and generate organization-wide learning objectives using LLM.

### User Flow

#### Step 1: View All Employee Assessments
**Admin Dashboard View:**

```
Organization: XYZ Corp
Phase 2 Assessments: 15/20 employees completed

SUMMARY BY COMPETENCY:

Requirements Engineering:
  - Average Current Level: 2.1
  - Average Required Level: 3.0
  - Gap: 0.9
  - Employees below requirement: 12/15 (80%)

System Architecture:
  - Average Current Level: 2.8
  - Average Required Level: 2.5
  - Gap: -0.3
  - Employees below requirement: 3/15 (20%)

[... for all competencies ...]
```

#### Step 2: Aggregation Logic

```python
def aggregate_competency_gaps(org_id):
    """
    Aggregate all employee assessments for an organization
    """
    results = {
        "org_id": org_id,
        "total_employees": 0,
        "completed_assessments": 0,
        "competency_summary": []
    }

    # Get all assessments for organization
    assessments = CompetencyAssessment.query.filter_by(
        organization_id=org_id,
        status='completed'
    ).all()

    results["completed_assessments"] = len(assessments)

    # For each competency, calculate aggregate statistics
    competencies = Competency.query.all()

    for comp in competencies:
        # Get all results for this competency across all employees
        employee_results = db.session.query(
            UserCompetencySurveyResults.score,
            RoleCompetencyMatrix.role_competency_value
        ).join(
            # ... complex join to get required vs current levels
        ).all()

        if not employee_results:
            continue

        current_levels = [r.score for r in employee_results]
        required_levels = [r.role_competency_value for r in employee_results]

        summary = {
            "competency_id": comp.id,
            "competency_name": comp.competency_name,
            "avg_current_level": np.mean(current_levels),
            "avg_required_level": np.mean(required_levels),
            "avg_gap": np.mean(required_levels) - np.mean(current_levels),
            "std_dev": np.std(current_levels),
            "employees_below_requirement": sum(1 for c, r in zip(current_levels, required_levels) if c < r),
            "total_employees_assessed": len(current_levels)
        }

        results["competency_summary"].append(summary)

    # Sort by gap (largest gaps first = highest priority)
    results["competency_summary"].sort(key=lambda x: x["avg_gap"], reverse=True)

    return results
```

#### Step 3: Generate Learning Objectives with LLM

**LLM Prompt for Learning Objectives:**

```python
def generate_learning_objectives(aggregated_data):
    """
    Use LLM to generate learning objectives based on aggregated competency gaps
    """

    prompt = f"""
You are an expert in Systems Engineering education and organizational learning.

Given the following competency gap analysis for an organization:

Organization Size: {org_size}
Total Employees Assessed: {total_employees}
SE Maturity Level: {maturity_level}

COMPETENCY GAP SUMMARY (sorted by priority):
{format_competency_summary(aggregated_data)}

Generate a comprehensive learning objective plan with:

1. PRIORITIZED COMPETENCIES (Top 3-5 based on gap severity and impact)
   - Why this competency is critical
   - Current state vs. desired state

2. LEARNING OBJECTIVES (following Bloom's taxonomy)
   For each priority competency, create 2-3 specific, measurable learning objectives.
   Format: "By the end of training, learners will be able to [action verb] [what] [how/context]"

   Example:
   - "Analyze stakeholder requirements to identify conflicts and dependencies using
      structured elicitation techniques"
   - "Apply requirements traceability methods to maintain consistency across system
      lifecycle phases"

3. SUGGESTED LEARNING FORMATS
   Based on organization size and maturity:
   - Workshops
   - E-learning modules
   - Mentoring programs
   - Train-the-trainer

4. IMPLEMENTATION ROADMAP
   Suggest phased approach based on priority and dependencies

Format the output as structured JSON.
"""

    # Call OpenAI API
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are an expert SE education consultant."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7
    )

    return response.choices[0].message.content
```

**Expected Output Structure:**

```json
{
  "priority_competencies": [
    {
      "competency_id": 1,
      "competency_name": "Requirements Engineering",
      "priority_rank": 1,
      "rationale": "80% of employees below required level, critical for project success",
      "current_state": "Average level 2.1 (Working knowledge)",
      "target_state": "Average level 3.0 (Strong competency)",
      "gap_severity": "high"
    },
    // ... top 3-5 competencies
  ],
  "learning_objectives": [
    {
      "competency_id": 1,
      "competency_name": "Requirements Engineering",
      "objectives": [
        {
          "id": "LO-RE-01",
          "objective": "Analyze stakeholder requirements to identify conflicts and dependencies using structured elicitation techniques",
          "bloom_level": "Analyze",
          "assessment_method": "Case study analysis"
        },
        {
          "id": "LO-RE-02",
          "objective": "Create comprehensive requirements specifications that address functional, non-functional, and constraint requirements",
          "bloom_level": "Create",
          "assessment_method": "Requirements document review"
        }
      ]
    },
    // ... for each priority competency
  ],
  "learning_formats": [
    {
      "format": "Workshop (2-day intensive)",
      "competencies_covered": ["Requirements Engineering", "System Architecture"],
      "target_audience": "All Systems Engineers",
      "prerequisites": "Basic SE knowledge"
    },
    {
      "format": "E-learning modules",
      "competencies_covered": ["Configuration Management", "Quality Assurance"],
      "target_audience": "All roles",
      "prerequisites": "None"
    }
  ],
  "implementation_roadmap": {
    "phase_1": {
      "duration": "Months 1-3",
      "focus": "Critical gaps (Requirements Engineering, V&V)",
      "deliverables": ["Workshop series", "E-learning modules"]
    },
    "phase_2": {
      "duration": "Months 4-6",
      "focus": "Secondary priorities",
      "deliverables": ["Mentoring program", "Advanced workshops"]
    },
    "phase_3": {
      "duration": "Months 7-12",
      "focus": "Continuous improvement and reassessment",
      "deliverables": ["Follow-up assessments", "Refresher training"]
    }
  }
}
```

#### Step 4: Store and Display Learning Objectives

**Storage:** Update `competency_assessment` table:

```python
# Update the organization's master assessment record
master_assessment = CompetencyAssessment.query.filter_by(
    organization_id=org_id,
    assessment_type='organization_master'
).first()

if not master_assessment:
    master_assessment = CompetencyAssessment(
        organization_id=org_id,
        assessment_type='organization_master'
    )
    db.session.add(master_assessment)

master_assessment.learning_objectives = learning_objectives_json
master_assessment.objectives_generated_at = datetime.utcnow()
master_assessment.status = 'completed'

db.session.commit()
```

**Display:**
- Create admin-only view for learning objectives
- Show prioritized competencies
- Display learning objectives with details
- Provide export functionality (PDF, Excel)

---

## Database Schema Additions/Modifications

### New Tables (if needed)

None required - existing tables sufficient:
- `competency_assessment` - already has `learning_objectives` JSONB field
- `user_se_competency_survey_results` - already has `assessment_id` link
- `user_competency_survey_feedback` - already has `assessment_id` link

### Modified Workflows

#### Existing CompetencyAssessment Model
Already has required fields:
- `assessment_type` - can distinguish phase2 assessments
- `selected_roles` - stores Task 1 role selections
- `learning_objectives` - stores Task 3 LLM output
- `status` - tracks progress

---

## Frontend Views Required

### Task 1 Views

1. **Role Selection Page** (`Phase2RoleSelection.vue`)
   - Display identified roles from Phase 1
   - Multi-select interface
   - Confirm button to calculate competencies

2. **Necessary Competencies Page** (`Phase2NecessaryCompetencies.vue`)
   - Display calculated competencies
   - Show required levels
   - "Start Assessment" button to proceed to Task 2

### Task 2 Views

3. **Dynamic Competency Survey** (`Phase2CompetencySurvey.vue`)
   - Reuse existing survey component
   - Dynamically generate questions based on Task 1 results
   - Submit to modified endpoint

4. **Enhanced Results Page** (`Phase2AssessmentResults.vue`)
   - Show strengths and gaps clearly
   - Display required vs. current levels
   - Show LLM feedback
   - For employees: End of journey message
   - For admins: Option to continue to Task 3

### Task 3 Views (Admin Only)

5. **Employee Assessment Dashboard** (`Phase2AdminDashboard.vue`)
   - List all employee assessments
   - Show completion status
   - Aggregate statistics per competency
   - "Generate Learning Objectives" button

6. **Learning Objectives View** (`Phase2LearningObjectives.vue`)
   - Display LLM-generated learning objectives
   - Show priority competencies
   - Implementation roadmap
   - Export functionality

---

## API Endpoints Summary

### Task 1: Determine Necessary Competencies

```python
# GET /api/phase2/identified-roles/<org_id>
# Returns: List of roles from phase1_roles

# POST /api/phase2/calculate-competencies
# Body: { "org_id": int, "role_ids": [int, ...] }
# Returns: { "competencies": [...], "selected_roles": [...] }

# POST /api/phase2/save-role-selection
# Body: { "org_id": int, "user_id": int, "role_ids": [int, ...] }
# Returns: { "assessment_id": int }
```

### Task 2: Identify Competency Gaps

```python
# GET /api/phase2/assessment-questions/<assessment_id>
# Returns: { "questions": [...] }  # Only for necessary competencies

# POST /api/phase2/submit-assessment
# Body: { "assessment_id": int, "answers": [...] }
# Returns: { "results": {...}, "feedback": {...} }

# GET /api/phase2/assessment-results/<assessment_id>
# Returns: Full results with gaps and LLM feedback
```

### Task 3: Formulate Learning Objectives (Admin)

```python
# GET /api/phase2/admin/assessment-summary/<org_id>
# Returns: Aggregated results for all employees

# POST /api/phase2/admin/generate-learning-objectives
# Body: { "org_id": int }
# Returns: { "learning_objectives": {...} }

# GET /api/phase2/admin/learning-objectives/<org_id>
# Returns: Stored learning objectives for organization

# GET /api/phase2/admin/export-learning-objectives/<org_id>?format=pdf
# Returns: PDF or Excel export
```

---

## Implementation Phases

### Phase A: Task 1 Implementation (Week 1-2)
1. Backend: API endpoints for role retrieval and competency calculation
2. Frontend: Role selection and necessary competencies display
3. Testing: Verify dynamic calculation works correctly

### Phase B: Task 2 Implementation (Week 3-4)
1. Backend: Modified survey generation and gap calculation
2. Frontend: Dynamic survey and enhanced results page
3. LLM Integration: Enhanced feedback generation
4. Testing: Full employee workflow (Task 1 → Task 2)

### Phase C: Task 3 Implementation (Week 5-6)
1. Backend: Aggregation logic and LLM learning objectives
2. Frontend: Admin dashboard and learning objectives view
3. Export functionality
4. Testing: Full admin workflow (Task 1 → Task 2 → Task 3)

### Phase D: Integration and Testing (Week 7)
1. End-to-end testing
2. UI/UX refinement
3. Documentation
4. Deployment

---

## Key Considerations

### 1. Role-Competency Matrix Population
**Question:** Is `role_competency_matrix` pre-populated for each organization?
- **If YES:** Use direct queries
- **If NO:** Calculate dynamically from role_process_matrix × process_competency_matrix

### 2. Survey Fatigue Reduction
- Current: 16 questions always
- New: 3-12 questions typically (based on role requirements)
- Benefit: Better user experience, higher completion rates

### 3. LLM Token Usage
- Task 2: Individual feedback (existing pattern)
- Task 3: Organization-level summary (new, higher token usage)
- Consider: Caching, batch processing for large orgs

### 4. Data Persistence
- Link all Task 2 results to `competency_assessment.id`
- Store Task 1 selections in `selected_roles` JSONB field
- Store Task 3 objectives in `learning_objectives` JSONB field

### 5. User Experience Flow
```
EMPLOYEE USER:
Phase 1 (completed) → Task 1: Select Roles → Task 2: Assessment → END

ADMIN USER:
Phase 1 (completed) → Task 1: Select Roles → Task 2: Assessment →
Task 3: View All Employees → Generate Learning Objectives → Export
```

---

## Files to Reference

### Derik's Implementation (sesurveyapp-main)
- Review for existing competency assessment patterns
- Understand LLM feedback generation approach
- UI/UX patterns for results display

### Current Codebase
- `src/competency_assessor/app/models.py` - Database models
- `src/competency_assessor/app/routes.py` - Existing API endpoints
- `src/competency_assessor/app/generate_survey_feedback.py` - LLM feedback logic
- `src/frontend/src/components/SurveyResults.vue` - Results display

---

## Success Metrics

### Task 1
- [ ] Correctly retrieve Phase 1 roles
- [ ] Accurately calculate necessary competencies
- [ ] Filter out competencies with required_level = 0
- [ ] Support multi-role selection

### Task 2
- [ ] Dynamic survey generation (only necessary competencies)
- [ ] Accurate gap calculation
- [ ] Enhanced LLM feedback with role context
- [ ] Clear display of strengths and development areas

### Task 3
- [ ] Accurate aggregation across all employees
- [ ] Meaningful learning objectives from LLM
- [ ] Actionable implementation roadmap
- [ ] Export functionality works

---

## Next Steps

1. **Review and validate** this reference document
2. **Clarify** role_competency_matrix population approach
3. **Start with Task 1** backend implementation
4. **Iterate** through Phases A → B → C → D

---

**Document Status:** DRAFT v1.0
**Last Updated:** 2025-10-20
**Ready for Implementation:** Pending review and clarification
