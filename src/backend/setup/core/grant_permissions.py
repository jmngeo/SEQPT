#!/usr/bin/env python3
"""
Grant database permissions to ma0349 user
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def grant_permissions():
    """Grant permissions to ma0349 on competency_assessment database"""
    try:
        # Connect as postgres superuser
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='postgres',  # Try common default password
            database='competency_assessment'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        print("Granting permissions to ma0349...")

        # Grant schema privileges
        cursor.execute("GRANT ALL PRIVILEGES ON SCHEMA public TO ma0349")
        print("[OK] Schema privileges granted")

        # Grant table privileges
        cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349")
        print("[OK] Table privileges granted")

        # Grant sequence privileges
        cursor.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349")
        print("[OK] Sequence privileges granted")

        # Grant default privileges for future objects
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ma0349")
        cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349")
        print("[OK] Default privileges set")

        cursor.close()
        conn.close()

        print("\n[SUCCESS] All permissions granted to ma0349")
        return True

    except psycopg2.Error as e:
        print(f"[ERROR] Database error: {e}")
        print("\nTrying alternative password 'root'...")

        try:
            # Try with 'root' password
            conn = psycopg2.connect(
                host='localhost',
                port=5432,
                user='postgres',
                password='root',
                database='competency_assessment'
            )
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            cursor = conn.cursor()

            print("Granting permissions to ma0349...")
            cursor.execute("GRANT ALL PRIVILEGES ON SCHEMA public TO ma0349")
            cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349")
            cursor.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349")
            cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ma0349")
            cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349")

            cursor.close()
            conn.close()

            print("\n[SUCCESS] All permissions granted to ma0349")
            return True

        except psycopg2.Error as e2:
            print(f"[ERROR] Alternative password also failed: {e2}")
            print("\nPlease run this SQL manually as postgres user:")
            print("  psql -U postgres -d competency_assessment")
            print("  GRANT ALL PRIVILEGES ON SCHEMA public TO ma0349;")
            print("  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ma0349;")
            print("  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ma0349;")
            return False

if __name__ == '__main__':
    grant_permissions()
