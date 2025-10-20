"""
Migration script to create Phase1Roles and Phase1TargetGroup tables
"""
import sys
sys.path.insert(0, 'C:/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis/src/competency_assessor')

from app import create_app, db
from app.models import Phase1Roles, Phase1TargetGroup

def create_tables():
    app = create_app()
    with app.app_context():
        print("[INFO] Creating Phase 1 Task 2 tables...")

        try:
            # Create the tables
            db.create_all()
            print("[SUCCESS] Tables created successfully!")

            # Verify tables exist
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()

            if 'phase1_roles' in tables:
                print("[OK] phase1_roles table created")
            else:
                print("[WARNING] phase1_roles table not found")

            if 'phase1_target_group' in tables:
                print("[OK] phase1_target_group table created")
            else:
                print("[WARNING] phase1_target_group table not found")

        except Exception as e:
            print(f"[ERROR] Failed to create tables: {str(e)}")
            raise

if __name__ == '__main__':
    create_tables()
