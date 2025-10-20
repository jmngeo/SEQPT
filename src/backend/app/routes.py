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

from models import (
    db,
    User,
    SECompetency,
    SERole,
    QualificationArchetype,
    Assessment,
    CompetencyAssessmentResult,
    LearningObjective,
    QualificationPlan,
    CompanyContext,
    RAGTemplate,
    Organization,
    MVPUser,
    MaturityAssessment,
    CompetencyAssessment,
    LearningPlan,
    RoleMapping,
    calculate_maturity_score,
    select_archetype,
    generate_learning_plan_templates,
    generate_basic_modules
)

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


# =============================================================================
# MVP SIMPLIFIED API ROUTES (merged into main_bp)
# =============================================================================

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
        user = MVPUser.query.filter_by(username=username).first()

        if user and user.check_password(password):
            # Update last login
            user.last_login = datetime.utcnow()
            db.session.commit()

            # Create access token
            access_token = create_access_token(
                identity=user.id,
                additional_claims={
                    'organization_id': user.organization_id,
                    'role': user.role
                }
            )

            return jsonify({
                'access_token': access_token,
                'user': user.to_dict()
            }), 200

        return jsonify({'error': 'Invalid credentials'}), 401

    except Exception as e:
        current_app.logger.error(f"Login error: {str(e)}")
        return jsonify({'error': 'Login failed'}), 500


@main_bp.route('/mvp/auth/register-admin', methods=['POST'])
def register_admin():
    """Admin creates organization and becomes first user"""
    try:
        data = request.get_json()

        # Required fields
        required_fields = ['username', 'password', 'first_name', 'last_name', 'organization_name', 'organization_size']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400

        # Check if username already exists
        if MVPUser.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already registered'}), 400

        # Create organization (using Derik's unified model)
        org_code = Organization.generate_public_key(data['organization_name'])
        organization = Organization(
            organization_name=data['organization_name'],
            organization_public_key=org_code,
            size=data['organization_size']
        )
        db.session.add(organization)
        db.session.flush()  # Get organization ID

        # Create admin user
        admin_user = MVPUser(
            username=data['username'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            role='admin',
            organization_id=organization.id,
            joined_via_code=org_code
        )
        admin_user.set_password(data['password'])
        db.session.add(admin_user)
        db.session.commit()

        # Create access token
        access_token = create_access_token(
            identity=admin_user.id,
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
        required_fields = ['username', 'password', 'first_name', 'last_name', 'organization_code']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400

        # Check if username already exists
        if MVPUser.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already registered'}), 400

        # Validate organization code (using Derik's organization_public_key field)
        organization = Organization.query.filter_by(
            organization_public_key=data['organization_code'].upper()
        ).first()

        if not organization:
            return jsonify({'error': 'Invalid organization code'}), 400

        # Create employee user
        employee_user = MVPUser(
            username=data['username'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            role='employee',
            organization_id=organization.id,
            joined_via_code=data['organization_code'].upper()
        )
        employee_user.set_password(data['password'])
        db.session.add(employee_user)
        db.session.commit()

        # Create access token
        access_token = create_access_token(
            identity=employee_user.id,
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
        user_id = get_jwt_identity()
        user = MVPUser.query.get(user_id)

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
        user_id = get_jwt_identity()
        user = MVPUser.query.get(user_id)

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
        user_id = get_jwt_identity()
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = MVPUser.query.get(user_id)
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
@jwt_required()
def organization_dashboard():
    """Get organization dashboard data"""
    print("=" * 80)
    print("ORGANIZATION DASHBOARD ENDPOINT HIT!")
    print("=" * 80)
    sys.stdout.flush()
    try:
        user_id = get_jwt_identity()
        claims = get_jwt()

        print(f"DEBUG: User ID: {user_id}, Role: {claims.get('role')}")
        sys.stdout.flush()
        current_app.logger.info(f"DEBUG: Organization dashboard requested by user {user_id}, role: {claims.get('role')}")

        user = MVPUser.query.get(user_id)
        organization = Organization.query.get(user.organization_id)

        current_app.logger.info(f"DEBUG: Found user: {user.username if user else 'None'}")
        current_app.logger.info(f"DEBUG: Organization ID: {user.organization_id if user else 'None'}")
        current_app.logger.info(f"DEBUG: Organization: {organization.organization_name if organization else 'None'}")

        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        # Get organization statistics
        total_users = MVPUser.query.filter_by(organization_id=organization.id).count()
        completed_assessments = CompetencyAssessment.query.join(MVPUser).filter(
            MVPUser.organization_id == organization.id
        ).count()

        # Get maturity assessment if exists (MVP system)
        maturity_assessment = MaturityAssessment.query.filter_by(
            organization_id=organization.id
        ).first()

        # BRIDGE: Check questionnaire system for Phase 1 assessment data
        questionnaire_maturity_data = None
        selected_archetype = organization.selected_archetype  # Default fallback

        try:
            # Import questionnaire models to check for completed assessments
            from models import QuestionnaireResponse, Questionnaire

            current_app.logger.info(f"DEBUG: Starting bridge check for organization {organization.id}")

            # Find admin users in this organization who completed Phase 1
            admin_users = MVPUser.query.filter_by(
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

        # Use questionnaire data if available, otherwise fall back to MVP data
        final_maturity_assessment = questionnaire_maturity_data if questionnaire_maturity_data else (maturity_assessment.to_dict() if maturity_assessment else None)

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
        user_id = get_jwt_identity()
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = MVPUser.query.get(user_id)
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
        user_id = get_jwt_identity()
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = MVPUser.query.get(user_id)
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
        user_id = get_jwt_identity()
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
def get_assessment_results(user_id):
    """Get assessment results for a user"""
    try:
        current_user_id = get_jwt_identity()
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
        user_id = get_jwt_identity()
        claims = get_jwt()

        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        user = MVPUser.query.get(user_id)

        # Get all users in organization
        org_users = MVPUser.query.filter_by(organization_id=user.organization_id).all()

        # Get completion statistics
        total_users = len(org_users)
        completed_competency = CompetencyAssessment.query.join(MVPUser).filter(
            MVPUser.organization_id == user.organization_id
        ).count()

        # Get maturity assessment
        maturity_assessment = MaturityAssessment.query.filter_by(
            organization_id=user.organization_id
        ).first()

        summary = {
            'total_users': total_users,
            'completed_competency_assessments': completed_competency,
            'completion_rate': (completed_competency / total_users * 100) if total_users > 0 else 0,
            'maturity_assessment': maturity_assessment.to_dict() if maturity_assessment else None
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
        current_user_id = get_jwt_identity()
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
        user_id = get_jwt_identity()
        data = request.get_json()

        # Get user's competency assessment
        competency_assessment = CompetencyAssessment.query.filter_by(
            user_id=user_id
        ).first()

        if not competency_assessment:
            return jsonify({'error': 'Competency assessment required first'}), 400

        # Get organization's selected archetype
        user = MVPUser.query.get(user_id)
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
