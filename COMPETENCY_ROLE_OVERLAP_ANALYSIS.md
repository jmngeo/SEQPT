# Competency, Role & Assessment Data Overlap Analysis
**SE-QPT vs Derik's Competency Assessor - Complete Data Audit**

## 🎯 Executive Summary

**MAJOR DUPLICATIONS FOUND!** Both systems define:
- ✅ **Competencies** (16 SE competencies) - **USE DERIK'S**
- ✅ **Roles** (14-16 role clusters) - **USE DERIK'S**
- ⚠️ **Assessment Results** (overlapping storage) - **USE DERIK'S with extensions**
- ❌ **Learning Plans** (only in SE-QPT) - **KEEP SE-QPT's**

**Recommendation**: Use Derik's competency/role master data + Derik's assessment storage, extend for learning objectives.

---

## 📊 Detailed Side-by-Side Comparison

### 1. **COMPETENCIES** - COMPLETE OVERLAP ⚠️

#### **Derik's System** (EXISTING, VALIDATED)
```sql
Table: competency
- id (INTEGER, auto-increment)
- competency_name (VARCHAR 255) ✅ 16 competencies loaded
- competency_area (VARCHAR 50)    ✅ "Core", "Technical", "Management", etc.
- description (TEXT)
- why_it_matters (TEXT)

Referenced by:
  - competency_indicators (validation questions)
  - role_competency_matrix (role-competency mappings)
  - process_competency_matrix (process-competency mappings)
  - user_se_competency_survey_results (assessment results)
```

**Data**: 16 INCOSE competencies already loaded:
1. Systems Thinking
2. Lifecycle Consideration
3. Customer / Value Orientation
4. Systems Modeling and Analysis
5. Communication
6. Leadership
7. Self-Organization
8. Project Management
9. Decision Management
10. Information Management
11. Configuration Management
12. Requirements Definition
13. System Architecting
14. Integration, Verification, Validation
15. Operation and Support
16. Agile Methods

#### **SE-QPT System** (DUPLICATE)
```python
Table: se_competencies
- id (INTEGER)
- name (VARCHAR 100) ❌ Same 16 competencies
- code (VARCHAR 10)
- category (VARCHAR 50)
- description (TEXT)
- incose_reference (VARCHAR 50)
- level_definitions (TEXT/JSON)
- assessment_indicators (TEXT/JSON)
```

**Status**: ❌ **COMPLETE DUPLICATE** - Same 16 INCOSE competencies

---

### 2. **ROLES** - COMPLETE OVERLAP ⚠️

#### **Derik's System** (EXISTING, VALIDATED)
```sql
Table: role_cluster
- id (INTEGER)
- role_cluster_name (VARCHAR 255) ✅ 16 roles loaded
- role_cluster_description (TEXT)

Referenced by:
  - role_competency_matrix (which competencies each role needs)
  - role_process_matrix (which ISO processes each role performs)
  - user_role_cluster (user-role assignments)
```

**Data**: 16 role clusters already loaded:
1. Customer
2. Customer Representative
3. Project Manager
4. System Engineer
5. Specialist Developer
6. Production Planner/Coordinator
7. Production Employee
8. Quality Engineer/Manager
9. Verification and Validation (V&V) Operator
10. Service Technician
11. Process and Policy Manager
12. Internal Support
13. Innovation Management
14. Management
15. Unknown_Role
16. All_Roles

#### **SE-QPT System** (DUPLICATE)
```python
Table: se_roles
- id (INTEGER)
- name (VARCHAR 100) ❌ Similar role clusters
- description (TEXT)
- typical_responsibilities (TEXT/JSON)
- career_level (VARCHAR 50)
- primary_focus (VARCHAR 100)
- typical_experience_years (INTEGER)
```

**Status**: ❌ **COMPLETE DUPLICATE** - Same/similar 14-16 role clusters

---

### 3. **ASSESSMENT RESULTS** - PARTIAL OVERLAP ⚠️

#### **Derik's System** (OPERATIONAL)
```sql
Table: user_se_competency_survey_results
- id (INTEGER)
- user_id (INTEGER) → app_user.id
- organization_id (INTEGER) → organization.id
- competency_id (INTEGER) → competency.id
- score (INTEGER) ✅ Actual assessment score
- submitted_at (TIMESTAMP)

Purpose: Stores individual competency assessment scores (16 scores per user)
Status: ✅ Already collecting data from Derik's survey
```

#### **SE-QPT System** (NEW)
```python
Table: competency_assessments
- id (UUID)
- user_id (UUID) → mvp_users.id
- competency_scores (TEXT/JSON) ❌ Redundant storage
  Format: {competency_name: {current: X, target: Y, gap: Z}}
- role_cluster (VARCHAR 100)
- completed_at (TIMESTAMP)

Additional SE-QPT tables:
- assessments (general assessment tracking)
- competency_assessment_results (detailed per-competency results)
```

**Status**: ⚠️ **PARTIAL OVERLAP**
- Derik stores raw scores
- SE-QPT stores scores + gaps + targets
- **Both are storing competency assessment data!**

---

### 4. **ROLE ASSIGNMENT** - OVERLAP ⚠️

#### **Derik's System**
```sql
Table: user_role_cluster
- (Implied: maps users to role clusters)

Also:
- Derik's RAG can identify roles from job descriptions
```

#### **SE-QPT System**
```python
Table: role_mappings
- id (UUID)
- user_id (UUID)
- assigned_role_cluster (VARCHAR 100)
- confidence (FLOAT)
- mapping_data (TEXT/JSON)
```

**Status**: ⚠️ **OVERLAP** - Both assign users to roles

---

### 5. **LEARNING PLANS** - SE-QPT ONLY ✅

#### **SE-QPT System** (UNIQUE)
```python
Table: learning_plans
- id (UUID)
- user_id (UUID)
- objectives (TEXT/JSON) ✅ SMART learning objectives
- recommended_modules (TEXT/JSON)
- estimated_duration_weeks (INTEGER)
- archetype_used (VARCHAR 100)
- created_at (TIMESTAMP)

Purpose: Store generated SMART learning objectives
```

**Status**: ✅ **NO OVERLAP** - This is SE-QPT's innovation (RAG-LLM objectives)

---

## 🚨 Critical Issues Summary

| Data Type | Derik's System | SE-QPT System | Issue | Recommendation |
|-----------|---------------|---------------|-------|----------------|
| **Competencies** | `competency` table (16 rows) | `se_competencies` table | ❌ Complete duplicate | **DELETE SE-QPT table, use Derik's** |
| **Roles** | `role_cluster` table (16 rows) | `se_roles` table | ❌ Complete duplicate | **DELETE SE-QPT table, use Derik's** |
| **Assessment Scores** | `user_se_competency_survey_results` | `competency_assessments` | ⚠️ Redundant storage | **Use Derik's, extend with gap fields** |
| **Role Assignment** | `user_role_cluster` | `role_mappings` | ⚠️ Overlap | **Use Derik's table** |
| **Learning Plans** | ❌ Not present | `learning_plans` | ✅ No conflict | **Keep SE-QPT's** |
| **Organization** | `organization` table | `organizations` table | ❌ Duplicate | **Use Derik's (covered in prev analysis)** |

---

## ✅ Recommended Unified Architecture

### **Master Data (READ-ONLY from Derik)**

```python
# Use Derik's tables directly - DO NOT duplicate

class Competency(db.Model):
    """Derik's 16 SE competencies - READ ONLY"""
    __tablename__ = 'competency'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    competency_name = db.Column(db.String(255), nullable=False)
    competency_area = db.Column(db.String(50))
    description = db.Column(db.Text)
    why_it_matters = db.Column(db.Text)

    # DO NOT add/edit - Derik manages this data


class RoleCluster(db.Model):
    """Derik's 16 role clusters - READ ONLY"""
    __tablename__ = 'role_cluster'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False)
    role_cluster_description = db.Column(db.Text, nullable=False)

    # DO NOT add/edit - Derik manages this data
```

### **Assessment Data (EXTEND Derik's tables)**

```sql
-- Option A: Add gap analysis fields to Derik's existing table
ALTER TABLE user_se_competency_survey_results
  ADD COLUMN target_level INTEGER,      -- Target level from archetype
  ADD COLUMN gap_size INTEGER,           -- Calculated gap
  ADD COLUMN archetype_source VARCHAR(100);  -- Which archetype defined target

-- Now we have:
-- - Derik's original: user_id, competency_id, score (current level)
-- - SE-QPT additions: target_level, gap_size, archetype_source
```

OR

```sql
-- Option B: Create SE-QPT gap analysis as separate table
CREATE TABLE competency_gap_analysis (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES app_user(id),
  competency_id INTEGER REFERENCES competency(id),
  organization_id INTEGER REFERENCES organization(id),

  -- Link to Derik's assessment
  survey_result_id INTEGER REFERENCES user_se_competency_survey_results(id),

  -- Gap analysis (SE-QPT specific)
  current_level INTEGER,  -- From Derik's survey
  target_level INTEGER,   -- From archetype matrix
  gap_size INTEGER,       -- Calculated
  archetype_used VARCHAR(100),

  -- Timestamps
  analyzed_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(user_id, competency_id, survey_result_id)
);
```

### **Learning Plans (SE-QPT ONLY)**

```python
class LearningPlan(db.Model):
    """SE-QPT learning plans - KEEP AS IS"""
    __tablename__ = 'learning_plans'

    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'))  # Reference Derik's users
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))

    # Learning objectives (RAG-LLM generated)
    objectives = db.Column(db.Text)  # JSON
    recommended_modules = db.Column(db.Text)  # JSON
    estimated_duration_weeks = db.Column(db.Integer)
    archetype_used = db.Column(db.String(100))

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```

---

## 🔄 Migration Strategy

### **Step 1: Delete SE-QPT Duplicates**

```python
# DELETE these tables completely:
# - se_competencies (use Derik's competency)
# - se_roles (use Derik's role_cluster)
# - role_mappings (use Derik's user_role_cluster)

# MODIFY these models to reference Derik's tables:
class CompetencyAssessmentResult(db.Model):
    # BEFORE
    competency_id = db.Column(db.Integer, db.ForeignKey('se_competencies.id'))

    # AFTER
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'))
```

### **Step 2: Extend Derik's Assessment Table (Option A - SIMPLER)**

```sql
-- Add Phase 2 gap analysis fields
ALTER TABLE user_se_competency_survey_results
  ADD COLUMN IF NOT EXISTS target_level INTEGER,
  ADD COLUMN IF NOT EXISTS gap_size INTEGER,
  ADD COLUMN IF NOT EXISTS archetype_source VARCHAR(100),
  ADD COLUMN IF NOT EXISTS learning_plan_id VARCHAR(36);  -- Link to learning_plans

-- Create index for gap queries
CREATE INDEX IF NOT EXISTS idx_survey_results_gaps
  ON user_se_competency_survey_results(user_id, gap_size);
```

### **Step 3: Update Backend to Use Unified Models**

```python
# src/backend/models.py or mvp_models.py

# REMOVE these classes:
# - class SECompetency
# - class SERole
# - class CompetencyAssessmentResult (from old assessments table)

# ADD references to Derik's tables:
from competency_assessor.app.models import (
    Competency,           # Derik's competency table
    RoleCluster,          # Derik's role_cluster table
    Organization          # Derik's organization table
)

# Or define as SQLAlchemy models pointing to Derik's tables:
class Competency(db.Model):
    __tablename__ = 'competency'
    __table_args__ = {'extend_existing': True}
    # Define columns but don't manage data

class UserCompetencySurveyResult(db.Model):
    """Derik's survey results - extended for SE-QPT"""
    __tablename__ = 'user_se_competency_survey_results'
    __table_args__ = {'extend_existing': True}

    # Derik's original fields
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'))
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'))
    score = db.Column(db.Integer, nullable=False)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)

    # SE-QPT extensions (new columns)
    target_level = db.Column(db.Integer)
    gap_size = db.Column(db.Integer)
    archetype_source = db.Column(db.String(100))
    learning_plan_id = db.Column(db.String(36), db.ForeignKey('learning_plans.id'))

    # Relationships
    competency = db.relationship('Competency', backref='survey_results')
    organization = db.relationship('Organization')
    user = db.relationship('AppUser')
```

### **Step 4: Update API Routes**

```python
# Phase 2 Competency Assessment Flow

@app.route('/api/phase2/complete-assessment', methods=['POST'])
def complete_phase2_assessment():
    """
    Process completed competency assessment
    Uses Derik's survey submission + SE-QPT gap analysis
    """
    data = request.get_json()
    user_id = data['user_id']
    organization_id = data['organization_id']
    survey_responses = data['responses']  # 16 competency scores

    # 1. Submit to Derik's system (stores in user_se_competency_survey_results)
    derik_response = requests.post('/api/derik/submit_survey', json={
        'user_id': user_id,
        'organization_id': organization_id,
        'responses': survey_responses
    })

    # 2. Get organization's selected archetype
    org = Organization.query.get(organization_id)
    archetype = org.selected_archetype

    # 3. Calculate gaps using archetype matrix
    archetype_matrix = load_archetype_matrix()
    gaps = []

    for competency_id, current_score in survey_responses.items():
        target_level = archetype_matrix[archetype][competency_id]
        gap_size = max(0, target_level - current_score)

        # Update Derik's record with gap analysis
        survey_result = UserCompetencySurveyResult.query.filter_by(
            user_id=user_id,
            competency_id=competency_id
        ).order_by(UserCompetencySurveyResult.submitted_at.desc()).first()

        if survey_result:
            survey_result.target_level = target_level
            survey_result.gap_size = gap_size
            survey_result.archetype_source = archetype

        gaps.append({
            'competency_id': competency_id,
            'current': current_score,
            'target': target_level,
            'gap': gap_size
        })

    db.session.commit()

    return {
        'status': 'success',
        'gaps': gaps,
        'archetype': archetype
    }
```

---

## 📊 Data Flow Diagram (Unified)

```
┌─────────────────────────────────────────────────────────┐
│                   MASTER DATA (Derik)                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ competency   │  │ role_cluster │  │ organization │  │
│  │ (16 rows)    │  │ (16 rows)    │  │ (N rows)     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                  ▲          │
│         │                  │                  │          │
│         └──────────────────┴──────────────────┘          │
│                            │                              │
└────────────────────────────┼──────────────────────────────┘
                             │
                             │ Foreign Keys
                             ▼
┌─────────────────────────────────────────────────────────┐
│              ASSESSMENT DATA (Derik + SE-QPT)            │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │ user_se_competency_survey_results (EXTENDED)      │  │
│  │                                                    │  │
│  │  - user_id, organization_id, competency_id        │  │
│  │  - score (current level) ← Derik's survey         │  │
│  │  - target_level ← SE-QPT archetype                │  │
│  │  - gap_size ← SE-QPT calculation                  │  │
│  │  - archetype_source ← Phase 1 selection           │  │
│  └───────────────────────────────────────────────────┘  │
│                            │                              │
└────────────────────────────┼──────────────────────────────┘
                             │
                             │ References
                             ▼
┌─────────────────────────────────────────────────────────┐
│            LEARNING PLANS (SE-QPT ONLY)                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │ learning_plans                                     │  │
│  │                                                    │  │
│  │  - user_id, organization_id                       │  │
│  │  - objectives (RAG-LLM generated SMART)           │  │
│  │  - recommended_modules                            │  │
│  │  - archetype_used                                 │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Benefits of Unified Approach

| Benefit | Description |
|---------|-------------|
| **Single Source of Truth** | 16 competencies + 16 roles defined once (Derik's tables) |
| **No Data Duplication** | All systems reference same master data |
| **Validated Data** | Derik's competencies already validated with INCOSE |
| **Existing Integrations** | Derik's RAG, matrices, indicators all work out of box |
| **Easy Extension** | Just add fields to existing tables |
| **Backward Compatible** | Derik's system continues working unchanged |
| **Clear Separation** | Master data (Derik) vs Learning plans (SE-QPT) |

---

## 🎯 Action Items

### Immediate (Delete Duplicates)
- [ ] Drop `se_competencies` table
- [ ] Drop `se_roles` table
- [ ] Drop `role_mappings` table
- [ ] Drop `competency_assessment_results` table (old SE-QPT)

### Database Changes
- [ ] Run `ALTER TABLE user_se_competency_survey_results` to add gap fields
- [ ] Run `ALTER TABLE organization` to add Phase 1 fields (from prev analysis)

### Backend Updates
- [ ] Update all `competency_id` foreign keys to reference `competency` table
- [ ] Update all `role_cluster_id` references to `role_cluster` table
- [ ] Update `organization_id` to reference `organization` (INTEGER not UUID)
- [ ] Create unified model classes that extend Derik's tables
- [ ] Update API routes to use unified models

### Frontend Updates
- [ ] Update competency displays to fetch from Derik's API
- [ ] Update role selection to use Derik's role clusters
- [ ] Update assessment submission to use unified endpoint

---

## 📝 Conclusion

**You are ABSOLUTELY CORRECT!** There are massive duplications:

1. ❌ **16 Competencies** - Completely duplicated
2. ❌ **16 Role Clusters** - Completely duplicated
3. ⚠️ **Assessment Results** - Overlapping storage
4. ⚠️ **Role Assignment** - Overlapping logic

**Solution**: Use Derik's master data tables as the single source of truth, extend his assessment table with gap analysis fields, and keep SE-QPT's learning plans table as the innovation layer.

This eliminates ~4 duplicate tables and creates a clean, unified architecture! 🎉
