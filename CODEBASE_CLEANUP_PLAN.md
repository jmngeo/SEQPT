# SE-QPT Codebase Cleanup & Refactoring Plan

**Created:** 2025-10-20
**Priority:** CRITICAL - Must be done before further development
**Est. Duration:** 4-8 hours (can be split across sessions)

---

## 🎯 Goal

**Unify fragmented architecture into a clean, maintainable codebase with:**
- ✅ One unified model file
- ✅ One consolidated routes file (or clear modular structure)
- ✅ One backend directory
- ✅ Clear separation of concerns
- ✅ No circular dependencies
- ✅ Working authentication

---

## 📊 Current State Assessment

### Models (3 Files - CRITICAL ISSUE)
```
src/backend/
├── models.py           # 607 lines - Original SE-QPT models
│   └── Issue: References 'SECompetency' (doesn't exist)
├── unified_models.py   # 371 lines - Derik integration
│   └── Issue: Has 'Competency' not 'SECompetency'
└── mvp_models.py       # 340 lines - MVP simplified
    └── Issue: Imports from both above, circular deps
```

**Problem:** SQLAlchemy can't resolve relationships → 500 errors

### Routes (4+ Files - CONFUSION)
```
src/backend/app/
├── routes.py           # 454 lines - Basic CRUD
├── mvp_routes.py       # 810 lines - Auth + Phase 1
├── seqpt_routes.py     # 1054 lines - RAG + objectives
├── derik_integration.py # 1051 lines - Phase 2
├── api.py              # 423 lines - Additional API
├── admin.py            # 549 lines - Admin functions
└── ... (more)
```

**Problem:** Overlapping responsibilities, hard to maintain

### Backends (2 Directories - MAJOR CONFUSION)
```
src/
├── backend/            # Main backend (correct)
└── competency_assessor/ # Legacy Derik backend
```

**Problem:** Not clear which to use, partial functionality in both

---

## 🚨 Immediate Fix (Session 1 - 30 mins)

### Step 1: Fix SQLAlchemy Relationship Error

**File:** `src/backend/models.py`
**Find and fix** all references to `'SECompetency'`:

```python
# BEFORE (WRONG):
competency = relationship('SECompetency', backref='assessment_results')

# AFTER (CORRECT):
competency = relationship('Competency', backref='assessment_results')
```

**How to find:**
```bash
cd src/backend
grep -n "SECompetency" models.py
```

**Expected occurrences:**
- `CompetencyAssessmentResult` class
- Possibly in `UserCompetencySurveyResult` class
- Check all relationship() calls

**Test:**
```bash
cd src/backend
python -c "from models import db, Competency; print('SUCCESS')"
```

---

## 📋 Phase 1: Model Unification (Session 1-2 - 2-3 hours)

### Goal
Create ONE unified `models.py` with all models, no conflicts.

### Strategy: Keep + Merge Approach

**Keep:** `src/backend/unified_models.py` as base (most compatible with Derik)
**Merge In:** Useful models from `models.py` and `mvp_models.py`
**Result:** New `models_unified.py`

### Step 1.1: Analyze Current Models

**Run analysis:**
```bash
cd src/backend
# List all models in each file
grep "class.*db.Model" models.py unified_models.py mvp_models.py
```

**Create inventory:**
```
models.py:
- User
- SECompetency (should be Competency)
- SERole
- QualificationArchetype
- Assessment
- CompetencyAssessmentResult ← HAS ERROR
- LearningObjective
- QualificationPlan
- CompanyContext
- RAGTemplate
- LearningModule
- LearningPath
- ModuleEnrollment
- ModuleAssessment
- LearningResource

unified_models.py:
- Organization (Derik's, extended)
- Competency (Derik's)
- RoleCluster (Derik's)
- AppUser (Derik's)
- UserCompetencySurveyResult (Derik's, extended)
- LearningPlan (SE-QPT)
- PhaseQuestionnaireResponse (SE-QPT)

mvp_models.py:
- MVPUser (imports from unified_models)
- MaturityAssessment
- CompetencyAssessment
- RoleMapping
```

### Step 1.2: Create Unified Models File

**File:** `src/backend/models_unified.py`

**Structure:**
```python
"""
SE-QPT Unified Models
Combines: Derik's models + SE-QPT models + MVP models
Date: 2025-10-20
"""

from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import uuid
import json

# Initialize db
db = SQLAlchemy()

# ===========================================================================
# SECTION 1: CORE MODELS (from Derik - DO NOT CHANGE)
# ===========================================================================

class Organization(db.Model):
    """Derik's organization model (extended for SE-QPT)"""
    __tablename__ = 'organizations'
    # ... keep from unified_models.py

class Competency(db.Model):
    """Derik's competency model"""
    __tablename__ = 'competencies'
    # ... keep from unified_models.py

class RoleCluster(db.Model):
    """Derik's role cluster model"""
    __tablename__ = 'role_clusters'
    # ... keep from unified_models.py

class AppUser(db.Model):
    """Derik's app user model"""
    __tablename__ = 'app_users'
    # ... keep from unified_models.py

# ===========================================================================
# SECTION 2: SE-QPT MODELS
# ===========================================================================

class User(db.Model):
    """SE-QPT main user model"""
    __tablename__ = 'users'
    # ... from models.py (rename SEUser to User if needed)

class QualificationArchetype(db.Model):
    """SE-QPT qualification archetype"""
    __tablename__ = 'qualification_archetypes'
    # ... from models.py

class Assessment(db.Model):
    """SE-QPT assessment"""
    __tablename__ = 'assessments'
    # ... from models.py

class CompetencyAssessmentResult(db.Model):
    """SE-QPT assessment results"""
    __tablename__ = 'competency_assessment_results'

    # FIX THE RELATIONSHIP:
    competency = relationship('Competency', backref='assessment_results')  # NOT 'SECompetency'

# ===========================================================================
# SECTION 3: MVP MODELS (Simplified)
# ===========================================================================

class MVPUser(db.Model):
    """Simplified user for MVP"""
    __tablename__ = 'mvp_users'
    # ... from mvp_models.py

class MaturityAssessment(db.Model):
    """Phase 1 maturity assessment"""
    __tablename__ = 'maturity_assessments'
    # ... from mvp_models.py

# ===========================================================================
# SECTION 4: HELPER FUNCTIONS
# ===========================================================================

def calculate_maturity_score(responses):
    """Calculate maturity score from questionnaire responses"""
    # ... from mvp_models.py

def select_archetype(maturity_score, org_context):
    """Select qualification archetype based on maturity"""
    # ... from mvp_models.py

# Export all models
__all__ = [
    'db',
    'Organization', 'Competency', 'RoleCluster', 'AppUser',
    'User', 'QualificationArchetype', 'Assessment', 'CompetencyAssessmentResult',
    'MVPUser', 'MaturityAssessment',
    # ... all other models
]
```

### Step 1.3: Update Imports

**Files to update:**
1. `src/backend/app/__init__.py`
2. `src/backend/app/mvp_routes.py`
3. `src/backend/app/routes.py`
4. `src/backend/app/seqpt_routes.py`
5. `src/backend/run.py`

**Change:**
```python
# BEFORE:
from models import db, User, Competency
from unified_models import Organization, AppUser
from mvp_models import MVPUser, MaturityAssessment

# AFTER:
from models_unified import db, User, Competency, Organization, AppUser, MVPUser, MaturityAssessment
```

### Step 1.4: Test Models

```bash
cd src/backend
python -c "
from models_unified import db, Competency, Organization, User, MVPUser
print('All imports successful!')
print('Competency:', Competency)
print('Organization:', Organization)
"
```

### Step 1.5: Backup and Replace

```bash
cd src/backend

# Backup old files
mv models.py models.py.backup
mv unified_models.py unified_models.py.backup
mv mvp_models.py mvp_models.py.backup

# Rename unified file
mv models_unified.py models.py
```

---

## 📋 Phase 2: Route Consolidation (Session 2-3 - 2-3 hours)

### Goal
Organize routes into clear, modular structure.

### Strategy: Domain-Driven Structure

**New structure:**
```
src/backend/app/routes/
├── __init__.py         # Register all blueprints
├── auth.py             # Authentication (login, register, logout)
├── phase1.py           # Phase 1 routes (maturity, roles, strategies)
├── phase2.py           # Phase 2 routes (competency assessment)
├── phase3.py           # Phase 3 routes (module selection)
├── phase4.py           # Phase 4 routes (final plan)
├── organization.py     # Organization management
├── admin.py            # Admin functions
└── utilities.py        # Helper functions shared across routes
```

### Step 2.1: Create Routes Directory

```bash
cd src/backend/app
mkdir routes
touch routes/__init__.py
```

### Step 2.2: Extract Authentication Routes

**File:** `src/backend/app/routes/auth.py`

**Extract from:** `mvp_routes.py` (lines 34-161)

```python
"""
Authentication Routes
Handles: login, register (admin/employee), logout, token management
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required
from models import db, MVPUser, Organization

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    """Login for both admin and employee users"""
    # ... move from mvp_routes.py

@auth_bp.route('/register-admin', methods=['POST'])
def register_admin():
    """Register new admin and create organization"""
    # ... move from mvp_routes.py

@auth_bp.route('/register-employee', methods=['POST'])
def register_employee():
    """Register employee and join organization"""
    # ... move from mvp_routes.py

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """Logout current user"""
    # ... move from mvp_routes.py
```

### Step 2.3: Extract Phase 1 Routes

**File:** `src/backend/app/routes/phase1.py`

**Extract from:** `mvp_routes.py` + any Phase 1 code

```python
"""
Phase 1 Routes: Maturity Assessment & Role Identification
Handles: maturity questionnaire, role identification, target group, strategy selection
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models import db, MaturityAssessment, RoleMapping, Organization

phase1_bp = Blueprint('phase1', __name__, url_prefix='/api/phase1')

@phase1_bp.route('/maturity/<int:org_id>/latest', methods=['GET'])
@jwt_required()
def get_latest_maturity(org_id):
    """Get latest maturity assessment for organization"""
    # ... consolidate from various sources

@phase1_bp.route('/roles/<int:org_id>/latest', methods=['GET'])
@jwt_required()
def get_latest_roles(org_id):
    """Get latest role identification for organization"""
    # ...

@phase1_bp.route('/target-group/<int:org_id>', methods=['GET'])
@jwt_required()
def get_target_group(org_id):
    """Get target group size for organization"""
    # ...

@phase1_bp.route('/strategies/<int:org_id>/latest', methods=['GET'])
@jwt_required()
def get_latest_strategies(org_id):
    """Get latest strategy selection for organization"""
    # ...
```

### Step 2.4: Extract Phase 2 Routes

**File:** `src/backend/app/routes/phase2.py`

**Extract from:** `derik_integration.py` + `routes.py` (Phase 2 code)

```python
"""
Phase 2 Routes: Competency Assessment
Handles: competency surveys, results, feedback, indicators
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models import db, Competency, UserCompetencySurveyResult, AppUser

phase2_bp = Blueprint('phase2', __name__, url_prefix='/api/phase2')

@phase2_bp.route('/identified-roles/<int:org_id>', methods=['GET'])
@jwt_required()
def get_identified_roles(org_id):
    """Get Phase 1 identified roles for Phase 2"""
    # ... from routes.py (lines 3245+)

@phase2_bp.route('/calculate-competencies', methods=['POST'])
@jwt_required()
def calculate_competencies():
    """Calculate necessary competencies from selected roles"""
    # ...

@phase2_bp.route('/start-assessment', methods=['POST'])
@jwt_required()
def start_assessment():
    """Start new competency assessment"""
    # ...

@phase2_bp.route('/submit-survey', methods=['POST'])
def submit_survey():
    """Submit competency survey results"""
    # ... from derik_integration.py
```

### Step 2.5: Update Main App

**File:** `src/backend/app/__init__.py`

```python
def create_app(config_name='development'):
    app = Flask(__name__)

    # ... config setup

    # Register consolidated blueprints
    from app.routes.auth import auth_bp
    from app.routes.phase1 import phase1_bp
    from app.routes.phase2 import phase2_bp
    from app.routes.organization import org_bp
    from app.routes.admin import admin_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(phase1_bp)
    app.register_blueprint(phase2_bp)
    app.register_blueprint(org_bp)
    app.register_blueprint(admin_bp)

    # Derik integration (keep separate for now)
    try:
        from app.derik_integration import derik_bp
        app.register_blueprint(derik_bp, url_prefix='/api/derik')
        print("Derik's competency assessor integration enabled")
    except Exception as e:
        print(f"Warning: Derik's competency assessor not available: {e}")

    # RAG routes (keep separate for now)
    try:
        from app.seqpt_routes import seqpt_bp
        app.register_blueprint(seqpt_bp, url_prefix='/api/seqpt')
        print("SE-QPT RAG routes registered successfully")
    except Exception as e:
        print(f"Warning: SE-QPT RAG routes not available: {e}")

    return app
```

### Step 2.6: Update Frontend API Calls

**File:** `src/frontend/src/api/auth.js`

```javascript
// Update if URLs changed
export const authApi = {
  login: (credentials) => {
    return axios.post('/api/auth/login', { ... })  // NEW path structure
  },
  // ...
}
```

---

## 📋 Phase 3: Backend Consolidation (Session 3 - 1-2 hours)

### Goal
Eliminate confusion from dual backend architecture.

### Strategy: Archive Legacy Backend

```bash
cd src

# Create archive
mkdir -p ../archives
mv competency_assessor ../archives/competency_assessor_$(date +%Y%m%d)

# Update documentation
echo "Legacy backend archived to ../archives/" > backend/MIGRATION_NOTES.md
```

**Update:**
1. Remove all references to `competency_assessor` from docs
2. Update `.gitignore` if needed
3. Update `STARTUP_README.md` to remove confusion

---

## 📋 Phase 4: Testing & Validation (Session 4 - 1 hour)

### Test Checklist

#### Models
- [ ] All imports work: `python -c "from models import *"`
- [ ] No circular dependencies
- [ ] SQLAlchemy relationships resolve
- [ ] Database connection works

#### Routes
- [ ] Login: `POST /api/auth/login`
- [ ] Phase 1 dashboard: `GET /api/organization/dashboard`
- [ ] Phase 1 maturity: `GET /api/phase1/maturity/{org_id}/latest`
- [ ] Phase 2 roles: `GET /api/phase2/identified-roles/{org_id}`

#### Integration
- [ ] Frontend connects to backend
- [ ] Authentication flow works
- [ ] Phase 1 workflow loads
- [ ] Phase 2 workflow loads

---

## 🎯 Success Criteria

### Must Have
- ✅ Login works without 500 errors
- ✅ Phase 1 routes return data
- ✅ Phase 2 routes accessible
- ✅ One models.py file
- ✅ Clear route organization
- ✅ No dual backend confusion

### Nice to Have
- ✅ All routes follow REST conventions
- ✅ Consistent error handling
- ✅ API documentation
- ✅ Unit tests for critical paths

---

## 📊 Estimated Timeline

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 0 | Fix SQLAlchemy error | 30 min | CRITICAL |
| 1 | Model unification | 2-3 hrs | HIGH |
| 2 | Route consolidation | 2-3 hrs | MEDIUM |
| 3 | Backend cleanup | 1-2 hrs | LOW |
| 4 | Testing | 1 hr | HIGH |
| **Total** | **Full cleanup** | **6-9 hrs** | |

**Can be split across multiple sessions**

---

## 🚧 Migration Safety

### Backup Strategy
```bash
# Before starting any phase:
cd SE-QPT-Master-Thesis
git add -A
git commit -m "Backup before refactoring Phase X"
git tag "pre-refactor-phase-X-$(date +%Y%m%d)"
```

### Rollback Plan
If something breaks:
```bash
git reset --hard pre-refactor-phase-X-YYYYMMDD
```

### Test After Each Phase
Don't move to next phase until current phase tests pass!

---

## 📁 File Organization (Final State)

```
SE-QPT-Master-Thesis/
├── src/
│   ├── backend/                    # ONLY backend
│   │   ├── app/
│   │   │   ├── __init__.py
│   │   │   ├── models.py           # UNIFIED (was 3 files)
│   │   │   └── routes/             # ORGANIZED
│   │   │       ├── __init__.py
│   │   │       ├── auth.py
│   │   │       ├── phase1.py
│   │   │       ├── phase2.py
│   │   │       └── ...
│   │   ├── run.py
│   │   └── requirements.txt
│   └── frontend/
│       ├── src/
│       └── vite.config.js          # FIXED
├── archives/                        # OLD stuff
│   └── competency_assessor_20251020/
├── start_backend.bat                # CLEAR
├── start_frontend.bat               # CLEAR
└── STARTUP_README.md                # COMPREHENSIVE
```

---

## 🎓 Best Practices Moving Forward

### 1. Model Changes
- Only edit `src/backend/models.py`
- Run migration after changes
- Test imports immediately

### 2. Route Changes
- Add routes to appropriate file in `app/routes/`
- Follow blueprint naming: `{domain}_bp`
- Use consistent URL prefixes

### 3. Backend Changes
- Only `src/backend/` exists
- Port 5000 always
- Document in `STARTUP_README.md`

### 4. Documentation
- Update `SESSION_HANDOVER.md` after each session
- Keep `STARTUP_README.md` current
- Document API changes

---

**Ready for next session! Good luck with the refactoring! 🚀**
