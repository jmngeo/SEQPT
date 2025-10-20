"""
Unified database models integrating Derik's competency assessor with SE-QPT
Extends Derik's proven models with SE qualification planning capabilities
"""

from app import db
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSONB

# ===== DERIK'S ORIGINAL MODELS (PRESERVED) =====

class RoleCluster(db.Model):
    """Derik's original role model - preserved for compatibility"""
    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False, unique=True)
    role_cluster_description = db.Column(db.Text, nullable=False)

class Competency(db.Model):
    """Derik's original competency model - preserved for compatibility"""
    id = db.Column(db.Integer, primary_key=True)
    competency_area = db.Column(db.String(50), nullable=False)  # Core, Technical, Professional, Managerial
    competency_name = db.Column(db.String(255), nullable=False, unique=True)
    description = db.Column(db.Text, nullable=False)
    why_it_matters = db.Column(db.Text, nullable=False)

class CompetencyIndicator(db.Model):
    """Derik's original indicator model - preserved for compatibility"""
    __tablename__ = 'competency_indicators'
    id = db.Column(db.Integer, primary_key=True)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=True)
    level = db.Column(db.String(50), nullable=True)  # 'verstehen', 'beherrschen', 'kennen', 'anwenden'
    indicator_en = db.Column(db.Text, nullable=True)
    indicator_de = db.Column(db.Text, nullable=True)
    competency = db.relationship('Competency', backref=db.backref('indicators', cascade="all, delete-orphan", lazy=True))

# ===== SE-QPT EXTENSIONS =====

class QualificationArchetype(db.Model):
    """SE-QPT: 6 qualification archetypes from Marcel's methodology"""
    __tablename__ = 'qualification_archetypes'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False, unique=True)  # e.g., "Common basic understanding"
    description = db.Column(db.Text, nullable=False)
    target_competency_levels = db.Column(JSONB)  # Competency-level mappings
    learning_formats = db.Column(JSONB)  # Preferred learning formats
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class LearningObjective(db.Model):
    """SE-QPT: RAG-generated learning objectives"""
    __tablename__ = 'learning_objectives'
    id = db.Column(db.Integer, primary_key=True)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    role_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    archetype_id = db.Column(db.Integer, db.ForeignKey('qualification_archetypes.id'), nullable=False)

    # Learning objective details
    objective_text = db.Column(db.Text, nullable=False)
    bloom_level = db.Column(db.String(50))  # Know, Understand, Apply, Master
    competency_level = db.Column(db.Integer)  # 1, 2, 4, 6 scale

    # RAG metadata
    generated_by_llm = db.Column(db.Boolean, default=True)
    source_context = db.Column(db.Text)  # Company-specific context used
    quality_score = db.Column(db.Float)  # RAG quality assessment

    # Learning format recommendations
    recommended_formats = db.Column(JSONB)  # ["seminars", "coaching", etc.]
    estimated_duration = db.Column(db.String(50))  # "2 days", "4 hours", etc.

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    competency = db.relationship('Competency', backref='learning_objectives')
    role = db.relationship('RoleCluster', backref='learning_objectives')
    archetype = db.relationship('QualificationArchetype', backref='learning_objectives')

class QualificationPlan(db.Model):
    """SE-QPT: Individual qualification plans"""
    __tablename__ = 'qualification_plans'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)  # Links to user system
    role_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    archetype_id = db.Column(db.Integer, db.ForeignKey('qualification_archetypes.id'), nullable=False)

    # Plan details
    plan_name = db.Column(db.String(255), nullable=False)
    target_competency_gaps = db.Column(JSONB)  # Identified gaps from assessment
    learning_objectives = db.Column(JSONB)  # Selected learning objectives

    # Company-specific context
    company_context = db.Column(db.Text)  # Used for RAG generation
    industry_domain = db.Column(db.String(100))

    # Plan status
    status = db.Column(db.String(50), default='draft')  # draft, active, completed
    progress = db.Column(db.Float, default=0.0)  # 0.0 to 1.0

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    role = db.relationship('RoleCluster', backref='qualification_plans')
    archetype = db.relationship('QualificationArchetype', backref='qualification_plans')

class RoleCompetencyMatrix(db.Model):
    """SE-QPT: 14×16 role-competency mapping matrix"""
    __tablename__ = 'role_competency_matrix'
    id = db.Column(db.Integer, primary_key=True)
    role_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    required_level = db.Column(db.Integer, nullable=False)  # 0, 1, 2, 4, 6 scale

    # Matrix metadata
    source = db.Column(db.String(100), default='SE-QPT Excel foundation')
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    role = db.relationship('RoleCluster')
    competency = db.relationship('Competency')

    # Unique constraint
    __table_args__ = (db.UniqueConstraint('role_id', 'competency_id', name='_role_competency_uc'),)

class CompanyContext(db.Model):
    """SE-QPT: Company-specific context for RAG generation"""
    __tablename__ = 'company_contexts'
    id = db.Column(db.Integer, primary_key=True)
    company_name = db.Column(db.String(255), nullable=False)
    industry = db.Column(db.String(100))

    # Context data for RAG
    business_domain = db.Column(db.Text)
    products_services = db.Column(db.Text)
    se_maturity_level = db.Column(db.String(50))
    specific_challenges = db.Column(db.Text)

    # Document embeddings for RAG
    context_embeddings = db.Column(JSONB)  # Stored vector embeddings

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# ===== PRESERVE DERIK'S EXISTING MODELS =====
# Include all other Derik models for backward compatibility

class IsoSystemLifeCycleProcesses(db.Model):
    """Derik's ISO process model - preserved"""
    __tablename__ = 'iso_system_life_cycle_processes'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    processes = db.relationship('IsoProcesses', backref='life_cycle_process', lazy=True)

class IsoProcesses(db.Model):
    """Derik's ISO process model - preserved"""
    __tablename__ = 'iso_processes'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    life_cycle_process_id = db.Column(db.Integer, db.ForeignKey('iso_system_life_cycle_processes.id'))
    activities = db.relationship('IsoActivities', backref='process', lazy=True)

class IsoActivities(db.Model):
    """Derik's ISO activities model - preserved"""
    __tablename__ = 'iso_activities'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id'))

# Add remaining Derik models as needed for full compatibility...