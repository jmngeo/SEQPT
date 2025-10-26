"""
Populate ISO/IEC 15288 Process Data
Creates minimal but functional ISO process data for Phase 1 task-based role identification
"""

import os
import sys

# Set database URL before importing app
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db, IsoSystemLifeCycleProcesses, IsoProcesses

def populate_iso_data():
    """Populate ISO/IEC 15288 process data"""
    app = create_app()

    with app.app_context():
        print("[INFO] Populating ISO/IEC 15288 process data...")
        print()

        # Check if data already exists
        existing_count = IsoSystemLifeCycleProcesses.query.count()
        if existing_count > 0:
            print(f"[WARNING] Found {existing_count} existing lifecycle processes.")
            response = input("Do you want to clear and repopulate? (yes/no): ")
            if response.lower() != 'yes':
                print("[INFO] Skipping population.")
                return 0

            # Clear existing data
            print("[INFO] Clearing existing data...")
            IsoProcesses.query.delete()
            IsoSystemLifeCycleProcesses.query.delete()
            db.session.commit()
            print("[OK] Existing data cleared.")
            print()

        # Create ISO/IEC 15288 System Life Cycle Process Groups
        lifecycle_processes = [
            {'id': 1, 'name': 'Agreement Processes'},
            {'id': 2, 'name': 'Organizational Project-Enabling Processes'},
            {'id': 3, 'name': 'Technical Management Processes'},
            {'id': 4, 'name': 'Technical Processes'}
        ]

        print("[INFO] Creating lifecycle process groups...")
        for lc_data in lifecycle_processes:
            lc = IsoSystemLifeCycleProcesses(
                id=lc_data['id'],
                name=lc_data['name']
            )
            db.session.add(lc)
            print(f"[OK] {lc_data['name']}")

        db.session.commit()
        print()

        # Create ISO/IEC 15288 Processes
        # These are the key processes referenced in the code
        processes = [
            # Agreement Processes (lifecycle 1)
            {'id': 1, 'name': 'Acquisition', 'life_cycle_process_id': 1,
             'description': 'Acquire products or services'},
            {'id': 2, 'name': 'Supply', 'life_cycle_process_id': 1,
             'description': 'Provide products or services'},

            # Organizational Processes (lifecycle 2)
            {'id': 3, 'name': 'Life Cycle Model Management', 'life_cycle_process_id': 2,
             'description': 'Define and manage life cycle models'},
            {'id': 4, 'name': 'Infrastructure Management', 'life_cycle_process_id': 2,
             'description': 'Provide infrastructure for projects'},
            {'id': 5, 'name': 'Portfolio Management', 'life_cycle_process_id': 2,
             'description': 'Manage organizational portfolio'},
            {'id': 6, 'name': 'Human Resource Management', 'life_cycle_process_id': 2,
             'description': 'Provide qualified human resources'},
            {'id': 7, 'name': 'Quality Management', 'life_cycle_process_id': 2,
             'description': 'Ensure quality objectives are achieved'},

            # Technical Management Processes (lifecycle 3)
            {'id': 8, 'name': 'Project Planning', 'life_cycle_process_id': 3,
             'description': 'Plan and schedule project activities'},
            {'id': 9, 'name': 'Project Assessment and Control', 'life_cycle_process_id': 3,
             'description': 'Assess and control project progress'},
            {'id': 10, 'name': 'Decision Management', 'life_cycle_process_id': 3,
             'description': 'Make informed decisions'},
            {'id': 11, 'name': 'Risk Management', 'life_cycle_process_id': 3,
             'description': 'Identify and manage risks'},
            {'id': 12, 'name': 'Configuration Management', 'life_cycle_process_id': 3,
             'description': 'Manage system configurations'},
            {'id': 13, 'name': 'Information Management', 'life_cycle_process_id': 3,
             'description': 'Manage project information'},
            {'id': 14, 'name': 'Measurement', 'life_cycle_process_id': 3,
             'description': 'Measure products and processes'},

            # Technical Processes (lifecycle 4) - MOST IMPORTANT FOR TASK MAPPING
            {'id': 15, 'name': 'Business or Mission Analysis', 'life_cycle_process_id': 4,
             'description': 'Define business or mission problem/opportunity'},
            {'id': 16, 'name': 'Stakeholder Needs and Requirements Definition', 'life_cycle_process_id': 4,
             'description': 'Define stakeholder requirements'},
            {'id': 17, 'name': 'System Requirements Definition', 'life_cycle_process_id': 4,
             'description': 'Transform stakeholder requirements into technical requirements'},
            {'id': 18, 'name': 'System Architecture Definition', 'life_cycle_process_id': 4,
             'description': 'Define system architecture and design'},
            {'id': 19, 'name': 'Design Definition', 'life_cycle_process_id': 4,
             'description': 'Create detailed system design'},
            {'id': 20, 'name': 'System Analysis', 'life_cycle_process_id': 4,
             'description': 'Analyze system to support decisions'},
            {'id': 21, 'name': 'Implementation', 'life_cycle_process_id': 4,
             'description': 'Realize system elements'},
            {'id': 22, 'name': 'Integration', 'life_cycle_process_id': 4,
             'description': 'Combine system elements into complete system'},
            {'id': 23, 'name': 'Verification', 'life_cycle_process_id': 4,
             'description': 'Confirm requirements are fulfilled'},
            {'id': 24, 'name': 'Transition', 'life_cycle_process_id': 4,
             'description': 'Establish capability to provide services'},
            {'id': 25, 'name': 'Validation', 'life_cycle_process_id': 4,
             'description': 'Confirm system fulfills intended use'},
            {'id': 26, 'name': 'Operation', 'life_cycle_process_id': 4,
             'description': 'Use system to deliver services'},
            {'id': 27, 'name': 'Maintenance', 'life_cycle_process_id': 4,
             'description': 'Sustain system capability'},
            {'id': 28, 'name': 'Disposal', 'life_cycle_process_id': 4,
             'description': 'End system existence'}
        ]

        print("[INFO] Creating ISO/IEC 15288 processes...")
        for proc_data in processes:
            proc = IsoProcesses(
                id=proc_data['id'],
                name=proc_data['name'],
                description=proc_data['description'],
                life_cycle_process_id=proc_data['life_cycle_process_id']
            )
            db.session.add(proc)
            print(f"[OK] [{proc_data['id']:2d}] {proc_data['name']}")

        db.session.commit()
        print()
        print(f"[SUCCESS] Created {len(lifecycle_processes)} lifecycle process groups")
        print(f"[SUCCESS] Created {len(processes)} ISO/IEC 15288 processes")
        print()
        print("[INFO] ISO process data population complete!")
        return 0

if __name__ == '__main__':
    sys.exit(populate_iso_data())
