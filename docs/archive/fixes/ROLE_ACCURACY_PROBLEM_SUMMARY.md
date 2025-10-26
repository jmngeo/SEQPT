# Role Suggestion Accuracy Problem - Root Cause Analysis

**Date**: 2025-10-21
**Status**: CRITICAL ISSUE IDENTIFIED

---

## Problem Statement

All 5 different job profiles (Software Developer, Integration Engineer, QA Engineer, Project Manager, Hardware Designer) are mapping to the same role: **Service Technician**.

Expected mappings:
1. Software Developer → Specialist Developer
2. Integration Engineer → System Engineer
3. QA Engineer → Quality Engineer/Manager
4. Project Manager → Project Manager
5. Hardware Designer → Specialist Developer

Actual: **ALL → Service Technician** (incorrect)

---

## Root Cause

**User competency vectors are 100% zeros!**

Debug output shows:
```
User Vector Stats:
  Length: 16
  Non-zero count: 0
  Sum: 0
  Max: 0
  Mean: 0.00

User vector zero ratio: 100.0%
```

When all user competencies are 0, the Euclidean distance algorithm simply finds the role with the lowest competency sum, which happens to be Service Technician (sum=23).

---

## Why This Happens

The competency calculation formula is:
```
user_competency_value = role_process_value * process_competency_value
```

This formula is executed by the stored procedure `update_unknown_role_competency_values`.

If EITHER value is 0, the result is 0.

**Three possible causes:**

### 1. Process Involvement is Zero
- `unknown_role_process_matrix` has all `role_process_value = 0`
- This means LLM marked all processes as "Not performing"
- Formula: `0 * process_competency_value = 0`

### 2. Process-Competency Matrix is Empty/Wrong
- `process_competency_matrix` has no data or incorrect mappings
- Already checked: Has 480 entries ✅
- So this is NOT the problem

### 3. Stored Procedure Not Executing
- `update_unknown_role_competency_values` isn't being called
- Or it's failing silently
- Code shows it IS being called at routes.py:1671

---

## Investigation Needed

Check if process involvement is being saved correctly:

```sql
-- Check process involvement for test user
SELECT urpm.iso_process_id, ip.name, urpm.role_process_value
FROM unknown_role_process_matrix urpm
JOIN iso_processes ip ON urpm.iso_process_id = ip.id
WHERE urpm.user_name = 'test_role_suggestion_user'
  AND urpm.organization_id = 11;
```

Expected: Multiple entries with values 1 (Supporting), 2 (Responsible), 4 (Designing)
If ALL are 0 → LLM is marking everything as "Not performing"

---

## Likely Diagnosis

Based on FAISS_AND_ROLE_MATCHING_FIX_SUMMARY.md, we know:
- Only 3 processes matched for software developer
- Expected: 8-10 processes for a developer role

**Two scenarios:**

### Scenario A: Too Few Processes Matched
- FAISS retrieves 10 processes
- But LLM marks only 2-3 as "performing"
- Result: 7-8 processes with value=0, only 2-3 with value>0
- This gives VERY sparse competency vectors
- All roles look similar (mostly zeros)

### Scenario B: ALL Processes Marked as "Not Performing"
- FAISS retrieves 10 processes
- LLM marks ALL as value=0 ("Not performing")
- Result: 100% zero competency vector
- This matches what we see in debugging

---

## Why LLM Might Mark Everything as "Not Performing"

Looking at the test output, only 3 processes had non-zero values:
- System architecture definition process: Designing
- Design definition process: Designing
- Implementation process: Responsible

This suggests the LLM prompt or logic is too restrictive, or the task descriptions aren't matching well enough to the process descriptions.

---

## Solution Approaches

### Option 1: Fix LLM Process Matching (Recommended)
- Review LLM prompt in `llm_process_identification_pipeline.py`
- Make it less restrictive
- Ensure it considers partial/indirect involvement
- Test with clearer, more detailed task descriptions

### Option 2: Improve FAISS Retrieval
- Currently retrieves 10 processes (k=10)
- Could increase to k=15 or k=20 for more candidates
- Better retrieval = better matching chances

### Option 3: Fall Back to Process-Based Matching
- If competency vector is >90% zeros, use process-based matching instead
- Calculate role similarity based on process profiles
- Derik's simple approach assumes good competency data

### Option 4: Hybrid Fallback
- Try competency-based first
- If confidence < 50% or vector is >80% zeros
- Fall back to process-based scoring
- This was the "hybrid" approach mentioned in SESSION_HANDOVER.md

---

## Immediate Action Required

1. **Check actual process involvement data** in database
   - Query `unknown_role_process_matrix`
   - Verify values are not all 0

2. **Review LLM prompt** in process identification
   - File: `llm_process_identification_pipeline.py`
   - May be too strict in determining involvement

3. **Test with more detailed task descriptions**
   - Current test has good tasks
   - But may need even more specific SE terminology

4. **Consider re-implementing hybrid approach**
   - Pure competency-based fails with sparse vectors
   - Need process-based scoring as backup

---

## Files to Check

1. `src/backend/app/services/llm_pipeline/llm_process_identification_pipeline.py`
   - LLM prompt for process involvement classification
   - Lines ~400-500

2. `src/backend/app/routes.py`
   - Line 1671: Stored procedure call
   - Lines ~1600-1700: Process data storage

3. Database tables:
   - `unknown_role_process_matrix` - Process involvement
   - `process_competency_matrix` - Process-competency mapping (480 entries ✅)
   - `unknown_role_competency_matrix` - Calculated user competencies (all zeros ❌)

---

## Status

- ✅ FAISS enabled and working
- ✅ Database populated (role_competency_matrix)
- ✅ Stored procedure exists and is called
- ❌ User competency vectors are 100% zeros
- ❌ All roles map to Service Technician
- ⚠️  System is "operational" but completely inaccurate

**Next Step**: Investigate why process involvement is resulting in zero competencies.
