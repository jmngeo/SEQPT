import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("LINKING EXISTING FEEDBACK TO ASSESSMENT #7")
    print("=" * 80)

    # Update feedback for user_id 42 to link to assessment #7
    result = db.session.execute(text("""
        UPDATE user_competency_survey_feedback
        SET assessment_id = 7
        WHERE user_id = 42 AND assessment_id IS NULL
    """))
    db.session.commit()

    print(f"\n[SUCCESS] Updated {result.rowcount} feedback record(s)")
    print("Feedback is now linked to assessment #7")

    # Verify the update
    feedback = db.session.execute(text("""
        SELECT id, user_id, assessment_id, created_at
        FROM user_competency_survey_feedback
        WHERE user_id = 42
    """)).fetchone()

    if feedback:
        print(f"\nVerification:")
        print(f"   Feedback ID: {feedback[0]}")
        print(f"   User ID: {feedback[1]}")
        print(f"   Assessment ID: {feedback[2]}")
        print(f"   Created At: {feedback[3]}")

    print("\n" + "=" * 80)
