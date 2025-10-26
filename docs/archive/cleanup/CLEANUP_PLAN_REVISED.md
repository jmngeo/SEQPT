# SE-QPT Codebase Cleanup Plan (REVISED)
**Date**: 2025-10-25
**Revision**: Corrected to preserve setup scripts for new environment deployment

---

## Key Insight from User Feedback

**User Question**: "Populate and init scripts - aren't they important when setting this project up in a new environment?"

**Answer**: YES! You're absolutely correct. These scripts ARE essential for:
- Setting up the project on a new machine
- Initializing a fresh database with reference data
- Populating ISO processes, competencies, roles, and matrices
- Creating stored procedures and database functions

**Revised Strategy**: Organize scripts by purpose rather than deleting them all.

---

## Script Organization Strategy

### ✅ KEEP - Essential Setup Scripts (Move to `setup/`)

These scripts are **REQUIRED** for setting up SE-QPT in a new environment:

#### **Core Setup Scripts** → `src/backend/setup/core/`
1. `setup_database.py` - Main database setup script
2. `init_db_as_postgres.py` - Initialize database as postgres user
3. `create_user_and_grant.py` - Create seqpt_admin database user
4. `grant_permissions.py` - Grant necessary permissions
5. `fix_schema_permissions.py` - Fix schema permissions (may be needed)

#### **Data Population Scripts** → `src/backend/setup/populate/`
6. `populate_iso_processes.py` - ✅ Populate 30 ISO/IEC 15288 processes
7. `populate_competencies.py` - ✅ Populate 16 SE competencies
8. `populate_competency_indicators.py` - ✅ Populate competency behavioral indicators
9. `populate_roles_and_matrices.py` - ✅ Populate 14 SE roles + initial matrices
10. `populate_process_competency_matrix.py` - ✅ Populate global process-competency mapping
11. `add_14_roles.py` - ✅ Add/update 14 SE role clusters (if needed)
12. `add_derik_process_tables.py` - ✅ Add Derik's process tables (ISO hierarchy)
13. `align_iso_processes.py` - ✅ Align ISO processes with standard
14. `initialize_all_data.py` - ✅ **MASTER SCRIPT** - Run all population scripts in order

#### **Database Objects** → `src/backend/setup/database_objects/`
15. `create_stored_procedures.py` - ✅ Create competency calculation stored procedures
16. `create_competency_feedback_stored_procedures.py` - ✅ Create feedback procedures
17. `create_competency_indicators_table.py` - ✅ Create indicators table (if not in models)
18. `create_role_competency_matrix.py` - ✅ Create role-competency matrix calculation

#### **UI Data** → `src/backend/setup/ui_data/`
19. `init_questionnaire_data.py` - ✅ Initialize questionnaire data
20. `init_module_library.py` - ✅ Initialize learning module library
21. `update_complete_questionnaires.py` - ✅ Update questionnaire definitions
22. `update_real_questions.py` - ✅ Update real questions

#### **Reference Data Updates** → `src/backend/setup/reference/`
23. `extract_role_descriptions.py` - Extract role descriptions from Excel
24. `update_frontend_role_descriptions.py` - Update frontend with role descriptions
25. `update_brief_role_descriptions.py` - Update brief role descriptions

#### **Utilities** → `src/backend/setup/utils/`
26. `backup_database.py` - ✅ Database backup utility
27. `rename_database.py` - Database rename utility (may be useful)
28. `create_test_user.py` - ✅ Create test user for development

**Total KEEP: 28 scripts**

---

### 📦 ARCHIVE - One-Time Migration/Fix Scripts (Move to `archive/migrations/`)

These were used for specific migrations and fixes but aren't needed for fresh setup:

#### **Foreign Key Fixes** (Already applied to codebase)
1. `fix_phase_questionnaire_fk.py` - Fixed Phase 1 questionnaire FK constraint
2. `fix_all_user_fks.py` - Fixed user foreign key issues
3. `fix_constraint.py` - Fixed specific constraint
4. `fix_constraint_with_migration.py` - Fixed constraint with migration

#### **Data Fixes** (Already applied to database)
5. `fix_role_competency_discrepancies.py` - Fixed role-competency data issues
6. `apply_role_competency_fixes.py` - Applied role-competency fixes
7. `populate_org11_matrices.py` - One-time population for org 11 (specific org)
8. `populate_org11_role_competency_matrix.py` - One-time population for org 11

**Total ARCHIVE (Migrations): 8 scripts**

---

### 📦 ARCHIVE - Debug/Development Scripts (Move to `archive/debug/`)

These were used during development for debugging and analysis:

#### **Check/Verification Scripts**
9. `check_existing_tables.py`
10. `check_org_matrices.py`
11. `check_stored_procedure.py`
12. `check_role_competency_matrix.py`
13. `check_role8_data.py`
14. `check_roles.py`
15. `check_role_data.py`
16. `check_process_involvement.py`
17. `check_exact_values.py`
18. `check_debug_test_user.py`
19. `check_constraint.py`
20. `check_existing_values.py`
21. `check_user_competencies.py`
22. `check_indicators.py`
23. `check_excel_roles.py`

#### **Analysis Scripts**
24. `analyze_role_matrices.py`
25. `analyze_competency_vectors.py`
26. `analyze_derik_vectors.py`
27. `analyze_qa_profile.py`
28. `analyze_role_differentiation.py`
29. `analyze_model_sync.py`
30. `analyze_zero_level_competencies.py`

#### **Comparison Scripts**
31. `compare_with_derik.py`
32. `compare_role_competency_sources.py`

#### **Debug Scripts**
33. `debug_responses.py`
34. `debug_findprocesses.py`
35. `debug_role_suggestion_accuracy.py`

#### **Data Inspection Scripts**
36. `show_all_data.py`
37. `inspect_excel.py`

#### **Data Extraction Scripts** (Development-only)
38. `extract_matrix_data.py` - Extract matrix data to text
39. `extract_archetype_matrix.py` - Extract archetype matrix

**Total ARCHIVE (Debug): 31 scripts**

---

### 📦 ARCHIVE - Test Scripts (Move to `archive/tests/`)

Unit and integration tests (could move to `tests/` folder instead):

40. `test_user_model.py`
41. `test_stored_procedure.py`
42. `test_llm_pipeline.py`
43. `test_llm_direct.py`
44. `test_llm_vs_euclidean.py`
45. `test_role_suggestion_end_to_end.py`
46. `test_involvement_mapping.py`
47. `test_end_to_end_role_mapping.py`
48. `test_new_assessment_endpoints.py`

#### **Validation Scripts**
49. `validate_indicator_matching.py`

**Total ARCHIVE (Tests): 9 scripts**

**Alternative**: Move to `src/backend/tests/` if you want to keep tests accessible

---

### 🗑️ DELETE - Backup Files

These are redundant backup files that can be safely deleted:

1. `src/backend/app/routes.py.backup_before_simplification`
2. `src/backend/app/mvp_routes.py.archived`
3. `src/backend/app/routes_role_suggestion_SIMPLE.py`

**Total DELETE: 3 files**

---

### ⚠️ DANGEROUS - Do NOT Delete

1. `drop_all_tables.py` - Useful for development (complete database reset)
   - **Recommendation**: Move to `setup/utils/` with WARNING comment
   - Add confirmation prompt to prevent accidental execution

---

## Recommended Folder Structure

```
src/backend/
├── setup/                          # ✅ Setup scripts for new environments
│   ├── README.md                   # Setup instructions
│   ├── core/                       # Database and user setup
│   │   ├── setup_database.py
│   │   ├── init_db_as_postgres.py
│   │   ├── create_user_and_grant.py
│   │   ├── grant_permissions.py
│   │   └── fix_schema_permissions.py
│   ├── populate/                   # Data population scripts
│   │   ├── initialize_all_data.py  # ⭐ MASTER SCRIPT
│   │   ├── populate_iso_processes.py
│   │   ├── populate_competencies.py
│   │   ├── populate_competency_indicators.py
│   │   ├── populate_roles_and_matrices.py
│   │   ├── populate_process_competency_matrix.py
│   │   └── ...
│   ├── database_objects/           # Stored procedures, functions
│   │   ├── create_stored_procedures.py
│   │   └── ...
│   ├── ui_data/                    # UI/frontend data
│   │   └── ...
│   ├── reference/                  # Reference data updates
│   │   └── ...
│   └── utils/                      # Utilities
│       ├── backup_database.py
│       ├── create_test_user.py
│       └── drop_all_tables.py      # ⚠️ DANGEROUS
├── archive/                        # 📦 Historical/debug scripts
│   ├── migrations/                 # One-time migration scripts
│   ├── debug/                      # Debug/analysis scripts
│   └── tests/                      # Test scripts (or move to tests/)
├── tests/                          # 🧪 Active test suite (optional)
├── app/                            # Flask application
├── models.py                       # Database models
└── run.py                          # Application entry point
```

---

## Setup Documentation (NEW)

### Create: `src/backend/setup/README.md`

```markdown
# SE-QPT Backend Setup Guide

## New Environment Setup

### Prerequisites
- PostgreSQL 12+ installed
- Python 3.9+ with venv
- Database credentials ready

### Step 1: Database Setup
```bash
# As postgres superuser
cd setup/core
python init_db_as_postgres.py
python create_user_and_grant.py
python grant_permissions.py
```

### Step 2: Initialize Database Schema
```bash
# Run Flask migrations
cd ../..
python run.py db upgrade
```

### Step 3: Populate Reference Data
```bash
cd setup/populate
python initialize_all_data.py  # Master script runs all population scripts
```

This will populate:
- ✅ 30 ISO/IEC 15288 processes
- ✅ 16 SE competencies
- ✅ 14 SE role clusters
- ✅ Competency behavioral indicators
- ✅ Global matrices (process-competency)

### Step 4: Create Database Objects
```bash
cd ../database_objects
python create_stored_procedures.py
python create_competency_feedback_stored_procedures.py
```

### Step 5: Initialize UI Data
```bash
cd ../ui_data
python init_questionnaire_data.py
python init_module_library.py
```

### Step 6: Create Test User (Development)
```bash
cd ../utils
python create_test_user.py
```

### Verification
```bash
# Check database population
python ../../show_all_data.py  # If kept
```

## Backup & Restore
```bash
cd setup/utils
python backup_database.py
```
```

---

## Cleanup Execution Plan

### Phase 1: Create Folder Structure
```bash
mkdir -p src/backend/setup/{core,populate,database_objects,ui_data,reference,utils}
mkdir -p src/backend/archive/{migrations,debug,tests}
```

### Phase 2: Move Setup Scripts
Move 28 essential setup scripts to appropriate `setup/` subfolders.

### Phase 3: Archive Development Scripts
Move 48 debug/analysis/test scripts to `archive/`.

### Phase 4: Delete Backup Files
Delete 3 backup files.

### Phase 5: Create Documentation
Create `setup/README.md` with setup instructions.

---

## Summary

| Category | Count | Action | Destination |
|----------|-------|--------|-------------|
| **Essential Setup Scripts** | 28 | MOVE | `setup/` subfolders |
| **Migration/Fix Scripts** | 8 | ARCHIVE | `archive/migrations/` |
| **Debug/Analysis Scripts** | 31 | ARCHIVE | `archive/debug/` |
| **Test Scripts** | 9 | ARCHIVE | `archive/tests/` (or `tests/`) |
| **Backup Files** | 3 | DELETE | — |
| **Core App Files** | 3 | KEEP | `src/backend/` |
| **Blueprint Files** | 15 | KEEP | `src/backend/app/` |

**Total Files**: 97
**Files to Organize**: 79 (setup: 28, archive: 48, delete: 3)
**Workspace Cleanup**: 81% reduction in root folder clutter

---

## Benefits

✅ **New Environment Setup**: Clear, documented setup process
✅ **Organized Repository**: Setup scripts separated from development scripts
✅ **Preserved History**: All scripts archived, not deleted
✅ **Clean Workspace**: 81% fewer files in backend root folder
✅ **Better Onboarding**: New developers can easily set up the project
✅ **Maintainability**: Easy to find and update setup scripts

---

**END OF REVISED CLEANUP PLAN**
