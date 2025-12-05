# Learning Objectives Design v5 - Part 2

**Continuation of:** LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE.md

---

## Core Algorithms (Continued)

### Algorithm 5: Process TTT Gaps (Simplified)

**Purpose:** Identify competencies needing Level 6 training for "Train the Trainer" strategy

**Input:**
- `org_id`: Organization ID
- `ttt_targets`: All competencies at Level 6

**Output:**
- TTT gap data with Level 6 competencies

**Algorithm:**
```python
def process_ttt_gaps(org_id, ttt_targets):
    """
    Process Train the Trainer gaps.

    SIMPLIFIED: Just identify which competencies need Level 6 training.
    No internal/external selection - that's Phase 3.

    Args:
        org_id: Organization ID
        ttt_targets: Dictionary {competency_id: 6}

    Returns:
        {
            'enabled': True,
            'competencies': [...]
        } or None
    """

    if ttt_targets is None:
        return None

    ttt_data = {
        'enabled': True,
        'competencies': []
    }

    # Check each competency
    for competency in ALL_16_COMPETENCIES:
        target_level = ttt_targets[competency.id]  # Should always be 6

        # Get all user scores
        all_user_scores = get_all_user_scores_for_competency(
            org_id,
            competency.id
        )

        if len(all_user_scores) == 0:
            # No assessment data - assume gap exists
            users_needing_mastery = []
            gap_percentage = 1.0  # 100% need training (unknown state)
        else:
            # Count users below Level 6
            users_needing_mastery = [
                score for score in all_user_scores
                if score < 6
            ]
            gap_percentage = len(users_needing_mastery) / len(all_user_scores)

        # If ANY user needs Level 6 → Include in TTT
        if len(all_user_scores) == 0 or len(users_needing_mastery) > 0:
            ttt_data['competencies'].append({
                'competency_id': competency.id,
                'competency_name': competency.name,
                'level': 6,
                'level_name': 'Mastering SE',
                'users_needing': len(users_needing_mastery),
                'total_users': len(all_user_scores),
                'gap_percentage': gap_percentage
            })

    # Return None if no competencies need TTT
    if len(ttt_data['competencies']) == 0:
        return None

    return ttt_data
```

**Edge Cases:**
1. ✅ All users already at Level 6: No TTT competencies (return None)
2. ✅ No assessment data: Assume gap exists, include competency
3. ✅ Some users at Level 6: Still include (even if majority at 6)

**Critical Analysis:**
- ✅ Simplified - no internal/external decision
- ✅ Consistent with "ANY gap" principle
- ✅ Handles missing assessment data gracefully
- ⚠️ If no users need Level 6 but TTT selected → Return None (edge case)
- ✅ Can be extended in Phase 3 for trainer selection

---

### Algorithm 6: Generate Learning Objectives

**Purpose:** Create learning objective text for each competency at each needed level

**Input:**
- `gaps`: Gap detection results
- `ttt_gaps`: TTT gap detection results (or None)
- `pmt_context`: PMT information (or None)

**Output:**
- Learning objectives organized by level and competency

**Algorithm:**
```python
def generate_learning_objectives(gaps, ttt_gaps=None, pmt_context=None):
    """
    Generate learning objective text for all gaps.

    Uses template-based approach with optional PMT customization.

    Args:
        gaps: Gap detection results (main pyramid)
        ttt_gaps: TTT gap detection results
        pmt_context: PMT information (optional)

    Returns:
        {
            'main_pyramid': {...},
            'ttt_section': {...} or None
        }
    """

    # Load templates
    templates = load_learning_objectives_templates()

    # Generate main pyramid objectives
    main_pyramid = generate_pyramid_objectives(
        gaps,
        templates,
        pmt_context
    )

    # Generate TTT objectives (if applicable)
    ttt_section = None
    if ttt_gaps is not None:
        ttt_section = generate_ttt_objectives(
            ttt_gaps,
            templates,
            pmt_context
        )

    return {
        'main_pyramid': main_pyramid,
        'ttt_section': ttt_section
    }


def generate_pyramid_objectives(gaps, templates, pmt_context):
    """
    Generate objectives for main pyramid.
    """

    pyramid_objectives = {
        'by_level': {1: [], 2: [], 4: [], 6: []},
        'by_competency': {},
        'metadata': {
            'generation_timestamp': datetime.now(),
            'pmt_customization': pmt_context is not None
        }
    }

    for competency_id, gap_data in gaps['by_competency'].items():
        competency = get_competency_by_id(competency_id)

        if not gap_data['has_gap']:
            # No gap - mark as achieved
            pyramid_objectives['by_competency'][competency_id] = {
                'competency_id': competency_id,
                'competency_name': competency.name,
                'status': 'achieved',
                'message': 'Target level already achieved'
            }
            continue

        # Generate objectives for each needed level
        competency_objectives = {
            'competency_id': competency_id,
            'competency_name': competency.name,
            'target_level': gap_data['target_level'],
            'status': 'training_required',
            'objectives_by_level': {}
        }

        for level in gap_data['levels_needed']:
            # Get template
            template = templates[competency_id][level]

            # Customize with PMT if applicable
            if pmt_context and requires_pmt_customization(template):
                objective_text = customize_objective_with_pmt(
                    template,
                    pmt_context,
                    competency
                )
                customized = True
            else:
                objective_text = template['objective_text']
                customized = False

            # Store objective
            objective_data = {
                'level': level,
                'level_name': get_level_name(level),
                'objective_text': objective_text,
                'customized': customized,
                'template_id': template['id']
            }

            competency_objectives['objectives_by_level'][level] = objective_data

            # Add to level-organized structure
            pyramid_objectives['by_level'][level].append({
                'competency_id': competency_id,
                'competency_name': competency.name,
                'objective': objective_data,
                'gap_data': gap_data
            })

        pyramid_objectives['by_competency'][competency_id] = competency_objectives

    return pyramid_objectives


def generate_ttt_objectives(ttt_gaps, templates, pmt_context):
    """
    Generate Level 6 objectives for TTT section.

    SIMPLIFIED: Just generate objectives, no special handling.
    """

    ttt_objectives = {
        'enabled': True,
        'competencies': []
    }

    for comp_data in ttt_gaps['competencies']:
        competency_id = comp_data['competency_id']
        competency = get_competency_by_id(competency_id)

        # Get Level 6 template
        template = templates[competency_id][6]

        # Customize with PMT if applicable
        if pmt_context and requires_pmt_customization(template):
            objective_text = customize_objective_with_pmt(
                template,
                pmt_context,
                competency
            )
            customized = True
        else:
            objective_text = template['objective_text']
            customized = False

        ttt_objectives['competencies'].append({
            'competency_id': competency_id,
            'competency_name': competency.name,
            'level': 6,
            'level_name': 'Mastering SE',
            'objective_text': objective_text,
            'customized': customized,
            'users_needing': comp_data['users_needing'],
            'total_users': comp_data['total_users'],
            'gap_percentage': comp_data['gap_percentage']
        })

    return ttt_objectives


def customize_objective_with_pmt(template, pmt_context, competency):
    """
    Customize learning objective text using PMT context.

    Uses LLM (GPT-4) to integrate company-specific PMT.
    """

    # Extract PMT components
    processes = pmt_context.get('processes', '')
    methods = pmt_context.get('methods', '')
    tools = pmt_context.get('tools', '')

    # Build prompt for LLM
    prompt = f"""
You are customizing a learning objective for a Systems Engineering competency training program.

COMPETENCY: {competency.name}
LEVEL: {template['level']} ({template['level_name']})

STANDARD TEMPLATE OBJECTIVE:
{template['objective_text']}

COMPANY-SPECIFIC CONTEXT:
Processes: {processes}
Methods: {methods}
Tools: {tools}

TASK:
Customize the learning objective to incorporate the company's specific processes, methods, and tools.
Keep the same competency level and learning outcomes, but make it relevant to their context.
Return ONLY the customized objective text.

CUSTOMIZED OBJECTIVE:
"""

    # Call LLM
    response = call_openai_gpt4(prompt, max_tokens=300, temperature=0.3)

    customized_text = response.strip()

    # Validate that customization actually happened
    if len(customized_text) < 50 or customized_text == template['objective_text']:
        # LLM failed or returned same text - use template
        return template['objective_text']

    return customized_text


def requires_pmt_customization(template):
    """
    Check if template requires/benefits from PMT customization.

    Some competencies (e.g., Communication, Teamwork) don't benefit from PMT.
    Technical competencies (e.g., Requirements, Verification) do benefit.
    """

    # Templates should have 'pmt_customizable' flag
    return template.get('pmt_customizable', False)
```

**Edge Cases:**
1. ✅ No PMT context: Use standard templates
2. ✅ PMT context but template not customizable: Use standard template
3. ✅ LLM fails: Fallback to standard template
4. ✅ No gaps: Mark competency as "achieved"
5. ✅ TTT selected but no users need Level 6: Return None

**Critical Analysis:**
- ✅ Template-based approach is fast and reliable
- ✅ PMT customization adds value when applicable
- ✅ Graceful fallback if customization fails
- ⚠️ LLM calls add latency (can be async/cached)
- ✅ Distinguishes which competencies benefit from PMT
- ⚠️ Assumes templates exist for all competency-level combinations
- ✅ Validation ensures quality (minimum length check)

---

### Algorithm 7: Structure Pyramid Output

**Purpose:** Organize generated objectives into pyramid structure for frontend consumption

**Input:**
- `gaps`: Gap detection results
- `objectives`: Generated learning objectives
- `validation_result`: Mastery requirements validation

**Output:**
- Complete pyramid structure organized by level

**Algorithm:**
```python
def structure_pyramid_output(gaps, objectives, validation_result):
    """
    Structure final output for frontend.

    Organized by pyramid level with all 16 competencies per level.

    Args:
        gaps: Gap detection results
        objectives: Generated learning objectives
        validation_result: Mastery validation

    Returns:
        Complete pyramid structure
    """

    pyramid = {
        'levels': {},
        'metadata': {
            'organization_id': gaps['metadata']['organization_id'],
            'has_roles': gaps['metadata']['has_roles'],
            'generation_timestamp': objectives['main_pyramid']['metadata']['generation_timestamp'],
            'pmt_customization': objectives['main_pyramid']['metadata']['pmt_customization'],
            'mastery_validation': validation_result
        }
    }

    # Build each level
    for level_num in [1, 2, 4, 6]:
        pyramid['levels'][level_num] = build_level_structure(
            level_num,
            gaps,
            objectives['main_pyramid']
        )

    return pyramid


def build_level_structure(level_num, gaps, objectives):
    """
    Build complete structure for one pyramid level.

    Shows ALL 16 competencies (active or grayed).
    """

    level_names = {
        1: 'Knowing SE',
        2: 'Understanding SE',
        4: 'Applying SE',
        6: 'Mastering SE'
    }

    # Check if entire level should be grayed
    should_gray_level, gray_reason = check_if_level_grayed(level_num, gaps)

    level_structure = {
        'level_number': level_num,
        'level_name': level_names[level_num],
        'grayed_out': should_gray_level,
        'gray_reason': gray_reason,
        'competencies': []
    }

    # Add all 16 competencies
    for competency in ALL_16_COMPETENCIES:
        comp_id = competency.id
        gap_data = gaps['by_competency'][comp_id]
        obj_data = objectives['by_competency'][comp_id]

        # Check if this competency needs training at this level
        needs_training = level_num in gap_data.get('levels_needed', [])

        competency_card = {
            'competency_id': comp_id,
            'competency_name': competency.name,
            'target_level': gap_data['target_level'],
            'status': 'training_required' if needs_training else 'achieved',
            'grayed_out': not needs_training
        }

        if needs_training:
            # Add learning objective
            competency_card['learning_objective'] = obj_data['objectives_by_level'][level_num]

            # Add role information (if high maturity)
            if gaps['metadata']['has_roles'] and 'roles' in gap_data:
                competency_card['roles'] = build_role_data_for_level(
                    gap_data['roles'],
                    level_num
                )

            # Add organizational stats (if low maturity)
            elif not gaps['metadata']['has_roles'] and gap_data['organizational_stats']:
                competency_card['organizational_stats'] = gap_data['organizational_stats']

        else:
            # Already achieved
            competency_card['message'] = f"Already at Level {level_num}+ or not required by strategy"

        level_structure['competencies'].append(competency_card)

    return level_structure


def build_role_data_for_level(roles_data, level_num):
    """
    Extract role data specific to one level.

    Only include roles that need this specific level.
    """

    roles_for_level = []

    for role_id, role_info in roles_data.items():
        if level_num in role_info['levels_needed']:
            # This role needs training at this level
            level_detail = role_info['level_details'][level_num]

            roles_for_level.append({
                'role_id': role_id,
                'role_name': role_info['role_name'],
                'users_needing': level_detail['users_needing'],
                'total_users': role_info['total_users'],
                'percentage': level_detail['percentage'],
                'median_level': role_info['median_level'],
                'variance': role_info['variance'],
                'training_recommendation': role_info['training_recommendation']
            })

    return roles_for_level


def check_if_level_grayed(level_num, gaps):
    """
    Determine if entire pyramid level should be grayed out.

    TWO conditions:
    1. No competencies have gaps at this level
    2. Level exceeds BOTH strategy targets AND role requirements

    REVISED: Check role requirements too, not just strategy targets.
    """

    # Get max strategy target
    max_strategy_target = 0
    for gap_data in gaps['by_competency'].values():
        if gap_data['target_level'] > max_strategy_target:
            max_strategy_target = gap_data['target_level']

    # Get max role requirement (if high maturity)
    max_role_requirement = 0
    if gaps['metadata']['has_roles']:
        for gap_data in gaps['by_competency'].values():
            if 'roles' in gap_data:
                for role_info in gap_data['roles'].values():
                    # Infer role requirement from levels needed
                    if len(role_info['levels_needed']) > 0:
                        max_level_for_role = max(role_info['levels_needed'])
                        if max_level_for_role > max_role_requirement:
                            max_role_requirement = max_level_for_role

    # Take HIGHER of strategy target or role requirement
    max_needed_level = max(max_strategy_target, max_role_requirement)

    # Condition 2: Level exceeds both strategy and role requirements
    if level_num > max_needed_level:
        return True, f"Level {level_num} exceeds strategy targets (max: {max_needed_level})"

    # Condition 1: No competencies need this level
    any_competency_needs_level = any(
        level_num in gap_data.get('levels_needed', [])
        for gap_data in gaps['by_competency'].values()
    )

    if not any_competency_needs_level:
        return True, f"No training gaps at Level {level_num}"

    return False, None
```

**Edge Cases:**
1. ✅ All competencies achieved at level: Gray out entire level
2. ✅ Level exceeds strategy targets: Gray out
3. ✅ Level exceeds role requirements AND strategy: Gray out
4. ✅ No roles defined: Check only strategy targets
5. ✅ Mixed: Some roles need level, some don't: Show active

**Critical Analysis:**
- ✅ Shows complete picture (all 16 competencies)
- ✅ Graying provides visual feedback
- ✅ Handles both high and low maturity gracefully
- ✅ Considers role requirements in graying logic (critical fix)
- ✅ Provides clear messaging for grayed competencies
- ⚠️ Large data structure (16 competencies × 4 levels = 64 cards)
- ✅ Frontend can easily render from this structure

---

### Algorithm 8: Strategy Validation (Informational)

**Purpose:** Compare current organizational levels vs strategy targets for information

**Input:**
- `org_id`: Organization ID
- `selected_strategies`: List of strategies
- `main_targets`: Target levels per competency

**Output:**
- Validation summary (informational, non-blocking)

**Algorithm:**
```python
def validate_strategy_alignment(org_id, selected_strategies, main_targets):
    """
    Validate strategy alignment with current competency levels.

    INFORMATIONAL ONLY - no blocking or warning.
    Uses median for organizational-level comparison.

    Args:
        org_id: Organization ID
        selected_strategies: List of selected strategies
        main_targets: Target levels per competency

    Returns:
        Informational summary
    """

    # Calculate current organizational levels (use median)
    current_levels = {}
    for competency in ALL_16_COMPETENCIES:
        all_scores = get_all_user_scores_for_competency(org_id, competency.id)

        if len(all_scores) > 0:
            current_levels[competency.id] = calculate_median(all_scores)
        else:
            current_levels[competency.id] = 0  # No data = assume lowest

    # Compare current vs target
    aligned = []
    below_target = []
    above_target = []

    for competency in ALL_16_COMPETENCIES:
        current = current_levels[competency.id]
        target = main_targets[competency.id]

        if current == target:
            aligned.append(competency.name)
        elif current < target:
            below_target.append({
                'name': competency.name,
                'current': current,
                'target': target,
                'gap': target - current
            })
        else:  # current > target
            above_target.append({
                'name': competency.name,
                'current': current,
                'target': target,
                'surplus': current - target
            })

    # Generate message
    message = (
        f"Current competency levels align with selected strategies for "
        f"{len(aligned)}/16 competencies. "
        f"{len(below_target)} competencies below target (training needed), "
        f"{len(above_target)} competencies already exceed targets."
    )

    return {
        'status': 'INFORMATIONAL',
        'aligned_count': len(aligned),
        'below_count': len(below_target),
        'above_count': len(above_target),
        'message': message,
        'details': {
            'aligned': aligned,
            'below_target': below_target,
            'above_target': above_target
        }
    }
```

**Critical Analysis:**
- ✅ Uses median (not "ANY gap" rule) - appropriate for org-level view
- ✅ Purely informational - no blocking
- ✅ Provides context for admin
- ✅ Helps identify potential maturity assessment errors
- ⚠️ Median might hide distribution issues
- ✅ "Above target" indicates potential over-training or incorrect maturity
- ✅ Simple, clear messaging

---

## Complete Data Structures

### Input Structure

```python
api_request = {
    "organization_id": int,
    "selected_strategies": [
        {
            "strategy_id": int,
            "strategy_name": str  # e.g., "Continuous Support", "Train the Trainer"
        }
    ],
    "pmt_context": {  # Optional
        "processes": str,  # e.g., "ISO 26262, V-model, Agile"
        "methods": str,    # e.g., "Scrum, Requirements Traceability"
        "tools": str       # e.g., "DOORS, JIRA, Enterprise Architect"
    } or None
}
```

**Validation:**
- `organization_id` must exist in database
- `selected_strategies` must not be empty
- Each strategy_id must be valid
- `pmt_context` optional but should be provided if strategies require PMT

---

### Output Structure (Complete Schema)

```python
api_response = {
    "success": bool,
    "data": {
        "main_pyramid": {
            "levels": {
                "1": {
                    "level_number": 1,
                    "level_name": "Knowing SE",
                    "grayed_out": bool,
                    "gray_reason": str or None,
                    "competencies": [
                        {
                            "competency_id": int,
                            "competency_name": str,
                            "target_level": int,
                            "status": "training_required" | "achieved",
                            "grayed_out": bool,

                            # If training_required:
                            "learning_objective": {
                                "level": int,
                                "level_name": str,
                                "objective_text": str,
                                "customized": bool,
                                "template_id": str
                            },

                            # If has_roles (high maturity):
                            "roles": [
                                {
                                    "role_id": int,
                                    "role_name": str,
                                    "users_needing": int,
                                    "total_users": int,
                                    "percentage": float,
                                    "median_level": int,
                                    "variance": float,
                                    "training_recommendation": {
                                        "method": str,
                                        "rationale": str,
                                        "cost_level": str,
                                        "icon": str
                                    }
                                }
                            ],

                            # If no roles (low maturity):
                            "organizational_stats": {
                                "total_users": int,
                                "users_needing_training": int,
                                "gap_percentage": float,
                                "median_level": int,
                                "mean_level": float,
                                "variance": float,
                                "training_recommendation": {
                                    "method": str,
                                    "rationale": str,
                                    "cost_level": str,
                                    "icon": str
                                }
                            },

                            # If achieved:
                            "message": str
                        }
                        # ... 15 more competencies (all 16 shown)
                    ]
                },
                "2": { ... },  # Similar structure
                "4": { ... },
                "6": { ... }
            },
            "metadata": {
                "organization_id": int,
                "organization_name": str,
                "has_roles": bool,
                "generation_timestamp": datetime,
                "pmt_customization": bool
            }
        },

        "train_the_trainer": {
            "enabled": bool,
            "competencies": [
                {
                    "competency_id": int,
                    "competency_name": str,
                    "level": 6,
                    "level_name": "Mastering SE",
                    "objective_text": str,
                    "customized": bool,
                    "users_needing": int,
                    "total_users": int,
                    "gap_percentage": float
                }
            ]
        } or None,

        "mastery_requirements_check": {
            "status": "OK" | "INADEQUATE",
            "severity": "NONE" | "MEDIUM" | "HIGH",
            "message": str,
            "affected": [
                {
                    "role_id": int,
                    "role_name": str,
                    "competency_id": int,
                    "competency_name": str,
                    "required_level": int,
                    "strategy_provides": int,
                    "gap": int
                }
            ] or [],
            "recommendations": [
                {
                    "action": str,  # "add_ttt_strategy", "accept_risk", etc.
                    "label": str,
                    "description": str,
                    "priority": "HIGH" | "MEDIUM" | "LOW"
                }
            ] or []
        },

        "strategy_validation": {
            "status": "INFORMATIONAL",
            "aligned_count": int,
            "below_count": int,
            "above_count": int,
            "message": str,
            "details": {
                "aligned": [str],  # Competency names
                "below_target": [
                    {
                        "name": str,
                        "current": int,
                        "target": int,
                        "gap": int
                    }
                ],
                "above_target": [
                    {
                        "name": str,
                        "current": int,
                        "target": int,
                        "surplus": int
                    }
                ]
            }
        }
    },
    "errors": [] or None
}
```

**Data Size Estimation:**
- Main pyramid: 64 competency cards (16 × 4 levels)
- Per competency: ~1-2 KB (with LO text and stats)
- Total response: ~100-200 KB (acceptable for modern web)
- Can be gzipped for transmission (~30-50 KB)

---

*Continued in Part 3...*
