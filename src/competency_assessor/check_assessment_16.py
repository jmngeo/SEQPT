import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, AdminUser

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ASSESSMENT 16")
    print("=" * 80)

    # Get assessment 16
    assessment = CompetencyAssessment.query.get(16)

    if assessment:
        print(f"\nAssessment ID: {assessment.id}")
        print(f"  Admin User ID: {assessment.admin_user_id}")
        print(f"  App User ID: {assessment.app_user_id}")
        print(f"  Organization ID: {assessment.organization_id}")
        print(f"  Assessment Type: {assessment.assessment_type}")
        print(f"  Date: {assessment.assessment_date}")
        print(f"  Status: {assessment.status}")

        # Get admin user who created it
        admin = AdminUser.query.get(assessment.admin_user_id)
        if admin:
            print(f"\n  Created by Admin:")
            print(f"    Username: {admin.username}")
            print(f"    Role: {admin.role}")
            print(f"    Organization ID: {admin.organization_id}")

            if assessment.organization_id == admin.organization_id:
                print(f"\n  [OK] Assessment org_id matches admin's org_id")
            else:
                print(f"\n  [ERROR] Mismatch!")
                print(f"    Assessment org_id: {assessment.organization_id}")
                print(f"    Admin org_id: {admin.organization_id}")
    else:
        print("\n[NOT FOUND] Assessment 16 does not exist in database")

    # Show recent assessments
    print("\n" + "=" * 80)
    print("RECENT ASSESSMENTS (last 5)")
    print("=" * 80)
    recent = CompetencyAssessment.query.order_by(CompetencyAssessment.id.desc()).limit(5).all()
    for a in recent:
        print(f"ID: {a.id}, Admin: {a.admin_user_id}, Org: {a.organization_id}, Date: {a.assessment_date}")
