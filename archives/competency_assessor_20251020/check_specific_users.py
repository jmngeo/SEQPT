import os

os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import AdminUser

app = create_app()

with app.app_context():
    # Check admin users with IDs 30 and 31 (who created the assessments)
    users = AdminUser.query.filter(AdminUser.id.in_([30, 31])).all()

    print("="* 80)
    print("ADMIN USERS WHO CREATED ASSESSMENTS:")
    print("=" * 80)
    for user in users:
        print(f"ID: {user.id}, Username: {user.username}, Role: {user.role}, Org ID: {user.organization_id}")

    # Also check the current admin user
    print("\n" + "=" * 80)
    print("ALL ADMIN USERS (showing org_id and role):")
    print("=" * 80)
    all_users = AdminUser.query.order_by(AdminUser.id).all()
    for user in all_users:
        print(f"ID: {user.id}, Username: {user.username}, Role: {user.role}, Org ID: {user.organization_id}")
