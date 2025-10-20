"""Clear all cached feedback to force regeneration with improved LLM prompt"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Database connection
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment')

try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()

    # Delete all cached feedback
    cursor.execute("DELETE FROM user_competency_survey_feedback;")
    conn.commit()

    # Verify deletion
    cursor.execute("SELECT COUNT(*) FROM user_competency_survey_feedback;")
    count = cursor.fetchone()[0]

    print(f"[SUCCESS] Cleared all cached feedback")
    print(f"[INFO] Remaining entries: {count}")

    cursor.close()
    conn.close()

except Exception as e:
    print(f"[ERROR] Failed to clear feedback cache: {e}")
