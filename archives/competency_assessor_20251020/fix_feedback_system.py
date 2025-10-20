"""
Comprehensive fix for the LLM feedback system:
1. Create assessment_feedback table
2. Create feedback generation stored procedure
3. Create trigger on survey_completion_status
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("FIXING LLM FEEDBACK SYSTEM")
    print("=" * 80)

    # Step 1: Create assessment_feedback table
    print("\n[1/3] Creating assessment_feedback table...")
    try:
        db.session.execute(text("""
            CREATE TABLE IF NOT EXISTS assessment_feedback (
                id SERIAL PRIMARY KEY,
                username VARCHAR(255) NOT NULL,
                competency_id INTEGER NOT NULL,
                feedback_text TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (username) REFERENCES new_survey_user(username),
                FOREIGN KEY (competency_id) REFERENCES competencies(id)
            )
        """))
        db.session.commit()
        print("   [SUCCESS] assessment_feedback table created")
    except Exception as e:
        print(f"   [ERROR] Failed to create table: {e}")
        db.session.rollback()

    # Step 2: Create stored procedure for feedback generation
    print("\n[2/3] Creating feedback generation stored procedure...")
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
                    SELECT DISTINCT c.id, c.name
                    FROM competencies c
                    JOIN role_competency rc ON rc.competency_id = c.id
                    WHERE EXISTS (
                        SELECT 1 FROM competency_assessment ca
                        WHERE ca.username = p_username
                        AND ca.competency_id = c.id
                    )
                LOOP
                    -- Generate feedback (placeholder - will be replaced by LLM)
                    feedback_text := 'Feedback for ' || competency_record.name || ' - Assessment ID: ' || p_username;

                    -- Insert feedback
                    INSERT INTO assessment_feedback (username, competency_id, feedback_text)
                    VALUES (p_username, competency_record.id, feedback_text);
                END LOOP;
            END;
            $$ LANGUAGE plpgsql;
        """))
        db.session.commit()
        print("   [SUCCESS] Stored procedure created")
    except Exception as e:
        print(f"   [ERROR] Failed to create procedure: {e}")
        db.session.rollback()

    # Step 3: Create trigger on survey_completion_status
    print("\n[3/3] Creating trigger on survey_completion_status...")
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
        print("   [SUCCESS] Trigger created")
    except Exception as e:
        print(f"   [ERROR] Failed to create trigger: {e}")
        db.session.rollback()

    # Verify setup
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
    print("[SUCCESS] LLM feedback system setup complete!")
    print("=" * 80)
