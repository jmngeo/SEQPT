# Learning Objectives Generation - Design v5 COMPREHENSIVE & FINAL

**Date:** 2025-11-24
**Status:** Implementation-Ready Final Design
**Version:** 5.0 (Comprehensive)
**Incorporates:** All clarifications and corrections from session

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Design Principles](#critical-design-principles)
3. [System Architecture](#system-architecture)
4. [Core Algorithms - Complete Specification](#core-algorithms)
5. [Data Structures - Complete Schemas](#data-structures)
6. [Edge Cases & Error Handling](#edge-cases--error-handling)
7. [UI Components - Complete Specification](#ui-components)
8. [API Endpoints - Complete Specification](#api-endpoints)
9. [Implementation Plan - Phased Approach](#implementation-plan)
10. [Testing Strategy - Comprehensive](#testing-strategy)
11. [Critical Analysis & Risk Assessment](#critical-analysis--risk-assessment)
12. [Performance Considerations](#performance-considerations)
13. [Migration from v4](#migration-from-v4)

---

## Executive Summary

### Purpose
Generate learning objectives for SE competency training based on:
- Organizational competency assessment results
- Selected training strategies
- Role-competency requirements (if defined)
- PMT context (if applicable)

### Key Outcomes
1. Pyramid structure showing progressive learning levels (1, 2, 4, 6)
2. Learning objectives for each competency at each needed level
3. Two views: Organizational (all roles) and Role-based (single role drill-down)
4. Distribution statistics and training method recommendations
5. Mastery requirements validation
6. Separate "Train the Trainer" section

### Design Principles (NON-NEGOTIABLE)

**1. ANY GAP TRIGGERS GENERATION**
```python
# If even 1 user out of 20 has gap → Generate LO
if any(user_score < target_level):
    generate_learning_objective()
```

**2. BOTH PATHWAYS USE PYRAMID**
- High maturity: Pyramid with role data
- Low maturity: Pyramid without role data
- NO strategy-based organization for low maturity

**3. PROGRESSIVE LEVELS**
```python
# Current=0, Target=4 → Generate levels 1, 2, AND 4
# Not just final target
```

**4. EXCLUDE TTT FROM MAIN TARGETS**
```python
# "Train the Trainer" processed separately
# Main pyramid uses other strategies only
# TTT section shows Level 6 objectives separately
```

**5. THREE-WAY VALIDATION**
```python
# Check: Role requirement vs Strategy target vs Current level
# Flag if: role_requirement > strategy_target
```

---

## Critical Design Principles

### Principle 1: Gap Detection is User-Based, Not Median-Based

**WRONG Approach (v4):**
```python
median = calculate_median(user_scores)
if median < target:
    generate_LO()  # Only if median shows gap
```

**CORRECT Approach (v5):**
```python
users_with_gap = [score for score in user_scores if score < target]
if len(users_with_gap) > 0:
    generate_LO()  # If ANY user has gap
```

**Rationale:**
- Training is GROUP-BASED but INCLUSIVE
- If even 1 person needs training, LO must be available
- Median is used for CONTEXT (training method recommendation), not DECISION

**Critical Analysis:**
- ✅ Ensures no one is left behind
- ✅ Aligns with "any gap" requirement
- ⚠️ May generate LOs when median suggests not needed
- ✅ Distribution statistics provide context for admin decision-making

---

### Principle 2: Unified Pyramid Structure

**WRONG Approach:**
```
High Maturity → Pyramid structure (levels 1,2,4,6)
Low Maturity → Strategy-based structure (strategy tabs)
```

**CORRECT Approach:**
```
BOTH Pathways → Pyramid structure (levels 1,2,4,6)
Difference: High maturity shows role data, low maturity shows org stats
```

**Rationale:**
- User shouldn't see multiple LOs for same competency across strategies
- Pyramid represents progressive learning naturally
- Strategy is used for TARGET determination, not ORGANIZATION

**Critical Analysis:**
- ✅ Consistent UX across maturity levels
- ✅ Simpler mental model for users
- ✅ Aligns with pedagogical progression (Bloom's Taxonomy)
- ✅ Avoids duplicate LOs when multiple strategies selected

---

### Principle 3: Progressive Learning Objectives

**Generation Logic:**
```python
current_level = 0
target_level = 4

# Generate for ALL intermediate levels
levels_to_generate = [1, 2, 4]  # Not just 4

for level in levels_to_generate:
    if level in [1, 2, 4, 6]:  # Valid levels only
        generate_objective(competency, level)
```

**Pedagogical Basis:**
- Can't skip foundational levels (Bloom's Taxonomy)
- Must understand before applying
- Sequential competency development

**Critical Analysis:**
- ✅ Pedagogically sound
- ✅ Provides complete learning path
- ⚠️ Generates more LOs (but necessary)
- ✅ Enables proper training module sequencing

---

### Principle 4: Train the Trainer Separation

**Architecture:**
```
Main Pyramid:
  - Uses strategies: Continuous Support, Needs-based, SE for Managers, etc.
  - Targets: Levels 1-4 typically
  - Excludes: Train the Trainer

Separate TTT Section:
  - Uses strategy: Train the Trainer only
  - Targets: Level 6 (mastery)
  - Simple display: Just competencies and Level 6 LOs
```

**Target Calculation:**
```python
def calculate_combined_targets(selected_strategies):
    # Separate TTT from others
    ttt_strategy = None
    other_strategies = []

    for strategy in selected_strategies:
        if strategy.name == 'Train the Trainer':
            ttt_strategy = strategy
        else:
            other_strategies.append(strategy)

    # Main targets (take HIGHER among non-TTT strategies)
    main_targets = {}
    for strategy in other_strategies:
        for comp in ALL_16_COMPETENCIES:
            target = get_strategy_target(strategy, comp)
            if comp.id not in main_targets:
                main_targets[comp.id] = target
            else:
                main_targets[comp.id] = max(main_targets[comp.id], target)

    # TTT targets (all level 6)
    ttt_targets = None
    if ttt_strategy:
        ttt_targets = {comp.id: 6 for comp in ALL_16_COMPETENCIES}

    return {
        'main_targets': main_targets,
        'ttt_targets': ttt_targets,
        'ttt_selected': ttt_strategy is not None
    }
```

**Critical Analysis:**
- ✅ Prevents TTT from dominating main pyramid (all targets → 6)
- ✅ Maintains dual-track approach from v4
- ✅ Clear separation of concerns (regular training vs trainer development)
- ✅ Aligns with different purposes (train employees vs develop trainers)

---

### Principle 5: Mastery Requirements Validation

**Three-Way Check:**
```python
role_requirement = 6    # From role-competency matrix
strategy_target = 4     # From selected strategies (excluding TTT)
current_level = 2       # From user assessments (median)

# Check 1: Strategy provides what role requires?
if role_requirement > strategy_target:
    flag = "STRATEGY_INADEQUATE"
    message = "Role requires Level 6, but strategy only provides Level 4"
    recommend = "Add 'Train the Trainer' strategy"

# Check 2: Current exceeds strategy target? (over-training)
if current_level > strategy_target:
    flag = "OVER_TRAINING"
    message = "Current levels exceed strategy targets"
    recommend = "Re-evaluate maturity assessment"

# Check 3: Normal gap
if current_level < strategy_target:
    flag = None
    generate_LOs()
```

**Critical Analysis:**
- ✅ Catches mismatch between role requirements and strategy selection
- ✅ Prevents situation where roles can't achieve required competency
- ✅ Provides actionable recommendations
- ⚠️ Requires role-competency matrix to be accurate
- ✅ Only applies to high maturity (roles defined)

---

## System Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      USER INPUT                              │
│  - Organization ID                                           │
│  - Selected Strategies (from Phase 1)                        │
│  - PMT Context (optional)                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                  BACKEND PROCESSING                          │
│                                                              │
│  Step 1: Load Data                                          │
│    - Get organization info (has_roles?)                     │
│    - Get all user assessment scores                         │
│    - Get role-competency matrix (if high maturity)          │
│    - Get strategy archetype targets                         │
│                                                              │
│  Step 2: Separate TTT from Other Strategies                 │
│    - Calculate main_targets (excluding TTT)                 │
│    - Calculate ttt_targets (if TTT selected)                │
│                                                              │
│  Step 3: Validate Mastery Requirements                      │
│    - Check role_requirement vs strategy_target              │
│    - Flag inadequacy if role requires > strategy provides   │
│                                                              │
│  Step 4: Detect Gaps (Main Pyramid)                         │
│    FOR each competency:                                      │
│      IF has_roles:                                           │
│        Process by role (calculate per-role gaps)            │
│      ELSE:                                                   │
│        Process organizationally (all users together)        │
│                                                              │
│      IF any(user_score < target):                           │
│        Determine levels needed (progressive)                │
│        Calculate distribution statistics                    │
│        Determine training method recommendation             │
│                                                              │
│  Step 5: Detect TTT Gaps (if TTT selected)                  │
│    FOR each competency:                                      │
│      IF any(user_score < 6):                                │
│        Mark for Level 6 generation                          │
│                                                              │
│  Step 6: Generate Learning Objectives                       │
│    Main Pyramid:                                             │
│      FOR each competency with gap:                           │
│        FOR each level needed:                                │
│          Get template objective                              │
│          Customize with PMT (if applicable)                  │
│                                                              │
│    TTT Section:                                              │
│      FOR each competency needing Level 6:                    │
│        Get template objective (Level 6)                      │
│        Customize with PMT (if applicable)                    │
│                                                              │
│  Step 7: Structure Output                                   │
│    Organize by pyramid level (1, 2, 4, 6)                   │
│    Include all 16 competencies per level (active/grayed)    │
│    Attach role data (if high maturity)                      │
│    Attach distribution stats                                 │
│    Attach training recommendations                           │
│    Add TTT section (if applicable)                          │
│    Add mastery validation results                           │
│                                                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   FRONTEND DISPLAY                           │
│                                                              │
│  Component 1: Mastery Requirements Warning (if inadequate)  │
│  Component 2: Strategy Validation Summary (informational)   │
│  Component 3: View Selector (Organizational vs Role-Based)  │
│                                                              │
│  Main View (Organizational or Role-Based):                  │
│    - Pyramid Level Tabs (1, 2, 4, 6)                        │
│    - Competency Cards (all 16 per level)                    │
│      - Active: Show LO, role data, training rec             │
│      - Grayed: Show "achieved" message                      │
│                                                              │
│  TTT Section (if applicable):                                │
│    - Separate section below main pyramid                     │
│    - Competency cards with Level 6 LOs                      │
│    - Simple display (no internal/external selection)        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Data Dependencies

```
Input Dependencies:
  ├─ organizations (org_id, maturity_level, has_roles)
  ├─ selected_strategies (from Phase 1 Task 3)
  ├─ pmt_context (optional, from Phase 2 Task 3 PMT collection)
  ├─ user_se_competency_survey_results (from Phase 2 Task 1)
  ├─ role_competency_matrix (if high maturity, from Phase 1 Task 2)
  ├─ user_role_assignments (if high maturity, from Phase 2 Task 1)
  └─ learning_objectives_templates (JSON file)

Processing Dependencies:
  ├─ Strategy archetype templates (target levels per competency)
  ├─ Competency definitions (16 competencies)
  └─ Level definitions (1, 2, 4, 6)

Output Dependencies:
  └─ Consumed by: Phase 3 (training planning)
```

### Critical Path Analysis

**Must Complete Before Generation:**
1. ✅ Phase 1 Task 3: Strategy selection
2. ✅ Phase 2 Task 1: User competency assessments
3. ✅ Phase 2 Task 2: Role definitions (if high maturity)
4. ⚠️ Phase 2 Task 3 PMT: PMT collection (optional, only if strategy requires)

**Blocking Issues:**
- If no assessment data → Cannot calculate gaps → ERROR
- If high maturity but no roles defined → Inconsistency → ERROR
- If PMT-requiring strategy but no PMT provided → Use standard templates (WARNING)

---

## Core Algorithms - Complete Specification

### Algorithm 1: Calculate Combined Targets

**Purpose:** Determine target levels for each competency, separating TTT from other strategies

**Input:**
- `selected_strategies`: Array of strategy objects

**Output:**
- Dictionary with `main_targets`, `ttt_targets`, `ttt_selected`

**Algorithm:**
```python
def calculate_combined_targets(selected_strategies):
    """
    Calculate combined strategy targets.

    CRITICAL: Separate "Train the Trainer" from other strategies.
    Main targets: Take HIGHER among non-TTT strategies.
    TTT targets: All level 6 (processed separately).

    Args:
        selected_strategies: List of strategy objects

    Returns:
        {
            'main_targets': {competency_id: target_level},
            'ttt_targets': {competency_id: 6} or None,
            'ttt_selected': bool
        }
    """

    # Separate TTT from other strategies
    ttt_strategy = None
    other_strategies = []

    for strategy in selected_strategies:
        if strategy['strategy_name'] == 'Train the Trainer':
            ttt_strategy = strategy
        else:
            other_strategies.append(strategy)

    # Validate: Must have at least one non-TTT strategy OR TTT
    if len(other_strategies) == 0 and ttt_strategy is None:
        raise ValueError("No strategies selected")

    # Calculate main targets (from non-TTT strategies)
    main_targets = {}

    if len(other_strategies) > 0:
        for strategy in other_strategies:
            # Get strategy archetype targets
            archetype = get_strategy_archetype(strategy['strategy_id'])

            for competency in ALL_16_COMPETENCIES:
                target = archetype['targets'][competency.id]

                if competency.id not in main_targets:
                    main_targets[competency.id] = target
                else:
                    # Take HIGHER target if multiple strategies
                    main_targets[competency.id] = max(
                        main_targets[competency.id],
                        target
                    )
    else:
        # Only TTT selected (edge case)
        # Set main_targets to 0 for all (no regular training)
        main_targets = {comp.id: 0 for comp in ALL_16_COMPETENCIES}

    # Calculate TTT targets (all level 6)
    ttt_targets = None
    if ttt_strategy is not None:
        ttt_targets = {comp.id: 6 for comp in ALL_16_COMPETENCIES}

    return {
        'main_targets': main_targets,
        'ttt_targets': ttt_targets,
        'ttt_selected': ttt_strategy is not None
    }
```

**Edge Cases:**
1. ✅ Only TTT selected: `main_targets` all 0, only TTT section shown
2. ✅ No TTT selected: `ttt_targets` is None, no TTT section
3. ✅ Multiple non-TTT strategies: Take HIGHER target per competency
4. ✅ No strategies selected: Raise error (validation in Phase 1 should prevent)

**Critical Analysis:**
- ✅ Prevents TTT from affecting main pyramid targets
- ✅ Handles edge case of only TTT selected
- ✅ Takes HIGHER when multiple strategies (user confirmed)
- ⚠️ Assumes strategy archetype data is valid and complete

---

### Algorithm 2: Validate Mastery Requirements

**Purpose:** Check if selected strategies can meet role requirements, especially for Level 6

**Input:**
- `org_id`: Organization ID
- `selected_strategies`: Array of strategies
- `main_targets`: Target levels from non-TTT strategies

**Output:**
- Validation result with status, affected roles, recommendations

**Algorithm:**
```python
def validate_mastery_requirements(org_id, selected_strategies, main_targets):
    """
    Validate that selected strategies can meet role requirements.

    Critical Check: If any role requires Level 6, but TTT not selected
    and main strategies don't provide Level 6.

    Args:
        org_id: Organization ID
        selected_strategies: List of selected strategies
        main_targets: Target levels from non-TTT strategies

    Returns:
        {
            'status': 'OK' | 'INADEQUATE',
            'severity': 'NONE' | 'MEDIUM' | 'HIGH',
            'message': str,
            'affected': [...],
            'recommendations': [...]
        }
    """

    # Check if organization has roles defined
    has_roles = check_if_org_has_roles(org_id)

    if not has_roles:
        # Low maturity - no role requirements to validate
        return {
            'status': 'OK',
            'severity': 'NONE',
            'message': 'No role requirements defined (low maturity)'
        }

    # Check if TTT is selected
    ttt_selected = any(
        s['strategy_name'] == 'Train the Trainer'
        for s in selected_strategies
    )

    # Get all roles and their requirements
    roles = get_organization_roles(org_id)
    affected_combinations = []

    for role in roles:
        for competency in ALL_16_COMPETENCIES:
            # Get role requirement level
            role_requirement = get_role_competency_requirement(
                role.id,
                competency.id
            )

            # Get strategy target for this competency
            strategy_target = main_targets.get(competency.id, 0)

            # Check if requirement exceeds what strategy provides
            if role_requirement > strategy_target:
                # INADEQUACY DETECTED
                affected_combinations.append({
                    'role_id': role.id,
                    'role_name': role.name,
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'required_level': role_requirement,
                    'strategy_provides': strategy_target,
                    'gap': role_requirement - strategy_target
                })

    # Analyze results
    if len(affected_combinations) == 0:
        # All role requirements can be met by selected strategies
        return {
            'status': 'OK',
            'severity': 'NONE',
            'message': 'All role requirements can be met by selected strategies'
        }

    # Count how many require Level 6 specifically
    level_6_requirements = [
        a for a in affected_combinations
        if a['required_level'] == 6
    ]

    # Determine severity
    if len(level_6_requirements) > 0 and not ttt_selected:
        severity = 'HIGH'
        message = (
            f"{len(level_6_requirements)} role-competency combination(s) "
            f"require Mastery (Level 6), but 'Train the Trainer' strategy "
            f"is not selected. Selected strategies only provide up to "
            f"Level {max(main_targets.values())}."
        )
    else:
        severity = 'MEDIUM'
        message = (
            f"{len(affected_combinations)} role-competency combination(s) "
            f"have requirements exceeding selected strategy targets."
        )

    # Generate recommendations
    recommendations = []

    if len(level_6_requirements) > 0 and not ttt_selected:
        recommendations.append({
            'action': 'add_ttt_strategy',
            'label': 'Add "Train the Trainer" Strategy',
            'description': (
                'Select the "Train the Trainer" strategy to develop '
                'internal trainers to mastery level (Level 6).'
            ),
            'priority': 'HIGH'
        })

    recommendations.append({
        'action': 'accept_risk',
        'label': 'Accept Limited Training',
        'description': (
            'Proceed with current strategies. Affected roles will not '
            'achieve full required competency levels (risk accepted).'
        ),
        'priority': 'MEDIUM'
    })

    recommendations.append({
        'action': 'hire_external',
        'label': 'Plan for External Trainers',
        'description': (
            'Engage external experts for mastery-level training '
            'where needed.'
        ),
        'priority': 'MEDIUM'
    })

    recommendations.append({
        'action': 'revise_requirements',
        'label': 'Revise Role Requirements',
        'description': (
            'Review role-competency matrix and adjust requirements '
            'to align with available strategies.'
        ),
        'priority': 'LOW'
    })

    return {
        'status': 'INADEQUATE',
        'severity': severity,
        'message': message,
        'affected': affected_combinations,
        'recommendations': recommendations
    }
```

**Edge Cases:**
1. ✅ Low maturity (no roles): Return OK
2. ✅ All requirements met: Return OK
3. ✅ Level 6 required, TTT selected: OK (TTT provides Level 6)
4. ✅ Level 6 required, TTT not selected: INADEQUATE HIGH severity
5. ✅ Level 4 required, strategy provides 2: INADEQUATE MEDIUM severity

**Critical Analysis:**
- ✅ Catches critical mismatch early (before LO generation)
- ✅ Provides actionable recommendations
- ✅ Differentiates severity (Level 6 vs lower levels)
- ⚠️ Assumes role-competency matrix is accurate
- ⚠️ Admin might ignore warning (that's acceptable - their decision)

---

### Algorithm 3: Detect Gaps with Role Processing

**Purpose:** Identify which competencies need training and at which levels, processing by role if applicable

**Input:**
- `org_id`: Organization ID
- `main_targets`: Target levels per competency
- `ttt_targets`: TTT target levels (or None)

**Output:**
- Gap data structure organized by competency and level

**Algorithm:**
```python
def detect_gaps(org_id, main_targets, ttt_targets=None):
    """
    Detect training gaps for all competencies.

    CRITICAL: Generate LO if ANY user has gap (not median-based).
    Process by role if high maturity, organizationally if low maturity.

    Args:
        org_id: Organization ID
        main_targets: Target levels per competency (excluding TTT)
        ttt_targets: TTT targets (if selected)

    Returns:
        {
            'by_competency': {comp_id: gap_data},
            'by_level': {level: [competencies]},
            'metadata': {...}
        }
    """

    # Check if organization has roles
    has_roles = check_if_org_has_roles(org_id)

    # Initialize structure
    gaps = {
        'by_competency': {},
        'by_level': {1: [], 2: [], 4: [], 6: []},
        'metadata': {
            'organization_id': org_id,
            'has_roles': has_roles,
            'generation_timestamp': datetime.now()
        }
    }

    # Process each competency
    for competency in ALL_16_COMPETENCIES:
        target_level = main_targets[competency.id]

        if has_roles:
            # HIGH MATURITY: Process by role
            competency_gaps = process_competency_with_roles(
                org_id,
                competency,
                target_level
            )
        else:
            # LOW MATURITY: Process organizationally
            competency_gaps = process_competency_organizational(
                org_id,
                competency,
                target_level
            )

        gaps['by_competency'][competency.id] = competency_gaps

        # Organize by level for pyramid structure
        for level in competency_gaps.get('levels_needed', []):
            if level in [1, 2, 4, 6]:
                gaps['by_level'][level].append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'gap_data': competency_gaps
                })

    return gaps


def process_competency_with_roles(org_id, competency, target_level):
    """
    Process one competency for high maturity organization.

    Calculate gaps per role, check if ANY user has gap.
    """

    roles = get_organization_roles(org_id)

    competency_data = {
        'competency_id': competency.id,
        'competency_name': competency.name,
        'target_level': target_level,
        'has_gap': False,
        'levels_needed': [],
        'roles': {}
    }

    # Process each role
    for role in roles:
        # Get all users in this role
        user_ids = get_users_in_role(role.id)

        if len(user_ids) == 0:
            continue  # No users in this role

        # Get assessment scores for these users
        user_scores = []
        for user_id in user_ids:
            score = get_user_competency_score(user_id, competency.id)
            if score is not None:
                user_scores.append(score)

        if len(user_scores) == 0:
            continue  # No assessment data

        # Calculate statistics
        median_level = calculate_median(user_scores)
        mean_level = calculate_mean(user_scores)
        variance = calculate_variance(user_scores)

        # Determine which levels this role needs
        role_levels_needed = []
        level_details = {}

        for level in [1, 2, 4, 6]:
            if level > target_level:
                continue  # This level exceeds strategy target

            # Count users needing this level
            # User needs level if: current_score < level <= target
            users_needing_level = [
                score for score in user_scores
                if score < level <= target_level
            ]

            if len(users_needing_level) > 0:
                # AT LEAST ONE user needs this level
                competency_data['has_gap'] = True

                if level not in competency_data['levels_needed']:
                    competency_data['levels_needed'].append(level)

                if level not in role_levels_needed:
                    role_levels_needed.append(level)

                # Store level-specific details
                level_details[level] = {
                    'users_needing': len(users_needing_level),
                    'total_users': len(user_scores),
                    'percentage': len(users_needing_level) / len(user_scores)
                }

        # Store role data (only if this role has gaps)
        if len(role_levels_needed) > 0:
            # Calculate overall gap percentage for this role
            users_below_target = [
                score for score in user_scores
                if score < target_level
            ]
            gap_percentage = len(users_below_target) / len(user_scores)

            # Determine training method recommendation
            training_rec = determine_training_method(
                gap_percentage,
                variance,
                len(user_scores)
            )

            competency_data['roles'][role.id] = {
                'role_id': role.id,
                'role_name': role.name,
                'total_users': len(user_scores),
                'users_needing_training': len(users_below_target),
                'gap_percentage': gap_percentage,
                'median_level': median_level,
                'mean_level': mean_level,
                'variance': variance,
                'levels_needed': sorted(role_levels_needed),
                'level_details': level_details,
                'training_recommendation': training_rec
            }

    # Sort levels needed
    competency_data['levels_needed'] = sorted(competency_data['levels_needed'])

    return competency_data


def process_competency_organizational(org_id, competency, target_level):
    """
    Process one competency for low maturity organization.

    All users treated as one group (no role separation).
    """

    # Get all user scores for this competency
    all_user_scores = get_all_user_scores_for_competency(
        org_id,
        competency.id
    )

    if len(all_user_scores) == 0:
        # No assessment data
        return {
            'competency_id': competency.id,
            'competency_name': competency.name,
            'target_level': target_level,
            'has_gap': False,
            'levels_needed': [],
            'organizational_stats': None
        }

    # Calculate statistics
    median_level = calculate_median(all_user_scores)
    mean_level = calculate_mean(all_user_scores)
    variance = calculate_variance(all_user_scores)

    # Determine which levels needed
    levels_needed = []
    level_details = {}

    for level in [1, 2, 4, 6]:
        if level > target_level:
            continue

        # Count users needing this level
        users_needing_level = [
            score for score in all_user_scores
            if score < level <= target_level
        ]

        if len(users_needing_level) > 0:
            levels_needed.append(level)

            level_details[level] = {
                'users_needing': len(users_needing_level),
                'total_users': len(all_user_scores),
                'percentage': len(users_needing_level) / len(all_user_scores)
            }

    # Calculate overall gap
    has_gap = len(levels_needed) > 0
    gap_percentage = 0
    users_below_target = 0

    if has_gap:
        users_below_target_list = [
            score for score in all_user_scores
            if score < target_level
        ]
        users_below_target = len(users_below_target_list)
        gap_percentage = users_below_target / len(all_user_scores)

    # Determine training method
    training_rec = determine_training_method(
        gap_percentage,
        variance,
        len(all_user_scores)
    ) if has_gap else None

    return {
        'competency_id': competency.id,
        'competency_name': competency.name,
        'target_level': target_level,
        'has_gap': has_gap,
        'levels_needed': sorted(levels_needed),
        'organizational_stats': {
            'total_users': len(all_user_scores),
            'users_needing_training': users_below_target,
            'gap_percentage': gap_percentage,
            'median_level': median_level,
            'mean_level': mean_level,
            'variance': variance,
            'level_details': level_details,
            'training_recommendation': training_rec
        } if has_gap else None
    }
```

**Edge Cases:**
1. ✅ Role with no users: Skip role
2. ✅ Role with no assessment data: Skip role
3. ✅ All users at/above target: `has_gap = False`, no levels needed
4. ✅ One user below target: `has_gap = True`, generate LOs
5. ✅ Target = 0 (no training): No levels needed

**Critical Analysis:**
- ✅ Implements "ANY gap" principle correctly
- ✅ Handles both high and low maturity
- ✅ Calculates distribution statistics for training recommendations
- ✅ Provides complete per-role and per-level data
- ⚠️ Assumes assessment data exists (should validate)
- ✅ Handles missing/sparse data gracefully

---

### Algorithm 4: Determine Training Method

**Purpose:** Based on distribution statistics, recommend appropriate training delivery method

**Input:**
- `gap_percentage`: Percentage of users needing training
- `variance`: Statistical variance of user scores
- `total_users`: Total number of users in the group

**Output:**
- Training method recommendation object

**Algorithm:**
```python
def determine_training_method(gap_percentage, variance, total_users):
    """
    Recommend training delivery method based on distribution.

    This is Phase 3 logic, but calculated and DISPLAYED in Phase 2
    to provide context for admin decision-making.

    Args:
        gap_percentage: Fraction of users needing training (0.0 to 1.0)
        variance: Statistical variance of scores
        total_users: Total number of users

    Returns:
        {
            'method': str,
            'rationale': str,
            'cost_level': str,
            'icon': str
        }
    """

    # Edge case: Very small group
    if total_users < 3:
        return {
            'method': 'Individual Coaching',
            'rationale': 'Very small group - individual approach more effective',
            'cost_level': 'Low',
            'icon': 'mdi-account'
        }

    # High variance suggests diverse needs
    if variance > 4.0:
        return {
            'method': 'Blended Approach (Multiple Tracks)',
            'rationale': (
                f'High variance ({variance:.1f}) indicates diverse competency '
                f'levels - differentiated approach recommended'
            ),
            'cost_level': 'Medium',
            'icon': 'mdi-format-list-bulleted'
        }

    # Decision based on gap percentage
    if gap_percentage < 0.20:
        # Less than 20% need training
        return {
            'method': 'Individual Coaching or External Certification',
            'rationale': (
                f'Only {gap_percentage:.0%} need training - group training '
                f'not cost-effective'
            ),
            'cost_level': 'Medium',
            'icon': 'mdi-account-tie'
        }

    elif gap_percentage < 0.40:
        # 20-40% need training
        return {
            'method': 'Small Group Training or Mentoring',
            'rationale': (
                f'{gap_percentage:.0%} need training - small group or '
                f'mentoring pairs recommended'
            ),
            'cost_level': 'Low to Medium',
            'icon': 'mdi-account-group'
        }

    elif gap_percentage < 0.70:
        # 40-70% need training
        return {
            'method': 'Group Training with Differentiation',
            'rationale': (
                f'{gap_percentage:.0%} need training - mixed group with '
                f'flexibility for varied starting levels'
            ),
            'cost_level': 'Low',
            'icon': 'mdi-school'
        }

    else:
        # 70%+ need training
        expert_percentage = 1.0 - gap_percentage

        if expert_percentage >= 0.10:
            # At least 10% are experts
            return {
                'method': 'Group Training (Experts as Mentors)',
                'rationale': (
                    f'{gap_percentage:.0%} need training, '
                    f'{expert_percentage:.0%} can serve as mentors/helpers'
                ),
                'cost_level': 'Low',
                'icon': 'mdi-school'
            }
        else:
            # Almost everyone needs training
            return {
                'method': 'Group Classroom Training',
                'rationale': (
                    f'{gap_percentage:.0%} need training - group approach '
                    f'most cost-effective'
                ),
                'cost_level': 'Low',
                'icon': 'mdi-school'
            }
```

**Decision Matrix:**

| Gap % | Variance | Total Users | Recommended Method |
|-------|----------|-------------|--------------------|
| Any | Any | < 3 | Individual Coaching |
| Any | > 4.0 | Any | Blended (Multiple Tracks) |
| < 20% | Low | Any | Individual/Certification |
| 20-40% | Low | Any | Small Group/Mentoring |
| 40-70% | Low | Any | Group with Differentiation |
| 70-100% | Low | Any | Group Training |

**Critical Analysis:**
- ✅ Provides actionable recommendations based on data
- ✅ Considers both percentage and distribution pattern
- ✅ Cost-conscious (recommends cheaper methods when appropriate)
- ✅ Accounts for edge cases (small groups, high variance)
- ⚠️ Thresholds are somewhat arbitrary (20%, 40%, 70%)
- ✅ Rationale explains the reasoning to admin
- ⚠️ Doesn't account for other factors (urgency, budget constraints, location)
- ✅ Suitable for Phase 2 display, actual decision in Phase 3

---

*Continued in next file due to length...*
