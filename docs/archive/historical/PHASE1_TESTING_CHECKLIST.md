# Phase 1 Implementation Testing Checklist
## Comprehensive Validation Guide for SE-QPT Questionnaire System

**Date Created**: 2025-10-13
**Implementation Reference**: PHASE1_IMPLEMENTATION_COMPLETE.md
**Session**: 2025-10-13 15:30

---

## Pre-Testing Verification

### System Status
- [ ] Backend Flask server running on http://127.0.0.1:5000
- [ ] Frontend Vite server running on http://localhost:3000
- [ ] PostgreSQL database accessible (ma0349:MA0349_2025@localhost:5432/competency_assessment)
- [ ] No console errors in either server output

### Database State Check
```sql
-- Verify existing Phase 1 data structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'organization'
AND column_name IN ('maturity_score', 'selected_archetype', 'maturity_responses', 'archetype_responses', 'phase1_completed');
```

**Expected Columns**:
- [ ] maturity_score (numeric)
- [ ] selected_archetype (varchar)
- [ ] maturity_responses (jsonb)
- [ ] archetype_responses (jsonb)
- [ ] phase1_completed (boolean)
- [ ] phase1_completed_at (timestamp)

---

## PHASE 1A: Maturity Assessment Testing

### Test 1.1: Questionnaire Loading
**Objective**: Verify JSON file loads correctly with all 12 questions

**Steps**:
1. [ ] Navigate to http://localhost:3000 (or wherever Phase 1 starts)
2. [ ] Click to start Maturity Assessment questionnaire
3. [ ] Verify questionnaire loads without errors

**Expected Results**:
- [ ] No console errors in browser dev tools (F12)
- [ ] No Flask errors in backend terminal
- [ ] Questionnaire UI displays properly

**Data to Verify**:
- [ ] Total question count: 12 questions
- [ ] Section headers visible (if frontend implements sections):
  - [ ] "Fundamentals" (3 questions)
  - [ ] "Organization" (4 questions)
  - [ ] "Process Capability" (3 questions)
  - [ ] "Infrastructure" (2 questions)

---

### Test 1.2: Question Display and Content
**Objective**: Verify all questions display correctly with proper content

**For Each Question, Verify**:

#### MAT_01: SE Mindset & Culture (Fundamentals)
- [ ] Question text: "How established is the Systems Engineering mindset and culture in your organization?"
- [ ] Scale type: 0-4 (5 options)
- [ ] Options display correctly:
  - [ ] 0: Not present
  - [ ] 1: Initial awareness exists
  - [ ] 2: Recognized but not consistently applied
  - [ ] 3: Established and practiced
  - [ ] 4: Fully embedded in organizational culture

#### MAT_02: Knowledge Base (Fundamentals)
- [ ] Question text: "How comprehensive is the SE knowledge base and documentation?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

#### MAT_03: Tailoring Concept (Fundamentals)
- [ ] Question text: "Does your organization have a documented SE tailoring concept?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

#### MAT_04: SE Roles and Processes (Organization) **[ROUTING CRITICAL]**
- [ ] Question text: "How are SE roles, responsibilities, and processes defined?"
- [ ] Scale type: 0-4 (5 options)
- [ ] Help text/indicator shows this is routing-critical (if implemented)
- [ ] All 5 options display correctly:
  - [ ] 0: No defined SE roles
  - [ ] 1: Ad hoc SE responsibilities
  - [ ] 2: Individually controlled processes
  - [ ] 3: Defined and established roles
  - [ ] 4: Optimized with continuous improvement

**CRITICAL**: Note the value selected - this determines archetype path!

#### MAT_05: Rollout Scope (Organization) **[ROUTING CRITICAL]**
- [ ] Question text: "What is the scope of SE application in your organization?"
- [ ] Scale type: 0-4 (5 options)
- [ ] Help text/indicator shows this is routing-critical (if implemented)
- [ ] All 5 options display correctly:
  - [ ] 0: SE not currently used
  - [ ] 1: Individual area/project
  - [ ] 2: Multiple areas/projects
  - [ ] 3: Company-wide rollout
  - [ ] 4: Integrated across entire enterprise

**CRITICAL**: Note the value selected - this determines high-maturity archetype!

#### MAT_06: Training Concept (Organization)
- [ ] Question text: "How structured is your SE training and qualification concept?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

#### MAT_07: SE Organizational Structure (Organization)
- [ ] Question text: "How is SE integrated into the organizational structure?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

#### MAT_08: Requirements Management (Process Capability)
- [ ] Question text: "How mature is your requirements management process?"
- [ ] Scale type: 0-5 (6 options)
- [ ] All 6 options display (note: 0-5 scale)

#### MAT_09: System Architecture (Process Capability)
- [ ] Question text: "How well-defined is your system architecture and design process?"
- [ ] Scale type: 0-5 (6 options)
- [ ] All 6 options display (note: 0-5 scale)

#### MAT_10: V&V Process (Process Capability)
- [ ] Question text: "How mature is your verification and validation process?"
- [ ] Scale type: 0-5 (6 options)
- [ ] All 6 options display (note: 0-5 scale)

#### MAT_11: Tool Integration (Infrastructure)
- [ ] Question text: "What is the level of SE tool integration?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

#### MAT_12: MBSE Adoption (Infrastructure)
- [ ] Question text: "What is the status of Model-Based Systems Engineering (MBSE) adoption?"
- [ ] Scale type: 0-4 (5 options)
- [ ] All 5 options display

---

### Test 1.3: Maturity Score Calculation - Low Maturity
**Objective**: Test scoring algorithm with low maturity inputs

**Test Data Set**:
```
MAT_01: 0 (Not present)
MAT_02: 0 (No documentation)
MAT_03: 0 (No tailoring concept)
MAT_04: 0 (No defined SE roles) **[ROUTING]**
MAT_05: 0 (SE not currently used) **[ROUTING]**
MAT_06: 0 (No training concept)
MAT_07: 0 (No integration)
MAT_08: 0 (No requirements process)
MAT_09: 0 (No architecture process)
MAT_10: 0 (No V&V process)
MAT_11: 0 (No tool integration)
MAT_12: 0 (No MBSE)
```

**Steps**:
1. [ ] Select all "0" values (lowest option for each question)
2. [ ] Submit maturity assessment
3. [ ] Note the calculated maturity score

**Expected Maturity Score**: 0.0 (Initial Level)

**Verification**:
- [ ] Score displayed in UI
- [ ] Score saved to database (organization.maturity_score)
- [ ] Level label shows "Initial" or equivalent
- [ ] MAT_04 value (0) saved correctly for routing
- [ ] MAT_05 value (0) saved correctly for routing

**Backend Logs to Check**:
- [ ] Look for maturity score calculation logs
- [ ] Verify weighted average calculation
- [ ] No errors in Flask console

---

### Test 1.4: Maturity Score Calculation - High Maturity
**Objective**: Test scoring algorithm with high maturity inputs

**Test Data Set**:
```
MAT_01: 4 (Fully embedded)
MAT_02: 4 (Comprehensive)
MAT_03: 4 (Fully implemented)
MAT_04: 4 (Optimized) **[ROUTING]**
MAT_05: 4 (Enterprise-wide) **[ROUTING]**
MAT_06: 4 (Comprehensive program)
MAT_07: 4 (Fully integrated)
MAT_08: 5 (Optimized)
MAT_09: 5 (Optimized)
MAT_10: 5 (Optimized)
MAT_11: 4 (Fully integrated)
MAT_12: 4 (Organization-wide)
```

**Steps**:
1. [ ] Select all highest values for each question
2. [ ] Submit maturity assessment
3. [ ] Note the calculated maturity score

**Expected Maturity Score**: ~4.0-4.5 (Managed/Optimized Level)

**Verification**:
- [ ] Score displayed in UI
- [ ] Score saved to database
- [ ] Level label shows "Managed" or "Optimized"
- [ ] MAT_04 value (4) saved correctly
- [ ] MAT_05 value (4) saved correctly

---

### Test 1.5: Maturity Score Calculation - Medium Maturity
**Objective**: Test scoring algorithm with mixed inputs

**Test Data Set**:
```
MAT_01: 2 (Recognized)
MAT_02: 2 (Basic documentation)
MAT_03: 2 (Concept exists)
MAT_04: 2 (Individually controlled) **[ROUTING]**
MAT_05: 1 (Individual area) **[ROUTING]**
MAT_06: 2 (Basic training)
MAT_07: 2 (Partial integration)
MAT_08: 2 (Defined)
MAT_09: 2 (Defined)
MAT_10: 2 (Defined)
MAT_11: 2 (Partially integrated)
MAT_12: 2 (Pilot projects)
```

**Steps**:
1. [ ] Select middle-range values
2. [ ] Submit maturity assessment
3. [ ] Note the calculated maturity score

**Expected Maturity Score**: ~2.0 (Defined Level)

**Verification**:
- [ ] Score calculation matches expected range
- [ ] MAT_04 = 2 (above threshold for high-maturity path)
- [ ] MAT_05 = 1 (below threshold, should select "Needs-based")

---

### Test 1.6: Data Persistence Check
**Objective**: Verify maturity responses saved to database

**After completing any maturity assessment**:

```sql
-- Check saved data
SELECT id, organization_name, maturity_score, maturity_responses
FROM organization
WHERE phase1_completed = true
ORDER BY phase1_completed_at DESC
LIMIT 1;
```

**Verify**:
- [ ] maturity_score matches calculated score
- [ ] maturity_responses JSON contains all 12 responses
- [ ] MAT_04 value accessible: `maturity_responses->>'MAT_04'`
- [ ] MAT_05 value accessible: `maturity_responses->>'MAT_05'`
- [ ] JSON format is valid and complete

---

## PHASE 1B: Archetype Selection Testing

### Test 2.1: LOW MATURITY PATH - Pilot Project
**Objective**: Test dual selection with pilot project preference

**Prerequisites**:
- [ ] Complete maturity assessment with MAT_04 = 0 or 1 (trigger low maturity path)

**Test Data**:
```
Maturity Assessment:
- MAT_04: 1 (Ad hoc SE responsibilities)
- MAT_05: 0 (SE not currently used)
- Other scores: 0-1 range

Archetype Questions:
- ARCH_01: "apply_pilot" (Apply in pilot project)
- ARCH_02: 2 (Management moderately ready)
- ARCH_03: 3 (Pilot project available) **[conditional on ARCH_01]**
- ARCH_06: "medium" (6-15 employees)
- ARCH_07: "short" (3-6 months)
```

**Steps**:
1. [ ] Complete maturity assessment with MAT_04 ≤ 1
2. [ ] Navigate to archetype selection
3. [ ] Verify LOW MATURITY questions appear:
   - [ ] ARCH_01 visible
   - [ ] ARCH_02 visible
   - [ ] ARCH_03 visible (conditional)
   - [ ] ARCH_06 visible
   - [ ] ARCH_07 visible
4. [ ] Verify HIGH MATURITY questions DO NOT appear:
   - [ ] ARCH_04 not visible
   - [ ] ARCH_05 not visible
5. [ ] Select "apply_pilot" for ARCH_01
6. [ ] Verify ARCH_03 appears (conditional display)
7. [ ] Complete all questions
8. [ ] Submit archetype selection

**Expected Result**:
```json
{
  "success": true,
  "archetype": {
    "name": "SE for Managers + Orientation in Pilot Project",
    "primary": "SE for Managers",
    "secondary": "Orientation in Pilot Project",
    "selection_type": "dual",
    "requires_dual_processing": true,
    "supplementary": [],
    "rationale": "Low SE maturity requires executive-level understanding (SE for Managers) combined with practical pilot application (Orientation in Pilot Project)."
  }
}
```

**Verification**:
- [ ] Primary archetype: "SE for Managers"
- [ ] Secondary archetype: "Orientation in Pilot Project"
- [ ] selection_type: "dual"
- [ ] No supplementary archetypes (ARCH_06 not "enterprise", ARCH_07 not "long")
- [ ] UI displays both primary and secondary
- [ ] Database saves correct archetype string

**Backend Logs**:
- [ ] Look for `[ARCHETYPE] Routing variables: MAT_04=1, MAT_05=0`
- [ ] Look for `[ARCHETYPE] Low maturity path selected`
- [ ] Look for `[ARCHETYPE] Secondary archetype: Orientation in Pilot Project`

---

### Test 2.2: LOW MATURITY PATH - Common Understanding
**Objective**: Test dual selection with awareness-building preference

**Prerequisites**:
- [ ] Complete maturity assessment with MAT_04 ≤ 1

**Test Data**:
```
Maturity Assessment:
- MAT_04: 0 (No defined SE roles)
- MAT_05: 0 (SE not currently used)

Archetype Questions:
- ARCH_01: "build_awareness" (Build common understanding)
- ARCH_02: 1 (Management low readiness)
- ARCH_06: "small" (1-5 employees)
- ARCH_07: "medium" (6-12 months)
```

**Expected Result**:
```json
{
  "primary": "SE for Managers",
  "secondary": "Common Basic Understanding",
  "selection_type": "dual",
  "supplementary": []
}
```

**Verification**:
- [ ] Secondary archetype: "Common Basic Understanding"
- [ ] ARCH_03 did NOT appear (only shows for "apply_pilot")

---

### Test 2.3: LOW MATURITY PATH - Certification
**Objective**: Test dual selection with expert development preference

**Test Data**:
```
Maturity Assessment:
- MAT_04: 1 (Ad hoc)
- MAT_05: 0

Archetype Questions:
- ARCH_01: "develop_experts" (Develop SE experts)
- ARCH_02: 3 (Management ready)
- ARCH_06: "large" (16-50 employees)
- ARCH_07: "short" (3-6 months)
```

**Expected Result**:
```json
{
  "primary": "SE for Managers",
  "secondary": "Certification",
  "selection_type": "dual",
  "supplementary": []
}
```

**Verification**:
- [ ] Secondary archetype: "Certification"

---

### Test 2.4: HIGH MATURITY PATH - Needs-Based Training
**Objective**: Test single selection for limited scope

**Prerequisites**:
- [ ] Complete maturity assessment with MAT_04 > 1

**Test Data**:
```
Maturity Assessment:
- MAT_04: 2 (Individually controlled processes)
- MAT_05: 1 (Individual area/project)
- Other scores: 2 range

Archetype Questions:
- ARCH_04: Auto-calculated (should not require user input)
- ARCH_05: "project_specific" (Project-specific learning)
- ARCH_06: "large" (16-50 employees)
- ARCH_07: "medium" (6-12 months)
```

**Steps**:
1. [ ] Complete maturity with MAT_04 = 2, MAT_05 = 1
2. [ ] Navigate to archetype selection
3. [ ] Verify HIGH MATURITY questions appear:
   - [ ] ARCH_05 visible
   - [ ] ARCH_06 visible
   - [ ] ARCH_07 visible
4. [ ] Verify LOW MATURITY questions DO NOT appear:
   - [ ] ARCH_01 not visible
   - [ ] ARCH_02 not visible
   - [ ] ARCH_03 not visible
5. [ ] Verify ARCH_04 handling (auto-calculated or hidden)
6. [ ] Complete questions
7. [ ] Submit

**Expected Result**:
```json
{
  "name": "Needs-based Project-oriented Training",
  "primary": "Needs-based Project-oriented Training",
  "secondary": null,
  "selection_type": "single",
  "supplementary": []
}
```

**Verification**:
- [ ] Single archetype selected (not dual)
- [ ] Archetype: "Needs-based Project-oriented Training"
- [ ] Decision based on MAT_05 ≤ 1

**Backend Logs**:
- [ ] `[ARCHETYPE] High maturity path selected (MAT_04 > 1)`
- [ ] `[ARCHETYPE] Limited scope (MAT_05 <= 1): Needs-based`

---

### Test 2.5: HIGH MATURITY PATH - Continuous Support
**Objective**: Test single selection for broad scope

**Test Data**:
```
Maturity Assessment:
- MAT_04: 3 (Defined and established roles)
- MAT_05: 3 (Company-wide rollout)
- Other scores: 3 range

Archetype Questions:
- ARCH_05: "continuous" (Continuous learning)
- ARCH_06: "medium" (6-15 employees)
- ARCH_07: "short" (3-6 months)
```

**Expected Result**:
```json
{
  "name": "Continuous Support",
  "primary": "Continuous Support",
  "secondary": null,
  "selection_type": "single",
  "supplementary": []
}
```

**Verification**:
- [ ] Archetype: "Continuous Support"
- [ ] Decision based on MAT_05 ≥ 2

**Backend Logs**:
- [ ] `[ARCHETYPE] Broad scope (MAT_05 >= 2): Continuous Support`

---

### Test 2.6: SUPPLEMENTARY - Train the Trainer (Large Scale)
**Objective**: Test Train the Trainer suggestion based on enterprise size

**Test Data**:
```
Maturity Assessment:
- MAT_04: 3
- MAT_05: 3

Archetype Questions:
- ARCH_05: "continuous"
- ARCH_06: "enterprise" (50+ employees) **[TRIGGER]**
- ARCH_07: "medium" (6-12 months)
```

**Expected Result**:
```json
{
  "name": "Continuous Support",
  "selection_type": "single",
  "supplementary": [
    {
      "name": "Train the Trainer",
      "rationale": "Large-scale implementation (50+ employees) benefits from internal trainer development to ensure sustainable SE knowledge transfer."
    }
  ]
}
```

**Verification**:
- [ ] Primary: "Continuous Support"
- [ ] Supplementary includes "Train the Trainer"
- [ ] Rationale mentions enterprise size

---

### Test 2.7: SUPPLEMENTARY - Train the Trainer (Long Timeline)
**Objective**: Test Train the Trainer suggestion based on timeline

**Test Data**:
```
Archetype Questions:
- ARCH_06: "medium" (6-15 employees)
- ARCH_07: "long" (12+ months) **[TRIGGER]**
```

**Expected Result**:
- [ ] Supplementary includes "Train the Trainer"
- [ ] Rationale mentions long timeline

---

### Test 2.8: SUPPLEMENTARY - Train the Trainer (Both Triggers)
**Objective**: Test Train the Trainer with both conditions met

**Test Data**:
```
Archetype Questions:
- ARCH_06: "enterprise" (50+) **[TRIGGER]**
- ARCH_07: "long" (12+ months) **[TRIGGER]**
```

**Expected Result**:
- [ ] Supplementary includes "Train the Trainer"
- [ ] Rationale mentions both scale and timeline
- [ ] Only ONE Train the Trainer entry (not duplicated)

---

### Test 2.9: Conditional Question Display - ARCH_03
**Objective**: Verify ARCH_03 only appears when ARCH_01 = "apply_pilot"

**Test Variations**:

**Variation A: ARCH_01 = "apply_pilot"**
- [ ] ARCH_03 appears after selecting ARCH_01
- [ ] ARCH_03 question: "Is a suitable pilot project available?"

**Variation B: ARCH_01 = "build_awareness"**
- [ ] ARCH_03 does NOT appear
- [ ] Skip directly to ARCH_06

**Variation C: ARCH_01 = "develop_experts"**
- [ ] ARCH_03 does NOT appear

**Note**: This tests frontend conditional logic if implemented

---

### Test 2.10: Data Persistence - Archetype Responses
**Objective**: Verify archetype responses saved correctly

**After completing any archetype selection**:

```sql
-- Check saved archetype data
SELECT id, organization_name, selected_archetype, archetype_responses
FROM organization
WHERE phase1_completed = true
ORDER BY phase1_completed_at DESC
LIMIT 1;
```

**Verify**:
- [ ] selected_archetype matches result
- [ ] archetype_responses JSON contains all responses
- [ ] Dual selection format (if applicable):
  ```json
  {
    "primary": "SE for Managers",
    "secondary": "Orientation in Pilot Project",
    "supplementary": []
  }
  ```

---

## PHASE 1C: Integration Testing

### Test 3.1: Complete End-to-End Flow - Low Maturity
**Objective**: Test full Phase 1 flow from start to finish

**Steps**:
1. [ ] Start fresh (or create new test organization)
2. [ ] Complete maturity assessment (MAT_04 = 0, all low scores)
3. [ ] Verify maturity score calculated and saved
4. [ ] Proceed to archetype selection
5. [ ] Verify low maturity questions appear
6. [ ] Complete archetype selection (ARCH_01 = "build_awareness")
7. [ ] Verify dual selection result
8. [ ] Confirm phase1_completed flag set to true
9. [ ] Verify phase1_completed_at timestamp set

**Expected Final Database State**:
```sql
SELECT maturity_score, selected_archetype, phase1_completed, phase1_completed_at
FROM organization
WHERE id = [test_org_id];
```

- [ ] maturity_score: ~0.0-0.5
- [ ] selected_archetype: "SE for Managers + Common Basic Understanding"
- [ ] phase1_completed: true
- [ ] phase1_completed_at: [recent timestamp]

---

### Test 3.2: Complete End-to-End Flow - High Maturity
**Objective**: Test full flow with high maturity organization

**Steps**:
1. [ ] Complete maturity assessment (MAT_04 = 4, MAT_05 = 4, all high scores)
2. [ ] Verify maturity score ~4.0+
3. [ ] Proceed to archetype selection
4. [ ] Verify high maturity questions appear
5. [ ] Complete (ARCH_05 = "continuous", ARCH_06 = "enterprise", ARCH_07 = "long")
6. [ ] Verify single selection + Train the Trainer

**Expected Result**:
- [ ] maturity_score: ~4.0-4.5
- [ ] selected_archetype: "Continuous Support"
- [ ] supplementary: ["Train the Trainer"]

---

### Test 3.3: Boundary Condition - MAT_04 Threshold
**Objective**: Test exact boundary at MAT_04 = 1 vs 2

**Test A: MAT_04 = 1 (should use LOW path)**
- [ ] Complete maturity with MAT_04 = 1
- [ ] Verify LOW maturity questions appear (ARCH_01-03)
- [ ] Verify dual selection result

**Test B: MAT_04 = 2 (should use HIGH path)**
- [ ] Complete maturity with MAT_04 = 2
- [ ] Verify HIGH maturity questions appear (ARCH_04-05)
- [ ] Verify single selection result

**Verification**:
- [ ] MAT_04 = 1: LOW path (dual)
- [ ] MAT_04 = 2: HIGH path (single)
- [ ] Boundary condition at 1 < MAT_04 ≤ 2

---

### Test 3.4: Boundary Condition - MAT_05 Threshold
**Objective**: Test MAT_05 routing within high maturity path

**Test A: MAT_04 = 3, MAT_05 = 1 (limited scope)**
- [ ] Expected: "Needs-based Project-oriented Training"

**Test B: MAT_04 = 3, MAT_05 = 2 (broad scope)**
- [ ] Expected: "Continuous Support"

**Verification**:
- [ ] MAT_05 ≤ 1: Needs-based
- [ ] MAT_05 ≥ 2: Continuous Support
- [ ] Boundary at 1 < MAT_05 ≤ 2

---

### Test 3.5: Multiple Organizations
**Objective**: Test phase1 data isolation between organizations

**Steps**:
1. [ ] Complete Phase 1 for Organization A (low maturity)
2. [ ] Complete Phase 1 for Organization B (high maturity)
3. [ ] Query database for both organizations

**Verify**:
- [ ] Organization A has low maturity score and dual archetype
- [ ] Organization B has high maturity score and single archetype
- [ ] Data not mixed between organizations
- [ ] Both phase1_completed = true

---

## PHASE 1D: Frontend Compatibility Testing

### Test 4.1: QuestionnaireComponent Compatibility
**Objective**: Verify existing frontend handles new JSON structure

**File to Check**: Frontend questionnaire component (likely `QuestionnaireComponent.vue`)

**Verify**:
- [ ] Component loads maturity_assessment.json without errors
- [ ] All 12 questions render
- [ ] Radio buttons/selects work for each question
- [ ] Question numbering displays correctly (1-12)
- [ ] Section headers display (if implemented)
- [ ] Help text displays for routing-critical questions (if implemented)

**Potential Issues to Watch**:
- [ ] Does component handle 4 sections?
- [ ] Does it support weighted scoring?
- [ ] Does it handle 0-4 vs 0-5 scales?
- [ ] Does it handle routing_critical flag?

---

### Test 4.2: Conditional Question Logic
**Objective**: Test frontend conditional display (ARCH_03)

**If Frontend Implements Conditionals**:
- [ ] ARCH_03 only appears when ARCH_01 = "apply_pilot"
- [ ] ARCH_03 hidden for other ARCH_01 values
- [ ] No errors when conditions evaluated

**If Frontend Does NOT Implement Conditionals**:
- [ ] ARCH_03 always appears
- [ ] Backend handles missing value gracefully
- [ ] Note: Frontend enhancement needed

---

### Test 4.3: Auto-Calculated Fields
**Objective**: Test ARCH_04 (auto-calculated from MAT_05)

**Verify**:
- [ ] ARCH_04 does not require user input
- [ ] Backend calculates ARCH_04 from MAT_05
- [ ] Frontend either hides or auto-fills ARCH_04

---

### Test 4.4: Path-Based Question Display
**Objective**: Verify frontend shows correct questions based on maturity path

**Low Maturity Path (MAT_04 ≤ 1)**:
- [ ] Shows: ARCH_01, ARCH_02, ARCH_03 (conditional), ARCH_06, ARCH_07
- [ ] Hides: ARCH_04, ARCH_05

**High Maturity Path (MAT_04 > 1)**:
- [ ] Shows: ARCH_04 (auto), ARCH_05, ARCH_06, ARCH_07
- [ ] Hides: ARCH_01, ARCH_02, ARCH_03

**Note**: If frontend doesn't implement path-based display, backend should handle gracefully

---

### Test 4.5: Result Display
**Objective**: Verify archetype selection result displays correctly

**For Dual Selection**:
- [ ] Displays primary archetype prominently
- [ ] Displays secondary archetype clearly
- [ ] Indicates "dual selection" or "combined approach"
- [ ] Shows supplementary if present

**For Single Selection**:
- [ ] Displays single archetype
- [ ] Shows supplementary if present
- [ ] Clearly indicates single approach

---

## PHASE 1E: Scoring Algorithm Validation

### Test 5.1: Weighted Average Calculation
**Objective**: Manually verify hierarchical weighted scoring

**Test Input**:
```
Fundamentals (25% weight):
- MAT_01: 2 (weight 0.35) = 2 * 0.35 = 0.70
- MAT_02: 2 (weight 0.30) = 2 * 0.30 = 0.60
- MAT_03: 2 (weight 0.35) = 2 * 0.35 = 0.70
Fundamentals Score = (0.70 + 0.60 + 0.70) / 1.0 = 2.0

Organization (30% weight):
- MAT_04: 2 (weight 0.35) = 2 * 0.35 = 0.70
- MAT_05: 2 (weight 0.30) = 2 * 0.30 = 0.60
- MAT_06: 2 (weight 0.20) = 2 * 0.20 = 0.40
- MAT_07: 2 (weight 0.15) = 2 * 0.15 = 0.30
Organization Score = (0.70 + 0.60 + 0.40 + 0.30) / 1.0 = 2.0

Process Capability (25% weight):
- MAT_08: 2 (weight 0.35) = 2 * 0.35 = 0.70
- MAT_09: 2 (weight 0.35) = 2 * 0.35 = 0.70
- MAT_10: 2 (weight 0.30) = 2 * 0.30 = 0.60
Process Score = (0.70 + 0.70 + 0.60) / 1.0 = 2.0

Infrastructure (20% weight):
- MAT_11: 2 (weight 0.50) = 2 * 0.50 = 1.0
- MAT_12: 2 (weight 0.50) = 2 * 0.50 = 1.0
Infrastructure Score = (1.0 + 1.0) / 1.0 = 2.0

Overall Maturity = (2.0*0.25 + 2.0*0.30 + 2.0*0.25 + 2.0*0.20)
                 = (0.50 + 0.60 + 0.50 + 0.40)
                 = 2.0
```

**Expected Result**: Maturity Score = 2.0

**Verification**:
- [ ] Backend calculates 2.0
- [ ] Database stores 2.0
- [ ] Frontend displays 2.0

---

### Test 5.2: Weight Validation
**Objective**: Verify all weights sum to 1.0

**Section Weights**:
- [ ] Fundamentals: 0.25
- [ ] Organization: 0.30
- [ ] Process Capability: 0.25
- [ ] Infrastructure: 0.20
- [ ] **Total**: 1.0 ✓

**Fundamentals Question Weights**:
- [ ] MAT_01: 0.35
- [ ] MAT_02: 0.30
- [ ] MAT_03: 0.35
- [ ] **Total**: 1.0 ✓

**Organization Question Weights**:
- [ ] MAT_04: 0.35
- [ ] MAT_05: 0.30
- [ ] MAT_06: 0.20
- [ ] MAT_07: 0.15
- [ ] **Total**: 1.0 ✓

**Process Capability Question Weights**:
- [ ] MAT_08: 0.35
- [ ] MAT_09: 0.35
- [ ] MAT_10: 0.30
- [ ] **Total**: 1.0 ✓

**Infrastructure Question Weights**:
- [ ] MAT_11: 0.50
- [ ] MAT_12: 0.50
- [ ] **Total**: 1.0 ✓

---

### Test 5.3: Scale Consistency
**Objective**: Verify correct scale ranges applied

**Questions Using 0-4 Scale** (5 options):
- [ ] MAT_01 through MAT_07
- [ ] MAT_11, MAT_12
- [ ] All ARCH questions (except auto-calculated)

**Questions Using 0-5 Scale** (6 options):
- [ ] MAT_08 (Requirements Management)
- [ ] MAT_09 (System Architecture)
- [ ] MAT_10 (V&V Process)

**Verification**:
- [ ] No questions exceed their max scale value
- [ ] Score normalization handles different scales correctly

---

## PHASE 1F: Error Handling & Edge Cases

### Test 6.1: Incomplete Maturity Assessment
**Objective**: Test validation when questions skipped

**Steps**:
1. [ ] Start maturity assessment
2. [ ] Leave MAT_04 or MAT_05 unanswered
3. [ ] Attempt to submit

**Expected Behavior**:
- [ ] Validation error prevents submission
- [ ] Error message indicates which question is required
- [ ] Special emphasis on MAT_04 and MAT_05 (routing-critical)

---

### Test 6.2: Missing Routing Variables
**Objective**: Test backend handling of missing MAT_04/MAT_05

**Steps**:
1. [ ] Manually call archetype selection endpoint
2. [ ] Omit MAT_04 or MAT_05 from request

**Expected Backend Response**:
- [ ] HTTP 400 Bad Request
- [ ] Error message: "MAT_04 score required for archetype routing"
- [ ] Graceful error handling (no crash)

---

### Test 6.3: Invalid Score Values
**Objective**: Test validation of score ranges

**Test Cases**:
- [ ] MAT_01 = -1 (below min)
- [ ] MAT_01 = 5 (above max for 0-4 scale)
- [ ] MAT_08 = 6 (above max for 0-5 scale)
- [ ] MAT_04 = "invalid" (non-numeric)

**Expected**:
- [ ] Validation error
- [ ] Submission prevented
- [ ] Clear error message

---

### Test 6.4: Network Errors
**Objective**: Test handling of API failures

**Scenarios**:
1. [ ] Backend server down during submission
2. [ ] Timeout during score calculation
3. [ ] Database connection error

**Expected Frontend Behavior**:
- [ ] Error message displayed to user
- [ ] No silent failure
- [ ] Option to retry
- [ ] Form data preserved (not lost)

---

### Test 6.5: Concurrent Submissions
**Objective**: Test race conditions

**Steps**:
1. [ ] Open Phase 1 in two browser tabs
2. [ ] Complete different assessments simultaneously
3. [ ] Submit both

**Expected**:
- [ ] Both submissions succeed (or handled with proper locking)
- [ ] No data corruption
- [ ] Last submission wins (or proper conflict resolution)

---

## PHASE 1G: Regression Testing

### Test 7.1: Backward Compatibility
**Objective**: Verify existing Phase 1 data still works

**If Database Has Old Phase 1 Data**:
```sql
-- Check for existing organizations with old Phase 1 data
SELECT id, organization_name, maturity_score, selected_archetype
FROM organization
WHERE phase1_completed = true
AND maturity_responses IS NOT NULL;
```

**Verify**:
- [ ] Old data readable
- [ ] No errors when viewing old organizations
- [ ] Old archetype selections still valid
- [ ] Can complete new Phase 1 for new organizations

---

### Test 7.2: Phase 2 Integration
**Objective**: Ensure Phase 1 changes don't break Phase 2

**Steps**:
1. [ ] Complete Phase 1 with new questionnaires
2. [ ] Proceed to Phase 2 (competency assessment)
3. [ ] Verify Phase 2 loads correctly
4. [ ] Check archetype is used in competency mapping

**Expected**:
- [ ] Phase 2 receives correct archetype
- [ ] Competency matrix loads based on archetype
- [ ] No errors in Phase 1 to Phase 2 transition

---

## Test Results Summary

### Coverage Metrics
- [ ] Maturity Assessment: __/12 questions tested
- [ ] Archetype Selection: __/7 questions tested
- [ ] Low Maturity Path: __/3 secondary archetype options tested
- [ ] High Maturity Path: __/2 single archetype options tested
- [ ] Supplementary Logic: __/2 trigger conditions tested
- [ ] Boundary Conditions: __/4 tested
- [ ] Error Handling: __/5 scenarios tested

### Critical Issues Found
_(Document any critical issues that block deployment)_

1. Issue:
   - Severity: [Critical/High/Medium/Low]
   - Description:
   - Steps to reproduce:
   - Expected behavior:
   - Actual behavior:

### Non-Critical Issues Found
_(Document issues that can be addressed post-deployment)_

1. Issue:
   - Severity: [Medium/Low]
   - Description:
   - Workaround:

### Frontend Enhancement Recommendations
_(Features that would improve UX but aren't blocking)_

1. Conditional question display for ARCH_03
2. Section headers between questions
3. Help tooltips for routing-critical questions
4. Progress indicator showing section completion
5. Visual distinction between low/high maturity paths

---

## Deployment Readiness

### Pre-Deployment Checklist
- [ ] All critical tests pass
- [ ] No critical bugs found
- [ ] Scoring algorithm validated
- [ ] Data persistence verified
- [ ] Error handling adequate
- [ ] Documentation complete
- [ ] Backup files created
- [ ] Database migration tested (if applicable)

### Recommendation
- [ ] **READY FOR DEPLOYMENT** - All tests pass
- [ ] **NOT READY** - Critical issues found (see above)
- [ ] **READY WITH MINOR ISSUES** - Deploy with known limitations documented

---

## Notes and Observations

### Performance
- Questionnaire load time: ____ms
- Score calculation time: ____ms
- API response time: ____ms

### User Experience
- Question clarity: [Excellent/Good/Needs Improvement]
- Navigation flow: [Excellent/Good/Needs Improvement]
- Result presentation: [Excellent/Good/Needs Improvement]

### Technical Observations
- Backend logging adequate: [Yes/No]
- Error messages helpful: [Yes/No]
- Code quality: [Good/Acceptable/Needs Improvement]

---

**Test Conducted By**: _________________
**Date**: _________________
**Test Duration**: _____ hours
**Overall Assessment**: [Pass/Fail/Pass with Reservations]

---

## Quick Reference

### All 7 Archetypes
1. **SE for Managers** (Low maturity primary)
2. **Orientation in Pilot Project** (Low maturity secondary)
3. **Common Basic Understanding** (Low maturity secondary)
4. **Certification** (Low maturity secondary)
5. **Needs-based Project-oriented Training** (High maturity, limited scope)
6. **Continuous Support** (High maturity, broad scope)
7. **Train the Trainer** (Supplementary)

### Routing Logic
```
IF MAT_04 <= 1:
    PRIMARY = "SE for Managers"
    SECONDARY = based on ARCH_01
ELSE:
    IF MAT_05 <= 1:
        SINGLE = "Needs-based Project-oriented Training"
    ELSE:
        SINGLE = "Continuous Support"

IF ARCH_06 == "enterprise" OR ARCH_07 == "long":
    ADD "Train the Trainer" to supplementary
```

### Server URLs
- Backend: http://127.0.0.1:5000
- Frontend: http://localhost:3000
- Database: postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment

---

**END OF TESTING CHECKLIST**
