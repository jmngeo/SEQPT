# CRITICAL ERROR - Fix First in Next Session

## Error Details

**File**: `src/backend/app/services/task_based_pathway.py:306`

**Error**:
```
AttributeError: 'UserCompetencySurveyResult' object has no attribute 'self_reported_level'
```

**Stack Trace**:
```
File "task_based_pathway.py", line 469, in generate_task_based_learning_objectives
    users_count = calculate_users_affected(comp_id, data['user_assessments'], target_level)
File "task_based_pathway.py", line 306, in calculate_users_affected
    if score and score.self_reported_level < target_level:
AttributeError: 'UserCompetencySurveyResult' object has no attribute 'self_reported_level'
```

## Root Cause

Wrong model used in `calculate_users_affected()` function!

**Current Code (WRONG)**:
```python
def calculate_users_affected(comp_id, user_assessments, target_level):
    count = 0
    for assessment in user_assessments:
        # This query returns UserCompetencySurveyResult, not CompetencyScore!
        score = CompetencyScore.query.filter_by(
            assessment_id=assessment.id,
            competency_id=comp_id
        ).first()

        if score and score.self_reported_level < target_level:  # ❌ WRONG ATTRIBUTE
            count += 1
    return count
```

**Issue**:
- `CompetencyScore` model doesn't exist or maps to wrong table
- The actual model is `UserCompetencySurveyResult`
- Attribute name is NOT `self_reported_level`

## Fix Required

**Need to check models.py to find correct:**
1. Model name for competency scores
2. Attribute name for the level value
3. Correct foreign key relationship

**Likely Fix**:
```python
def calculate_users_affected(comp_id, user_assessments, target_level):
    count = 0
    for assessment in user_assessments:
        # Use correct model and attribute
        score = UserCompetencySurveyResult.query.filter_by(
            survey_id=assessment.id,  # Check correct FK
            competency_id=comp_id
        ).first()

        if score and score.competency_level < target_level:  # Check correct attribute
            count += 1
    return count
```

## Testing Steps

1. Check `models.py` for correct model names
2. Find the model that stores user competency levels
3. Find the correct attribute name for level value
4. Update `calculate_users_affected()` function
5. Restart backend
6. Test generation for Org 28

## Quick Command to Check Models

```bash
cd /c/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis/src/backend
grep -n "class.*Competency.*Result" models.py
grep -n "self_reported_level\|competency_level\|level" models.py
```

## Impact

**Blocking**: YES - Generation fails completely
**Priority**: CRITICAL - Fix immediately in next session
**Estimated Fix Time**: 5-10 minutes

## Workaround

None - backend generation is completely broken until fixed.

---

**Created**: 2025-11-05 23:06:00 UTC
**Status**: UNRESOLVED - Needs immediate attention
