"""
Script to list and drop empty tables from Phase 2A model removals
"""
import psycopg2
from psycopg2 import sql

# Database connection
conn = psycopg2.connect(
    dbname='seqpt_database',
    user='seqpt_admin',
    password='SeQpt_2025',
    host='localhost',
    port='5432'
)

def list_all_tables():
    """List all tables in the database"""
    cursor = conn.cursor()
    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)
    tables = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return tables

def get_table_row_count(table_name):
    """Get row count for a table"""
    cursor = conn.cursor()
    try:
        cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table_name)))
        count = cursor.fetchone()[0]
        cursor.close()
        return count
    except Exception as e:
        cursor.close()
        return -1  # Error

def find_empty_tables(tables):
    """Find tables with zero rows"""
    empty_tables = []
    for table in tables:
        count = get_table_row_count(table)
        if count == 0:
            empty_tables.append(table)
            print(f"  - {table}: 0 rows (EMPTY)")
        else:
            print(f"  - {table}: {count} rows")
    return empty_tables

def drop_empty_tables(empty_tables):
    """Drop empty tables"""
    cursor = conn.cursor()

    print(f"\n[INFO] Found {len(empty_tables)} empty tables")
    print(f"[INFO] Dropping empty tables...")

    for table in empty_tables:
        try:
            cursor.execute(sql.SQL("DROP TABLE IF EXISTS {} CASCADE").format(sql.Identifier(table)))
            print(f"  [OK] Dropped table: {table}")
        except Exception as e:
            print(f"  [ERROR] Failed to drop {table}: {e}")

    conn.commit()
    cursor.close()
    print(f"\n[SUCCESS] Dropped {len(empty_tables)} empty tables")

if __name__ == '__main__':
    print("[INFO] Listing all tables in seqpt_database...\n")
    tables = list_all_tables()

    print(f"\n[INFO] Found {len(tables)} total tables")
    print(f"[INFO] Checking for empty tables...\n")

    empty_tables = find_empty_tables(tables)

    if empty_tables:
        print(f"\n[INFO] Empty tables to drop:")
        for t in empty_tables:
            print(f"  - {t}")

        response = input(f"\n[CONFIRM] Drop {len(empty_tables)} empty tables? (yes/no): ")
        if response.lower() == 'yes':
            drop_empty_tables(empty_tables)
        else:
            print("[CANCELLED] No tables were dropped")
    else:
        print("\n[INFO] No empty tables found!")

    conn.close()
