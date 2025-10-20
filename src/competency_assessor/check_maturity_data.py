import psycopg2
import json

# Connect to database
conn = psycopg2.connect(
    host="localhost",
    database="competency_assessment",
    user="ma0349",
    password="MA0349_2025",
    port=5432
)

cur = conn.cursor()

# Query maturity data for org 24
query = """
SELECT
    id, org_id,
    final_score, maturity_level, maturity_name,
    q1_rollout_scope, q2_se_processes, q3_se_mindset, q4_knowledge_base,
    created_at
FROM phase1_maturity
WHERE org_id = 24
ORDER BY created_at DESC
LIMIT 3;
"""

cur.execute(query)
rows = cur.fetchall()

print("=" * 80)
print("MATURITY ASSESSMENT DATA FOR ORG 24")
print("=" * 80)

if not rows:
    print("[ERROR] No maturity assessments found for org_id=24")
else:
    for row in rows:
        print(f"\n[OK] ID: {row[0]} | Org: {row[1]} | Created: {row[9]}")
        print(f"     Final Score: {row[2]} (type: {type(row[2])})")
        print(f"     Maturity Level: {row[3]} (type: {type(row[3])})")
        print(f"     Maturity Name: {row[4]} (type: {type(row[4])})")
        print(f"     Q1 (Rollout): {row[5]}, Q2 (Processes): {row[6]}, Q3 (Mindset): {row[7]}, Q4 (Knowledge): {row[8]}")

        if row[2] is None:
            print(f"     [WARNING] final_score is NULL!")
        if row[3] is None:
            print(f"     [WARNING] maturity_level is NULL!")
        if row[4] is None:
            print(f"     [WARNING] maturity_name is NULL!")

cur.close()
conn.close()

print("\n" + "=" * 80)
print("Check complete!")
print("=" * 80)
