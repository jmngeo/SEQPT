"""
SE Competency Module API Routes
Handles all learning module and learning path endpoints
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import json

from models import (
    db, User, LearningModule, LearningPath, ModuleEnrollment,
    ModuleAssessment, LearningResource, SECompetency,
    CompetencyAssessmentResult, QuestionnaireResponse
)

module_bp = Blueprint('modules', __name__)

# Learning Modules Endpoints

@module_bp.route('/modules', methods=['GET'])
@jwt_required()
def get_learning_modules():
    """Get all available learning modules with filtering"""
    try:
        # Query parameters
        category = request.args.get('category')
        difficulty = request.args.get('difficulty')
        competency_id = request.args.get('competency_id', type=int)
        search = request.args.get('search', '').strip()

        # Base query
        query = LearningModule.query.filter_by(is_active=True)

        # Apply filters
        if category:
            query = query.filter_by(category=category)
        if difficulty:
            query = query.filter_by(difficulty_level=difficulty)
        if competency_id:
            query = query.filter_by(competency_id=competency_id)
        if search:
            query = query.filter(
                LearningModule.name.ilike(f'%{search}%') |
                LearningModule.definition.ilike(f'%{search}%') |
                LearningModule.overview.ilike(f'%{search}%')
            )

        modules = query.order_by(LearningModule.module_code).all()

        modules_data = []
        for module in modules:
            modules_data.append({
                'id': module.id,
                'uuid': module.uuid,
                'module_code': module.module_code,
                'name': module.name,
                'category': module.category,
                'definition': module.definition,
                'overview': module.overview,
                'total_duration_hours': module.total_duration_hours,
                'difficulty_level': module.difficulty_level,
                'competency': {
                    'id': module.competency.id,
                    'name': module.competency.name,
                    'code': module.competency.code
                } if module.competency else None,
                'prerequisites': json.loads(module.prerequisites) if module.prerequisites else [],
                'created_at': module.created_at.isoformat()
            })

        return {
            'modules': modules_data,
            'total': len(modules_data),
            'filters_applied': {
                'category': category,
                'difficulty': difficulty,
                'competency_id': competency_id,
                'search': search
            }
        }

    except Exception as e:
        current_app.logger.error(f"Get learning modules error: {str(e)}")
        return {'error': 'Failed to get learning modules'}, 500

@module_bp.route('/modules/<module_code>', methods=['GET'])
@jwt_required()
def get_module_details(module_code):
    """Get detailed module information including all levels"""
    try:
        module = LearningModule.query.filter_by(
            module_code=module_code.upper(),
            is_active=True
        ).first()

        if not module:
            return {'error': 'Module not found'}, 404

        # Parse level content
        level_contents = {}
        for level in ['level_1_content', 'level_2_content', 'level_3_4_content', 'level_5_6_content']:
            content = getattr(module, level)
            if content:
                level_contents[level] = json.loads(content)

        module_data = {
            'id': module.id,
            'uuid': module.uuid,
            'module_code': module.module_code,
            'name': module.name,
            'category': module.category,
            'definition': module.definition,
            'overview': module.overview,
            'industry_relevance': module.industry_relevance,
            'total_duration_hours': module.total_duration_hours,
            'difficulty_level': module.difficulty_level,
            'version': module.version,
            'competency': {
                'id': module.competency.id,
                'name': module.competency.name,
                'code': module.competency.code,
                'category': module.competency.category
            } if module.competency else None,
            'prerequisites': json.loads(module.prerequisites) if module.prerequisites else [],
            'dependencies': json.loads(module.dependencies) if module.dependencies else [],
            'industry_adaptations': json.loads(module.industry_adaptations) if module.industry_adaptations else {},
            'level_contents': level_contents,
            'created_at': module.created_at.isoformat(),
            'updated_at': module.updated_at.isoformat()
        }

        return {'module': module_data}

    except Exception as e:
        current_app.logger.error(f"Get module details error: {str(e)}")
        return {'error': 'Failed to get module details'}, 500

@module_bp.route('/modules/by-competency/<int:competency_id>', methods=['GET'])
@jwt_required()
def get_modules_by_competency(competency_id):
    """Get all modules for a specific competency"""
    try:
        competency = SECompetency.query.get(competency_id)
        if not competency:
            return {'error': 'Competency not found'}, 404

        modules = LearningModule.query.filter_by(
            competency_id=competency_id,
            is_active=True
        ).order_by(LearningModule.module_code).all()

        modules_data = []
        for module in modules:
            modules_data.append({
                'id': module.id,
                'uuid': module.uuid,
                'module_code': module.module_code,
                'name': module.name,
                'category': module.category,
                'total_duration_hours': module.total_duration_hours,
                'difficulty_level': module.difficulty_level,
                'prerequisites': json.loads(module.prerequisites) if module.prerequisites else []
            })

        return {
            'competency': {
                'id': competency.id,
                'name': competency.name,
                'code': competency.code,
                'category': competency.category
            },
            'modules': modules_data,
            'total': len(modules_data)
        }

    except Exception as e:
        current_app.logger.error(f"Get modules by competency error: {str(e)}")
        return {'error': 'Failed to get modules by competency'}, 500

# Learning Paths Endpoints

@module_bp.route('/learning-paths', methods=['GET'])
@jwt_required()
def get_learning_paths():
    """Get all available learning paths"""
    try:
        path_type = request.args.get('path_type')
        industry = request.args.get('industry')
        experience_level = request.args.get('experience_level')

        query = LearningPath.query.filter_by(is_active=True)

        if path_type:
            query = query.filter_by(path_type=path_type)
        if industry:
            query = query.filter_by(industry_focus=industry)
        if experience_level:
            query = query.filter_by(experience_level=experience_level)

        paths = query.order_by(LearningPath.name).all()

        paths_data = []
        for path in paths:
            paths_data.append({
                'id': path.id,
                'uuid': path.uuid,
                'name': path.name,
                'description': path.description,
                'path_type': path.path_type,
                'target_audience': path.target_audience,
                'industry_focus': path.industry_focus,
                'role_focus': path.role_focus,
                'experience_level': path.experience_level,
                'estimated_duration_weeks': path.estimated_duration_weeks,
                'module_sequence': json.loads(path.module_sequence) if path.module_sequence else [],
                'completion_criteria': json.loads(path.completion_criteria) if path.completion_criteria else {},
                'created_at': path.created_at.isoformat()
            })

        return {
            'learning_paths': paths_data,
            'total': len(paths_data)
        }

    except Exception as e:
        current_app.logger.error(f"Get learning paths error: {str(e)}")
        return {'error': 'Failed to get learning paths'}, 500

@module_bp.route('/learning-paths/<path_uuid>', methods=['GET'])
@jwt_required()
def get_learning_path_details(path_uuid):
    """Get detailed learning path with module information"""
    try:
        path = LearningPath.query.filter_by(uuid=path_uuid, is_active=True).first()
        if not path:
            return {'error': 'Learning path not found'}, 404

        # Get detailed module information for the path
        module_sequence = json.loads(path.module_sequence) if path.module_sequence else []
        modules_info = []

        for module_code in module_sequence:
            module = LearningModule.query.filter_by(
                module_code=module_code,
                is_active=True
            ).first()
            if module:
                modules_info.append({
                    'module_code': module.module_code,
                    'name': module.name,
                    'category': module.category,
                    'total_duration_hours': module.total_duration_hours,
                    'difficulty_level': module.difficulty_level,
                    'competency_name': module.competency.name if module.competency else None
                })

        path_data = {
            'id': path.id,
            'uuid': path.uuid,
            'name': path.name,
            'description': path.description,
            'path_type': path.path_type,
            'target_audience': path.target_audience,
            'industry_focus': path.industry_focus,
            'role_focus': path.role_focus,
            'experience_level': path.experience_level,
            'estimated_duration_weeks': path.estimated_duration_weeks,
            'module_sequence': module_sequence,
            'modules_info': modules_info,
            'completion_criteria': json.loads(path.completion_criteria) if path.completion_criteria else {},
            'assessment_strategy': json.loads(path.assessment_strategy) if path.assessment_strategy else {},
            'created_at': path.created_at.isoformat(),
            'updated_at': path.updated_at.isoformat()
        }

        return {'learning_path': path_data}

    except Exception as e:
        current_app.logger.error(f"Get learning path details error: {str(e)}")
        return {'error': 'Failed to get learning path details'}, 500

# Module Enrollment Endpoints

@module_bp.route('/modules/<module_code>/enroll', methods=['POST'])
@jwt_required()
def enroll_in_module(module_code):
    """Enroll user in a learning module"""
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()

        module = LearningModule.query.filter_by(
            module_code=module_code.upper(),
            is_active=True
        ).first()

        if not module:
            return {'error': 'Module not found'}, 404

        # Check if already enrolled
        existing_enrollment = ModuleEnrollment.query.filter_by(
            user_id=user_id,
            module_id=module.id
        ).first()

        if existing_enrollment:
            return {
                'message': 'Already enrolled in this module',
                'enrollment': {
                    'uuid': existing_enrollment.uuid,
                    'status': existing_enrollment.status,
                    'progress_percentage': existing_enrollment.progress_percentage
                }
            }

        # Create new enrollment
        enrollment = ModuleEnrollment(
            user_id=user_id,
            module_id=module.id,
            target_level=data.get('target_level', 1),
            learning_style_preference=data.get('learning_style_preference'),
            status='enrolled'
        )

        db.session.add(enrollment)
        db.session.commit()

        return {
            'message': 'Successfully enrolled in module',
            'enrollment': {
                'uuid': enrollment.uuid,
                'module_code': module.module_code,
                'module_name': module.name,
                'target_level': enrollment.target_level,
                'status': enrollment.status,
                'enrolled_at': enrollment.enrolled_at.isoformat()
            }
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Module enrollment error: {str(e)}")
        return {'error': 'Failed to enroll in module'}, 500

@module_bp.route('/enrollments', methods=['GET'])
@jwt_required()
def get_user_enrollments():
    """Get all enrollments for the current user"""
    try:
        user_id = int(get_jwt_identity())

        enrollments = ModuleEnrollment.query.filter_by(user_id=user_id).order_by(
            ModuleEnrollment.enrolled_at.desc()
        ).all()

        enrollments_data = []
        for enrollment in enrollments:
            enrollments_data.append({
                'uuid': enrollment.uuid,
                'module': {
                    'code': enrollment.module.module_code,
                    'name': enrollment.module.name,
                    'category': enrollment.module.category,
                    'total_duration_hours': enrollment.module.total_duration_hours
                },
                'target_level': enrollment.target_level,
                'current_level': enrollment.current_level,
                'status': enrollment.status,
                'progress_percentage': enrollment.progress_percentage,
                'time_spent_hours': enrollment.time_spent_hours,
                'enrolled_at': enrollment.enrolled_at.isoformat(),
                'last_accessed_at': enrollment.last_accessed_at.isoformat() if enrollment.last_accessed_at else None
            })

        return {
            'enrollments': enrollments_data,
            'total': len(enrollments_data)
        }

    except Exception as e:
        current_app.logger.error(f"Get user enrollments error: {str(e)}")
        return {'error': 'Failed to get enrollments'}, 500

@module_bp.route('/enrollments/<enrollment_uuid>/progress', methods=['POST'])
@jwt_required()
def update_module_progress(enrollment_uuid):
    """Update progress for a module enrollment"""
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()

        enrollment = ModuleEnrollment.query.filter_by(
            uuid=enrollment_uuid,
            user_id=user_id
        ).first()

        if not enrollment:
            return {'error': 'Enrollment not found'}, 404

        # Update progress
        if 'progress_percentage' in data:
            enrollment.progress_percentage = min(100.0, max(0.0, data['progress_percentage']))

        if 'time_spent_hours' in data:
            enrollment.time_spent_hours = data['time_spent_hours']

        if 'current_level' in data:
            enrollment.current_level = data['current_level']

        if 'status' in data:
            enrollment.status = data['status']
            if data['status'] == 'in_progress' and not enrollment.started_at:
                enrollment.started_at = datetime.utcnow()
            elif data['status'] == 'completed':
                enrollment.completed_at = datetime.utcnow()
                enrollment.progress_percentage = 100.0

        enrollment.last_accessed_at = datetime.utcnow()

        db.session.commit()

        return {
            'message': 'Progress updated successfully',
            'enrollment': {
                'uuid': enrollment.uuid,
                'status': enrollment.status,
                'progress_percentage': enrollment.progress_percentage,
                'current_level': enrollment.current_level,
                'time_spent_hours': enrollment.time_spent_hours
            }
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Update module progress error: {str(e)}")
        return {'error': 'Failed to update progress'}, 500

# Recommendation Endpoints

@module_bp.route('/recommendations', methods=['GET'])
@jwt_required()
def get_module_recommendations():
    """Get personalized module recommendations based on competency assessment"""
    try:
        user_id = int(get_jwt_identity())

        # Get latest competency assessment results
        latest_assessment = QuestionnaireResponse.query.filter_by(
            user_id=user_id,
            status='completed'
        ).join(
            QuestionnaireResponse.questionnaire
        ).filter_by(
            questionnaire_type='competency'
        ).order_by(
            QuestionnaireResponse.completed_at.desc()
        ).first()

        if not latest_assessment:
            return {
                'message': 'No competency assessment found. Complete a competency assessment to get personalized recommendations.',
                'recommendations': []
            }

        # Analyze competency gaps and recommend modules
        recommendations = []

        # Parse assessment results to identify competency gaps
        results_summary = json.loads(latest_assessment.results_summary) if latest_assessment.results_summary else {}
        competency_breakdown = results_summary.get('competency_breakdown', {})

        # Find modules for competencies with low scores
        for competency_name, competency_data in competency_breakdown.items():
            current_level = competency_data.get('current_level', 0)

            if current_level < 3:  # Recommend modules for competencies below level 3
                # Find competency and its modules
                competency = SECompetency.query.filter_by(name=competency_name).first()
                if competency:
                    modules = LearningModule.query.filter_by(
                        competency_id=competency.id,
                        is_active=True
                    ).all()

                    for module in modules:
                        # Check if user is already enrolled
                        existing_enrollment = ModuleEnrollment.query.filter_by(
                            user_id=user_id,
                            module_id=module.id
                        ).first()

                        if not existing_enrollment:
                            recommendations.append({
                                'module': {
                                    'code': module.module_code,
                                    'name': module.name,
                                    'category': module.category,
                                    'total_duration_hours': module.total_duration_hours,
                                    'competency_name': competency.name
                                },
                                'reason': f'Strengthen {competency_name} competency (current level: {current_level})',
                                'priority': 'high' if current_level < 2 else 'medium',
                                'recommended_target_level': min(current_level + 2, 4)
                            })

        # Sort by priority and limit results
        priority_order = {'high': 0, 'medium': 1, 'low': 2}
        recommendations.sort(key=lambda x: priority_order.get(x['priority'], 3))
        recommendations = recommendations[:10]  # Limit to top 10

        return {
            'assessment_date': latest_assessment.completed_at.isoformat(),
            'recommendations': recommendations,
            'total': len(recommendations)
        }

    except Exception as e:
        current_app.logger.error(f"Get module recommendations error: {str(e)}")
        return {'error': 'Failed to get recommendations'}, 500

@module_bp.route('/categories', methods=['GET'])
def get_module_categories():
    """Get all available module categories and statistics"""
    try:
        categories = db.session.query(
            LearningModule.category,
            db.func.count(LearningModule.id).label('module_count'),
            db.func.avg(LearningModule.total_duration_hours).label('avg_duration')
        ).filter_by(is_active=True).group_by(LearningModule.category).all()

        categories_data = []
        for category, count, avg_duration in categories:
            categories_data.append({
                'name': category,
                'module_count': count,
                'average_duration_hours': round(avg_duration, 1) if avg_duration else 0
            })

        return {
            'categories': categories_data,
            'total_categories': len(categories_data)
        }

    except Exception as e:
        current_app.logger.error(f"Get module categories error: {str(e)}")
        return {'error': 'Failed to get categories'}, 500