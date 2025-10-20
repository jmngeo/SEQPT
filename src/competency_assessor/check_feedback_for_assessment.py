import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, CompetencySurveyFeedback
import json

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING LLM FEEDBACK FOR ASSESSMENTS")
    print("=" * 80)

    # Get recent assessments
    assessments = CompetencyAssessment.query.order_by(CompetencyAssessment.assessment_date.desc()).limit(5).all()

    for assessment in assessments:
        print(f"\nAssessment ID: {assessment.id}")
        print(f"  Admin User: {assessment.admin_user_id}")
        print(f"  Organization: {assessment.organization_id}")
        print(f"  Date: {assessment.assessment_date}")
        print(f"  Type: {assessment.assessment_type}")

        # Check if feedback exists
        feedback = CompetencySurveyFeedback.query.filter_by(assessment_id=assessment.id).first()

        if feedback:
            print(f"  [OK] Feedback found!")
            print(f"  Feedback ID: {feedback.id}")
            print(f"  Created: {feedback.created_at}")

            # Parse and show sample feedback
            try:
                feedback_data = json.loads(feedback.feedback_content)
                print(f"  Number of competency areas: {len(feedback_data)}")
                for area in feedback_data[:2]:  # Show first 2 areas
                    print(f"    - {area['competency_area']}: {len(area.get('feedbacks', []))} competencies")
            except:
                print(f"  [ERROR] Could not parse feedback content")
        else:
            print(f"  [MISSING] No feedback found!")

    print("\n" + "=" * 80)
    print("FEEDBACK SUMMARY")
    print("=" * 80)
    total_feedback = CompetencySurveyFeedback.query.count()
    print(f"Total feedback records in database: {total_feedback}")
