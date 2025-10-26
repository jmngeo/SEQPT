"""
Populate process_competency_matrix from Derik's data
This table is essential for calculating competency requirements from process involvement
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("POPULATING PROCESS_COMPETENCY_MATRIX")
    print("=" * 80)

    # Check if table already has data
    count = db.session.execute(text('SELECT COUNT(*) FROM process_competency_matrix;')).scalar()
    if count > 0:
        print(f"\nWARNING: Table already has {count} rows")
        response = input("Do you want to delete existing data and repopulate? (yes/no): ")
        if response.lower() != 'yes':
            print("Aborted.")
            exit()

        print("Deleting existing data...")
        db.session.execute(text('TRUNCATE TABLE process_competency_matrix RESTART IDENTITY CASCADE;'))
        db.session.commit()
        print("Existing data deleted.")

    # Read data from Derik's init file
    derik_sql_file = r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\sesurveyapp-main\postgres-init\filtered_init.sql'

    print(f"\nReading data from: {derik_sql_file}")

    # Extract the COPY block for process_competency_matrix
    with open(derik_sql_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Find the start and end of the COPY block
    start_idx = None
    end_idx = None

    for i, line in enumerate(lines):
        if 'COPY public.process_competency_matrix' in line:
            start_idx = i + 1  # Data starts on next line
        elif start_idx and line.strip() == '\\.':
            end_idx = i
            break

    if not start_idx or not end_idx:
        print("ERROR: Could not find process_competency_matrix data in file")
        exit(1)

    print(f"Found data block: lines {start_idx+1} to {end_idx}")

    # Extract and parse data
    data_lines = lines[start_idx:end_idx]
    rows_to_insert = []

    for line in data_lines:
        line = line.strip()
        if not line:
            continue

        parts = line.split('\t')
        if len(parts) == 4:
            id_val, iso_process_id, competency_id, process_competency_value = parts
            rows_to_insert.append((
                int(id_val),
                int(iso_process_id),
                int(competency_id),
                int(process_competency_value)
            ))

    print(f"\nParsed {len(rows_to_insert)} rows")

    # Insert data in batches
    print("Inserting data...")
    batch_size = 100
    for i in range(0, len(rows_to_insert), batch_size):
        batch = rows_to_insert[i:i+batch_size]

        # Build INSERT statement
        values_str = ','.join([
            f"({row[0]}, {row[1]}, {row[2]}, {row[3]})"
            for row in batch
        ])

        insert_sql = f"""
            INSERT INTO process_competency_matrix
            (id, iso_process_id, competency_id, process_competency_value)
            VALUES {values_str};
        """

        db.session.execute(text(insert_sql))
        print(f"  Inserted rows {i+1} to {min(i+batch_size, len(rows_to_insert))}")

    db.session.commit()

    # Verify
    final_count = db.session.execute(text('SELECT COUNT(*) FROM process_competency_matrix;')).scalar()
    print(f"\n[SUCCESS] process_competency_matrix now has {final_count} rows")

    # Show sample data
    sample = db.session.execute(text("""
        SELECT iso_process_id, competency_id, process_competency_value
        FROM process_competency_matrix
        ORDER BY iso_process_id, competency_id
        LIMIT 10;
    """)).fetchall()

    print("\nSample data:")
    print("  iso_process_id | competency_id | process_competency_value")
    print("  " + "-" * 60)
    for row in sample:
        print(f"  {row[0]:14} | {row[1]:13} | {row[2]:24}")

    print("\n" + "=" * 80)
    print("PROCESS_COMPETENCY_MATRIX POPULATED SUCCESSFULLY")
    print("=" * 80)
    print("\nNext steps:")
    print("  1. Run /findProcesses again to populate UnknownRoleProcessMatrix")
    print("  2. Stored procedure will now calculate competencies correctly")
    print("  3. Test /api/phase1/roles/suggest-from-processes for role matching")
