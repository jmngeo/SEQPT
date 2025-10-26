"""
Script to check if organization matrices are auto-populated correctly
Usage: python check_org_matrices.py [organization_id]
"""

import os
import sys
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    # Get organization_id from command line or use the latest
    if len(sys.argv) > 1:
        org_id = int(sys.argv[1])
    else:
        # Get the latest organization
        latest_org = db.session.execute(text("""
            SELECT id, organization_name FROM organization ORDER BY id DESC LIMIT 1;
        """)).fetchone()

        if not latest_org:
            print("[ERROR] No organizations found in database")
            exit(1)

        org_id = latest_org[0]
        org_name = latest_org[1]
        print(f"Checking latest organization: {org_name} (ID: {org_id})")

    print("=" * 80)
    print(f"CHECKING MATRICES FOR ORGANIZATION {org_id}")
    print("=" * 80)

    # Check role-process matrix
    print("\n[1/2] Checking role_process_matrix...")
    rp_count = db.session.execute(text("""
        SELECT COUNT(*)
        FROM role_process_matrix
        WHERE organization_id = :org_id;
    """), {'org_id': org_id}).scalar()

    print(f"  Entries found: {rp_count}")

    if rp_count == 392:
        print(f"  [OK] All 392 entries populated correctly!")
    elif rp_count == 0:
        print(f"  [ERROR] No entries found - matrix initialization failed")
    else:
        print(f"  [WARNING] Expected 392, found {rp_count}")

    # Show breakdown by role
    if rp_count > 0:
        print("\n  Breakdown by role:")
        role_breakdown = db.session.execute(text("""
            SELECT
                rc.role_cluster_name,
                COUNT(*) as process_count
            FROM role_process_matrix rpm
            JOIN role_cluster rc ON rpm.role_cluster_id = rc.id
            WHERE rpm.organization_id = :org_id
            GROUP BY rc.role_cluster_name
            ORDER BY rc.id;
        """), {'org_id': org_id}).fetchall()

        for role_name, count in role_breakdown:
            print(f"    - {role_name}: {count} processes")

    # Check role-competency matrix
    print("\n[2/2] Checking role_competency_matrix...")
    rc_count = db.session.execute(text("""
        SELECT COUNT(*)
        FROM role_competency_matrix
        WHERE organization_id = :org_id;
    """), {'org_id': org_id}).scalar()

    print(f"  Entries found: {rc_count}")

    if rc_count == 0:
        print(f"  [INFO] Empty (no competencies loaded yet) - this is expected")
    else:
        print(f"  [OK] {rc_count} entries populated")

    print("\n" + "=" * 80)
    print("CHECK COMPLETE")
    print("=" * 80)

    # Summary
    print("\nSummary:")
    print(f"  Organization ID: {org_id}")
    print(f"  Role-Process Matrix: {rp_count} / 392 entries")
    print(f"  Role-Competency Matrix: {rc_count} entries")

    if rp_count == 392:
        print("\n[SUCCESS] Matrix auto-initialization working correctly!")
    else:
        print("\n[FAILED] Matrix initialization incomplete")
