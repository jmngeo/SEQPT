# Learning Objectives Generation - Complete Final Design Document (v3 - INTEGRATED)
**Date**: November 3, 2025
**Version**: 3 - Integrated with Strategy Validation Layer
**Status**: FINALIZED WITH VALIDATION LAYER - Ready for Implementation
**Purpose**: Complete reference document for Phase 2 Task 3 implementation with holistic strategy validation

---

## Executive Summary

The Learning Objectives Generation system creates customized training objectives for organizations based on their competency assessment results. The system handles two distinct pathways depending on organizational maturity:

1. **Low Maturity Organizations** (no defined SE roles) → Task-based pathway with 2-way comparison
2. **High Maturity Organizations** (defined SE roles) → Role-based pathway with 3-way comparison + validation layer

**Critical Design Principles**:
- Generate ONE unified set of learning objectives per strategy for the entire organization
- Validate that Phase 1 strategy selections are still appropriate given actual assessment data
- Make holistic recommendations based on cross-strategy coverage, not isolated per-competency decisions

---

## Part 1: Non-Technical Explanation for Thesis Advisor

### What This System Does

Think of this system as an intelligent training planner that:
1. **Waits** for employees to complete competency assessments (minimum 70% completion)
2. **Looks** at what skills employees currently have (using median to find typical level)
3. **Compares** this to training strategy targets and role requirements (if roles exist)
4. **Validates** that selected strategies adequately cover organizational needs
5. **Generates** specific learning objectives to close the gaps
6. **Recommends** additional strategies if current ones insufficient (based on holistic analysis)

### The Two Organizational Types

**Type A: Low Maturity Organizations**
- Just starting with Systems Engineering
- NO formal SE roles defined yet
- Employees describe their daily tasks
- System uses **2-way comparison**: Current Level vs Strategy Target
- After first training iteration, organization gains maturity and can define roles

**Type B: High Maturity Organizations**
- Established SE processes and defined roles
- Employees select their roles from organization's custom list
- System uses **3-way comparison**: Current vs Strategy Target vs Role Requirement
- Each role has specific competency requirements
- **NEW: Validation layer** checks if strategies adequately cover all role needs

### How We Aggregate Data

**For Current Competency Levels**: Use **MEDIAN** (middle value)
- Example: 5 developers with skills [1,2,2,4,6] → median = 2
- Why? Not affected by outliers, returns actual valid level

**For Role Requirements**: Each role keeps its specific requirements
- We DON'T average role requirements (would lose role differentiation)
- Instead, we count how many USERS need each level
- Decisions based on user distribution, not role averages

### Decision Making: Two-Layer Approach

**Layer 1: Per-Competency Analysis**
The system counts how many USERS (not roles) fall into each scenario:
- **Scenario A**: Normal training (strategy brings users toward role requirement)
- **Scenario B**: Strategy insufficient (users need higher levels than strategy provides)
- **Scenario C**: Over-training (strategy exceeds role needs)
- **Scenario D**: Targets already met

**Layer 2: Strategy-Level Validation (NEW!)**
After analyzing all 16 competencies:
- Check if multiple selected strategies TOGETHER cover gaps
- Aggregate Scenario B data across competencies
- Make holistic decision: Are selected strategies adequate?
- Only recommend strategy changes if SYSTEMATIC gaps exist (not isolated ones)

**Decision Logic**:
- If Scenario B affects >60% of users in MANY competencies → Recommend strategy addition
- If other selected strategies cover Scenario B gaps → No new strategy needed
- If only 1-2 competencies have gaps → Supplementary modules, not new strategy

### Important Notes

- **Assessment First**: Learning objectives generated ONLY after assessments complete
- **Latest Only**: System uses only the LATEST assessment per user (ignores retakes)
- **One Plan**: Creates ONE training plan for organization, not separate per role
- **Validation Checkpoint**: This phase validates Phase 1 strategy selections

---

## Part 2: Complete Technical Algorithm Design

### Core Algorithm Structure

```python
def generate_learning_objectives(org_id):
    """
    Main entry point - determines pathway based on organization
    """
    # Check assessment completion rate first
    completion_rate = get_assessment_completion_rate(org_id)
    if completion_rate < 0.7:  # 70% minimum
        return {
            'error': 'Insufficient assessment data',
            'completion_rate': completion_rate,
            'message': 'At least 70% of users must complete assessment'
        }

    # Determine pathway
    role_count = OrganizationRole.query.filter_by(organization_id=org_id).count()
    pathway = 'TASK_BASED' if role_count == 0 else 'ROLE_BASED'

    if pathway == 'TASK_BASED':
        return generate_task_based_objectives(org_id)
    else:
        return generate_role_based_objectives(org_id)
```

### Algorithm 1: Task-Based Organizations (Low Maturity)

```python
def generate_task_based_objectives(org_id):
    """
    2-WAY COMPARISON for organizations without defined roles
    NOTE: We do NOT use task requirements (unknown_role_competency_matrix) in comparison
    Only compare: Current Level vs Archetype Target

    No validation layer needed - simpler logic for low maturity orgs
    """
    # Step 1: Get LATEST assessment per user (ignore retakes)
    user_assessments = get_latest_assessments_per_user(org_id, 'unknown_roles')

    # Step 2: Get selected strategies (with or without priorities)
    selected_strategies = get_organization_strategies(org_id)

    objectives = {}

    for strategy in selected_strategies:
        strategy_objectives = []

        for competency in all_16_competencies:
            # Check if core competency (cannot be directly trained)
            if competency.id in [1, 4, 5, 6]:  # Systems Thinking, etc.
                continue  # Skip or add note only

            # Step 3: Calculate current level using MEDIAN
            current_scores = []
            for user in user_assessments:
                score = get_user_competency_score(user.id, competency.id)
                if score is not None:  # Only include actual scores
                    current_scores.append(score)

            current_level = calculate_median(current_scores) if current_scores else 0

            # Step 4: Get archetype target from strategy template
            archetype_target = get_archetype_target(strategy, competency)

            # Step 5: 2-WAY COMPARISON (NO role target!)
            if current_level < archetype_target:
                # Training needed
                objective = generate_objective_text(
                    competency, current_level, archetype_target, strategy
                )

                strategy_objectives.append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'current_level': current_level,
                    'target_level': archetype_target,
                    'gap': archetype_target - current_level,
                    'learning_objective': objective,
                    'comparison_type': '2-way',
                    'status': 'training_required'
                })

            else:
                # Target already achieved
                strategy_objectives.append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'current_level': current_level,
                    'target_level': archetype_target,
                    'status': 'target_achieved'
                })

        objectives[strategy] = strategy_objectives

    return {
        'pathway': 'TASK_BASED',
        'learning_objectives_by_strategy': objectives,
        'validation_note': 'Task-based pathway does not require strategy validation'
    }
```

### Algorithm 2: Role-Based Organizations (High Maturity) - COMPLETE WITH VALIDATION LAYER

```python
def generate_role_based_objectives(org_id):
    """
    3-WAY COMPARISON for organizations with defined roles
    INCLUDES VALIDATION LAYER for holistic strategy assessment
    """
    # Step 1: Get latest assessments and role selections
    user_assessments = get_latest_assessments_per_user(org_id, 'known_roles')
    organization_roles = get_organization_roles(org_id)
    selected_strategies = get_organization_strategies(org_id)

    # Step 2: Analyze each role individually (PER-COMPETENCY SCENARIOS)
    role_analyses = analyze_all_roles(
        organization_roles, user_assessments, selected_strategies
    )

    # Step 3: Aggregate by user distribution (COUNT USERS IN EACH SCENARIO)
    competency_scenario_distributions = aggregate_by_user_distribution(role_analyses)

    # Step 4: Cross-strategy coverage check (NEW - VALIDATION LAYER)
    cross_strategy_coverage = check_cross_strategy_coverage(
        competency_scenario_distributions,
        selected_strategies,
        role_analyses  # Added: needed for fit score calculation
    )

    # Step 5: Strategy-level validation (NEW - HOLISTIC ASSESSMENT)
    strategy_validation = validate_strategy_adequacy(
        competency_scenario_distributions,
        cross_strategy_coverage
    )

    # Step 6: Make strategic decisions (REVISED - INFORMED BY VALIDATION)
    strategic_decisions = make_distribution_based_decisions(
        competency_scenario_distributions,
        cross_strategy_coverage,
        strategy_validation
    )

    # Step 7: Generate unified objectives
    unified_objectives = generate_unified_objectives(
        strategic_decisions,
        role_analyses,
        selected_strategies,
        competency_scenario_distributions
    )

    return {
        'pathway': 'ROLE_BASED',
        'competency_scenario_distributions': competency_scenario_distributions,
        'cross_strategy_coverage': cross_strategy_coverage,
        'strategy_validation': strategy_validation,
        'strategic_decisions': strategic_decisions,
        'learning_objectives_by_strategy': unified_objectives
    }

# =============================================================================
# STEP 2: ANALYZE ALL ROLES (PER-COMPETENCY SCENARIO CLASSIFICATION)
# =============================================================================

def analyze_all_roles(organization_roles, user_assessments, selected_strategies):
    """
    Step 2 DETAILED: Analyze each role separately
    For each role, classify users into scenarios A, B, C, D per competency PER STRATEGY

    IMPORTANT: We analyze against EACH selected strategy separately
    because different strategies may yield different scenarios
    """
    role_analyses = {}

    for role in organization_roles:
        # Get users who selected this specific role
        users_in_role = [
            user for user in user_assessments
            if role.id in user.selected_roles
        ]

        if not users_in_role:
            continue  # Skip roles no one selected

        role_analyses[role.id] = {
            'role_name': role.name,
            'user_count': len(users_in_role),
            'competencies': {}
        }

        for competency in all_16_competencies:
            # Get current level for users IN THIS ROLE
            role_user_scores = [
                get_user_competency_score(user.id, competency.id)
                for user in users_in_role
            ]
            current_level = calculate_median(role_user_scores)

            # Get THIS SPECIFIC ROLE's requirement
            role_requirement = get_role_competency_value(role.id, competency.id)

            # Initialize competency entry
            role_analyses[role.id]['competencies'][competency.id] = {
                'current_level': current_level,
                'role_requirement': role_requirement,
                'user_ids': [u.id for u in users_in_role],
                'by_strategy': {}  # Store analysis per strategy
            }

            # Analyze against EACH strategy separately
            for strategy in selected_strategies:
                archetype_target = get_archetype_target(strategy, competency.id)

                # 3-way comparison for THIS SPECIFIC ROLE against THIS SPECIFIC STRATEGY
                scenario = classify_gap_scenario(
                    current_level, archetype_target, role_requirement
                )

                role_analyses[role.id]['competencies'][competency.id]['by_strategy'][strategy.name] = {
                    'archetype_target': archetype_target,
                    'scenario': scenario
                }

    return role_analyses

# =============================================================================
# STEP 3: AGGREGATE BY USER DISTRIBUTION (COUNT USERS IN SCENARIOS)
# =============================================================================

def aggregate_by_user_distribution(role_analyses):
    """
    Step 3 DETAILED: Count USERS in each scenario PER STRATEGY
    This handles multi-role users correctly and preserves per-strategy analysis

    OUTPUT: Per-competency, per-strategy user distribution across scenarios A, B, C, D

    NOTE: We track scenarios BY STRATEGY because different strategies may have
    different scenario classifications for the same users
    """
    competency_distributions = {}

    # Get all unique strategy names from role_analyses
    all_strategies = set()
    for role_data in role_analyses.values():
        for comp_data in role_data['competencies'].values():
            all_strategies.update(comp_data['by_strategy'].keys())

    for competency_id in all_competency_ids:
        competency_distributions[competency_id] = {
            'competency_name': get_competency_name(competency_id),
            'by_strategy': {}
        }

        # Aggregate separately FOR EACH STRATEGY
        for strategy_name in all_strategies:
            # Track unique users in each scenario for this strategy
            unique_users_by_scenario = {
                'A': set(),  # Current < Archetype ≤ Role (normal training)
                'B': set(),  # Archetype ≤ Current < Role (STRATEGY INSUFFICIENT!)
                'C': set(),  # Archetype > Role (over-training)
                'D': set()   # Targets already met
            }

            # Collect users from ALL roles for this strategy
            for role_id, role_data in role_analyses.items():
                if competency_id in role_data['competencies']:
                    comp_data = role_data['competencies'][competency_id]

                    # Check if this strategy was analyzed for this role-competency
                    if strategy_name in comp_data['by_strategy']:
                        strategy_data = comp_data['by_strategy'][strategy_name]
                        scenario = strategy_data['scenario']
                        user_ids = comp_data['user_ids']

                        # Add to appropriate scenario (handles multi-role users via set)
                        unique_users_by_scenario[scenario].update(user_ids)

            # Calculate percentages based on UNIQUE users
            all_unique_users = set()
            for users in unique_users_by_scenario.values():
                all_unique_users.update(users)
            total_users = len(all_unique_users)

            if total_users > 0:
                competency_distributions[competency_id]['by_strategy'][strategy_name] = {
                    'total_users': total_users,
                    'scenario_A_count': len(unique_users_by_scenario['A']),
                    'scenario_B_count': len(unique_users_by_scenario['B']),
                    'scenario_C_count': len(unique_users_by_scenario['C']),
                    'scenario_D_count': len(unique_users_by_scenario['D']),
                    'scenario_A_percentage': len(unique_users_by_scenario['A']) / total_users * 100,
                    'scenario_B_percentage': len(unique_users_by_scenario['B']) / total_users * 100,
                    'scenario_C_percentage': len(unique_users_by_scenario['C']) / total_users * 100,
                    'scenario_D_percentage': len(unique_users_by_scenario['D']) / total_users * 100,
                    'users_by_scenario': {
                        'A': list(unique_users_by_scenario['A']),
                        'B': list(unique_users_by_scenario['B']),
                        'C': list(unique_users_by_scenario['C']),
                        'D': list(unique_users_by_scenario['D'])
                    }
                }

    return competency_distributions

# =============================================================================
# STEP 4: CROSS-STRATEGY COVERAGE CHECK (NEW - VALIDATION LAYER)
# =============================================================================

def check_cross_strategy_coverage(competency_distributions, selected_strategies, role_analyses):
    """
    Step 4 NEW (CORRECTED): Find BEST-FIT strategy for each competency

    CRITICAL FIX: Don't just pick highest target!
    - Pick strategy that best serves MAJORITY of users
    - Minimize gaps (Scenario B) - critical
    - Minimize over-training (Scenario C) - wasteful
    - Maximize normal training (Scenario A) - ideal

    Key Question: Which selected strategy best fits the organization's needs
                  for this competency, considering user distribution?
    """
    coverage = {}

    for competency_id, distribution in competency_distributions.items():
        # Calculate fit score for EACH selected strategy
        strategy_fit_scores = {}

        for strategy in selected_strategies:
            # Count users in each scenario for THIS strategy
            scenario_counts = {
                'A': 0,  # Normal training (ideal)
                'B': 0,  # Gap - strategy insufficient (critical problem)
                'C': 0,  # Over-training (wasteful but not critical)
                'D': 0   # Already achieved (good)
            }

            # Aggregate across all roles
            for role_id, role_data in role_analyses.items():
                comp_data = role_data['competencies'][competency_id]
                if strategy.name in comp_data['by_strategy']:
                    strategy_scenario = comp_data['by_strategy'][strategy.name]['scenario']
                    user_count = len(comp_data['user_ids'])
                    scenario_counts[strategy_scenario] += user_count

            total_users = sum(scenario_counts.values())

            # Calculate fit score
            # Scenario A: Good (weight = +1.0) - training matches needs
            # Scenario D: Good (weight = +1.0) - already achieved
            # Scenario B: Bad (weight = -2.0) - gaps are CRITICAL, double penalty
            # Scenario C: Wasteful (weight = -0.5) - over-training costs money/time

            fit_score = (
                scenario_counts['A'] * 1.0 +      # Normal training
                scenario_counts['D'] * 1.0 +      # Already achieved
                scenario_counts['B'] * -2.0 +     # Gap (double penalty!)
                scenario_counts['C'] * -0.5       # Over-training (half penalty)
            )

            normalized_score = fit_score / total_users if total_users > 0 else 0

            strategy_fit_scores[strategy.name] = {
                'fit_score': normalized_score,
                'scenario_counts': scenario_counts,
                'scenario_A_percentage': scenario_counts['A'] / total_users * 100 if total_users > 0 else 0,
                'scenario_B_percentage': scenario_counts['B'] / total_users * 100 if total_users > 0 else 0,
                'scenario_C_percentage': scenario_counts['C'] / total_users * 100 if total_users > 0 else 0,
                'scenario_D_percentage': scenario_counts['D'] / total_users * 100 if total_users > 0 else 0,
                'target_level': get_archetype_target(strategy, competency_id),
                'total_users': total_users
            }

        # Pick strategy with HIGHEST FIT SCORE (not highest target!)
        if strategy_fit_scores:
            best_strategy = max(strategy_fit_scores, key=lambda s: strategy_fit_scores[s]['fit_score'])
            best_fit_data = strategy_fit_scores[best_strategy]
        else:
            best_strategy = None
            best_fit_data = None

        # Get max role requirement for this competency
        max_role_requirement = get_max_role_requirement_for_competency(competency_id)

        # Determine if there's a REAL gap using the BEST-FIT strategy
        if best_fit_data:
            best_target = best_fit_data['target_level']
            has_real_gap = best_target < max_role_requirement
            gap_size = max_role_requirement - best_target if has_real_gap else 0

            # Get users in Scenario B for the best-fit strategy
            scenario_B_count = best_fit_data['scenario_counts']['B']
            scenario_B_pct = best_fit_data['scenario_B_percentage']

            # Get user IDs from best strategy
            users_with_real_gap = []
            if 'by_strategy' in distribution and best_strategy in distribution['by_strategy']:
                best_strategy_data = distribution['by_strategy'][best_strategy]
                users_with_real_gap = best_strategy_data['users_by_scenario'].get('B', [])
        else:
            has_real_gap = False
            gap_size = 0
            scenario_B_count = 0
            scenario_B_pct = 0
            users_with_real_gap = []

        coverage[competency_id] = {
            'competency_name': distribution['competency_name'],
            'max_role_requirement': max_role_requirement,
            'best_fit_strategy': best_strategy,
            'best_fit_score': best_fit_data['fit_score'] if best_fit_data else 0,
            'all_strategy_fit_scores': strategy_fit_scores,
            'has_real_gap': has_real_gap,
            'gap_size': gap_size,
            'scenario_B_count': scenario_B_count,
            'scenario_B_percentage': scenario_B_pct,
            'users_with_real_gap': list(users_with_real_gap),
            'gap_severity': classify_gap_severity(scenario_B_pct, has_real_gap)
        }

    return coverage

def classify_gap_severity(scenario_B_percentage, has_real_gap):
    """
    Classify gap severity based on Scenario B percentage and reality check
    """
    if not has_real_gap:
        return 'none'  # Other strategies cover it
    elif scenario_B_percentage > 60:
        return 'critical'
    elif scenario_B_percentage >= 20:
        return 'significant'
    elif scenario_B_percentage > 0:
        return 'minor'
    else:
        return 'none'

# =============================================================================
# STEP 5: STRATEGY-LEVEL VALIDATION (NEW - HOLISTIC ASSESSMENT)
# =============================================================================

def validate_strategy_adequacy(competency_distributions, cross_strategy_coverage):
    """
    Step 5 NEW: Aggregate Scenario B data across all competencies

    Answers: "Are the selected strategies adequate for the organization?"

    Key Principle: Make strategy-level decisions, not per-competency decisions
    Only recommend new strategies if SYSTEMATIC gaps exist across many competencies
    """

    # Categorize competencies by gap severity
    critical_gaps = []     # Scenario B > 60% AND real gap exists
    significant_gaps = []  # Scenario B 20-60% AND real gap exists
    minor_gaps = []        # Scenario B < 20% AND real gap exists
    over_training = []     # Scenario C > 40%
    well_covered = []      # Scenario A/D dominant, no gaps

    for competency_id, coverage in cross_strategy_coverage.items():
        severity = coverage['gap_severity']

        # Check for over-training (Scenario C) from the best-fit strategy's data
        best_strategy = coverage['best_fit_strategy']
        scenario_C_pct = 0
        if best_strategy and 'by_strategy' in competency_distributions[competency_id]:
            if best_strategy in competency_distributions[competency_id]['by_strategy']:
                best_strategy_data = competency_distributions[competency_id]['by_strategy'][best_strategy]
                scenario_C_pct = best_strategy_data.get('scenario_C_percentage', 0)

        if severity == 'critical':
            critical_gaps.append(competency_id)
        elif severity == 'significant':
            significant_gaps.append(competency_id)
        elif severity == 'minor':
            minor_gaps.append(competency_id)
        elif scenario_C_pct > 40:
            over_training.append(competency_id)
        else:
            well_covered.append(competency_id)

    # Calculate overall metrics
    total_competencies = len(cross_strategy_coverage)
    total_gaps = len(critical_gaps) + len(significant_gaps) + len(minor_gaps)
    gap_percentage = (total_gaps / total_competencies * 100) if total_competencies > 0 else 0

    # Count total affected users (across all gap competencies)
    # Use users_with_real_gap from cross_strategy_coverage (after cross-check)
    total_users_with_gaps = len(set(
        user_id
        for comp_id in (critical_gaps + significant_gaps + minor_gaps)
        for user_id in cross_strategy_coverage[comp_id].get('users_with_real_gap', [])
    ))

    # Determine validation status
    if len(critical_gaps) >= 3:  # Multiple critical gaps
        status = 'CRITICAL'
        severity = 'critical'
        message = f'{len(critical_gaps)} competencies have critical gaps (>60% of users affected)'
        requires_revision = True
    elif gap_percentage > 40:  # Gaps in many competencies
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

    # Add over-training warning if applicable
    if len(over_training) > 3:
        message += f' | WARNING: {len(over_training)} competencies may involve over-training'

    return {
        'status': status,
        'severity': severity,
        'message': message,
        'gap_percentage': gap_percentage,
        'competency_breakdown': {
            'critical_gaps': critical_gaps,
            'significant_gaps': significant_gaps,
            'minor_gaps': minor_gaps,
            'over_training': over_training,
            'well_covered': well_covered
        },
        'total_users_with_gaps': total_users_with_gaps,
        'strategies_adequate': status in ['EXCELLENT', 'GOOD'],
        'requires_strategy_revision': requires_revision,
        'recommendation_level': determine_recommendation_level(
            len(critical_gaps), len(significant_gaps), len(minor_gaps)
        )
    }

def determine_recommendation_level(critical_count, significant_count, minor_count):
    """
    Determine what level of action is needed
    """
    if critical_count >= 3:
        return 'URGENT_STRATEGY_ADDITION'
    elif critical_count > 0 or significant_count >= 5:
        return 'STRATEGY_ADDITION_RECOMMENDED'
    elif significant_count >= 2 or minor_count >= 5:
        return 'SUPPLEMENTARY_MODULES'
    else:
        return 'PROCEED_AS_PLANNED'

# =============================================================================
# STEP 6: MAKE STRATEGIC DECISIONS (REVISED - INFORMED BY VALIDATION)
# =============================================================================

def make_distribution_based_decisions(competency_distributions, cross_strategy_coverage, strategy_validation):
    """
    Step 6 REVISED: Make decisions informed by validation results

    IMPORTANT: This now makes HOLISTIC decisions at strategy level,
    not isolated per-competency decisions
    """

    recommendation_level = strategy_validation['recommendation_level']

    # Initialize recommendations structure
    recommendations = {
        'overall_action': recommendation_level,
        'overall_message': strategy_validation['message'],
        'per_competency_details': {},
        'suggested_strategy_additions': [],
        'supplementary_module_guidance': []
    }

    # If strategies are adequate, provide minor guidance only
    if strategy_validation['strategies_adequate']:
        recommendations['overall_action'] = 'PROCEED_AS_PLANNED'
        recommendations['overall_message'] = 'Selected strategies are well-aligned with organizational needs'

        # Provide Phase 3 guidance for minor gaps
        if strategy_validation['gap_percentage'] > 0:
            minor_gap_comps = strategy_validation['competency_breakdown']['minor_gaps']
            for comp_id in minor_gap_comps:
                # Get Scenario B count from cross_strategy_coverage (after cross-check)
                scenario_B_count = cross_strategy_coverage[comp_id]['scenario_B_count']

                recommendations['supplementary_module_guidance'].append({
                    'competency_id': comp_id,
                    'competency_name': competency_distributions[comp_id]['competency_name'],
                    'guidance': 'Select advanced modules during Phase 3',
                    'affected_users': scenario_B_count
                })

    # If major gaps exist, recommend strategy additions
    elif strategy_validation['requires_strategy_revision']:
        critical_and_significant = (
            strategy_validation['competency_breakdown']['critical_gaps'] +
            strategy_validation['competency_breakdown']['significant_gaps']
        )

        # Find best strategy to fill these gaps
        suggested_strategy = find_best_strategy_to_fill_gaps(
            critical_and_significant,
            cross_strategy_coverage
        )

        recommendations['suggested_strategy_additions'].append({
            'suggested_strategy': suggested_strategy,
            'rationale': f'Would cover gaps in {len(critical_and_significant)} competencies',
            'competencies_affected': critical_and_significant,
            'priority': 'HIGH'
        })

    # Provide detailed per-competency information
    for competency_id, coverage in cross_strategy_coverage.items():
        distribution = competency_distributions[competency_id]

        recommendations['per_competency_details'][competency_id] = {
            'competency_name': distribution['competency_name'],
            'scenario_B_percentage': coverage['scenario_B_percentage'],  # From cross-strategy check
            'scenario_B_count': coverage['scenario_B_count'],
            'has_real_gap': coverage['has_real_gap'],
            'gap_severity': coverage['gap_severity'],
            'best_fit_strategy': coverage['best_fit_strategy'],
            'best_fit_score': coverage['best_fit_score'],
            'all_strategy_fit_scores': coverage['all_strategy_fit_scores'],
            'max_requirement': coverage['max_role_requirement']
        }

    return recommendations

# =============================================================================
# STEP 7: GENERATE UNIFIED OBJECTIVES (UPDATED WITH VALIDATION CONTEXT)
# =============================================================================

def generate_unified_objectives(strategic_decisions, role_analyses, selected_strategies, competency_distributions):
    """
    Step 7: Generate ONE unified set of objectives per strategy
    Now includes validation context and strategic guidance
    """
    unified_objectives = {}

    for strategy in selected_strategies:
        strategy_objectives = []

        for competency_id in all_competency_ids:
            # Skip core competencies (cannot be directly trained)
            if competency_id in [1, 4, 5, 6]:
                continue

            decision = strategic_decisions['per_competency_details'].get(competency_id, {})
            distribution = competency_distributions[competency_id]

            # Calculate organizational current level (median across ALL users)
            all_user_scores = get_all_user_scores_for_competency(competency_id)
            org_current_level = calculate_median(all_user_scores)

            # Get archetype target for this strategy
            archetype_target = get_archetype_target(strategy, competency_id)

            # Get max role requirement for reference
            max_role_requirement = get_max_role_requirement_for_competency(competency_id)

            # Get scenario data for THIS SPECIFIC STRATEGY
            strategy_scenario_data = None
            if 'by_strategy' in distribution and strategy.name in distribution['by_strategy']:
                strategy_scenario_data = distribution['by_strategy'][strategy.name]

            # Generate objective if training needed
            if org_current_level < archetype_target:
                objective = {
                    'competency_id': competency_id,
                    'competency_name': distribution['competency_name'],
                    'current_level': org_current_level,
                    'target_level': archetype_target,
                    'max_role_requirement': max_role_requirement,
                    'gap': archetype_target - org_current_level,
                    'learning_objective': generate_objective_text(
                        competency_id, org_current_level, archetype_target, strategy
                    ),
                    'comparison_type': '3-way',
                    'gap_severity': decision.get('gap_severity', 'none')
                }

                # Add scenario distribution if available for this strategy
                if strategy_scenario_data:
                    objective['scenario_distribution'] = {
                        'A': strategy_scenario_data['scenario_A_percentage'],
                        'B': strategy_scenario_data['scenario_B_percentage'],
                        'C': strategy_scenario_data['scenario_C_percentage'],
                        'D': strategy_scenario_data['scenario_D_percentage']
                    }
                    objective['users_requiring_training'] = (
                        strategy_scenario_data['scenario_A_count'] +
                        strategy_scenario_data['scenario_B_count']
                    )

                # Add notes based on gap severity from cross-strategy check
                if decision.get('has_real_gap') and decision.get('gap_severity') in ['significant', 'critical']:
                    scenario_B_pct = decision.get('scenario_B_percentage', 0)
                    objective['note'] = f"Consider supplementary modules - {scenario_B_pct:.1f}% of users need higher levels"

                strategy_objectives.append(objective)

            elif org_current_level < max_role_requirement:
                # Current meets strategy target but not all role requirements
                # Get Scenario B count from cross-strategy coverage (real gap users)
                scenario_B_count = decision.get('scenario_B_count', 0)

                strategy_objectives.append({
                    'competency_id': competency_id,
                    'competency_name': distribution['competency_name'],
                    'current_level': org_current_level,
                    'target_level': archetype_target,
                    'max_role_requirement': max_role_requirement,
                    'status': 'target_achieved_but_role_gap',
                    'note': f'{scenario_B_count} users in roles requiring level {max_role_requirement}'
                })

        unified_objectives[strategy.name] = {
            'priority': getattr(strategy, 'priority', 'PRIMARY'),
            'objectives': strategy_objectives,
            'summary': {
                'total_objectives': len([obj for obj in strategy_objectives if 'learning_objective' in obj]),
                'competencies_with_gaps': len([obj for obj in strategy_objectives if obj.get('gap', 0) > 0])
            }
        }

    return unified_objectives
```

### 3-Way Comparison Scenarios (Role-Based Only)

```python
def classify_gap_scenario(current, archetype_target, role_target):
    """
    Classify gap into scenarios for role-based pathway

    These scenarios are the FOUNDATION of the validation layer
    """
    if current < archetype_target <= role_target:
        return 'A'  # Normal: training brings us toward role requirement

    elif archetype_target <= current < role_target:
        return 'B'  # Strategy insufficient - KEY INDICATOR for validation

    elif archetype_target > role_target:
        return 'C'  # Strategy exceeds role needs (over-training)

    else:  # current >= archetype_target AND current >= role_target
        return 'D'  # All targets already met
```

### Key Helper Functions

```python
def calculate_median(values):
    """
    Calculate median - returns actual competency level
    Better than mean for ordinal data
    """
    if not values:
        return 0

    sorted_values = sorted(values)
    n = len(sorted_values)

    if n % 2 == 1:
        # Odd count: return middle value
        return sorted_values[n // 2]
    else:
        # Even count: average two middle values
        mid1 = sorted_values[n // 2 - 1]
        mid2 = sorted_values[n // 2]
        avg = (mid1 + mid2) / 2
        # Round to nearest valid level
        return round_to_valid_level(avg)

def round_to_valid_level(value):
    """Map to nearest valid competency level"""
    VALID_LEVELS = [0, 1, 2, 4, 6]
    return min(VALID_LEVELS, key=lambda x: abs(x - value))

def get_latest_assessments_per_user(org_id, survey_type):
    """
    Get ONLY the latest assessment per user (ignore retakes)
    """
    query = """
    SELECT DISTINCT ON (user_id)
        user_id,
        id as assessment_id,
        completed_at,
        selected_roles,
        tasks_responsibilities
    FROM user_assessment
    WHERE organization_id = %s
        AND survey_type = %s
        AND completed_at IS NOT NULL
    ORDER BY user_id, completed_at DESC
    """
    return execute_query(query, [org_id, survey_type])

def get_max_role_requirement_for_competency(competency_id):
    """
    Get highest requirement across all org roles for a specific competency
    """
    query = """
    SELECT MAX(role_competency_value)
    FROM role_competency_matrix
    WHERE competency_id = %s
    """
    result = execute_query(query, [competency_id])
    return result[0][0] if result and result[0][0] else 0

def find_best_strategy_to_fill_gaps(gap_competency_ids, cross_strategy_coverage):
    """
    NEW: Find which additional strategy would best fill the identified gaps
    """
    # All available strategies (not currently selected)
    all_strategies = [
        'se_for_managers',
        'common_understanding',
        'orientation_pilot',
        'needs_based_project',
        'continuous_support',
        'certification',
        'train_the_trainer'
    ]

    strategy_scores = {}

    for strategy_name in all_strategies:
        coverage_count = 0
        total_gap = 0

        for comp_id in gap_competency_ids:
            # Get what this strategy provides
            strategy_target = get_archetype_target_by_name(strategy_name, comp_id)
            required_level = cross_strategy_coverage[comp_id]['max_role_requirement']

            if strategy_target >= required_level:
                coverage_count += 1
            else:
                total_gap += (required_level - strategy_target)

        # Score: prioritize high coverage with minimal over-training
        strategy_scores[strategy_name] = coverage_count * 100 - total_gap

    return max(strategy_scores, key=strategy_scores.get) if strategy_scores else None

def get_archetype_target_by_name(strategy_name, competency_id):
    """
    Get archetype target for a strategy by name (for recommendation purposes)
    """
    # This would query the strategy_archetype_values table
    query = """
    SELECT target_value
    FROM strategy_archetype_values
    WHERE strategy_name = %s AND competency_id = %s
    """
    result = execute_query(query, [strategy_name, competency_id])
    return result[0][0] if result and result[0][0] else 0
```

### Complete Output Structure (UPDATED WITH VALIDATION LAYER)

```json
{
  "organization_id": 28,
  "pathway": "ROLE_BASED",
  "generation_timestamp": "2025-11-03T10:00:00Z",
  "data_source": "latest_assessments_only",

  "assessment_summary": {
    "total_users": 45,
    "assessments_completed": 40,
    "completion_rate": 0.889,
    "using_latest_only": true,
    "retakes_ignored": 17
  },

  "competency_scenario_distributions": {
    "11": {
      "competency_name": "Decision Management",
      "by_strategy": {
        "needs_based_project": {
          "total_users": 40,
          "scenario_A_count": 30,
          "scenario_B_count": 3,
          "scenario_C_count": 2,
          "scenario_D_count": 5,
          "scenario_A_percentage": 75.0,
          "scenario_B_percentage": 7.5,
          "scenario_C_percentage": 5.0,
          "scenario_D_percentage": 12.5,
          "users_by_scenario": {
            "A": [1, 2, 3, ...],
            "B": [35, 36, 37],
            "C": [30, 31],
            "D": [40, 41, 42, 43, 44]
          }
        },
        "se_for_managers": {
          "total_users": 40,
          "scenario_A_count": 20,
          "scenario_B_count": 15,
          "scenario_C_count": 0,
          "scenario_D_count": 5,
          "scenario_A_percentage": 50.0,
          "scenario_B_percentage": 37.5,
          "scenario_C_percentage": 0.0,
          "scenario_D_percentage": 12.5,
          "users_by_scenario": {
            "A": [1, 2, 3, ...],
            "B": [10, 11, 12, ...],
            "C": [],
            "D": [40, 41, 42, 43, 44]
          }
        }
      }
    }
  },

  "cross_strategy_coverage": {
    "11": {
      "competency_name": "Decision Management",
      "max_role_requirement": 6,
      "best_fit_strategy": "needs_based_project",
      "best_fit_score": 0.65,
      "all_strategy_fit_scores": {
        "needs_based_project": {
          "fit_score": 0.65,
          "scenario_counts": {"A": 35, "B": 3, "C": 2, "D": 0},
          "scenario_A_percentage": 87.5,
          "scenario_B_percentage": 7.5,
          "scenario_C_percentage": 5.0,
          "scenario_D_percentage": 0.0,
          "target_level": 4,
          "total_users": 40
        },
        "se_for_managers": {
          "fit_score": -0.25,
          "scenario_counts": {"A": 10, "B": 30, "C": 0, "D": 0},
          "scenario_A_percentage": 25.0,
          "scenario_B_percentage": 75.0,
          "scenario_C_percentage": 0.0,
          "scenario_D_percentage": 0.0,
          "target_level": 2,
          "total_users": 40
        }
      },
      "has_real_gap": true,
      "gap_size": 2,
      "scenario_B_count": 3,
      "scenario_B_percentage": 7.5,
      "users_with_real_gap": [35, 36, 37],
      "gap_severity": "minor",
      "_note": "scenario_B_count and users_with_real_gap are from the BEST-FIT strategy (needs_based_project with score 0.65), representing users who still need higher levels. Note: se_for_managers has negative fit score due to high Scenario B (75% gaps)."
    }
  },

  "strategy_validation": {
    "status": "ACCEPTABLE",
    "severity": "moderate",
    "message": "25.0% of competencies have gaps, supplementary training recommended",
    "gap_percentage": 25.0,
    "competency_breakdown": {
      "critical_gaps": [],
      "significant_gaps": [11, 15],
      "minor_gaps": [9, 12],
      "over_training": [],
      "well_covered": [2, 3, 7, 8, 10, 13, 14, 16]
    },
    "total_users_with_gaps": 15,
    "strategies_adequate": true,
    "requires_strategy_revision": false,
    "recommendation_level": "SUPPLEMENTARY_MODULES"
  },

  "strategic_decisions": {
    "overall_action": "SUPPLEMENTARY_MODULES",
    "overall_message": "Selected strategies are well-aligned with organizational needs",
    "per_competency_details": {
      "11": {
        "competency_name": "Decision Management",
        "scenario_B_percentage": 20.0,
        "scenario_B_count": 8,
        "has_real_gap": true,
        "gap_severity": "significant",
        "best_fit_strategy": "needs_based_project",
        "best_fit_score": 0.45,
        "all_strategy_fit_scores": {
          "needs_based_project": {
            "fit_score": 0.45,
            "scenario_A_percentage": 65.0,
            "scenario_B_percentage": 20.0,
            "scenario_C_percentage": 15.0,
            "target_level": 4
          },
          "se_for_managers": {
            "fit_score": -0.60,
            "scenario_A_percentage": 20.0,
            "scenario_B_percentage": 80.0,
            "scenario_C_percentage": 0.0,
            "target_level": 2
          }
        },
        "max_requirement": 6
      }
    },
    "suggested_strategy_additions": [],
    "supplementary_module_guidance": [
      {
        "competency_id": 11,
        "competency_name": "Decision Management",
        "guidance": "Select advanced modules during Phase 3",
        "affected_users": 8
      }
    ]
  },

  "learning_objectives_by_strategy": {
    "needs_based_project": {
      "priority": "PRIMARY",
      "objectives": [
        {
          "competency_id": 11,
          "competency_name": "Decision Management",
          "current_level": 2,
          "target_level": 4,
          "max_role_requirement": 6,
          "gap": 2,
          "learning_objective": "By the end of this training...",
          "comparison_type": "3-way",
          "scenario_distribution": {
            "A": 65.0,
            "B": 20.0,
            "C": 5.0,
            "D": 10.0
          },
          "gap_severity": "significant",
          "users_requiring_training": 34,
          "note": "Consider supplementary modules - 20.0% of users need higher levels"
        }
      ],
      "summary": {
        "total_objectives": 12,
        "competencies_with_gaps": 12
      }
    }
  }
}
```

---

## Part 3: Critical Implementation Notes

### Important Clarifications

1. **Scenarios A, B, C, D are Foundation**
   - Calculated per-competency in Step 3
   - Used throughout validation layer
   - Scenario B is the KEY indicator for strategy inadequacy

2. **Two-Layer Decision Making**
   - **Layer 1**: Per-competency scenario classification
   - **Layer 2**: Strategy-level validation (aggregates across competencies)
   - Prevents fragmented recommendations for isolated gaps

3. **Cross-Strategy Coverage is Critical**
   - Before recommending new strategies, check if existing ones already cover gaps
   - Multiple selected strategies may TOGETHER provide adequate coverage
   - Only recommend additions if REAL gaps exist after cross-check

4. **Holistic Validation Thresholds**
   - **≥3 critical gaps** OR **>40% gap percentage** → Strategy revision needed
   - **2-4 significant gaps** OR **20-40% gap percentage** → Supplementary modules
   - **<20% gap percentage** → Minor guidance for Phase 3

5. **Task-Based Pathway Simpler**
   - No validation layer needed (no roles to validate against)
   - Simple 2-way comparison (Current vs Archetype)
   - Appropriate for low-maturity organizations

6. **Only LATEST Assessment Counts**
   - Ignore retakes and test data
   - One assessment per user for calculation
   - Query must use DISTINCT ON (user_id) ORDER BY completed_at DESC

7. **One Organization, One Plan**
   - Even with multiple roles and validation layers
   - System produces unified objectives
   - Simplifies training management

### Pre-Implementation Checklist

- [x] Phase 1 completed (maturity score, strategies selected)
- [x] Phase 2 assessments completed (minimum 70% of users)
- [x] Database tables exist and populated
- [x] Learning objective templates available
- [ ] Validation logic implemented with two layers
- [ ] Cross-strategy coverage checking implemented
- [ ] Admin confirmation before generation

### Database Queries Required

```sql
-- Get latest assessment per user
SELECT DISTINCT ON (user_id)
    user_id, assessment_id, completed_at, selected_roles
FROM user_assessment
WHERE organization_id = :org_id
    AND survey_type = :survey_type
    AND completed_at IS NOT NULL
ORDER BY user_id, completed_at DESC;

-- Get competency scores for users
SELECT user_id, competency_id, score
FROM user_se_competency_survey_results
WHERE organization_id = :org_id
    AND user_id IN (:user_ids);

-- Get role requirements
SELECT role_id, competency_id, role_competency_value
FROM role_competency_matrix
WHERE organization_id = :org_id;

-- Get max role requirement per competency
SELECT competency_id, MAX(role_competency_value) as max_requirement
FROM role_competency_matrix
WHERE organization_id = :org_id
GROUP BY competency_id;

-- Get archetype targets for strategies
SELECT strategy_id, competency_id, target_value
FROM strategy_archetype_values
WHERE strategy_id IN (:strategy_ids);

-- Check if organization has roles
SELECT COUNT(*) as role_count
FROM organization_roles
WHERE organization_id = :org_id;
```

### API Endpoints to Implement

```python
# Main generation endpoint
@main_bp.route('/api/learning-objectives/generate', methods=['POST'])
def generate_learning_objectives():
    org_id = request.json.get('organization_id')
    force = request.json.get('force', False)  # Override 70% check

    # Check completion rate unless forced
    if not force:
        rate = get_completion_rate(org_id)
        if rate < 0.7:
            return jsonify({'error': 'Insufficient assessments'}), 400

    # Generate objectives with validation layer
    result = generate_learning_objectives(org_id)

    # Store in database
    save_learning_objectives(result)

    return jsonify(result), 200

# Get validation summary
@main_bp.route('/api/learning-objectives/<int:org_id>/validation', methods=['GET'])
def get_strategy_validation(org_id):
    """
    NEW: Get just the validation results without full objective generation
    Useful for quick strategy adequacy check
    """
    result = generate_learning_objectives(org_id)
    return jsonify({
        'strategy_validation': result.get('strategy_validation'),
        'cross_strategy_coverage': result.get('cross_strategy_coverage')
    }), 200

# Get latest generated objectives
@main_bp.route('/api/learning-objectives/<int:org_id>/latest', methods=['GET'])
def get_latest_objectives(org_id):
    # Retrieve from database
    pass

# Approve objectives (admin)
@main_bp.route('/api/learning-objectives/approve', methods=['POST'])
def approve_objectives():
    # Mark as approved, trigger next phase
    pass
```

### Testing Scenarios

1. **Excellent Strategy Selection**
   - All Scenario B percentages < 10%
   - No real gaps after cross-strategy check
   - Expected: EXCELLENT status, proceed as planned

2. **Good Strategy Selection with Minor Gaps**
   - 1-2 competencies with Scenario B 20-30%
   - Gaps covered by other selected strategies
   - Expected: GOOD status, Phase 3 guidance only

3. **Inadequate Strategy Selection**
   - 5+ competencies with Scenario B > 40%
   - Real gaps exist after cross-strategy check
   - Expected: INADEQUATE status, strategy addition recommended

4. **Critical Gaps**
   - 3+ competencies with Scenario B > 60%
   - Expected: CRITICAL status, urgent strategy revision

5. **Multi-Strategy Coverage**
   - Strategy A: covers competencies 1-8 to level 2
   - Strategy B: covers competencies 9-16 to level 4
   - Expected: No gaps if requirements are met by combined coverage

### Configuration Options

```python
CONFIG = {
    # Aggregation methods
    'current_level_method': 'median',  # Don't change

    # Validation thresholds
    'minimum_completion_rate': 0.7,
    'critical_gap_threshold': 60,  # Scenario B percentage
    'significant_gap_threshold': 20,
    'critical_gap_competency_count': 3,  # Number of critical competencies
    'inadequate_gap_percentage': 40,  # Overall gap percentage

    # Features
    'enable_validation_layer': True,  # NEW - can disable for testing
    'enable_cross_strategy_check': True,  # NEW - can disable for testing
    'use_strategy_priorities': False,  # Simpler without

    # Competencies
    'core_competency_ids': [1, 4, 5, 6],
    'valid_levels': [0, 1, 2, 4, 6],

    # External training
    'level_6_flag': 'external_training_required'
}
```

---

## Part 4: Algorithm Validation and Consistency Check

### Algorithm Flow Validation

**TASK-BASED PATHWAY (Low Maturity)**
```
Input: Organization with no roles
↓
Step 1: Get latest assessments
↓
Step 2: Get selected strategies
↓
Step 3: For each competency, calculate median current level
↓
Step 4: Compare current vs archetype target (2-way)
↓
Step 5: Generate objectives
↓
Output: Learning objectives by strategy (no validation layer)
```

**ROLE-BASED PATHWAY (High Maturity)**
```
Input: Organization with defined roles
↓
Step 1: Get latest assessments + roles
↓
Step 2: Analyze each role → classify into scenarios A/B/C/D per competency
↓
Step 3: Aggregate by user distribution → count users in each scenario per competency
↓
Step 4: Check cross-strategy coverage → do multiple strategies cover gaps?
↓
Step 5: Validate strategy adequacy → aggregate Scenario B across competencies
↓
Step 6: Make strategic decisions → holistic recommendations
↓
Step 7: Generate unified objectives → one plan per strategy
↓
Output: Learning objectives + validation + recommendations
```

### Consistency Validation

**✓ Scenarios A, B, C, D**
- Defined in Step 2 (classify_gap_scenario)
- Counted in Step 3 (aggregate_by_user_distribution)
- Used in Step 4 (check_cross_strategy_coverage)
- Aggregated in Step 5 (validate_strategy_adequacy)
- Referenced in Step 6 (make_distribution_based_decisions)
- Included in output (Step 7)

**✓ Validation Layer Integration**
- Built on top of per-competency analysis
- Does not replace scenarios, uses them
- Provides holistic strategy-level view
- Prevents fragmented recommendations

**✓ Cross-Strategy Coverage**
- Checks all selected strategies TOGETHER
- Prevents unnecessary strategy additions
- Real gaps only after cross-check

**✓ Decision Thresholds**
- Per-competency: 60% (critical), 20-60% (significant), <20% (minor)
- Strategy-level: 3+ critical OR 40%+ gap → revision needed
- Consistent throughout algorithm

---

## Summary: Implementation Roadmap

### Phase 1: Foundation (Task-Based Pathway)
1. Implement 2-way comparison logic
2. Test with Organization 28 (task-based)
3. Verify median calculations
4. Generate basic objectives

### Phase 2: Role-Based Core (Steps 2-3)
1. Implement role analysis (Step 2)
2. Implement user distribution aggregation (Step 3)
3. Test scenario classification (A, B, C, D)
4. Verify user counting logic

### Phase 3: Validation Layer (Steps 4-5) - NEW
1. Implement cross-strategy coverage check
2. Implement strategy validation
3. Test with multiple selected strategies
4. Verify holistic decision logic

### Phase 4: Recommendations (Step 6)
1. Implement strategic decision making
2. Integrate validation results
3. Generate appropriate recommendations
4. Test recommendation logic

### Phase 5: Objective Generation (Step 7)
1. Generate unified objectives
2. Include validation context
3. Format output structure
4. Test complete flow

### Phase 6: Integration & Testing
1. End-to-end testing
2. Edge case validation
3. Performance optimization
4. Admin interface

---

*This document (v3) integrates the validation layer with the original per-competency analysis, providing both granular and holistic views of organizational training needs.*
