#!/usr/bin/env python3
"""
Create ma0349 user and grant permissions on competency_assessment database
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def setup_database_user():
    """Create user and grant permissions"""
    try:
        # Connect as postgres superuser to postgres database
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='root',  # Try 'root' first
            database='postgres'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        print("Step 1: Creating user ma0349...")

        # Check if user exists
        cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = 'ma0349'")
        user_exists = cursor.fetchone()

        if not user_exists:
            cursor.execute("CREATE USER ma0349 WITH PASSWORD 'MA0349_2025'")
            print("[OK] User ma0349 created")
        else:
            print("[OK] User ma0349 already exists")

        print("\nStep 2: Granting permissions on competency_assessment database...")

        # Grant database connection
        cursor.execute("GRANT ALL PRIVILEGES ON DATABASE competency_assessment TO ma0349")
        print("[OK] Database privileges granted")

        cursor.close()
        conn.close()

        # Now connect to competency_assessment database to grant schema/table privileges
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='root',
            database='competency_assessment'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        print("\nStep 3: Granting schema and table privileges...")

        # Grant schema privileges
        cursor.execute("GRANT ALL PRIVILEGES ON SCHEMA public TO ma0349")
        print("[OK] Schema privileges granted")

        # Grant table privileges (for existing tables)
        cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349")
        print("[OK] Table privileges granted")

        # Grant sequence privileges (for SERIAL columns)
        cursor.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349")
        print("[OK] Sequence privileges granted")

        # Grant default privileges for future objects
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ma0349")
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349")
        print("[OK] Default privileges set for future objects")

        # Make ma0349 owner of the database
        cursor.execute("ALTER DATABASE competency_assessment OWNER TO ma0349")
        print("[OK] Database ownership transferred to ma0349")

        cursor.close()
        conn.close()

        print("\n" + "="*60)
        print("[SUCCESS] User ma0349 created and all permissions granted!")
        print("="*60)
        print("\nYou can now run:")
        print("  python run.py --init-db")
        print("\nTo create all database tables from the unified models.py")

        return True

    except psycopg2.Error as e:
        print(f"\n[ERROR] Database error: {e}")
        print("\n" + "="*60)
        print("MANUAL SETUP REQUIRED")
        print("="*60)
        print("\nPlease run these SQL commands as postgres user:")
        print("\n1. Connect to PostgreSQL:")
        print("   psql -U postgres")
        print("\n2. Run these commands:")
        print("   CREATE USER ma0349 WITH PASSWORD 'MA0349_2025';")
        print("   GRANT ALL PRIVILEGES ON DATABASE competency_assessment TO ma0349;")
        print("   \\c competency_assessment")
        print("   GRANT ALL PRIVILEGES ON SCHEMA public TO ma0349;")
        print("   GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349;")
        print("   GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349;")
        print("   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ma0349;")
        print("   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349;")
        print("   ALTER DATABASE competency_assessment OWNER TO ma0349;")
        print("   \\q")
        print("\nOR with Windows authentication (if using Windows):")
        print("   Set your postgres password first using pgAdmin or:")
        print("   ALTER USER postgres WITH PASSWORD 'your_password';")

        return False

if __name__ == '__main__':
    setup_database_user()
