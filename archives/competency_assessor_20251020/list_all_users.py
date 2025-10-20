"""
Script to list all users in the database
"""
from app import create_app, db
from app.models import AppUser, AdminUser, NewSurveyUser

def list_all_users():
    app = create_app()

    with app.app_context():
        print("=" * 80)
        print("ALL USERS IN DATABASE")
        print("=" * 80)

        # AppUser
        app_users = AppUser.query.all()
        print(f"\nAppUser table: {len(app_users)} users")
        for user in app_users:
            print(f"  - {user.username} (ID: {user.id}, Org: {user.organization_id})")

        # AdminUser
        admin_users = AdminUser.query.all()
        print(f"\nAdminUser table: {len(admin_users)} users")
        for user in admin_users:
            print(f"  - {user.username} (ID: {user.id}, Role: {user.role}, Org: {user.organization_id})")

        # NewSurveyUser
        survey_users = NewSurveyUser.query.all()
        print(f"\nNewSurveyUser table: {len(survey_users)} users")
        for user in survey_users:
            print(f"  - {user.username} (ID: {user.id}, Completed: {user.survey_completion_status})")

if __name__ == '__main__':
    list_all_users()
