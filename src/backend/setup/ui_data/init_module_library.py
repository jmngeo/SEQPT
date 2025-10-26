"""
SE Competency Module Library Initialization Script
Populates the database with the comprehensive SE competency modules
"""

import sys
import os
import json
from datetime import datetime

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models import (
    db, LearningModule, LearningPath, LearningResource, SECompetency
)
from app import create_app

def init_core_competency_modules():
    """Initialize the 4 core competency modules"""
    core_modules = [
        {
            "module_code": "C01",
            "name": "Systems Thinking",
            "category": "Core Competencies",
            "competency_code": "ST",
            "definition": "The competence to apply fundamental concepts of systems thinking in systems engineering and to understand the role of one's own system in its overall context.",
            "overview": "Critical across all industries, particularly complex systems development (aerospace, automotive, healthcare, defense)",
            "industry_relevance": "Essential for understanding complex system interactions, emergent properties, and holistic problem-solving approaches",
            "level_1_content": {
                "hours": 8,
                "objectives": [
                    "Define systems thinking principles and core concepts",
                    "Identify system boundaries in given scenarios",
                    "Recognize system hierarchies and levels of abstraction",
                    "List common systems archetypes and patterns"
                ],
                "topics": [
                    "General Systems Theory principles",
                    "System types: open, closed, adaptive",
                    "System properties: purpose, structure, process",
                    "Holism vs. reductionism",
                    "Boundary definition techniques",
                    "System-environment interactions"
                ],
                "assessments": [
                    "Multiple choice questions on systems concepts",
                    "System boundary identification exercises",
                    "Systems archetype recognition tasks",
                    "Case study analysis (written)"
                ]
            },
            "level_2_content": {
                "hours": 16,
                "objectives": [
                    "Explain the relationship between system structure and behavior",
                    "Describe emergent properties and system dynamics",
                    "Analyze cause-and-effect relationships in complex systems",
                    "Compare different systems thinking methodologies"
                ],
                "topics": [
                    "System levels and hierarchies",
                    "Emergent properties identification",
                    "Bottom-up vs. top-down thinking",
                    "Hierarchy theory applications",
                    "Context diagrams and boundary analysis"
                ],
                "assessments": [
                    "Systems behavior analysis",
                    "Emergent properties identification",
                    "Cause-effect relationship mapping"
                ]
            },
            "level_3_4_content": {
                "hours": 32,
                "objectives": [
                    "Apply systems thinking tools (causal loops, stock-flow diagrams)",
                    "Model system interactions and feedback mechanisms",
                    "Design interventions based on systems analysis",
                    "Facilitate systems thinking workshops with stakeholders"
                ],
                "topics": [
                    "Causal loop diagrams",
                    "Stock and flow models",
                    "Rich pictures and mind mapping",
                    "Systems maps and influence diagrams",
                    "System dynamics and behavior",
                    "Feedback loops and delays"
                ],
                "assessments": [
                    "Causal loop diagram creation",
                    "System dynamics modeling projects",
                    "Root cause analysis assignments",
                    "Facilitation skill demonstrations"
                ]
            },
            "level_5_6_content": {
                "hours": 48,
                "objectives": [
                    "Lead organizational systems transformation initiatives",
                    "Develop custom systems thinking frameworks for specific domains",
                    "Mentor others in advanced systems thinking techniques",
                    "Research and publish systems thinking innovations"
                ],
                "topics": [
                    "Soft systems methodology (SSM)",
                    "Viable systems model (VSM)",
                    "Critical systems heuristics",
                    "Systems of systems engineering",
                    "Systems leadership principles",
                    "Organizational learning systems"
                ],
                "assessments": [
                    "Complex systems intervention design",
                    "Systems transformation project leadership",
                    "Peer teaching and mentoring evaluation",
                    "Original research contribution"
                ]
            },
            "prerequisites": ["None"],
            "total_duration_hours": 104,
            "industry_adaptations": {
                "automotive": [
                    "Focus on ADAS and autonomous vehicle systems",
                    "Supply chain systems thinking",
                    "Safety system interactions (ISO 26262)",
                    "Manufacturing system optimization"
                ],
                "aerospace": [
                    "Mission system complexity",
                    "Safety-critical system interactions",
                    "System-of-systems integration",
                    "Regulatory compliance systems"
                ],
                "healthcare": [
                    "Patient care system design",
                    "Medical device integration",
                    "Healthcare delivery systems",
                    "Regulatory and quality systems"
                ]
            }
        },
        {
            "module_code": "C02",
            "name": "System Modeling and Analysis",
            "category": "Core Competencies",
            "competency_code": "SMA",
            "definition": "The ability to provide accurate data and information using cross-domain models to support technical understanding and decision-making.",
            "overview": "Essential for model-based systems engineering (MBSE) implementation and system analysis",
            "industry_relevance": "Critical for complex system development, verification, and validation across all industries",
            "level_1_content": {
                "hours": 12,
                "objectives": [
                    "Define system modeling principles and purposes",
                    "Identify different types of system models",
                    "Recognize modeling languages and notations (SysML, UML)",
                    "List model-based systems engineering (MBSE) benefits"
                ],
                "topics": [
                    "Purpose and benefits of system modeling",
                    "Model types: descriptive, predictive, prescriptive",
                    "Abstraction and simplification principles",
                    "Systems Modeling Language (SysML)",
                    "Unified Modeling Language (UML) basics"
                ],
                "assessments": [
                    "Model type identification exercises",
                    "SysML notation recognition",
                    "MBSE benefits analysis"
                ]
            },
            "level_2_content": {
                "hours": 24,
                "objectives": [
                    "Explain model abstraction levels and viewpoints",
                    "Describe model integration and consistency requirements",
                    "Analyze trade-offs in model complexity vs. usability",
                    "Compare different modeling methodologies"
                ],
                "topics": [
                    "Model abstraction levels",
                    "MBSE vs. document-based approaches",
                    "Tool landscape and selection criteria",
                    "Model lifecycle management"
                ],
                "assessments": [
                    "Model viewpoint analysis",
                    "MBSE methodology comparison",
                    "Tool selection exercises"
                ]
            },
            "level_3_4_content": {
                "hours": 48,
                "objectives": [
                    "Create system models using standard notations",
                    "Perform system analysis using models (performance, reliability)",
                    "Validate and verify model accuracy and completeness",
                    "Support decision-making with model-based analysis"
                ],
                "topics": [
                    "Structural modeling (block definition, internal block)",
                    "Behavioral modeling (activity, sequence, state machine)",
                    "Parametric modeling and constraints",
                    "Requirement modeling and traceability",
                    "Performance analysis techniques",
                    "Reliability and availability modeling"
                ],
                "assessments": [
                    "SysML model creation exercises",
                    "Model analysis and interpretation tasks",
                    "Tool proficiency demonstrations",
                    "MBSE process design projects"
                ]
            },
            "level_5_6_content": {
                "hours": 64,
                "objectives": [
                    "Architect enterprise-level MBSE implementations",
                    "Develop custom modeling frameworks and methodologies",
                    "Lead model-based system design organizations",
                    "Advance MBSE research and tool development"
                ],
                "topics": [
                    "Enterprise MBSE architecture",
                    "Tool integration and interoperability",
                    "Process integration and automation",
                    "Emerging modeling technologies (AI/ML integration)",
                    "Digital twin development"
                ],
                "assessments": [
                    "Enterprise MBSE strategy design",
                    "Custom framework development",
                    "MBSE implementation leadership",
                    "Research contribution assessment"
                ]
            },
            "prerequisites": ["C01"],
            "total_duration_hours": 148
        },
        {
            "module_code": "C03",
            "name": "System Life Cycle Phases",
            "category": "Core Competencies",
            "competency_code": "CSLCP",
            "definition": "Understanding and application of system lifecycle concepts, phases, and transitions throughout the entire system lifespan.",
            "overview": "Essential for managing complex system development from concept through disposal",
            "industry_relevance": "Critical for project management, cost optimization, and lifecycle planning in all industries",
            "level_1_content": {
                "hours": 10,
                "objectives": [
                    "Define system lifecycle phases and transitions",
                    "Identify key activities in each lifecycle phase",
                    "Recognize lifecycle models (V-model, spiral, agile)",
                    "List lifecycle management challenges"
                ],
                "topics": [
                    "System lifecycle definition and importance",
                    "ISO 15288 lifecycle processes",
                    "Phase characteristics and objectives",
                    "Waterfall and V-model approaches",
                    "Iterative and incremental models"
                ],
                "assessments": [
                    "Lifecycle phase identification",
                    "Model comparison exercises",
                    "Key activity mapping"
                ]
            },
            "level_2_content": {
                "hours": 20,
                "objectives": [
                    "Explain phase gate processes and decision criteria",
                    "Describe lifecycle cost implications and optimization",
                    "Analyze phase transition risks and mitigation strategies",
                    "Compare different lifecycle models for various contexts"
                ],
                "topics": [
                    "Phase gate processes",
                    "Lifecycle cost modeling",
                    "Risk management throughout lifecycle",
                    "Agile and lean lifecycle approaches"
                ],
                "assessments": [
                    "Phase gate design exercises",
                    "Cost analysis projects",
                    "Risk assessment tasks"
                ]
            },
            "level_3_4_content": {
                "hours": 40,
                "objectives": [
                    "Plan and manage system lifecycle phases",
                    "Execute phase gate reviews and assessments",
                    "Optimize lifecycle processes for efficiency and quality",
                    "Implement lifecycle management tools and practices"
                ],
                "topics": [
                    "Lifecycle planning techniques",
                    "Resource allocation across phases",
                    "Gate review processes and criteria",
                    "Decision-making frameworks"
                ],
                "assessments": [
                    "Lifecycle planning projects",
                    "Gate review facilitation",
                    "Process optimization tasks"
                ]
            },
            "level_5_6_content": {
                "hours": 56,
                "objectives": [
                    "Design custom lifecycle models for complex systems",
                    "Lead organizational lifecycle process improvement",
                    "Develop lifecycle management methodologies",
                    "Research lifecycle optimization techniques"
                ],
                "topics": [
                    "Through-life capability management",
                    "Sustainability and circular lifecycle design",
                    "Digital lifecycle management",
                    "Advanced lifecycle optimization"
                ],
                "assessments": [
                    "Custom lifecycle model design",
                    "Organizational improvement leadership",
                    "Methodology development",
                    "Research contributions"
                ]
            },
            "prerequisites": ["C01"],
            "total_duration_hours": 126
        },
        {
            "module_code": "C04",
            "name": "Agile Thinking / Customer Benefit Orientation",
            "category": "Core Competencies",
            "competency_code": "ATCBO",
            "definition": "The ability to apply agile principles and customer-focused thinking in systems engineering contexts while maintaining system integrity and quality.",
            "overview": "Essential for modern SE practices that emphasize customer value and adaptive development",
            "industry_relevance": "Critical for competitive advantage and customer satisfaction across all industries",
            "level_1_content": {
                "hours": 8,
                "objectives": [
                    "Define agile principles and values in SE context",
                    "Identify customer benefit orientation concepts",
                    "Recognize agile SE practices and techniques",
                    "List challenges of agile SE implementation"
                ],
                "topics": [
                    "Agile manifesto adaptation for SE",
                    "Agile vs. traditional SE paradigms",
                    "Customer collaboration in SE context",
                    "Value identification and definition"
                ],
                "assessments": [
                    "Agile principles recognition",
                    "Customer value identification",
                    "Practice categorization exercises"
                ]
            },
            "level_2_content": {
                "hours": 16,
                "objectives": [
                    "Explain agile SE framework integration approaches",
                    "Describe customer value identification and measurement",
                    "Analyze trade-offs between agility and system architecture",
                    "Compare agile SE with traditional SE approaches"
                ],
                "topics": [
                    "Scaling agile principles to complex systems",
                    "Value stream mapping for systems",
                    "Customer journey and experience design",
                    "Benefit realization and measurement"
                ],
                "assessments": [
                    "Framework integration analysis",
                    "Value measurement exercises",
                    "Trade-off evaluation tasks"
                ]
            },
            "level_3_4_content": {
                "hours": 32,
                "objectives": [
                    "Implement agile SE practices in system development",
                    "Facilitate customer collaboration and feedback integration",
                    "Adapt SE processes for agile delivery cadences",
                    "Measure and optimize customer value delivery"
                ],
                "topics": [
                    "Agile SE practice implementation",
                    "Customer feedback integration",
                    "Agile delivery adaptation",
                    "Value delivery optimization"
                ],
                "assessments": [
                    "Agile SE implementation projects",
                    "Customer collaboration facilitation",
                    "Process adaptation exercises",
                    "Value measurement implementation"
                ]
            },
            "level_5_6_content": {
                "hours": 44,
                "objectives": [
                    "Architect agile SE transformation strategies",
                    "Develop custom agile SE frameworks and methods",
                    "Lead organizational agile SE culture change",
                    "Research and innovate in agile SE methodologies"
                ],
                "topics": [
                    "Agile SE transformation architecture",
                    "Custom framework development",
                    "Culture change leadership",
                    "Agile SE research and innovation"
                ],
                "assessments": [
                    "Transformation strategy design",
                    "Custom framework development",
                    "Culture change leadership",
                    "Research contribution evaluation"
                ]
            },
            "prerequisites": ["C01"],
            "total_duration_hours": 100
        }
    ]

    for module_data in core_modules:
        # Find the associated competency
        competency = SECompetency.query.filter_by(code=module_data['competency_code']).first()

        # Check if module already exists
        existing = LearningModule.query.filter_by(module_code=module_data['module_code']).first()
        if existing:
            continue

        module = LearningModule(
            module_code=module_data['module_code'],
            name=module_data['name'],
            category=module_data['category'],
            competency_id=competency.id if competency else None,
            definition=module_data['definition'],
            overview=module_data['overview'],
            industry_relevance=module_data['industry_relevance'],
            level_1_content=json.dumps(module_data['level_1_content']),
            level_2_content=json.dumps(module_data['level_2_content']),
            level_3_4_content=json.dumps(module_data['level_3_4_content']),
            level_5_6_content=json.dumps(module_data['level_5_6_content']),
            prerequisites=json.dumps(module_data['prerequisites']),
            total_duration_hours=module_data['total_duration_hours'],
            industry_adaptations=json.dumps(module_data.get('industry_adaptations', {})),
            difficulty_level='beginner'
        )

        db.session.add(module)

    db.session.commit()
    print("Initialized 4 core competency modules")

def init_professional_skill_modules():
    """Initialize professional skills modules (P01-P06)"""
    professional_modules = [
        {
            "module_code": "P01",
            "name": "Requirements Management",
            "category": "Professional Skills",
            "competency_code": "RM",
            "definition": "The systematic approach to capturing, analyzing, documenting, validating, and managing system requirements throughout the system lifecycle.",
            "overview": "Fundamental skill for all SE practitioners dealing with stakeholder needs and system specifications",
            "total_duration_hours": 144,
            "prerequisites": ["C01"]
        },
        {
            "module_code": "P02",
            "name": "System Architecture Design",
            "category": "Professional Skills",
            "competency_code": "SAD",
            "definition": "The discipline of creating coherent system architectures that satisfy stakeholder requirements while optimizing system qualities and constraints.",
            "overview": "Critical for senior SE practitioners responsible for system design and technical leadership",
            "total_duration_hours": 170,
            "prerequisites": ["C01", "C02"]
        },
        {
            "module_code": "P03",
            "name": "Integration, Verification & Validation",
            "category": "Professional Skills",
            "competency_code": "IVV",
            "definition": "The systematic approach to combining system elements and confirming that the system meets specified requirements and stakeholder needs.",
            "overview": "Essential for ensuring system quality and stakeholder satisfaction",
            "total_duration_hours": 122,
            "prerequisites": ["P01", "P02"]
        },
        {
            "module_code": "P04",
            "name": "Operation, Service and Maintenance",
            "category": "Professional Skills",
            "competency_code": "OSM",
            "definition": "The systematic approach to operating, supporting, and maintaining systems throughout their operational life to ensure continued effectiveness and value delivery.",
            "overview": "Important for through-life system support and sustainability",
            "total_duration_hours": 100,
            "prerequisites": ["C03"]
        },
        {
            "module_code": "P05",
            "name": "Agile Methodological Competence",
            "category": "Professional Skills",
            "competency_code": "AMC",
            "definition": "The ability to apply agile methodologies and practices effectively in systems engineering contexts while maintaining system integrity and stakeholder value.",
            "overview": "Essential for modern SE practices in dynamic environments",
            "total_duration_hours": 78,
            "prerequisites": ["C04"]
        },
        {
            "module_code": "P06",
            "name": "Configuration Management",
            "category": "Professional Skills",
            "competency_code": "CM",
            "definition": "The systematic approach to managing and controlling changes to system configurations throughout the system lifecycle.",
            "overview": "Critical for maintaining system integrity and change control",
            "total_duration_hours": 100,
            "prerequisites": ["P01"]
        }
    ]

    for module_data in professional_modules:
        # Find the associated competency
        competency = SECompetency.query.filter_by(code=module_data['competency_code']).first()

        # Check if module already exists
        existing = LearningModule.query.filter_by(module_code=module_data['module_code']).first()
        if existing:
            continue

        module = LearningModule(
            module_code=module_data['module_code'],
            name=module_data['name'],
            category=module_data['category'],
            competency_id=competency.id if competency else None,
            definition=module_data['definition'],
            overview=module_data['overview'],
            prerequisites=json.dumps(module_data['prerequisites']),
            total_duration_hours=module_data['total_duration_hours'],
            difficulty_level='intermediate'
        )

        db.session.add(module)

    db.session.commit()
    print("Initialized 6 professional skills modules")

def init_social_competency_modules():
    """Initialize social and self-competency modules (S01-S03)"""
    social_modules = [
        {
            "module_code": "S01",
            "name": "Self-Organization",
            "category": "Social and Self-Competencies",
            "competency_code": "SO",
            "definition": "The ability to manage one's own work, time, and professional development effectively while contributing to team and organizational success.",
            "overview": "Essential personal effectiveness skills for all SE practitioners",
            "total_duration_hours": 74,
            "prerequisites": []
        },
        {
            "module_code": "S02",
            "name": "Communication & Collaboration",
            "category": "Social and Self-Competencies",
            "competency_code": "CC",
            "definition": "The ability to communicate effectively and collaborate productively with diverse stakeholders in various contexts and formats.",
            "overview": "Critical interpersonal skills for SE success in team environments",
            "total_duration_hours": 100,
            "prerequisites": ["S01"]
        },
        {
            "module_code": "S03",
            "name": "Leadership",
            "category": "Social and Self-Competencies",
            "competency_code": "L",
            "definition": "The ability to inspire, guide, and influence individuals and teams to achieve common goals and drive organizational success.",
            "overview": "Advanced leadership skills for senior SE practitioners and managers",
            "total_duration_hours": 126,
            "prerequisites": ["S01", "S02"]
        }
    ]

    for module_data in social_modules:
        # Find the associated competency
        competency = SECompetency.query.filter_by(code=module_data['competency_code']).first()

        # Check if module already exists
        existing = LearningModule.query.filter_by(module_code=module_data['module_code']).first()
        if existing:
            continue

        module = LearningModule(
            module_code=module_data['module_code'],
            name=module_data['name'],
            category=module_data['category'],
            competency_id=competency.id if competency else None,
            definition=module_data['definition'],
            overview=module_data['overview'],
            prerequisites=json.dumps(module_data['prerequisites']),
            total_duration_hours=module_data['total_duration_hours'],
            difficulty_level='intermediate'
        )

        db.session.add(module)

    db.session.commit()
    print("Initialized 3 social and self-competency modules")

def init_management_competency_modules():
    """Initialize management competency modules (M01-M03)"""
    management_modules = [
        {
            "module_code": "M01",
            "name": "Project Management",
            "category": "Management Competencies",
            "competency_code": "PM",
            "definition": "The systematic approach to planning, executing, monitoring, and closing projects to achieve specific goals within constraints of time, budget, and quality.",
            "overview": "Essential management skills for SE project leaders and program managers",
            "total_duration_hours": 148,
            "prerequisites": ["S02", "S03"]
        },
        {
            "module_code": "M02",
            "name": "Decision Management",
            "category": "Management Competencies",
            "competency_code": "DM",
            "definition": "The systematic approach to making effective decisions in complex, uncertain environments using structured processes and analytical tools.",
            "overview": "Critical for senior SE practitioners making complex technical and business decisions",
            "total_duration_hours": 100,
            "prerequisites": ["S03"]
        },
        {
            "module_code": "M03",
            "name": "Information Management",
            "category": "Management Competencies",
            "competency_code": "IM",
            "definition": "The systematic approach to capturing, organizing, storing, retrieving, and utilizing information to support decision-making and organizational effectiveness.",
            "overview": "Important for managing complex information flows in SE environments",
            "total_duration_hours": 100,
            "prerequisites": ["M02"]
        }
    ]

    for module_data in management_modules:
        # Find the associated competency
        competency = SECompetency.query.filter_by(code=module_data['competency_code']).first()

        # Check if module already exists
        existing = LearningModule.query.filter_by(module_code=module_data['module_code']).first()
        if existing:
            continue

        module = LearningModule(
            module_code=module_data['module_code'],
            name=module_data['name'],
            category=module_data['category'],
            competency_id=competency.id if competency else None,
            definition=module_data['definition'],
            overview=module_data['overview'],
            prerequisites=json.dumps(module_data['prerequisites']),
            total_duration_hours=module_data['total_duration_hours'],
            difficulty_level='advanced'
        )

        db.session.add(module)

    db.session.commit()
    print("Initialized 3 management competency modules")

def init_learning_paths():
    """Initialize recommended learning paths"""
    learning_paths = [
        {
            "name": "Beginner SE Practitioner Path",
            "description": "Foundational learning path for new systems engineers",
            "path_type": "level_based",
            "target_audience": "Entry-level systems engineers",
            "module_sequence": ["C01", "P01", "S02", "M01", "C02"],
            "estimated_duration_weeks": 24,
            "experience_level": "entry",
            "completion_criteria": {
                "min_modules": 4,
                "min_level": 2,
                "assessment_pass_rate": 70
            }
        },
        {
            "name": "Intermediate SE Practitioner Path",
            "description": "Comprehensive path for developing SE practitioners",
            "path_type": "level_based",
            "target_audience": "Mid-level systems engineers",
            "module_sequence": ["C01", "P01", "P02", "P03", "S03"],
            "estimated_duration_weeks": 36,
            "experience_level": "mid",
            "completion_criteria": {
                "min_modules": 5,
                "min_level": 3,
                "assessment_pass_rate": 75
            }
        },
        {
            "name": "Automotive Industry Focus",
            "description": "SE competencies tailored for automotive industry",
            "path_type": "industry_based",
            "target_audience": "Automotive systems engineers",
            "industry_focus": "automotive",
            "module_sequence": ["C01", "P01", "P02", "P03", "P06"],
            "estimated_duration_weeks": 40,
            "completion_criteria": {
                "min_modules": 5,
                "min_level": 3,
                "industry_certification": True
            }
        },
        {
            "name": "Aerospace Industry Focus",
            "description": "SE competencies for aerospace and defense",
            "path_type": "industry_based",
            "target_audience": "Aerospace systems engineers",
            "industry_focus": "aerospace",
            "module_sequence": ["C03", "P01", "P02", "P03", "M02"],
            "estimated_duration_weeks": 42,
            "completion_criteria": {
                "min_modules": 5,
                "min_level": 3,
                "industry_certification": True
            }
        },
        {
            "name": "SE Leadership Track",
            "description": "Leadership development for senior SE practitioners",
            "path_type": "role_based",
            "target_audience": "Senior systems engineers and managers",
            "role_focus": "leadership",
            "module_sequence": ["S03", "M01", "M02", "M03", "C04"],
            "estimated_duration_weeks": 30,
            "experience_level": "senior",
            "completion_criteria": {
                "min_modules": 4,
                "min_level": 4,
                "leadership_project": True
            }
        }
    ]

    for path_data in learning_paths:
        # Check if path already exists
        existing = LearningPath.query.filter_by(name=path_data['name']).first()
        if existing:
            continue

        path = LearningPath(
            name=path_data['name'],
            description=path_data['description'],
            path_type=path_data['path_type'],
            target_audience=path_data['target_audience'],
            module_sequence=json.dumps(path_data['module_sequence']),
            estimated_duration_weeks=path_data['estimated_duration_weeks'],
            industry_focus=path_data.get('industry_focus'),
            role_focus=path_data.get('role_focus'),
            experience_level=path_data.get('experience_level'),
            completion_criteria=json.dumps(path_data['completion_criteria'])
        )

        db.session.add(path)

    db.session.commit()
    print("Initialized learning paths")

def init_module_library():
    """Initialize the complete SE competency module library"""
    try:
        print("Starting SE Competency Module Library initialization...")

        # Create new tables for module system
        db.create_all()
        print("Module system tables created")

        # Initialize modules by category
        init_core_competency_modules()
        init_professional_skill_modules()
        init_social_competency_modules()
        init_management_competency_modules()

        # Initialize learning paths
        init_learning_paths()

        print("SE Competency Module Library initialization completed successfully!")

        # Print summary
        module_count = LearningModule.query.count()
        path_count = LearningPath.query.count()
        print(f"Total modules initialized: {module_count}")
        print(f"Total learning paths initialized: {path_count}")

    except Exception as e:
        print(f"Error during module library initialization: {e}")
        db.session.rollback()
        raise

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        init_module_library()