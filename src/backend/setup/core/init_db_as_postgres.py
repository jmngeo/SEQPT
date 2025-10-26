#!/usr/bin/env python3
"""
Initialize database tables as postgres superuser, then transfer ownership to ma0349
"""

import os
import sys

# Override DATABASE_URL to use postgres superuser
os.environ['DATABASE_URL'] = 'postgresql://postgres:root@localhost:5432/competency_assessment'

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db

def main():
    """Create all tables as postgres, then grant ownership to ma0349"""

    app = create_app()

    with app.app_context():
        print("Creating database tables as postgres superuser...")
        print()

        try:
            # Create all tables
            db.create_all()
            print("[OK] All tables created successfully!")
            print()

            # Get list of all tables
            from sqlalchemy import inspect
            inspector = inspect(db.engine)
            tables = inspector.get_table_names()

            print(f"Created {len(tables)} tables:")
            for table in sorted(tables):
                print(f"  - {table}")

            # Transfer ownership to ma0349
            print()
            print("Transferring ownership to ma0349...")

            with db.engine.connect() as conn:
                for table in tables:
                    conn.execute(db.text(f"ALTER TABLE {table} OWNER TO ma0349"))
                    conn.commit()
                    print(f"  [OK] {table}")

                # Also transfer sequences
                sequences_query = db.text("""
                    SELECT sequence_name
                    FROM information_schema.sequences
                    WHERE sequence_schema = 'public'
                """)
                result = conn.execute(sequences_query)
                sequences = [row[0] for row in result]

                for seq in sequences:
                    conn.execute(db.text(f"ALTER SEQUENCE {seq} OWNER TO ma0349"))
                    conn.commit()

                print()
                print(f"[OK] Transferred {len(sequences)} sequences to ma0349")

            print()
            print("="*60)
            print("[SUCCESS] Database initialized successfully!")
            print("="*60)
            print()
            print("Next steps:")
            print("1. Run backend:  python run.py --port 5000")
            print("2. Test login:   curl -X POST http://localhost:5000/mvp/auth/login")
            print()

            return True

        except Exception as e:
            print(f"\n[ERROR] {e}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
