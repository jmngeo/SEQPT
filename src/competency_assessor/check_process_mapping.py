"""
Check process mapping for task-based assessment user.
"""
from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    username = 'seqpt_user_1760278265677'
    organization_id = 1

    print("=" * 80)
    print(f"PROCESS IDENTIFICATION FOR USER: {username}")
    print("=" * 80)

    # Check what processes were identified
    result = db.session.execute(
        text("""
        SELECT ip.name, urpm.role_process_value
        FROM unknown_role_process_matrix urpm
        JOIN iso_processes ip ON urpm.iso_process_id = ip.id
        WHERE urpm.user_name = :username
          AND urpm.organization_id = :org_id
        ORDER BY urpm.role_process_value DESC, ip.name
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    print(f"\nTotal processes: {len(result)}")

    designing_processes = []
    responsible_processes = []
    supporting_processes = []
    not_performing = []

    for process_name, involvement_level in result:
        if involvement_level == 3:
            designing_processes.append(process_name)
        elif involvement_level == 2:
            responsible_processes.append(process_name)
        elif involvement_level == 1:
            supporting_processes.append(process_name)
        else:
            not_performing.append(process_name)

    print(f"\nDESIGNING (level 3): {len(designing_processes)} processes")
    for p in designing_processes:
        print(f"  - {p}")

    print(f"\nRESPONSIBLE (level 2): {len(responsible_processes)} processes")
    for p in responsible_processes:
        print(f"  - {p}")

    print(f"\nSUPPORTING (level 1): {len(supporting_processes)} processes")
    for p in supporting_processes:
        print(f"  - {p}")

    print(f"\nNOT PERFORMING (level 0): {len(not_performing)} processes")
    if len(not_performing) <= 10:
        for p in not_performing:
            print(f"  - {p}")
    else:
        for p in not_performing[:5]:
            print(f"  - {p}")
        print(f"  ... and {len(not_performing) - 5} more")

    # Check what the user's tasks were
    print("\n" + "=" * 80)
    print("USER'S ORIGINAL TASKS")
    print("=" * 80)

    user_data = db.session.execute(
        text("""
        SELECT tasks_responsibilities
        FROM app_user
        WHERE username = :username
        """),
        {"username": username}
    ).fetchone()

    if user_data and user_data[0]:
        import json
        tasks = json.loads(user_data[0]) if isinstance(user_data[0], str) else user_data[0]
        print("\nTasks submitted:")
        print(json.dumps(tasks, indent=2))
    else:
        print("\nNo task data found in app_user table")

    # Check process-competency matrix for Lifecycle Consideration (ID 18)
    print("\n" + "=" * 80)
    print("PROCESS-COMPETENCY MATRIX FOR LIFECYCLE CONSIDERATION (ID 18)")
    print("=" * 80)

    pcm_result = db.session.execute(
        text("""
        SELECT ip.name, pcm.process_competency_value
        FROM process_competency_matrix pcm
        JOIN iso_processes ip ON pcm.iso_process_id = ip.id
        WHERE pcm.competency_id = 18
          AND pcm.process_competency_value > 0
        ORDER BY pcm.process_competency_value DESC
        """)
    ).fetchall()

    print(f"\nProcesses that require Lifecycle Consideration:")
    for process_name, competency_level in pcm_result[:10]:
        print(f"  {process_name}: Level {competency_level}")

    # Now check if user is performing any of these processes
    print("\n" + "=" * 80)
    print("CHECKING IF USER PERFORMS PROCESSES REQUIRING LIFECYCLE CONSIDERATION")
    print("=" * 80)

    check_result = db.session.execute(
        text("""
        SELECT ip.name, pcm.process_competency_value, urpm.role_process_value
        FROM process_competency_matrix pcm
        JOIN iso_processes ip ON pcm.iso_process_id = ip.id
        JOIN unknown_role_process_matrix urpm
          ON pcm.iso_process_id = urpm.iso_process_id
          AND urpm.user_name = :username
          AND urpm.organization_id = :org_id
        WHERE pcm.competency_id = 18
          AND pcm.process_competency_value > 0
          AND urpm.role_process_value > 0
        ORDER BY pcm.process_competency_value DESC
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    if check_result:
        print(f"\nUser IS performing {len(check_result)} processes that require Lifecycle Consideration:")
        for process_name, required_level, user_involvement in check_result:
            print(f"  {process_name}")
            print(f"    Required competency level: {required_level}")
            print(f"    User involvement: {user_involvement}")
    else:
        print("\nUser is NOT performing any processes that require Lifecycle Consideration")
        print("This is why Required Level = 0 (not required for this role)")
