#!/usr/bin/env python3
"""Complete database dump script to show all stored values in SE-QPT system."""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db
import sqlite3
import json

app = create_app()

with app.app_context():
    conn = sqlite3.connect('instance/seqpt.db')
    cursor = conn.cursor()

    # Get all table names
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    tables = [table[0] for table in cursor.fetchall()]

    for table_name in tables:
        print(f"\n{'='*60}")
        print(f"TABLE: {table_name.upper()}")
        print(f"{'='*60}")

        # Get column info
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = cursor.fetchall()
        print(f"Columns: {', '.join([col[1] for col in columns])}")

        # Get all records
        cursor.execute(f"SELECT * FROM {table_name}")
        records = cursor.fetchall()

        print(f"Records: {len(records)}")

        if len(records) > 0:
            print()
            # Show first few records for large tables, all records for small tables
            show_count = min(10, len(records)) if len(records) > 5 else len(records)

            for i, record in enumerate(records[:show_count]):
                print(f"Record {i+1}:")
                for j, value in enumerate(record):
                    col_name = columns[j][1]
                    # Format long text fields
                    if isinstance(value, str) and len(value) > 100:
                        value = value[:100] + "..."
                    print(f"  {col_name}: {value}")
                print()

            if len(records) > show_count:
                print(f"... and {len(records) - show_count} more records")

        print()

    # Special detailed view for key questionnaire data
    print(f"\n{'='*60}")
    print("DETAILED QUESTIONNAIRE ANALYSIS")
    print(f"{'='*60}")

    print("\n--- RECENT QUESTIONNAIRE RESPONSES ---")
    cursor.execute("""
        SELECT qr.uuid, qr.questionnaire_id, q.name as questionnaire_name,
               qr.status, qr.total_score, qr.completion_percentage,
               qr.started_at, qr.completed_at
        FROM questionnaire_responses qr
        JOIN questionnaires q ON qr.questionnaire_id = q.id
        WHERE qr.user_id = 1
        ORDER BY qr.started_at DESC
        LIMIT 10
    """)

    recent_responses = cursor.fetchall()
    for resp in recent_responses:
        print(f"UUID: {resp[0]}")
        print(f"  Questionnaire: {resp[2]} (ID: {resp[1]})")
        print(f"  Status: {resp[3]} | Score: {resp[4]} | Completion: {resp[5]}%")
        print(f"  Started: {resp[6]} | Completed: {resp[7]}")
        print()

    print("\n--- QUESTION RESPONSES DETAILS ---")
    cursor.execute("""
        SELECT qr.uuid, qres.question_id, q.question_text, qres.response_value, qres.score
        FROM questionnaire_responses qr
        JOIN question_responses qres ON qr.id = qres.questionnaire_response_id
        JOIN questions q ON qres.question_id = q.id
        WHERE qr.user_id = 1 AND qr.status = 'completed'
        ORDER BY qr.started_at DESC, qres.question_id
        LIMIT 20
    """)

    question_details = cursor.fetchall()
    current_uuid = None
    for detail in question_details:
        if detail[0] != current_uuid:
            current_uuid = detail[0]
            print(f"\nResponse UUID: {current_uuid}")

        print(f"  Q{detail[1]}: {detail[2][:50]}...")
        print(f"    Answer: {detail[3]} (Score: {detail[4]})")

    print("\n--- QUESTIONNAIRE QUESTIONS & OPTIONS ---")
    for qid in [1, 2]:  # Maturity and Archetype questionnaires
        cursor.execute("SELECT name FROM questionnaires WHERE id = ?", (qid,))
        qname = cursor.fetchone()
        print(f"\nQuestionnaire {qid}: {qname[0] if qname else 'Unknown'}")

        cursor.execute("""
            SELECT q.id, q.question_number, q.question_text, q.question_type
            FROM questions q
            WHERE q.questionnaire_id = ?
            ORDER BY q.sort_order
        """, (qid,))

        questions = cursor.fetchall()
        for q in questions:
            print(f"  Question {q[0]} ({q[1]}): {q[2]}")
            print(f"    Type: {q[3]}")

            # Get options
            cursor.execute("""
                SELECT option_value, option_text, score_value
                FROM question_options
                WHERE question_id = ?
                ORDER BY sort_order
            """, (q[0],))

            options = cursor.fetchall()
            for opt in options:
                print(f"    Option {opt[0]}: {opt[1]} (Score: {opt[2]})")
            print()

    conn.close()