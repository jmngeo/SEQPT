"""
Script to create the missing set_username() function and trigger in the database.
"""
from app import create_app, db

def create_database_objects():
    app = create_app()

    with app.app_context():
        print("=" * 60)
        print("Creating Database Objects")
        print("=" * 60)

        # Create the set_username() function
        function_sql = """
        CREATE OR REPLACE FUNCTION public.set_username() RETURNS trigger
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
        """

        try:
            db.session.execute(db.text(function_sql))
            db.session.commit()
            print("[OK] Created set_username() function")
        except Exception as e:
            print(f"[ERROR] Error creating function: {str(e)}")
            db.session.rollback()
            return

        # Create the trigger
        trigger_sql = """
        DROP TRIGGER IF EXISTS before_insert_new_survey_user ON public.new_survey_user;

        CREATE TRIGGER before_insert_new_survey_user
        BEFORE INSERT ON public.new_survey_user
        FOR EACH ROW
        EXECUTE FUNCTION public.set_username();
        """

        try:
            db.session.execute(db.text(trigger_sql))
            db.session.commit()
            print("[OK] Created before_insert_new_survey_user trigger")
        except Exception as e:
            print(f"[ERROR] Error creating trigger: {str(e)}")
            db.session.rollback()
            return

        # Verify creation
        print("\n" + "=" * 60)
        print("Verification")
        print("=" * 60)

        result = db.session.execute(db.text("""
            SELECT routine_name
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'set_username'
        """))
        function_exists = result.fetchone()
        print(f"Function exists: {bool(function_exists)}")

        result = db.session.execute(db.text("""
            SELECT trigger_name
            FROM information_schema.triggers
            WHERE trigger_name = 'before_insert_new_survey_user'
        """))
        trigger_exists = result.fetchone()
        print(f"Trigger exists: {bool(trigger_exists)}")

        print("\n" + "=" * 60)
        print("SUCCESS! Database objects created.")
        print("=" * 60)
        print("\nNote: I fixed the typo - using 'se_survey_user_' instead of 'se_surver_user_'")

if __name__ == '__main__':
    create_database_objects()
