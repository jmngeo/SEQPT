"""Check if stored procedure exists"""
import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    # Check if stored procedure exists
    result = db.session.execute(
        text("SELECT proname FROM pg_proc WHERE proname='update_unknown_role_competency_values';")
    ).fetchall()

    if result:
        print(f"[SUCCESS] Stored procedure 'update_unknown_role_competency_values' EXISTS")
        print(f"Procedure name: {result[0][0]}")
    else:
        print("[ERROR] Stored procedure 'update_unknown_role_competency_values' NOT FOUND")
        print("\nYou need to run create_stored_procedures.py to create it!")
