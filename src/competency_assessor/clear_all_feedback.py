"""
Clear all cached feedback to force regeneration with the fixed logic.
"""
from app import create_app, db
from app.models import UserCompetencySurveyFeedback

app = create_app()

with app.app_context():
    # Count existing feedback
    count = UserCompetencySurveyFeedback.query.count()
    print(f"Found {count} cached feedback entries")

    # Delete all cached feedback
    UserCompetencySurveyFeedback.query.delete()
    db.session.commit()

    print(f"[SUCCESS] Cleared all {count} cached feedback entries")
    print("Next time users view results, feedback will regenerate with the fixed logic")
