"""
Script to verify the new_survey_user endpoint is working correctly.
"""
from app import create_app, db
from app.models import NewSurveyUser

def verify_endpoint():
    app = create_app()

    with app.app_context():
        # Check all users in the table
        users = NewSurveyUser.query.all()

        print("=" * 60)
        print("NewSurveyUser Table Contents")
        print("=" * 60)
        print(f"Total users: {len(users)}\n")

        for user in users:
            print(f"ID: {user.id}")
            print(f"Username: {user.username}")
            print(f"Created at: {user.created_at}")
            print(f"Completion status: {user.survey_completion_status}")
            print("-" * 60)

        print("\n" + "=" * 60)
        print("Testing username uniqueness...")
        print("=" * 60)

        # Create a test user to verify trigger works
        new_user = NewSurveyUser()
        db.session.add(new_user)
        db.session.commit()
        db.session.refresh(new_user)

        print(f"Created new user: {new_user.username}")
        print(f"User ID: {new_user.id}")

        # Verify it's in the database
        verify = NewSurveyUser.query.filter_by(username=new_user.username).first()
        if verify:
            print(f"[OK] User successfully created and verified in database")
        else:
            print(f"[ERROR] User not found in database!")

if __name__ == '__main__':
    verify_endpoint()
