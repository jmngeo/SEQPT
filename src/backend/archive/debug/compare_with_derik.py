"""
Compare our role_competency_matrix with Derik's to identify discrepancies
"""
from app import create_app, db
from sqlalchemy import text
import psycopg2

def get_our_data():
    """Get our role_competency_matrix data"""
    app = create_app()
    with app.app_context():
        result = db.session.execute(text(
            """SELECT role_cluster_id, competency_id, role_competency_value
               FROM role_competency_matrix
               WHERE organization_id = 1
               ORDER BY role_cluster_id, competency_id"""
        ))
        return {(r[0], r[1]): r[2] for r in result.fetchall()}

def get_derik_data():
    """Get Derik's role_competency_matrix data"""
    # Connect to Derik's database
    conn = psycopg2.connect(
        host="localhost",
        database="sesurveyappdb",
        user="adminderik",
        password="rootadmin"
    )
    cursor = conn.cursor()

    cursor.execute("""
        SELECT role_cluster_id, competency_id, role_competency_value
        FROM role_competency_matrix
        WHERE organization_id = 1
        ORDER BY role_cluster_id, competency_id
    """)

    derik_data = {(r[0], r[1]): r[2] for r in cursor.fetchall()}

    cursor.close()
    conn.close()

    return derik_data

def main():
    print("="*80)
    print("COMPARING OUR DATA WITH DERIK'S")
    print("="*80)

    our_data = get_our_data()
    print(f"\nOur data: {len(our_data)} entries")

    try:
        derik_data = get_derik_data()
        print(f"Derik's data: {len(derik_data)} entries")

        # Find discrepancies
        print("\n" + "="*80)
        print("DISCREPANCIES")
        print("="*80)

        all_keys = set(our_data.keys()) | set(derik_data.keys())

        discrepancies = 0
        missing_in_ours = 0
        missing_in_deriks = 0

        for key in sorted(all_keys):
            role_id, comp_id = key
            our_val = our_data.get(key, None)
            derik_val = derik_data.get(key, None)

            if our_val is None:
                print(f"MISSING IN OURS: Role {role_id:2d}, Comp {comp_id:2d} = {derik_val} (Derik's)")
                missing_in_ours += 1
            elif derik_val is None:
                print(f"MISSING IN DERIK: Role {role_id:2d}, Comp {comp_id:2d} = {our_val} (Ours)")
                missing_in_deriks += 1
            elif our_val != derik_val:
                print(f"DIFFERENT: Role {role_id:2d}, Comp {comp_id:2d}: Ours={our_val}, Derik={derik_val}")
                discrepancies += 1

        print(f"\n{'Total discrepancies:':<30} {discrepancies}")
        print(f"{'Missing in ours:':<30} {missing_in_ours}")
        print(f"{'Missing in Deriks:':<30} {missing_in_deriks}")
        print(f"{'Total issues:':<30} {discrepancies + missing_in_ours + missing_in_deriks}")

        # Show specific role examples
        print("\n" + "="*80)
        print("EXAMPLE: Role 11 (Process and Policy Manager)")
        print("="*80)

        print("\nOur values:")
        for comp_id in sorted(set(c for r, c in our_data.keys() if r == 11)):
            val = our_data.get((11, comp_id), "MISSING")
            print(f"  Comp {comp_id:2d}: {val}")

        print("\nDerik's values:")
        for comp_id in sorted(set(c for r, c in derik_data.keys() if r == 11)):
            val = derik_data.get((11, comp_id), "MISSING")
            print(f"  Comp {comp_id:2d}: {val}")

    except Exception as e:
        print(f"\nERROR connecting to Derik's database: {e}")
        print("This is expected if Derik's database is not accessible")
        print("\nWill analyze from Derik's init.sql file instead...")

        # Parse from init.sql
        print("\n" + "="*80)
        print("ANALYZING DERIK'S init.sql")
        print("="*80)

        import re
        with open("C:\\Users\\jomon\\Documents\\MyDocuments\\Development\\Thesis\\sesurveyapp-main\\postgres-init\\init.sql", "r", encoding="utf-8") as f:
            content = f.read()

        # Find the COPY section for role_competency_matrix
        pattern = r"COPY public\.role_competency_matrix.*?FROM stdin;(.*?)\\\."
        match = re.search(pattern, content, re.DOTALL)

        if match:
            lines = match.group(1).strip().split('\n')
            print(f"\nFound {len(lines)} entries in Derik's init.sql")

            derik_data_from_file = {}
            for line in lines:
                if line.strip():
                    parts = line.split('\t')
                    if len(parts) >= 5:
                        # Format: id, role_cluster_id, competency_id, role_competency_value, organization_id
                        role_id = int(parts[1])
                        comp_id = int(parts[2])
                        value = int(parts[3])
                        org_id = int(parts[4])

                        if org_id == 1:
                            derik_data_from_file[(role_id, comp_id)] = value

            print(f"Parsed {len(derik_data_from_file)} entries for organization_id=1")

            # Compare
            print("\n" + "="*80)
            print("COMPARISON WITH PARSED DATA")
            print("="*80)

            all_keys = set(our_data.keys()) | set(derik_data_from_file.keys())

            discrepancies = 0
            missing_in_ours = 0
            missing_in_deriks = 0

            for key in sorted(all_keys):
                role_id, comp_id = key
                our_val = our_data.get(key, None)
                derik_val = derik_data_from_file.get(key, None)

                if our_val is None:
                    print(f"MISSING IN OURS: Role {role_id:2d}, Comp {comp_id:2d} = {derik_val} (Derik's)")
                    missing_in_ours += 1
                elif derik_val is None:
                    print(f"MISSING IN DERIK: Role {role_id:2d}, Comp {comp_id:2d} = {our_val} (Ours)")
                    missing_in_deriks += 1
                elif our_val != derik_val:
                    print(f"DIFFERENT: Role {role_id:2d}, Comp {comp_id:2d}: Ours={our_val}, Derik={derik_val}")
                    discrepancies += 1

            print(f"\n{'Total discrepancies:':<30} {discrepancies}")
            print(f"{'Missing in ours:':<30} {missing_in_ours}")
            print(f"{'Missing in Deriks:':<30} {missing_in_deriks}")

            if discrepancies + missing_in_ours + missing_in_deriks == 0:
                print("\n[SUCCESS] Our data EXACTLY matches Derik's data!")
            else:
                print(f"\n[ISSUE] Total issues: {discrepancies + missing_in_ours + missing_in_deriks}")

if __name__ == "__main__":
    main()
