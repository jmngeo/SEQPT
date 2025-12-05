# Session 4 Investigation Report
## users_by_scenario Field Missing from API Output

**Date**: November 6, 2025 (20:00-21:00 UTC)
**Investigator**: Claude (Session 4)
**Issue**: `users_by_scenario` field not appearing in API response despite code fix

---

## Executive Summary

Session 3 added a `users_by_scenario` field to the algorithm output to track which specific users fall into each scenario (A, B, C, D). However, despite multiple backend restarts and cache clears, this field never appeared in the API response at `/api/phase2/learning-objectives/29`.

**Current Status**: Issue identified but NOT resolved. Standalone test script created for next session to isolate the problem.

---

## Investigation Timeline

### Discovery Phase (30 minutes)

**Initial Verification**:
- Confirmed fix exists in code at line 1283 of `role_based_pathway_fixed.py`
- Traced complete API call chain from Flask route to algorithm function
- Verified we edited the correct file and function

**Code Path Traced**:
```
routes.py:4240 (api_get_learning_objectives)
    ↓
pathway_determination.py:209 (generate_learning_objectives)
    ↓
role_based_pathway_fixed.py:318 (import and call)
    ↓
role_based_pathway_fixed.py:605 (run_role_based_pathway_analysis_fixed)
    ↓
role_based_pathway_fixed.py:1283 (final output formatting - OUR FIX)
```

### Debugging Phase (45 minutes)

**Attempts Made**:
1. Restarted Flask backend 3 times
2. Cleared Python `__pycache__` directories
3. Killed ALL Python processes via Task Manager
4. Started completely fresh backend instance
5. Added debug logging with `logger.info()`
6. Added debug output with `print()` statements

**Results**: Field still missing, NO debug output appeared

### Analysis Phase (15 minutes)

**Key Observations**:
- API returns 200 OK (request succeeds)
- Response structure matches expected format
- Only `users_by_scenario` field is missing
- All other fields present and correct
- **Neither logging nor print() produced any output**

**This suggests**: Either caching, buffering, or a different execution path

---

## Technical Details

### Fix Location (Verified Present)

**File**: `src/backend/app/services/role_based_pathway_fixed.py`

**Line 421-427** (Step 3 function):
```python
return {
    'scenario_A_count': counts['A'],
    ...
    'users_by_scenario': {
        'A': list(unique_users_by_scenario['A']),
        'B': list(unique_users_by_scenario['B']),
        'C': list(unique_users_by_scenario['C']),
        'D': list(unique_users_by_scenario['D'])
    }
}
```

**Line 1267-1285** (Final output formatting):
```python
for competency_id, data in coverage.items():
    agg = data['aggregation']
    result['cross_strategy_coverage'][competency_id] = {
        ...
        'users_by_scenario': agg['users_by_scenario'],  # Line 1283
        'warnings': data.get('warnings', [])
    }
```

### API Response Structure (Current)

```json
{
  "cross_strategy_coverage": {
    "1": {
      "best_fit_strategy_id": 34,
      "fit_score": -1.43,
      "scenario_A_count": 1,
      "scenario_B_count": 17,
      "scenario_C_count": 0,
      "scenario_D_count": 3,
      "scenario_A_percentage": 4.76,
      "scenario_B_percentage": 80.95,
      "scenario_C_percentage": 0.0,
      "scenario_D_percentage": 14.29,
      "warnings": [...]
      // users_by_scenario: MISSING!
    }
  }
}
```

### Expected Structure

```json
{
  "cross_strategy_coverage": {
    "1": {
      ...
      "users_by_scenario": {
        "A": [145],
        "B": [123, 124, 125, ...],
        "C": [],
        "D": [146, 147, 148]
      },
      "warnings": [...]
    }
  }
}
```

---

## Hypotheses

### Hypothesis 1: Caching (Most Likely)
**Evidence**:
- Code is correct
- Multiple restarts didn't help
- Previous response (without field) being served

**Test**: Clear all caches, hard refresh browser

### Hypothesis 2: Output Buffering
**Evidence**:
- No debug output appeared (neither logging nor print)
- Flask may redirect stdout/stderr

**Test**: Add `flush=True` to print(), check Flask logging config

### Hypothesis 3: Data Missing Upstream
**Evidence**:
- Field might not exist in `agg` dict when line 1283 executes
- Error silently caught?

**Test**: Standalone script to verify data at each step

### Hypothesis 4: Different Code Path
**Evidence**:
- Despite tracing, middleware or proxy might transform response
- Cached bytecode from old version?

**Test**: Standalone script bypasses Flask entirely

---

## Solution Approach

### RECOMMENDED: Standalone Test Script

**File Created**: `test_users_by_scenario_direct.py`

**Purpose**:
- Bypasses Flask web server completely
- Directly calls `run_role_based_pathway_analysis_fixed(29)`
- Verifies field exists in raw Python dictionary output
- Saves output to JSON file for inspection

**Usage**:
```bash
cd /c/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis
venv/Scripts/python.exe test_users_by_scenario_direct.py
```

**Expected Results**:

**If SUCCESS**:
- Field exists in algorithm output
- Problem is Flask/caching/middleware
- Next step: investigate API layer

**If FAILURE**:
- Field missing from algorithm output
- Problem is in data flow (Step 3 → Step 8)
- Next step: add intermediate debugging

---

## Files Modified

**Backend Code**:
- `src/backend/app/services/role_based_pathway_fixed.py:1270-1271` - Added debug statements (temporary)
- `src/backend/app/services/role_based_pathway_fixed.py:1283` - users_by_scenario fix (Session 3, verified)

**Test Scripts**:
- `test_users_by_scenario_direct.py` - NEW: Standalone test bypassing Flask

**Documentation**:
- `SESSION_HANDOVER.md` - Updated with Session 4 summary
- `SESSION4_INVESTIGATION_REPORT.md` - THIS FILE

---

## Next Steps for Resolution

### Immediate (Next Session Start)

1. **Run standalone test script**:
   ```bash
   venv/Scripts/python.exe test_users_by_scenario_direct.py
   ```

2. **Interpret results**:
   - If SUCCESS → investigate Flask/API layer (caching, middleware)
   - If FAILURE → debug data flow from Step 3 to Step 8

### If Standalone Test Succeeds

**Problem is in Flask/API layer**:
1. Clear ALL browser caches (hard refresh: Ctrl+F5)
2. Check Flask response caching configuration
3. Check if nginx/proxy is caching responses
4. Test with `curl` to bypass browser cache
5. Add `Cache-Control: no-cache` headers

### If Standalone Test Fails

**Problem is in algorithm data flow**:
1. Add debug logging to `aggregate_by_user_distribution()` (line 363-427)
2. Verify `users_by_scenario` in return value
3. Add debug logging to `cross_strategy_coverage()` (line 534-598)
4. Verify `aggregation` dict contains the field
5. Trace exact data flow from Step 3 → coverage dict → final output

---

## Background Context

### System State
- **Database**: PostgreSQL, org 29 ready (21 users, 4 roles)
- **Backend**: Multiple instances running (18+ processes - CLEANUP NEEDED)
- **Frontend**: http://localhost:3000

### Test Data Available
- ✅ Org 29: High maturity, 4 roles, 21 users
- ✅ Script: `create_test_org_30_multirole.py` (ready to run)
- ⏸️ Orgs 30-33: Not yet created

### Key Learnings
1. **Code path tracing is essential** - wasted time until we verified the exact call chain
2. **Debug output unreliable in Flask** - neither logging nor print() worked
3. **Standalone testing needed** - web server adds too many variables
4. **Cache awareness critical** - code changes can be masked by caching

---

## References

**Design Document**: `data/source/Phase 2/LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

**Related Files**:
- `src/backend/app/routes.py:4205-4240` - API endpoint
- `src/backend/app/services/pathway_determination.py:209-363` - Pathway orchestration
- `src/backend/app/services/role_based_pathway_fixed.py` - Main algorithm

**Previous Sessions**:
- Session 2: Chart mislabeling fixed, algorithm issues identified
- Session 3: "Double-counting bug" corrected (was already fixed), users_by_scenario added

---

## Conclusion

This session successfully traced the complete code execution path and verified that the fix IS in the correct location. However, the field still doesn't appear in API responses, and debug output never appeared.

The standalone test script created in this session will definitively determine whether the issue is in the algorithm logic or in the Flask/API layer. This is the critical next step for resolution.

**Next Session Priority**: Run `test_users_by_scenario_direct.py` FIRST before any other work.

---

**Report Generated**: November 6, 2025
**Status**: Investigation Complete, Solution Pending
**Confidence**: High that standalone test will isolate the issue
