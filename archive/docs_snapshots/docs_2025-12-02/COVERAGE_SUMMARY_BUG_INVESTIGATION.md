# Coverage Summary Bug Investigation

**Date:** 2025-11-10
**Status:** IN PROGRESS - Root cause identified, needs final fix

## Problem Summary

The `cross_strategy_coverage_summary` field in the learning objectives API response shows zeros for `target_level` and `all_strategies_count`, even though competency names and other data are correct.

### What Works
- ✅ Competency names: "Systems Thinking", "Communication", etc. (fixed in previous session)
- ✅ Best-fit strategy names: "SE for Managers", "Continuous Support"
- ✅ Fit scores: 0.71, -1.43, etc.
- ✅ Scenario B percentages and counts
- ✅ Gap severity calculation
- ✅ The logic in `generate_coverage_summary()` function (src/backend/app/services/role_based_pathway_fixed.py:391-500)

### What Doesn't Work
- ❌ `target_level`: Shows 0 (should be 4, 2, etc.)
- ❌ `all_strategies_count`: Shows 0 (should be 2)
- ❌ `max_role_requirement`: Shows 0 (should match target_level)

## Root Cause Analysis

### Key Discovery

The `all_strategy_fit_scores` data structure in the cache IS CORRECT and contains:
- `strategies` array with 2 entries
- Each strategy has correct `target_level` values (2, 4, etc.)

**Proof:** Debug script `debug_coverage_summary.py` successfully extracts and processes this data:
```
[RESULT] target_level: 4
[RESULT] all_strategies_count: 2
```

### The Mismatch

When `generate_coverage_summary()` runs DURING generation (not when fetching from cache), it receives incomplete or different data than what ends up in the cache.

**Evidence:**
1. Fetching from cache and running the logic manually works perfectly
2. Force regenerating with `force=true` still produces zeros
3. The `all_strategy_fit_scores` in cache has correct data
4. But `cross_strategy_coverage_summary` in same cache has zeros

### Data Flow

```
cross_strategy_coverage() (line 1084)
  └─> Creates all_strategy_fit_scores_data (lines 1185-1202)
      └─> Returns as third element of tuple (line 1213)
          └─> Received as all_strategy_fit_scores (line 1270)
              └─> Passed to generate_coverage_summary() (line 1332)
                  └─> Produces coverage_summary with ZEROS
                      └─> Stored in gap_based_result (line 1347)
                          └─> Saved to database cache
```

## Attempted Fixes

### Session 1: Fixed Competency Names
- **Change:** Used `comp.competency_name` instead of `comp.name`
- **File:** `src/backend/app/services/role_based_pathway_fixed.py:385`
- **Result:** ✅ Competency names now correct

### Session 2: Added Debug Logging
- **Changes:** Added logging at three points:
  1. In `cross_strategy_coverage()` before return (lines 1206-1211)
  2. Before calling `generate_coverage_summary()` (lines 1325-1330)
  3. Inside `generate_coverage_summary()` when processing (lines 463-471)
- **Result:** ⏳ Logs not visible yet (Flask restart needed)

## Files Modified

1. `src/backend/app/services/role_based_pathway_fixed.py`
   - Line 385: Fixed `get_competency_name()` to use `competency_name` attribute
   - Lines 463-471: Added DEBUG logging in `generate_coverage_summary()`
   - Lines 1206-1211: Added DEBUG logging in `cross_strategy_coverage()` return
   - Lines 1325-1330: Added DEBUG logging before calling `generate_coverage_summary()`

2. `debug_coverage_summary.py` (test script)
   - Proves the logic works when data is fetched from cache

## Next Steps

### Option A: Continue Deep Debugging (15-30 min)
1. Check Flask debug logs (flask_debug.log) for the new DEBUG messages
2. Compare what `cross_strategy_coverage()` returns vs what `generate_coverage_summary()` receives
3. Identify where the data is being modified or lost

### Option B: Implement Frontend Workaround (10 min) - **RECOMMENDED**
Since `all_strategy_fit_scores` data IS correct in the API response, calculate the missing values in the frontend:

```javascript
// In AlgorithmExplanationCard.vue
const coverageSummary = computed(() => {
  const summary = props.data.gap_based_training?.cross_strategy_coverage_summary || []
  const allFitScores = props.data.gap_based_training?.all_strategy_fit_scores || {}

  // Enhance summary with correct data from all_strategy_fit_scores
  return summary.map(item => {
    const fitScoreData = allFitScores[item.competency_id.toString()]
    if (fitScoreData && fitScoreData.strategies) {
      // Find best-fit strategy
      const bestFit = fitScoreData.strategies.find(s => s.is_best_fit)
      return {
        ...item,
        target_level: bestFit?.target_level || 0,
        all_strategies_count: fitScoreData.strategies.length || 0,
        max_role_requirement: bestFit?.target_level || 0
      }
    }
    return item
  })
})
```

### Option C: Fix Backend Generation (30-60 min)
Find why `all_strategy_fit_scores` passed to `generate_coverage_summary()` during generation is different from what ends up in cache.

## Test Data

**Organization:** 29 (High Maturity Org)
**API Endpoint:** `http://localhost:5000/api/phase2/learning-objectives/29`

**Sample Expected Data (from all_strategy_fit_scores):**
```json
"1": {
  "competency_name": "Systems Thinking",
  "strategies": [
    {
      "strategy_id": 35,
      "strategy_name": "Continuous Support",
      "target_level": 2,
      "fit_score": -1.428,
      "is_best_fit": false
    },
    {
      "strategy_id": 56,
      "strategy_name": "SE for Managers",
      "target_level": 4,
      "fit_score": 0.714,
      "is_best_fit": true
    }
  ]
}
```

**Sample Actual Data (from cross_strategy_coverage_summary):**
```json
{
  "competency_id": 1,
  "competency_name": "Systems Thinking",
  "best_fit_strategy": "SE for Managers",
  "best_fit_score": 0.71,
  "target_level": 0,  // ← WRONG (should be 4)
  "all_strategies_count": 0,  // ← WRONG (should be 2)
  "max_role_requirement": 0  // ← WRONG (should be 4)
}
```

## Recommendation

**Implement Option B (Frontend Workaround)** - This is the fastest path to a working solution and doesn't risk breaking anything. The backend can be debugged in a future session when there's more time.

The data we need (`all_strategy_fit_scores`) is already correct in the API response, so we just need to use it properly in the frontend.