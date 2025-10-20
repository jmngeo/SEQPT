"""
Unified SE-QPT + Derik Models
Uses Derik's tables as foundation, extends for SE-QPT features
Author: Integration Team
Date: 2025-10-01
"""

from datetime import datetime
import uuid
import json
import hashlib
import time
from werkzeug.security import generate_password_hash, check_password_hash

# Lazy import to avoid circular dependency
# db will be imported from models when needed
db = None

def _get_db():
    global db
    if db is None:
        from models import db as models_db
        db = models_db
    return db

# For convenience, make db available at module level after first import
try:
    from models import db
except ImportError:
    # If models can't be imported yet, db will be set later
    pass

# =============================================================================
# DERIK'S MASTER DATA (READ-ONLY REFERENCES)
# These tables are managed by Derik's system - we only read from them
# =============================================================================

class Organization(db.Model):
    """
    Derik's organization table - EXTENDED for SE-QPT Phase 1
    Uses Derik's existing table structure with SE-QPT additions
    """
    __tablename__ = 'organization'
    __table_args__ = {'extend_existing': True}

    # Derik's original fields
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    organization_name = db.Column(db.String(255), nullable=False, unique=True)
    organization_public_key = db.Column(db.String(50), nullable=False, unique=True,
                                       default='singleuser')

    # SE-QPT Phase 1 extensions (NEW COLUMNS - added via migration)
    size = db.Column(db.String(20))  # 'small', 'medium', 'large', 'enterprise'
    maturity_score = db.Column(db.Float)  # Overall maturity score (0-5)
    selected_archetype = db.Column(db.String(100))  # Selected qualification archetype
    phase1_completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    @staticmethod
    def generate_public_key(org_name):
        """Generate unique organization public key"""
        base = f"{org_name}_{int(time.time() * 1000)}"
        hash_key = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

        # Check uniqueness
        while Organization.query.filter_by(organization_public_key=hash_key).first():
            base = f"{org_name}_{int(time.time() * 1000)}_{uuid.uuid4().hex[:4]}"
            hash_key = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

        return hash_key

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.organization_name,
            'organization_code': self.organization_public_key,  # Alias for frontend compatibility
            'size': self.size,
            'maturity_score': self.maturity_score,
            'selected_archetype': self.selected_archetype,
            'phase1_completed': self.phase1_completed,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Competency(db.Model):
    """
    Derik's 16 SE competencies - READ ONLY
    Based on INCOSE competency framework
    """
    __tablename__ = 'competency'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    competency_name = db.Column(db.String(255), nullable=False)
    competency_area = db.Column(db.String(50))  # 'Core', 'Technical', 'Management', etc.
    description = db.Column(db.Text)
    why_it_matters = db.Column(db.Text)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.competency_name,
            'area': self.competency_area,
            'description': self.description,
            'why_it_matters': self.why_it_matters
        }


class RoleCluster(db.Model):
    """
    Derik's 16 role clusters - READ ONLY
    Defines SE roles across organizations
    """
    __tablename__ = 'role_cluster'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False)
    role_cluster_description = db.Column(db.Text, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.role_cluster_name,
            'description': self.role_cluster_description
        }


class AppUser(db.Model):
    """
    Derik's app_user table - READ ONLY reference
    User accounts managed by Derik's system
    """
    __tablename__ = 'app_user'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(255), unique=True)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))

    # Relationship
    organization = db.relationship('Organization', backref='users', foreign_keys=[organization_id])

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'organization_id': self.organization_id
        }


# =============================================================================
# DERIK'S ASSESSMENT DATA (EXTENDED FOR SE-QPT)
# =============================================================================

class UserCompetencySurveyResult(db.Model):
    """
    Derik's survey results - EXTENDED for SE-QPT gap analysis
    Stores individual competency assessment scores with gap calculations
    """
    __tablename__ = 'user_se_competency_survey_results'
    __table_args__ = {'extend_existing': True}

    # Derik's original fields
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'))
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'))
    score = db.Column(db.Integer, nullable=False)  # Current level (1-5)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)

    # SE-QPT gap analysis extensions (NEW COLUMNS - added via migration)
    target_level = db.Column(db.Integer)  # Target level from archetype matrix
    gap_size = db.Column(db.Integer)  # Calculated: target_level - score
    archetype_source = db.Column(db.String(100))  # Which archetype defined target
    learning_plan_id = db.Column(db.String(36), db.ForeignKey('learning_plans.id'))

    # Relationships
    competency = db.relationship('Competency', backref='survey_results', foreign_keys=[competency_id])
    organization = db.relationship('Organization', backref='survey_results', foreign_keys=[organization_id])
    user = db.relationship('AppUser', backref='survey_results', foreign_keys=[user_id])
    learning_plan = db.relationship('LearningPlan', backref='survey_results', foreign_keys=[learning_plan_id])

    def calculate_gap(self, target_level):
        """Calculate and update gap size"""
        self.target_level = target_level
        self.gap_size = max(0, target_level - self.score) if target_level else 0
        return self.gap_size

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'competency_id': self.competency_id,
            'competency_name': self.competency.competency_name if self.competency else None,
            'current_level': self.score,
            'target_level': self.target_level,
            'gap_size': self.gap_size,
            'archetype_source': self.archetype_source,
            'submitted_at': self.submitted_at.isoformat() if self.submitted_at else None
        }


# =============================================================================
# SE-QPT SPECIFIC TABLES (NEW)
# =============================================================================

class LearningPlan(db.Model):
    """
    SE-QPT learning plans with RAG-LLM generated SMART objectives
    This is SE-QPT's innovation - personalized learning objectives
    """
    __tablename__ = 'learning_plans'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Learning objectives (RAG-LLM generated, stored as JSON)
    objectives = db.Column(db.Text, nullable=False)  # JSON array of SMART objectives

    # Recommended modules (JSON array)
    recommended_modules = db.Column(db.Text)

    # Plan metadata
    estimated_duration_weeks = db.Column(db.Integer)
    archetype_used = db.Column(db.String(100))  # Which archetype was used

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship('AppUser', backref='learning_plans', foreign_keys=[user_id])
    organization = db.relationship('Organization', backref='learning_plans', foreign_keys=[organization_id])

    def get_objectives(self):
        """Get objectives as Python list"""
        if self.objectives:
            return json.loads(self.objectives)
        return []

    def set_objectives(self, objectives_list):
        """Set objectives from Python list"""
        self.objectives = json.dumps(objectives_list, ensure_ascii=False)

    def get_recommended_modules(self):
        """Get recommended modules as Python list"""
        if self.recommended_modules:
            return json.loads(self.recommended_modules)
        return []

    def set_recommended_modules(self, modules_list):
        """Set recommended modules from Python list"""
        self.recommended_modules = json.dumps(modules_list, ensure_ascii=False)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'objectives': self.get_objectives(),
            'recommended_modules': self.get_recommended_modules(),
            'estimated_duration_weeks': self.estimated_duration_weeks,
            'archetype_used': self.archetype_used,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class PhaseQuestionnaireResponse(db.Model):
    """
    Store simplified questionnaire responses for SE-QPT phases
    Simpler than the full Questionnaire system - just stores JSON responses
    """
    __tablename__ = 'phase_questionnaire_responses'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Questionnaire metadata
    questionnaire_type = db.Column(db.String(50), nullable=False)  # 'maturity', 'archetype_selection'
    phase = db.Column(db.Integer, nullable=False)  # 1, 2, 3, 4

    # Response data (stored as JSON)
    responses = db.Column(db.Text, nullable=False)  # Raw responses
    computed_scores = db.Column(db.Text)  # Calculated scores/results

    # Timestamps
    completed_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship('AppUser', backref='questionnaire_responses', foreign_keys=[user_id])
    organization = db.relationship('Organization', backref='questionnaire_responses', foreign_keys=[organization_id])

    def get_responses(self):
        """Get responses as Python dict"""
        if self.responses:
            return json.loads(self.responses)
        return {}

    def set_responses(self, responses_dict):
        """Set responses from Python dict"""
        self.responses = json.dumps(responses_dict, ensure_ascii=False)

    def get_computed_scores(self):
        """Get computed scores as Python dict"""
        if self.computed_scores:
            return json.loads(self.computed_scores)
        return {}

    def set_computed_scores(self, scores_dict):
        """Set computed scores from Python dict"""
        self.computed_scores = json.dumps(scores_dict, ensure_ascii=False)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'questionnaire_type': self.questionnaire_type,
            'phase': self.phase,
            'responses': self.get_responses(),
            'computed_scores': self.get_computed_scores(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None
        }


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_organization_by_code(org_code):
    """Get organization by public key (code)"""
    return Organization.query.filter_by(organization_public_key=org_code).first()


def get_user_competency_gaps(user_id, organization_id=None):
    """Get all competency gaps for a user"""
    query = UserCompetencySurveyResult.query.filter_by(user_id=user_id)
    if organization_id:
        query = query.filter_by(organization_id=organization_id)

    results = query.filter(UserCompetencySurveyResult.gap_size > 0).all()
    return [r.to_dict() for r in results]


def get_organization_completion_stats(organization_id):
    """Get Phase 1/2 completion statistics for organization"""
    org = Organization.query.get(organization_id)
    if not org:
        return None

    total_users = AppUser.query.filter_by(organization_id=organization_id).count()

    # Count users with completed assessments
    users_with_assessments = db.session.query(
        db.func.count(db.distinct(UserCompetencySurveyResult.user_id))
    ).filter_by(organization_id=organization_id).scalar()

    return {
        'organization_id': organization_id,
        'organization_name': org.organization_name,
        'phase1_completed': org.phase1_completed,
        'selected_archetype': org.selected_archetype,
        'total_users': total_users,
        'users_with_assessments': users_with_assessments or 0,
        'completion_rate': (users_with_assessments / total_users * 100) if total_users > 0 else 0
    }
