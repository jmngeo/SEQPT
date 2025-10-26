"""
Analyze role-competency matrix to identify competencies with required level = 0
"""
import sys
from app import create_app
from models import db, RoleCluster, Competency, RoleCompetencyMatrix, Organization

app = create_app()

with app.app_context():
    print("[INFO] Analyzing Role-Competency Matrix for Zero-Level Competencies")
    print("=" * 80)

    # Get all role clusters
    roles = RoleCluster.query.order_by(RoleCluster.id).all()
    print(f"\n[INFO] Total Role Clusters: {len(roles)}")

    # Get all competencies
    competencies = Competency.query.order_by(Competency.id).all()
    print(f"[INFO] Total Competencies: {len(competencies)}")

    # Get organizations
    organizations = Organization.query.all()
    print(f"[INFO] Total Organizations: {len(organizations)}")

    # Analyze matrix for each role and organization
    zero_level_data = {}

    for org in organizations:
        print(f"\n{'='*80}")
        print(f"Organization: {org.organization_name} (ID: {org.id})")
        print(f"{'='*80}")

        for role in roles:
            # Get matrix entries for this role in this organization
            matrix_entries = RoleCompetencyMatrix.query.filter_by(
                role_cluster_id=role.id,
                organization_id=org.id
            ).order_by(RoleCompetencyMatrix.competency_id).all()

            if not matrix_entries:
                continue

            zero_count = 0
            non_zero_count = 0
            zero_competencies = []

            for entry in matrix_entries:
                competency = Competency.query.get(entry.competency_id)
                if competency:
                    if entry.role_competency_value == 0:
                        zero_count += 1
                        zero_competencies.append({
                            'id': competency.id,
                            'name': competency.competency_name,
                            'area': competency.competency_area
                        })
                    else:
                        non_zero_count += 1

            if zero_count > 0:
                print(f"\n  Role: {role.role_cluster_name} (ID: {role.id})")
                print(f"    Competencies with Value = 0: {zero_count}")
                print(f"    Competencies with Value > 0: {non_zero_count}")

                if zero_competencies:
                    print(f"\n    Zero-Level Competencies:")
                    for comp in zero_competencies:
                        print(f"      - ID {comp['id']}: {comp['name']} ({comp['area']})")

                    key = f"{org.id}_{role.id}"
                    zero_level_data[key] = {
                        'org_name': org.organization_name,
                        'org_id': org.id,
                        'role_name': role.role_cluster_name,
                        'role_id': role.id,
                        'zero_count': zero_count,
                        'competencies': zero_competencies
                    }

    # Summary
    print(f"\n{'='*80}")
    print("SUMMARY: Role-Organization Pairs with Zero-Level Competencies")
    print(f"{'='*80}")

    if zero_level_data:
        for key, data in zero_level_data.items():
            print(f"\nOrg {data['org_id']} ({data['org_name']}) - Role {data['role_id']} ({data['role_name']})")
            print(f"  Total Zero-Level Competencies: {data['zero_count']}")
            print(f"  Competency IDs: {[c['id'] for c in data['competencies']]}")
    else:
        print("\n[SUCCESS] No roles have competencies with value = 0!")

    print("\n" + "="*80)
    print("[INFO] Analysis Complete")
    print("="*80)
