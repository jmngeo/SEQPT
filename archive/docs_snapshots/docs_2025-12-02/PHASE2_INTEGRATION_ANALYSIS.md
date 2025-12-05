# Phase 2 Integration Analysis: Role-Based vs Task-Based

**Date**: 2025-11-01
**Priority**: CRITICAL - Must integrate before production
**Status**: Analysis Complete, Implementation Pending

---

## Executive Summary

**Current State**:
- ✅ **Working**: Role-based Phase 2 at `/app/phases/2` (PhaseTwo.vue)
- ⚠️ **Testing**: Task-based Phase 2 at `/app/phases/2/new` (Phase2NewFlow.vue)
- ❌ **Problem**: Task-based results failing with "No assessment ID or assessment data provided"

**Root Cause**: Task-based flow doesn't properly fetch/calculate results after submit

**Solution Needed**:
1. Make task-based save results same way as role-based
2. Make task-based calculate gaps and generate feedback
3. Eventually merge both into single unified Phase 2

---

## System Architecture

### Two Implementations Currently Exist

#### 1. OLD/WORKING: Role-Based Phase 2 (`/app/phases/2`)

**File**: `src/frontend/src/views/phases/PhaseTwo.vue`
**Flow**:
```
Step 0: Role Selection (from Phase 1 org_roles)
   ↓
Step 1: Competency Assessment (Derik's survey)
   ↓
Step 2: Assessment Results (gaps + feedback)
   ↓
Step 3: Learning Objectives (admin only)
```

**Components Used**:
- PhaseTwo.vue - Main container
- (Derik's components for assessment)
- Phase2AssessmentResults.vue - Results display

**Database Tables Used**:
- `organization_roles` - Selected roles
- `role_competency_matrix` - Required competencies per role
- `user_competency_survey_results` - User's scores
- (Likely has gap calculation and feedback tables)

#### 2. NEW/TESTING: Task-Based Phase 2 (`/app/phases/2/new`)

**File**: `src/frontend/src/views/phases/Phase2NewFlow.vue`
**Flow**:
```
If maturity < 3:
   Task Input (DerikTaskSelector)
      ↓
   Necessary Competencies (from task analysis)
      ↓
   Competency Assessment (Phase2CompetencyAssessment)
      ↓
   Results (CompetencyResults) ← FAILING HERE

If maturity >= 3:
   Role Selection
      ↓
   (same as above from Necessary Competencies)
```

**Components Used**:
- Phase2NewFlow.vue - Entry point
- Phase2TaskFlowContainer.vue - Main container
- DerikTaskSelector.vue - Task input (task-based only)
- Phase2RoleSelection.vue - Role selection (role-based only)
- Phase2NecessaryCompetencies.vue - Shows required competencies
- Phase2CompetencyAssessment.vue - Shared assessment
- CompetencyResults.vue - Shared results ← ERROR HERE

**Database Tables Used**:
- `unknown_role_process_matrix` - Process involvement (task-based)
- `unknown_role_competency_matrix` - Required competencies (task-based)
- `user_assessment` - Assessment metadata
- `user_competency_survey_results` - User's scores (shared)

---

## Current Error Analysis

### Error Message
```
Error fetching assessment results: Error: No assessment ID or assessment data provided
at processAssessmentData (CompetencyResults.vue:424:13)
at CompetencyResults.vue:918:3
```

### Why It's Happening

**CompetencyResults.vue expects**:
- Option A: `assessment_id` prop to fetch results from API
- Option B: `assessment` prop with pre-loaded data

**Task-based flow currently passes**:
- `assessmentResults.value` which is likely `null` or empty

**File**: Phase2TaskFlowContainer.vue:65-68
```vue
<CompetencyResults
  v-else-if="currentStep === 'results'"
  :assessment-data="assessmentResults"  ← Passing null!
  @continue="handleContinue"
  @back="handleBackToAssessment"
/>
```

---

## What Role-Based Phase 2 Saves (Database Schema)

### Need to investigate these tables in old PhaseTwo.vue:

1. **user_competency_survey_results** (scores)
```sql
- user_id
- organization_id
- competency_id
- score (user's level: 0, 1, 2, 4, 6)
- assessment_id (optional link to user_assessment)
```

2. **Gap Calculation** (needs verification)
Likely calculated on-the-fly:
```
gap = required_level - user_score
```

Where:
- `required_level` from `role_competency_matrix` (role-based) OR `unknown_role_competency_matrix` (task-based)
- `user_score` from `user_competency_survey_results`

3. **Feedback/Learning Objectives** (needs verification)
- Possibly stored in a separate table
- Or generated on-the-fly using LLM

---

## Missing Pieces for Task-Based

### ❌ **Results Calculation Endpoint**

Need backend endpoint: `/api/phase2/assessment-results/<assessment_id>`

**Should return**:
```json
{
  "assessment_id": 30,
  "user": {...},
  "competencies": [
    {
      "competency_id": 1,
      "competency_name": "Systems Thinking",
      "required_level": 4,
      "current_level": 2,
      "gap": 2,
      "status": "needs_improvement" // or "proficient", "exceeds"
    },
    ...
  ],
  "summary": {
    "total_competencies": 14,
    "proficient": 5,
    "needs_improvement": 7,
    "exceeds": 2
  },
  "feedback": "LLM-generated personalized feedback..."
}
```

### ❌ **Proper State Management in Phase2TaskFlowContainer**

**Current** (line 211):
```javascript
const handleAssessmentComplete = (completedAssessmentData) => {
  assessmentResults.value = completedAssessmentData  // What is this?
  currentStep.value = 'results'
}
```

**Needed**:
```javascript
const handleAssessmentComplete = async (completedAssessmentData) => {
  try {
    // Fetch full results with gap analysis
    const response = await phase2Task2Api.getAssessmentResults(assessmentId.value)
    assessmentResults.value = response
    currentStep.value = 'results'
  } catch (error) {
    console.error('Failed to load results:', error)
    toast.error('Failed to load assessment results')
  }
}
```

---

## Integration Strategy

### Option A: Quick Fix (Recommended for this session)
**Goal**: Make task-based work with minimal changes

**Steps**:
1. ✅ Create `/api/phase2/assessment-results/<id>` endpoint
2. ✅ Fetch results in `handleAssessmentComplete`
3. ✅ Pass correct data to CompetencyResults
4. ✅ Test end-to-end flow

**Estimated Time**: 1-2 hours (doable in this session)

### Option B: Full Integration (Next session)
**Goal**: Merge both implementations into single Phase 2

**Steps**:
1. Determine unified flow based on maturity + role availability
2. Migrate PhaseTwo.vue to use new architecture
3. Remove duplicate code
4. Unified routing `/app/phases/2`
5. Comprehensive testing

**Estimated Time**: 4-6 hours (next session)

---

## Data Flow Comparison

### Role-Based (Working)
```
1. User selects roles from organization_roles
2. Fetch required competencies from role_competency_matrix
3. User completes assessment → user_competency_survey_results
4. Calculate gaps: required - current
5. Display results with feedback
```

### Task-Based (Current - Incomplete)
```
1. User enters tasks
2. LLM maps to processes → unknown_role_process_matrix
3. Stored proc calculates → unknown_role_competency_matrix
4. Fetch competencies for display
5. User completes assessment → user_competency_survey_results ✓
6. Calculate gaps: required - current ← MISSING
7. Display results with feedback ← FAILING
```

---

## Required Backend Endpoints

### ✅ Already Implemented
- `POST /findProcesses` - Task analysis
- `POST /get_required_competencies_for_roles` - Fetch competencies
- `POST /api/phase2/start-assessment` - Create assessment
- `POST /api/phase2/submit-assessment` - Submit answers

### ❌ Missing (CRITICAL)
- `GET /api/phase2/assessment-results/<id>` - Fetch results with gaps

---

## Database Queries Needed for Results

### For Task-Based Assessment:

```sql
-- Get user's scores
SELECT
    c.id as competency_id,
    c.competency_name,
    ucsr.score as current_level
FROM user_competency_survey_results ucsr
JOIN competency c ON ucsr.competency_id = c.id
WHERE ucsr.assessment_id = ?

-- Get required levels (task-based)
SELECT
    competency_id,
    role_competency_value as required_level
FROM unknown_role_competency_matrix
WHERE user_name = ? AND organization_id = ?

-- Calculate gaps
SELECT
    c.id,
    c.competency_name,
    urcm.role_competency_value as required_level,
    COALESCE(ucsr.score, 0) as current_level,
    (urcm.role_competency_value - COALESCE(ucsr.score, 0)) as gap
FROM unknown_role_competency_matrix urcm
JOIN competency c ON urcm.competency_id = c.id
LEFT JOIN user_competency_survey_results ucsr
    ON ucsr.competency_id = c.id
    AND ucsr.assessment_id = ?
WHERE urcm.user_name = ?
    AND urcm.organization_id = ?
    AND urcm.role_competency_value > 0
```

### For Role-Based Assessment (for reference):

```sql
-- Similar but uses role_competency_matrix instead
SELECT
    c.id,
    c.competency_name,
    rcm.role_competency_value as required_level,
    COALESCE(ucsr.score, 0) as current_level,
    (rcm.role_competency_value - COALESCE(ucsr.score, 0)) as gap
FROM role_competency_matrix rcm
JOIN competency c ON rcm.competency_id = c.id
LEFT JOIN user_competency_survey_results ucsr
    ON ucsr.competency_id = c.id
    AND ucsr.assessment_id = ?
WHERE rcm.organization_id = ?
    AND rcm.role_id IN (SELECT role_id FROM user_role_cluster WHERE assessment_id = ?)
```

---

## Next Steps (Priority Order)

### Immediate (This Session if time permits)

1. **Create /api/phase2/assessment-results endpoint**
   - Fetch user scores from user_competency_survey_results
   - Fetch required levels from unknown_role_competency_matrix (for task-based) or role_competency_matrix (for role-based)
   - Calculate gaps
   - Return structured response

2. **Fix handleAssessmentComplete in Phase2TaskFlowContainer**
   - Call getAssessmentResults API
   - Store full results in assessmentResults.value
   - Pass to CompetencyResults

3. **Test end-to-end task-based flow**
   - Complete assessment
   - Verify results display
   - Check gap calculations

### Next Session

4. **Analyze feedback/learning objectives generation**
   - Find how role-based generates feedback
   - Implement same for task-based

5. **Plan full integration**
   - Single Phase 2 route
   - Conditional rendering based on pathway
   - Remove duplicate code

6. **Migration plan**
   - Update routing
   - Migrate existing users
   - Deprecate old PhaseTwo.vue

---

## Key Files to Review

### Frontend
1. `src/frontend/src/views/phases/PhaseTwo.vue` - Old working implementation
2. `src/frontend/src/views/phases/Phase2NewFlow.vue` - New entry point
3. `src/frontend/src/components/phase2/Phase2TaskFlowContainer.vue` - New container
4. `src/frontend/src/components/phase2/CompetencyResults.vue` - Shared results component
5. `src/frontend/src/components/phase2/Phase2AssessmentResults.vue` - Old results component?

### Backend
1. `src/backend/app/routes.py` - All Phase 2 endpoints
2. Need to find old results endpoint used by PhaseTwo.vue

### Database
1. `user_assessment` - Assessment metadata
2. `user_competency_survey_results` - User scores
3. `unknown_role_competency_matrix` - Task-based required levels
4. `role_competency_matrix` - Role-based required levels
5. Unknown feedback/learning objectives tables

---

## Questions to Answer (Next Session)

1. Does PhaseTwo.vue use an existing results endpoint we can reuse?
2. Where/how is feedback generated in role-based flow?
3. Are learning objectives stored or generated on-the-fly?
4. Should we merge implementations or keep separate?
5. What's the long-term maintenance strategy?

---

## Success Criteria

**Task-Based Flow Complete When**:
- ✅ User can enter tasks
- ✅ LLM identifies processes
- ✅ Competencies are calculated
- ✅ User completes assessment
- ✅ Scores are saved to database
- ❌ Results display with gap analysis ← CURRENT BLOCKER
- ❌ Feedback is generated
- ❌ Can proceed to learning objectives (if admin)

---

**Analysis Completed**: 2025-11-01 00:30 UTC
**Next Action**: Implement `/api/phase2/assessment-results` endpoint
**Time Estimate**: 1-2 hours to unblock
