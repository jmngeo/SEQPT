#!/usr/bin/env python3
"""
Check existing tables in competency_assessment database
"""

import psycopg2

def check_tables():
    """Check what tables already exist"""
    try:
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='ma0349',
            password='MA0349_2025',
            database='competency_assessment'
        )
        cursor = conn.cursor()

        # Get list of tables
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """)

        tables = cursor.fetchall()

        print(f"Found {len(tables)} existing tables:")
        print()
        for table in tables:
            print(f"  - {table[0]}")

        cursor.close()
        conn.close()

        if len(tables) > 0:
            print()
            print("="*60)
            print("EXISTING TABLES FOUND!")
            print("="*60)
            print()
            print("These tables may have been created with old schema.")
            print("You should drop all tables and recreate from scratch.")
            print()
            print("To drop all tables, run:")
            print("  python drop_all_tables.py")
            print()

        return len(tables) > 0

    except psycopg2.Error as e:
        print(f"[ERROR] {e}")
        return False

if __name__ == '__main__':
    check_tables()
