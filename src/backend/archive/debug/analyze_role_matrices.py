"""Analyze role-process matrices to understand role matching"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db, RoleCluster, RoleProcessMatrix, IsoProcesses

app = create_app()
with app.app_context():
    print("=" * 80)
    print("ROLE-PROCESS MATRIX ANALYSIS")
    print("=" * 80)

    # Get Customer Representative
    customer_rep = RoleCluster.query.filter_by(role_cluster_name='Customer Representative').first()
    if customer_rep:
        matrices = RoleProcessMatrix.query.filter_by(
            role_cluster_id=customer_rep.id,
            organization_id=1
        ).all()
        print(f"\nCustomer Representative (ID {customer_rep.id}): {len(matrices)} total process mappings")

        involved = [m for m in matrices if m.role_process_value > 0]
        not_involved = [m for m in matrices if m.role_process_value == 0]
        print(f"  - Actively involved in: {len(involved)} processes")
        print(f"  - Not performing: {len(not_involved)} processes")
        print(f"\n  Processes with involvement:")
        for m in involved[:15]:
            proc = IsoProcesses.query.get(m.iso_process_id)
            value_names = {0: 'Not performing', 1: 'Supporting', 2: 'Responsible', 3: 'Designing'}
            value_str = value_names.get(m.role_process_value, f'Unknown({m.role_process_value})')
            if proc:
                print(f"    - {proc.name}: {value_str}")

    # Get Specialist Developer
    print("\n" + "=" * 80)
    specialist = RoleCluster.query.filter_by(role_cluster_name='Specialist Developer').first()
    if specialist:
        matrices2 = RoleProcessMatrix.query.filter_by(
            role_cluster_id=specialist.id,
            organization_id=1
        ).all()
        print(f"\nSpecialist Developer (ID {specialist.id}): {len(matrices2)} total process mappings")

        involved2 = [m for m in matrices2 if m.role_process_value > 0]
        not_involved2 = [m for m in matrices2 if m.role_process_value == 0]
        print(f"  - Actively involved in: {len(involved2)} processes")
        print(f"  - Not performing: {len(not_involved2)} processes")
        print(f"\n  Processes with involvement:")
        for m in involved2[:15]:
            proc = IsoProcesses.query.get(m.iso_process_id)
            value_names = {0: 'Not performing', 1: 'Supporting', 2: 'Responsible', 3: 'Designing'}
            value_str = value_names.get(m.role_process_value, f'Unknown({m.role_process_value})')
            if proc:
                print(f"    - {proc.name}: {value_str}")

    # Get System Engineer
    print("\n" + "=" * 80)
    sys_eng = RoleCluster.query.filter_by(role_cluster_name='System Engineer').first()
    if sys_eng:
        matrices3 = RoleProcessMatrix.query.filter_by(
            role_cluster_id=sys_eng.id,
            organization_id=1
        ).all()
        print(f"\nSystem Engineer (ID {sys_eng.id}): {len(matrices3)} total process mappings")

        involved3 = [m for m in matrices3 if m.role_process_value > 0]
        not_involved3 = [m for m in matrices3 if m.role_process_value == 0]
        print(f"  - Actively involved in: {len(involved3)} processes")
        print(f"  - Not performing: {len(not_involved3)} processes")
        print(f"\n  Processes with involvement:")
        for m in involved3[:15]:
            proc = IsoProcesses.query.get(m.iso_process_id)
            value_names = {0: 'Not performing', 1: 'Supporting', 2: 'Responsible', 3: 'Designing'}
            value_str = value_names.get(m.role_process_value, f'Unknown({m.role_process_value})')
            if proc:
                print(f"    - {proc.name}: {value_str}")

    # Analyze the scoring issue
    print("\n" + "=" * 80)
    print("SCORING ANALYSIS FOR SOFTWARE DEVELOPER PROFILE")
    print("=" * 80)

    # Sample processes from LLM
    test_processes = {
        'System Architecture Definition': 3,  # Designing
        'Design Definition': 2,               # Responsible
        'Implementation': 2,                  # Responsible
        'Verification': 1,                    # Supporting
        'Validation': 1                       # Supporting
    }

    # Find ISO process IDs
    user_map = {}
    for pname, pvalue in test_processes.items():
        proc = IsoProcesses.query.filter(IsoProcesses.name.ilike(f'%{pname}%')).first()
        if proc:
            user_map[proc.id] = pvalue
            print(f"\nUser doing: {proc.name} = {pvalue}")

    print("\n" + "-" * 80)
    print("SCORING EACH ROLE:")
    print("-" * 80)

    all_roles = RoleCluster.query.all()
    role_scores = []

    for role in all_roles:
        role_matrix = RoleProcessMatrix.query.filter_by(
            role_cluster_id=role.id,
            organization_id=1
        ).all()

        if not role_matrix:
            continue

        score = 0
        max_score = 0
        matches = 0
        mismatches = 0

        for matrix_entry in role_matrix:
            process_id = matrix_entry.iso_process_id
            expected_value = matrix_entry.role_process_value
            user_value = user_map.get(process_id, 0)

            # Score calculation (from routes.py)
            if expected_value > 0 or user_value > 0:
                if expected_value == user_value:
                    score += 10
                    matches += 1
                elif abs(expected_value - user_value) <= 1:
                    score += 5
                    matches += 1
                elif expected_value > 0 and user_value == 0:
                    score -= 5
                    mismatches += 1
                elif user_value > 0 and expected_value == 0:
                    score -= 5
                    mismatches += 1

                max_score += 10

        confidence = score / max_score if max_score > 0 else 0

        role_scores.append({
            'name': role.role_cluster_name,
            'score': score,
            'max_score': max_score,
            'confidence': confidence,
            'matches': matches,
            'mismatches': mismatches
        })

    # Sort by score
    role_scores.sort(key=lambda x: (x['score'], x['confidence']), reverse=True)

    # Show top 5
    print("\nTOP 5 ROLES BY SCORE:")
    for i, rs in enumerate(role_scores[:5]):
        print(f"  {i+1}. {rs['name']}")
        print(f"      Score: {rs['score']}/{rs['max_score']} = {rs['confidence']:.2%} confidence")
        print(f"      Matches: {rs['matches']}, Mismatches: {rs['mismatches']}")

    print("\n" + "=" * 80)
