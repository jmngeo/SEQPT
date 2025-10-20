"""
SE-QPT MVP Database Models
UPDATED: Uses unified_models for Derik integration
Date: 2025-10-01
"""

from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import json

# Import db from existing models to use same SQLAlchemy instance
from models import db

# Import unified models (Derik integration)
from unified_models import (
    Organization,  # Use Derik's organization table (extended)
    Competency,  # Use Derik's competency table
    RoleCluster,  # Use Derik's role_cluster table
    AppUser,  # Use Derik's app_user table
    UserCompetencySurveyResult,  # Use Derik's survey results (extended)
    LearningPlan,  # SE-QPT specific
    PhaseQuestionnaireResponse  # SE-QPT specific (simplified questionnaires)
)

# =============================================================================
# NOTE: Organization class is now imported from unified_models
# It references Derik's 'organization' table with SE-QPT extensions
# =============================================================================


class MVPUser(db.Model):
    """Simplified user model with two-tier role structure"""
    __tablename__ = 'mvp_users'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

    # User profile
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)

    # Two-tier role system
    role = db.Column(db.String(20), nullable=False)  # 'admin' or 'employee'

    # Organization relationship
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)
    joined_via_code = db.Column(db.String(8))  # Organization code used to join

    # Status
    is_active = db.Column(db.Boolean, default=True)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    # NOTE: Relationships disabled - queries use explicit joins for better control
    # MVPUser → CompetencyAssessment: Query via CompetencyAssessment.query.filter_by(user_id=...)
    # MVPUser → LearningPlan: Query via LearningPlan.query.filter_by(user_id=...)
    # MVPUser → RoleMapping: Query via RoleMapping.query.filter_by(user_id=...)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    @property
    def is_admin(self):
        return self.role == 'admin'

    @property
    def is_employee(self):
        return self.role == 'employee'

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.full_name,
            'role': self.role,
            'organization_id': self.organization_id,
            'joined_via_code': self.joined_via_code,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None
        }


class MaturityAssessment(db.Model):
    """Organizational maturity assessment (Admin only)"""
    __tablename__ = 'maturity_assessments'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Maturity scores
    scope_score = db.Column(db.Float, nullable=False)
    process_score = db.Column(db.Float, nullable=False)
    overall_maturity = db.Column(db.String(20), nullable=False)  # 'Initial', 'Developing', etc.
    overall_score = db.Column(db.Float, nullable=False)

    # Raw responses (JSON storage)
    responses = db.Column(db.Text)  # JSON string of all 33 question responses

    # Timestamps
    completed_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'organization_id': self.organization_id,
            'scope_score': self.scope_score,
            'process_score': self.process_score,
            'overall_maturity': self.overall_maturity,
            'overall_score': self.overall_score,
            'responses': json.loads(self.responses) if self.responses else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None
        }


# =============================================================================
# COMPATIBILITY ALIASES for existing code
# =============================================================================

# CompetencyAssessment → UserCompetencySurveyResult
CompetencyAssessment = UserCompetencySurveyResult

# RoleMapping: Create compatibility class that maps to Derik's structure
class RoleMapping:
    """
    Compatibility wrapper for role mapping functionality
    In unified system, this is handled by:
    - Derik's user_role_cluster table (not yet used)
    - PhaseQuestionnaireResponse for SE-QPT archetype selection

    This is a minimal placeholder to maintain API compatibility
    """
    @staticmethod
    def query_by_user(user_id):
        """Query role mapping for a user - returns None for now"""
        # TODO: Implement using PhaseQuestionnaireResponse or user_role_cluster
        return None

    @staticmethod
    def create(user_id, role_id, archetype):
        """Create role mapping - stores in PhaseQuestionnaireResponse"""
        # TODO: Implement using PhaseQuestionnaireResponse
        pass


# =============================================================================
# MVP BUSINESS LOGIC FUNCTIONS
# =============================================================================

def calculate_maturity_score(responses):
    """
    Calculate maturity score from 33-question assessment
    Based on MVP architecture specification
    """
    # Scope questions (1-15)
    scope_questions = responses[:15]
    # Process questions (16-33)
    process_questions = responses[15:33]

    # Calculate averages
    scope_score = sum(q.get('score', 0) for q in scope_questions) / len(scope_questions)
    process_score = sum(q.get('score', 0) for q in process_questions) / len(process_questions)

    # Calculate overall maturity (geometric mean)
    import math
    overall_maturity_score = math.sqrt((scope_score ** 2 + process_score ** 2) / 2)

    # Determine maturity level
    if overall_maturity_score <= 1.5:
        level = 'Initial'
    elif overall_maturity_score <= 2.5:
        level = 'Developing'
    elif overall_maturity_score <= 3.5:
        level = 'Defined'
    elif overall_maturity_score <= 4.0:
        level = 'Managed'
    else:
        level = 'Optimized'

    return {
        'scope_score': round(scope_score, 2),
        'process_score': round(process_score, 2),
        'overall_score': round(overall_maturity_score, 2),
        'overall_maturity': level
    }


def select_archetype(maturity_result, preferences=None):
    """
    Select qualification archetype based on maturity and preferences
    Based on MVP architecture specification
    """
    scope_score = maturity_result['scope_score']
    process_score = maturity_result['process_score']

    if process_score <= 1.5:
        # Low maturity - dual selection needed
        primary = 'SE_for_Managers'

        # Determine secondary based on preferences
        if preferences and preferences.get('goal'):
            goal = preferences['goal']
            if goal == 'apply_se':
                secondary = 'Orientation_Pilot_Project'
            elif goal == 'basic_understanding':
                secondary = 'Common_Understanding'
            elif goal == 'expert_training':
                secondary = 'Certification'
            else:
                secondary = 'Common_Understanding'
        else:
            secondary = 'Common_Understanding'

        return {
            'primary': primary,
            'secondary': secondary,
            'customization_level': 'low',
            'dual_selection': True
        }
    else:
        # Higher maturity - single selection
        if scope_score >= 3.0:
            archetype = 'Continuous_Support'
        else:
            archetype = 'Needs_Based_Training'

        return {
            'primary': archetype,
            'secondary': None,
            'customization_level': 'high',
            'dual_selection': False
        }


def generate_learning_plan_templates():
    """
    Template-based learning objectives for different archetypes
    Based on MVP architecture specification
    """
    return {
        'SE_for_Managers': [
            'Understand Systems Engineering fundamentals',
            'Learn SE process integration',
            'Develop SE leadership skills',
            'Master SE project management',
            'Build SE team coordination capabilities'
        ],
        'Common_Understanding': [
            'Gain SE awareness across organization',
            'Understand SE terminology and concepts',
            'Learn basic SE tools and methods',
            'Develop SE communication skills',
            'Understand SE lifecycle processes'
        ],
        'Orientation_Pilot_Project': [
            'Complete hands-on SE project',
            'Apply SE methods in practice',
            'Develop practical SE skills',
            'Build SE experience portfolio',
            'Demonstrate SE competency'
        ],
        'Certification': [
            'Prepare for SE certification',
            'Master advanced SE concepts',
            'Complete SE knowledge assessment',
            'Develop expert-level SE skills',
            'Achieve professional SE recognition'
        ],
        'Continuous_Support': [
            'Maintain SE competency levels',
            'Stay current with SE innovations',
            'Develop advanced SE specializations',
            'Mentor other SE professionals',
            'Lead SE improvement initiatives'
        ],
        'Needs_Based_Training': [
            'Address specific SE skill gaps',
            'Complete targeted SE training',
            'Develop project-specific SE capabilities',
            'Apply SE methods to current work',
            'Build contextual SE expertise'
        ]
    }


def generate_basic_modules(archetype):
    """
    Basic module recommendations based on archetype
    Based on MVP architecture specification
    """
    module_templates = {
        'SE_for_Managers': [
            'SE Management Fundamentals',
            'SE Leadership and Teams',
            'SE Process Integration',
            'SE Project Planning'
        ],
        'Common_Understanding': [
            'Introduction to Systems Engineering',
            'SE Terminology and Concepts',
            'Basic SE Tools',
            'SE Communication'
        ],
        'Orientation_Pilot_Project': [
            'SE Project Methods',
            'Hands-on SE Practice',
            'SE Tool Application',
            'Project Portfolio Development'
        ],
        'Certification': [
            'Advanced SE Concepts',
            'SE Certification Prep',
            'Expert SE Methods',
            'Professional SE Standards'
        ]
    }

    return module_templates.get(archetype, [])


def calculate_duration(objectives_count):
    """
    Estimate learning plan duration based on objective count
    """
    # Simple estimation: 2-3 weeks per objective
    base_weeks = objectives_count * 2.5
    return max(4, min(52, int(base_weeks)))  # Minimum 4 weeks, maximum 52 weeks