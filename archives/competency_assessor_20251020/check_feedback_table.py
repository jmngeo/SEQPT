import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING FEEDBACK TABLE STRUCTURE")
    print("=" * 80)

    # Check user_competency_survey_feedback table
    print("\nuser_competency_survey_feedback table columns:")
    columns = db.session.execute(text("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'user_competency_survey_feedback'
        ORDER BY ordinal_position
    """)).fetchall()
    for col in columns:
        print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")

    # Check if there are any rows
    print("\nRows in user_competency_survey_feedback:")
    count = db.session.execute(text("SELECT COUNT(*) FROM user_competency_survey_feedback")).fetchone()[0]
    print(f"   Total rows: {count}")

    if count > 0:
        print("\n   Sample rows:")
        rows = db.session.execute(text("SELECT * FROM user_competency_survey_feedback LIMIT 3")).fetchall()
        for row in rows:
            print(f"      {row}")

    # Check competency table structure
    print("\n" + "=" * 80)
    print("competency table columns:")
    columns = db.session.execute(text("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'competency'
        ORDER BY ordinal_position
    """)).fetchall()
    for col in columns:
        print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")

    # Check role_competency_matrix table
    print("\n" + "=" * 80)
    print("role_competency_matrix table columns:")
    columns = db.session.execute(text("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'role_competency_matrix'
        ORDER BY ordinal_position
    """)).fetchall()
    for col in columns:
        print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")

    print("\n" + "=" * 80)
