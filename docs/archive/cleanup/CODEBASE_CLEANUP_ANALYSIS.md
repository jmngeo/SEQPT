# SE-QPT Codebase Cleanup Analysis
**Date**: 2025-10-25
**Analyst**: Claude Code
**Purpose**: Comprehensive analysis of unused models, routes, and code for cleanup

---

## Executive Summary

This document analyzes the SE-QPT codebase to identify:
1. **Unused database models** that are defined but never queried
2. **Orphaned route endpoints** that exist in backend but aren't called by frontend
3. **Duplicate/redundant code** across multiple blueprint files
4. **Unused utility scripts** in the backend folder
5. **Safe removal candidates** that can be deleted without breaking functionality

---

## 1. Database Models Analysis

### Models Defined in models.py (39 total)

#### CORE MODELS - ACTIVELY USED
These models are critical to the system and should NOT be removed:

1. ✅ **Organization** - Used extensively in Phase 1 & Phase 2
2. ✅ **Competency** - Core SE competency framework (16 competencies)
3. ✅ **CompetencyIndicator** - Behavioral indicators for competencies
4. ✅ **RoleCluster** - 14 SE role clusters
5. ✅ **IsoProcesses** - ISO/IEC 15288 processes (30 processes)
6. ✅ **RoleProcessMatrix** - Role-to-process mapping (organization-specific)
7. ✅ **ProcessCompetencyMatrix** - Process-to-competency mapping (global)
8. ✅ **RoleCompetencyMatrix** - Role-to-competency mapping (organization-specific)
9. ✅ **UnknownRoleProcessMatrix** - Task-based process involvement
10. ✅ **UnknownRoleCompetencyMatrix** - Task-based competency requirements
11. ✅ **User** - Unified user model (authentication + profile)
12. ✅ **UserCompetencySurveyResult** - Phase 2 assessment results
13. ✅ **UserRoleCluster** - User's selected roles for assessment
14. ✅ **UserCompetencySurveyFeedback** - LLM-generated feedback
15. ✅ **UserAssessment** - Assessment tracking
16. ✅ **PhaseQuestionnaireResponse** - Phase 1 questionnaire responses
17. ✅ **LearningObjective** - RAG-generated learning objectives

#### MODELS TO INVESTIGATE - POTENTIALLY UNUSED

18. ⚠️ **IsoSystemLifeCycleProcesses** - Parent of IsoProcesses (4 process groups)
   - **Used in**: Unknown - needs verification
   - **Database**: Has data populated
   - **Recommendation**: Check if frontend uses process grouping

19. ⚠️ **IsoActivities** - Activities within ISO processes
   - **Used in**: Unknown - needs verification
   - **Database**: May have data populated
   - **Recommendation**: Check if system uses activity-level granularity

20. ⚠️ **IsoTasks** - Tasks within ISO activities
   - **Used in**: Unknown - needs verification
   - **Database**: May have data populated
   - **Recommendation**: Check if system uses task-level granularity

21. ⚠️ **AppUser** - Legacy Derik user model
   - **Status**: DUPLICATE of User model
   - **Used in**: derik_integration.py, UserSurveyType relationship
   - **Database**: Separate table (app_user)
   - **Recommendation**: **CANDIDATE FOR REMOVAL** - Migrate to User model

22. ⚠️ **UserSurveyType** - Tracks survey type (known_role/unknown_role)
   - **Used in**: Unknown
   - **Foreign Key**: References AppUser (legacy model)
   - **Recommendation**: **CANDIDATE FOR REMOVAL** - Not used in unified system

23. ⚠️ **NewSurveyUser** - Legacy survey completion tracking
   - **Used in**: routes.py endpoint `/new_survey_user`
   - **Status**: LEGACY - Replaced by UserAssessment
   - **Recommendation**: **CANDIDATE FOR REMOVAL** after verifying no active users

24. ⚠️ **MaturityAssessment** - Organization maturity assessment
   - **Used in**: Potentially in seqpt_routes.py or routes.py
   - **Status**: Part of Phase 1 Task 1
   - **Recommendation**: VERIFY if PhaseQuestionnaireResponse replaced this

25. ⚠️ **QualificationArchetype** - 6 qualification strategies
   - **Used in**: Potentially in seqpt_routes.py, Assessment relationship
   - **Status**: Part of original SE-QPT design
   - **Recommendation**: VERIFY usage vs PhaseQuestionnaireResponse

26. ⚠️ **Assessment** - Generic assessment model
   - **Used in**: api.py, main routes.py
   - **Status**: May overlap with UserAssessment
   - **Recommendation**: VERIFY if this is redundant with UserAssessment

27. ⚠️ **CompetencyAssessmentResult** - Individual competency results
   - **Used in**: May be in api.py or seqpt_routes.py
   - **Status**: May overlap with UserCompetencySurveyResult
   - **Recommendation**: VERIFY redundancy

28. ⚠️ **CompanyContext** - Company context for RAG
   - **Used in**: seqpt_routes.py (RAG system)
   - **Status**: Part of RAG-LLM innovation
   - **Recommendation**: KEEP if RAG system is active

29. ⚠️ **RAGTemplate** - Templates for RAG objective generation
   - **Used in**: seqpt_routes.py (RAG system)
   - **Status**: Part of RAG-LLM innovation
   - **Recommendation**: KEEP if RAG system is active

#### LEARNING MODULE MODELS - FUTURE FEATURES

30. ⚠️ **Questionnaire** - Questionnaire definitions
   - **Used in**: questionnaire_api.py
   - **Status**: Full questionnaire system (complex)
   - **Recommendation**: VERIFY if used vs simplified PhaseQuestionnaireResponse

31. ⚠️ **Question** - Individual questions
32. ⚠️ **QuestionOption** - Answer options
33. ⚠️ **QuestionnaireResponse** - User responses to questionnaires
34. ⚠️ **QuestionResponse** - Individual question responses
   - **Used in**: questionnaire_api.py
   - **Status**: Full questionnaire system
   - **Recommendation**: CHECK if this complex system is needed vs Phase 1's simpler JSON storage

35. ⚠️ **LearningModule** - SE competency learning modules
36. ⚠️ **LearningPath** - Recommended learning paths
37. ⚠️ **ModuleEnrollment** - User enrollment tracking
38. ⚠️ **ModuleAssessment** - Module assessment results
39. ⚠️ **LearningResource** - Learning resources
   - **Used in**: module_api.py
   - **Status**: Phase 3/4 learning module system
   - **Recommendation**: VERIFY if implemented or planned future feature

---

## 2. Blueprint Analysis - Route Duplication & Usage

### Current Blueprint Structure

| Blueprint | Prefix | File | Endpoints | Status |
|-----------|--------|------|-----------|--------|
| main_bp | / | routes.py | 60+ | ✅ ACTIVE - Primary routes |
| api_bp | /api | api.py | 7 | ⚠️ CHECK - May have overlap |
| admin_bp | /admin | admin.py | 12 | ⚠️ CHECK - Admin functions |
| questionnaire_bp | /api | questionnaire_api.py | 10 | ⚠️ CHECK - Questionnaire system |
| module_bp | /api | module_api.py | 10 | ⚠️ CHECK - Learning modules |
| competency_service_bp | /api/competency | competency_service.py | 6 | ⚠️ CHECK - Competency service |
| derik_bp | /api/derik | derik_integration.py | 13 | ⚠️ OPTIONAL - Derik bridge |
| seqpt_bp | /api/seqpt | seqpt_routes.py | 9 | ⚠️ OPTIONAL - SE-QPT RAG |

### Endpoint Analysis by Blueprint

#### **main_bp (routes.py)** - PRIMARY ROUTES ✅
**Endpoints (60+)**:
- Authentication: `/mvp/auth/login`, `/mvp/auth/register-admin`, `/mvp/auth/register-employee`
- Phase 1: `/api/phase1/maturity/*`, `/api/phase1/roles/*`, `/api/phase1/target-group/*`, `/api/phase1/strategies/*`
- Phase 2: `/assessment/start`, `/assessment/{id}/submit`, `/assessment/{id}/results`
- Matrix Admin: `/role_process_matrix/*`, `/process_competency_matrix/*`, `/competencies`, `/roles`
- Legacy Derik: `/findProcesses`, `/submit_survey`, `/get_required_competencies_for_roles`
- **Status**: **KEEP ALL** - These are actively used by frontend

#### **api_bp (api.py)** - ANALYTICS & EXPORT ⚠️
**Endpoints (7)**:
- `/api/analytics/assessments` - Assessment analytics
- `/api/recommendations/{id}` - Recommendations
- `/api/modules/search` - Module search
- `/api/progress/{uuid}` (GET/POST) - Progress tracking
- `/api/export/assessment/{id}` - Export assessment
- `/api/export/plan/{uuid}` - Export plan
- **Frontend Usage**: MENTIONED in frontend analysis
- **Recommendation**: **KEEP** - These provide unique analytics/export functionality

#### **admin_bp (admin.py)** - ADMIN PANEL ⚠️
**Endpoints (12)**:
- `/admin/dashboard` - Admin dashboard
- `/admin/users` - User management
- `/admin/users/{id}/assessments` - User assessments
- `/admin/competencies` (GET/POST/PUT) - Competency CRUD
- `/admin/modules` (GET/POST) - Module CRUD
- `/admin/config` - System configuration
- `/admin/usage-report` - Usage report
- `/admin/quality-report` - Quality report
- **Frontend Usage**: Frontend has AdminPanel.vue using these
- **Recommendation**: **KEEP** - Admin functionality is essential

#### **questionnaire_bp (questionnaire_api.py)** - COMPLEX QUESTIONNAIRE SYSTEM ⚠️
**Endpoints (10)**:
- `/api/questionnaires` (GET) - List questionnaires
- `/api/questionnaires/{id}` (GET) - Get questionnaire
- `/api/questionnaires/{id}/start` (POST) - Start questionnaire
- `/api/responses/{uuid}/answer` (POST) - Submit answer
- `/api/responses/{uuid}/complete` (POST) - Complete questionnaire
- `/api/responses/{uuid}` (GET) - Get response
- `/api/users/{id}/responses` (GET) - User responses
- `/api/public/users/{id}/responses` (GET) - Public user responses
- **Current System**: Phase 1 uses PhaseQuestionnaireResponse (simpler JSON storage)
- **Question**: Is this complex Questionnaire system used anywhere?
- **Recommendation**: **INVESTIGATE** - May be redundant with PhaseQuestionnaireResponse

#### **module_bp (module_api.py)** - LEARNING MODULES (PHASE 3/4) ⚠️
**Endpoints (10)**:
- `/api/modules` (GET) - List modules
- `/api/modules/{code}` (GET) - Get module
- `/api/modules/by-competency/{id}` (GET) - Modules by competency
- `/api/learning-paths` (GET) - List learning paths
- `/api/learning-paths/{uuid}` (GET) - Get learning path
- `/api/modules/{code}/enroll` (POST) - Enroll in module
- `/api/enrollments` (GET) - Get enrollments
- `/api/enrollments/{uuid}/progress` (POST) - Update progress
- `/api/recommendations` (GET) - Module recommendations
- `/api/categories` (GET) - Module categories
- **Frontend Usage**: MENTIONED in frontend analysis (Phase 3/4)
- **Database**: LearningModule, LearningPath, ModuleEnrollment tables
- **Recommendation**: **VERIFY** - Check if Phase 3/4 is implemented or placeholder

#### **competency_service_bp (competency_service.py)** - COMPETENCY SERVICE ⚠️
**Endpoints (6)**:
- `/api/competency/competencies` (GET) - Get competencies
- `/api/competency/public/roles` (GET) - Get public roles
- `/api/competency/roles` (GET) - Get roles
- `/api/competency/roles/{id}/competencies` (GET) - Role competencies
- `/api/competency/assessment/{id}/competency-questionnaire` (GET) - Competency questions
- `/api/competency/assessment/{id}/submit-responses` (POST) - Submit responses
- **Overlap**: Competencies and roles are already in main_bp
- **Recommendation**: **CHECK FOR DUPLICATION** - May be redundant

#### **derik_bp (derik_integration.py)** - DERIK BRIDGE (OPTIONAL) ⚠️
**Endpoints (13)**:
- `/api/derik/status` - Status check
- `/api/derik/public/identify-processes` - Identify processes (public)
- `/api/derik/identify-processes` - Identify processes
- `/api/derik/rank-competencies` - Rank competencies
- `/api/derik/find-similar-role` - Find similar role
- `/api/derik/complete-assessment` - Complete assessment
- `/api/derik/questionnaire/{name}` - Get questionnaire
- `/api/derik/assessment-report/{id}` - Assessment report
- `/api/derik/get_required_competencies_for_roles` - Required competencies
- `/api/derik/get_competency_indicators_for_competency/{id}` - Competency indicators
- `/api/derik/get_all_competency_indicators` - All indicators
- `/api/derik/submit_survey` - Submit survey
- `/api/derik/bridge/health` - Bridge health
- **Status**: OPTIONAL bridge for Derik's original system
- **Recommendation**: **VERIFY USAGE** - Check if frontend uses `/api/derik/*` endpoints

#### **seqpt_bp (seqpt_routes.py)** - SE-QPT RAG SYSTEM (OPTIONAL) ⚠️
**Endpoints (9)**:
- `/api/seqpt/test` - Test endpoint
- `/api/seqpt/phase1/archetype-selection` - Archetype selection
- `/api/seqpt/phase2/competency-assessment` - Competency assessment
- `/api/seqpt/public/phase2/generate-objectives` - Generate objectives (public)
- `/api/seqpt/phase2/generate-objectives` - Generate objectives
- `/api/seqpt/phase3/module-selection` - Module selection
- `/api/seqpt/phase4/cohort-formation` - Cohort formation
- `/api/seqpt/rag/status` - RAG status
- `/api/seqpt/public/phase2/generate-objectives-enhanced` - Enhanced objectives (public)
- **Frontend Usage**: MENTIONED in frontend analysis
- **Status**: RAG-LLM innovation for learning objectives
- **Recommendation**: **VERIFY USAGE** - Check if RAG system is active

---

## 3. Utility Scripts Analysis (src/backend/*.py)

### SAFE TO REMOVE - One-time Setup/Migration Scripts ❌

These scripts were used for initial database setup and data migration. They are no longer needed for running the application:

1. **Database Setup/Migration**:
   - `init_db_as_postgres.py` - Initial database setup
   - `drop_all_tables.py` - Drop all tables (dangerous!)
   - `setup_database.py` - Database setup
   - `create_user_and_grant.py` - Create database user
   - `grant_permissions.py` - Grant database permissions
   - `fix_schema_permissions.py` - Fix schema permissions
   - `rename_database.py` - Rename database
   - `backup_database.py` - Database backup utility

2. **Data Population Scripts**:
   - `populate_iso_processes.py` - Populate ISO processes
   - `populate_roles_and_matrices.py` - Populate roles and matrices
   - `populate_competencies.py` - Populate competencies
   - `populate_competency_indicators.py` - Populate competency indicators
   - `populate_process_competency_matrix.py` - Populate process-competency matrix
   - `populate_org11_matrices.py` - Populate org 11 matrices
   - `populate_org11_role_competency_matrix.py` - Populate org 11 role-competency matrix
   - `initialize_all_data.py` - Initialize all data
   - `add_14_roles.py` - Add 14 roles
   - `add_derik_process_tables.py` - Add Derik process tables
   - `align_iso_processes.py` - Align ISO processes

3. **Migration/Fix Scripts**:
   - `fix_phase_questionnaire_fk.py` - Fix foreign key
   - `fix_all_user_fks.py` - Fix user foreign keys
   - `fix_constraint.py` - Fix constraint
   - `fix_constraint_with_migration.py` - Fix constraint with migration
   - `fix_role_competency_discrepancies.py` - Fix role-competency discrepancies
   - `apply_role_competency_fixes.py` - Apply fixes
   - `create_role_competency_matrix.py` - Create role-competency matrix
   - `create_stored_procedures.py` - Create stored procedures
   - `create_competency_indicators_table.py` - Create competency indicators table
   - `create_competency_feedback_stored_procedures.py` - Create feedback stored procedures
   - `create_test_user.py` - Create test user

4. **Data Extraction/Update Scripts**:
   - `extract_matrix_data.py` - Extract matrix data
   - `extract_archetype_matrix.py` - Extract archetype matrix
   - `extract_role_descriptions.py` - Extract role descriptions
   - `update_frontend_role_descriptions.py` - Update frontend role descriptions
   - `update_brief_role_descriptions.py` - Update brief role descriptions
   - `inspect_excel.py` - Inspect Excel files
   - `check_excel_roles.py` - Check Excel roles
   - `init_module_library.py` - Initialize module library
   - `init_questionnaire_data.py` - Initialize questionnaire data
   - `update_complete_questionnaires.py` - Update questionnaires
   - `update_real_questions.py` - Update questions

### SAFE TO REMOVE - Debug/Analysis Scripts ❌

These scripts were used for debugging and analysis during development:

1. **Check Scripts** (verification):
   - `check_existing_tables.py` - Check existing tables
   - `check_org_matrices.py` - Check organization matrices
   - `check_stored_procedure.py` - Check stored procedure
   - `check_role_competency_matrix.py` - Check role-competency matrix
   - `check_role8_data.py` - Check role 8 data
   - `check_roles.py` - Check roles
   - `check_role_data.py` - Check role data
   - `check_process_involvement.py` - Check process involvement
   - `check_exact_values.py` - Check exact values
   - `check_debug_test_user.py` - Check debug test user
   - `check_constraint.py` - Check constraint
   - `check_existing_values.py` - Check existing values
   - `check_user_competencies.py` - Check user competencies
   - `check_indicators.py` - Check indicators

2. **Analysis Scripts**:
   - `analyze_role_matrices.py` - Analyze role matrices
   - `analyze_competency_vectors.py` - Analyze competency vectors
   - `analyze_derik_vectors.py` - Analyze Derik vectors
   - `analyze_qa_profile.py` - Analyze QA profile
   - `analyze_role_differentiation.py` - Analyze role differentiation
   - `analyze_model_sync.py` - Analyze model sync
   - `analyze_zero_level_competencies.py` - Analyze zero level competencies
   - `compare_with_derik.py` - Compare with Derik
   - `compare_role_competency_sources.py` - Compare role-competency sources

3. **Debug Scripts**:
   - `debug_responses.py` - Debug responses
   - `debug_findprocesses.py` - Debug findProcesses endpoint
   - `debug_role_suggestion_accuracy.py` - Debug role suggestion accuracy
   - `show_all_data.py` - Show all data

4. **Test Scripts**:
   - `test_user_model.py` - Test user model
   - `test_stored_procedure.py` - Test stored procedure
   - `test_llm_pipeline.py` - Test LLM pipeline
   - `test_llm_direct.py` - Test LLM direct
   - `test_llm_vs_euclidean.py` - Test LLM vs Euclidean
   - `test_role_suggestion_end_to_end.py` - Test role suggestion end-to-end
   - `test_involvement_mapping.py` - Test involvement mapping
   - `test_end_to_end_role_mapping.py` - Test end-to-end role mapping
   - `test_new_assessment_endpoints.py` - Test new assessment endpoints

5. **Validation Scripts**:
   - `validate_indicator_matching.py` - Validate indicator matching

### KEEP - Core Application Files ✅

1. **run.py** - Application entry point ✅ KEEP
2. **models.py** - Database models ✅ KEEP

---

## 4. Unused Imports in routes.py

From the analysis, routes.py imports these models but may not use all of them:

```python
from models import (
    db,  # ✅ USED
    User,  # ✅ USED
    SECompetency,  # ⚠️ Alias for Competency - CHECK
    SERole,  # ⚠️ Alias for RoleCluster - CHECK
    QualificationArchetype,  # ❌ LIKELY UNUSED
    Assessment,  # ⚠️ CHECK USAGE
    CompetencyAssessmentResult,  # ⚠️ CHECK USAGE
    LearningObjective,  # ⚠️ CHECK USAGE
    CompanyContext,  # ❌ LIKELY UNUSED (RAG system)
    RAGTemplate,  # ❌ LIKELY UNUSED (RAG system)
    Organization,  # ✅ USED
    MaturityAssessment,  # ⚠️ CHECK vs PhaseQuestionnaireResponse
    CompetencyAssessment,  # ⚠️ Alias - CHECK
    RoleMapping,  # ❌ LIKELY UNUSED (wrapper class)
    RoleCluster,  # ✅ USED
    IsoProcesses,  # ✅ USED
    Competency,  # ✅ USED
    CompetencyIndicator,  # ✅ USED
    RoleProcessMatrix,  # ✅ USED
    ProcessCompetencyMatrix,  # ✅ USED
    RoleCompetencyMatrix,  # ✅ USED
    UnknownRoleProcessMatrix,  # ✅ USED
    UnknownRoleCompetencyMatrix,  # ✅ USED
    AppUser,  # ❌ LEGACY - Should be removed
    UserCompetencySurveyResults,  # ✅ USED (Alias)
    UserRoleCluster,  # ✅ USED
    UserSurveyType,  # ❌ LIKELY UNUSED
    NewSurveyUser,  # ⚠️ LEGACY - CHECK USAGE
    UserCompetencySurveyFeedback,  # ✅ USED
    calculate_maturity_score,  # ✅ USED (function)
    select_archetype,  # ⚠️ CHECK USAGE (function)
    generate_learning_plan_templates,  # ❌ LIKELY UNUSED (function)
    generate_basic_modules  # ❌ LIKELY UNUSED (function)
)
```

---

## 5. Cleanup Recommendations

### IMMEDIATE SAFE REMOVALS (No Risk)

#### A. Delete Utility Scripts (78 files)
Move to `archive/` or delete entirely:
- All `test_*.py` files (12 files)
- All `check_*.py` files (15 files)
- All `analyze_*.py` files (8 files)
- All `debug_*.py` files (3 files)
- All `populate_*.py` files (6 files)
- All `init_*.py` files (3 files)
- All `create_*.py` files (7 files)
- All `fix_*.py` files (6 files)
- All `extract_*.py` files (3 files)
- All `update_*.py` files (4 files)
- Other setup scripts (11 files)

**Action**: Create `src/backend/archive/` and move all these files there.

#### B. Delete Orphaned Backend Files
Files in `src/backend/app/`:
- `routes_role_suggestion_SIMPLE.py` - Appears to be a backup file
- Potentially `routes.py.backup_before_simplification` (if it exists)

### REQUIRES INVESTIGATION

#### C. Verify Blueprint Usage
**Action Required**: Check if frontend actually uses these blueprints:
1. **questionnaire_bp** - Is the complex Questionnaire system used?
2. **module_bp** - Is the LearningModule system implemented?
3. **competency_service_bp** - Duplicate of main_bp routes?
4. **derik_bp** - Is the Derik bridge actively used?
5. **seqpt_bp** - Is the RAG-LLM system active?

#### D. Verify Model Usage
**Action Required**: Run queries to check if these models have data in database:
1. **IsoSystemLifeCycleProcesses**, **IsoActivities**, **IsoTasks** - Are these used?
2. **AppUser** - Migrate to User and remove
3. **UserSurveyType** - Is this used?
4. **NewSurveyUser** - Legacy, replace with UserAssessment
5. **MaturityAssessment** - vs PhaseQuestionnaireResponse?
6. **QualificationArchetype** - Is this used?
7. **Assessment** - vs UserAssessment?
8. **CompetencyAssessmentResult** - vs UserCompetencySurveyResult?
9. **Questionnaire/Question/QuestionOption/QuestionnaireResponse/QuestionResponse** - Complex system vs PhaseQuestionnaireResponse?
10. **LearningModule/LearningPath/ModuleEnrollment/ModuleAssessment/LearningResource** - Are these implemented?

#### E. Clean Up Imports
**Action Required**: Remove unused imports from routes.py:
- `QualificationArchetype` (if unused)
- `CompanyContext` (if RAG not active)
- `RAGTemplate` (if RAG not active)
- `RoleMapping` (wrapper class, likely unused)
- `AppUser` (legacy, should be User)
- `UserSurveyType` (if unused)
- `generate_learning_plan_templates` (if unused)
- `generate_basic_modules` (if unused)

---

## 6. Next Steps

### Phase 1: Safe Cleanup (No Breaking Changes)
1. ✅ Archive all utility scripts to `src/backend/archive/`
2. ✅ Delete `routes_role_suggestion_SIMPLE.py` (backup file)
3. ✅ Remove unused imports from routes.py (after verification)

### Phase 2: Database Analysis
1. ⚠️ Query database to check which models have data
2. ⚠️ Identify truly unused models
3. ⚠️ Plan migration path for legacy models (AppUser → User)

### Phase 3: Blueprint Consolidation
1. ⚠️ Verify frontend usage of each blueprint
2. ⚠️ Merge redundant blueprints into main_bp if appropriate
3. ⚠️ Remove unused blueprints

### Phase 4: Model Cleanup
1. ⚠️ Remove unused models from models.py
2. ⚠️ Create database migration to drop unused tables
3. ⚠️ Update all imports across codebase

---

## Appendix: File Count Summary

- **Total Python files in src/backend/**: 81 files
- **Core application files**: 3 files (run.py, models.py, setup_database.py)
- **Blueprint files in src/backend/app/**: 15 files
- **Utility scripts (archivable)**: 78+ files
- **Database model classes**: 39 models
- **Blueprint endpoints**: ~115+ total endpoints across all blueprints

**Potential Cleanup Savings**:
- Delete/Archive: ~78 utility scripts (96% of backend folder files)
- Investigate: 5-8 blueprints for potential consolidation
- Review: ~20 database models for usage verification

---

**END OF ANALYSIS**
