"""
Debug why all job profiles map to Service Technician
Check:
1. User competency vectors
2. Role competency vectors
3. Euclidean distances for each role
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db, RoleCluster, RoleCompetencyMatrix, UnknownRoleCompetencyMatrix
from sqlalchemy import text
import numpy as np

app = create_app()

def euclidean_distance(vec1, vec2):
    return np.linalg.norm(vec1 - vec2)

with app.app_context():
    print("=" * 80)
    print("ROLE SUGGESTION ACCURACY DEBUGGING")
    print("=" * 80)

    # Check test_role_suggestion_user (from our test)
    username = "test_role_suggestion_user"
    org_id = 11

    print(f"\n[1] Checking user competency vector: {username}")
    user_comps = UnknownRoleCompetencyMatrix.query.filter_by(
        user_name=username,
        organization_id=org_id
    ).all()

    if not user_comps:
        print(f"  [WARNING] No competency data found for {username}")
        print(f"  This means /findProcesses was not called or stored procedure failed")
    else:
        print(f"  Found {len(user_comps)} competency values")

        # Show non-zero competencies
        non_zero = [(c.competency_id, c.role_competency_value) for c in user_comps if c.role_competency_value > 0]
        print(f"  Non-zero competencies: {len(non_zero)} out of {len(user_comps)}")

        if non_zero:
            print(f"\n  User's Non-Zero Competencies:")
            for comp_id, value in non_zero[:10]:
                comp_name = db.session.execute(text(
                    f"SELECT competency_name FROM competency WHERE id = {comp_id}"
                )).scalar()
                print(f"    Competency {comp_id} ({comp_name}): {value}")

    print(f"\n[2] Checking role competency vectors (organization {org_id})")

    # Get all roles
    roles = RoleCluster.query.all()
    print(f"  Total roles: {len(roles)}")

    # Get all competency IDs
    all_comp_ids = [c.competency_id for c in user_comps] if user_comps else []
    all_comp_ids_sorted = sorted(set(all_comp_ids))

    if not all_comp_ids_sorted:
        print(f"  [ERROR] Cannot calculate distances - no user competency data")
        exit(1)

    # Build user vector
    user_scores_map = {c.competency_id: c.role_competency_value for c in user_comps}
    user_vector = np.array([user_scores_map.get(c_id, 0) for c_id in all_comp_ids_sorted])

    print(f"\n  User Vector Stats:")
    print(f"    Length: {len(user_vector)}")
    print(f"    Non-zero count: {np.count_nonzero(user_vector)}")
    print(f"    Sum: {np.sum(user_vector)}")
    print(f"    Max: {np.max(user_vector)}")
    print(f"    Mean: {np.mean(user_vector):.2f}")

    print(f"\n[3] Calculating distances to all roles:")

    distances = {}

    for role in roles:
        # Get role competency matrix entries
        role_comps = RoleCompetencyMatrix.query.filter_by(
            role_cluster_id=role.id,
            organization_id=org_id
        ).all()

        if not role_comps:
            print(f"  [SKIP] {role.role_cluster_name}: No matrix data")
            continue

        # Build role vector
        role_scores_map = {rc.competency_id: rc.role_competency_value for rc in role_comps}
        role_vector = np.array([role_scores_map.get(c_id, 0) for c_id in all_comp_ids_sorted])

        # Calculate distance
        dist = euclidean_distance(user_vector, role_vector)
        distances[role.role_cluster_name] = dist

        # Show vector stats
        non_zero = np.count_nonzero(role_vector)
        vector_sum = np.sum(role_vector)

        print(f"  {role.role_cluster_name[:35]:<35}: distance={dist:7.4f}  non-zero={non_zero:2d}  sum={vector_sum:4.0f}")

    print(f"\n[4] Top 5 Closest Roles:")
    sorted_distances = sorted(distances.items(), key=lambda x: x[1])
    for i, (role_name, dist) in enumerate(sorted_distances[:5], 1):
        print(f"  {i}. {role_name[:40]:<40}: {dist:.4f}")

    print(f"\n[5] Analysis:")
    if len(sorted_distances) >= 2:
        best = sorted_distances[0]
        second_best = sorted_distances[1]
        separation = (second_best[1] - best[1]) / second_best[1] if second_best[1] > 0 else 0
        print(f"  Best: {best[0]} (distance: {best[1]:.4f})")
        print(f"  Second: {second_best[0]} (distance: {second_best[1]:.4f})")
        print(f"  Separation: {separation:.2%}")

        if separation < 0.05:
            print(f"  [WARNING] Very small separation - roles are too similar!")
            print(f"  This suggests most role vectors look the same (likely all zeros or near-zeros)")

    # Check if user vector is mostly zeros
    zero_ratio = 1 - (np.count_nonzero(user_vector) / len(user_vector))
    print(f"\n  User vector zero ratio: {zero_ratio:.1%}")
    if zero_ratio > 0.90:
        print(f"  [PROBLEM] User vector is {zero_ratio:.1%} zeros!")
        print(f"  This means very few processes were matched or very few competencies calculated")
        print(f"  Root cause: Likely insufficient task input or FAISS retrieval problems")

    print("\n" + "=" * 80)
    print("END OF DEBUGGING")
    print("=" * 80)
