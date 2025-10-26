"""
SE-QPT Unified Database Models
Combines Marcel's methodology, Derik's competency assessment, MVP features, and RAG-LLM innovations

This file unifies three previously separate model files:
- models.py (SE-QPT main models)
- unified_models.py (Derik's competency assessment models
- mvp_models.py (MVP/simplified models)

Author: Integration Team
Date: 2025-10-20
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import json
import hashlib
import time
import math

# =============================================================================
# DATABASE INITIALIZATION
# =============================================================================
db = SQLAlchemy()


# =============================================================================
# SECTION 1: CORE ENTITIES (Derik's Foundation)
# =============================================================================

class Organization(db.Model):
    """
    Derik's organization table - EXTENDED for SE-QPT Phase 1
    Uses Derik's existing table structure with SE-QPT additions
    """
    __tablename__ = 'organization'

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
    Derik's 16 SE competencies
    Based on INCOSE competency framework
    """
    __tablename__ = 'competency'

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


class CompetencyIndicator(db.Model):
    """
    Derik's competency indicators - specific observable behaviors for each competency
    Organized by proficiency level (1-4)
    """
    __tablename__ = 'competency_indicators'

    id = db.Column(db.Integer, primary_key=True)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=True)
    level = db.Column(db.String(50), nullable=True)  # Can hold 'verstehen', 'beherrschen', 'kennen', 'anwenden'
    indicator_en = db.Column(db.Text, nullable=True)  # English indicator text
    indicator_de = db.Column(db.Text, nullable=True)  # German indicator text

    # Relationship to Competency
    competency = db.relationship('Competency', backref=db.backref('indicators', cascade="all, delete-orphan", lazy=True))


class RoleCluster(db.Model):
    """
    Derik's 16 role clusters
    Defines SE roles across organizations
    """
    __tablename__ = 'role_cluster'

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False)
    role_cluster_description = db.Column(db.Text, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.role_cluster_name,
            'description': self.role_cluster_description
        }


# =============================================================================
# SECTION 2: ISO/IEC 15288 PROCESS MODELS (Derik's Task-Based Role Mapping)
# =============================================================================

class IsoSystemLifeCycleProcesses(db.Model):
    """
    ISO/IEC 15288 System Life Cycle Process Groups
    Four main process groups: Agreement, Organizational, Technical, Project
    """
    __tablename__ = 'iso_system_life_cycle_processes'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)

    # Relationships
    processes = db.relationship('IsoProcesses', backref='life_cycle_process', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name
        }


class IsoProcesses(db.Model):
    """
    ISO/IEC 15288 System Engineering Processes
    Approximately 30 processes defined in the standard
    """
    __tablename__ = 'iso_processes'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    life_cycle_process_id = db.Column(db.Integer, db.ForeignKey('iso_system_life_cycle_processes.id'))

    # Relationships removed: IsoActivities model was deleted in Phase 2A cleanup

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'life_cycle_process_id': self.life_cycle_process_id
        }


class RoleProcessMatrix(db.Model):
    """
    Maps SE role clusters to ISO processes
    Defines which processes each role is involved in and at what level
    """
    __tablename__ = 'role_process_matrix'

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    iso_process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id'), nullable=False)
    role_process_value = db.Column(db.Integer, nullable=False, default=-100)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Relationships
    role_cluster = db.relationship('RoleCluster', backref=db.backref('role_process_matrices', cascade="all, delete-orphan", lazy=True))
    iso_process = db.relationship('IsoProcesses', backref=db.backref('role_process_matrices', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('role_process_matrices', cascade="all, delete-orphan", lazy=True))

    __table_args__ = (
        db.UniqueConstraint('organization_id', 'role_cluster_id', 'iso_process_id', name='role_process_matrix_unique'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'role_cluster_id': self.role_cluster_id,
            'iso_process_id': self.iso_process_id,
            'role_process_value': self.role_process_value,
            'organization_id': self.organization_id
        }


class ProcessCompetencyMatrix(db.Model):
    """
    Maps ISO processes to competencies
    Defines which competencies are required for each process
    """
    __tablename__ = 'process_competency_matrix'

    id = db.Column(db.Integer, primary_key=True)
    iso_process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    process_competency_value = db.Column(db.Integer, nullable=False, default=-100)

    # Relationships
    iso_process = db.relationship('IsoProcesses', backref=db.backref('competency_matrices', cascade="all, delete-orphan", lazy=True))
    competency = db.relationship('Competency', backref=db.backref('process_matrices', cascade="all, delete-orphan", lazy=True))

    __table_args__ = (
        db.UniqueConstraint('iso_process_id', 'competency_id', name='process_competency_matrix_unique'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'iso_process_id': self.iso_process_id,
            'competency_id': self.competency_id,
            'process_competency_value': self.process_competency_value
        }


class RoleCompetencyMatrix(db.Model):
    """
    Maps SE role clusters to competencies
    Defines which competencies each role requires and at what level
    Calculated from RoleProcessMatrix × ProcessCompetencyMatrix
    """
    __tablename__ = 'role_competency_matrix'

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    role_competency_value = db.Column(db.Integer, nullable=False, default=-100)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Relationships
    role_cluster = db.relationship('RoleCluster', backref=db.backref('role_competency_matrices', cascade="all, delete-orphan", lazy=True))
    competency = db.relationship('Competency', backref=db.backref('role_competency_matrices', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('role_competency_matrices', cascade="all, delete-orphan", lazy=True))

    __table_args__ = (
        db.UniqueConstraint('organization_id', 'role_cluster_id', 'competency_id', name='role_competency_matrix_unique'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'role_cluster_id': self.role_cluster_id,
            'competency_id': self.competency_id,
            'role_competency_value': self.role_competency_value,
            'organization_id': self.organization_id
        }


class UnknownRoleProcessMatrix(db.Model):
    """
    Stores process involvement for users with unknown/custom roles
    Used for task-based role identification in Phase 1
    """
    __tablename__ = 'unknown_role_process_matrix'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_name = db.Column(db.String(50), nullable=False)
    iso_process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id', ondelete='CASCADE'), nullable=False)
    role_process_value = db.Column(db.Integer, default=-100, nullable=True)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)

    # Relationships
    iso_process = db.relationship('IsoProcesses', backref=db.backref('unknown_role_process_matrix', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('unknown_role_process_matrix', cascade="all, delete-orphan", lazy=True))

    __table_args__ = (
        db.UniqueConstraint('organization_id', 'iso_process_id', 'user_name', name='unknown_role_process_matrix_unique'),
        db.CheckConstraint("role_process_value IN (-100, 0, 1, 2, 4)", name="unknown_role_process_matrix_role_process_value_check"),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'user_name': self.user_name,
            'iso_process_id': self.iso_process_id,
            'role_process_value': self.role_process_value,
            'organization_id': self.organization_id
        }


class UnknownRoleCompetencyMatrix(db.Model):
    """
    Stores competency requirements for users with unknown/custom roles
    Calculated from process involvement via stored procedure
    """
    __tablename__ = 'unknown_role_competency_matrix'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_name = db.Column(db.String(50), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    role_competency_value = db.Column(db.Integer, default=-100, nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)

    # Relationships
    competency = db.relationship('Competency', backref=db.backref('unknown_role_competency_matrix', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('unknown_role_competency_matrix', cascade="all, delete-orphan", lazy=True))

    __table_args__ = (
        db.UniqueConstraint('organization_id', 'user_name', 'competency_id', name='unknown_role_competency_matrix_unique'),
        db.CheckConstraint("role_competency_value IN (-100, 0, 1, 2, 3, 4, 6)", name="unknown_role_competency_matrix_role_competency_value_check"),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'user_name': self.user_name,
            'competency_id': self.competency_id,
            'role_competency_value': self.role_competency_value,
            'organization_id': self.organization_id
        }


# =============================================================================
# SECTION 3: USER AND AUTHENTICATION MODELS
# =============================================================================

# NOTE: AppUser model removed - consolidated into User model below
# The User model (table: 'users') is the single unified user model for SE-QPT
# It combines authentication, organization management, and role handling

class UserCompetencySurveyResult(db.Model):
    """
    Derik's survey results - EXTENDED for SE-QPT gap analysis
    Stores individual competency assessment scores with gap calculations
    """
    __tablename__ = 'user_se_competency_survey_results'

    # Derik's original fields
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'))
    score = db.Column(db.Integer, nullable=False)  # Current level (1-5)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)
    assessment_id = db.Column(db.Integer, db.ForeignKey('user_assessment.id', ondelete='CASCADE'))

    # SE-QPT gap analysis extensions (NEW COLUMNS - added via migration)
    target_level = db.Column(db.Integer)  # Target level from archetype matrix
    gap_size = db.Column(db.Integer)  # Calculated: target_level - score
    archetype_source = db.Column(db.String(100))  # Which archetype defined target

    # Relationships
    competency = db.relationship('Competency', backref='survey_results', foreign_keys=[competency_id])
    organization = db.relationship('Organization', backref='survey_results', foreign_keys=[organization_id])
    user = db.relationship('User', backref='survey_results', foreign_keys=[user_id])

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
# DERIK'S COMPETENCY ASSESSMENT MODELS (for Phase 2 integration)
# =============================================================================

# REMOVED Phase 2B: AppUser model (legacy - replaced by unified User model)


# Note: UserCompetencySurveyResults uses the existing UserCompetencySurveyResult model
# Create an alias for backward compatibility with Derik's endpoints
UserCompetencySurveyResults = UserCompetencySurveyResult


class UserRoleCluster(db.Model):
    """
    Derik's user-role mapping table
    Links users to selected role clusters
    """
    __tablename__ = 'user_role_cluster'

    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), primary_key=True, nullable=False)
    role_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), primary_key=True, nullable=False)
    assessment_id = db.Column(db.Integer, db.ForeignKey('user_assessment.id', ondelete='CASCADE'))

    # Relationships
    user = db.relationship('User', backref=db.backref('role_clusters', cascade="all, delete-orphan", lazy=True), foreign_keys=[user_id])
    role_cluster = db.relationship('RoleCluster', backref=db.backref('user_roles', cascade="all, delete-orphan", lazy=True))

    def __repr__(self):
        return f"<UserRoleCluster user_id={self.user_id}, role_cluster_id={self.role_cluster_id}>"


# REMOVED Phase 2B: UserSurveyType model (legacy - merged into UserAssessment.survey_type)


# REMOVED Phase 2B: NewSurveyUser model (legacy - replaced by UserAssessment)


class UserCompetencySurveyFeedback(db.Model):
    """
    Stores LLM-generated feedback for competency assessment surveys
    """
    __tablename__ = 'user_competency_survey_feedback'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)
    feedback = db.Column(db.JSON, nullable=False)  # Store feedback as JSON array
    assessment_id = db.Column(db.Integer, db.ForeignKey('user_assessment.id', ondelete='CASCADE'))

    def __repr__(self):
        return f"<UserCompetencySurveyFeedback user_id={self.user_id} organization_id={self.organization_id}>"


# NOTE: LearningPlan model removed - not yet implemented
# Future learning plan features will be added when implemented


class UserAssessment(db.Model):
    """
    Tracks individual competency assessments for authenticated users
    Replaces the anonymous survey system (NewSurveyUser, AppUser)
    Links assessments to real User accounts for history and aggregation
    """
    __tablename__ = 'user_assessment'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Assessment type and survey mode
    assessment_type = db.Column(db.String(50), nullable=False)  # 'role_based', 'task_based', 'full_competency'
    survey_type = db.Column(db.String(50))  # 'known_roles', 'unknown_roles', 'all_roles'

    # Assessment data
    tasks_responsibilities = db.Column(db.JSON)  # Task descriptions for task-based assessments
    selected_roles = db.Column(db.JSON)  # Array of selected role IDs for role-based assessments

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)

    # Relationships
    user = db.relationship('User', backref='assessments_history', foreign_keys=[user_id])
    organization = db.relationship('Organization', backref='user_assessments', foreign_keys=[organization_id])

    def to_dict(self):
        """Convert assessment to dictionary for API responses"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'assessment_type': self.assessment_type,
            'survey_type': self.survey_type,
            'tasks_responsibilities': self.tasks_responsibilities,
            'selected_roles': self.selected_roles,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'status': 'completed' if self.completed_at else 'in_progress'
        }

    def __repr__(self):
        return f"<UserAssessment id={self.id} user_id={self.user_id} type={self.assessment_type} status={'completed' if self.completed_at else 'in_progress'}>"


class PhaseQuestionnaireResponse(db.Model):
    """
    Store simplified questionnaire responses for SE-QPT phases
    Simpler than the full Questionnaire system - just stores JSON responses
    """
    __tablename__ = 'phase_questionnaire_responses'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
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
    user = db.relationship('User', backref='questionnaire_responses', foreign_keys=[user_id])
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
# SECTION 2: UNIFIED USER MANAGEMENT
# Merges MVPUser + User into single comprehensive model
# =============================================================================

class User(db.Model):
    """
    Unified user model for all platform access
    Combines best features from MVPUser and original User model
    """
    __tablename__ = 'users'

    # Primary identification
    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)

    # User profile
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))

    # Organization relationship (supports both FK and string for flexibility)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'))  # Proper FK relationship
    organization = db.Column(db.String(200))  # Fallback/legacy string field
    joined_via_code = db.Column(db.String(32))  # Organization code used to join (16-char hex codes)

    # Role and permissions (flexible system supporting both patterns)
    role = db.Column(db.String(100))  # Flexible role field (e.g., 'admin', 'employee', custom roles)
    user_type = db.Column(db.String(20), default='participant')  # participant, admin, assessor, employee

    # Status flags
    is_active = db.Column(db.Boolean, default=True)
    is_verified = db.Column(db.Boolean, default=False)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    # Relationships removed: Assessment, LearningObjective, ModuleEnrollment models deleted in Phase 2A cleanup

    def set_password(self, password):
        """Hash and set user password"""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Verify password against stored hash"""
        return check_password_hash(self.password_hash, password)

    @property
    def full_name(self):
        """Get user's full name or fallback to username"""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.username

    @property
    def is_admin(self):
        """Check if user has admin privileges"""
        return self.role == 'admin' or self.user_type == 'admin'

    @property
    def is_employee(self):
        """Check if user is an employee"""
        return self.role == 'employee' or self.user_type == 'employee'

    @property
    def is_participant(self):
        """Check if user is a participant"""
        return self.user_type == 'participant'

    @property
    def is_assessor(self):
        """Check if user is an assessor"""
        return self.user_type == 'assessor'

    def to_dict(self):
        """Convert user to dictionary representation"""
        return {
            'id': self.id,
            'uuid': self.uuid,
            'username': self.username,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.full_name,
            'organization_id': self.organization_id,
            'joined_via_code': self.joined_via_code,
            'role': self.role,
            'user_type': self.user_type,
            'is_active': self.is_active,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None
        }


# =============================================================================
# SECTION 3: SE-QPT CORE MODELS
# =============================================================================

# =============================================================================
# SECTION 5: ASSESSMENT MODELS
# =============================================================================

# =============================================================================
# SECTION 6: RAG-LLM MODELS
# =============================================================================

# =============================================================================
# SECTION 7: QUESTIONNAIRE SYSTEM MODELS
# =============================================================================

# =============================================================================
# SECTION 8: LEARNING MODULE SYSTEM MODELS
# =============================================================================

# =============================================================================
# BACKWARD COMPATIBILITY ALIASES
# =============================================================================

# Alias for existing code that references SECompetency
SECompetency = Competency

# Alias for existing code that references SERole
SERole = RoleCluster

# Alias for existing code that references CompetencyAssessment
CompetencyAssessment = UserCompetencySurveyResult


# =============================================================================
# HELPER FUNCTIONS (from unified_models.py)
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

    total_users = User.query.filter_by(organization_id=organization_id).count()

    # Count users with completed assessments
    users_with_assessments = db.session.query(
        db.func.count(db.func.distinct(UserCompetencySurveyResult.user_id))
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


# =============================================================================
# MVP BUSINESS LOGIC FUNCTIONS (from mvp_models.py)
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


# Compatibility wrapper for role mapping (from mvp_models.py)
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
