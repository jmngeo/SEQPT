import os
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, AdminUser

app = create_app()

with app.app_context():
    print("=" * 80)
    print("FIXING ASSESSMENTS 17 AND 18")
    print("=" * 80)

    assessments = CompetencyAssessment.query.filter(
        CompetencyAssessment.id.in_([17, 18])
    ).all()

    for assessment in assessments:
        admin = AdminUser.query.get(assessment.admin_user_id)
        if admin:
            old_org_id = assessment.organization_id
            assessment.organization_id = admin.organization_id

            print(f"\nAssessment {assessment.id}:")
            print(f"  Old org_id: {old_org_id}")
            print(f"  New org_id: {admin.organization_id}")
            print(f"  Admin: {admin.username}")

    db.session.commit()
    print("\n[SUCCESS] Fixed assessments 17 and 18!")
    print("=" * 80)
