import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING DATABASE TABLE STRUCTURE")
    print("=" * 80)

    # Check new_survey_user table structure
    print("\n1. new_survey_user table columns:")
    columns = db.session.execute(text("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'new_survey_user'
        ORDER BY ordinal_position
    """)).fetchall()
    for col in columns:
        print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")

    # Check assessment_feedback table structure
    print("\n2. assessment_feedback table:")
    exists = db.session.execute(text("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_name = 'assessment_feedback'
        )
    """)).fetchone()[0]
    if exists:
        print("   Table EXISTS")
        columns = db.session.execute(text("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'assessment_feedback'
            ORDER BY ordinal_position
        """)).fetchall()
        for col in columns:
            print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")
    else:
        print("   Table DOES NOT EXIST")

    # Check phase1_response table
    print("\n3. phase1_response table columns:")
    columns = db.session.execute(text("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'phase1_response'
        ORDER BY ordinal_position
    """)).fetchall()
    for col in columns:
        print(f"   - {col[0]}: {col[1]} (nullable: {col[2]})")

    print("\n" + "=" * 80)
