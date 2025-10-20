# Survey User Creation Fix - Summary

## Problem
The `/new_survey_user` endpoint was returning a 400 BAD REQUEST error:
```
POST http://localhost:5000/new_survey_user 400 (BAD REQUEST)
Error: Failed to create survey user
```

## Root Cause
The database was missing two critical objects:
1. **Function**: `set_username()` - Auto-generates usernames for new survey users
2. **Trigger**: `before_insert_new_survey_user` - Executes the function on each INSERT

These objects are defined in `init.sql` but were never created in the actual database.

## Solution
Created the missing database objects using `create_trigger.py`:

### The Function (line 332 in init.sql)
```sql
CREATE FUNCTION public.set_username() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;
  NEW.username := 'se_survey_user_' || NEW.id;
  RETURN NEW;
END;
$$;
```

### The Trigger (line 9913 in init.sql)
```sql
CREATE TRIGGER before_insert_new_survey_user
BEFORE INSERT ON public.new_survey_user
FOR EACH ROW
EXECUTE FUNCTION public.set_username();
```

**Note**: Fixed typo in original init.sql - changed `'se_surver_user_'` to `'se_survey_user_'`

## Architecture Explanation

### Why Create Usernames for Survey Sessions?

The system uses a **three-table architecture** to support both authenticated admin access and **anonymous survey participation**:

1. **AdminUser** - Authentication credentials for admin/employee portal
   - Purpose: Login system for internal users
   - Contains: username, password, email, role

2. **NewSurveyUser** - Temporary survey session tracking
   - Purpose: Track individual survey sessions (anonymous or authenticated)
   - Contains: auto-generated username (e.g., `se_survey_user_9`)
   - Lifecycle: Created at survey start, converted to AppUser on completion

3. **AppUser** - Permanent survey respondent records
   - Purpose: Store completed survey data for analysis
   - Contains: Final survey responses, role, competency assessments

### Key Design Decisions

**Q: Why create usernames when users are already logged in?**

A: The system supports **anonymous surveys**. Not all survey participants need to log in. The `NewSurveyUser` table provides:
- **Session tracking** for both logged-in and anonymous users
- **Multiple assessment support** - Same person can take surveys multiple times
- **Data separation** - Admin credentials remain separate from survey data
- **Survey identification** - Each survey attempt gets a unique identifier

**Q: How does the flow work?**

1. User navigates to survey (with or without login)
2. System creates `NewSurveyUser` with auto-generated username (`se_survey_user_10`)
3. User completes survey questions
4. On submission, `NewSurveyUser` data converts to `AppUser` record
5. Survey completion status updates to `true`

## Verification

### Before Fix
```bash
$ curl -X POST http://localhost:5000/new_survey_user
{"message": "A user with this username already exists."}  # 400 ERROR
```

### After Fix
```bash
$ curl -X POST http://localhost:5000/new_survey_user
{
  "message": "User created successfully.",
  "username": "se_survey_user_9"
}  # 201 SUCCESS
```

### Database Verification
```
Total users: 2
- se_survey_user_9 (ID: 9)
- se_survey_user_10 (ID: 10)
```

## Files Modified

### Backend Code (Already Reverted in Previous Session)
- `src/competency_assessor/app/routes.py` (lines 556-576)
  - Reverted to Derik's implementation
  - Creates `NewSurveyUser()` without setting username
  - Uses `db.session.refresh()` to retrieve trigger-generated username

- `src/competency_assessor/app/models.py` (line 322)
  - Reverted username field to `nullable=False`
  - Removed `__init__` method to rely on database trigger

### Database Objects Created
- Function: `public.set_username()`
- Trigger: `before_insert_new_survey_user`

### Scripts Created
- `check_trigger.py` - Diagnose missing database objects
- `create_trigger.py` - Create function and trigger
- `verify_endpoint.py` - Test endpoint and verify database

## Testing Steps

1. **Test endpoint via curl:**
   ```bash
   curl -X POST http://localhost:5000/new_survey_user
   ```

2. **Test via frontend:**
   - Navigate to competency assessment
   - Select role
   - Begin survey
   - Submit responses
   - Verify no 400 errors in console

3. **Verify database:**
   ```bash
   python verify_endpoint.py
   ```

## Status: ✅ FIXED

The `/new_survey_user` endpoint is now fully functional. Survey submissions should work without errors.
