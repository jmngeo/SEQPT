"""
Add Phase 1 columns to organization table
"""
from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("Adding Phase 1 columns to organization table...")

    # Add columns one by one
    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS organization_size VARCHAR(50)"))
        print("Added organization_size column")
    except Exception as e:
        print(f"Note: organization_size - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS maturity_score FLOAT"))
        print("Added maturity_score column")
    except Exception as e:
        print(f"Note: maturity_score - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS selected_archetype TEXT"))
        print("Added selected_archetype column")
    except Exception as e:
        print(f"Note: selected_archetype - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS phase1_completed BOOLEAN DEFAULT FALSE"))
        print("Added phase1_completed column")
    except Exception as e:
        print(f"Note: phase1_completed - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS phase1_completed_at TIMESTAMP"))
        print("Added phase1_completed_at column")
    except Exception as e:
        print(f"Note: phase1_completed_at - {e}")

    db.session.commit()
    print("\nMigration completed successfully!")
