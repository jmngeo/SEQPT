# Competency Assessment Architecture Cleanup Analysis

**Date**: 2025-10-23
**Issue**: Derik's anonymous survey system is being used in an authenticated app with proper user management

---

## Executive Summary

The Phase 2 competency assessment was copied from Derik's standalone survey application, which was designed for **anonymous, stateless surveys** without login functionality. Our SE-QPT system has **proper authentication with the `User` model** (username, password, organization, roles), making much of Derik's anonymous survey infrastructure **redundant and unnecessarily complex**.

This document analyzes what can be cleaned up, simplified, and removed.

---

## Current Architecture (Derik's Anonymous Survey System)

### **The Flow**

1. **Frontend calls `/new_survey_user` (POST)**
   - Creates entry in `new_survey_user` table with empty username
   - Database trigger `before_insert_new_survey_user` calls `set_username()` function
   - Auto-generates username like `se_survey_user_42`
   - Returns username to frontend

2. **User completes competency assessment**
   - Frontend collects competency scores
   - Frontend prepares survey data with auto-generated username

3. **Frontend calls `/submit_survey` (POST)**
   - Updates `new_survey_user.survey_completion_status = True`
   - Creates/updates entry in `app_user` table with:
     - Generated username (e.g., `se_survey_user_42`)
     - Organization ID
     - Name (from localStorage admin user)
     - Tasks/responsibilities
   - Saves competency scores to `user_se_competency_survey_results`
   - Saves role selections to `user_role_cluster`
   - Saves survey type to `user_survey_type`

4. **Frontend calls `/get_user_competency_results` (GET)**
   - Fetches results using the auto-generated username
   - Queries `app_user` by username
   - Returns radar chart data

### **Database Components**

#### **Tables**
1. **`new_survey_user`** - Tracks survey completion status
   - `id` (auto-increment)
   - `username` (auto-generated via trigger)
   - `created_at`
   - `survey_completion_status` (boolean)

2. **`app_user`** - Separate user table for survey participants
   - `id` (auto-increment)
   - `organization_id`
   - `name`
   - `username` (matches `new_survey_user.username`)
   - `tasks_responsibilities` (JSON)

3. **`user_role_cluster`** - Maps users to roles
   - `user_id` (FK to `app_user.id`)
   - `role_cluster_id`

4. **`user_survey_type`** - Tracks survey type
   - `user_id` (FK to `app_user.id`)
   - `survey_type` ('known_roles', 'unknown_roles', 'all_roles')

5. **`user_se_competency_survey_results`** - Competency scores
   - `user_id` (FK to `users.id` - ⚠️ NOTE: Uses `users` table, not `app_user`!)
   - `organization_id`
   - `competency_id`
   - `score`

6. **`user_competency_survey_feedback`** - LLM feedback
   - `user_id` (FK to `app_user.id`)
   - `organization_id`
   - `feedback` (JSON)

#### **Database Triggers**
1. **`before_insert_new_survey_user` trigger**
   - Calls `set_username()` function
   - Auto-generates usernames like `se_survey_user_<id>`

2. **`set_username()` function**
   ```sql
   CREATE OR REPLACE FUNCTION public.set_username() RETURNS trigger AS $$
   BEGIN
     IF NEW.id IS NULL THEN
       NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
     END IF;
     IF NEW.username IS NULL OR NEW.username = '' THEN
       NEW.username := 'se_survey_user_' || NEW.id;
     END IF;
     RETURN NEW;
   END;
   $$;
   ```

#### **Models (models.py)**
- Line 505: `NewSurveyUser` model
- Line 443: `AppUser` model
- Line 468: `UserRoleCluster` model
- Line 486: `UserSurveyType` model
- Line 393: `UserCompetencySurveyResult` model
- Line 521: `UserCompetencySurveyFeedback` model
- Line 604: `User` model (authenticated users)

#### **Endpoints (routes.py)**
- Line 2422: `POST /new_survey_user` - Creates anonymous survey user
- Line 2611: `POST /submit_survey` - Submits survey results
- Line 2694: `GET /get_user_competency_results` - Fetches results by username

---

## Problems with Current Approach

### **1. Dual User System**
We have **TWO completely separate user systems**:
- `User` table (line 604) - Authenticated users with username/password/org
- `AppUser` table (line 443) - Anonymous survey users with auto-generated usernames

**Problem**: When an authenticated admin/employee takes a competency assessment, we create a **fake anonymous user** (`se_survey_user_42`) instead of linking results to their **real account**.

### **2. Inconsistent Foreign Keys**
- `UserCompetencySurveyResult.user_id` → Points to `users.id` (authenticated User)
- `UserRoleCluster.user_id` → Points to `app_user.id` (anonymous AppUser)
- `UserSurveyType.user_id` → Points to `app_user.id` (anonymous AppUser)
- `UserCompetencySurveyFeedback.user_id` → Points to `app_user.id` (anonymous AppUser)

**Result**: Data is split across two user systems with no clear relationship.

### **3. Unnecessary Complexity**
- **Database trigger** to auto-generate usernames - Not needed when users already have usernames
- **`new_survey_user` table** - Redundant tracking when we have authenticated users
- **`app_user` table** - Duplicate of `User` table functionality
- **Username generation logic** - Pointless when logged-in users have real usernames

### **4. Username Confusion**
The frontend code shows this confusion (DerikCompetencyBridge.vue:930-950):
```javascript
// Step 1: Determine username based on assessment mode
let username
if (props.mode === 'task-based' && taskBasedUsername.value) {
  // Reuse username from task analysis for task-based assessments
  username = taskBasedUsername.value
  console.log('Using task-based username:', username)
} else {
  // Create a new survey user for role-based and full-competency assessments
  const newUserResponse = await fetch('http://localhost:5000/new_survey_user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
  username = userData.username  // e.g., 'se_survey_user_42'
}
```

**Why does this exist?** The user is **already logged in** with a username (from `localStorage.getItem('user')`). We should use that!

### **5. Lost Assessment History**
When admin creates assessments for employees, the results are stored under anonymous usernames (`se_survey_user_42`) with **no traceable link** back to the actual authenticated user who created them.

---

## What Derik's System Was Designed For

**Context**: Derik's competency_assessor app was a **standalone survey tool** where:
- No user registration required
- Anyone could visit the site and take a survey
- System needed to generate unique identifiers for anonymous respondents
- Results were stored by auto-generated username
- No concept of "logged-in admin creating assessments for employees"

**This made sense for Derik's use case but NOT for SE-QPT.**

---

## Recommended Cleanup Strategy

### **Phase 1: Analysis (Current)**
✅ Document current architecture
✅ Identify all dependencies on `NewSurveyUser` and `AppUser`
✅ Map data relationships and FK constraints

### **Phase 2: Simplification (Recommended)**

#### **A. Use Authenticated User Instead of Anonymous System**

**Before**:
```javascript
// Create anonymous survey user
const response = await fetch('/new_survey_user', { method: 'POST' })
const username = response.username  // 'se_survey_user_42'
```

**After**:
```javascript
// Use logged-in user's username
const user = JSON.parse(localStorage.getItem('user'))
const username = user.username  // Real username like 'admin' or 'john_doe'
```

#### **B. Consolidate User Tables**

**Option 1: Direct `User` Usage (Simplest)**
- Remove `AppUser`, `NewSurveyUser` tables entirely
- Update all FKs to point to `users.id`
- Store assessment metadata directly in `User` model

**Option 2: Assessment-Specific Extension (Cleaner)**
- Keep `User` as authentication model
- Create `UserAssessment` table to link assessments to users:
  ```sql
  CREATE TABLE user_assessment (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    organization_id INTEGER REFERENCES organization(id),
    assessment_type VARCHAR(50),  -- 'self', 'admin_created', 'employee'
    created_by_user_id INTEGER REFERENCES users(id),  -- Who created it
    tasks_responsibilities JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
  );
  ```

- Link competency results to `UserAssessment`:
  ```sql
  ALTER TABLE user_se_competency_survey_results
  ADD COLUMN assessment_id INTEGER REFERENCES user_assessment(id);
  ```

**Benefits**:
- Clear audit trail: Who created the assessment
- Support for admin-created employee assessments
- Proper user relationship
- No duplicate user data

#### **C. Remove Anonymous Survey Infrastructure**

**Can be deleted**:
1. ✂️ Database trigger: `before_insert_new_survey_user`
2. ✂️ Database function: `set_username()`
3. ✂️ Table: `new_survey_user`
4. ✂️ Model: `NewSurveyUser` (models.py:505)
5. ✂️ Endpoint: `POST /new_survey_user` (routes.py:2422)

**Can be consolidated/refactored**:
6. 🔄 Table: `app_user` → Merge into `User` or replace with `UserAssessment`
7. 🔄 Model: `AppUser` → Remove or replace with proper relationship
8. 🔄 Table: `user_role_cluster` → Update FK to reference `users.id` or `user_assessment.id`
9. 🔄 Table: `user_survey_type` → Move to `UserAssessment.assessment_type`

#### **D. Update Endpoints**

**Before** (3 steps):
1. POST `/new_survey_user` → Get username
2. POST `/submit_survey` → Submit with username
3. GET `/get_user_competency_results?username=se_survey_user_42`

**After** (2 steps):
1. POST `/assessment/start` → Create assessment record, return assessment_id
2. POST `/assessment/{assessment_id}/submit` → Submit scores
3. GET `/assessment/{assessment_id}/results` → Fetch by assessment ID

**Benefits**:
- RESTful design
- Clear assessment tracking
- Direct link to authenticated user
- Support for assessment history

---

## Migration Path

### **Step 1: Add New Tables (Backward Compatible)**
```sql
CREATE TABLE user_assessment (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) NOT NULL,
  organization_id INTEGER REFERENCES organization(id) NOT NULL,
  assessment_type VARCHAR(50) NOT NULL,  -- 'role_based', 'task_based', 'full_competency'
  created_by_user_id INTEGER REFERENCES users(id),
  tasks_responsibilities JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);

ALTER TABLE user_se_competency_survey_results
ADD COLUMN assessment_id INTEGER REFERENCES user_assessment(id);

ALTER TABLE user_role_cluster
ADD COLUMN assessment_id INTEGER REFERENCES user_assessment(id);
```

### **Step 2: Update Endpoints (New Implementation)**
- Add new assessment endpoints alongside old ones
- Migrate frontend to use new endpoints
- Keep old endpoints for backward compatibility during transition

### **Step 3: Data Migration**
```sql
-- Migrate existing app_user data to User if needed
-- Link existing results to proper users
-- Update FKs to point to new assessment records
```

### **Step 4: Remove Old System**
Once new system is verified working:
- Drop old endpoints
- Drop old tables (`new_survey_user`, `app_user`)
- Remove old models
- Drop database triggers
- Clean up frontend code

---

## Frontend Changes Required

### **DerikCompetencyBridge.vue**

**Before** (lines 920-950):
```javascript
// Create a new survey user for role-based and full-competency assessments
const newUserResponse = await fetch('http://localhost:5000/new_survey_user', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' }
})
const userData = await newUserResponse.json()
username = userData.username  // 'se_survey_user_42'
```

**After**:
```javascript
// Use authenticated user
const user = JSON.parse(localStorage.getItem('user'))
const assessment_id = await createAssessment({
  user_id: user.id,
  assessment_type: props.mode,  // 'role_based', 'task_based', 'full_competency'
  organization_id: user.organization_id
})
```

---

## Benefits of Cleanup

### **Technical**
- ✅ Single source of truth for users
- ✅ Consistent foreign key relationships
- ✅ Proper audit trail for assessments
- ✅ Support for assessment history per user
- ✅ Reduced database complexity (fewer tables, no triggers)

### **User Experience**
- ✅ Assessment results linked to real user accounts
- ✅ Users can view their assessment history
- ✅ Admins can track which employees completed assessments
- ✅ Support for re-taking assessments
- ✅ Better reporting and analytics

### **Maintainability**
- ✅ Simpler codebase
- ✅ Fewer edge cases
- ✅ Clearer data model
- ✅ Easier to add features (e.g., assessment comparison, progress tracking)

---

## Risk Assessment

### **Low Risk**
- Adding new `UserAssessment` table (backward compatible)
- Adding new endpoints alongside old ones
- Updating frontend incrementally

### **Medium Risk**
- Migrating existing data from `app_user` to `User`
- Updating foreign key constraints
- Ensuring no data loss during migration

### **High Risk (Avoid)**
- Dropping tables before migration complete
- Removing endpoints before frontend updated
- Direct modification of production data without backups

---

## Recommended Implementation Order

1. **Document Current System** ✅ (This document)
2. **Add Assessment Tracking** (New table + endpoints)
3. **Update Frontend** (Use authenticated user + new endpoints)
4. **Data Migration** (Link old data to new system)
5. **Deprecate Old System** (Remove triggers, tables, endpoints)
6. **Code Cleanup** (Remove unused models and code)

---

## Questions to Answer Before Cleanup

1. **Do we need to preserve existing assessment data?**
   - If yes: Write migration scripts to link `app_user` data to `User`
   - If no: Can drop old tables after new system works

2. **Should admins be able to create assessments for employees?**
   - If yes: Use `created_by_user_id` in `UserAssessment`
   - If no: Simpler model with just `user_id`

3. **Do users need to see assessment history?**
   - If yes: Keep all assessment records with timestamps
   - If no: Could use single "latest assessment" pattern

4. **What about anonymous surveys in the future?**
   - If needed: Add `is_anonymous` flag to `UserAssessment`
   - For now: Remove anonymous infrastructure

---

## Next Steps

**Recommended**:
1. Review this analysis with team/stakeholders
2. Decide on preferred architecture (Option 1 vs Option 2)
3. Create detailed implementation plan
4. Build new endpoints with tests
5. Update frontend incrementally
6. Migrate data safely
7. Remove old system

**Timeline Estimate**:
- Design: 1 day
- Backend implementation: 2-3 days
- Frontend updates: 2-3 days
- Testing & migration: 2-3 days
- **Total**: ~1.5 weeks for complete cleanup

---

## Integration with DERIK_INTEGRATION_ANALYSIS.md Findings

This cleanup analysis should be read alongside `DERIK_INTEGRATION_ANALYSIS.md` which documents:

### What's Working (Keep These)
- ✅ 18 Derik models actively used in Phase 2
- ✅ 12 core competency endpoints working
- ✅ LLM feedback generation (OpenAI GPT-4o-mini)
- ✅ Task-to-process mapping via FAISS pipeline
- ✅ PDF export feature (implemented October 23, 2025)
- ✅ Role-based and task-based assessment flows

### What Needs Cleanup (This Document's Focus)
- ⚠️ Dual user system (User vs AppUser vs NewSurveyUser)
- ⚠️ Anonymous username generation (unnecessary with auth)
- ⚠️ Database triggers for username auto-generation
- ⚠️ Possible duplicate models (SECompetency vs Competency, SERole vs RoleCluster)
- ⚠️ Utility scripts in `src/backend/` (analyze_*.py, check_*.py, etc.)

### Combined Recommendation

**Phase 1: This Cleanup (High Priority)**
1. Simplify user system (remove anonymous survey infrastructure)
2. Consolidate duplicate models
3. Remove utility scripts
4. Fix inconsistent foreign keys

**Phase 2: Feature Additions (Lower Priority per DERIK_INTEGRATION_ANALYSIS.md)**
1. Verify three survey modes work correctly
2. Add role matching for "all_roles" mode (if needed)
3. Admin CRUD panel (defer to future)
4. Multi-language support (defer to future)

---

## Conclusion

The current Phase 2 competency assessment architecture is **overly complex** because it was designed for **anonymous surveys** but is being used in an **authenticated app**. By consolidating the dual user system and using the existing `User` model with proper assessment tracking, we can:

- Eliminate unnecessary complexity
- Improve data integrity
- Enable better features (history, reporting, admin management)
- Simplify maintenance

The cleanup is **highly recommended** and can be done **incrementally** with low risk using the phased approach outlined above.

**Key Insight**: Your Phase 2 implementation is **75% complete and working well** (per DERIK_INTEGRATION_ANALYSIS.md). This cleanup focuses on architectural simplification rather than adding new features.

---

## Related Documents

- **DERIK_INTEGRATION_ANALYSIS.md** - Analysis of what's implemented vs what's missing from Derik's system
- **SESSION_HANDOVER.md** - Session-by-session progress tracking with timestamps
- **TRIGGER_FIX_SUMMARY.md** - Documentation of username auto-generation trigger implementation

---

**Document Version**: 1.1
**Last Updated**: 2025-10-23 (Updated with DERIK_INTEGRATION_ANALYSIS.md findings)
**Author**: Claude Code Analysis
