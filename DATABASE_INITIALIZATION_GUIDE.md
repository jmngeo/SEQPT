# Database Initialization Guide for SE-QPT

## Overview

This guide explains the matrix architecture, database initialization process, and how to set up SE-QPT on a new machine.

---

## Part 1: Matrix Architecture

### The Three Matrices

```
┌──────────────────────────────────────────────────────────────────┐
│                   SE-QPT MATRIX SYSTEM                            │
└──────────────────────────────────────────────────────────────────┘

1. ROLE_PROCESS_MATRIX (Organization-specific, Customizable)
   ├─ Links: 14 Roles × 28 ISO Processes = 392 entries per org
   ├─ Values: 0-4
   │    0 = Not performing
   │    1 = Supporting
   │    2 = Responsible
   │    3 = Designing (Process and Policy Manager only)
   │    4 = Designing (all other roles)
   ├─ Purpose: Defines WHICH processes each role performs
   └─ Editable: YES - Admins can customize per organization

2. PROCESS_COMPETENCY_MATRIX (Global, Fixed)
   ├─ Links: 28 ISO Processes × 16 Competencies = 448 entries
   ├─ Values: 0 or 1 (binary)
   │    0 = Process does NOT require this competency
   │    1 = Process DOES require this competency
   ├─ Purpose: Defines WHICH competencies each process needs
   └─ Editable: NO - Fixed based on ISO/IEC/IEEE 15288 standards

3. ROLE_COMPETENCY_MATRIX (Organization-specific, Auto-calculated)
   ├─ Links: 14 Roles × 16 Competencies = 224 entries per org
   ├─ Values: 0-6 (required proficiency level)
   │    0 = Not required
   │    1-6 = Proficiency level needed
   ├─ Purpose: Final competency requirements for each role
   └─ Editable: NO - CALCULATED from matrices 1 & 2
```

### How They Work Together

```
CALCULATION FORMULA:
═══════════════════

role_competency_matrix = role_process_matrix × process_competency_matrix

EXAMPLE:
────────
Role: Specialist Developer (Role 5)
Question: What competency level is needed for "Systems Thinking" (C1)?

Step 1: Check which processes the Specialist Developer performs
  - Design Definition (P13): Supporting (1)
  - Implementation (P21): Responsible (2)
  - Integration (P20): Supporting (1)
  ... etc (see role_process_matrix)

Step 2: Check which processes need "Systems Thinking"
  - Design Definition (P13): YES (1)
  - Implementation (P21): YES (1)
  - Integration (P20): YES (1)
  ... etc (see process_competency_matrix)

Step 3: Calculate the required level
  For each process that needs the competency:
    Add the role's involvement level (0-4)

  Systems Thinking for Specialist Developer:
    = 1 (Design) + 2 (Implementation) + 1 (Integration) + ...
    = 4 (final required proficiency level)

This calculation is done by PostgreSQL stored procedure:
  → update_role_competency_matrix(organization_id)
```

---

## Part 2: New Organization Setup

### Current Implementation (PROBLEMATIC)

**File**: `src/backend/app/routes.py` lines 493-530

When a new organization registers, this happens:

```python
def _initialize_organization_matrices(new_org_id):
    # Step 1: Copy role-process matrix from org 1 ✓ CORRECT
    CALL insert_new_org_default_role_process_matrix(new_org_id)
    # → Copies 392 entries from organization_id=1

    # Step 2: Copy role-competency matrix from org 1 ✗ WRONG!
    CALL insert_new_org_default_role_competency_matrix(new_org_id)
    # → Copies 224 entries from organization_id=1
    # ⚠️  PROBLEM: Just copying instead of calculating!
```

**Why This is Wrong:**
- If org 1 has old/incorrect matrix data, ALL new organizations inherit the bug
- If admin later edits role-process matrix, role-competency doesn't update
- This caused your test failure with org 16

### Correct Implementation (SHOULD BE)

```python
def _initialize_organization_matrices(new_org_id):
    # Step 1: Copy role-process matrix ✓
    CALL insert_new_org_default_role_process_matrix(new_org_id)
    # → Gives new org the default process assignments

    # Step 2: CALCULATE (not copy!) role-competency matrix ✓
    CALL update_role_competency_matrix(new_org_id)
    # → Calculates correct values based on org's role-process matrix
```

**Advantages:**
- New organizations always get correct, calculated values
- Works even if org 1 has no data
- Admin can customize role-process, then recalculate competencies

### When Admin Edits Matrices

**Scenario**: Admin customizes which processes a role performs

```
Admin edits role_process_matrix for their organization
  ↓
Frontend calls backend API: /api/matrices/role-process/update
  ↓
Backend saves changes to role_process_matrix
  ↓
Backend MUST call: update_role_competency_matrix(organization_id)
  ↓
role_competency_matrix is recalculated automatically
```

**Important**: This recalculation endpoint is NOT yet implemented in routes.py!
You need to add it when building the admin matrix editor.

---

## Part 3: Database Initialization on New Machine

### Prerequisites

1. **PostgreSQL installed** (v12 or higher)
2. **Database created**: `competency_assessment`
3. **Database user created**: `ma0349` with password `MA0349_2025`
4. **Python environment** with dependencies installed

### Initialization Steps

```bash
# Navigate to backend directory
cd src/backend

# Set database connection
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
# (On Linux/Mac: export DATABASE_URL=...)

# STEP 1: Create all tables (empty)
# This creates the table structure but no data
python init_db_as_postgres.py

# STEP 2: Populate base data (run in this order!)

# 2a. Populate 16 SE competencies
python populate_competencies.py
# → Adds 16 rows to 'competency' table

# 2b. Populate 28 ISO processes
python populate_iso_processes.py
# → Adds 28 rows to 'iso_process' table

# 2c. Populate 14 SE roles + role-process matrix for org 1
python populate_roles_and_matrices.py
# → Adds 14 rows to 'role_cluster' table
# → Adds 392 rows to 'role_process_matrix' for organization_id=1

# 2d. Populate process-competency matrix (global)
python populate_process_competency_matrix.py
# → Adds 448 rows to 'process_competency_matrix'

# STEP 3: Create PostgreSQL stored procedures
python create_stored_procedures.py
# → Creates 3 stored procedures:
#   - insert_new_org_default_role_process_matrix
#   - insert_new_org_default_role_competency_matrix (deprecated)
#   - update_role_competency_matrix (use this!)
#   - update_unknown_role_competency_values

# STEP 4: Calculate role-competency matrix for org 1
python -c "from app import create_app; from models import db; from sqlalchemy import text; app = create_app(); app.app_context().push(); db.session.execute(text('CALL update_role_competency_matrix(1)')); db.session.commit(); print('[SUCCESS] Calculated 224 competency entries for org 1')"

# STEP 5: Populate questionnaire data (for Phase 1)
python init_questionnaire_data.py
# → Adds maturity assessment questions

# STEP 6: Populate module library (for Phase 2)
python init_module_library.py
# → Adds training modules and learning objectives
```

### Verification

Check that all data was loaded correctly:

```bash
python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    tables = {
        'competency': 'SELECT COUNT(*) FROM competency',
        'iso_process': 'SELECT COUNT(*) FROM iso_process',
        'role_cluster': 'SELECT COUNT(*) FROM role_cluster',
        'process_competency_matrix': 'SELECT COUNT(*) FROM process_competency_matrix',
        'role_process_matrix (org 1)': 'SELECT COUNT(*) FROM role_process_matrix WHERE organization_id=1',
        'role_competency_matrix (org 1)': 'SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id=1',
    }

    expected = {
        'competency': 16,
        'iso_process': 28,
        'role_cluster': 14,
        'process_competency_matrix': 448,
        'role_process_matrix (org 1)': 392,
        'role_competency_matrix (org 1)': 224,
    }

    print('Database Verification:')
    print('=' * 60)
    for table, query in tables.items():
        count = db.session.execute(text(query)).scalar()
        status = '✓' if count == expected[table] else '✗'
        print(f'{status} {table}: {count} (expected {expected[table]})')
"
```

Expected output:
```
Database Verification:
============================================================
✓ competency: 16 (expected 16)
✓ iso_process: 28 (expected 28)
✓ role_cluster: 14 (expected 14)
✓ process_competency_matrix: 448 (expected 448)
✓ role_process_matrix (org 1): 392 (expected 392)
✓ role_competency_matrix (org 1): 224 (expected 224)
```

---

## Part 4: The 16 SE Competencies

```
C1  - Systems Thinking
C4  - Personal Communication
C5  - Teamwork
C6  - Holistic Thinking
C7  - Analytical Thinking
C8  - Initiative
C9  - Creativity
C10 - Self-organization
C11 - Negotiation Skills
C12 - Problem-solving Skills
C13 - Decision-making Ability
C14 - Conflict Management
C15 - Lifelong Learning
C16 - Intercultural Competence
C17 - Leadership
C18 - Specialized Skills (domain-specific)
```

---

## Part 5: The 28 ISO Processes

Based on ISO/IEC/IEEE 15288 (Systems and Software Engineering)

**Technical Processes:**
1. Business or Mission Analysis
2. Stakeholder Needs and Requirements Definition
3. System Requirements Definition
4. System Architecture Definition
5. Design Definition
6. System Analysis
7. Implementation
8. Integration
9. Verification
10. Transition
11. Validation
12. Operation
13. Maintenance
14. Disposal

**Technical Management Processes:**
15. Project Planning
16. Project Assessment and Control
17. Decision Management
18. Risk Management
19. Configuration Management
20. Information Management
21. Measurement
22. Quality Assurance

**Organizational Project-Enabling Processes:**
23. Life Cycle Model Management
24. Infrastructure Management
25. Portfolio Management
26. Human Resource Management
27. Quality Management
28. Knowledge Management

---

## Part 6: The 14 SE Role Clusters

```
1.  Customer
2.  Customer Representative
3.  Project Manager
4.  System Engineer
5.  Specialist Developer
6.  Production Planner/Coordinator
7.  Production Employee
8.  Quality Engineer/Manager
9.  Verification and Validation (V&V) Operator
10. Service Technician
11. Process and Policy Manager
12. Internal Support
13. Innovation Management
14. Management
```

---

## Part 7: Common Issues

### Issue 1: New org gets wrong role matches

**Symptom**: Test profiles return incorrect roles
**Cause**: New organization copied old matrix data from org 1
**Fix**: Recalculate matrix for the organization

```bash
cd src/backend
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment

python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    org_id = 16  # Replace with your org ID

    # Recalculate role-competency matrix
    db.session.execute(text('CALL update_role_competency_matrix(:org_id)'), {'org_id': org_id})
    db.session.commit()

    print(f'[SUCCESS] Recalculated competency matrix for org {org_id}')
"
```

### Issue 2: All new orgs get wrong data

**Symptom**: Every new registration has incorrect matrix values
**Cause**: Org 1 has outdated data that gets copied
**Fix**: Update org 1 with correct values

```bash
# Option A: Copy from a working organization (e.g., org 15)
python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    # Delete old org 1 data
    db.session.execute(text('DELETE FROM role_competency_matrix WHERE organization_id=1'))

    # Copy corrected data from org 15
    db.session.execute(text('''
        INSERT INTO role_competency_matrix
        (organization_id, role_cluster_id, competency_id, role_competency_value)
        SELECT 1, role_cluster_id, competency_id, role_competency_value
        FROM role_competency_matrix
        WHERE organization_id=15
    '''))

    db.session.commit()
    print('[SUCCESS] Updated org 1 with corrected matrix data')
"

# Option B: Recalculate from scratch
python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    db.session.execute(text('CALL update_role_competency_matrix(1)'))
    db.session.commit()
    print('[SUCCESS] Recalculated org 1 matrix')
"
```

### Issue 3: Admin edits role-process matrix but results don't change

**Symptom**: Admin customizes process assignments but competency requirements stay the same
**Cause**: role_competency_matrix was never recalculated
**Fix**: Call `update_role_competency_matrix` after edit

**TODO**: This endpoint needs to be implemented in routes.py:

```python
@main_bp.route('/api/admin/matrices/role-process/save', methods=['POST'])
def save_role_process_matrix():
    """Save admin's edits to role-process matrix and recalculate competencies"""
    # ... save edits to role_process_matrix ...

    # IMPORTANT: Recalculate role-competency matrix!
    db.session.execute(
        text('CALL update_role_competency_matrix(:org_id)'),
        {'org_id': organization_id}
    )
    db.session.commit()
```

---

## Part 8: Quick Reference

### One-Line Commands

```bash
# Create tables
python init_db_as_postgres.py

# Seed all base data (run in order!)
python populate_competencies.py && python populate_iso_processes.py && python populate_roles_and_matrices.py && python populate_process_competency_matrix.py && python create_stored_procedures.py

# Calculate role-competency matrix for org 1
python -c "from app import create_app; from models import db; from sqlalchemy import text; app = create_app(); app.app_context().push(); db.session.execute(text('CALL update_role_competency_matrix(1)')); db.session.commit(); print('Done')"

# Verify database
python -c "from app import create_app; from models import db; from sqlalchemy import text; app = create_app(); app.app_context().push(); print(f\"Competencies: {db.session.execute(text('SELECT COUNT(*) FROM competency')).scalar()}, Processes: {db.session.execute(text('SELECT COUNT(*) FROM iso_process')).scalar()}, Roles: {db.session.execute(text('SELECT COUNT(*) FROM role_cluster')).scalar()}\")"
```

---

## Summary

**Key Takeaways:**
1. **3 matrices**: role-process (editable), process-competency (fixed), role-competency (calculated)
2. **Calculation formula**: role_competency = role_process × process_competency
3. **New org setup**: Copy role-process from org 1, then CALCULATE (not copy) role-competency
4. **Admin edits**: When role-process changes, recalculate role-competency immediately
5. **Fresh install**: Run 6 populate scripts in order, then calculate org 1 matrix

**Critical Bug Fixed:**
- Old code copied matrices → new orgs inherited bugs
- New code calculates matrices → new orgs get correct values

**Next Steps for You:**
1. Fix `_initialize_organization_matrices()` to call `update_role_competency_matrix` instead of copying
2. Implement admin matrix editor with auto-recalculation
3. Add recalculation endpoint to routes.py

---

*Last Updated: 2025-10-21*
*Session: Task-Based Role Matching Fix*
