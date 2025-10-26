"""
Analyze why different roles have similar competency profiles.
This will help identify if it's a data issue or an algorithmic issue.
"""

import psycopg2
from collections import defaultdict
import math

DATABASE_URL = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

def get_role_competency_vector(role_id, organization_id=11):
    """Get competency vector for a specific role."""
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    query = """
        SELECT c.competency_name, rcm.role_competency_value
        FROM role_competency_matrix rcm
        JOIN competency c ON rcm.competency_id = c.id
        WHERE rcm.role_cluster_id = %s AND rcm.organization_id = %s
        ORDER BY c.id
    """

    cur.execute(query, (role_id, organization_id))
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {name: value for name, value in rows}


def euclidean_distance(vec1, vec2):
    """Calculate Euclidean distance between two vectors."""
    all_keys = set(vec1.keys()) | set(vec2.keys())
    sum_sq = sum((vec1.get(k, 0) - vec2.get(k, 0)) ** 2 for k in all_keys)
    return math.sqrt(sum_sq)


def analyze_role_differences():
    """Analyze how different roles are from each other."""
    print("=" * 80)
    print("ROLE COMPETENCY DIFFERENTIATION ANALYSIS")
    print("=" * 80)

    # Get vectors for key roles
    roles = {
        2: "Customer Representative",
        3: "Project Manager",
        4: "System Engineer",
        5: "Specialist Developer",
        6: "Production Planner/Coordinator",
        8: "Quality Engineer/Manager",
        9: "Verification and Validation (V&V) Operator",
        12: "Internal Support"
    }

    vectors = {}
    for role_id, role_name in roles.items():
        vectors[role_id] = get_role_competency_vector(role_id)
        print(f"\n{role_name} (ID {role_id}):")
        print(f"  Total competencies: {len(vectors[role_id])}")
        print(f"  Non-zero values: {sum(1 for v in vectors[role_id].values() if v > 0)}")

        # Show value distribution
        value_counts = defaultdict(int)
        for v in vectors[role_id].values():
            value_counts[v] += 1

        print(f"  Value distribution:")
        for val in sorted(value_counts.keys()):
            print(f"    Value {val}: {value_counts[val]} competencies")

        # Show top 10 competencies
        top_comps = sorted(vectors[role_id].items(), key=lambda x: x[1], reverse=True)[:10]
        print(f"  Top 10 competencies:")
        for comp, val in top_comps:
            print(f"    {comp}: {val}")

    # Calculate pairwise distances
    print("\n" + "=" * 80)
    print("PAIRWISE EUCLIDEAN DISTANCES")
    print("=" * 80)

    role_ids = list(roles.keys())
    for i, role_id1 in enumerate(role_ids):
        for role_id2 in role_ids[i+1:]:
            dist = euclidean_distance(vectors[role_id1], vectors[role_id2])
            print(f"{roles[role_id1][:30]:<30} <--> {roles[role_id2][:30]:<30}: {dist:.4f}")

    # Analyze specific problem pair: Specialist Developer vs Project Manager
    print("\n" + "=" * 80)
    print("DETAILED COMPARISON: Specialist Developer vs Project Manager")
    print("=" * 80)

    dev_vec = vectors[5]
    pm_vec = vectors[3]

    print("\nCompetencies where they differ:")
    differences = []
    for comp in set(dev_vec.keys()) | set(pm_vec.keys()):
        dev_val = dev_vec.get(comp, 0)
        pm_val = pm_vec.get(comp, 0)
        if dev_val != pm_val:
            differences.append((comp, dev_val, pm_val, abs(dev_val - pm_val)))

    differences.sort(key=lambda x: x[3], reverse=True)

    print(f"Total differing competencies: {len(differences)}")
    print("\nTop 20 differences:")
    for comp, dev_val, pm_val, diff in differences[:20]:
        print(f"  {comp[:40]:<40}: Dev={dev_val}, PM={pm_val}, Diff={diff}")

    # Calculate what percentage of competencies are identical
    identical = sum(1 for comp in dev_vec if dev_vec.get(comp, 0) == pm_vec.get(comp, 0))
    total = len(set(dev_vec.keys()) | set(pm_vec.keys()))
    print(f"\nIdentical competencies: {identical}/{total} ({100*identical/total:.1f}%)")

    print("\n" + "=" * 80)
    print("CONCLUSION")
    print("=" * 80)

    print("""
If all roles have very similar competency profiles (high percentage identical),
then the Euclidean distance calculation will not differentiate well between roles.

This could be due to:
1. Process-competency matrix being too uniform (all processes require similar competencies)
2. Role-process matrix being too uniform (all roles perform similar processes)
3. The multiplication formula amplifying similarities

Recommendation: Check if the source data (Excel file) actually shows different
competency requirements for different roles.
    """)


if __name__ == '__main__':
    analyze_role_differences()
