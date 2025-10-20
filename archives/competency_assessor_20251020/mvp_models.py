"""
SE-QPT MVP Database Models
Uses Derik's models directly + helper functions
Date: 2025-10-02
"""

from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid
import json
import hashlib
import time

# Import db from Derik's app
from app import db

# Import Derik's models directly
from app.models import Organization, Competency, RoleCluster, AdminUser, AppUser

# Import SE-QPT specific tables from unified_models
from unified_models import LearningPlan, PhaseQuestionnaireResponse

# =============================================================================
# HELPER FUNCTIONS FOR ORGANIZATION
# =============================================================================

def generate_organization_key(org_name):
    """Generate unique organization public key"""
    base = f"{org_name}_{int(time.time() * 1000)}"
    hash_key = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

    # Check uniqueness
    while Organization.query.filter_by(organization_public_key=hash_key).first():
        base = f"{org_name}_{int(time.time() * 1000)}_{uuid.uuid4().hex[:4]}"
        hash_key = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

    return hash_key


# Monkeypatch the Organization class to add SE-QPT methods
Organization.generate_public_key = staticmethod(generate_organization_key)


# =============================================================================
# USE DERIK'S EXISTING MODELS - NO NEW USER TABLE
# =============================================================================

# Extend AdminUser with helper methods
def admin_set_password(self, password):
    self.password_hash = generate_password_hash(password)

def admin_check_password(self, password):
    return check_password_hash(self.password_hash, password)

def admin_to_dict(self):
    return {
        'id': self.id,
        'username': self.username,
        'created_at': self.created_at.isoformat() if self.created_at else None
    }

AdminUser.set_password = admin_set_password
AdminUser.check_password = admin_check_password
AdminUser.to_dict = admin_to_dict

# Create an alias for compatibility
MVPUser = AdminUser


# =============================================================================
# MATURITY ASSESSMENT MODEL
# =============================================================================

class MaturityAssessment(db.Model):
    """Phase 1: Maturity Assessment"""
    __tablename__ = 'maturity_assessments'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)
    user_id = db.Column(db.Integer, nullable=False)

    # Assessment results
    scope_score = db.Column(db.Float)
    process_score = db.Column(db.Float)
    overall_maturity = db.Column(db.String(50))

    # JSON storage
    responses = db.Column(db.Text)  # JSON array of question responses

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'organization_id': self.organization_id,
            'user_id': self.user_id,
            'scope_score': self.scope_score,
            'process_score': self.process_score,
            'overall_maturity': self.overall_maturity,
            'responses': json.loads(self.responses) if self.responses else [],
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


# =============================================================================
# COMPETENCY ASSESSMENT (Alias to Derik's table)
# =============================================================================

class CompetencyAssessment(db.Model):
    """Phase 2: Competency Assessment - extends Derik's survey results"""
    __tablename__ = 'user_se_competency_survey_results'
    __table_args__ = {'extend_existing': True}

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'))
    score = db.Column(db.Integer, nullable=False)  # Current level

    # SE-QPT extensions for gap analysis
    target_level = db.Column(db.Integer)
    gap_size = db.Column(db.Integer)
    archetype_source = db.Column(db.String(100))
    learning_plan_id = db.Column(db.String(36))

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'competency_id': self.competency_id,
            'current_level': self.score,
            'target_level': self.target_level,
            'gap_size': self.gap_size,
            'archetype_source': self.archetype_source
        }


# =============================================================================
# PLACEHOLDER CLASSES
# =============================================================================

class RoleMapping:
    """Placeholder for role mapping functionality"""
    @staticmethod
    def query_by_user(user_id):
        return None


# =============================================================================
# BUSINESS LOGIC FUNCTIONS
# =============================================================================

def calculate_maturity_score(responses):
    """Calculate maturity score from questionnaire responses"""
    # Placeholder - implement based on questionnaire structure
    return {'scope_score': 3.0, 'process_score': 3.5, 'overall_maturity': 'Developing'}


def select_archetype(maturity_result):
    """Select archetype based on maturity assessment"""
    # Placeholder - implement based on archetype selection logic
    return "Common Basic Understanding"


def generate_learning_plan_templates(user_id, archetype):
    """Generate learning plan templates"""
    # Placeholder
    return []


def generate_basic_modules(competencies_with_gaps):
    """Generate basic module recommendations"""
    # Placeholder
    return []
