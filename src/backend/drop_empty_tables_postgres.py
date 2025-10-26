"""
Script to drop empty tables using postgres superuser
"""
import psycopg2
from psycopg2 import sql

# Database connection as postgres superuser
conn = psycopg2.connect(
    dbname='seqpt_database',
    user='postgres',
    password='root',
    host='localhost',
    port='5432'
)

def drop_empty_tables():
    """Drop the 21 empty tables"""
    empty_tables = [
        'assessments',
        'company_contexts',
        'competency_assessment_results',
        'iso_activities',
        'iso_tasks',
        'learning_modules',
        'learning_objectives',
        'learning_paths',
        'learning_plans',
        'learning_resources',
        'maturity_assessments',
        'module_assessments',
        'module_enrollments',
        'qualification_archetypes',
        'qualification_plans',
        'question_options',
        'question_responses',
        'questionnaire_responses',
        'questionnaires',
        'questions',
        'rag_templates'
    ]

    cursor = conn.cursor()

    print(f"[INFO] Dropping {len(empty_tables)} empty tables as postgres superuser...\n")

    dropped = 0
    failed = 0

    for table in empty_tables:
        try:
            cursor.execute(sql.SQL("DROP TABLE IF EXISTS {} CASCADE").format(sql.Identifier(table)))
            conn.commit()
            print(f"  [OK] Dropped table: {table}")
            dropped += 1
        except Exception as e:
            conn.rollback()
            print(f"  [ERROR] Failed to drop {table}: {e}")
            failed += 1

    cursor.close()
    print(f"\n[SUCCESS] Dropped {dropped} tables")
    if failed > 0:
        print(f"[WARNING] Failed to drop {failed} tables")

if __name__ == '__main__':
    drop_empty_tables()
    conn.close()
