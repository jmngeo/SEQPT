"""
Migration script to add organization_id column to admin_user table
"""
from app import create_app, db
from sqlalchemy import text

def run_migration():
    app = create_app()

    with app.app_context():
        try:
            # Check if column already exists
            result = db.session.execute(text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'admin_user'
                AND column_name = 'organization_id'
            """))

            if result.fetchone():
                print("Column organization_id already exists in admin_user table")
                return

            # Add the organization_id column
            print("Adding organization_id column to admin_user table...")
            db.session.execute(text("""
                ALTER TABLE admin_user
                ADD COLUMN organization_id INTEGER REFERENCES organization(id)
            """))

            db.session.commit()
            print("[SUCCESS] Successfully added organization_id column to admin_user table")

        except Exception as e:
            db.session.rollback()
            print(f"[ERROR] Error during migration: {e}")
            raise

if __name__ == '__main__':
    run_migration()
