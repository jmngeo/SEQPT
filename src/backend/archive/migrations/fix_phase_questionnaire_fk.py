"""
Fix PhaseQuestionnaireResponse foreign key constraint
Changes FK from app_user.id to users.id to match registration system
"""
import psycopg2
import sys

def fix_foreign_key():
    """Drop old FK constraint and add new one pointing to users table"""

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

        print("[1/3] Checking existing foreign key constraint...")

        # Check if constraint exists
        cur.execute("""
            SELECT constraint_name
            FROM information_schema.table_constraints
            WHERE table_name = 'phase_questionnaire_responses'
            AND constraint_type = 'FOREIGN KEY'
            AND constraint_name = 'phase_questionnaire_responses_user_id_fkey'
        """)

        constraint_exists = cur.fetchone()

        if constraint_exists:
            print(f"[2/3] Dropping old constraint: {constraint_exists[0]}")
            cur.execute("""
                ALTER TABLE phase_questionnaire_responses
                DROP CONSTRAINT phase_questionnaire_responses_user_id_fkey
            """)
            print("    [OK] Old constraint dropped")
        else:
            print("[2/3] No old constraint found (may have been dropped already)")

        print("[3/3] Adding new foreign key constraint pointing to users table...")
        cur.execute("""
            ALTER TABLE phase_questionnaire_responses
            ADD CONSTRAINT phase_questionnaire_responses_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id)
            ON DELETE CASCADE
        """)
        print("    [OK] New constraint added")

        # Commit changes
        conn.commit()
        print("\n[SUCCESS] Foreign key constraint updated successfully!")
        print("Phase questionnaire responses now reference the 'users' table.")

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
    print("=" * 80)
    print("FIX PHASE QUESTIONNAIRE FOREIGN KEY CONSTRAINT")
    print("=" * 80)
    print()
    fix_foreign_key()
