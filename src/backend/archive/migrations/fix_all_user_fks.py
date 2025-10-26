"""
Fix all foreign key constraints to point to users table instead of app_user
Updates: user_se_competency_survey_results and learning_plans tables
"""
import psycopg2
import sys

def fix_foreign_keys():
    """Drop old FK constraints and add new ones pointing to users table"""

    conn = None
    try:
        # Connect to database
        conn = psycopg2.connect(
            dbname="competency_assessment",
            user="ma0349",
            password="MA0349_2025",
            host="localhost",
            port="5432"
        )
        cur = conn.cursor()

        print("=" * 80)
        print("FIXING USER FOREIGN KEY CONSTRAINTS")
        print("=" * 80)
        print()

        # List of tables and their constraint names
        tables_to_fix = [
            {
                'table': 'user_se_competency_survey_results',
                'constraint': 'user_se_competency_survey_results_user_id_fkey',
                'column': 'user_id'
            },
            {
                'table': 'learning_plans',
                'constraint': 'learning_plans_user_id_fkey',
                'column': 'user_id'
            }
        ]

        for table_info in tables_to_fix:
            table = table_info['table']
            constraint = table_info['constraint']
            column = table_info['column']

            print(f"\n[{table}] Checking constraint: {constraint}")

            # Check if constraint exists
            cur.execute("""
                SELECT constraint_name
                FROM information_schema.table_constraints
                WHERE table_name = %s
                AND constraint_type = 'FOREIGN KEY'
                AND constraint_name = %s
            """, (table, constraint))

            constraint_exists = cur.fetchone()

            if constraint_exists:
                print(f"  [OK] Found constraint, dropping...")
                cur.execute(f"""
                    ALTER TABLE {table}
                    DROP CONSTRAINT {constraint}
                """)
                print(f"  [OK] Constraint dropped")
            else:
                print(f"  [SKIP] Constraint not found (may have been dropped already)")

            print(f"  [OK] Adding new constraint pointing to users table...")
            cur.execute(f"""
                ALTER TABLE {table}
                ADD CONSTRAINT {constraint}
                FOREIGN KEY ({column}) REFERENCES users(id)
                ON DELETE CASCADE
            """)
            print(f"  [OK] New constraint added")

        # Commit changes
        conn.commit()
        print("\n" + "=" * 80)
        print("[SUCCESS] All foreign key constraints updated successfully!")
        print("All tables now reference the unified 'users' table.")
        print("=" * 80)

    except psycopg2.Error as e:
        print(f"\n[ERROR] Database error: {e}")
        if conn:
            conn.rollback()
        sys.exit(1)

    except Exception as e:
        print(f"\n[ERROR] Unexpected error: {e}")
        if conn:
            conn.rollback()
        sys.exit(1)

    finally:
        if conn:
            cur.close()
            conn.close()

if __name__ == '__main__':
    fix_foreign_keys()
