# Model Changes Compatibility Analysis

**Date**: 2025-10-12
**Status**: ✅ ALL EXISTING CODE IS COMPATIBLE

---

## Summary

All model changes are **backward compatible**. The new fields are nullable, so existing code will continue to work without modifications. However, to enable new features (assessment history, persistent results), we need to update specific routes.

---

## Model Changes Applied

### 1. AppUser Model
- ✅ Added: `admin_user_id` (Integer, nullable, FK to admin_user.id)
- ✅ Added: Relationship to AdminUser
- **Impact**: None - field is nullable

### 2. UserCompetencySurveyResults Model
- ✅ Added: `assessment_id` (Integer, nullable, FK to competency_assessment.id)
- ✅ Added: Relationship to CompetencyAssessment
- **Impact**: None - field is nullable

### 3. UserCompetencySurveyFeedback Model
- ✅ Added: `assessment_id` (Integer, nullable, FK to competency_assessment.id)
- ✅ Added: Relationship to CompetencyAssessment
- **Impact**: None - field is nullable

### 4. CompetencyAssessment Model (NEW)
- ✅ Created new model with all Phase 2 fields
- **Impact**: None - new table, doesn't affect existing code

---

## Code Analysis by Location

### ✅ `/create_user` (routes.py:500)
```python
new_user = AppUser(
    organization_id=organization_id,
    name=name,
    username=username,
    tasks_responsibilities=tasks_responsibilities
)
```
- **Status**: COMPATIBLE
- **Reason**: `admin_user_id` is nullable
- **Action Required**: None (this is a legacy endpoint)

---

### ⚠️ `/submit_survey` (routes.py:778-843)
```python
# Line 778 - AppUser creation
user = AppUser(
    organization_id=organization_id,
    name=full_name,
    username=username,
    tasks_responsibilities=json.dumps(tasks_responsibilities)
)

# Line 835 - UserCompetencySurveyResults creation
survey = UserCompetencySurveyResults(
    user_id=user.id,
    organization_id=organization_id,
    competency_id=competency['competencyId'],
    score=competency['score']
)
```
- **Status**: COMPATIBLE (works as-is)
- **Enhancement Needed**: YES - Add assessment instance creation
- **Priority**: HIGH - This enables all new features

**Required Changes**:
1. Accept `admin_user_id` from frontend
2. Create `CompetencyAssessment` instance before saving results
3. Link AppUser to AdminUser via `admin_user_id`
4. Link survey results to assessment via `assessment_id`
5. Remove DELETE operations (preserve historical data)

---

### ⚠️ `/get_user_competency_results` (routes.py:998)
```python
new_feedback = UserCompetencySurveyFeedback(
    user_id=user.id,
    organization_id=organization_id,
    feedback=feedback_list
)
```
- **Status**: COMPATIBLE (works as-is)
- **Enhancement Needed**: YES - Link feedback to assessment
- **Priority**: HIGH

**Required Changes**:
1. Accept or derive `assessment_id`
2. Link feedback to specific assessment instance

---

## Frontend Compatibility

### Data Being Sent (Current)
```json
{
  "organization_id": 1,
  "full_name": "John Doe",
  "username": "se_survey_user_57",
  "tasks_responsibilities": {...},
  "selected_roles": [{...}],
  "competency_scores": [{...}],
  "survey_type": "known_roles"
}
```

### Data Needed (Enhanced)
```json
{
  "organization_id": 1,
  "admin_user_id": 12,  // NEW - from auth store
  "full_name": "John Doe",
  "username": "se_survey_user_57",
  "tasks_responsibilities": {...},
  "selected_roles": [{...}],
  "competency_scores": [{...}],
  "survey_type": "known_roles"
}
```

### Frontend Files to Update
1. **DerikCompetencyBridge.vue** - Add `admin_user_id` to submission
2. **CompetencyResults.vue** - Accept `assessmentId` prop for direct navigation
3. **NEW: AssessmentHistory.vue** - Display assessment history
4. **Router** - Add routes for assessment history

---

## Critical Deletions to Remove

### ❌ Current Code (DELETES Historical Data)
```python
# Lines 825-831 - DO NOT DELETE!
UserCompetencySurveyResults.query.filter_by(user_id=user.id).delete()
UserCompetencySurveyFeedback.query.filter_by(user_id=user.id, organization_id=organization_id).delete()
```

### ✅ New Approach (PRESERVES Historical Data)
```python
# Create new assessment instance
new_assessment = CompetencyAssessment(
    admin_user_id=admin_user_id,
    app_user_id=user.id,
    organization_id=organization_id,
    assessment_type=survey_type,
    status='completed',
    selected_roles=selected_roles,
    task_inputs=tasks_responsibilities if survey_type == 'unknown_roles' else None
)
db.session.add(new_assessment)
db.session.flush()  # Get assessment.id

# Link results to THIS assessment (don't delete old ones!)
for competency in competency_scores:
    survey = UserCompetencySurveyResults(
        user_id=user.id,
        organization_id=organization_id,
        competency_id=competency['competencyId'],
        score=competency['score'],
        assessment_id=new_assessment.id  # NEW
    )
    db.session.add(survey)
```

---

## New Endpoints Needed

### 1. `/api/assessments/<assessment_id>/results` (GET)
- **Purpose**: Get results for specific assessment
- **Returns**: Full assessment data (scores, feedback, context, objectives)
- **Priority**: HIGH

### 2. `/api/users/<admin_user_id>/assessments` (GET)
- **Purpose**: Get assessment history for user
- **Returns**: List of all assessments with metadata
- **Priority**: HIGH

### 3. `/api/assessments/<assessment_id>/objectives` (PUT)
- **Purpose**: Save learning objectives to assessment
- **Priority**: MEDIUM

### 4. `/api/assessments/<assessment_id>/context` (PUT)
- **Purpose**: Save company context to assessment
- **Priority**: MEDIUM

---

## Testing Strategy

### Phase 1: Verify Existing Functionality
- [  ] Existing assessments still work (backward compatibility)
- [  ] No errors on survey submission
- [  ] Results still display correctly

### Phase 2: Test New Features
- [  ] Assessment instances are created
- [  ] `admin_user_id` is properly linked
- [  ] `assessment_id` is properly linked in results/feedback
- [  ] Old results are NOT deleted on retake

### Phase 3: Test History Features
- [  ] Assessment history loads for user
- [  ] Can view previous assessment results
- [  ] Can retake assessment (creates new instance)
- [  ] Multiple assessments tracked correctly

---

## Migration Risk Assessment

| Component | Risk | Mitigation |
|-----------|------|------------|
| Database Schema | LOW | All new fields are nullable |
| Existing Routes | LOW | No breaking changes |
| Data Integrity | LOW | Cascading deletes properly configured |
| Frontend | MEDIUM | Need to pass `admin_user_id` |
| Historical Data | LOW | No existing data will be lost |

---

## Rollback Plan

If issues arise:

1. **Immediate**: Comment out new assessment creation code
2. **Quick**: Restore old DELETE logic (loses history but works)
3. **Full**: Drop new columns/tables with migration script:
   ```sql
   ALTER TABLE user_se_competency_survey_results DROP COLUMN assessment_id;
   ALTER TABLE user_competency_survey_feedback DROP COLUMN assessment_id;
   ALTER TABLE app_user DROP COLUMN admin_user_id;
   DROP TABLE competency_assessment;
   ```

---

## Next Steps (Priority Order)

1. ✅ Import CompetencyAssessment model in routes.py
2. 🔄 Update `/submit_survey` to create assessment instances
3. ⏳ Create `/api/assessments/<id>/results` endpoint
4. ⏳ Create `/api/users/<id>/assessments` endpoint
5. ⏳ Update frontend to pass `admin_user_id`
6. ⏳ Create AssessmentHistory.vue component
7. ⏳ Add router entries
8. ⏳ Test complete workflow

---

## Conclusion

✅ **All model changes are backward compatible**
✅ **Existing functionality will continue to work**
⚠️ **Enhancements needed to enable new features**
🎯 **Primary focus: Update `/submit_survey` route**

The system is **production-safe** but needs route updates to unlock assessment history and persistence features.
