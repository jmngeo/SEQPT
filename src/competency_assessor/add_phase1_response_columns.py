"""
Add Phase 1 response data columns to organization table
"""
from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("Adding Phase 1 response data columns to organization table...")

    # Add columns for storing detailed questionnaire responses
    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS maturity_responses TEXT"))
        print("Added maturity_responses column")
    except Exception as e:
        print(f"Note: maturity_responses - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS archetype_responses TEXT"))
        print("Added archetype_responses column")
    except Exception as e:
        print(f"Note: archetype_responses - {e}")

    try:
        db.session.execute(text("ALTER TABLE organization ADD COLUMN IF NOT EXISTS computed_archetype TEXT"))
        print("Added computed_archetype column")
    except Exception as e:
        print(f"Note: computed_archetype - {e}")

    db.session.commit()
    print("\nMigration completed successfully!")
