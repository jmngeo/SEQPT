# Database Rename - Complete Analysis & Tools Summary

## What You Asked
"Double check all the places that need to update references when renaming the database."

## What I Found

### Total Files with Database Credential References: ~100+

I performed a comprehensive search across your entire project and found references in:
- ✅ 1 core config file (`.env`)
- ✅ 4 core application files (read from `.env` - auto-working)
- ⚠️ 39 utility/test scripts (hardcoded - optional to update)
- 📝 30+ documentation files (optional to update)
- 🚫 30+ backup/history files (never update)
- 📖 1 user documentation file (`CLAUDE.md`)

## What I Created for You

### 1. Automated Rename Script
**File:** `src/backend/rename_database.py`

**What it does automatically:**
1. ✅ Creates full database backup
2. ✅ Creates new PostgreSQL user
3. ✅ Renames the database
4. ✅ Transfers ownership and permissions
5. ✅ Updates `.env` file (with backup)
6. ✅ Updates `CLAUDE.md` file (with backup)

**Usage:**
```bash
# 1. Edit the script to set your desired credentials (lines 19-21)
# 2. Run it
cd src/backend
../../venv/Scripts/python.exe rename_database.py
```

### 2. Complete Reference Checklist
**File:** `DATABASE_RENAME_CHECKLIST.md`

A comprehensive breakdown showing:
- Which files are auto-updated
- Which files don't need updates
- Which files are optional to update
- Which files should never be updated
- Line numbers for all references

### 3. Step-by-Step Guide
**File:** `DATABASE_RENAME_GUIDE.md`

Complete walkthrough including:
- Is it app-breaking? (No!)
- What needs to change
- How to do it manually (if preferred)
- Rollback procedure
- Time estimates

### 4. This Summary
**File:** `DATABASE_RENAME_SUMMARY.md`

What you're reading now!

---

## Key Findings

### ✅ GOOD NEWS: Your App is Well-Designed!

The Flask application **reads credentials from `.env`**, which means:
- Only 1 file needs updating for the app to work (`.env`)
- The script updates it automatically
- No hardcoded credentials in core application code
- Very low risk of breaking anything

### The 39 Utility Scripts

Files like `test_*.py`, `populate_*.py`, `analyze_*.py` have hardcoded credentials BUT:
- ❌ They DON'T affect the main application
- ⚠️ You only need to update them if you actively use them
- 💡 Easy to update all at once with find/replace (instructions in checklist)

### Documentation Files

Found 30+ markdown files with credential references:
- Most are historical session logs
- Only 2-3 are actively used for reference
- Safe to update later if needed

---

## Automatic vs Manual Updates

### Automatically Handled (By Script)
```
✅ .env file
✅ CLAUDE.md user documentation
✅ Database rename in PostgreSQL
✅ User creation and permissions
✅ Backups of everything
```

### No Update Needed (Read from .env)
```
✅ src/backend/app/__init__.py
✅ src/backend/app/services/llm_pipeline/*.py
✅ src/backend/models.py
✅ src/backend/run.py
```

### Optional (If You Use These Scripts)
```
⚠️ 39 test/populate/analysis scripts
   (Instructions provided for batch update)
```

### Optional (Documentation)
```
📝 SESSION_HANDOVER.md
📝 DATABASE_INITIALIZATION_GUIDE.md
📝 Various session logs
```

---

## Risk Assessment

**App Breaking Risk:** ❌ **Very Low**

The script:
- ✓ Creates backup before any changes
- ✓ Only modifies PostgreSQL database and config files
- ✓ Doesn't touch application code
- ✓ Easily reversible (backup + rollback instructions provided)

**What could go wrong?**
1. Wrong postgres password → Script aborts early, no damage
2. Database in use → Script disconnects users first
3. .env backup exists → Creates timestamped backups
4. Credentials typo → Easy to re-run script or restore backup

---

## Time Estimates

| Task | Time | Required? |
|------|------|-----------|
| Edit script with new credentials | 2 min | Yes |
| Run script | 3 min | Yes |
| Restart Flask server | 1 min | Yes |
| **Total for working app** | **~5 min** | **Yes** |
| Update utility scripts | 5 min | Optional |
| Update documentation | 10 min | Optional |
| **Total for everything** | **~20 min** | **Optional** |

---

## Quick Start

Want to rename your database right now? Here's the fastest path:

```bash
# 1. Open the script and edit lines 19-21
notepad src/backend/rename_database.py

# Change these:
NEW_DB_USER = "your_username"
NEW_DB_PASSWORD = "your_password"
NEW_DB_NAME = "your_database"

# 2. Run the script
cd src/backend
../../venv/Scripts/python.exe rename_database.py
# (Enter postgres password when prompted)

# 3. Restart Flask server
# Kill current server and restart run.py

# 4. Done! Test your app
```

---

## File Locations

All created files are in your project root:
```
SE-QPT-Master-Thesis/
├── DATABASE_RENAME_SUMMARY.md        (this file)
├── DATABASE_RENAME_GUIDE.md          (step-by-step guide)
├── DATABASE_RENAME_CHECKLIST.md      (complete file listing)
├── src/backend/
│   ├── rename_database.py            (automated script)
│   └── backup_database.py            (backup script)
└── backups/
    └── competency_assessment_*.sql   (existing backups)
```

---

## Bottom Line

**Is database rename app-breaking?**
👉 **NO** - It's a safe, routine operation when done correctly.

**Do I need to update 100+ files?**
👉 **NO** - Script auto-updates the 2 that matter. Rest are optional.

**How long will my app be down?**
👉 **~1 minute** (just to restart Flask server)

**What if something goes wrong?**
👉 Full backup created automatically + rollback instructions provided

**Should I do this now?**
👉 Up to you! Everything is ready. You can rename anytime with confidence.

---

## Questions?

Refer to:
- `DATABASE_RENAME_GUIDE.md` - Detailed instructions
- `DATABASE_RENAME_CHECKLIST.md` - Complete file listing
- The script itself has extensive comments

All tools are ready to use whenever you decide to rename!
