import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("CHECKING ASSESSMENT #7 FEEDBACK ISSUE")
    print("=" * 80)

    # Check survey user #7
    print("\n1. Survey User #7 Info:")
    result = db.session.execute(text("SELECT id, username, completed_at FROM new_survey_user WHERE id = 7")).fetchone()
    if result:
        print(f"   ID: {result[0]}")
        print(f"   Username: {result[1]}")
        print(f"   Completed At: {result[2]}")
        username = result[1]
    else:
        print("   [ERROR] Survey user #7 not found!")
        sys.exit(1)

    # Check if feedback exists
    print(f"\n2. Feedback for {username}:")
    feedbacks = db.session.execute(
        text("SELECT id, competency_id, feedback_text, created_at FROM assessment_feedback WHERE username = :username"),
        {"username": username}
    ).fetchall()
    if feedbacks:
        for fb in feedbacks:
            print(f"   - Feedback ID {fb[0]}: Competency {fb[1]}, Created: {fb[3]}")
            print(f"     Text: {fb[2][:100]}...")
    else:
        print("   [NO FEEDBACK FOUND]")

    # Check if trigger exists
    print("\n3. Checking for feedback trigger:")
    triggers = db.session.execute(text("SELECT tgname, tgrelid::regclass FROM pg_trigger WHERE tgname LIKE '%feedback%'")).fetchall()
    if triggers:
        for trig in triggers:
            print(f"   - Trigger: {trig[0]} on table {trig[1]}")
    else:
        print("   [NO FEEDBACK TRIGGER FOUND]")

    # Check if stored procedure exists
    print("\n4. Checking for feedback generation function:")
    procs = db.session.execute(text("SELECT proname FROM pg_proc WHERE proname LIKE '%feedback%'")).fetchall()
    if procs:
        for proc in procs:
            print(f"   - Function: {proc[0]}")
    else:
        print("   [NO FEEDBACK FUNCTION FOUND]")

    # Check recent survey completions
    print("\n5. Recent survey completions:")
    recent = db.session.execute(text("SELECT id, username, completed_at FROM new_survey_user WHERE completed_at IS NOT NULL ORDER BY completed_at DESC LIMIT 5")).fetchall()
    for rec in recent:
        print(f"   - User {rec[0]} ({rec[1]}): Completed at {rec[2]}")

    print("\n" + "=" * 80)
