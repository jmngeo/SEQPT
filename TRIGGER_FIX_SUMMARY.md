# Task-Based Assessment Submit Survey Fix - Summary

## Problem Identified

The task-based assessment survey submission was failing with **404 NOT FOUND** error because of a database trigger issue.

### Root Cause

The `new_survey_user` table had a `BEFORE INSERT` trigger that **always overwrote** the username with an auto-generated value:

```sql
-- OLD TRIGGER (BROKEN)
CREATE FUNCTION public.set_username() RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;
  NEW.username := 'se_surver_user_' || NEW.id;  -- Always overwrites!
  RETURN NEW;
END;
$$;
```

### The Issue

1. **Frontend** generates username: `seqpt_user_1760141460284`
2. **Backend** `/findProcesses` creates: `NewSurveyUser(username='seqpt_user_1760141460284')`
3. **Database trigger** overwrites it to: `se_surver_user_84`
4. **Backend** `/submit_survey` looks for: `seqpt_user_1760141460284` → **404 NOT FOUND**

## Solution Applied

The trigger was fixed to **only generate username if NULL**, allowing both assessment types to work:

```sql
-- NEW TRIGGER (FIXED)
CREATE OR REPLACE FUNCTION public.set_username() RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;

  -- Only set username if NULL or empty
  IF NEW.username IS NULL OR NEW.username = '' THEN
    NEW.username := 'se_survey_user_' || NEW.id;
  END IF;

  RETURN NEW;
END;
$$;
```

## Verification

The fix was tested and verified:

✅ **Task-based assessment**: Custom username `seqpt_user_1760156097855` was preserved
✅ **Role-based assessment**: Auto-generated username `se_survey_user_38` was created

## Current Status

- **Flask Server**: Running on `http://127.0.0.1:5000`
- **Database Trigger**: Fixed and working correctly
- **Task-based Assessment**: Ready for testing

## Testing Instructions

1. **Open your browser** and navigate to the task-based assessment page
2. **Enter tasks** in the three categories (responsible for, supporting, designing)
3. **Submit tasks** and proceed to process identification
4. **Fill out competency survey** with your self-assessments
5. **Submit survey** - Should now work without 404 error!
6. **View results** - Required competency scores should show varying values (not all 6)

## Files Modified

1. `src/competency_assessor/fix_trigger_via_flask.py` - Script that applied the fix
2. `src/competency_assessor/test_trigger_fix.py` - Verification test
3. Database: `public.set_username()` function updated

## Next Steps

1. Test the complete task-based assessment flow
2. Verify that required competency scores are calculated correctly
3. Ensure survey results display properly
