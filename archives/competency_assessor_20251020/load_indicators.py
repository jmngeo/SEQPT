"""
Script to load competency indicators from Questionnaires.txt into the database.
"""
from app import create_app, db
from app.models import CompetencyIndicator, Competency
import re

def parse_questionnaires_file(filepath):
    """
    Parse the Questionnaires.txt file and extract competency indicators.
    Returns a list of tuples: (competency_name, level, indicator_text)
    """
    indicators = []

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by competency (each starts with a number followed by period)
    competency_blocks = re.split(r'\n(?=\d+\.\s+Competency Name)', content)

    for block in competency_blocks:
        if not block.strip():
            continue

        # Extract competency name
        comp_match = re.search(r'Competency Name\s*:\s*(.+?)(?:\n|Definition)', block)
        if not comp_match:
            continue
        competency_name = comp_match.group(1).strip()

        # Extract indicators for each group/level
        # Groups 1-4 are the levels, Group 5 is the "none" option (we don't store this)
        for level in range(1, 5):
            pattern = rf'Group {level}:\s*(.+?)(?:\n\n|Group {level+1}:|$)'
            level_match = re.search(pattern, block, re.DOTALL)
            if level_match:
                indicator_text = level_match.group(1).strip()
                # Clean up the text
                indicator_text = re.sub(r'\s+', ' ', indicator_text)
                indicators.append((competency_name, level, indicator_text))

    return indicators

def load_indicators_to_db():
    """
    Load the parsed indicators into the database.
    """
    app = create_app()

    with app.app_context():
        # Parse the questionnaires file
        filepath = r'C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\competency_assessor\competency_questionnaire\Questionnaires.txt'
        indicators = parse_questionnaires_file(filepath)

        print(f"Parsed {len(indicators)} indicators from file")

        # Get all competencies from database
        competencies = Competency.query.all()
        comp_map = {comp.competency_name.strip(): comp.id for comp in competencies}

        print(f"Found {len(comp_map)} competencies in database:")
        for name in comp_map.keys():
            print(f"  - {name}")

        # Delete existing indicators
        CompetencyIndicator.query.delete()
        db.session.commit()
        print("Cleared existing indicators")

        # Insert new indicators
        added_count = 0
        skipped_count = 0

        for competency_name, level, indicator_text in indicators:
            # Find matching competency in database
            # Try exact match first
            comp_id = comp_map.get(competency_name.strip())

            if not comp_id:
                # Try partial match (some names might have slight differences)
                for db_name, db_id in comp_map.items():
                    if competency_name.lower() in db_name.lower() or db_name.lower() in competency_name.lower():
                        comp_id = db_id
                        print(f"Matched '{competency_name}' to database competency '{db_name}'")
                        break

            if comp_id:
                indicator = CompetencyIndicator(
                    competency_id=comp_id,
                    level=level,
                    indicator_en=indicator_text,
                    indicator_de=indicator_text  # Using English for both for now
                )
                db.session.add(indicator)
                added_count += 1
            else:
                print(f"WARNING: Could not find competency '{competency_name}' in database")
                skipped_count += 1

        db.session.commit()
        print(f"\nSuccessfully loaded {added_count} indicators into database")
        if skipped_count > 0:
            print(f"Skipped {skipped_count} indicators due to missing competencies")

        # Verify
        total = CompetencyIndicator.query.count()
        print(f"\nTotal indicators in database: {total}")

        # Show sample
        samples = CompetencyIndicator.query.limit(5).all()
        print("\nSample indicators:")
        for ind in samples:
            comp = Competency.query.get(ind.competency_id)
            print(f"  - {comp.competency_name} (Level {ind.level}): {ind.indicator_en[:60]}...")

if __name__ == '__main__':
    load_indicators_to_db()
