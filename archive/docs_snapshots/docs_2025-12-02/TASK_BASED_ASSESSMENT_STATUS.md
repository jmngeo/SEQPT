# Task-Based Competency Assessment: Current Status & Requirements

**Date**: 2025-10-30
**Context**: Bringing task-based competency assessment to Phase 2

---

## Executive Summary

The SE-QPT codebase **already has a fully functional task-based assessment system**, but it's currently used in **Phase 1 Task 2 (Role Identification)** only. We need to adapt it for **Phase 2 (Individual Competency Assessment)** when maturity level < "defined and established".

---

## Two Different Use Cases

### Use Case 1: Phase 1 Task 2 - ROLE IDENTIFICATION (Currently Active)

**Purpose**: Organizations describe job profiles → AI maps to standard SE roles

**Flow**:
```
User enters tasks → AI analyzes → Maps to ISO processes → Suggests SE role →
User confirms → Creates organization_role → Used for Phase 2
```

**Location**: `src/frontend/src/components/phase1/task2/TaskBasedMapping.vue`

**Current Validation**: **ALL THREE task categories REQUIRED**
```javascript
// Lines 289-296
const canMap = computed(() => {
  return jobProfiles.value.some(p =>
    p.title.trim() !== '' &&
    p.tasks.responsible_for.trim() !== '' &&  // REQUIRED
    p.tasks.supporting.trim() !== '' &&        // REQUIRED
    p.tasks.designing.trim() !== ''            // REQUIRED
  )
})
```

**Issue**: This contradicts advisor's guidance that fields should be optional.

---

### Use Case 2: Phase 2 Task-Based Assessment - INDIVIDUAL ASSESSMENT (Needs Implementation)

**Purpose**: Individuals describe their tasks → AI determines competency requirements → Take survey → Compare results

**Flow**:
```
Phase 1 complete → Check maturity < "defined and established" →
Show task input (3 categories) → AI analyzes → Calculate competencies →
Take survey → Show results with gaps
```

**Required Location**: New pathway in Phase 2 flow

**Validation**: **ANY task category can be filled** (per advisor)

---

## Current Codebase Inventory

### 1. Database Tables (ACTIVE - 4,444 rows)

| Table | Purpose | Status | Data |
|-------|---------|--------|------|
| `unknown_role_process_matrix` | Stores process involvement per user | ACTIVE | 2,908 rows |
| `unknown_role_competency_matrix` | Stores calculated competency requirements | ACTIVE | 1,536 rows |

**Schema**: `src/backend/models.py` lines 344-405

### 2. Backend Route (ACTIVE)

**Route**: `POST /findProcesses`
**Location**: `src/backend/app/routes.py` lines 1989-2200
**Purpose**: Maps user tasks to ISO processes using AI

**Request Format**:
```json
{
  "username": "phase1_temp_123456789_abc",
  "organizationId": 1,
  "tasks": {
    "responsible_for": ["Task 1", "Task 2"],
    "supporting": ["Task 3"],
    "designing": ["Task 4"]
  }
}
```

**Response**:
```json
{
  "status": "success",
  "processes": [
    {"process_name": "Design Definition", "involvement": "Responsible"}
  ],
  "llm_role_suggestion": {
    "role_id": 4,
    "role_name": "System Engineer",
    "confidence": "High",
    "reasoning": "..."
  }
}
```

### 3. AI Pipeline (ACTIVE)

**Location**: `src/backend/app/services/llm_pipeline/llm_process_identification_pipeline.py`
**Technology**: LangChain + OpenAI GPT-4o-mini + FAISS
**Lines**: 582 lines of production code

**Pipeline Stages**:
1. Language detection (English/German)
2. Translation (if German)
3. Validation (reject nonsense)
4. Process identification (RAG retrieval from FAISS)
5. Reasoning (determine involvement levels: 0/1/2/3)
6. Role suggestion (NEW - suggests best SE role)

**FAISS Index**: `src/backend/app/faiss_index/` (184 KB index.faiss + 63 KB index.pkl)

### 4. Stored Procedure (ACTIVE)

**Procedure**: `update_unknown_role_competency_values(username, org_id)`
**Location**: `src/backend/setup/database_objects/create_stored_procedures.py` lines 118-162

**Logic**:
```sql
role_competency_value = MAX(role_process_value × process_competency_value)
```

Joins `unknown_role_process_matrix` × `process_competency_matrix` to calculate competencies.

### 5. Frontend Components

#### Active: TaskBasedMapping.vue (Phase 1)
**Location**: `src/frontend/src/components/phase1/task2/TaskBasedMapping.vue`
**Lines**: 672 lines
**Status**: ACTIVE in Phase 1 Task 2

**Validation Issue**: Requires ALL THREE categories (contradicts advisor)

#### Exists but Unused: DerikTaskSelector.vue (Phase 2)
**Location**: `src/frontend/src/components/phase2/DerikTaskSelector.vue`
**Status**: EXISTS but NOT INTEGRATED into Phase 2 flow

**Validation** (lines 165-169): **ANY field can be filled** ✅
```javascript
const hasValidInput = computed(() => {
  return tasksResponsibleFor.value.trim() ||  // OR logic
         tasksYouSupport.value.trim() ||
         tasksDefineAndImprove.value.trim()
})
```

**Default Values** (lines 178-188):
- "Not responsible for any tasks"
- "Not supporting any tasks"
- "Not designing any tasks"

**Good News**: This component already implements advisor's requirement!

---

## Discrepancy Analysis

### Issue 1: Validation Mismatch

**Phase 1 Component** (`TaskBasedMapping.vue`):
- ❌ Requires ALL THREE task categories
- Lines 289-296, 327-338

**Phase 2 Component** (`DerikTaskSelector.vue`):
- ✅ Requires AT LEAST ONE task category
- Lines 165-169
- Uses defaults for empty fields

**Advisor Requirement**: Fields should NOT be mandatory (any or all)

**Resolution Needed**:
1. Update Phase 1 component to allow optional fields (match advisor requirement)
2. Keep Phase 2 component as-is (already correct)

### Issue 2: Backend Validation

**Current Backend** (`routes.py` lines 2009-2014):
```python
tasks_responsibilities = {
    "responsible_for": tasks.get("responsible_for", []),
    "supporting": tasks.get("supporting", []),
    "designing": tasks.get("designing", [])
}
```

Backend accepts empty arrays by default. No strict validation.

**LLM Pipeline** (`llm_process_identification_pipeline.py`):
- Expects all three keys in dictionary
- Sets defaults if values are empty (lines 178-188 in DerikTaskSelector)

**Status**: Backend is flexible, no changes needed ✅

---

## What Needs to Be Done

### Task 1: Fix Phase 1 Validation (Optional)
Make task fields optional in Phase 1 to match advisor guidance.

**File**: `src/frontend/src/components/phase1/task2/TaskBasedMapping.vue`

**Change**: Lines 289-296, 327-338
```javascript
// From:
const canMap = computed(() => {
  return jobProfiles.value.some(p =>
    p.title.trim() !== '' &&
    p.tasks.responsible_for.trim() !== '' &&  // ALL REQUIRED
    p.tasks.supporting.trim() !== '' &&
    p.tasks.designing.trim() !== ''
  )
})

// To:
const canMap = computed(() => {
  return jobProfiles.value.some(p =>
    p.title.trim() !== '' &&
    (p.tasks.responsible_for.trim() !== '' ||  // ANY REQUIRED
     p.tasks.supporting.trim() !== '' ||
     p.tasks.designing.trim() !== '')
  )
})
```

### Task 2: Integrate Task-Based Pathway into Phase 2 ⭐ MAIN TASK

**Requirement**: When Phase 1 maturity < "defined and established", show task-based assessment in Phase 2 instead of role selection.

#### What Already Exists ✅
- Database tables (`unknown_role_process_matrix`, `unknown_role_competency_matrix`)
- Backend route (`POST /findProcesses`)
- AI pipeline (fully functional)
- Stored procedure (`update_unknown_role_competency_values`)
- Frontend component (`DerikTaskSelector.vue` - ready to use!)

#### What Needs to Be Created 🔨

**A. Maturity Level Check**
- Add maturity level to Phase 1 completion data
- Pass maturity level to Phase 2
- Threshold: `process_score < 3.0` means "not defined and established"

**B. Conditional Routing in Phase 2**
- Modify `Phase2TaskFlowContainer.vue` to support two pathways:

  **Pathway 1: Role-Based (if maturity ≥ 3.0)**
  ```
  Role Selection → Review Competencies → Self-Assessment → Results
  ```

  **Pathway 2: Task-Based (if maturity < 3.0)**
  ```
  Task Input (DerikTaskSelector) → Review Competencies → Self-Assessment → Results
  ```

**C. Backend Endpoint for Phase 2 Task-Based Assessment**
- Reuse existing `/findProcesses` route
- Create Phase 2 specific wrapper if needed
- Ensure username format works for Phase 2 users (not just phase1_temp_*)

**D. Frontend Integration**
- Modify `Phase2TaskFlowContainer.vue` step logic:
  ```javascript
  const currentStep = ref(
    maturityLevel < 3.0 ? 'task-input' : 'role-selection'
  )
  ```

- Add DerikTaskSelector as first step for low maturity
- Connect to `/findProcesses` endpoint
- Store results in Phase 2 state
- Proceed to competency review

**E. Competency Retrieval**
- Modify `Phase2NecessaryCompetencies.vue` to support two sources:
  - **Role-based**: Query `role_competency_matrix` (current)
  - **Task-based**: Query `unknown_role_competency_matrix` (new)

**F. Results Display**
- Ensure `CompetencyResults.vue` works with task-based data
- May need to adjust labels ("Based on your tasks" vs "Based on your role")

---

## Architecture Decision

### Option A: Reuse Everything (RECOMMENDED ⭐)

**Advantages**:
- DerikTaskSelector.vue already exists and works
- /findProcesses route already exists and works
- Database tables already exist with proven schema
- AI pipeline is production-ready
- Stored procedure is tested
- Minimal development time

**What to do**:
1. Check Phase 1 maturity level at Phase 2 start
2. If low maturity, render DerikTaskSelector first
3. Call /findProcesses with Phase 2 username
4. Fetch competencies from unknown_role_competency_matrix
5. Continue with existing assessment flow

**Estimated effort**: 2-4 hours

### Option B: Port from Derik's Codebase

**Why NOT recommended**:
- Everything already exists in SE-QPT!
- Would duplicate code and database tables
- Derik's original system is similar but not identical
- More testing required
- Higher risk of bugs

**Only consider if**: Current system has fundamental flaws (unlikely)

---

## Data Flow Comparison

### Phase 1 Task-Based (Current)
```
Organization describes job profiles
    ↓
TaskBasedMapping.vue (multiple profiles)
    ↓
POST /findProcesses (for each profile)
    ↓
AI Pipeline → unknown_role_process_matrix
    ↓
Stored procedure → unknown_role_competency_matrix
    ↓
AI suggests SE role
    ↓
User confirms → organization_roles table
    ↓
Phase 2 uses organization_roles (role-based pathway)
```

### Phase 2 Task-Based (Proposed)
```
Individual starts Phase 2
    ↓
Check Phase 1 maturity < 3.0?
    ↓ YES
DerikTaskSelector.vue (individual's tasks)
    ↓
POST /findProcesses (for individual)
    ↓
AI Pipeline → unknown_role_process_matrix (user-specific)
    ↓
Stored procedure → unknown_role_competency_matrix (user-specific)
    ↓
Phase2NecessaryCompetencies (fetch from unknown_role_competency_matrix)
    ↓
Phase2CompetencyAssessment (standard survey)
    ↓
CompetencyResults (compare user scores vs. required scores)
```

---

## Key Technical Considerations

### 1. Username Format

**Phase 1**: `phase1_temp_1761080345662_5i6al8edx`
**Phase 2**: Currently uses `organization_id` + selected roles

**For Phase 2 Task-Based**: Need consistent username format
- Option A: Use auth user's username
- Option B: Generate `phase2_user_{user_id}`
- Must be unique per assessment

### 2. Data Isolation

**Question**: Should Phase 2 task-based data be separate from Phase 1?

**Recommendation**: YES
- Phase 1: Organization-level (job profiles)
- Phase 2: Individual-level (personal assessment)
- Use different username prefixes to distinguish

### 3. Competency Matrix Source

**Current Phase 2** (role-based):
```sql
SELECT * FROM role_competency_matrix
WHERE organization_id = ? AND role_id IN (?)
```

**New Phase 2** (task-based):
```sql
SELECT * FROM unknown_role_competency_matrix
WHERE organization_id = ? AND user_name = ?
```

**Solution**: Add `survey_type` parameter to competency fetch endpoint
- `survey_type = 'known_roles'` → Query role_competency_matrix
- `survey_type = 'unknown_roles'` → Query unknown_role_competency_matrix

### 4. Results Comparison

**Both pathways use same logic**:
```
Gap = required_score - user_score
```

**Source difference**:
- Role-based: `required_score` from `role_competency_matrix`
- Task-based: `required_score` from `unknown_role_competency_matrix`

---

## Implementation Checklist

### Backend (Minimal Changes)
- [ ] Verify `/findProcesses` works with Phase 2 usernames
- [ ] Add endpoint variant or parameter for Phase 2 context
- [ ] Test stored procedure with Phase 2 data
- [ ] Add competency fetch endpoint that supports `survey_type` parameter

### Frontend (Moderate Changes)
- [ ] Fix Phase 1 TaskBasedMapping validation (make fields optional)
- [ ] Add maturity level to Phase 1 completion data
- [ ] Pass maturity level from Phase 1 → Phase 2
- [ ] Modify Phase2TaskFlowContainer to conditionally show task input
- [ ] Integrate DerikTaskSelector as first step (if low maturity)
- [ ] Update Phase2NecessaryCompetencies to fetch from correct matrix
- [ ] Test CompetencyResults with task-based data
- [ ] Update UI labels/text for task-based pathway

### Database (No Changes)
- [x] Tables exist (`unknown_role_process_matrix`, `unknown_role_competency_matrix`)
- [x] Stored procedure exists (`update_unknown_role_competency_values`)
- [x] Schema is correct

### Testing
- [ ] Test task input with all three fields filled
- [ ] Test task input with only one field filled
- [ ] Test task input with two fields filled
- [ ] Test task input with empty fields (should use defaults)
- [ ] Test AI pipeline with minimal task descriptions
- [ ] Test competency calculation accuracy
- [ ] Test results display with task-based data
- [ ] Test maturity threshold logic (< 3.0 vs ≥ 3.0)

---

## Maturity Threshold Definition

**Question**: What exactly is "defined and established"?

**Phase 1 Assessment**: 33 questions about SE process maturity
- Each question scored 1-5
- Average score = `process_score`

**ISO/IEC 33020 Maturity Levels** (reference):
- Level 0: Incomplete (0-14%)
- Level 1: Performed (15-49%)
- Level 2: Managed (50-84%)
- Level 3: Established (85-100%)

**Proposed Threshold**:
```
if process_score < 3.0:
    # Processes not yet established
    # Use task-based assessment (no role definitions yet)
    show_task_based_pathway()
else:
    # Processes are defined and established
    # Organization has clear roles
    show_role_based_pathway()
```

**Alternative Threshold** (more conservative):
```
if process_score < 2.5:
    show_task_based_pathway()
```

**Recommendation**: Ask user/advisor for exact threshold value.

---

## Comparison with Derik's Original System

### Similarities ✅
- Three task input categories (responsible_for, supporting, designing)
- AI-powered mapping using OpenAI GPT-4o-mini
- FAISS vector store for ISO process retrieval
- LangChain pipeline architecture
- Process-competency matrix multiplication logic
- Stored procedure for calculation

### Differences 🔄

| Aspect | Derik's Original | SE-QPT Current |
|--------|------------------|----------------|
| **Use Case** | Individual competency survey (standalone) | Two-phase organizational assessment |
| **Survey Types** | 3 types (known_roles, unknown_roles, all_roles) | Currently only known_roles in Phase 2 |
| **Role Integration** | Optional (only for reference) | Central (organizational role definitions) |
| **Database Naming** | `new_survey_user` table | `app_user` + `organization_roles` |
| **Frontend Framework** | Vue 2 + Vuetify | Vue 3 + Element Plus |
| **Backend Structure** | Flask monolith | Flask with service layer |
| **FAISS Index** | Lives in app root | `src/backend/app/faiss_index/` |

### What SE-QPT Already Has (vs Derik)
- ✅ More sophisticated role management system
- ✅ Organization multi-tenancy
- ✅ Phase-based workflow
- ✅ LLM role suggestion (added recently)
- ✅ Better error handling and validation

---

## Questions for User/Advisor

1. **Maturity Threshold**: Exact value for "defined and established"?
   - Option A: `process_score < 3.0`
   - Option B: `process_score < 2.5`
   - Option C: Different calculation?

2. **Task Field Requirement**: Confirm advisor's guidance
   - Current Phase 1: ALL THREE required
   - Current Phase 2 (unused): AT LEAST ONE required
   - Advisor said: NOT mandatory (user can fill any or all)
   - **Which is correct?**

3. **Username Format**: How to identify Phase 2 task-based users?
   - Use authenticated user's username?
   - Generate new temp username?
   - Use email address?

4. **Data Persistence**: Should Phase 2 task-based data be saved?
   - Save for future reference (org can see employee assessments)
   - Temporary (delete after session)
   - Anonymous (no user tracking)

5. **UI/UX**: When maturity < 3.0, should user:
   - **Option A**: Only see task-based pathway (no choice)
   - **Option B**: See both options (task-based recommended)
   - **Option C**: See explanation + ability to override

---

## Recommendation

**REUSE EXISTING SYSTEM** with minimal modifications:

### Phase 1 Fix (Optional, 30 min)
Update validation to allow optional fields:
- `src/frontend/src/components/phase1/task2/TaskBasedMapping.vue`
- Change AND logic to OR logic (lines 289-296, 327-338)

### Phase 2 Integration (Main Work, 3-4 hours)

**Step 1**: Add maturity passthrough (30 min)
- Store Phase 1 `process_score` in `organization` table or session
- Pass to Phase 2 on start

**Step 2**: Conditional routing (1 hour)
- Modify `Phase2TaskFlowContainer.vue`
- Add `if (maturityLevel < 3.0)` check
- Render `DerikTaskSelector` as first step

**Step 3**: Backend endpoint parameter (30 min)
- Add `survey_type` support to competency fetch
- Handle both role-based and task-based queries

**Step 4**: Competency retrieval (1 hour)
- Update `Phase2NecessaryCompetencies.vue`
- Query correct matrix based on pathway
- Display appropriate labels

**Step 5**: Testing (1 hour)
- Test both pathways end-to-end
- Verify data flows correctly
- Check edge cases

### Total Estimated Time: 4-5 hours

---

## Next Steps

1. **Clarify Requirements**: Get answers to questions above
2. **Choose Implementation**: Confirm reuse approach
3. **Create Todo List**: Break down tasks
4. **Fix Phase 1** (if needed): Make fields optional
5. **Implement Phase 2**: Integrate task-based pathway
6. **Test Thoroughly**: Both pathways + edge cases
7. **Document**: Update user guides and API docs

---

## Conclusion

The good news: **Everything you need already exists in the codebase!**

The SE-QPT system has:
- ✅ Fully functional task-based assessment pipeline
- ✅ Production-ready AI integration
- ✅ Database schema and stored procedures
- ✅ Frontend component (DerikTaskSelector) ready to use
- ✅ 4,444 rows of real data proving it works

The work required is **integration**, not development from scratch. We need to:
1. Connect Phase 2 to existing task-based system
2. Add conditional routing based on maturity level
3. Ensure data flows between components

**Estimated effort**: 4-5 hours for full implementation and testing.

**Risk level**: Low (reusing proven components)

**Recommended approach**: Reuse existing system, don't port from Derik's codebase.
