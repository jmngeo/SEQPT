# Smart-Merge Feature for Role-Process Matrix

**Date**: 2025-10-30
**Feature**: Smart merge for role changes in Phase 1 Task 2
**Status**: ✅ Implemented and Ready for Testing

---

## Problem Statement

### Previous Behavior (Before Smart-Merge)
When users made ANY changes to their organization's roles during retake assessment:
- ❌ **All role-process matrix data was deleted entirely**
- ❌ Users had to **re-configure the entire matrix from scratch**
- ❌ Even adding ONE new role would **wipe out all previous work**
- ❌ Very frustrating UX - hours of matrix configuration lost

**Example Scenario**:
1. User configures matrix for 10 roles (30 processes × 10 roles = 300 values)
2. User realizes they forgot to add "Junior Developer" role
3. User goes back to role selection and adds 1 role
4. **BOOM**: All 300 previous matrix values are gone
5. User must re-configure entire matrix again

---

## Solution: Smart-Merge Algorithm

### New Behavior (With Smart-Merge)
The system now **intelligently preserves unchanged data** while handling role changes:

✅ **Unchanged roles**: Matrix data **preserved** (no re-work needed)
✅ **New roles**: Matrix initialized with template values
✅ **Deleted roles**: Matrix data removed (CASCADE)
✅ **Pathway changes**: Full reset (when threshold crossed)

---

## Technical Implementation

### 1. Pathway Detection (Task 1 Impact)

The system tracks two pathways based on maturity assessment:

```javascript
MATURITY_THRESHOLD = 3  // "Defined and Established"

Pathways:
- STANDARD: seProcesses >= 3 → Has role-process matrix
- TASK_BASED: seProcesses < 3 → No matrix (undefined roles)
```

**Pathway Change Detection**:
- If old_seProcesses >= 3 AND new_seProcesses < 3:
  → **FULL RESET** (STANDARD → TASK_BASED, matrix no longer needed)

- If old_seProcesses < 3 AND new_seProcesses >= 3:
  → **FULL RESET** (TASK_BASED → STANDARD, matrix needed now)

**Why Full Reset for Pathway Changes?**
- Matrix structure fundamentally changes
- Different process requirements
- User needs to reconfigure for new context

---

### 2. Role Change Detection (Task 2 Changes)

The system compares role "signatures" to detect changes:

```python
Role Signature = f"{orgRoleName}|{standardRoleId}|{identificationMethod}"

Examples:
- "Senior Developer|4|STANDARD"
- "Test Engineer|12|STANDARD"
- "Data Analyst|null|CUSTOM"
```

**Change Detection**:
```python
unchanged_roles = submitted_signatures & existing_signatures
added_roles = submitted_signatures - existing_signatures
removed_roles = existing_signatures - submitted_signatures
```

---

### 3. Smart-Merge Decision Tree

```
START
  |
  +-- Is this first time setup?
  |     YES → Full initialization (no merge needed)
  |     NO → Continue
  |
  +-- Did roles change?
  |     NO → Return existing roles (preserve matrix) ✅
  |     YES → Continue
  |
  +-- Did pathway change (threshold crossed)?
        YES → Full reset (delete all, rebuild) ⚠️
        NO → **SMART MERGE** 🎯
           |
           +-- Keep unchanged roles (preserve matrix)
           +-- Add new roles (template values)
           +-- Remove deleted roles (CASCADE delete)
```

---

## Implementation Details

### Backend Changes

#### 1. `save_roles()` Endpoint (routes.py:1536-1810)

**NEW Parameters**:
- `maturity_id`: Required for pathway detection

**NEW Logic**:
```python
# STEP 1: Detect pathway changes
if old_pathway != new_pathway:
    pathway_changed = True

# STEP 2: Compare role signatures
unchanged_roles = submitted & existing
added_roles = submitted - existing
removed_roles = existing - submitted

# STEP 3: Handle changes
if pathway_changed:
    # Full reset
    OrganizationRoles.query.filter_by(organization_id=org_id).delete()
    smart_merge_enabled = False
else:
    # Smart merge - only delete removed roles
    if removed_roles:
        OrganizationRoles.query.filter(...).delete()
    smart_merge_enabled = True

# STEP 4: Insert/update roles
for role in roles:
    sig = build_signature(role)
    if smart_merge_enabled and sig in unchanged_roles:
        # Reuse existing role (preserve matrix)
        existing_obj = OrganizationRoles.query.get(existing_id)
        saved_roles.append(existing_obj.to_dict())
    else:
        # Create new role
        new_role = OrganizationRoles(...)
        saved_roles.append(new_role.to_dict())
        roles_to_add.append(new_role)
```

**NEW Response Fields**:
```python
{
    'roles_changed': True/False,
    'pathway_changed': True/False,
    'smart_merge_enabled': True/False,
    'roles_to_add': [...],  # Only new roles needing matrix init
    'change_summary': {
        'unchanged': count,
        'added': count,
        'removed': count
    }
}
```

#### 2. `initialize_role_process_matrix()` Endpoint (routes.py:1813-1979)

**NEW Parameters**:
- `smart_merge`: Boolean flag indicating merge mode

**NEW Logic**:
```python
# STEP 1: Conditional deletion
if not smart_merge:
    # Full reset - delete all
    RoleProcessMatrix.query.filter_by(organization_id=org_id).delete()
else:
    # Smart merge - preserve existing
    # (removed roles already deleted by CASCADE)
    pass

# STEP 2: Check before creating entries
for role in roles:
    if smart_merge:
        # Skip roles that already have matrix data
        existing_count = RoleProcessMatrix.query.filter_by(
            organization_id=org_id,
            role_cluster_id=role_id
        ).count()

        if existing_count > 0:
            continue  # Preserve existing matrix

    # Create matrix entries for new roles only
    ...
```

**NEW Response Fields**:
```python
{
    'roles_skipped': count,  # Roles with preserved matrix
    'smart_merge': True/False
}
```

---

### Frontend Changes

#### 1. `StandardRoleSelection.vue` (lines 442-499)

**Changes**:
```javascript
// Pass maturity_id for pathway detection
const response = await rolesApi.save(
  authStore.organizationId,
  props.maturityId,  // NEW: Added maturity_id
  rolesToSave,
  'STANDARD'
)

// Determine which roles need matrix initialization
const rolesToInitialize = response.smart_merge_enabled
  ? response.roles_to_add  // Only new roles
  : response.roles         // All roles (full reset)

// Pass smart_merge flag
const matrixResponse = await rolesApi.initializeMatrix(
  authStore.organizationId,
  rolesToInitialize,
  response.smart_merge_enabled  // NEW: Smart merge flag
)

// Show appropriate message
if (response.pathway_changed) {
  ElMessage.warning({
    message: `Pathway changed! Role-process matrix has been reset...`,
    duration: 6000
  })
} else if (response.smart_merge_enabled) {
  const { unchanged, added, removed } = response.change_summary
  ElMessage.success({
    message: `Smart merge complete: ${unchanged} preserved, ${added} added, ${removed} removed...`,
    duration: 6000
  })
}
```

#### 2. `phase1.js` API (lines 220-232)

**Updated Function Signature**:
```javascript
initializeMatrix: async (organizationId, roles, smartMerge = false) => {
  const response = await axiosInstance.post('/api/phase1/roles/initialize-matrix', {
    organization_id: organizationId,
    roles,
    smart_merge: smartMerge  // NEW: Smart merge flag
  });
  return response.data;
}
```

---

## User Experience

### Scenario 1: Add One New Role (Smart Merge)

**User Actions**:
1. Organization has 5 roles with fully configured matrix (150 values)
2. User clicks "Retake Assessment" → goes to role selection
3. User adds "Junior Developer" (6th role)
4. User clicks "Continue to Role-Process Matrix"

**System Behavior**:
```
[BACKEND LOG]
[ROLE SAVE] Roles changed but pathway stable - SMART MERGE: keep 5, add 1, remove 0
[ROLE SAVE] Keeping unchanged role 'Senior Developer' (ID: 23) - matrix preserved
[ROLE SAVE] Keeping unchanged role 'Test Engineer' (ID: 24) - matrix preserved
...
[ROLE SAVE] Added role 'Junior Developer' (ID: 28)

[MATRIX INIT] Smart merge - preserving matrix for unchanged roles
[MATRIX INIT] Skipping role 'Senior Developer' (ID: 23) - matrix already exists (30 entries)
...
[MATRIX INIT] Copied 30 values for STANDARD role 'Junior Developer' (cluster 4)
```

**User Sees**:
✅ Success message: "Smart merge complete: 5 roles preserved, 1 added, 0 removed. Only new roles need matrix configuration!"

**Result**:
- 5 existing roles: All 150 values **preserved** ✅
- 1 new role: 30 values initialized from template
- **User only needs to review/adjust the 30 new values!**

---

### Scenario 2: Remove One Role (Smart Merge)

**User Actions**:
1. Organization has 8 roles with configured matrix
2. User removes "Data Analyst" role
3. User continues to matrix

**System Behavior**:
```
[ROLE SAVE] Roles changed but pathway stable - SMART MERGE: keep 7, add 0, remove 1
[ROLE SAVE] Deleted 1 removed roles (matrix CASCADE)
```

**User Sees**:
✅ "Smart merge complete: 7 roles preserved, 0 added, 1 removed"

**Result**:
- 7 remaining roles: Matrix data **preserved** ✅
- 1 removed role: Matrix data deleted automatically
- **No manual re-work needed!**

---

### Scenario 3: Pathway Change - Task 1 Retake (Full Reset)

**User Actions**:
1. User had seProcesses = 3 (STANDARD pathway, has matrix)
2. User retakes Task 1, changes answer to seProcesses = 2
3. User goes to Task 2

**System Behavior**:
```
[ROLE SAVE] Pathway changed (STANDARD -> TASK_BASED) - FULL MATRIX RESET
[ROLE SAVE] Deleted old roles and matrix (pathway change)
```

**User Sees**:
⚠️ Warning: "Pathway changed! Role-process matrix has been reset. Please re-configure all roles."

**Result**:
- Matrix structure changed (now TASK_BASED, no matrix needed)
- Full reset appropriate for context change

---

## Testing Checklist

### Test Case 1: Smart Merge - Add Roles
- [ ] Start with org that has 3 roles with configured matrix
- [ ] Retake Task 2, add 2 new roles
- [ ] Verify: Old 3 roles preserve matrix data
- [ ] Verify: New 2 roles get template values
- [ ] Check logs for "SMART MERGE: keep 3, add 2, remove 0"

### Test Case 2: Smart Merge - Remove Roles
- [ ] Start with org that has 5 roles
- [ ] Retake Task 2, remove 1 role
- [ ] Verify: Remaining 4 roles preserve matrix data
- [ ] Check database: Deleted role's matrix entries gone

### Test Case 3: Smart Merge - Mix (Add + Remove)
- [ ] Start with 4 roles
- [ ] Remove 1 role, add 2 roles
- [ ] Verify: 3 unchanged roles preserve data
- [ ] Verify: 2 new roles get template values
- [ ] Check logs for "keep 3, add 2, remove 1"

### Test Case 4: Pathway Change (Full Reset)
- [ ] Start with seProcesses = 3 (STANDARD)
- [ ] Retake Task 1, change to seProcesses = 2
- [ ] Verify: Warning message about full reset
- [ ] Verify: All matrix data deleted
- [ ] Check logs for "Pathway changed (STANDARD -> TASK_BASED)"

### Test Case 5: No Changes (Preserve All)
- [ ] Start with configured roles and matrix
- [ ] Retake Task 2, make NO changes
- [ ] Verify: Message "Using existing roles (no changes detected)"
- [ ] Verify: Matrix completely unchanged

### Test Case 6: Custom Roles
- [ ] Add mix of standard and custom roles
- [ ] Retake, modify custom roles
- [ ] Verify: Smart merge works for custom roles too

---

## Database Impact

### Tables Affected

1. **`organization_roles`**:
   - Roles preserved during smart merge
   - Only changed roles inserted/deleted

2. **`role_process_matrix`**:
   - Unchanged roles: Rows preserved ✅
   - New roles: Rows inserted with template values
   - Deleted roles: Rows deleted (CASCADE)

3. **`role_competency_matrix`**:
   - Automatically recalculated via stored procedure
   - `CALL update_role_competency_matrix(org_id)`

---

## Performance Benefits

### Before Smart-Merge
```
User adds 1 role to 10 existing roles:
- DELETE: 10 roles × 30 processes = 300 rows
- INSERT: 11 roles × 30 processes = 330 rows
Total operations: 630 DB operations
```

### After Smart-Merge
```
User adds 1 role to 10 existing roles:
- DELETE: 0 rows (nothing deleted)
- INSERT: 1 role × 30 processes = 30 rows
Total operations: 30 DB operations

Performance improvement: 95% reduction! 🚀
```

---

## Logging

### Backend Logs to Watch

```python
# Pathway detection
[ROLE SAVE] Pathway changed for org 2: STANDARD -> TASK_BASED (seProcesses: 3 -> 2)

# Role change analysis
[ROLE SAVE] Change analysis for org 2: unchanged=5, added=2, removed=1, pathway_changed=False

# Smart merge execution
[ROLE SAVE] Roles changed but pathway stable - SMART MERGE: keep 5, add 2, remove 1
[ROLE SAVE] Keeping unchanged role 'Senior Developer' (ID: 23) - matrix preserved
[ROLE SAVE] Added role 'Junior Developer' (ID: 28)
[ROLE SAVE] Deleted 1 removed roles (matrix CASCADE)

# Matrix initialization
[MATRIX INIT] Smart merge - preserving matrix for unchanged roles
[MATRIX INIT] Skipping role 'Senior Developer' (ID: 23) - matrix already exists (30 entries)
[MATRIX INIT] Copied 30 values for STANDARD role 'Junior Developer' (cluster 4)
```

---

## Edge Cases Handled

### 1. First-Time Setup
- No existing roles
- Full initialization (smart merge not needed)
- All roles get template values

### 2. Role Renamed
- Signature changes (orgRoleName different)
- Treated as: Remove old + Add new
- Matrix values reset for that role

### 3. Cluster Changed
- E.g., "Developer" from cluster 4 → cluster 5
- Signature changes (standardRoleId different)
- Treated as new role, gets new template values

### 4. Multiple Retakes
- Smart merge works across multiple retake cycles
- Each retake preserves unchanged roles from previous state

### 5. Concurrent Users
- Each organization's matrix independent
- No cross-contamination risk

---

## Files Modified

### Backend
1. `src/backend/app/routes.py` (lines 1536-1810, 1813-1979)
   - `save_roles()`: Added pathway detection and smart merge logic
   - `initialize_role_process_matrix()`: Added smart merge mode

### Frontend
1. `src/frontend/src/components/phase1/task2/StandardRoleSelection.vue` (lines 442-499)
   - Updated role save logic
   - Added smart merge handling
   - Improved user messages

2. `src/frontend/src/api/phase1.js` (lines 220-232)
   - Updated `initializeMatrix()` to accept `smartMerge` parameter

---

## Next Steps

1. **Test thoroughly** using the test cases above
2. **Monitor logs** during testing to verify correct behavior
3. **User feedback** - observe if users notice the improvement
4. **Documentation** - Update user guide if needed

---

## Success Metrics

The smart-merge feature is successful if:

✅ **Users can add/remove roles without losing matrix data**
✅ **Only affected roles require matrix reconfiguration**
✅ **Pathway changes still trigger appropriate full reset**
✅ **No data corruption or inconsistencies**
✅ **Clear messages inform users what happened**

---

**Implementation Status**: ✅ **COMPLETE**
**Backend Server**: ✅ Running on http://127.0.0.1:5000
**Ready for Testing**: ✅ Yes

---

## Quick Reference

### When Does Smart Merge Happen?
- ✅ User modifies roles (add/remove/edit)
- ✅ Pathway stays the same (seProcesses threshold not crossed)
- ✅ Not first-time setup

### When Does Full Reset Happen?
- ✅ Pathway changes (seProcesses crosses threshold 3)
- ✅ First-time organization setup
- ✅ User explicitly wants full reset (future feature)

### What Gets Preserved?
- ✅ Role-process matrix values for unchanged roles
- ✅ Role metadata (name, description, cluster)
- ✅ Role-competency matrix (recalculated automatically)

### What Gets Reset?
- ✅ Matrix values for new roles (template values)
- ✅ Matrix values for edited roles (signature changed)
- ✅ Everything if pathway changed

---

**Questions or Issues?**
- Check backend logs: `[ROLE SAVE]` and `[MATRIX INIT]` prefixes
- Check browser console: `[StandardRoleSelection]` logs
- Verify database: `organization_roles` and `role_process_matrix` tables
