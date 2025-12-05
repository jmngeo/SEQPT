# Learning Objectives Generation - Design v5 (FINAL)

**Date:** 2025-11-24
**Status:** Final design incorporating all clarifications
**Supersedes:** v4 design
**Reference:** CLARIFICATIONS_FROM_JOMON_2025-11-24.md

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Core Architecture](#core-architecture)
3. [Algorithm Specification](#algorithm-specification)
4. [Data Structures](#data-structures)
5. [UI Components](#ui-components)
6. [API Endpoints](#api-endpoints)
7. [Implementation Plan](#implementation-plan)
8. [Testing Strategy](#testing-strategy)

---

## Executive Summary

### Key Design Decisions

**BOTH Pathways Use Pyramid Structure:**
- High maturity AND low maturity use same pyramid organization
- 4 levels: Knowing (1), Understanding (2), Applying (4), Mastering (6)
- Difference: High maturity shows role data, low maturity doesn't

**LO Generation Rule:**
- Generate learning objective if **ANY user has gap** (even 1 out of 20)
- NOT median-based decision
- Check: `if any(user_score < target_level): generate_LO = True`

**Two Views (Both in Phase 2):**
1. **Organizational Pyramid:** See all roles aggregated
2. **Role-Based Pyramid:** Drill down into single role's needs

**Distribution Statistics:**
- Calculate median, gap_percentage, variance
- Use for training method recommendation (display in Phase 2, use in Phase 3)
- NOT for deciding if LO should be generated

**Progressive Objectives:**
- Generate objectives for ALL intermediate levels
- Example: Current=0, Target=4 → Generate levels 1, 2, and 4
- Applies to BOTH high and low maturity

---

## Core Architecture

### System Flow

```
User completes Phase 1 Task 3 (Strategy Selection)
  ↓
[Selected Strategies] → API Request to Phase 2 Task 3
  ↓
Backend: Load Data
  - Organization info
  - Selected strategies → Get targets
  - User competency assessments
  - Role-competency matrix (if high maturity)
  - PMT context (if applicable)
  ↓
Backend: Calculate Gaps
  - For each competency:
    - For each role (or all users):
      - Check if ANY user < target
      - If yes: Determine which levels needed
      - Calculate distribution stats
  ↓
Backend: Generate Learning Objectives
  - For each competency with gap:
    - For each level needed:
      - Get template objective
      - Customize with PMT (if applicable)
      - Attach distribution stats
      - Determine training recommendation
  ↓
Backend: Structure Output
  - Organize by pyramid level (1, 2, 4, 6)
  - Within each level: All 16 competencies
  - Mark as active or grayed
  - Include role data (if high maturity)
  ↓
Frontend: Two View Options
  1. Organizational Pyramid → Shows all roles
  2. Role-Based Pyramid → Select role, shows that role only
  ↓
User: Review Learning Objectives
  - Navigate pyramid levels
  - See progressive objectives
  - View training recommendations
  - Drill down by role (optional)
```

### Data Flow Diagram

```
┌─────────────────┐
│  Phase 1 Data   │
│  - Strategies   │
│  - Maturity     │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────────────────────┐
│              Phase 2 Task 3 Backend                 │
│                                                     │
│  1. Load Assessment Data                            │
│     - All user scores per competency                │
│     - Role assignments (if high maturity)           │
│                                                      │
│  2. Calculate Strategy Targets                       │
│     - If multiple strategies: take HIGHER target    │
│                                                      │
│  3. Determine Gaps (Per Competency)                 │
│     FOR each competency:                             │
│       FOR each role (or all users):                  │
│         IF any(user_score < target):                 │
│           gap_exists = True                          │
│           levels_needed = [1,2,4,6 between current and target] │
│                                                      │
│  4. Calculate Distribution Statistics                │
│     - Median (for display/context)                   │
│     - Gap percentage                                 │
│     - Variance                                       │
│     - Training recommendation                        │
│                                                      │
│  5. Generate Learning Objectives                     │
│     - Template lookup                                │
│     - PMT customization (if applicable)              │
│     - Attach metadata                                │
│                                                      │
│  6. Structure Output                                 │
│     - Organize by pyramid level                      │
│     - Include distribution stats                     │
│     - Training recommendations                       │
│                                                      │
└────────────────┬───────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│              Phase 2 Task 3 Frontend                │
│                                                     │
│  View 1: Organizational Pyramid                     │
│    - Level tabs (1, 2, 4, 6)                       │
│    - All 16 competencies per level                  │
│    - Roles shown within competencies                │
│                                                      │
│  View 2: Role-Based Pyramid                          │
│    - Role selector dropdown                          │
│    - Level tabs (1, 2, 4, 6)                       │
│    - Competencies filtered for selected role         │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Algorithm Specification

### Algorithm 1: Gap Detection

**Purpose:** Determine which competencies need training and at which levels

```python
def detect_gaps(org_id, selected_strategies):
    """
    Detect training gaps for all competencies across all roles.

    Returns: Dictionary of gaps by competency and level
    """

    # Get strategy targets (take HIGHER if multiple strategies)
    strategy_targets = calculate_combined_targets(selected_strategies)
    # Returns: {competency_id: target_level}

    # Get organization structure
    has_roles = check_if_org_has_roles(org_id)

    # Initialize gaps structure
    gaps = {
        'by_level': {1: [], 2: [], 4: [], 6: []},  # For pyramid organization
        'by_competency': {},  # For processing
        'metadata': {
            'has_roles': has_roles,
            'organization_id': org_id,
            'strategies': selected_strategies
        }
    }

    # Process each competency
    for competency in ALL_16_COMPETENCIES:
        target_level = strategy_targets[competency.id]

        if has_roles:
            # High maturity: Process by role
            gaps['by_competency'][competency.id] = process_competency_with_roles(
                competency,
                target_level,
                org_id
            )
        else:
            # Low maturity: Process all users together
            gaps['by_competency'][competency.id] = process_competency_without_roles(
                competency,
                target_level,
                org_id
            )

        # Organize by pyramid level
        for level in [1, 2, 4, 6]:
            if level_has_gap(gaps['by_competency'][competency.id], level):
                gaps['by_level'][level].append({
                    'competency': competency,
                    'gap_data': get_level_specific_data(
                        gaps['by_competency'][competency.id],
                        level
                    )
                })

    return gaps
```

### Algorithm 2: Process Competency with Roles (High Maturity)

```python
def process_competency_with_roles(competency, target_level, org_id):
    """
    Process one competency across all roles in organization.

    Check if ANY user in ANY role has gap → Generate LO
    Calculate distribution stats per role for training recommendations
    """

    roles = get_organization_roles(org_id)
    competency_data = {
        'competency_id': competency.id,
        'target_level': target_level,
        'has_gap': False,
        'levels_needed': [],
        'roles': {}
    }

    # Process each role
    for role in roles:
        user_scores = get_user_scores_for_role(role.id, competency.id)

        if len(user_scores) == 0:
            # No users in this role
            continue

        # Calculate statistics
        median_level = calculate_median(user_scores)
        mean_level = calculate_mean(user_scores)
        variance = calculate_variance(user_scores)

        # Check gap at each level
        role_levels_needed = []
        for level in [1, 2, 4, 6]:
            if level > target_level:
                # This level exceeds strategy target
                continue

            # Count users needing this level
            users_needing_level = [
                score for score in user_scores
                if score < level <= target_level
            ]

            if len(users_needing_level) > 0:
                # At least one user in this role needs this level
                competency_data['has_gap'] = True

                if level not in competency_data['levels_needed']:
                    competency_data['levels_needed'].append(level)

                if level not in role_levels_needed:
                    role_levels_needed.append(level)

        # Store role-specific data
        if len(role_levels_needed) > 0:
            gap_percentage = len([s for s in user_scores if s < target_level]) / len(user_scores)

            competency_data['roles'][role.id] = {
                'role_name': role.name,
                'role_id': role.id,
                'total_users': len(user_scores),
                'median_level': median_level,
                'mean_level': mean_level,
                'variance': variance,
                'levels_needed': role_levels_needed,
                'gap_percentage': gap_percentage,
                'users_needing_training': len([s for s in user_scores if s < target_level]),
                'training_recommendation': determine_training_method(
                    gap_percentage,
                    variance,
                    len(user_scores)
                ),
                # Per-level details
                'level_details': {
                    level: {
                        'users_needing': len([s for s in user_scores if s < level <= target_level]),
                        'percentage': len([s for s in user_scores if s < level <= target_level]) / len(user_scores)
                    }
                    for level in role_levels_needed
                }
            }

    # Sort levels
    competency_data['levels_needed'].sort()

    return competency_data
```

### Algorithm 3: Process Competency without Roles (Low Maturity)

```python
def process_competency_without_roles(competency, target_level, org_id):
    """
    Process one competency for organization without defined roles.

    All users treated as one group.
    """

    # Get all user scores for this competency
    all_user_scores = get_all_user_scores(org_id, competency.id)

    if len(all_user_scores) == 0:
        # No assessment data
        return {
            'competency_id': competency.id,
            'target_level': target_level,
            'has_gap': False,
            'levels_needed': [],
            'organizational_stats': None
        }

    # Calculate statistics
    median_level = calculate_median(all_user_scores)
    mean_level = calculate_mean(all_user_scores)
    variance = calculate_variance(all_user_scores)

    # Check gap at each level
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
                'percentage': len(users_needing_level) / len(all_user_scores),
                'total_users': len(all_user_scores)
            }

    # Determine overall gap and training recommendation
    has_gap = len(levels_needed) > 0
    gap_percentage = 0
    if has_gap:
        gap_percentage = len([s for s in all_user_scores if s < target_level]) / len(all_user_scores)

    return {
        'competency_id': competency.id,
        'target_level': target_level,
        'has_gap': has_gap,
        'levels_needed': levels_needed,
        'organizational_stats': {
            'total_users': len(all_user_scores),
            'median_level': median_level,
            'mean_level': mean_level,
            'variance': variance,
            'gap_percentage': gap_percentage,
            'users_needing_training': len([s for s in all_user_scores if s < target_level]),
            'training_recommendation': determine_training_method(
                gap_percentage,
                variance,
                len(all_user_scores)
            ),
            'level_details': level_details
        }
    }
```

### Algorithm 4: Determine Training Method (Phase 3 Logic, Display in Phase 2)

```python
def determine_training_method(gap_percentage, variance, total_users):
    """
    Based on distribution statistics, recommend training method.

    This is Phase 3 logic, but calculate and display in Phase 2.
    """

    # Check for edge cases
    if total_users < 3:
        return {
            'method': 'Individual coaching',
            'rationale': 'Very small group - individual approach recommended',
            'cost_level': 'Low',
            'icon': 'person'
        }

    # High variance suggests diverse needs
    if variance > 4.0:
        return {
            'method': 'Blended approach with multiple tracks',
            'rationale': 'High variance detected - users have diverse competency levels',
            'cost_level': 'Medium',
            'icon': 'school'
        }

    # Gap percentage determines group vs individual
    if gap_percentage < 0.2:  # Less than 20% need training
        return {
            'method': 'Individual coaching or external certification',
            'rationale': f'Only {gap_percentage:.0%} need training - not cost-effective for group training',
            'cost_level': 'Medium',
            'icon': 'person'
        }

    elif gap_percentage < 0.4:  # 20-40% need training
        return {
            'method': 'Small group training or mentoring',
            'rationale': f'{gap_percentage:.0%} need training - small group or mentoring recommended',
            'cost_level': 'Low to Medium',
            'icon': 'groups'
        }

    elif gap_percentage < 0.7:  # 40-70% need training
        return {
            'method': 'Group training with differentiation',
            'rationale': f'{gap_percentage:.0%} need training - mixed group with some flexibility',
            'cost_level': 'Low',
            'icon': 'school'
        }

    else:  # 70%+ need training
        # Check for experts who can be mentors
        if gap_percentage < 1.0:  # Some don't need training
            expert_percentage = 1.0 - gap_percentage
            return {
                'method': 'Group training (experts as mentors)',
                'rationale': f'{gap_percentage:.0%} need training, {expert_percentage:.0%} can serve as mentors',
                'cost_level': 'Low',
                'icon': 'school'
            }
        else:  # 100% need training
            return {
                'method': 'Group classroom training',
                'rationale': 'All users need training - group training most cost-effective',
                'cost_level': 'Low',
                'icon': 'school'
            }
```

### Algorithm 5: Generate Learning Objectives

```python
def generate_learning_objectives(gaps, pmt_context=None):
    """
    Generate learning objective text for all competencies with gaps.

    Uses template-based approach with optional PMT customization.
    """

    learning_objectives = {
        'by_level': {1: [], 2: [], 4: [], 6: []},
        'by_competency': {},
        'metadata': {
            'generation_timestamp': datetime.now(),
            'pmt_customization': pmt_context is not None
        }
    }

    # Load learning objectives templates
    templates = load_lo_templates()  # From JSON file

    # Process each competency with gap
    for competency_id, competency_data in gaps['by_competency'].items():
        if not competency_data['has_gap']:
            # No gap - mark as achieved but include in output
            learning_objectives['by_competency'][competency_id] = {
                'competency_id': competency_id,
                'status': 'achieved',
                'message': 'Already at target level or higher'
            }
            continue

        competency = get_competency_by_id(competency_id)
        competency_objectives = {
            'competency_id': competency_id,
            'competency_name': competency.name,
            'target_level': competency_data['target_level'],
            'status': 'training_required',
            'objectives_by_level': {}
        }

        # Generate objective for each needed level
        for level in competency_data['levels_needed']:
            template = templates[competency_id][level]

            # Customize with PMT if applicable
            if pmt_context and template_requires_pmt(template):
                objective_text = customize_with_pmt(template, pmt_context, competency)
            else:
                objective_text = template['objective_text']

            competency_objectives['objectives_by_level'][level] = {
                'level': level,
                'level_name': get_level_name(level),
                'objective_text': objective_text,
                'customized': pmt_context is not None and template_requires_pmt(template),
                'template_id': template['id']
            }

            # Add to level-organized structure
            learning_objectives['by_level'][level].append({
                'competency_id': competency_id,
                'competency_name': competency.name,
                'objective_text': objective_text,
                'gap_data': competency_data
            })

        learning_objectives['by_competency'][competency_id] = competency_objectives

    return learning_objectives
```

### Algorithm 6: Structure Final Output

```python
def structure_pyramid_output(gaps, learning_objectives, validation_result):
    """
    Structure final output for frontend consumption.

    Organized by pyramid level for easy UI rendering.
    """

    pyramid_structure = {
        'levels': {},
        'metadata': {
            'organization_id': gaps['metadata']['organization_id'],
            'has_roles': gaps['metadata']['has_roles'],
            'strategies': gaps['metadata']['strategies'],
            'validation': validation_result
        }
    }

    # Build each pyramid level
    for level_num in [1, 2, 4, 6]:
        level_data = build_level_structure(
            level_num,
            gaps,
            learning_objectives
        )

        pyramid_structure['levels'][level_num] = level_data

    return pyramid_structure

def build_level_structure(level_num, gaps, learning_objectives):
    """
    Build data structure for one pyramid level.
    """

    level_name_map = {
        1: 'Knowing SE',
        2: 'Understanding SE',
        4: 'Applying SE',
        6: 'Mastering SE'
    }

    # Check if level should be grayed out
    should_gray_out, gray_reason = check_if_level_grayed(level_num, gaps)

    level_structure = {
        'level_number': level_num,
        'level_name': level_name_map[level_num],
        'grayed_out': should_gray_out,
        'gray_reason': gray_reason,
        'competencies': []
    }

    # Add all 16 competencies (active or grayed)
    for competency in ALL_16_COMPETENCIES:
        competency_data = gaps['by_competency'][competency.id]
        lo_data = learning_objectives['by_competency'][competency.id]

        # Check if this competency needs training at this level
        needs_training_at_level = level_num in competency_data.get('levels_needed', [])

        competency_structure = {
            'competency_id': competency.id,
            'competency_name': competency.name,
            'target_level': competency_data['target_level'],
            'status': 'training_required' if needs_training_at_level else 'achieved',
            'grayed_out': not needs_training_at_level
        }

        if needs_training_at_level:
            # Add learning objective and gap data
            competency_structure['learning_objective'] = lo_data['objectives_by_level'][level_num]

            # Add role information (if high maturity)
            if gaps['metadata']['has_roles'] and 'roles' in competency_data:
                competency_structure['roles'] = [
                    {
                        'role_id': role_id,
                        'role_name': role_info['role_name'],
                        'users_needing': role_info['level_details'][level_num]['users_needing'],
                        'total_users': role_info['total_users'],
                        'percentage': role_info['level_details'][level_num]['percentage'],
                        'median_level': role_info['median_level'],
                        'training_recommendation': role_info['training_recommendation']
                    }
                    for role_id, role_info in competency_data['roles'].items()
                    if level_num in role_info['levels_needed']
                ]
            elif not gaps['metadata']['has_roles']:
                # Low maturity: organizational stats
                competency_structure['organizational_stats'] = competency_data['organizational_stats']

        else:
            # Already achieved
            competency_structure['message'] = f"Already at Level {level_num}+ or not required"

        level_structure['competencies'].append(competency_structure)

    return level_structure

def check_if_level_grayed(level_num, gaps):
    """
    Determine if entire pyramid level should be grayed out.

    Two conditions:
    1. No competencies have gaps at this level
    2. Level exceeds all strategy targets
    """

    # Condition 2: Check strategy targets
    max_target_across_competencies = max(
        data['target_level']
        for data in gaps['by_competency'].values()
    )

    if level_num > max_target_across_competencies:
        return True, f"Level {level_num} exceeds all strategy targets (max target: {max_target_across_competencies})"

    # Condition 1: Check if any competency needs this level
    any_competency_needs_level = any(
        level_num in data.get('levels_needed', [])
        for data in gaps['by_competency'].values()
    )

    if not any_competency_needs_level:
        return True, f"No users need training at Level {level_num}"

    return False, None
```

### Algorithm 7: Validation (Informational Only)

```python
def validate_strategy_alignment(org_id, selected_strategies):
    """
    Compare current organizational levels vs strategy targets.

    Returns informational summary (no blocking).
    """

    # Get combined strategy targets
    strategy_targets = calculate_combined_targets(selected_strategies)

    # Calculate current organizational levels (use median)
    current_levels = {}
    for competency in ALL_16_COMPETENCIES:
        all_user_scores = get_all_user_scores(org_id, competency.id)
        if len(all_user_scores) > 0:
            current_levels[competency.id] = calculate_median(all_user_scores)
        else:
            current_levels[competency.id] = 0

    # Compare
    aligned = []
    below_target = []
    above_target = []

    for competency in ALL_16_COMPETENCIES:
        current = current_levels[competency.id]
        target = strategy_targets[competency.id]

        if current == target:
            aligned.append(competency.name)
        elif current < target:
            below_target.append({
                'name': competency.name,
                'current': current,
                'target': target,
                'gap': target - current
            })
        else:
            above_target.append({
                'name': competency.name,
                'current': current,
                'target': target,
                'surplus': current - target
            })

    return {
        'status': 'INFORMATIONAL',
        'aligned_count': len(aligned),
        'below_count': len(below_target),
        'above_count': len(above_target),
        'message': (
            f"Current competency levels align with selected strategy for "
            f"{len(aligned)}/16 competencies. "
            f"{len(below_target)} competencies below target (training needed). "
            f"{len(above_target)} competencies already exceed targets."
        ),
        'details': {
            'aligned': aligned,
            'below_target': below_target,
            'above_target': above_target
        }
    }
```

---

## Data Structures

### Input Structure

```python
request_input = {
    'organization_id': int,
    'selected_strategies': [
        {
            'strategy_id': int,
            'strategy_name': str
        }
    ],
    'pmt_context': {  # Optional, only if PMT collected
        'processes': str,
        'methods': str,
        'tools': str
    } or None
}
```

### Output Structure

```python
response_output = {
    'success': bool,
    'data': {
        'pyramid': {
            'levels': {
                '1': level_structure,  # Knowing
                '2': level_structure,  # Understanding
                '4': level_structure,  # Applying
                '6': level_structure   # Mastering
            },
            'metadata': {
                'organization_id': int,
                'organization_name': str,
                'has_roles': bool,
                'strategies': [strategy_info],
                'validation': validation_result,
                'generation_timestamp': datetime
            }
        }
    },
    'errors': [] or None
}

# level_structure format:
level_structure = {
    'level_number': int,  # 1, 2, 4, or 6
    'level_name': str,    # "Knowing SE", etc.
    'grayed_out': bool,
    'gray_reason': str or None,
    'competencies': [competency_structure]
}

# competency_structure format:
competency_structure = {
    'competency_id': int,
    'competency_name': str,
    'target_level': int,
    'status': 'training_required' or 'achieved',
    'grayed_out': bool,

    # If training_required:
    'learning_objective': {
        'level': int,
        'level_name': str,
        'objective_text': str,
        'customized': bool
    },

    # If has_roles (high maturity):
    'roles': [
        {
            'role_id': int,
            'role_name': str,
            'users_needing': int,
            'total_users': int,
            'percentage': float,
            'median_level': int,
            'training_recommendation': {
                'method': str,
                'rationale': str,
                'cost_level': str,
                'icon': str
            }
        }
    ],

    # If no roles (low maturity):
    'organizational_stats': {
        'total_users': int,
        'median_level': int,
        'mean_level': float,
        'variance': float,
        'gap_percentage': float,
        'users_needing_training': int,
        'training_recommendation': {...}
    },

    # If achieved:
    'message': str
}
```

---

*Continued in Part 2...*
