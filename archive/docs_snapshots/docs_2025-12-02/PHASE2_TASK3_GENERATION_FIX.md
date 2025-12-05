# Phase 2 Task 3 - Automatic Generation Fix
**Date**: 2025-11-08
**Issue**: Learning objectives were being generated automatically on page load
**Status**: FIXED

## Problem Analysis

### Issue 1: Automatic Generation on Page Load
**Symptom**: Page took a long time to load, indicating LLM calls were being made

**Root Cause**:
1. `usePhase2Task3.js` → `fetchData()` called `fetchObjectives()` on mount (line 63)
2. `fetchObjectives()` → calls `GET /phase2/learning-objectives/{org_id}`
3. Backend endpoint → calls `generate_learning_objectives()` if no cache exists
4. This triggers LLM calls automatically without user action

**Impact**: 
- Slow page loads
- Unexpected API costs
- Poor user experience
- Generation happens without user consent

### Issue 2: PMT Form Not Visible
**Symptom**: PMT input form didn't appear for org 29

**Root Cause**: PMT context existed in database, so form was hidden

**Solution**: Deleted PMT context from org 29 to allow testing

## Fixes Applied

### Fix 1: Remove Automatic Objective Fetching

**File**: `src/frontend/src/composables/usePhase2Task3.js`

**Before**:
```javascript
// Try to fetch existing objectives
try {
  await fetchObjectives()  // WRONG: Always calls, may trigger generation
} catch (err) {
  console.log('[usePhase2Task3] No existing objectives found')
}
```

**After**:
```javascript
// Only fetch objectives if they exist (without triggering generation)
// Check the has_generated_objectives flag from prerequisites
if (prerequisitesResponse?.has_generated_objectives) {
  console.log('[usePhase2Task3] Objectives exist, fetching them...')
  try {
    await fetchObjectives()
  } catch (err) {
    console.log('[usePhase2Task3] Failed to fetch existing objectives:', err.message)
  }
} else {
  console.log('[usePhase2Task3] No objectives exist yet. Waiting for user to generate.')
}
```

**Key Changes**:
- Added conditional check before fetching
- Only fetch if `has_generated_objectives` flag is true
- This prevents automatic generation on page load

### Fix 2: Add "Objectives Exist" Flag to Prerequisites

**File**: `src/backend/app/services/pathway_determination.py`

**Added** (lines 663-667):
```python
# Check if generated objectives exist (without triggering generation)
existing_objectives = GeneratedLearningObjectives.query.filter_by(
    organization_id=org_id
).first()
has_generated_objectives = existing_objectives is not None
```

**Return value updated** (line 695):
```python
return {
    # ... other fields ...
    'has_generated_objectives': has_generated_objectives,  # NEW FLAG
    # ... rest of fields ...
}
```

**Purpose**: Allows frontend to know if objectives exist without calling the GET endpoint

### Fix 3: Database Cleanup

**Command**:
```sql
DELETE FROM organization_pmt_context WHERE organization_id = 29;
```

**Result**: PMT form now visible for org 29 for testing

## New Flow

### Page Load (No Generation)
```
1. User navigates to Phase 2 Task 3
2. fetchData() runs
3. fetchPrerequisites() → returns has_generated_objectives flag
4. If flag = false → Skip fetchObjectives()
5. Page loads fast (no LLM calls)
```

### Explicit Generation (User Action Required)
```
1. User clicks "Generate Learning Objectives" button
2. Confirmation dialog appears
3. User confirms
4. POST /phase2/learning-objectives/generate called
5. Backend generates with LLM
6. Results displayed
7. has_generated_objectives flag set to true
8. Next page load will fetch existing objectives
```

## Benefits

1. **Fast Page Loads**: No automatic LLM calls
2. **User Control**: Generation only happens when button clicked
3. **Cost Savings**: No unexpected API charges
4. **Better UX**: Clear user intent required
5. **Caching Works**: Existing objectives still loaded efficiently

## Testing Checklist

- [x] Remove PMT context from org 29
- [ ] Navigate to Phase 2 Task 3 for org 29
- [ ] Verify page loads quickly (< 2 seconds)
- [ ] Verify PMT form is visible
- [ ] Verify no LLM calls in backend logs
- [ ] Click "Generate Learning Objectives" button
- [ ] Verify generation happens with LLM calls
- [ ] Refresh page
- [ ] Verify objectives load from cache (fast)

## Files Modified

### Frontend (1 file)
1. `src/frontend/src/composables/usePhase2Task3.js`
   - Added conditional check for objectives fetching (lines 54-73)

### Backend (1 file)
2. `src/backend/app/services/pathway_determination.py`
   - Added `has_generated_objectives` flag check (lines 663-667)
   - Added flag to return value (line 695)

## API Changes

### GET /phase2/learning-objectives/{org_id}/prerequisites

**New Response Field**:
```json
{
  "has_generated_objectives": true,  // NEW: Indicates if objectives exist
  "has_pmt_context": true,
  "selected_strategies": [...],
  // ... rest of fields
}
```

**Usage**: Frontend checks this flag before calling GET objectives endpoint

## Rollback Plan

If issues occur:

```bash
# Revert composable
git checkout HEAD~1 src/frontend/src/composables/usePhase2Task3.js

# Revert backend
git checkout HEAD~1 src/backend/app/services/pathway_determination.py
```

## Success Criteria

- ✅ Page loads in < 2 seconds without objectives
- ✅ No LLM calls on page load
- ✅ Generation only happens when button clicked
- ✅ PMT form visible when needed
- ✅ Existing objectives still load properly

---

**Status**: ✅ FIXED - Ready for Testing
**Last Updated**: 2025-11-08
