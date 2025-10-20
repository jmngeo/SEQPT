"""
Test that the trigger fix works for both task-based and role-based assessments.
"""
from app import create_app, db
from app.models import NewSurveyUser
from datetime import datetime

app = create_app()

print("Testing trigger fix...")
print("=" * 60)

with app.app_context():
    # Test 1: Create with custom username (task-based assessment)
    print("\nTest 1: Task-based assessment (custom username)")
    print("-" * 60)
    custom_username = f"seqpt_user_{int(datetime.now().timestamp() * 1000)}"
    print(f"Creating NewSurveyUser with username: {custom_username}")

    try:
        user1 = NewSurveyUser(username=custom_username)
        db.session.add(user1)
        db.session.commit()
        db.session.refresh(user1)

        if user1.username == custom_username:
            print(f"[SUCCESS] Username preserved: {user1.username}")
        else:
            print(f"[FAILED] Username changed to: {user1.username}")
    except Exception as e:
        print(f"[ERROR] {e}")
        db.session.rollback()

    # Test 2: Create without username (role-based assessment)
    print("\nTest 2: Role-based assessment (auto-generated username)")
    print("-" * 60)
    print("Creating NewSurveyUser without username...")

    try:
        user2 = NewSurveyUser()
        db.session.add(user2)
        db.session.commit()
        db.session.refresh(user2)

        if user2.username and user2.username.startswith('se_survey_user_'):
            print(f"[SUCCESS] Username auto-generated: {user2.username}")
        else:
            print(f"[FAILED] Unexpected username: {user2.username}")
    except Exception as e:
        print(f"[ERROR] {e}")
        db.session.rollback()

    print("\n" + "=" * 60)
    print("Trigger fix verification complete!")
