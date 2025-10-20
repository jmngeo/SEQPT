"""
Check actual feedback in database for a specific user.
"""
from app import create_app, db
from app.models import UserCompetencySurveyFeedback, AppUser
import json

app = create_app()

with app.app_context():
    # Get the most recent user
    recent_user = AppUser.query.order_by(AppUser.id.desc()).first()

    if not recent_user:
        print("No users found in database")
        exit()

    print(f"Checking feedback for user: {recent_user.username} (ID: {recent_user.id})")
    print("="*80)

    # Get feedback for this user
    feedback = UserCompetencySurveyFeedback.query.filter_by(
        user_id=recent_user.id
    ).first()

    if not feedback:
        print("No feedback found for this user")
        exit()

    feedback_list = feedback.feedback

    for area_feedback in feedback_list:
        competency_area = area_feedback.get('competency_area', 'Unknown')
        print(f"\n{'='*80}")
        print(f"COMPETENCY AREA: {competency_area}")
        print('='*80)

        feedbacks = area_feedback.get('feedbacks', [])
        for fb in feedbacks:
            competency_name = fb.get('competency_name', 'Unknown')
            strengths = fb.get('user_strengths', 'N/A')
            improvements = fb.get('improvement_areas', 'N/A')

            print(f"\nCompetency: {competency_name}")
            print(f"Strengths:\n  {strengths}")
            print(f"Improvements:\n  {improvements}")

            # Check if this is a problematic case
            if "demonstrate awareness" in strengths.lower():
                print("  [NOTE: Level 1 - Aware feedback]")
            if "successfully achieved" in strengths.lower() and improvements != "N/A":
                print("  [WARNING: Says 'successfully achieved' but has improvement areas!]")
            if "exceed" in strengths.lower() and improvements != "N/A":
                print("  [WARNING: Says 'exceed' but has improvement areas!]")
