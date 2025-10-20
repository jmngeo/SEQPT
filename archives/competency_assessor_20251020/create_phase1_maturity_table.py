"""
Database migration script to create phase1_maturity table
Run this script to add the Phase 1 Maturity Assessment table to the database
"""

import sys
import os
from sqlalchemy import create_engine, text

# Database connection details
DB_USER = "ma0349"
DB_PASSWORD = "MA0349_2025"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "competency_assessment"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# SQL to create the phase1_maturity table
CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS phase1_maturity (
    id SERIAL PRIMARY KEY,
    org_id INTEGER NOT NULL,

    -- Question responses (raw values)
    q1_rollout_scope INTEGER NOT NULL CHECK (q1_rollout_scope BETWEEN 0 AND 4),
    q2_se_processes INTEGER NOT NULL CHECK (q2_se_processes BETWEEN 0 AND 5),
    q3_se_mindset INTEGER NOT NULL CHECK (q3_se_mindset BETWEEN 0 AND 4),
    q4_knowledge_base INTEGER NOT NULL CHECK (q4_knowledge_base BETWEEN 0 AND 4),

    -- Calculation results
    raw_weighted_score REAL NOT NULL,
    balance_penalty REAL NOT NULL,
    final_score REAL NOT NULL,
    maturity_level INTEGER NOT NULL CHECK (maturity_level BETWEEN 1 AND 5),
    maturity_name VARCHAR(20) NOT NULL,
    balance_score REAL NOT NULL,
    profile_type VARCHAR(50) NOT NULL,

    -- Individual field scores (0-100 scale)
    field_score_rollout REAL NOT NULL,
    field_score_processes REAL NOT NULL,
    field_score_mindset REAL NOT NULL,
    field_score_knowledge REAL NOT NULL,

    -- Weakest and strongest fields
    weakest_field VARCHAR(50) NOT NULL,
    weakest_field_value REAL NOT NULL,
    strongest_field VARCHAR(50) NOT NULL,
    strongest_field_value REAL NOT NULL,

    -- Metadata
    assessment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key
    CONSTRAINT fk_organization
        FOREIGN KEY (org_id)
        REFERENCES organization(id)
        ON DELETE CASCADE
);

-- Create index on org_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_phase1_maturity_org_id ON phase1_maturity(org_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_phase1_maturity_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_phase1_maturity_timestamp ON phase1_maturity;

CREATE TRIGGER trigger_update_phase1_maturity_timestamp
    BEFORE UPDATE ON phase1_maturity
    FOR EACH ROW
    EXECUTE FUNCTION update_phase1_maturity_timestamp();
"""


def run_migration():
    """Run the migration to create phase1_maturity table"""
    print("=" * 60)
    print("Phase 1 Maturity Assessment - Database Migration")
    print("=" * 60)
    print(f"\nConnecting to database: {DB_NAME}")
    print(f"Host: {DB_HOST}:{DB_PORT}")
    print(f"User: {DB_USER}")

    try:
        # Create engine
        engine = create_engine(DATABASE_URL)

        # Execute migration
        with engine.connect() as conn:
            print("\nExecuting migration...")
            conn.execute(text(CREATE_TABLE_SQL))
            conn.commit()
            print("[OK] Migration completed successfully!")

            # Verify table exists
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'phase1_maturity'
                );
            """))
            table_exists = result.scalar()

            if table_exists:
                print("[OK] Table 'phase1_maturity' created and verified!")

                # Show table structure
                result = conn.execute(text("""
                    SELECT column_name, data_type, is_nullable
                    FROM information_schema.columns
                    WHERE table_name = 'phase1_maturity'
                    ORDER BY ordinal_position;
                """))

                print("\nTable Structure:")
                print("-" * 60)
                for row in result:
                    nullable = "NULL" if row[2] == "YES" else "NOT NULL"
                    print(f"  {row[0]:30s} {row[1]:20s} {nullable}")
                print("-" * 60)
            else:
                print("[ERROR] Table creation verification failed!")
                return False

        print("\n[SUCCESS] Migration completed successfully!")
        print("\nYou can now use the Phase 1 Maturity Assessment feature.")
        return True

    except Exception as e:
        print(f"\n[ERROR] Migration failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
