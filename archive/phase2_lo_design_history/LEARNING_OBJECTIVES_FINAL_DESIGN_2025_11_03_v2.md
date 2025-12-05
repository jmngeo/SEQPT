# Learning Objectives Generation - Complete Final Design Document (v2)
**Date**: November 3, 2025
**Status**: FINALIZED WITH ALL DETAILS - Ready for Implementation
**Purpose**: Complete reference document for Phase 2 Task 3 implementation

---

## Executive Summary

The Learning Objectives Generation system creates customized training objectives for organizations based on their competency assessment results. The system handles two distinct pathways depending on organizational maturity:

1. **Low Maturity Organizations** (no defined SE roles) → Task-based pathway with 2-way comparison
2. **High Maturity Organizations** (defined SE roles) → Role-based pathway with 3-way comparison

**Critical Design Principle**: Generate ONE unified set of learning objectives per strategy for the entire organization, not separate objectives per role.

---

## Part 1: Non-Technical Explanation for Thesis Advisor

### What This System Does

Think of this system as an intelligent training planner that:
1. **Waits** for employees to complete competency assessments (minimum 70% completion)
2. **Looks** at what skills employees currently have (using median to find typical level)
3. **Compares** this to training strategy targets and role requirements (if roles exist)
4. **Generates** specific learning objectives to close the gaps
5. **Recommends** additional strategies if current ones insufficient

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

### How We Aggregate Data

**For Current Competency Levels**: Use **MEDIAN** (middle value)
- Example: 5 developers with skills [1,2,2,4,6] → median = 2
- Why? Not affected by outliers, returns actual valid level

**For Role Requirements**: Each role keeps its specific requirements
- We DON'T average role requirements (would lose role differentiation)
- Instead, we count how many USERS need each level
- Decisions based on user distribution, not role averages

### Decision Making Based on User Distribution

The system counts how many USERS (not roles) fall into each scenario:
- **>60% users** need higher levels → Recommend additional strategy
- **20-60% users** need more → Suggest supplementary modules
- **<20% users** need more → Note for future training cycles

### Important Notes

- **Assessment First**: Learning objectives generated ONLY after assessments complete
- **Latest Only**: System uses only the LATEST assessment per user (ignores retakes)
- **One Plan**: Creates ONE training plan for organization, not separate per role

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
    """
    # Step 1: Get LATEST assessment per user (ignore retakes)
    user_assessments = get_latest_assessments_per_user(org_id, 'unknown_roles')

    # Step 2: Get selected strategies (with or without priorities)
    selected_strategies = get_organization_strategies(org_id)

    objectives = {}

    for strategy in selected_strategies:
        # Optional: Handle priority (can be ignored for simpler implementation)
        # if strategy.priority == 'SUPPLEMENTARY':
        #     ... special handling ...

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

                # ================================================================
                # FUTURE ENHANCEMENT: Soft Target Guidance (NOT IMPLEMENTED NOW)
                # ================================================================
                # If needed in future, reference task-derived requirements as context:
                #
                # task_requirements = get_from_unknown_role_competency_matrix(org_id, competency)
                # median_task_requirement = calculate_median(task_requirements)
                # if median_task_requirement > archetype_target:
                #     strategy_objectives[-1]['future_note'] = (
                #         f"Task analysis suggests level {median_task_requirement} "
                #         f"may be beneficial. Consider in next iteration."
                #     )
                # ================================================================

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

    return objectives
```

### Algorithm 2: Role-Based Organizations (High Maturity) - COMPLETE

```python
def generate_role_based_objectives(org_id):
    """
    3-WAY COMPARISON for organizations with defined roles
    IMPORTANT: We analyze each role separately, then aggregate decisions
    """
    # Step 1: Get latest assessments and role selections
    user_assessments = get_latest_assessments_per_user(org_id, 'known_roles')
    organization_roles = get_organization_roles(org_id)
    selected_strategies = get_organization_strategies(org_id)

    # Step 2: Analyze each role individually
    role_analyses = analyze_all_roles(
        organization_roles, user_assessments, selected_strategies
    )

    # Step 3: Aggregate by user distribution (NOT averaging requirements!)
    user_distribution = aggregate_by_user_distribution(role_analyses)

    # Step 4: Make strategic decisions based on distribution
    strategic_decisions = make_distribution_based_decisions(user_distribution)

    # Step 5: Generate unified objectives
    unified_objectives = generate_unified_objectives(
        strategic_decisions, role_analyses, selected_strategies
    )

    return unified_objectives

def analyze_all_roles(organization_roles, user_assessments, selected_strategies):
    """
    Step 2 DETAILED: Analyze each role separately
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

        role_analyses[role.id] = {}

        for competency in all_16_competencies:
            # Get current level for users IN THIS ROLE
            role_user_scores = [
                get_user_competency_score(user.id, competency.id)
                for user in users_in_role
            ]
            current_level = calculate_median(role_user_scores)

            # Get THIS SPECIFIC ROLE's requirement
            role_requirement = get_role_competency_value(role.id, competency.id)

            for strategy in selected_strategies:
                archetype_target = get_archetype_target(strategy, competency.id)

                # 3-way comparison for THIS SPECIFIC ROLE
                scenario = classify_gap_scenario(
                    current_level, archetype_target, role_requirement
                )

                role_analyses[role.id][competency.id] = {
                    'role_name': role.name,
                    'current_level': current_level,
                    'archetype_target': archetype_target,
                    'role_requirement': role_requirement,  # SPECIFIC to this role!
                    'scenario': scenario,
                    'users_in_role': len(users_in_role),
                    'user_ids': [u.id for u in users_in_role]
                }

    return role_analyses

def aggregate_by_user_distribution(role_analyses):
    """
    Step 3 DETAILED: Count USERS in each scenario (NOT averaging requirements!)
    This is where we handle multi-role users correctly
    """
    competency_distributions = {}

    for competency_id in all_competency_ids:
        # Track unique users in each scenario
        unique_users_by_scenario = {
            'A': set(),  # Current < Archetype ≤ Role (normal training)
            'B': set(),  # Archetype ≤ Current < Role (need higher strategy)
            'C': set(),  # Archetype > Role (over-training)
            'D': set()   # Targets already met
        }

        # Collect users from ALL roles
        for role_id, role_data in role_analyses.items():
            if competency_id in role_data:
                scenario = role_data[competency_id]['scenario']
                user_ids = role_data[competency_id]['user_ids']

                # Add to appropriate scenario (handles multi-role users via set)
                unique_users_by_scenario[scenario].update(user_ids)

        # Calculate percentages based on UNIQUE users
        all_unique_users = set()
        for users in unique_users_by_scenario.values():
            all_unique_users.update(users)
        total_users = len(all_unique_users)

        if total_users > 0:
            competency_distributions[competency_id] = {
                'total_users': total_users,
                'scenario_A_percentage': len(unique_users_by_scenario['A']) / total_users * 100,
                'scenario_B_percentage': len(unique_users_by_scenario['B']) / total_users * 100,
                'scenario_C_percentage': len(unique_users_by_scenario['C']) / total_users * 100,
                'scenario_D_percentage': len(unique_users_by_scenario['D']) / total_users * 100,
                'user_details': {
                    'A': list(unique_users_by_scenario['A']),
                    'B': list(unique_users_by_scenario['B']),
                    'C': list(unique_users_by_scenario['C']),
                    'D': list(unique_users_by_scenario['D'])
                }
            }

    return competency_distributions

def make_distribution_based_decisions(competency_distributions):
    """
    Step 4 DETAILED: Decide actions based on user distribution
    """
    strategic_decisions = {}

    for competency_id, distribution in competency_distributions.items():
        # Get percentages
        scenario_B_pct = distribution['scenario_B_percentage']
        scenario_C_pct = distribution['scenario_C_percentage']

        # Decision logic
        if scenario_B_pct > 60:
            # Majority need higher than strategy provides
            strategic_decisions[competency_id] = {
                'action': 'recommend_additional_strategy',
                'reason': f'{scenario_B_pct:.1f}% of users need higher levels',
                'suggested_strategy': find_better_strategy_for_competency(competency_id),
                'affected_users': distribution['user_details']['B']
            }

        elif 20 <= scenario_B_pct < 60:
            # Significant minority need more
            strategic_decisions[competency_id] = {
                'action': 'add_supplementary_modules',
                'reason': f'{scenario_B_pct:.1f}% need additional training',
                'phase_3_guidance': 'Select advanced modules for this group',
                'affected_users': distribution['user_details']['B']
            }

        elif scenario_C_pct > 50:
            # Many would be over-trained
            strategic_decisions[competency_id] = {
                'action': 'consider_lower_strategy',
                'reason': f'{scenario_C_pct:.1f}% would be over-trained',
                'warning': 'Strategy may be too advanced for current roles'
            }

        elif scenario_B_pct < 20 and scenario_B_pct > 0:
            # Small group needs more
            strategic_decisions[competency_id] = {
                'action': 'note_for_future',
                'reason': f'Small group ({scenario_B_pct:.1f}%) needs enhancement',
                'timing': 'next_iteration'
            }

        else:
            # Strategy is appropriate
            strategic_decisions[competency_id] = {
                'action': 'proceed_as_planned',
                'reason': 'Strategy matches organizational needs'
            }

    return strategic_decisions

def generate_unified_objectives(strategic_decisions, role_analyses, selected_strategies):
    """
    Step 5 DETAILED: Generate ONE unified set of objectives per strategy
    """
    unified_objectives = {}

    for strategy in selected_strategies:
        strategy_objectives = []

        for competency_id in all_competency_ids:
            decision = strategic_decisions.get(competency_id, {})

            # Calculate organizational current level (median across ALL users)
            all_user_scores = get_all_user_scores_for_competency(competency_id)
            org_current_level = calculate_median(all_user_scores)

            # Get archetype target
            archetype_target = get_archetype_target(strategy, competency_id)

            # For reference: get max role requirement (simplified approach)
            max_role_requirement = get_max_role_requirement(competency_id)

            # Generate objective if training needed
            if org_current_level < archetype_target:
                objective = {
                    'competency_id': competency_id,
                    'competency_name': get_competency_name(competency_id),
                    'current_level': org_current_level,
                    'target_level': archetype_target,
                    'max_role_requirement': max_role_requirement,
                    'gap': archetype_target - org_current_level,
                    'learning_objective': generate_objective_text(
                        competency_id, org_current_level, archetype_target
                    ),
                    'comparison_type': '3-way',
                    'decision': decision.get('action', 'proceed_as_planned'),
                    'rationale': decision.get('reason', ''),
                    'users_impacted': count_users_below_target(archetype_target)
                }

                # Add supplementary notes if needed
                if decision.get('action') == 'add_supplementary_modules':
                    objective['supplementary_note'] = decision.get('phase_3_guidance')

                strategy_objectives.append(objective)

        unified_objectives[strategy] = {
            'priority': strategy.priority if hasattr(strategy, 'priority') else 'PRIMARY',
            'objectives': strategy_objectives,
            'summary': generate_summary(strategy_objectives)
        }

    return unified_objectives
```

### 3-Way Comparison Scenarios (Role-Based Only)

```python
def classify_gap_scenario(current, archetype_target, role_target):
    """
    Classify gap into scenarios for role-based pathway
    """
    if current < archetype_target <= role_target:
        return 'A'  # Normal: training brings us toward role requirement

    elif archetype_target <= current < role_target:
        return 'B'  # Current strategy insufficient for role

    elif archetype_target > role_target:
        return 'C'  # Strategy exceeds role needs (over-training)

    else:  # current >= archetype_target AND current >= role_target
        return 'D'  # All targets already met
```

### Simplified Approach (Alternative Implementation)

```python
def generate_objectives_simplified(org_id):
    """
    SIMPLIFIED VERSION: Uses maximum role requirement instead of distribution
    Easier to implement, still effective
    """
    pathway = determine_pathway(org_id)

    objectives = {}
    for strategy in get_organization_strategies(org_id):
        strategy_objectives = []

        for competency in all_16_competencies:
            # Get current level (median of ALL users)
            all_scores = get_all_user_scores(org_id, competency.id)
            current_level = calculate_median(all_scores)

            # Get archetype target
            archetype_target = get_archetype_target(strategy, competency.id)

            if pathway == 'ROLE_BASED':
                # Use MAXIMUM role requirement (simpler than distribution)
                max_role_req = get_max_role_requirement(org_id, competency.id)

                # 3-way comparison with max
                if current_level < archetype_target:
                    if archetype_target <= max_role_req:
                        # Training appropriate
                        generate_objective(current_level, archetype_target)
                    else:
                        # Over-training warning
                        generate_objective_with_warning(current_level, archetype_target)

                elif current_level < max_role_req:
                    # Need higher strategy
                    add_recommendation('consider_higher_strategy')

            else:  # TASK_BASED
                # Simple 2-way comparison
                if current_level < archetype_target:
                    generate_objective(current_level, archetype_target)

        objectives[strategy] = strategy_objectives

    return objectives
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

def get_max_role_requirement(org_id, competency_id):
    """
    Simplified: Get highest requirement across all org roles
    """
    query = """
    SELECT MAX(role_competency_value)
    FROM role_competency_matrix
    WHERE organization_id = %s AND competency_id = %s
    """
    result = execute_query(query, [org_id, competency_id])
    return result[0][0] if result else 0

def handle_multi_role_users(user_id):
    """
    When user has multiple roles, use MAXIMUM requirement
    """
    user_roles = get_user_selected_roles(user_id)
    max_requirements = {}

    for competency_id in all_competency_ids:
        requirements = [
            get_role_requirement(role.id, competency_id)
            for role in user_roles
        ]
        max_requirements[competency_id] = max(requirements) if requirements else 0

    return max_requirements

def check_cross_strategy_coverage(selected_strategies, competency_id):
    """
    Check if multiple strategies together cover higher requirements
    """
    max_coverage = 0
    covering_strategy = None

    for strategy in selected_strategies:
        target = get_archetype_target(strategy, competency_id)
        if target > max_coverage:
            max_coverage = target
            covering_strategy = strategy

    return {
        'max_level_covered': max_coverage,
        'best_strategy': covering_strategy,
        'all_targets': {s.name: get_archetype_target(s, competency_id)
                       for s in selected_strategies}
    }
```

### Strategy Selection Hierarchy

```python
def get_strategy_recommendation_priority(org_maturity, rollout_scope, target_size):
    """
    Based on Phase 1 strategy selection logic
    """
    # Large organizations
    if target_size > 100:
        return {
            'primary': 'train_the_trainer',
            'reason': 'Large group requires multiplier approach'
        }

    # Low maturity organizations
    if org_maturity < 3:
        return {
            'primary': 'se_for_managers',
            'secondary_options': [
                'common_understanding',
                'orientation_pilot',
                'certification'
            ],
            'reason': 'Low maturity requires management buy-in first'
        }

    # High maturity organizations
    if rollout_scope > 3:
        return {
            'primary': 'continuous_support',
            'reason': 'High rollout scope needs ongoing support'
        }
    else:
        return {
            'primary': 'needs_based_project',
            'reason': 'Low rollout scope suits targeted training'
        }

def find_better_strategy_for_competency(competency_id, needed_level):
    """
    Find which strategy best addresses a competency gap
    """
    all_strategies = [
        'se_for_managers',      # Basic: levels 1-2
        'common_understanding',  # Awareness: level 2
        'orientation_pilot',     # Practical: level 4
        'needs_based_project',   # Customizable: up to 4
        'continuous_support',    # Ongoing: levels 2-4
        'certification',         # Advanced: level 4
        'train_the_trainer'      # Mastery: level 6
    ]

    strategy_scores = {}
    for strategy in all_strategies:
        target = get_archetype_target(strategy, competency_id)

        if target >= needed_level:
            # Penalize over-training
            overshoot = target - needed_level
            strategy_scores[strategy] = 100 - (overshoot * 10)
        else:
            # Heavily penalize under-training
            undershoot = needed_level - target
            strategy_scores[strategy] = 50 - (undershoot * 20)

    return max(strategy_scores, key=strategy_scores.get) if strategy_scores else None
```

### Complete Output Structure

```json
{
  "organization_id": 28,
  "pathway": "TASK_BASED",
  "generation_timestamp": "2025-11-03T10:00:00Z",
  "data_source": "latest_assessments_only",

  "assessment_summary": {
    "total_users": 45,
    "assessments_completed": 40,
    "completion_rate": 0.889,
    "using_latest_only": true,
    "retakes_ignored": 17
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
          "comparison_type": "2-way",
          "gap": 2,
          "learning_objective": "By the end of this training...",
          "users_requiring": 35,
          "impact_percentage": 87.5,
          "notes": []
        }
      ],
      "summary": {
        "total_objectives": 12,
        "core_competencies_noted": 4,
        "training_hours_estimated": 180,
        "competencies_already_met": 4
      }
    },

    "se_for_managers": {
      "priority": "SUPPLEMENTARY",
      "objectives": [...],
      "rationale": "Management buy-in strategy"
    },

    "common_understanding": {
      "priority": "SECONDARY",
      "objectives": [...]
    }
  },

  "strategic_recommendations": [
    {
      "type": "strategy_addition",
      "trigger": "user_distribution",
      "recommendation": "Consider 'certification' strategy",
      "rationale": "25% of users in technical roles need level 6",
      "competencies_affected": [14, 15, 16],
      "affected_user_count": 11,
      "priority": "medium",
      "timing": "next_iteration"
    }
  ],

  "cross_strategy_analysis": {
    "competencies_fully_covered": [1, 2, 3],
    "competencies_partially_covered": [4, 5],
    "competencies_not_covered": [],
    "maximum_coverage_by_competency": {...}
  },

  "module_planning_guidance": {
    "needs_based_project": {
      "approach": "customizable_modules",
      "core_modules_required": 8,
      "supplementary_modules_suggested": 3,
      "existing_training_reusable": ["project_management_basics"],
      "new_training_needed": ["systems_thinking_workshop"],
      "phase_3_reference": "Use gap analysis for module selection"
    }
  },

  "future_training_pipeline": {
    "gaps_remaining": [
      {
        "competency_id": 15,
        "competency_name": "Systems Architecture",
        "current": 4,
        "ultimate_need": 6,
        "affected_roles": ["System Architect"],
        "affected_users": 3,
        "suggested_approach": "external_certification",
        "timeline": "after_initial_training"
      }
    ],
    "iteration_recommendation": "Review after 6-month cycle"
  },

  "configuration_used": {
    "aggregation_method": "median",
    "minimum_completion_rate": 0.7,
    "decision_thresholds": {
      "majority": 60,
      "significant_minority_min": 20,
      "significant_minority_max": 60
    },
    "strategy_priorities_considered": false,
    "simplified_mode": false
  }
}
```

---

## Part 3: Critical Implementation Notes

### Important Clarifications

1. **We DON'T average role requirements**
   - Each role maintains its specific requirements
   - We count USER distribution across scenarios
   - Decisions based on percentage of USERS affected

2. **Task-based pathway does NOT use 75th percentile**
   - Only 2-way comparison (Current vs Archetype)
   - The `unknown_role_competency_matrix` is for reference only
   - No role targets exist in low maturity organizations

3. **Only LATEST assessment counts**
   - Ignore retakes and test data
   - One assessment per user for calculation
   - Query must use DISTINCT ON (user_id) ORDER BY completed_at DESC

4. **Strategy priorities are OPTIONAL**
   - Can generate full objectives for all strategies equally
   - Or handle PRIMARY/SUPPLEMENTARY/SECONDARY differently
   - Simpler to ignore priorities initially

5. **Core competencies (IDs: 1, 4, 5, 6) cannot be directly trained**
   - Systems Thinking, Lifecycle Consideration, Customer Orientation, Systems Modeling
   - Generate notes only, not training objectives
   - They develop indirectly through other competencies

6. **Model switching is safe**
   - This document is comprehensive enough for any model
   - Start session with: "Read LEARNING_OBJECTIVES_FINAL_DESIGN_2025_11_03_v2.md"
   - Document serves as complete implementation guide

### Pre-Implementation Checklist

- [x] Phase 1 completed (maturity score, strategies selected)
- [x] Phase 2 assessments completed (minimum 70% of users)
- [x] Database tables exist and populated
- [x] Learning objective templates available
- [ ] PMT context input mechanism (optional for customization)
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

    # Generate objectives
    result = generate_learning_objectives(org_id)

    # Store in database
    save_learning_objectives(result)

    return jsonify(result), 200

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

1. **Organization 28** (task-based, 0 roles, low maturity)
2. **Mock organization** with 5 roles, 50 users, varied scores
3. **Edge cases**:
   - All users at same level
   - No gaps (all targets met)
   - All gaps too large
   - Multi-role users
   - <70% completion rate

### Configuration Options

```python
CONFIG = {
    # Aggregation methods
    'current_level_method': 'median',  # Don't change
    'role_requirement_method': 'maximum',  # Or 'distribution'

    # Thresholds
    'minimum_completion_rate': 0.7,
    'majority_threshold': 60,
    'significant_minority_min': 20,

    # Features
    'use_strategy_priorities': False,  # Simpler without
    'use_simplified_algorithm': False,  # Use distribution-based
    'include_soft_targets': False,  # Future enhancement

    # Competencies
    'core_competency_ids': [1, 4, 5, 6],
    'valid_levels': [0, 1, 2, 4, 6],

    # External training
    'level_6_flag': 'external_training_required'
}
```

---

## Summary: Key Points for Implementation

1. **Start Simple**: Implement task-based pathway first (2-way comparison only)
2. **Use Median**: For all current level aggregations
3. **Latest Only**: Only use most recent assessment per user
4. **One Output**: Generate unified objectives for organization, not per role
5. **Test with Org 28**: Has task-based data ready
6. **Ignore Priorities Initially**: Treat all strategies equally at first
7. **Check Completion**: Require 70% assessments complete
8. **Document Everything**: This design is your implementation bible

---

*This document contains ALL details from our discussion. Version 2 includes all clarifications, missing steps, and corrections.*