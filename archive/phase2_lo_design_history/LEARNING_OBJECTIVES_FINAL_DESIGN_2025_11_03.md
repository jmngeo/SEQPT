# Learning Objectives Generation - Final Design Document
**Date**: November 3, 2025
**Status**: FINALIZED - Ready for Implementation
**Purpose**: Reference document for Phase 2 Task 3 implementation

---

## Executive Summary

The Learning Objectives Generation system creates customized training objectives for organizations based on their competency assessment results. The system handles two distinct pathways depending on organizational maturity:

1. **Low Maturity Organizations** (no defined SE roles) → Task-based pathway with 2-way comparison
2. **High Maturity Organizations** (defined SE roles) → Role-based pathway with 3-way comparison

---

## Part 1: Non-Technical Explanation for Thesis Advisor

### What This System Does

Think of this system as an intelligent training planner that:
1. Looks at what skills employees currently have
2. Compares this to what they need for their jobs
3. Checks what the selected training strategies can provide
4. Generates specific learning objectives to close the gaps

### The Two Organizational Types

**Type A: Low Maturity Organizations**
- These companies are just starting with Systems Engineering
- They don't have formal SE roles defined yet (no "Systems Architect" or "Requirements Engineer" positions)
- Employees describe their daily tasks instead
- The system figures out what competencies they need based on these tasks

**Type B: High Maturity Organizations**
- These companies have established SE processes
- They have defined SE roles with clear responsibilities
- Employees select their roles from a list
- The system knows exactly what each role requires

### The Comparison Logic

**For Low Maturity (Task-based):**
- **2-Way Comparison**: Current Skills vs. Training Strategy Target
- Example: "Employee has level 2 in Decision Making, training strategy provides level 4"
- Result: "Generate objective to move from level 2 to level 4"

**For High Maturity (Role-based):**
- **3-Way Comparison**: Current Skills vs. Training Strategy Target vs. Role Requirements
- Example: "Employee has level 2, training provides level 4, but role needs level 6"
- Result: "Generate objective for level 4 now, note that additional training needed later"

### How We Aggregate Data

When an organization has multiple employees:
- We use the **median** (middle value) to represent typical employee competency
- Why median? It's not affected by one expert or one beginner
- Example: If 5 developers have skills [1,2,2,4,6], the median is 2 (typical developer)

### Decision Making Based on Patterns

The system looks at patterns across all employees:
- If >60% need higher training → Recommend adding advanced strategy
- If 20-60% need more → Suggest supplementary modules
- If <20% need more → Note for future training cycles

### Strategy Priorities

Organizations select 1-3 training strategies with priorities:
- **PRIMARY**: Main focus, full objectives generated
- **SUPPLEMENTARY**: Fills specific gaps
- **SECONDARY**: Optional enhancements

---

## Part 2: Technical Algorithm Design

### Core Algorithm Structure

```python
def generate_learning_objectives(org_id):
    """
    Main entry point for learning objectives generation
    """
    # Determine pathway based on organization configuration
    pathway = determine_pathway(org_id)

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
    Compares: Current Level vs Archetype Target
    """
    # Step 1: Get latest assessment per user
    user_assessments = get_latest_assessments(org_id, survey_type='unknown_roles')

    # Step 2: Get selected training strategies
    selected_strategies = get_organization_strategies(org_id)

    objectives = {}

    for strategy in selected_strategies:
        strategy_objectives = []

        for competency in all_16_competencies:
            # Step 3: Calculate current level (median of all users)
            current_scores = [
                get_user_score(user.id, competency.id)
                for user in user_assessments
            ]
            current_level = median(current_scores) if current_scores else 0

            # Step 4: Get strategy target
            archetype_target = get_archetype_target(strategy, competency)

            # Step 5: 2-way comparison
            if current_level < archetype_target:
                # Training needed
                objective = create_learning_objective(
                    competency=competency,
                    from_level=current_level,
                    to_level=archetype_target,
                    strategy=strategy
                )
                strategy_objectives.append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'current_level': current_level,
                    'target_level': archetype_target,
                    'gap': archetype_target - current_level,
                    'learning_objective': objective,
                    'status': 'training_required'
                })
            else:
                # Target already met
                strategy_objectives.append({
                    'competency_id': competency.id,
                    'status': 'target_achieved'
                })

        objectives[strategy] = strategy_objectives

    return objectives
```

### Algorithm 2: Role-Based Organizations (High Maturity)

```python
def generate_role_based_objectives(org_id):
    """
    3-WAY COMPARISON for organizations with defined roles
    Compares: Current Level vs Archetype Target vs Role Requirement
    """
    # Step 1: Get user-role selections
    user_role_data = get_user_role_selections(org_id)

    # Step 2: Analyze per role
    role_analyses = {}

    for role in get_organization_roles(org_id):
        users_in_role = get_users_who_selected_role(role.id)

        if not users_in_role:
            continue

        role_analyses[role.id] = analyze_role_competencies(
            role_id=role.id,
            users=users_in_role,
            strategies=selected_strategies
        )

    # Step 3: Aggregate across organization
    aggregated = aggregate_by_user_distribution(role_analyses)

    # Step 4: Make strategic decisions
    decisions = make_distribution_based_decisions(aggregated)

    # Step 5: Generate unified objectives
    return generate_unified_objectives(decisions)
```

### 3-Way Comparison Scenarios

```python
def classify_gap_scenario(current, archetype_target, role_target):
    """
    Classify the gap into one of four scenarios
    """
    if current < archetype_target <= role_target:
        return 'A'  # Normal training path

    elif archetype_target <= current < role_target:
        return 'B'  # Need higher strategy

    elif archetype_target > role_target:
        return 'C'  # Over-training warning

    else:  # current >= both targets
        return 'D'  # No training needed
```

### Aggregation Methods

```python
# Method 1: For Current Competency Levels
def aggregate_current_levels(scores):
    """Use MEDIAN - robust to outliers, returns valid level"""
    return median(scores)

# Method 2: For Role Requirements (Role-based)
def aggregate_role_requirements(role_targets, user_counts):
    """Use WEIGHTED AVERAGE by number of users in each role"""
    weighted_sum = sum(target * count for target, count in zip(role_targets, user_counts))
    total_users = sum(user_counts)
    return round_to_nearest_level(weighted_sum / total_users)

# Method 3: For Task Requirements (Task-based)
def aggregate_task_requirements(task_values):
    """Use 75th PERCENTILE - handles AI interpretation variability"""
    return percentile(task_values, 75)

# Method 4: For Multiple Strategies
def aggregate_across_strategies(strategies):
    """Use MAXIMUM - find highest coverage available"""
    return max(get_archetype_target(s, competency) for s in strategies)
```

### Decision Rules Based on Distribution

```python
def make_strategic_decisions(distribution):
    """
    Make recommendations based on user distribution patterns
    """
    decisions = []

    for competency in distribution:
        scenario_B_percentage = distribution[competency]['need_higher_strategy']

        if scenario_B_percentage > 60:
            decisions.append({
                'action': 'recommend_additional_strategy',
                'reason': f'{scenario_B_percentage}% of users need higher levels',
                'suggested_strategy': find_appropriate_strategy(competency)
            })

        elif 20 <= scenario_B_percentage <= 60:
            decisions.append({
                'action': 'add_supplementary_modules',
                'reason': f'Significant minority ({scenario_B_percentage}%) need enhancement',
                'phase_3_guidance': 'Select advanced modules for this group'
            })

        elif scenario_B_percentage < 20:
            decisions.append({
                'action': 'note_for_future',
                'reason': f'Small group ({scenario_B_percentage}%) for next iteration'
            })

    return decisions
```

### Strategy Selection Hierarchy

Based on Phase 1 maturity assessment:

```python
def get_strategy_hierarchy(maturity_level, rollout_scope, target_size):
    """
    Determine appropriate strategies based on organizational context
    """
    if target_size > 100:
        # Large organizations need multiplier approach
        return ['train_the_trainer'] + other_strategies

    if maturity_level < 3:  # Low maturity
        primary = 'se_for_managers'  # Management buy-in first
        secondary_options = [
            'common_understanding',  # Basic awareness
            'orientation_pilot',     # Pilot project
            'certification'          # Formal training
        ]
        return [primary] + user_selected_from(secondary_options)

    else:  # High maturity (>= 3)
        if rollout_scope > 3:
            return ['continuous_support']  # Ongoing development
        else:
            return ['needs_based_project']  # Targeted training
```

### Handling Edge Cases

```python
def handle_multi_role_users(user_id):
    """
    When a user has multiple roles, use highest requirement
    """
    user_roles = get_user_selected_roles(user_id)
    max_requirements = {}

    for competency in all_competencies:
        requirements = [
            get_role_requirement(role.id, competency.id)
            for role in user_roles
        ]
        max_requirements[competency.id] = max(requirements)

    return max_requirements

def handle_zero_assessments():
    """
    Prevent generation if assessments incomplete
    """
    completion_rate = get_assessment_completion_rate(org_id)

    if completion_rate < 0.7:  # Less than 70% completed
        return {
            'error': 'Insufficient assessment data',
            'message': f'Only {completion_rate*100}% of users have completed assessment',
            'action': 'Please ensure more users complete assessment before generating objectives'
        }
```

### Data Structures

#### Input Data Sources

1. **Phase 1 Data**
   - Organization maturity score
   - Selected training strategies (1-3 with priorities)
   - Target group size

2. **Phase 2 Assessment Data**
   - User competency scores (0, 1, 2, 4, 6)
   - Role selections (for role-based)
   - Task descriptions (for task-based)

3. **Matrix Data**
   - `role_competency_matrix`: Role requirements
   - `unknown_role_competency_matrix`: Task-derived requirements
   - `archetype_competency_targets`: Strategy target levels

4. **Learning Templates**
   - Objective templates per competency level
   - SMART criteria formatting

#### Output Structure

```json
{
  "organization_id": 28,
  "pathway": "TASK_BASED",
  "generation_timestamp": "2025-11-03T10:00:00Z",

  "assessment_summary": {
    "total_users": 45,
    "assessments_completed": 40,
    "completion_rate": 88.9,
    "data_quality": "sufficient"
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
          "gap": 2,
          "learning_objective": "By the end of this training, participants will be able to prepare complex decisions using company-specific decision matrices and tools, evaluate alternatives systematically, and communicate decisions effectively to stakeholders.",
          "bloom_taxonomy_level": "Apply",
          "estimated_hours": 16,
          "users_requiring": 35,
          "impact_percentage": 87.5
        }
      ],
      "summary": {
        "total_objectives": 12,
        "total_training_hours": 180,
        "competencies_covered": 12,
        "competencies_already_met": 4
      }
    },

    "se_for_managers": {
      "priority": "SUPPLEMENTARY",
      "objectives": [...],
      "rationale": "Selected to ensure management buy-in and support"
    }
  },

  "strategic_recommendations": [
    {
      "type": "strategy_addition",
      "recommendation": "Consider adding 'certification' strategy",
      "rationale": "25% of users in technical roles need level 6 competencies",
      "competencies_affected": [14, 15, 16],
      "priority": "medium",
      "timing": "next_iteration"
    }
  ],

  "module_planning_guidance": {
    "needs_based_project": {
      "core_modules_required": 8,
      "supplementary_modules_suggested": 3,
      "existing_training_reusable": ["project_management_basics"],
      "new_training_needed": ["systems_thinking_workshop"]
    }
  },

  "future_training_pipeline": {
    "gaps_remaining": [
      {
        "competency": "Systems Architecture",
        "current": 4,
        "ultimate_need": 6,
        "affected_roles": ["System Architect"],
        "suggested_approach": "external_certification"
      }
    ],
    "recommended_timeline": "Review after 6-month training cycle"
  }
}
```

---

## Part 3: Implementation Checklist

### Pre-Implementation Requirements
- [x] Phase 1 completion (maturity, strategies selected)
- [x] Phase 2 assessments completed (>70% users)
- [x] Database tables exist (role_competency_matrix, unknown_role_competency_matrix)
- [x] Learning objective templates loaded
- [ ] PMT context input mechanism (optional but recommended)

### Implementation Steps

1. **Backend API Endpoints**
   ```
   POST /api/learning-objectives/generate
   GET /api/learning-objectives/{org_id}/latest
   POST /api/learning-objectives/approve
   ```

2. **Core Functions to Implement**
   - `determine_pathway(org_id)`
   - `get_latest_assessments_per_user(org_id)`
   - `calculate_median(scores)`
   - `generate_task_based_objectives(org_id)`
   - `generate_role_based_objectives(org_id)`
   - `classify_gap_scenario(current, archetype, role)`
   - `make_distribution_based_decisions(data)`

3. **Database Queries Needed**
   - Latest assessment per user
   - Role selections per user
   - Competency scores per user
   - Strategy selections for organization
   - Role/task requirements

4. **UI Components**
   - Generation trigger button (admin only)
   - Progress indicator
   - Results display with tabs per strategy
   - Recommendations panel
   - Export functionality

### Configuration Parameters

```python
CONFIGURATION = {
    'aggregation': {
        'current_level_method': 'median',
        'role_requirement_method': 'weighted_average',
        'task_requirement_method': 'percentile_75',
        'minimum_completion_rate': 0.7
    },
    'thresholds': {
        'majority_percentage': 60,
        'significant_minority_min': 20,
        'significant_minority_max': 60
    },
    'competency_levels': [0, 1, 2, 4, 6],
    'exclude_core_competencies_direct_training': [1, 4, 5, 6],  # Systems Thinking, etc.
    'level_6_external_training_flag': True
}
```

### Testing Scenarios

1. **Task-based organization** with varied assessment scores
2. **Role-based organization** with multiple roles
3. **Multi-role users** (one user, multiple roles)
4. **Edge cases**:
   - All users at same level
   - Missing assessments
   - No gaps (all targets met)
   - All gaps too large

### Success Metrics

- Generates objectives for all selected strategies
- Correctly identifies gaps using appropriate comparison (2-way vs 3-way)
- Aggregation produces valid competency levels
- Recommendations align with distribution patterns
- Output is actionable for Phase 3 module planning

---

## Notes for Next Session

1. **Start with**: Backend API endpoint structure
2. **Priority**: Task-based pathway first (simpler, no roles)
3. **Test with**: Organization 28 data (task-based, low maturity)
4. **Remember**: Only use latest assessment per user
5. **Key distinction**: Task-based = 2-way comparison, Role-based = 3-way comparison
6. **Aggregation**: Median for current levels, 75th percentile for task requirements
7. **Output**: One unified set of objectives per strategy

---

## Appendix: Key Design Decisions

1. **Why separate pathways?** Low maturity orgs don't have roles defined
2. **Why median aggregation?** Robust to outliers, returns valid levels
3. **Why 2-way for task-based?** No role targets exist yet
4. **Why check completion rate?** Need sufficient data for meaningful objectives
5. **Why strategy priorities?** Organizations have primary focus vs. supplementary needs
6. **Why distribution-based decisions?** Percentage of users affected determines action
7. **Why unified output?** Organization needs one training plan, not per-role plans

---

*This document represents the complete, finalized design for Learning Objectives Generation in SE-QPT Phase 2 Task 3.*