"""
Create the competency_indicators table and populate it if needed.
"""

from app import create_app
from models import db, CompetencyIndicator
import psycopg2
from psycopg2.extras import RealDictCursor

def create_table():
    """Create the competency_indicators table"""
    app = create_app()
    with app.app_context():
        # Create the table
        print("[INFO] Creating competency_indicators table...")
        db.create_all()  # This will only create tables that don't exist
        print("[SUCCESS] Table created!")

        # Check if the table is empty
        count = CompetencyIndicator.query.count()
        print(f"[INFO] Current indicators count: {count}")

        if count == 0:
            print("[INFO] Table is empty. Attempting to copy data from Derik's database...")
            copy_from_derik_db()
        else:
            print("[INFO] Table already has data.")

def copy_from_derik_db():
    """Copy competency indicators from Derik's database if it exists"""
    try:
        # Try to connect to Derik's database (sesurveyapp uses different DB name)
        # We'll try common names
        for db_name in ['sesurveyapp', 'competency_survey', 'se_survey']:
            try:
                print(f"[INFO] Trying to connect to database: {db_name}")
                conn = psycopg2.connect(
                    host="localhost",
                    port="5432",
                    database=db_name,
                    user="ma0349",
                    password="MA0349_2025"
                )

                cursor = conn.cursor(cursor_factory=RealDictCursor)
                cursor.execute("SELECT * FROM competency_indicators ORDER BY id")
                indicators = cursor.fetchall()

                if indicators:
                    print(f"[SUCCESS] Found {len(indicators)} indicators in {db_name}")

                    # Copy to our database
                    app = create_app()
                    with app.app_context():
                        for ind in indicators:
                            indicator = CompetencyIndicator(
                                competency_id=ind['competency_id'],
                                level=ind['level'],
                                indicator_en=ind['indicator_en'],
                                indicator_de=ind['indicator_de']
                            )
                            db.session.add(indicator)

                        db.session.commit()
                        print(f"[SUCCESS] Copied {len(indicators)} indicators!")

                    conn.close()
                    return True

                conn.close()
            except Exception as e:
                print(f"[INFO] Database {db_name} not found or error: {str(e)[:100]}")
                continue

        print("[WARNING] Could not find Derik's database to copy from.")
        print("[INFO] You may need to manually populate the competency_indicators table.")
        return False

    except Exception as e:
        print(f"[ERROR] Error copying data: {e}")
        return False

if __name__ == "__main__":
    create_table()
