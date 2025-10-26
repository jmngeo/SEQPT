"""
Analyze role competency vectors to understand why they are similar
"""
from app import create_app, db
from sqlalchemy import text
import sys

def analyze_vectors():
    app = create_app()
    with app.app_context():
        print("="*80)
        print("ROLE COMPETENCY VECTOR ANALYSIS")
        print("="*80)

        # Get total count
        result = db.session.execute(text(
            "SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 1"
        ))
        total = result.scalar()
        print(f"\nTotal entries in role_competency_matrix: {total}")

        # Get distinct roles
        result = db.session.execute(text(
            "SELECT DISTINCT role_cluster_id FROM role_competency_matrix WHERE organization_id = 1 ORDER BY role_cluster_id"
        ))
        role_ids = [r[0] for r in result.fetchall()]
        print(f"\nDistinct role IDs: {role_ids}")
        print(f"Number of distinct roles: {len(role_ids)}")

        # Get distinct competencies
        result = db.session.execute(text(
            "SELECT DISTINCT competency_id FROM role_competency_matrix WHERE organization_id = 1 ORDER BY competency_id"
        ))
        comp_ids = [r[0] for r in result.fetchall()]
        print(f"\nDistinct competency IDs: {comp_ids}")
        print(f"Number of distinct competencies: {len(comp_ids)}")

        # Value distribution
        result = db.session.execute(text(
            """SELECT role_competency_value, COUNT(*) as count
               FROM role_competency_matrix
               WHERE organization_id = 1
               GROUP BY role_competency_value
               ORDER BY role_competency_value"""
        ))
        print(f"\n{'Value':<10} {'Count':<10} {'Percentage':<10}")
        print("-"*30)
        for value, count in result.fetchall():
            percentage = (count / total) * 100
            print(f"{value:<10} {count:<10} {percentage:>6.2f}%")

        # Get role names
        result = db.session.execute(text(
            """SELECT rc.id, rc.role_cluster_name
               FROM role_cluster rc
               ORDER BY rc.id"""
        ))
        print("\n" + "="*80)
        print("ROLE NAMES")
        print("="*80)
        role_names = {}
        for role_id, role_name in result.fetchall():
            role_names[role_id] = role_name
            print(f"Role {role_id:2d}: {role_name}")

        # Analyze each role's competency vector
        print("\n" + "="*80)
        print("COMPETENCY VECTORS BY ROLE")
        print("="*80)

        for role_id in role_ids:
            result = db.session.execute(text(
                """SELECT competency_id, role_competency_value
                   FROM role_competency_matrix
                   WHERE organization_id = 1 AND role_cluster_id = :role_id
                   ORDER BY competency_id"""
            ), {"role_id": role_id})

            vector = list(result.fetchall())
            role_name = role_names.get(role_id, "Unknown")

            print(f"\nRole {role_id} - {role_name}")
            print(f"  Entries: {len(vector)}")

            # Value distribution for this role
            value_counts = {}
            for comp_id, value in vector:
                value_counts[value] = value_counts.get(value, 0) + 1

            print(f"  Value distribution: {dict(sorted(value_counts.items()))}")

            # Show actual vector (first 18 competencies)
            vec_str = ", ".join([str(v) for c, v in vector])
            print(f"  Vector: [{vec_str}]")

        # Calculate similarity between roles
        print("\n" + "="*80)
        print("ROLE SIMILARITY ANALYSIS")
        print("="*80)

        # Get all vectors as lists
        vectors = {}
        for role_id in role_ids:
            result = db.session.execute(text(
                """SELECT competency_id, role_competency_value
                   FROM role_competency_matrix
                   WHERE organization_id = 1 AND role_cluster_id = :role_id
                   ORDER BY competency_id"""
            ), {"role_id": role_id})
            vectors[role_id] = [v for c, v in result.fetchall()]

        # Compare each pair of roles
        print("\nComparing role pairs (number of matching competency values):")
        print(f"{'Role 1':<25} {'Role 2':<25} {'Matches':<10} {'Total':<10} {'Similarity %':<15}")
        print("-"*90)

        for i, role1_id in enumerate(role_ids):
            for role2_id in role_ids[i+1:]:
                vec1 = vectors[role1_id]
                vec2 = vectors[role2_id]

                # Count matching values
                matches = sum(1 for v1, v2 in zip(vec1, vec2) if v1 == v2)
                total = len(vec1)
                similarity = (matches / total) * 100 if total > 0 else 0

                role1_name = role_names.get(role1_id, "Unknown")
                role2_name = role_names.get(role2_id, "Unknown")

                # Only show if similarity is high
                if similarity > 50:
                    print(f"{role1_name[:24]:<25} {role2_name[:24]:<25} {matches:<10} {total:<10} {similarity:>6.2f}%")

if __name__ == "__main__":
    analyze_vectors()
