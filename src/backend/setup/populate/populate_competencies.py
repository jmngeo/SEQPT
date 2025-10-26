"""
Populate competency table with essential data from Derik's system
These are the 15 core SE competencies required for the competency-based role matching
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("POPULATING COMPETENCY TABLE")
    print("=" * 80)

    # Check if table already has data
    count = db.session.execute(text('SELECT COUNT(*) FROM competency;')).scalar()
    if count > 0:
        print(f"\nTable already has {count} rows - skipping")
    else:
        print("\nInserting 15 core SE competencies...")

        # Data from Derik's init.sql (lines 1476-1491)
        competencies = [
            (1, 'Core', 'Systems Thinking', 'The application of the fundamental concepts of systems thinking to Systems Engineering...', 'Systems thinking is a way of dealing with increasing complexity...'),
            (4, 'Core', 'Lifecycle Consideration', '', ''),
            (5, 'Core', 'Customer / Value Orientation', '', ''),
            (6, 'Core', 'Systems Modeling and Analysis', '', ''),
            (7, 'Social / Personal', 'Communication', '', ''),
            (8, 'Social / Personal', 'Leadership', '', ''),
            (9, 'Social / Personal', 'Self-Organization', '', ''),
            (10, 'Management', 'Project Management', '', ''),
            (11, 'Management', 'Decision Management', '', ''),
            (12, 'Management', 'Information Management', '', ''),
            (13, 'Management', 'Configuration Management', '', ''),
            (14, 'Technical', 'Requirements Definition', '', ''),
            (15, 'Technical', 'System Architecting', '', ''),
            (16, 'Technical', 'Integration, Verification, Validation', '', ''),
            (17, 'Technical', 'Operation and Support', '', ''),
            (18, 'Technical', 'Agile Methods', '', '')
        ]

        for comp in competencies:
            db.session.execute(text("""
                INSERT INTO competency (id, competency_area, competency_name, description, why_it_matters)
                VALUES (:id, :area, :name, :desc, :why)
            """), {
                'id': comp[0],
                'area': comp[1],
                'name': comp[2],
                'desc': comp[3],
                'why': comp[4]
            })

        db.session.commit()

        print(f"[SUCCESS] Inserted {len(competencies)} competencies")

        # Show results
        results = db.session.execute(text("""
            SELECT id, competency_area, competency_name
            FROM competency
            ORDER BY id;
        """)).fetchall()

        print("\nCompetencies:")
        for r in results:
            print(f"  {r[0]:2}: [{r[1]:20}] {r[2]}")

    print("\n" + "=" * 80)
    print("COMPETENCY TABLE READY")
    print("=" * 80)
