import sys
import os
import json
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ACTUAL FEEDBACK CONTENT FOR ASSESSMENT #7")
    print("=" * 80)

    # Get feedback for user_id 42
    print("\nFetching feedback for user_id=42:")
    feedback = db.session.execute(text("""
        SELECT id, feedback, created_at, assessment_id
        FROM user_competency_survey_feedback
        WHERE user_id = 42
    """)).fetchone()

    if feedback:
        print(f"\n[FOUND] Feedback ID: {feedback[0]}")
        print(f"Created at: {feedback[2]}")
        print(f"Assessment ID: {feedback[3]}")
        print(f"\nFeedback content (first 500 chars):")
        feedback_data = feedback[1]
        if isinstance(feedback_data, str):
            feedback_json = json.loads(feedback_data)
        else:
            feedback_json = feedback_data

        print(json.dumps(feedback_json, indent=2)[:1000])
        print("\n...")
        print(f"\nTotal feedback areas: {len(feedback_json)}")
        for area in feedback_json:
            print(f"   - {area.get('competency_area', 'Unknown')}: {len(area.get('feedbacks', []))} competencies")
    else:
        print("[NOT FOUND] No feedback for user_id=42")

    # Check what the API endpoint would return
    print("\n" + "=" * 80)
    print("SIMULATING API RESPONSE")
    print("=" * 80)

    assessment = db.session.execute(text("SELECT * FROM competency_assessment WHERE id = 7")).fetchone()
    app_user_id = assessment[2]
    organization_id = assessment[3]

    existing_feedbacks = db.session.execute(text("""
        SELECT feedback FROM user_competency_survey_feedback
        WHERE user_id = :user_id AND organization_id = :organization_id
    """), {"user_id": app_user_id, "organization_id": organization_id}).fetchall()

    print(f"\nQuery for user_id={app_user_id}, organization_id={organization_id}")
    print(f"Found {len(existing_feedbacks)} feedback entries")

    if existing_feedbacks:
        feedback_list = [fb[0] for fb in existing_feedbacks]
        print(f"\nFeedback list length: {len(feedback_list)}")
        print(f"First feedback type: {type(feedback_list[0])}")

    print("\n" + "=" * 80)
