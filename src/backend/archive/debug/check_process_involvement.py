"""
Check if process involvement was recorded and if stored procedure was called
"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    username = "test_role_suggestion_user"
    org_id = 11

    print("=" * 80)
    print("CHECKING PROCESS INVOLVEMENT AND COMPETENCY CALCULATION")
    print("=" * 80)

    # Check unknown_role_process_matrix (process involvement)
    print(f"\n[1] Checking process involvement for {username}")
    result = db.session.execute(text(f"""
        SELECT urpm.iso_process_id, ip.name as process_name, urpm.role_process_value
        FROM unknown_role_process_matrix urpm
        JOIN iso_processes ip ON urpm.iso_process_id = ip.id
        WHERE urpm.user_name = '{username}'
          AND urpm.organization_id = {org_id}
        ORDER BY urpm.role_process_value DESC
    """)).fetchall()

    if not result:
        print(f"  [ERROR] NO process involvement data found!")
        print(f"  This means /findProcesses did not store results properly")
    else:
        print(f"  Found {len(result)} process involvement entries")
        print(f"\n  Process Involvement:")
        for iso_id, proc_name, value in result:
            if value > 0:
                involvement_map = {0: "Not performing", 1: "Supporting", 2: "Responsible", 4: "Designing"}
                print(f"    {proc_name[:50]:<50}: {involvement_map.get(value, value)}")

        # Count by involvement level
        supporting = sum(1 for _, _, v in result if v == 1)
        responsible = sum(1 for _, _, v in result if v == 2)
        designing = sum(1 for _, _, v in result if v == 4)
        not_performing = sum(1 for _, _, v in result if v == 0)

        print(f"\n  Summary:")
        print(f"    Not performing: {not_performing}")
        print(f"    Supporting: {supporting}")
        print(f"    Responsible: {responsible}")
        print(f"    Designing: {designing}")

    # Check process_competency_matrix
    print(f"\n[2] Checking process_competency_matrix")
    result = db.session.execute(text("""
        SELECT COUNT(*) FROM process_competency_matrix
    """)).scalar()
    print(f"  Total entries in process_competency_matrix: {result}")

    if result == 0:
        print(f"  [CRITICAL] process_competency_matrix is EMPTY!")
        print(f"  This table is required to calculate competencies from processes")
        print(f"  Without it, all competencies will be 0")

    # Show sample of process_competency_matrix
    print(f"\n[3] Sample process_competency_matrix entries:")
    result = db.session.execute(text("""
        SELECT ip.name as process_name, c.competency_name, pcm.process_competency_value
        FROM process_competency_matrix pcm
        JOIN iso_processes ip ON pcm.iso_process_id = ip.id
        JOIN competency c ON pcm.competency_id = c.id
        WHERE pcm.process_competency_value > 0
        LIMIT 10
    """)).fetchall()

    if result:
        for proc, comp, val in result:
            print(f"    {proc[:30]:<30} -> {comp[:30]:<30}: {val}")
    else:
        print(f"    [ERROR] No non-zero entries found!")

    # Check unknown_role_competency_matrix (calculated competencies)
    print(f"\n[4] Checking calculated competencies (unknown_role_competency_matrix)")
    result = db.session.execute(text(f"""
        SELECT urcm.competency_id, c.competency_name, urcm.role_competency_value
        FROM unknown_role_competency_matrix urcm
        JOIN competency c ON urcm.competency_id = c.id
        WHERE urcm.user_name = '{username}'
          AND urcm.organization_id = {org_id}
        ORDER BY urcm.role_competency_value DESC
    """)).fetchall()

    if not result:
        print(f"  [ERROR] NO competency data found!")
        print(f"  Stored procedure update_unknown_role_competency_values was not called")
    else:
        print(f"  Found {len(result)} competency values")
        non_zero = [(comp_id, name, val) for comp_id, name, val in result if val > 0]

        if non_zero:
            print(f"\n  Non-zero competencies: {len(non_zero)}")
            for comp_id, name, val in non_zero[:10]:
                print(f"    {name[:40]:<40}: {val}")
        else:
            print(f"\n  [PROBLEM] All {len(result)} competencies are ZERO!")
            print(f"  This is why role matching fails")

    # Diagnose the calculation
    print(f"\n[5] Diagnosis:")
    print(f"  Formula: role_competency_value = role_process_value * process_competency_value")
    print(f"  If either is 0, result is 0")
    print(f"  If process_competency_matrix is empty, all results are 0")

    print("\n" + "=" * 80)
    print("END OF CHECK")
    print("=" * 80)
