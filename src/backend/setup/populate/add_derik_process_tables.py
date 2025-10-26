"""
Add ISO/IEC 15288 Process Tables Migration
Creates tables for task-based role identification (Phase 1)

This script adds 7 new tables from Derik's system:
- iso_system_life_cycle_processes
- iso_processes
- iso_activities
- iso_tasks
- role_process_matrix
- process_competency_matrix
- unknown_role_process_matrix
- unknown_role_competency_matrix
"""

import os
import sys

# Set database URL before importing app
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import inspect

def main():
    """Create new ISO process tables"""
    app = create_app()

    with app.app_context():
        print("[INFO] Creating new ISO process tables...")

        # Create all tables (only creates tables that don't exist)
        db.create_all()

        print("[OK] Tables created successfully!")
        print()

        # Verify tables exist
        inspector = inspect(db.engine)
        all_tables = inspector.get_table_names()

        required_tables = [
            'iso_system_life_cycle_processes',
            'iso_processes',
            'iso_activities',
            'iso_tasks',
            'role_process_matrix',
            'process_competency_matrix',
            'unknown_role_process_matrix',
            'unknown_role_competency_matrix'
        ]

        print("[INFO] Verifying new tables...")
        print()
        all_exist = True

        for table in required_tables:
            if table in all_tables:
                print(f"[OK] {table}")
            else:
                print(f"[MISSING] {table}")
                all_exist = False

        print()
        if all_exist:
            print("[SUCCESS] All required tables created successfully!")
        else:
            print("[ERROR] Some tables are missing. Check for errors above.")
            return 1

        # Show total table count
        print()
        print(f"[INFO] Total tables in database: {len(all_tables)}")

        return 0

if __name__ == '__main__':
    sys.exit(main())
