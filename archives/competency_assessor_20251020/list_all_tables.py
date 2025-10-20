import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("ALL TABLES IN DATABASE")
    print("=" * 80)

    # List all tables
    tables = db.session.execute(text("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    """)).fetchall()

    print(f"\nFound {len(tables)} tables:")
    for table in tables:
        print(f"   - {table[0]}")

    print("\n" + "=" * 80)

    # For each important table, show its columns
    important_tables = [
        'new_survey_user',
        'competency_assessment',
        'role_competency',
        'phase2_response'
    ]

    for table_name in important_tables:
        print(f"\nTable: {table_name}")
        try:
            columns = db.session.execute(text(f"""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = :table_name
                ORDER BY ordinal_position
            """), {"table_name": table_name}).fetchall()
            if columns:
                for col in columns:
                    print(f"   - {col[0]}: {col[1]}")
            else:
                print("   [Table not found or no columns]")
        except Exception as e:
            print(f"   [Error: {e}]")

    print("\n" + "=" * 80)
