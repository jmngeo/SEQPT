import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, AdminUser

app = create_app()

with app.app_context():
    print("=" * 80)
    print("FIXING ASSESSMENT 16 ORGANIZATION ID")
    print("=" * 80)

    assessment = CompetencyAssessment.query.get(16)

    if assessment:
        admin = AdminUser.query.get(assessment.admin_user_id)

        if admin:
            old_org_id = assessment.organization_id
            assessment.organization_id = admin.organization_id

            db.session.commit()

            print(f"\n[FIXED] Assessment 16:")
            print(f"  Old organization_id: {old_org_id}")
            print(f"  New organization_id: {admin.organization_id}")
            print(f"  Admin: {admin.username} (org_id={admin.organization_id})")
            print("\n[SUCCESS] Assessment 16 updated successfully!")
        else:
            print("\n[ERROR] Admin user not found")
    else:
        print("\n[ERROR] Assessment 16 not found")
