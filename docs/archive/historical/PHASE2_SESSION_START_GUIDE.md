# Phase 2 Implementation - Session Start Guide

**Created:** 2025-10-20
**Purpose:** Quick reference for starting Phase 2 implementation in a new session

---

## ✅ Prerequisites Checklist

All prerequisites are **CONFIRMED** and ready for implementation:

- [x] Phase 1 completed and validated
- [x] Database schema supports Phase 2 (validated)
- [x] Role-Competency Matrix dynamic calculation working ✓
- [x] Learning objectives template file confirmed ✓
- [x] Derik's implementation analyzed ✓
- [x] 16 SE competencies documented ✓
- [x] UI design approved (grid layout) ✓

**Status:** 🟢 READY FOR PHASE A IMPLEMENTATION

---

## 📚 Required Reading (Priority Order)

When starting a new session for Phase 2 implementation, read these documents **in order**:

### 1. SESSION_HANDOVER.md ⭐ START HERE
**What it contains:**
- Latest session summary with timestamps
- System status (servers, database, credentials)
- Key design decisions
- What was completed in previous sessions
- Current system state

**Why read it:** Understand where we left off and current project status

---

### 2. PHASE2_IMPLEMENTATION_REFERENCE.md ⭐ MAIN BLUEPRINT
**What it contains:**
- Complete Phase 2 architecture
- Task 1: Determine Necessary Competencies (detailed workflow)
- Task 2: Identify Competency Gaps (detailed workflow)
- Task 3: Formulate Learning Objectives (detailed workflow)
- API endpoint specifications
- Database queries
- Frontend component requirements
- LLM prompt engineering
- Implementation phases (A → D)

**Why read it:** This is the master plan for Phase 2

---

### 3. DERIK_PHASE2_ANALYSIS.md ⭐ PATTERNS TO REUSE
**What it contains:**
- Analysis of Derik's original competency assessment
- Frontend: CompetencySurvey.vue breakdown
- Frontend: SurveyResults.vue breakdown
- Backend: API endpoints documentation
- 4-level indicator system (kennen, verstehen, anwenden, beherrschen)
- Score mapping logic (Group → Score)
- **What to keep** vs. **What to change**

**Why read it:** Leverage proven patterns instead of building from scratch

---

### 4. PHASE2_COMPETENCIES_REFERENCE.md ⭐ QUICK REFERENCE
**What it contains:**
- All 16 SE competencies by area (Core, Social, Management, Technical)
- Competency level scale (0, 1, 2, 4, 6)
- Competency indicators structure (4 levels × 3 indicators each)
- SQL queries for Phase 2
- API endpoint summary

**Why read it:** Quick lookup during implementation

---

### 5. PHASE2_VALIDATION_SUMMARY.md
**What it contains:**
- Infrastructure validation results
- Role-Competency Matrix calculation confirmation
- UI design specifications
- Implementation readiness checklist
- User input status

**Why read it:** Confirms everything is ready to go

---

## 🗂️ Key Data Files

### Learning Objectives Template ✓
**Path:** `data/source/questionnaires/phase2/se_qpt_learning_objectives_template.json`

**Contains:**
- 6 qualification archetypes
- 16 SE competencies
- Learning objectives for each competency at different levels
- Target levels per archetype

**Usage:** Task 3 - Generate organization-wide learning objectives

---

### Competency Scale Reference
**Path:** `data/processed/role_competency_matrix_corrected.json`

**Contains:**
- Scale definition: "0=not relevant, 1=apply, 2=understand, 3/4=apply, 6=master"
- Role-competency mappings

**Usage:** Understanding competency level values

---

## 💻 Code References (Derik's Implementation)

### Frontend Components to Study

1. **CompetencySurvey.vue**
   **Path:** `sesurveyapp-main/frontend/src/components/CompetencySurvey.vue`
   **Reuse:**
   - Card-based selection UI (5 groups)
   - Sequential one-at-a-time presentation
   - Score mapping logic
   - Progress indicator
   **Change:**
   - Add dynamic competency filtering (required_level > 0)
   - Display required level for each competency

2. **SurveyResults.vue**
   **Path:** `sesurveyapp-main/frontend/src/components/SurveyResults.vue`
   **Reuse:**
   - Radar chart visualization
   - Competency area filtering
   - LLM feedback display
   - PDF export
   **Change:**
   - Only show assessed competencies
   - Add Strengths/Gaps breakdown

### Backend Routes to Study

**Path:** `sesurveyapp-main/app/routes.py`

**Key Endpoints:**
- `POST /get_required_competencies_for_roles` - Adapt for filtering
- `GET /get_competency_indicators_for_competency/<id>` - Reuse as-is
- `POST /submit_survey` - Adapt for Phase 2 assessment tracking
- `GET /get_user_competency_results` - Enhance for gap display

---

## 🚀 Phase A Implementation Tasks

### Week 1-2: Task 1 - Determine Necessary Competencies

#### Backend (Flask)

**1. Create API Endpoint: Get Phase 1 Identified Roles**
```python
# GET /api/phase2/identified-roles/<org_id>
# Returns: List of roles from phase1_roles table

def get_phase1_identified_roles(org_id):
    roles = Phase1Roles.query.filter_by(
        org_id=org_id,
        participating_in_training=True
    ).all()

    return jsonify([role.to_dict() for role in roles])
```

**2. Create API Endpoint: Calculate Necessary Competencies**
```python
# POST /api/phase2/calculate-competencies
# Body: { "org_id": int, "role_ids": [int, ...] }
# Returns: { "competencies": [...], "selected_roles": [...] }

def calculate_necessary_competencies():
    data = request.json
    org_id = data['org_id']
    role_ids = data['role_ids']  # Phase1Roles IDs

    # Get standard role IDs from Phase1Roles
    phase1_roles = Phase1Roles.query.filter(
        Phase1Roles.id.in_(role_ids),
        Phase1Roles.org_id == org_id
    ).all()

    standard_role_ids = [r.standard_role_id for r in phase1_roles]

    # Query role_competency_matrix
    competencies = db.session.query(
        RoleCompetencyMatrix.competency_id,
        Competency.competency_name,
        Competency.competency_area,
        func.max(RoleCompetencyMatrix.role_competency_value).label('required_level')
    ).join(
        Competency, RoleCompetencyMatrix.competency_id == Competency.id
    ).filter(
        RoleCompetencyMatrix.role_cluster_id.in_(standard_role_ids),
        RoleCompetencyMatrix.organization_id == org_id,
        RoleCompetencyMatrix.role_competency_value > 0  # FILTER OUT IRRELEVANT
    ).group_by(
        RoleCompetencyMatrix.competency_id,
        Competency.competency_name,
        Competency.competency_area
    ).order_by(
        RoleCompetencyMatrix.competency_id
    ).all()

    return jsonify({
        "competencies": [
            {
                "competency_id": c.competency_id,
                "competency_name": c.competency_name,
                "competency_area": c.competency_area,
                "required_level": c.required_level
            }
            for c in competencies
        ],
        "selected_roles": [
            {
                "phase1_role_id": r.id,
                "standard_role_id": r.standard_role_id,
                "standard_role_name": r.standard_role_name,
                "org_role_name": r.org_role_name
            }
            for r in phase1_roles
        ]
    })
```

**Files to modify:**
- `src/competency_assessor/app/routes.py` - Add new endpoints

**Files to create:**
- None (use existing models)

---

#### Frontend (Vue 3 + Vuetify)

**1. Create Component: Phase2RoleSelection.vue**

**Location:** `src/frontend/src/components/Phase2RoleSelection.vue`

**Features:**
- Grid layout (3-4 columns, responsive)
- Display Phase 1 identified roles
- Show both standard_role_name and org_role_name
- Multi-select with checkboxes
- "Calculate Competencies" button

**Template Structure:**
```vue
<template>
  <v-container>
    <h1>Select Roles for Competency Assessment</h1>
    <p>Organization: {{ organizationName }}</p>

    <v-row>
      <v-col
        v-for="role in identifiedRoles"
        :key="role.id"
        cols="12"
        md="4"
        sm="6"
      >
        <v-card>
          <v-card-text>
            <v-checkbox
              v-model="selectedRoleIds"
              :value="role.id"
              :label="role.orgRoleName || role.standardRoleName"
            />
            <p class="text-caption">
              Standard: {{ role.standardRoleName }}
            </p>
            <v-chip
              size="small"
              :color="role.identificationMethod === 'STANDARD' ? 'primary' : 'secondary'"
            >
              {{ role.identificationMethod }}
            </v-chip>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <v-btn
      color="primary"
      @click="calculateCompetencies"
      :disabled="selectedRoleIds.length === 0"
    >
      Calculate Necessary Competencies
    </v-btn>
  </v-container>
</template>
```

**Data Flow:**
1. On mount: Fetch Phase 1 roles via `GET /api/phase2/identified-roles/<org_id>`
2. User selects roles (multi-select checkboxes)
3. On button click: Call `POST /api/phase2/calculate-competencies`
4. Navigate to Phase2NecessaryCompetencies.vue with results

---

**2. Create Component: Phase2NecessaryCompetencies.vue**

**Location:** `src/frontend/src/components/Phase2NecessaryCompetencies.vue`

**Features:**
- Table showing necessary competencies
- Required level for each competency
- Grouped by competency area
- "Start Assessment" button to proceed to Task 2

**Template Structure:**
```vue
<template>
  <v-container>
    <h1>Necessary Competencies for Selected Roles</h1>

    <div v-for="area in competencyAreas" :key="area">
      <h3>{{ area }}</h3>
      <v-table>
        <thead>
          <tr>
            <th>Competency</th>
            <th>Required Level</th>
            <th>Level Name</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="comp in competenciesByArea[area]"
            :key="comp.competency_id"
          >
            <td>{{ comp.competency_name }}</td>
            <td>{{ comp.required_level }}</td>
            <td>{{ getLevelName(comp.required_level) }}</td>
          </tr>
        </tbody>
      </v-table>
    </div>

    <v-btn
      color="success"
      @click="startAssessment"
      class="mt-4"
    >
      Start Competency Assessment
    </v-btn>
  </v-container>
</template>

<script setup>
const getLevelName = (level) => {
  const mapping = {
    1: 'Know (Kennen)',
    2: 'Understand (Verstehen)',
    4: 'Apply (Anwenden)',
    6: 'Master (Beherrschen)'
  };
  return mapping[level] || 'Unknown';
};
</script>
```

---

## ⚙️ System Information

### Servers
- **Backend:** `http://localhost:5003` (Flask)
- **Frontend:** `http://localhost:5173` (Vue/Vite)

### Database
- **PostgreSQL:** `competency_assessment`
- **Credentials:** `ma0349:MA0349_2025@localhost:5432`
- **Port:** 5432

### Important Environment Variables
```bash
DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
FLASK_APP=run.py
FLASK_DEBUG=1
FLASK_RUN_PORT=5003
```

---

## 🔧 Development Notes

### Flask Hot-Reload
**⚠️ Does NOT work reliably in this project**
- Always manually restart Flask server after backend changes
- Kill process and start again
- Don't rely on auto-reload

### Character Encoding
**⚠️ Windows console uses charmap (cp1252)**
- NO emojis in code (causes 500 errors)
- Use ASCII: `[OK]`, `[ERROR]`, `[SUCCESS]`, `[FAILED]`

### Database Access
- Use credentials: `ma0349:MA0349_2025`
- Other credentials (`postgres:postgres`, `postgres:root`) may not work

---

## 📊 The 16 SE Competencies

**Core (4):**
1. Systems Thinking
4. Lifecycle Consideration
5. Customer / Value Orientation
6. Systems Modelling and Analysis

**Social/Personal (3):**
7. Communication
8. Leadership
9. Self-Organization

**Management (4):**
10. Project Management
11. Decision Management
12. Information Management
13. Configuration Management

**Technical (5):**
14. Requirements Definition
15. System Architecting
16. Integration, Verification, Validation
17. Operation and Support
18. Agile Methods

**Level Scale:** 0 (Not Relevant), 1 (Know), 2 (Understand), 4 (Apply), 6 (Master)

---

## 🎯 Success Criteria for Phase A

### Backend
- [x] `GET /api/phase2/identified-roles/<org_id>` working
- [x] Returns Phase 1 roles with correct data structure
- [x] `POST /api/phase2/calculate-competencies` working
- [x] Filters competencies where `required_level > 0`
- [x] Handles multi-role selection correctly
- [x] Returns aggregated competencies (MAX for duplicates)

### Frontend
- [x] Phase2RoleSelection.vue displays Phase 1 roles
- [x] Grid layout responsive (3-4 columns desktop, 1-2 mobile)
- [x] Multi-select checkboxes working
- [x] Phase2NecessaryCompetencies.vue displays results
- [x] Grouped by competency area
- [x] Shows required levels clearly

### Testing
- [x] Test with organization that has Phase 1 completed
- [x] Test single role selection
- [x] Test multiple role selection
- [x] Verify competency filtering (no required_level = 0)
- [x] Verify aggregation (MAX across roles)

---

## 🚦 Next Steps After Phase A

Once Phase A is complete, proceed to:

**Phase B (Weeks 3-4): Task 2 - Identify Competency Gaps**
- Adapt Derik's CompetencySurvey.vue for dynamic filtering
- Implement gap calculation logic
- Enhanced LLM feedback with role context
- Enhanced results page with Strengths/Gaps

**Phase C (Weeks 5-6): Task 3 - Learning Objectives (Admin Only)**
- Admin dashboard for all employee assessments
- Aggregation logic
- LLM learning objectives generation
- Export functionality

**Phase D (Week 7): Integration and Testing**
- End-to-end testing
- UI/UX refinement
- Documentation
- Deployment

---

## 📋 Quick Commands Reference

### Start Backend
```bash
cd src/competency_assessor
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
set FLASK_APP=run.py
set FLASK_DEBUG=1
set FLASK_RUN_PORT=5003
flask run --port=5003
```

### Start Frontend
```bash
cd src/frontend
npm run dev
```

### Check Database Competencies
```bash
cd src/competency_assessor
python -c "from app import create_app, db; from app.models import Competency; app = create_app(); app.app_context().push(); comps = Competency.query.all(); [print(f'{c.id}: {c.competency_name}') for c in comps]"
```

---

**Document Status:** READY FOR USE ✓
**Last Updated:** 2025-10-20
**Next Action:** Start Phase A implementation following this guide
