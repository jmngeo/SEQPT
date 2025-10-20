#!/usr/bin/env python3
"""
Quick script to add the 14 KONEMANN role clusters to SE-QPT database
Based on the role data from the processed files
"""

import sys
import os
import json

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models import db, SERole
from app import create_app

def add_14_role_clusters():
    """Add the 14 SE role clusters based on KONEMANN methodology"""

    # The 14 role clusters from the processed data
    roles_data = [
        {
            "name": "Customer",
            "description": "End user or client stakeholder with system requirements and needs",
            "typical_responsibilities": json.dumps([
                "Define system requirements",
                "Accept delivered systems",
                "Provide usage feedback",
                "System requirements validation"
            ]),
            "career_level": "Stakeholder",
            "primary_focus": "Requirements",
            "typical_experience_years": 0
        },
        {
            "name": "Customer Representative",
            "description": "Acts as liaison between customer and development teams",
            "typical_responsibilities": json.dumps([
                "Stakeholder communication",
                "Requirements clarification",
                "Customer advocacy",
                "Acceptance coordination"
            ]),
            "career_level": "Entry-level",
            "primary_focus": "Stakeholder Management",
            "typical_experience_years": 2
        },
        {
            "name": "Project Manager",
            "description": "Manages project execution and coordinates SE activities",
            "typical_responsibilities": json.dumps([
                "Project planning and coordination",
                "Resource management",
                "Risk management",
                "Stakeholder communication"
            ]),
            "career_level": "Mid-level",
            "primary_focus": "Project Management",
            "typical_experience_years": 5
        },
        {
            "name": "Internal Support (IT, qualification, SE)",
            "description": "Provides internal support services and SE guidance",
            "typical_responsibilities": json.dumps([
                "IT infrastructure support",
                "Process qualification",
                "SE methodology guidance",
                "Training and mentoring"
            ]),
            "career_level": "Mid-level",
            "primary_focus": "Support Services",
            "typical_experience_years": 4
        },
        {
            "name": "Process & Policy Manager",
            "description": "Defines and maintains organizational processes and policies",
            "typical_responsibilities": json.dumps([
                "Process definition and optimization",
                "Policy development",
                "Compliance monitoring",
                "Process improvement initiatives"
            ]),
            "career_level": "Senior",
            "primary_focus": "Process Management",
            "typical_experience_years": 6
        },
        {
            "name": "System Engineer",
            "description": "Core SE practitioner responsible for system-level activities",
            "typical_responsibilities": json.dumps([
                "System architecture design",
                "Requirements engineering",
                "System integration",
                "Interface management"
            ]),
            "career_level": "Mid-level",
            "primary_focus": "Systems Engineering",
            "typical_experience_years": 4
        },
        {
            "name": "Developer",
            "description": "Implements system components and software solutions",
            "typical_responsibilities": json.dumps([
                "Component development",
                "Code implementation",
                "Unit testing",
                "Technical documentation"
            ]),
            "career_level": "Entry-level",
            "primary_focus": "Development",
            "typical_experience_years": 3
        },
        {
            "name": "Production Coordinator/Planner",
            "description": "Coordinates production planning and manufacturing processes",
            "typical_responsibilities": json.dumps([
                "Production planning",
                "Resource coordination",
                "Manufacturing process optimization",
                "Supply chain management"
            ]),
            "career_level": "Mid-level",
            "primary_focus": "Production",
            "typical_experience_years": 4
        },
        {
            "name": "V&V Employee",
            "description": "Performs verification and validation activities",
            "typical_responsibilities": json.dumps([
                "Test planning and execution",
                "Verification activities",
                "Validation strategies",
                "Quality assurance"
            ]),
            "career_level": "Mid-level",
            "primary_focus": "Testing",
            "typical_experience_years": 4
        },
        {
            "name": "Production Employee",
            "description": "Executes production and manufacturing activities",
            "typical_responsibilities": json.dumps([
                "Manufacturing execution",
                "Quality control",
                "Process adherence",
                "Production reporting"
            ]),
            "career_level": "Entry-level",
            "primary_focus": "Manufacturing",
            "typical_experience_years": 2
        },
        {
            "name": "Service Technician",
            "description": "Provides maintenance and service support for deployed systems",
            "typical_responsibilities": json.dumps([
                "System maintenance",
                "Technical support",
                "Field service",
                "Issue resolution"
            ]),
            "career_level": "Entry-level",
            "primary_focus": "Service",
            "typical_experience_years": 3
        },
        {
            "name": "Quality Manager",
            "description": "Manages quality assurance and control processes",
            "typical_responsibilities": json.dumps([
                "Quality system management",
                "Process auditing",
                "Compliance oversight",
                "Quality improvement initiatives"
            ]),
            "career_level": "Senior",
            "primary_focus": "Quality Management",
            "typical_experience_years": 6
        },
        {
            "name": "Innovation and Strategy Management",
            "description": "Drives innovation initiatives and strategic planning",
            "typical_responsibilities": json.dumps([
                "Innovation strategy development",
                "Technology roadmapping",
                "Research coordination",
                "Strategic planning"
            ]),
            "career_level": "Senior",
            "primary_focus": "Innovation",
            "typical_experience_years": 8
        },
        {
            "name": "Management",
            "description": "Provides organizational leadership and decision-making",
            "typical_responsibilities": json.dumps([
                "Strategic decision making",
                "Organizational leadership",
                "Resource allocation",
                "Performance management"
            ]),
            "career_level": "Executive",
            "primary_focus": "Leadership",
            "typical_experience_years": 10
        }
    ]

    # First, remove the old 5 roles to avoid conflicts
    old_roles = SERole.query.all()
    for old_role in old_roles:
        db.session.delete(old_role)

    # Add the new 14 role clusters
    for role_data in roles_data:
        existing = SERole.query.filter_by(name=role_data['name']).first()
        if not existing:
            role = SERole(**role_data)
            db.session.add(role)
            print(f"Added role: {role_data['name']}")
        else:
            print(f"Role already exists: {role_data['name']}")

    db.session.commit()
    print("Successfully added 14 KONEMANN role clusters to database")

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        add_14_role_clusters()