"""
Script to check if the set_username() function and trigger exist in the database.
"""
from app import create_app, db

def check_database_objects():
    app = create_app()

    with app.app_context():
        # Check if set_username function exists
        result = db.session.execute(db.text("""
            SELECT routine_name
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'set_username'
        """))
        function_exists = result.fetchone()

        print("=" * 60)
        print("Database Objects Check")
        print("=" * 60)
        print(f"set_username() function exists: {bool(function_exists)}")
        if function_exists:
            print(f"  Function name: {function_exists[0]}")

        # Check if trigger exists
        result = db.session.execute(db.text("""
            SELECT trigger_name
            FROM information_schema.triggers
            WHERE trigger_name = 'before_insert_new_survey_user'
        """))
        trigger_exists = result.fetchone()

        print(f"\nbefore_insert_new_survey_user trigger exists: {bool(trigger_exists)}")
        if trigger_exists:
            print(f"  Trigger name: {trigger_exists[0]}")

        # Check new_survey_user table
        result = db.session.execute(db.text("""
            SELECT COUNT(*) FROM new_survey_user
        """))
        count = result.fetchone()[0]
        print(f"\nRecords in new_survey_user table: {count}")

        # If missing, we need to create them
        if not function_exists or not trigger_exists:
            print("\n" + "=" * 60)
            print("DIAGNOSIS: Function or Trigger is MISSING!")
            print("=" * 60)
            print("\nWe need to create the missing database objects.")
            print("This explains why the endpoint is failing.")

            if not function_exists:
                print("\nMissing: set_username() function")
            if not trigger_exists:
                print("Missing: before_insert_new_survey_user trigger")
        else:
            print("\n" + "=" * 60)
            print("All database objects exist - investigating further...")
            print("=" * 60)

if __name__ == '__main__':
    check_database_objects()
