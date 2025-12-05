# Level 3 and 5 Data Mismatch - Root Cause Analysis

**Date:** 2025-11-15
**Status:** CRITICAL - Data Model Inconsistency Identified

## Executive Summary

A critical data model inconsistency has been discovered where the role-competency matrix calculation produces **level 3** values, but the learning objectives templates only support levels **0, 1, 2, 4, 6** (skipping 3 and 5).

**Database counts:**
- **18 entries** in `role_competency_matrix` with value 3
- **160 entries** in `unknown_role_competency_matrix` with value 3
- **NO entries** with value 5 found in any competency tables
- **NO entries** with value 8 found (despite being a possible product)

## Root Cause: Inherited Logic from Derik's Implementation

### The Problem

The stored procedures `update_role_competency_matrix()` and `update_unknown_role_competency_values()` were copied from Derik's original implementation and include support for **level 3**, which conflicts with your learning objectives design.

### Evidence from Code

**File:** `src/backend/setup/database_objects/create_stored_procedures.py`
**Lines:** 62-72, 139-149

```sql
CASE
    WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
    WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1
    WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2
    WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3  -- PROBLEM
    WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4
    WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6
    ELSE -100  -- Invalid combination
END
```

**Derik's Original:** `sesurveyapp/postgres-init/init.sql` (lines 367, 412)
```sql
WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3 -- "anwenden"
```

### How Level 3 is Created

The calculation multiplies two matrices:
- `role_process_matrix.role_process_value` (values: 0, 1, 2, **3**)
- `process_competency_matrix.process_competency_value` (values: 0, 1, 2)

**Product that creates level 3:**
- **3 × 1 = 3** ← This is the source of all level 3 values

### Verified Products from Database

**Role-Process Matrix × Process-Competency Matrix:**
```
role_process | process_competency | product | current_mapping | valid_in_templates
-------------|-------------------|---------|-----------------|-------------------
     0       |        0          |    0    |       0         |       YES
     0       |        1          |    0    |       0         |       YES
     0       |        2          |    0    |       0         |       YES
     1       |        1          |    1    |       1         |       YES
     2       |        1          |    2    |       2         |       YES
     1       |        2          |    2    |       2         |       YES
     3       |        1          |    3    |       3         |       NO  <- PROBLEM
     2       |        2          |    4    |       4         |       YES
     3       |        2          |    6    |       6         |       YES
```

**Unknown-Role-Process Matrix × Process-Competency Matrix:**
```
unknown_role | process_competency | product | current_mapping | valid_in_templates
-------------|-------------------|---------|-----------------|-------------------
     0       |        0,1,2      |    0    |       0         |       YES
     1       |        1          |    1    |       1         |       YES
     1       |        2          |    2    |       2         |       YES
     2       |        1          |    2    |       2         |       YES
     2       |        2          |    4    |       4         |       YES
     4       |        1          |    4    |       4         |       YES
     4       |        2          |    8    |      -100       |       NO  <- Maps to invalid
```

## Competency Level Design Differences

### Your Learning Objectives Template Levels
**Valid levels:** 0, 1, 2, 4, 6

**Mapping:**
- **Level 0:** No competency required / Not relevant
- **Level 1:** Kennen (Know/Awareness)
- **Level 2:** Verstehen (Understand)
- **Level 4:** Anwenden (Apply) ← Note: skips 3
- **Level 6:** Beherrschen (Master) ← Note: skips 5

### Derik's Original Design
**Valid levels:** 0, 1, 2, 3, 4, 6

**His mapping** (from init.sql comments):
- **Level 0:** nicht relevant (not relevant)
- **Level 1:** kennen (know)
- **Level 2:** verstehen (understand)
- **Level 3:** anwenden (apply) ← Conflicting with level 4
- **Level 4:** anwenden (apply) ← Both 3 and 4 map to "apply"
- **Level 6:** beherrschen (master)

### Competency Indicators Table
Your `competency_indicators` table has **4 levels** (1, 2, 3, 4), suggesting an original 4-level design:
- Level 1: Know/Awareness
- Level 2: Understand
- Level 3: Apply
- Level 4: Master

This was later converted to a scoring system (1, 2, 4, 6) for the matrices, but level 3 was retained in the calculation logic.

## Value 3 and 5 - FOUND in Survey Responses!

**Investigation results:**

From `user_se_competency_survey_results` table:
```
Score 0: 187 responses
Score 1: 102 responses
Score 2: 194 responses
Score 3: 262 responses  <- FOUND!
Score 4: 254 responses
Score 5: 46 responses   <- FOUND!
Score 6: 171 responses
```

**Root Cause: Survey Answer Options Include All Values 0-6**

Your current competency assessment survey allows users to select scores **0, 1, 2, 3, 4, 5, 6**, but your learning objectives templates only support levels **0, 1, 2, 4, 6**.

**Comparison with Derik's Design:**

Derik's original survey (sesurveyapp/frontend/src/components/CompetencySurvey.vue):
- Users select competency indicator **groups** (1, 2, 3, 4, or "none")
- Groups map to scores: `1→1, 2→2, 3→4, 4→6, else→0`
- **NEVER produces scores 3 or 5**

Your current system appears to use a **direct 0-6 scale** for survey responses, which creates the mismatch.

## TWO SEPARATE PROBLEMS REQUIRING TWO SEPARATE SOLUTIONS

### Problem 1: Role-Competency Matrix Calculation
**Location:** Stored procedures calculate value 3 from multiplication
**Affected tables:** `role_competency_matrix` (18 rows), `unknown_role_competency_matrix` (160 rows)

### Problem 2: Survey Answer Options
**Location:** Competency assessment survey allows direct input of scores 0-6
**Affected table:** `user_se_competency_survey_results` (262 rows with score 3, 46 rows with score 5)

---

## Solutions

### SOLUTION FOR PROBLEM 1: Map Level 3 to Level 4 in Stored Procedures (Recommended)

**Rationale:** Level 3 represents "apply" competency, which should map to your level 4 (Anwenden).

**Changes needed:**

**File:** `src/backend/setup/database_objects/create_stored_procedures.py`

**In procedure `update_role_competency_matrix` (line 67):**
```sql
-- BEFORE
WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3

-- AFTER
WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 4
```

**In procedure `update_unknown_role_competency_values` (line 143):**
```sql
-- BEFORE
WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 3

-- AFTER
WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 4
```

**Then migrate existing data:**
```sql
-- Update role_competency_matrix
UPDATE role_competency_matrix SET role_competency_value = 4 WHERE role_competency_value = 3;

-- Update unknown_role_competency_matrix
UPDATE unknown_role_competency_matrix SET role_competency_value = 4 WHERE role_competency_value = 3;

-- Verify counts
SELECT COUNT(*) FROM role_competency_matrix WHERE role_competency_value = 3;  -- Should be 0
SELECT COUNT(*) FROM unknown_role_competency_matrix WHERE role_competency_value = 3;  -- Should be 0
```

### SOLUTION FOR PROBLEM 2: Restrict Survey Answer Options

**Option A: Use Derik's Group-Based Survey (Recommended)**

Modify the competency assessment survey to match Derik's design:
- Users select competency indicator **groups** (not direct scores)
- Map groups to scores: `1→1, 2→2, 3→4, 4→6, 0→0`
- **Eliminates scores 3 and 5 automatically**

**Changes needed:**
1. Update frontend survey component to use group selection
2. Map group selections to valid scores (0, 1, 2, 4, 6)
3. Migrate existing survey responses (map 3→4, 5→6)

**Option B: Restrict Direct Score Input**

If keeping direct numeric input, restrict allowed values:
- Frontend validation: Only allow 0, 1, 2, 4, 6
- Backend validation: Reject scores 3 and 5
- Migrate existing data

**Migration for existing survey data:**
```sql
-- Map score 3 to 4 (apply level)
UPDATE user_se_competency_survey_results SET score = 4 WHERE score = 3;

-- Map score 5 to 6 (master level)
UPDATE user_se_competency_survey_results SET score = 6 WHERE score = 5;

-- Verify migration
SELECT COUNT(*) as count, score FROM user_se_competency_survey_results GROUP BY score ORDER BY score;
-- Should only show: 0, 1, 2, 4, 6
```

---

### ALTERNATIVE: Add Learning Objectives for Level 3 and 5 (NOT Recommended)

**Rationale:** Support Derik's original 6-level design by creating templates for levels 3 and 5.

**Changes needed:**
1. Add learning objectives templates for level 3 and 5 in `config/learning_objectives_config.json`
2. Update frontend validation to accept levels 3 and 5
3. Create competency indicators for these levels

**This is NOT recommended** because:
- More complex to maintain
- Your design intentionally uses a 5-level system (0, 1, 2, 4, 6)
- Would require significant rework of existing templates

### ALTERNATIVE: Eliminate Level 3 from Role-Process Matrix (NOT Recommended)

**Rationale:** Prevent level 3 from ever being created by changing the source data.

**Changes needed:**
1. Update all `role_process_value = 3` to `role_process_value = 2` in `role_process_matrix`
2. This would change the semantics of role involvement, which may not be desirable

**This is NOT recommended** because:
- Changes the meaning of role involvement levels
- May not accurately represent the role requirements
- Better to fix at the calculation/mapping layer (Option 1)

## Recommended Action Plan

### Phase 1: Fix Stored Procedures (Problem 1)

1. **Update stored procedures** to map level 3 → level 4
   - File: `src/backend/setup/database_objects/create_stored_procedures.py`
   - Change lines 67 and 143: `WHEN ... = 3 THEN 3` → `WHEN ... = 3 THEN 4`

2. **Migrate existing matrix data**
   ```sql
   UPDATE role_competency_matrix SET role_competency_value = 4 WHERE role_competency_value = 3;
   UPDATE unknown_role_competency_matrix SET role_competency_value = 4 WHERE role_competency_value = 3;
   ```

3. **Recreate stored procedures** in database
   ```bash
   cd src/backend/setup/database_objects
   python create_stored_procedures.py
   ```

4. **Recalculate matrices** for test organizations
   ```sql
   CALL update_role_competency_matrix(28);
   CALL update_role_competency_matrix(29);
   ```

### Phase 2: Fix Survey Answer Options (Problem 2)

**Recommended: Implement Derik's group-based survey**

1. **Update frontend survey component**
   - Modify to show competency indicator groups (not direct scores)
   - Map selections: Group 1→1, 2→2, 3→4, 4→6

2. **Migrate existing survey responses**
   ```sql
   UPDATE user_se_competency_survey_results SET score = 4 WHERE score = 3;  -- 262 rows
   UPDATE user_se_competency_survey_results SET score = 6 WHERE score = 5;  -- 46 rows
   ```

3. **Add validation** to prevent scores 3 and 5 in future
   - Frontend: Validate before submission
   - Backend: Reject invalid scores in API

### Phase 3: Validation and Testing

1. **Verify no invalid values remain**
   ```sql
   -- Should return 0 rows
   SELECT COUNT(*) FROM role_competency_matrix WHERE role_competency_value = 3;
   SELECT COUNT(*) FROM unknown_role_competency_matrix WHERE role_competency_value = 3;
   SELECT COUNT(*) FROM user_se_competency_survey_results WHERE score IN (3, 5);
   ```

2. **Test learning objectives generation**
   - Verify all competencies generate objectives correctly
   - Check that scores 0, 1, 2, 4, 6 map to correct templates

3. **Update documentation**
   - Schema documentation: Clarify 5-level design (0, 1, 2, 4, 6)
   - API documentation: Document valid score values

## Database Constraint Update Needed

**File:** `src/backend/setup/database_objects/create_role_competency_matrix.py` (line 29)

**Current constraint:**
```sql
CHECK (role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 3, 4, 6]))
```

**After implementing Option 1:**
```sql
CHECK (role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 4, 6]))
```

This constraint should be updated to prevent level 3 from being inserted in the future.

## Files to Modify

### Backend
1. `src/backend/setup/database_objects/create_stored_procedures.py` (lines 67, 143)
2. `src/backend/setup/database_objects/create_role_competency_matrix.py` (line 29 - constraint)
3. Database migration script to update existing data
4. Backend API validation (survey submission endpoint)

### Frontend
5. Survey component (implement group-based selection like Derik's)
6. Survey validation logic (restrict to valid scores)

## Impact Assessment

### Problem 1: Matrix Calculation
**Tables affected:**
- `role_competency_matrix` (18 rows will change from 3 → 4)
- `unknown_role_competency_matrix` (160 rows will change from 3 → 4)

### Problem 2: Survey Responses
**Tables affected:**
- `user_se_competency_survey_results` (262 rows with score 3 → 4, 46 rows with score 5 → 6)

**No impact on:**
- `process_competency_matrix` (no level 3 or 5 values)
- `strategy_template_competency` (no level 3 or 5 values)
- `competency_indicators` (levels 1, 2, 3, 4 as strings are valid in that context)

**Downstream effects:**
- **308 user assessments** will have their scores adjusted (262 + 46)
- Learning plans may need to be regenerated for affected users
- Gap calculations may change slightly (score 3→4, score 5→6)

## Next Steps

1. User to confirm: Where were "level 5" values observed?
2. User to approve: Option 1 (map 3 → 4) as the solution
3. Implement: Code changes and data migration
4. Test: Verify all learning objectives generate correctly
5. Deploy: Roll out to production database
