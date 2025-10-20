"""
SE-QPT Extended API Routes
Additional endpoints for advanced functionality
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timedelta
import json

from models import db
from models import *

api_bp = Blueprint('api', __name__)

# Extended Assessment Analytics
@api_bp.route('/analytics/assessments', methods=['GET'])
@jwt_required()
def get_assessment_analytics():
    """Get assessment analytics for user"""
    try:
        user_id = get_jwt_identity()

        # Get user's assessments
        assessments = Assessment.query.filter_by(user_id=user_id).all()

        if not assessments:
            return {'analytics': {'message': 'No assessments found'}}

        completed_assessments = [a for a in assessments if a.status == 'completed']

        analytics = {
            'total_assessments': len(assessments),
            'completed_assessments': len(completed_assessments),
            'completion_rate': len(completed_assessments) / len(assessments) * 100 if assessments else 0,
            'average_progress': sum(a.progress_percentage for a in assessments) / len(assessments),
            'competency_trends': {},
            'phase_distribution': {},
            'improvement_over_time': []
        }

        # Phase distribution
        for assessment in assessments:
            phase = f"Phase {assessment.phase}"
            analytics['phase_distribution'][phase] = analytics['phase_distribution'].get(phase, 0) + 1

        # Competency trends (from completed assessments)
        competency_scores = {}
        for assessment in completed_assessments:
            if assessment.competency_scores:
                for comp_name, score in assessment.competency_scores.items():
                    if comp_name not in competency_scores:
                        competency_scores[comp_name] = []
                    competency_scores[comp_name].append({
                        'score': score,
                        'date': assessment.completed_at.isoformat(),
                        'assessment_id': assessment.id
                    })

        analytics['competency_trends'] = competency_scores

        return {'analytics': analytics}

    except Exception as e:
        current_app.logger.error(f"Assessment analytics error: {str(e)}")
        return {'error': 'Failed to get analytics'}, 500

@api_bp.route('/recommendations/<int:assessment_id>', methods=['GET'])
@jwt_required()
def get_recommendations(assessment_id):
    """Get personalized recommendations for assessment"""
    try:
        user_id = get_jwt_identity()
        assessment = Assessment.query.filter_by(id=assessment_id, user_id=user_id).first()

        if not assessment:
            return {'error': 'Assessment not found'}, 404

        # Get competency results
        results = CompetencyAssessmentResult.query.filter_by(assessment_id=assessment_id).all()

        recommendations = {
            'priority_competencies': [],
            'suggested_learning_paths': [],
            'recommended_modules': [],
            'timeline_suggestions': {},
            'resource_recommendations': []
        }

        # Priority competencies (highest gaps)
        sorted_results = sorted(results, key=lambda x: x.gap_score, reverse=True)
        for result in sorted_results[:5]:
            competency = SECompetency.query.get(result.competency_id)
            if competency:
                recommendations['priority_competencies'].append({
                    'competency_name': competency.name,
                    'current_level': result.current_level,
                    'required_level': result.required_level,
                    'gap_score': result.gap_score,
                    'priority': result.priority_ranking
                })

        # Suggested learning paths based on role
        if assessment.results and 'similar_role' in assessment.results:
            role_name = assessment.results['similar_role']
            role = SERole.query.filter_by(name=role_name).first()
            if role:
                recommendations['suggested_learning_paths'].append({
                    'role_name': role.name,
                    'description': role.description,
                    'career_level': role.career_level,
                    'focus_areas': role.primary_focus
                })

        # Timeline suggestions
        total_gap = sum(r.gap_score for r in results)
        estimated_weeks = min(52, max(12, int(total_gap * 4)))  # 4 weeks per gap point

        recommendations['timeline_suggestions'] = {
            'estimated_duration_weeks': estimated_weeks,
            'suggested_intensity': 'moderate' if estimated_weeks > 26 else 'intensive',
            'milestone_intervals': 'bi-weekly' if estimated_weeks > 26 else 'weekly'
        }

        return {'recommendations': recommendations}

    except Exception as e:
        current_app.logger.error(f"Recommendations error: {str(e)}")
        return {'error': 'Failed to get recommendations'}, 500

# Module and Resource Management endpoints moved to module_api.py

@api_bp.route('/modules/search', methods=['GET'])
def search_modules():
    """Search learning modules"""
    try:
        query = request.args.get('q', '')
        category = request.args.get('category', '')
        difficulty = request.args.get('difficulty', '')

        modules_query = LearningModule.query.filter_by(is_active=True)

        if query:
            modules_query = modules_query.filter(
                LearningModule.name.ilike(f'%{query}%') |
                LearningModule.description.ilike(f'%{query}%')
            )

        if category:
            modules_query = modules_query.filter_by(category=category)

        if difficulty:
            modules_query = modules_query.filter_by(difficulty_level=difficulty)

        modules = modules_query.all()

        return {
            'modules': [
                {
                    'id': m.id,
                    'name': m.name,
                    'description': m.description,
                    'category': m.category,
                    'difficulty_level': m.difficulty_level,
                    'estimated_duration_hours': m.estimated_duration_hours
                } for m in modules
            ],
            'total_found': len(modules)
        }

    except Exception as e:
        current_app.logger.error(f"Module search error: {str(e)}")
        return {'error': 'Failed to search modules'}, 500

# Progress Tracking
@api_bp.route('/progress/<plan_uuid>', methods=['GET'])
@jwt_required()
def get_plan_progress(plan_uuid):
    """Get detailed progress for qualification plan"""
    try:
        user_id = get_jwt_identity()
        plan = QualificationPlan.query.filter_by(uuid=plan_uuid, user_id=user_id).first()

        if not plan:
            return {'error': 'Plan not found'}, 404

        # Get progress tracking records
        progress_records = ProgressTracking.query.filter_by(plan_id=plan.id).order_by(ProgressTracking.tracked_at).all()

        progress_data = {
            'plan_info': {
                'id': plan.id,
                'uuid': plan.uuid,
                'name': plan.plan_name,
                'status': plan.status,
                'progress_percentage': plan.progress_percentage
            },
            'timeline': [],
            'competency_progress': {},
            'module_completion': {},
            'milestones': []
        }

        # Timeline data
        for record in progress_records:
            progress_data['timeline'].append({
                'date': record.tracked_at.isoformat(),
                'overall_progress': record.overall_progress,
                'competency_id': record.competency_id,
                'module_id': record.module_id,
                'status': record.status,
                'notes': record.notes
            })

        # Competency progress
        competency_progress = {}
        for record in progress_records:
            if record.competency_id:
                comp_id = record.competency_id
                if comp_id not in competency_progress:
                    competency = SECompetency.query.get(comp_id)
                    competency_progress[comp_id] = {
                        'competency_name': competency.name if competency else 'Unknown',
                        'progress_history': []
                    }
                competency_progress[comp_id]['progress_history'].append({
                    'date': record.tracked_at.isoformat(),
                    'progress': record.overall_progress,
                    'status': record.status
                })

        progress_data['competency_progress'] = competency_progress

        return {'progress': progress_data}

    except Exception as e:
        current_app.logger.error(f"Progress tracking error: {str(e)}")
        return {'error': 'Failed to get progress data'}, 500

@api_bp.route('/progress/<plan_uuid>', methods=['POST'])
@jwt_required()
def update_plan_progress(plan_uuid):
    """Update progress for qualification plan"""
    try:
        user_id = get_jwt_identity()
        plan = QualificationPlan.query.filter_by(uuid=plan_uuid, user_id=user_id).first()

        if not plan:
            return {'error': 'Plan not found'}, 404

        data = request.get_json()

        # Create progress record
        progress_record = ProgressTracking(
            plan_id=plan.id,
            competency_id=data.get('competency_id'),
            module_id=data.get('module_id'),
            overall_progress=data.get('progress_percentage', 0),
            status=data.get('status', 'in_progress'),
            notes=data.get('notes', ''),
            tracked_at=datetime.utcnow()
        )

        db.session.add(progress_record)

        # Update plan progress
        if 'progress_percentage' in data:
            plan.progress_percentage = data['progress_percentage']

        if data.get('status') == 'completed':
            plan.status = 'completed'
            plan.actual_end_date = datetime.utcnow()

        db.session.commit()

        return {
            'message': 'Progress updated successfully',
            'progress_record_id': progress_record.id
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Progress update error: {str(e)}")
        return {'error': 'Failed to update progress'}, 500

# Export and Reporting
@api_bp.route('/export/assessment/<int:assessment_id>', methods=['GET'])
@jwt_required()
def export_assessment(assessment_id):
    """Export assessment data"""
    try:
        user_id = get_jwt_identity()
        assessment = Assessment.query.filter_by(id=assessment_id, user_id=user_id).first()

        if not assessment:
            return {'error': 'Assessment not found'}, 404

        # Get user info
        user = User.query.get(user_id)

        # Get competency results
        results = CompetencyAssessmentResult.query.filter_by(assessment_id=assessment_id).all()

        export_data = {
            'export_info': {
                'generated_at': datetime.utcnow().isoformat(),
                'assessment_id': assessment.id,
                'assessment_uuid': assessment.uuid
            },
            'user_info': {
                'name': f"{user.first_name} {user.last_name}",
                'email': user.email,
                'organization': user.organization
            },
            'assessment_details': {
                'type': assessment.assessment_type,
                'phase': assessment.phase,
                'status': assessment.status,
                'organization_name': assessment.organization_name,
                'industry_domain': assessment.industry_domain,
                'started_at': assessment.started_at.isoformat() if assessment.started_at else None,
                'completed_at': assessment.completed_at.isoformat() if assessment.completed_at else None
            },
            'competency_results': [],
            'summary_statistics': {},
            'recommendations': assessment.recommendations or []
        }

        # Competency results
        for result in results:
            competency = SECompetency.query.get(result.competency_id)
            export_data['competency_results'].append({
                'competency_name': competency.name if competency else 'Unknown',
                'competency_category': competency.category if competency else '',
                'current_level': result.current_level,
                'required_level': result.required_level,
                'gap_score': result.gap_score,
                'priority_ranking': result.priority_ranking,
                'development_recommendations': result.development_recommendations
            })

        # Summary statistics
        if results:
            export_data['summary_statistics'] = {
                'total_competencies_assessed': len(results),
                'average_current_level': sum(r.current_level for r in results) / len(results),
                'average_required_level': sum(r.required_level for r in results) / len(results),
                'total_gap_score': sum(r.gap_score for r in results),
                'competencies_meeting_requirements': len([r for r in results if r.current_level >= r.required_level])
            }

        return {'export_data': export_data}

    except Exception as e:
        current_app.logger.error(f"Assessment export error: {str(e)}")
        return {'error': 'Failed to export assessment'}, 500

@api_bp.route('/export/plan/<plan_uuid>', methods=['GET'])
@jwt_required()
def export_qualification_plan(plan_uuid):
    """Export qualification plan data"""
    try:
        user_id = get_jwt_identity()
        plan = QualificationPlan.query.filter_by(uuid=plan_uuid, user_id=user_id).first()

        if not plan:
            return {'error': 'Plan not found'}, 404

        # Get user info
        user = User.query.get(user_id)

        # Get associated assessment
        assessment = Assessment.query.get(plan.assessment_id) if plan.assessment_id else None

        # Get target role
        target_role = SERole.query.get(plan.target_role_id) if plan.target_role_id else None

        # Get selected archetype
        archetype = QualificationArchetype.query.get(plan.selected_archetype_id) if plan.selected_archetype_id else None

        export_data = {
            'export_info': {
                'generated_at': datetime.utcnow().isoformat(),
                'plan_id': plan.id,
                'plan_uuid': plan.uuid
            },
            'user_info': {
                'name': f"{user.first_name} {user.last_name}",
                'email': user.email,
                'organization': user.organization
            },
            'plan_details': {
                'name': plan.plan_name,
                'description': plan.description,
                'status': plan.status,
                'progress_percentage': plan.progress_percentage,
                'planned_start_date': plan.planned_start_date.isoformat() if plan.planned_start_date else None,
                'planned_end_date': plan.planned_end_date.isoformat() if plan.planned_end_date else None,
                'estimated_duration_weeks': plan.estimated_duration_weeks,
                'target_role': target_role.name if target_role else None,
                'selected_archetype': archetype.name if archetype else None
            },
            'learning_objectives': plan.learning_objectives or [],
            'selected_modules': plan.selected_modules or [],
            'learning_formats': plan.learning_formats or {},
            'resource_requirements': plan.resource_requirements or {},
            'assessment_summary': {}
        }

        # Assessment summary
        if assessment:
            export_data['assessment_summary'] = {
                'assessment_type': assessment.assessment_type,
                'completion_date': assessment.completed_at.isoformat() if assessment.completed_at else None,
                'organization_maturity': assessment.se_maturity_level,
                'total_competency_gaps': len(assessment.gap_analysis or {})
            }

        return {'export_data': export_data}

    except Exception as e:
        current_app.logger.error(f"Plan export error: {str(e)}")
        return {'error': 'Failed to export qualification plan'}, 500