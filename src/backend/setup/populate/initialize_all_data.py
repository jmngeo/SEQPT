#!/usr/bin/env python3
"""
Master Data Initialization Script for SE-QPT
Runs ALL required populate scripts in correct order with verification

This script ensures:
1. ISO Processes are populated (30 entries - ISO 15288:2015)
2. SE Competencies are populated (16 entries)
3. Roles are populated (14 entries)
4. Role-Process Matrix for Organization 1 is populated (420 entries - TEMPLATE!)
5. Process-Competency Matrix is populated (480 entries - GLOBAL!)
6. Stored procedures are created
7. Role-Competency Matrix for Organization 1 is calculated

Author: SE-QPT Team
Date: 2025-10-21
"""

import os
import sys
import subprocess
from sqlalchemy import text

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

def print_header(text):
    """Print a formatted header"""
    print("\n" + "=" * 80)
    print(f"  {text}")
    print("=" * 80)

def print_step(step_num, total_steps, description):
    """Print a step indicator"""
    print(f"\n[STEP {step_num}/{total_steps}] {description}")
    print("-" * 80)

def run_script(script_name, description):
    """Run a populate script and check for errors"""
    print(f"\nRunning: {script_name}")
    print(f"Purpose: {description}")

    result = subprocess.run(
        [sys.executable, script_name],
        capture_output=True,
        text=True,
        cwd=os.path.dirname(__file__)
    )

    if result.returncode == 0:
        print(f"[OK] {script_name} completed successfully")
        if result.stdout:
            # Print stdout but limit to last 20 lines to avoid clutter
            lines = result.stdout.strip().split('\n')
            if len(lines) > 20:
                print('\n'.join(lines[-20:]))
            else:
                print(result.stdout)
        return True
    else:
        print(f"[ERROR] {script_name} failed!")
        print("Error output:")
        print(result.stderr)
        if result.stdout:
            print("Standard output:")
            print(result.stdout)
        return False

def verify_data():
    """Verify all required data is present in database"""
    print_step("FINAL", "FINAL", "Verifying Data Integrity")

    try:
        from app import create_app
        from models import db

        app = create_app()
        with app.app_context():
            # Check each table
            checks = [
                ('iso_processes', 28, "ISO/IEC 15288 Processes"),
                ('competency', 16, "SE Competencies"),
                ('role_cluster', 14, "SE Role Clusters"),
                ('role_process_matrix WHERE organization_id = 1', 392, "Role-Process Matrix (Org 1)"),
                ('process_competency_matrix', 448, "Process-Competency Matrix (Global)"),
                ('role_competency_matrix WHERE organization_id = 1', 224, "Role-Competency Matrix (Org 1)"),
            ]

            all_passed = True
            print("\nData Integrity Checks:")
            print("-" * 80)

            for table, expected_min, description in checks:
                count = db.session.execute(text(f'SELECT COUNT(*) FROM {table};')).scalar()

                if count >= expected_min:
                    print(f"[OK] {description:50s} {count:4d} entries (expected >= {expected_min})")
                else:
                    print(f"[FAIL] {description:50s} {count:4d} entries (expected >= {expected_min})")
                    all_passed = False

            print("-" * 80)

            if all_passed:
                print("\n[SUCCESS] All data integrity checks passed!")
                return True
            else:
                print("\n[WARNING] Some checks failed. Data may be incomplete.")
                return False

    except Exception as e:
        print(f"\n[ERROR] Verification failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def create_stored_procedures():
    """Create PostgreSQL stored procedures"""
    print("\nCreating stored procedures...")

    # Check if create_stored_procedures.py exists
    script_path = os.path.join(os.path.dirname(__file__), 'create_stored_procedures.py')
    if os.path.exists(script_path):
        return run_script('create_stored_procedures.py', 'Create PostgreSQL stored procedures')
    else:
        print("[SKIP] create_stored_procedures.py not found")
        print("Stored procedures may need to be created manually")
        return True  # Don't fail the whole process

def calculate_org1_role_competency():
    """Calculate role-competency matrix for organization 1"""
    print("\nCalculating role-competency matrix for Organization 1...")

    try:
        from app import create_app
        from models import db

        app = create_app()
        with app.app_context():
            # Call the stored procedure to calculate role-competency matrix
            db.session.execute(
                text('CALL update_role_competency_matrix(:org_id);'),
                {'org_id': 1}
            )
            db.session.commit()

            # Verify it worked
            count = db.session.execute(
                text('SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 1;')
            ).scalar()

            print(f"[OK] Calculated {count} role-competency entries for Organization 1")
            return True

    except Exception as e:
        print(f"[ERROR] Failed to calculate role-competency matrix: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main initialization process"""
    print_header("SE-QPT MASTER DATA INITIALIZATION")

    print("\nThis script will populate ALL required data for SE-QPT:")
    print("  1. ISO/IEC 15288 Processes (28 entries)")
    print("  2. SE Competencies based on INCOSE framework (16 entries)")
    print("  3. SE Role Clusters (14 entries)")
    print("  4. Role-Process Matrix for Organization 1 (392 entries - TEMPLATE)")
    print("  5. Process-Competency Matrix (448 entries - GLOBAL)")
    print("  6. PostgreSQL Stored Procedures")
    print("  7. Role-Competency Matrix for Organization 1 (calculated)")
    print("\nIMPORTANT: Organization 1 serves as the TEMPLATE for all new organizations!")
    print("           If you skip this, new organizations will have EMPTY matrices!")

    # Check if database is accessible
    print("\nChecking database connection...")
    try:
        from app import create_app
        from models import db

        app = create_app()
        with app.app_context():
            db.session.execute(text('SELECT 1;'))
        print("[OK] Database connection successful")
    except Exception as e:
        print(f"[ERROR] Cannot connect to database: {e}")
        print("\nPlease ensure:")
        print("  1. PostgreSQL is running")
        print("  2. Database 'competency_assessment' exists")
        print("  3. User 'ma0349' has access")
        print("  4. DATABASE_URL environment variable is set")
        return False

    response = input("\nContinue with data initialization? (yes/no): ")
    if response.lower() != 'yes':
        print("Aborted by user.")
        return False

    # Define initialization steps
    steps = [
        {
            'script': 'populate_iso_processes.py',
            'description': 'Populate ISO/IEC 15288 Processes (28 entries)',
            'required': True
        },
        {
            'script': 'populate_competencies.py',
            'description': 'Populate SE Competencies (16 entries)',
            'required': True
        },
        {
            'script': 'populate_roles_and_matrices.py',
            'description': 'Populate Roles + Role-Process Matrix for Org 1 (14 + 392 entries)',
            'required': True
        },
        {
            'script': 'populate_process_competency_matrix.py',
            'description': 'Populate Process-Competency Matrix - GLOBAL (448 entries)',
            'required': True
        },
    ]

    total_steps = len(steps) + 3  # +3 for stored procedures, calculation, verification
    failed_steps = []

    # Run each populate script
    for i, step in enumerate(steps, 1):
        print_step(i, total_steps, step['description'])

        if not run_script(step['script'], step['description']):
            if step['required']:
                print(f"\n[CRITICAL] Required step failed: {step['script']}")
                failed_steps.append(step['script'])

                response = input("\nContinue despite error? (yes/no): ")
                if response.lower() != 'yes':
                    print("Initialization aborted.")
                    return False
            else:
                print(f"[WARNING] Optional step failed: {step['script']}")

    # Create stored procedures
    print_step(len(steps) + 1, total_steps, "Create PostgreSQL Stored Procedures")
    if not create_stored_procedures():
        print("[WARNING] Stored procedures creation had issues, but continuing...")

    # Calculate role-competency matrix for org 1
    print_step(len(steps) + 2, total_steps, "Calculate Role-Competency Matrix for Organization 1")
    if not calculate_org1_role_competency():
        print("[ERROR] Failed to calculate role-competency matrix!")
        failed_steps.append('calculate_role_competency')

    # Verify all data
    verification_passed = verify_data()

    # Final summary
    print_header("INITIALIZATION SUMMARY")

    if failed_steps:
        print("\n[WARNING] Some steps failed:")
        for step in failed_steps:
            print(f"  - {step}")
        print("\nPlease review errors above and fix manually if needed.")

    if verification_passed and not failed_steps:
        print("\n[SUCCESS] All data initialized successfully!")
        print("\nYour SE-QPT database is ready!")
        print("\nNext steps:")
        print("  1. Start the backend server:")
        print("     cd src/backend")
        print("     python run.py")
        print("\n  2. Start the frontend:")
        print("     cd src/frontend")
        print("     npm run dev")
        print("\n  3. Register your first organization")
        print("     Organization 1 will serve as the template for future organizations")
        return True
    elif verification_passed:
        print("\n[PARTIAL SUCCESS] Data verification passed, but some steps had errors.")
        print("System should work, but please review warnings above.")
        return True
    else:
        print("\n[FAILED] Initialization incomplete. Please fix errors and run again.")
        return False

if __name__ == '__main__':
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nInitialization interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n[FATAL ERROR] Unexpected error during initialization:")
        import traceback
        traceback.print_exc()
        sys.exit(1)
