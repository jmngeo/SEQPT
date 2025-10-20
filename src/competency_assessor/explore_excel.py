import pandas as pd

# Read the Excel file
excel_file = r'Qualifizierungsmodule_Qualifizierungspläne_v4 (1).xlsx'

try:
    # Read Role-Competency Matrix
    df = pd.read_excel(excel_file, sheet_name='Rollen-Kompetenzen-Matrix', header=None)

    print("=== EXPLORING EXCEL STRUCTURE ===\n")
    print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns\n")

    # Print first 15 rows to understand structure
    print("First 15 rows, first 8 columns:")
    print("=" * 120)
    for row_idx in range(min(15, df.shape[0])):
        row_data = []
        for col_idx in range(min(8, df.shape[1])):
            val = df.iloc[row_idx, col_idx]
            if pd.isna(val):
                row_data.append("NaN")
            else:
                val_str = str(val)[:20]  # Truncate long values
                row_data.append(val_str)
        print(f"Row {row_idx:2d}: {' | '.join(row_data)}")

    print("\n" + "=" * 120)
    print("\nLooking for role names in columns...")

    # Check all cells in first few rows for role names
    for row_idx in range(min(10, df.shape[0])):
        for col_idx in range(df.shape[1]):
            val = df.iloc[row_idx, col_idx]
            if pd.notna(val):
                val_str = str(val).lower()
                if any(keyword in val_str for keyword in ['prozess', 'policy', 'intern', 'support', 'manager', 'kunde']):
                    print(f"  Row {row_idx}, Col {col_idx}: {df.iloc[row_idx, col_idx]}")

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
