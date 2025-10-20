"""
Unified SE-QPT + Derik Models
Simply imports Derik's models and adds SE-QPT specific extensions
Author: Integration Team
Date: 2025-10-02
"""

from datetime import datetime
import uuid
import json
from werkzeug.security import generate_password_hash, check_password_hash

# Import db from Derik's app
from app import db

# Import ALL Derik's existing models (don't redefine them!)
from app.models import (
    Organization,
    Competency,
    RoleCluster
)

# Import AppUser if it exists, otherwise we'll use a simpler approach
try:
    from app.models import AppUser
except ImportError:
    # AppUser might be defined elsewhere or not at all
    pass

# SE-QPT specific tables only
class LearningPlan(db.Model):
    """SE-QPT Learning Plan with SMART objectives"""
    __tablename__ = 'learning_plans'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, nullable=False)
    organization_id = db.Column(db.Integer)

    # JSON storage for flexibility
    objectives = db.Column(db.Text, nullable=False)
    recommended_modules = db.Column(db.Text)
    estimated_duration_weeks = db.Column(db.Integer)
    archetype_used = db.Column(db.String(100))

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'objectives': json.loads(self.objectives) if self.objectives else [],
            'recommended_modules': json.loads(self.recommended_modules) if self.recommended_modules else [],
            'estimated_duration_weeks': self.estimated_duration_weeks,
            'archetype_used': self.archetype_used,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class PhaseQuestionnaireResponse(db.Model):
    """Questionnaire responses for all 4 phases"""
    __tablename__ = 'questionnaire_responses'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, nullable=False)
    organization_id = db.Column(db.Integer)
    phase = db.Column(db.Integer, nullable=False)

    responses = db.Column(db.Text, nullable=False)
    completed_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'organization_id': self.organization_id,
            'phase': self.phase,
            'responses': json.loads(self.responses) if self.responses else {},
            'completed_at': self.completed_at.isoformat() if self.completed_at else None
        }


# Alias classes for backward compatibility
UserCompetencySurveyResult = None  # Will be imported from app.models if needed
AppUser = None  # Will be imported from app.models if needed
