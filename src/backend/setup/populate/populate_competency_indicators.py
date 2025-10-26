"""
Parse Questionnaires.txt and populate competency_indicators table
"""

import re
from app import create_app
from models import db, Competency, CompetencyIndicator

def parse_questionnaires(file_path):
    """Parse the Questionnaires.txt file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by competency sections
    competency_sections = re.split(r'\n\n(?=\d+\. Competency Name)', content)

    competencies_data = []

    for section in competency_sections:
        if not section.strip() or 'Competency Name' not in section:
            continue

        lines = section.strip().split('\n')

        # Extract competency name
        name_match = re.search(r'Competency Name\s*:\s*(.+)', lines[0])
        if not name_match:
            continue

        competency_name = name_match.group(1).strip()

        # Extract indicators for each group/level
        indicators = {}
        current_group = None

        for line in lines:
            # Match group lines
            group_match = re.match(r'Group (\d+):\s*(.+)', line)
            if group_match:
                group_num = int(group_match.group(1))
                indicator_text = group_match.group(2).strip()

                # Only store Groups 1-4 (skip Group 5 which is "none of these")
                if group_num <= 4:
                    indicators[group_num] = indicator_text

        if indicators:
            competencies_data.append({
                'name': competency_name,
                'indicators': indicators
            })

    return competencies_data

def populate_database(competencies_data):
    """Populate the competency_indicators table"""
    app = create_app()
    with app.app_context():
        # Get all competencies from database
        all_competencies = Competency.query.all()
        competency_map = {comp.competency_name.strip().lower(): comp.id
                         for comp in all_competencies}

        print(f"[INFO] Found {len(all_competencies)} competencies in database")
        print(f"[INFO] Parsed {len(competencies_data)} competencies from file")

        indicators_added = 0

        for comp_data in competencies_data:
            comp_name = comp_data['name'].strip().lower()

            # Try exact match first
            comp_id = competency_map.get(comp_name)

            # Try partial matching if exact doesn't work
            if not comp_id:
                for db_name, db_id in competency_map.items():
                    if comp_name in db_name or db_name in comp_name:
                        comp_id = db_id
                        print(f"[INFO] Matched '{comp_data['name']}' to '{db_name}'")
                        break

            if not comp_id:
                print(f"[WARNING] Could not find competency ID for: {comp_data['name']}")
                continue

            # Add indicators for this competency
            for level, indicator_text in comp_data['indicators'].items():
                indicator = CompetencyIndicator(
                    competency_id=comp_id,
                    level=str(level),  # Store as '1', '2', '3', '4'
                    indicator_en=indicator_text,
                    indicator_de=None  # We don't have German translations in this file
                )
                db.session.add(indicator)
                indicators_added += 1

        db.session.commit()
        print(f"[SUCCESS] Added {indicators_added} competency indicators!")

        # Verify
        total = CompetencyIndicator.query.count()
        print(f"[INFO] Total indicators in database: {total}")

if __name__ == "__main__":
    questionnaires_path = r"C:\Users\jomon\Documents\MyDocuments\Development\Thesis\sesurveyapp\competency_questionnaire\Questionnaires.txt"

    print("[INFO] Parsing questionnaires file...")
    competencies_data = parse_questionnaires(questionnaires_path)

    print(f"[INFO] Parsed {len(competencies_data)} competencies")
    for comp in competencies_data:
        print(f"  - {comp['name']}: {len(comp['indicators'])} indicators")

    print("\n[INFO] Populating database...")
    populate_database(competencies_data)
