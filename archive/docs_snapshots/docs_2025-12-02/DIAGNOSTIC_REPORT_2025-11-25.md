# Diagnostic Report - Phase 2 Task 3 Implementation
**Date:** 2025-11-25
**Session:** Week 1 Bug Fixes and Test Data Setup

---

## Executive Summary

**Status:** 🟡 Minor issues found, ready to fix

**Key Findings:**
1. ✅ Core algorithms implemented correctly (Algorithms 1-3)
2. ⚠️ Database schema mismatch (column naming)
3. ⚠️ Test organization setup incorrect (org 30 has roles, should have none)
4. ✅ Test data exists with proper competency scores
5. ⚠️ Hardcoded competency count (assumes 16, database has 18)

---

## Detailed Findings

### 1. Database Schema Issues

#### Issue 1.1: RoleCompetencyMatrix Column Name Mismatch
**Severity:** HIGH
**Impact:** Code will fail when querying role competency requirements

**Problem:**
- **Code expects:** `role_id`
- **Actual column:** `role_cluster_id`
- **Location:** `src/backend/app/services/learning_objectives_core.py:430`
- **Function:** `get_role_competency_requirement()`

**Database Schema:**
```sql
Table "public.role_competency_matrix"
- id (PK)
- role_cluster_id (FK -> organization_roles.id)  ← Actual column name
- competency_id (FK -> competency.id)
- role_competency_value (integer)
- organization_id (FK -> organization.id)
```

**Fix Required:**
```python
# Current (WRONG):
role_req = RoleCompetencyMatrix.query.filter_by(
    role_id=role_cluster_id,  # ← Wrong column name
    competency_id=competency_id
).first()

# Corrected:
role_req = RoleCompetencyMatrix.query.filter_by(
    role_cluster_id=role_cluster_id,  # ← Correct column name
    competency_id=competency_id
).first()
```

---

### 2. Test Organization Setup

#### Current State:

**Org 28: "High Maturity - Role-Based" ✅**
- ✅ Has 3 roles defined:
  - Systems Engineer (ID 318)
  - Requirements Engineer (ID 319)
  - Project Manager (ID 320)
- ✅ Has 8 users assigned to roles (user IDs 47-54)
- ✅ Has competency scores with variation (scores: 4-6)
- ✅ **Suitable for high-maturity role-based pathway testing**

**Org 29: "High Maturity - Different Scenario" ⚠️**
- ✅ Has 4 roles defined:
  - Site Reliability Engineer (SRE) (ID 438)
  - Infrastructure Automation Engineer (ID 439)
  - Platform Engineer (ID 440)
  - Cloud Solutions Architect (ID 441)
- ⚠️ **Status Unknown:** Need to verify if users are assigned and have scores
- 🔍 **Action Required:** Verify test data completeness

**Org 30: "Low Maturity - Organizational" ❌**
- ❌ **INCORRECT SETUP:** Currently has 8 roles defined (IDs 306-314)
  - Tempest customer
  - Tempest Manager 1/2
  - Tempest SE 1/2
  - Random dudes 0/2
  - Dum Support
- ❌ For low-maturity testing, org should have **ZERO roles**
- ❌ Users should NOT be assigned to roles (organizational pathway)

**Recommendation:**
- **Option A (Preferred):** Create new **Org 31** for low-maturity testing
  - Zero roles defined
  - Users exist but are NOT assigned to organization_roles
  - Competency scores exist for gap detection
  - Keep org 30 as-is (don't break existing data)

- **Option B:** Delete all roles from org 30 (risky, might break existing workflows)

---

### 3. Competency ID Range

#### Issue 3.1: Hardcoded Competency Count
**Severity:** MEDIUM
**Impact:** Extra competencies (17-18) not processed

**Problem:**
- **Code assumes:** 16 competencies (IDs 1-16)
- **Database has:** 18 competencies (IDs 1-18)
- **Extra competencies:**
  - ID 17: "Operation and Support"
  - ID 18: "Agile Methods"

**Current Code:**
```python
# Hardcoded in learning_objectives_core.py
ALL_16_COMPETENCY_IDS = list(range(1, 17))  # Only 1-16
```

**Data Distribution:**
```sql
-- Competencies found in user_se_competency_survey_results:
1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
-- Note: Missing 2, 3 (not used in current test data)
```

**Fix Required:**
```python
# Make it dynamic instead of hardcoded
def get_all_competency_ids():
    """Get all competency IDs from database"""
    return [c.id for c in Competency.query.order_by(Competency.id).all()]

# OR query from config/strategy templates
```

---

### 4. Test Data Quality Assessment

#### Org 28 User Competency Scores (Sample):

**User 47 (emp_high_performer):**
```
Competency  | Score | Assessment
------------|-------|------------
1,4,5,6,7   | 6     | At highest level
9,10,12,15  | 6     | At highest level
16,18       | 6     | At highest level
8,11,13,14  | 4     | Mid-level
17          | 4     | Mid-level
```
**Analysis:** Good variation, suitable for gap detection testing

**User 48 (emp_mid_level):**
```
All competencies (1,4-18): Score 4
```
**Analysis:** Consistent mid-level performer, good baseline

---

### 5. Table Naming Corrections

**Verified Correct Table Names:**
```
✅ organization_roles (not "roles")
✅ user_role_cluster (for user-role assignments)
✅ user_se_competency_survey_results (for competency scores)
✅ users (main user table)
✅ role_competency_matrix (role requirements)
```

**Model Name vs Table Name Mapping:**
```python
# Model                          → Table Name
UserCompetencySurveyResult       → user_se_competency_survey_results
UserRoleCluster                  → user_role_cluster
OrganizationRoles                → organization_roles
RoleCompetencyMatrix             → role_competency_matrix
```

---

## Issues to Fix (Priority Order)

### HIGH PRIORITY

**1. Fix RoleCompetencyMatrix Column Name**
- **File:** `src/backend/app/services/learning_objectives_core.py:430`
- **Change:** `role_id` → `role_cluster_id`
- **Impact:** Algorithm 2 (validate_mastery_requirements) will work correctly

**2. Create Org 31 for Low-Maturity Testing**
- **Action:** SQL script to create new organization
- **Requirements:**
  - Organization with low maturity level
  - NO roles defined in organization_roles
  - 5-10 users created
  - Users NOT assigned to user_role_cluster
  - Competency scores with gaps (mix of 0, 1, 2, 4)
- **Impact:** Enables testing of organizational pathway (Algorithm 3)

**3. Fix Hardcoded Competency IDs**
- **File:** `src/backend/app/services/learning_objectives_core.py`
- **Change:** Make competency list dynamic
- **Impact:** Handles all 18 competencies correctly

### MEDIUM PRIORITY

**4. Fix Test File App Context**
- **File:** `test_learning_objectives_week1.py:29`
- **Change:** Wrap Algorithm 1 tests in `with app.app_context():`
- **Impact:** Tests run without context errors

**5. Verify Org 29 Test Data**
- **Action:** Query database to confirm users and scores exist
- **Impact:** Ensures all 3 test orgs are properly configured

### LOW PRIORITY

**6. Handle Missing Competencies (2, 3)**
- **Observation:** Competency IDs 2, 3 not in test data
- **Action:** Either add them or document why they're excluded
- **Impact:** Completeness of test coverage

---

## Proposed Test Data Structure

### Org 28: High Maturity, Role-Based (EXISTING - KEEP)
```
Organization: "Org 28"
Maturity: High (e.g., Level 4-5)
Pathway: Role-Based
Roles:
  - Systems Engineer (3 users)
  - Requirements Engineer (3 users)
  - Project Manager (2 users)
Users: 8 total
Competency Scores: Mix of 4, 6 (has gaps)
Test Scenarios:
  - Multiple roles with different requirements
  - Users with varying competency levels
  - Gap detection across roles
```

### Org 29: High Maturity, Role-Based Variant (EXISTING - VERIFY)
```
Organization: "Org 29"
Maturity: High
Pathway: Role-Based
Roles:
  - SRE (users TBD)
  - Infrastructure Engineer (users TBD)
  - Platform Engineer (users TBD)
  - Cloud Architect (users TBD)
Users: TBD
Competency Scores: TBD
Test Scenarios:
  - Different role set from Org 28
  - Validate role-based pathway works with different roles
```

### Org 31: Low Maturity, Organizational (NEW - CREATE)
```
Organization: "Org 31"
Maturity: Low (e.g., Level 1-2)
Pathway: Organizational (NO ROLES)
Roles: NONE
Users: 5-10 users (NOT assigned to roles)
Competency Scores: Mix of 0, 1, 2, 4 (significant gaps)
Test Scenarios:
  - Organizational-level gap detection
  - No role-based processing
  - Large gaps requiring foundational LOs
```

---

## Code Fixes Required

### Fix 1: Column Name in learning_objectives_core.py

**Location:** Line ~430 in `get_role_competency_requirement()`

```python
# BEFORE:
role_req = RoleCompetencyMatrix.query.filter_by(
    role_id=role_cluster_id,  # ❌ Wrong
    competency_id=competency_id
).first()

# AFTER:
role_req = RoleCompetencyMatrix.query.filter_by(
    role_cluster_id=role_cluster_id,  # ✅ Correct
    competency_id=competency_id
).first()
```

### Fix 2: Dynamic Competency Loading

**Location:** Top of `learning_objectives_core.py`

```python
# BEFORE:
ALL_16_COMPETENCY_IDS = list(range(1, 17))  # ❌ Hardcoded

# AFTER:
def get_all_competency_ids(organization_id):
    """
    Get all competency IDs relevant for this organization.
    Dynamically loads from database based on strategies/requirements.
    """
    # Option A: Get from all competencies
    return [c.id for c in Competency.query.order_by(Competency.id).all()]

    # Option B: Get from organization's strategies only
    # (More efficient, only processes competencies in use)
```

### Fix 3: Test App Context Wrapper

**Location:** `test_learning_objectives_week1.py`

```python
# BEFORE:
def test_algorithm_1_basic():
    result = calculate_combined_targets(...)  # ❌ No app context

# AFTER:
def test_algorithm_1_basic():
    with app.app_context():  # ✅ Wrapped
        result = calculate_combined_targets(...)
```

---

## SQL Script for Org 31 Setup

**To be created:** `setup_org_31_low_maturity_test.sql`

```sql
-- Create Organization 31 for low-maturity testing
INSERT INTO organization (name, maturity_level, industry)
VALUES ('Test Org 31 - Low Maturity', 1, 'Technology');

-- Create 8 users (NOT assigned to roles)
-- Users will have organization_id = 31 but NO entries in user_role_cluster

-- Insert competency scores with gaps
-- Mix of scores: 0, 1, 2, 4 (NO 6s - all have gaps)
```

---

## Next Steps

1. ✅ **Apply Code Fixes** (10 mins)
   - Fix RoleCompetencyMatrix column name
   - Make competency IDs dynamic
   - Fix test app context

2. ✅ **Create Org 31 Test Data** (20 mins)
   - Write SQL migration script
   - Execute and verify
   - Test with Algorithm 3

3. ✅ **Verify Org 29** (5 mins)
   - Check if users/scores exist
   - If not, set up similar to Org 28

4. ✅ **Run End-to-End Tests** (15 mins)
   - Test Algorithm 1 with all orgs
   - Test Algorithm 2 with role-based orgs
   - Test Algorithm 3 with both pathways

5. ✅ **Start Flask Server** (5 mins)
   - Verify server runs without errors
   - Test basic API endpoints

**Total Estimated Time:** ~1 hour

---

## Questions for User

1. **Org 30 Decision:** Should I create new Org 31 for low-maturity testing, or delete roles from Org 30?
   - **Recommendation:** Create Org 31 (safer, doesn't break existing data)

2. **Competencies 17-18:** Should these be included in learning objectives generation?
   - Current: Code only processes 1-16
   - Database has: 1-18

3. **Missing Competencies 2-3:** Are these intentionally excluded from test data?
   - Found in results: 1, 4-18
   - NOT found: 2, 3

---

**End of Diagnostic Report**
