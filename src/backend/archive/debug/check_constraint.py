import psycopg2
import os

DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    # Check for all constraints on unknown_role_process_matrix table
    cur.execute("""
        SELECT conname, pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conrelid = 'unknown_role_process_matrix'::regclass
        AND conname LIKE '%role_process_value%'
    """)

    results = cur.fetchall()
    if results:
        print("Found constraints:")
        for name, definition in results:
            print(f"  Constraint name: {name}")
            print(f"  Definition: {definition}")
            print()
    else:
        print("No constraints found matching 'role_process_value'")

    cur.close()
    conn.close()

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
