# Database Rename - Complete Update Checklist

## Overview
This document lists ALL files that reference the current database credentials and whether they need updating.

**Current Credentials:**
- Database: `competency_assessment`
- Username: `ma0349`
- Password: `MA0349_2025`

---

## ✅ AUTOMATICALLY UPDATED (By Script)

These files are automatically updated by `rename_database.py`:

### 1. Core Configuration
- ✅ `.env` - **DATABASE_URL updated automatically**
- ✅ `C:\Users\jomon\.claude\CLAUDE.md` - **Database credentials updated automatically**
- ✅ Backups created automatically for both files

---

## ✅ NO UPDATE NEEDED (Reads from .env)

These files read from environment variables, so they work automatically after `.env` is updated:

### Core Application Files
- ✅ `src/backend/app/__init__.py` - Reads `os.getenv('DATABASE_URL')`
- ✅ `src/backend/app/services/llm_pipeline/llm_process_identification_pipeline.py` - Reads from env
- ✅ `src/backend/models.py` - Uses Flask's config (which reads from .env)
- ✅ `src/backend/run.py` - Uses Flask's config

**Result:** Main application will work immediately after restart!

---

## ⚠️ OPTIONAL UPDATES (Utility Scripts)

These are **test/populate/analysis scripts** with hardcoded credentials. They DON'T affect the main app but you may want to update them if you use these scripts:

### Analysis Scripts (39 files total)
```
src/backend/add_derik_process_tables.py:20
src/backend/analyze_qa_profile.py:5
src/backend/align_iso_processes.py:7
src/backend/analyze_role_differentiation.py:10
src/backend/analyze_role_matrices.py:3
src/backend/apply_role_competency_fixes.py:5
src/backend/check_constraint.py:4
src/backend/check_exact_values.py:5
src/backend/check_existing_values.py:4
src/backend/check_org_matrices.py:8
src/backend/check_process_involvement.py:5
src/backend/check_role8_data.py:5
src/backend/check_role_competency_matrix.py:2
src/backend/check_stored_procedure.py:3
src/backend/check_user_competencies.py:11
src/backend/compare_role_competency_sources.py:17
src/backend/create_role_competency_matrix.py:6
src/backend/create_stored_procedures.py:6
src/backend/debug_role_suggestion_accuracy.py:9
src/backend/fix_constraint.py:4
src/backend/fix_constraint_with_migration.py:4
src/backend/fix_role_competency_discrepancies.py:5
src/backend/populate_competencies.py:7
src/backend/populate_iso_processes.py:10
src/backend/populate_org11_matrices.py:5
src/backend/populate_org11_role_competency_matrix.py:6
src/backend/populate_process_competency_matrix.py:7
src/backend/populate_roles_and_matrices.py:7
src/backend/test_end_to_end_role_mapping.py:17
src/backend/test_involvement_mapping.py:10
src/backend/test_llm_direct.py:5
src/backend/test_llm_pipeline.py:6
```

**How to update all at once (if you want to):**

After renaming, run this PowerShell script:
```powershell
cd C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\backend

# Replace old credentials with new ones in all .py files
Get-ChildItem -Filter "*.py" | ForEach-Object {
    (Get-Content $_.FullName) -replace
        'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment',
        'postgresql://NEW_USER:NEW_PASS@localhost:5432/NEW_DB' |
    Set-Content $_.FullName
}
```

Or just update these constants at the top of each file when you need to use them.

### Special Cases

**backup_database.py** - Update credentials for future backups:
```python
# Lines 11-15
DB_USER = "NEW_USER"
DB_PASSWORD = "NEW_PASS"
DB_NAME = "NEW_DATABASE"
```

**rename_database.py** - Already has new credentials defined (that's its job!)

**init_db_as_postgres.py** - Uses postgres superuser, might not need update

**setup_database.py** - Has old example credentials, can be ignored

---

## 📝 DOCUMENTATION UPDATES (Optional but Recommended)

These documentation files reference old credentials. Update them for future reference:

### High Priority (Frequently Referenced)
1. ~~**`C:\Users\jomon\.claude\CLAUDE.md`**~~ - ✅ **Auto-updated by script!**

2. **`SESSION_HANDOVER.md`** (lines 339, 426)
   - Update for next session reference

3. **`DATABASE_INITIALIZATION_GUIDE.md`** (lines 154-155, 165, 358)
   - Update setup instructions

### Medium Priority (Reference Documents)
- `DATABASE_RENAME_GUIDE.md` - Already has both old and new examples
- `NEW_MACHINE_SETUP_GUIDE.md:303`
- `SETUP_AUTOMATION_COMPLETE.md:286`
- `MD Files/INTEGRATION_COMPLETE.md:354-356`
- `MD Files/PHASE2_SESSION_START_GUIDE.md:386-387, 392, 414, 505`
- `MD Files/RESTORATION_SUCCESS_SUMMARY.md:44-46, 168, 179`
- `MD Files/SESSION_2025-10-18_TASK1_COMPLETE.md:246-250, 260, 314`
- `src/backend/README_SETUP.md:27, 110-115, 151, 184`

### Low Priority (Historical/Archive)
- Various session logs in `MD Files/SESSION_*.md`
- Archive folders: `archives/competency_assessor_*/`
- Data documentation: `data/*.md`
- File history: `C:\Users\jomon\.claude\file-history/` (leave as-is)

---

## 🚫 NEVER UPDATE (Leave As-Is)

These should NOT be updated:

### Backup Files
- ✅ `backups/competency_assessment_*.sql` - Historical backups (keep original credentials)
- ✅ `backups/competency_assessment_*.dump` - Compressed backups

### File History
- ✅ `.claude/file-history/**` - Historical snapshots (don't modify)

### Reference Implementation
- ✅ Derik's original project: `sesurveyapp-main/` - Keep as reference

---

## 🎯 RECOMMENDED UPDATE WORKFLOW

### Phase 1: Run the Script (5 minutes)
1. Edit `src/backend/rename_database.py` - Set new credentials
2. Run script - Creates backup, renames database, updates `.env` and `CLAUDE.md`
3. Restart Flask server

**Status after Phase 1:** ✅ **Main application fully working!**

### Phase 2: Update Key Documentation (5 minutes)
Update these 2 files so future sessions have correct info:
1. `SESSION_HANDOVER.md`
2. `DATABASE_INITIALIZATION_GUIDE.md`

### Phase 3: Update Utility Scripts (Optional)
Only if you actively use test/populate/analysis scripts:
- Use PowerShell find/replace script above
- Or update manually when you need to run a specific script

---

## 📊 Summary Statistics

**Total files with references:** ~100+

**Breakdown:**
- ✅ Auto-updated: 2 (`.env`, `CLAUDE.md`)
- ✅ No update needed: 4 (core app files)
- ⚠️ Optional (utility scripts): 39
- 📝 Documentation: 30+
- 🚫 Never update: 30+ (backups, history)

**Critical for app to work:** Only `.env` (auto-updated by script)

**Everything else:** Nice to have, but not required for the app to function!

---

## Quick Reference: What Makes the App Work?

The Flask app only needs these to connect:
1. ✅ `.env` file with correct `DATABASE_URL`
2. ✅ PostgreSQL database exists
3. ✅ PostgreSQL user has permissions

That's it! Everything else is just documentation and utility scripts.
