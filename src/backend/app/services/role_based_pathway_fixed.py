"""
Phase 2 Task-Based Assessment - Role-Based Pathway Algorithm
============================================================

COMPLETE IMPLEMENTATION with Multi-Role User Bug Fix

This module implements the complete 8-step role-based pathway algorithm:

Steps 1-4 (TESTED & VALIDATED):
1. Get assessment data
2. Analyze all roles (WITH CRITICAL FIX)
3. Aggregate by user distribution
4. Cross-strategy coverage with best-fit selection

Steps 5-8 (NEW):
5. Strategy validation layer (holistic assessment)
6. Strategic decisions (recommendations)
7. Gap analysis & learning objectives generation
8. Output formatting & storage

Enhancements:
- CRITICAL FIX: Multi-role users use MAX requirement across all roles
- ENHANCEMENT: Explicit tie-breaking logic
- ENHANCEMENT: Negative fit score warnings
- ENHANCEMENT: Zero users exclusion from best-fit selection

IMPORTANT DATA SOURCES (READ THIS!):
===================================

Q: Which roles does this algorithm use?
A: OrganizationRoles (user-defined roles from Phase 1 Task 2)
   NOT RoleCluster (14 standard INCOSE reference roles)

Q: Which strategies does it use?
A: LearningStrategy (Phase 2 specific training programs)
   NOT Organization.selected_archetype (Phase 1 high-level approach)

Relationship:
┌────────────────────────────────────────────────────────────┐
│ Phase 1 Archetype: "Certification" (philosophy)            │
│         ↓ (guides selection of)                            │
│ Phase 2 Strategies: "CSEP Foundation", "CSEP Advanced"     │
│         ↓ (algorithm analyzes and recommends)              │
│ Output: User-specific learning recommendations             │
└────────────────────────────────────────────────────────────┘

See models.py (lines 955-987) for detailed data mapping documentation.

Date: November 4, 2025
Status: COMPLETE - Production Ready
"""

from typing import Dict, List, Set, Tuple, Optional
import logging
from flask import current_app
from app.services.config_loader import get_validation_thresholds, get_priority_weights

logger = logging.getLogger(__name__)

# Import compatibility layer - works both in Flask context and standalone
try:
    # Try Flask app context first (production)
    from app import models as app_models
    from app.models import (
        UserAssessment, Role, LearningStrategy, RoleCompetency,
        StrategyTemplateCompetency, CompetencyScore, PMTContext, Competency
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
        UserAssessment, Role, LearningStrategy, RoleCompetency,
        StrategyTemplateCompetency, CompetencyScore, PMTContext, Competency
    )
    # Import text generator from same directory
    import sys
    import os
    sys.path.insert(0, os.path.dirname(__file__))
    from app.services.learning_objectives_text_generator import (
        get_template_objective,
        get_template_objective_full,
        llm_deep_customize,
        check_if_strategy_needs_pmt,
        get_competency_name,
        get_core_competency_note,
        CORE_COMPETENCIES
    )


# ============================================================================
# STEP 1: Get Data
# ============================================================================

def get_assessment_data(organization_id: int):
    """
    Get all required data for role-based pathway analysis

    Returns:
        {
            'user_assessments': List[UserAssessment],
            'organization_roles': List[Role],
            'selected_strategies': List[Strategy],
            'all_competencies': List[int]  # All competency IDs from database
        }
    """
    # Get all completed user assessments
    user_assessments = UserAssessment.query.filter_by(
        organization_id=organization_id
    ).filter(
        UserAssessment.completed_at.isnot(None)
    ).all()

    # Get organization's selected roles
    organization_roles = Role.query.filter_by(
        organization_id=organization_id
    ).all()

    # Get selected learning strategies
    selected_strategies = LearningStrategy.query.filter_by(
        organization_id=organization_id,
        selected=True
    ).all()

    # Get all competency IDs dynamically from database
    all_competencies = [c.id for c in Competency.query.order_by(Competency.id).all()]

    logger.info(
        f"[STEP 1] Retrieved data: {len(user_assessments)} users, "
        f"{len(organization_roles)} roles, {len(selected_strategies)} strategies"
    )

    return {
        'user_assessments': user_assessments,
        'organization_roles': organization_roles,
        'selected_strategies': selected_strategies,
        'all_competencies': all_competencies
    }


def extract_user_assessment_details(user_assessments: List, all_competencies: List[int]) -> List[Dict]:
    """
    Extract detailed user assessment data for frontend Algorithm Explanation Card

    Returns array of user assessment details with competency scores
    """
    user_details = []

    for assessment in user_assessments:
        # Get competency scores for this user
        competencies_data = []

        for comp_id in all_competencies:
            score = CompetencyScore.query.filter_by(
                assessment_id=assessment.id,
                competency_id=comp_id
            ).first()

            competencies_data.append({
                'id': comp_id,
                'name': get_competency_name(comp_id),
                'current_level': score.score if score else 0
            })

        # Get user's role name(s) from assessment
        role_name = "Unknown"
        if assessment.selected_roles:
            # Handle JSON field - could be list or stringified JSON
            role_ids = assessment.selected_roles
            if isinstance(role_ids, str):
                import json
                try:
                    role_ids = json.loads(role_ids)
                except:
                    role_ids = []

            if role_ids and isinstance(role_ids, list):
                roles = Role.query.filter(Role.id.in_(role_ids)).all()
                role_name = ", ".join([r.role_name for r in roles]) if roles else "Unknown"

        user_details.append({
            'user_id': assessment.user_id,
            'username': assessment.user.username if assessment.user else f"User {assessment.user_id}",
            'role': role_name,
            'competencies': competencies_data
        })

    logger.info(f"[extract_user_assessment_details] Extracted data for {len(user_details)} users")
    return user_details


def extract_role_requirements(organization_roles: List, all_competencies: List[int]) -> List[Dict]:
    """
    Extract role competency requirements for frontend Algorithm Explanation Card

    Returns array of role requirements with competency levels
    """
    role_requirements = []

    for role in organization_roles:
        requirements_data = []

        for comp_id in all_competencies:
            role_comp = RoleCompetency.query.filter_by(
                role_cluster_id=role.id,
                competency_id=comp_id
            ).first()

            # Get level (-100 for N/A, or actual level 0-6)
            level = role_comp.role_competency_value if (role_comp and role_comp.role_competency_value is not None) else -100

            requirements_data.append({
                'id': comp_id,
                'name': get_competency_name(comp_id),
                'level': level
            })

        role_requirements.append({
            'role_id': role.id,
            'role_name': role.role_name,
            'requirements': requirements_data
        })

    logger.info(f"[extract_role_requirements] Extracted requirements for {len(role_requirements)} roles")
    return role_requirements


def extract_role_analysis_details(
    role_analyses: Dict,
    organization_roles: List,
    user_assessments: List,
    selected_strategies: List,
    all_competencies: List[int]
) -> Dict:
    """
    Extract detailed role analysis data for frontend Algorithm Explanation Card (Step 2)

    Shows:
    - Median current level calculations per role per competency
    - Scenario classifications for each user per role per competency per strategy

    Args:
        role_analyses: Output from analyze_all_roles_fixed()
        organization_roles: List of organization roles
        user_assessments: List of user assessments
        selected_strategies: List of selected strategies
        all_competencies: List of all competency IDs

    Returns:
        {
            role_id: {
                role_name: str,
                competency_analyses: {
                    competency_id: {
                        competency_name: str,
                        users_in_role: [user_ids],
                        user_scores: {user_id: score},
                        median_current_level: int,
                        by_strategy: {
                            strategy_name: {
                                strategy_id: int,
                                strategy_target: int,
                                role_requirement: int,
                                scenario_classifications: {user_id: 'A'|'B'|'C'|'D'},
                                scenario_counts: {A: int, B: int, C: int, D: int}
                            }
                        }
                    }
                }
            }
        }
    """
    from statistics import median

    logger.info("[extract_role_analysis_details] Starting extraction...")

    role_analysis_details = {}

    for role in organization_roles:
        role_id = role.id
        role_name = role.role_name

        # Get users in this role
        users_in_role = [u for u in user_assessments if role_id in [r.id for r in u.selected_role_objects]]

        if not users_in_role:
            continue  # Skip roles with no users

        competency_analyses = {}

        for comp_id in all_competencies:
            comp_name = get_competency_name(comp_id)

            # Get user scores for this competency in this role
            user_scores = {}
            score_list = []

            for user in users_in_role:
                comp_score = CompetencyScore.query.filter_by(
                    user_id=user.user_id,
                    competency_id=comp_id
                ).first()

                score = comp_score.score if comp_score else 0
                user_scores[user.user_id] = score
                score_list.append(score)

            # Calculate median
            median_level = int(median(score_list)) if score_list else 0

            # Get role requirement for this competency
            role_comp = RoleCompetency.query.filter_by(
                role_cluster_id=role_id,
                competency_id=comp_id
            ).first()
            role_requirement = role_comp.role_competency_value if (role_comp and role_comp.role_competency_value is not None) else 0

            # Extract scenario classifications per strategy
            by_strategy = {}

            for strategy in selected_strategies:
                strategy_id = strategy.id
                strategy_name = strategy.strategy_name

                # Get strategy target
                target_level = get_strategy_target_level(strategy, comp_id)
                if target_level is None:
                    continue

                # Get scenario classifications for users in this role
                scenario_classifications = {}
                scenario_counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0}

                if strategy_id in role_analyses and comp_id in role_analyses[strategy_id]:
                    all_scenario_classifications = role_analyses[strategy_id][comp_id]['scenario_classifications']

                    for user in users_in_role:
                        if user.user_id in all_scenario_classifications:
                            scenario = all_scenario_classifications[user.user_id]
                            scenario_classifications[user.user_id] = scenario
                            scenario_counts[scenario] += 1

                by_strategy[strategy_name] = {
                    'strategy_id': strategy_id,
                    'strategy_target': target_level,
                    'role_requirement': role_requirement,
                    'scenario_classifications': scenario_classifications,
                    'scenario_counts': scenario_counts
                }

            competency_analyses[comp_id] = {
                'competency_id': comp_id,
                'competency_name': comp_name,
                'users_in_role': [u.user_id for u in users_in_role],
                'user_count': len(users_in_role),
                'user_scores': user_scores,
                'median_current_level': median_level,
                'role_requirement': role_requirement,
                'by_strategy': by_strategy
            }

        role_analysis_details[role_id] = {
            'role_id': role_id,
            'role_name': role_name,
            'user_count': len(users_in_role),
            'competency_analyses': competency_analyses
        }

    logger.info(f"[extract_role_analysis_details] Extracted data for {len(role_analysis_details)} roles")
    return role_analysis_details


def get_competency_name(competency_id: int) -> str:
    """Helper: Get competency name from database"""
    try:
        comp = Competency.query.get(competency_id)
        return comp.competency_name if comp else f'Competency {competency_id}'
    except Exception as e:
        logger.warning(f"[get_competency_name] Error fetching name for ID {competency_id}: {e}")
        return f'Competency {competency_id}'


def generate_coverage_summary(
    coverage: Dict,
    all_strategy_fit_scores: Dict,
    selected_strategies: List,
    organization_roles: List,
    all_competencies: List[int],
    user_assessments: List
) -> List[Dict]:
    """
    Generate summary table data for Step 4 display (all 16 competencies at a glance)

    Args:
        coverage: Cross-strategy coverage from Step 4
        all_strategy_fit_scores: Fit scores for all strategies (from enhanced Step 4)
        selected_strategies: List of selected strategies
        organization_roles: List of organization roles (for max_role_requirement calculation)
        all_competencies: List of all competency IDs (for max_role_requirement calculation)
        user_assessments: List of user assessments (for current level calculation)

    Returns:
        Array of competency summaries:
        [
            {
                competency_id: int,
                competency_name: str,
                best_fit_strategy_id: int,
                best_fit_strategy: str,
                best_fit_score: float,
                scenario_B_count: int,
                scenario_B_percentage: float,
                gap_severity: str,
                current_level: int,  # NEW: Organizational median current level
                max_role_requirement: int,  # FIXED: Now calculated from actual role requirements
                target_level: int,
                all_strategies_count: int
            },
            ...
        ]
    """
    logger.info("[generate_coverage_summary] Starting generation...")

    # CRITICAL FIX: Pre-calculate max role requirements for all competencies
    max_role_requirements = {}
    for competency_id in all_competencies:
        max_req = 0
        for role in organization_roles:
            req = get_role_requirement(role.id, competency_id)
            if req != -100:  # Exclude N/A values
                max_req = max(max_req, req)
        max_role_requirements[competency_id] = max_req

    logger.info(f"[generate_coverage_summary] Calculated max role requirements for {len(max_role_requirements)} competencies")

    # NEW: Pre-calculate organizational median current levels for all competencies
    org_current_levels = {}
    for competency_id in all_competencies:
        all_scores = []
        for user in user_assessments:
            comp_score = CompetencyScore.query.filter_by(
                user_id=user.user_id,
                competency_id=competency_id
            ).first()
            if comp_score and comp_score.score is not None:
                all_scores.append(comp_score.score)

        # Calculate organizational median
        org_current_levels[competency_id] = calculate_median(all_scores) if all_scores else 0

    logger.info(f"[generate_coverage_summary] Calculated organizational current levels for {len(org_current_levels)} competencies")

    summary = []

    for comp_id_str, comp_data in coverage.items():
        comp_id = int(comp_id_str)

        # Get best-fit strategy info
        best_fit_strategy_id = comp_data.get('best_fit_strategy_id')
        best_fit_strategy_name = 'Unknown'

        # Find strategy name from ID
        for strategy in selected_strategies:
            if strategy.id == best_fit_strategy_id:
                best_fit_strategy_name = strategy.strategy_name
                break

        # Get aggregation data (this has scenario counts!)
        aggregation = comp_data.get('aggregation', {})

        # Get scenario B data
        scenario_B_count = aggregation.get('scenario_B_count', 0)
        scenario_B_percentage = aggregation.get('scenario_B_percentage', 0)

        # Calculate gap severity based on Scenario B percentage
        if scenario_B_percentage > 60:
            gap_severity = 'critical'
        elif scenario_B_percentage >= 20:
            gap_severity = 'significant'
        elif scenario_B_percentage > 0:
            gap_severity = 'minor'
        else:
            gap_severity = 'none'

        # Get competency name directly from database
        comp_name = get_competency_name(comp_id)

        # Get fit scores data
        fit_scores_entry = all_strategy_fit_scores.get(comp_id_str, {})

        # DEBUG: Log what we received
        if comp_id == 1:  # Only log for competency 1 to avoid spam
            logger.info(f"[generate_coverage_summary] DEBUG comp_id=1:")
            logger.info(f"  fit_scores_entry keys: {list(fit_scores_entry.keys())}")
            logger.info(f"  fit_scores_entry type: {type(fit_scores_entry)}")
            strategies_in_entry = fit_scores_entry.get('strategies', [])
            logger.info(f"  strategies count: {len(strategies_in_entry)}")
            if strategies_in_entry:
                logger.info(f"  First strategy: {strategies_in_entry[0]}")

        # Get target level and strategy count
        strategies_list = fit_scores_entry.get('strategies', [])
        target_level = 0
        all_strategies_count = len(strategies_list)

        # Find target level for best-fit strategy
        for strategy_data in strategies_list:
            if strategy_data.get('strategy_id') == best_fit_strategy_id:
                target_level = strategy_data.get('target_level', 0)
                break

        # FIXED: Get max role requirement from pre-calculated values
        max_role_requirement = max_role_requirements.get(comp_id, 0)

        # NEW: Get organizational median current level
        current_level = org_current_levels.get(comp_id, 0)

        summary_entry = {
            'competency_id': comp_id,
            'competency_name': comp_name,
            'best_fit_strategy_id': best_fit_strategy_id,
            'best_fit_strategy': best_fit_strategy_name,
            'best_fit_score': comp_data.get('fit_score', 0),
            'scenario_B_count': scenario_B_count,
            'scenario_B_percentage': scenario_B_percentage,
            'gap_severity': gap_severity,
            'current_level': current_level,  # NEW: Organizational median
            'max_role_requirement': max_role_requirement,
            'target_level': target_level,
            'all_strategies_count': all_strategies_count
        }

        logger.debug(f"[generate_coverage_summary] Comp {comp_id} ({comp_name}): current={current_level}, target={target_level}, strategy={best_fit_strategy_name}, score={comp_data.get('fit_score', 0):.2f}, strategies_count={all_strategies_count}")

        summary.append(summary_entry)

    # Sort by competency ID
    summary.sort(key=lambda x: x['competency_id'])

    logger.info(f"[generate_coverage_summary] Generated summary for {len(summary)} competencies")
    return summary


# ============================================================================
# CRITICAL FIX: Multi-Role User Max Requirements
# ============================================================================

def get_user_max_role_requirements(
    user_id: int,
    user_selected_roles: List[int],
    all_competencies: List[int]
) -> Dict[int, int]:
    """
    CRITICAL FIX: For multi-role users, return MAX requirement per competency

    This prevents the critical bug where multi-role users are counted in
    multiple scenarios simultaneously.

    Args:
        user_id: User ID
        user_selected_roles: List of role IDs the user selected
        all_competencies: List of all competency IDs

    Returns:
        Dict[competency_id] = max_requirement_level
    """
    max_requirements = {}

    for competency_id in all_competencies:
        requirements = []

        for role_id in user_selected_roles:
            role_comp = RoleCompetency.query.filter_by(
                role_cluster_id=role_id,  # Note: role_cluster_id is the FK to organization_roles
                competency_id=competency_id
            ).first()

            if role_comp and role_comp.role_competency_value is not None:
                requirements.append(role_comp.role_competency_value)

        # Use MAX requirement across all roles
        max_requirements[competency_id] = max(requirements) if requirements else 0

    logger.debug(
        f"User {user_id} has {len(user_selected_roles)} roles. "
        f"Max requirements calculated for {len(max_requirements)} competencies"
    )

    return max_requirements


# ============================================================================
# STRATEGY CLASSIFICATION: Dual-Track Processing
# ============================================================================

def classify_strategies(selected_strategies: List) -> Tuple[List, List]:
    """
    Separate gap-based (standard) from expert development (strategic) strategies

    Gap-Based Strategies:
    - Common basic understanding
    - SE for managers
    - Orientation in pilot project
    - Needs-based project-oriented training
    - Continuous support
    - Certification

    Expert Development Strategies:
    - Train the trainer (Level 6 for all competencies)
    - Train the SE-Trainer (variations in naming)

    Critical Issue: "Train the Trainer" has Level 6 targets for ALL competencies,
    causing 90-100% Scenario C classifications and highly negative fit scores.
    It should be processed separately without validation.

    Returns:
        (gap_based_strategies, expert_strategies)
    """
    EXPERT_STRATEGY_PATTERNS = [
        'Train the trainer',
        'Train the SE-Trainer',
        'Train the SE trainer',
        'train the trainer'  # lowercase variant
    ]

    gap_based = []
    expert = []

    for strategy in selected_strategies:
        # Case-insensitive partial matching
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
            logger.debug(f"[CLASSIFICATION] '{strategy.strategy_name}' → GAP-BASED (full validation)")

    logger.info(
        f"[CLASSIFICATION] Total strategies: {len(selected_strategies)} | "
        f"Gap-based: {len(gap_based)} | Expert: {len(expert)}"
    )

    return gap_based, expert


def process_expert_strategies_simple(
    organization_id: int,
    expert_strategies: List,
    user_assessments: List,
    all_competencies: List[int],
    pmt_context
) -> Dict:
    """
    Simple 2-way processing for expert development strategies (e.g., Train the Trainer)

    No validation, no scenario classification, no fit scores.
    Just: current organizational level vs target level → generate objectives

    Expert strategies are strategic capability investments targeting mastery-level
    competencies (Level 6) for select individuals to develop internal training capacity.

    Args:
        organization_id: Organization ID
        expert_strategies: List of expert development strategies
        user_assessments: All user assessments
        all_competencies: List of all competency IDs
        pmt_context: PMT context (optional, typically not used for expert strategies)

    Returns:
        Dictionary of learning objectives by strategy (no validation context)
    """
    if not expert_strategies:
        return {}

    logger.info(f"[EXPERT PROCESSING] Processing {len(expert_strategies)} expert strategies (simple 2-way)")

    objectives = {}

    for strategy in expert_strategies:
        logger.info(f"[EXPERT] Processing strategy: {strategy.strategy_name}")

        strategy_objectives = {
            'strategy_id': strategy.id,
            'strategy_name': strategy.strategy_name,
            'strategy_type': 'EXPERT_DEVELOPMENT',
            'target_level_all_competencies': 6,
            'purpose': 'Develop expert internal trainers with mastery-level competencies',
            'typical_audience': 'Select individuals (1-5 people)',
            'typical_delivery': 'External certification programs or advanced workshops',
            'note': 'This is a strategic capability investment, not subject to gap-based validation',
            'trainable_competencies': []
        }

        competencies_requiring_training = 0
        competencies_achieved = 0

        for competency_id in all_competencies:
            # Get target level for this competency from strategy template
            target_level = get_strategy_target_level(strategy, competency_id)

            if target_level is None or target_level == 0:
                continue  # Strategy doesn't train this competency

            # Calculate organizational median current level
            current_scores = []
            for user in user_assessments:
                # CRITICAL FIX: Use user.user_id (FK to users), NOT user.id (assessment ID)
                comp_score = CompetencyScore.query.filter_by(
                    user_id=user.user_id,
                    competency_id=competency_id
                ).first()

                if comp_score and comp_score.score is not None:
                    current_scores.append(comp_score.score)

            if not current_scores:
                logger.warning(
                    f"[EXPERT] No scores for competency {competency_id} - skipping"
                )
                continue

            current_level = calculate_median(current_scores)
            gap = target_level - current_level

            competency_name = get_competency_name(competency_id)

            if gap > 0:
                # Training required
                competencies_requiring_training += 1

                # Get template objective (no PMT customization for expert strategies)
                objective_text = get_template_objective(competency_id, target_level)

                strategy_objectives['trainable_competencies'].append({
                    'competency_id': competency_id,
                    'competency_name': competency_name,
                    'current_level': current_level,
                    'target_level': target_level,
                    'gap': gap,
                    'status': 'expert_development_required',
                    'learning_objective': objective_text,
                    'comparison_type': '2-way-expert',
                    'users_assessed': len(current_scores),
                    'note': f'Mastery-level training - Gap of {gap} levels from organizational median'
                })
            else:
                # Target already achieved
                competencies_achieved += 1

                strategy_objectives['trainable_competencies'].append({
                    'competency_id': competency_id,
                    'competency_name': competency_name,
                    'current_level': current_level,
                    'target_level': target_level,
                    'gap': 0,
                    'status': 'expert_level_achieved',
                    'comparison_type': '2-way-expert',
                    'note': 'Organization has already achieved mastery level for this competency'
                })

        # Add summary
        strategy_objectives['summary'] = {
            'total_competencies': len(all_competencies),
            'competencies_requiring_training': competencies_requiring_training,
            'competencies_achieved': competencies_achieved,
            'note': f'Expert development for {competencies_requiring_training} competencies at mastery level (6)'
        }

        objectives[strategy.strategy_name] = strategy_objectives

        logger.info(
            f"[EXPERT] {strategy.strategy_name}: "
            f"{competencies_requiring_training} require training, "
            f"{competencies_achieved} achieved"
        )

    return objectives


# ============================================================================
# STEP 2: Analyze All Roles (with CRITICAL FIX)
# ============================================================================

def classify_gap_scenario(
    current_level: int,
    archetype_target: int,
    role_requirement: int
) -> str:
    """
    Classify user into one of 4 scenarios

    Returns: 'A', 'B', 'C', or 'D'
    """
    # Scenario D: Target already met
    if current_level >= role_requirement and current_level >= archetype_target:
        return 'D'

    # Scenario C: Over-training
    if archetype_target > role_requirement:
        return 'C'

    # Scenario B: Strategy insufficient
    if archetype_target <= current_level < role_requirement:
        return 'B'

    # Scenario A: Normal training
    if current_level < archetype_target <= role_requirement:
        return 'A'

    # Default fallback
    return 'A'


def analyze_all_roles_fixed(
    organization_roles: List,
    user_assessments: List,
    selected_strategies: List,
    all_competencies: List[int]
) -> Dict:
    """
    STEP 2: Analyze all roles with CRITICAL FIX for multi-role users

    Key difference from original: Multi-role users are evaluated against
    their MAX role requirement only, preventing scenario conflicts.

    Returns:
        {
            strategy_id: {
                competency_id: {
                    'scenario_classifications': {
                        user_id: scenario ('A', 'B', 'C', or 'D')
                    }
                }
            }
        }
    """
    # CRITICAL FIX: Preprocess multi-role users
    multi_role_requirements = {}
    for user in user_assessments:
        user_role_ids = [r.id for r in user.selected_role_objects]
        if len(user_role_ids) > 1:
            multi_role_requirements[user.user_id] = get_user_max_role_requirements(
                user.user_id,
                user_role_ids,
                all_competencies
            )
            logger.debug(
                f"User {user.user_id} has multiple roles: {user_role_ids}. "
                f"Using max requirements."
            )

    role_analyses = {}

    for strategy in selected_strategies:
        role_analyses[strategy.id] = {}

        for competency_id in all_competencies:
            scenario_classifications = {}

            # Get strategy target for this competency
            archetype_target = get_strategy_target_level(strategy, competency_id)

            if archetype_target is None:
                continue

            # Classify each user
            for user in user_assessments:
                # Get user's current level
                # CRITICAL FIX: Use user.user_id (FK to users), NOT user.id (assessment ID)
                comp_score = CompetencyScore.query.filter_by(
                    user_id=user.user_id,  # Fixed: was user.id (assessment ID)
                    competency_id=competency_id
                ).first()

                current_level = comp_score.score if comp_score else 0

                # CRITICAL FIX: Determine role requirement
                if user.user_id in multi_role_requirements:
                    # Multi-role user: use MAX requirement
                    role_requirement = multi_role_requirements[user.user_id][competency_id]
                else:
                    # Single-role user: use that role's requirement
                    user_role_ids = [r.id for r in user.selected_role_objects]
                    if user_role_ids:
                        role_requirement = get_role_requirement(
                            user_role_ids[0],
                            competency_id
                        )
                    else:
                        role_requirement = 0

                # Classify scenario
                scenario = classify_gap_scenario(
                    current_level,
                    archetype_target,
                    role_requirement
                )

                # CRITICAL FIX: Use user.user_id (actual user ID), not user.id (assessment ID)
                scenario_classifications[user.user_id] = scenario

            role_analyses[strategy.id][competency_id] = {
                'scenario_classifications': scenario_classifications
            }

    logger.info(
        f"[STEP 2] Analyzed {len(selected_strategies)} strategies "
        f"with multi-role fix applied"
    )

    return role_analyses


def get_strategy_target_level(strategy, competency_id: int) -> Optional[int]:
    """
    Helper: Get strategy's target level for a competency

    Uses global strategy_template_competency via strategy's template_id link
    instead of per-organization strategy_competency table
    """
    if strategy.strategy_template_id:
        template_comp = StrategyTemplateCompetency.query.filter_by(
            strategy_template_id=strategy.strategy_template_id,
            competency_id=competency_id
        ).first()

        return template_comp.target_level if template_comp else None
    else:
        # Fallback: strategy not linked to template (shouldn't happen)
        logger.warning(f"[ROLE-BASED] Strategy {strategy.id} has no template_id for competency {competency_id}")
        return None


def get_role_requirement(role_id: int, competency_id: int) -> int:
    """Helper: Get role's requirement level for a competency"""
    role_comp = RoleCompetency.query.filter_by(
        role_cluster_id=role_id,  # Note: role_cluster_id is the FK to organization_roles
        competency_id=competency_id
    ).first()

    # CRITICAL FIX: Check for 'is not None' instead of truthiness
    # 0 is a valid competency level (Awareness) but evaluates to False!
    return role_comp.role_competency_value if (role_comp and role_comp.role_competency_value is not None) else 0


# ============================================================================
# STEP 3: Aggregate by User Distribution (FIXED)
# ============================================================================

def aggregate_by_user_distribution(
    scenario_classifications: Dict[int, str],
    total_users: int
) -> Dict:
    """
    STEP 3: Aggregate users by scenario with percentage calculation

    With the CRITICAL FIX in Step 2, each user appears in exactly ONE scenario,
    so percentages will always sum to 100%.

    Returns:
        {
            'scenario_A_count': int,
            'scenario_B_count': int,
            'scenario_C_count': int,
            'scenario_D_count': int,
            'scenario_A_percentage': float,
            'scenario_B_percentage': float,
            'scenario_C_percentage': float,
            'scenario_D_percentage': float
        }
    """
    unique_users_by_scenario = {
        'A': set(),
        'B': set(),
        'C': set(),
        'D': set()
    }

    for user_id, scenario in scenario_classifications.items():
        unique_users_by_scenario[scenario].add(user_id)

    # Calculate counts
    counts = {s: len(users) for s, users in unique_users_by_scenario.items()}

    # Calculate percentages
    percentages = {
        s: (count / total_users * 100.0) if total_users > 0 else 0.0
        for s, count in counts.items()
    }

    # Verify percentages sum to 100% (with CRITICAL FIX, this should always pass)
    total_percentage = sum(percentages.values())
    if abs(total_percentage - 100.0) > 0.1 and total_users > 0:
        logger.error(
            f"[BUG] Percentages sum to {total_percentage:.1f}%, not 100%! "
            f"Multi-role fix may have failed."
        )

    return {
        'scenario_A_count': counts['A'],
        'scenario_B_count': counts['B'],
        'scenario_C_count': counts['C'],
        'scenario_D_count': counts['D'],
        'scenario_A_percentage': percentages['A'],
        'scenario_B_percentage': percentages['B'],
        'scenario_C_percentage': percentages['C'],
        'scenario_D_percentage': percentages['D'],
        'users_by_scenario': {
            'A': list(unique_users_by_scenario['A']),
            'B': list(unique_users_by_scenario['B']),
            'C': list(unique_users_by_scenario['C']),
            'D': list(unique_users_by_scenario['D'])
        }
    }


# ============================================================================
# STEP 4: Cross-Strategy Coverage with ENHANCEMENTS
# ============================================================================

def calculate_fit_score(aggregation: Dict, total_users: int) -> float:
    """
    Calculate normalized fit score

    Fit = (A * 1.0) + (D * 1.0) + (B * -2.0) + (C * -0.5)
    Normalized = Fit / total_users
    """
    if total_users == 0:
        return 0.0

    fit_score = (
        aggregation['scenario_A_count'] * 1.0 +
        aggregation['scenario_D_count'] * 1.0 +
        aggregation['scenario_B_count'] * -2.0 +
        aggregation['scenario_C_count'] * -0.5
    )

    return fit_score / total_users


def select_best_fit_strategy_with_tie_breaking(
    strategy_fit_scores: Dict[int, Dict],
    strategies: List
) -> Tuple[Optional[int], bool, Optional[str], List[str]]:
    """
    ENHANCEMENT: Select best-fit strategy with explicit tie-breaking

    Tie-breaking rules:
    1. Highest fit score
    2. If tied, highest target level
    3. If still tied, alphabetical order

    Returns:
        (best_strategy_id, tie_detected, tie_break_reason, warnings)
    """
    if not strategy_fit_scores:
        return (None, False, None, [])

    warnings = []

    # ENHANCEMENT: Exclude strategies with 0 users
    valid_scores = {
        sid: data for sid, data in strategy_fit_scores.items()
        if data['total_users'] > 0
    }

    if not valid_scores:
        warnings.append({
            'type': 'all_strategies_zero_users',
            'message': 'All strategies apply to 0 users for this competency'
        })
        return (None, False, None, warnings)

    # Find max fit score
    max_score = max(data['fit_score'] for data in valid_scores.values())

    # ENHANCEMENT: Warning for all negative fit scores
    if max_score < 0:
        warnings.append({
            'type': 'all_strategies_suboptimal',
            'best_score': max_score,
            'message': 'All selected strategies have net negative impact'
        })

    # Find strategies with max score
    tied_strategies = [
        sid for sid, data in valid_scores.items()
        if abs(data['fit_score'] - max_score) < 0.001
    ]

    # No tie
    if len(tied_strategies) == 1:
        return (tied_strategies[0], False, None, warnings)

    # Tie detected - apply tie-breaking
    logger.info(
        f"Tie detected: {len(tied_strategies)} strategies with score {max_score:.2f}"
    )

    # Tie-break rule 1: Highest target level
    max_target = max(valid_scores[sid]['target_level'] for sid in tied_strategies)
    tied_after_target = [
        sid for sid in tied_strategies
        if valid_scores[sid]['target_level'] == max_target
    ]

    if len(tied_after_target) == 1:
        return (tied_after_target[0], True, 'target_level', warnings)

    # Tie-break rule 2: Alphabetical by strategy name
    strategy_names = {s.id: s.strategy_name for s in strategies}
    best = sorted(tied_after_target, key=lambda sid: strategy_names[sid])[0]

    logger.info(
        f"Tie-breaking applied: Selected {strategy_names[best]} (alphabetical)"
    )

    return (best, True, 'alphabetical', warnings)


def cross_strategy_coverage(
    role_analyses: Dict,
    selected_strategies: List,
    all_competencies: List[int],
    total_users: int
) -> Tuple[Dict, Dict, Dict]:
    """
    STEP 4: Cross-strategy coverage with ENHANCEMENTS

    Returns:
        Tuple of (coverage, competency_scenario_distributions, all_strategy_fit_scores)
        - coverage: best-fit strategy per competency with warnings (original output)
        - competency_scenario_distributions: detailed scenario data for frontend
        - all_strategy_fit_scores: all fit scores per competency for frontend
    """
    coverage = {}
    competency_scenario_distributions = {}
    all_strategy_fit_scores_data = {}

    for competency_id in all_competencies:
        strategy_fit_scores = {}
        scenario_distributions_by_strategy = {}

        for strategy in selected_strategies:
            if competency_id not in role_analyses[strategy.id]:
                continue

            scenario_classifications = role_analyses[strategy.id][competency_id]['scenario_classifications']

            # Aggregate
            aggregation = aggregate_by_user_distribution(
                scenario_classifications,
                total_users
            )

            # Calculate fit score
            fit_score = calculate_fit_score(aggregation, total_users)

            # Get target level
            target_level = get_strategy_target_level(strategy, competency_id)

            strategy_fit_scores[strategy.id] = {
                'fit_score': fit_score,
                'target_level': target_level,
                'total_users': total_users,
                'aggregation': aggregation
            }

            # Store detailed scenario distribution for frontend
            scenario_distributions_by_strategy[str(strategy.id)] = {
                'strategy_name': strategy.strategy_name,
                'scenario_A_count': aggregation['scenario_A_count'],
                'scenario_A_percentage': aggregation['scenario_A_percentage'],
                'scenario_B_count': aggregation['scenario_B_count'],
                'scenario_B_percentage': aggregation['scenario_B_percentage'],
                'scenario_C_count': aggregation['scenario_C_count'],
                'scenario_C_percentage': aggregation['scenario_C_percentage'],
                'scenario_D_count': aggregation['scenario_D_count'],
                'scenario_D_percentage': aggregation['scenario_D_percentage'],
                'users_by_scenario': aggregation['users_by_scenario'],
                'target_level': target_level
            }

        # Select best-fit with tie-breaking and enhancements
        best_strategy_id, tie_detected, tie_reason, warnings = \
            select_best_fit_strategy_with_tie_breaking(
                strategy_fit_scores,
                selected_strategies
            )

        if best_strategy_id is None:
            continue

        best_data = strategy_fit_scores[best_strategy_id]

        coverage[competency_id] = {
            'best_fit_strategy_id': best_strategy_id,
            'fit_score': best_data['fit_score'],
            'aggregation': best_data['aggregation'],
            'tie_detected': tie_detected,
            'tie_break_reason': tie_reason,
            'warnings': warnings
        }

        # Store competency scenario distributions for frontend
        competency_scenario_distributions[str(competency_id)] = {
            'competency_name': get_competency_name(competency_id),
            'by_strategy': scenario_distributions_by_strategy
        }

        # Store all strategy fit scores for frontend
        all_strategy_fit_scores_data[str(competency_id)] = {
            'competency_name': get_competency_name(competency_id),
            'strategies': [
                {
                    'strategy_id': strategy.id,
                    'strategy_name': strategy.strategy_name,
                    'fit_score': strategy_fit_scores[strategy.id]['fit_score'],
                    'target_level': strategy_fit_scores[strategy.id]['target_level'],
                    'scenario_A_percentage': strategy_fit_scores[strategy.id]['aggregation']['scenario_A_percentage'],
                    'scenario_B_percentage': strategy_fit_scores[strategy.id]['aggregation']['scenario_B_percentage'],
                    'scenario_C_percentage': strategy_fit_scores[strategy.id]['aggregation']['scenario_C_percentage'],
                    'scenario_D_percentage': strategy_fit_scores[strategy.id]['aggregation']['scenario_D_percentage'],
                    'is_best_fit': strategy.id == best_strategy_id
                }
                for strategy in selected_strategies
                if strategy.id in strategy_fit_scores
            ]
        }

    logger.info(f"[STEP 4] Best-fit strategies determined for {len(coverage)} competencies")

    # DEBUG: Log what we're returning
    if '1' in all_strategy_fit_scores_data:
        logger.info(f"[cross_strategy_coverage] DEBUG: Returning all_strategy_fit_scores_data for comp 1:")
        logger.info(f"  strategies count: {len(all_strategy_fit_scores_data['1'].get('strategies', []))}")
        if all_strategy_fit_scores_data['1'].get('strategies'):
            logger.info(f"  first strategy target_level: {all_strategy_fit_scores_data['1']['strategies'][0].get('target_level', 'MISSING')}")

    return coverage, competency_scenario_distributions, all_strategy_fit_scores_data


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def run_role_based_pathway_analysis_fixed(organization_id: int) -> Dict:
    """
    Run complete role-based pathway analysis with DUAL-TRACK PROCESSING

    This is the production-ready implementation with:
    1. Multi-role user fix (CRITICAL)
    2. Tie-breaking logic (ENHANCEMENT)
    3. Negative score warnings (ENHANCEMENT)
    4. Zero users exclusion (ENHANCEMENT)
    5. Step 8: Learning objective TEXT generation (NEW)
    6. Dual-track processing: Gap-based vs Expert strategies (NEW)

    Dual-Track Processing:
    - Gap-based strategies: Full 8-step validation (Continuous Support, etc.)
    - Expert strategies: Simple 2-way comparison (Train the Trainer)

    Returns complete analysis results with separated gap-based and expert development sections
    """
    logger.info(f"[START] Role-based pathway analysis for org {organization_id} (DUAL-TRACK)")

    # Step 1: Get data
    data = get_assessment_data(organization_id)

    if not data['user_assessments']:
        return {'error': 'No completed assessments found'}

    if not data['selected_strategies']:
        return {'error': 'No learning strategies selected'}

    # Get PMT context if available
    pmt_context = PMTContext.query.filter_by(organization_id=organization_id).first()

    total_users = len(data['user_assessments'])

    # NEW: Classify strategies into gap-based vs expert development
    gap_based_strategies, expert_strategies = classify_strategies(data['selected_strategies'])

    # ==========================================================================
    # TRACK 1: GAP-BASED STRATEGIES (Full 8-Step Validation)
    # ==========================================================================
    gap_based_result = {}

    if gap_based_strategies:
        logger.info(f"[TRACK 1] Processing {len(gap_based_strategies)} gap-based strategies with FULL validation")

        # Check if PMT is needed for gap-based strategies
        needs_pmt = any(
            check_if_strategy_needs_pmt(strategy.strategy_name)
            for strategy in gap_based_strategies
        )

        if needs_pmt and (not pmt_context or not pmt_context.is_complete()):
            logger.warning(
                f"[WARNING] Gap-based strategies require PMT context, "
                f"but PMT context is {'missing' if not pmt_context else 'incomplete'}. "
                f"Learning objectives will use templates without customization."
            )

        # Step 2: Analyze all roles (WITH CRITICAL FIX) - ONLY gap-based strategies
        role_analyses = analyze_all_roles_fixed(
            data['organization_roles'],
            data['user_assessments'],
            gap_based_strategies,  # Only gap-based
            data['all_competencies']
        )

        # Step 4: Cross-strategy coverage (WITH ENHANCEMENTS) - ONLY gap-based
        coverage, competency_scenario_distributions, all_strategy_fit_scores = cross_strategy_coverage(
            role_analyses,
            gap_based_strategies,  # Only gap-based
            data['all_competencies'],
            total_users
        )

        # Step 5: Strategy Validation Layer - ONLY gap-based
        validation = validate_strategy_adequacy(coverage, total_users)

        # Step 6: Strategic Decisions - ONLY gap-based
        decisions = make_strategic_decisions(
            coverage,
            validation,
            gap_based_strategies,  # Only gap-based
            data['all_competencies']
        )

        # Step 7: Gap Analysis & Learning Objectives (with Step 8 TEXT) - ONLY gap-based
        objectives = generate_learning_objectives(
            decisions,
            data['user_assessments'],
            gap_based_strategies,  # Only gap-based
            data['all_competencies'],
            coverage,
            data['organization_roles'],
            pmt_context
        )

        # NEW: Extract detailed processing data for frontend Algorithm Explanation Card
        role_analysis_details = extract_role_analysis_details(
            role_analyses,
            data['organization_roles'],
            data['user_assessments'],
            gap_based_strategies,
            data['all_competencies']
        )

        # DEBUG: Log what we're passing to generate_coverage_summary
        if '1' in all_strategy_fit_scores:
            logger.info(f"[BEFORE generate_coverage_summary] DEBUG: all_strategy_fit_scores for comp 1:")
            logger.info(f"  strategies count: {len(all_strategy_fit_scores['1'].get('strategies', []))}")
            if all_strategy_fit_scores['1'].get('strategies'):
                logger.info(f"  first strategy target_level: {all_strategy_fit_scores['1']['strategies'][0].get('target_level', 'MISSING')}")

        coverage_summary = generate_coverage_summary(
            coverage,
            all_strategy_fit_scores,
            gap_based_strategies,
            data['organization_roles'],  # ADDED for max_role_requirement fix
            data['all_competencies'],  # ADDED for max_role_requirement fix
            data['user_assessments']  # NEW: For current_level calculation
        )

        gap_based_result = {
            'coverage': coverage,
            'validation': validation,
            'decisions': decisions,
            'objectives': objectives,
            'competency_scenario_distributions': competency_scenario_distributions,
            'all_strategy_fit_scores': all_strategy_fit_scores,
            # NEW: Detailed algorithm processing data for frontend
            'role_analysis_details': role_analysis_details,
            'cross_strategy_coverage_summary': coverage_summary
        }

        logger.info(f"[TRACK 1] Gap-based processing complete - Validation: {validation['status']}")
    else:
        logger.info("[TRACK 1] No gap-based strategies - skipping full validation")

    # ==========================================================================
    # TRACK 2: EXPERT DEVELOPMENT STRATEGIES (Simple 2-Way Comparison)
    # ==========================================================================
    expert_result = {}

    if expert_strategies:
        logger.info(f"[TRACK 2] Processing {len(expert_strategies)} expert strategies with SIMPLE 2-way comparison")

        expert_result = process_expert_strategies_simple(
            organization_id,
            expert_strategies,
            data['user_assessments'],
            data['all_competencies'],
            pmt_context
        )

        logger.info(f"[TRACK 2] Expert processing complete - {len(expert_result)} strategies processed")
    else:
        logger.info("[TRACK 2] No expert strategies selected")

    # ==========================================================================
    # COMBINE RESULTS with Clear Separation
    # ==========================================================================

    # Extract user assessment details and role requirements for frontend
    user_assessments_detail = extract_user_assessment_details(data['user_assessments'], data['all_competencies'])
    role_requirements_detail = extract_role_requirements(data['organization_roles'], data['all_competencies'])

    # Determine pathway based on strategy classification
    if len(expert_strategies) > 0 and len(gap_based_strategies) > 0:
        pathway = 'ROLE_BASED_DUAL_TRACK'
    elif len(gap_based_strategies) > 0:
        pathway = 'ROLE_BASED'
    else:
        # Only expert strategies (rare case)
        pathway = 'ROLE_BASED_EXPERT_ONLY'

    result = {
        'pathway': pathway,
        'organization_id': organization_id,
        'total_users_assessed': total_users,
        'aggregation_method': 'median_per_role_with_user_distribution',
        'pmt_context_available': pmt_context is not None and pmt_context.is_complete(),

        # NEW: Input data for Algorithm Explanation Card
        'user_assessments': user_assessments_detail,
        'role_requirements': role_requirements_detail,

        # Track 1: Gap-based strategies with full validation
        'gap_based_training': {
            'strategy_count': len(gap_based_strategies),
            'strategies': [s.strategy_name for s in gap_based_strategies],
            'has_validation': len(gap_based_strategies) > 0,
            'cross_strategy_coverage': gap_based_result.get('coverage', {}),
            'strategy_validation': gap_based_result.get('validation', {}),
            'strategic_decisions': gap_based_result.get('decisions', {}),
            'learning_objectives_by_strategy': gap_based_result.get('objectives', {}),
            # NEW: Detailed processing data for Algorithm Explanation Card
            'competency_scenario_distributions': gap_based_result.get('competency_scenario_distributions', {}),
            'all_strategy_fit_scores': gap_based_result.get('all_strategy_fit_scores', {}),
            'role_analysis_details': gap_based_result.get('role_analysis_details', {}),
            'cross_strategy_coverage_summary': gap_based_result.get('cross_strategy_coverage_summary', [])
        },

        # Track 2: Expert development strategies (no validation)
        'expert_development': {
            'strategy_count': len(expert_strategies),
            'strategies': [s.strategy_name for s in expert_strategies],
            'note': 'Expert development strategies represent strategic capability investments '
                    'and are processed separately without gap-based validation. These typically '
                    'target mastery-level (Level 6) competencies.',
            'learning_objectives_by_strategy': expert_result
        }
    }

    logger.info(
        f"[COMPLETE] Dual-track analysis finished | "
        f"Gap-based: {len(gap_based_strategies)} | Expert: {len(expert_strategies)}"
    )

    return result


# ============================================================================
# STEP 5: Strategy Validation Layer
# ============================================================================

def classify_gap_severity(scenario_B_percentage: float, has_real_gap: bool) -> str:
    """
    Classify gap severity based on Scenario B percentage using configurable thresholds

    Args:
        scenario_B_percentage: Percentage of users in Scenario B
        has_real_gap: Whether the best-fit strategy has a real gap

    Returns:
        'none', 'minor', 'significant', or 'critical'
    """
    if not has_real_gap:
        return 'none'

    # Load thresholds from configuration
    thresholds = get_validation_thresholds()
    critical_threshold = thresholds['critical_gap_threshold']
    significant_threshold = thresholds['significant_gap_threshold']

    if scenario_B_percentage > critical_threshold:
        return 'critical'
    elif scenario_B_percentage >= significant_threshold:
        return 'significant'
    elif scenario_B_percentage > 0:
        return 'minor'
    else:
        return 'none'


def determine_recommendation_level(
    critical_count: int,
    significant_count: int,
    minor_count: int
) -> str:
    """
    Determine what level of action is needed using configurable thresholds

    Returns:
        'URGENT_STRATEGY_ADDITION', 'STRATEGY_ADDITION_RECOMMENDED',
        'SUPPLEMENTARY_MODULES', or 'PROCEED_AS_PLANNED'
    """
    # Load thresholds from configuration
    thresholds = get_validation_thresholds()
    critical_competency_count = thresholds['critical_competency_count']

    if critical_count >= critical_competency_count:
        return 'URGENT_STRATEGY_ADDITION'
    elif critical_count > 0 or significant_count >= 5:
        return 'STRATEGY_ADDITION_RECOMMENDED'
    elif significant_count >= 2 or minor_count >= 5:
        return 'SUPPLEMENTARY_MODULES'
    else:
        return 'PROCEED_AS_PLANNED'


def validate_strategy_adequacy(coverage: Dict, total_users: int) -> Dict:
    """
    STEP 5: Strategy-level validation

    Aggregates scenario B data across all competencies to determine if
    selected strategies are adequate for the organization.

    Args:
        coverage: Cross-strategy coverage data from Step 4
        total_users: Total number of users

    Returns:
        Validation results with status, severity, recommendations
    """
    # Categorize competencies by gap severity
    critical_gaps = []
    significant_gaps = []
    minor_gaps = []
    well_covered = []

    for competency_id, data in coverage.items():
        agg = data['aggregation']
        scenario_B_pct = agg['scenario_B_percentage']
        fit_score = data['fit_score']

        # Classify gap severity
        # Consider a competency to have a gap if it has negative or low fit score
        has_gap = fit_score < 0.5

        severity = classify_gap_severity(scenario_B_pct, has_gap)

        if severity == 'critical':
            critical_gaps.append(competency_id)
        elif severity == 'significant':
            significant_gaps.append(competency_id)
        elif severity == 'minor':
            minor_gaps.append(competency_id)
        else:
            well_covered.append(competency_id)

    # Calculate overall metrics
    total_competencies = len(coverage)
    total_gaps = len(critical_gaps) + len(significant_gaps) + len(minor_gaps)
    gap_percentage = (total_gaps / total_competencies * 100) if total_competencies > 0 else 0

    # Calculate actual unique users affected (Scenario B users across competencies with gaps)
    unique_users_with_gaps = set()
    competencies_with_gaps = critical_gaps + significant_gaps + minor_gaps

    for competency_id in competencies_with_gaps:
        if competency_id in coverage:
            agg = coverage[competency_id].get('aggregation', {})
            users_by_scenario = agg.get('users_by_scenario', {})
            scenario_B_users = users_by_scenario.get('B', [])
            unique_users_with_gaps.update(scenario_B_users)

    total_users_with_gaps = len(unique_users_with_gaps)

    logger.info(
        f"[STEP 5] Users affected: {total_users_with_gaps} unique users "
        f"in Scenario B across {len(competencies_with_gaps)} competencies with gaps"
    )

    # Load thresholds from configuration
    thresholds = get_validation_thresholds()
    critical_competency_count = thresholds['critical_competency_count']
    inadequate_gap_percentage = thresholds['inadequate_gap_percentage']
    critical_gap_threshold = thresholds['critical_gap_threshold']

    # Determine validation status
    if len(critical_gaps) >= critical_competency_count:
        status = 'CRITICAL'
        severity = 'critical'
        message = f'{len(critical_gaps)} competencies have critical gaps (>{critical_gap_threshold}% of users affected)'
        requires_revision = True
    elif gap_percentage > inadequate_gap_percentage:
        status = 'INADEQUATE'
        severity = 'high'
        message = f'{gap_percentage:.1f}% of competencies have coverage gaps'
        requires_revision = True
    elif gap_percentage > 20:
        status = 'ACCEPTABLE'
        severity = 'moderate'
        message = f'{gap_percentage:.1f}% of competencies have gaps, supplementary training recommended'
        requires_revision = False
    elif gap_percentage > 0:
        status = 'GOOD'
        severity = 'low'
        message = f'Minor gaps in {total_gaps} competencies, manageable with Phase 3 module selection'
        requires_revision = False
    else:
        status = 'EXCELLENT'
        severity = 'none'
        message = 'Selected strategies fully cover organizational needs'
        requires_revision = False

    recommendation_level = determine_recommendation_level(
        len(critical_gaps),
        len(significant_gaps),
        len(minor_gaps)
    )

    logger.info(
        f"[STEP 5] Validation: {status} - {gap_percentage:.1f}% gaps, "
        f"{len(critical_gaps)} critical, {len(significant_gaps)} significant"
    )

    return {
        'status': status,
        'severity': severity,
        'message': message,
        'gap_percentage': gap_percentage,
        'competency_breakdown': {
            'critical_gaps': critical_gaps,
            'significant_gaps': significant_gaps,
            'minor_gaps': minor_gaps,
            'well_covered': well_covered
        },
        'total_users_with_gaps': total_gaps,  # Simplified for now
        'strategies_adequate': status in ['EXCELLENT', 'GOOD'],
        'requires_strategy_revision': requires_revision,
        'recommendation_level': recommendation_level
    }


# ============================================================================
# STEP 6: Strategic Decisions
# ============================================================================

def make_strategic_decisions(
    coverage: Dict,
    validation: Dict,
    selected_strategies: List,
    all_competencies: List[int]
) -> Dict:
    """
    STEP 6: Make strategic decisions based on validation

    Makes holistic decisions at strategy level, not isolated per-competency

    Args:
        coverage: Cross-strategy coverage data
        validation: Validation results from Step 5
        selected_strategies: List of selected strategies
        all_competencies: List of all competency IDs

    Returns:
        Strategic decisions and recommendations
    """
    recommendation_level = validation['recommendation_level']

    decisions = {
        'overall_action': recommendation_level,
        'overall_message': validation['message'],
        'per_competency_details': {},
        'suggested_strategy_additions': [],
        'supplementary_module_guidance': []
    }

    # If strategies are adequate, provide minor guidance
    if validation['strategies_adequate']:
        decisions['overall_action'] = 'PROCEED_AS_PLANNED'
        decisions['overall_message'] = 'Selected strategies are well-aligned with organizational needs'

        # Provide Phase 3 guidance for gaps
        if validation['gap_percentage'] > 0:
            gap_comps = (
                validation['competency_breakdown']['minor_gaps'] +
                validation['competency_breakdown']['significant_gaps']
            )

            for comp_id in gap_comps:
                if comp_id in coverage:
                    agg = coverage[comp_id]['aggregation']
                    scenario_B_count = agg['scenario_B_count']

                    decisions['supplementary_module_guidance'].append({
                        'competency_id': comp_id,
                        'guidance': 'Select advanced modules during Phase 3',
                        'affected_users': scenario_B_count
                    })

    # If major gaps exist, recommend strategy additions
    elif validation['requires_strategy_revision']:
        critical_and_significant = (
            validation['competency_breakdown']['critical_gaps'] +
            validation['competency_breakdown']['significant_gaps']
        )

        if critical_and_significant:
            # Determine which strategy to recommend based on gaps
            # For now, recommend "Continuous support" as it's a broad gap-covering strategy
            # TODO: Implement intelligent strategy recommendation based on gap analysis
            recommended_strategy = "Continuous support"

            # Alternative logic could check which available strategies would best cover the gaps
            # by analyzing their target levels against the gap competencies

            decisions['suggested_strategy_additions'].append({
                'strategy_name': recommended_strategy,
                'rationale': f'Would cover gaps in {len(critical_and_significant)} competencies',
                'competencies_affected': critical_and_significant,
                'priority': 'HIGH'
            })

    # Provide detailed per-competency information
    for competency_id in all_competencies:
        if competency_id in coverage:
            comp_data = coverage[competency_id]
            agg = comp_data['aggregation']

            decisions['per_competency_details'][competency_id] = {
                'scenario_B_percentage': agg['scenario_B_percentage'],
                'scenario_B_count': agg['scenario_B_count'],
                'best_fit_strategy': comp_data.get('best_fit_strategy_id'),
                'best_fit_score': comp_data['fit_score'],
                'warnings': comp_data.get('warnings', [])
            }

    logger.info(
        f"[STEP 6] Strategic decisions: {recommendation_level}, "
        f"{len(decisions['supplementary_module_guidance'])} guidance items"
    )

    return decisions


# ============================================================================
# STEP 7: Gap Analysis & Learning Objectives
# ============================================================================

def calculate_median(values: List[int]) -> int:
    """
    Calculate median - returns actual competency level
    Better than mean for ordinal data
    """
    if not values:
        return 0

    sorted_values = sorted(values)
    n = len(sorted_values)

    if n % 2 == 1:
        return sorted_values[n // 2]
    else:
        mid1 = sorted_values[n // 2 - 1]
        mid2 = sorted_values[n // 2]
        avg = (mid1 + mid2) / 2
        return round_to_valid_level(avg)


def round_to_valid_level(value: float) -> int:
    """Map to nearest valid competency level"""
    VALID_LEVELS = [0, 1, 2, 4, 6]
    return min(VALID_LEVELS, key=lambda x: abs(x - value))


def calculate_training_priority(
    gap: int,
    max_role_requirement: int,
    scenario_B_percentage: float
) -> float:
    """
    Calculate training priority using multi-factor formula with configurable weights

    As per LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md (Lines 942-966):

    Factors (weights configurable):
    - Gap size: How many levels to train (default: 40% weight)
    - Role criticality: How critical for role requirements (default: 30% weight)
    - User urgency: Percentage of users in Scenario B (default: 30% weight)

    Args:
        gap: Gap to target level (target - current)
        max_role_requirement: Maximum role requirement level across all org roles
        scenario_B_percentage: Percentage of users in Scenario B (strategy insufficient)

    Returns:
        Priority score (0-10 scale)

    Example (with default weights):
        gap=2, max_role_req=6, scenario_B_pct=25
        -> gap_score = (2/6)*10 = 3.33
        -> role_score = (6/6)*10 = 10.0
        -> urgency_score = (25/100)*10 = 2.5
        -> priority = (3.33*0.4) + (10.0*0.3) + (2.5*0.3) = 5.08
    """
    # Load weights from configuration
    weights = get_priority_weights()
    gap_weight = weights['gap_weight']
    role_weight = weights['role_weight']
    urgency_weight = weights['urgency_weight']

    # Normalize gap (assume max gap is 6)
    gap_score = (gap / 6.0) * 10 if gap > 0 else 0

    # Normalize role requirement (max is 6)
    role_score = (max_role_requirement / 6.0) * 10

    # Normalize Scenario B percentage to 0-10 scale
    urgency_score = (scenario_B_percentage / 100.0) * 10

    # Weighted combination using configuration
    priority = (gap_score * gap_weight) + (role_score * role_weight) + (urgency_score * urgency_weight)

    return round(priority, 2)


def generate_learning_objectives(
    decisions: Dict,
    user_assessments: List,
    selected_strategies: List,
    all_competencies: List[int],
    coverage: Dict,
    organization_roles: List,
    pmt_context: Optional['PMTContext'] = None
) -> Dict:
    """
    STEP 7 + 8: Generate learning objectives per strategy WITH TEXT GENERATION

    Creates unified objectives for each strategy based on gap analysis,
    then generates actual learning objective text using templates and PMT customization.

    Args:
        decisions: Strategic decisions from Step 6
        user_assessments: List of user assessments
        selected_strategies: List of selected strategies
        all_competencies: List of all competency IDs
        coverage: Cross-strategy coverage data
        organization_roles: List of organization roles (for max role requirement)
        pmt_context: Optional PMT context for deep customization

    Returns:
        Learning objectives organized by strategy with full text
    """
    objectives_by_strategy = {}

    # Pre-calculate max role requirements for all competencies
    max_role_requirements = {}
    for competency_id in all_competencies:
        max_req = 0
        for role in organization_roles:
            req = get_role_requirement(role.id, competency_id)
            max_req = max(max_req, req)
        max_role_requirements[competency_id] = max_req

    logger.info(f"[STEP 7] Calculated max role requirements for {len(max_role_requirements)} competencies")

    for strategy in selected_strategies:
        # Determine if this strategy needs deep customization
        requires_deep_customization = check_if_strategy_needs_pmt(strategy.strategy_name)
        logger.info(f"[STEP 8 DEBUG] Strategy '{strategy.strategy_name}' requires_deep_customization={requires_deep_customization}")
        logger.info(f"[STEP 8 DEBUG] pmt_context={pmt_context}, is_complete={pmt_context.is_complete() if pmt_context else 'N/A'}")

        # Separate lists for core and trainable competencies
        core_competencies_output = []
        trainable_competencies_output = []

        for competency_id in all_competencies:
            # Get all user scores for this competency
            all_scores = []
            for user in user_assessments:
                # CRITICAL FIX: Use user.user_id (FK to users), NOT user.id (assessment ID)
                comp_score = CompetencyScore.query.filter_by(
                    user_id=user.user_id,  # Fixed: was user.id (assessment ID)
                    competency_id=competency_id
                ).first()

                if comp_score:
                    all_scores.append(comp_score.score)

            # Calculate organizational current level (median)
            org_current_level = calculate_median(all_scores) if all_scores else 0

            # Get strategy target
            strategy_target = get_strategy_target_level(strategy, competency_id)

            if strategy_target is None:
                continue

            # Skip if not in coverage
            if competency_id not in coverage:
                continue

            # Get coverage data
            comp_data = coverage[competency_id]
            agg = comp_data['aggregation']
            decision_detail = decisions['per_competency_details'].get(competency_id, {})

            # 3-WAY COMPARISON: Check if training is needed
            # Use max role requirement across all org roles
            max_role_req = max_role_requirements.get(competency_id, 0)

            # CRITICAL FIX: Prioritize role requirements over strategy targets
            # According to LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md:
            # If role requirement is already met, training is OPTIONAL (may be over-training)

            # STEP 1: Check if role requirement is already met
            if org_current_level >= max_role_req:
                # Role requirement satisfied!

                # Check if strategy target is also met
                if org_current_level >= strategy_target:
                    # Scenario D: Both met - No training needed
                    org_scenario = classify_gap_scenario(
                        org_current_level,
                        strategy_target,
                        max_role_req
                    )

                    trainable_obj = {
                        'competency_id': competency_id,
                        'competency_name': get_competency_name(competency_id),
                        'current_level': org_current_level,
                        'target_level': strategy_target,
                        'gap': 0,
                        'priority_score': 0,  # No training needed, priority is 0
                        'status': 'target_achieved',
                        'max_role_requirement': max_role_req,
                        'organizational_scenario': org_scenario,
                        'scenario': f'Scenario {org_scenario}',
                        'is_core': competency_id in CORE_COMPETENCIES,
                        'core_note': get_core_competency_note(competency_id),
                        'note': 'Both archetype and role targets achieved. No training needed.'
                    }
                    trainable_competencies_output.append(trainable_obj)
                    continue
                else:
                    # Scenario C: Role met, but strategy target higher
                    # IMPORTANT: Strategy was selected intentionally - generate objectives to reach strategy target!
                    # Role requirement is met, but the organization wants to train beyond that.
                    gap = strategy_target - org_current_level

                    org_scenario = classify_gap_scenario(
                        org_current_level,
                        strategy_target,
                        max_role_req
                    )

                    logger.info(
                        f"[SCENARIO C - BEYOND ROLE] Competency {competency_id} ({get_competency_name(competency_id)}): "
                        f"Current {org_current_level} >= Role Req {max_role_req} but < Strategy {strategy_target}. "
                        f"Role requirement is MET. Training to strategy target (gap = {gap}). "
                        f"Generating learning objective."
                    )

                    # Generate learning objective text (same as normal training case)
                    template_data = get_template_objective_full(competency_id, strategy_target)

                    # get_template_objective_full returns: {'objective_text': str, 'has_pmt': bool, 'pmt_breakdown': dict|None}
                    has_pmt_breakdown = isinstance(template_data, dict) and template_data.get('has_pmt', False)
                    if has_pmt_breakdown:
                        base_template = template_data.get('objective_text', '[Template error]')
                        pmt_breakdown = template_data.get('pmt_breakdown')
                    else:
                        base_template = template_data.get('objective_text', '[Template error]') if isinstance(template_data, dict) else str(template_data)
                        pmt_breakdown = None

                    # Generate objective text
                    if requires_deep_customization and pmt_context and pmt_context.is_complete():
                        objective_text = llm_deep_customize(
                            base_template,
                            pmt_context,
                            org_current_level,
                            strategy_target,
                            competency_id,
                            pmt_breakdown
                        )
                    else:
                        objective_text = base_template

                    # Calculate priority (lower than normal training since role requirement is met)
                    priority_score = calculate_training_priority(
                        gap=gap,
                        max_role_requirement=max_role_req,
                        scenario_B_percentage=agg['scenario_B_percentage']
                    ) * 0.7  # Reduce priority by 30% since role requirement is already met

                    trainable_obj = {
                        'competency_id': competency_id,
                        'competency_name': get_competency_name(competency_id),
                        'current_level': org_current_level,
                        'target_level': strategy_target,
                        'gap': gap,
                        'priority_score': priority_score,
                        'status': 'role_requirement_met',  # Informational status
                        'max_role_requirement': max_role_req,
                        'organizational_scenario': org_scenario,
                        'scenario': f'Scenario {org_scenario}',
                        'is_core': competency_id in CORE_COMPETENCIES,
                        'core_note': get_core_competency_note(competency_id),
                        'learning_objective': objective_text,
                        'base_template': base_template,
                        'scenario_distribution': {
                            'A': agg['scenario_A_percentage'],
                            'B': agg['scenario_B_percentage'],
                            'C': agg['scenario_C_percentage'],
                            'D': agg['scenario_D_percentage']
                        },
                        'users_requiring_training': (
                            agg['scenario_A_count'] + agg['scenario_B_count']
                        ),
                        'note': f'Role requirement ({max_role_req}) already met. Training to strategy target ({strategy_target}) represents organizational investment beyond role requirements.'
                    }

                    if pmt_breakdown:
                        trainable_obj['pmt_breakdown'] = pmt_breakdown

                    trainable_competencies_output.append(trainable_obj)
                    continue

            # STEP 2: Role requirement NOT met - training needed
            # Determine if strategy provides adequate training

            # Initialize role_gap for use in notes later
            role_gap = max_role_req - org_current_level

            # Scenario B: Strategy target met BUT role requirement not met
            if org_current_level >= strategy_target and org_current_level < max_role_req:
                # Strategy is insufficient!
                # IMPORTANT: Gap is calculated vs strategy target (not role requirement)
                # Learning objectives target what the strategy teaches, not role requirements
                gap = max(0, strategy_target - org_current_level)
                logger.info(
                    f"[SCENARIO B - STRATEGY INSUFFICIENT] Competency {competency_id}: "
                    f"Current {org_current_level} >= Strategy {strategy_target} but < Role {max_role_req}. "
                    f"Strategy gap = {gap}, Role gap = {role_gap} levels"
                )

                # If strategy target is already met (gap = 0), don't generate learning objective
                if gap == 0:
                    logger.info(
                        f"[SCENARIO B - NO OBJECTIVE] Competency {competency_id}: "
                        f"Strategy target already met. No learning objective for this strategy."
                    )

                    trainable_obj = {
                        'competency_id': competency_id,
                        'competency_name': get_competency_name(competency_id),
                        'current_level': org_current_level,
                        'target_level': strategy_target,
                        'gap': 0,
                        'priority_score': 0,
                        'status': 'strategy_insufficient',
                        'max_role_requirement': max_role_req,
                        'organizational_scenario': 'B',
                        'scenario': 'Scenario B',
                        'is_core': competency_id in CORE_COMPETENCIES,
                        'core_note': get_core_competency_note(competency_id),
                        'note': (
                            f"Strategy target ({strategy_target}) already achieved, but role requirement "
                            f"({max_role_req}) not yet met. Gap to role: {role_gap} levels. "
                            f"This strategy cannot provide further training. Consider selecting a higher-level strategy."
                        )
                    }
                    trainable_competencies_output.append(trainable_obj)
                    continue  # Skip learning objective generation

            # Scenario A: Current < strategy target (normal training path)
            else:
                gap = strategy_target - org_current_level
                logger.debug(
                    f"[SCENARIO A - NORMAL TRAINING] Competency {competency_id}: "
                    f"Current {org_current_level} < Strategy {strategy_target}. Gap = {gap}"
                )

            # STEP 8: Generate learning objective TEXT
            template_data = get_template_objective_full(competency_id, strategy_target)

            # get_template_objective_full returns: {'objective_text': str, 'has_pmt': bool, 'pmt_breakdown': dict|None}
            has_pmt_breakdown = isinstance(template_data, dict) and template_data.get('has_pmt', False)

            if has_pmt_breakdown:
                base_template = template_data.get('objective_text', '[Template error]')
                pmt_breakdown = template_data.get('pmt_breakdown')
            else:
                base_template = template_data.get('objective_text', '[Template error]') if isinstance(template_data, dict) else str(template_data)
                pmt_breakdown = None

            # Generate objective text
            if requires_deep_customization and pmt_context and pmt_context.is_complete():
                # Deep customization with LLM
                objective_text = llm_deep_customize(
                    base_template,
                    pmt_context,
                    org_current_level,
                    strategy_target,
                    competency_id,
                    pmt_breakdown
                )
                logger.info(f"[STEP 8] Deep customization applied for competency {competency_id}")
            else:
                # Use template as-is (no customization)
                objective_text = base_template

            # Calculate organizational scenario (for frontend badge display)
            org_scenario = classify_gap_scenario(
                org_current_level,
                strategy_target,
                max_role_req
            )

            # Calculate training priority (multi-factor formula from design)
            priority_score = calculate_training_priority(
                gap=gap,
                max_role_requirement=max_role_req,
                scenario_B_percentage=agg['scenario_B_percentage']
            )

            # Build objective output
            trainable_obj = {
                'competency_id': competency_id,
                'competency_name': get_competency_name(competency_id),
                'current_level': org_current_level,
                'target_level': strategy_target,
                'gap': gap,
                'priority_score': priority_score,  # NEW: Training priority for sorting/sequencing
                'status': 'training_required',
                'max_role_requirement': max_role_req,  # Use consistent variable
                'organizational_scenario': org_scenario,  # NEW: Explicit scenario for frontend
                'scenario': f'Scenario {org_scenario}',  # Frontend compatibility (displays as badge)
                'is_core': competency_id in CORE_COMPETENCIES,  # Flag core competencies
                'core_note': get_core_competency_note(competency_id),  # Add informational note if core
                'learning_objective': objective_text,  # NEW: Actual text
                'base_template': base_template,  # For reference
                'scenario_distribution': {
                    'A': agg['scenario_A_percentage'],
                    'B': agg['scenario_B_percentage'],
                    'C': agg['scenario_C_percentage'],
                    'D': agg['scenario_D_percentage']
                },
                'users_requiring_training': (
                    agg['scenario_A_count'] + agg['scenario_B_count']
                )
            }

            # Add PMT breakdown if available
            if pmt_breakdown:
                trainable_obj['pmt_breakdown'] = pmt_breakdown

            # Add notes for significant gaps
            scenario_B_pct = agg['scenario_B_percentage']

            # Determine which scenario this competency is primarily in
            if org_current_level >= strategy_target and org_current_level < max_role_req:
                # Scenario B: Strategy target met, but role requirement not met
                trainable_obj['note'] = (
                    f"Strategy target ({strategy_target}) achieved, but role requirement "
                    f"({max_role_req}) not yet met. Gap to role: {role_gap} levels. "
                    f"Consider supplementary modules or a higher-level strategy."
                )
            elif scenario_B_pct >= 20:
                # Mixed scenario with significant Scenario B users
                trainable_obj['note'] = (
                    f"Consider supplementary modules - {scenario_B_pct:.1f}% "
                    f"of users need higher levels than strategy provides"
                )

            trainable_competencies_output.append(trainable_obj)

        # Calculate summary statistics
        core_count = len([c for c in trainable_competencies_output if c.get('is_core', False)])

        objectives_by_strategy[strategy.id] = {
            'strategy_id': strategy.id,
            'strategy_name': strategy.strategy_name,
            'requires_pmt': requires_deep_customization,
            'pmt_customization_applied': requires_deep_customization and pmt_context and pmt_context.is_complete(),
            'trainable_competencies': trainable_competencies_output,  # Now includes core competencies
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
        f"[STEP 7+8] Generated learning objectives with TEXT for {len(objectives_by_strategy)} strategies"
    )

    return objectives_by_strategy


# ============================================================================
# STEP 8: Output & Store Results
# ============================================================================

def format_complete_output(
    organization_id: int,
    total_users: int,
    coverage: Dict,
    validation: Dict,
    decisions: Dict,
    objectives: Dict
) -> Dict:
    """
    STEP 8: Format complete output for API response

    Returns structured JSON with all analysis results
    """
    from datetime import datetime

    result = {
        'organization_id': organization_id,
        'pathway': 'ROLE_BASED',
        'generation_timestamp': datetime.utcnow().isoformat() + 'Z',
        'status': 'success',

        'assessment_summary': {
            'total_users': total_users,
            'using_latest_only': True
        },

        'cross_strategy_coverage': {},

        'strategy_validation': validation,

        'strategic_decisions': decisions,

        'learning_objectives_by_strategy': objectives
    }

    # Format coverage data
    for competency_id, data in coverage.items():
        agg = data['aggregation']
        print(f"[DEBUG-PRINT] Competency {competency_id}: agg keys = {list(agg.keys())}")
        print(f"[DEBUG-PRINT] Has users_by_scenario: {'users_by_scenario' in agg}")
        result['cross_strategy_coverage'][competency_id] = {
            'best_fit_strategy_id': data.get('best_fit_strategy_id'),
            'fit_score': data['fit_score'],
            'scenario_A_count': agg['scenario_A_count'],
            'scenario_B_count': agg['scenario_B_count'],
            'scenario_C_count': agg['scenario_C_count'],
            'scenario_D_count': agg['scenario_D_count'],
            'scenario_A_percentage': agg['scenario_A_percentage'],
            'scenario_B_percentage': agg['scenario_B_percentage'],
            'scenario_C_percentage': agg['scenario_C_percentage'],
            'scenario_D_percentage': agg['scenario_D_percentage'],
            'users_by_scenario': agg['users_by_scenario'],
            'warnings': data.get('warnings', [])
        }

    logger.info("[STEP 8] Complete output formatted")

    return result


# ============================================================================
# VERIFICATION FUNCTION
# ============================================================================

def verify_percentage_sums(coverage: Dict) -> bool:
    """
    Verify that all competency percentages sum to 100%

    This should ALWAYS pass with the CRITICAL FIX applied
    """
    all_valid = True

    for competency_id, data in coverage.items():
        agg = data['aggregation']
        total = (
            agg['scenario_A_percentage'] +
            agg['scenario_B_percentage'] +
            agg['scenario_C_percentage'] +
            agg['scenario_D_percentage']
        )

        if abs(total - 100.0) > 0.1:
            logger.error(
                f"[VERIFICATION FAILED] Competency {competency_id}: "
                f"Percentages sum to {total:.1f}%, not 100%"
            )
            all_valid = False

    if all_valid:
        logger.info("[VERIFICATION PASSED] All percentages sum to 100%")

    return all_valid
