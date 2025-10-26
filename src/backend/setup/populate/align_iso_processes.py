"""
Align our iso_processes table with Derik's exact structure (30 processes)
This ensures process_competency_matrix foreign keys will work correctly
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

# Derik's complete list of 30 processes (from lines 2474-2503 of init.sql)
DERIK_PROCESSES = [
    (1, "acquisition process", 1),
    (2, "supply process", 1),
    (3, "Life cycle model management process", 2),
    (4, "Infrastructure management process", 2),
    (5, "Portfolio management process", 2),
    (6, "Human resource management process", 2),
    (7, "Quality management process", 2),
    (8, "Knowledge management process", 2),  # MISSING IN OUR DB
    (9, "Project planning process", 3),
    (10, "Project assessment and control process", 3),
    (11, "Decision management process", 3),
    (12, "Risk management process", 3),
    (13, "Configuration management process", 3),
    (14, "Information management process", 3),
    (15, "Measurement process", 3),
    (16, "Quality assurance process", 3),  # MISSING IN OUR DB
    (17, "Business or mission analysis process", 4),
    (18, "Stakeholder needs and requirements definition process", 4),
    (19, "System requirements definition process", 4),
    (20, "System architecture definition process", 4),
    (21, "Design definition process", 4),
    (22, "System analysis process", 4),
    (23, "Implementation process", 4),
    (24, "Integration process", 4),
    (25, "Verification process", 4),
    (26, "Transition process", 4),
    (27, "Validation process", 4),  # WE HAVE THIS AS ID 25
    (28, "Operation process", 4),  # WE HAVE THIS AS ID 26
    (29, "Maintenance process", 4),  # WE HAVE THIS AS ID 27
    (30, "Disposal process", 4),  # WE HAVE THIS AS ID 28
]

with app.app_context():
    print("=" * 80)
    print("ALIGNING ISO_PROCESSES WITH DERIK'S STRUCTURE")
    print("=" * 80)

    # Check current state
    current = db.session.execute(text('SELECT id, name FROM iso_processes ORDER BY id;')).fetchall()
    print(f"\nCurrent: {len(current)} processes (IDs: {[r[0] for r in current]})")
    print(f"Target:  {len(DERIK_PROCESSES)} processes (IDs: 1-30)")

    # Find missing IDs
    current_ids = [r[0] for r in current]
    missing_ids = [p[0] for p in DERIK_PROCESSES if p[0] not in current_ids]
    print(f"\nMissing IDs: {missing_ids}")

    # Show what needs to be added
    print("\nProcesses to add:")
    for proc_id, name, life_cycle in DERIK_PROCESSES:
        if proc_id in missing_ids:
            print(f"  ID {proc_id}: {name}")

    print("\n" + "-" * 80)
    response = input("Proceed with adding missing processes? (yes/no): ")
    if response.lower() != 'yes':
        print("Aborted.")
        exit()

    # Add missing processes
    print("\nAdding missing processes...")
    for proc_id, name, life_cycle_id in DERIK_PROCESSES:
        if proc_id in missing_ids:
            db.session.execute(text("""
                INSERT INTO iso_processes (id, name, description, life_cycle_process_id)
                VALUES (:id, :name, '', :life_cycle_id)
            """), {'id': proc_id, 'name': name, 'life_cycle_id': life_cycle_id})
            print(f"  Added ID {proc_id}: {name}")

    db.session.commit()

    # Verify
    final = db.session.execute(text('SELECT COUNT(*) FROM iso_processes;')).scalar()
    print(f"\n[SUCCESS] iso_processes now has {final} processes")

    # Show final list
    all_procs = db.session.execute(text('SELECT id, name FROM iso_processes ORDER BY id;')).fetchall()
    print("\nFinal process list:")
    for r in all_procs:
        print(f"  {r[0]:2}: {r[1]}")

    print("\n" + "=" * 80)
    print("ISO_PROCESSES ALIGNED WITH DERIK'S STRUCTURE")
    print("=" * 80)
    print("\nNext step: Run populate_process_competency_matrix.py")
