import psycopg2
import os

DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    # Step 1: Drop old constraint FIRST
    print("Step 1: Dropping old constraint...")
    cur.execute("""
        ALTER TABLE unknown_role_process_matrix
        DROP CONSTRAINT IF EXISTS unknown_role_process_matrix_role_process_value_check
    """)
    print("  Constraint dropped")

    # Step 2: Update all value 3s to value 4s
    print("\nStep 2: Updating all value 3 rows to value 4...")
    cur.execute("""
        UPDATE unknown_role_process_matrix
        SET role_process_value = 4
        WHERE role_process_value = 3
    """)
    rows_updated = cur.rowcount
    print(f"  Updated {rows_updated} rows from value 3 to value 4")

    # Step 3: Create new constraint with values: -100, 0, 1, 2, 4
    print("\nStep 3: Creating new constraint with values: -100, 0, 1, 2, 4...")
    cur.execute("""
        ALTER TABLE unknown_role_process_matrix
        ADD CONSTRAINT unknown_role_process_matrix_role_process_value_check
        CHECK (role_process_value = ANY (ARRAY[-100, 0, 1, 2, 4]))
    """)
    print("  New constraint created")

    # Commit the transaction
    conn.commit()
    print("\n[SUCCESS] Database migration completed successfully!")

    # Verify the new constraint
    print("\nVerifying new constraint definition:")
    cur.execute("""
        SELECT pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conname = 'unknown_role_process_matrix_role_process_value_check'
    """)
    result = cur.fetchone()
    if result:
        print(f"  Definition: {result[0]}")

    # Verify the new values
    print("\nVerifying updated values:")
    cur.execute("""
        SELECT DISTINCT role_process_value, COUNT(*)
        FROM unknown_role_process_matrix
        GROUP BY role_process_value
        ORDER BY role_process_value
    """)
    results = cur.fetchall()
    for value, count in results:
        print(f"  Value {value}: {count} rows")

    cur.close()
    conn.close()

except Exception as e:
    print(f"\n[ERROR] {e}")
    import traceback
    traceback.print_exc()
    if conn:
        conn.rollback()
        print("\nTransaction rolled back")
