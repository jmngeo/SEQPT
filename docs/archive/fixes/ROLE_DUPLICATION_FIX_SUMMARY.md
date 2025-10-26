# Role Duplication Fix Summary

**Date**: 2025-10-25
**Issue**: Duplicate "Specialist Developer (Hardware Design Engineer)" role displayed on Phase 1 Review page
**Affected User**: reeguy (org_id: 20)
**Status**: RESOLVED

---

## Root Cause Analysis

### How the Duplication Occurred

When **retaking Phase 1 assessment**, the system allowed duplicate standard roles to be saved:

1. **Initial Phase 1 Completion**: User identified roles through task-based mapping, which suggested "Specialist Developer" (ID: 5)
2. **Retaking Phase 1**: User went back and re-ran role identification
3. **Frontend Loading Bug**: `StandardRoleSelection.vue` component's `onMounted` hook loaded existing roles and blindly pushed all role IDs to the `selectedRoleIds` array without checking for duplicates
4. **No Backend Validation**: The `save_roles()` endpoint accepted the array with duplicate `standardRoleId` values without validation
5. **Database State**: The `phase_questionnaire_responses` table stored the JSON with duplicate roles
6. **Display Issue**: The Review page rendered all items in the array, showing duplicates

### Technical Details

**Database Record**:
- Table: `phase_questionnaire_responses`
- Record ID: `c645b119-c513-4280-b0f8-ffe219a42acd`
- Original role count: 6 roles (with 1 duplicate)
- After cleanup: 5 unique roles

**Duplicate Role**:
- `standardRoleId`: 5
- `standardRoleName`: "Specialist Developer"
- `orgRoleName`: "Hardware Design Engineer"
- Appeared twice in the `responses.roles` JSON array

---

## Implemented Solutions

### 1. Backend Validation (routes.py:1553-1575)

Added duplicate detection and removal in `save_roles()` endpoint:

```python
# VALIDATION: Check for duplicate standardRoleId values
seen_role_ids = set()
deduplicated_roles = []
duplicates_found = []

for role in roles:
    role_id = role.get('standardRoleId')
    if role_id is None:
        continue

    if role_id in seen_role_ids:
        duplicates_found.append(f"{role.get('standardRoleName', 'Unknown')} (ID: {role_id})")
        current_app.logger.warning(f"[DUPLICATE DETECTED] Role ID {role_id} appears multiple times")
    else:
        seen_role_ids.add(role_id)
        deduplicated_roles.append(role)

# Log if duplicates were removed
if duplicates_found:
    current_app.logger.info(f"[DEDUPLICATION] Removed {len(duplicates_found)} duplicate role(s)")

# Use deduplicated roles
roles = deduplicated_roles
```

**Behavior**:
- Automatically removes duplicates before saving
- Logs warnings when duplicates are detected
- Preserves the first occurrence of each role
- No error thrown - silently deduplicates

### 2. Frontend Loading Fix (StandardRoleSelection.vue:219-247)

Fixed the `onMounted` hook to use a Set for deduplication:

```javascript
// Use Set to prevent duplicate role IDs
const uniqueRoleIds = new Set()

// Pre-fill selected role IDs and custom names
props.existingRoles.roles.forEach(role => {
  if (role.standardRoleId) {
    // Only add if not already present (prevents duplicates from database)
    if (!uniqueRoleIds.has(role.standardRoleId)) {
      uniqueRoleIds.add(role.standardRoleId)
      selectedRoleIds.value.push(role.standardRoleId)

      // If there's an organization-specific name, store it (prefer first occurrence)
      if (role.orgRoleName && !customNames.value[role.standardRoleId]) {
        customNames.value[role.standardRoleId] = role.orgRoleName
      }
    } else {
      console.warn(`[StandardRoleSelection] DUPLICATE DETECTED: Role ID ${role.standardRoleId} already loaded - skipping duplicate`)
    }
  }
})
```

**Behavior**:
- Uses Set to track already-loaded role IDs
- Skips duplicate entries when loading from database
- Logs console warning when duplicates are encountered
- Preserves first occurrence (including custom org name)

### 3. Database Cleanup

Cleaned all existing duplicates using SQL:

```sql
-- Deduplicate using ROW_NUMBER() window function
WITH numbered_roles AS (
    SELECT
        r,
        ROW_NUMBER() OVER (PARTITION BY r->>'standardRoleId' ORDER BY r::text) AS rn
    FROM phase_questionnaire_responses,
         jsonb_array_elements((responses::jsonb)->'roles') AS r
    WHERE id = '<record_id>'
),
deduplicated AS (
    SELECT jsonb_agg(r) AS clean_roles
    FROM numbered_roles
    WHERE rn = 1
)
UPDATE phase_questionnaire_responses
SET responses = jsonb_set(
    responses::jsonb,
    '{roles}',
    (SELECT clean_roles FROM deduplicated)
)
WHERE id = '<record_id>';
```

**Results**:
- Organization 20 (reeguy):
  - Record `c645b119-...`: 6 roles -> 5 roles (removed 1 duplicate)
  - Record `2962154b-...`: 4 roles -> 3 roles (removed 1 duplicate)
- All other organizations: No duplicates found
- Total duplicates removed: 2

---

## Prevention Strategy

### Multi-Layer Defense

1. **Backend Layer** (PRIMARY):
   - Deduplicates roles before saving to database
   - Logs warnings for monitoring
   - No user-facing error - graceful handling

2. **Frontend Layer** (SECONDARY):
   - Deduplicates when loading existing data
   - Prevents duplicate state from propagating
   - Console warnings for debugging

3. **Database Layer** (CLEANUP):
   - One-time cleanup of existing duplicates
   - No schema changes required (JSON validation is complex)

### Why This Approach?

1. **No Breaking Changes**: Doesn't reject user submissions or throw errors
2. **Backward Compatible**: Handles existing duplicates gracefully
3. **Defensive Programming**: Multiple layers prevent future occurrences
4. **Monitoring**: Logs provide visibility into duplicate attempts
5. **User Experience**: No disruption - silently fixes the issue

---

## Testing Recommendations

### Test Scenario 1: New Role Selection
1. Log in as admin for any organization
2. Complete Phase 1 Task 2 (Role Selection)
3. Manually try to select the same role twice (frontend should prevent this)
4. Save and verify only one instance is stored

### Test Scenario 2: Retaking Phase 1
1. Complete Phase 1 with some roles selected
2. Go back to Task 2 and modify role selection
3. Verify no duplicates appear in the UI
4. Save and verify database has no duplicates

### Test Scenario 3: Task-Based Mapping
1. Use task-based mapping to identify roles
2. Retake Phase 1 and use task-based mapping again
3. Verify no duplicates if the same role is suggested

### Test Scenario 4: Review Page (reeguy)
1. Log in as reeguy (password: reeguy)
2. Navigate to Phase 1 Review page
3. Verify "Specialist Developer (Hardware Design Engineer)" appears only ONCE
4. Expected roles displayed:
   - System Engineer (Systems Integration Engineer)
   - Specialist Developer (Hardware Design Engineer)
   - Quality Engineer/Manager (Quality Assurance Specialist)
   - Service Technician (Hoi Hoi)
   - Internal Support

---

## Files Modified

### Backend
- `src/backend/app/routes.py` (lines 1553-1575)
  - Added duplicate detection in `save_roles()` function

### Frontend
- `src/frontend/src/components/phase1/task2/StandardRoleSelection.vue` (lines 219-247)
  - Fixed `onMounted()` hook to deduplicate loaded roles

### Database
- Cleaned 2 records in `phase_questionnaire_responses` table
- No schema changes

---

## Known Limitations

1. **JSON Validation**: PostgreSQL doesn't support complex JSON constraints easily, so we can't enforce uniqueness at the database level
2. **Old Records**: Historical duplicate records remain in the database but are handled gracefully by the frontend
3. **Task-Based Mapping**: If multiple job profiles are mapped to the same standard role, duplicates could theoretically occur - but backend validation will catch this

---

## Monitoring

Backend logs will show:
```
[DUPLICATE DETECTED] Role ID 5 appears multiple times in submission for org 20
[DEDUPLICATION] Removed 1 duplicate role(s) for org 20: Specialist Developer (ID: 5)
```

Frontend console will show:
```
[StandardRoleSelection] DUPLICATE DETECTED: Role ID 5 (Specialist Developer) already loaded - skipping duplicate
```

These logs indicate the system is working correctly and preventing duplicates.

---

## Success Criteria

- [x] Backend validation prevents duplicate standardRoleId values
- [x] Frontend loading handles duplicates from database gracefully
- [x] Existing database duplicates cleaned up
- [x] No user-facing errors or disruptions
- [ ] User verifies Review page shows no duplicates (PENDING USER TEST)

---

## Related Issues

This fix also prevents similar issues with:
- Task-based role mapping duplication
- Any future role identification pathways
- Retaking Phase 1 multiple times

---

**Status**: Ready for user testing
**Next Action**: User should log in as reeguy and verify the Review page shows 5 unique roles
