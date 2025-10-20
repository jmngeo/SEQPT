import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, AdminUser

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ASSESSMENTS 17 AND 18")
    print("=" * 80)

    # Get recent assessments
    assessments = CompetencyAssessment.query.filter(
        CompetencyAssessment.id.in_([17, 18])
    ).all()

    for assessment in assessments:
        admin = AdminUser.query.get(assessment.admin_user_id)

        print(f"\nAssessment ID: {assessment.id}")
        print(f"  Admin User ID: {assessment.admin_user_id} ({admin.username if admin else 'Unknown'})")
        print(f"  Organization ID: {assessment.organization_id}")
        print(f"  Date: {assessment.assessment_date}")

        if admin:
            print(f"  Admin's Org ID: {admin.organization_id}")
            if assessment.organization_id == admin.organization_id:
                print(f"  [OK] Organization IDs match")
            else:
                print(f"  [ERROR] Mismatch! Assessment has org_id {assessment.organization_id}, admin has {admin.organization_id}")

    print("\n" + "=" * 80)
    print("ALL RECENT ASSESSMENTS")
    print("=" * 80)
    recent = CompetencyAssessment.query.order_by(CompetencyAssessment.id.desc()).limit(5).all()
    for a in recent:
        print(f"ID: {a.id}, Admin: {a.admin_user_id}, Org: {a.organization_id}, Date: {a.assessment_date}")
