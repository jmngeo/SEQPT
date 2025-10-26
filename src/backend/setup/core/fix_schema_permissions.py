#!/usr/bin/env python3
"""
Fix PostgreSQL 15+ public schema permissions for ma0349
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def fix_schema_permissions():
    """Grant CREATE permission on public schema - required for PostgreSQL 15+"""
    try:
        # Connect to competency_assessment database as postgres superuser
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='root',
            database='competency_assessment'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        print("Fixing public schema permissions for PostgreSQL 15+...")
        print()

        # PostgreSQL 15+ restricts public schema by default
        # We need to explicitly grant CREATE permission

        # Revoke public permissions first (cleanup)
        cursor.execute("REVOKE CREATE ON SCHEMA public FROM PUBLIC")
        print("[OK] Revoked default public schema permissions")

        # Grant CREATE permission to ma0349
        cursor.execute("GRANT CREATE ON SCHEMA public TO ma0349")
        print("[OK] Granted CREATE permission on schema public to ma0349")

        # Grant USAGE permission
        cursor.execute("GRANT USAGE ON SCHEMA public TO ma0349")
        print("[OK] Granted USAGE permission on schema public to ma0349")

        # Grant all privileges on existing objects
        cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349")
        print("[OK] Granted ALL privileges on existing tables to ma0349")

        cursor.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349")
        print("[OK] Granted ALL privileges on existing sequences to ma0349")

        # Set default privileges for future objects created by ma0349
        cursor.execute("ALTER DEFAULT PRIVILEGES FOR ROLE ma0349 IN SCHEMA public GRANT ALL ON TABLES TO ma0349")
        cursor.execute("ALTER DEFAULT PRIVILEGES FOR ROLE ma0349 IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349")
        print("[OK] Set default privileges for future objects")

        cursor.close()
        conn.close()

        print()
        print("="*60)
        print("[SUCCESS] Schema permissions fixed!")
        print("="*60)
        print()
        print("Now run:")
        print("  python run.py --init-db")
        print()

        return True

    except psycopg2.Error as e:
        print(f"\n[ERROR] {e}")
        return False

if __name__ == '__main__':
    fix_schema_permissions()
