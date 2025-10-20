"""
Fix table names in stored procedures and assessment_feedback table
Issues:
1. competencies -> competency (singular)
2. role_competency -> role_competency_matrix
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("FIXING TABLE NAMES IN STORED PROCEDURES")
    print("=" * 80)

    # Step 1: Drop existing assessment_feedback table
    print("\n[1/4] Dropping old assessment_feedback table...")
    try:
        db.session.execute(text("""
            DROP TABLE IF EXISTS assessment_feedback CASCADE;
        """))
        db.session.commit()
        print("   [OK] Dropped old table")
    except Exception as e:
        print(f"   [ERROR] {e}")
        db.session.rollback()

    # Step 2: Create assessment_feedback table with correct references
    print("\n[2/4] Creating assessment_feedback table with correct table names...")
    try:
        db.session.execute(text("""
            CREATE TABLE IF NOT EXISTS assessment_feedback (
                id SERIAL PRIMARY KEY,
                username VARCHAR(255) NOT NULL,
                competency_id INTEGER NOT NULL,
                feedback_text TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (username) REFERENCES new_survey_user(username),
                FOREIGN KEY (competency_id) REFERENCES competency(id)
            )
        """))
        db.session.commit()
        print("   [OK] assessment_feedback table created")
    except Exception as e:
        print(f"   [ERROR] Failed to create table: {e}")
        db.session.rollback()

    # Step 3: Create stored procedure with correct table names
    print("\n[3/4] Creating stored procedure with correct table names...")
    try:
        db.session.execute(text("""
            CREATE OR REPLACE FUNCTION generate_feedback_for_assessment(p_username VARCHAR)
            RETURNS VOID AS $$
            DECLARE
                competency_record RECORD;
                feedback_text TEXT;
            BEGIN
                -- Loop through all competencies the user was assessed on
                FOR competency_record IN
                    SELECT DISTINCT c.id, c.competency_name
                    FROM competency c
                    JOIN role_competency_matrix rc ON rc.competency_id = c.id
                    WHERE EXISTS (
                        SELECT 1 FROM user_se_competency_survey_results ca
                        WHERE ca.user_id IN (
                            SELECT id FROM app_user WHERE username = p_username
                        )
                        AND ca.competency_id = c.id
                    )
                LOOP
                    -- Generate feedback (placeholder - will be replaced by LLM)
                    feedback_text := 'Feedback for ' || competency_record.competency_name || ' - User: ' || p_username;

                    -- Insert feedback
                    INSERT INTO assessment_feedback (username, competency_id, feedback_text)
                    VALUES (p_username, competency_record.id, feedback_text);
                END LOOP;
            END;
            $$ LANGUAGE plpgsql;
        """))
        db.session.commit()
        print("   [OK] Stored procedure created")
    except Exception as e:
        print(f"   [ERROR] Failed to create procedure: {e}")
        db.session.rollback()

    # Step 4: Recreate trigger (just in case)
    print("\n[4/4] Recreating trigger...")
    try:
        # Drop existing trigger if it exists
        db.session.execute(text("""
            DROP TRIGGER IF EXISTS generate_feedback_on_complete ON new_survey_user;
        """))

        # Create trigger function
        db.session.execute(text("""
            CREATE OR REPLACE FUNCTION trigger_generate_feedback()
            RETURNS TRIGGER AS $$
            BEGIN
                -- Only generate if status changed from FALSE to TRUE
                IF (OLD.survey_completion_status IS DISTINCT FROM TRUE)
                   AND (NEW.survey_completion_status = TRUE) THEN
                    -- Call the stored procedure
                    PERFORM generate_feedback_for_assessment(NEW.username);
                END IF;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        """))

        # Create the trigger
        db.session.execute(text("""
            CREATE TRIGGER generate_feedback_on_complete
            AFTER UPDATE ON new_survey_user
            FOR EACH ROW
            EXECUTE FUNCTION trigger_generate_feedback();
        """))

        db.session.commit()
        print("   [OK] Trigger created")
    except Exception as e:
        print(f"   [ERROR] Failed to create trigger: {e}")
        db.session.rollback()

    # Verification
    print("\n" + "=" * 80)
    print("VERIFICATION")
    print("=" * 80)

    # Check table exists
    print("\nChecking assessment_feedback table:")
    result = db.session.execute(text("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'assessment_feedback'
        )
    """)).fetchone()[0]
    print(f"   Table exists: {result}")

    # Check procedure exists
    print("\nChecking stored procedure:")
    result = db.session.execute(text("""
        SELECT EXISTS (
            SELECT FROM pg_proc
            WHERE proname = 'generate_feedback_for_assessment'
        )
    """)).fetchone()[0]
    print(f"   Procedure exists: {result}")

    # Check trigger exists
    print("\nChecking trigger:")
    result = db.session.execute(text("""
        SELECT EXISTS (
            SELECT FROM pg_trigger
            WHERE tgname = 'generate_feedback_on_complete'
        )
    """)).fetchone()[0]
    print(f"   Trigger exists: {result}")

    print("\n" + "=" * 80)
    print("[SUCCESS] Fixed table names in stored procedures!")
    print("=" * 80)
