"""
Phase 2 Task-Based Assessment - Task-Based Pathway Algorithm
=============================================================

COMPLETE IMPLEMENTATION for Low-Maturity Organizations

This module implements the task-based pathway algorithm for organizations
without defined SE roles (low maturity).

Algorithm: 2-WAY COMPARISON
- Current Level (median of users) vs Archetype Target (from strategy)
- NO role requirements (organization has no roles defined)
- NO validation layer (simpler than role-based)

Key Differences from Role-Based:
1. Uses users with survey_type='unknown_roles' (task-based assessments)
2. Only 2 data points: Current vs Strategy Target
3. No cross-strategy validation
4. Simpler decision logic

Steps:
1. Get assessment data (task-based users only)
2. Calculate median current level per competency
3. Get archetype target from strategy
4. Simple comparison: if current < target, generate objective
5. Text generation using same module as role-based

Date: November 4, 2025
Status: COMPLETE - Production Ready
"""

from typing import Dict, List, Optional
import logging
from statistics import median

logger = logging.getLogger(__name__)

# Import compatibility layer
try:
    # Try Flask app context first (production)
    from app import models as app_models
    from app.models import (
        UserAssessment, LearningStrategy, StrategyTemplateCompetency,
        UserCompetencySurveyResult, PMTContext, Competency
    )
    from app.services.learning_objectives_text_generator import (
        get_template_objective,
        get_template_objective_full,
        llm_deep_customize,
        check_if_strategy_needs_pmt,
        get_competency_name,
        get_core_competency_note,
        CORE_COMPETENCIES
    )
except (ImportError, ModuleNotFoundError):
    # Fall back to direct import (testing/standalone)
    import models as app_models
    from models import (
        UserAssessment, LearningStrategy, StrategyTemplateCompetency,
        UserCompetencySurveyResult, PMTContext, Competency
    )
    import sys
    import os
    sys.path.insert(0, os.path.dirname(__file__))
    from learning_objectives_text_generator import (
        get_template_objective,
        get_template_objective_full,
        llm_deep_customize,
        check_if_strategy_needs_pmt,
        get_competency_name,
        get_core_competency_note,
        CORE_COMPETENCIES
    )


# ============================================================================
# STEP 1: Get Task-Based Assessment Data
# ============================================================================

def get_task_based_assessment_data(organization_id: int):
    """
    Get assessment data for task-based users (low-maturity organizations)

    Task-based users are those with:
    - survey_type = 'unknown_roles'
    - No role selection (filled task descriptions instead)

    Returns:
        {
            'user_assessments': List[UserAssessment],  # Only task-based users
            'selected_strategies': List[LearningStrategy],
            'all_competencies': List[int]  # 16 competency IDs
        }
    """
    # Get completed task-based assessments (latest per user)
    # First, get all completed task-based assessments
    all_assessments = UserAssessment.query.filter_by(
        organization_id=organization_id,
        survey_type='unknown_roles'  # Task-based assessments
    ).filter(
        UserAssessment.completed_at.isnot(None)
    ).order_by(UserAssessment.user_id, UserAssessment.completed_at.desc()).all()

    # Keep only the latest assessment per user
    user_assessments = []
    seen_users = set()
    for assessment in all_assessments:
        if assessment.user_id not in seen_users:
            user_assessments.append(assessment)
            seen_users.add(assessment.user_id)

    # Get selected learning strategies
    selected_strategies = LearningStrategy.query.filter_by(
        organization_id=organization_id,
        selected=True
    ).order_by(LearningStrategy.priority.asc()).all()

    # Get actual competency IDs from database (not hardcoded)
    all_competencies = [c.id for c in Competency.query.order_by(Competency.id).all()]

    logger.info(
        f"[STEP 1 TASK-BASED] Retrieved {len(user_assessments)} task-based users, "
        f"{len(selected_strategies)} strategies"
    )

    return {
        'user_assessments': user_assessments,
        'selected_strategies': selected_strategies,
        'all_competencies': all_competencies
    }


# ============================================================================
# STEP 2: Calculate Current Competency Levels (MEDIAN)
# ============================================================================

def calculate_current_levels(user_assessments: List[UserAssessment], all_competencies: List[int]) -> Dict[int, float]:
    """
    Calculate median current competency levels across all task-based users

    Why MEDIAN instead of MEAN:
    - Not affected by outliers
    - Returns actual valid competency level (0, 1, 2, 4, 6)
    - Represents the "typical" user level

    Args:
        user_assessments: List of UserAssessment objects (task-based only)
        all_competencies: List of competency IDs (1-16)

    Returns:
        Dict mapping competency_id -> median_current_level

    Example:
        {
            1: 2,  # Systems Thinking median = 2
            2: 4,  # Requirements Engineering median = 4
            ...
        }
    """
    current_levels = {}

    for comp_id in all_competencies:
        scores = []

        for assessment in user_assessments:
            # Get competency score from this specific assessment
            score_obj = UserCompetencySurveyResult.query.filter_by(
                assessment_id=assessment.id,
                competency_id=comp_id
            ).first()

            if score_obj and score_obj.score is not None:
                scores.append(score_obj.score)

        # Calculate median (or 0 if no scores)
        if scores:
            current_levels[comp_id] = median(scores)
        else:
            current_levels[comp_id] = 0

    logger.info(f"[STEP 2 TASK-BASED] Calculated median levels for {len(current_levels)} competencies")

    return current_levels


# ============================================================================
# STEP 3: Get Archetype Targets from Strategies
# ============================================================================

def get_strategy_targets(strategy: LearningStrategy, all_competencies: List[int]) -> Dict[int, int]:
    """
    Get archetype target levels for a strategy

    Args:
        strategy: LearningStrategy object
        all_competencies: List of competency IDs (1-16)

    Returns:
        Dict mapping competency_id -> target_level

    Example:
        {
            1: 2,  # Foundation Workshop targets level 2 for Systems Thinking
            2: 2,  # Foundation Workshop targets level 2 for Requirements
            ...
        }
    """
    targets = {}

    for comp_id in all_competencies:
        # Get target from strategy_template_competency table (global templates)
        # Query via strategy's template_id link instead of per-org strategy_id
        if strategy.strategy_template_id:
            template_comp = StrategyTemplateCompetency.query.filter_by(
                strategy_template_id=strategy.strategy_template_id,
                competency_id=comp_id
            ).first()

            if template_comp:
                targets[comp_id] = template_comp.target_level
            else:
                # If no target defined in template, assume 0 (no training for this competency)
                targets[comp_id] = 0
        else:
            # Fallback: strategy not linked to template (shouldn't happen with new architecture)
            logger.warning(f"[TASK-BASED] Strategy {strategy.id} has no template_id, using 0 for competency {comp_id}")
            targets[comp_id] = 0

    logger.debug(f"[STEP 3 TASK-BASED] Retrieved targets for strategy '{strategy.strategy_name}'")

    return targets


# ============================================================================
# STEP 4: Scenario Classification and Priority Calculation
# ============================================================================

def classify_scenario(gap: int, strategy_can_achieve_target: bool = True) -> str:
    """
    Classify competency scenario based on gap analysis

    Task-based pathway uses simple 2-way comparison, so no "Scenario B"
    (strategy insufficiency is only for role-based 3-way comparison)

    Args:
        gap: Target level - Current level
        strategy_can_achieve_target: Always True for task-based (no validation layer)

    Returns:
        "Scenario A" | "Scenario C" | "Scenario D"
    """
    if gap == 0:
        return "Scenario D"  # Target achieved
    elif gap < 0:
        return "Scenario C"  # Over-training (current exceeds target)
    else:
        return "Scenario A"  # Normal training needed


def calculate_priority_score(gap: int, users_affected: int, is_core: bool = False) -> int:
    """
    Calculate priority score (0-10) for a competency

    Formula:
    - Gap size: larger gap = higher priority (0-6 points)
    - Users affected: more users = higher priority (0-2 points)
    - Core competency: +2 bonus points

    Args:
        gap: Number of levels difference (target - current)
        users_affected: Number of users needing training
        is_core: Whether this is a core competency

    Returns:
        int: Priority score from 0 to 10
    """
    # Base priority from gap (max 6 points)
    base_priority = min(abs(gap) * 2, 6)

    # User factor (max 2 points)
    # Scale: 1-3 users = 0.5, 4-6 = 1.0, 7-9 = 1.5, 10+ = 2.0
    user_factor = min(users_affected / 5, 2.0)

    # Core competency bonus
    core_bonus = 2 if is_core else 0

    total = base_priority + user_factor + core_bonus

    return min(int(round(total)), 10)


def calculate_users_affected(comp_id: int, user_assessments: List, target_level: int) -> int:
    """
    Count how many users need training for this competency

    Args:
        comp_id: Competency ID
        user_assessments: List of UserAssessment objects
        target_level: Strategy's target level for this competency

    Returns:
        int: Number of users whose current level < target level
    """
    count = 0
    for assessment in user_assessments:
        # Get user's score for this competency
        score = UserCompetencySurveyResult.query.filter_by(
            assessment_id=assessment.id,
            competency_id=comp_id
        ).first()

        if score and score.score < target_level:
            count += 1

    return count


def estimate_training_duration(gap: int) -> int:
    """
    Estimate training duration in hours based on gap

    Rule of thumb:
    - 1 level gap: 8 hours (1 day workshop)
    - 2 levels: 16 hours (2 days)
    - 3 levels: 24 hours (3 days)
    - 4+ levels: 40 hours (1 week intensive)

    Args:
        gap: Number of levels to improve

    Returns:
        int: Estimated hours needed
    """
    gap = abs(gap)
    if gap == 1:
        return 8
    elif gap == 2:
        return 16
    elif gap == 3:
        return 24
    else:
        return 40


def aggregate_scenario_distribution(trainable_competencies: List[Dict]) -> Dict[str, int]:
    """
    Count how many competencies fall into each scenario

    Args:
        trainable_competencies: List of competency objects with 'scenario' field

    Returns:
        dict: {"Scenario A": 5, "Scenario C": 1, "Scenario D": 2}
    """
    distribution = {}
    for comp in trainable_competencies:
        scenario = comp.get('scenario', 'Scenario A')
        distribution[scenario] = distribution.get(scenario, 0) + 1

    return distribution


# ============================================================================
# STRATEGY CLASSIFICATION: Dual-Track Processing
# ============================================================================

def classify_strategies_task_based(selected_strategies: List) -> tuple:
    """
    Separate gap-based (standard) from expert development (strategic) strategies

    Same logic as role-based pathway - Train the Trainer should be processed separately

    Returns:
        (gap_based_strategies, expert_strategies)
    """
    EXPERT_STRATEGY_PATTERNS = [
        'Train the trainer',
        'Train the SE-Trainer',
        'Train the SE trainer',
        'train the trainer'
    ]

    gap_based = []
    expert = []

    for strategy in selected_strategies:
        strategy_name_lower = strategy.strategy_name.lower()
        is_expert = any(
            pattern.lower() in strategy_name_lower
            for pattern in EXPERT_STRATEGY_PATTERNS
        )

        if is_expert:
            expert.append(strategy)
            logger.info(f"[CLASSIFICATION] '{strategy.strategy_name}' → EXPERT DEVELOPMENT (no validation)")
        else:
            gap_based.append(strategy)
            logger.debug(f"[CLASSIFICATION] '{strategy.strategy_name}' → GAP-BASED (standard)")

    logger.info(
        f"[CLASSIFICATION] Total strategies: {len(selected_strategies)} | "
        f"Gap-based: {len(gap_based)} | Expert: {len(expert)}"
    )

    return gap_based, expert


# ============================================================================
# STEP 5: 2-Way Comparison & Learning Objective Generation
# ============================================================================

def generate_task_based_learning_objectives(organization_id: int) -> Dict:
    """
    Main algorithm for task-based pathway with DUAL-TRACK PROCESSING

    2-WAY COMPARISON: Current Level vs Archetype Target
    - If current < target → Generate learning objective
    - If current >= target → Mark as target achieved

    DUAL-TRACK PROCESSING:
    - Gap-based strategies: Standard processing
    - Expert strategies (Train the Trainer): Separate simple processing

    NO validation layer (simpler for low-maturity orgs)

    Returns (Dual-Track):
        {
            'pathway': 'TASK_BASED_DUAL_TRACK' or 'TASK_BASED',
            'organization_id': 28,
            'generation_timestamp': '2025-11-04T12:00:00Z',
            'status': 'success',
            'assessment_summary': {...},
            'gap_based_training': {
                'strategy_count': 2,
                'learning_objectives_by_strategy': {...}
            },
            'expert_development': {
                'strategy_count': 1,
                'learning_objectives_by_strategy': {...}
            }
        }
    """
    from datetime import datetime

    logger.info(f"[START] Task-based pathway analysis for org {organization_id} (DUAL-TRACK)")

    # Step 1: Get data
    data = get_task_based_assessment_data(organization_id)

    if not data['user_assessments']:
        return {'error': 'No task-based assessments found for this organization'}

    if not data['selected_strategies']:
        return {'error': 'No learning strategies selected'}

    # NEW: Classify strategies into gap-based vs expert
    gap_based_strategies, expert_strategies = classify_strategies_task_based(data['selected_strategies'])

    total_users = len(data['user_assessments'])

    # Get PMT context if available
    pmt_context = PMTContext.query.filter_by(organization_id=organization_id).first()

    # Check if PMT is needed but missing
    needs_pmt = any(
        check_if_strategy_needs_pmt(strategy.strategy_name)
        for strategy in data['selected_strategies']
    )

    if needs_pmt and (not pmt_context or not pmt_context.is_complete()):
        logger.warning(
            f"[WARNING] Organization {organization_id} has strategies requiring PMT context, "
            f"but PMT context is {'missing' if not pmt_context else 'incomplete'}. "
            f"Learning objectives will use templates without customization."
        )

    # Step 2: Calculate current levels (median across users)
    current_levels = calculate_current_levels(
        data['user_assessments'],
        data['all_competencies']
    )

    # Step 3-4: Generate objectives for GAP-BASED strategies
    gap_based_objectives = {}

    for strategy in gap_based_strategies:
        logger.info(f"[STRATEGY] Processing: {strategy.strategy_name}")

        # Get strategy targets
        strategy_targets = get_strategy_targets(strategy, data['all_competencies'])

        # Check if this strategy requires deep customization
        requires_deep_customization = check_if_strategy_needs_pmt(strategy.strategy_name)

        # Separate core and trainable competencies
        core_competencies_output = []
        trainable_competencies_output = []

        for comp_id in data['all_competencies']:
            current_level = current_levels[comp_id]
            target_level = strategy_targets[comp_id]
            comp_name = get_competency_name(comp_id)

            # Skip if strategy doesn't target this competency
            if target_level == 0:
                continue

            # TRAINABLE COMPETENCIES - 2-WAY COMPARISON
            gap = target_level - current_level

            # Calculate users affected
            users_count = calculate_users_affected(comp_id, data['user_assessments'], target_level)

            # Classify scenario
            scenario = classify_scenario(gap)

            # Calculate priority
            priority = calculate_priority_score(gap, users_count, is_core=False)

            # Estimate duration
            duration = estimate_training_duration(gap)

            if current_level < target_level:
                # Training required

                # Get template (may include PMT breakdown)
                template_data = get_template_objective_full(comp_id, target_level)

                # get_template_objective_full returns: {'objective_text': str, 'has_pmt': bool, 'pmt_breakdown': dict|None}
                has_pmt_breakdown = isinstance(template_data, dict) and template_data.get('has_pmt', False)

                if has_pmt_breakdown:
                    base_template = template_data.get('objective_text', '[Template error]')
                    pmt_breakdown = template_data.get('pmt_breakdown')
                else:
                    base_template = template_data.get('objective_text', '[Template error]') if isinstance(template_data, dict) else str(template_data)
                    pmt_breakdown = None

                # Generate learning objective text
                if requires_deep_customization and pmt_context and pmt_context.is_complete():
                    # Deep customization with LLM
                    learning_objective = llm_deep_customize(
                        base_template,
                        pmt_context,
                        current_level,
                        target_level,
                        comp_id,
                        pmt_breakdown
                    )
                    pmt_applied = True
                else:
                    # Use template as-is (no customization)
                    learning_objective = base_template
                    pmt_applied = False

                trainable_obj = {
                    'competency_id': comp_id,
                    'competency_name': comp_name,
                    'current_level': current_level,
                    'target_level': target_level,
                    'gap': gap,
                    'scenario': scenario,
                    'priority_score': priority,
                    'users_affected': users_count,
                    'estimated_duration_hours': duration,
                    'role_requirement_level': None,  # N/A for task-based
                    'is_core': comp_id in CORE_COMPETENCIES,  # Flag core competencies
                    'core_note': get_core_competency_note(comp_id),  # Add informational note if core
                    'learning_objective_text': learning_objective,  # Renamed for consistency
                    'comparison_type': '2-way',
                    'status': 'training_required',
                    'pmt_customization_applied': pmt_applied
                }

                trainable_competencies_output.append(trainable_obj)

            else:
                # Target already achieved or over-training
                trainable_competencies_output.append({
                    'competency_id': comp_id,
                    'competency_name': comp_name,
                    'current_level': current_level,
                    'target_level': target_level,
                    'gap': gap,
                    'scenario': scenario,
                    'priority_score': 0,  # No training needed
                    'users_affected': 0,
                    'estimated_duration_hours': 0,
                    'role_requirement_level': None,
                    'is_core': comp_id in CORE_COMPETENCIES,  # Flag core competencies
                    'core_note': get_core_competency_note(comp_id),  # Add informational note if core
                    'learning_objective_text': None,
                    'comparison_type': '2-way',
                    'status': 'target_achieved',
                    'pmt_customization_applied': False
                })

        # Calculate scenario distribution for charts
        scenario_dist = aggregate_scenario_distribution(trainable_competencies_output)

        # Calculate summary statistics
        core_count = len([c for c in trainable_competencies_output if c.get('is_core', False)])

        gap_based_objectives[strategy.id] = {
            'strategy_id': strategy.id,
            'strategy_name': strategy.strategy_name,
            'requires_pmt': requires_deep_customization,
            'pmt_customization_applied': requires_deep_customization and pmt_context and pmt_context.is_complete(),
            'trainable_competencies': trainable_competencies_output,  # Now includes core competencies
            'scenario_distribution': scenario_dist,  # For charts
            'summary': {
                'total_competencies': len(trainable_competencies_output),
                'core_competencies_count': core_count,
                'trainable_competencies_count': len(trainable_competencies_output),
                'competencies_requiring_training': len([
                    obj for obj in trainable_competencies_output if obj.get('status') == 'training_required'
                ]),
                'competencies_targets_achieved': len([
                    obj for obj in trainable_competencies_output if obj.get('status') == 'target_achieved'
                ])
            }
        }

    logger.info(
        f"[GAP-BASED] Generated objectives for {len(gap_based_objectives)} gap-based strategies"
    )

    # Step 5: Process EXPERT strategies (simple 2-way comparison)
    expert_objectives = {}

    if expert_strategies:
        logger.info(f"[EXPERT] Processing {len(expert_strategies)} expert strategies")

        for strategy in expert_strategies:
            logger.info(f"[EXPERT STRATEGY] Processing: {strategy.strategy_name}")

            strategy_targets = get_strategy_targets(strategy, data['all_competencies'])

            trainable_competencies_output = []

            for comp_id in data['all_competencies']:
                current_level = current_levels[comp_id]
                target_level = strategy_targets[comp_id]
                comp_name = get_competency_name(comp_id)

                if target_level == 0:
                    continue

                gap = target_level - current_level

                if gap > 0:
                    # Training required - use template only (no PMT for expert)
                    template_data = get_template_objective_full(comp_id, target_level)

                    # get_template_objective_full returns: {'objective_text': str, 'has_pmt': bool, 'pmt_breakdown': dict|None}
                    if isinstance(template_data, dict) and 'objective_text' in template_data:
                        learning_objective = template_data['objective_text']
                    else:
                        learning_objective = str(template_data) if template_data else '[Template error]'

                    trainable_competencies_output.append({
                        'competency_id': comp_id,
                        'competency_name': comp_name,
                        'current_level': current_level,
                        'target_level': target_level,
                        'gap': gap,
                        'status': 'expert_development_required',
                        'learning_objective_text': learning_objective,
                        'comparison_type': '2-way-expert',
                        'users_assessed': total_users,
                        'note': f'Mastery-level training - Gap of {gap} levels'
                    })
                else:
                    trainable_competencies_output.append({
                        'competency_id': comp_id,
                        'competency_name': comp_name,
                        'current_level': current_level,
                        'target_level': target_level,
                        'gap': 0,
                        'status': 'expert_level_achieved',
                        'comparison_type': '2-way-expert',
                        'note': 'Mastery level already achieved'
                    })

            expert_objectives[strategy.strategy_name] = {
                'strategy_id': strategy.id,
                'strategy_name': strategy.strategy_name,
                'strategy_type': 'EXPERT_DEVELOPMENT',
                'target_level_all_competencies': 6,
                'purpose': 'Develop expert internal trainers with mastery-level competencies',
                'typical_audience': 'Select individuals (1-5 people)',
                'typical_delivery': 'External certification programs',
                'note': 'Strategic capability investment, not subject to validation',
                'trainable_competencies': trainable_competencies_output,
                'summary': {
                    'total_competencies': len(trainable_competencies_output),
                    'competencies_requiring_training': len([
                        obj for obj in trainable_competencies_output if obj.get('status') == 'expert_development_required'
                    ]),
                    'competencies_achieved': len([
                        obj for obj in trainable_competencies_output if obj.get('status') == 'expert_level_achieved'
                    ])
                }
            }

        logger.info(f"[EXPERT] Generated objectives for {len(expert_objectives)} expert strategies")

    # Determine pathway name based on whether we have both tracks
    pathway_name = 'TASK_BASED_DUAL_TRACK' if expert_objectives else 'TASK_BASED'

    logger.info(f"[COMPLETE] Task-based pathway: {pathway_name}")

    # Format output with dual-track structure
    if expert_objectives:
        # Dual-track result
        result = {
            'organization_id': organization_id,
            'pathway': pathway_name,
            'generation_timestamp': datetime.utcnow().isoformat() + 'Z',
            'status': 'success',

            'assessment_summary': {
                'total_users': total_users,
                'survey_type': 'unknown_roles',
                'using_latest_only': True
            },

            # Gap-based training
            'gap_based_training': {
                'strategy_count': len(gap_based_strategies),
                'learning_objectives_by_strategy': gap_based_objectives,
                'note': 'Gap-based strategies using 2-way comparison (Current vs Target)'
            },

            # Expert development
            'expert_development': {
                'strategy_count': len(expert_strategies),
                'strategies': [s.strategy_name for s in expert_strategies],
                'note': 'Expert development strategies represent strategic capability investments '
                        'and are processed separately without gap-based validation. These typically '
                        'target mastery-level (Level 6) competencies.',
                'learning_objectives_by_strategy': expert_objectives
            },

            'validation_note': 'Task-based pathway does not require strategy validation layer'
        }
    else:
        # Standard single-track result (backward compatible)
        result = {
            'organization_id': organization_id,
            'pathway': 'TASK_BASED',
            'generation_timestamp': datetime.utcnow().isoformat() + 'Z',
            'status': 'success',

            'assessment_summary': {
                'total_users': total_users,
                'survey_type': 'unknown_roles',
                'using_latest_only': True
            },

            'learning_objectives_by_strategy': gap_based_objectives,

            'validation_note': 'Task-based pathway does not require strategy validation layer'
        }

    return result


# ============================================================================
# EXPORT
# ============================================================================

__all__ = [
    'generate_task_based_learning_objectives',
    'get_task_based_assessment_data',
    'calculate_current_levels',
    'get_strategy_targets'
]
