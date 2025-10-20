#!/usr/bin/env python3
"""
Update SE-QPT Database with REAL Complete Questions
Replaces placeholder questions with actual SE-QPT content from the complete questionnaire set
"""

import sys
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import json

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, Questionnaire, Question, QuestionOption

def clear_existing_questionnaires():
    """Clear existing questionnaire data"""
    print("Clearing existing questionnaire data...")

    # Delete in correct order due to foreign key constraints
    QuestionOption.query.delete()
    Question.query.delete()
    Questionnaire.query.delete()

    db.session.commit()
    print("Existing questionnaire data cleared.")

def create_real_maturity_assessment():
    """Create SE Maturity Assessment with REAL questions from SE-QPT"""
    questionnaire = Questionnaire(
        name='SE Maturity Assessment',
        title='Systems Engineering Maturity Assessment',
        description='Comprehensive assessment based on Bretz Maturity Model - measures organizational breadth (Scope/Rollout) and depth (SE Roles/Processes) of SE implementation',
        questionnaire_type='maturity',
        phase=1,
        estimated_duration_minutes=25,
        is_active=True,
        sort_order=1
    )
    db.session.add(questionnaire)
    db.session.flush()

    # REAL Section A: Scope/Rollout Assessment (Q1-Q15)
    scope_questions = [
        {
            'number': 'Q1', 'text': 'In which organizational areas is Systems Engineering currently applied?',
            'weight': 0.25, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'SE is not used in the company', 'value': '0', 'score': 0},
                {'text': 'Individual teams/areas use SE approaches, not universally', 'value': '1', 'score': 1},
                {'text': 'SE is used throughout Engineering, not entire company', 'value': '2', 'score': 2},
                {'text': 'SE is rolled out and used throughout the entire company', 'value': '3', 'score': 3},
                {'text': 'SE extends beyond company boundaries to suppliers/partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q2', 'text': 'What percentage of your development projects formally use SE processes?',
            'weight': 0.20, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': '0%', 'value': '0', 'score': 0},
                {'text': '1-25%', 'value': '1', 'score': 1},
                {'text': '26-50%', 'value': '2', 'score': 2},
                {'text': '51-75%', 'value': '3', 'score': 3},
                {'text': '76-100%', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q3', 'text': 'How many organizational divisions actively implement SE practices?',
            'weight': 0.15, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'None', 'value': '0', 'score': 0},
                {'text': '1 division', 'value': '1', 'score': 1},
                {'text': '2-3 divisions', 'value': '2', 'score': 2},
                {'text': 'Most divisions (>75%)', 'value': '3', 'score': 3},
                {'text': 'All divisions + external partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q4', 'text': 'To what extent do SE activities involve suppliers and partners?',
            'weight': 0.15, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No external involvement', 'value': '0', 'score': 0},
                {'text': 'Minimal external coordination', 'value': '1', 'score': 1},
                {'text': 'Some supplier integration', 'value': '2', 'score': 2},
                {'text': 'Regular supplier/partner involvement', 'value': '3', 'score': 3},
                {'text': 'Fully integrated value chain SE', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q5', 'text': 'How would you describe SE adoption across management levels?',
            'weight': 0.25, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No management awareness', 'value': '0', 'score': 0},
                {'text': 'Individual manager interest', 'value': '1', 'score': 1},
                {'text': 'Department-level support', 'value': '2', 'score': 2},
                {'text': 'Executive-level commitment', 'value': '3', 'score': 3},
                {'text': 'Board-level strategic priority', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q6', 'text': 'What is the geographic spread of SE implementation?',
            'weight': 0.10, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No geographic implementation', 'value': '0', 'score': 0},
                {'text': 'Single location/site', 'value': '1', 'score': 1},
                {'text': 'Multiple locations within region', 'value': '2', 'score': 2},
                {'text': 'National implementation', 'value': '3', 'score': 3},
                {'text': 'International/global implementation', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q7', 'text': 'How extensively is SE applied across different product lines?',
            'weight': 0.08, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No product line coverage', 'value': '0', 'score': 0},
                {'text': 'Single product line', 'value': '1', 'score': 1},
                {'text': 'Some product lines', 'value': '2', 'score': 2},
                {'text': 'Most product lines', 'value': '3', 'score': 3},
                {'text': 'All product lines + new ventures', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q8', 'text': 'What is the level of SE integration with customer interactions?',
            'weight': 0.06, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No customer SE involvement', 'value': '0', 'score': 0},
                {'text': 'Occasional customer SE discussions', 'value': '1', 'score': 1},
                {'text': 'Regular customer SE presentations', 'value': '2', 'score': 2},
                {'text': 'Joint SE planning with customers', 'value': '3', 'score': 3},
                {'text': 'Full SE collaboration in value chain', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q9', 'text': 'How widely are SE tools deployed across the organization?',
            'weight': 0.05, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No SE tools', 'value': '0', 'score': 0},
                {'text': 'Individual tool usage', 'value': '1', 'score': 1},
                {'text': 'Department-level tool deployment', 'value': '2', 'score': 2},
                {'text': 'Organization-wide tool usage', 'value': '3', 'score': 3},
                {'text': 'Integrated tool ecosystem with partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q10', 'text': 'What is the scope of SE training and education programs?',
            'weight': 0.04, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No SE training', 'value': '0', 'score': 0},
                {'text': 'Ad-hoc individual training', 'value': '1', 'score': 1},
                {'text': 'Department-level training programs', 'value': '2', 'score': 2},
                {'text': 'Company-wide training initiatives', 'value': '3', 'score': 3},
                {'text': 'Extended training ecosystem including partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q11', 'text': 'How extensive is SE knowledge sharing across organizational boundaries?',
            'weight': 0.03, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No knowledge sharing', 'value': '0', 'score': 0},
                {'text': 'Within team sharing', 'value': '1', 'score': 1},
                {'text': 'Cross-departmental sharing', 'value': '2', 'score': 2},
                {'text': 'Company-wide knowledge sharing', 'value': '3', 'score': 3},
                {'text': 'Industry-wide knowledge sharing', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q12', 'text': 'What is the level of SE standardization across projects?',
            'weight': 0.03, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No standardization', 'value': '0', 'score': 0},
                {'text': 'Project-specific approaches', 'value': '1', 'score': 1},
                {'text': 'Department-level standards', 'value': '2', 'score': 2},
                {'text': 'Company-wide standards', 'value': '3', 'score': 3},
                {'text': 'Industry-aligned standards with external partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q13', 'text': 'How broadly is SE performance measurement implemented?',
            'weight': 0.02, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No SE performance measurement', 'value': '0', 'score': 0},
                {'text': 'Individual project measurement', 'value': '1', 'score': 1},
                {'text': 'Department-level measurement', 'value': '2', 'score': 2},
                {'text': 'Company-wide measurement', 'value': '3', 'score': 3},
                {'text': 'Value chain measurement including partners', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q14', 'text': 'What is the extent of SE community building and networking?',
            'weight': 0.02, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No SE community', 'value': '0', 'score': 0},
                {'text': 'Informal individual networks', 'value': '1', 'score': 1},
                {'text': 'Department SE communities', 'value': '2', 'score': 2},
                {'text': 'Company-wide SE community', 'value': '3', 'score': 3},
                {'text': 'External SE community participation', 'value': '4', 'score': 4}
            ]
        },
        {
            'number': 'Q15', 'text': 'How comprehensive is SE governance and oversight?',
            'weight': 0.01, 'section': 'Scope/Rollout Assessment',
            'options': [
                {'text': 'No SE governance', 'value': '0', 'score': 0},
                {'text': 'Project-level governance', 'value': '1', 'score': 1},
                {'text': 'Department-level governance', 'value': '2', 'score': 2},
                {'text': 'Company-wide governance', 'value': '3', 'score': 3},
                {'text': 'Extended governance including partners', 'value': '4', 'score': 4}
            ]
        }
    ]

    # REAL Section B: SE Roles/Processes Assessment (Q16-Q33)
    process_questions = [
        {
            'number': 'Q16', 'text': 'How would you characterize your SE process documentation?',
            'weight': 0.20, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No documented processes', 'value': '0', 'score': 0},
                {'text': 'Ad-hoc, informal guidelines only', 'value': '1', 'score': 1},
                {'text': 'Individual goals specified, no overarching process', 'value': '2', 'score': 2},
                {'text': 'Formal SE processes defined and established company-wide', 'value': '3', 'score': 3},
                {'text': 'Processes analyzed using quantitative parameters', 'value': '4', 'score': 4},
                {'text': 'Processes continuously optimized based on metrics', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q17', 'text': 'How are SE responsibilities assigned in your organization?',
            'weight': 0.18, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No clear SE responsibility assignment', 'value': '0', 'score': 0},
                {'text': 'Tasks carried out "somehow" by available people', 'value': '1', 'score': 1},
                {'text': 'Individual expertise-based assignment', 'value': '2', 'score': 2},
                {'text': 'Formal SE role definitions with clear responsibilities', 'value': '3', 'score': 3},
                {'text': 'Roles measured and controlled quantitatively', 'value': '4', 'score': 4},
                {'text': 'Roles continuously optimized through performance data', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q18', 'text': 'How do you measure the effectiveness of your SE processes?',
            'weight': 0.15, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No measurement system in place', 'value': '0', 'score': 0},
                {'text': 'Basic activity tracking only', 'value': '1', 'score': 1},
                {'text': 'Individual project-level metrics', 'value': '2', 'score': 2},
                {'text': 'Standardized company-wide SE metrics', 'value': '3', 'score': 3},
                {'text': 'Quantitative analysis with statistical process control', 'value': '4', 'score': 4},
                {'text': 'Continuous improvement based on predictive analytics', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q19', 'text': 'What is the level of SE process standardization?',
            'weight': 0.12, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No standardized processes', 'value': '0', 'score': 0},
                {'text': 'Inconsistent process application', 'value': '1', 'score': 1},
                {'text': 'Project-specific process variations', 'value': '2', 'score': 2},
                {'text': 'Standardized processes across projects', 'value': '3', 'score': 3},
                {'text': 'Quantitatively controlled process variations', 'value': '4', 'score': 4},
                {'text': 'Statistically optimized process standards', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q20', 'text': 'How mature is your requirements management process?',
            'weight': 0.10, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No formal requirements process', 'value': '0', 'score': 0},
                {'text': 'Ad-hoc requirements handling', 'value': '1', 'score': 1},
                {'text': 'Basic requirements documentation', 'value': '2', 'score': 2},
                {'text': 'Systematic requirements management', 'value': '3', 'score': 3},
                {'text': 'Quantitative requirements process control', 'value': '4', 'score': 4},
                {'text': 'Optimized requirements innovation process', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q21', 'text': 'What is the maturity of your system architecture practices?',
            'weight': 0.08, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No systematic architecture approach', 'value': '0', 'score': 0},
                {'text': 'Informal architecture decisions', 'value': '1', 'score': 1},
                {'text': 'Basic architecture documentation', 'value': '2', 'score': 2},
                {'text': 'Formal architecture design processes', 'value': '3', 'score': 3},
                {'text': 'Quantitative architecture evaluation', 'value': '4', 'score': 4},
                {'text': 'Continuous architecture optimization', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q22', 'text': 'How developed are your verification and validation processes?',
            'weight': 0.06, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No systematic V&V approach', 'value': '0', 'score': 0},
                {'text': 'Ad-hoc testing activities', 'value': '1', 'score': 1},
                {'text': 'Basic V&V procedures', 'value': '2', 'score': 2},
                {'text': 'Comprehensive V&V processes', 'value': '3', 'score': 3},
                {'text': 'Quantitative V&V measurement', 'value': '4', 'score': 4},
                {'text': 'Predictive V&V optimization', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q23', 'text': 'What is the maturity of your configuration management?',
            'weight': 0.05, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No configuration management', 'value': '0', 'score': 0},
                {'text': 'Basic version control', 'value': '1', 'score': 1},
                {'text': 'Systematic configuration control', 'value': '2', 'score': 2},
                {'text': 'Integrated configuration management', 'value': '3', 'score': 3},
                {'text': 'Quantitative configuration metrics', 'value': '4', 'score': 4},
                {'text': 'Optimized configuration processes', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q24', 'text': 'How mature is your risk management process?',
            'weight': 0.04, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No formal risk management', 'value': '0', 'score': 0},
                {'text': 'Reactive risk handling', 'value': '1', 'score': 1},
                {'text': 'Basic risk identification', 'value': '2', 'score': 2},
                {'text': 'Systematic risk management', 'value': '3', 'score': 3},
                {'text': 'Quantitative risk analysis', 'value': '4', 'score': 4},
                {'text': 'Predictive risk optimization', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q25', 'text': 'What is the level of your project management integration with SE?',
            'weight': 0.04, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No SE-PM integration', 'value': '0', 'score': 0},
                {'text': 'Minimal coordination', 'value': '1', 'score': 1},
                {'text': 'Basic integration points', 'value': '2', 'score': 2},
                {'text': 'Systematic SE-PM integration', 'value': '3', 'score': 3},
                {'text': 'Quantitative integration metrics', 'value': '4', 'score': 4},
                {'text': 'Optimized SE-PM processes', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q26', 'text': 'How mature are your SE training and competency development processes?',
            'weight': 0.03, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No systematic SE training', 'value': '0', 'score': 0},
                {'text': 'Ad-hoc skill development', 'value': '1', 'score': 1},
                {'text': 'Basic training programs', 'value': '2', 'score': 2},
                {'text': 'Systematic competency development', 'value': '3', 'score': 3},
                {'text': 'Quantitative skill measurement', 'value': '4', 'score': 4},
                {'text': 'Continuous competency optimization', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q27', 'text': 'What is the maturity of your SE tool integration?',
            'weight': 0.03, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No systematic tool use', 'value': '0', 'score': 0},
                {'text': 'Individual tool usage', 'value': '1', 'score': 1},
                {'text': 'Basic tool integration', 'value': '2', 'score': 2},
                {'text': 'Systematic tool integration', 'value': '3', 'score': 3},
                {'text': 'Quantitative tool effectiveness', 'value': '4', 'score': 4},
                {'text': 'Optimized tool ecosystem', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q28', 'text': 'How developed is your SE knowledge management?',
            'weight': 0.02, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No knowledge management', 'value': '0', 'score': 0},
                {'text': 'Individual knowledge retention', 'value': '1', 'score': 1},
                {'text': 'Basic knowledge sharing', 'value': '2', 'score': 2},
                {'text': 'Systematic knowledge management', 'value': '3', 'score': 3},
                {'text': 'Quantitative knowledge metrics', 'value': '4', 'score': 4},
                {'text': 'Continuous knowledge optimization', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q29', 'text': 'What is the maturity of your supplier/partner SE integration?',
            'weight': 0.02, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No supplier SE integration', 'value': '0', 'score': 0},
                {'text': 'Basic supplier coordination', 'value': '1', 'score': 1},
                {'text': 'Systematic supplier SE requirements', 'value': '2', 'score': 2},
                {'text': 'Integrated supplier SE processes', 'value': '3', 'score': 3},
                {'text': 'Quantitative supplier SE metrics', 'value': '4', 'score': 4},
                {'text': 'Optimized SE value chain', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q30', 'text': 'How mature is your SE performance measurement system?',
            'weight': 0.02, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No SE performance measurement', 'value': '0', 'score': 0},
                {'text': 'Basic activity metrics', 'value': '1', 'score': 1},
                {'text': 'Systematic performance tracking', 'value': '2', 'score': 2},
                {'text': 'Comprehensive performance management', 'value': '3', 'score': 3},
                {'text': 'Quantitative performance optimization', 'value': '4', 'score': 4},
                {'text': 'Predictive performance management', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q31', 'text': 'What is the level of your SE process improvement capability?',
            'weight': 0.01, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No improvement process', 'value': '0', 'score': 0},
                {'text': 'Reactive problem solving', 'value': '1', 'score': 1},
                {'text': 'Basic improvement initiatives', 'value': '2', 'score': 2},
                {'text': 'Systematic process improvement', 'value': '3', 'score': 3},
                {'text': 'Quantitative improvement management', 'value': '4', 'score': 4},
                {'text': 'Continuous innovation culture', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q32', 'text': 'How mature is your SE governance structure?',
            'weight': 0.01, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No SE governance', 'value': '0', 'score': 0},
                {'text': 'Informal SE oversight', 'value': '1', 'score': 1},
                {'text': 'Basic SE governance', 'value': '2', 'score': 2},
                {'text': 'Systematic SE governance', 'value': '3', 'score': 3},
                {'text': 'Quantitative governance metrics', 'value': '4', 'score': 4},
                {'text': 'Optimized governance processes', 'value': '5', 'score': 5}
            ]
        },
        {
            'number': 'Q33', 'text': 'What is the maturity of your SE culture and mindset?',
            'weight': 0.01, 'section': 'SE Roles/Processes Assessment',
            'options': [
                {'text': 'No SE awareness', 'value': '0', 'score': 0},
                {'text': 'Individual SE interest', 'value': '1', 'score': 1},
                {'text': 'Growing SE awareness', 'value': '2', 'score': 2},
                {'text': 'Established SE culture', 'value': '3', 'score': 3},
                {'text': 'Quantifiable SE behaviors', 'value': '4', 'score': 4},
                {'text': 'Continuously evolving SE culture', 'value': '5', 'score': 5}
            ]
        }
    ]

    # Add all questions to database
    all_questions = scope_questions + process_questions
    for i, q_data in enumerate(all_questions):
        max_score = 5 if q_data['section'] == 'SE Roles/Processes Assessment' else 4

        question = Question(
            questionnaire_id=questionnaire.id,
            question_number=q_data['number'],
            question_text=q_data['text'],
            question_type='multiple_choice',
            section=q_data['section'],
            weight=q_data['weight'],
            max_score=max_score,
            is_required=True,
            sort_order=i + 1
        )
        db.session.add(question)
        db.session.flush()

        # Add options
        for j, opt in enumerate(q_data['options']):
            option = QuestionOption(
                question_id=question.id,
                option_text=opt['text'],
                option_value=opt['value'],
                score_value=opt['score'],
                sort_order=j + 1
            )
            db.session.add(option)

    return questionnaire

def create_real_archetype_selection():
    """Create Qualification Archetype Selection questionnaire with REAL questions"""
    questionnaire = Questionnaire(
        name='Qualification Archetype Selection',
        title='Qualification Strategy Selection',
        description='Decision tree-based strategy selection for SE qualification approach',
        questionnaire_type='archetype',
        phase=1,
        estimated_duration_minutes=10,
        is_active=True,
        sort_order=2
    )
    db.session.add(questionnaire)
    db.session.flush()

    # REAL Archetype selection questions (Q34-Q38)
    archetype_questions = [
        {
            'number': 'Q34', 'text': "What is your company's primary goal for SE implementation?",
            'weight': 0.30,
            'options': [
                {'text': 'Create basic awareness and understanding', 'value': 'A', 'archetype': 'Common Basic Understanding'},
                {'text': 'Apply SE systematically in projects', 'value': 'B', 'archetype': 'Needs-based Training'},
                {'text': 'Develop internal SE experts', 'value': 'C', 'archetype': 'Certification'},
                {'text': 'Maintain and improve existing SE practices', 'value': 'D', 'archetype': 'Continuous Support'}
            ]
        },
        {
            'number': 'Q35', 'text': 'What is your preferred approach to employee development?',
            'weight': 0.25,
            'options': [
                {'text': 'Broad-based awareness programs', 'value': 'A', 'archetype': 'Common Basic Understanding'},
                {'text': 'Hands-on project experience', 'value': 'B', 'archetype': 'Needs-based Training'},
                {'text': 'Intensive specialist training', 'value': 'C', 'archetype': 'Certification'},
                {'text': 'Continuous skill enhancement', 'value': 'D', 'archetype': 'Continuous Support'}
            ]
        },
        {
            'number': 'Q36', 'text': 'What is your timeline for SE qualification implementation?',
            'weight': 0.20,
            'options': [
                {'text': 'Long-term cultural change (2+ years)', 'value': 'A', 'archetype': 'Common Basic Understanding'},
                {'text': 'Medium-term project cycles (6-18 months)', 'value': 'B', 'archetype': 'Needs-based Training'},
                {'text': 'Short-term intensive programs (1-6 months)', 'value': 'C', 'archetype': 'Certification'},
                {'text': 'Ongoing continuous development', 'value': 'D', 'archetype': 'Continuous Support'}
            ]
        },
        {
            'number': 'Q37', 'text': "What is your organization's current SE experience level?",
            'weight': 0.15,
            'options': [
                {'text': 'No prior SE experience', 'value': 'A', 'archetype': 'Common Basic Understanding'},
                {'text': 'Some informal SE practices', 'value': 'B', 'archetype': 'Needs-based Training'},
                {'text': 'Basic SE knowledge present', 'value': 'C', 'archetype': 'Certification'},
                {'text': 'Established SE practices', 'value': 'D', 'archetype': 'Continuous Support'}
            ]
        },
        {
            'number': 'Q38', 'text': 'What type of learning outcomes do you prioritize?',
            'weight': 0.10,
            'options': [
                {'text': 'Awareness and motivation', 'value': 'A', 'archetype': 'Common Basic Understanding'},
                {'text': 'Practical application skills', 'value': 'B', 'archetype': 'Needs-based Training'},
                {'text': 'Deep technical expertise', 'value': 'C', 'archetype': 'Certification'},
                {'text': 'Leadership and coaching abilities', 'value': 'D', 'archetype': 'Continuous Support'}
            ]
        }
    ]

    # Add archetype questions to database
    for i, q_data in enumerate(archetype_questions):
        question = Question(
            questionnaire_id=questionnaire.id,
            question_number=q_data['number'],
            question_text=q_data['text'],
            question_type='multiple_choice',
            section='Archetype Selection',
            weight=q_data['weight'],
            max_score=1,  # Binary scoring for archetype
            is_required=True,
            sort_order=i + 1
        )
        db.session.add(question)
        db.session.flush()

        # Add options
        for j, opt in enumerate(q_data['options']):
            option = QuestionOption(
                question_id=question.id,
                option_text=opt['text'],
                option_value=opt['value'],
                score_value=1,  # All options score 1 for archetype selection
                sort_order=j + 1
            )
            db.session.add(option)

    return questionnaire

def main():
    """Main function to update questionnaires with REAL questions"""
    app = create_app()

    with app.app_context():
        print("Starting REAL questionnaire update...")
        print("This will replace placeholder questions with actual SE-QPT content")

        # Clear existing data
        clear_existing_questionnaires()

        # Create complete questionnaires with REAL questions
        print("\nCreating SE Maturity Assessment with REAL questions (Q1-Q33)...")
        maturity_q = create_real_maturity_assessment()

        print("Creating Qualification Archetype Selection with REAL questions (Q34-Q38)...")
        archetype_q = create_real_archetype_selection()

        # Commit all changes
        db.session.commit()

        print(f"\nSUCCESS: Complete REAL questionnaire set created!")
        print(f"   SE Maturity Assessment: {maturity_q.name} (33 questions)")
        print(f"   Archetype Selection: {archetype_q.name} (5 questions)")
        print(f"   Total Phase 1 questions: 38 REAL SE-QPT questions")
        print(f"\nNo more placeholder questions - all content is authentic SE-QPT!")

if __name__ == '__main__':
    main()