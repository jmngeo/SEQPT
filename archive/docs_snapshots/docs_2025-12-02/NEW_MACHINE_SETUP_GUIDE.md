# New Machine Setup Guide for SE-QPT

**Date:** 2025-10-21
**Critical**: Follow these steps EXACTLY to avoid missing critical matrix data!

---

## Overview: What Needs to Be Set Up

When setting up SE-QPT on a new machine, you must populate:

1. **Process-Competency Matrix** (GLOBAL) - 448 entries
2. **Role-Process Matrix for Organization 1** (TEMPLATE) - 392 entries
3. ISO Processes, Roles, and Competencies (reference data)

**Risk**: If you forget steps 1 or 2, new organizations will have EMPTY matrices and the system will not function correctly!

---

## Current Status: ⚠️ MANUAL PROCESS (High Risk of Forgetting!)

### What We Have

#### 1. Setup Script (`setup_database.py`) - INCOMPLETE
```bash
cd src/backend
python setup_database.py
```

**What it does:**
- ✓ Creates PostgreSQL database
- ✓ Creates user and grants privileges
- ✓ Runs Flask migrations (creates tables)
- ✓ Calls `run.py --init-db` for data initialization

**What it DOESN'T do:**
- ❌ Does NOT populate process_competency_matrix
- ❌ Does NOT populate role_process_matrix for org 1
- ❌ INCOMPLETE - You must run additional scripts manually!

#### 2. Manual Populate Scripts (MUST RUN!)

You must run these scripts **MANUALLY** after `setup_database.py`:

```bash
# Step 1: Populate ISO processes
python populate_iso_processes.py

# Step 2: Populate competencies
python populate_competencies.py

# Step 3: Populate roles and role-process matrix (org 1)
python populate_roles_and_matrices.py

# Step 4: Populate process-competency matrix (GLOBAL)
python populate_process_competency_matrix.py
```

**Risk**: If you forget any of these, the system will be broken!

---

## Current Scripts Breakdown

### 1. `populate_process_competency_matrix.py`
**Purpose**: Populates the GLOBAL process-competency matrix

**Source Data**:
```python
derik_sql_file = r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\sesurveyapp-main\postgres-init\filtered_init.sql'
```

**Warning**:
- ⚠️ Hard-coded path to Derik's reference data
- ⚠️ Path may not exist on new machine
- ⚠️ Not automated

**What it populates**:
- 448 entries (28 processes × 16 competencies)
- Values: 0 or 1 (binary - process needs competency or not)

**Example Entry**:
```
iso_process_id=21 (Implementation)
competency_id=1 (Systems Thinking)
process_competency_value=1 (YES, needed)
```

---

### 2. `populate_roles_and_matrices.py`
**Purpose**: Populates roles and role-process matrix for Organization 1

**Data Source**: Hard-coded in the Python file itself

**What it populates**:
- 14 roles in `role_cluster` table
- 392 entries in `role_process_matrix` for organization_id=1

**Example Entry**:
```
organization_id=1
role_cluster_id=5 (Specialist Developer)
iso_process_id=21 (Implementation)
role_process_value=2 (Responsible)
```

**Why Organization 1 Matters**:
- Organization 1 serves as the **TEMPLATE** for all new organizations
- When a new org registers, it COPIES role-process matrix from org 1
- If org 1 is empty, all new orgs will be empty!

---

### 3. `populate_iso_processes.py`
**Purpose**: Populates the 28 ISO/IEC 15288 processes

**Example**:
```
id=21, name="Implementation", description="Realize system elements"
```

---

### 4. `populate_competencies.py`
**Purpose**: Populates the 16 SE competencies

**Example**:
```
id=1, name="Systems Thinking", area="Core"
```

---

## The Problem: Easy to Forget!

### Scenario 1: Forgot Process-Competency Matrix
```
New org created → Copies role-process from org 1 → Calculates role-competency
                                                   ↓
                                            BUT process_competency_matrix is EMPTY!
                                                   ↓
                                            Result: All role-competency values = 0
                                                   ↓
                                            SYSTEM BROKEN!
```

### Scenario 2: Forgot Role-Process Matrix for Org 1
```
New org created → Copies role-process from org 1
                        ↓
                  BUT org 1 matrix is EMPTY!
                        ↓
                  New org gets 0 entries
                        ↓
                  Calculates role-competency: 0 × anything = 0
                        ↓
                  SYSTEM BROKEN!
```

---

## Recommended Solution: Create Master Setup Script

### Proposed: `initialize_all_data.py`

```python
"""
Master initialization script for SE-QPT database
Runs ALL required populate scripts in correct order
"""

import os
import sys
import subprocess

def run_script(script_name):
    """Run a populate script and check for errors"""
    print(f"\n{'=' * 60}")
    print(f"Running: {script_name}")
    print('=' * 60)

    result = subprocess.run(['python', script_name], capture_output=True, text=True)

    if result.returncode == 0:
        print(f"[OK] {script_name} completed successfully")
        if result.stdout:
            print(result.stdout)
        return True
    else:
        print(f"[ERROR] {script_name} failed!")
        print(result.stderr)
        return False

def main():
    """Run all initialization scripts in correct order"""
    os.chdir(os.path.dirname(__file__))

    scripts = [
        'populate_iso_processes.py',       # ISO processes (28 entries)
        'populate_competencies.py',        # Competencies (16 entries)
        'populate_roles_and_matrices.py',  # Roles + role-process for org 1 (14 + 392 entries)
        'populate_process_competency_matrix.py',  # Global matrix (448 entries)
    ]

    print("SE-QPT DATA INITIALIZATION")
    print("=" * 60)
    print("This script will populate ALL required data:")
    print("  1. ISO Processes (28 entries)")
    print("  2. SE Competencies (16 entries)")
    print("  3. Roles (14 entries)")
    print("  4. Role-Process Matrix for Org 1 (392 entries)")
    print("  5. Process-Competency Matrix (448 entries - GLOBAL)")
    print("=" * 60)

    response = input("\nContinue? (yes/no): ")
    if response.lower() != 'yes':
        print("Aborted.")
        return False

    failed = []
    for script in scripts:
        if not run_script(script):
            failed.append(script)

    print("\n" + "=" * 60)
    if failed:
        print("[FAILED] Some scripts did not complete successfully:")
        for script in failed:
            print(f"  - {script}")
        print("\nPlease fix errors and run again.")
        return False
    else:
        print("[SUCCESS] All data initialized successfully!")
        print("\nDatabase is ready. You can now:")
        print("  1. Start the backend: cd src/backend && python run.py")
        print("  2. Register your first organization")
        print("  3. Organization 1 will serve as template for future orgs")
        return True

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
```

---

## Correct New Machine Setup Process (PROPOSED)

### Step 1: Clone Repository
```bash
git clone <repo-url>
cd SE-QPT-Master-Thesis
```

### Step 2: Install Dependencies
```bash
# Backend
cd src/backend
python -m venv venv
venv/Scripts/activate  # Windows
pip install -r requirements.txt

# Frontend
cd ../frontend
npm install
```

### Step 3: Setup Database (Automated Part)
```bash
cd src/backend
python setup_database.py
# Creates database, user, runs migrations
```

### Step 4: Initialize ALL Data (NEW MASTER SCRIPT)
```bash
cd src/backend
python initialize_all_data.py
# Runs ALL populate scripts in correct order
# This is the CRITICAL step that's easy to forget!
```

### Step 5: Start Servers
```bash
# Backend (Terminal 1)
cd src/backend
python run.py

# Frontend (Terminal 2)
cd src/frontend
npm run dev
```

---

## Verification Checklist

After setup, verify data is populated:

```sql
-- Connect to database
psql -U ma0349 -d competency_assessment

-- Check ISO processes (should have 28 or 30)
SELECT COUNT(*) FROM iso_processes;

-- Check competencies (should have 16 or 18)
SELECT COUNT(*) FROM competency;

-- Check roles (should have 14)
SELECT COUNT(*) FROM role_cluster;

-- Check role-process matrix for org 1 (should have 392)
SELECT COUNT(*) FROM role_process_matrix WHERE organization_id = 1;

-- Check process-competency matrix (should have 448)
SELECT COUNT(*) FROM process_competency_matrix;

-- All these should return rows > 0!
```

---

## What Happens When You Forget

### If You Forget Step 4 (initialize_all_data.py):

**Symptom 1**: New organization created, but role suggestion doesn't work
```
Error: "No processes found for organization"
or
Error: "No competencies calculated"
```

**Symptom 2**: Admin tries to edit matrices, sees empty dropdowns
```
Roles dropdown: Empty
Processes dropdown: Empty
Competencies dropdown: Empty
```

**Symptom 3**: Task-based role mapping returns no results
```
User enters tasks → LLM identifies processes → Database has no matrix data
Result: No role suggestions, all scores = 0
```

---

## Current Gaps & Recommendations

### Gap 1: No Master Initialization Script
**Problem**: Must run 4 scripts manually in correct order
**Risk**: HIGH - Easy to forget or run in wrong order
**Solution**: Create `initialize_all_data.py` (proposed above)

### Gap 2: Hard-coded Paths
**Problem**: `populate_process_competency_matrix.py` references hard-coded path
```python
derik_sql_file = r'C:\Users\jomon\Documents\...\filtered_init.sql'
```
**Risk**: MEDIUM - Path won't exist on other machines
**Solution**:
- Embed data in Python script, OR
- Copy reference data to project repo, OR
- Make path configurable via environment variable

### Gap 3: No Setup Documentation
**Problem**: No single guide explaining complete setup process
**Risk**: HIGH - New developers will miss critical steps
**Solution**: This document! Add link to README.md

### Gap 4: No Automated Tests
**Problem**: Can't verify setup was successful
**Risk**: MEDIUM - May not discover issues until runtime
**Solution**: Add verification script that checks all data exists

---

## Summary

### What You Must Do on New Machine:

1. ✓ Run `setup_database.py` (creates DB + tables)
2. ⚠️ Run `initialize_all_data.py` (NEW - populates critical data)
   - ISO Processes
   - Competencies
   - Roles
   - Role-Process Matrix for Org 1 (TEMPLATE!)
   - Process-Competency Matrix (GLOBAL!)

### What Can Go Wrong:

- ❌ Forgetting step 2 → SYSTEM BROKEN
- ❌ Running populate scripts in wrong order → Errors
- ❌ Hard-coded paths don't exist → Script fails
- ❌ No verification → Don't know if setup worked

### What We Fixed Today (2025-10-21):

- ✓ Organization creation now CALCULATES role-competency (doesn't copy)
- ✓ Admin matrix editing auto-recalculates derived matrices
- ❌ But setup process is still MANUAL and RISKY!

---

## Next Steps (Recommended)

1. **Create `initialize_all_data.py`** master script (HIGH PRIORITY)
2. **Embed reference data** in project (remove hard-coded paths)
3. **Add setup verification** script
4. **Update README.md** with setup instructions
5. **Add to onboarding** checklist for new developers

---

**Created:** 2025-10-21
**Status:** DOCUMENTATION ONLY - Master script not yet implemented
**Risk Level:** HIGH - Easy to forget critical setup steps
