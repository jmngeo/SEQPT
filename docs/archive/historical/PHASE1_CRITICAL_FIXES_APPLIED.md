# Phase 1 Critical Fixes - Session 2025-10-13

## Issues Found During Testing

### 1. **400 BAD REQUEST Error** [FIXED]
**Problem**: Archetype selection endpoint returned 400 error with message "MAT_04 score required for archetype routing"

**Root Cause**: PhaseOne.vue line 572 was NOT passing `maturity_responses` to the backend

**Fix Applied**:
```javascript
// BEFORE (line 572-576):
const archetypeComputationResponse = await axios.post('/api/seqpt/phase1/archetype-selection', {
  assessment_uuid: response.assessment_uuid,
  responses: response.responses || {},
  company_preference: response.responses?.company_preference
})

// AFTER:
const archetypeComputationResponse = await axios.post('/api/seqpt/phase1/archetype-selection', {
  assessment_uuid: response.assessment_uuid,
  responses: response.responses || {},
  maturity_responses: maturityResponse.value?.responses || {},  // ADDED: Pass MAT_04/MAT_05 for routing
  company_preference: response.responses?.company_preference
})
```

**File**: `src/frontend/src/views/phases/PhaseOne.vue:576`

**Status**: ✅ FIXED - Frontend now passes maturity responses containing MAT_04 and MAT_05 to backend

---

### 2. **Incorrect Maturity Score (41 instead of 0-5)** [PENDING]
**Problem**: Maturity score shows as 41 (should be 0-5 weighted average)

**Root Cause**: QuestionnaireComponent.vue (lines 314-323) is summing raw score_value instead of calculating hierarchical weighted average

**Current Implementation**:
```javascript
// Calculate total score
let totalScore = 0
Object.keys(answers.value).forEach(questionId => {
  const question = questionnaire.value.questions.find(q => q.id === questionId)
  if (question) {
    const selectedOption = question.options.find(opt => opt.option_value === answers.value[questionId])
    if (selectedOption) {
      totalScore += selectedOption.score_value || 0  // WRONG: Just summing!
    }
  }
})
```

**Expected Algorithm** (from maturity_assessment.json:219-227):
```
Method: hierarchical_weighted_average

Step 1 - Section Scores:
  Fundamentals = Sum(MAT_01*0.35 + MAT_02*0.30 + MAT_03*0.35) / Sum(weights)
  Organization = Sum(MAT_04*0.35 + MAT_05*0.30 + MAT_06*0.20 + MAT_07*0.15) / Sum(weights)
  Process Capability = Sum(MAT_08*0.35 + MAT_09*0.35 + MAT_10*0.30) / Sum(weights)
  Infrastructure = Sum(MAT_11*0.50 + MAT_12*0.50) / Sum(weights)

Step 2 - Overall Score:
  Overall = Sum(
    Fundamentals * 0.25 +
    Organization * 0.30 +
    Process Capability * 0.25 +
    Infrastructure * 0.20
  ) / Sum(section_weights)

Result Range: 0.0 - 5.0
```

**Fix Required**:
Two options:
1. **Backend calculation**: Move scoring to backend (recommended for consistency)
2. **Frontend calculation**: Implement weighted average in QuestionnaireComponent

**Files**:
- `src/frontend/src/components/common/QuestionnaireComponent.vue:314-323`
- `data/source/questionnaires/phase1/maturity_assessment.json` (scoring structure)

**Status**: ❌ PENDING - Requires implementation of hierarchical weighted scoring

---

### 3. **All Archetype Questions Showing** [PENDING]
**Problem**: Both LOW and HIGH maturity questions appear simultaneously

**Evidence from Console**:
```javascript
{
  ARCH_01: "apply_pilot",  // LOW maturity question
  ARCH_02: 2,              // LOW maturity question
  ARCH_03: 1,              // LOW maturity conditional question
  ARCH_05: "project_specific",  // HIGH maturity question (WRONG!)
  ARCH_06: "small",        // Common question
  ARCH_07: "immediate"     // Common question
}
```

**Expected Behavior**:
- **IF MAT_04 ≤ 1** (Low Maturity): Show ARCH_01, ARCH_02, ARCH_03 (conditional), ARCH_06, ARCH_07
- **IF MAT_04 > 1** (High Maturity): Show ARCH_04 (auto), ARCH_05, ARCH_06, ARCH_07

**Root Cause**: Frontend is not filtering questions based on maturity level (MAT_04 value)

**Fix Required**:
Option 1: Backend filter questions before sending to frontend based on MAT_04
Option 2: Frontend receives all questions but only displays relevant ones based on maturity level

**Files**:
- `src/competency_assessor/app/routes.py:1646-1683` (backend transformation)
- `src/frontend/src/components/common/QuestionnaireComponent.vue` (frontend display)

**Status**: ❌ PENDING - Requires conditional question filtering logic

---

### 4. **ARCH_04 "SE Application Breadth (Auto-calculated)" Showing** [PENDING]
**Problem**: User asked "Is the question 'SE Application Breadth (Auto-calculated)' needed to show to user?"

**Answer**: NO! This should be hidden from users.

**Root Cause**: archetype_selection.json contains ARCH_04 with display_to_user flag that's not being respected

**Expected Behavior**:
- ARCH_04 should be auto-calculated from MAT_05 value
- Backend should calculate: `ARCH_04 = MAT_05` (inherit rollout scope value)
- Users should never see this question

**Fix Required**:
Option 1: Remove ARCH_04 from questions array entirely (backend filters it out)
Option 2: Add `hidden: true` flag and respect it in QuestionnaireComponent

**Files**:
- `data/source/questionnaires/phase1/archetype_selection.json` (ARCH_04 definition)
- `src/competency_assessor/app/routes.py:1646-1683` (backend transformation - filter hidden questions)

**Status**: ❌ PENDING - Requires question hiding/filtering logic

---

### 5. **First Option Not Clickable** [INVESTIGATING]
**Problem**: User reports "The first option of each question in maturity assessment is not clickable"

**Possible Causes**:
1. CSS issue with radio button styling (z-index, pointer-events)
2. Event handling issue in Element Plus radio-group
3. Browser-specific issue
4. Option value issue (value: 0 might be treated as falsy)

**Investigation Needed**:
- Check if issue affects all questions or only specific ones
- Check if issue is with value=0 options
- Test in different browsers
- Inspect DOM for CSS issues

**Files**:
- `src/frontend/src/components/common/QuestionnaireComponent.vue` (radio button rendering)
- Styles at lines 162-188 (answer-option CSS)

**Status**: ⚠️ INVESTIGATING - Need more details from user testing

---

## Summary of Fixes Applied

### ✅ Completed (1/5)
1. **400 BAD REQUEST Error** - Fixed by passing maturity_responses to archetype endpoint

### ❌ Pending (4/5)
2. **Incorrect Maturity Score** - Needs hierarchical weighted average implementation
3. **All Archetype Questions Showing** - Needs conditional question filtering by MAT_04
4. **ARCH_04 Showing** - Needs question hiding logic
5. **First Option Not Clickable** - Needs investigation and diagnosis

---

## Testing Instructions

### Test 1: Verify 400 Error Fixed
1. Complete maturity assessment with any values
2. Answer MAT_04 and MAT_05 questions
3. Proceed to archetype selection
4. Complete archetype questions
5. **Expected**: No 400 error, archetype computed successfully
6. **Check backend logs** for: `[ARCHETYPE] Routing variables - MAT_04: X, MAT_05: Y`

### Test 2: Verify Maturity Score Issue (Still Broken)
1. Complete maturity assessment
2. Note the score displayed
3. **Expected (CURRENT BEHAVIOR)**: Score ~30-50 (wrong)
4. **Expected (AFTER FIX)**: Score 0.0-5.0 (correct)

### Test 3: Verify Question Filtering Issue (Still Broken)
1. Complete maturity with MAT_04 = 0 or 1
2. Proceed to archetype selection
3. **Current Behavior**: All questions appear (ARCH_01-07)
4. **Expected (AFTER FIX)**: Only ARCH_01, ARCH_02, ARCH_03 (conditional), ARCH_06, ARCH_07

### Test 4: Verify ARCH_04 (Still Showing)
1. In archetype selection questionnaire
2. Look for question "SE Application Breadth (Auto-calculated)"
3. **Current Behavior**: Question appears
4. **Expected (AFTER FIX)**: Question hidden/not shown

### Test 5: Investigate First Option
1. Try clicking the first option (value: 0) of any maturity question
2. **Report**: Does it select? Does it highlight? Does cursor change?
3. **Test**: Try clicking the second option (value: 1) - does it work?
4. **Test**: Try different browsers (Chrome, Firefox, Edge)

---

## Recommended Next Steps

### Priority 1: Enable Basic Testing
1. ✅ **DONE**: Fix 400 error (maturity_responses)
2. **Test**: Verify archetype selection completes without errors
3. **Test**: Check backend logs show correct MAT_04/MAT_05 values
4. **Test**: Verify dual/single selection logic works

### Priority 2: Fix Scoring (Required for Validation)
1. Implement hierarchical weighted average scoring
2. Options:
   - **Backend**: Add `/api/seqpt/phase1/maturity-score` endpoint to calculate score
   - **Frontend**: Implement weighted average in QuestionnaireComponent.completeQuestionnaire()
3. Test with known inputs to verify correct 0-5 range

### Priority 3: Fix Question Filtering (Required for Correct Archetype Path)
1. Backend option: Filter questions before sending to frontend based on previous maturity responses
2. Frontend option: Pass MAT_04 value when loading archetype questionnaire, filter questions dynamically
3. Hide ARCH_04 from user display

### Priority 4: Fix First Option Issue
1. Investigate and diagnose the exact cause
2. Apply appropriate fix (CSS, value handling, or Element Plus configuration)

---

## Files Modified

### Frontend
- **src/frontend/src/views/phases/PhaseOne.vue** (Line 576)
  - Added `maturity_responses` to archetype selection API call

### Backend
- No backend changes required for the 400 fix
- Backend was already correctly expecting `maturity_responses`

---

## Next Session TODO

1. **Test the 400 fix**: Complete full Phase 1 flow and verify archetype selection works
2. **Implement hierarchical weighted scoring**: Either backend or frontend
3. **Implement conditional question filtering**: Show correct questions based on MAT_04
4. **Hide ARCH_04**: Filter auto-calculated questions from display
5. **Investigate first option issue**: Diagnose and fix clickability problem

---

**Session End**: 2025-10-13 (Partial fixes applied)
**Status**: 1/5 issues fixed, 4/5 pending implementation
**Ready for Testing**: Yes (with known limitations)
