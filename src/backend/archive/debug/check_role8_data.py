"""
Check if Quality Engineer/Manager (Role 8) data is correct
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db, IsoProcesses
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("QUALITY ENGINEER/MANAGER (ROLE 8) DATA ANALYSIS")
    print("=" * 80)

    # Get process involvement for Role 8
    result = db.session.execute(text("""
        SELECT iso_process_id, role_process_value
        FROM role_process_matrix
        WHERE organization_id=1 AND role_cluster_id=8 AND role_process_value > 0
        ORDER BY iso_process_id
    """))

    val_names = {0: 'Not performing', 1: 'Supporting', 2: 'Responsible', 3: 'Designing (P&P)', 4: 'Designing'}

    print("\nRole 8 Process Assignments:")
    print("-" * 80)
    for process_id, value in result:
        process = IsoProcesses.query.get(process_id)
        process_name = process.name if process else f"Unknown P{process_id}"
        print(f"  P{process_id:2d} {process_name:45s} {val_names[value]}")

    # Get competency requirements for Role 8
    result = db.session.execute(text("""
        SELECT competency_id, role_competency_value
        FROM role_competency_matrix
        WHERE organization_id=1 AND role_cluster_id=8
        ORDER BY competency_id
    """))

    competencies = list(result)
    print("\nRole 8 Competency Requirements:")
    print("-" * 80)
    comp_names = {
        1: "Systems Thinking",
        4: "Personal Communication",
        5: "Teamwork",
        6: "Holistic Thinking",
        7: "Analytical Thinking",
        8: "Initiative",
        9: "Creativity",
        10: "Self-organization",
        11: "Negotiation Skills",
        12: "Problem-solving Skills",
        13: "Decision-making Ability",
        14: "Conflict Management",
        15: "Lifelong Learning",
        16: "Intercultural Competence",
        17: "Leadership",
        18: "Specialized Skills"
    }

    for comp_id, value in competencies:
        comp_name = comp_names.get(comp_id, f"Unknown C{comp_id}")
        print(f"  C{comp_id:2d} {comp_name:30s} Level: {value}")

    # Show summary
    values = [v for _, v in competencies]
    print("\nSummary:")
    print(f"  Average competency level: {sum(values) / len(values):.1f}")
    print(f"  Min: {min(values)}, Max: {max(values)}")
    print(f"  Distribution: {dict((v, values.count(v)) for v in set(values))}")

    # Compare with other roles
    print("\n" + "=" * 80)
    print("COMPARISON WITH OTHER ROLES")
    print("=" * 80)

    role_names = {
        4: "System Engineer",
        5: "Specialist Developer",
        8: "Quality Engineer/Manager",
        9: "V&V Operator"
    }

    for role_id, role_name in role_names.items():
        result = db.session.execute(text("""
            SELECT AVG(role_competency_value), MIN(role_competency_value), MAX(role_competency_value)
            FROM role_competency_matrix
            WHERE organization_id=1 AND role_cluster_id=:rid
        """), {'rid': role_id})
        avg, min_val, max_val = result.fetchone()
        print(f"  Role {role_id} ({role_name:30s}): Avg={avg:.1f}, Min={min_val}, Max={max_val}")
