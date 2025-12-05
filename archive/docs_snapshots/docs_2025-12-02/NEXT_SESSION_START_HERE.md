# Next Session: Phase 2 Task-Based Assessment Integration

**Created**: 2025-10-30 23:15
**Priority**: HIGH
**Estimated Time**: 3-4 hours

---

## Session Context

You want to add task-based competency assessment to Phase 2. When Phase 1 maturity level < 3 ("defined and established"), Phase 2 should show task-based assessment instead of role selection.

**Good News**: Everything you need already exists in the codebase! Just needs integration.

---

## What Was Completed in Last Session

✅ **CRITICAL BUG FIXED**: Changed `"Designing": 4` to `3` in `routes.py:2097`
✅ **Comprehensive Analysis**: Compared SE-QPT with Derik's original code (95% match)
✅ **Maturity Threshold Found**: `seProcessesValue >= 3` (line 146 in RoleIdentification.vue)
✅ **System Validated**: Task-based components are production-ready
✅ **Documentation Created**:
  - TASK_BASED_ASSESSMENT_STATUS.md
  - DERIK_COMPARISON_REPORT.md

---

## Quick Reference

### Maturity Threshold
```javascript
// RoleIdentification.vue line 146
const MATURITY_THRESHOLD = 3 // "Defined and Established"
return seProcessesValue >= 3 ? 'STANDARD' : 'TASK_BASED'
```

### Backend Route (Working)
```
POST http://127.0.0.1:5000/findProcesses
{
  "username": "test_user",
  "organizationId": 1,
  "tasks": {
    "responsible_for": ["Software development"],
    "supporting": ["Code reviews"],
    "designing": ["System architecture"]
  }
}
```

### Database Tables (Active)
- `unknown_role_process_matrix` (2,908 rows)
- `unknown_role_competency_matrix` (1,536 rows)

### Frontend Component (Ready)
- `src/frontend/src/components/phase2/DerikTaskSelector.vue`
- Validation: "At least one field required" ✅

---

## Implementation Plan (Next Session)

### Step 1: Pass Maturity Data to Phase 2 (30 min)

**Option A - Via Route Query Parameter**:
```javascript
// When navigating to Phase 2
router.push({
  path: '/app/phases/2',
  query: {
    orgId: organizationId,
    maturityLevel: seProcessesValue
  }
})
```

**Option B - Via Vuex/Pinia Store**:
```javascript
// Phase1Store
const phase1Results = ref({
  organizationId: null,
  maturityLevel: null,
  seProcessesValue: null,
  // ...
})
```

**Recommendation**: Use Option A (query parameter) - simpler and more explicit.

### Step 2: Conditional Routing in Phase 2 (1 hour)

**File**: `src/frontend/src/components/phase2/Phase2TaskFlowContainer.vue`

**Current Flow**:
```
role-selection → necessary-competencies → assessment → results
```

**New Flow**:
```javascript
// Add prop
const props = defineProps({
  organizationId: Number,
  employeeName: String,
  maturityLevel: Number  // NEW
})

// Determine pathway
const pathway = computed(() => {
  return props.maturityLevel < 3 ? 'TASK_BASED' : 'ROLE_BASED'
})

// Initial step
const currentStep = ref(
  pathway.value === 'TASK_BASED' ? 'task-input' : 'role-selection'
)
```

**Add DerikTaskSelector**:
```vue
<DerikTaskSelector
  v-if="currentStep === 'task-input'"
  @tasksAnalyzed="handleTasksAnalyzed"
  @switchToRoleBased="handleSwitchToRoleBased"
/>
```

**Handle Task Analysis Results**:
```javascript
const handleTasksAnalyzed = (analysisResult) => {
  // Store username from task analysis
  taskBasedUsername.value = analysisResult.username

  // Move to competency review
  currentStep.value = 'necessary-competencies'
}
```

### Step 3: Update Competency Fetching (1 hour)

**File**: `src/frontend/src/components/phase2/Phase2NecessaryCompetencies.vue`

**Add Props**:
```javascript
const props = defineProps({
  competencies: Array,
  selectedRoles: Array,
  organizationId: Number,
  pathway: String,  // NEW: 'ROLE_BASED' or 'TASK_BASED'
  username: String   // NEW: For task-based pathway
})
```

**Fetch Competencies**:
```javascript
const fetchCompetencies = async () => {
  if (props.pathway === 'TASK_BASED') {
    // Fetch from unknown_role_competency_matrix
    const response = await phase2Api.getTaskBasedCompetencies(
      props.username,
      props.organizationId
    )
    competencies.value = response.data
  } else {
    // Fetch from role_competency_matrix (current logic)
    const response = await phase2Api.getRoleBasedCompetencies(
      props.selectedRoles,
      props.organizationId
    )
    competencies.value = response.data
  }
}
```

### Step 4: Backend Endpoint (30 min)

**File**: `src/backend/app/routes.py`

**Add New Endpoint**:
```python
@main_bp.route('/get_task_based_competencies', methods=['POST'])
def get_task_based_competencies():
    """
    Get required competencies for task-based assessment
    Query: unknown_role_competency_matrix
    """
    data = request.get_json()
    username = data.get('username')
    organization_id = data.get('organization_id')

    # Query unknown_role_competency_matrix
    competencies = db.session.query(
        UnknownRoleCompetencyMatrix.competency_id,
        Competency.name,
        Competency.competency_area,
        UnknownRoleCompetencyMatrix.role_competency_value.label('max_value')
    ).join(
        Competency,
        UnknownRoleCompetencyMatrix.competency_id == Competency.id
    ).filter(
        UnknownRoleCompetencyMatrix.user_name == username,
        UnknownRoleCompetencyMatrix.organization_id == organization_id,
        UnknownRoleCompetencyMatrix.role_competency_value > 0  # Filter out non-required
    ).all()

    return jsonify([{
        'competency_id': c.competency_id,
        'name': c.name,
        'category': c.competency_area,
        'max_value': c.max_value
    } for c in competencies])
```

**Or Extend Existing Endpoint**:
```python
@main_bp.route('/get_required_competencies_for_roles', methods=['POST'])
def get_required_competencies_for_roles():
    data = request.get_json()
    survey_type = data.get('survey_type', 'known_roles')  # NEW parameter

    if survey_type == 'unknown_roles':
        username = data.get('user_name')
        organization_id = data.get('organization_id')
        # Query unknown_role_competency_matrix
        # ...
    else:
        # Existing role-based logic
        # ...
```

**Recommendation**: Extend existing endpoint with `survey_type` parameter.

### Step 5: Testing (1 hour)

**Test Cases**:
1. ✅ Maturity level >= 3 → Role-based pathway (existing)
2. ✅ Maturity level < 3 → Task-based pathway (new)
3. ✅ One task field filled → Valid
4. ✅ Two task fields filled → Valid
5. ✅ All three fields filled → Valid
6. ✅ All fields empty → Show defaults, require at least one
7. ✅ Competencies calculated correctly (not -100)
8. ✅ Survey works with task-based competencies
9. ✅ Results show correct gaps

---

## Key Files to Modify

### Frontend
1. `src/frontend/src/views/phases/Phase2NewFlow.vue` - Pass maturityLevel prop
2. `src/frontend/src/components/phase2/Phase2TaskFlowContainer.vue` - Add conditional routing
3. `src/frontend/src/components/phase2/Phase2NecessaryCompetencies.vue` - Support both pathways
4. `src/frontend/src/api/phase2.js` - Add task-based competency fetch

### Backend
5. `src/backend/app/routes.py` - Extend `/get_required_competencies_for_roles` with survey_type

### No Changes Needed
- ✅ Database tables (already exist)
- ✅ Stored procedure (already works)
- ✅ LLM pipeline (already works)
- ✅ DerikTaskSelector component (already works)

---

## Potential Issues to Watch

1. **Username Format**: Task-based uses different username format than role-based
   - Phase 1: `phase1_temp_1761080345662_5i6al8edx`
   - Phase 2 task-based: Use authenticated user's username or generate new temp

2. **Competency Matrix Source**: Make sure to query correct table
   - Role-based: `role_competency_matrix`
   - Task-based: `unknown_role_competency_matrix`

3. **Data Persistence**: Decide if task analysis should be saved per user or per session

4. **Survey Results**: Ensure results comparison works for both pathways

---

## Start Commands

**Backend**:
```bash
cd src/backend
PYTHONUNBUFFERED=1 ../../venv/Scripts/python.exe run.py
```

**Frontend** (if needed):
```bash
cd src/frontend
npm run dev
```

**Database**:
```bash
PGPASSWORD=SeQpt_2025 psql -U seqpt_admin -d seqpt_database -h localhost -p 5432
```

---

## Verify Bug Fix is Active

Before starting, verify the bug fix is applied:
```bash
cd src/backend/app
grep -A 3 "involvement_values = {" routes.py
# Should show: "Designing": 3 (not 4)
```

If you see 4, apply the fix again from DERIK_COMPARISON_REPORT.md.

---

## Success Criteria

✅ User with maturity < 3 sees task input form
✅ User with maturity >= 3 sees role selection (existing)
✅ Task analysis produces valid competencies
✅ Competency values are not -100
✅ Survey works with task-based requirements
✅ Results show correct gaps and strengths
✅ Both pathways work independently

---

## Documentation References

- **TASK_BASED_ASSESSMENT_STATUS.md**: System status and architecture
- **DERIK_COMPARISON_REPORT.md**: Detailed comparison and bug fix
- **SESSION_HANDOVER.md**: Latest session details (compacted, 1,512 lines)
- **SESSION_HANDOVER_ARCHIVE_2025-10-30.md**: Older sessions (archived)

---

**Ready to Code!** All groundwork is done. Just needs integration. 🚀
