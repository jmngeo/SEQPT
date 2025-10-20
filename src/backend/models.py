"""
SE-QPT Unified Database Models
Combines Marcel's methodology, Derik's competency assessment, and RAG-LLM innovations
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import json

# Initialize db - will be initialized by app factory
db = SQLAlchemy()

# =============================================================================
# UNIFIED MODELS INTEGRATION (Derik's System)
# Import Derik's competency and role models instead of duplicating
# =============================================================================
try:
    from unified_models import Competency as SECompetency, RoleCluster as SERole
    UNIFIED_MODELS_AVAILABLE = True
except ImportError:
    # Fallback: Define minimal placeholder classes if unified_models not available
    UNIFIED_MODELS_AVAILABLE = False
    class SECompetency:
        """Placeholder - use unified_models.Competency"""
        pass
    class SERole:
        """Placeholder - use unified_models.RoleCluster"""
        pass

# User Management Models
class User(db.Model):
    """Unified user model for all platform access"""
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)

    # User profile
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    organization = db.Column(db.String(200))
    role = db.Column(db.String(100))

    # User type and permissions
    user_type = db.Column(db.String(20), default='participant')  # participant, admin, assessor
    is_active = db.Column(db.Boolean, default=True)
    is_verified = db.Column(db.Boolean, default=False)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

    # Relationships
    assessments = db.relationship('Assessment', backref='user', lazy=True)
    qualification_plans = db.relationship('QualificationPlan', backref='user', lazy=True)
    learning_objectives = db.relationship('LearningObjective', backref='user', lazy=True, foreign_keys='LearningObjective.user_id')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @property
    def full_name(self):
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.username

    def to_dict(self):
        return {
            'id': self.id,
            'uuid': self.uuid,
            'username': self.username,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'organization': self.organization,
            'role': self.role,
            'user_type': self.user_type,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

# SE-QPT Core Models (Marcel's Framework)
class QualificationArchetype(db.Model):
    """6 qualification archetype strategies from Marcel's research"""
    __tablename__ = 'qualification_archetypes'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False, unique=True)
    description = db.Column(db.Text)
    typical_duration = db.Column(db.String(50))
    learning_format = db.Column(db.String(100))
    target_audience = db.Column(db.String(200))
    focus_area = db.Column(db.String(100))
    delivery_method = db.Column(db.String(100))
    strategy = db.Column(db.String(100))

    # Metadata
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# =============================================================================
# REMOVED DUPLICATE CLASSES - Now using Derik's unified models
# =============================================================================
# class SECompetency - DELETED: Use unified_models.Competency (Derik's 16 competencies)
# class SERole - DELETED: Use unified_models.RoleCluster (Derik's 16 role clusters)
# =============================================================================

# Assessment Models
class Assessment(db.Model):
    """Unified assessment model"""
    __tablename__ = 'assessments'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # Assessment details
    phase = db.Column(db.Integer)
    assessment_type = db.Column(db.String(50))
    title = db.Column(db.String(200))
    description = db.Column(db.Text)

    # Status and scoring
    status = db.Column(db.String(20), default='in_progress')
    score = db.Column(db.Float)
    max_score = db.Column(db.Float, default=100.0)
    completion_time_minutes = db.Column(db.Integer)

    # Results
    results = db.Column(db.Text)  # JSON string
    selected_archetype_id = db.Column(db.Integer, db.ForeignKey('qualification_archetypes.id'))

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)

    # Relationships
    selected_archetype = db.relationship('QualificationArchetype', backref='assessments')
    competency_results = db.relationship('CompetencyAssessmentResult', backref='assessment', lazy=True)

class CompetencyAssessmentResult(db.Model):
    """Individual competency assessment results"""
    __tablename__ = 'competency_assessment_results'

    id = db.Column(db.Integer, primary_key=True)
    assessment_id = db.Column(db.Integer, db.ForeignKey('assessments.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('se_competencies.id'), nullable=False)

    # Assessment scores
    current_level = db.Column(db.Integer)
    target_level = db.Column(db.Integer)
    score = db.Column(db.Float)
    confidence_score = db.Column(db.Float)

    # Analysis
    gap_analysis = db.Column(db.Text)  # JSON string
    recommendations = db.Column(db.Text)  # JSON string

    # Relationships
    competency = db.relationship('Competency', backref='assessment_results')

    @property
    def gap_size(self):
        if self.target_level and self.current_level:
            return max(0, self.target_level - self.current_level)
        return 0

# RAG-LLM Models
class CompanyContext(db.Model):
    """Company context for RAG generation"""
    __tablename__ = 'company_contexts'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200))
    industry = db.Column(db.String(100))
    size = db.Column(db.String(50))
    domain = db.Column(db.String(100))

    # PMT Framework
    processes = db.Column(db.Text)  # JSON string
    methods = db.Column(db.Text)    # JSON string
    tools = db.Column(db.Text)      # JSON string
    standards = db.Column(db.Text)  # JSON string
    project_types = db.Column(db.Text)  # JSON string

    # Organizational context
    organizational_structure = db.Column(db.Text)  # JSON string
    quality_score = db.Column(db.Float)
    extraction_metadata = db.Column(db.Text)  # JSON string

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class LearningObjective(db.Model):
    """RAG-generated learning objectives"""
    __tablename__ = 'learning_objectives'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    competency_id = db.Column(db.Integer, db.ForeignKey('se_competencies.id'), nullable=False)

    # Objective content
    text = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), default='rag_generated')
    priority = db.Column(db.String(20), default='medium')

    # Quality metrics
    smart_score = db.Column(db.Float)
    smart_analysis = db.Column(db.Text)  # JSON string
    context_relevance = db.Column(db.Float)
    validation_status = db.Column(db.String(20), default='pending')

    # RAG metadata
    rag_sources = db.Column(db.Text)  # JSON string
    generation_metadata = db.Column(db.Text)  # JSON string

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    competency = db.relationship('Competency', backref='learning_objectives')

class QualificationPlan(db.Model):
    """Qualification plans from 4-phase process"""
    __tablename__ = 'qualification_plans'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # Plan details
    name = db.Column(db.String(200))
    description = db.Column(db.Text)
    target_role = db.Column(db.String(100))
    archetype_id = db.Column(db.Integer, db.ForeignKey('qualification_archetypes.id'))

    # Plan content
    estimated_duration_weeks = db.Column(db.Integer)
    modules = db.Column(db.Text)  # JSON string
    learning_path = db.Column(db.Text)  # JSON string
    progress_tracking = db.Column(db.Text)  # JSON string

    # Status
    status = db.Column(db.String(20), default='draft')

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    archetype = db.relationship('QualificationArchetype', backref='qualification_plans')

# RAG Template Model
class RAGTemplate(db.Model):
    """Templates for RAG objective generation"""
    __tablename__ = 'rag_templates'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    category = db.Column(db.String(50))
    competency_focus = db.Column(db.String(100))
    industry_context = db.Column(db.String(100))

    # Template content
    template_text = db.Column(db.Text, nullable=False)
    variables = db.Column(db.Text)  # JSON string
    success_criteria = db.Column(db.Text)  # JSON string

    # Usage tracking
    usage_count = db.Column(db.Integer, default=0)
    average_quality_score = db.Column(db.Float, default=0.0)
    template_metadata = db.Column(db.Text)  # JSON string

    # Status
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Questionnaire System Models
class Questionnaire(db.Model):
    """SE-QPT Questionnaire definitions"""
    __tablename__ = 'questionnaires'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    title = db.Column(db.String(500))
    description = db.Column(db.Text)
    questionnaire_type = db.Column(db.String(50))  # maturity, archetype, competency, etc.
    phase = db.Column(db.Integer)  # SE-QPT phase (1-4)

    # Configuration
    is_active = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)
    estimated_duration_minutes = db.Column(db.Integer)

    # Metadata
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    questions = db.relationship('Question', backref='questionnaire', lazy=True, cascade='all, delete-orphan')

class Question(db.Model):
    """Individual questions within questionnaires"""
    __tablename__ = 'questions'

    id = db.Column(db.Integer, primary_key=True)
    questionnaire_id = db.Column(db.Integer, db.ForeignKey('questionnaires.id'), nullable=False)

    # Question content
    question_number = db.Column(db.String(10))  # Q1, Q2, etc.
    question_text = db.Column(db.Text, nullable=False)
    question_type = db.Column(db.String(20))  # multiple_choice, text, rating, etc.
    section = db.Column(db.String(100))  # Section name if applicable

    # Weighting and scoring
    weight = db.Column(db.Float, default=1.0)
    max_score = db.Column(db.Float, default=5.0)
    scoring_method = db.Column(db.String(50))  # linear, weighted, custom

    # Configuration
    is_required = db.Column(db.Boolean, default=True)
    sort_order = db.Column(db.Integer, default=0)

    # Question metadata
    help_text = db.Column(db.Text)
    validation_rules = db.Column(db.Text)  # JSON string

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    options = db.relationship('QuestionOption', backref='question', lazy=True, cascade='all, delete-orphan')
    responses = db.relationship('QuestionResponse', backref='question', lazy=True)

class QuestionOption(db.Model):
    """Answer options for multiple choice questions"""
    __tablename__ = 'question_options'

    id = db.Column(db.Integer, primary_key=True)
    question_id = db.Column(db.Integer, db.ForeignKey('questions.id'), nullable=False)

    # Option content
    option_text = db.Column(db.Text, nullable=False)
    option_value = db.Column(db.String(10))  # e.g., "A", "1", "true"
    score_value = db.Column(db.Float, default=0.0)

    # Configuration
    sort_order = db.Column(db.Integer, default=0)
    is_correct = db.Column(db.Boolean, default=False)

    # Metadata
    additional_data = db.Column(db.Text)  # JSON string for any extra data

class QuestionnaireResponse(db.Model):
    """User responses to complete questionnaires"""
    __tablename__ = 'questionnaire_responses'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    questionnaire_id = db.Column(db.Integer, db.ForeignKey('questionnaires.id'), nullable=False)

    # Response status
    status = db.Column(db.String(20), default='in_progress')  # in_progress, completed, abandoned
    completion_percentage = db.Column(db.Float, default=0.0)

    # Scoring results
    total_score = db.Column(db.Float)
    max_possible_score = db.Column(db.Float)
    score_percentage = db.Column(db.Float)
    section_scores = db.Column(db.Text)  # JSON string with section breakdowns

    # Analysis results
    results_summary = db.Column(db.Text)  # JSON string
    recommendations = db.Column(db.Text)  # JSON string
    computed_archetype = db.Column(db.Text)  # JSON string for SE-QPT computed archetype

    # Timing
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    duration_minutes = db.Column(db.Integer)

    # Relationships
    questionnaire = db.relationship('Questionnaire', backref='responses', lazy=True)
    question_responses = db.relationship('QuestionResponse', backref='questionnaire_response', lazy=True)

class QuestionResponse(db.Model):
    """Individual question responses"""
    __tablename__ = 'question_responses'

    id = db.Column(db.Integer, primary_key=True)
    questionnaire_response_id = db.Column(db.Integer, db.ForeignKey('questionnaire_responses.id'), nullable=False)
    question_id = db.Column(db.Integer, db.ForeignKey('questions.id'), nullable=False)

    # Response data
    response_value = db.Column(db.Text)  # Can store text, numbers, JSON for complex responses
    selected_option_id = db.Column(db.Integer, db.ForeignKey('question_options.id'))
    score = db.Column(db.Float)

    # Response metadata
    confidence_level = db.Column(db.Integer)  # 1-5 scale
    time_spent_seconds = db.Column(db.Integer)
    revision_count = db.Column(db.Integer, default=0)

    # Timestamps
    responded_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_modified_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    selected_option = db.relationship('QuestionOption')

# Learning Module System Models
class LearningModule(db.Model):
    """SE Competency Learning Modules"""
    __tablename__ = 'learning_modules'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))

    # Module identification
    module_code = db.Column(db.String(10), unique=True, nullable=False)  # e.g., C01, P01, S01, M01
    name = db.Column(db.String(200), nullable=False)
    category = db.Column(db.String(50), nullable=False)  # Core, Professional, Social, Management
    competency_id = db.Column(db.Integer, db.ForeignKey('se_competencies.id'))

    # Module content
    definition = db.Column(db.Text)
    overview = db.Column(db.Text)
    industry_relevance = db.Column(db.Text)

    # Level-based structure (JSON for each level)
    level_1_content = db.Column(db.Text)  # JSON: {hours, objectives, topics, assessments}
    level_2_content = db.Column(db.Text)  # JSON
    level_3_4_content = db.Column(db.Text)  # JSON
    level_5_6_content = db.Column(db.Text)  # JSON

    # Prerequisites and dependencies
    prerequisites = db.Column(db.Text)  # JSON array of prerequisite module codes
    dependencies = db.Column(db.Text)  # JSON array of dependent modules

    # Industry adaptations
    industry_adaptations = db.Column(db.Text)  # JSON object with industry-specific content

    # Module metadata
    total_duration_hours = db.Column(db.Integer)
    difficulty_level = db.Column(db.String(20), default='beginner')  # beginner, intermediate, advanced, expert
    version = db.Column(db.String(10), default='1.0')

    # Status and tracking
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    competency = db.relationship('Competency', backref='modules')

class LearningPath(db.Model):
    """Recommended learning paths for different roles/industries"""
    __tablename__ = 'learning_paths'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))

    # Path identification
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    path_type = db.Column(db.String(50))  # role_based, industry_based, level_based
    target_audience = db.Column(db.String(200))

    # Path content
    module_sequence = db.Column(db.Text)  # JSON array of module codes in order
    estimated_duration_weeks = db.Column(db.Integer)
    difficulty_progression = db.Column(db.Text)  # JSON showing level progression

    # Industry/role specifics
    industry_focus = db.Column(db.String(100))
    role_focus = db.Column(db.String(100))
    experience_level = db.Column(db.String(50))  # entry, junior, mid, senior, expert

    # Success criteria
    completion_criteria = db.Column(db.Text)  # JSON defining completion requirements
    assessment_strategy = db.Column(db.Text)  # JSON describing assessment approach

    # Metadata
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class ModuleEnrollment(db.Model):
    """User enrollment in learning modules"""
    __tablename__ = 'module_enrollments'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    module_id = db.Column(db.Integer, db.ForeignKey('learning_modules.id'), nullable=False)

    # Enrollment details
    target_level = db.Column(db.Integer, default=1)  # 1-6 proficiency level target
    current_level = db.Column(db.Integer, default=0)  # Current achieved level

    # Progress tracking
    status = db.Column(db.String(20), default='enrolled')  # enrolled, in_progress, completed, paused
    progress_percentage = db.Column(db.Float, default=0.0)
    time_spent_hours = db.Column(db.Float, default=0.0)

    # Learning analytics
    learning_style_preference = db.Column(db.String(50))
    engagement_score = db.Column(db.Float)
    completion_quality = db.Column(db.Float)

    # Timestamps
    enrolled_at = db.Column(db.DateTime, default=datetime.utcnow)
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    last_accessed_at = db.Column(db.DateTime)

    # Relationships
    user = db.relationship('User', backref='module_enrollments')
    module = db.relationship('LearningModule', backref='enrollments')

class ModuleAssessment(db.Model):
    """Assessment results for learning modules"""
    __tablename__ = 'module_assessments'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    enrollment_id = db.Column(db.Integer, db.ForeignKey('module_enrollments.id'), nullable=False)

    # Assessment details
    assessment_type = db.Column(db.String(50))  # knowledge_check, practical, portfolio, capstone
    level_assessed = db.Column(db.Integer)  # 1-6 proficiency level

    # Results
    score = db.Column(db.Float)
    max_score = db.Column(db.Float)
    pass_threshold = db.Column(db.Float, default=70.0)
    passed = db.Column(db.Boolean, default=False)

    # Assessment content
    questions_data = db.Column(db.Text)  # JSON with assessment questions/tasks
    responses_data = db.Column(db.Text)  # JSON with user responses
    feedback = db.Column(db.Text)

    # Analytics
    time_taken_minutes = db.Column(db.Integer)
    attempt_number = db.Column(db.Integer, default=1)
    competency_demonstration = db.Column(db.Text)  # JSON showing competency evidence

    # Timestamps
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)

    # Relationships
    enrollment = db.relationship('ModuleEnrollment', backref='assessments')

class LearningResource(db.Model):
    """Learning resources associated with modules"""
    __tablename__ = 'learning_resources'

    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String(36), unique=True, default=lambda: str(uuid.uuid4()))
    module_id = db.Column(db.Integer, db.ForeignKey('learning_modules.id'), nullable=False)

    # Resource details
    title = db.Column(db.String(300), nullable=False)
    resource_type = db.Column(db.String(50))  # video, document, simulation, tool, reference
    format = db.Column(db.String(20))  # pdf, mp4, html, interactive, external

    # Content
    description = db.Column(db.Text)
    url = db.Column(db.String(500))
    file_path = db.Column(db.String(500))
    content_data = db.Column(db.Text)  # JSON with structured content

    # Level and prerequisites
    target_levels = db.Column(db.String(20))  # e.g., "1,2" or "3-4" or "5-6"
    prerequisites = db.Column(db.Text)  # JSON array of prerequisite topics

    # Quality and usage metrics
    difficulty_rating = db.Column(db.Float)
    quality_rating = db.Column(db.Float)
    usage_count = db.Column(db.Integer, default=0)
    average_completion_time = db.Column(db.Integer)  # minutes

    # Metadata
    author = db.Column(db.String(200))
    source = db.Column(db.String(200))
    language = db.Column(db.String(10), default='en')
    last_updated = db.Column(db.DateTime)
    is_active = db.Column(db.Boolean, default=True)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    module = db.relationship('LearningModule', backref='resources')