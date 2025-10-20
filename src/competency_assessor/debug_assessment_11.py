"""Debug script to check assessment 11 data."""
import psycopg2
import json

# Connect to database
conn = psycopg2.connect(
    "postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment"
)
cur = conn.cursor()

assessment_id = 11

print(f"\n=== ASSESSMENT {assessment_id} DETAILS ===\n")

# Get assessment basic info
cur.execute("""
    SELECT id, admin_user_id, role, assessment_date, assessment_type
    FROM competency_assessment
    WHERE id = %s
""", (assessment_id,))
assessment = cur.fetchone()
print(f"Assessment: {assessment}")

# Get user scores for this assessment
cur.execute("""
    SELECT
        c.competency_id,
        c.competency_name,
        c.competency_area,
        c.score
    FROM competency_results c
    WHERE c.assessment_id = %s
    ORDER BY c.competency_name
""", (assessment_id,))
user_scores = cur.fetchall()

print(f"\n=== USER SCORES ({len(user_scores)} competencies) ===")
for score in user_scores:
    print(f"  {score[1]}: score={score[3]}, area={score[2]}")

# Get max/required scores for this assessment
cur.execute("""
    SELECT
        m.competency_id,
        c.competency_name,
        m.max_score
    FROM competency_max_scores m
    JOIN competencies c ON m.competency_id = c.competency_id
    WHERE m.assessment_id = %s
    ORDER BY c.competency_name
""", (assessment_id,))
max_scores = cur.fetchall()

print(f"\n=== REQUIRED SCORES ({len(max_scores)} competencies) ===")
for max_score in max_scores:
    comp_id, comp_name, required = max_score
    print(f"  {comp_name} (ID {comp_id}): required={required}")

# Check for Project Management specifically
print(f"\n=== PROJECT MANAGEMENT ANALYSIS ===")
cur.execute("""
    SELECT
        c.competency_id,
        c.competency_name,
        cr.score as user_score,
        m.max_score as required_score
    FROM competencies c
    LEFT JOIN competency_results cr ON c.competency_id = cr.competency_id AND cr.assessment_id = %s
    LEFT JOIN competency_max_scores m ON c.competency_id = m.competency_id AND m.assessment_id = %s
    WHERE c.competency_name ILIKE '%project%management%'
    ORDER BY c.competency_name
""", (assessment_id, assessment_id))
pm_data = cur.fetchall()

for pm in pm_data:
    print(f"\nCompetency ID: {pm[0]}")
    print(f"Name: {pm[1]}")
    print(f"User Score: {pm[2]}")
    print(f"Required Score: {pm[3]}")

cur.close()
conn.close()

print("\n[OK] Debug complete")
