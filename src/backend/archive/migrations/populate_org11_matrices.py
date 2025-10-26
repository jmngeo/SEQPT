"""
Populate role_process_matrix for organization_id=11 using the stored procedure
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("="*80)
    print("POPULATING MATRICES FOR ORGANIZATION ID=11")
    print("="*80)

    # Check if organization 11 exists
    result = db.session.execute(text(
        "SELECT id, organization_name FROM organization WHERE id = 11"
    ))
    org = result.fetchone()

    if not org:
        print("\n[ERROR] Organization ID=11 does not exist!")
        print("Please check the organization ID in your test.")
        exit(1)

    print(f"\n[OK] Found organization: {org[1]} (ID={org[0]})")

    # Check current state
    print("\n[1/3] Checking current matrix data for org 11...")
    result = db.session.execute(text(
        "SELECT COUNT(*) FROM role_process_matrix WHERE organization_id = 11"
    ))
    count = result.scalar()
    print(f"  Current role_process_matrix entries for org 11: {count}")

    # Populate using stored procedure
    print("\n[2/3] Populating role_process_matrix for org 11...")
    try:
        db.session.execute(text(
            "CALL insert_new_org_default_role_process_matrix(11)"
        ))
        db.session.commit()
        print("  [OK] Stored procedure executed successfully")
    except Exception as e:
        print(f"  [ERROR] Failed to execute stored procedure: {e}")
        db.session.rollback()
        exit(1)

    # Verify
    print("\n[3/3] Verifying populated data...")
    result = db.session.execute(text(
        "SELECT COUNT(*) FROM role_process_matrix WHERE organization_id = 11"
    ))
    new_count = result.scalar()
    print(f"  New role_process_matrix entries for org 11: {new_count}")

    if new_count > 0:
        print(f"  [SUCCESS] Added {new_count} entries!")

        # Show sample
        result = db.session.execute(text("""
            SELECT rc.role_cluster_name, ip.process_name, rpm.role_process_value
            FROM role_process_matrix rpm
            JOIN role_cluster rc ON rpm.role_cluster_id = rc.id
            JOIN iso_process ip ON rpm.iso_process_id = ip.id
            WHERE rpm.organization_id = 11
            LIMIT 10
        """))

        print("\n  Sample entries:")
        for role, process, value in result.fetchall():
            print(f"    {role[:30]:<30} | {process[:40]:<40} | {value}")
    else:
        print("  [WARNING] No entries were added")

    print("\n" + "="*80)
    print("MATRIX POPULATION COMPLETE")
    print("="*80)
    print("\nYou can now test role suggestion with organization_id=11")
