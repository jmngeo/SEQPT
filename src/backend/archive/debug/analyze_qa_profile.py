"""
Analyze why QA Specialist profile isn't matching Quality Engineer/Manager role
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text
import numpy as np

app = create_app()

with app.app_context():
    print("=" * 80)
    print("ANALYZING QA PROFILE MATCHING ISSUE")
    print("=" * 80)

    # Find the QA profile
    result = db.session.execute(text("""
        SELECT DISTINCT user_name
        FROM unknown_role_competency_matrix
        WHERE organization_id=16
        ORDER BY user_name DESC
        LIMIT 5
    """))
    profiles = [r[0] for r in result]

    print("\nRecent profiles:")
    for p in profiles:
        print(f"  {p}")

    # Assuming the QA profile is one of the recent ones
    # Let's check all of them
    for profile_name in profiles:
        print(f"\n{'='*80}")
        print(f"Profile: {profile_name}")
        print('='*80)

        # Get the competency vector
        result = db.session.execute(text("""
            SELECT competency_id, role_competency_value
            FROM unknown_role_competency_matrix
            WHERE user_name = :username AND organization_id=16
            ORDER BY competency_id
        """), {'username': profile_name})

        rows = result.fetchall()
        if not rows:
            print("No data found")
            continue

        user_vector = np.array([r[1] for r in rows])
        print(f"User competency vector: {user_vector}")

        # Get all role vectors and calculate distances
        result = db.session.execute(text("""
            SELECT role_cluster_id, competency_id, role_competency_value
            FROM role_competency_matrix
            WHERE organization_id=16
            ORDER BY role_cluster_id, competency_id
        """))

        roles = {}
        for row in result:
            role_id = row[0]
            if role_id not in roles:
                roles[role_id] = []
            roles[role_id].append(row[2])

        # Calculate distances
        print("\nDistances to all roles:")
        distances = {}
        for role_id, role_vector in roles.items():
            role_vec = np.array(role_vector)
            euclidean = np.linalg.norm(user_vector - role_vec)
            manhattan = np.sum(np.abs(user_vector - role_vec))

            # Cosine distance
            dot_product = np.dot(user_vector, role_vec)
            magnitude_user = np.linalg.norm(user_vector)
            magnitude_role = np.linalg.norm(role_vec)
            cosine = 1 - (dot_product / (magnitude_user * magnitude_role)) if magnitude_user and magnitude_role else 1.0

            distances[role_id] = {
                'euclidean': euclidean,
                'manhattan': manhattan,
                'cosine': cosine,
                'vector': role_vec
            }

        # Get role names
        role_names = {
            1: "Customer",
            2: "Customer Representative",
            3: "Project Manager",
            4: "System Engineer",
            5: "Specialist Developer",
            6: "Production Planner/Coordinator",
            7: "Production Employee",
            8: "Quality Engineer/Manager",
            9: "Verification and Validation (V&V) Operator",
            10: "Service Technician",
            11: "Process and Policy Manager",
            12: "Internal Support",
            13: "Innovation Management",
            14: "Management"
        }

        # Sort by euclidean distance
        sorted_roles = sorted(distances.items(), key=lambda x: x[1]['euclidean'])

        for rank, (role_id, dist) in enumerate(sorted_roles[:5], 1):
            role_name = role_names.get(role_id, f"Unknown Role {role_id}")
            print(f"  {rank}. {role_name:40s} Eucl: {dist['euclidean']:6.2f}  Manh: {dist['manhattan']:4.0f}  Cosine: {dist['cosine']:.4f}")

        # Focus on Role 8 (Quality Engineer/Manager)
        if 8 in distances:
            print(f"\n{'='*80}")
            print("DETAILED ANALYSIS: Quality Engineer/Manager (Role 8)")
            print('='*80)
            role8_vector = distances[8]['vector']
            print(f"User vector:  {user_vector}")
            print(f"Role 8 vector: {role8_vector}")
            print(f"Difference:   {user_vector - role8_vector}")
            print(f"\nEuclidean distance: {distances[8]['euclidean']:.2f}")
            print(f"Rank: {[i for i, (rid, _) in enumerate(sorted_roles, 1) if rid == 8][0]}")

            # Show which competencies differ
            print("\nCompetency differences:")
            for i, (user_val, role_val) in enumerate(zip(user_vector, role8_vector), 1):
                if user_val != role_val:
                    print(f"  C{i:2d}: User={user_val}, Role 8={role_val}, Diff={user_val-role_val:+.0f}")
