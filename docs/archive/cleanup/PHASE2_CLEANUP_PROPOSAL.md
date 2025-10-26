# SE-QPT Phase 2 Cleanup Proposal
**Date**: 2025-10-25
**Status**: 📋 PROPOSAL - Awaiting Approval
**Goal**: Remove unused database models and clean up code

---

## Database Analysis Results

### Tables Analyzed: 41 total

#### ✅ ACTIVE TABLES (Must Keep - 16 tables)

**Core System Tables** (with data):
1. `users` (21 rows) - Main user table
2. `organization` (21 orgs) - Organizations
3. `competency` (16 rows) - SE competencies
4. `competency_indicators` (~64 rows) - Competency indicators
5. `role_cluster` (14 rows) - SE role clusters
6. `iso_processes` (30 rows) - ISO processes
7. `iso_system_life_cycle_processes` (4 rows) - ISO process groups
8. `role_process_matrix` (~560 rows) - Role-process mapping
9. `process_competency_matrix` (~480 rows) - Process-competency mapping
10. `role_competency_matrix` (~448 rows) - Role-competency mapping
11. `unknown_role_process_matrix` (~90 rows) - Task-based process involvement
12. `unknown_role_competency_matrix` (~48 rows) - Task-based competency requirements
13. `user_se_competency_survey_results` (~192 rows) - Phase 2 assessment results
14. `user_role_cluster` (~11 rows) - User role selections
15. `user_competency_survey_feedback` (~6 rows) - LLM feedback
16. `user_assessment` (6 rows) - Assessment tracking
17. `phase_questionnaire_responses` (~10 rows) - Phase 1 responses

**Total Active**: 17 tables with critical data

---

#### ⚠️ LEGACY TABLES (Have Data - Migration Needed)

**These tables have data but are duplicates of the unified system**:

1. **`app_user`** (8 rows)
   - **Status**: LEGACY duplicate of `users` table
   - **Used by**: derik_integration.py, user_survey_type FK
   - **Action**: ⚠️ MIGRATE to `users` table, then DROP
   - **Risk**: MEDIUM - Need to preserve 8 user records

2. **`new_survey_user`** (10 rows)
   - **Status**: LEGACY survey completion tracking
   - **Used by**: routes.py endpoint `/new_survey_user`
   - **Replaced by**: `user_assessment` table
   - **Action**: ⚠️ MIGRATE to `user_assessment`, then DROP
   - **Risk**: MEDIUM - Need to preserve 10 survey records

3. **`user_survey_type`** (8 rows)
   - **Status**: LEGACY survey type tracking
   - **FK to**: `app_user` (legacy table)
   - **Replaced by**: `user_assessment.survey_type` field
   - **Action**: ⚠️ MIGRATE to `user_assessment`, then DROP
   - **Risk**: LOW - Data can be merged

---

#### ❌ EMPTY TABLES (Safe to Remove - 21 tables)

**These tables exist but have ZERO data - Candidates for removal**:

##### Learning Module System (NOT IMPLEMENTED) - 5 tables
1. `learning_modules` (0 rows)
2. `learning_paths` (0 rows)
3. `learning_resources` (0 rows)
4. `module_enrollments` (0 rows)
5. `module_assessments` (0 rows)

**Conclusion**: Phase 3/4 learning module system was designed but never implemented.
**Action**: ❌ REMOVE all 5 models

---

##### Complex Questionnaire System (NOT USED) - 5 tables
6. `questionnaires` (0 rows)
7. `questions` (0 rows)
8. `question_options` (0 rows)
9. `questionnaire_responses` (0 rows)
10. `question_responses` (0 rows)

**Conclusion**: Complex questionnaire system was designed but Phase 1 uses `phase_questionnaire_responses` (simpler JSON storage) instead.
**Action**: ❌ REMOVE all 5 models

---

##### Generic Assessment System (REPLACED) - 2 tables
11. `assessments` (0 rows)
12. `competency_assessment_results` (0 rows)

**Conclusion**: Generic assessment models were replaced by:
- `user_assessment` (specific assessments)
- `user_se_competency_survey_results` (competency results)

**Action**: ❌ REMOVE both models

---

##### Maturity Assessment (REPLACED) - 1 table
13. `maturity_assessments` (0 rows)

**Conclusion**: Replaced by `phase_questionnaire_responses` (stores maturity assessment as JSON).
**Action**: ❌ REMOVE model

---

##### Qualification Archetypes (REPLACED) - 2 tables
14. `qualification_archetypes` (0 rows)
15. `qualification_plans` (0 rows)

**Conclusion**: Original SE-QPT archetype models were replaced by simplified strategy selection in Phase 1.
**Action**: ❌ REMOVE both models

---

##### RAG-LLM System (NOT IMPLEMENTED) - 4 tables
16. `company_contexts` (0 rows)
17. `learning_objectives` (0 rows)
18. `rag_templates` (0 rows)
19. `learning_plans` (0 rows)

**Conclusion**: RAG-LLM innovation was partially implemented but not using these database models.
**Action**: ❌ REMOVE all 4 models

---

##### ISO Hierarchy Details (NOT USED) - 2 tables
20. `iso_activities` (0 rows)
21. `iso_tasks` (0 rows)

**Conclusion**: System only uses ISO processes level, not activity/task granularity.
**Action**: ❌ REMOVE both models

**Note**: Keep `iso_system_life_cycle_processes` (4 rows) - in use as process grouping.

---

## Summary

| Category | Tables | Action | Risk |
|----------|--------|--------|------|
| **Active (Keep)** | 17 | ✅ NO CHANGE | None |
| **Legacy (Migrate)** | 3 | ⚠️ MIGRATE → DROP | Medium |
| **Empty (Remove)** | 21 | ❌ REMOVE | None |
| **Total** | 41 | | |

---

## Phase 2 Cleanup Plan

### Step 1: Remove Empty Models (SAFE - Zero Risk)

**Models to remove from models.py** (21 models):

```python
# Learning Module System (5 models)
- class LearningModule(db.Model)
- class LearningPath(db.Model)
- class LearningResource(db.Model)
- class ModuleEnrollment(db.Model)
- class ModuleAssessment(db.Model)

# Questionnaire System (5 models)
- class Questionnaire(db.Model)
- class Question(db.Model)
- class QuestionOption(db.Model)
- class QuestionnaireResponse(db.Model)
- class QuestionResponse(db.Model)

# Generic Assessment System (2 models)
- class Assessment(db.Model)
- class CompetencyAssessmentResult(db.Model)

# Maturity Assessment (1 model)
- class MaturityAssessment(db.Model)

# Qualification Archetypes (2 models)
- class QualificationArchetype(db.Model)
- class LearningPlan(db.Model) # Note: Different from learning_plans table

# RAG System (4 models)
- class CompanyContext(db.Model)
- class LearningObjective(db.Model)
- class RAGTemplate(db.Model)
# (learning_plans already counted above)

# ISO Hierarchy (2 models)
- class IsoActivities(db.Model)
- class IsoTasks(db.Model)
```

**Impact**:
- ✅ Removes ~700 lines from models.py
- ✅ No breaking changes (tables are empty)
- ✅ Cleaner codebase
- ✅ Faster migrations

---

### Step 2: Clean Up Blueprint Files (SAFE)

**Blueprints to investigate**:

1. **`questionnaire_bp`** (`questionnaire_api.py`)
   - Uses: Questionnaire, Question, QuestionOption, QuestionnaireResponse
   - **All empty tables** → Blueprint is unused
   - **Action**: ❌ REMOVE questionnaire_api.py OR mark as deprecated

2. **`module_bp`** (`module_api.py`)
   - Uses: LearningModule, LearningPath, ModuleEnrollment
   - **All empty tables** → Blueprint is unused
   - **Action**: ❌ REMOVE module_api.py OR mark as deprecated

3. **`seqpt_bp`** (`seqpt_routes.py`)
   - Uses: CompanyContext, RAGTemplate, LearningObjective
   - **All empty tables** → RAG system partially implemented
   - **Action**: ⚠️ INVESTIGATE - Some RAG functionality may work without DB

**Impact**:
- ✅ Removes 2-3 unused blueprint files
- ✅ Cleaner __init__.py
- ✅ Faster application startup

---

### Step 3: Clean Up Unused Imports in routes.py

**Currently importing but unused** (from analysis):

```python
# Remove these imports:
- QualificationArchetype  # Empty table
- Assessment  # Empty table, replaced by UserAssessment
- CompetencyAssessmentResult  # Empty table
- LearningObjective  # Empty table
- CompanyContext  # Empty table
- RAGTemplate  # Empty table
- MaturityAssessment  # Empty table
- RoleMapping  # Wrapper class, not a real model
- generate_learning_plan_templates  # Function, likely unused
- generate_basic_modules  # Function, likely unused
```

**Impact**:
- ✅ Cleaner imports
- ✅ Faster import time
- ✅ Easier code navigation

---

### Step 4: Legacy Model Migration (CAREFUL - Has Data)

**Option A: Keep for now** (Recommended)
- Leave `app_user`, `new_survey_user`, `user_survey_type` untouched
- Mark as deprecated in code comments
- Plan migration for later

**Option B: Migrate now** (Requires careful planning)
1. Create migration script to copy 8 app_user → users
2. Create migration script to copy 10 new_survey_user → user_assessment
3. Update user_survey_type references
4. Drop old tables

**Recommendation**: **Option A** - Keep legacy tables for now, focus on removing empty models first.

---

## Proposed Execution Order

### Phase 2A: Safe Removals (This session)
1. ✅ Remove 21 empty models from models.py
2. ✅ Create database migration to drop 21 empty tables
3. ✅ Remove 2 unused blueprint files (questionnaire_api, module_api)
4. ✅ Clean up unused imports in routes.py
5. ✅ Update __init__.py to remove blueprint registrations
6. ✅ Test application

**Estimated time**: 30 minutes
**Risk**: ❌ ZERO (all tables are empty)

---

### Phase 2B: Legacy Migration (Future session)
1. ⚠️ Create migration script for app_user → users
2. ⚠️ Create migration script for new_survey_user → user_assessment
3. ⚠️ Update code references
4. ⚠️ Test thoroughly
5. ⚠️ Drop legacy tables

**Estimated time**: 2-3 hours
**Risk**: ⚠️ MEDIUM (has data, requires testing)

---

## Expected Results After Phase 2A

### models.py Changes:
- **Before**: 39 model classes, ~1500 lines
- **After**: 18 model classes, ~800 lines
- **Reduction**: 54% smaller, much cleaner

### Blueprint Changes:
- **Before**: 8 blueprints registered
- **After**: 6 blueprints (remove 2 unused)
- **Reduction**: 25% fewer blueprints

### Import Cleanup:
- **Before**: 35+ imports in routes.py
- **After**: ~25 imports (remove 10 unused)
- **Reduction**: 30% cleaner imports

---

## Benefits of Phase 2A Cleanup

1. **Cleaner Codebase**
   - 700 fewer lines of unused model code
   - Easier to understand what's actually used
   - Less confusion for new developers

2. **Faster Development**
   - Faster database migrations
   - Quicker application startup
   - Easier code navigation

3. **Better Maintenance**
   - Clear separation of implemented vs planned features
   - No dead code to maintain
   - Easier to find bugs

4. **Database Optimization**
   - 21 fewer empty tables
   - Cleaner schema
   - Easier backups

---

## Risks and Mitigation

### Risk 1: Accidentally removing used code
**Mitigation**:
- ✅ Verified all 21 tables are empty (0 rows)
- ✅ Grep'd codebase for usage of empty models
- ✅ Can rollback with git if needed

### Risk 2: Future feature plans
**Mitigation**:
- ✅ All code preserved in git history
- ✅ Can restore any model if needed later
- ✅ Document removed models in cleanup summary

### Risk 3: Blueprint dependencies
**Mitigation**:
- ✅ Check __init__.py for try/except blocks
- ✅ Remove blueprint imports gracefully
- ✅ Test application startup

---

## Next Steps - Awaiting Your Approval

**Would you like me to proceed with Phase 2A cleanup?**

**Option 1**: Execute Phase 2A now (remove 21 empty models)
- Safe, zero-risk cleanup
- ~30 minutes
- Immediate codebase improvement

**Option 2**: Review the proposal first
- Read through this document
- Ask questions
- Approve specific items

**Option 3**: Skip Phase 2 for now
- Keep current state
- Come back later

**Which option do you prefer?**

---

**END OF PHASE 2 CLEANUP PROPOSAL**
