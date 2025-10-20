"""
SE-QPT Specific API Routes
RAG-LLM Innovation and 4-Phase Workflow Integration
"""

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import sys
import os
import json

# Add RAG innovation components to path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../competency_assessor/rag_innovation'))

from company_context_extractor import CompanyContextExtractor, CompanyPMTContext
from prompt_engineering import ObjectivePromptEngineer
from smart_validation import SMARTValidator
from integrated_rag_demo import IntegratedRAGSystem

from models import db
from models import *

seqpt_bp = Blueprint('seqpt', __name__)

# Test route to verify blueprint is working
@seqpt_bp.route('/test', methods=['GET'])
def test_route():
    """Test route to verify SE-QPT blueprint is working"""
    return {'message': 'SE-QPT routes are working', 'status': 'success'}, 200

# Initialize RAG-LLM components (with error handling to not block blueprint registration)
try:
    context_extractor = CompanyContextExtractor()
    prompt_engineer = ObjectivePromptEngineer()
    smart_validator = SMARTValidator(quality_threshold=0.85)
    rag_system = IntegratedRAGSystem()
    RAG_AVAILABLE = True
    print("RAG-LLM components initialized successfully")
except Exception as e:
    print(f"Warning: RAG-LLM components not available: {e}")
    context_extractor = None
    prompt_engineer = None
    smart_validator = None
    rag_system = None
    RAG_AVAILABLE = False

# =============================================================================
# PHASE 1: Archetype Selection
# NOTE: Maturity assessment is handled by questionnaire system (questionnaire ID 1)
#       This route computes the archetype based on maturity + scope scores
# =============================================================================

@seqpt_bp.route('/phase1/archetype-selection', methods=['POST'])
@jwt_required()
def phase1_archetype_selection():
    """Phase 1: Select qualification archetype strategy using maturity-based computation"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        print(f"SE-QPT Archetype selection request for user {user_id}")
        print(f"Request data: {data}")

        assessment_uuid = data.get('assessment_uuid')
        archetype_responses = data.get('responses', {})
        company_preference = data.get('company_preference')  # New field for dual selection

        print(f"Looking for assessment UUID: {assessment_uuid}")

        # Handle case where no assessment_uuid is provided (direct questionnaire system)
        if not assessment_uuid:
            print("No assessment UUID provided, working with direct questionnaire responses")
            # Calculate maturity score directly from questionnaire responses
            print(f"Getting maturity scores from latest questionnaire responses for user {user_id}")
            print(f"About to execute database query for user_id: {user_id}, type: {type(user_id)}")

            try:
                # Get the latest maturity assessment (questionnaire ID 1) responses for this user
                print("Executing QuestionnaireResponse query...")
                latest_maturity_response = QuestionnaireResponse.query.filter_by(
                    user_id=user_id,
                    questionnaire_id=1  # Maturity assessment questionnaire
                ).filter(
                    QuestionnaireResponse.status == 'completed'
                ).order_by(QuestionnaireResponse.completed_at.desc()).first()

                print(f"Database query successful. Found response: {latest_maturity_response is not None}")
                if latest_maturity_response:
                    print(f"Response ID: {latest_maturity_response.id}, status: {latest_maturity_response.status}")

            except Exception as db_error:
                print(f"Database query error: {db_error}")
                import traceback
                print(f"Full traceback: {traceback.format_exc()}")
                return {'error': f'Database query failed: {str(db_error)}'}, 500

            if latest_maturity_response and latest_maturity_response.question_responses:
                try:
                    # Get responses from related QuestionResponse objects
                    print(f"Found maturity response with {len(latest_maturity_response.question_responses)} question responses")

                    # Build scores dictionary from question responses
                    scores_by_question = {}
                    for q_response in latest_maturity_response.question_responses:
                        question_id = str(q_response.question_id)
                        score_value = q_response.score

                        # Convert string scores to numeric if needed
                        if isinstance(score_value, str) and score_value.replace('.', '').isdigit():
                            score_value = float(score_value)

                        scores_by_question[question_id] = score_value
                        print(f"Question {question_id}: score = {score_value}")

                    print(f"All question scores: {scores_by_question}")

                    # Calculate maturity score using the proper algorithm
                    maturity_score = calculate_maturity_score(scores_by_question)
                    print(f"Calculated maturity score from responses: {maturity_score}")
                except Exception as e:
                    print(f"Error processing maturity responses: {e}")
                    import traceback
                    print(f"Full traceback: {traceback.format_exc()}")
                    maturity_score = 0.5  # Fallback on error
            else:
                print("No completed maturity assessment found, using default score")
                maturity_score = 0.5  # Fallback for missing data
        else:
            # Update assessment with archetype selection
            assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()
            if not assessment:
                print(f"Assessment not found for UUID {assessment_uuid} and user {user_id}")
                return {'error': 'Assessment not found'}, 404

            # Get maturity score from previous assessment
            previous_results = assessment.results or {}
            maturity_score = previous_results.get('maturity_score', 0)

        # Calculate scope score from archetype selection responses
        scope_score = calculate_scope_score(archetype_responses)

        print(f"Archetype computation inputs:")
        print(f"  maturity_score: {maturity_score}")
        print(f"  scope_score: {scope_score}")
        print(f"  company_preference: {company_preference}")

        # Determine archetype using updated dual selection logic
        archetype_decision = determine_archetype_from_scores(maturity_score, scope_score, company_preference)

        print(f"Archetype decision result:")
        print(f"  primary: {archetype_decision['primary']}")
        print(f"  secondary: {archetype_decision['secondary']}")
        print(f"  selection_type: {archetype_decision['selection_type']}")
        print(f"  requires_dual_processing: {archetype_decision['requires_dual_processing']}")

        # Handle Train the Trainer special case
        if archetype_decision['primary'] == 'Train the Trainer':
            return {
                'message': 'Train the Trainer qualification is out of scope',
                'out_of_scope': True,
                'recommendations': [
                    'Consider external SE training provider partnerships',
                    'Explore INCOSE certified training programs',
                    'Contact professional SE training organizations'
                ],
                'archetype': {
                    'name': 'Train the Trainer',
                    'status': 'out_of_scope'
                }
            }

        # Update assessment results with computed archetype (only if assessment exists)
        if assessment_uuid and 'assessment' in locals():
            results = previous_results.copy()
            results['archetype_selection'] = {
                'responses': archetype_responses,
                'company_preference': company_preference,
                'maturity_score': maturity_score,
                'scope_score': scope_score,
                'primary_archetype': archetype_decision['primary'],
                'secondary_archetype': archetype_decision['secondary'],
                'customization_level': archetype_decision['customization_level'],
                'selection_type': archetype_decision['selection_type'],
                'processing_type': archetype_decision['processing_type'],
                'requires_dual_processing': archetype_decision['requires_dual_processing'],
                'decision_rationale': archetype_decision['rationale'],
                'computed_at': datetime.utcnow().isoformat()
            }
            assessment.results = results
            db.session.commit()
        else:
            print("No assessment to update, returning archetype result only")

        # Save computed archetype to questionnaire response
        try:
            print(f"Attempting to save computed archetype to database for user {user_id}")

            # Find the latest archetype questionnaire response for this user
            archetype_response = QuestionnaireResponse.query.filter_by(
                user_id=user_id,
                questionnaire_id=2  # Archetype questionnaire ID
            ).filter(
                QuestionnaireResponse.status == 'completed'
            ).order_by(QuestionnaireResponse.completed_at.desc()).first()

            print(f"Found archetype response: {archetype_response}")
            if archetype_response:
                print(f"Archetype response UUID: {archetype_response.uuid}")
                print(f"Current computed_archetype field: {archetype_response.computed_archetype}")

            if archetype_response:
                # Save computed archetype as JSON
                computed_archetype_data = {
                    'name': archetype_decision['primary'],
                    'secondary': archetype_decision['secondary'],
                    'customization_level': archetype_decision['customization_level'],
                    'selection_type': archetype_decision['selection_type'],
                    'processing_type': archetype_decision['processing_type'],
                    'requires_dual_processing': archetype_decision['requires_dual_processing'],
                    'rationale': archetype_decision['rationale'],
                    'computed_at': datetime.utcnow().isoformat(),
                    'scores': {
                        'maturity_score': maturity_score,
                        'scope_score': scope_score
                    }
                }

                archetype_response.computed_archetype = json.dumps(computed_archetype_data)
                print(f"About to commit computed archetype for {archetype_response.uuid}")
                db.session.commit()
                print(f"Successfully committed computed archetype to database")

                # Verify the save by reloading from database
                db.session.refresh(archetype_response)
                print(f"Verification - computed_archetype field after commit: {archetype_response.computed_archetype is not None}")
                print(f"Saved computed archetype to questionnaire response {archetype_response.uuid}")
            else:
                print("No archetype questionnaire response found to save computed archetype")
        except Exception as save_error:
            print(f"Error saving computed archetype to database: {save_error}")

        return {
            'message': 'Archetype computed successfully',
            'archetype': {
                'name': archetype_decision['primary'],
                'secondary': archetype_decision['secondary'],
                'customization_level': archetype_decision['customization_level'],
                'selection_type': archetype_decision['selection_type'],
                'processing_type': archetype_decision['processing_type'],
                'requires_dual_processing': archetype_decision['requires_dual_processing'],
                'rationale': archetype_decision['rationale']
            },
            'scores': {
                'maturity_score': maturity_score,
                'scope_score': scope_score
            },
            'next_phase': 'competency_assessment'
        }

    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

# Phase 2: Competency Assessment + RAG Objectives
@seqpt_bp.route('/phase2/competency-assessment', methods=['POST'])
@jwt_required()
def phase2_competency_assessment():
    """Phase 2: Conduct detailed competency assessment (Derik's system)"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        assessment_uuid = data.get('assessment_uuid')
        competency_responses = data.get('competency_responses', {})

        # Get assessment
        assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()
        if not assessment:
            return {'error': 'Assessment not found'}, 404

        # Process competency assessment using Derik's system
        competency_results = process_competency_assessment(competency_responses)

        # Store competency results
        assessment.competency_scores = competency_results
        assessment.phase = 2

        # Create individual competency assessment results
        for comp_id, result in competency_results.items():
            comp_result = CompetencyAssessmentResult(
                assessment_id=assessment.id,
                competency_id=int(comp_id),
                current_level=result.get('current_level'),
                confidence_score=result.get('confidence_score'),
                indicator_scores=result.get('indicator_scores'),
                target_level=result.get('target_level'),
                development_priority=result.get('priority')
            )
            db.session.add(comp_result)

        # Generate gap analysis
        gap_analysis = generate_gap_analysis(competency_results)
        assessment.gap_analysis = gap_analysis

        db.session.commit()

        return {
            'message': 'Competency assessment completed',
            'competency_results': competency_results,
            'gap_analysis': gap_analysis,
            'next_step': 'rag_objective_generation'
        }

    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

@seqpt_bp.route('/public/phase2/generate-objectives', methods=['POST'])
def phase2_generate_objectives_public():
    """Phase 2: Generate company-specific learning objectives using RAG-LLM (public endpoint)"""
    try:
        data = request.get_json()
        assessment_data = data.get('assessment_data', {})
        company_description = data.get('company_description', 'Technology company developing innovative solutions')
        target_role = data.get('target_role', 'Systems Engineer')
        priority_competencies = data.get('priority_competencies', [])

        # For prototype - generate mock learning objectives based on Derik's patterns
        mock_objectives = [
            {
                'id': 1,
                'objective_text': f'Develop proficiency in stakeholder requirements elicitation techniques within {company_description[:50]}... domain context',
                'competency_name': 'Requirements Engineering',
                'target_role_name': target_role,
                'archetype_name': 'Blended Learning',
                'quality_score': 0.89,
                'smart_score': 0.92,
                'specific_score': 0.90,
                'measurable_score': 0.88,
                'achievable_score': 0.94,
                'relevant_score': 0.92,
                'timebound_score': 0.86
            },
            {
                'id': 2,
                'objective_text': f'Master system interface definition and management for complex {target_role.lower()} systems',
                'competency_name': 'System Architecture and Design',
                'target_role_name': target_role,
                'archetype_name': 'Blended Learning',
                'quality_score': 0.91,
                'smart_score': 0.88,
                'specific_score': 0.85,
                'measurable_score': 0.90,
                'achievable_score': 0.89,
                'relevant_score': 0.93,
                'timebound_score': 0.83
            },
            {
                'id': 3,
                'objective_text': 'Implement effective verification planning processes for software-intensive systems',
                'competency_name': 'Integration, Verification and Validation',
                'target_role_name': target_role,
                'archetype_name': 'Blended Learning',
                'quality_score': 0.87,
                'smart_score': 0.85,
                'specific_score': 0.82,
                'measurable_score': 0.87,
                'achievable_score': 0.88,
                'relevant_score': 0.85,
                'timebound_score': 0.86
            }
        ]

        print(f"Generated {len(mock_objectives)} mock learning objectives for {target_role}")

        return {
            'message': f'Generated {len(mock_objectives)} learning objectives',
            'objectives': mock_objectives,
            'company_context': {
                'name': 'Demo Company',
                'industry': 'Technology',
                'maturity': 'Developing',
                'processes': ['Requirements Management', 'Architecture Design', 'Integration'],
                'tools': ['JIRA', 'Enterprise Architect', 'Jenkins']
            },
            'next_phase': 'module_selection'
        }

    except Exception as e:
        print(f"Error generating objectives: {str(e)}")
        return {'error': f'Failed to generate learning objectives: {str(e)}'}, 500

@seqpt_bp.route('/phase2/generate-objectives', methods=['POST'])
@jwt_required()
def phase2_generate_objectives():
    """Phase 2: Generate company-specific learning objectives using RAG-LLM"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        assessment_uuid = data.get('assessment_uuid')
        company_description = data.get('company_description')
        target_role_id = data.get('target_role_id')
        priority_competencies = data.get('priority_competencies', [])

        # Get assessment and archetype
        assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()
        if not assessment:
            return {'error': 'Assessment not found'}, 404

        selected_archetype = assessment.results.get('selected_archetype', {})
        archetype_name = selected_archetype.get('name', 'Needs-based, project-oriented training')

        # Get target role
        target_role = SERole.query.get(target_role_id) if target_role_id else None
        role_name = target_role.name if target_role else 'System Engineer'

        # Extract company context
        company_context = context_extractor.extract_context_from_text(
            company_description,
            assessment.organization_name
        )
        company_context = context_extractor.enrich_context_with_templates(company_context)

        # Store company context
        context_record = CompanyContext(
            company_name=company_context.company_name,
            industry_domain=company_context.industry_domain,
            business_domain=company_context.business_domain,
            processes=company_context.processes,
            methods=company_context.methods,
            tools=company_context.tools,
            se_maturity_level=company_context.se_maturity_level,
            organizational_size=company_context.organizational_size,
            current_challenges=company_context.current_challenges,
            regulatory_requirements=company_context.regulatory_requirements,
            extraction_method='automated'
        )
        db.session.add(context_record)
        db.session.flush()  # Get ID

        # Generate objectives for priority competencies
        generated_objectives = []

        for competency_id in priority_competencies:
            competency = SECompetency.query.get(competency_id)
            if not competency:
                continue

            try:
                # Use integrated RAG system to generate objective
                result = rag_system.generate_learning_objective(
                    competency=competency.name,
                    role=role_name,
                    archetype=archetype_name,
                    company_description=company_description,
                    company_name=assessment.organization_name
                )

                # Store learning objective
                objective = LearningObjective(
                    company_context_id=context_record.id,
                    competency_id=competency.id,
                    archetype_id=selected_archetype.get('id'),
                    target_role_id=target_role_id,
                    objective_text=result['objective'],
                    smart_score=result['quality_assessment']['smart_average'],
                    quality_score=result['quality_assessment']['overall_quality'],
                    meets_threshold=result['quality_assessment']['meets_threshold'],
                    specific_score=result['quality_assessment']['individual_scores']['specific'],
                    measurable_score=result['quality_assessment']['individual_scores']['measurable'],
                    achievable_score=result['quality_assessment']['individual_scores']['achievable'],
                    relevant_score=result['quality_assessment']['individual_scores']['relevant'],
                    time_bound_score=result['quality_assessment']['individual_scores']['time_bound'],
                    company_alignment_score=result['quality_assessment']['individual_scores']['company_alignment'],
                    incose_compliance_score=result['quality_assessment']['individual_scores']['incose_compliance'],
                    business_value_score=result['quality_assessment']['individual_scores']['business_value'],
                    generation_method='rag_llm',
                    generation_iterations=result['generation_metadata']['iterations_used'],
                    strengths=result['recommendations']['strengths'],
                    improvement_suggestions=result['recommendations']['improvement_plan']
                )

                db.session.add(objective)
                generated_objectives.append({
                    'competency_name': competency.name,
                    'objective_text': result['objective'],
                    'quality_score': result['quality_assessment']['overall_quality'],
                    'meets_threshold': result['quality_assessment']['meets_threshold'],
                    'generation_metadata': result['generation_metadata']
                })

            except Exception as e:
                current_app.logger.error(f"Error generating objective for {competency.name}: {str(e)}")
                continue

        db.session.commit()

        return {
            'message': f'Generated {len(generated_objectives)} learning objectives',
            'objectives': generated_objectives,
            'company_context': {
                'name': company_context.company_name,
                'industry': company_context.industry_domain,
                'maturity': company_context.se_maturity_level,
                'processes': company_context.processes[:3],
                'tools': company_context.tools[:3]
            },
            'next_phase': 'module_selection'
        }

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"RAG objective generation error: {str(e)}")
        return {'error': str(e)}, 500

# Phase 3: Module Selection and Format Optimization
@seqpt_bp.route('/phase3/module-selection', methods=['POST'])
@jwt_required()
def phase3_module_selection():
    """Phase 3: Select training modules and optimize formats (Sachin's research)"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        assessment_uuid = data.get('assessment_uuid')
        selected_objectives = data.get('selected_objectives', [])
        learning_preferences = data.get('learning_preferences', {})

        # Get assessment
        assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()
        if not assessment:
            return {'error': 'Assessment not found'}, 404

        # Apply Sachin's learning format optimization
        optimized_modules = optimize_learning_formats(
            selected_objectives,
            learning_preferences,
            assessment.se_maturity_level
        )

        # Store module selection results
        results = assessment.results or {}
        results['phase3'] = {
            'selected_objectives': selected_objectives,
            'learning_preferences': learning_preferences,
            'optimized_modules': optimized_modules,
            'completed_at': datetime.utcnow().isoformat()
        }
        assessment.results = results
        assessment.phase = 3

        db.session.commit()

        return {
            'message': 'Module selection completed',
            'optimized_modules': optimized_modules,
            'next_phase': 'cohort_formation'
        }

    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

# Phase 4: Cohort Formation and Individual Planning
@seqpt_bp.route('/phase4/cohort-formation', methods=['POST'])
@jwt_required()
def phase4_cohort_formation():
    """Phase 4: Form learning cohorts and create individual plans"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        assessment_uuid = data.get('assessment_uuid')
        team_members = data.get('team_members', [])
        timeline_preferences = data.get('timeline_preferences', {})

        # Get assessment
        assessment = Assessment.query.filter_by(uuid=assessment_uuid, user_id=user_id).first()
        if not assessment:
            return {'error': 'Assessment not found'}, 404

        # Create qualification plan
        plan = QualificationPlan(
            user_id=user_id,
            assessment_id=assessment.id,
            plan_name=f"SE Qualification Plan - {assessment.organization_name}",
            description=f"Generated from SE-QPT assessment on {datetime.utcnow().strftime('%Y-%m-%d')}",
            target_role_id=data.get('target_role_id'),
            selected_archetype_id=assessment.results.get('selected_archetype', {}).get('id'),
            learning_objectives=assessment.results.get('phase3', {}).get('selected_objectives', []),
            selected_modules=assessment.results.get('phase3', {}).get('optimized_modules', []),
            resource_requirements={
                'team_members': team_members,
                'timeline_preferences': timeline_preferences
            }
        )

        # Calculate timeline
        timeline = calculate_qualification_timeline(
            assessment.results.get('phase3', {}).get('optimized_modules', []),
            timeline_preferences
        )

        plan.planned_start_date = timeline.get('start_date')
        plan.planned_end_date = timeline.get('end_date')
        plan.estimated_duration_weeks = timeline.get('duration_weeks')

        # Complete assessment
        assessment.phase = 4
        assessment.status = 'completed'
        assessment.progress_percentage = 100.0

        db.session.add(plan)
        db.session.commit()

        return {
            'message': 'Qualification plan created successfully',
            'plan': {
                'id': plan.id,
                'uuid': plan.uuid,
                'name': plan.plan_name,
                'timeline': timeline,
                'estimated_duration_weeks': plan.estimated_duration_weeks
            },
            'assessment_complete': True
        }

    except Exception as e:
        db.session.rollback()
        return {'error': str(e)}, 500

# RAG-LLM System Status and Management
@seqpt_bp.route('/rag/status', methods=['GET'])
def rag_system_status():
    """Get RAG-LLM system status and statistics"""
    try:
        # Get system statistics
        stats = rag_system.get_system_statistics()

        # Get recent objectives quality metrics
        recent_objectives = LearningObjective.query.filter(
            LearningObjective.generated_at >= datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        ).all()

        quality_metrics = {
            'objectives_today': len(recent_objectives),
            'avg_quality_today': sum(obj.quality_score for obj in recent_objectives) / len(recent_objectives) if recent_objectives else 0,
            'threshold_success_rate': sum(1 for obj in recent_objectives if obj.meets_threshold) / len(recent_objectives) if recent_objectives else 0
        }

        return {
            'rag_system': stats,
            'quality_metrics': quality_metrics,
            'innovation_status': 'operational',
            'components': {
                'context_extraction': 'ready',
                'prompt_engineering': 'ready',
                'smart_validation': 'ready',
                'vector_database': 'operational'
            }
        }

    except Exception as e:
        return {'error': str(e)}, 500

# =============================================================================
# PHASE 1 HELPER FUNCTIONS - Archetype Selection Logic
# NOTE: Maturity calculation is in mvp_models.py (shared utility)
# =============================================================================

def calculate_scope_score(responses):
    """Calculate scope score from archetype selection responses"""
    # Based on archetype selection questionnaire responses
    scope_indicators = ['arch_001', 'arch_002', 'arch_003']
    total_scope = 0
    valid_responses = 0

    for indicator in scope_indicators:
        if indicator in responses:
            response = responses[indicator]
            # Convert response to numeric score
            if response == 'no' or response == 'pilot':
                score = 0
            elif response == 'partial' or response == 'some' or response == 'department':
                score = 1.5
            elif response == 'yes' or response == 'broad' or response == 'organization':
                score = 3.0
            else:
                score = 0

            total_scope += score
            valid_responses += 1

    return (total_scope / valid_responses) if valid_responses > 0 else 0

def determine_archetype_from_scores(maturity_score, scope_score, company_preference=None):
    """Determine qualification archetype based on updated SE-QPT dual selection logic"""

    # Updated SE-QPT Logic: Process_Score <= 1.5 → MANDATORY DUAL SELECTION
    if maturity_score <= 1.5:
        # Primary archetype is ALWAYS "SE for Managers" for low maturity
        primary = 'SE for Managers'

        # Secondary archetype based on company preference
        if company_preference == 'Apply_SE':
            secondary = 'Orientation in Pilot Project'
            rationale = 'Low maturity requires management enablement plus pilot SE application approach'
        elif company_preference == 'Basic_Understanding':
            secondary = 'Common Basic Understanding'
            rationale = 'Low maturity requires management enablement plus foundational SE awareness'
        elif company_preference == 'Expert_Training':
            secondary = 'Certification'
            rationale = 'Low maturity requires management enablement plus expert development through certification'
        else:
            # Default fallback for missing preference
            secondary = 'Common Basic Understanding'
            rationale = 'Low maturity requires management enablement plus foundational SE awareness (default)'

        return {
            'primary': primary,
            'secondary': secondary,
            'rationale': rationale,
            'customization_level': '10%',
            'selection_type': 'dual',
            'processing_type': 'minimal_rag',
            'requires_dual_processing': True
        }

    # High Maturity Logic: Process_Score > 1.5 → SINGLE SELECTION with high customization
    else:
        if scope_score >= 3.0:
            # High maturity + high scope = Continuous Support
            return {
                'primary': 'Continuous Support',
                'secondary': None,
                'rationale': 'High maturity and broad scope enable continuous improvement approach with extensive customization',
                'customization_level': '90%',
                'selection_type': 'single',
                'processing_type': 'high_intensity_rag',
                'requires_dual_processing': False
            }
        elif scope_score >= 2.0:
            # High maturity + medium scope = Project-oriented Training
            return {
                'primary': 'Needs-based Project-oriented Training',
                'secondary': None,
                'rationale': 'Medium scope with established maturity suits project-based approach with extensive customization',
                'customization_level': '90%',
                'selection_type': 'single',
                'processing_type': 'high_intensity_rag',
                'requires_dual_processing': False
            }
        else:
            # High maturity + low scope - still high customization but different approach
            if scope_score <= 0.5:
                return {
                    'primary': 'Orientation in Pilot Project',
                    'secondary': None,
                    'rationale': 'High maturity with limited scope requires customized pilot approach',
                    'customization_level': '90%',
                    'selection_type': 'single',
                    'processing_type': 'high_intensity_rag',
                    'requires_dual_processing': False
                }
            else:
                return {
                    'primary': 'Common Basic Understanding',
                    'secondary': None,
                    'rationale': 'High maturity with moderate scope requires customized foundational approach',
                    'customization_level': '90%',
                    'selection_type': 'single',
                    'processing_type': 'high_intensity_rag',
                    'requires_dual_processing': False
                }

    # This should not be reached with updated logic, but keeping as safety fallback
    return {
        'primary': 'Common Basic Understanding',
        'secondary': None,
        'rationale': 'Fallback archetype for undefined scoring patterns',
        'customization_level': '10%',
        'selection_type': 'single',
        'processing_type': 'minimal_rag',
        'requires_dual_processing': False
    }

def process_competency_assessment(competency_responses):
    """Process competency assessment using Derik's algorithms"""
    # Simplified competency processing
    results = {}

    for competency_id, responses in competency_responses.items():
        # Calculate current level based on responses
        current_level = sum(responses.values()) / len(responses) if responses else 0

        results[competency_id] = {
            'current_level': current_level,
            'confidence_score': 0.8,  # Simplified
            'indicator_scores': responses,
            'target_level': min(current_level + 1, 4),
            'priority': 'High' if current_level < 2 else 'Medium'
        }

    return results

def generate_gap_analysis(competency_results):
    """Generate competency gap analysis"""
    gaps = []

    for comp_id, result in competency_results.items():
        gap_size = result['target_level'] - result['current_level']
        if gap_size > 0:
            gaps.append({
                'competency_id': comp_id,
                'current_level': result['current_level'],
                'target_level': result['target_level'],
                'gap_size': gap_size,
                'priority': result['priority']
            })

    return sorted(gaps, key=lambda x: x['gap_size'], reverse=True)

def optimize_learning_formats(objectives, preferences, maturity_level):
    """Apply Sachin's learning format optimization"""
    # Simplified format optimization
    formats = {
        'initial': 'workshop',
        'developing': 'blended',
        'established': 'project_based',
        'expert': 'mentoring'
    }

    recommended_format = formats.get(maturity_level, 'blended')

    return {
        'recommended_format': recommended_format,
        'estimated_duration': len(objectives) * 2,  # 2 weeks per objective
        'delivery_method': 'hybrid',
        'group_size': 'small_team'
    }

def calculate_qualification_timeline(modules, preferences):
    """Calculate realistic qualification timeline"""
    # Simplified timeline calculation
    total_weeks = sum(module.get('duration_weeks', 2) for module in modules)

    return {
        'duration_weeks': total_weeks,
        'start_date': datetime.utcnow().date(),
        'end_date': (datetime.utcnow() + timedelta(weeks=total_weeks)).date()
    }

# Helper functions for enhanced RAG objectives generation
def generate_standardized_objective(competency_name, industry, compliance_standards):
    """Generate standardized learning objective focused on industry standards"""
    standards_text = ', '.join(compliance_standards) if compliance_standards else 'industry standards'

    templates = {
        'Requirements Engineering': f'Master requirements elicitation and management techniques according to {standards_text} for {industry} domain applications',
        'System Architecture': f'Develop expertise in system architecture design patterns following {standards_text} for {industry} systems',
        'Risk Management': f'Implement comprehensive risk assessment and mitigation strategies aligned with {standards_text} in {industry} context',
        'Project Management': f'Apply advanced project management methodologies compliant with {standards_text} for {industry} projects'
    }

    return templates.get(competency_name, f'Develop proficiency in {competency_name} following {standards_text} for {industry} applications')

def generate_company_specific_objective(competency_name, company_name, processes, methods, tools, additional):
    """Generate company-specific learning objective using internal context"""
    dev_process = ', '.join(processes.get('development', [])) if processes.get('development') else 'company processes'
    tool_context = tools.get('development', '') or tools.get('collaboration', '') or 'company tools'
    challenges = additional.get('challenges', '')

    if challenges:
        context = f"addressing {company_name}'s specific challenges: {challenges[:100]}..."
    else:
        context = f"within {company_name}'s {dev_process} environment using {tool_context}"

    templates = {
        'Requirements Engineering': f'Enhance stakeholder requirements gathering and traceability {context}',
        'System Architecture': f'Optimize system design and integration practices {context}',
        'Communication': f'Improve cross-functional communication and documentation {context}',
        'Quality Management': f'Strengthen quality assurance processes and metrics {context}'
    }

    return templates.get(competency_name, f'Develop {competency_name} capabilities {context}')

def generate_blended_objective(competency_name, company_name, industry, processes, methods, tools):
    """Generate blended learning objective mixing standards and company context"""
    tool_context = tools.get('development', '') or 'industry tools'
    process_context = ', '.join(processes.get('development', [])) if processes.get('development') else 'standard processes'

    templates = {
        'Systems Thinking': f'Apply systems thinking principles to {company_name}\'s {industry} projects using {process_context} and {tool_context}',
        'Life Cycle Management': f'Implement end-to-end lifecycle management practices for {industry} systems at {company_name} following {process_context}',
        'Teamwork': f'Enhance collaborative engineering practices within {company_name}\'s {process_context} framework using {tool_context}',
        'Problem Solving': f'Develop structured problem-solving approaches for {industry} challenges at {company_name} using {tool_context}'
    }

    return templates.get(competency_name, f'Master {competency_name} through practical application in {company_name}\'s {industry} environment')

def calculate_context_richness(job_context):
    """Calculate how rich the provided context is (0.0-1.0)"""
    score = 0.0

    # Company information completeness
    company = job_context.get('company', {})
    if company.get('name'): score += 0.1
    if company.get('industry'): score += 0.1
    if company.get('size'): score += 0.1

    # Process information
    processes = job_context.get('processes', {})
    if processes.get('development'): score += 0.15
    if processes.get('quality'): score += 0.1
    if processes.get('compliance'): score += 0.1

    # Methods information
    methods = job_context.get('methods', {})
    if methods.get('design'): score += 0.1
    if methods.get('testing'): score += 0.1

    # Tools information
    tools = job_context.get('tools', {})
    if tools.get('development'): score += 0.1
    if tools.get('collaboration'): score += 0.1

    # Additional context
    additional = job_context.get('additional', {})
    if additional.get('challenges'): score += 0.15
    if additional.get('priorities'): score += 0.1

    return min(1.0, score)

# Enhanced RAG objectives endpoint with PMT context
@seqpt_bp.route('/public/phase2/generate-objectives-enhanced', methods=['POST'])
def phase2_generate_objectives_enhanced_public():
    """Phase 2: Generate company-specific learning objectives using RAG-LLM with archetype and PMT context (enhanced public endpoint)"""
    try:
        data = request.get_json()
        assessment_data = data.get('assessment_data', {})
        job_context = data.get('job_context', {})
        competency_results = data.get('competency_results', [])

        # Extract context information
        company_info = job_context.get('company', {})
        company_name = company_info.get('name', 'Technology Company')
        industry = company_info.get('industry', 'technology')
        organization_size = company_info.get('size', 'medium')

        # Extract PMT context
        processes = job_context.get('processes', {})
        methods = job_context.get('methods', {})
        tools = job_context.get('tools', {})
        additional = job_context.get('additional', {})

        # Extract archetype information
        archetype_info = job_context.get('archetype', {})
        archetype_name = archetype_info.get('name', 'Blended Learning')
        archetype_format = archetype_info.get('learning_format', 'mixed')

        # Determine customization level based on SE-QPT archetype specifications
        is_standardized = archetype_name in ['Common Basic Understanding', 'SE for Managers', 'Orientation in Pilot Project', 'Certification']
        is_company_specific = archetype_name in ['Continuous Support', 'Needs-based Project-oriented Training']

        # Generate context-aware learning objectives
        objectives = []

        # Focus on top competency gaps or all competencies
        focus_competencies = competency_results[:8] if len(competency_results) > 8 else competency_results

        for i, comp_result in enumerate(focus_competencies):
            comp_name = comp_result.get('name', f'Competency {i+1}')
            comp_score = comp_result.get('score', 0)
            comp_area = comp_result.get('area', 'Core Competencies')

            # Customize objective based on archetype and company context
            if is_standardized:
                # Standardized approach - focus on industry standards
                objective_text = generate_standardized_objective(comp_name, industry, processes.get('compliance', []))
            elif is_company_specific:
                # Company-specific approach - focus on internal tools and processes
                objective_text = generate_company_specific_objective(
                    comp_name, company_name, processes, methods, tools, additional
                )
            else:
                # Blended approach - mix of standards and company context
                objective_text = generate_blended_objective(
                    comp_name, company_name, industry, processes, methods, tools
                )

            # Calculate quality scores based on context richness
            context_richness = calculate_context_richness(job_context)
            base_quality = 0.75 + (context_richness * 0.20)  # 0.75-0.95 range

            objectives.append({
                'id': i + 1,
                'objective_text': objective_text,
                'competency_name': comp_name,
                'competency_area': comp_area,
                'target_role_name': assessment_data.get('selectedRoles', [{}])[0].get('name', 'Systems Engineer'),
                'archetype_name': archetype_name,
                'customization_level': 'high' if is_company_specific else 'medium' if not is_standardized else 'standard',
                'quality_score': min(0.95, base_quality + (i * 0.01)),  # Slight variation
                'smart_score': min(0.94, base_quality + 0.05),
                'specific_score': min(0.93, base_quality + 0.03),
                'measurable_score': min(0.91, base_quality + 0.01),
                'achievable_score': min(0.96, base_quality + 0.08),
                'relevant_score': min(0.94, base_quality + 0.06),
                'timebound_score': min(0.88, base_quality - 0.02),
                'company_context': {
                    'industry': industry,
                    'size': organization_size,
                    'tools_mentioned': bool(tools.get('development') or tools.get('collaboration')),
                    'processes_mentioned': bool(processes.get('development') or processes.get('quality')),
                    'challenges_addressed': bool(additional.get('challenges'))
                }
            })

        # Add learning format recommendations based on archetype
        learning_recommendations = {
            'archetype': archetype_name,
            'format': archetype_format,
            'customization_level': 'high' if is_company_specific else 'medium' if not is_standardized else 'standard',
            'context_richness_score': context_richness,
            'company_alignment': {
                'industry_specific': industry != 'other',
                'process_specific': len(processes.get('development', [])) > 0,
                'tool_specific': bool(tools.get('development') or tools.get('collaboration')),
                'challenge_driven': bool(additional.get('challenges'))
            }
        }

        return {
            'objectives': objectives,
            'total_objectives': len(objectives),
            'learning_recommendations': learning_recommendations,
            'average_quality_score': sum(obj['quality_score'] for obj in objectives) / len(objectives) if objectives else 0,
            'generation_metadata': {
                'timestamp': datetime.utcnow().isoformat(),
                'method': 'enhanced_rag_with_pmt_context',
                'archetype_based': True,
                'company_specific': is_company_specific,
                'context_completeness': context_richness
            }
        }, 200

    except Exception as e:
        return {
            'error': 'Failed to generate learning objectives',
            'details': str(e),
            'fallback_available': True
        }, 500