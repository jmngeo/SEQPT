"""
Clear feedback for a specific user to force regeneration with updated LLM prompt.
"""

from app import create_app, db
from app.models import UserCompetencySurveyFeedback, AppUser
import sys

def clear_user_feedback(username):
    app = create_app()
    with app.app_context():
        # Find user by username
        user = AppUser.query.filter_by(username=username).first()

        if not user:
            print(f"[ERROR] User '{username}' not found in database")
            return False

        print(f"[OK] Found user: {username} (ID: {user.id})")

        # Delete all feedback for this user
        deleted_count = UserCompetencySurveyFeedback.query.filter_by(user_id=user.id).delete()
        db.session.commit()

        print(f"[OK] Deleted {deleted_count} feedback record(s) for user {username}")
        print(f"[OK] Next assessment will generate fresh feedback with updated LLM prompt")

        return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        username = sys.argv[1]
    else:
        # Default to the user mentioned by the user
        username = "se_survey_user_49"

    print(f"Clearing feedback cache for user: {username}")
    print("=" * 60)
    clear_user_feedback(username)
