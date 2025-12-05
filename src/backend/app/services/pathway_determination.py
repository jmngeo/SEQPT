"""
Phase 2 Learning Objectives - Pathway Determination Module
===========================================================

This module determines which pathway to use for learning objectives generation:
- TASK_BASED: For organizations without defined roles (low maturity)
- ROLE_BASED: For organizations with defined roles (high maturity)

Main Entry Point:
    generate_learning_objectives(org_id) - Orchestrates the entire process

Dependencies:
    - models.py: OrganizationRoles, LearningStrategy, get_organization_completion_stats
    - role_based_pathway_fixed.py: generate_role_based_learning_objectives
    - task_based_pathway.py: generate_task_based_learning_objectives (TO BE CREATED)

Date: November 4, 2025
Status: COMPLETE - Pathway Determination
"""

from models import db, OrganizationRoles, LearningStrategy, get_organization_completion_stats
from app.services.role_based_pathway_fixed import run_role_based_pathway_analysis_fixed
from app.services.task_based_pathway import generate_task_based_learning_objectives
import hashlib
import json


def calculate_input_hash(organization_id: int) -> str:
    """
    Calculate SHA-256 hash of all inputs that affect learning objectives generation

    Includes:
    - Latest assessment IDs per user (to detect new assessments)
    - Selected strategy IDs + priorities (to detect strategy changes)
    - PMT context content (to detect PMT updates)
    - Maturity level (to detect pathway changes)

    Args:
        organization_id: Organization ID

    Returns:
        64-character SHA-256 hash (hex digest)

    Example:
        hash = calculate_input_hash(28)
        # Returns: "a7f3b2c1..." (64 chars)
    """
    from models import (
        UserAssessment, LearningStrategy, OrganizationPMTContext,
        PhaseQuestionnaireResponse
    )

    # 1. Get latest assessment IDs per user
    assessments = UserAssessment.query.filter_by(
        organization_id=organization_id
    ).filter(
        UserAssessment.completed_at.isnot(None)
    ).order_by(
        UserAssessment.user_id,
        UserAssessment.completed_at.desc()
    ).all()

    # Keep only latest assessment ID per user
    assessment_ids = []
    seen_users = set()
    for a in assessments:
        if a.user_id not in seen_users:
            assessment_ids.append(a.id)
            seen_users.add(a.user_id)

    # 2. Get selected strategy IDs + priorities
    strategies = LearningStrategy.query.filter_by(
        organization_id=organization_id,
        selected=True
    ).order_by(LearningStrategy.id).all()

    strategy_data = [
        {'id': s.id, 'priority': s.priority}
        for s in strategies
    ]

    # 3. Get PMT context (if exists)
    pmt = OrganizationPMTContext.query.filter_by(
        organization_id=organization_id
    ).first()

    pmt_data = None
    if pmt:
        pmt_data = {
            'processes': pmt.processes,
            'methods': pmt.methods,
            'tools': pmt.tools,
            'industry': pmt.industry,
            'additional_context': pmt.additional_context
        }

    # 4. Get maturity level
    maturity_response = PhaseQuestionnaireResponse.query.filter_by(
        organization_id=organization_id,
        questionnaire_type='maturity',
        phase=1
    ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

    maturity_level = None
    if maturity_response:
        response_data = maturity_response.get_responses()
        results = response_data.get('results', {})
        strategy_inputs = results.get('strategyInputs', {})
        maturity_level = strategy_inputs.get('seProcessesValue')

    # Create stable JSON representation
    input_dict = {
        'assessments': sorted(assessment_ids),  # Sorted for stability
        'strategies': strategy_data,  # Already ordered by ID
        'pmt': pmt_data,
        'maturity': maturity_level
    }

    # Convert to JSON string (sorted keys for stability)
    input_string = json.dumps(input_dict, sort_keys=True, separators=(',', ':'))

    # Calculate SHA-256 hash
    hash_obj = hashlib.sha256(input_string.encode('utf-8'))

    return hash_obj.hexdigest()


def get_assessment_completion_rate(org_id):
    """
    Get assessment completion rate for an organization.

    Args:
        org_id (int): Organization ID

    Returns:
        dict: Completion statistics including completion_rate percentage

    Example return:
        {
            'organization_id': 28,
            'organization_name': 'MedDevice Corp',
            'total_users': 10,
            'users_with_assessments': 10,
            'completion_rate': 100.0
        }
    """
    stats = get_organization_completion_stats(org_id)
    if not stats:
        return {
            'error': 'Organization not found',
            'completion_rate': 0
        }
    return stats


def get_selected_strategies(org_id):
    """
    Get learning strategies selected by the organization.

    Args:
        org_id (int): Organization ID

    Returns:
        list: List of selected LearningStrategy objects, ordered by priority

    Example:
        [
            <LearningStrategy id=1 name="Foundation Workshop" priority=1>,
            <LearningStrategy id=2 name="Advanced Training" priority=2>
        ]
    """
    strategies = LearningStrategy.query.filter_by(
        organization_id=org_id,
        selected=True
    ).order_by(LearningStrategy.priority.asc()).all()

    return strategies


def determine_pathway(org_id):
    """
    Determines which pathway to use based on Phase 1 maturity assessment.

    Logic (as per LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md, Lines 368-432):
        - maturity_level >= 3 (Defined) → ROLE_BASED pathway (high maturity)
        - maturity_level < 3 (Initial/Managed) → TASK_BASED pathway (low maturity)

    Maturity Levels:
        1 - Initial/Ad-hoc
        2 - Managed
        3 - Defined (threshold)
        4 - Quantitatively Managed
        5 - Optimizing

    Args:
        org_id (int): Organization ID

    Returns:
        dict: Pathway determination result

    Example return (low maturity):
        {
            'pathway': 'TASK_BASED',
            'maturity_level': 2,
            'maturity_description': 'Managed',
            'reason': 'Maturity level 2 (below threshold 3) - using task-based approach'
        }

    Example return (high maturity):
        {
            'pathway': 'ROLE_BASED',
            'maturity_level': 4,
            'maturity_description': 'Quantitatively Managed',
            'role_count': 3,
            'roles': ['Systems Engineer', 'Requirements Engineer', 'Project Manager'],
            'reason': 'Maturity level 4 (at or above threshold 3) - using role-based approach'
        }
    """
    import requests
    from flask import current_app
    import logging

    logger = logging.getLogger(__name__)

    # Maturity threshold (from design)
    MATURITY_THRESHOLD = 3

    # Maturity level descriptions
    MATURITY_DESCRIPTIONS = {
        1: 'Initial/Ad-hoc',
        2: 'Managed',
        3: 'Defined',
        4: 'Quantitatively Managed',
        5: 'Optimizing'
    }

    # Step 1: Get Phase 1 maturity assessment
    maturity_level = None
    maturity_description = None

    try:
        # Call internal API endpoint
        from models import PhaseQuestionnaireResponse

        maturity = PhaseQuestionnaireResponse.query.filter_by(
            organization_id=org_id,
            questionnaire_type='maturity',
            phase=1
        ).order_by(PhaseQuestionnaireResponse.completed_at.desc()).first()

        if maturity:
            response_data = maturity.get_responses()
            results = response_data.get('results', {})
            strategy_inputs = results.get('strategyInputs', {})
            maturity_level = strategy_inputs.get('seProcessesValue')

            if maturity_level is not None:
                maturity_description = MATURITY_DESCRIPTIONS.get(maturity_level, 'Unknown')
                logger.info(f"[Pathway Determination] Org {org_id}: maturity_level={maturity_level} ({maturity_description})")
            else:
                logger.warning(f"[Pathway Determination] Org {org_id}: maturity assessment exists but seProcessesValue not found")
        else:
            logger.warning(f"[Pathway Determination] Org {org_id}: No maturity assessment found")

    except Exception as e:
        logger.error(f"[Pathway Determination] Error fetching maturity for org {org_id}: {e}")

    # Step 2: Default to high maturity (role-based) if no maturity data
    # Rationale: If organization is using the system, assume they have some maturity
    if maturity_level is None:
        logger.info(f"[Pathway Determination] Org {org_id}: No maturity data, defaulting to maturity_level=5 (role-based)")
        maturity_level = 5
        maturity_description = 'Optimizing (default)'

    # Step 3: Determine pathway based on threshold
    pathway = 'ROLE_BASED' if maturity_level >= MATURITY_THRESHOLD else 'TASK_BASED'

    # Step 4: Get role information (for context in role-based pathway)
    role_count = 0
    role_names = []

    if pathway == 'ROLE_BASED':
        roles = OrganizationRoles.query.filter_by(organization_id=org_id).all()
        role_count = len(roles)
        role_names = [role.role_name for role in roles]

    # Step 5: Build result
    result = {
        'pathway': pathway,
        'maturity_level': maturity_level,
        'maturity_description': maturity_description,
        'maturity_threshold': MATURITY_THRESHOLD
    }

    if pathway == 'TASK_BASED':
        result['reason'] = f'Maturity level {maturity_level} (below threshold {MATURITY_THRESHOLD}) - using task-based approach'
    else:
        result['role_count'] = role_count
        result['roles'] = role_names
        result['reason'] = f'Maturity level {maturity_level} (at or above threshold {MATURITY_THRESHOLD}) - using role-based approach'

        if role_count == 0:
            logger.warning(
                f"[Pathway Determination] Org {org_id}: ROLE_BASED pathway selected but no roles defined. "
                f"This may cause issues. Consider defining roles or user will see errors."
            )

    return result


def generate_learning_objectives(org_id, force=False):
    """
    Main entry point for learning objectives generation with intelligent caching.

    IMPORTANT: As per LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.1 (Lines 591-596):
    "Admin confirmation required in UI before calling this endpoint.
    No automatic completion rate check - admin decides if assessments are complete."

    This function orchestrates the entire process:
    1. Check for cached objectives (unless force=True)
    2. Calculate input hash and validate cache
    3. Gets completion stats for informational purposes only (NO threshold enforcement)
    4. Gets selected strategies for the organization
    5. Determines pathway (TASK_BASED vs ROLE_BASED) based on Phase 1 maturity
    6. Routes to appropriate algorithm
    7. Stores results in cache
    8. Returns learning objectives

    Args:
        org_id (int): Organization ID
        force (bool): If True, regenerate even if cached version exists (default: False)

    Returns:
        dict: Learning objectives generation result

    Success return structure:
        {
            'success': True,
            'pathway': 'ROLE_BASED' or 'TASK_BASED',
            'pathway_reason': 'Description of why this pathway was selected',
            'maturity_level': 3,
            'maturity_description': 'Defined',
            'completion_rate': 85.0,  # Informational only
            'selected_strategies': [
                {
                    'id': 1,
                    'name': 'Foundation Workshop',
                    'priority': 1
                },
                ...
            ],
            'learning_objectives': {
                'strategy_1': [...],
                'strategy_2': [...]
            },
            'validation_results': {...},  # Only for ROLE_BASED pathway
            'recommendations': {...}      # Only for ROLE_BASED pathway
        }

    Error return structure:
        {
            'success': False,
            'error': 'Error description',
            'error_type': 'NO_ASSESSMENTS' | 'NO_STRATEGIES' | 'ORGANIZATION_NOT_FOUND',
            'details': {...}
        }

    Example usage:
        >>> result = generate_learning_objectives(28)
        >>> if result['success']:
        >>>     print(f"Generated objectives via {result['pathway']} pathway")
        >>>     for strategy, objectives in result['learning_objectives'].items():
        >>>         print(f"{strategy}: {len(objectives)} objectives")
    """
    from models import GeneratedLearningObjectives
    from app.services.config_loader import is_caching_enabled
    import logging

    logger = logging.getLogger(__name__)

    # CACHING LOGIC - Step 0: Check for cached objectives
    caching_enabled = is_caching_enabled()

    if caching_enabled and not force:
        # Try to retrieve from cache
        cached = GeneratedLearningObjectives.query.filter_by(
            organization_id=org_id
        ).first()

        if cached:
            # Calculate current input hash
            current_hash = calculate_input_hash(org_id)

            # Check if hash matches (cache still valid)
            if current_hash == cached.input_hash:
                logger.info(
                    f"[CACHE HIT] Returning cached objectives for org {org_id} "
                    f"(generated {cached.generated_at})"
                )

                # Return cached data with metadata
                result = cached.objectives_data.copy() if isinstance(cached.objectives_data, dict) else cached.objectives_data
                result['cached'] = True
                result['cache_generated_at'] = cached.generated_at.isoformat()
                result['cache_hit'] = True

                return result
            else:
                logger.info(
                    f"[CACHE INVALIDATED] Hash mismatch for org {org_id}. "
                    f"Cached: {cached.input_hash[:8]}..., Current: {current_hash[:8]}..."
                )
        else:
            logger.info(f"[CACHE MISS] No cached objectives found for org {org_id}")
    elif not caching_enabled:
        logger.info(f"[CACHE DISABLED] Caching disabled in configuration for org {org_id}")
    else:
        logger.info(f"[CACHE BYPASS] Force regeneration requested for org {org_id}")

    # If we get here, we need to generate fresh objectives
    logger.info(f"[GENERATING] Fresh objectives for org {org_id}")

    # Step 1: Get assessment completion stats (informational only, NO threshold check)
    completion_stats = get_assessment_completion_rate(org_id)

    if 'error' in completion_stats:
        return {
            'success': False,
            'error': completion_stats['error'],
            'error_type': 'ORGANIZATION_NOT_FOUND'
        }

    completion_rate = completion_stats['completion_rate']

    # DESIGN COMPLIANCE: No automatic threshold check
    # Admin decides if assessments are complete before calling this endpoint
    # We only return error if ZERO assessments exist
    if completion_stats['users_with_assessments'] == 0:
        return {
            'success': False,
            'error': 'No assessment data available',
            'error_type': 'NO_ASSESSMENTS',
            'details': {
                'completion_rate': 0.0,
                'total_users': completion_stats['total_users'],
                'users_with_assessments': 0,
                'message': 'No users have completed competency assessments. At least one assessment is required.'
            }
        }

    # Step 2: Get selected strategies
    selected_strategies = get_selected_strategies(org_id)

    if not selected_strategies:
        return {
            'success': False,
            'error': 'No learning strategies selected',
            'error_type': 'NO_STRATEGIES',
            'details': {
                'message': 'Organization must select at least one learning strategy in Phase 1'
            }
        }

    # Step 3: Determine pathway based on Phase 1 maturity level
    pathway_info = determine_pathway(org_id)
    pathway = pathway_info['pathway']

    # Step 4: Route to appropriate algorithm
    if pathway == 'ROLE_BASED':
        # Route to role-based pathway algorithm (already implemented)
        algorithm_result = run_role_based_pathway_analysis_fixed(org_id)

        # Add pathway metadata to result
        # IMPORTANT: Don't overwrite pathway if algorithm returned ROLE_BASED_DUAL_TRACK
        if 'pathway' not in algorithm_result or algorithm_result['pathway'] not in ['ROLE_BASED', 'ROLE_BASED_DUAL_TRACK']:
            algorithm_result['pathway'] = 'ROLE_BASED'
        algorithm_result['pathway_reason'] = pathway_info['reason']
        algorithm_result['maturity_level'] = pathway_info['maturity_level']
        algorithm_result['maturity_description'] = pathway_info['maturity_description']
        algorithm_result['maturity_threshold'] = pathway_info['maturity_threshold']
        algorithm_result['role_count'] = pathway_info.get('role_count', 0)
        algorithm_result['roles'] = pathway_info.get('roles', [])

    else:  # TASK_BASED
        # Route to task-based pathway algorithm
        algorithm_result = generate_task_based_learning_objectives(org_id)

        # Add pathway metadata to result
        # IMPORTANT: Don't overwrite pathway if algorithm returned TASK_BASED_DUAL_TRACK
        if 'pathway' not in algorithm_result or algorithm_result['pathway'] not in ['TASK_BASED', 'TASK_BASED_DUAL_TRACK']:
            algorithm_result['pathway'] = 'TASK_BASED'
        algorithm_result['pathway_reason'] = pathway_info['reason']
        algorithm_result['maturity_level'] = pathway_info['maturity_level']
        algorithm_result['maturity_description'] = pathway_info['maturity_description']
        algorithm_result['maturity_threshold'] = pathway_info['maturity_threshold']
        algorithm_result['role_count'] = 0

    # Step 5: Add completion rate (informational) and strategy info to result
    if 'error' not in algorithm_result:
        algorithm_result['success'] = True
        algorithm_result['completion_rate'] = completion_rate
        algorithm_result['completion_stats'] = {
            'total_users': completion_stats['total_users'],
            'users_with_assessments': completion_stats['users_with_assessments'],
            'completion_rate': completion_rate,
            'note': 'Admin has confirmed assessments are ready for objective generation'
        }
        algorithm_result['selected_strategies'] = [
            {
                'id': strategy.id,
                'name': strategy.strategy_name,
                'description': strategy.strategy_description,
                'priority': strategy.priority
            }
            for strategy in selected_strategies
        ]
    else:
        algorithm_result['success'] = False

    # Add cache metadata flags
    algorithm_result['cached'] = False
    algorithm_result['cache_hit'] = False
    algorithm_result['caching_enabled'] = caching_enabled

    # Step 6: Store result in cache (only if caching is enabled)
    if caching_enabled and algorithm_result.get('success'):
        try:
            # Calculate hash of inputs
            input_hash = calculate_input_hash(org_id)

            # Extract validation results for quick access
            validation_status = algorithm_result.get('strategy_validation', {}).get('status')
            gap_percentage = algorithm_result.get('strategy_validation', {}).get('gap_percentage')

            # Check if cache entry exists
            cached = GeneratedLearningObjectives.query.filter_by(
                organization_id=org_id
            ).first()

            if cached:
                # Update existing cache
                cached.pathway = algorithm_result.get('pathway')
                cached.objectives_data = algorithm_result
                cached.generated_at = db.func.now()
                cached.input_hash = input_hash
                cached.validation_status = validation_status
                cached.gap_percentage = gap_percentage
                logger.info(f"[CACHE UPDATED] Updated cache for org {org_id}")
            else:
                # Create new cache entry
                new_cache = GeneratedLearningObjectives(
                    organization_id=org_id,
                    pathway=algorithm_result.get('pathway'),
                    objectives_data=algorithm_result,
                    input_hash=input_hash,
                    validation_status=validation_status,
                    gap_percentage=gap_percentage
                )
                db.session.add(new_cache)
                logger.info(f"[CACHE CREATED] New cache entry for org {org_id}")

            db.session.commit()

        except Exception as e:
            logger.error(f"[CACHE ERROR] Failed to store cache for org {org_id}: {str(e)}")
            db.session.rollback()
            # Don't fail the request if caching fails, just log it

    return algorithm_result


# =============================================================================
# HELPER FUNCTIONS FOR API ROUTES
# =============================================================================

def validate_prerequisites(org_id):
    """
    Validates that all prerequisites are met before generating learning objectives.

    IMPORTANT: As per design v4.1, NO automatic completion rate threshold.
    This function checks for basic prerequisites only:
    - At least 1 user has completed assessment
    - At least 1 strategy selected
    - Pathway determination successful

    This is a lighter check than generate_learning_objectives() - useful for
    pre-flight validation in API endpoints (e.g., enabling "Generate" button).

    Args:
        org_id (int): Organization ID

    Returns:
        dict: Validation result

    Example return (success):
        {
            'valid': True,
            'completion_rate': 85.0,
            'completion_stats': {
                'total_users': 40,
                'users_with_assessments': 34
            },
            'pathway': 'ROLE_BASED',
            'maturity_level': 4,
            'maturity_description': 'Quantitatively Managed',
            'selected_strategies_count': 2,
            'ready_to_generate': True,
            'note': 'Admin should confirm assessments are complete before generating objectives'
        }

    Example return (failure):
        {
            'valid': False,
            'error': 'No assessment data available',
            'completion_rate': 0.0,
            'ready_to_generate': False
        }
    """
    # Check completion stats (informational only, NO threshold)
    completion_stats = get_assessment_completion_rate(org_id)

    if 'error' in completion_stats:
        return {
            'valid': False,
            'error': completion_stats['error'],
            'ready_to_generate': False
        }

    completion_rate = completion_stats['completion_rate']

    # DESIGN COMPLIANCE: Only fail if ZERO assessments
    if completion_stats['users_with_assessments'] == 0:
        return {
            'valid': False,
            'error': 'No assessment data available',
            'completion_rate': 0.0,
            'completion_stats': {
                'total_users': completion_stats['total_users'],
                'users_with_assessments': 0
            },
            'ready_to_generate': False,
            'note': 'At least one user must complete assessment before generating objectives'
        }

    # Check strategies
    selected_strategies = get_selected_strategies(org_id)

    if not selected_strategies:
        return {
            'valid': False,
            'error': 'No learning strategies selected',
            'completion_rate': completion_rate,
            'ready_to_generate': False,
            'note': 'At least one learning strategy must be selected in Phase 1'
        }

    # Determine pathway
    pathway_info = determine_pathway(org_id)

    # Check if PMT context exists
    from models import OrganizationPMTContext, GeneratedLearningObjectives
    pmt_context = OrganizationPMTContext.query.filter_by(
        organization_id=org_id
    ).first()
    has_pmt_context = pmt_context is not None

    # Check if generated objectives exist (without triggering generation)
    existing_objectives = GeneratedLearningObjectives.query.filter_by(
        organization_id=org_id
    ).first()
    has_generated_objectives = existing_objectives is not None

    # Format selected strategies with full details
    strategies_list = [
        {
            'id': strategy.id,
            'name': strategy.strategy_name,
            'description': strategy.strategy_description,
            'priority': strategy.priority
        }
        for strategy in selected_strategies
    ]

    return {
        'valid': True,
        'completion_rate': completion_rate,
        'completion_stats': {
            'total_users': completion_stats['total_users'],
            'users_with_assessments': completion_stats['users_with_assessments'],
            'organization_name': completion_stats.get('organization_name', 'Unknown')
        },
        'pathway': pathway_info['pathway'],
        'maturity_level': pathway_info['maturity_level'],
        'maturity_description': pathway_info['maturity_description'],
        'maturity_threshold': pathway_info['maturity_threshold'],
        'selected_strategies_count': len(selected_strategies),
        'selected_strategies': strategies_list,  # Added: Full strategy objects
        'has_pmt_context': has_pmt_context,  # Added: PMT context existence flag
        'has_generated_objectives': has_generated_objectives,  # Added: Objectives exist flag
        'role_count': pathway_info.get('role_count', 0),
        'ready_to_generate': True,
        'note': 'Admin should confirm all necessary assessments are complete before generating objectives'
    }


# =============================================================================
# EXPORT
# =============================================================================

__all__ = [
    'generate_learning_objectives',
    'determine_pathway',
    'get_assessment_completion_rate',
    'get_selected_strategies',
    'validate_prerequisites'
]
