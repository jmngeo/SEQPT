# Routes Cleanup & Organization Plan

**Created:** 2025-10-20
**Priority:** MEDIUM (Optional improvement)
**Estimated Time:** 2-3 hours
**Risk Level:** MEDIUM - RAG service interdependencies

---

## Problem Statement

The SE-QPT backend currently has **9+ route files** scattered in the `app/` directory:

```
app/
├── admin.py               # Admin functions
├── api.py                 # Legacy API endpoints
├── competency_service.py  # Competency business logic
├── derik_integration.py   # Derik's assessment integration
├── module_api.py          # Learning module API
├── mvp_routes.py          # MVP routes (Phase 1 maturity, auth)
├── questionnaire_api.py   # Questionnaire API
├── routes.py              # Main SE-QPT routes
├── seqpt_routes.py        # SE-QPT RAG routes
└── learning_objectives_generator.py  # LO generation
```

### Issues This Causes:

- **Flat structure** - All routes at same level, hard to navigate
- **Unclear organization** - Not obvious which file handles what
- **Naming inconsistency** - Some files end in `_routes.py`, some in `_api.py`, some have neither
- **Difficult to locate endpoints** - Need to search multiple files to find specific route
- **No clear separation** - Business logic mixed with route definitions

---

## Proposed Solution: Organized Routes Directory

Create `app/routes/` directory with clear, phase-based organization:

```
app/
├── routes/                    # NEW: Organized routes directory
│   ├── __init__.py           # Import and register all blueprints
│   ├── auth.py               # Authentication & user management
│   ├── mvp.py                # MVP simplified endpoints
│   ├── phase1.py             # Phase 1: Organizational Maturity
│   ├── phase2.py             # Phase 2: Competency Assessment (Derik)
│   ├── phase3.py             # Phase 3: Learning Objectives (RAG-LLM)
│   ├── phase4.py             # Phase 4: Qualification Plans
│   ├── admin.py              # Admin routes
│   ├── modules.py            # Learning module CRUD
│   └── questionnaires.py     # Questionnaire system
├── services/                  # Business logic (already organized)
│   ├── llm_pipeline/
│   ├── rag/
│   └── utils/
└── __init__.py               # Main app initialization
```

---

## Detailed Migration Plan

### Phase 1: Analysis & Preparation (30 min)

**1.1 Document Current Routes**
Create spreadsheet mapping all routes:
```bash
# Find all @app.route and @bp.route decorators
grep -r "@.*\.route" app/*.py
```

Expected routes:
- Authentication: `/mvp/auth/login`, `/mvp/auth/register`, etc.
- MVP: `/mvp/organizations`, `/mvp/maturity`, etc.
- Phase 2: `/api/assessments`, `/derik/*`, etc.
- Phase 3: `/seqpt/rag/*`, `/api/learning-objectives`, etc.
- Phase 4: `/api/qualification-plans`, etc.
- Admin: `/admin/*`, etc.
- Modules: `/api/modules`, `/api/learning-paths`, etc.

**1.2 Identify Dependencies**
Map import dependencies between route files:
```bash
# Find cross-imports
grep -r "^from app\." app/*.py
grep -r "^import app\." app/*.py
```

**1.3 Create Backup**
```bash
git checkout -b routes-cleanup-backup
git tag pre-routes-cleanup-20251020
```

### Phase 2: Create New Route Structure (1 hour)

**2.1 Create Routes Directory**
```bash
mkdir app/routes
touch app/routes/__init__.py
```

**2.2 Create Individual Route Files**

**`app/routes/auth.py`** - Authentication routes
```python
"""
Authentication and User Management Routes
Endpoints: /auth/*, /mvp/auth/*
"""
from flask import Blueprint

auth_bp = Blueprint('auth', __name__)

# Migrate from mvp_routes.py:
# - /mvp/auth/login
# - /mvp/auth/register
# - /mvp/auth/logout
```

**`app/routes/mvp.py`** - MVP simplified routes
```python
"""
MVP Routes - Simplified Workflow
Endpoints: /mvp/*
"""
from flask import Blueprint

mvp_bp = Blueprint('mvp', __name__, url_prefix='/mvp')

# Migrate from mvp_routes.py:
# - /mvp/organizations
# - /mvp/maturity
# - /mvp/users
```

**`app/routes/phase1.py`** - Phase 1: Organizational Maturity
```python
"""
Phase 1: Organizational Maturity Assessment
Endpoints: /api/phase1/*, /mvp/maturity
"""
from flask import Blueprint

phase1_bp = Blueprint('phase1', __name__)

# Migrate from mvp_routes.py and routes.py:
# - Maturity questionnaire endpoints
# - Organization assessment
```

**`app/routes/phase2.py`** - Phase 2: Competency Assessment
```python
"""
Phase 2: Competency Assessment (Derik's System)
Endpoints: /derik/*, /api/assessments/*, /api/competencies/*
"""
from flask import Blueprint

phase2_bp = Blueprint('phase2', __name__)

# Migrate from derik_integration.py and routes.py:
# - Competency assessment endpoints
# - Survey submission
# - Results retrieval
```

**`app/routes/phase3.py`** - Phase 3: RAG-LLM Learning Objectives
```python
"""
Phase 3: Learning Objectives Generation (RAG-LLM)
Endpoints: /seqpt/rag/*, /api/learning-objectives/*
"""
from flask import Blueprint

phase3_bp = Blueprint('phase3', __name__)

# Migrate from seqpt_routes.py:
# - RAG pipeline endpoints
# - Learning objective generation
# - SMART validation
```

**`app/routes/phase4.py`** - Phase 4: Qualification Plans
```python
"""
Phase 4: Qualification Plan Generation
Endpoints: /api/qualification-plans/*, /api/archetypes/*
"""
from flask import Blueprint

phase4_bp = Blueprint('phase4', __name__)

# Migrate from routes.py:
# - Qualification plan creation
# - Archetype selection
# - Plan customization
```

**`app/routes/modules.py`** - Learning Modules
```python
"""
Learning Module System
Endpoints: /api/modules/*, /api/learning-paths/*
"""
from flask import Blueprint

modules_bp = Blueprint('modules', __name__)

# Migrate from module_api.py:
# - Module CRUD
# - Learning paths
# - Enrollments
```

**`app/routes/questionnaires.py`** - Questionnaire System
```python
"""
Questionnaire System
Endpoints: /api/questionnaires/*
"""
from flask import Blueprint

questionnaires_bp = Blueprint('questionnaires', __name__)

# Migrate from questionnaire_api.py:
# - Questionnaire CRUD
# - Response submission
# - Results calculation
```

**`app/routes/admin.py`** - Admin Routes
```python
"""
Admin Routes
Endpoints: /admin/*
"""
from flask import Blueprint

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

# Migrate from admin.py:
# - User management
# - System configuration
# - Data management
```

**2.3 Create Routes __init__.py**
```python
"""
Routes Package - Centralized Blueprint Registration
"""
from .auth import auth_bp
from .mvp import mvp_bp
from .phase1 import phase1_bp
from .phase2 import phase2_bp
from .phase3 import phase3_bp
from .phase4 import phase4_bp
from .modules import modules_bp
from .questionnaires import questionnaires_bp
from .admin import admin_bp

def register_blueprints(app):
    """Register all blueprints with the Flask app"""
    app.register_blueprint(auth_bp)
    app.register_blueprint(mvp_bp)
    app.register_blueprint(phase1_bp)
    app.register_blueprint(phase2_bp)
    app.register_blueprint(phase3_bp)
    app.register_blueprint(phase4_bp)
    app.register_blueprint(modules_bp)
    app.register_blueprint(questionnaires_bp)
    app.register_blueprint(admin_bp)
```

### Phase 3: Migrate Routes Systematically (1 hour)

**Priority Order:**
1. ✅ Auth routes (simple, no RAG dependencies)
2. ✅ MVP routes (simple, clear boundaries)
3. ✅ Phase 1 routes (maturity assessment)
4. ⚠️ Phase 2 routes (Derik integration - be careful)
5. ⚠️ Phase 3 routes (RAG - complex dependencies)
6. ✅ Phase 4 routes (qualification plans)
7. ✅ Modules routes (straightforward)
8. ✅ Questionnaires routes (clear API)
9. ✅ Admin routes (simple)

**Migration Pattern for Each File:**
```python
# OLD (mvp_routes.py):
@mvp_bp.route('/auth/login', methods=['POST'])
def login():
    # ... code ...

# NEW (routes/auth.py):
from flask import Blueprint, request, jsonify
from models import MVPUser  # Now unified User model
from app.services.utils import some_helper

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/mvp/auth/login', methods=['POST'])
def login():
    # ... same code ...
```

### Phase 4: Update App Initialization (15 min)

**Update `app/__init__.py`:**
```python
# OLD:
from app import mvp_routes, routes, seqpt_routes, admin, module_api, questionnaire_api
app.register_blueprint(mvp_routes.mvp_bp)
app.register_blueprint(routes.main_bp)
# ... etc ...

# NEW:
from app.routes import register_blueprints
register_blueprints(app)
```

### Phase 5: Testing & Validation (30 min)

**5.1 Verify Backend Starts**
```bash
python run.py --port 5000
# Should start without errors
```

**5.2 Test Each Endpoint Category**
```bash
# Auth
curl -X POST http://localhost:5000/mvp/auth/login -d '{"username":"test","password":"test"}'

# MVP
curl http://localhost:5000/mvp/organizations

# Phase 2 (Derik)
curl http://localhost:5000/derik/competencies

# Phase 3 (RAG)
curl http://localhost:5000/seqpt/rag/status

# Modules
curl http://localhost:5000/api/modules
```

**5.3 Verify No Import Errors**
```bash
# Check for any import issues
python -c "from app import create_app; app = create_app(); print('Success')"
```

### Phase 6: Cleanup (15 min)

**6.1 Archive Old Route Files**
```bash
mkdir app/routes_archived
mv app/mvp_routes.py app/routes_archived/
mv app/routes.py app/routes_archived/
mv app/seqpt_routes.py app/routes_archived/
mv app/api.py app/routes_archived/
mv app/module_api.py app/routes_archived/
mv app/questionnaire_api.py app/routes_archived/
# Keep: admin.py, derik_integration.py, competency_service.py (if they have logic)
```

**6.2 Update Documentation**
- Update SESSION_HANDOVER.md
- Create ROUTES_GUIDE.md explaining new structure
- Update any API documentation

---

## Risk Mitigation

### Backup Strategy
```bash
# BEFORE starting
git checkout -b routes-cleanup
git tag pre-routes-cleanup-20251020

# After each phase
git add -A
git commit -m "Routes cleanup: Phase X complete"
```

### Rollback Plan
If anything breaks:
```bash
git checkout master
git reset --hard pre-routes-cleanup-20251020
```

### Testing Checkpoints
After each phase, verify:
- [ ] Python imports work (no ImportError)
- [ ] Flask app starts successfully
- [ ] All blueprints registered
- [ ] Test endpoints respond correctly
- [ ] No 404 errors on existing routes

---

## Known Challenges

### 1. RAG Service Dependencies
**Issue:** `seqpt_routes.py` has complex RAG service imports
**Solution:** Move RAG business logic to `services/rag/`, keep only route definitions in `routes/phase3.py`

### 2. Shared Utilities
**Issue:** Some utility functions used across multiple route files
**Solution:** Keep in `services/utils/` and import as needed

### 3. Derik Integration
**Issue:** `derik_integration.py` might have tightly coupled logic
**Solution:** Extract route definitions to `routes/phase2.py`, keep business logic in `derik_integration.py` as a service

### 4. Circular Imports
**Issue:** Routes importing from each other
**Solution:** Use blueprints properly, import shared code from `services/`

---

## Alternative: Incremental Approach

If 2-3 hours is too much, do it incrementally:

### Week 1: Auth & MVP
- Create `routes/` directory
- Move auth and MVP routes
- Test thoroughly

### Week 2: Phase 1 & 2
- Move Phase 1 (maturity) routes
- Move Phase 2 (Derik) routes
- Test thoroughly

### Week 3: Phase 3 & 4
- Move Phase 3 (RAG) routes - CAREFULLY
- Move Phase 4 (qualification) routes
- Test thoroughly

### Week 4: Modules & Cleanup
- Move modules and questionnaires
- Archive old files
- Update documentation

---

## Success Criteria

✅ **Code Organization**
- Clear, logical route structure
- Easy to find specific endpoints
- Consistent naming conventions
- Separated by SE-QPT phases

✅ **Functionality**
- All existing endpoints work unchanged
- No broken imports
- No 404 errors
- All tests pass (if tests exist)

✅ **Developer Experience**
- New developers can easily navigate routes
- Clear which file handles which endpoints
- Well-documented blueprint registration
- Obvious where to add new routes

---

## Benefits Post-Cleanup

1. **Better Organization** - Routes grouped by SE-QPT phase
2. **Easier Navigation** - Know exactly where to find routes
3. **Clearer Architecture** - Phase-based structure matches project design
4. **Simpler Onboarding** - New developers understand structure immediately
5. **Maintainability** - Changes isolated to specific phase files
6. **Scalability** - Easy to add new routes to appropriate phase

---

## Recommendations

### Do This Cleanup If:
- You plan to add many new routes
- Multiple developers will work on the project
- You want clearer project organization
- You have 2-3 hours for careful refactoring

### Skip This Cleanup If:
- System is working fine as-is
- You're focused on feature development
- Limited time for refactoring
- Risk tolerance is low

**Current Status:** System works well with current structure. This cleanup is **OPTIONAL** but would improve long-term maintainability.

---

**STATUS:** Plan Complete - Ready for Implementation (Optional)
**NEXT SESSION:** Can be implemented anytime or skipped in favor of feature development
