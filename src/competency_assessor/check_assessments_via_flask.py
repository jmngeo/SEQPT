import os
import sys

# Set environment variables
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

from app import create_app, db
from app.models import AdminUser, CompetencyAssessment

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ADMIN USERS AND ORGANIZATION IDs")
    print("=" * 80)

    # Check admin users
    admin_users = AdminUser.query.order_by(AdminUser.id).limit(20).all()

    print("\nADMIN USERS:")
    print("-" * 80)
    for user in admin_users:
        print(f"ID: {user.id}, Username: {user.username}, Role: {user.role}, Org ID: {user.organization_id}")

    # Check competency assessments
    assessments = CompetencyAssessment.query.order_by(CompetencyAssessment.assessment_date.desc()).limit(20).all()

    print("\n" + "=" * 80)
    print("COMPETENCY ASSESSMENTS:")
    print("-" * 80)
    if assessments:
        for assessment in assessments:
            print(f"ID: {assessment.id}, Admin User ID: {assessment.admin_user_id}, Org ID: {assessment.organization_id}, Type: {assessment.assessment_type}, Date: {assessment.assessment_date}, Status: {assessment.status}")
    else:
        print("NO ASSESSMENTS FOUND")

    # Check counts
    total_assessments = CompetencyAssessment.query.count()
    total_users = AdminUser.query.count()

    print("\n" + "=" * 80)
    print("SUMMARY:")
    print("-" * 80)
    print(f"Total admin users: {total_users}")
    print(f"Total competency assessments: {total_assessments}")

    # Check assessments by organization
    print("\nAssessments by organization:")
    from sqlalchemy import func
    results = db.session.query(
        CompetencyAssessment.organization_id,
        func.count(CompetencyAssessment.id)
    ).group_by(CompetencyAssessment.organization_id).order_by(CompetencyAssessment.organization_id).all()

    for org_id, count in results:
        org_str = str(org_id) if org_id is not None else "NULL"
        print(f"  Org ID {org_str}: {count} assessments")

    # Check admin users by organization and role
    print("\nAdmin users by organization and role:")
    results = db.session.query(
        AdminUser.organization_id,
        AdminUser.role,
        func.count(AdminUser.id)
    ).group_by(AdminUser.organization_id, AdminUser.role).order_by(AdminUser.organization_id, AdminUser.role).all()

    for org_id, role, count in results:
        org_str = str(org_id) if org_id is not None else "NULL"
        role_str = role if role is not None else "NULL"
        print(f"  Org ID {org_str}, Role {role_str}: {count} users")

print("\n" + "=" * 80)
