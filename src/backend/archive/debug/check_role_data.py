"""
Check database for role clusters and role_competency_matrix data
"""
import sys
sys.path.insert(0, 'C:/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis/src/backend')

from models import db, RoleCluster, RoleCompetencyMatrix
from app import create_app

app = create_app()

with app.app_context():
    print("\n=== Checking Role Clusters (Global) ===")

    # RoleCluster is global - no organization_id
    all_roles = RoleCluster.query.all()

    if all_roles:
        print(f"Found {len(all_roles)} global roles:")
        for role in all_roles[:5]:  # Show first 5
            print(f"  - ID {role.id}: {role.role_cluster_name}")
        if len(all_roles) > 5:
            print(f"  ... and {len(all_roles) - 5} more roles")
    else:
        print("No roles found in database")

    print(f"\n=== Checking Role Competency Matrix ===")

    # Check organizations with matrix data
    org_matrices = db.session.query(
        RoleCompetencyMatrix.organization_id,
        db.func.count(RoleCompetencyMatrix.id).label('matrix_count')
    ).group_by(RoleCompetencyMatrix.organization_id).all()

    print(f"\nOrganizations with matrix data:")
    for org_id, count in org_matrices:
        print(f"  Organization {org_id}: {count} matrix entries")

    # Check org 11 matrix specifically
    print(f"\n=== Organization 11 Matrix ===")
    org11_matrix = RoleCompetencyMatrix.query.filter_by(organization_id=11).limit(10).all()

    if org11_matrix:
        print(f"Sample of {len(org11_matrix)} matrix entries (showing first 10):")
        for entry in org11_matrix:
            role = RoleCluster.query.get(entry.role_cluster_id)
            role_name = role.role_cluster_name if role else "Unknown"
            print(f"  Role: {role_name}, Competency ID: {entry.competency_id}, Value: {entry.role_competency_value}")

        # Count total
        total_count = RoleCompetencyMatrix.query.filter_by(organization_id=11).count()
        print(f"\nTotal matrix entries for org 11: {total_count}")
    else:
        print("No matrix entries found for organization 11")

    # Suggest fix
    print("\n=== Recommendations ===")
    if not all_roles:
        print("[CRITICAL] No role clusters found in database")
        print("  -> Database not initialized properly")
    elif not org11_matrix:
        print("[ACTION NEEDED] Roles exist but no competency matrix data for org 11")
        print("  -> Option 1: Run populate_org11_matrices.py to populate matrix")
        print("  -> Option 2: Test with organization 1 if it has data")
    else:
        print("[OK] Organization 11 has matrix data - ready for testing")
