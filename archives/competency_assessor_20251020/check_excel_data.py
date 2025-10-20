import pandas as pd
import sys

# Read the Excel file
excel_file = r'Qualifizierungsmodule_Qualifizierungspläne_v4 (1).xlsx'

try:
    # Read Role-Competency Matrix
    df = pd.read_excel(excel_file, sheet_name='Rollen-Kompetenzen-Matrix', header=None)

    print("=== ROLE-COMPETENCY MATRIX ANALYSIS ===\n")
    print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns\n")

    # First row contains role names
    print("ROLES (First row):")
    roles = df.iloc[0, :].tolist()
    for i, role in enumerate(roles):
        if pd.notna(role):
            print(f"  Column {i}: {role}")

    # Find Process and Policy Manager and Internal Support columns
    process_policy_col = None
    internal_support_col = None

    for i, role in enumerate(roles):
        if pd.notna(role):
            role_str = str(role).lower()
            if 'prozess' in role_str and 'policy' in role_str:
                process_policy_col = i
                print(f"\n[OK] Found 'Process and Policy Manager' at column {i}: {role}")
            elif 'intern' in role_str and 'support' in role_str:
                internal_support_col = i
                print(f"[OK] Found 'Internal Support' at column {i}: {role}")

    if process_policy_col is None or internal_support_col is None:
        print("\n[ERROR] Could not find both roles!")
        print("\nSearching for similar names...")
        for i, role in enumerate(roles):
            if pd.notna(role):
                role_str = str(role).lower()
                if 'prozess' in role_str or 'policy' in role_str or 'intern' in role_str:
                    print(f"  Column {i}: {role}")
        sys.exit(1)

    # Extract competency values for both roles
    print("\n=== COMPETENCY VALUES ===\n")
    print(f"{'Competency Name':<50} | Process&Policy | Internal | MAX")
    print("-" * 90)

    # Start from row 1 (competencies start here)
    competencies = []
    for row_idx in range(1, df.shape[0]):
        comp_name = df.iloc[row_idx, 1]  # Competency name is usually in column 1
        if pd.notna(comp_name) and str(comp_name).strip() != '':
            process_val = df.iloc[row_idx, process_policy_col]
            internal_val = df.iloc[row_idx, internal_support_col]

            # Convert to int if numeric
            try:
                process_val = int(process_val) if pd.notna(process_val) else 0
            except:
                process_val = 0

            try:
                internal_val = int(internal_val) if pd.notna(internal_val) else 0
            except:
                internal_val = 0

            max_val = max(process_val, internal_val)
            competencies.append((comp_name, process_val, internal_val, max_val))

            print(f"{str(comp_name)[:50]:<50} | {process_val:14} | {internal_val:8} | {max_val}")

    # Summary
    print("\n" + "=" * 90)
    print("SUMMARY:")
    mastering_count = sum(1 for c in competencies if c[3] == 6)
    applying_count = sum(1 for c in competencies if c[3] == 4)
    understanding_count = sum(1 for c in competencies if c[3] == 2)
    aware_count = sum(1 for c in competencies if c[3] == 1)

    print(f"  Total competencies: {len(competencies)}")
    print(f"  Level 6 (Mastering): {mastering_count}")
    print(f"  Level 4 (Applying): {applying_count}")
    print(f"  Level 2 (Understanding): {understanding_count}")
    print(f"  Level 1 (Aware): {aware_count}")

    if mastering_count == len(competencies):
        print("\n[FINDING] ALL competencies require Mastering (Level 6)!")
        print("This matches what we see in the database.")

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
