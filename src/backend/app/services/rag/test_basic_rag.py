"""
Basic RAG test without complex dependencies
Tests vector database setup and retrieval
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
import logging
from datetime import datetime
import chromadb
from dotenv import load_dotenv

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BasicRAGTester:
    """Basic RAG functionality tester without LangChain dependencies"""

    def __init__(self, vector_db_path: str = "../../../../data/rag_vectordb"):
        self.vector_db_path = vector_db_path
        self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        logger.info("Basic RAG tester initialized")

    def setup_vector_database(self, force_rebuild: bool = False):
        """Setup ChromaDB with learning objective templates"""
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

            return collection

        except Exception as e:
            logger.error(f"Error setting up vector database: {e}")
            return None

    def _load_learning_objective_templates(self):
        """Load learning objective templates from processed data"""
        templates = []

        try:
            # Load from SE foundation data
            with open('../../../data/processed/se_foundation_data.json', 'r') as f:
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

    def _create_sample_templates(self):
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

    def _template_to_text(self, template):
        """Convert template to searchable text"""
        return f"""
        Competency: {template.get('competency', '')}
        Learning Objective: {template.get('objective_text', '')}
        Level: {template.get('level', '')}
        Archetype: {template.get('archetype', '')}
        Format: {template.get('format', '')}
        """

    def test_similarity_search(self, collection):
        """Test similarity search functionality"""
        if not collection:
            logger.error("No collection provided for testing")
            return False

        # Test search
        test_query = "systemic thinking competency"
        results = collection.query(
            query_texts=[test_query],
            n_results=3
        )

        logger.info(f"Search query: '{test_query}'")
        logger.info(f"Found {len(results['documents'][0])} results:")

        for i, doc in enumerate(results['documents'][0]):
            logger.info(f"Result {i+1}: {doc[:100]}...")

        return len(results['documents'][0]) > 0

def main():
    """Main test function"""
    logger.info("Starting basic RAG test...")

    # Initialize tester
    tester = BasicRAGTester()

    # Setup vector database
    collection = tester.setup_vector_database(force_rebuild=True)
    if not collection:
        logger.error("Failed to setup vector database")
        return False

    # Test similarity search
    success = tester.test_similarity_search(collection)

    if success:
        logger.info("Basic RAG test completed successfully!")

        # Save test report
        test_report = {
            'test_timestamp': datetime.now().isoformat(),
            'database_path': tester.vector_db_path,
            'status': 'success',
            'message': 'Basic RAG functionality working'
        }

        with open('basic_rag_test_report.json', 'w') as f:
            json.dump(test_report, f, indent=2)

        logger.info("Test report saved: basic_rag_test_report.json")
        return True
    else:
        logger.error("Basic RAG test failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)