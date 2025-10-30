# Role-Competency Matrix Calculation Issues - TO FIX IN NEXT SESSION

**Date**: 2025-10-30
**Status**: Issues Identified - Needs Fixing

---

## Current Status

✅ **Working**: Role-competency matrix calculation via stored procedure
✅ **Working**: Org 1 restored as template with all 14 roles
⚠️ **Issue**: Matrix calculation logic may have conceptual problems

---

## The Flow (How It Should Work)

```
Phase 1: Organization Setup
┌─────────────────────────────────────┐
│ Task 2: Role Identification         │
│  → User selects/defines roles       │
│  → Creates entries in                │
│     organization_roles table         │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ Task 3: Role-Process Matrix         │
│  → Initialize matrix with baseline  │
│     from org 1 (template)           │
│  → User edits matrix to reflect     │
│     THEIR organization's process    │
│     involvement                      │
│  → Saves to role_process_matrix     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ AUTOMATIC CALCULATION                │
│  → Stored procedure calculates       │
│     role_competency_matrix           │
│  → Formula: role_process_value ×     │
│              process_competency_value│
└─────────────────────────────────────┘
           ↓
Phase 2: Competency Assessment
┌─────────────────────────────────────┐
│ Uses role_competency_matrix to      │
│ determine required competencies      │
└─────────────────────────────────────┘
```

---

## Issues Identified

### Issue 1: When Does Calculation Happen?

**Question**: When should `update_role_competency_matrix()` be called?

**Current Implementation**:
- ✅ Called in: `initialize-matrix` endpoint (after role-process matrix created)
- ✅ Called in: `role_process_matrix/bulk` endpoint (after bulk update)
- ✅ Called in: `process_competency_matrix/bulk` endpoint (after process-competency update)

**Potential Problem**:
- What if user edits role-process matrix one cell at a time?
- Should we recalculate after EVERY edit, or only when user clicks "Save"?
- Performance implications for large matrices?

**Recommendation**: Review frontend to understand when matrix saves happen

---

### Issue 2: Org 1 as Template

**Current State**: ✅ FIXED
- Org 1 now has all 14 standard roles (IDs 272-285)
- Complete role-process matrix (392 entries)
- Complete role-competency matrix (224 entries)

**How New Orgs Use Template**:
```python
# In initialize-matrix endpoint
reference_role = OrganizationRoles.query.filter_by(
    organization_id=1,  # Template org
    standard_role_cluster_id=standard_cluster_id
).first()

# Copy baseline values
reference_entries = RoleProcessMatrix.query.filter_by(
    organization_id=1,
    role_cluster_id=reference_role.id
).all()
```

**Concern**:
- What if org 1's baseline values are wrong?
- Should there be a "system default" separate from org 1?
- What if org 1 gets corrupted again?

**Recommendation**:
- Consider creating a "system defaults" table
- OR protect org 1 from accidental modification
- OR add validation to prevent org 1 deletion

---

### Issue 3: Stored Procedure Logic

**Current Formula**:
```sql
role_competency_value = MAX(
    role_process_value × process_competency_value
) GROUP BY role_id, competency_id
```

**Example**:
- Role: Project Manager (ID 274)
- Process: Requirements Analysis (ID 5)
- Role-Process value: 2 (Responsible)
- Process-Competency value for "Systems Thinking": 2
- **Result**: 2 × 2 = 4 → Role needs "Systems Thinking" at level 4

**Potential Issues**:
1. **MAX across processes**: Is this correct?
   - If a role is Responsible(2) for one process and Designing(4) for another
   - Both need same competency at level 2
   - Result: MAX(2×2, 4×2) = MAX(4, 8) = 8 (but max level is 6!)

2. **Multiplication semantics**:
   - Does 2×2=4 make sense?
   - Or should it be MIN(role_level, process_level)?
   - Or should there be a lookup table?

3. **CASE statement has gaps**:
   ```sql
   WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
   WHEN ... = 1 THEN 1
   WHEN ... = 2 THEN 2
   WHEN ... = 3 THEN 3
   WHEN ... = 4 THEN 4
   WHEN ... = 6 THEN 6
   ELSE -100  -- What about 5, 7, 8, 9, etc.?
   ```

   **Missing values**: 5, 7, 8, 9, 10, 12, 16, etc.

**Recommendation**:
- Review the mathematical model with domain expert
- Verify the CASE statement covers all valid combinations
- Add logging to catch ELSE -100 cases

---

### Issue 4: Process-Competency Matrix (Global)

**Current State**:
- Process-competency matrix is **GLOBAL** (no organization_id)
- Same for all organizations
- 448 entries (28 processes × 16 competencies)

**Question**:
- Is this correct?
- Or should each org have their own process-competency matrix?
- Current assumption: "Requirements Analysis always needs Systems Thinking at level X"

**Implication**:
- If process-competency is global, then differences between orgs come ONLY from role-process matrix
- This makes sense if we assume ISO processes have standard competency requirements

**Recommendation**: Verify this is the intended design

---

### Issue 5: Missing Validation

**No validation for**:
1. **Circular references**: What if role-process → process-competency → role-competency creates weird loops?
2. **Null values**: What if role_process_value is NULL?
3. **Out-of-range values**: What if someone manually inserts value=999?
4. **Orphaned entries**: What if a role is deleted but matrix entries remain?

**Current Protection**:
- CASCADE DELETE on organization_roles → role_process_matrix ✅
- CASCADE DELETE on organization_roles → role_competency_matrix ✅
- But no range validation

**Recommendation**: Add CHECK constraints or validation logic

---

## What Was Fixed Today

### Fix 1: Added Stored Procedure Call
**File**: `src/backend/app/routes.py` (line 1787-1801)

**Before**: `initialize-matrix` endpoint didn't call stored procedure
**After**:
```python
# CRITICAL: Calculate role-competency matrix
db.session.execute(
    text('CALL update_role_competency_matrix(:org_id);'),
    {'org_id': org_id}
)
```

### Fix 2: Restored Org 1 Template
**Database Changes**:
```sql
-- Deleted incomplete org 1 data (only 4 roles)
-- Created all 14 standard roles
-- Copied baseline matrix from org 11
-- Calculated role-competency matrix
```

**Result**:
- Org 1: 14 roles, 392 process entries, 224 competency entries ✅

### Fix 3: Updated Reference Organization
**File**: `src/backend/app/routes.py` (lines 1728-1739)

**Changed**: `organization_id=11` → `organization_id=1`

---

## Testing Needed

1. **Test full Phase 1 flow**:
   - Create new organization
   - Select roles
   - Initialize matrix
   - Edit matrix
   - Verify role-competency calculated correctly

2. **Test Phase 2 flow**:
   - Select roles
   - Verify competencies load
   - Complete assessment
   - Check results

3. **Test edge cases**:
   - Custom roles (no standard cluster)
   - Mix of standard + custom roles
   - Organization with all 14 roles
   - Organization with only 1 role

4. **Test matrix updates**:
   - Edit role-process matrix
   - Verify role-competency updates
   - Edit process-competency matrix
   - Verify all orgs' role-competency updates

---

## Questions for Next Session

1. **Calculation Frequency**: How often should we recalculate?
2. **Template Protection**: How do we protect org 1 from corruption?
3. **Formula Verification**: Is the multiplication formula correct?
4. **CASE Statement**: Should we handle values beyond {0,1,2,3,4,6}?
5. **Performance**: Should we cache role-competency or always calculate fresh?

---

## References

**Stored Procedure**: `update_role_competency_matrix`
- Location: Database (created via populate scripts)
- Formula: `role_competency_value = role_process_value × process_competency_value`
- Grouping: MAX value per (role_id, competency_id)

**Related Files**:
- `src/backend/app/routes.py` - Matrix endpoints
- `src/backend/models.py` - OrganizationRoles, RoleProcessMatrix, RoleCompetencyMatrix
- Derik's implementation: `sesurveyapp-main/postgres-init/init.sql`

---

## Next Session Tasks

1. Review stored procedure logic with domain expert
2. Add validation for matrix values
3. Consider adding org 1 protection
4. Test complete Phase 1 → Phase 2 flow
5. Document the mathematical model
6. Consider performance optimizations

---

**Status**: Ready for next session review
**Priority**: Medium (system works but may have conceptual issues)
