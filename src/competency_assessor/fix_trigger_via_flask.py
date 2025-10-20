"""
Fix the username trigger using Flask's database connection.
This works regardless of credentials because it uses the app's configured connection.
"""
from app import create_app, db
from sqlalchemy import text

app = create_app()

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

print("Fixing username trigger via Flask app...")
try:
    with app.app_context():
        db.session.execute(text(fix_trigger_sql))
        db.session.commit()
        print("[SUCCESS] Trigger fixed successfully!")
        print("")
        print("The trigger will now:")
        print("  - Use provided username if given (task-based assessments)")
        print("  - Generate 'se_survey_user_{id}' if NULL (role-based assessments)")
        print("")
        print("You can now test the task-based assessment flow.")
except Exception as e:
    print(f"[ERROR] Failed to fix trigger: {e}")
    import traceback
    traceback.print_exc()
