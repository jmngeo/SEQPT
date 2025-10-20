"""
Fix the username trigger to only set username when NULL.
This allows both auto-generated usernames (role-based) and
frontend-provided usernames (task-based) to work.
"""
from sqlalchemy import create_engine, text
import os

# Database connection
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment')
engine = create_engine(DATABASE_URL)

# SQL to fix the trigger
fix_trigger_sql = """
CREATE OR REPLACE FUNCTION public.set_username() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;

  -- Only set username if it's NULL or empty
  IF NEW.username IS NULL OR NEW.username = '' THEN
    NEW.username := 'se_survey_user_' || NEW.id;
  END IF;

  RETURN NEW;
END;
$$;
"""

print("Fixing username trigger...")
try:
    with engine.connect() as conn:
        conn.execute(text(fix_trigger_sql))
        conn.commit()
    print("[SUCCESS] Trigger fixed successfully!")
    print("The trigger will now:")
    print("  - Use provided username if given (task-based assessments)")
    print("  - Generate 'se_survey_user_{id}' if NULL (role-based assessments)")
except Exception as e:
    print(f"[ERROR] Failed to fix trigger: {e}")
