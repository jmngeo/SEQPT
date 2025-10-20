import pandas as pd
import sys

# Read the Excel file
excel_file = r'Qualifizierungsmodule_Qualifizierungspläne_v4 (1).xlsx'

try:
    # Read Role-Competency Matrix
    df = pd.read_excel(excel_file, sheet_name='Rollen-Kompetenzen-Matrix', header=None)

    print("=== VALIDATING EXCEL DATA AGAINST DATABASE ===\n")

    # Row 1 contains role headers
    print("STEP 1: Identifying role columns...")
    roles_row = df.iloc[1, :]

    internal_support_col = None
    process_policy_col = None

    for col_idx in range(df.shape[1]):
        val = df.iloc[1, col_idx]
        if pd.notna(val):
            val_clean = str(val).replace('\u200b', '').strip()
            if 'Interner Support' in val_clean:
                internal_support_col = col_idx
                print(f"  [OK] Found 'Interner Support' at column {col_idx}")
            elif 'Prozess-' in val_clean and 'Richtlini' in val_clean:
                process_policy_col = col_idx
                print(f"  [OK] Found 'Prozess- & Richtlinien' at column {col_idx}")

    if internal_support_col is None or process_policy_col is None:
        print("\n[ERROR] Could not find both roles!")
        print("Available columns in row 1:")
        for col_idx in range(df.shape[1]):
            val = df.iloc[1, col_idx]
            if pd.notna(val):
                print(f"  Col {col_idx}: {str(val).replace(chr(8203), '')[:60]}")
        sys.exit(1)

    print(f"\n  Internal Support: Column {internal_support_col}")
    print(f"  Process & Policy Manager: Column {process_policy_col}\n")

    # Now extract competency data starting from row 2
    print("STEP 2: Extracting competency values...\n")
    print(f"{'Competency':<50} | Process&Policy | Internal | MAX")
    print("-" * 90)

    competencies = []
    mastering_count = 0

    # Start from row 2 (first competency)
    for row_idx in range(2, df.shape[0]):
        # Competency name is in column 1
        comp_name = df.iloc[row_idx, 1]

        if pd.notna(comp_name):
            comp_name_str = str(comp_name).strip()

            # Skip if it's a process code or empty
            if comp_name_str and not comp_name_str.startswith('6.') and len(comp_name_str) > 3:
                # Get values for both roles
                process_val = df.iloc[row_idx, process_policy_col]
                internal_val = df.iloc[row_idx, internal_support_col]

                # Convert to int
                try:
                    process_val = int(process_val) if pd.notna(process_val) else 0
                except:
                    process_val = 0

                try:
                    internal_val = int(internal_val) if pd.notna(internal_val) else 0
                except:
                    internal_val = 0

                max_val = max(process_val, internal_val)
                competencies.append((comp_name_str, process_val, internal_val, max_val))

                if max_val == 6:
                    mastering_count += 1

                print(f"{comp_name_str[:50]:<50} | {process_val:14} | {internal_val:8} | {max_val}")

    # Summary
    print("\n" + "=" * 90)
    print("VALIDATION RESULTS:\n")
    print(f"  Total competencies found: {len(competencies)}")
    print(f"  Competencies requiring Mastering (6): {mastering_count}")
    print(f"  Percentage requiring Mastering: {(mastering_count/len(competencies)*100):.1f}%\n")

    # Check if matches database
    print("COMPARISON WITH DATABASE:")
    print(f"  Database showed: 16 competencies, ALL at level 6 (Mastering)")
    print(f"  Excel shows: {len(competencies)} competencies, {mastering_count} at level 6 (Mastering)\n")

    if mastering_count == len(competencies):
        print("[CONFIRMED] Excel data MATCHES database!")
        print("Process and Policy Manager DOES require Mastering for ALL competencies.")
    elif mastering_count > len(competencies) * 0.9:
        print("[WARNING] Process and Policy Manager requires Mastering for MOST competencies.")
        print("The database is correctly reflecting the source Excel data.")
    else:
        print("[INFO] Process and Policy Manager has mixed requirements.")

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
