"""
Populate competency table with essential data from Derik's system
These are the 15 core SE competencies required for the competency-based role matching
"""

import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("=" * 80)
    print("POPULATING COMPETENCY TABLE")
    print("=" * 80)

    # Check if table already has data
    count = db.session.execute(text('SELECT COUNT(*) FROM competency;')).scalar()
    if count > 0:
        print(f"\nTable already has {count} rows - skipping")
    else:
        print("\nInserting 15 core SE competencies...")

        # Data from Derik's init.sql with English descriptions from SE4OWL competency framework
        competencies = [
            (1, 'Core', 'Systems Thinking',
             'The ability to apply fundamental concepts of systems thinking in Systems Engineering and understand the role of one\'s own system in its overall context.',
             'Systems thinking is a way of dealing with increasing complexity...'),
            (4, 'Core', 'Lifecycle Consideration',
             'The ability to consider all lifecycle phases (except the operational phase) in system requirements, architectures, and designs during system development.',
             ''),
            (5, 'Core', 'Customer / Value Orientation',
             'The ability to place agile values and customer benefits at the center of development.',
             ''),
            (6, 'Core', 'Systems Modelling and Analysis',
             'The ability to provide precise data and information using cross-domain models to support technical understanding and decision-making.',
             ''),
            (7, 'Social / Personal', 'Communication',
             'The ability to communicate constructively, efficiently, and consciously across domains, while capturing and considering the feelings of others and maintaining sustainable and fair relationships with colleagues and supervisors.',
             ''),
            (8, 'Social / Personal', 'Leadership',
             'The ability to select appropriate goals for a system or system element, negotiate when necessary, and efficiently achieve them with a team while guiding team members in problem-solving when needed.',
             ''),
            (9, 'Social / Personal', 'Self-Organization',
             'The ability to organize oneself and manage tasks independently.',
             ''),
            (10, 'Management', 'Project Management',
             'The ability to identify, plan, coordinate, and adapt activities to deliver a satisfactory system, product, or service with appropriate quality, budget, and timeline.',
             ''),
            (11, 'Management', 'Decision Management',
             'The ability to identify, characterize, and evaluate an objective set of alternatives in a structured and analytical manner while considering risks and opportunities.',
             ''),
            (12, 'Management', 'Information Management',
             'The ability to address all aspects of information for specific stakeholders to deliver the right information at the right time with appropriate security.',
             ''),
            (13, 'Management', 'Configuration Management',
             'The ability to consistently design system functions, performance, and physical properties across the lifecycle and ensure consistency.',
             ''),
            (14, 'Technical', 'Requirements Definition',
             'The ability to analyze stakeholder needs and expectations and derive system requirements from them.',
             ''),
            (15, 'Technical', 'System Architecting',
             'The ability to define system-related elements, their hierarchy, interfaces, behavior, and associated derived requirements to develop an implementable solution.',
             ''),
            (16, 'Technical', 'Integration, Verification, Validation',
             'The ability to integrate a set of system elements into a verifiable or validatable unit, and provide objective evidence that a system meets specified requirements (verification) or achieves its intended properties in the intended operational environment (validation).',
             ''),
            (17, 'Technical', 'Operation and Support',
             'The ability to commission, operate, and maintain a system\'s capabilities and functionalities throughout its lifetime.',
             ''),
            (18, 'Technical', 'Agile Methods',
             'The ability to apply methods that support agile values in the project context and enable parallel work.',
             '')
        ]

        for comp in competencies:
            db.session.execute(text("""
                INSERT INTO competency (id, competency_area, competency_name, description, why_it_matters)
                VALUES (:id, :area, :name, :desc, :why)
            """), {
                'id': comp[0],
                'area': comp[1],
                'name': comp[2],
                'desc': comp[3],
                'why': comp[4]
            })

        db.session.commit()

        print(f"[SUCCESS] Inserted {len(competencies)} competencies")

        # Show results
        results = db.session.execute(text("""
            SELECT id, competency_area, competency_name
            FROM competency
            ORDER BY id;
        """)).fetchall()

        print("\nCompetencies:")
        for r in results:
            print(f"  {r[0]:2}: [{r[1]:20}] {r[2]}")

    print("\n" + "=" * 80)
    print("COMPETENCY TABLE READY")
    print("=" * 80)
