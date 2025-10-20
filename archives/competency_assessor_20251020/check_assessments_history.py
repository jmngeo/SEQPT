import os
import sys
from sqlalchemy import create_engine, text

# Database connection
DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"
engine = create_engine(DATABASE_URL)

print("=" * 80)
print("CHECKING ADMIN USERS AND ORGANIZATION IDs")
print("=" * 80)

with engine.connect() as conn:
    # Check admin users
    result = conn.execute(text("""
        SELECT id, username, role, organization_id
        FROM admin_user
        ORDER BY id
        LIMIT 20;
    """))

    print("\nADMIN USERS:")
    print("-" * 80)
    for row in result:
        print(f"ID: {row[0]}, Username: {row[1]}, Role: {row[2]}, Org ID: {row[3]}")

    # Check competency assessments
    result = conn.execute(text("""
        SELECT id, admin_user_id, organization_id, assessment_type, assessment_date, status
        FROM competency_assessment
        ORDER BY assessment_date DESC
        LIMIT 20;
    """))

    print("\n" + "=" * 80)
    print("COMPETENCY ASSESSMENTS:")
    print("-" * 80)
    rows = list(result)
    if rows:
        for row in rows:
            print(f"ID: {row[0]}, Admin User ID: {row[1]}, Org ID: {row[2]}, Type: {row[3]}, Date: {row[4]}, Status: {row[5]}")
    else:
        print("NO ASSESSMENTS FOUND")

    # Check counts
    result = conn.execute(text("SELECT COUNT(*) FROM competency_assessment;"))
    total_assessments = result.scalar()

    result = conn.execute(text("SELECT COUNT(*) FROM admin_user;"))
    total_users = result.scalar()

    print("\n" + "=" * 80)
    print("SUMMARY:")
    print("-" * 80)
    print(f"Total admin users: {total_users}")
    print(f"Total competency assessments: {total_assessments}")

    # Check assessments by organization
    result = conn.execute(text("""
        SELECT organization_id, COUNT(*)
        FROM competency_assessment
        GROUP BY organization_id
        ORDER BY organization_id;
    """))

    print("\nAssessments by organization:")
    for row in result:
        org_id = row[0] if row[0] is not None else "NULL"
        print(f"  Org ID {org_id}: {row[1]} assessments")

    # Check admin users by organization
    result = conn.execute(text("""
        SELECT organization_id, role, COUNT(*)
        FROM admin_user
        GROUP BY organization_id, role
        ORDER BY organization_id, role;
    """))

    print("\nAdmin users by organization and role:")
    for row in result:
        org_id = row[0] if row[0] is not None else "NULL"
        print(f"  Org ID {org_id}, Role {row[1]}: {row[2]} users")

print("\n" + "=" * 80)
