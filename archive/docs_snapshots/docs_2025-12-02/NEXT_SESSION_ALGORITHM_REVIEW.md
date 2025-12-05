# Phase 2 Task 3 - Algorithm Review for Next Session

**Date Created**: November 6, 2025
**Priority**: HIGH
**Status**: Backend algorithm VALIDATED - Frontend display issue identified

---

## Executive Summary

After extensive debugging, the **backend algorithm is working correctly**. The issue is with how the **frontend displays multi-strategy results**.

### What Was Fixed Today

1. **Critical Bug: Wrong User ID in Queries** ✅ FIXED
   - Was using `user.id` (assessment ID) instead of `user.user_id`
   - Caused incorrect medians and scenario distributions
   - Fixed at: `role_based_pathway_fixed.py:287, 1021`

2. **Critical Bug: 2-Way vs 3-Way Gap Comparison** ✅ FIXED
   - Was only comparing Current vs Target, ignoring Role Requirement
   - Now properly implements Scenario B detection (target met, role not met)
   - Fixed at: `role_based_pathway_fixed.py:1052-1090`

3. **Missing Field: organizational_scenario** ✅ FIXED
   - Added explicit scenario field for frontend compatibility
   - Fixed at: `role_based_pathway_fixed.py:1050, 1084, 1155`

---

## Diagnostic Results (Communication Competency, Org 29)

### Raw Data
- **Organizational median**: 3
- **Max role requirement**: 6
- **User scores**: [0, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4]

### Strategy 34: "Common Basic Understanding"
```
Current: 3
Target:  1
Role:    6

Scenario Logic:
  Check D: 3 >= 6 AND 3 >= 1 → FALSE
  Check C: 1 > 6 → FALSE
  Check B: 1 <= 3 < 6 → TRUE ✅

Result: Scenario B (CORRECT)
Gap: 3 levels (to role requirement)
Individual distribution: 95% B, 5% A
```

### Strategy 35: "Continuous Support"
```
Current: 3
Target:  4
Role:    6

Scenario Logic:
  Check D: 3 >= 6 AND 3 >= 4 → FALSE
  Check C: 4 > 6 → FALSE
  Check B: 4 <= 3 < 6 → FALSE
  Check A: 3 < 4 <= 6 → TRUE ✅

Result: Scenario A (CORRECT)
Gap: 1 level (to strategy target)
Individual distribution: 76% A, 24% B
```

---

## The Remaining Issue

**User Report**: "For Continuous Support strategy, I see all Scenario B even though Communication has values 3,4,6"

**Expected**: Scenario A
**Showing**: Scenario B (according to user)

**Hypothesis**: Frontend display issue, not algorithm bug

### Possible Causes

1. **UI Rendering Issue**
   - Frontend showing wrong strategy's data
   - Competency cards not properly linked to their parent strategy
   - Strategy tabs/sections mixing up data

2. **Frontend Scenario Derivation**
   - `CompetencyCard.vue:257-263` has fallback `deriveScenario()` function
   - Still only checks gap, doesn't use the API's `scenario` field
   - May override correct backend values

3. **API Response Mapping**
   - Frontend may not be correctly parsing multi-strategy responses
   - May be duplicating Strategy 34's data for Strategy 35

---

## Next Session Action Plan

### Phase 1: Verify Frontend Display (30 min)

1. **Check API Response Structure**
   ```bash
   curl -s http://localhost:5000/api/phase2/learning-objectives/29 | \
     python -m json.tool > api_response.json
   ```
   - Verify Strategy 35 section has correct scenarios
   - Check if both strategies are properly separated

2. **Inspect Frontend Component Hierarchy**
   - `LearningObjectivesView.vue` → How does it loop through strategies?
   - `CompetencyCard.vue` → Is it using `props.competency.scenario`?
   - Check if strategy separation is maintained in rendering

3. **Browser DevTools Inspection**
   - Open Vue DevTools
   - Check if Strategy 35's competencies have correct `scenario` values
   - Verify no data mixing between strategies

### Phase 2: Comprehensive Algorithm Review (60 min)

**Even though the algorithm appears correct, we need architectural review:**

1. **Test All Scenario Combinations**
   ```python
   test_cases = [
       # (current, target, role, expected_scenario, expected_gap)
       (0, 1, 6, 'A', 1),      # Normal training
       (3, 1, 6, 'B', 3),      # Strategy insufficient
       (5, 6, 4, 'C', 0),      # Over-training
       (6, 5, 5, 'D', 0),      # All targets met
       (3, 4, 6, 'A', 1),      # Normal training
       (4, 4, 6, 'B', 2),      # Strategy met, role not met
       (6, 6, 6, 'D', 0),      # Exactly at all targets
   ]
   ```

2. **Multi-Strategy Interaction**
   - How does the algorithm handle 2+ strategies?
   - Should each strategy have independent classifications? (YES)
   - Are we correctly iterating per-strategy? (VERIFY)

3. **Edge Cases**
   - What if role requirement < strategy target? (Scenario C)
   - What if user scores vary wildly? (Check median calculation)
   - What if a user has multiple roles? (Already fixed - uses MAX)

### Phase 3: Documentation & Validation (30 min)

1. **Create Unit Tests**
   - Test `classify_gap_scenario()` with all combinations
   - Test gap calculation for each scenario
   - Test median calculation with various distributions

2. **Integration Test**
   - Full end-to-end test with known data
   - Verify API response matches expected values
   - Verify frontend correctly displays API data

3. **Architecture Documentation**
   - Document the 3-way comparison logic clearly
   - Document per-strategy vs organizational-level scenarios
   - Document individual distribution vs org recommendation

---

## Files to Review Next Session

### Backend
- `src/backend/app/services/role_based_pathway_fixed.py`
  - Lines 200-228: `classify_gap_scenario()` function
  - Lines 1052-1090: Gap calculation logic
  - Lines 1123-1167: Trainable competency output construction

### Frontend
- `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue`
  - How are strategies looped?
  - How are competencies assigned to strategies?

- `src/frontend/src/components/phase2/task3/CompetencyCard.vue`
  - Lines 217-263: Scenario computation and display
  - Line 242: `scenarioTitle` computed property
  - Line 257: `deriveScenario()` fallback function

### Diagnostic Tools
- `diagnose_scenario_logic.py` - Run this to verify backend logic
- `api_response.json` - Save full API response for inspection

---

## Key Questions for Next Session

1. **Is the frontend correctly parsing multi-strategy responses?**
2. **Is CompetencyCard using the API's `scenario` field or deriving it?**
3. **Are strategy sections properly isolated in the UI?**
4. **Should we remove the `deriveScenario()` fallback function entirely?**

---

## Testing Commands

**Run Diagnostic**:
```bash
cd src/backend
export PYTHONPATH=.
../../venv/Scripts/python.exe diagnose_scenario_logic.py
```

**Check API Response**:
```bash
curl -s http://localhost:5000/api/phase2/learning-objectives/29 | \
  python -m json.tool | grep -A30 "Continuous Support"
```

**Restart Backend**:
```bash
cd src/backend
taskkill //F //IM python.exe
PYTHONPATH=src/backend ../../venv/Scripts/python.exe run.py
```

---

## Success Criteria

✅ Strategy 34 shows Scenario B for Communication (3,1,6)
✅ Strategy 35 shows Scenario A for Communication (3,4,6)
✅ Gap values are correct for each scenario
✅ All 16 competencies classified correctly across both strategies
✅ Unit tests pass for all scenario combinations
✅ Architecture is clean, not band-aided

---

**Note**: Today's fixes were **band-aids on top of band-aids**. Next session must focus on **architectural validation** to ensure the entire system is sound, not just patched.
