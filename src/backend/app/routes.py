"""
SE-QPT Main API Routes
Core platform endpoints integrating all components
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from datetime import datetime
import traceback

from models import db, User, SECompetency, SERole, QualificationArchetype, Assessment, CompetencyAssessmentResult, LearningObjective, QualificationPlan, CompanyContext, RAGTemplate

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    """Platform welcome endpoint"""
    return {
        'message': 'SE-QPT Unified Platform API',
        'version': '1.0.0',
        'description': 'Systems Engineering Qualification Planning Tool with RAG-LLM Innovation',
        'components': {
            'marcel_methodology': 'SE-QPT 4-phase framework',
            'derik_assessor': 'Competency assessment system',
            'rag_innovation': 'AI-powered learning objective generation'
        },
        'endpoints': {
            'assessments': '/api/assessments',
            'competencies': '/api/competencies',
            'learning_objectives': '/api/learning-objectives',
            'qualification_plans': '/api/qualification-plans',
            'admin': '/admin',
            'auth': '/auth'
        }
    }

# Assessment Endpoints
@main_bp.route('/api/assessments', methods=['GET'])
@jwt_required()
def get_assessments():
    """Get user's assessments"""
    try:
        user_id = get_jwt_identity()
        assessments = Assessment.query.filter_by(user_id=user_id).all()

        return {
            'assessments': [
                {
                    'id': a.id,
                    'uuid': a.uuid,
                    'type': a.assessment_type,
                    'phase': a.phase,
                    'status': a.status,
                    'progress': a.progress_percentage,
                    'organization': a.organization_name,
                    'started_at': a.started_at.isoformat() if a.started_at else None,
                    'completed_at': a.completed_at.isoformat() if a.completed_at else None
                } for a in assessments
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

@main_bp.route('/api/assessments', methods=['POST'])
@jwt_required()
def create_assessment():
    """Create new assessment"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        assessment = Assessment(
            user_id=user_id,
            assessment_type=data.get('type', 'comprehensive'),
            phase=data.get('phase', 1),
            organization_name=data.get('organization_name'),
            industry_domain=data.get('industry_domain'),
            organization_size=data.get('organization_size')
        )

        db.session.add(assessment)
        db.session.commit()

        return {
            'message': 'Assessment created successfully',
            'assessment': {
                'id': assessment.id,
                'uuid': assessment.uuid,
                'type': assessment.assessment_type,
                'phase': assessment.phase
            }
        }
    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

@main_bp.route('/api/assessments/<assessment_uuid>', methods=['GET'])
@jwt_required()
def get_assessment(assessment_uuid):
    """Get specific assessment details"""
    try:
        user_id = get_jwt_identity()
        assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()

        if not assessment:
            return {'error': 'Assessment not found'}, 404

        return {
            'assessment': {
                'id': assessment.id,
                'uuid': assessment.uuid,
                'type': assessment.assessment_type,
                'phase': assessment.phase,
                'status': assessment.status,
                'progress': assessment.progress_percentage,
                'organization_name': assessment.organization_name,
                'industry_domain': assessment.industry_domain,
                'se_maturity_level': assessment.se_maturity_level,
                'results': assessment.results,
                'competency_scores': assessment.competency_scores,
                'gap_analysis': assessment.gap_analysis,
                'recommendations': assessment.recommendations,
                'started_at': assessment.started_at.isoformat() if assessment.started_at else None,
                'completed_at': assessment.completed_at.isoformat() if assessment.completed_at else None
            }
        }
    except Exception as e:
        return {'error': str(e)}, 500

# Competency Endpoints
@main_bp.route('/api/competencies', methods=['GET'])
def get_competencies():
    """Get all SE competencies"""
    try:
        competencies = SECompetency.query.filter_by(is_active=True).all()

        return {
            'competencies': [
                {
                    'id': c.id,
                    'name': c.name,
                    'category': c.category,
                    'description': c.description,
                    'incose_reference': c.incose_reference,
                    'level_definitions': c.level_definitions,
                    'assessment_indicators': c.assessment_indicators
                } for c in competencies
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

@main_bp.route('/api/roles', methods=['GET'])
def get_roles():
    """Get all SE roles"""
    try:
        roles = SERole.query.filter_by(is_active=True).all()

        return {
            'roles': [
                {
                    'id': r.id,
                    'name': r.name,
                    'description': r.description,
                    'typical_responsibilities': r.typical_responsibilities,
                    'career_level': r.career_level,
                    'primary_focus': r.primary_focus
                } for r in roles
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

# @main_bp.route('/api/role-competency-matrix', methods=['GET'])
# def get_role_competency_matrix():
#     """Get the 14x16 role-competency matrix"""
#     # This endpoint is temporarily disabled until RoleCompetencyMatrix model is implemented
#     return {'message': 'Role-competency matrix endpoint temporarily disabled'}, 501

# Qualification Archetype Endpoints
@main_bp.route('/api/archetypes', methods=['GET'])
def get_archetypes():
    """Get qualification archetypes"""
    try:
        archetypes = QualificationArchetype.query.filter_by(is_active=True).all()

        return {
            'archetypes': [
                {
                    'id': a.id,
                    'name': a.name,
                    'description': a.description,
                    'typical_duration': a.typical_duration,
                    'learning_format': a.learning_format,
                    'target_audience': a.target_audience,
                    'focus_area': a.focus_area,
                    'delivery_method': a.delivery_method
                } for a in archetypes
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

# Qualification Plan Endpoints
@main_bp.route('/api/qualification-plans', methods=['GET'])
@jwt_required()
def get_qualification_plans():
    """Get user's qualification plans"""
    try:
        user_id = get_jwt_identity()
        plans = QualificationPlan.query.filter_by(user_id=user_id).all()

        return {
            'plans': [
                {
                    'id': p.id,
                    'uuid': p.uuid,
                    'name': p.plan_name,
                    'description': p.description,
                    'status': p.status,
                    'progress': p.progress_percentage,
                    'planned_start_date': p.planned_start_date.isoformat() if p.planned_start_date else None,
                    'planned_end_date': p.planned_end_date.isoformat() if p.planned_end_date else None,
                    'estimated_duration_weeks': p.estimated_duration_weeks,
                    'created_at': p.created_at.isoformat() if p.created_at else None
                } for p in plans
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

@main_bp.route('/api/qualification-plans', methods=['POST'])
@jwt_required()
def create_qualification_plan():
    """Create new qualification plan"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        plan = QualificationPlan(
            user_id=user_id,
            plan_name=data.get('name'),
            description=data.get('description'),
            target_role_id=data.get('target_role_id'),
            selected_archetype_id=data.get('archetype_id'),
            assessment_id=data.get('assessment_id'),
            planned_start_date=datetime.fromisoformat(data['planned_start_date']) if data.get('planned_start_date') else None,
            planned_end_date=datetime.fromisoformat(data['planned_end_date']) if data.get('planned_end_date') else None,
            estimated_duration_weeks=data.get('estimated_duration_weeks'),
            learning_objectives=data.get('learning_objectives', []),
            selected_modules=data.get('selected_modules', []),
            learning_formats=data.get('learning_formats', {}),
            resource_requirements=data.get('resource_requirements', {})
        )

        db.session.add(plan)
        db.session.commit()

        return {
            'message': 'Qualification plan created successfully',
            'plan': {
                'id': plan.id,
                'uuid': plan.uuid,
                'name': plan.plan_name
            }
        }
    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

# Company Context Endpoints
@main_bp.route('/api/company-context', methods=['POST'])
@jwt_required()
def create_company_context():
    """Create or update company context for RAG generation"""
    try:
        data = request.get_json()

        context = CompanyContext(
            company_name=data.get('company_name'),
            industry_domain=data.get('industry_domain'),
            business_domain=data.get('business_domain'),
            processes=data.get('processes', []),
            methods=data.get('methods', []),
            tools=data.get('tools', []),
            se_maturity_level=data.get('se_maturity_level'),
            organizational_size=data.get('organizational_size'),
            current_challenges=data.get('current_challenges', []),
            regulatory_requirements=data.get('regulatory_requirements', []),
            learning_preferences=data.get('learning_preferences', []),
            available_resources=data.get('available_resources', {}),
            extraction_method='manual'
        )

        db.session.add(context)
        db.session.commit()

        return {
            'message': 'Company context created successfully',
            'context': {
                'id': context.id,
                'uuid': context.uuid,
                'company_name': context.company_name
            }
        }
    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

# Learning Objectives Endpoints
@main_bp.route('/api/learning-objectives', methods=['GET'])
@jwt_required()
def get_learning_objectives():
    """Get learning objectives with optional filtering"""
    try:
        # Query parameters
        competency_id = request.args.get('competency_id', type=int)
        archetype_id = request.args.get('archetype_id', type=int)
        company_context_id = request.args.get('company_context_id', type=int)

        query = LearningObjective.query

        if competency_id:
            query = query.filter_by(competency_id=competency_id)
        if archetype_id:
            query = query.filter_by(archetype_id=archetype_id)
        if company_context_id:
            query = query.filter_by(company_context_id=company_context_id)

        objectives = query.all()

        return {
            'objectives': [
                {
                    'id': obj.id,
                    'uuid': obj.uuid,
                    'objective_text': obj.objective_text,
                    'competency_name': obj.competency.name if obj.competency else None,
                    'archetype_name': obj.archetype.name if obj.archetype else None,
                    'target_role_name': obj.target_role.name if obj.target_role else None,
                    'quality_score': obj.quality_score,
                    'smart_score': obj.smart_score,
                    'meets_threshold': obj.meets_threshold,
                    'status': obj.status,
                    'generated_at': obj.generated_at.isoformat() if obj.generated_at else None
                } for obj in objectives
            ]
        }
    except Exception as e:
        return {'error': str(e)}, 500

# System Status Endpoints
@main_bp.route('/api/system/status', methods=['GET'])
def get_system_status():
    """Get comprehensive system status"""
    try:
        # Database connectivity check
        db_status = 'connected'
        try:
            db.session.execute('SELECT 1')
        except:
            db_status = 'disconnected'

        # Component counts
        total_users = User.query.count()
        total_assessments = Assessment.query.count()
        total_objectives = LearningObjective.query.count()
        total_plans = QualificationPlan.query.count()

        # Recent activity
        recent_assessments = Assessment.query.filter(
            Assessment.created_at >= datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        ).count()

        return {
            'status': 'operational',
            'timestamp': datetime.utcnow().isoformat(),
            'database': {
                'status': db_status,
                'total_users': total_users,
                'total_assessments': total_assessments,
                'total_objectives': total_objectives,
                'total_plans': total_plans
            },
            'activity': {
                'assessments_today': recent_assessments
            },
            'components': {
                'marcel_framework': 'operational',
                'derik_assessor': 'integrated',
                'rag_llm_innovation': 'operational',
                'frontend': 'ready'
            }
        }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500

# User Response Endpoints
@main_bp.route('/api/users/<int:user_id>/responses', methods=['GET'])
@jwt_required()
def get_user_responses(user_id):
    """Get user's questionnaire responses"""
    try:
        # Verify user access (users can only access their own responses)
        current_user_id = get_jwt_identity()
        if current_user_id != user_id:
            return {'error': 'Unauthorized access to user responses'}, 403

        # Get user's assessment responses
        assessments = Assessment.query.filter_by(user_id=user_id).all()

        responses = []
        for assessment in assessments:
            if assessment.results:
                responses.append({
                    'assessment_id': assessment.id,
                    'assessment_uuid': assessment.uuid,
                    'assessment_type': assessment.assessment_type,
                    'phase': assessment.phase,
                    'responses': assessment.results,
                    'completed_at': assessment.completed_at.isoformat() if assessment.completed_at else None
                })

        return {
            'user_id': user_id,
            'responses': responses,
            'total_assessments': len(responses)
        }

    except Exception as e:
        return {'error': str(e)}, 500


# Error handlers
@main_bp.errorhandler(400)
def bad_request(error):
    return {'error': 'Bad request', 'message': str(error)}, 400

@main_bp.errorhandler(401)
def unauthorized(error):
    return {'error': 'Unauthorized', 'message': 'Authentication required'}, 401

@main_bp.errorhandler(403)
def forbidden(error):
    return {'error': 'Forbidden', 'message': 'Insufficient permissions'}, 403

@main_bp.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return {'error': 'Internal server error'}, 500