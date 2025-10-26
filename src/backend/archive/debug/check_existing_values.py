import psycopg2
import os

DATABASE_URL = "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    # Check what values currently exist
    print("Checking distinct values in role_process_value column...")
    cur.execute("""
        SELECT DISTINCT role_process_value, COUNT(*)
        FROM unknown_role_process_matrix
        GROUP BY role_process_value
        ORDER BY role_process_value
    """)

    results = cur.fetchall()
    print(f"\nFound {len(results)} distinct values:")
    for value, count in results:
        print(f"  Value: {value}, Count: {count}")

    cur.close()
    conn.close()

except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
