import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ASSESSMENT #7 DETAILS")
    print("=" * 80)

    # Check if assessment #7 exists
    print("\n1. Check CompetencyAssessment #7:")
    assessment = db.session.execute(text("SELECT * FROM competency_assessment WHERE id = 7")).fetchone()
    if assessment:
        print("   [EXISTS] Assessment #7 found")
        print(f"   - ID: {assessment[0]}")
        print(f"   - admin_user_id: {assessment[1]}")
        print(f"   - app_user_id: {assessment[2]}")
        print(f"   - organization_id: {assessment[3]}")
        print(f"   - assessment_type: {assessment[4]}")
        print(f"   - status: {assessment[6]}")
        app_user_id = assessment[2]
    else:
        print("   [ERROR] Assessment #7 NOT FOUND")
        app_user_id = None

    # Check if associated AppUser exists
    if app_user_id:
        print(f"\n2. Check AppUser #{app_user_id}:")
        user = db.session.execute(text(f"SELECT * FROM app_user WHERE id = {app_user_id}")).fetchone()
        if user:
            print(f"   [EXISTS] AppUser found")
            print(f"   - ID: {user[0]}")
            print(f"   - organization_id: {user[1]}")
            print(f"   - name: {user[3]}")
            print(f"   - username: {user[4]}")
            username = user[4]
        else:
            print(f"   [ERROR] AppUser #{app_user_id} NOT FOUND")
            username = None

        # Check survey results
        print(f"\n3. Check UserCompetencySurveyResults for assessment #7:")
        results = db.session.execute(text(f"SELECT COUNT(*) FROM user_se_competency_survey_results WHERE assessment_id = 7")).fetchone()[0]
        print(f"   - Found {results} competency results")

        # Check feedback
        if username:
            print(f"\n4. Check UserCompetencySurveyFeedback for user '{username}':")
            feedback = db.session.execute(text(f"SELECT COUNT(*) FROM user_competency_survey_feedback WHERE user_id = {app_user_id}")).fetchone()[0]
            print(f"   - Found {feedback} feedback entries")
    else:
        print("\n[SKIP] No app_user_id to check")

    print("\n" + "=" * 80)
