"""
Migration script to add role column to admin_user table
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
                AND column_name = 'role'
            """))

            if result.fetchone():
                print("Column role already exists in admin_user table")
                return

            # Add the role column
            print("Adding role column to admin_user table...")
            db.session.execute(text("""
                ALTER TABLE admin_user
                ADD COLUMN role VARCHAR(50) NOT NULL DEFAULT 'employee'
            """))

            db.session.commit()
            print("[SUCCESS] Successfully added role column to admin_user table")

        except Exception as e:
            db.session.rollback()
            print(f"[ERROR] Error during migration: {e}")
            raise

if __name__ == '__main__':
    run_migration()
