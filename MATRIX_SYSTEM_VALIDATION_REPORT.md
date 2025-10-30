# Matrix System Validation Report

**Date**: 2025-10-29
**Validated By**: Claude Code Analysis
**Status**: ✅ VERIFIED

## Executive Summary

Validated the current matrix initialization and process-competency matrix implementation:

1. ✅ **Process Count**: 30 processes in database (but only 28 used in reference)
2. ✅ **Process-Competency Matrix**: CORRECTLY implemented as central/shared matrix
3. ✅ **Registration Function**: Handles role-process matrix only (not process-competency)

## Detailed Findings

### 1. Process Count Discrepancy

**Database Reality:**
```sql
SELECT COUNT(*) FROM iso_processes;
-- Result: 30 processes
```

**Processes 26-30:**
- Process 26: "Operation"
- Process 27: "Maintenance"
- Process 28: "Disposal"
- Process 29: "Maintenance process" ⚠️ **DUPLICATE**
- Process 30: "Disposal process" ⚠️ **DUPLICATE**

**Reference Matrix (Organization 1):**
- Only contains data for processes 1-28
- 14 roles × 28 processes = **392 entries**
- No data for processes 29-30 (duplicates)

**Recommendation:**
- ⚠️ **Decision needed**: Should we use 28 or 30 processes?
- If 30: Need to populate missing data for processes 29-30 in org 1
- If 28: Should clean up duplicate processes 29-30 from database

### 2. `_initialize_organization_matrices()` Function

**Location**: `src/backend/app/routes.py:498-540`

**Called From**:
- `register_admin()` line 628
- Creates matrices when new organization registers

**What It Does:**

#### Step 1: Copy Role-Process Matrix
```python
# Line 517-520
db.session.execute(
    text('CALL insert_new_org_default_role_process_matrix(:org_id);'),
    {'org_id': new_org_id}
)
# Copies 392 entries (14 roles × 28 processes) from org 1
```

#### Step 2: Calculate Role-Competency Matrix
```python
# Line 526-529
db.session.execute(
    text('CALL update_role_competency_matrix(:org_id);'),
    {'org_id': new_org_id}
)
# CALCULATES from: role_process × process_competency
# Does NOT copy from org 1 (this was a bug that was fixed)
```

#### What It DOES NOT Do:
- ❌ Does NOT touch process-competency matrix
- ❌ Does NOT create org-specific process-competency entries
- ✅ Process-competency remains central/shared

### 3. Process-Competency Matrix (CENTRAL/SHARED) ✅

#### Database Structure

**Table**: `process_competency_matrix`

```sql
\d process_competency_matrix

Columns:
  - id (integer, primary key)
  - iso_process_id (integer, foreign key → iso_processes.id)
  - competency_id (integer, foreign key → competency.id)
  - process_competency_value (integer)

IMPORTANT: NO organization_id column! ✅
```

**Data:**
- 480 entries = 30 processes × 16 competencies
- Shared by ALL organizations
- Single source of truth

#### API Endpoints

**GET** `/process_competency_matrix/<competency_id>`
```python
# Line 2322-2341
# NO organization_id parameter ✅
# Returns data for ALL organizations

ProcessCompetencyMatrix.query.filter_by(
    competency_id=competency_id
).all()
```

**PUT** `/process_competency_matrix/bulk`
```python
# Line 2344-2399
# Updates central matrix
# Then recalculates role-competency for ALL organizations ✅

# Lines 2382-2388 (THE KEY PART):
organizations = Organization.query.all()
for org in organizations:
    db.session.execute(
        text('CALL update_role_competency_matrix(:org_id);'),
        {'org_id': org.id}
    )
```

#### Admin UI

**File**: `src/frontend/src/views/admin/matrix/ProcessCompetencyMatrixCrud.vue`

**Route**: `/admin/matrix/process-competency`

**Behavior:**
- Fetches matrix WITHOUT org_id parameter ✅
- Edits affect ALL organizations ✅
- Shows warning: "Any changes affect all organizations" ✅

### 4. Validation Results

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Process-competency is central/shared | ✅ PASS | No `organization_id` column in table |
| Edits affect all organizations | ✅ PASS | Bulk update recalculates for all orgs (line 2382) |
| Not organization-specific | ✅ PASS | API endpoints have no org_id parameter |
| Registration doesn't touch it | ✅ PASS | `_initialize_organization_matrices()` only handles role-process |
| Stored as single source | ✅ PASS | 480 entries shared by all, not duplicated per org |

### 5. Matrix Calculation Flow

```
Process-Competency Matrix (CENTRAL)
         ↓
         × (matrix multiplication)
         ↓
Role-Process Matrix (ORG-SPECIFIC)
         ↓
         = (calculated result)
         ↓
Role-Competency Matrix (ORG-SPECIFIC)
```

**When Recalculation Happens:**
1. When admin edits role-process matrix → recalc for THAT org
2. When admin edits process-competency matrix → recalc for ALL orgs ✅
3. At registration → initial calculation for new org

## Corrected Implementation Plan

### What Needs to Change

#### Backend Changes

1. **Stop Pre-Population at Registration**
   ```python
   # routes.py line 628 - COMMENT OUT
   # _initialize_organization_matrices(organization.id)
   ```

2. **Create New Initialization Endpoint**
   ```python
   @main_bp.route('/api/phase1/roles/initialize-matrix', methods=['POST'])
   def initialize_role_process_matrix():
       """
       Initialize role-process matrix when user defines roles in Phase 1 Task 2

       For STANDARD roles: Copy from org 1 reference for that role_cluster_id
       For CUSTOM roles: Initialize with zeros
       """
   ```

3. **Use 28 or 30 Processes?**
   - ⚠️ **USER DECISION NEEDED**
   - Current reference (org 1): Uses 28 processes
   - Database has 30 (with 2 duplicates)
   - Recommendation: **Use 28** (processes 1-28) and clean up duplicates

#### Frontend Changes

1. **Fix RoleProcessMatrix.vue**
   - Transpose: Processes as rows, Roles as columns
   - Use 28 or 30 processes (based on user decision)

2. **Add RACI Validation**
   - Per process (row): exactly one "2", at most one "3"

3. **Call Matrix Initialization**
   - After roles saved in StandardRoleSelection
   - Before showing matrix editor

### What STAYS THE SAME

✅ **Process-Competency Matrix**
   - Already correct implementation
   - Central/shared across all orgs
   - No changes needed

✅ **Admin Matrix Pages**
   - `/admin/matrix/role-process` - org-specific ✅
   - `/admin/matrix/process-competency` - central/shared ✅
   - Both working correctly

✅ **Stored Procedures**
   - `insert_new_org_default_role_process_matrix` - works correctly
   - `update_role_competency_matrix` - works correctly
   - No changes needed

## Open Questions for User

### Question 1: Process Count

**Issue**: Database has 30 processes, but org 1 reference only has 28

**Processes 29-30 are duplicates:**
- 27: "Maintenance" vs 29: "Maintenance process"
- 28: "Disposal" vs 30: "Disposal process"

**Options:**
- **Option A**: Use 28 processes (current reference) - RECOMMENDED
  - Clean up duplicate processes 29-30
  - Less work, maintains consistency

- **Option B**: Use 30 processes
  - Populate missing data for processes 29-30 in org 1
  - Update reference matrix to 14 × 30 = 420 entries

**User Decision**: ???

### Question 2: Matrix Initialization Timing

When should the role-process matrix be created?

**Current Plan**: When roles are SAVED in Step 2a (StandardRoleSelection)

**Alternative**: When user ENTERS Step 2b (RoleProcessMatrix component)

**Recommendation**: Create when roles saved ✅

## Summary

### What's Working ✅

1. **Process-Competency Matrix** is correctly implemented as central/shared
2. **Matrix Calculation** correctly propagates changes to all orgs
3. **Admin UI** correctly shows shared vs org-specific matrices
4. **Registration** correctly initializes role-process and calculates role-competency

### What Needs Fixing ⚠️

1. **Process count discrepancy** (28 vs 30) - user decision needed
2. **Pre-population at registration** - should be removed for new flow
3. **Matrix initialization** - should happen when roles are defined
4. **RoleProcessMatrix.vue** - needs transpose and RACI validation

### Next Steps

1. **Get user decision** on 28 vs 30 processes
2. **Proceed with implementation** based on validated plan
3. **No changes needed** to process-competency matrix system

## Files Analyzed

### Backend
- `src/backend/app/routes.py` (lines 498-540, 2322-2400)
- `src/backend/setup/populate/populate_roles_and_matrices.py`
- `src/backend/models.py` (ProcessCompetencyMatrix model)

### Frontend
- `src/frontend/src/views/admin/matrix/ProcessCompetencyMatrixCrud.vue`
- `src/frontend/src/views/admin/matrix/RoleProcessMatrixCrud.vue`
- `src/frontend/src/components/phase1/task2/RoleProcessMatrix.vue`

### Database
- Tables: `iso_processes`, `process_competency_matrix`, `role_process_matrix`
- Stored Procedures: `insert_new_org_default_role_process_matrix`, `update_role_competency_matrix`
