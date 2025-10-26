"""
SE-QPT Unified API Routes
Combines main platform endpoints and MVP simplified endpoints
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token, get_jwt
from datetime import datetime, timedelta
import json
import sys
import traceback
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from collections import defaultdict

from models import (
    db,
    User,
    SECompetency,
    SERole,
    Organization,
    CompetencyAssessment,
    RoleCluster,
    IsoProcesses,
    Competency,
    CompetencyIndicator,
    RoleProcessMatrix,
    ProcessCompetencyMatrix,
    RoleCompetencyMatrix,
    UnknownRoleProcessMatrix,
    UnknownRoleCompetencyMatrix,
    UserCompetencySurveyResults,
    UserRoleCluster,
    UserCompetencySurveyFeedback,
    calculate_maturity_score,
    select_archetype
)

# Import LLM feedback generation
from app.generate_survey_feedback import generate_feedback_with_llm

# =============================================================================
# BLUEPRINT 1: Main SE-QPT Platform Routes
# =============================================================================

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
        user_id = int(get_jwt_identity())
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
        user_id = int(get_jwt_identity())
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
        user_id = int(get_jwt_identity())
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
        user_id = int(get_jwt_identity())
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
        user_id = int(get_jwt_identity())
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
        current_user_id = int(get_jwt_identity())
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


# =============================================================================
# MVP SIMPLIFIED API ROUTES (merged into main_bp)
# =============================================================================

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def _initialize_organization_matrices(new_org_id):
    """
    Initialize a new organization with default role-process matrix and CALCULATE role-competency matrix.
    Copies role-process from organization_id=1 (default/template organization).
    Then CALCULATES role-competency matrix using update_role_competency_matrix stored procedure.

    FIXED BUG: Previously copied role-competency from org 1, which would propagate bad data.
    NOW: Always calculates fresh values from role-process × process-competency.

    Uses Derik's stored procedures:
    - insert_new_org_default_role_process_matrix (copies from org 1)
    - update_role_competency_matrix (calculates from matrices)

    Source: sesurveyapp-main/postgres-init/init.sql lines 251-292, 393-432
    """
    from sqlalchemy import text

    try:
        # 1. Copy role-process matrix from org 1 (always succeeds - we have 392 entries)
        db.session.execute(
            text('CALL insert_new_org_default_role_process_matrix(:org_id);'),
            {'org_id': new_org_id}
        )
        current_app.logger.info(f"[OK] Copied 392 role-process matrix entries for org {new_org_id}")

        # 2. CALCULATE role-competency matrix (don't copy - always calculate fresh!)
        # This ensures correct values even if org 1 has bad data
        try:
            db.session.execute(
                text('CALL update_role_competency_matrix(:org_id);'),
                {'org_id': new_org_id}
            )
            current_app.logger.info(f"[OK] Calculated role-competency matrix for org {new_org_id} (from role-process × process-competency)")
        except Exception as calc_error:
            # This might fail if process_competency_matrix is empty, but that's OK
            current_app.logger.warning(f"[SKIP] Role-competency calculation failed (process-competency matrix may be empty): {calc_error}")

        return True

    except Exception as e:
        current_app.logger.error(f"[ERROR] Failed to initialize matrices for org {new_org_id}: {e}")
        # Don't fail the registration - org can configure manually later
        return False


# =============================================================================
# AUTHENTICATION ENDPOINTS (4 endpoints)
# =============================================================================

@main_bp.route('/mvp/auth/login', methods=['POST'])
def login():
    """Login for both admin and employee users"""
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            return jsonify({'error': 'Username and password required'}), 400

        # Find user in MVP users table
        user = User.query.filter_by(username=username).first()

        if user and user.check_password(password):
            # Update last login
            user.last_login = datetime.utcnow()
            db.session.commit()

            # Create access token
            access_token = create_access_token(
                identity=str(user.id),
                additional_claims={
                    'organization_id': user.organization_id,
                    'role': user.role
                }
            )

            # Fetch organization details
            response_data = {
                'access_token': access_token,
                'user': user.to_dict()
            }

            # Include organization details if user belongs to one
            if user.organization_id:
                org = Organization.query.get(user.organization_id)
                if org:
                    response_data['organization'] = org.to_dict()

            return jsonify(response_data), 200

        return jsonify({'error': 'Invalid credentials'}), 401

    except Exception as e:
        current_app.logger.error(f"Login error: {str(e)}")
        return jsonify({'error': 'Login failed'}), 500


@main_bp.route('/mvp/auth/register-admin', methods=['POST'])
def register_admin():
    """Admin creates organization and becomes first user"""
    try:
        data = request.get_json()
        current_app.logger.info(f"[ADMIN REGISTRATION] Received data: {data}")

        # Required fields
        required_fields = ['username', 'password', 'organization_name', 'organization_size']
        for field in required_fields:
            if not data.get(field):
                error_msg = f'{field} is required'
                current_app.logger.error(f"[ADMIN REGISTRATION] Validation failed: {error_msg}")
                return jsonify({'error': error_msg}), 400

        # Check if username already exists
        if User.query.filter_by(username=data['username']).first():
            error_msg = 'Username already registered'
            current_app.logger.error(f"[ADMIN REGISTRATION] Username conflict: {data['username']}")
            return jsonify({'error': error_msg}), 400

        # Create organization (using Derik's unified model)
        org_code = Organization.generate_public_key(data['organization_name'])
        organization = Organization(
            organization_name=data['organization_name'],
            organization_public_key=org_code,
            size=data['organization_size']
        )
        db.session.add(organization)
        db.session.flush()  # Get organization ID

        # Initialize organization with default matrices
        _initialize_organization_matrices(organization.id)
        current_app.logger.info(f"[ADMIN REGISTRATION] Initialized default matrices for org {organization.id}")

        # Create admin user
        admin_user = User(
            username=data['username'],
            first_name=data.get('first_name'),  # Optional
            last_name=data.get('last_name'),    # Optional
            role='admin',
            organization_id=organization.id,
            joined_via_code=org_code
        )
        admin_user.set_password(data['password'])
        db.session.add(admin_user)
        db.session.commit()

        # Create access token
        access_token = create_access_token(
            identity=str(admin_user.id),
            additional_claims={
                'organization_id': organization.id,
                'role': 'admin'
            }
        )

        return jsonify({
            'access_token': access_token,
            'user': admin_user.to_dict(),
            'organization': organization.to_dict(),
            'organization_code': org_code
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Admin registration error: {str(e)}")
        return jsonify({'error': 'Registration failed'}), 500


@main_bp.route('/mvp/auth/register-employee', methods=['POST'])
def register_employee():
    """Employee joins organization with organization code"""
    try:
        data = request.get_json()

        # Required fields
        required_fields = ['username', 'password', 'organization_code']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400

        # Check if username already exists
        if User.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already registered'}), 400

        # Validate organization code (using Derik's organization_public_key field)
        organization = Organization.query.filter_by(
            organization_public_key=data['organization_code'].upper()
        ).first()

        if not organization:
            return jsonify({'error': 'Invalid organization code'}), 400

        # Create employee user
        employee_user = User(
            username=data['username'],
            first_name=data.get('first_name'),  # Optional
            last_name=data.get('last_name'),    # Optional
            role='employee',
            organization_id=organization.id,
            joined_via_code=data['organization_code'].upper()
        )
        employee_user.set_password(data['password'])
        db.session.add(employee_user)
        db.session.commit()

        # Create access token
        access_token = create_access_token(
            identity=str(employee_user.id),
            additional_claims={
                'organization_id': organization.id,
                'role': 'employee'
            }
        )

        return jsonify({
            'access_token': access_token,
            'user': employee_user.to_dict(),
            'organization': organization.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Employee registration error: {str(e)}")
        return jsonify({'error': 'Registration failed'}), 500


@main_bp.route('/api/auth/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current user information"""
    try:
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({'user': user.to_dict()}), 200

    except Exception as e:
        current_app.logger.error(f"Get current user error: {str(e)}")
        return jsonify({'error': 'Failed to get user info'}), 500

@main_bp.route('/auth/verify', methods=['GET'])
@jwt_required()
def verify_auth():
    """Verify JWT token and return user info (compatibility endpoint)"""
    try:
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({'user': user.to_dict()}), 200

    except Exception as e:
        current_app.logger.error(f"Auth verification error: {str(e)}")
        return jsonify({'error': 'Token verification failed'}), 401

@main_bp.route('/mvp/auth/logout', methods=['POST'])
def logout():
    """Logout endpoint (for MVP - since JWT tokens are stateless, this is mainly for client-side cleanup)"""
    try:
        # For JWT tokens, logout is mainly handled client-side
        # Server-side logout would require token blacklisting which is not implemented in MVP
        return jsonify({'message': 'Logged out successfully'}), 200
    except Exception as e:
        current_app.logger.error(f"Logout error: {str(e)}")
        return jsonify({'error': 'Logout failed'}), 500


# =============================================================================
# ORGANIZATION MANAGEMENT ENDPOINTS (3 endpoints)
# =============================================================================

@main_bp.route('/api/organization/setup', methods=['POST'])
@jwt_required()
def organization_setup():
    """Update organization details (Admin only)"""
    try:
        user_id = int(get_jwt_identity())
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = User.query.get(user_id)
        organization = Organization.query.get(user.organization_id)

        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        data = request.get_json()

        # Update organization details (using Derik's field names)
        if 'name' in data:
            organization.organization_name = data['name']
        if 'size' in data:
            organization.size = data['size']

        db.session.commit()

        return jsonify({'organization': organization.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Organization setup error: {str(e)}")
        return jsonify({'error': 'Organization setup failed'}), 500


@main_bp.route('/api/organization/verify-code/<code>', methods=['GET'])
def verify_organization_code(code):
    """Verify organization code for employee registration"""
    try:
        organization = Organization.query.filter_by(organization_public_key=code.upper()).first()

        if organization:
            return jsonify({
                'valid': True,
                'organization_name': organization.organization_name
            }), 200
        else:
            return jsonify({
                'valid': False,
                'organization_name': None
            }), 200

    except Exception as e:
        current_app.logger.error(f"Organization verification error: {str(e)}")
        return jsonify({'error': 'Verification failed'}), 500


@main_bp.route('/api/organization/dashboard', methods=['GET'])
def organization_dashboard():
    """Get organization dashboard data - supports both JWT and query param authentication"""
    print("=" * 80)
    print("ORGANIZATION DASHBOARD ENDPOINT HIT!")
    print("=" * 80)
    sys.stdout.flush()
    try:
        # Try to get user from JWT token
        auth_header = request.headers.get('Authorization')
        user_id = None
        user = None
        organization = None

        print(f"DEBUG: Authorization header: {auth_header}")
        sys.stdout.flush()

        if auth_header and auth_header.startswith('Bearer '):
            # Try JWT authentication
            try:
                from flask_jwt_extended import verify_jwt_in_request
                verify_jwt_in_request(optional=True)
                user_id = int(get_jwt_identity())
                if user_id:
                    claims = get_jwt()
                    print(f"DEBUG: User ID from JWT: {user_id}, Role: {claims.get('role')}")
                    current_app.logger.info(f"DEBUG: Organization dashboard requested by user {user_id}, role: {claims.get('role')}")
                    user = User.query.get(user_id)
                    if user:
                        organization = Organization.query.get(user.organization_id)
            except Exception as jwt_error:
                print(f"DEBUG: JWT verification failed: {jwt_error}")
                # Continue to query param fallback

        # If no JWT or JWT failed, try query parameters
        if not organization:
            org_code = request.args.get('code')
            org_id = request.args.get('id')

            print(f"DEBUG: Using query params - code: {org_code}, id: {org_id}")
            sys.stdout.flush()

            if org_code:
                organization = Organization.query.filter_by(organization_public_key=org_code).first()
            elif org_id:
                organization = Organization.query.get(int(org_id))

        current_app.logger.info(f"DEBUG: Found user: {user.username if user else 'None'}")
        current_app.logger.info(f"DEBUG: Organization ID: {user.organization_id if user else 'None'}")
        current_app.logger.info(f"DEBUG: Organization: {organization.organization_name if organization else 'None'}")

        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        # Get organization statistics
        total_users = User.query.filter_by(organization_id=organization.id).count()

        # Get completed assessments - use proper join with select_from
        try:
            completed_assessments = db.session.query(CompetencyAssessment).select_from(User).join(
                CompetencyAssessment, User.id == CompetencyAssessment.user_id
            ).filter(
                User.organization_id == organization.id
            ).count()
        except Exception as e:
            print(f"DEBUG: Completed assessments query failed: {e}")
            completed_assessments = 0

        # REMOVED Phase 2A: MaturityAssessment model deleted - data now comes from questionnaire system
        # maturity_assessment = MaturityAssessment.query.filter_by(organization_id=organization.id).first()

        # BRIDGE: Check questionnaire system for Phase 1 assessment data
        questionnaire_maturity_data = None
        selected_archetype = organization.selected_archetype  # Default fallback

        try:
            # Import questionnaire models to check for completed assessments
            from models import QuestionnaireResponse, Questionnaire

            current_app.logger.info(f"DEBUG: Starting bridge check for organization {organization.id}")

            # Find admin users in this organization who completed Phase 1
            admin_users = User.query.filter_by(
                organization_id=organization.id,
                role='admin'
            ).all()

            current_app.logger.info(f"DEBUG: Found {len(admin_users)} admin users in organization")

            for admin_user in admin_users:
                current_app.logger.info(f"DEBUG: Checking admin user {admin_user.id} ({admin_user.username})")

                # Check for completed maturity assessment (questionnaire ID 1)
                # ORDER BY completed_at DESC to get the LATEST assessment
                maturity_response = QuestionnaireResponse.query.filter_by(
                    user_id=str(admin_user.id),
                    questionnaire_id=1,
                    status='completed'
                ).order_by(QuestionnaireResponse.completed_at.desc()).first()

                current_app.logger.info(f"DEBUG: Maturity response found: {maturity_response is not None}")
                if maturity_response:
                    current_app.logger.info(f"DEBUG: Maturity score: {maturity_response.total_score}/{maturity_response.max_possible_score} (completed: {maturity_response.completed_at})")

                # Check for completed archetype selection (questionnaire ID 2)
                # ORDER BY completed_at DESC to get the LATEST archetype selection
                archetype_response = QuestionnaireResponse.query.filter_by(
                    user_id=str(admin_user.id),
                    questionnaire_id=2,
                    status='completed'
                ).order_by(QuestionnaireResponse.completed_at.desc()).first()

                current_app.logger.info(f"DEBUG: Archetype response found: {archetype_response is not None}")

                if maturity_response and archetype_response:
                    current_app.logger.info(f"DEBUG: Found both responses! Creating bridge data...")

                    # CRITICAL: Extract computed archetype from questionnaire response (including secondary)
                    secondary_archetype = None
                    if archetype_response.computed_archetype:
                        try:
                            import json
                            computed_data = json.loads(archetype_response.computed_archetype)
                            selected_archetype = computed_data.get('name', selected_archetype)
                            secondary_archetype = computed_data.get('secondary')  # Extract secondary archetype
                            current_app.logger.info(f"DEBUG: Extracted archetype from computed data: {selected_archetype}, secondary: {secondary_archetype}")
                        except json.JSONDecodeError as e:
                            current_app.logger.error(f"DEBUG: Failed to parse computed_archetype JSON: {e}")
                    else:
                        current_app.logger.warning(f"DEBUG: No computed_archetype data found in archetype response")

                    # Create maturity assessment data from questionnaire responses
                    # Use archetype_response.completed_at for accurate timestamp
                    questionnaire_maturity_data = {
                        'id': maturity_response.uuid,
                        'organization_id': organization.id,
                        'overall_score': maturity_response.total_score / maturity_response.max_possible_score * 5.0 if maturity_response.max_possible_score > 0 else 0,
                        'scope_score': 2.5,  # Default - could be calculated from specific questions
                        'process_score': 2.5,  # Default - could be calculated from specific questions
                        'overall_maturity': get_maturity_level_from_score(maturity_response.total_score / maturity_response.max_possible_score * 5.0 if maturity_response.max_possible_score > 0 else 0),
                        'completed_at': archetype_response.completed_at.isoformat() if archetype_response.completed_at else None,  # Use archetype completion time
                        'responses': None,
                        'secondary_archetype': secondary_archetype  # Include secondary archetype
                    }
                    current_app.logger.info(f"DEBUG: Bridge data created with score: {questionnaire_maturity_data['overall_score']}, archetype: {selected_archetype}, secondary: {secondary_archetype}")
                    break  # Use first completed assessment found

        except ImportError as e:
            current_app.logger.warning(f"Could not import questionnaire models: {e}")
        except Exception as e:
            current_app.logger.error(f"Error checking questionnaire system: {e}")
            import traceback
            current_app.logger.error(f"Traceback: {traceback.format_exc()}")

        # Use questionnaire data (MaturityAssessment model was removed in Phase 2A)
        final_maturity_assessment = questionnaire_maturity_data

        # Extract secondary archetype from questionnaire data if available
        final_secondary_archetype = questionnaire_maturity_data.get('secondary_archetype') if questionnaire_maturity_data else None

        # Log the timestamps being sent
        if final_maturity_assessment:
            current_app.logger.info(f"DEBUG: Sending completion timestamp: {final_maturity_assessment.get('completed_at')}")

        dashboard_data = {
            'organization': {
                **organization.to_dict(),
                'selected_archetype': selected_archetype,
                'secondary_archetype': final_secondary_archetype  # Include secondary archetype
            },
            'statistics': {
                'total_users': total_users,
                'completed_assessments': completed_assessments,
                'maturity_completed': final_maturity_assessment is not None
            },
            'maturity_assessment': final_maturity_assessment
        }

        return jsonify(dashboard_data), 200

    except Exception as e:
        current_app.logger.error(f"Organization dashboard error: {str(e)}")
        return jsonify({'error': 'Failed to load dashboard'}), 500


def get_maturity_level_from_score(score):
    """Convert maturity score to level name"""
    if score >= 4.0:
        return 'Optimizing'
    elif score >= 3.0:
        return 'Defined'
    elif score >= 2.0:
        return 'Managed'
    elif score >= 1.0:
        return 'Performed'
    else:
        return 'Initial'


@main_bp.route('/api/organization/archetype', methods=['PUT'])
@jwt_required()
def update_organization_archetype():
    """Update organization's selected archetype (Admin only)"""
    try:
        user_id = int(get_jwt_identity())
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = User.query.get(user_id)
        organization = Organization.query.get(user.organization_id)

        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        data = request.get_json()
        archetype = data.get('selected_archetype')

        if not archetype:
            return jsonify({'error': 'selected_archetype is required'}), 400

        organization.selected_archetype = archetype
        db.session.commit()

        return jsonify({'organization': organization.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Update archetype error: {str(e)}")
        return jsonify({'error': 'Failed to update archetype'}), 500


@main_bp.route('/api/organization/phase1-complete', methods=['PUT'])
@jwt_required()
def complete_phase1():
    """Mark Phase 1 as complete for organization (Admin only)"""
    try:
        user_id = int(get_jwt_identity())
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = User.query.get(user_id)
        organization = Organization.query.get(user.organization_id)

        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        data = request.get_json()
        maturity_score = data.get('maturity_score')
        selected_archetype = data.get('selected_archetype')

        # Update organization with Phase 1 completion data
        if maturity_score is not None:
            organization.maturity_score = maturity_score
        if selected_archetype:
            organization.selected_archetype = selected_archetype

        organization.phase1_completed = True
        db.session.commit()

        current_app.logger.info(f"Phase 1 completed for organization {organization.id}")
        return jsonify({'organization': organization.to_dict()}), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Phase 1 completion error: {str(e)}")
        return jsonify({'error': 'Failed to mark Phase 1 as complete'}), 500


# =============================================================================
# ASSESSMENT ENDPOINTS (3 endpoints)
# NOTE: Maturity assessment is handled by questionnaire system (questionnaire ID 1)
#       Archetype selection is handled by /api/seqpt/phase1/archetype-selection
# =============================================================================

@main_bp.route('/api/assessments/competency', methods=['POST'])
@jwt_required()
def submit_competency_assessment():
    """Submit individual competency assessment (All users)"""
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()

        # Validate competency scores
        competency_scores = data.get('competency_scores')
        if not competency_scores:
            return jsonify({'error': 'competency_scores required'}), 400

        # Create competency assessment record
        assessment = CompetencyAssessment(
            user_id=user_id,
            role_cluster=data.get('role_cluster', 'Unknown')
        )
        assessment.set_competency_scores(competency_scores)
        db.session.add(assessment)
        db.session.commit()

        return jsonify({'assessment': assessment.to_dict()}), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Competency assessment error: {str(e)}")
        return jsonify({'error': 'Failed to submit assessment'}), 500


@main_bp.route('/api/assessments/results/<user_id>', methods=['GET'])
@jwt_required()
def get_user_assessment_results_legacy(user_id):
    """Get assessment results for a user (legacy endpoint)"""
    try:
        current_user_id = int(get_jwt_identity())
        claims = get_jwt()

        # Users can only see their own results, admins can see all
        if user_id != current_user_id and claims.get('role') != 'admin':
            return jsonify({'error': 'Access denied'}), 403

        # Get competency assessment
        competency_assessment = CompetencyAssessment.query.filter_by(
            user_id=user_id
        ).first()

        # Get role mapping
        role_mapping = RoleMapping.query.filter_by(user_id=user_id).first()

        # Get learning plan
        learning_plan = LearningPlan.query.filter_by(user_id=user_id).first()

        results = {
            'competency_assessment': competency_assessment.to_dict() if competency_assessment else None,
            'role_mapping': role_mapping.to_dict() if role_mapping else None,
            'learning_plan': learning_plan.to_dict() if learning_plan else None
        }

        return jsonify(results), 200

    except Exception as e:
        current_app.logger.error(f"Get assessment results error: {str(e)}")
        return jsonify({'error': 'Failed to get results'}), 500


@main_bp.route('/api/assessments/organization-summary', methods=['GET'])
@jwt_required()
def get_organization_assessment_summary():
    """Get organization-wide assessment summary (Admin only)"""
    try:
        user_id = int(get_jwt_identity())
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = User.query.get(user_id)

        # Get all users in organization
        org_users = User.query.filter_by(organization_id=user.organization_id).all()

        # Get completion statistics
        total_users = len(org_users)
        completed_competency = CompetencyAssessment.query.join(User).filter(
            User.organization_id == user.organization_id
        ).count()

        # REMOVED Phase 2A: MaturityAssessment model deleted - data comes from questionnaire system
        # maturity_assessment = MaturityAssessment.query.filter_by(organization_id=user.organization_id).first()

        summary = {
            'total_users': total_users,
            'completed_competency_assessments': completed_competency,
            'completion_rate': (completed_competency / total_users * 100) if total_users > 0 else 0,
            'maturity_assessment': None  # MaturityAssessment removed - use dashboard endpoint for full data
        }

        return jsonify(summary), 200

    except Exception as e:
        current_app.logger.error(f"Organization summary error: {str(e)}")
        return jsonify({'error': 'Failed to get summary'}), 500


# =============================================================================
# LEARNING PLAN ENDPOINTS (2 endpoints)
# =============================================================================

@main_bp.route('/api/learning-plan/<user_id>', methods=['GET'])
@jwt_required()
def get_learning_plan(user_id):
    """Get learning plan for a user"""
    try:
        current_user_id = int(get_jwt_identity())
        claims = get_jwt()

        # Users can only see their own plan, admins can see all
        if user_id != current_user_id and claims.get('role') != 'admin':
            return jsonify({'error': 'Access denied'}), 403

        learning_plan = LearningPlan.query.filter_by(user_id=user_id).first()

        if not learning_plan:
            return jsonify({'error': 'Learning plan not found'}), 404

        return jsonify({'learning_plan': learning_plan.to_dict()}), 200

    except Exception as e:
        current_app.logger.error(f"Get learning plan error: {str(e)}")
        return jsonify({'error': 'Failed to get learning plan'}), 500


@main_bp.route('/api/learning-plan/generate', methods=['POST'])
@jwt_required()
def generate_learning_plan():
    """Generate learning plan for current user"""
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()

        # Get user's competency assessment
        competency_assessment = CompetencyAssessment.query.filter_by(
            user_id=user_id
        ).first()

        if not competency_assessment:
            return jsonify({'error': 'Competency assessment required first'}), 400

        # Get organization's selected archetype
        user = User.query.get(user_id)
        organization = Organization.query.get(user.organization_id)

        archetype = data.get('archetype') or organization.selected_archetype
        if not archetype:
            return jsonify({'error': 'No archetype available'}), 400

        # Generate learning plan using templates
        templates = generate_learning_plan_templates()
        objectives = templates.get(archetype, [])
        recommended_modules = generate_basic_modules(archetype)

        # Create or update learning plan
        learning_plan = LearningPlan.query.filter_by(user_id=user_id).first()
        if not learning_plan:
            learning_plan = LearningPlan(user_id=user_id)
            db.session.add(learning_plan)

        learning_plan.set_objectives(objectives)
        learning_plan.set_recommended_modules(recommended_modules)
        learning_plan.estimated_duration_weeks = len(objectives) * 2  # 2 weeks per objective
        learning_plan.archetype_used = archetype

        db.session.commit()

        return jsonify({'learning_plan': learning_plan.to_dict()}), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Generate learning plan error: {str(e)}")
        return jsonify({'error': 'Failed to generate learning plan'}), 500


# =============================================================================
# QUESTIONNAIRE COMPATIBILITY ENDPOINTS
# =============================================================================

@main_bp.route('/api/public/users/<string:user_id>/responses', methods=['GET'])
def get_user_questionnaire_responses_uuid(user_id):
    """Public endpoint for questionnaire responses using UUID user IDs (compatibility)"""
    try:
        # Import the models from models.py to avoid circular imports
        from models import QuestionnaireResponse, Questionnaire, User

        import sys
        debug_msg = f"DEBUG: MVP public endpoint accessed for user UUID {user_id}"
        print(debug_msg)
        sys.stdout.flush()

        # CRITICAL: The questionnaire system uses integer User IDs, not UUIDs
        # We need to find the User by UUID first, then query responses by integer ID
        user = User.query.filter_by(uuid=user_id).first()

        if not user:
            debug_msg = f"DEBUG: No user found with UUID {user_id}"
            print(debug_msg)
            sys.stdout.flush()
            return jsonify({
                'success': True,
                'responses': [],
                'total_count': 0
            }), 200

        debug_msg = f"DEBUG: Found user ID {user.id} for UUID {user_id}"
        print(debug_msg)
        sys.stdout.flush()

        # Query responses using the integer user ID
        responses = QuestionnaireResponse.query.filter_by(user_id=user.id).order_by(QuestionnaireResponse.started_at.desc()).all()

        debug_msg = f"DEBUG: Found {len(responses)} responses for user ID {user.id}"
        print(debug_msg)
        sys.stdout.flush()

        responses_data = []
        for response in responses:
            questionnaire_name = 'Unknown Questionnaire'
            questionnaire_type = 'unknown'

            if response.questionnaire:
                questionnaire_name = response.questionnaire.name
                questionnaire_type = response.questionnaire.questionnaire_type

            responses_data.append({
                'uuid': response.uuid,
                'questionnaire_id': response.questionnaire_id,
                'questionnaire_name': questionnaire_name,
                'questionnaire_type': questionnaire_type,
                'started_at': response.started_at.isoformat() if response.started_at else None,
                'completed_at': response.completed_at.isoformat() if response.completed_at else None,
                'status': response.status,
                'is_completed': response.status == 'completed',
                'phase_name': getattr(response, 'phase_name', None),
                'current_score': getattr(response, 'total_score', None),
                'max_score': getattr(response, 'max_possible_score', None),
                'completion_percentage': response.completion_percentage if response.completion_percentage else 0.0
            })

        debug_msg = f"DEBUG: MVP endpoint returning {len(responses_data)} responses for user {user_id}"
        print(debug_msg)
        sys.stdout.flush()

        return jsonify({
            'success': True,
            'responses': responses_data,
            'total_count': len(responses_data)
        }), 200

    except Exception as e:
        import traceback
        debug_msg = f"DEBUG: Error in MVP public endpoint: {str(e)}"
        print(debug_msg)
        print(f"Traceback: {traceback.format_exc()}")
        sys.stdout.flush()
        return jsonify({'error': 'Failed to get questionnaire responses'}), 500


# =============================================================================
# PHASE 1 API ENDPOINTS
# Maturity Assessment, Role Identification, Target Group, and Strategy Selection
# =============================================================================

@main_bp.route('/api/phase1/maturity/<int:org_id>/latest', methods=['GET'])
def get_latest_maturity_assessment(org_id):
    """Get latest maturity assessment for an organization"""
    try:
        from models import PhaseQuestionnaireResponse, Organization

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


@main_bp.route('/api/phase1/maturity/save', methods=['POST'])
def save_maturity_assessment():
    """Save maturity assessment results"""
    try:
        from models import PhaseQuestionnaireResponse
        from flask_jwt_extended import verify_jwt_in_request

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


@main_bp.route('/api/phase1/roles/<int:org_id>/latest', methods=['GET'])
def get_latest_roles(org_id):
    """Get latest role identification for an organization"""
    try:
        from models import PhaseQuestionnaireResponse, Organization

        # Verify organization exists
        org = Organization.query.get(org_id)
        if not org:
            return jsonify({'error': 'Organization not found'}), 404

        # Get latest role identification
        roles = PhaseQuestionnaireResponse.query.filter_by(
            organization_id=org_id,
            questionnaire_type='roles',
            phase=1
        ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

        if not roles:
            return jsonify({
                'success': True,
                'data': None,
                'count': 0
            }), 200

        # Parse the response
        response_data = roles.get_responses()
        roles_list = response_data.get('roles', []) if isinstance(response_data, dict) else []

        return jsonify({
            'success': True,
            'data': roles_list,
            'count': len(roles_list),
            'maturityId': response_data.get('maturityId') if isinstance(response_data, dict) else None,
            'completed_at': roles.completed_at.isoformat() if roles.completed_at else None
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting roles: {str(e)}")
        return jsonify({'error': 'Failed to get roles'}), 500


@main_bp.route('/api/phase1/roles/save', methods=['POST'])
def save_roles():
    """Save identified SE roles for an organization"""
    try:
        from models import PhaseQuestionnaireResponse
        from flask_jwt_extended import verify_jwt_in_request

        data = request.get_json()

        org_id = data.get('org_id')
        roles = data.get('roles', [])
        identification_method = data.get('identification_method', 'STANDARD')

        if not org_id:
            return jsonify({'error': 'org_id is required'}), 400

        # VALIDATION: Check for duplicate standardRoleId values
        seen_role_ids = set()
        deduplicated_roles = []
        duplicates_found = []

        for role in roles:
            role_id = role.get('standardRoleId')
            if role_id is None:
                continue  # Skip roles without standardRoleId

            if role_id in seen_role_ids:
                duplicates_found.append(f"{role.get('standardRoleName', 'Unknown')} (ID: {role_id})")
                current_app.logger.warning(f"[DUPLICATE DETECTED] Role ID {role_id} appears multiple times in submission for org {org_id}")
            else:
                seen_role_ids.add(role_id)
                deduplicated_roles.append(role)

        # Log if duplicates were removed
        if duplicates_found:
            current_app.logger.info(f"[DEDUPLICATION] Removed {len(duplicates_found)} duplicate role(s) for org {org_id}: {', '.join(duplicates_found)}")

        # Use deduplicated roles
        roles = deduplicated_roles

        # Get user ID from JWT if available
        user_id = 1  # Default fallback
        try:
            verify_jwt_in_request(optional=True)
            jwt_user_id = get_jwt_identity()
            if jwt_user_id:
                user_id = int(jwt_user_id) if isinstance(jwt_user_id, str) else jwt_user_id
        except Exception:
            pass  # Use default user_id

        # Create new role identification
        role_data = PhaseQuestionnaireResponse(
            organization_id=org_id,
            user_id=user_id,
            questionnaire_type='roles',
            phase=1
        )
        role_data.set_responses({
            'roles': roles,
            'identification_method': identification_method
        })

        db.session.add(role_data)
        db.session.commit()

        return jsonify({
            'success': True,
            'id': role_data.id,
            'message': 'Roles saved successfully',
            'roles': roles,
            'count': len(roles)
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving roles: {str(e)}")
        return jsonify({'error': 'Failed to save roles'}), 500


@main_bp.route('/findProcesses', methods=['POST'])
def find_processes():
    """
    Map user tasks to ISO/IEC 15288 SE processes using AI
    Used in Phase 1 task-based role identification pathway
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No input provided"}), 400

        # Extract required fields
        username = data.get('username')
        organization_id = data.get('organizationId')
        tasks = data.get('tasks', {})

        if not username or not organization_id:
            return jsonify({"error": "Username or Organization ID missing"}), 400

        # Extract task categories with defaults
        tasks_responsibilities = {
            "responsible_for": tasks.get("responsible_for", []),
            "supporting": tasks.get("supporting", []),
            "designing": tasks.get("designing", [])
        }

        print(f"[findProcesses] Processing tasks for user: {username}, org: {organization_id}")
        print(f"[findProcesses] Tasks: {tasks_responsibilities}")

        # Try to use LLM pipeline if available
        llm_success = False
        try:
            from app.services.llm_pipeline import llm_process_identification_pipeline
            pipeline = llm_process_identification_pipeline.create_pipeline()

            result = pipeline(tasks_responsibilities)

            # Handle invalid tasks case
            if result.get("status") == "invalid_tasks":
                return jsonify({
                    "status": "invalid_tasks",
                    "message": result.get("message", "Tasks are invalid or empty")
                }), 400

            # Handle success case
            elif result.get("status") == "success":
                # Extract process involvement from LLM result
                llm_result = result.get("result")
                processes_list = llm_result.processes if hasattr(llm_result, 'processes') else []

                # Format response for frontend
                processes = [
                    {
                        "process_name": process.process_name,
                        "involvement": process.involvement
                    }
                    for process in processes_list
                ]

                llm_success = True

                # Extract LLM role suggestion if available
                llm_role_suggestion = result.get("llm_role_suggestion", None)

                # DERIK'S APPROACH: Store in UnknownRoleProcessMatrix for competency calculation
                try:
                    from models import UnknownRoleProcessMatrix, IsoProcesses, db
                    from sqlalchemy import text

                    # Fetch ALL ISO Processes from database
                    iso_processes = IsoProcesses.query.with_entities(IsoProcesses.id, IsoProcesses.name).all()
                    iso_process_map = {
                        process.name.strip().lower(): process.id for process in iso_processes
                    }

                    # Create process involvement map from LLM result
                    # Strip " process" suffix from LLM output to match database format
                    llm_process_map = {}
                    for process in processes:
                        name = process.get('process_name', '').strip().lower()
                        # Remove " process" suffix if present
                        if name.endswith(' process'):
                            name = name[:-8]  # Remove last 8 characters (" process")
                        llm_process_map[name] = process.get('involvement', 'Not performing')

                    # Delete existing entries for this user to avoid duplicates
                    UnknownRoleProcessMatrix.query.filter_by(
                        user_name=username,
                        organization_id=organization_id
                    ).delete()

                    # Prepare rows to insert (one row per ISO process)
                    rows_to_insert = []
                    for process in iso_processes:
                        process_name = process.name.strip().lower()
                        iso_process_id = process.id

                        # Determine involvement from LLM output
                        involvement = llm_process_map.get(process_name, "Not performing")

                        # Map involvement to numeric value
                        involvement_values = {
                            "Responsible": 2,
                            "Supporting": 1,
                            "Designing": 4,  # Fixed: was 3, should be 4
                            "Not performing": 0
                        }
                        role_process_value = involvement_values.get(involvement, 0)

                        # Add row to insert
                        rows_to_insert.append(UnknownRoleProcessMatrix(
                            user_name=username,
                            iso_process_id=iso_process_id,
                            role_process_value=role_process_value,
                            organization_id=organization_id
                        ))

                    # Bulk insert
                    if rows_to_insert:
                        db.session.bulk_save_objects(rows_to_insert)
                        db.session.commit()

                    # Call stored procedure to calculate competency requirements from process involvement
                    try:
                        db.session.execute(
                            text("CALL update_unknown_role_competency_values(:username, :organization_id);"),
                            {"username": username, "organization_id": organization_id}
                        )
                        db.session.commit()
                    except Exception as proc_error:
                        db.session.rollback()
                        # Continue anyway - competency calculation can be done later

                except Exception as db_error:
                    db.session.rollback()
                    # Continue anyway - return processes to frontend

                response_data = {
                    "status": "success",
                    "processes": processes
                }

                # Add LLM role suggestion if available
                if llm_role_suggestion:
                    response_data["llm_role_suggestion"] = llm_role_suggestion

                return jsonify(response_data), 200

        except ImportError as import_err:
            pass  # LLM pipeline not available, use fallback
        except Exception as llm_err:
            pass  # LLM pipeline error, use fallback

        # Fallback: Simple keyword-based process identification
        if not llm_success:
            print("=" * 80)
            print("[WARNING] LLM pipeline unavailable - falling back to keyword matching")
            print("[INFO] This is a simplified fallback mechanism with limited accuracy")
            print("[INFO] For better results, ensure LLM pipeline is properly configured")
            print("=" * 80)
            processes = []
            combined_tasks = ' '.join(
                tasks_responsibilities.get("responsible_for", []) +
                tasks_responsibilities.get("supporting", []) +
                tasks_responsibilities.get("designing", [])
            ).lower()

            # Map keywords to ISO 15288 processes
            process_keywords = {
                'Business or Mission Analysis': ['business', 'mission', 'strategy', 'goals', 'objectives'],
                'Stakeholder Needs and Requirements Definition': ['stakeholder', 'needs', 'requirements', 'gather', 'elicit'],
                'System Requirements Definition': ['system requirements', 'specification', 'define requirements'],
                'System Architecture Definition': ['architecture', 'design', 'structure', 'components', 'interfaces'],
                'Implementation': ['implement', 'code', 'develop', 'build', 'program'],
                'Integration': ['integrate', 'combine', 'merge', 'connect', 'assemble'],
                'Verification': ['verify', 'test', 'check', 'validate', 'inspect'],
                'Transition': ['deploy', 'release', 'transition', 'deliver', 'install'],
                'Validation': ['validate', 'acceptance', 'user testing', 'customer'],
                'Operation': ['operate', 'run', 'maintain', 'monitor', 'support'],
                'Maintenance': ['maintain', 'fix', 'update', 'patch', 'service'],
                'Disposal': ['dispose', 'retire', 'decommission', 'remove', 'shutdown']
            }

            for process_name, keywords in process_keywords.items():
                if any(keyword in combined_tasks for keyword in keywords):
                    # Determine involvement based on task category
                    if any(keyword in ' '.join(tasks_responsibilities.get("designing", [])).lower() for keyword in keywords):
                        involvement = "Designing"
                    elif any(keyword in ' '.join(tasks_responsibilities.get("responsible_for", [])).lower() for keyword in keywords):
                        involvement = "Responsible"
                    else:
                        involvement = "Supporting"

                    processes.append({
                        "process_name": process_name,
                        "involvement": involvement
                    })

            # Default processes if none found
            if not processes:
                processes = [
                    {"process_name": "System Architecture Definition", "involvement": "Responsible"},
                    {"process_name": "System Requirements Definition", "involvement": "Responsible"},
                    {"process_name": "Implementation", "involvement": "Responsible"}
                ]

            print(f"[findProcesses] Fallback identified {len(processes)} processes")

            return jsonify({
                "status": "success",
                "processes": processes,
                "fallback": True
            }), 200

    except Exception as e:
        print(f"[findProcesses] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@main_bp.route('/api/phase1/roles/suggest-from-processes', methods=['POST'])
def suggest_role_from_processes():
    """
    DERIK'S SIMPLE APPROACH: Pure competency-based distance matching
    - Uses Euclidean distance between user and role competency vectors
    - Returns role(s) with minimum distance
    - Confidence based on distance separation
    """
    try:
        from models import RoleCluster, UnknownRoleCompetencyMatrix
        from app.most_similar_role import find_most_similar_role_cluster

        data = request.get_json()

        if not data:
            return jsonify({'error': 'No input provided'}), 400

        username = data.get('username')
        organization_id = data.get('organizationId', 11)

        if not username:
            return jsonify({'error': 'Username required'}), 400

        print(f"[suggest-role-simple] Analyzing user: {username} (org: {organization_id})")

        # ====================
        # STEP 1: Get user's competency requirements
        # ====================
        competencies = UnknownRoleCompetencyMatrix.query.filter_by(
            user_name=username,
            organization_id=organization_id
        ).all()

        if not competencies:
            print(f"[suggest-role-simple] No competency data for user: {username}")
            return jsonify({
                'error': 'No competency data available. Please complete task analysis first.',
                'debug': {
                    'username': username,
                    'organization_id': organization_id,
                    'hint': 'Call /findProcesses endpoint first'
                }
            }), 400

        user_scores = [
            {'competency_id': c.competency_id, 'score': c.role_competency_value}
            for c in competencies
        ]

        print(f"[suggest-role-simple] User has {len(user_scores)} competency requirements")

        # ====================
        # STEP 2: Find most similar role using Euclidean distance
        # ====================
        result = find_most_similar_role_cluster(organization_id, user_scores)

        if not result or not result.get('role_ids'):
            print("[suggest-role-simple] No similar roles found")
            return jsonify({
                'error': 'No matching roles found',
                'debug': result
            }), 404

        # ====================
        # STEP 3: Calculate confidence based on distance separation
        # ====================
        best_role_id = result['role_ids'][0]
        distances = result['distances']['euclidean']
        metric_agreement = result.get('metric_agreement', 0)

        # Get all distances sorted
        sorted_distances = sorted(distances.items(), key=lambda x: x[1])

        if len(sorted_distances) >= 2:
            best_distance = sorted_distances[0][1]
            second_best_distance = sorted_distances[1][1]

            # Calculate separation (how much better is #1 vs #2)
            if second_best_distance > 0:
                separation = (second_best_distance - best_distance) / second_best_distance
            else:
                separation = 1.0

            # Confidence based on:
            # 1. All 3 distance metrics agree (metric_agreement = 3): +0.15
            # 2. Good separation from second best: up to +0.30
            base_confidence = 0.55
            agreement_bonus = 0.15 if metric_agreement == 3 else (0.10 if metric_agreement == 2 else 0.05)
            separation_bonus = separation * 0.30

            confidence = min(base_confidence + agreement_bonus + separation_bonus, 0.95)
        else:
            # Only one role found
            confidence = 0.80 if metric_agreement == 3 else 0.70

        print(f"[suggest-role-simple] Best role ID: {best_role_id}")
        print(f"[suggest-role-simple] Euclidean distance: {distances[best_role_id]:.4f}")
        print(f"[suggest-role-simple] Metric agreement: {metric_agreement}/3")
        print(f"[suggest-role-simple] Confidence: {confidence:.0%}")

        # ====================
        # STEP 4: Build response
        # ====================
        best_role = RoleCluster.query.get(best_role_id)

        if not best_role:
            return jsonify({'error': 'Role not found in database'}), 500

        # Get alternative roles (next 2 best matches)
        alternative_roles = []
        for role_id, distance in sorted_distances[1:3]:
            role = RoleCluster.query.get(role_id)
            if role:
                alt_confidence = confidence * 0.75  # Lower confidence for alternatives
                alt_role_dict = role.to_dict()
                alt_role_dict['confidence'] = round(alt_confidence, 2)
                alt_role_dict['distance'] = round(distance, 4)
                alternative_roles.append(alt_role_dict)

        response_data = {
            'suggestedRole': best_role.to_dict(),
            'confidence': round(confidence, 2),
            'alternativeRoles': alternative_roles,
            'debug': {
                'method': 'COMPETENCY_DISTANCE (Euclidean)',
                'euclidean_distance': round(distances[best_role_id], 4),
                'metric_agreement': f"{metric_agreement}/3",
                'all_distances': {
                    RoleCluster.query.get(rid).role_cluster_name: round(dist, 4)
                    for rid, dist in sorted_distances[:5]
                    if RoleCluster.query.get(rid)
                }
            }
        }

        print(f"[suggest-role-simple] RESULT: {best_role.role_cluster_name} ({confidence:.0%} confidence)")
        return jsonify(response_data), 200

    except Exception as e:
        print(f"[suggest-role-simple] ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': 'Internal server error',
            'details': str(e)
        }), 500


@main_bp.route('/api/phase1/target-group/<int:org_id>', methods=['GET'])
def get_target_group(org_id):
    """Get target group size for an organization"""
    try:
        from models import PhaseQuestionnaireResponse, Organization

        # Verify organization exists
        org = Organization.query.get(org_id)
        if not org:
            return jsonify({'error': 'Organization not found'}), 404

        # Get latest target group data
        target_group = PhaseQuestionnaireResponse.query.filter_by(
            organization_id=org_id,
            questionnaire_type='target_group',
            phase=1
        ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

        if not target_group:
            return jsonify({
                'success': True,
                'data': None
            }), 200

        # Get the response data
        response_data = target_group.get_responses()

        return jsonify({
            'success': True,
            'data': response_data,
            'completed_at': target_group.completed_at.isoformat() if target_group.completed_at else None
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting target group: {str(e)}")
        return jsonify({'error': 'Failed to get target group'}), 500


@main_bp.route('/api/phase1/target-group/save', methods=['POST'])
def save_target_group():
    """Save target group size information"""
    try:
        from models import PhaseQuestionnaireResponse
        from flask_jwt_extended import verify_jwt_in_request

        data = request.get_json()

        org_id = data.get('org_id')
        size_data = data.get('sizeData', {})

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

        # Create new target group data
        target_group = PhaseQuestionnaireResponse(
            organization_id=org_id,
            user_id=user_id,
            questionnaire_type='target_group',
            phase=1
        )
        target_group.set_responses(size_data)

        db.session.add(target_group)
        db.session.commit()

        return jsonify({
            'success': True,
            'id': target_group.id,
            'message': 'Target group saved successfully'
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving target group: {str(e)}")
        return jsonify({'error': 'Failed to save target group'}), 500


@main_bp.route('/api/phase1/strategies/definitions', methods=['GET'])
def get_strategy_definitions():
    """Get all 7 SE training strategy definitions"""
    try:
        from app.strategy_selection_engine import SE_TRAINING_STRATEGIES

        return jsonify({
            'success': True,
            'strategies': SE_TRAINING_STRATEGIES
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting strategy definitions: {str(e)}")
        return jsonify({'error': 'Failed to get strategy definitions'}), 500


@main_bp.route('/api/phase1/strategies/calculate', methods=['POST'])
def calculate_strategies():
    """Calculate recommended strategies based on maturity and target group"""
    try:
        from app.strategy_selection_engine import StrategySelectionEngine

        data = request.get_json()
        maturity_data = data.get('maturityData', {})
        target_group_data = data.get('targetGroupData', {})

        if not maturity_data or not target_group_data:
            return jsonify({'error': 'maturityData and targetGroupData are required'}), 400

        # Run strategy selection engine
        engine = StrategySelectionEngine(maturity_data, target_group_data)
        results = engine.select_strategies()

        return jsonify({
            'success': True,
            'strategies': results['strategies'],
            'decisionPath': results['decisionPath'],
            'reasoning': results['reasoning'],
            'requiresUserChoice': results['requiresUserChoice']
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error calculating strategies: {str(e)}")
        return jsonify({'error': f'Failed to calculate strategies: {str(e)}'}), 500


@main_bp.route('/api/phase1/strategies/<int:org_id>/latest', methods=['GET'])
def get_latest_strategies(org_id):
    """Get latest strategy selection for an organization"""
    try:
        from models import PhaseQuestionnaireResponse, Organization

        # Verify organization exists
        org = Organization.query.get(org_id)
        if not org:
            return jsonify({'error': 'Organization not found'}), 404

        # Get latest strategy selection
        strategies = PhaseQuestionnaireResponse.query.filter_by(
            organization_id=org_id,
            questionnaire_type='strategies',
            phase=1
        ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

        if not strategies:
            return jsonify({
                'success': True,
                'data': None,
                'count': 0
            }), 200

        # Parse the response
        response_data = strategies.get_responses()
        strategies_list = response_data.get('strategies', []) if isinstance(response_data, dict) else []

        return jsonify({
            'success': True,
            'data': strategies_list,
            'count': len(strategies_list),
            'userPreference': response_data.get('userPreference') if isinstance(response_data, dict) else None,
            'decisionPath': response_data.get('decisionPath') if isinstance(response_data, dict) else None,
            'reasoning': response_data.get('reasoning') if isinstance(response_data, dict) else None,
            'completed_at': strategies.completed_at.isoformat() if strategies.completed_at else None
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting strategies: {str(e)}")
        return jsonify({'error': 'Failed to get strategies'}), 500


@main_bp.route('/api/phase1/strategies/save', methods=['POST'])
def save_strategies():
    """Save selected strategies"""
    try:
        from models import PhaseQuestionnaireResponse
        from flask_jwt_extended import verify_jwt_in_request

        data = request.get_json()

        org_id = data.get('orgId')
        strategies = data.get('strategies', [])
        decision_path = data.get('decisionPath', [])

        if not org_id:
            return jsonify({'error': 'orgId is required'}), 400

        # Get user ID from JWT if available
        user_id = 1  # Default fallback
        try:
            verify_jwt_in_request(optional=True)
            jwt_user_id = get_jwt_identity()
            if jwt_user_id:
                user_id = int(jwt_user_id) if isinstance(jwt_user_id, str) else jwt_user_id
        except Exception:
            pass  # Use default user_id

        # Create new strategy selection
        strategy_data = PhaseQuestionnaireResponse(
            organization_id=org_id,
            user_id=user_id,
            questionnaire_type='strategies',
            phase=1
        )
        strategy_data.set_responses({
            'strategies': strategies,
            'decision_path': decision_path
        })

        db.session.add(strategy_data)
        db.session.commit()

        return jsonify({
            'success': True,
            'id': strategy_data.id,
            'message': 'Strategies saved successfully',
            'strategies': strategies,
            'count': len(strategies)
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving strategies: {str(e)}")
        return jsonify({'error': 'Failed to save strategies'}), 500


# =============================================================================
# ADMIN MATRIX MANAGEMENT ENDPOINTS
# Based on Derik's implementation and MATRIX_CALCULATION_PATTERN.md
# =============================================================================

@main_bp.route('/roles', methods=['GET'])
def get_role_clusters():
    """Get all 14 SE role clusters for competency assessment"""
    try:
        roles = RoleCluster.query.all()
        return jsonify([r.to_dict() for r in roles]), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching roles: {str(e)}")
        return jsonify({'error': 'Failed to fetch roles'}), 500


@main_bp.route('/roles_and_processes', methods=['GET'])
def get_roles_and_processes():
    """Get all roles and processes for admin matrix editing"""
    try:
        roles = RoleCluster.query.all()
        processes = IsoProcesses.query.all()

        return jsonify({
            'roles': [r.to_dict() for r in roles],
            'processes': [p.to_dict() for p in processes]
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching roles and processes: {str(e)}")
        return jsonify({'error': 'Failed to fetch roles and processes'}), 500


@main_bp.route('/role_process_matrix/<int:organization_id>/<int:role_id>', methods=['GET'])
def get_role_process_matrix(organization_id, role_id):
    """Get role-process matrix values for a specific role and organization"""
    try:
        matrix_entries = RoleProcessMatrix.query.filter_by(
            organization_id=organization_id,
            role_cluster_id=role_id
        ).all()

        return jsonify([entry.to_dict() for entry in matrix_entries]), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching role-process matrix: {str(e)}")
        return jsonify({'error': 'Failed to fetch role-process matrix'}), 500


@main_bp.route('/role_process_matrix/bulk', methods=['PUT'])
def bulk_update_role_process_matrix():
    """
    Bulk update role-process matrix and recalculate role-competency matrix
    Based on Derik's implementation (routes.py:250)
    """
    try:
        data = request.get_json()
        organization_id = data.get('organization_id')
        role_cluster_id = data.get('role_cluster_id')
        matrix = data.get('matrix')  # Dict: {process_id: value}

        if not all([organization_id, role_cluster_id, matrix]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Update or create matrix entries
        for process_id, value in matrix.items():
            process_id = int(process_id)

            # Find existing entry or create new one
            entry = RoleProcessMatrix.query.filter_by(
                organization_id=organization_id,
                role_cluster_id=role_cluster_id,
                iso_process_id=process_id
            ).first()

            if entry:
                entry.role_process_value = value
            else:
                entry = RoleProcessMatrix(
                    organization_id=organization_id,
                    role_cluster_id=role_cluster_id,
                    iso_process_id=process_id,
                    role_process_value=value
                )
                db.session.add(entry)

        db.session.commit()

        # Recalculate role-competency matrix for this organization
        # As per MATRIX_CALCULATION_PATTERN.md
        db.session.execute(
            text('CALL update_role_competency_matrix(:org_id);'),
            {'org_id': organization_id}
        )
        db.session.commit()

        return jsonify({
            'message': 'Role-process matrix updated successfully',
            'recalculated': True
        }), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating role-process matrix: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': 'Failed to update role-process matrix'}), 500


@main_bp.route('/competencies', methods=['GET'])
def get_competencies_for_matrix():
    """Get all competencies for admin matrix editing"""
    try:
        competencies = Competency.query.all()

        return jsonify([c.to_dict() for c in competencies]), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching competencies: {str(e)}")
        return jsonify({'error': 'Failed to fetch competencies'}), 500


@main_bp.route('/process_competency_matrix/<int:competency_id>', methods=['GET'])
def get_process_competency_matrix(competency_id):
    """Get process-competency matrix values for a specific competency"""
    try:
        # Get all processes
        processes = IsoProcesses.query.all()

        # Get matrix entries for this competency
        matrix_entries = ProcessCompetencyMatrix.query.filter_by(
            competency_id=competency_id
        ).all()

        return jsonify({
            'processes': [p.to_dict() for p in processes],
            'matrix': [entry.to_dict() for entry in matrix_entries]
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching process-competency matrix: {str(e)}")
        return jsonify({'error': 'Failed to fetch process-competency matrix'}), 500


@main_bp.route('/process_competency_matrix/bulk', methods=['PUT'])
def bulk_update_process_competency_matrix():
    """
    Bulk update process-competency matrix and recalculate for ALL organizations
    Based on Derik's implementation (routes.py:322-328)
    """
    try:
        data = request.get_json()
        competency_id = data.get('competency_id')
        matrix = data.get('matrix')  # Dict: {process_id: value}

        if not all([competency_id, matrix]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Update or create matrix entries
        for process_id, value in matrix.items():
            process_id = int(process_id)

            # Find existing entry or create new one
            entry = ProcessCompetencyMatrix.query.filter_by(
                iso_process_id=process_id,
                competency_id=competency_id
            ).first()

            if entry:
                entry.process_competency_value = value
            else:
                entry = ProcessCompetencyMatrix(
                    iso_process_id=process_id,
                    competency_id=competency_id,
                    process_competency_value=value
                )
                db.session.add(entry)

        db.session.commit()

        # Recalculate role-competency matrix for ALL organizations
        # As per MATRIX_CALCULATION_PATTERN.md
        organizations = Organization.query.all()
        for org in organizations:
            db.session.execute(
                text('CALL update_role_competency_matrix(:org_id);'),
                {'org_id': org.id}
            )
        db.session.commit()

        return jsonify({
            'message': 'Process-competency matrix updated successfully',
            'recalculated_for_orgs': len(organizations)
        }), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating process-competency matrix: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': 'Failed to update process-competency matrix'}), 500


# =============================================================================
# QUESTIONNAIRE ENDPOINTS
# =============================================================================

@main_bp.route('/api/questionnaires/<int:questionnaire_id>', methods=['GET'])
def get_questionnaire_definition(questionnaire_id):
    """Get questionnaire definition (stub for now)"""
    try:
        # Stub implementation - return empty questionnaire structure
        # This can be expanded later with actual questionnaire data
        return jsonify({
            'id': questionnaire_id,
            'name': f'Questionnaire {questionnaire_id}',
            'questions': [],
            'description': 'Questionnaire definition'
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error getting questionnaire: {str(e)}")
        return jsonify({'error': 'Failed to get questionnaire'}), 500


# =============================================================================
# DERIK'S COMPETENCY ASSESSMENT ENDPOINTS
# Legacy endpoints for competency assessment bridge compatibility
# =============================================================================

# REMOVED Phase 2B (2025-10-26): Legacy endpoint /new_survey_user
# Replaced by /assessment/start endpoint in main assessment flow
# Used deprecated NewSurveyUser model (removed from models.py)
# @main_bp.route('/new_survey_user', methods=['POST'])
# def create_new_survey_user():
#     """Create a new survey user for competency assessment"""
#     ...


@main_bp.route('/get_required_competencies_for_roles', methods=['POST'])
def get_required_competencies_for_roles():
    """Fetch distinct competencies and the maximum competency value for selected roles and organization."""
    from sqlalchemy import func

    data = request.json
    role_ids = data.get('role_ids')
    organization_id = data.get('organization_id')
    user_name = data.get('user_name')
    survey_type = data.get('survey_type')

    print(f"[get_required_competencies_for_roles] Role IDs: {role_ids}")
    print(f"[get_required_competencies_for_roles] Organization ID: {organization_id}")
    print(f"[get_required_competencies_for_roles] Survey type: {survey_type}")

    if survey_type == 'known_roles':
        if role_ids is None or organization_id is None:
            return jsonify({"error": "role_ids and organization_id are required"}), 400

        try:
            competencies = (
                db.session.query(
                    RoleCompetencyMatrix.competency_id,
                    func.max(RoleCompetencyMatrix.role_competency_value).label('max_value')
                )
                .filter(
                    RoleCompetencyMatrix.role_cluster_id.in_(role_ids),
                    RoleCompetencyMatrix.organization_id == organization_id
                )
                .group_by(RoleCompetencyMatrix.competency_id)
                .having(func.max(RoleCompetencyMatrix.role_competency_value) > 0)  # Filter out zero-level competencies
                .order_by(RoleCompetencyMatrix.competency_id)
                .all()
            )

            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            print(f"[get_required_competencies_for_roles] Filtered {len(competencies_data)} competencies with required level > 0")
            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(f"[get_required_competencies_for_roles] Error: {str(e)}")
            return jsonify({"error": str(e)}), 500

    elif survey_type == 'unknown_roles':
        if user_name is None or organization_id is None:
            return jsonify({"error": "user_name and organization_id are required"}), 400

        try:
            competencies = (
                db.session.query(
                    UnknownRoleCompetencyMatrix.competency_id,
                    UnknownRoleCompetencyMatrix.role_competency_value.label('max_value')
                )
                .filter(
                    UnknownRoleCompetencyMatrix.user_name == user_name,
                    UnknownRoleCompetencyMatrix.organization_id == organization_id,
                    UnknownRoleCompetencyMatrix.role_competency_value > 0  # Filter out zero-level competencies
                )
                .order_by(UnknownRoleCompetencyMatrix.competency_id)
                .all()
            )

            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            print(f"[get_required_competencies_for_roles] Filtered {len(competencies_data)} competencies with required level > 0")
            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(f"[get_required_competencies_for_roles] Error: {str(e)}")
            return jsonify({"error": str(e)}), 500

    elif survey_type == "all_roles":
        print("[get_required_competencies_for_roles] Fetching competencies for all roles")
        if organization_id is None:
            return jsonify({"error": "organization_id is required"}), 400

        try:
            competencies = (
                db.session.query(
                    RoleCompetencyMatrix.competency_id,
                    func.round(func.avg(RoleCompetencyMatrix.role_competency_value)).label('max_value')
                )
                .filter(
                    RoleCompetencyMatrix.organization_id == organization_id
                )
                .group_by(RoleCompetencyMatrix.competency_id)
                .having(func.round(func.avg(RoleCompetencyMatrix.role_competency_value)) > 0)  # Filter out zero-level competencies
                .order_by(RoleCompetencyMatrix.competency_id)
                .all()
            )

            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            print(f"[get_required_competencies_for_roles] Filtered {len(competencies_data)} competencies with required level > 0")
            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(f"[get_required_competencies_for_roles] Error: {str(e)}")
            return jsonify({"error": str(e)}), 500

    return jsonify({"error": "Invalid survey_type"}), 400


# =============================================================================
# DERIK'S COMPETENCY ASSESSMENT ENDPOINTS (Phase 2 Integration)
# =============================================================================

@main_bp.route('/get_competency_indicators_for_competency/<int:competency_id>', methods=['GET'])
def get_competency_indicators_for_competency(competency_id):
    """
    Fetch all indicators associated with the specified competency, grouped by level.
    Used by Phase 2 competency assessment to display indicators for each competency.
    """
    try:
        # Query to fetch indicators by competency ID
        indicators = CompetencyIndicator.query.filter_by(competency_id=competency_id).all()

        # Group indicators by their level
        indicators_by_level = {}
        for indicator in indicators:
            if indicator.level not in indicators_by_level:
                indicators_by_level[indicator.level] = []
            indicators_by_level[indicator.level].append({
                "indicator_en": indicator.indicator_en,
                "indicator_de": indicator.indicator_de
            })

        # Structure response with indicators grouped by level
        response_data = [
            {
                "level": level,
                "indicators": indicators
            }
            for level, indicators in indicators_by_level.items()
        ]

        return jsonify(response_data), 200

    except Exception as e:
        print(f"[get_competency_indicators] Error: {str(e)}")
        return jsonify({"error": "An error occurred while fetching competency indicators"}), 500


# Note: /findProcesses endpoint already exists at line ~1587 in this file
# No need for duplicate implementation here


# =============================================================================
# NEW AUTHENTICATED ASSESSMENT ENDPOINTS (Replaces anonymous survey system)
# =============================================================================

@main_bp.route('/assessment/start', methods=['POST'])
def start_assessment():
    """
    Start a new assessment for an authenticated user
    Replaces /new_survey_user endpoint - uses real authenticated user instead of anonymous username
    """
    from models import UserAssessment, User

    data = request.get_json()
    try:
        user_id = data.get('user_id')
        organization_id = data.get('organization_id')
        assessment_type = data.get('assessment_type')  # 'role_based', 'task_based', 'full_competency'

        if not user_id or not organization_id or not assessment_type:
            return jsonify({"error": "user_id, organization_id, and assessment_type are required"}), 400

        # Verify user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Determine survey_type based on assessment_type
        survey_type_map = {
            'role_based': 'known_roles',
            'task_based': 'unknown_roles',
            'full_competency': 'all_roles'
        }
        survey_type = survey_type_map.get(assessment_type, 'known_roles')

        # Create new assessment record
        assessment = UserAssessment(
            user_id=user_id,
            organization_id=organization_id,
            assessment_type=assessment_type,
            survey_type=survey_type
        )

        db.session.add(assessment)
        db.session.commit()
        db.session.refresh(assessment)

        print(f"[start_assessment] Created assessment {assessment.id} for user {user.username}")

        return jsonify({
            "message": "Assessment started successfully",
            "assessment_id": assessment.id,
            "username": user.username,  # Return for compatibility
            "user_id": user.id,
            "assessment": assessment.to_dict()
        }), 201

    except Exception as e:
        print(f"[start_assessment] Error: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "An error occurred", "details": str(e)}), 500


@main_bp.route('/assessment/<int:assessment_id>/submit', methods=['POST'])
def submit_assessment(assessment_id):
    """
    Submit competency scores for an assessment
    Replaces /submit_survey endpoint - uses assessment_id instead of username
    """
    from models import UserAssessment, User, UserCompetencySurveyResults, UserRoleCluster

    data = request.get_json()
    try:
        # Fetch the assessment
        assessment = UserAssessment.query.get(assessment_id)
        if not assessment:
            return jsonify({"error": "Assessment not found"}), 404

        # Extract data
        selected_roles = data.get('selected_roles', [])
        competency_scores = data.get('competency_scores', [])
        tasks_responsibilities = data.get('tasks_responsibilities')

        # Update assessment with submitted data
        assessment.selected_roles = selected_roles
        assessment.tasks_responsibilities = tasks_responsibilities
        assessment.completed_at = datetime.utcnow()

        # Delete existing roles for this assessment if any
        UserRoleCluster.query.filter_by(assessment_id=assessment_id).delete()

        # Insert new roles with assessment_id
        for role in selected_roles:
            role_entry = UserRoleCluster(
                user_id=assessment.user_id,
                role_cluster_id=role.get('role_id') or role.get('id'),
                assessment_id=assessment_id
            )
            db.session.add(role_entry)

        # Delete existing survey results for this assessment
        UserCompetencySurveyResults.query.filter_by(
            user_id=assessment.user_id,
            assessment_id=assessment_id
        ).delete()

        # Insert survey results with assessment_id
        for competency in competency_scores:
            # Extract score with proper fallback to 0 for None values
            score = competency.get('user_score') if competency.get('user_score') is not None else competency.get('score')
            if score is None:
                score = 0  # Default to 0 if no score provided

            survey = UserCompetencySurveyResults(
                user_id=assessment.user_id,
                organization_id=assessment.organization_id,
                competency_id=competency.get('competency_id') or competency.get('competencyId'),
                score=score,
                assessment_id=assessment_id
            )
            db.session.add(survey)

        db.session.commit()

        print(f"[submit_assessment] Assessment {assessment_id} completed for user {assessment.user_id}")

        return jsonify({
            'message': 'Assessment submitted successfully',
            'assessment_id': assessment_id,
            'assessment': assessment.to_dict()
        }), 200

    except Exception as e:
        print(f"[submit_assessment] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        db.session.rollback()
        return jsonify({"error": "An error occurred", "details": str(e)}), 500


@main_bp.route('/assessment/<int:assessment_id>/results', methods=['GET'])
def get_assessment_results(assessment_id):
    """
    Get results for a specific assessment
    Replaces /get_user_competency_results endpoint - uses assessment_id instead of username
    """
    from models import (UserAssessment, UserCompetencySurveyResults, Competency,
                       UserRoleCluster, RoleCompetencyMatrix, UnknownRoleCompetencyMatrix,
                       UserCompetencySurveyFeedback)

    try:
        # Fetch the assessment
        assessment = UserAssessment.query.get(assessment_id)
        if not assessment:
            return jsonify({'error': 'Assessment not found'}), 404

        # Fetch competency survey results for this assessment
        user_competencies = UserCompetencySurveyResults.query.filter_by(
            assessment_id=assessment_id
        ).order_by(UserCompetencySurveyResults.competency_id).all()

        if not user_competencies:
            return jsonify({'error': 'No results found for this assessment'}), 404

        competencies = Competency.query.filter(
            Competency.id.in_([u.competency_id for u in user_competencies])
        ).order_by(Competency.id).all()

        competency_info_map = {comp.id: {'name': comp.competency_name, 'area': comp.competency_area} for comp in competencies}

        user_scores = [
            {
                'competency_id': u.competency_id,
                'score': u.score,
                'competency_name': competency_info_map[u.competency_id]['name'],
                'competency_area': competency_info_map[u.competency_id]['area']
            }
            for u in user_competencies
        ]

        # Fetch required competency scores based on survey type
        if assessment.survey_type == 'known_roles':
            user_roles = UserRoleCluster.query.filter_by(assessment_id=assessment_id).all()
            role_cluster_ids = [role.role_cluster_id for role in user_roles]

            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
            ).filter(
                RoleCompetencyMatrix.organization_id == assessment.organization_id,
                RoleCompetencyMatrix.role_cluster_id.in_(role_cluster_ids)
            ).group_by(RoleCompetencyMatrix.competency_id).having(
                db.func.max(RoleCompetencyMatrix.role_competency_value) > 0
            ).order_by(RoleCompetencyMatrix.competency_id).all()

        elif assessment.survey_type == 'unknown_roles':
            # For task-based, fetch from UnknownRoleCompetencyMatrix
            # Note: This would require the username from the assessment's user
            user = User.query.get(assessment.user_id)
            max_scores = db.session.query(
                UnknownRoleCompetencyMatrix.competency_id,
                UnknownRoleCompetencyMatrix.role_competency_value.label('max_score')
            ).filter(
                UnknownRoleCompetencyMatrix.organization_id == assessment.organization_id,
                UnknownRoleCompetencyMatrix.user_name == user.username,
                UnknownRoleCompetencyMatrix.role_competency_value > 0
            ).all()

        elif assessment.survey_type == 'all_roles':
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.avg(RoleCompetencyMatrix.role_competency_value).label('max_score')
            ).filter(
                RoleCompetencyMatrix.organization_id == assessment.organization_id
            ).group_by(RoleCompetencyMatrix.competency_id).having(
                db.func.avg(RoleCompetencyMatrix.role_competency_value) > 0
            ).order_by(RoleCompetencyMatrix.competency_id).all()
        else:
            max_scores = []

        max_scores_dict = [{'competency_id': m.competency_id, 'max_score': float(m.max_score)} for m in max_scores]

        # Filter user_scores to only include competencies with required level > 0
        required_competency_ids = {m['competency_id'] for m in max_scores_dict}
        user_scores = [score for score in user_scores if score['competency_id'] in required_competency_ids]

        # Check if feedback already exists for this assessment
        existing_feedbacks = UserCompetencySurveyFeedback.query.filter_by(
            assessment_id=assessment_id
        ).all()

        if existing_feedbacks:
            # Since feedback is stored as a JSONB array in a single row, extract it directly
            # The feedback column contains the complete feedback_list, not individual items
            if len(existing_feedbacks) == 1:
                feedback_list = existing_feedbacks[0].feedback
            else:
                # Fallback: flatten if multiple rows (shouldn't happen with current schema)
                feedback_list = []
                for fb in existing_feedbacks:
                    if isinstance(fb.feedback, list):
                        feedback_list.extend(fb.feedback)
                    else:
                        feedback_list.append(fb.feedback)
            print(f"[get_assessment_results] Using cached feedback for assessment {assessment_id}")
        else:
            # Generate feedback using LLM
            print(f"[get_assessment_results] No cached feedback found for assessment {assessment_id}, generating...")
            feedback_list = []

            try:
                from collections import defaultdict
                from models import CompetencyIndicator
                from app.generate_survey_feedback import generate_feedback_with_llm

                # Helper function to map score to level
                def score_to_level(score):
                    score_map = {
                        0: '0',  # unwissend (unaware)
                        1: '1',  # kennen (know)
                        2: '2',  # verstehen (understand)
                        4: '3',  # anwenden (apply)
                        6: '4'   # beherrschen (master)
                    }
                    return score_map.get(score, '0')

                # Helper function to get level name
                def get_level_name(level):
                    level_names = {
                        '0': 'unwissend (unaware)',
                        '1': 'kennen (know)',
                        '2': 'verstehen (understand)',
                        '3': 'anwenden (apply)',
                        '4': 'beherrschen (master)'
                    }
                    return level_names.get(level, 'unknown')

                # Helper function to get indicators for a competency at a specific level
                def get_indicators_for_level(competency_id, level):
                    if level == '0':
                        return 'You are unaware or lack knowledge in this competency area'

                    indicators = CompetencyIndicator.query.filter_by(
                        competency_id=competency_id,
                        level=level
                    ).all()

                    if not indicators:
                        return f'No specific indicators available for level {level} ({get_level_name(level)})'

                    return '. '.join([ind.indicator_en for ind in indicators if ind.indicator_en])

                # Build max_scores_map for easy lookup
                max_scores_map = {m['competency_id']: m['max_score'] for m in max_scores_dict}

                # Build detailed competency results
                aggregated_results = defaultdict(list)

                for user_comp in user_competencies:
                    competency_id = user_comp.competency_id
                    user_score = user_comp.score

                    # Get competency info
                    competency_obj = Competency.query.get(competency_id)
                    if not competency_obj:
                        continue

                    competency_name = competency_obj.competency_name
                    competency_area = competency_obj.competency_area

                    # Map user score to level
                    user_level = score_to_level(user_score)
                    user_indicators = get_indicators_for_level(competency_id, user_level)

                    # Get required score and map to level
                    required_score = max_scores_map.get(competency_id, 0)

                    # Skip competencies with required level = 0
                    if required_score == 0:
                        continue

                    required_level = score_to_level(int(required_score)) if required_score else 'unwissend'
                    required_indicators = get_indicators_for_level(competency_id, required_level)

                    # Add to aggregated results
                    aggregated_results[competency_area].append({
                        "competency_name": competency_name,
                        "user_level": user_level,
                        "user_indicator": user_indicators,
                        "required_level": required_level,
                        "required_indicator": required_indicators
                    })

                print(f"[get_assessment_results] Aggregated {len(aggregated_results)} areas for feedback generation")

                # Generate feedback using LLM for each competency area
                for competency_area, competencies in aggregated_results.items():
                    print(f"[get_assessment_results] Generating feedback for {competency_area} with {len(competencies)} competencies")
                    feedback_json = generate_feedback_with_llm(competency_area, competencies)
                    feedback_list.append(feedback_json)

                # Save feedback to database with assessment_id
                new_feedback = UserCompetencySurveyFeedback(
                    user_id=assessment.user_id,
                    organization_id=assessment.organization_id,
                    feedback=feedback_list,
                    assessment_id=assessment_id
                )
                db.session.add(new_feedback)
                db.session.commit()
                print(f"[get_assessment_results] Generated and saved {len(feedback_list)} feedback items for assessment {assessment_id}")

            except Exception as e:
                db.session.rollback()
                print(f"[get_assessment_results] LLM feedback generation error: {str(e)}")
                import traceback
                traceback.print_exc()
                feedback_list = []  # Return empty feedback on error

        return jsonify({
            'assessment': assessment.to_dict(),
            'user_scores': user_scores,
            'max_scores': max_scores_dict,
            'feedback_list': feedback_list
        }), 200

    except Exception as e:
        print(f"[get_assessment_results] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': 'An error occurred', 'details': str(e)}), 500


@main_bp.route('/user/<int:user_id>/assessments', methods=['GET'])
def get_user_assessment_history(user_id):
    """
    Get all assessments for a user (assessment history)
    NEW endpoint - enables users to see their assessment history
    """
    from models import UserAssessment, User

    try:
        # Verify user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Fetch all assessments for this user
        assessments = UserAssessment.query.filter_by(user_id=user_id).order_by(
            UserAssessment.created_at.desc()
        ).all()

        assessments_list = [assessment.to_dict() for assessment in assessments]

        print(f"[get_user_assessment_history] Found {len(assessments_list)} assessments for user {user.username}")

        return jsonify({
            'user_id': user_id,
            'username': user.username,
            'assessment_count': len(assessments_list),
            'assessments': assessments_list
        }), 200

    except Exception as e:
        print(f"[get_user_assessment_history] Error: {str(e)}")
        return jsonify({'error': 'An error occurred', 'details': str(e)}), 500


# =============================================================================
# OLD ANONYMOUS SURVEY ENDPOINTS (Keep for backward compatibility during migration)
# =============================================================================

# REMOVED Phase 2B (2025-10-26): Legacy endpoint /submit_survey
# Replaced by /assessment/<id>/submit endpoint in main assessment flow
# Used deprecated AppUser, NewSurveyUser, UserSurveyType models (removed from models.py)
# @main_bp.route('/submit_survey', methods=['POST'])
# def submit_survey():
#     """Submit competency assessment survey results"""
#     ...


# REMOVED Phase 2B (2025-10-26): Legacy endpoint /get_user_competency_results
# Replaced by /assessment/<id>/results endpoint in main assessment flow
# Used deprecated AppUser model (removed from models.py)
# This was a 227-line function that generated competency feedback with LLM
# @main_bp.route('/get_user_competency_results', methods=['GET'])
# def get_user_competency_results():
#     """Get competency assessment results for a user"""
#     ...


@main_bp.route('/api/latest_competency_overview', methods=['GET'])
@jwt_required()
def get_latest_competency_overview():
    """
    Get top 5 competencies from user's latest Phase 2 assessment,
    sorted by required level (importance) from role-competency matrix.

    Returns competencies with highest required levels to show users
    what's most critical for their SE role.
    """
    from models import (UserAssessment, UserCompetencySurveyResults, Competency,
                       UserRoleCluster, RoleCompetencyMatrix, UnknownRoleCompetencyMatrix)

    try:
        user_id = int(get_jwt_identity())

        # Get user's latest completed Phase 2 assessment
        latest_assessment = UserAssessment.query.filter_by(
            user_id=user_id
        ).order_by(UserAssessment.created_at.desc()).first()

        if not latest_assessment:
            return jsonify({
                'competencies': [],
                'message': 'No Phase 2 assessment completed yet'
            }), 200

        # Get user's competency scores for this assessment
        user_competencies = UserCompetencySurveyResults.query.filter_by(
            assessment_id=latest_assessment.id
        ).all()

        if not user_competencies:
            return jsonify({
                'competencies': [],
                'message': 'No competency data found'
            }), 200

        # Get competency info
        competency_ids = [uc.competency_id for uc in user_competencies]
        competencies = Competency.query.filter(
            Competency.id.in_(competency_ids)
        ).all()

        competency_info_map = {
            comp.id: {
                'name': comp.competency_name,
                'area': comp.competency_area
            }
            for comp in competencies
        }

        # Get required competency levels based on survey type
        if latest_assessment.survey_type == 'known_roles':
            # Get user's selected roles
            user_roles = UserRoleCluster.query.filter_by(
                assessment_id=latest_assessment.id
            ).all()
            role_cluster_ids = [role.role_cluster_id for role in user_roles]

            # Get max required level across all user's roles
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.max(RoleCompetencyMatrix.role_competency_value).label('required_level')
            ).filter(
                RoleCompetencyMatrix.organization_id == latest_assessment.organization_id,
                RoleCompetencyMatrix.role_cluster_id.in_(role_cluster_ids)
            ).group_by(RoleCompetencyMatrix.competency_id).having(
                db.func.max(RoleCompetencyMatrix.role_competency_value) > 0
            ).all()

        elif latest_assessment.survey_type == 'unknown_roles':
            # Get from task-based role mapping
            user = User.query.get(latest_assessment.user_id)
            max_scores = db.session.query(
                UnknownRoleCompetencyMatrix.competency_id,
                UnknownRoleCompetencyMatrix.role_competency_value.label('required_level')
            ).filter(
                UnknownRoleCompetencyMatrix.organization_id == latest_assessment.organization_id,
                UnknownRoleCompetencyMatrix.user_name == user.username,
                UnknownRoleCompetencyMatrix.role_competency_value > 0
            ).all()

        elif latest_assessment.survey_type == 'all_roles':
            # Average across all roles
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.avg(RoleCompetencyMatrix.role_competency_value).label('required_level')
            ).filter(
                RoleCompetencyMatrix.organization_id == latest_assessment.organization_id
            ).group_by(RoleCompetencyMatrix.competency_id).having(
                db.func.avg(RoleCompetencyMatrix.role_competency_value) > 0
            ).all()
        else:
            max_scores = []

        # Build map of required levels
        required_level_map = {m.competency_id: float(m.required_level) for m in max_scores}

        # Build combined data: user score + required level + competency info
        combined_data = []
        for uc in user_competencies:
            competency_id = uc.competency_id

            # Only include competencies with required level > 0
            if competency_id not in required_level_map:
                continue

            if competency_id not in competency_info_map:
                continue

            combined_data.append({
                'competency_id': competency_id,
                'competency_name': competency_info_map[competency_id]['name'],
                'competency_area': competency_info_map[competency_id]['area'],
                'current_score': uc.score,
                'required_score': required_level_map[competency_id],
                'gap': required_level_map[competency_id] - uc.score
            })

        # Sort by required level (importance) descending, then by gap descending
        combined_data.sort(key=lambda x: (-x['required_score'], -x['gap']))

        # Take top 5
        top_5_competencies = combined_data[:5]

        print(f"[get_latest_competency_overview] Returning {len(top_5_competencies)} competencies for user {user_id}")

        return jsonify({
            'competencies': top_5_competencies,
            'assessment_id': latest_assessment.id,
            'completed_at': latest_assessment.created_at.isoformat() if latest_assessment.created_at else None,
            'total_competencies': len(combined_data)
        }), 200

    except Exception as e:
        print(f"[get_latest_competency_overview] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
