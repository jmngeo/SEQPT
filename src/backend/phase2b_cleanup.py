"""
Phase 2B Cleanup - Legacy Model Removal
Date: 2025-10-25
Purpose: Drop legacy tables and remove unused models/endpoints

LEGACY TABLES TO DROP (26 rows total):
1. app_user (8 rows) - Old user table, replaced by users
2. new_survey_user (10 rows) - Old survey tracking, replaced by user_assessment
3. user_survey_type (8 rows) - Old survey type, merged into user_assessment.survey_type

SAFETY: Frontend already uses new endpoints, no breaking changes
"""

import os
from datetime import datetime
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Load environment variables
load_dotenv()

# Database connection
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database')

def inspect_legacy_data():
    """Step 1: Inspect what data exists in legacy tables"""
    engine = create_engine(DATABASE_URL)

    print("[INFO] Inspecting legacy table data...")
    print("=" * 80)

    with engine.connect() as conn:
        # Check app_user
        print("\n[TABLE] app_user:")
        result = conn.execute(text("SELECT id, username, organization_id, name FROM app_user ORDER BY id"))
        rows = result.fetchall()
        for row in rows:
            print(f"  - ID: {row[0]}, Username: {row[1]}, Org: {row[2]}, Name: {row[3]}")
        print(f"  Total: {len(rows)} rows")

        # Check new_survey_user
        print("\n[TABLE] new_survey_user:")
        result = conn.execute(text("SELECT id, username, survey_completion_status, created_at FROM new_survey_user ORDER BY id"))
        rows = result.fetchall()
        for row in rows:
            print(f"  - ID: {row[0]}, Username: {row[1]}, Completed: {row[2]}, Created: {row[3]}")
        print(f"  Total: {len(rows)} rows")

        # Check user_survey_type
        print("\n[TABLE] user_survey_type:")
        result = conn.execute(text("SELECT id, user_id, survey_type FROM user_survey_type ORDER BY id"))
        rows = result.fetchall()
        for row in rows:
            print(f"  - ID: {row[0]}, User ID: {row[1]}, Survey Type: {row[2]}")
        print(f"  Total: {len(rows)} rows")

    print("\n" + "=" * 80)
    print("[INFO] Inspection complete. This is historical data from old system.")
    print("[INFO] New users are stored in 'users' table.")
    print("[INFO] New assessments are stored in 'user_assessment' table.")
    print("\n")

def drop_legacy_tables():
    """Step 2: Drop legacy tables"""
    engine = create_engine(DATABASE_URL)

    print("[INFO] Dropping legacy tables...")
    print("=" * 80)

    tables_to_drop = [
        'user_survey_type',  # Drop child table first (has FK to app_user)
        'new_survey_user',   # No FK dependencies
        'app_user'           # Drop parent table last
    ]

    with engine.connect() as conn:
        for table in tables_to_drop:
            try:
                print(f"\n[DROP] Dropping table: {table}")
                conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
                conn.commit()
                print(f"[SUCCESS] Table '{table}' dropped successfully")
            except Exception as e:
                print(f"[ERROR] Failed to drop {table}: {str(e)}")
                conn.rollback()
                raise

    print("\n" + "=" * 80)
    print("[SUCCESS] All legacy tables dropped successfully!")
    print("\n")

def verify_table_deletion():
    """Step 3: Verify tables are gone"""
    engine = create_engine(DATABASE_URL)

    print("[INFO] Verifying table deletion...")
    print("=" * 80)

    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name IN ('app_user', 'new_survey_user', 'user_survey_type')
            ORDER BY table_name
        """))
        remaining = result.fetchall()

        if remaining:
            print("\n[WARNING] Some tables still exist:")
            for row in remaining:
                print(f"  - {row[0]}")
            return False
        else:
            print("\n[SUCCESS] All legacy tables have been removed from database!")
            print("\n[INFO] Active tables remain:")

            # Show active tables
            result = conn.execute(text("""
                SELECT table_name,
                       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
                FROM information_schema.tables t
                WHERE table_schema = 'public'
                AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """))
            tables = result.fetchall()
            for row in tables:
                print(f"  - {row[0]} ({row[1]} columns)")

            return True

    print("\n" + "=" * 80)

if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("PHASE 2B CLEANUP - Legacy Model Removal")
    print("=" * 80)
    print("\nThis script will:")
    print("1. Inspect legacy table data (26 rows)")
    print("2. Drop 3 legacy tables (app_user, new_survey_user, user_survey_type)")
    print("3. Verify deletion")
    print("\nNOTE: This will NOT affect:")
    print("  - User registration (uses 'users' table)")
    print("  - Assessment system (uses 'user_assessment' table)")
    print("  - Any active functionality")
    print("\n" + "=" * 80)

    response = input("\nProceed with Phase 2B cleanup? (yes/no): ")

    if response.lower() != 'yes':
        print("\n[CANCELLED] Phase 2B cleanup cancelled by user.")
        exit(0)

    try:
        # Step 1: Inspect data
        inspect_legacy_data()

        input("Press Enter to proceed with dropping tables...")

        # Step 2: Drop tables
        drop_legacy_tables()

        # Step 3: Verify
        if verify_table_deletion():
            print("\n[SUCCESS] Phase 2B database cleanup complete!")
            print("\nNext steps:")
            print("1. Remove legacy models from models.py (3 models)")
            print("2. Remove legacy endpoints from routes.py (3 endpoints)")
            print("3. Clean up imports")
            print("4. Test application")
        else:
            print("\n[WARNING] Verification failed. Check output above.")

    except Exception as e:
        print(f"\n[ERROR] Phase 2B cleanup failed: {str(e)}")
        print("[INFO] Database may be in inconsistent state. Check manually.")
        exit(1)
