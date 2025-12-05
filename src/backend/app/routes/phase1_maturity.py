"""
Phase 1 Maturity Assessment Routes Blueprint

Handles maturity assessment questionnaire responses for Phase 1.
Includes endpoints for retrieving and saving maturity assessments.
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt, verify_jwt_in_request
from datetime import datetime
import json

from models import db, User, Organization, PhaseQuestionnaireResponse

# Create blueprint
phase1_maturity_bp = Blueprint('phase1_maturity', __name__)


@phase1_maturity_bp.route('/phase1/maturity/<int:org_id>/latest', methods=['GET'])
def get_latest_maturity_assessment(org_id):
    """Get latest maturity assessment for an organization"""
    try:
        # Verify organization exists
        org = Organization.query.get(org_id)
        if not org:
            return jsonify({'error': 'Organization not found'}), 404

        # Get latest maturity assessment
        maturity = PhaseQuestionnaireResponse.query.filter_by(
            organization_id=org_id,
            questionnaire_type='maturity',
            phase=1
        ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

        if not maturity:
            return jsonify({
                'exists': False,
                'data': None
            }), 200

        # Get the responses which contain both answers and results
        response_data = maturity.get_responses()

        return jsonify({
            'exists': True,
            'data': {
                'id': maturity.id,
                'answers': response_data.get('answers', {}),
                'results': response_data.get('results', {}),
                'completed_at': maturity.completed_at.isoformat() if maturity.completed_at else None
            }
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting maturity assessment: {str(e)}")
        return jsonify({'error': 'Failed to get maturity assessment'}), 500


@phase1_maturity_bp.route('/phase1/maturity/save', methods=['POST'])
def save_maturity_assessment():
    """Save maturity assessment results"""
    try:
        data = request.get_json()

        org_id = data.get('org_id')
        answers = data.get('answers', {})
        results = data.get('results', {})

        if not org_id:
            return jsonify({'error': 'org_id is required'}), 400

        # Get user ID from JWT if available
        user_id = 1  # Default fallback
        try:
            verify_jwt_in_request(optional=True)
            jwt_user_id = get_jwt_identity()
            if jwt_user_id:
                user_id = int(jwt_user_id) if isinstance(jwt_user_id, str) else jwt_user_id
        except Exception:
            pass  # Use default user_id

        # Create new maturity assessment
        maturity = PhaseQuestionnaireResponse(
            organization_id=org_id,
            user_id=user_id,
            questionnaire_type='maturity',
            phase=1
        )

        # Store both answers and results together in the responses field
        maturity.set_responses({
            'answers': answers,
            'results': results
        })

        db.session.add(maturity)
        db.session.commit()

        return jsonify({
            'success': True,
            'id': maturity.id,
            'message': 'Maturity assessment saved successfully'
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving maturity assessment: {str(e)}")
        return jsonify({'error': 'Failed to save maturity assessment'}), 500
