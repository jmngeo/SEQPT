import psycopg2
import os

DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    print("Dropping old constraint...")
    cur.execute("""
        ALTER TABLE unknown_role_process_matrix
        DROP CONSTRAINT IF EXISTS unknown_role_process_matrix_role_process_value_check
    """)

    print("Creating new constraint with values: -100, 0, 1, 2, 4...")
    cur.execute("""
        ALTER TABLE unknown_role_process_matrix
        ADD CONSTRAINT unknown_role_process_matrix_role_process_value_check
        CHECK (role_process_value = ANY (ARRAY[-100, 0, 1, 2, 4]))
    """)

    conn.commit()
    print("\n[SUCCESS] Constraint updated successfully!")

    # Verify the new constraint
    print("\nVerifying new constraint definition:")
    cur.execute("""
        SELECT pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conname = 'unknown_role_process_matrix_role_process_value_check'
    """)
    result = cur.fetchone()
    if result:
        print(f"  New definition: {result[0]}")

    cur.close()
    conn.close()

except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
    if conn:
        conn.rollback()
