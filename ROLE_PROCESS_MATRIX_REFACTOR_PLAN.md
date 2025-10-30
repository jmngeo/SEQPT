# Role-Process Matrix Refactoring Plan

**Date**: 2025-10-29
**Objective**: Change from pre-populated matrices to user-defined role-based matrices with RACI validation

## Current System (Before Changes)

### At Registration
- `register_admin()` calls `_initialize_organization_matrices(org_id)` (routes.py:628)
- This copies 392 entries (14 roles × 28 processes) from org 1
- Every organization starts with the same default matrix
- Users can modify via `/admin/matrix/role-process` page

### Data Structure
- **Reference data**: Organization 1 has default role-process values
- **Source**: `populate_roles_and_matrices.py` contains the baseline matrix
- **Matrix layout**: Processes as rows, Roles as columns

## New System (After Changes)

### Phase 1 Task 2 Flow
1. **Step 1**: Target Group Size (unchanged)
2. **Step 2a**: Map Roles (user defines organization roles)
   - Add multiple company roles per cluster
   - Add custom roles not in clusters
3. **Step 2b**: **NEW** - Initialize & Edit Role-Process Matrix
   - **Auto-create matrix** when user saves roles in Step 2a
   - Matrix contains ONLY user-defined roles
   - Cluster-mapped roles get default values from org 1
   - Custom roles initialized with zeros
   - User can edit all values
   - **RACI validation** enforced

### Matrix Initialization Logic

```python
# When roles are saved in StandardRoleSelection (Step 2a)
# Backend should create role_process_matrix entries

for each user_role in saved_roles:
    if user_role.identificationMethod == 'STANDARD':
        # Copy from reference (org 1) for this cluster
        reference_values = get_role_process_for_cluster(
            org_id=1,
            role_cluster_id=user_role.standardRoleId
        )
        for process_id, value in reference_values:
            create_entry(
                org_id=current_org,
                role_id=user_role.id,  # NEW role ID
                process_id=process_id,
                value=value  # From reference
            )

    elif user_role.identificationMethod == 'CUSTOM':
        # Initialize with zeros
        for process_id in all_28_processes:
            create_entry(
                org_id=current_org,
                role_id=user_role.id,  # NEW role ID
                process_id=process_id,
                value=0  # User must define
            )
```

### RACI Validation Rules

**For each process (row):**
1. ✅ **Exactly ONE** role must have value = 2 (Responsible)
2. ✅ **At most ONE** role can have value = 3 (Accountable/Designs)

**Visual Indicators:**
- ❌ Red border/background: Missing Responsible (no "2" in row)
- ⚠️ Orange border/background: Multiple Responsible (more than one "2")
- ⚠️ Orange border/background: Multiple Accountable (more than one "3")
- ✅ Green indicator: Row passes validation

**Validation Messages:**
- Display at top: "X processes need attention"
- Highlight problematic rows
- Show tooltip on hover explaining the issue
- Cannot proceed to next step until all processes pass validation

## Implementation Tasks

### Backend Changes

#### Task 1: Update Registration (routes.py)
- [ ] Comment out or remove line 628: `_initialize_organization_matrices(organization.id)`
- [ ] Add comment explaining why (matrices created in Phase 1 Task 2)

#### Task 2: Create Matrix Initialization Endpoint
- [ ] New endpoint: `POST /api/phase1/roles/initialize-matrix`
- [ ] Called after roles are saved in StandardRoleSelection
- [ ] Input: `{ organizationId, maturityId, roles: [...] }`
- [ ] Logic:
  - Delete existing role_process_matrix entries for this org (if any)
  - For each role:
    - If STANDARD: Copy from org 1 for that cluster
    - If CUSTOM: Create with zeros
- [ ] Return: `{ success: true, entriesCreated: N }`

#### Task 3: Update Bulk Save Endpoint (optional)
- [ ] Current: `PUT /role_process_matrix/bulk` expects `role_cluster_id`
- [ ] Should work with new user-defined role IDs
- [ ] No changes needed if it already uses role.id from organization_se_roles table

### Frontend Changes

#### Task 4: Fix RoleProcessMatrix.vue Structure
- [ ] **Transpose matrix**: Processes as rows, Roles as columns
- [ ] Match admin matrix layout
- [ ] Update table structure:
  ```html
  <thead>
    <tr>
      <th>Corner cell: "Roles →" / "Processes ↓"</th>
      <th v-for="role in roles">{{ role.orgRoleName }}</th>
    </tr>
  </thead>
  <tbody>
    <tr v-for="process in processes">
      <td>{{ process.process_name }}</td>
      <td v-for="role in roles">
        <el-input-number v-model="matrix[process.id][role.id]" />
      </td>
    </tr>
  </tbody>
  ```
- [ ] Update data structure: `matrix[process.id][role.id] = value`

#### Task 5: Add Matrix Initialization Call
- [ ] In StandardRoleSelection.vue `handleContinue()`
- [ ] After roles are saved successfully
- [ ] Call new initialization endpoint
- [ ] Pass roles data to RoleProcessMatrix component

#### Task 6: Implement RACI Validation
- [ ] Add validation functions:
  ```javascript
  const validateProcess = (processId) => {
    const values = roles.map(role => matrix[processId][role.id])
    const responsibleCount = values.filter(v => v === 2).length
    const accountableCount = values.filter(v => v === 3).length

    return {
      hasResponsible: responsibleCount === 1,
      multipleResponsible: responsibleCount > 1,
      multipleAccountable: accountableCount > 1,
      isValid: responsibleCount === 1 && accountableCount <= 1
    }
  }
  ```
- [ ] Add visual indicators:
  - Row highlighting (red/orange/green)
  - Validation summary at top
  - Tooltips on problematic rows
- [ ] Disable "Save & Continue" until all processes pass validation
- [ ] Show clear error messages

#### Task 7: Update UI Components
- [ ] Add validation summary card
- [ ] Show process-by-process validation status
- [ ] Add legend explaining validation rules
- [ ] Improve UX with clear messaging

### Database Considerations

#### No Schema Changes Needed ✅
- `role_process_matrix` table already has correct structure:
  - `organization_id`
  - `role_cluster_id` (this is actually the role.id from organization_se_roles)
  - `iso_process_id`
  - `role_process_value` (0-3)

#### Data Migration
- [ ] No migration needed - new flow only applies to new organizations
- [ ] Existing organizations keep their current matrices
- [ ] Admin can still edit via `/admin/matrix/role-process`

## Testing Checklist

### Registration Flow
- [ ] Register new admin - verify NO matrix created automatically
- [ ] Verify organization created successfully
- [ ] Verify can login and access Phase 1

### Role Selection & Matrix Creation
- [ ] Add multiple roles to same cluster
- [ ] Add custom roles
- [ ] Save roles - verify matrix initialization endpoint called
- [ ] Verify matrix contains only user-defined roles
- [ ] Verify cluster-mapped roles have default values copied
- [ ] Verify custom roles have all zeros

### Matrix Editing & Validation
- [ ] Matrix displays correctly (processes as rows, roles as columns)
- [ ] Can edit all cells
- [ ] Validation highlights missing Responsible (no "2")
- [ ] Validation highlights multiple Responsible (>1 "2")
- [ ] Validation highlights multiple Accountable (>1 "3")
- [ ] Cannot proceed until all processes valid
- [ ] Save works correctly

### Edge Cases
- [ ] Organization with only custom roles (no cluster-mapped)
- [ ] Organization with only cluster-mapped roles (no custom)
- [ ] Single role organization
- [ ] Many roles (15+) - UI still usable
- [ ] Back navigation with unsaved changes
- [ ] Refresh page - data persists

## Files to Modify

### Backend
1. `src/backend/app/routes.py`
   - Update `register_admin()` (line 628)
   - Add new initialization endpoint

### Frontend
2. `src/frontend/src/components/phase1/task2/StandardRoleSelection.vue`
   - Add matrix initialization call after role save

3. `src/frontend/src/components/phase1/task2/RoleProcessMatrix.vue`
   - Complete rewrite: transpose matrix
   - Add RACI validation
   - Improve UI/UX

4. `src/frontend/src/api/phase1.js` (if needed)
   - Add API call for matrix initialization

## Success Criteria

✅ **Registration**: No matrices created automatically
✅ **Role Definition**: Users can define multiple roles per cluster + custom roles
✅ **Matrix Initialization**: Matrix auto-created with correct values
✅ **Matrix Layout**: Processes as rows, roles as columns (matches admin page)
✅ **RACI Validation**: Enforced for all processes before proceeding
✅ **User Experience**: Clear, intuitive, with helpful validation messages
✅ **Data Integrity**: Correct values saved to database

## Rollback Plan

If issues arise:
1. Restore `_initialize_organization_matrices()` call at registration
2. Revert frontend changes
3. Existing organizations unaffected

## Timeline Estimate

- **Backend**: 2-3 hours
- **Frontend**: 3-4 hours
- **Testing**: 2 hours
- **Total**: 7-9 hours

## Notes

- Keep admin matrix page (`/admin/matrix/role-process`) functional
- Admin can always edit matrix later if needed
- Central reference (org 1) remains unchanged
- This improves UX by showing only relevant roles
- RACI validation ensures data quality
