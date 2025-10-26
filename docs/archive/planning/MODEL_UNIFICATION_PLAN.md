# Model Unification Plan - SE-QPT Database Architecture

**Created:** 2025-10-20
**Priority:** HIGH (Technical Debt)
**Estimated Time:** 4-6 hours
**Risk Level:** HIGH - Requires careful testing

---

## Problem Statement

The SE-QPT codebase currently has **THREE separate model files** with overlapping/conflicting definitions:

1. **models.py** (606 lines) - SE-QPT main models
2. **unified_models.py** (371 lines) - Derik's competency assessment models
3. **mvp_models.py** (339 lines) - MVP/simplified models

### Issues This Causes:

- **Circular Import Dependencies**: Files import from each other creating dependency loops
- **Duplicate Table Definitions**: Same tables defined differently in multiple files
- **Foreign Key Mismatches**: Tables reference wrong table names (e.g., 'organizations' vs 'organization')
- **Type Mismatches**: Same columns defined with different types (String(36) vs Integer)
- **Maintenance Nightmare**: Changes must be synchronized across 3 files
- **21+ Dependent Files**: Many files import from these models

### Specific Problems Found:

1. `Organization` table:
   - Defined in unified_models.py as `'organization'` (singular)
   - Referenced in mvp_models.py as `'organizations'` (plural)
   - organization_id type mismatch (Integer vs String(36))

2. MVPUser and User classes:
   - Similar functionality, different implementations
   - Both try to handle authentication
   - Confusing which one to use where

3. Import chains:
   - unified_models.py imports from models.py
   - models.py imports from unified_models.py
   - mvp_models.py imports from both

---

## Proposed Solution: Single Unified models.py

Create ONE comprehensive models.py file organized into logical sections:

```python
# models.py (NEW STRUCTURE)

# =============================================================================
# SECTION 1: DATABASE INITIALIZATION
# =============================================================================
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

# =============================================================================
# SECTION 2: CORE ENTITIES (Derik's Foundation)
# =============================================================================
class Organization(db.Model):
    """Unified organization model"""
    __tablename__ = 'organization'  # SINGULAR (Derik's convention)

class Competency(db.Model):
    """SE competency definitions (from Derik)"""
    __tablename__ = 'competency'

class RoleCluster(db.Model):
    """Role definitions (from Derik)"""
    __tablename__ = 'role_cluster'

# =============================================================================
# SECTION 3: USER MANAGEMENT (Unified)
# =============================================================================
class User(db.Model):
    """Unified user model (combines MVPUser + User)"""
    __tablename__ = 'users'
    # Merge best features from both implementations

class AppUser(db.Model):
    """Survey participants (from Derik)"""
    __tablename__ = 'app_user'

# =============================================================================
# SECTION 4: ASSESSMENT & RESULTS
# =============================================================================
class Assessment(db.Model):
    """Competency assessments"""

class CompetencyAssessmentResult(db.Model):
    """Assessment results (from Derik)"""

class MaturityAssessment(db.Model):
    """Organizational maturity (from MVP)"""

# =============================================================================
# SECTION 5: LEARNING & QUALIFICATION
# =============================================================================
class LearningObjective(db.Model):
    """Learning objectives"""

class LearningModule(db.Model):
    """Learning modules"""

class QualificationPlan(db.Model):
    """Qualification plans"""

# =============================================================================
# SECTION 6: QUESTIONNAIRES & SURVEYS
# =============================================================================
class Questionnaire(db.Model):
    """Questionnaire definitions"""

class PhaseQuestionnaireResponse(db.Model):
    """Phase questionnaire responses"""
```

---

## Implementation Plan

### Phase 1: Analysis & Preparation (1 hour)

**1.1 Document All Models**
- Create spreadsheet mapping all models across 3 files
- Document table names, relationships, dependencies
- Identify duplicates and conflicts

**1.2 Identify All Import Locations**
```bash
# Find all files importing from model files
grep -r "from models import" src/backend/
grep -r "from unified_models import" src/backend/
grep -r "from mvp_models import" src/backend/
```
Expected: 21+ files need updating

**1.3 Create Test Cases**
- Document current behavior that must be preserved
- Create test data for validation
- Document all foreign key relationships

### Phase 2: Create Unified Model File (2 hours)

**2.1 Start with Derik's Foundation**
- Copy Organization, Competency, RoleCluster from unified_models.py
- These are the source of truth (Derik's proven implementation)

**2.2 Merge User Models**
- Combine MVPUser + User into single User class
- Keep best features from both:
  - Authentication from MVPUser
  - Relationships from User
  - Ensure backward compatibility

**2.3 Add Assessment Models**
- CompetencyAssessmentResult (Derik)
- MaturityAssessment (MVP)
- Ensure foreign keys use correct table names

**2.4 Add Learning/Qualification Models**
- LearningObjective, LearningModule, QualificationPlan
- Fix all foreign key references
- Standardize on Integer IDs for organization_id

**2.5 Fix All Foreign Keys**
Critical fixes needed:
```python
# WRONG (current mvp_models.py):
organization_id = db.Column(db.String(36), db.ForeignKey('organizations.id'))

# CORRECT (unified):
organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))
```

### Phase 3: Update All Imports (1-2 hours)

**3.1 Create Import Compatibility Layer**
Create temporary `models_compat.py`:
```python
# models_compat.py (TEMPORARY - for gradual migration)
from models import *

# Provide backward-compatible aliases
SECompetency = Competency
SERole = RoleCluster
MVPUser = User  # Merged into User
```

**3.2 Update Files Systematically**
Priority order:
1. Core routes (mvp_routes.py, routes.py, api.py)
2. Services (derik_integration.py, competency_service.py)
3. Utility scripts
4. Migration files

**3.3 Update Pattern**
```python
# OLD:
from unified_models import Organization, Competency
from mvp_models import MVPUser

# NEW:
from models import Organization, Competency, User
```

### Phase 4: Testing & Validation (1 hour)

**4.1 Database Recreation**
```python
# Test script
from models import db
from app import create_app

app = create_app()
app.app_context().push()

# Drop all tables
db.drop_all()

# Create all tables with unified models
db.create_all()

# Verify table count and structure
from sqlalchemy import inspect
inspector = inspect(db.engine)
tables = inspector.get_table_names()
print(f"Created {len(tables)} tables")

# Verify foreign keys are correct
for table in tables:
    fks = inspector.get_foreign_keys(table)
    for fk in fks:
        print(f"{table}.{fk['constrained_columns']} -> {fk['referred_table']}.{fk['referred_columns']}")
```

**4.2 Functionality Tests**
- Test user registration/login
- Test assessment creation
- Test competency assignment
- Test learning objective generation
- Verify all foreign key relationships work

**4.3 Backend Startup Test**
```bash
# Must start without errors
python run.py --port 5000
```

### Phase 5: Cleanup (30 min)

**5.1 Archive Old Files**
```bash
mv unified_models.py archives/unified_models_pre_merge_20251020.py
mv mvp_models.py archives/mvp_models_pre_merge_20251020.py
```

**5.2 Remove Compatibility Layer**
- Delete models_compat.py
- Verify no imports reference it

**5.3 Update Documentation**
- Update SESSION_HANDOVER.md
- Document new model structure
- Create models diagram

---

## Risk Mitigation

### Backup Strategy
```bash
# BEFORE starting, create backup
git checkout -b backup-pre-model-unification
git push origin backup-pre-model-unification

# Create database backup
pg_dump -U ma0349 competency_assessment > backup_db_20251020.sql
```

### Rollback Plan
If anything breaks:
```bash
git checkout master
git reset --hard HEAD  # Discard all changes
# Restore from backup branch
git checkout backup-pre-model-unification
```

### Testing Checkpoints
After each phase, verify:
- [ ] Python imports work (no ImportError)
- [ ] Flask app starts successfully
- [ ] Database tables created correctly
- [ ] Foreign keys reference correct tables
- [ ] All relationships load properly

---

## Files That Need Updates (Known List)

Based on grep analysis, these 21+ files import from model files:

### Core Application:
1. `app/__init__.py` - Flask app initialization
2. `app/mvp_routes.py` - MVP routes (uses MVPUser)
3. `app/routes.py` - Main routes
4. `app/api.py` - API endpoints
5. `app/admin.py` - Admin functions
6. `app/derik_integration.py` - Derik integration
7. `app/seqpt_routes.py` - SE-QPT routes
8. `app/questionnaire_api.py` - Questionnaire API
9. `app/competency_service.py` - Competency service
10. `app/module_api.py` - Module API

### Utility Scripts:
11. `run.py` - Main entry point
12. `setup_database.py` - Database setup
13. `init_questionnaire_data.py` - Data initialization
14. `init_module_library.py` - Module initialization
15. `add_14_roles.py` - Role setup
16. `show_all_data.py` - Data viewing
17. `debug_responses.py` - Debugging
18. `update_real_questions.py` - Question updates
19. `update_complete_questionnaires.py` - Questionnaire updates

### Services:
20. `app/learning_objectives_generator.py` - LO generation
21. `app/services/llm_pipeline/*` - May have indirect dependencies

---

## Success Criteria

✅ **Code Quality**
- Single models.py file (no duplicates)
- No circular imports
- All foreign keys reference correct tables
- Consistent data types across relationships

✅ **Functionality**
- All existing features work unchanged
- User registration/login functional
- Assessment creation works
- Competency assignment works
- Learning objectives generate correctly

✅ **Database**
- All tables created successfully
- Foreign key constraints valid
- No orphaned records
- Migrations work (if using Alembic)

✅ **Maintenance**
- Clear, documented model structure
- Easy to understand for new developers
- Single source of truth for database schema

---

## Post-Unification Benefits

1. **Simplified Maintenance**: One file to update instead of three
2. **No Import Conflicts**: Eliminated circular dependencies
3. **Consistent Schema**: All foreign keys and types aligned
4. **Better Performance**: Reduced import overhead
5. **Easier Onboarding**: New developers understand structure immediately
6. **Reduced Bugs**: No more table name/type mismatches

---

## Notes for Future Session

### Before Starting:
- [ ] Ensure all current work is committed
- [ ] Create backup branch
- [ ] Export current database
- [ ] Block 4-6 hours of uninterrupted time
- [ ] Have pgAdmin or psql ready for database inspection

### Tools Needed:
- Text editor with search/replace across files
- Database IDE (pgAdmin/DBeaver)
- Git for version control
- Python environment with all dependencies

### Key Decision Points:
1. **User Model Merge**: Decide which fields from MVPUser vs User to keep
2. **ID Types**: Standardize on Integer vs UUID/String(36)
3. **Table Naming**: Singular vs plural (recommend: follow Derik's singular convention)
4. **Timestamps**: Ensure all tables have created_at/updated_at if needed

---

## Estimated Timeline

| Phase | Task | Time | Risk |
|-------|------|------|------|
| 1 | Analysis & Preparation | 1h | Low |
| 2 | Create Unified Model | 2h | Medium |
| 3 | Update All Imports | 1-2h | High |
| 4 | Testing & Validation | 1h | Medium |
| 5 | Cleanup | 0.5h | Low |
| **Total** | **Complete Unification** | **5.5-6.5h** | **HIGH** |

---

## Alternative: Incremental Approach

If 6 hours is too much at once, consider incremental approach:

### Week 1: Preparation
- Document all models
- Create unified models.py
- Test it loads without errors

### Week 2: Phase 1 Routes
- Update MVP routes only
- Test thoroughly
- Commit

### Week 3: Phase 2 Routes
- Update main routes
- Test thoroughly
- Commit

### Week 4: Cleanup
- Archive old files
- Final testing
- Documentation

---

**STATUS**: Plan Complete - Ready for Implementation
**NEXT SESSION**: Follow this plan to unify all model files into one
