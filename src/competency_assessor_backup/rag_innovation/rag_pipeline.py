"""
RAG-LLM Learning Objectives Innovation - Core Pipeline
First application of RAG-LLM for SE qualification planning
Transforms standardized objectives using company PMT context
"""

import os
import json
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import chromadb
from chromadb.config import Settings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema import Document
from langchain_community.vectorstores import Chroma
from langchain.chains import RetrievalQA
from pydantic import BaseModel, Field
from dotenv import load_dotenv

load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LearningObjectiveQuality(BaseModel):
    """Quality assessment model for generated learning objectives"""
    smart_score: float = Field(..., description="SMART criteria score (0.0-1.0)")
    specific: float = Field(..., description="Specificity score")
    measurable: float = Field(..., description="Measurability score")
    achievable: float = Field(..., description="Achievability score")
    relevant: float = Field(..., description="Relevance score")
    time_bound: float = Field(..., description="Time-bound score")
    company_alignment: float = Field(..., description="Company context alignment")
    incose_compliance: float = Field(..., description="INCOSE framework compliance")
    overall_quality: float = Field(..., description="Overall quality score")

class CompanyContext(BaseModel):
    """Company PMT (Processes, Methods, Tools) context model"""
    company_name: str
    industry_domain: str
    business_processes: List[str] = []
    methods_used: List[str] = []
    tools_technologies: List[str] = []
    specific_challenges: List[str] = []
    se_maturity_level: str = "developing"
    organizational_context: str = ""

class RAGLearningObjectiveGenerator:
    """
    RAG-LLM pipeline for generating company-specific learning objectives
    Core innovation of the SE-QPT thesis
    """

    def __init__(self, vector_db_path: str = "data/rag_vectordb"):
        """Initialize the RAG pipeline"""
        self.vector_db_path = vector_db_path
        self.embeddings = self._init_embeddings()
        self.llm = self._init_llm()
        self.vectorstore = None
        self.quality_threshold = 0.85  # 85% quality threshold as specified

        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(path=vector_db_path)

        # Text splitter for document processing
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            separators=["\n\n", "\n", ". ", " ", ""]
        )

        logger.info("RAG-LLM Learning Objective Generator initialized")

    def _init_embeddings(self) -> OpenAIEmbeddings:
        """Initialize OpenAI embeddings (same as Derik's setup)"""
        return OpenAIEmbeddings(
            api_key=os.getenv("OPENAI_API_KEY"),
            model="text-embedding-ada-002"
        )

    def _init_llm(self) -> ChatOpenAI:
        """Initialize LLM (same as Derik's setup)"""
        return ChatOpenAI(
            api_key=os.getenv("OPENAI_API_KEY"),
            model="gpt-4o-mini",
            temperature=0.1  # Slightly creative but consistent
        )

    def setup_vector_database(self, force_rebuild: bool = False) -> bool:
        """Setup ChromaDB vector database with learning objective templates"""
        try:
            collection_name = "se_learning_objectives"

            if force_rebuild:
                try:
                    self.chroma_client.delete_collection(collection_name)
                    logger.info("Deleted existing collection for rebuild")
                except:
                    pass

            # Get or create collection
            try:
                collection = self.chroma_client.get_collection(collection_name)
                logger.info("Using existing vector database")
            except:
                collection = self.chroma_client.create_collection(
                    name=collection_name,
                    metadata={"description": "SE learning objective templates and examples"}
                )
                logger.info("Created new vector database collection")

            # Load learning objective templates
            templates = self._load_learning_objective_templates()

            if not templates:
                logger.warning("No templates loaded, creating sample data")
                templates = self._create_sample_templates()

            # Process and store templates
            documents = []
            metadatas = []
            ids = []

            for i, template in enumerate(templates):
                # Create document text
                doc_text = self._template_to_text(template)

                documents.append(doc_text)
                metadatas.append({
                    'competency': template.get('competency', 'unknown'),
                    'level': template.get('level', 'unknown'),
                    'archetype': template.get('archetype', 'generic'),
                    'format': template.get('format', 'standard')
                })
                ids.append(f"template_{i}")

            # Add to collection if we have documents
            if documents:
                collection.add(
                    documents=documents,
                    metadatas=metadatas,
                    ids=ids
                )
                logger.info(f"Added {len(documents)} templates to vector database")

            # Initialize Chroma vectorstore for LangChain
            self.vectorstore = Chroma(
                client=self.chroma_client,
                collection_name=collection_name,
                embedding_function=self.embeddings
            )

            return True

        except Exception as e:
            logger.error(f"Error setting up vector database: {e}")
            return False

    def _load_learning_objective_templates(self) -> List[Dict]:
        """Load learning objective templates from processed data"""
        templates = []

        try:
            # Load from SE foundation data
            with open('data/processed/se_foundation_data.json', 'r') as f:
                foundation_data = json.load(f)

            # Extract learning objectives
            learning_objectives = foundation_data.get('learning_objectives', [])

            for obj in learning_objectives:
                template = {
                    'competency': obj.get('col_0', 'Unknown'),
                    'objective_text': obj.get('col_1', ''),
                    'level': obj.get('col_2', 'Apply'),
                    'format': obj.get('col_3', 'Standard'),
                    'source': 'se_foundation_excel'
                }
                if template['objective_text']:
                    templates.append(template)

            logger.info(f"Loaded {len(templates)} learning objective templates")

        except Exception as e:
            logger.error(f"Error loading templates: {e}")

        return templates

    def _create_sample_templates(self) -> List[Dict]:
        """Create sample learning objective templates"""
        return [
            {
                'competency': 'Systemic thinking',
                'objective_text': 'At the end of the module, participants understand the interrelationships of system components and can identify system boundaries in their work context.',
                'level': 'Understand',
                'archetype': 'Common basic understanding',
                'format': 'Workshop'
            },
            {
                'competency': 'Requirements management',
                'objective_text': 'Participants can independently identify, analyze, and document system requirements using established tools and processes.',
                'level': 'Apply',
                'archetype': 'Needs-based, project-oriented training',
                'format': 'On-the-job training'
            },
            {
                'competency': 'System architecture design',
                'objective_text': 'Participants can create and evaluate system architecture models for complex systems in their domain.',
                'level': 'Master',
                'archetype': 'Train the trainer',
                'format': 'Mentoring'
            }
        ]

    def _template_to_text(self, template: Dict) -> str:
        """Convert template to searchable text"""
        return f"""
        Competency: {template.get('competency', '')}
        Learning Objective: {template.get('objective_text', '')}
        Level: {template.get('level', '')}
        Archetype: {template.get('archetype', '')}
        Format: {template.get('format', '')}
        """

    def generate_customized_objective(
        self,
        competency: str,
        role: str,
        archetype: str,
        company_context: CompanyContext,
        retrieve_k: int = 5
    ) -> Dict[str, Any]:
        """
        Generate company-specific learning objective using RAG-LLM
        Core innovation method
        """
        try:
            if not self.vectorstore:
                raise ValueError("Vector database not initialized")

            # Create retrieval query
            query = f"Learning objective for {competency} competency in {role} role using {archetype} approach"

            # Retrieve relevant templates
            relevant_docs = self.vectorstore.similarity_search(query, k=retrieve_k)

            # Create RAG-enhanced prompt
            prompt_template = ChatPromptTemplate.from_messages([
                ("system", self._get_system_prompt()),
                ("human", self._get_human_prompt())
            ])

            # Prepare context
            template_context = "\n".join([doc.page_content for doc in relevant_docs])

            # Generate objective
            chain = prompt_template | self.llm
            response = chain.invoke({
                "competency": competency,
                "role": role,
                "archetype": archetype,
                "company_name": company_context.company_name,
                "industry": company_context.industry_domain,
                "processes": ", ".join(company_context.business_processes),
                "methods": ", ".join(company_context.methods_used),
                "tools": ", ".join(company_context.tools_technologies),
                "challenges": ", ".join(company_context.specific_challenges),
                "maturity": company_context.se_maturity_level,
                "template_context": template_context
            })

            generated_objective = response.content

            # Assess quality
            quality_assessment = self._assess_objective_quality(
                generated_objective, competency, company_context
            )

            # Determine if objective meets quality threshold
            meets_threshold = quality_assessment.overall_quality >= self.quality_threshold

            result = {
                'objective': generated_objective,
                'quality_assessment': quality_assessment.dict(),
                'meets_threshold': meets_threshold,
                'competency': competency,
                'role': role,
                'archetype': archetype,
                'company_context': company_context.dict(),
                'retrieved_templates': len(relevant_docs),
                'generation_timestamp': datetime.now().isoformat(),
                'rag_sources': [doc.metadata for doc in relevant_docs if hasattr(doc, 'metadata')]
            }

            # Log generation
            logger.info(f"Generated objective for {competency} with quality score: {quality_assessment.overall_quality:.2f}")

            return result

        except Exception as e:
            logger.error(f"Error generating customized objective: {e}")
            return self._get_fallback_objective(competency, role, archetype)

    def _get_system_prompt(self) -> str:
        """Get system prompt for RAG-LLM generation"""
        return """You are an expert Systems Engineering learning objective designer specializing in creating company-specific, SMART learning objectives.

Your task is to generate high-quality learning objectives that:
1. Follow SMART criteria (Specific, Measurable, Achievable, Relevant, Time-bound)
2. Are customized for the specific company context (processes, methods, tools)
3. Align with INCOSE SE competency framework
4. Match the qualification archetype strategy
5. Are practical and actionable for the target role

Use the provided template context as inspiration but create objectives specifically tailored to the company's PMT (Processes, Methods, Tools) context.

Generate objectives that are:
- Specific to the company's domain and tools
- Measurable with clear success criteria
- Achievable within the role's scope
- Relevant to company challenges
- Time-bound with realistic durations"""

    def _get_human_prompt(self) -> str:
        """Get human prompt template for RAG-LLM generation"""
        return """Create a company-specific learning objective for:

Competency: {competency}
Role: {role}
Qualification Archetype: {archetype}

Company Context:
- Company: {company_name}
- Industry: {industry}
- Key Processes: {processes}
- Methods Used: {methods}
- Tools/Technologies: {tools}
- Current Challenges: {challenges}
- SE Maturity Level: {maturity}

Template Context for Inspiration:
{template_context}

Generate ONE specific, actionable learning objective that:
1. Uses company-specific processes, methods, and tools
2. Addresses the company's challenges
3. Fits the qualification archetype strategy
4. Is measurable and time-bound
5. Appropriate for the target role

Format: "At the end of [timeframe], participants will be able to [specific measurable outcome] by [method/approach] so that [business benefit]."

Learning Objective:"""

    def _assess_objective_quality(
        self,
        objective: str,
        competency: str,
        company_context: CompanyContext
    ) -> LearningObjectiveQuality:
        """Assess the quality of generated learning objective using SMART criteria"""

        # Create quality assessment prompt
        assessment_prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a learning objective quality assessor. Evaluate the provided learning objective against SMART criteria and company alignment.

Provide scores from 0.0 to 1.0 for each criterion:
- Specific: Is it clear and well-defined?
- Measurable: Can success be measured/observed?
- Achievable: Is it realistic for the target audience?
- Relevant: Is it relevant to the competency and company?
- Time-bound: Does it include timeframe?
- Company alignment: How well does it use company-specific context?
- INCOSE compliance: Does it align with SE competency framework?

Respond ONLY with a JSON object containing the scores."""),
            ("human", """Learning Objective: {objective}
Competency: {competency}
Company: {company_name}
Industry: {industry}

Assess this objective and return JSON with scores:
{{"specific": 0.0-1.0, "measurable": 0.0-1.0, "achievable": 0.0-1.0, "relevant": 0.0-1.0, "time_bound": 0.0-1.0, "company_alignment": 0.0-1.0, "incose_compliance": 0.0-1.0}}""")
        ])

        try:
            chain = assessment_prompt | self.llm
            response = chain.invoke({
                "objective": objective,
                "competency": competency,
                "company_name": company_context.company_name,
                "industry": company_context.industry_domain
            })

            # Parse JSON response
            scores = json.loads(response.content)

            # Calculate SMART score (average of SMART criteria)
            smart_score = (
                scores["specific"] + scores["measurable"] +
                scores["achievable"] + scores["relevant"] + scores["time_bound"]
            ) / 5

            # Calculate overall quality (weighted average)
            overall_quality = (
                smart_score * 0.6 +  # SMART criteria weight
                scores["company_alignment"] * 0.25 +  # Company alignment weight
                scores["incose_compliance"] * 0.15  # INCOSE compliance weight
            )

            return LearningObjectiveQuality(
                smart_score=smart_score,
                specific=scores["specific"],
                measurable=scores["measurable"],
                achievable=scores["achievable"],
                relevant=scores["relevant"],
                time_bound=scores["time_bound"],
                company_alignment=scores["company_alignment"],
                incose_compliance=scores["incose_compliance"],
                overall_quality=overall_quality
            )

        except Exception as e:
            logger.error(f"Error assessing objective quality: {e}")
            # Return default moderate scores if assessment fails
            return LearningObjectiveQuality(
                smart_score=0.7,
                specific=0.7,
                measurable=0.7,
                achievable=0.7,
                relevant=0.7,
                time_bound=0.7,
                company_alignment=0.6,
                incose_compliance=0.8,
                overall_quality=0.7
            )

    def _get_fallback_objective(self, competency: str, role: str, archetype: str) -> Dict[str, Any]:
        """Provide fallback objective when generation fails"""
        fallback_text = f"Participants will demonstrate {competency.lower()} competency appropriate for {role} role following {archetype} approach."

        return {
            'objective': fallback_text,
            'quality_assessment': {
                'overall_quality': 0.6,
                'smart_score': 0.6,
                'company_alignment': 0.3,
                'is_fallback': True
            },
            'meets_threshold': False,
            'competency': competency,
            'role': role,
            'archetype': archetype,
            'generation_timestamp': datetime.now().isoformat(),
            'error': 'Used fallback due to generation failure'
        }

    def batch_generate_objectives(
        self,
        competency_role_pairs: List[Tuple[str, str]],
        archetype: str,
        company_context: CompanyContext
    ) -> List[Dict[str, Any]]:
        """Generate multiple learning objectives in batch"""
        results = []

        for competency, role in competency_role_pairs:
            result = self.generate_customized_objective(
                competency, role, archetype, company_context
            )
            results.append(result)

        return results

    def get_generation_statistics(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Get statistics about generated objectives"""
        if not results:
            return {}

        quality_scores = [r['quality_assessment']['overall_quality'] for r in results]
        meets_threshold_count = sum(1 for r in results if r['meets_threshold'])

        return {
            'total_generated': len(results),
            'meets_threshold': meets_threshold_count,
            'threshold_rate': meets_threshold_count / len(results),
            'average_quality': sum(quality_scores) / len(quality_scores),
            'min_quality': min(quality_scores),
            'max_quality': max(quality_scores),
            'quality_threshold': self.quality_threshold
        }