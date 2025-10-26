#!/usr/bin/env python3
"""
Drop all tables in competency_assessment database
Use this to clean up old schema before recreating from unified models.py
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def drop_all_tables():
    """Drop all tables in public schema"""
    try:
        # Connect as postgres to ensure we have permission
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='root',
            database='competency_assessment'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        print("Dropping all tables in competency_assessment database...")
        print()

        # Drop all tables in public schema (CASCADE to handle dependencies)
        cursor.execute("DROP SCHEMA public CASCADE")
        print("[OK] Dropped public schema")

        # Recreate public schema
        cursor.execute("CREATE SCHEMA public")
        print("[OK] Created fresh public schema")

        # Grant permissions to ma0349
        cursor.execute("GRANT ALL ON SCHEMA public TO ma0349")
        cursor.execute("GRANT CREATE ON SCHEMA public TO ma0349")
        print("[OK] Granted permissions to ma0349")

        # Set default privileges
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ma0349")
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349")
        print("[OK] Set default privileges")

        cursor.close()
        conn.close()

        print()
        print("="*60)
        print("[SUCCESS] All tables dropped successfully!")
        print("="*60)
        print()
        print("Now run:")
        print("  python init_db_as_postgres.py")
        print()
        print("To create all tables from the unified models.py")

        return True

    except psycopg2.Error as e:
        print(f"\n[ERROR] {e}")
        return False

if __name__ == '__main__':
    drop_all_tables()
