"""
Create role_competency_matrix table and populate with Derik's default data
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CREATING ROLE_COMPETENCY_MATRIX TABLE")
    print("=" * 80)

    # Create the table
    print("\n[1/2] Creating role_competency_matrix table...")
    db.session.execute(text("""
        CREATE TABLE IF NOT EXISTS public.role_competency_matrix (
            id SERIAL PRIMARY KEY,
            role_cluster_id INTEGER NOT NULL,
            competency_id INTEGER NOT NULL,
            role_competency_value INTEGER DEFAULT -100 NOT NULL,
            organization_id INTEGER NOT NULL,
            CONSTRAINT role_competency_matrix_role_competency_value_check
                CHECK (role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 3, 4, 6])),
            CONSTRAINT fk_role_cluster
                FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id),
            CONSTRAINT fk_competency
                FOREIGN KEY (competency_id) REFERENCES public.competency(id),
            CONSTRAINT fk_organization
                FOREIGN KEY (organization_id) REFERENCES public.organization(id)
        );
    """))
    db.session.commit()
    print("[OK] Table created")

    # Check if we have competencies in the database
    print("\n[2/2] Checking competencies...")
    comp_count = db.session.execute(text("SELECT COUNT(*) FROM competency;")).scalar()
    print(f"  Competencies in database: {comp_count}")

    if comp_count == 0:
        print("[WARNING] No competencies found - table is created but empty")
        print("  Role-competency matrix can only be populated after competencies exist")
    else:
        print("[OK] Competencies exist - ready for matrix population")

    print("\n" + "=" * 80)
    print("TABLE CREATION COMPLETE")
    print("=" * 80)
    print("\nNote: The table is created empty. It will be populated either:")
    print("  1. By calling the stored procedure after competencies are loaded")
    print("  2. Automatically when new organizations are created")
