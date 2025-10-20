"""
Seed default matrix values from KÖNEMANN et al.
This populates:
1. Process-Competency Matrix (static, organization-independent)
2. Role-Process Matrix (per organization, editable by admins)
"""

from app import create_app, db
from app.models import ProcessCompetencyMatrix, RoleProcessMatrix, Organization
from sqlalchemy import text

def seed_process_competency_matrix():
    """Seed the Process-Competency Matrix with KÖNEMANN default values"""
    print("Seeding Process-Competency Matrix...")

    # Read data from extracted file
    data_file = 'process_competency_data.txt'

    try:
        with open(data_file, 'r') as f:
            lines = f.readlines()

        for line in lines:
            parts = line.strip().split('\t')
            if len(parts) == 4:
                id_val, iso_process_id, competency_id, value = parts

                # Check if entry already exists
                existing = ProcessCompetencyMatrix.query.filter_by(
                    iso_process_id=int(iso_process_id),
                    competency_id=int(competency_id)
                ).first()

                if not existing:
                    entry = ProcessCompetencyMatrix(
                        iso_process_id=int(iso_process_id),
                        competency_id=int(competency_id),
                        process_competency_value=int(value)
                    )
                    db.session.add(entry)

        db.session.commit()
        print(f"[OK] Seeded {len(lines)} Process-Competency Matrix entries")

    except FileNotFoundError:
        print(f"[ERROR] File {data_file} not found")
        return False
    except Exception as e:
        print(f"[ERROR] Failed to seed Process-Competency Matrix: {e}")
        db.session.rollback()
        return False

    return True


def seed_role_process_matrix_for_org(org_id):
    """Seed Role-Process Matrix with default KÖNEMANN values for a specific organization"""
    print(f"Seeding Role-Process Matrix for organization {org_id}...")

    # Read default data from extracted file
    data_file = 'role_process_default.txt'

    try:
        with open(data_file, 'r') as f:
            lines = f.readlines()

        for line in lines:
            parts = line.strip().split('\t')
            if len(parts) == 5:
                _, role_cluster_id, iso_process_id, value, _ = parts

                # Check if entry already exists for this organization
                existing = RoleProcessMatrix.query.filter_by(
                    role_cluster_id=int(role_cluster_id),
                    iso_process_id=int(iso_process_id),
                    organization_id=org_id
                ).first()

                if not existing:
                    entry = RoleProcessMatrix(
                        role_cluster_id=int(role_cluster_id),
                        iso_process_id=int(iso_process_id),
                        role_process_value=int(value),
                        organization_id=org_id
                    )
                    db.session.add(entry)

        db.session.commit()
        print(f"[OK] Seeded {len(lines)} Role-Process Matrix entries for org {org_id}")

    except FileNotFoundError:
        print(f"[ERROR] File {data_file} not found")
        return False
    except Exception as e:
        print(f"[ERROR] Failed to seed Role-Process Matrix for org {org_id}: {e}")
        db.session.rollback()
        return False

    return True


def recalculate_role_competency_matrix(org_id):
    """Trigger stored procedure to calculate Role-Competency Matrix"""
    print(f"Calculating Role-Competency Matrix for organization {org_id}...")

    try:
        db.session.execute(
            text('CALL update_role_competency_matrix(:org_id);'),
            {'org_id': org_id}
        )
        db.session.commit()
        print(f"[OK] Role-Competency Matrix calculated for org {org_id}")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to calculate Role-Competency Matrix for org {org_id}: {e}")
        db.session.rollback()
        return False


def main():
    """Main seed function"""
    app = create_app()

    with app.app_context():
        print("=" * 60)
        print("Starting matrix seeding with KÖNEMANN default values...")
        print("=" * 60)

        try:
            # Step 1: Seed Process-Competency Matrix (organization-independent)
            if not seed_process_competency_matrix():
                return

            # Step 2: Get all organizations and seed Role-Process Matrix for each
            organizations = Organization.query.all()

            if not organizations:
                print("[WARNING] No organizations found. Matrix seeding incomplete.")
                print("Create organizations first, then run this script again.")
                return

            for org in organizations:
                # Seed Role-Process Matrix with defaults for this org
                if not seed_role_process_matrix_for_org(org.id):
                    continue

                # Calculate Role-Competency Matrix for this org
                if not recalculate_role_competency_matrix(org.id):
                    continue

            print("=" * 60)
            print("[SUCCESS] Matrix seeding completed successfully!")
            print("=" * 60)
            print(f"\nSeeded default matrices for {len(organizations)} organization(s)")
            print("\nAdmins can now:")
            print("  1. View Process-Competency Matrix (view-only by default)")
            print("  2. Edit Role-Process Matrix per organization")
            print("  3. View auto-calculated Role-Competency Matrix")

        except Exception as e:
            print(f"\n[ERROR] Error during seeding: {e}")
            db.session.rollback()
            raise


if __name__ == '__main__':
    main()
