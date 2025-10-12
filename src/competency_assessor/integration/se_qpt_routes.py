"""
SE-QPT Integration Routes
Extends Derik's competency assessor with qualification planning capabilities
Maintains LangChain patterns and OpenAI integration
"""

from flask import Blueprint, request, jsonify
from app import db
from app.models import RoleCluster, Competency, CompetencyIndicator
from integration.unified_models import (
    QualificationArchetype, LearningObjective, QualificationPlan,
    RoleCompetencyMatrix, CompanyContext
)
import json
import os
from datetime import datetime
from sqlalchemy.exc import SQLAlchemyError
from langchain.prompts import ChatPromptTemplate
from langchain_openai import AzureChatOpenAI
from langchain_openai import OpenAIEmbeddings
from dotenv import load_dotenv

load_dotenv()

# Create SE-QPT blueprint
se_qpt = Blueprint('se_qpt', __name__, url_prefix='/api/se-qpt')

# ===== OPENAI SETUP (SAME AS DERIK'S) =====

def init_llm():
    """Initialize OpenAI LLM with same models as Derik's system"""
    openai_api_key = os.getenv("OPENAI_API_KEY")
    llm = AzureChatOpenAI(
        openai_api_key=openai_api_key,
        openai_api_base=os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1"),
        deployment_name="gpt-4o-mini",
        temperature=0
    )
    return llm

def init_embeddings():
    """Initialize embeddings with same model as Derik's system"""
    openai_api_key = os.getenv("OPENAI_API_KEY")
    embeddings = OpenAIEmbeddings(
        openai_api_key=openai_api_key,
        model="text-embedding-ada-002"
    )
    return embeddings

# ===== QUALIFICATION ARCHETYPES API =====

@se_qpt.route('/archetypes', methods=['GET'])
def get_qualification_archetypes():
    """Get all 6 qualification archetypes"""
    try:
        archetypes = QualificationArchetype.query.all()
        return jsonify([{
            'id': a.id,
            'name': a.name,
            'description': a.description,
            'target_competency_levels': a.target_competency_levels,
            'learning_formats': a.learning_formats
        } for a in archetypes])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@se_qpt.route('/archetypes', methods=['POST'])
def create_qualification_archetype():
    """Create a new qualification archetype"""
    try:
        data = request.json
        archetype = QualificationArchetype(
            name=data['name'],
            description=data['description'],
            target_competency_levels=data.get('target_competency_levels', {}),
            learning_formats=data.get('learning_formats', [])
        )
        db.session.add(archetype)
        db.session.commit()
        return jsonify({'message': 'Archetype created successfully', 'id': archetype.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# ===== LEARNING OBJECTIVES API =====

@se_qpt.route('/learning-objectives/generate', methods=['POST'])
def generate_learning_objectives():
    """Generate company-specific learning objectives using RAG-LLM"""
    try:
        data = request.json
        competency_id = data['competency_id']
        role_id = data['role_id']
        archetype_id = data['archetype_id']
        company_context = data.get('company_context', '')

        # Get related data
        competency = Competency.query.get(competency_id)
        role = RoleCluster.query.get(role_id)
        archetype = QualificationArchetype.query.get(archetype_id)

        if not all([competency, role, archetype]):
            return jsonify({'error': 'Invalid competency, role, or archetype ID'}), 400

        # Initialize LLM (same as Derik's setup)
        llm = init_llm()

        # Create RAG-enhanced prompt
        prompt_template = ChatPromptTemplate.from_messages([
            ("system", (
                "You are an expert in Systems Engineering qualification planning. "
                "Generate specific, actionable learning objectives for SE competency development. "
                "Use the SMART criteria and consider the company-specific context provided. "
                "Focus on practical application in the given role and archetype strategy."
            )),
            ("human", (
                "Generate learning objectives for:\\n"
                "Competency: {competency_name}\\n"
                "Role: {role_name}\\n"
                "Archetype: {archetype_name}\\n"
                "Company Context: {company_context}\\n\\n"
                "Provide 3-5 specific learning objectives that are:\\n"
                "1. Measurable and observable\\n"
                "2. Role-specific and practical\\n"
                "3. Aligned with the qualification archetype\\n"
                "4. Relevant to the company context\\n\\n"
                "Format each objective with recommended learning format and duration."
            ))
        ])

        # Generate objectives
        chain = prompt_template | llm
        response = chain.invoke({
            "competency_name": competency.competency_name,
            "role_name": role.role_cluster_name,
            "archetype_name": archetype.name,
            "company_context": company_context
        })

        # Parse and save objectives
        objectives_text = response.content

        # Create learning objective record
        learning_obj = LearningObjective(
            competency_id=competency_id,
            role_id=role_id,
            archetype_id=archetype_id,
            objective_text=objectives_text,
            generated_by_llm=True,
            source_context=company_context,
            quality_score=0.85  # Default score, can be enhanced with evaluation
        )

        db.session.add(learning_obj)
        db.session.commit()

        return jsonify({
            'id': learning_obj.id,
            'objectives': objectives_text,
            'competency': competency.competency_name,
            'role': role.role_cluster_name,
            'archetype': archetype.name,
            'generated_at': learning_obj.created_at.isoformat()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@se_qpt.route('/learning-objectives', methods=['GET'])
def get_learning_objectives():
    """Get learning objectives with optional filtering"""
    try:
        competency_id = request.args.get('competency_id')
        role_id = request.args.get('role_id')
        archetype_id = request.args.get('archetype_id')

        query = LearningObjective.query

        if competency_id:
            query = query.filter(LearningObjective.competency_id == competency_id)
        if role_id:
            query = query.filter(LearningObjective.role_id == role_id)
        if archetype_id:
            query = query.filter(LearningObjective.archetype_id == archetype_id)

        objectives = query.all()

        return jsonify([{
            'id': obj.id,
            'objective_text': obj.objective_text,
            'competency': obj.competency.competency_name,
            'role': obj.role.role_cluster_name,
            'archetype': obj.archetype.name,
            'bloom_level': obj.bloom_level,
            'competency_level': obj.competency_level,
            'recommended_formats': obj.recommended_formats,
            'quality_score': obj.quality_score,
            'created_at': obj.created_at.isoformat()
        } for obj in objectives])

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ===== QUALIFICATION PLANNING API =====

@se_qpt.route('/qualification-plans', methods=['POST'])
def create_qualification_plan():
    """Create a new qualification plan based on assessment results"""
    try:
        data = request.json

        plan = QualificationPlan(
            user_id=data['user_id'],
            role_id=data['role_id'],
            archetype_id=data['archetype_id'],
            plan_name=data['plan_name'],
            target_competency_gaps=data.get('competency_gaps', {}),
            company_context=data.get('company_context', ''),
            industry_domain=data.get('industry_domain', '')
        )

        db.session.add(plan)
        db.session.commit()

        return jsonify({
            'message': 'Qualification plan created successfully',
            'id': plan.id,
            'plan_name': plan.plan_name
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@se_qpt.route('/qualification-plans/<int:plan_id>', methods=['GET'])
def get_qualification_plan(plan_id):
    """Get a specific qualification plan"""
    try:
        plan = QualificationPlan.query.get_or_404(plan_id)

        return jsonify({
            'id': plan.id,
            'plan_name': plan.plan_name,
            'role': plan.role.role_cluster_name,
            'archetype': plan.archetype.name,
            'competency_gaps': plan.target_competency_gaps,
            'learning_objectives': plan.learning_objectives,
            'status': plan.status,
            'progress': plan.progress,
            'company_context': plan.company_context,
            'created_at': plan.created_at.isoformat()
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ===== ROLE-COMPETENCY MATRIX API =====

@se_qpt.route('/role-competency-matrix', methods=['GET'])
def get_role_competency_matrix():
    """Get the 14x16 role-competency matrix"""
    try:
        matrix_data = RoleCompetencyMatrix.query.all()

        # Organize into matrix format
        matrix = {}
        for entry in matrix_data:
            role_name = entry.role.role_cluster_name
            comp_name = entry.competency.competency_name

            if role_name not in matrix:
                matrix[role_name] = {}
            matrix[role_name][comp_name] = entry.required_level

        return jsonify({
            'matrix': matrix,
            'dimensions': f"{len(matrix)}x{len(next(iter(matrix.values())) if matrix else {})}",
            'roles': list(matrix.keys()),
            'competencies': list(next(iter(matrix.values())).keys()) if matrix else []
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ===== COMPANY CONTEXT API =====

@se_qpt.route('/company-context', methods=['POST'])
def create_company_context():
    """Create company-specific context for RAG generation"""
    try:
        data = request.json

        # Generate embeddings for context
        embeddings_model = init_embeddings()
        context_text = f"{data.get('business_domain', '')} {data.get('products_services', '')} {data.get('specific_challenges', '')}"

        context_embeddings = embeddings_model.embed_query(context_text)

        context = CompanyContext(
            company_name=data['company_name'],
            industry=data.get('industry', ''),
            business_domain=data.get('business_domain', ''),
            products_services=data.get('products_services', ''),
            se_maturity_level=data.get('se_maturity_level', ''),
            specific_challenges=data.get('specific_challenges', ''),
            context_embeddings=context_embeddings
        )

        db.session.add(context)
        db.session.commit()

        return jsonify({
            'message': 'Company context created successfully',
            'id': context.id,
            'company_name': context.company_name
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# ===== INTEGRATION STATUS =====

@se_qpt.route('/status', methods=['GET'])
def get_integration_status():
    """Get SE-QPT integration status"""
    try:
        competency_count = Competency.query.count()
        role_count = RoleCluster.query.count()
        archetype_count = QualificationArchetype.query.count()

        return jsonify({
            'status': 'active',
            'framework': 'KÖNEMANN et al. SE competencies',
            'competencies': competency_count,
            'roles': role_count,
            'archetypes': archetype_count,
            'derik_integration': 'active',
            'langchain_version': 'compatible',
            'openai_models': ['gpt-4o-mini', 'text-embedding-ada-002']
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500