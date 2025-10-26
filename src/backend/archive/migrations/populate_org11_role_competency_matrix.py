"""
Populate role_competency_matrix for organization 11
Uses stored procedure to copy from organization 1
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("POPULATING ROLE_COMPETENCY_MATRIX FOR ORGANIZATION 11")
    print("=" * 80)

    # Check current state
    print("\n[1/3] Checking current role_competency_matrix for org 11...")
    result = db.session.execute(text(
        "SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 11"
    ))
    current_count = result.scalar()
    print(f"  Current entries: {current_count}")

    # Check if org 1 has data (to copy from)
    print("\n[2/3] Checking organization 1 data (source)...")
    result = db.session.execute(text(
        "SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 1"
    ))
    org1_count = result.scalar()
    print(f"  Organization 1 entries: {org1_count}")

    if org1_count == 0:
        print("\n[ERROR] Organization 1 has no role_competency_matrix data!")
        print("  Cannot copy - source organization has no data")
        exit(1)

    # Copy from org 1 to org 11
    print(f"\n[3/3] Copying role_competency_matrix from org 1 to org 11...")
    try:
        db.session.execute(text(
            "CALL insert_new_org_default_role_competency_matrix(11)"
        ))
        db.session.commit()
        print("  [OK] Stored procedure executed successfully")
    except Exception as e:
        print(f"  [ERROR] Failed to execute stored procedure: {e}")
        db.session.rollback()
        exit(1)

    # Verify
    print("\n[VERIFICATION] Checking populated data...")
    result = db.session.execute(text(
        "SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 11"
    ))
    new_count = result.scalar()
    print(f"  New entries: {new_count}")

    if new_count > current_count:
        added = new_count - current_count
        print(f"  [SUCCESS] Added {added} new entries!")

        # Show sample
        print("\n  Sample entries:")
        result = db.session.execute(text("""
            SELECT rc.role_cluster_name, c.competency_name, rcm.role_competency_value
            FROM role_competency_matrix rcm
            JOIN role_cluster rc ON rcm.role_cluster_id = rc.id
            JOIN competency c ON rcm.competency_id = c.id
            WHERE rcm.organization_id = 11
            LIMIT 10
        """))

        for role, competency, value in result.fetchall():
            print(f"    {role[:25]:<25} | {competency[:35]:<35} | {value}")

        print(f"\n  ... and {new_count - 10} more entries")
    else:
        print("  [WARNING] No new entries were added")

    print("\n" + "=" * 80)
    print("MATRIX POPULATION COMPLETE")
    print("=" * 80)
    print("\nOrganization 11 is now ready for role suggestion testing!")
