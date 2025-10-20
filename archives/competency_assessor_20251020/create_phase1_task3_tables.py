"""
Migration script to create Phase1Strategy table for Task 3
"""
import sys
sys.path.insert(0, 'C:/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis/src/competency_assessor')

from app import create_app, db
from app.models import Phase1Strategy

def create_tables():
    app = create_app()
    with app.app_context():
        print("[INFO] Creating Phase 1 Task 3 tables...")

        try:
            # Create the tables
            db.create_all()
            print("[SUCCESS] Tables created successfully!")

            # Verify tables exist
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()

            if 'phase1_strategies' in tables:
                print("[OK] phase1_strategies table created")
            else:
                print("[WARNING] phase1_strategies table not found")

        except Exception as e:
            print(f"[ERROR] Failed to create tables: {str(e)}")
            raise

if __name__ == '__main__':
    create_tables()
