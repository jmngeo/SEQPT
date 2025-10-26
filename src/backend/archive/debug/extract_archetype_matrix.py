"""
Extract Archetype-Competency Matrix from Excel using Derik's exact competency names
Maps Marcel's qualification archetypes to Derik's 16 competencies from database
"""

import pandas as pd
import psycopg2
import json
import os
from pathlib import Path

# Derik's database connection
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'competency_assessment',
    'user': 'ma0349',
    'password': 'MA0349_2025'
}

# Excel file path
EXCEL_FILE = Path(__file__).parent.parent.parent / 'data' / 'source' / 'excel' / 'Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx'

def get_derik_competencies():
    """Get Derik's exact competency names and IDs from database"""
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, competency_name, competency_area
        FROM competency
        ORDER BY id
    """)

    competencies = {}
    for row in cursor.fetchall():
        comp_id, comp_name, comp_area = row
        competencies[comp_id] = {
            'id': comp_id,
            'name': comp_name,
            'area': comp_area
        }

    cursor.close()
    conn.close()

    return competencies

def map_excel_to_derik_competencies():
    """
    Map Excel competency names to Derik's exact names

    Excel (Your translation) → Derik's database names
    """
    mapping = {
        # Core Competencies
        'Systemic thinking': 'Systems Thinking',
        'System modeling and analysis': 'Systems Modeling and Analysis',
        'Consideration of system life cycle phases': 'Lifecycle Consideration',
        'Customer benefit orientation': 'Customer / Value Orientation',

        # Professional/Technical Competencies
        'Requirements management': 'Requirements Definition',
        'System architecture design': 'System Architecting',
        'Implementation and integration': 'Integration, Verification,  Validation',  # Note the double space in Derik's DB
        'System validation and verification': 'Integration, Verification,  Validation',
        'Interface management': 'Configuration Management',
        'Consideration of dependencies and risks': 'Project Management',

        # Social/Personal Competencies
        'Communication and cooperation': 'Communication',
        'Conflict management': 'Leadership',
        'Decision-making competence': 'Decision Management',

        # Management Competencies
        'Systems leadership': 'Leadership',
        'Systems engineering management': 'Information Management',
        'Resource and project management': 'Project Management',

        # Additional mappings
        'Self-Organization': 'Self-Organization',
        'Agile Methods': 'Agile Methods',
        'Operation and Support': 'Operation and Support'
    }

    return mapping

def extract_archetype_competency_matrix():
    """
    Extract archetype-competency matrix from Excel
    Returns: {archetype_name: {competency_id: target_level}}
    """

    print(f"[INFO] Reading Excel file: {EXCEL_FILE}")

    # Read the Excel file
    try:
        # Try different sheet names
        excel_data = pd.ExcelFile(EXCEL_FILE)
        print(f"   Available sheets: {excel_data.sheet_names}")

        # Look for sheet with qualification archetypes
        archetype_sheet = None
        possible_names = ['Qualification Archetypes', 'Qualifizierungspläne', 'Learning Objectives', 'Archetypes']

        for sheet_name in excel_data.sheet_names:
            if any(name.lower() in sheet_name.lower() for name in possible_names):
                archetype_sheet = sheet_name
                print(f"   Found archetype sheet: {archetype_sheet}")
                break

        if not archetype_sheet:
            # Default to reading the 4th sheet (Role-Competences-Matrix mentioned in README)
            archetype_sheet = excel_data.sheet_names[3] if len(excel_data.sheet_names) > 3 else excel_data.sheet_names[0]
            print(f"   Using sheet: {archetype_sheet}")

        df = pd.read_excel(EXCEL_FILE, sheet_name=archetype_sheet)
        print(f"   Shape: {df.shape}")
        print(f"   Columns: {list(df.columns)[:10]}")  # Show first 10 columns

    except Exception as e:
        print(f"[ERROR] Error reading Excel: {e}")
        return None

    # Get Derik's competencies from database
    print("\n[DB] Fetching Derik's competency names from database...")
    derik_competencies = get_derik_competencies()
    print(f"   Found {len(derik_competencies)} competencies")
    for comp_id, comp_data in derik_competencies.items():
        print(f"   {comp_id}: {comp_data['name']} ({comp_data['area']})")

    # Get mapping
    excel_to_derik = map_excel_to_derik_competencies()

    # Create reverse lookup: Derik name → Derik ID
    derik_name_to_id = {comp_data['name']: comp_id for comp_id, comp_data in derik_competencies.items()}

    # Define the 6 qualification archetypes
    archetypes = [
        'Common Basic Understanding',
        'SE for Managers',
        'Orientation in Pilot Project',
        'Needs-Based, Project-Oriented Training',
        'Continuous Support',
        'Train the Trainer'
    ]

    # Initialize archetype matrix
    archetype_matrix = {}

    # Parse the Excel data
    # Expected structure: Rows = Competencies, Columns = Archetypes
    # We need to identify which columns correspond to which archetype

    print("\n[ANALYZE] Analyzing Excel structure...")
    print(f"   First few rows:\n{df.head()}")

    # Build the matrix
    # For now, return a template structure that can be filled manually
    # This will be populated based on the actual Excel structure

    for archetype in archetypes:
        archetype_matrix[archetype] = {}
        # Initialize all competencies to level 0
        for comp_id in derik_competencies.keys():
            archetype_matrix[archetype][comp_id] = 0

    # Save to JSON for easy loading
    output_file = Path(__file__).parent.parent.parent / 'data' / 'processed' / 'archetype_competency_matrix.json'
    output_file.parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({
            'archetypes': archetype_matrix,
            'competency_names': {comp_id: comp_data['name'] for comp_id, comp_data in derik_competencies.items()},
            'metadata': {
                'source': 'Derik competency_assessment database + Marcel Excel file',
                'date_extracted': pd.Timestamp.now().isoformat(),
                'note': 'Competency IDs and names from Derik. Levels need to be mapped from Excel.'
            }
        }, f, indent=2, ensure_ascii=False)

    print(f"\n[SUCCESS] Template saved to: {output_file}")
    print(f"   Next step: Manually populate archetype levels from Excel data")

    return archetype_matrix

if __name__ == '__main__':
    print("=" * 80)
    print("ARCHETYPE-COMPETENCY MATRIX EXTRACTION")
    print("Using Derik's exact competency names from database")
    print("=" * 80)

    matrix = extract_archetype_competency_matrix()

    if matrix:
        print("\n[SUCCESS] Extraction complete!")
        print("\n[STRUCTURE] Archetype Matrix Structure:")
        for archetype, competencies in matrix.items():
            print(f"   {archetype}: {len(competencies)} competencies")
