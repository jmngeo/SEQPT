# Competency Vector Similarity Analysis
**Date:** 2025-10-21
**Status:** COMPLETED - Data verified and fixed

## Executive Summary

Investigated why role competency vectors appeared highly similar across different roles. **Finding:** The high similarity is BY DESIGN in Derik's original system and is NOT a bug.

### Key Results
- **Our data now EXACTLY matches Derik's reference implementation** (224/224 entries, 100% match)
- Applied 11 fixes to align with Derik's exact values
- Confirmed that role similarity is intentional in the competency model design

---

## Investigation Details

### A) Competency Vector Similarity (By Design)

**High similarity examples from Derik's original data:**
- Customer vs Service Technician: **81.25% similar**
- Customer Representative vs System Engineer: **81.25% similar**
- Customer Representative vs Innovation Management: **81.25% similar**
- System Engineer vs Specialist Developer: **75.00% similar**

**Why this is normal:**
1. Most roles share common core SE competencies at similar levels
2. The competency model focuses on 16 general competencies
3. Differentiation comes from subtle differences (level 2 vs 4, presence of 0s)
4. Primary role matching uses `role_process_matrix`, not competency vectors directly

### B) Role 11 (Process and Policy Manager) Special Case

**Finding:** Role 11 has ALL 6s (mastery level) for ALL 16 competencies

```
Vector: [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]
```

**Why:** Process and Policy Managers need mastery in all SE areas to:
- Define organizational processes
- Create policies across all SE domains
- Oversee all competency areas

**This is identical in both our system and Derik's.**

### C) Database Structure Verified

**Competencies in database:** 16 total (IDs: 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)
- **Missing:** Competencies 2 and 3 (not used in Derik's system either)

**Total entries:** 224 (14 roles × 16 competencies)

**Value distribution:**
- **48.66%** = Level 2 (understanding)
- **31.70%** = Level 4 (application)
- **7.14%** = Level 6 (mastery) - mostly Role 11
- **7.14%** = Level 1 (awareness)
- **5.36%** = Level 0 (not required)

---

## Fixes Applied

### 11 Discrepancies Corrected

Fixed competency values for 3 roles to match Derik's exact values:

#### 1. Role 5 (Specialist Developer) - 5 fixes
- Competency 1: 4 → 2
- Competency 7: 4 → 2
- Competency 14: 4 → 2
- Competency 15: 2 → 4
- Competency 17: 0 → 1

#### 2. Role 9 (Verification and Validation Operator) - 4 fixes
- Competency 1: 2 → 4
- Competency 10: 1 → 4
- Competency 14: 2 → 4
- Competency 15: 4 → 2

#### 3. Role 10 (Service Technician) - 2 fixes
- Competency 14: 1 → 2
- Competency 17: 2 → 4

**Verification:** All fixes applied and verified successfully.

---

## Example Role Vectors (After Fixes)

### Specialist Developer (Role 5)
```
Value distribution: {1: 1, 2: 9, 4: 6}
Vector: [2, 4, 4, 4, 2, 2, 4, 2, 2, 2, 2, 2, 4, 2, 1, 4]
```

### V&V Operator (Role 9)
```
Value distribution: {2: 7, 4: 9}
Vector: [4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 2, 4, 2, 4, 2, 4]
```

### Service Technician (Role 10)
```
Value distribution: {0: 5, 2: 9, 4: 2}
Vector: [2, 2, 2, 2, 4, 0, 2, 0, 0, 2, 2, 2, 0, 0, 4, 2]
```

---

## Implications for Role Matching

### Why Competency Vectors Have High Similarity

1. **Competency model is general-purpose**
   - 16 broad SE competencies cover all roles
   - Most roles need similar foundational competencies
   - Differentiation is subtle (level 2 vs 4)

2. **Process involvement is more distinctive**
   - `role_process_matrix` has 28 processes with 4 involvement levels
   - Provides 28-dimensional vector vs 16-dimensional competency vector
   - Process patterns are more role-specific

3. **Derik's architecture uses process-first matching**
   - Primary matching: `role_process_matrix` (role × process involvement)
   - Secondary calculation: `role_competency_matrix` = `role_process_matrix` × `process_competency_matrix`
   - Competencies are derived, not used directly for matching

### Recommendations

**Current approach is correct:**
- Use `role_process_matrix` for role matching (already implemented)
- Use `role_competency_matrix` for gap analysis after role is identified
- Weight process involvement patterns heavily in scoring algorithm

**This matches Derik's proven design.**

---

## Files Created During Investigation

1. `analyze_competency_vectors.py` - Analyzes our role competency vectors
2. `compare_with_derik.py` - Compares our data with Derik's init.sql
3. `analyze_derik_vectors.py` - Analyzes Derik's role competency vectors
4. `apply_role_competency_fixes.py` - Applies the 11 fixes to match Derik
5. `fix_role_competency_discrepancies.py` - Interactive version of fixer

---

## Conclusion

**Status:** RESOLVED

- High competency vector similarity is EXPECTED and BY DESIGN
- Our data now exactly matches Derik's reference implementation
- Process-based role matching (current approach) is the correct strategy
- Competency vectors are primarily for gap analysis, not role matching

**No further action required on competency vector similarity.**

---

*Analysis completed: 2025-10-21*
*Verified against: sesurveyapp-main/postgres-init/init.sql*
