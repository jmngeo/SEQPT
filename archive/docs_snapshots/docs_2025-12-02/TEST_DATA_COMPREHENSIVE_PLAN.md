# Comprehensive Test Data Plan - 8-Step Algorithm Validation

**Date**: November 6, 2025
**Purpose**: Complete test coverage for Role-Based Learning Objectives Algorithm
**Reference**: `ALGORITHM_8_STEP_DEEP_DIVE.md`, `LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

---

## Test Strategy Overview

Create 4 specialized test organizations, each targeting specific algorithm steps:

| Test Org | ID | Focus | Tests Steps | Key Validation |
|----------|----|----|-------------|----------------|
| Multi-Role Users | 30 | Unique user counting | Step 3 | No double-counting |
| All Scenarios | 31 | Scenario classification | Step 2 | All 4 scenarios present |
| Best-Fit Strategy | 32 | Strategy selection | Step 4 | Correct best-fit picked |
| Validation Edge Cases | 33 | Validation layer | Step 5-7 | Correct recommendations |

---

## Test Org 30: Multi-Role User Counting

**File**: `create_test_org_30_multirole.py` ✅ CREATED

**PURPOSE**: Validate Step 3 correctly counts unique users

**Setup**:
- 10 users total
- 3 roles: Architect (6), Developer (4), Tester (4)
- 5 single-role users
- 5 multi-role users (including 1 with all 3 roles)
- 2 strategies: "Common Basic" (target=1), "Continuous Support" (target=4)

**Expected Results**:
```
Communication Competency:
- Strategy 34:
  - Scenario B: ALL 10 users (current > target=1, but < role=6)
  - Total: 10 (not 15!)

- Strategy 35:
  - Scenario A: 6 users (scores 0-3, need to reach 4)
  - Scenario B: 2 users (score 4, met target but < role 6)
  - Scenario D: 2 users (score 5+, met both)
  - Total: 10 (not 15!)
```

**Validation Commands**:
```bash
# Run script
python create_test_org_30_multirole.py

# Test API
curl http://localhost:5000/api/phase2/learning-objectives/30 | python -m json.tool

# Verify user counts
echo "Should see exactly 10 users total, not double-counted"
```

---

## Test Org 31: All Scenario Combinations

**PURPOSE**: Validate Step 2 correctly classifies all 4 scenarios

**Setup**:
- 12 users across 3 roles
- 2 strategies with carefully chosen targets
- Design scores to trigger ALL scenarios for Communication:

| User | Role | Current Score | Strategy A Target | Strategy B Target | Role Req | Expected Scenario A | Expected Scenario B |
|------|------|---------------|-------------------|-------------------|----------|---------------------|---------------------|
| User1 | Architect | 1 | 2 | 6 | 6 | **A** (1<2≤6) | **A** (1<6≤6) |
| User2-4 | Developer | 3 | 2 | 4 | 4 | **B** (2≤3<4) | **A** (3<4≤4) |
| User5-7 | Tester | 4 | 2 | 6 | 4 | **D** (4≥2, 4≥4) | **C** (6>4) |
| User8-10 | Architect | 2 | 4 | 6 | 4 | **A** (2<4≤4) | **A** (2<6≤4) |
| User11-12 | Developer | 6 | 2 | 4 | 6 | **D** (6≥2, 6≥6) | **D** (6≥4, 6≥6) |

**Expected Results**:
- Strategy A should have: A=4, B=3, C=0, D=5
- Strategy B should have: A=7, B=0, C=3, D=2
- All 4 scenarios represented in at least one strategy
- No "Unknown" or null scenarios

**Creation Script**:
```python
# create_test_org_31_all_scenarios.py
# Uses test data from table above
# Sets specific role requirements and strategy targets to trigger each scenario
```

---

## Test Org 32: Best-Fit Strategy Selection

**PURPOSE**: Validate Step 4 selects correct best-fit strategy using fit scores

**Setup**:
- 15 users in 2 roles (Manager=4, Engineer=6)
- 3 strategies with different fit profiles:
  - **Strategy A**: Target=2 (too low for Engineer role)
  - **Strategy B**: Target=4 (perfect fit)
  - **Strategy C**: Target=6 (over-training for Manager role)

**User Distribution Design**:
```
Communication Competency:
Current Levels: [2,2,3,3,3,3,4,4,4,4,5,5,5,6,6]

For Strategy A (target=2):
- Scenario A: 1 (current 2) - fit: +1.0
- Scenario B: 13 (current 3-6, target met but role 4-6 not met) - fit: -2.0 each = -26.0
- Scenario D: 1 (current 2, role 2) - fit: +1.0
- FIT SCORE: 1 + (-26) + 1 = -24.0 (BAD)

For Strategy B (target=4):
- Scenario A: 9 (current 2-3, need to reach 4) - fit: +1.0 each = +9.0
- Scenario B: 0 - fit: 0
- Scenario D: 6 (current 4+, role 4-6) - fit: +1.0 each = +6.0
- FIT SCORE: 9 + 0 + 6 = +15.0 (BEST!)

For Strategy C (target=6):
- Scenario A: 13 (current 2-5, need to reach 6) - fit: +1.0 each = +13.0
- Scenario C: 2 (target 6 > role 4 for Managers) - fit: -0.5 each = -1.0
- Scenario D: 0 - fit: 0
- FIT SCORE: 13 + (-1) + 0 = +12.0 (GOOD but not best)
```

**Expected Results**:
- best_fit_strategy: "Strategy B"
- best_fit_score: +15.0
- all_strategy_fit_scores shows Strategy A with negative score
- Strategy C flagged for potential over-training

---

## Test Org 33: Validation Edge Cases

**PURPOSE**: Validate Steps 5-7 correctly identify inadequate strategies and make recommendations

**Setup**:
- 20 users in 3 roles
- 2 strategies selected that are INSUFFICIENT for multiple competencies
- Design for Scenario B > 40% in 5+ competencies

**Design Goals**:
```
Selected Strategies:
- "Common Basic Understanding" (targets all at level 1-2)
- "SE for Managers" (targets at level 2-4)

Role Requirements:
- Senior Engineer: Many competencies at level 6
- Lead Architect: Many competencies at level 6

Current Levels:
- Most users at level 3-4 (met strategy targets, but not role requirements)

Expected Scenario B Distribution:
- 10+ competencies with >40% users in Scenario B
- Critical gaps in: System Architecting, Integration, Verification
```

**Expected Validation Results**:
```json
{
  "strategy_validation": {
    "status": "INADEQUATE",
    "severity": "high",
    "strategies_adequate": false,
    "requires_strategy_revision": true,
    "recommendation_level": "ADD_STRATEGY",
    "competency_breakdown": {
      "critical_gaps": [8, 9, 10],  // System Arch, Integration, Verification
      "significant_gaps": [11, 13, 15],
      "minor_gaps": [2, 3]
    }
  },
  "strategic_decisions": {
    "overall_action": "REVISE_STRATEGY_SELECTION",
    "suggested_strategy_additions": [
      "Needs-based project-oriented training"
    ]
  }
}
```

---

## Running All Tests

### Creation Sequence

```bash
# 1. Multi-role user counting
python create_test_org_30_multirole.py
# Validates: unique user counting with sets

# 2. All scenarios
python create_test_org_31_all_scenarios.py
# Validates: 3-way comparison logic for all 4 scenarios

# 3. Best-fit strategy
python create_test_org_32_bestfit.py
# Validates: fit score calculation and strategy selection

# 4. Validation edge cases
python create_test_org_33_validation.py
# Validates: validation thresholds and recommendations
```

### Validation Sequence

```bash
# Test Org 30 - User Counting
curl -s http://localhost:5000/api/phase2/learning-objectives/30 | \
  python -m json.tool > test_org_30_result.json
# CHECK: All user counts = 10 (not more)

# Test Org 31 - All Scenarios
curl -s http://localhost:5000/api/phase2/learning-objectives/31 | \
  python -m json.tool > test_org_31_result.json
# CHECK: All 4 scenarios present (A, B, C, D)

# Test Org 32 - Best Fit
curl -s http://localhost:5000/api/phase2/learning-objectives/32 | \
  python -m json.tool > test_org_32_result.json
# CHECK: best_fit_strategy = "Strategy B", fit_score positive

# Test Org 33 - Validation
curl -s http://localhost:5000/api/phase2/learning-objectives/33 | \
  python -m json.tool > test_org_33_result.json
# CHECK: status = "INADEQUATE", suggested_strategy_additions exists
```

---

## Success Criteria Matrix

| Test | Criterion | Pass/Fail |
|------|-----------|-----------|
| **Org 30** | Total users = 10 in all scenario counts | ⏳ |
| **Org 30** | No user ID appears twice in same scenario | ⏳ |
| **Org 30** | Multi-role users counted once | ⏳ |
| **Org 31** | All 4 scenarios present | ⏳ |
| **Org 31** | Scenario A classification correct | ⏳ |
| **Org 31** | Scenario B classification correct | ⏳ |
| **Org 31** | Scenario C classification correct | ⏳ |
| **Org 31** | Scenario D classification correct | ⏳ |
| **Org 32** | Best-fit strategy = Strategy B | ⏳ |
| **Org 32** | Fit scores calculated correctly | ⏳ |
| **Org 32** | Strategy A has negative fit score | ⏳ |
| **Org 32** | Strategy C flagged for over-training | ⏳ |
| **Org 33** | Validation status = INADEQUATE | ⏳ |
| **Org 33** | Requires strategy revision = true | ⏳ |
| **Org 33** | Suggested strategies provided | ⏳ |
| **Org 33** | Critical gaps identified | ⏳ |

---

## Next Steps

1. ✅ Create Org 30 script (DONE)
2. ⏳ Create Org 31-33 scripts
3. ⏳ Run all creation scripts
4. ⏳ Execute validation tests
5. ⏳ Fix identified bugs
6. ⏳ Re-run tests until all pass
7. ⏳ Document final results

---

**Status**: Test Org 30 created, others pending
**Files Created**: 1/4 test data scripts
**Next**: Create remaining 3 test organizations
