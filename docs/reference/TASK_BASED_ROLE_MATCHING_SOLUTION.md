# Task-Based Role Matching - Complete Solution Documentation

**Date**: 2025-10-21
**Status**: IMPLEMENTATION IN PROGRESS
**Approach**: Option A - Derik's Exact Method (Competency Vectors + Distance Metrics)

---

## Problem Summary

### Initial Issue
Phase 1 task-based role identification was suggesting **incorrect roles** (e.g., "Customer Representative" for Software Developer profile).

### Root Cause Analysis

**Two separate issues identified:**

#### 1. LLM Pipeline Status (RESOLVED ✅)
- **Status**: FULLY FUNCTIONAL
- The LLM pipeline for task→process mapping works perfectly
- Uses OpenAI GPT-4o-mini with correct API configuration
- No fallback to keyword matching

#### 2. Role Matching Algorithm (FIXING IN PROGRESS 🔧)
- **Problem**: Process-based scoring with bias toward broad roles
- **Example**: Customer Representative (16 processes) scored 55/170 (32%)
- **Example**: Specialist Developer (9 processes) scored 30/120 (25%) ← Should be #1!
- **Cause**: Algorithm sorted by absolute score, not match quality
- **Impact**: Roles with broader involvement always scored higher

---

## Derik's Approach vs. Our Old Approach

### Our Old Approach (FLAWED)
```
Tasks → [LLM] → ISO Processes → [Scoring] → Role Suggestion
                                   ↑
                              PROBLEM HERE
```

**Scoring Algorithm**: Direct process-to-role matching
- Compare user processes vs role processes
- Give points for matches
- **Flaw**: Broad roles get more opportunities to score points

### Derik's Approach (CORRECT)
```
Tasks → [LLM] → ISO Processes → Process-Competency Matrix → Competency Vector → [Distance Metrics] → Role
```

**Key Differences:**
1. **Step 1**: Store in `UnknownRoleProcessMatrix` (ALL 28 processes with involvement values)
2. **Step 2**: Call stored procedure `update_unknown_role_competency_values` to calculate competency requirements
3. **Step 3**: Use competency vectors with **distance metrics** (Euclidean, Manhattan, Cosine)
4. **Result**: More accurate matching based on competency similarity

---

## Implementation Steps Completed

### ✅ Task 1: Create Missing Stored Procedure
**File**: `src/backend/create_stored_procedures.py`

Added `update_unknown_role_competency_values`:
- Deletes existing competency entries for user
- Calculates competencies from process involvement
  Formula: `role_competency_value = role_process_value × process_competency_value`
- Inserts calculated values into `unknown_role_competency_matrix`

**Result**: 4 stored procedures now available
1. `insert_new_org_default_role_process_matrix`
2. `update_role_competency_matrix`
3. `insert_new_org_default_role_competency_matrix`
4. **`update_unknown_role_competency_values`** ← NEW

### ✅ Task 2: Copy Derik's Distance-Based Matching
**File**: `src/backend/app/most_similar_role.py`

Copied `find_most_similar_role_cluster()` function:
- Builds competency vectors for all roles
- Compares user vector vs role vectors
- Calculates 3 distance metrics:
  - Euclidean distance (primary)
  - Manhattan distance
  - Cosine distance
- Returns role(s) with minimum Euclidean distance

### ✅ Task 3: Update `/findProcesses` Endpoint
**File**: `src/backend/app/routes.py` (lines 1610-1691)

**OLD BEHAVIOR**:
```python
# Saved to PhaseQuestionnaireResponse (just for logging)
process_data = PhaseQuestionnaireResponse(...)
process_data.set_responses({'processes': processes})
```

**NEW BEHAVIOR** (Derik's approach):
```python
# 1. Delete existing entries
UnknownRoleProcessMatrix.query.filter_by(user_name=username).delete()

# 2. Insert ALL 28 ISO processes with involvement values
for process in iso_processes:
    involvement = llm_process_map.get(process_name, "Not performing")
    role_process_value = involvement_values.get(involvement, 0)
    rows_to_insert.append(UnknownRoleProcessMatrix(...))

db.session.bulk_save_objects(rows_to_insert)

# 3. Call stored procedure to calculate competencies
db.session.execute(
    text("CALL update_unknown_role_competency_values(:username, :organization_id);"),
    {"username": username, "organization_id": organization_id}
)
```

**Result**: Process involvement → Competency requirements (automatic calculation)

---

## Implementation Steps Remaining

### 🔧 Task 4: Update `/api/phase1/roles/suggest-from-processes`
**File**: `src/backend/app/routes.py` (lines ~1714-1870)

**Current (BROKEN)**: Process-based scoring
```python
# OLD: Direct process matching with scoring
for role in roles:
    role_matrix = RoleProcessMatrix.query.filter_by(role_cluster_id=role.id).all()
    score = calculate_score(user_processes, role_matrix)  # FLAWED
```

**Needed (DERIK'S WAY)**: Competency-based distance matching
```python
from app.most_similar_role import find_most_similar_role_cluster
from models import UnknownRoleCompetencyMatrix

# 1. Query user's competency requirements
competencies = UnknownRoleCompetencyMatrix.query.filter_by(
    user_name=username,
    organization_id=organization_id
).all()

# 2. Format as score list for distance calculation
user_scores = [
    {'competency_id': c.competency_id, 'score': c.role_competency_value}
    for c in competencies
]

# 3. Find most similar role using distance metrics
most_similar_role_ids = find_most_similar_role_cluster(organization_id, user_scores)

# 4. Get role details
roles = RoleCluster.query.filter(RoleCluster.id.in_(most_similar_role_ids)).all()

# 5. Return best match
return jsonify({
    'suggestedRole': {
        'id': roles[0].id,
        'name': roles[0].role_cluster_name,
        'description': roles[0].role_cluster_description
    },
    'confidence': calculate_confidence(distances),  # Based on Euclidean distance
    'alternativeRoles': [...]
})
```

### ⏳ Task 5: Test End-to-End Workflow
1. Call `/findProcesses` with software developer tasks
2. Verify `UnknownRoleProcessMatrix` populated (28 entries)
3. Verify `UnknownRoleCompetencyMatrix` populated (16 competency entries)
4. Call `/api/phase1/roles/suggest-from-processes`
5. Verify correct role suggested (e.g., "Specialist Developer" not "Customer Representative")

### ⏳ Task 6: Update SESSION_HANDOVER.md
Document complete solution and test results

---

## Expected Results After Fix

### Before Fix (Process-Based):
```
Software Developer Profile:
1. Customer Representative: 32% ❌ WRONG
2. System Engineer: 29%
3. Specialist Developer: 25%  ← Should be #1!
```

### After Fix (Competency-Based):
```
Software Developer Profile:
1. Specialist Developer: ~85% ✅ CORRECT
2. System Engineer: ~72%
3. Implementation roles: ~65%
```

---

## Technical Notes

### Why Distance Metrics Work Better

**Process-Based Scoring**:
- Binary: Does user do this process? Yes/No
- Broad roles get more chances to match
- No concept of "specialization"

**Competency-Based Distance**:
- Continuous: How much does user need each competency? (0-6 scale)
- Euclidean distance captures overall similarity
- Specialization emerges naturally (focused vs. broad competency profiles)

### Database Flow

```
┌─────────────┐
│ User Tasks  │
└──────┬──────┘
       │
       ↓ LLM Pipeline
┌─────────────────────────┐
│ ISO Process Involvement │  (5 processes identified)
└──────┬──────────────────┘
       │
       ↓ Store in DB (28 entries total)
┌──────────────────────────────┐
│ UnknownRoleProcessMatrix     │
│ - process_id=1, value=0      │
│ - process_id=2, value=0      │
│ - process_id=14, value=3 ← Designing
│ - process_id=15, value=2 ← Responsible
│ - ...                        │
└──────┬───────────────────────┘
       │
       ↓ Stored Procedure Calculation
┌──────────────────────────────┐
│ UnknownRoleCompetencyMatrix  │
│ - competency_id=1, value=2   │
│ - competency_id=2, value=4   │
│ - competency_id=3, value=6   │
│ - ...                        │
└──────┬───────────────────────┘
       │
       ↓ Distance Calculation
┌─────────────────┐
│ Suggested Role  │
└─────────────────┘
```

---

## Files Modified

1. **create_stored_procedures.py** - Added missing procedure
2. **app/most_similar_role.py** - NEW FILE (Derik's distance algorithm)
3. **app/routes.py** - Updated `/findProcesses` to use Derik's approach
4. **app/routes.py** - Need to update `/api/phase1/roles/suggest-from-processes` (NEXT)

---

## Next Session Actions

**IMMEDIATE** (5-10 min):
1. Update `/api/phase1/roles/suggest-from-processes` endpoint to use `find_most_similar_role_cluster`
2. Restart Flask (auto-reload should work, but manual restart recommended)

**TESTING** (15-20 min):
3. Test with sample software developer profile
4. Verify database entries (UnknownRoleProcessMatrix, UnknownRoleCompetencyMatrix)
5. Check role suggestion results

**DOCUMENTATION** (10 min):
6. Update SESSION_HANDOVER.md with complete solution
7. Document test results and any edge cases found

---

## References

- **Derik's Implementation**: `sesurveyapp-main/app/routes.py` (lines 1102-1222)
- **Distance Algorithm**: `sesurveyapp-main/app/most_similar_role.py`
- **Stored Procedure**: `sesurveyapp-main/postgres-init/filtered_init.sql` (lines 438-476)
