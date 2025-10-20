import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, UserCompetencySurveyFeedback, AppUser
import json

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING FEEDBACK FOR ASSESSMENTS")
    print("=" * 80)

    # Get recent assessments
    assessments = CompetencyAssessment.query.order_by(CompetencyAssessment.assessment_date.desc()).limit(5).all()

    for assessment in assessments:
        print(f"\n--- Assessment ID: {assessment.id} ---")
        print(f"  Admin User: {assessment.admin_user_id}")
        print(f"  App User: {assessment.app_user_id}")
        print(f"  Organization: {assessment.organization_id}")
        print(f"  Type: {assessment.assessment_type}")
        print(f"  Date: {assessment.assessment_date}")

        # Get app user
        user = AppUser.query.get(assessment.app_user_id)
        if user:
            print(f"  Username: {user.username}")

        # Check if feedback exists for this assessment
        feedback_by_assessment = UserCompetencySurveyFeedback.query.filter_by(
            assessment_id=assessment.id
        ).all()

        if feedback_by_assessment:
            print(f"  [OK] Feedback found (by assessment_id)! Count: {len(feedback_by_assessment)}")
            for fb in feedback_by_assessment:
                print(f"    - Feedback ID: {fb.id}, Created: {fb.created_at}")
                if isinstance(fb.feedback, list):
                    print(f"      Feedback areas: {len(fb.feedback)}")
                    for area in fb.feedback[:2]:  # Show first 2
                        print(f"        - {area.get('competency_area', 'N/A')}")
        else:
            print(f"  [MISSING] No feedback found by assessment_id")

            # Also check by user_id and organization_id (old method)
            feedback_by_user = UserCompetencySurveyFeedback.query.filter_by(
                user_id=user.id if user else None,
                organization_id=assessment.organization_id
            ).all()

            if feedback_by_user:
                print(f"  [INFO] Found {len(feedback_by_user)} feedback(s) by user_id + org_id (not linked to assessment)")
                for fb in feedback_by_user:
                    print(f"    - Feedback ID: {fb.id}, assessment_id: {fb.assessment_id}")

    print("\n" + "=" * 80)
    print("ALL FEEDBACK RECORDS")
    print("=" * 80)
    all_feedback = UserCompetencySurveyFeedback.query.order_by(UserCompetencySurveyFeedback.created_at.desc()).limit(10).all()
    for fb in all_feedback:
        print(f"ID: {fb.id}, User: {fb.user_id}, Org: {fb.organization_id}, Assessment: {fb.assessment_id}, Created: {fb.created_at}")
