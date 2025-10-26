"""
SE-QPT Admin Interface
Administrative functions for platform management
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timedelta
from sqlalchemy import func, and_, or_
import json

from models import db
from models import *

admin_bp = Blueprint('admin', __name__)

def require_admin():
    """Decorator to require admin privileges"""
    def decorator(f):
        def wrapper(*args, **kwargs):
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            if not user or user.user_type != 'admin':
                return {'error': 'Admin access required'}, 403
            return f(*args, **kwargs)
        wrapper.__name__ = f.__name__
        return wrapper
    return decorator

# Dashboard and Analytics
@admin_bp.route('/dashboard', methods=['GET'])
@jwt_required()
@require_admin()
def admin_dashboard():
    """Get admin dashboard statistics"""
    try:
        # User statistics
        total_users = User.query.count()
        active_users = User.query.filter_by(is_active=True).count()
        new_users_week = User.query.filter(
            User.created_at >= datetime.utcnow() - timedelta(days=7)
        ).count()

        # Assessment statistics
        total_assessments = Assessment.query.count()
        completed_assessments = Assessment.query.filter_by(status='completed').count()
        assessments_week = Assessment.query.filter(
            Assessment.created_at >= datetime.utcnow() - timedelta(days=7)
        ).count()

        # Plan statistics
        total_plans = QualificationPlan.query.count()
        active_plans = QualificationPlan.query.filter_by(status='active').count()
        completed_plans = QualificationPlan.query.filter_by(status='completed').count()

        # Learning objectives statistics
        total_objectives = LearningObjective.query.count()
        quality_objectives = LearningObjective.query.filter_by(meets_threshold=True).count()

        # User type distribution
        user_types = db.session.query(
            User.user_type,
            func.count(User.id)
        ).group_by(User.user_type).all()

        # Assessment type distribution
        assessment_types = db.session.query(
            Assessment.assessment_type,
            func.count(Assessment.id)
        ).group_by(Assessment.assessment_type).all()

        dashboard_data = {
            'users': {
                'total': total_users,
                'active': active_users,
                'new_this_week': new_users_week,
                'types': dict(user_types)
            },
            'assessments': {
                'total': total_assessments,
                'completed': completed_assessments,
                'completion_rate': (completed_assessments / total_assessments * 100) if total_assessments > 0 else 0,
                'new_this_week': assessments_week,
                'types': dict(assessment_types)
            },
            'plans': {
                'total': total_plans,
                'active': active_plans,
                'completed': completed_plans,
                'completion_rate': (completed_plans / total_plans * 100) if total_plans > 0 else 0
            },
            'learning_objectives': {
                'total': total_objectives,
                'quality_objectives': quality_objectives,
                'quality_rate': (quality_objectives / total_objectives * 100) if total_objectives > 0 else 0
            }
        }

        return {'dashboard': dashboard_data}

    except Exception as e:
        current_app.logger.error(f"Admin dashboard error: {str(e)}")
        return {'error': 'Failed to load dashboard'}, 500

# User Management
@admin_bp.route('/users', methods=['GET'])
@jwt_required()
@require_admin()
def admin_list_users():
    """List all users with filtering and pagination"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        search = request.args.get('search', '')
        user_type = request.args.get('user_type', '')
        status = request.args.get('status', '')

        query = User.query

        # Apply filters
        if search:
            query = query.filter(
                or_(
                    User.username.ilike(f'%{search}%'),
                    User.email.ilike(f'%{search}%'),
                    User.first_name.ilike(f'%{search}%'),
                    User.last_name.ilike(f'%{search}%')
                )
            )

        if user_type:
            query = query.filter_by(user_type=user_type)

        if status == 'active':
            query = query.filter_by(is_active=True)
        elif status == 'inactive':
            query = query.filter_by(is_active=False)

        users = query.paginate(
            page=page,
            per_page=per_page,
            error_out=False
        )

        return {
            'users': [
                {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'full_name': f"{user.first_name} {user.last_name}",
                    'user_type': user.user_type,
                    'organization': user.organization,
                    'is_active': user.is_active,
                    'is_verified': user.is_verified,
                    'created_at': user.created_at.isoformat() if user.created_at else None,
                    'last_login': user.last_login.isoformat() if user.last_login else None
                } for user in users.items
            ],
            'pagination': {
                'page': page,
                'pages': users.pages,
                'per_page': per_page,
                'total': users.total
            }
        }

    except Exception as e:
        current_app.logger.error(f"Admin users list error: {str(e)}")
        return {'error': 'Failed to list users'}, 500

@admin_bp.route('/users/<int:user_id>/assessments', methods=['GET'])
@jwt_required()
@require_admin()
def admin_user_assessments(user_id):
    """Get user's assessments for admin review"""
    try:
        user = User.query.get(user_id)
        if not user:
            return {'error': 'User not found'}, 404

        assessments = Assessment.query.filter_by(user_id=user_id).all()

        assessment_data = []
        for assessment in assessments:
            # Get competency results
            results = CompetencyAssessmentResult.query.filter_by(assessment_id=assessment.id).all()

            assessment_data.append({
                'id': assessment.id,
                'uuid': assessment.uuid,
                'type': assessment.assessment_type,
                'phase': assessment.phase,
                'status': assessment.status,
                'progress': assessment.progress_percentage,
                'organization_name': assessment.organization_name,
                'industry_domain': assessment.industry_domain,
                'started_at': assessment.started_at.isoformat() if assessment.started_at else None,
                'completed_at': assessment.completed_at.isoformat() if assessment.completed_at else None,
                'competency_count': len(results),
                'average_score': sum(r.current_level for r in results) / len(results) if results else 0
            })

        return {
            'user': {
                'id': user.id,
                'name': f"{user.first_name} {user.last_name}",
                'email': user.email,
                'organization': user.organization
            },
            'assessments': assessment_data
        }

    except Exception as e:
        current_app.logger.error(f"Admin user assessments error: {str(e)}")
        return {'error': 'Failed to get user assessments'}, 500

# Content Management
@admin_bp.route('/competencies', methods=['GET'])
@jwt_required()
@require_admin()
def admin_list_competencies():
    """List all competencies for admin management"""
    try:
        competencies = SECompetency.query.all()

        return {
            'competencies': [
                {
                    'id': comp.id,
                    'name': comp.name,
                    'category': comp.category,
                    'description': comp.description,
                    'incose_reference': comp.incose_reference,
                    'is_active': comp.is_active,
                    'level_definitions': comp.level_definitions,
                    'assessment_indicators': comp.assessment_indicators
                } for comp in competencies
            ]
        }

    except Exception as e:
        current_app.logger.error(f"Admin competencies error: {str(e)}")
        return {'error': 'Failed to list competencies'}, 500

@admin_bp.route('/competencies', methods=['POST'])
@jwt_required()
@require_admin()
def admin_create_competency():
    """Create new competency"""
    try:
        data = request.get_json()

        competency = SECompetency(
            name=data.get('name'),
            category=data.get('category'),
            description=data.get('description'),
            incose_reference=data.get('incose_reference'),
            level_definitions=data.get('level_definitions', {}),
            assessment_indicators=data.get('assessment_indicators', []),
            is_active=data.get('is_active', True)
        )

        db.session.add(competency)
        db.session.commit()

        return {
            'message': 'Competency created successfully',
            'competency': {
                'id': competency.id,
                'name': competency.name,
                'category': competency.category
            }
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Admin create competency error: {str(e)}")
        return {'error': 'Failed to create competency'}, 500

@admin_bp.route('/competencies/<int:competency_id>', methods=['PUT'])
@jwt_required()
@require_admin()
def admin_update_competency(competency_id):
    """Update competency"""
    try:
        competency = SECompetency.query.get(competency_id)
        if not competency:
            return {'error': 'Competency not found'}, 404

        data = request.get_json()

        # Update fields
        if 'name' in data:
            competency.name = data['name']
        if 'category' in data:
            competency.category = data['category']
        if 'description' in data:
            competency.description = data['description']
        if 'incose_reference' in data:
            competency.incose_reference = data['incose_reference']
        if 'level_definitions' in data:
            competency.level_definitions = data['level_definitions']
        if 'assessment_indicators' in data:
            competency.assessment_indicators = data['assessment_indicators']
        if 'is_active' in data:
            competency.is_active = data['is_active']

        db.session.commit()

        return {
            'message': 'Competency updated successfully',
            'competency': {
                'id': competency.id,
                'name': competency.name,
                'category': competency.category
            }
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Admin update competency error: {str(e)}")
        return {'error': 'Failed to update competency'}, 500

# Learning Module Management
@admin_bp.route('/modules', methods=['GET'])
@jwt_required()
@require_admin()
def admin_list_modules():
    """List all learning modules"""
    try:
        modules = LearningModule.query.all()

        return {
            'modules': [
                {
                    'id': module.id,
                    'name': module.name,
                    'description': module.description,
                    'category': module.category,
                    'difficulty_level': module.difficulty_level,
                    'estimated_duration_hours': module.estimated_duration_hours,
                    'is_active': module.is_active,
                    'created_at': module.created_at.isoformat() if module.created_at else None
                } for module in modules
            ]
        }

    except Exception as e:
        current_app.logger.error(f"Admin modules error: {str(e)}")
        return {'error': 'Failed to list modules'}, 500

@admin_bp.route('/modules', methods=['POST'])
@jwt_required()
@require_admin()
def admin_create_module():
    """Create new learning module"""
    try:
        data = request.get_json()

        module = LearningModule(
            name=data.get('name'),
            description=data.get('description'),
            category=data.get('category'),
            difficulty_level=data.get('difficulty_level', 'intermediate'),
            estimated_duration_hours=data.get('estimated_duration_hours', 0),
            prerequisites=data.get('prerequisites', []),
            learning_objectives=data.get('learning_objectives', []),
            content_outline=data.get('content_outline', []),
            delivery_methods=data.get('delivery_methods', []),
            assessment_methods=data.get('assessment_methods', []),
            resources_required=data.get('resources_required', {}),
            is_active=data.get('is_active', True)
        )

        db.session.add(module)
        db.session.commit()

        return {
            'message': 'Learning module created successfully',
            'module': {
                'id': module.id,
                'name': module.name,
                'category': module.category
            }
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Admin create module error: {str(e)}")
        return {'error': 'Failed to create module'}, 500

# System Configuration
@admin_bp.route('/config', methods=['GET'])
@jwt_required()
@require_admin()
def admin_get_config():
    """Get system configuration"""
    try:
        # Get various configuration settings
        config = {
            'platform_settings': {
                'max_file_size_mb': current_app.config.get('MAX_CONTENT_LENGTH', 0) // (1024 * 1024),
                'jwt_expiry_hours': current_app.config.get('JWT_ACCESS_TOKEN_EXPIRES', timedelta(hours=24)).total_seconds() / 3600,
                'database_url': current_app.config.get('SQLALCHEMY_DATABASE_URI', '').split('@')[-1] if '@' in current_app.config.get('SQLALCHEMY_DATABASE_URI', '') else 'Not configured'
            },
            'assessment_settings': {
                'default_phase': 1,
                'max_competencies_per_assessment': 16,
                'quality_threshold': 0.85
            },
            'rag_settings': {
                'openai_configured': bool(current_app.config.get('OPENAI_API_KEY')),
                'default_temperature': 0.7,
                'max_tokens': 2000
            }
        }

        return {'config': config}

    except Exception as e:
        current_app.logger.error(f"Admin config error: {str(e)}")
        return {'error': 'Failed to get configuration'}, 500

# Reports and Analytics
@admin_bp.route('/reports/usage', methods=['GET'])
@jwt_required()
@require_admin()
def admin_usage_report():
    """Generate usage analytics report"""
    try:
        # Date range
        days = request.args.get('days', 30, type=int)
        start_date = datetime.utcnow() - timedelta(days=days)

        # User activity
        user_registrations = db.session.query(
            func.date(User.created_at).label('date'),
            func.count(User.id).label('count')
        ).filter(
            User.created_at >= start_date
        ).group_by(func.date(User.created_at)).all()

        # Assessment activity
        assessment_activity = db.session.query(
            func.date(Assessment.created_at).label('date'),
            func.count(Assessment.id).label('count')
        ).filter(
            Assessment.created_at >= start_date
        ).group_by(func.date(Assessment.created_at)).all()

        # Plan creation
        plan_activity = db.session.query(
            func.date(QualificationPlan.created_at).label('date'),
            func.count(QualificationPlan.id).label('count')
        ).filter(
            QualificationPlan.created_at >= start_date
        ).group_by(func.date(QualificationPlan.created_at)).all()

        # Most popular competencies
        popular_competencies = db.session.query(
            SECompetency.name,
            func.count(CompetencyAssessmentResult.id).label('assessment_count')
        ).join(CompetencyAssessmentResult).group_by(SECompetency.name).order_by(
            func.count(CompetencyAssessmentResult.id).desc()
        ).limit(10).all()

        report = {
            'period': {
                'start_date': start_date.isoformat(),
                'end_date': datetime.utcnow().isoformat(),
                'days': days
            },
            'user_registrations': [
                {'date': reg.date.isoformat(), 'count': reg.count}
                for reg in user_registrations
            ],
            'assessment_activity': [
                {'date': activity.date.isoformat(), 'count': activity.count}
                for activity in assessment_activity
            ],
            'plan_activity': [
                {'date': activity.date.isoformat(), 'count': activity.count}
                for activity in plan_activity
            ],
            'popular_competencies': [
                {'competency': comp.name, 'count': comp.assessment_count}
                for comp in popular_competencies
            ]
        }

        return {'report': report}

    except Exception as e:
        current_app.logger.error(f"Admin usage report error: {str(e)}")
        return {'error': 'Failed to generate usage report'}, 500

@admin_bp.route('/reports/quality', methods=['GET'])
@jwt_required()
@require_admin()
def admin_quality_report():
    """Generate quality metrics report"""
    try:
        # Learning objectives quality
        total_objectives = LearningObjective.query.count()
        quality_objectives = LearningObjective.query.filter_by(meets_threshold=True).count()

        # Average SMART scores
        avg_smart_score = db.session.query(
            func.avg(LearningObjective.smart_score)
        ).scalar() or 0

        avg_quality_score = db.session.query(
            func.avg(LearningObjective.quality_score)
        ).scalar() or 0

        # Assessment completion rates
        total_assessments = Assessment.query.count()
        completed_assessments = Assessment.query.filter_by(status='completed').count()

        # Plan completion rates
        total_plans = QualificationPlan.query.count()
        completed_plans = QualificationPlan.query.filter_by(status='completed').count()

        quality_report = {
            'learning_objectives': {
                'total': total_objectives,
                'meeting_quality_threshold': quality_objectives,
                'quality_rate': (quality_objectives / total_objectives * 100) if total_objectives > 0 else 0,
                'average_smart_score': round(avg_smart_score, 2),
                'average_quality_score': round(avg_quality_score, 2)
            },
            'assessments': {
                'total': total_assessments,
                'completed': completed_assessments,
                'completion_rate': (completed_assessments / total_assessments * 100) if total_assessments > 0 else 0
            },
            'qualification_plans': {
                'total': total_plans,
                'completed': completed_plans,
                'completion_rate': (completed_plans / total_plans * 100) if total_plans > 0 else 0
            }
        }

        return {'quality_report': quality_report}

    except Exception as e:
        current_app.logger.error(f"Admin quality report error: {str(e)}")
        return {'error': 'Failed to generate quality report'}, 500