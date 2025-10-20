import os

os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import CompetencyAssessment, AdminUser

app = create_app()

with app.app_context():
    print("=" * 80)
    print("FIXING ASSESSMENT ORGANIZATION IDs")
    print("=" * 80)

    # Get all assessments with incorrect organization_id
    assessments = CompetencyAssessment.query.all()

    print(f"\nFound {len(assessments)} assessments to check")

    fixed_count = 0
    already_correct = 0

    for assessment in assessments:
        # Get the admin user who created this assessment
        admin_user = AdminUser.query.get(assessment.admin_user_id)

        if not admin_user:
            print(f"  [SKIP] Assessment {assessment.id}: Admin user {assessment.admin_user_id} not found")
            continue

        if assessment.organization_id == admin_user.organization_id:
            already_correct += 1
            continue

        # Update the assessment's organization_id to match the admin user's
        old_org_id = assessment.organization_id
        assessment.organization_id = admin_user.organization_id

        print(f"  [FIX] Assessment {assessment.id}: {old_org_id} -> {admin_user.organization_id} (admin_user: {admin_user.username})")
        fixed_count += 1

    # Commit all changes
    if fixed_count > 0:
        db.session.commit()
        print(f"\n{fixed_count} assessments updated successfully!")
    else:
        print(f"\nAll assessments already have correct organization_id!")

    print(f"  - Fixed: {fixed_count}")
    print(f"  - Already correct: {already_correct}")
    print(f"  - Total: {len(assessments)}")

print("\n" + "=" * 80)
