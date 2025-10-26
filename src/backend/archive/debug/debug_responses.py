#!/usr/bin/env python3
"""Debug script to examine questionnaire responses and build proper response format."""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, QuestionnaireResponse, QuestionResponse, Question, Questionnaire
import json

app = create_app()

with app.app_context():
    # Get the latest maturity and archetype responses for user 1
    maturity_response = QuestionnaireResponse.query.filter_by(
        user_id=1,
        questionnaire_id=1,  # maturity
        status='completed'
    ).order_by(QuestionnaireResponse.started_at.desc()).first()

    archetype_response = QuestionnaireResponse.query.filter_by(
        user_id=1,
        questionnaire_id=2,  # archetype
        status='completed'
    ).order_by(QuestionnaireResponse.started_at.desc()).first()

    print("=== MATURITY RESPONSE ===")
    if maturity_response:
        print(f"UUID: {maturity_response.uuid}")
        print(f"Score: {maturity_response.total_score}")
        print(f"Status: {maturity_response.status}")
        print(f"Completed: {maturity_response.completed_at}")

        # Get question responses
        question_responses = QuestionResponse.query.filter_by(
            questionnaire_response_id=maturity_response.id
        ).all()

        print(f"Question responses count: {len(question_responses)}")

        responses_dict = {}
        for qr in question_responses:
            responses_dict[str(qr.question_id)] = qr.response_value
            print(f"  Question {qr.question_id}: {qr.response_value} (score: {qr.score})")

        # Build complete response object
        maturity_data = {
            'uuid': maturity_response.uuid,
            'questionnaire_id': maturity_response.questionnaire_id,
            'user_id': maturity_response.user_id,
            'status': maturity_response.status,
            'total_score': maturity_response.total_score,
            'score_percentage': maturity_response.score_percentage,
            'completion_percentage': maturity_response.completion_percentage,
            'completed_at': maturity_response.completed_at.isoformat() if maturity_response.completed_at else None,
            'responses': responses_dict
        }

        print(f"\nMaturity Response Object:")
        print(json.dumps(maturity_data, indent=2, default=str))
    else:
        print("No maturity response found")

    print("\n=== ARCHETYPE RESPONSE ===")
    if archetype_response:
        print(f"UUID: {archetype_response.uuid}")
        print(f"Score: {archetype_response.total_score}")
        print(f"Status: {archetype_response.status}")
        print(f"Completed: {archetype_response.completed_at}")

        # Get question responses
        question_responses = QuestionResponse.query.filter_by(
            questionnaire_response_id=archetype_response.id
        ).all()

        print(f"Question responses count: {len(question_responses)}")

        responses_dict = {}
        for qr in question_responses:
            responses_dict[str(qr.question_id)] = qr.response_value
            print(f"  Question {qr.question_id}: {qr.response_value} (score: {qr.score})")

        # Build complete response object
        archetype_data = {
            'uuid': archetype_response.uuid,
            'questionnaire_id': archetype_response.questionnaire_id,
            'user_id': archetype_response.user_id,
            'status': archetype_response.status,
            'total_score': archetype_response.total_score,
            'score_percentage': archetype_response.score_percentage,
            'completion_percentage': archetype_response.completion_percentage,
            'completed_at': archetype_response.completed_at.isoformat() if archetype_response.completed_at else None,
            'responses': responses_dict
        }

        print(f"\nArchetype Response Object:")
        print(json.dumps(archetype_data, indent=2, default=str))
    else:
        print("No archetype response found")

    print("\n=== QUESTIONS FOR ARCHETYPE SELECTION ===")
    # Show the archetype questions to understand the mapping
    archetype_questions = Question.query.filter_by(questionnaire_id=2).all()
    for q in archetype_questions:
        print(f"Question {q.id}: {q.question_text}")
        # Get options
        from models import QuestionOption
        options = QuestionOption.query.filter_by(question_id=q.id).all()
        for opt in options:
            print(f"  Option {opt.option_value}: {opt.option_text}")