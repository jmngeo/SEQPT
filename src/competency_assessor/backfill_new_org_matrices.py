"""
Backfill matrix defaults for organizations that were created without them.
This script identifies organizations missing matrix data and populates them.
"""

from app import create_app, db
from app.models import Organization, RoleProcessMatrix, RoleCompetencyMatrix
from sqlalchemy import text

def backfill_organizations():
    """Backfill matrix data for organizations that don't have it"""
    app = create_app()

    with app.app_context():
        print("=" * 60)
        print("Backfilling matrix defaults for organizations...")
        print("=" * 60)

        # Get all organizations
        all_orgs = Organization.query.all()
        print(f"\nFound {len(all_orgs)} total organizations")

        # Check which organizations are missing matrix data
        orgs_to_backfill = []

        for org in all_orgs:
            # Check if org has role-process matrix data
            rpm_count = RoleProcessMatrix.query.filter_by(organization_id=org.id).count()
            rcm_count = RoleCompetencyMatrix.query.filter_by(organization_id=org.id).count()

            if rpm_count == 0 or rcm_count == 0:
                orgs_to_backfill.append({
                    'org': org,
                    'rpm_count': rpm_count,
                    'rcm_count': rcm_count
                })
                print(f"\n  Org {org.id} ({org.organization_name}): RPM={rpm_count}, RCM={rcm_count} - NEEDS BACKFILL")
            else:
                print(f"\n  Org {org.id} ({org.organization_name}): RPM={rpm_count}, RCM={rcm_count} - OK")

        if not orgs_to_backfill:
            print("\n" + "=" * 60)
            print("[OK] All organizations have matrix data!")
            print("=" * 60)
            return

        print("\n" + "=" * 60)
        print(f"Backfilling {len(orgs_to_backfill)} organization(s)...")
        print("=" * 60)

        for item in orgs_to_backfill:
            org = item['org']
            print(f"\n[{org.id}] Processing: {org.organization_name}")

            try:
                # Call stored procedures to populate defaults
                if item['rpm_count'] == 0:
                    print(f"  - Copying Role-Process Matrix...")
                    db.session.execute(
                        text("CALL insert_new_org_default_role_process_matrix(:org_id)"),
                        {'org_id': org.id}
                    )
                    db.session.commit()
                    print(f"  [OK] Role-Process Matrix populated")
                else:
                    print(f"  [SKIP] Role-Process Matrix already exists")

                if item['rcm_count'] == 0:
                    print(f"  - Copying Role-Competency Matrix...")
                    db.session.execute(
                        text("CALL insert_new_org_default_role_competency_matrix(:org_id)"),
                        {'org_id': org.id}
                    )
                    db.session.commit()
                    print(f"  [OK] Role-Competency Matrix populated")
                else:
                    print(f"  [SKIP] Role-Competency Matrix already exists")

            except Exception as e:
                print(f"  [ERROR] Failed to backfill org {org.id}: {e}")
                db.session.rollback()
                continue

        print("\n" + "=" * 60)
        print("[SUCCESS] Backfill completed!")
        print("=" * 60)

        # Final verification
        print("\nFinal matrix counts:")
        for item in orgs_to_backfill:
            org = item['org']
            rpm_count = RoleProcessMatrix.query.filter_by(organization_id=org.id).count()
            rcm_count = RoleCompetencyMatrix.query.filter_by(organization_id=org.id).count()
            print(f"  Org {org.id}: RPM={rpm_count}, RCM={rcm_count}")


if __name__ == '__main__':
    backfill_organizations()
