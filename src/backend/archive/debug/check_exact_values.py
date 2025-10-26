"""
Check exact values in unknown_role_process_matrix
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
    print(f"CHECKING EXACT VALUES FOR: {username}")
    print("=" * 80)

    # Query ALL processes with their involvement values
    result = db.session.execute(text("""
        SELECT
            urpm.iso_process_id,
            ip.name as process_name,
            urpm.role_process_value
        FROM unknown_role_process_matrix urpm
        JOIN iso_processes ip ON urpm.iso_process_id = ip.id
        WHERE urpm.user_name = :username
          AND urpm.organization_id = :org_id
        ORDER BY urpm.role_process_value DESC, ip.name ASC
    """), {"username": username, "org_id": org_id}).fetchall()

    if not result:
        print(f"\n[ERROR] No data found for {username}")
    else:
        print(f"\nTotal processes: {len(result)}")

        # Show processes with non-zero values first
        print(f"\n{'PROCESSES WITH NON-ZERO VALUES:':-^80}")
        has_nonzero = False
        for iso_id, name, value in result:
            if value > 0:
                has_nonzero = True
                value_map = {0: "Not performing", 1: "Supporting", 2: "Responsible", 4: "Designing", 3: "INVALID(3)"}
                print(f"  {name[:60]:<60} value={value} ({value_map.get(value, 'UNKNOWN')})")

        if not has_nonzero:
            print("  NONE - All values are 0")

        # Show value distribution
        value_0 = sum(1 for _, _, v in result if v == 0)
        value_1 = sum(1 for _, _, v in result if v == 1)
        value_2 = sum(1 for _, _, v in result if v == 2)
        value_3 = sum(1 for _, _, v in result if v == 3)  # Invalid
        value_4 = sum(1 for _, _, v in result if v == 4)

        print(f"\n{'VALUE DISTRIBUTION:':-^80}")
        print(f"  Value 0 (Not performing): {value_0}")
        print(f"  Value 1 (Supporting):     {value_1}")
        print(f"  Value 2 (Responsible):    {value_2}")
        print(f"  Value 3 (INVALID):        {value_3}")
        print(f"  Value 4 (Designing):      {value_4}")

    print("\n" + "=" * 80)
    print("END")
    print("=" * 80)
