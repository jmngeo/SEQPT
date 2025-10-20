#!/usr/bin/env python3
"""
SE-QPT Backend Application Entry Point
"""

import os
import sys
from flask import Flask
from flask_migrate import Migrate, upgrade

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

# Import all models from unified models.py
from models import (
    db, User, SECompetency, SERole, QualificationArchetype, Assessment,
    CompetencyAssessmentResult, LearningObjective, QualificationPlan,
    CompanyContext, RAGTemplate, LearningModule, LearningPath,
    ModuleEnrollment, ModuleAssessment, LearningResource,
    Organization, MVPUser, MaturityAssessment, CompetencyAssessment,
    LearningPlan, RoleMapping,
    calculate_maturity_score, select_archetype,
    generate_learning_plan_templates, generate_basic_modules
)

def create_application():
    """Create and configure the Flask application"""
    app = create_app()

    # Initialize Flask-Migrate
    migrate = Migrate(app, db)

    return app

def init_database():
    """Initialize database with tables and sample data"""
    app = create_application()

    with app.app_context():
        print("Creating database tables...")
        db.create_all()

        # Check if we need to populate initial data
        if SECompetency.query.count() == 0:
            print("Populating initial competencies...")
            populate_competencies()

        if SERole.query.count() == 0:
            print("Populating initial roles...")
            populate_roles()

        if QualificationArchetype.query.count() == 0:
            print("Populating initial archetypes...")
            populate_archetypes()

        print("Database initialization complete!")

def populate_competencies():
    """Populate initial SE competencies (simplified for quick setup)"""
    import json

    competencies = [
        {'name': 'Systems Thinking', 'code': 'ST', 'category': 'Technical', 'description': 'Ability to understand complex systems', 'incose_reference': 'T1'},
        {'name': 'Requirements Engineering', 'code': 'RE', 'category': 'Technical', 'description': 'Requirements analysis and management', 'incose_reference': 'T2'},
        {'name': 'System Architecture', 'code': 'SA', 'category': 'Technical', 'description': 'System design and architecture', 'incose_reference': 'T3'},
        {'name': 'Verification & Validation', 'code': 'VV', 'category': 'Technical', 'description': 'Testing and validation methods', 'incose_reference': 'T4'},
        {'name': 'Project Management', 'code': 'PM', 'category': 'Management', 'description': 'Project planning and control', 'incose_reference': 'M1'},
        {'name': 'Risk Management', 'code': 'RM', 'category': 'Management', 'description': 'Risk identification and mitigation', 'incose_reference': 'M2'},
        {'name': 'Communication', 'code': 'CM', 'category': 'Personal', 'description': 'Technical communication skills', 'incose_reference': 'P1'},
        {'name': 'Leadership', 'code': 'LD', 'category': 'Personal', 'description': 'Team and project leadership', 'incose_reference': 'P2'}
    ]

    for comp_data in competencies:
        # Add JSON fields with default values
        comp_data['level_definitions'] = json.dumps({'1': 'Awareness', '2': 'Supervised', '3': 'Practitioner', '4': 'Expert', '5': 'Authority'})
        comp_data['assessment_indicators'] = json.dumps(['Basic understanding', 'Applied knowledge', 'Advanced skills'])

        competency = SECompetency(**comp_data)
        db.session.add(competency)

    db.session.commit()

def populate_roles():
    """Populate SE roles (simplified for quick setup)"""
    import json

    roles = [
        {'name': 'System Engineer', 'description': 'Core systems engineering role', 'career_level': 'Mid-level', 'primary_focus': 'System design', 'typical_experience_years': 3},
        {'name': 'Requirements Engineer', 'description': 'Requirements specialist', 'career_level': 'Mid-level', 'primary_focus': 'Requirements analysis', 'typical_experience_years': 2},
        {'name': 'System Architect', 'description': 'Senior system design role', 'career_level': 'Senior', 'primary_focus': 'Architecture design', 'typical_experience_years': 7},
        {'name': 'Project Manager', 'description': 'Project execution and delivery', 'career_level': 'Senior', 'primary_focus': 'Project management', 'typical_experience_years': 5},
        {'name': 'V&V Engineer', 'description': 'Verification and validation specialist', 'career_level': 'Mid-level', 'primary_focus': 'Testing and validation', 'typical_experience_years': 3},
        {'name': 'Quality Manager', 'description': 'Quality assurance and improvement', 'career_level': 'Senior', 'primary_focus': 'Quality management', 'typical_experience_years': 6}
    ]

    for role_data in roles:
        # Add JSON field with default value
        role_data['typical_responsibilities'] = json.dumps(['Core responsibilities', 'Technical activities', 'Team coordination'])

        role = SERole(**role_data)
        db.session.add(role)

    db.session.commit()

def populate_archetypes():
    """Populate initial qualification archetypes"""
    archetypes = [
        {
            'name': 'Project-Oriented Training',
            'description': 'Learning through real-world project experience',
            'typical_duration': '6-12 months',
            'learning_format': 'project-based',
            'target_audience': 'Experienced professionals',
            'focus_area': 'Practical application',
            'delivery_method': 'on-the-job'
        },
        {
            'name': 'Intensive Bootcamp',
            'description': 'Concentrated learning program',
            'typical_duration': '2-4 weeks',
            'learning_format': 'intensive',
            'target_audience': 'Career changers',
            'focus_area': 'Rapid skill acquisition',
            'delivery_method': 'classroom'
        },
        {
            'name': 'Self-Paced Online',
            'description': 'Flexible online learning modules',
            'typical_duration': '3-6 months',
            'learning_format': 'self-paced',
            'target_audience': 'Working professionals',
            'focus_area': 'Flexible learning',
            'delivery_method': 'online'
        },
        {
            'name': 'Mentored Development',
            'description': 'One-on-one mentoring with expert guidance',
            'typical_duration': '6-18 months',
            'learning_format': 'mentored',
            'target_audience': 'High-potential individuals',
            'focus_area': 'Personalized growth',
            'delivery_method': 'mentoring'
        },
        {
            'name': 'Blended Learning',
            'description': 'Combination of online and in-person learning',
            'typical_duration': '4-8 months',
            'learning_format': 'blended',
            'target_audience': 'Diverse learners',
            'focus_area': 'Balanced approach',
            'delivery_method': 'hybrid'
        },
        {
            'name': 'Certification Track',
            'description': 'Structured path to professional certification',
            'typical_duration': '6-12 months',
            'learning_format': 'structured',
            'target_audience': 'Certification seekers',
            'focus_area': 'Credential achievement',
            'delivery_method': 'formal'
        }
    ]

    for archetype_data in archetypes:
        archetype = QualificationArchetype(**archetype_data)
        db.session.add(archetype)

    db.session.commit()

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='SE-QPT Backend Application')
    parser.add_argument('--init-db', action='store_true', help='Initialize database with sample data')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')

    args = parser.parse_args()

    if args.init_db:
        init_database()
    else:
        app = create_application()
        app.run(host=args.host, port=args.port, debug=args.debug)