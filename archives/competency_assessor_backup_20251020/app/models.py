from app import db
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSONB


class RoleCluster(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False, unique=True)
    role_cluster_description = db.Column(db.Text, nullable=False)

# Competency model
class Competency(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    competency_area = db.Column(db.String(50), nullable=False)  # Core, Technical, etc.
    competency_name = db.Column(db.String(255), nullable=False, unique=True)
    description = db.Column(db.Text, nullable=False)
    why_it_matters = db.Column(db.Text, nullable=False)

# Competency Indicator model
class CompetencyIndicator(db.Model):
    __tablename__ = 'competency_indicators'
    id = db.Column(db.Integer, primary_key=True)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=True)
    level = db.Column(db.String(50), nullable=True)  # Now can hold 'verstehen', 'beherrschen', 'kennen', 'anwenden'
    indicator_en = db.Column(db.Text, nullable=True)  # English indicator text
    indicator_de = db.Column(db.Text, nullable=True)  # German indicator text

    # Relationship to Competency
    competency = db.relationship('Competency', backref=db.backref('indicators', cascade="all, delete-orphan", lazy=True))


class IsoSystemLifeCycleProcesses(db.Model):
    __tablename__ = 'iso_system_life_cycle_processes'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    
    # Relationship to IsoProcesses (One-to-Many)
    processes = db.relationship('IsoProcesses', backref='life_cycle_process', lazy=True)

class IsoProcesses(db.Model):
    __tablename__ = 'iso_processes'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    life_cycle_process_id = db.Column(db.Integer, db.ForeignKey('iso_system_life_cycle_processes.id'))

    # Relationship to IsoActivities (One-to-Many)
    activities = db.relationship('IsoActivities', backref='process', lazy=True)

class IsoActivities(db.Model):
    __tablename__ = 'iso_activities'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id'))

    # Relationship to IsoTasks (One-to-Many)
    tasks = db.relationship('IsoTasks', backref='activity', lazy=True)

class IsoTasks(db.Model):
    __tablename__ = 'iso_tasks'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    activity_id = db.Column(db.Integer, db.ForeignKey('iso_activities.id'))


# RoleProcessMatrix model for Role-Process Mapping
class RoleProcessMatrix(db.Model):
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

    # Unique constraint including organization_id, role_cluster_id, and iso_process_id
    __table_args__ = (
        db.UniqueConstraint('organization_id', 'role_cluster_id', 'iso_process_id', name='role_process_matrix_unique'),
    )

    def __repr__(self):
        return f"<RoleProcessMatrix organization_id={self.organization_id}, role_cluster_id={self.role_cluster_id}, iso_process_id={self.iso_process_id}, role_process_value={self.role_process_value}>"

# Process Competency Matrix for Process-Competency mapping
class ProcessCompetencyMatrix(db.Model):
    __tablename__ = 'process_competency_matrix'

    id = db.Column(db.Integer, primary_key=True)
    iso_process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    process_competency_value = db.Column(db.Integer, nullable=False, default=-100)  # Updated field name

    # Relationships to linked tables
    iso_process = db.relationship('IsoProcesses', backref=db.backref('competency_matrices', cascade="all, delete-orphan", lazy=True))
    competency = db.relationship('Competency', backref=db.backref('process_matrices', cascade="all, delete-orphan", lazy=True))

    # Constraints
    __table_args__ = (
        db.UniqueConstraint('iso_process_id', 'competency_id', name='process_competency_matrix_unique'),
    )

    def __repr__(self):
        return f"<ProcessCompetencyMatrix iso_process_id={self.iso_process_id}, competency_id={self.competency_id}, process_competency_value={self.process_competency_value}>"

# Role-Competency Matrix model
class RoleCompetencyMatrix(db.Model):
    __tablename__ = 'role_competency_matrix'

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    role_competency_value = db.Column(db.Integer, default=-100, nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)

    # Relationships
    role_cluster = db.relationship('RoleCluster', backref=db.backref('competencies', cascade="all, delete-orphan", lazy=True))
    competency = db.relationship('Competency', backref=db.backref('role_competencies', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('role_competencies', cascade="all, delete-orphan", lazy=True))

    # Constraints
    __table_args__ = (
        db.UniqueConstraint('organization_id', 'role_cluster_id', 'competency_id', name='role_competency_matrix_unique'),
    )

    def __repr__(self):
        return f"<RoleCompetencyMatrix organization_id={self.organization_id}, role_cluster_id={self.role_cluster_id}, competency_id={self.competency_id}, role_competency_value={self.role_competency_value}>"


# Organization Model
class Organization(db.Model):
    __tablename__ = 'organization'

    id = db.Column(db.Integer, primary_key=True)
    organization_name = db.Column(db.String(255), nullable=False, unique=True)
    organization_public_key = db.Column(db.String(50), nullable=False, unique=True)  # Added field

    def __repr__(self):
        return f"<Organization id={self.id}, organization_name='{self.organization_name}'>"

# User model for storing user details
class AppUser(db.Model):
    __tablename__ = 'app_user'

    id = db.Column(db.Integer, primary_key=True)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    username = db.Column(db.String(255), unique=True, nullable=False)
    tasks_responsibilities = db.Column(JSONB, nullable=False)  # JSONB field type for tasks

    # Relationships
    organization = db.relationship('Organization', backref=db.backref('users', lazy=True))

    def __repr__(self):
        return f"<User {self.username}>"
    
# For storing survey results of users
class UserCompetencySurveyResults(db.Model):
    __tablename__ = 'user_se_competency_survey_results'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id', ondelete='CASCADE'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id', ondelete='CASCADE'), nullable=False)
    score = db.Column(db.Integer, nullable=False)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship('AppUser', backref=db.backref('surveys', cascade='all, delete-orphan', lazy=True))
    organization = db.relationship('Organization', backref=db.backref('surveys', cascade='all, delete-orphan', lazy=True))
    competency = db.relationship('Competency', backref=db.backref('user_surveys', cascade='all, delete-orphan', lazy=True))

    def __repr__(self):
        return (f"<UserCompetencySurvey id={self.id}, user_id={self.user_id}, "
                f"competency_id={self.competency_id}, score={self.score}, submitted_at={self.submitted_at}>")
    

class UserRoleCluster(db.Model):
    __tablename__ = 'user_role_cluster'

    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'), primary_key=True, nullable=False)
    role_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), primary_key=True, nullable=False)

    # Relationships
    user = db.relationship('AppUser', backref=db.backref('role_clusters', cascade="all, delete-orphan", lazy=True))
    role_cluster = db.relationship('RoleCluster', backref=db.backref('user_roles', cascade="all, delete-orphan", lazy=True))

    def __repr__(self):
        return f"<UserRoleCluster user_id={self.user_id}, role_cluster_id={self.role_cluster_id}>"

# Updated UserCompetencySurveyFeedback Model
class UserCompetencySurveyFeedback(db.Model):
    __tablename__ = 'user_competency_survey_feedback'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id', ondelete='CASCADE'), nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)
    feedback = db.Column(JSONB, nullable=False)  # Store full feedback list as JSON
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship('AppUser', backref=db.backref('survey_feedbacks', cascade='all, delete-orphan', lazy=True))
    organization = db.relationship('Organization', backref=db.backref('survey_feedbacks', cascade='all, delete-orphan', lazy=True))

    def __repr__(self):
        return f"<UserCompetencySurveyFeedback id={self.id}, user_id={self.user_id}, organization_id={self.organization_id}, created_at={self.created_at}>"

# To store the type of survey user is performing
class UserSurveyType(db.Model):
    __tablename__ = 'user_survey_type'

    id = db.Column(db.Integer, primary_key=True)  # Unique identifier for each record
    user_id = db.Column(db.Integer, db.ForeignKey('app_user.id'), nullable=False)  # Foreign key to app_user table
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)  # Timestamp of when the record was created
    survey_type = db.Column(db.String(50), nullable=False, default='known_role')  # Survey type ('known_role' or 'unknown_role')

    # Relationships
    user = db.relationship('AppUser', backref=db.backref('survey_types', cascade="all, delete-orphan", lazy=True))

    def __repr__(self):
        return f"<UserSurveyType id={self.id}, user_id={self.user_id}, survey_type={self.survey_type}, created_at={self.created_at}>"
    

# Unknown Role Process Matrix model
class UnknownRoleProcessMatrix(db.Model):
    __tablename__ = 'unknown_role_process_matrix'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_name = db.Column(db.String(50), nullable=False)
    iso_process_id = db.Column(db.Integer, db.ForeignKey('iso_processes.id', ondelete='CASCADE'), nullable=False)
    role_process_value = db.Column(db.Integer, default=-100, nullable=True)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)

    # Relationships
    iso_process = db.relationship('IsoProcesses', backref=db.backref('unknown_role_process_matrix', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('unknown_role_process_matrix', cascade="all, delete-orphan", lazy=True))

    # Constraints
    __table_args__ = (
        db.UniqueConstraint('organization_id', 'iso_process_id', 'user_name', name='unknown_role_process_matrix_unique'),
        db.CheckConstraint("role_process_value IN (-100, 0, 1, 2, 3)", name="unknown_role_process_matrix_role_process_value_check"),
    )

    def __repr__(self):
        return f"<UnknownRoleProcessMatrix id={self.id}, user_name={self.user_name}, iso_process_id={self.iso_process_id}, role_process_value={self.role_process_value}, organization_id={self.organization_id}>"


# Unknown Role Competency Matrix model
class UnknownRoleCompetencyMatrix(db.Model):
    __tablename__ = 'unknown_role_competency_matrix'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_name = db.Column(db.String(50), nullable=False)
    competency_id = db.Column(db.Integer, db.ForeignKey('competency.id'), nullable=False)
    role_competency_value = db.Column(db.Integer, default=-100, nullable=False)
    organization_id = db.Column(db.Integer, db.ForeignKey('organization.id', ondelete='CASCADE'), nullable=False)

    # Relationships
    competency = db.relationship('Competency', backref=db.backref('unknown_role_competency_matrix', cascade="all, delete-orphan", lazy=True))
    organization = db.relationship('Organization', backref=db.backref('unknown_role_competency_matrix', cascade="all, delete-orphan", lazy=True))

    # Constraints
    __table_args__ = (
        db.UniqueConstraint('organization_id', 'user_name', 'competency_id', name='unknown_role_competency_matrix_unique'),
        db.CheckConstraint("role_competency_value IN (-100, 0, 1, 2, 3, 4, 6)", name="unknown_role_competency_matrix_role_competency_value_check"),
    )

    def __repr__(self):
        return f"<UnknownRoleCompetencyMatrix id={self.id}, user_name={self.user_name}, competency_id={self.competency_id}, role_competency_value={self.role_competency_value}, organization_id={self.organization_id}>"

# Table for storing admin password and username
class AdminUser(db.Model):
    __tablename__ = 'admin_user'

    id = db.Column(db.Integer, primary_key=True)  # Primary Key
    username = db.Column(db.String(255), unique=True, nullable=False)  # Unique username
    password_hash = db.Column(db.Text, nullable=False)  # Hashed password
    created_at = db.Column(db.DateTime, default=datetime.utcnow)  # Timestamp of creation



# class NewSurveyUser(db.Model):
#     __tablename__ = 'new_survey_user'

#     id = db.Column(db.Integer, primary_key=True)
#     username = db.Column(db.String(255), unique=True, nullable=False)
#     created_at = db.Column(db.DateTime, default=datetime.utcnow)
#     survey_completion_status = db.Column(db.Boolean, default=False, nullable=False)  # New column

#     def __init__(self, username):
#         self.username = username
#         self.survey_completion_status = False  # Default value

#     def __repr__(self):
#         return (
#             f"<NewSurveyUser id={self.id} username={self.username} "
#             f"survey_completion_status={self.survey_completion_status}>"
#         )

class NewSurveyUser(db.Model):
    __tablename__ = 'new_survey_user'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(255), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    survey_completion_status = db.Column(db.Boolean, default=False, nullable=False)

    # Remove the __init__ method so that username isn't required on instantiation.

    def __repr__(self):
        return (
            f"<NewSurveyUser id={self.id} username={self.username} "
            f"survey_completion_status={self.survey_completion_status}>"
        )
