"""
Setup script for RAG vector database
Processes learning objective templates from SE foundation data
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
import logging
from datetime import datetime
from rag_pipeline import RAGLearningObjectiveGenerator, CompanyContext

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def setup_vector_database():
    """Setup ChromaDB with learning objective templates"""
    logger.info("Initializing RAG Learning Objective Generator...")

    # Initialize the RAG pipeline (uses default absolute path from PROJECT_ROOT)
    rag_generator = RAGLearningObjectiveGenerator()

    # Setup vector database with force rebuild
    logger.info("Setting up vector database...")
    success = rag_generator.setup_vector_database(force_rebuild=True)

    if success:
        logger.info("Vector database setup completed successfully!")
        return rag_generator
    else:
        logger.error("Vector database setup failed!")
        return None

def test_objective_generation(rag_generator):
    """Test learning objective generation"""
    logger.info("Testing learning objective generation...")

    # Create test company context
    test_company = CompanyContext(
        company_name="TestCorp Automotive",
        industry_domain="Automotive",
        business_processes=["Requirements Engineering", "System Integration", "Testing"],
        methods_used=["Agile", "V-Model", "Systems Engineering"],
        tools_technologies=["DOORS", "MATLAB/Simulink", "JIRA"],
        specific_challenges=["Autonomous vehicle development", "Safety certification"],
        se_maturity_level="developing",
        organizational_context="Large OEM with multiple engineering teams"
    )

    # Test generation
    result = rag_generator.generate_customized_objective(
        competency="Systemic thinking",
        role="System engineer",
        archetype="Needs-based, project-oriented training",
        company_context=test_company
    )

    logger.info("Generated learning objective:")
    logger.info(f"Objective: {result['objective']}")
    logger.info(f"Quality Score: {result['quality_assessment']['overall_quality']:.2f}")
    logger.info(f"Meets Threshold: {result['meets_threshold']}")

    return result

def validate_database_content(rag_generator):
    """Validate that templates were loaded correctly"""
    logger.info("Validating vector database content...")

    if not rag_generator.vectorstore:
        logger.error("Vector store not initialized!")
        return False

    # Test similarity search
    test_query = "systemic thinking competency"
    docs = rag_generator.vectorstore.similarity_search(test_query, k=3)

    logger.info(f"Found {len(docs)} relevant templates for test query")
    for i, doc in enumerate(docs):
        logger.info(f"Template {i+1}: {doc.page_content[:100]}...")

    return len(docs) > 0

def main():
    """Main setup function"""
    logger.info("Starting RAG vector database setup...")

    # Setup vector database
    rag_generator = setup_vector_database()
    if not rag_generator:
        return False

    # Validate content
    if not validate_database_content(rag_generator):
        logger.error("Database validation failed!")
        return False

    # Test objective generation
    test_result = test_objective_generation(rag_generator)

    logger.info("RAG vector database setup completed successfully!")
    logger.info(f"Database location: {rag_generator.vector_db_path}")

    # Save setup report
    setup_report = {
        'setup_timestamp': datetime.now().isoformat(),
        'database_path': rag_generator.vector_db_path,
        'quality_threshold': rag_generator.quality_threshold,
        'test_generation_result': {
            'objective': test_result['objective'],
            'quality_score': test_result['quality_assessment']['overall_quality'],
            'meets_threshold': test_result['meets_threshold']
        },
        'status': 'success'
    }

    with open('rag_setup_report.json', 'w') as f:
        json.dump(setup_report, f, indent=2)

    logger.info("Setup report saved: rag_setup_report.json")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)