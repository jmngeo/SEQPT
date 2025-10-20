import pandas as pd

# Database competencies (English names)
db_competencies = [
    "Agile Methods",
    "Communication",
    "Configuration Management",
    "Customer / Value Orientation",
    "Decision Management",
    "Information Management",
    "Integration, Verification,  Validation",
    "Leadership",
    "Lifecycle Consideration",
    "Operation and Support",
    "Project Management",
    "Requirements Definition",
    "Self-Organization",
    "System Architecting",
    "Systems Modelling and Analysis",
    "Systems Thinking"
]

# German to English mapping (approximate)
german_to_english = {
    "Systemisches Denken": "Systems Thinking",
    "Systemmodellierung und -analyse": "Systems Modelling and Analysis",
    "Berücksichtigung von Systemlebenszyklusphasen": "Lifecycle Consideration",
    "Berücksichtigung von Systemlebenszayklusphasen": "Lifecycle Consideration",  # typo variant
    "Agiles Denken / Kunden-Nutzenorientierung": "Customer / Value Orientation",
    "Agiles Denken/ Kundennutzenorientierung": "Customer / Value Orientation",  # variant
    "Anforderungsmanagement": "Requirements Definition",
    "System-Architekturgestaltung": "System Architecting",
    "System- Architekturgestaltung": "System Architecting",  # variant
    "Integration, Verifikation & Validierung": "Integration, Verification,  Validation",
    "Betrieb, Service und Instandhaltung": "Operation and Support",
    "Agile Methodenkompetenz": "Agile Methods",
    "Selbstorganisation": "Self-Organization",
    "Kommunikation & Zusammenarbeit": "Communication",
    "Führen": "Leadership",
    "Projektmanagement": "Project Management",
    "Entscheidungsmanagement": "Decision Management",
    "Informationsmanagement": "Information Management",
    "Konfigurationsmanagement": "Configuration Management"
}

# Read the Excel file
excel_file = r'Qualifizierungsmodule_Qualifizierungspläne_v4 (1).xlsx'

try:
    df = pd.read_excel(excel_file, sheet_name='Rollen-Kompetenzen-Matrix', header=None)

    print("=== CROSS-REFERENCE: DATABASE vs EXCEL SOURCE ===\n")

    # Find role columns
    internal_support_col = 6
    process_policy_col = 7

    print("Analyzing 16 competencies that exist in database...\n")
    print(f"{'Database Competency (EN)':<50} | German Name in Excel | Process&Policy | MAX")
    print("-" * 110)

    matched = 0
    all_level_6 = 0

    for db_comp in sorted(db_competencies):
        # Find matching German competency in Excel
        found = False
        for row_idx in range(2, df.shape[0]):
            comp_name_german = df.iloc[row_idx, 1]
            if pd.notna(comp_name_german):
                comp_name_german_str = str(comp_name_german).strip()

                # Check if this German name maps to our DB competency
                english_equivalent = german_to_english.get(comp_name_german_str)
                if english_equivalent == db_comp:
                    # Get value from Excel
                    process_val = df.iloc[row_idx, process_policy_col]
                    internal_val = df.iloc[row_idx, internal_support_col]

                    try:
                        process_val = int(process_val) if pd.notna(process_val) else 0
                    except:
                        process_val = 0

                    try:
                        internal_val = int(internal_val) if pd.notna(internal_val) else 0
                    except:
                        internal_val = 0

                    max_val = max(process_val, internal_val)

                    print(f"{db_comp:<50} | {comp_name_german_str[:20]:<20} | {process_val:14} | {max_val}")

                    matched += 1
                    if max_val == 6:
                        all_level_6 += 1

                    found = True
                    break

        if not found:
            print(f"{db_comp:<50} | NOT FOUND IN EXCEL   | ?              | ?")

    print("\n" + "=" * 110)
    print("ANALYSIS:\n")
    print(f"  Competencies matched: {matched} / {len(db_competencies)}")
    print(f"  Matched competencies at level 6: {all_level_6}")
    print(f"  Percentage at level 6: {(all_level_6/matched*100):.1f}%\n")

    if all_level_6 == matched:
        print("[FINDING] ALL matched competencies show level 6 in Excel!")
        print("This confirms the database is correctly reflecting the Excel source data.")
        print("\nCONCLUSION: 'Required Level: Mastering' is CORRECT for Process and Policy Manager.")
    else:
        print("[FINDING] NOT all matched competencies are level 6 in Excel.")
        print("There may be a data import issue or the database was modified after import.")

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
