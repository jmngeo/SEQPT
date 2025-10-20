"""
Debug script to check data for task-based assessment user.
"""
from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    username = 'seqpt_user_1760278265677'
    organization_id = 1

    print("=" * 80)
    print(f"STORED PROCEDURE OUTPUT FOR USER: {username}")
    print("=" * 80)

    # Call stored procedure
    result = db.session.execute(
        text("""
        SELECT competency_area, competency_name, user_recorded_level,
               user_recorded_level_competency_indicator,
               user_required_level, user_required_level_competency_indicator
        FROM public.get_unknown_role_competency_results(:username, :org_id)
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    print(f"\nTotal competencies: {len(result)}")
    print("\nFirst 10 competencies:")
    for idx, r in enumerate(result[:10], 1):
        competency_area, competency_name, user_level, user_indicator, required_level, required_indicator = r
        print(f"\n{idx}. {competency_name}")
        print(f"   Area: {competency_area}")
        print(f"   User Level: {user_level}")
        print(f"   Required Level: {required_level}")
        print(f"   User Indicator: {user_indicator[:80] if user_indicator else 'None'}...")
        print(f"   Required Indicator: {required_indicator[:80] if required_indicator else 'None'}...")

    print("\n" + "=" * 80)
    print("UNKNOWN_ROLE_COMPETENCY_MATRIX TABLE")
    print("=" * 80)

    # Check raw table data
    matrix_result = db.session.execute(
        text("""
        SELECT competency_id, role_competency_value
        FROM unknown_role_competency_matrix
        WHERE user_name = :username AND organization_id = :org_id
        ORDER BY competency_id
        """),
        {"username": username, "org_id": organization_id}
    ).fetchall()

    print(f"\nTotal entries: {len(matrix_result)}")
    print("\nFirst 10 entries:")
    for comp_id, required_val in matrix_result[:10]:
        print(f"  Competency ID {comp_id}: Required Level = {required_val}")

    # Check for specific competency: Lifecycle Consideration (ID 18)
    print("\n" + "=" * 80)
    print("SPECIFIC CHECK: Lifecycle Consideration (ID 18)")
    print("=" * 80)

    lifecycle_result = db.session.execute(
        text("""
        SELECT c.competency_name, urcm.role_competency_value, ucsr.score
        FROM competency c
        LEFT JOIN unknown_role_competency_matrix urcm
            ON c.id = urcm.competency_id
            AND urcm.user_name = :username
            AND urcm.organization_id = :org_id
        LEFT JOIN app_user au ON au.username = :username
        LEFT JOIN user_competency_survey_results ucsr
            ON c.id = ucsr.competency_id
            AND ucsr.user_id = au.id
        WHERE c.id = 18
        """),
        {"username": username, "org_id": organization_id}
    ).fetchone()

    if lifecycle_result:
        comp_name, required_val, user_score = lifecycle_result
        print(f"Competency: {comp_name}")
        print(f"User Score (from survey): {user_score}")
        print(f"Required Value (from matrix): {required_val}")
    else:
        print("No data found for Lifecycle Consideration")
