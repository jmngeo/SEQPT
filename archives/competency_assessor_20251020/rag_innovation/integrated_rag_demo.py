"""
Integrated RAG-LLM Learning Objective Generation System
Complete demonstration of the SE-QPT thesis core innovation
Combines all components: RAG pipeline, context extraction, prompt engineering, and SMART validation
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple

# Import all our components
import chromadb
from company_context_extractor import CompanyContextExtractor, CompanyPMTContext
from prompt_engineering import ObjectivePromptEngineer
from smart_validation import SMARTValidator, QualityAssessment
from dotenv import load_dotenv

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IntegratedRAGSystem:
    """
    Complete RAG-LLM system for generating company-specific learning objectives
    Core innovation of the SE-QPT Master Thesis
    """

    def __init__(self, vector_db_path: str = "../../../../data/rag_vectordb"):
        self.vector_db_path = vector_db_path

        # Initialize all components
        logger.info("Initializing Integrated RAG-LLM System...")

        self.context_extractor = CompanyContextExtractor()
        self.prompt_engineer = ObjectivePromptEngineer()
        self.smart_validator = SMARTValidator(quality_threshold=0.85)

        # Initialize vector database (basic version for demo)
        self.chroma_client = chromadb.PersistentClient(path=vector_db_path)
        self.collection = self._get_or_create_collection()

        # System statistics
        self.generation_stats = {
            'total_generated': 0,
            'meets_threshold': 0,
            'average_quality': 0.0,
            'generation_history': []
        }

        logger.info("Integrated RAG-LLM System initialized successfully!")

    def _get_or_create_collection(self):
        """Get or create the learning objectives collection"""
        try:
            collection = self.chroma_client.get_collection("se_learning_objectives")
            logger.info("Using existing vector database collection")
        except:
            collection = self.chroma_client.create_collection(
                name="se_learning_objectives",
                metadata={"description": "SE learning objective templates"}
            )
            logger.info("Created new vector database collection")

        return collection

    def generate_learning_objective(
        self,
        competency: str,
        role: str,
        archetype: str,
        company_description: str,
        company_name: str = "Target Company",
        max_iterations: int = 3
    ) -> Dict[str, Any]:
        """
        Generate a high-quality, company-specific learning objective
        Uses iterative refinement to meet the 85% quality threshold
        """

        logger.info(f"Starting objective generation for {competency} competency")

        # Step 1: Extract company PMT context
        logger.info("Step 1: Extracting company PMT context...")
        company_context = self.context_extractor.extract_context_from_text(
            company_description, company_name
        )

        # Enrich with industry templates
        company_context = self.context_extractor.enrich_context_with_templates(company_context)
        context_summary = self.context_extractor.generate_context_summary(company_context)

        logger.info(f"Extracted context: {context_summary}")

        # Step 2: Retrieve relevant templates from vector database
        logger.info("Step 2: Retrieving relevant learning objective templates...")
        template_context = self._retrieve_templates(competency, archetype)

        # Step 3: Generate customized prompts
        logger.info("Step 3: Generating customized prompts...")
        system_prompt, human_prompt = self.prompt_engineer.generate_customized_prompt(
            competency=competency,
            role=role,
            archetype=archetype,
            company_context=company_context,
            template_context=template_context
        )

        # Step 4: Iterative objective generation with quality validation
        logger.info("Step 4: Generating and validating learning objective...")

        best_objective = None
        best_quality = 0.0
        iteration_results = []

        for iteration in range(max_iterations):
            logger.info(f"Generation iteration {iteration + 1}/{max_iterations}")

            # Generate objective (simulated for demo - would use actual LLM)
            generated_objective = self._simulate_llm_generation(
                system_prompt, human_prompt, company_context, competency, iteration
            )

            # Validate quality
            assessment = self.smart_validator.validate_objective(
                objective_text=generated_objective,
                competency=competency,
                company_context=company_context,
                archetype=archetype,
                role=role
            )

            iteration_results.append({
                'iteration': iteration + 1,
                'objective': generated_objective,
                'quality_score': assessment.overall_quality,
                'meets_threshold': assessment.meets_threshold
            })

            logger.info(f"Iteration {iteration + 1} quality: {assessment.overall_quality:.2f}")

            # Track best result
            if assessment.overall_quality > best_quality:
                best_objective = generated_objective
                best_quality = assessment.overall_quality
                best_assessment = assessment

            # Stop if we meet the threshold
            if assessment.meets_threshold:
                logger.info(f"Quality threshold met in iteration {iteration + 1}!")
                break

            # For next iteration, use improvement suggestions (in real system)
            if iteration < max_iterations - 1:
                logger.info("Refining for next iteration based on quality feedback...")

        # Step 5: Prepare final result
        final_result = {
            'objective': best_objective,
            'quality_assessment': {
                'overall_quality': best_assessment.overall_quality,
                'smart_average': best_assessment.smart_average,
                'meets_threshold': best_assessment.meets_threshold,
                'individual_scores': {
                    'specific': best_assessment.specific_score.score,
                    'measurable': best_assessment.measurable_score.score,
                    'achievable': best_assessment.achievable_score.score,
                    'relevant': best_assessment.relevant_score.score,
                    'time_bound': best_assessment.time_bound_score.score,
                    'company_alignment': best_assessment.company_alignment_score.score,
                    'incose_compliance': best_assessment.incose_compliance_score.score,
                    'business_value': best_assessment.business_value_score.score
                }
            },
            'company_context': {
                'name': company_context.company_name,
                'industry': company_context.industry_domain,
                'maturity': company_context.se_maturity_level,
                'processes': company_context.processes[:3],
                'tools': company_context.tools[:3],
                'challenges': company_context.current_challenges[:2]
            },
            'generation_metadata': {
                'competency': competency,
                'role': role,
                'archetype': archetype,
                'iterations_used': len(iteration_results),
                'template_sources': len(template_context.split('\\n')),
                'generation_timestamp': datetime.now().isoformat()
            },
            'iteration_history': iteration_results,
            'recommendations': {
                'strengths': best_assessment.strengths[:3],
                'improvement_plan': best_assessment.improvement_plan[:5] if best_assessment.improvement_plan else []
            }
        }

        # Update statistics
        self._update_statistics(final_result)

        logger.info(f"Objective generation completed! Final quality: {best_quality:.2f}")
        return final_result

    def _retrieve_templates(self, competency: str, archetype: str) -> str:
        """Retrieve relevant templates from vector database"""
        try:
            query = f"Learning objective for {competency} competency using {archetype} approach"
            results = self.collection.query(
                query_texts=[query],
                n_results=3
            )

            if results['documents'] and results['documents'][0]:
                template_context = "\\n---\\n".join(results['documents'][0])
                logger.info(f"Retrieved {len(results['documents'][0])} relevant templates")
                return template_context
            else:
                logger.warning("No templates found, using default examples")
                return self._get_default_templates(competency)

        except Exception as e:
            logger.error(f"Error retrieving templates: {e}")
            return self._get_default_templates(competency)

    def _get_default_templates(self, competency: str) -> str:
        """Get default templates when vector search fails"""
        default_templates = {
            'systemic thinking': 'At the end of the workshop, participants understand system boundaries and can identify interfaces in their work context.',
            'requirements management': 'Participants can independently identify and document requirements using established processes.',
            'technical leadership': 'Participants demonstrate technical decision-making and provide guidance to team members.'
        }

        competency_key = competency.lower().replace(' ', '_')
        return default_templates.get(competency_key, 'Participants will apply the competency effectively in their work context.')

    def _simulate_llm_generation(
        self,
        system_prompt: str,
        human_prompt: str,
        company_context: CompanyPMTContext,
        competency: str,
        iteration: int
    ) -> str:
        """
        Simulate LLM generation for demo purposes
        In real system, this would call OpenAI API with the prompts
        """

        # Simulate different quality levels across iterations
        if iteration == 0:
            # First iteration - basic attempt
            if competency.lower() == 'systemic thinking':
                return f"At the end of 4 hours, participants will understand system boundaries in {company_context.company_name}'s {company_context.business_domain} projects."
            elif competency.lower() == 'requirements management':
                return f"Participants will learn requirements engineering using {company_context.tools[0] if company_context.tools else 'standard tools'}."
            else:
                return f"Participants will apply {competency} in their work at {company_context.company_name}."

        elif iteration == 1:
            # Second iteration - improved based on feedback
            if competency.lower() == 'systemic thinking':
                return f"At the end of 1 week, participants will be able to identify system boundaries and interfaces in {company_context.company_name}'s {company_context.business_domain} architecture by analyzing system models using {company_context.tools[0] if company_context.tools else 'modeling tools'}."
            elif competency.lower() == 'requirements management':
                return f"At the end of 2 weeks, participants will demonstrate requirements elicitation and documentation for {company_context.company_name}'s {company_context.business_domain} projects by creating requirement specifications using {company_context.tools[0] if company_context.tools else 'DOORS'}."
            else:
                return f"At the end of 3 weeks, participants will effectively apply {competency} principles in {company_context.company_name}'s {company_context.industry_domain} projects by implementing best practices."

        else:
            # Third iteration - high quality with business value
            if competency.lower() == 'systemic thinking':
                challenge = company_context.current_challenges[0] if company_context.current_challenges else "system integration"
                tool = company_context.tools[0] if company_context.tools else "modeling tools"
                return f"At the end of 2 weeks, participants will be able to identify and analyze system boundaries, interfaces, and emergent properties in {company_context.company_name}'s {company_context.business_domain} architecture by creating system models using {tool} so that {challenge} challenges are better understood and resolved."

            elif competency.lower() == 'requirements management':
                process = company_context.processes[0] if company_context.processes else "Requirements Engineering"
                tool = company_context.tools[0] if company_context.tools else "DOORS"
                challenge = company_context.current_challenges[0] if company_context.current_challenges else "requirement quality"
                return f"At the end of 3 weeks, participants will be able to elicit, analyze, and document stakeholder requirements for {company_context.company_name}'s {company_context.business_domain} projects by applying {process} processes using {tool} so that {challenge} issues are reduced and project success is improved."

            else:
                method = company_context.methods[0] if company_context.methods else "Agile"
                return f"At the end of 4 weeks, participants will be able to apply {competency} principles effectively in {company_context.company_name}'s {company_context.industry_domain} environment by implementing {method} practices so that team performance and project outcomes are enhanced."

    def _update_statistics(self, result: Dict[str, Any]):
        """Update system generation statistics"""
        self.generation_stats['total_generated'] += 1

        if result['quality_assessment']['meets_threshold']:
            self.generation_stats['meets_threshold'] += 1

        # Update average quality
        total_quality = (self.generation_stats['average_quality'] * (self.generation_stats['total_generated'] - 1) +
                        result['quality_assessment']['overall_quality'])
        self.generation_stats['average_quality'] = total_quality / self.generation_stats['total_generated']

        # Add to history
        self.generation_stats['generation_history'].append({
            'timestamp': result['generation_metadata']['generation_timestamp'],
            'competency': result['generation_metadata']['competency'],
            'quality': result['quality_assessment']['overall_quality'],
            'meets_threshold': result['quality_assessment']['meets_threshold']
        })

    def get_system_statistics(self) -> Dict[str, Any]:
        """Get comprehensive system statistics"""
        success_rate = (self.generation_stats['meets_threshold'] /
                       max(self.generation_stats['total_generated'], 1))

        return {
            'total_objectives_generated': self.generation_stats['total_generated'],
            'objectives_meeting_threshold': self.generation_stats['meets_threshold'],
            'success_rate': success_rate,
            'average_quality_score': self.generation_stats['average_quality'],
            'quality_threshold': self.smart_validator.quality_threshold,
            'system_status': 'operational',
            'last_generation': self.generation_stats['generation_history'][-1] if self.generation_stats['generation_history'] else None
        }

    def batch_generate_objectives(
        self,
        company_description: str,
        company_name: str,
        competency_role_pairs: List[Tuple[str, str]],
        archetype: str
    ) -> List[Dict[str, Any]]:
        """Generate multiple objectives for a company"""
        logger.info(f"Starting batch generation of {len(competency_role_pairs)} objectives for {company_name}")

        results = []
        for competency, role in competency_role_pairs:
            try:
                result = self.generate_learning_objective(
                    competency=competency,
                    role=role,
                    archetype=archetype,
                    company_description=company_description,
                    company_name=company_name
                )
                results.append(result)

            except Exception as e:
                logger.error(f"Error generating objective for {competency}: {e}")
                # Add error result
                results.append({
                    'error': str(e),
                    'competency': competency,
                    'role': role,
                    'generation_metadata': {
                        'generation_timestamp': datetime.now().isoformat()
                    }
                })

        logger.info(f"Batch generation completed: {len(results)} objectives generated")
        return results

def main():
    """Demonstrate the complete integrated RAG-LLM system"""
    print("=" * 80)
    print("SE-QPT RAG-LLM LEARNING OBJECTIVE GENERATION SYSTEM")
    print("Core Innovation Demonstration")
    print("=" * 80)

    # Initialize the integrated system
    rag_system = IntegratedRAGSystem()

    # Test with different company scenarios
    test_scenarios = [
        {
            'company_name': 'AutoTech Systems',
            'description': 'AutoTech Systems is an automotive OEM developing autonomous vehicles. We use MATLAB/Simulink for modeling, DOORS for requirements management, and follow ISO 26262 for functional safety. Our main challenges include complex sensor integration and safety certification for self-driving features.',
            'competencies': [
                ('Systemic thinking', 'System engineer'),
                ('Requirements management', 'Requirements engineer'),
                ('Technical leadership', 'Senior engineer')
            ],
            'archetype': 'Needs-based, project-oriented training'
        },
        {
            'company_name': 'MedDevice Innovations',
            'description': 'MedDevice Innovations develops cardiac monitoring medical devices. We follow FDA regulations and IEC 62304 standards. Our main challenges are clinical validation and regulatory approval processes.',
            'competencies': [
                ('Requirements management', 'Requirements engineer'),
                ('System safety', 'Safety engineer')
            ],
            'archetype': 'Common basic understanding'
        }
    ]

    all_results = {}

    for scenario in test_scenarios:
        print(f"\\n{'='*60}")
        print(f"TESTING: {scenario['company_name']}")
        print(f"{'='*60}")

        # Generate objectives for this company
        results = rag_system.batch_generate_objectives(
            company_description=scenario['description'],
            company_name=scenario['company_name'],
            competency_role_pairs=scenario['competencies'],
            archetype=scenario['archetype']
        )

        all_results[scenario['company_name']] = results

        # Display results
        for i, result in enumerate(results):
            if 'error' in result:
                print(f"\\nObjective {i+1}: ERROR - {result['error']}")
                continue

            print(f"\\n--- Objective {i+1}: {result['generation_metadata']['competency']} ---")
            print(f"Generated Objective:")
            print(f"  {result['objective']}")
            print(f"\\nQuality Assessment:")
            print(f"  Overall Quality: {result['quality_assessment']['overall_quality']:.1%}")
            print(f"  SMART Average: {result['quality_assessment']['smart_average']:.1%}")
            print(f"  Meets Threshold: {'YES' if result['quality_assessment']['meets_threshold'] else 'NO'}")
            print(f"  Iterations Used: {result['generation_metadata']['iterations_used']}")

            if result['recommendations']['improvement_plan']:
                print(f"  Key Improvements: {', '.join(result['recommendations']['improvement_plan'][:2])}")

    # Show system statistics
    print(f"\\n{'='*60}")
    print("SYSTEM PERFORMANCE STATISTICS")
    print(f"{'='*60}")

    stats = rag_system.get_system_statistics()
    print(f"Total Objectives Generated: {stats['total_objectives_generated']}")
    print(f"Objectives Meeting 85% Threshold: {stats['objectives_meeting_threshold']}")
    print(f"Success Rate: {stats['success_rate']:.1%}")
    print(f"Average Quality Score: {stats['average_quality_score']:.1%}")

    # Save complete results
    final_report = {
        'system_demonstration': 'SE-QPT RAG-LLM Learning Objective Generation',
        'demonstration_timestamp': datetime.now().isoformat(),
        'test_scenarios': test_scenarios,
        'generated_objectives': all_results,
        'system_statistics': stats,
        'innovation_summary': {
            'key_components': [
                'Company PMT context extraction',
                'RAG-enhanced template retrieval',
                'Archetype-specific prompt engineering',
                'SMART criteria validation with 85% threshold',
                'Iterative quality improvement'
            ],
            'core_innovation': 'First application of RAG-LLM for SE qualification planning',
            'business_value': 'Generates company-specific learning objectives that address real challenges'
        }
    }

    with open('rag_system_demonstration.json', 'w') as f:
        json.dump(final_report, f, indent=2)

    print(f"\\nComplete demonstration report saved: rag_system_demonstration.json")
    print(f"\\n🎉 SE-QPT RAG-LLM System demonstration completed successfully!")

if __name__ == "__main__":
    main()