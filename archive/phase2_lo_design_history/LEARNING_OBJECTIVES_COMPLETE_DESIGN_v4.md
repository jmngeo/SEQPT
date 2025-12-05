# Learning Objectives Generation - Complete Design Document (v4.1 - FINAL)
**Date**: November 4, 2025
**Version**: 4.1 - Complete Integration (Simplified & Phase-Appropriate)
**Status**: PRODUCTION-READY - Complete Implementation Specification
**Purpose**: Comprehensive reference document integrating holistic validation with phase-appropriate learning objective generation

---

## Document Overview

**What This Document Contains**:
- ✅ Complete algorithm: Gap analysis → Validation → Text generation
- ✅ Two pathways: Task-based (low maturity) and Role-based (high maturity)
- ✅ Multi-strategy handling with cross-coverage validation
- ✅ PMT customization (conditional, deep-only for 2 strategies)
- ✅ Rich output structure with priorities and recommendations
- ✅ Complete API specification (5 endpoints)
- ✅ Configuration system for future-proofing
- ✅ UI flow and component specifications

**Version History**:
- v1: Original design (October 2025) - Basic algorithm without validation
- v2: Added user distribution aggregation
- v3: Added validation layer and cross-strategy coverage
- v4: **Complete integration** with text generation and all components
- v4.1: **Simplified approach** - Admin confirmation instead of 70% threshold, PMT-only customization (no timeframe/benefits yet - Phase 3 will complete)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Core Design Principles](#core-design-principles)
3. [Critical Insights from Research](#critical-insights-from-research)
4. [Data Sources and Templates](#data-sources-and-templates)
5. [Complete Algorithm - Task-Based Pathway](#algorithm-1-task-based-organizations)
6. [Complete Algorithm - Role-Based Pathway](#algorithm-2-role-based-organizations)
7. [Learning Objective Text Generation (Step 8)](#step-8-learning-objective-text-generation)
8. [PMT Context System](#pmt-context-system)
9. [Configuration & Future-Proofing](#configuration--future-proofing)
10. [Complete Output Structure](#complete-output-structure)
11. [API Specification](#api-specification)
12. [UI Flow & Components](#ui-flow--components)
13. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

### What This System Does

The Learning Objectives Generation system creates **customized, SMART-compliant training objectives** for organizations based on:
1. **Competency assessment results** (Phase 2 Task 2 data)
2. **Selected training strategies** (Phase 1 selections)
3. **Role-specific requirements** (if organization has defined roles)
4. **Company context** (PMT - Processes, Methods, Tools - for specific strategies)

### Two Distinct Pathways

**Pathway Selection**: Determined by Phase 1 maturity assessment (`MATURITY_THRESHOLD = 3`)

**1. Task-Based Pathway** (Low Maturity: `maturity_level < 3`)
- Organizations with maturity level 1-2 from Phase 1 assessment
- No formal SE roles defined
- Uses 2-way comparison: Current Level vs Strategy Target
- Simpler processing, no validation layer needed
- Output: Basic learning objectives from templates

**2. Role-Based Pathway** (High Maturity: `maturity_level >= 3`)
- Organizations with maturity level 3-5 from Phase 1 assessment
- Defined SE roles with competency requirements
- Uses 3-way comparison: Current vs Strategy Target vs Role Requirement
- **8-step process** including validation layer
- Output: Validated objectives with priorities and recommendations

**Implementation Reference**:
- **Frontend Pathway Logic**: `Phase2TaskFlowContainer.vue:103-109`
- **Maturity Fetch**: `PhaseTwo.vue:114-121`
- **Threshold Constant**: `MATURITY_THRESHOLD = 3`
- **API Endpoint**: `GET /api/phase1/maturity/{org_id}/latest`

### Key Innovation: Holistic Strategy Validation

Unlike simple gap analysis, this system:
- ✅ Checks if multiple selected strategies TOGETHER cover organizational needs
- ✅ Makes holistic recommendations (not fragmented per-competency)
- ✅ Validates Phase 1 strategy selections against actual assessment data
- ✅ Only recommends strategy changes if SYSTEMATIC gaps exist

### Critical Design Decisions

1. **Median for Current Levels**: Robust to outliers, returns valid competency level
2. **Per-Role Analysis with User Distribution**: Preserves granularity, no premature aggregation
3. **Best-Fit Strategy Selection**: Uses fit score algorithm (not highest target) to pick strategy that best serves majority - prevents over-training
4. **Cross-Strategy Coverage**: Checks if multiple strategies together cover organizational needs
5. **Conditional PMT**: Only required for deep-customization strategies
6. **Template-Based Text**: No light customization, only deep for 2 strategies
7. **Training Priorities**: Multi-factor formula adapted for user distribution

---

## Core Design Principles

### 1. One Unified Plan Per Strategy
Generate ONE set of learning objectives per selected strategy for the entire organization (not per-user or per-role).

### 2. Latest Assessment Only
Use only the LATEST assessment per user, ignore retakes and test submissions.

### 3. Validation as Checkpoint
Learning objectives generation validates Phase 1 strategy selections and recommends adjustments if needed.

### 4. Holistic Over Fragmented
Make strategy-level recommendations based on aggregated data, not isolated per-competency decisions.

### 5. PMT When Needed
Request company context only for strategies that require deep customization.

### 6. Template Fidelity
Maintain SMART structure from validated templates, customize only for deep-customization strategies.

---

## Critical Insights from Research

### The 4 Core Competencies

**Special characteristics** (develop more indirectly through practice in other competencies):
1. Systems Thinking (ID: 1)
2. Lifecycle Consideration (ID: 4)
3. Customer / Value Orientation (ID: 5)
4. Systems Modelling and Analysis (ID: 6)

**Handling**:
- ✅ Process through full gap analysis (same as all other competencies)
- ✅ Generate learning objectives from templates
- ✅ Apply PMT customization if applicable
- ✅ Include in trainable competencies list
- ✅ Add informational note explaining indirect development nature
- ✅ Flag with `is_core: true` and include `core_note` field in output

**Note**: While these competencies develop more indirectly, they still benefit from structured learning objectives that guide their development through practice in technical activities.

### Training Levels Limitation

- **Internal training**: Only up to Level 4 ("Apply")
- **Level 6 ("Mastery")**: Only for "Train the SE-trainer" strategy, typically external
- **Valid levels**: 0, 1, 2, 4, 6 (no 3 or 5)

### Three-Way Comparison Scenarios (Role-Based Only)

**Scenario A**: Current < Archetype ≤ Role
- **Meaning**: Normal training pathway
- **Action**: Generate learning objective
- **User Impact**: Training needed and appropriate

**Scenario B**: Archetype ≤ Current < Role
- **Meaning**: Selected strategy insufficient for role needs
- **Action**: Count users, check if other strategies cover gap
- **User Impact**: May need supplementary modules or additional strategy

**Scenario C**: Archetype > Role
- **Meaning**: Strategy may exceed role requirements (over-training)
- **Action**: Flag if affects many competencies
- **User Impact**: Training may not be necessary for role

**Scenario D**: Current ≥ Both Targets
- **Meaning**: All targets already achieved
- **Action**: No training needed
- **User Impact**: Competency already at required level

---

## Data Sources and Templates

### 1. Strategy/Archetype Target Levels
**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

**Structure**:
```json
{
  "archetypeCompetencyTargetLevels": {
    "SE for managers": {
      "Systems Thinking": 4,
      "Communication": 4,
      "Decision Management": 4,
      "Requirements Definition": 1,
      ...
    },
    "Common basic understanding": {
      "Systems Thinking": 2,
      "Requirements Definition": 2,
      ...
    },
    "Needs-based project-oriented training": {
      "Requirements Definition": 4,
      "System Architecting": 4,
      ...
    },
    ...
  }
}
```

### 2. Learning Objective Templates
**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

**Structure**:
```json
{
  "learningObjectiveTemplates": {
    "Decision Management": {
      "1": "Participants know the main decision-making bodies in the company and can name the most important decisions for their respective scope.",
      "2": "Participants learn about decision support methods such as trade studies and can apply simple decision matrices.",
      "4": "Participants are able to prepare decisions for their relevant scopes or make them themselves and document the decision-making process accordingly.",
      "6": "Participants can evaluate decisions at a higher systemic level and define overarching decision-making processes for the organization."
    },
    "Requirements Definition": {
      "1": "Participants understand the importance of requirements...",
      "2": "...",
      "4": {
        "base_template": "Participants can define, analyze, and manage requirements...",
        "pmt_breakdown": {
          "process": "Requirements engineering process (e.g., ISO 29148)",
          "method": "Use case analysis, requirements traceability",
          "tool": "Requirements management tool (e.g., DOORS, Jama)"
        }
      },
      "6": "..."
    }
  }
}
```

**Note**: Some competencies have PMT breakdown for certain levels (used for deep customization).

### 3. Role Competency Requirements
**Database**: `role_competency_matrix` table

```sql
CREATE TABLE role_competency_matrix (
    id SERIAL PRIMARY KEY,
    role_cluster_id INTEGER NOT NULL,
    competency_id INTEGER NOT NULL,
    role_competency_value INTEGER,  -- Values: -100, 0, 1, 2, 4, 6
    organization_id INTEGER NOT NULL
);
```

**Special Values**:
- `-100`: Not applicable for this role
- `0`: Awareness level only
- `1, 2, 4, 6`: Standard competency levels

### 4. Current Competency Levels
**Source**: `user_se_competency_survey_results` table (Phase 2 Task 2)

**Aggregation**: Use MEDIAN of latest assessment per user (robust to outliers).

### 5. PMT Context (Conditional)
**Storage**: `organization_pmt_context` table (new)

```sql
CREATE TABLE organization_pmt_context (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    processes TEXT,      -- SE processes used (e.g., "ISO 26262, V-model")
    methods TEXT,        -- Methods employed (e.g., "Agile, Scrum")
    tools TEXT,          -- Tool landscape (e.g., "DOORS, JIRA, SysML")
    industry TEXT,       -- Industry context
    additional_context TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**When Required**:
- If "Needs-based project-oriented training" selected → PMT required
- If "Continuous support" selected → PMT required
- If validation recommends one of these → PMT required before adding
- Otherwise → PMT optional

### 6. Learning Objectives Guidelines (Reference Only)
**File**: `data/source/templates/learning_objectives_guidelines.json`

**Purpose**: Reference document for **Phase 3 enhancement**, NOT Phase 2 generation

This file defines full SMART criteria including:
- Timeframes ("At the end of the 2-day course...")
- Demonstration methods ("by conducting...")
- Benefit statements ("so that...")

**Important**: Phase 2 does NOT use these guidelines because we don't yet have:
- Module selection (timeframe unknown)
- Learning format (demonstration method unknown)
- Detailed benefit analysis (Phase 3 task)

See "Phase 2 vs Phase 3 Objectives" section below for details.

---

## Phase 2 vs Phase 3 Objectives

### What Phase 2 Generates (This Design)

**Learning objectives are CAPABILITY STATEMENTS**:
- Define what participants will be able to do
- Include company PMT context (for deep customization strategies)
- NO timeframes (modules not selected yet)
- NO demonstration methods (format not decided yet)
- NO benefit clauses (Phase 3 analysis)

**Example Phase 2 Output**:
```
"Participants are able to prepare decisions for their relevant scopes
using JIRA decision logs and document the decision-making process
according to ISO 26262 requirements."
```

**Characteristics**:
- ✅ Competency-appropriate action verbs ("are able to")
- ✅ Company tools ("JIRA decision logs")
- ✅ Company processes ("ISO 26262")
- ❌ No timeframe
- ❌ No "by doing X" clauses
- ❌ No "so that" benefits

### What Phase 3 Adds (Module Selection Phase)

**After module selection and learning format decision**, objectives become **FULL SMART STATEMENTS**:

**Example Phase 3 Enhanced Output**:
```
"At the end of the 2-day Decision Management workshop, participants
are able to prepare decisions for their relevant scopes using JIRA
decision logs by documenting decision rationale, alternatives considered,
and trade-off analyses according to ISO 26262 requirements, so that all
safety-critical decisions are traceable and auditable for ADAS system development."
```

**What Phase 3 Adds**:
- ✅ Timeframe: "At the end of the 2-day Decision Management workshop"
- ✅ Demonstration: "by documenting decision rationale, alternatives..."
- ✅ Benefit: "so that all safety-critical decisions are traceable..."
- ✅ Specific context: "for ADAS system development"

### Why This Separation?

| Information | Available in Phase 2? | Available in Phase 3? |
|-------------|---------------------|---------------------|
| What competencies need training | ✅ Yes (from assessment) | ✅ Yes |
| What level to reach | ✅ Yes (from strategy) | ✅ Yes |
| Company PMT context | ✅ Yes (from admin input) | ✅ Yes |
| **Module duration** | ❌ No (not selected yet) | ✅ Yes (after module selection) |
| **Learning format** | ❌ No (workshop? online? project?) | ✅ Yes (after format decision) |
| **Specific activities** | ❌ No (undecided) | ✅ Yes (from module design) |
| **Detailed benefits** | ❌ No (needs analysis) | ✅ Yes (after benefit mapping) |

### Template Fidelity in Phase 2

The templates in `se_qpt_learning_objectives_template_latest.json` are:
- ✅ Research-validated (from Marcel Niemeyer's thesis)
- ✅ Bloom's taxonomy aligned
- ✅ Competency-level appropriate
- ✅ Ready for Phase 2 (capability statements)
- ⚠️ Will be enhanced in Phase 3 (not replaced)

**Design Decision**: Keep Phase 2 simple and accurate. Let Phase 3 complete the full SMART transformation when the information is available.

---

## Pathway Determination

### Main Entry Point

The system automatically selects the appropriate processing pathway based on the organization's maturity level from Phase 1 assessment.

```python
def generate_learning_objectives(org_id, pmt_context=None, force=False):
    """
    Main entry point for learning objectives generation.

    Automatically determines pathway based on Phase 1 maturity assessment:
    - maturity_level >= 3 → ROLE_BASED pathway (3-way comparison + validation)
    - maturity_level < 3 → TASK_BASED pathway (2-way comparison, simple)

    Args:
        org_id: Organization identifier
        pmt_context: Optional PMT (Processes, Methods, Tools) context
        force: If True, regenerate even if objectives already exist

    Returns:
        Complete learning objectives structure with validation results
    """

    # Step 1: Check if objectives already exist
    if not force:
        existing = get_existing_learning_objectives(org_id)
        if existing:
            return existing

    # Step 2: Get Phase 1 maturity assessment
    # API: GET /api/phase1/maturity/{org_id}/latest
    try:
        maturity_response = requests.get(f'/api/phase1/maturity/{org_id}/latest')

        if maturity_response.data.exists:
            results = maturity_response.data.results
            strategy_inputs = results.get('strategyInputs', {})
            maturity_level = strategy_inputs.get('seProcessesValue', 5)
        else:
            # No maturity assessment found - default to role-based (high maturity)
            maturity_level = 5

    except Exception as e:
        # Error fetching maturity - default to role-based pathway
        logger.warning(f"Could not fetch maturity for org {org_id}: {e}")
        maturity_level = 5

    # Step 3: Determine pathway using threshold
    MATURITY_THRESHOLD = 3  # From Phase2TaskFlowContainer.vue:103

    if maturity_level >= MATURITY_THRESHOLD:
        # High maturity (3-5): Role-based pathway
        # - Organization has defined SE roles
        # - Uses 3-way comparison: Current vs Archetype vs Role Requirement
        # - Includes validation layer (Steps 4-6)
        # - Generates priorities and strategic recommendations
        logger.info(f"Org {org_id}: maturity={maturity_level} → ROLE_BASED pathway")
        return generate_role_based_objectives(org_id, pmt_context)

    else:
        # Low maturity (1-2): Task-based pathway
        # - No formal SE roles defined
        # - Uses 2-way comparison: Current vs Archetype Target
        # - Simple processing, no validation layer
        # - Basic learning objectives from templates
        logger.info(f"Org {org_id}: maturity={maturity_level} → TASK_BASED pathway")
        return generate_task_based_objectives(org_id, pmt_context)
```

### Pathway Selection Logic

| Maturity Level | SE Process Maturity | Pathway | Comparison | Validation |
|----------------|---------------------|---------|------------|------------|
| 1 | Initial/Ad-hoc | TASK_BASED | 2-way | No |
| 2 | Managed | TASK_BASED | 2-way | No |
| **3** | **Defined** | **ROLE_BASED** | **3-way** | **Yes** |
| 4 | Quantitatively Managed | ROLE_BASED | 3-way | Yes |
| 5 | Optimizing | ROLE_BASED | 3-way | Yes |

**Key Insight**: The threshold (maturity >= 3) aligns with organizations that have:
- ✅ Defined SE processes and roles
- ✅ Role-specific competency requirements
- ✅ Documented role-competency matrices
- ✅ Sufficient organizational maturity for strategic validation

**Frontend Implementation** (already implemented):
```javascript
// Phase2TaskFlowContainer.vue:103-109
const MATURITY_THRESHOLD = 3

const pathway = computed(() => {
  const isTaskBased = props.maturityLevel < MATURITY_THRESHOLD
  console.log('[Phase2 Flow] Maturity level:', props.maturityLevel,
              'Pathway:', isTaskBased ? 'TASK_BASED' : 'ROLE_BASED')
  return isTaskBased ? 'TASK_BASED' : 'ROLE_BASED'
})
```

---

## Strategy Classification: Dual-Track Processing

### Critical Design Decision: Expert Development vs Gap-Based Strategies

**Problem Identified**: The "Train the Trainer" strategy has fundamentally different characteristics from other strategies and causes significant issues in the validation system:

1. **Unique Target Levels**: Only strategy with Level 6 (mastery) for ALL 16 competencies
2. **Different Purpose**: Develops expert internal trainers, not organizational gap closure
3. **Validation Impact**: Creates 90-100% Scenario C (over-training) classifications
4. **Negative Fit Scores**: Always receives highly negative fit scores (-0.3 to -0.5)
5. **False Warnings**: System recommends removing it despite being a strategic choice

**Solution**: Dual-track processing that separates expert development strategies from gap-based strategies.

### Strategy Classification

```python
def classify_strategies(selected_strategies):
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

    Returns:
        (gap_based_strategies, expert_strategies)
    """
    EXPERT_STRATEGY_PATTERNS = [
        'Train the trainer',
        'Train the SE-Trainer',
        'Train the SE trainer'
    ]

    gap_based = []
    expert = []

    for strategy in selected_strategies:
        # Case-insensitive partial matching
        is_expert = any(
            pattern.lower() in strategy.strategy_name.lower()
            for pattern in EXPERT_STRATEGY_PATTERNS
        )

        if is_expert:
            expert.append(strategy)
        else:
            gap_based.append(strategy)

    return gap_based, expert
```

### Processing Tracks

**Track 1: Gap-Based Strategies** (Full 8-Step Algorithm)
- Strategies that close organizational competency gaps
- Uses 3-way comparison: Current vs Strategy Target vs Role Requirement
- Includes full validation layer (Steps 4-6)
- Generates priorities, warnings, and recommendations
- Subject to cross-strategy coverage analysis
- Produces validated learning objectives with strategic decisions

**Track 2: Expert Development Strategies** (Simple 2-Way Comparison)
- Strategies that develop expert trainers and internal capability
- Uses 2-way comparison: Current vs Strategy Target only
- **No validation layer** - not subject to gap analysis
- No scenario classification (A/B/C/D)
- No fit score calculation
- No cross-strategy coverage check
- Produces basic learning objectives from templates

### Modified Role-Based Algorithm Entry Point

```python
def generate_role_based_objectives(org_id, pmt_context=None):
    """
    Modified entry point with dual-track processing

    Steps:
    1. Get selected strategies
    2. Classify into gap-based vs expert development
    3. Process gap-based strategies with full validation (Steps 1-8)
    4. Process expert strategies with simple 2-way comparison
    5. Combine outputs with clear separation
    """
    # Get all selected strategies
    all_strategies = get_organization_strategies(org_id, selected_only=True)

    # Classify strategies
    gap_based_strategies, expert_strategies = classify_strategies(all_strategies)

    logger.info(f"Org {org_id}: {len(gap_based_strategies)} gap-based, "
                f"{len(expert_strategies)} expert strategies")

    # Track 1: Process gap-based strategies with FULL validation
    gap_based_objectives = {}
    validation_results = {}

    if gap_based_strategies:
        gap_based_objectives = process_gap_based_strategies_with_validation(
            org_id, gap_based_strategies, pmt_context
        )
        validation_results = gap_based_objectives.get('validation', {})

    # Track 2: Process expert strategies with SIMPLE comparison
    expert_objectives = {}

    if expert_strategies:
        expert_objectives = process_expert_strategies_simple(
            org_id, expert_strategies, pmt_context
        )

    # Combine with clear separation
    return {
        'pathway': 'ROLE_BASED',
        'organization_id': org_id,
        'generated_at': datetime.now().isoformat(),
        'total_users_assessed': gap_based_objectives.get('total_users_assessed', 0),
        'aggregation_method': 'median_per_role_with_user_distribution',
        'pmt_context_available': pmt_context is not None,

        # Gap-based strategies (with validation)
        'gap_based_training': {
            'strategy_count': len(gap_based_strategies),
            'validation': validation_results.get('strategy_validation'),
            'cross_strategy_coverage': validation_results.get('cross_strategy_coverage'),
            'strategic_decisions': validation_results.get('strategic_decisions'),
            'learning_objectives_by_strategy': gap_based_objectives.get('learning_objectives_by_strategy', {})
        },

        # Expert development strategies (no validation)
        'expert_development': {
            'strategy_count': len(expert_strategies),
            'note': 'Expert development strategies represent strategic capability investments '
                    'and are processed separately without gap-based validation. These typically '
                    'target mastery-level (Level 6) competencies for select individuals.',
            'learning_objectives_by_strategy': expert_objectives
        }
    }
```

### Simple Processing for Expert Strategies

```python
def process_expert_strategies_simple(org_id, expert_strategies, pmt_context):
    """
    Simple 2-way processing for expert development strategies

    No validation, no scenario classification, no fit scores.
    Just: current organizational level vs target level → generate objectives

    Returns:
        Dictionary of learning objectives by strategy (no validation context)
    """
    objectives = {}

    # Get latest assessments (all users, all roles)
    user_assessments = get_latest_assessments_per_user(org_id, 'all_roles')

    if not user_assessments:
        return {}

    for strategy in expert_strategies:
        strategy_objectives = {
            'strategy_name': strategy.strategy_name,
            'strategy_type': 'EXPERT_DEVELOPMENT',
            'target_level_all_competencies': 6,
            'purpose': 'Develop expert internal trainers with mastery-level competencies',
            'typical_audience': 'Select individuals (1-5 people)',
            'typical_delivery': 'External certification programs or advanced workshops',
            'note': 'This is a strategic capability investment, not subject to gap-based validation',
            'trainable_competencies': []
        }

        # Get strategy competency targets (all Level 6 for Train the trainer)
        competency_targets = get_strategy_competency_targets(strategy.id)

        for competency_id, target_level in competency_targets.items():
            # Calculate organizational median current level
            current_scores = [
                get_user_competency_score(user.id, competency_id)
                for user in user_assessments
            ]
            current_scores = [s for s in current_scores if s is not None]

            if not current_scores:
                continue

            current_level = calculate_median(current_scores)
            gap = target_level - current_level

            competency_name = get_competency_name(competency_id)

            if gap > 0:
                # Get template objective (no PMT customization - typically external)
                objective_text = get_template_objective(competency_name, target_level)

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
                    'note': f'Mastery-level training - Gap of {gap} levels from current organizational median'
                })
            else:
                # Target already achieved
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

        objectives[strategy.strategy_name] = strategy_objectives

    return objectives
```

### Why This Separation is Critical

| Aspect | Gap-Based Strategies | Expert Development |
|--------|---------------------|-------------------|
| **Purpose** | Close current competency gaps | Develop expert internal trainers |
| **Target Levels** | 1-4 (awareness to application) | 6 (mastery + teaching ability) |
| **Selection Basis** | Gap analysis + validation | Strategic leadership decision |
| **Audience** | All employees in specific roles | Select individuals (1-5) |
| **Validation Needed?** | YES - ensure coverage | NO - strategic choice |
| **Scenario Classification** | A/B/C/D based on 3-way comparison | Not applicable |
| **Fit Score** | Calculated for best-fit selection | Not calculated |
| **Cross-Strategy Coverage** | Yes - find best fit per competency | No - independent choice |
| **Delivery** | Internal or external courses | External certification programs |
| **Cost Model** | Scales with number of employees | High cost, few people |

### Configuration Addition

```json
{
  "strategy_classification": {
    "expert_development_patterns": [
      "Train the trainer",
      "Train the SE-Trainer",
      "Train the SE trainer"
    ],
    "description": "Strategies classified as expert development are processed without validation",
    "use_case_insensitive_matching": true
  },

  "expert_strategy_processing": {
    "use_validation": false,
    "use_scenario_classification": false,
    "use_fit_score_calculation": false,
    "comparison_type": "2-way",
    "use_pmt_customization": false,
    "description": "Expert strategies use simple current vs target comparison only"
  }
}
```

### Impact Summary

**Before Separation** (Problems):
- 90-100% Scenario C classifications for Train the Trainer
- Highly negative fit scores (-0.3 to -0.5)
- False "INADEQUATE" validation warnings
- System recommends removing expert strategies
- Contradicts strategic organizational decisions

**After Separation** (Benefits):
- Clean separation of purposes
- No false warnings or misleading recommendations
- Accurate validation metrics for gap-based strategies
- Clear communication to users
- Faster processing (skips validation for expert strategies)
- Future-proof for additional expert-level programs

**Organizations Already Using**: 4 organizations (IDs: 28, 29, 36, 38) currently have "Train the Trainer" selected.

---

## Algorithm 1: Task-Based Organizations

### Complete Algorithm (Low Maturity - No Roles)

```python
def generate_task_based_objectives(org_id):
    """
    2-WAY COMPARISON for organizations without defined roles
    Simpler pathway: Current Level vs Archetype Target only

    Steps:
    1. Get latest assessments
    2. Calculate organizational current levels (median)
    3. For each strategy, compare current vs archetype target
    4. Generate objectives from templates (no customization)
    5. Return basic output structure
    """
    # Step 1: Get LATEST assessment per user
    user_assessments = get_latest_assessments_per_user(org_id, 'unknown_roles')

    if len(user_assessments) == 0:
        return {'error': 'No assessments available'}

    # Step 2: Get selected strategies
    selected_strategies = get_organization_strategies(org_id)

    # Step 3: Generate objectives per strategy
    objectives_by_strategy = {}

    for strategy in selected_strategies:
        # Get archetype targets for this strategy
        archetype_targets = get_archetype_targets_for_strategy(strategy.name)

        strategy_objectives = {
            'strategy_name': strategy.name,
            'strategy_description': strategy.description,
            'core_competencies': [],
            'trainable_competencies': []
        }

        for competency in all_16_competencies:
            # Calculate organizational current level (median)
            current_scores = [
                get_user_competency_score(user.id, competency.id)
                for user in user_assessments
            ]
            current_scores = [s for s in current_scores if s is not None]
            current_level = calculate_median(current_scores) if current_scores else 0

            # Get archetype target
            archetype_target = archetype_targets.get(competency.name, 0)

            # Note: Core competencies (1, 4, 5, 6) are now processed like all other competencies
            # They go through gap analysis and get learning objectives, with an informational note added

            # 2-way comparison
            gap = archetype_target - current_level

            if gap > 0:
                # Generate objective from template
                objective_text = get_template_objective(competency.name, archetype_target)

                strategy_objectives['trainable_competencies'].append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'current_level': current_level,
                    'target_level': archetype_target,
                    'gap': gap,
                    'status': 'training_required',
                    'learning_objective': objective_text,
                    'comparison_type': '2-way'
                })
            else:
                strategy_objectives['trainable_competencies'].append({
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'current_level': current_level,
                    'target_level': archetype_target,
                    'gap': 0,
                    'status': 'target_achieved',
                    'comparison_type': '2-way'
                })

        objectives_by_strategy[strategy.name] = strategy_objectives

    return {
        'pathway': 'TASK_BASED',
        'organization_id': org_id,
        'total_users_assessed': len(user_assessments),
        'aggregation_method': 'median',
        'learning_objectives_by_strategy': objectives_by_strategy,
        'validation_note': 'Task-based pathway does not include strategy validation layer'
    }
```

---

## Algorithm 2: Role-Based Organizations

### Complete 8-Step Algorithm (High Maturity - With Roles)

```python
def generate_role_based_objectives(org_id):
    """
    3-WAY COMPARISON + VALIDATION for organizations with defined roles

    Steps:
    1. Get latest assessments and roles
    2. Analyze each role (per-competency scenario classification)
    3. Aggregate by user distribution (count users per scenario per strategy)
    4. Cross-strategy coverage check
    5. Strategy-level validation
    6. Make strategic decisions
    7. Generate unified objectives
    8. Generate learning objective text (with PMT if applicable)
    """
    # Note: Admin confirmation required in UI before calling this endpoint
    # No automatic completion rate check - admin decides if assessments are complete

    # Step 1: Get data
    user_assessments = get_latest_assessments_per_user(org_id, 'known_roles')
    organization_roles = get_organization_roles(org_id)
    selected_strategies = get_organization_strategies(org_id)

    # Check if PMT context exists (needed for deep customization)
    pmt_context = get_pmt_context(org_id)
    needs_pmt = check_if_pmt_needed(selected_strategies)

    # Step 2: Analyze all roles (PER-COMPETENCY SCENARIO CLASSIFICATION)
    role_analyses = analyze_all_roles(
        organization_roles, user_assessments, selected_strategies
    )

    # Step 3: Aggregate by user distribution
    competency_scenario_distributions = aggregate_by_user_distribution(role_analyses)

    # Step 4: Cross-strategy coverage check (BEST-FIT ALGORITHM)
    cross_strategy_coverage = check_cross_strategy_coverage(
        competency_scenario_distributions,
        selected_strategies,
        role_analyses  # Required for fit score calculation
    )

    # Step 5: Strategy-level validation
    strategy_validation = validate_strategy_adequacy(
        competency_scenario_distributions,
        cross_strategy_coverage
    )

    # Step 6: Make strategic decisions
    strategic_decisions = make_distribution_based_decisions(
        competency_scenario_distributions,
        cross_strategy_coverage,
        strategy_validation
    )

    # Step 7: Generate unified objectives (structure only)
    unified_objectives_structure = generate_unified_objectives_structure(
        strategic_decisions,
        role_analyses,
        selected_strategies,
        competency_scenario_distributions,
        cross_strategy_coverage
    )

    # Step 8: Generate learning objective TEXT
    learning_objectives_with_text = generate_learning_objective_text(
        unified_objectives_structure,
        selected_strategies,
        pmt_context
    )

    return {
        'pathway': 'ROLE_BASED',
        'organization_id': org_id,
        'generated_at': datetime.now().isoformat(),
        'total_users_assessed': len(user_assessments),
        'aggregation_method': 'median_per_role_with_user_distribution',
        'pmt_context_available': pmt_context is not None,
        'pmt_required': needs_pmt,
        'competency_scenario_distributions': competency_scenario_distributions,
        'cross_strategy_coverage': cross_strategy_coverage,
        'strategy_validation': strategy_validation,
        'strategic_decisions': strategic_decisions,
        'learning_objectives_by_strategy': learning_objectives_with_text
    }
```

### Steps 2-7 Implementation (Same as v3_INTEGRATED)

[Note: Steps 2-7 are identical to v3_INTEGRATED lines 257-779. For brevity, not repeated here. See v3_INTEGRATED for full implementation.]

**Key Points**:
- Step 2: Per-strategy analysis, stores `by_strategy` nested structure
- Step 3: User distribution aggregation, per-strategy scenario counts
- **Step 4: Best-fit strategy selection** (CRITICAL FIX)
  - Uses **fit score algorithm** instead of just picking highest target
  - Weighs: Scenario A (+1.0), Scenario D (+1.0), Scenario B (-2.0), Scenario C (-0.5)
  - Picks strategy that best serves MAJORITY of users
  - Prevents over-training (e.g., doesn't pick target=6 strategy if most roles only need 4)
- Step 5: Holistic validation across all 16 competencies
- Step 6: Context-aware recommendations (holistic, not fragmented)
- Step 7: Unified objectives structure with validation context

---

## Step 8: Learning Objective Text Generation

### Main Generation Function

```python
def generate_learning_objective_text(objectives_structure, selected_strategies, pmt_context):
    """
    Step 8: Generate actual SMART-compliant learning objective text

    Approach:
    - Deep customization: For "needs_based_project" and "continuous_support" only
    - No customization: For other 5 strategies (use templates as-is)
    - Templates: From se_qpt_learning_objectives_template_latest.json
    """
    objectives_with_text = {}

    for strategy_name, strategy_obj in objectives_structure.items():
        # Determine if this strategy needs deep customization
        requires_deep_customization = strategy_name in [
            'Needs-based project-oriented training',
            'Continuous support'
        ]

        # Note: Core competencies are now in trainable_competencies list
        # They are processed the same way with is_core flag and core_note field

        # Process trainable competencies
        trainable_comps_with_text = []
        for comp in strategy_obj.get('trainable_competencies', []):
            if comp.get('status') == 'target_achieved':
                # No training needed
                trainable_comps_with_text.append(comp)
                continue

            # Get base template
            template_data = get_template_objective_full(
                comp['competency_name'],
                comp['target_level']
            )

            # Check if template has PMT breakdown
            has_pmt_breakdown = isinstance(template_data, dict) and 'pmt_breakdown' in template_data

            if has_pmt_breakdown:
                base_template = template_data['base_template']
                pmt_breakdown = template_data['pmt_breakdown']
            else:
                base_template = template_data
                pmt_breakdown = None

            # Generate objective text
            if requires_deep_customization and pmt_context:
                # Deep customization with LLM
                objective_text = llm_deep_customize(
                    template=base_template,
                    pmt_context=pmt_context,
                    current_level=comp['current_level'],
                    target_level=comp['target_level'],
                    competency_name=comp['competency_name'],
                    pmt_breakdown=pmt_breakdown
                )
            else:
                # Use template as-is (no customization)
                objective_text = base_template

            # Calculate training priority
            priority = calculate_training_priority(
                gap=comp.get('gap', 0),
                max_role_requirement=comp.get('max_role_requirement', 0),
                scenario_B_percentage=comp.get('scenario_distribution', {}).get('B', 0) if 'scenario_distribution' in comp else 0
            )

            comp_with_text = {
                **comp,
                'learning_objective': objective_text,
                'base_template': base_template,
                'training_priority': priority
            }

            if pmt_breakdown:
                comp_with_text['pmt_breakdown'] = pmt_breakdown

            trainable_comps_with_text.append(comp_with_text)

        # Sort by priority (highest first)
        trainable_comps_with_text.sort(key=lambda x: x.get('training_priority', 0), reverse=True)

        # Calculate summary statistics
        summary = calculate_strategy_summary(
            core_comps_with_text,
            trainable_comps_with_text
        )

        objectives_with_text[strategy_name] = {
            'strategy_name': strategy_name,
            'priority': strategy_obj.get('priority', 'PRIMARY'),
            'trainable_competencies': trainable_comps_with_text,  # Now includes core competencies
            'summary': summary
        }

    return objectives_with_text
```

### Deep Customization with LLM

```python
def llm_deep_customize(template, pmt_context, current_level, target_level, competency_name, pmt_breakdown=None):
    """
    PMT-only customization for Phase 2 (Simplified)

    IMPORTANT: This is Phase 2 - we only add company-specific PMT references.
    Phase 3 (after module selection) will add:
    - Timeframes ("At the end of the 2-day workshop...")
    - Demonstration methods ("by conducting a simulation...")
    - Benefit statements ("so that they can...")

    This function ONLY:
    - Replaces generic tool/process names with company-specific ones
    - Keeps template structure exactly
    - Maintains capability statement format
    """
    # Build PMT context string
    pmt_text = f"""
Company Context:
- Tools: {pmt_context.tools}
- Processes: {pmt_context.processes}
- Industry: {pmt_context.industry}
"""

    # Build PMT breakdown context if available
    pmt_breakdown_text = ""
    if pmt_breakdown:
        pmt_breakdown_text = f"""
Expected PMT Coverage:
- Process: {pmt_breakdown.get('process', '')}
- Method: {pmt_breakdown.get('method', '')}
- Tool: {pmt_breakdown.get('tool', '')}
"""

    # Simplified LLM Prompt (Phase 2 only)
    prompt = f"""
You are customizing a Systems Engineering learning objective for Phase 2.

Base Template:
{template}

{pmt_text}

{pmt_breakdown_text}

Instructions (CRITICAL - follow exactly):
1. KEEP the template structure exactly (do not change sentence structure)
2. REPLACE generic tool/process names with company-specific ones from the context
3. DO NOT add timeframes (e.g., "At the end of...")
4. DO NOT add "so that" benefit statements
5. DO NOT add "by doing X" demonstration methods
6. Keep it as a capability statement (what participants can do)
7. Maximum 2 sentences
8. If no relevant PMT to add, return the template unchanged

Example:
Original: "Participants are able to manage requirements using a requirements database."
Customized: "Participants are able to manage requirements using DOORS according to ISO 29148 process."

Generate the PMT-customized objective (template structure only):
"""

    # Call LLM API (OpenAI, Anthropic, etc.)
    response = call_llm_api(prompt, max_tokens=200, temperature=0.3)

    # Validate response maintains template structure
    if not validate_template_structure(response, template):
        # Fallback to template if LLM output changed structure
        return template

    return response.strip()

def validate_template_structure(customized_text, original_template):
    """
    Validate that customization maintained template structure
    (Only PMT names changed, no timeframes/benefits added)
    """
    # Must have reasonable length
    if len(customized_text) < 30 or len(customized_text) > 400:
        return False

    # Should contain action verbs from template
    action_verbs = ['able to', 'can', 'will', 'understand', 'know', 'apply', 'demonstrate', 'evaluate']
    if not any(verb in customized_text.lower() for verb in action_verbs):
        return False

    # Should NOT have Phase 3 elements
    phase_3_indicators = [
        'at the end of',
        'so that',
        'in order to',
        'by conducting',
        'by creating',
        'by performing'
    ]
    if any(indicator in customized_text.lower() for indicator in phase_3_indicators):
        return False  # LLM added Phase 3 elements - reject

    return True
```

### Template Retrieval Functions

```python
def get_template_objective(competency_name, level):
    """
    Get template text for competency at specific level
    Returns string only (no PMT breakdown)
    """
    templates = load_learning_objective_templates()

    if competency_name not in templates['learningObjectiveTemplates']:
        return f"[Template missing for {competency_name}]"

    level_str = str(level)
    template_data = templates['learningObjectiveTemplates'][competency_name].get(level_str)

    if template_data is None:
        return f"[Template missing for {competency_name} level {level}]"

    # Handle both string templates and dict templates (with PMT breakdown)
    if isinstance(template_data, dict):
        return template_data.get('base_template', '[Template structure error]')
    else:
        return template_data

def get_template_objective_full(competency_name, level):
    """
    Get full template data (may include PMT breakdown)
    Returns either string or dict with base_template + pmt_breakdown
    """
    templates = load_learning_objective_templates()

    if competency_name not in templates['learningObjectiveTemplates']:
        return "[Template missing]"

    level_str = str(level)
    return templates['learningObjectiveTemplates'][competency_name].get(level_str, "[Template missing]")

def load_learning_objective_templates():
    """
    Load templates from JSON file
    """
    template_path = 'data/source/Phase 2/se_qpt_learning_objectives_template_latest.json'
    with open(template_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_archetype_targets_for_strategy(strategy_name):
    """
    Get competency target levels for a specific strategy
    """
    templates = load_learning_objective_templates()
    return templates['archetypeCompetencyTargetLevels'].get(strategy_name, {})
```

### Training Priority Calculation (Adapted for v4)

```python
def calculate_training_priority(gap, max_role_requirement, scenario_B_percentage):
    """
    Calculate training priority using multi-factor formula

    Factors:
    - Gap size: How many levels to train (40% weight)
    - Role criticality: How critical for role requirements (30% weight)
    - User urgency: Percentage of users in Scenario B (30% weight)

    Returns: Priority score (0-10 scale)
    """
    # Normalize gap (assume max gap is 6)
    gap_score = (gap / 6.0) * 10

    # Normalize role requirement (max is 6)
    role_score = (max_role_requirement / 6.0) * 10

    # Scenario B percentage is already 0-100, normalize to 0-10
    urgency_score = (scenario_B_percentage / 100.0) * 10

    # Weighted combination
    priority = (gap_score * 0.4) + (role_score * 0.3) + (urgency_score * 0.3)

    return round(priority, 2)

def calculate_strategy_summary(trainable_competencies):
    """
    Calculate summary statistics for a strategy

    Note: trainable_competencies now includes core competencies (flagged with is_core=True)
    """
    requiring_training = [c for c in trainable_competencies if c.get('status') == 'training_required']
    targets_achieved = [c for c in trainable_competencies if c.get('status') == 'target_achieved']
    core_competencies = [c for c in trainable_competencies if c.get('is_core', False)]

    # Calculate average gap (only for those requiring training)
    gaps = [c.get('gap', 0) for c in requiring_training]
    avg_gap = sum(gaps) / len(gaps) if gaps else 0

    # Estimate training duration (rough: 2 weeks per level of gap)
    total_gap = sum(gaps)
    estimated_weeks = total_gap * 2

    return {
        'total_competencies': len(trainable_competencies),
        'core_competencies_count': len(core_competencies),
        'trainable_competencies_count': len(trainable_competencies),
        'competencies_requiring_training': len(requiring_training),
        'competencies_targets_achieved': len(targets_achieved),
        'average_competency_gap': round(avg_gap, 2),
        'total_gap_levels': total_gap,
        'estimated_training_duration_weeks': estimated_weeks,
        'estimated_training_duration_readable': f"{estimated_weeks} weeks ({estimated_weeks // 4} months)" if estimated_weeks > 0 else "No training needed"
    }
```

---

## PMT Context System

### When PMT is Required

```python
def check_if_pmt_needed(selected_strategies):
    """
    Determine if PMT context is needed based on selected strategies
    """
    deep_customization_strategies = [
        'Needs-based project-oriented training',
        'Continuous support'
    ]

    for strategy in selected_strategies:
        if strategy.name in deep_customization_strategies:
            return True

    return False

def check_pmt_for_recommended_strategy(recommended_strategy_name):
    """
    Check if a recommended strategy would require PMT
    """
    deep_customization_strategies = [
        'Needs-based project-oriented training',
        'Continuous support'
    ]

    return recommended_strategy_name in deep_customization_strategies
```

### PMT Context Data Model

```python
class PMTContext:
    """
    Represents company PMT context
    """
    def __init__(self, organization_id, processes=None, methods=None, tools=None, industry=None, additional_context=None):
        self.organization_id = organization_id
        self.processes = processes or ""
        self.methods = methods or ""
        self.tools = tools or ""
        self.industry = industry or ""
        self.additional_context = additional_context or ""

    def is_complete(self):
        """
        Check if PMT context has minimum required information
        """
        # At minimum, should have tools or processes
        return bool(self.processes or self.tools)

    def to_dict(self):
        return {
            'processes': self.processes,
            'methods': self.methods,
            'tools': self.tools,
            'industry': self.industry,
            'additional_context': self.additional_context
        }

def get_pmt_context(org_id):
    """
    Retrieve PMT context from database
    """
    query = """
    SELECT processes, methods, tools, industry, additional_context
    FROM organization_pmt_context
    WHERE organization_id = %s
    ORDER BY updated_at DESC
    LIMIT 1
    """
    result = execute_query(query, [org_id])

    if not result:
        return None

    row = result[0]
    return PMTContext(
        organization_id=org_id,
        processes=row[0],
        methods=row[1],
        tools=row[2],
        industry=row[3],
        additional_context=row[4]
    )

def save_pmt_context(pmt_context):
    """
    Save or update PMT context
    """
    query = """
    INSERT INTO organization_pmt_context
    (organization_id, processes, methods, tools, industry, additional_context, updated_at)
    VALUES (%s, %s, %s, %s, %s, %s, NOW())
    ON CONFLICT (organization_id)
    DO UPDATE SET
        processes = EXCLUDED.processes,
        methods = EXCLUDED.methods,
        tools = EXCLUDED.tools,
        industry = EXCLUDED.industry,
        additional_context = EXCLUDED.additional_context,
        updated_at = NOW()
    """
    execute_query(query, [
        pmt_context.organization_id,
        pmt_context.processes,
        pmt_context.methods,
        pmt_context.tools,
        pmt_context.industry,
        pmt_context.additional_context
    ])
```

---

## Configuration & Future-Proofing

### Configuration File Structure

**File**: `config/learning_objectives_config.json`

```json
{
  "version": "4.0",
  "description": "Learning Objectives Generation Configuration - v4 Complete",

  "aggregation": {
    "per_role_method": "median",
    "available_options": ["median", "min", "max", "average"],
    "description": "How to aggregate current competency levels within each role"
  },

  "role_analysis": {
    "method": "per_role_with_user_distribution",
    "description": "Analyze each role separately, then aggregate by counting users in scenarios"
  },

  "validation": {
    "critical_gap_threshold": 60,
    "significant_gap_threshold": 20,
    "critical_competency_count": 3,
    "inadequate_gap_percentage": 40,
    "description": "Thresholds for strategy validation layer (Note: Assessment completion confirmed by admin, no automatic threshold)"
  },

  "customization": {
    "strategies_requiring_deep_customization": [
      "Needs-based project-oriented training",
      "Continuous support"
    ],
    "use_light_customization": false,
    "description": "Deep customization via LLM for specific strategies only"
  },

  "text_generation": {
    "llm_provider": "openai",
    "llm_model": "gpt-4",
    "max_tokens": 300,
    "temperature": 0.3,
    "fallback_to_template": true,
    "description": "LLM settings for deep customization"
  },

  "priority_calculation": {
    "gap_weight": 0.4,
    "role_criticality_weight": 0.3,
    "user_urgency_weight": 0.3,
    "description": "Training priority formula weights"
  },

  "features": {
    "include_core_competencies_in_output": true,
    "include_level_6_objectives": true,
    "calculate_training_priorities": true,
    "generate_summary_statistics": true,
    "enable_archetype_suitability_warnings": true,
    "description": "Feature flags for optional functionality"
  },

  "output": {
    "include_base_templates": true,
    "include_pmt_breakdown": true,
    "include_scenario_distributions": true,
    "include_validation_results": true,
    "description": "What to include in output structure"
  },

  "export": {
    "formats": ["pdf", "excel", "json"],
    "default_format": "pdf",
    "description": "Supported export formats"
  }
}
```

### Loading Configuration

```python
def load_config():
    """
    Load configuration from JSON file
    """
    config_path = 'config/learning_objectives_config.json'
    with open(config_path, 'r') as f:
        return json.load(f)

CONFIG = load_config()

# Use in code:
completion_threshold = CONFIG['validation']['minimum_completion_rate']
deep_customization_strategies = CONFIG['customization']['strategies_requiring_deep_customization']
```

---

## Complete Output Structure

### Role-Based Pathway Output

```json
{
  "pathway": "ROLE_BASED",
  "organization_id": 28,
  "organization_name": "TechCorp Systems GmbH",
  "generated_at": "2025-11-04T15:30:00Z",
  "total_users_assessed": 40,
  "completion_rate": 0.889,
  "aggregation_method": "median_per_role_with_user_distribution",
  "pmt_context_available": true,
  "pmt_required": true,

  "competency_scenario_distributions": {
    "11": {
      "competency_name": "Decision Management",
      "by_strategy": {
        "Needs-based project-oriented training": {
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
        }
      }
    }
  },

  "cross_strategy_coverage": {
    "11": {
      "competency_name": "Decision Management",
      "max_role_requirement": 6,
      "best_fit_strategy": "Needs-based project-oriented training",
      "best_fit_score": 0.65,
      "all_strategy_fit_scores": {
        "Needs-based project-oriented training": {
          "fit_score": 0.65,
          "scenario_counts": {"A": 30, "B": 3, "C": 2, "D": 5},
          "scenario_A_percentage": 75.0,
          "scenario_B_percentage": 7.5,
          "scenario_C_percentage": 5.0,
          "scenario_D_percentage": 12.5,
          "target_level": 4,
          "total_users": 40
        },
        "SE for managers": {
          "fit_score": -0.50,
          "scenario_counts": {"A": 10, "B": 20, "C": 0, "D": 10},
          "scenario_A_percentage": 25.0,
          "scenario_B_percentage": 50.0,
          "scenario_C_percentage": 0.0,
          "scenario_D_percentage": 25.0,
          "target_level": 2,
          "total_users": 40
        }
      },
      "has_real_gap": true,
      "gap_size": 2,
      "scenario_B_count": 3,
      "scenario_B_percentage": 7.5,
      "users_with_real_gap": [35, 36, 37],
      "gap_severity": "minor"
    }
  },

  "strategy_validation": {
    "status": "GOOD",
    "severity": "low",
    "message": "Minor gaps in 2 competencies, manageable with Phase 3 module selection",
    "gap_percentage": 12.5,
    "competency_breakdown": {
      "critical_gaps": [],
      "significant_gaps": [],
      "minor_gaps": [11, 15],
      "over_training": [],
      "well_covered": [2, 3, 7, 8, 9, 10, 12, 13, 14, 16]
    },
    "total_users_with_gaps": 8,
    "strategies_adequate": true,
    "requires_strategy_revision": false,
    "recommendation_level": "PROCEED_AS_PLANNED"
  },

  "strategic_decisions": {
    "overall_action": "PROCEED_AS_PLANNED",
    "overall_message": "Selected strategies are well-aligned with organizational needs",
    "per_competency_details": {
      "11": {
        "competency_name": "Decision Management",
        "scenario_B_percentage": 7.5,
        "scenario_B_count": 3,
        "has_real_gap": true,
        "gap_severity": "minor",
        "best_fit_strategy": "Needs-based project-oriented training",
        "best_fit_score": 0.65,
        "all_strategy_fit_scores": {
          "Needs-based project-oriented training": {
            "fit_score": 0.65,
            "scenario_A_percentage": 75.0,
            "scenario_B_percentage": 7.5,
            "target_level": 4
          },
          "SE for managers": {
            "fit_score": -0.50,
            "scenario_A_percentage": 25.0,
            "scenario_B_percentage": 50.0,
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
        "affected_users": 3
      }
    ]
  },

  "learning_objectives_by_strategy": {
    "Needs-based project-oriented training": {
      "strategy_name": "Needs-based project-oriented training",
      "priority": "PRIMARY",

      "trainable_competencies": [
        {
          "competency_id": 1,
          "competency_name": "Systems Thinking",
          "current_level": 2,
          "target_level": 4,
          "max_role_requirement": 6,
          "gap": 2,
          "status": "training_required",
          "training_priority": 4.25,
          "learning_objective": "Participants develop systems thinking through analyzing system boundaries, interfaces, and interactions in ISO 26262 compliant automotive systems.",
          "is_core": true,
          "core_note": "This core competency develops indirectly through training in other competencies. It will be strengthened through practice in requirements definition, system architecting, integration, and other technical activities.",
          "comparison_type": "3-way",
          "scenario_distribution": {
            "A": 75.0,
            "B": 7.5,
            "C": 5.0,
            "D": 12.5
          }
        },
        {
          "competency_id": 11,
          "competency_name": "Decision Management",
          "current_level": 2,
          "target_level": 4,
          "max_role_requirement": 6,
          "gap": 2,
          "status": "training_required",
          "training_priority": 4.25,
          "learning_objective": "Participants are able to prepare decisions for their relevant scopes using JIRA decision logs and document the decision-making process according to ISO 26262 requirements.",
          "base_template": "Participants are able to prepare decisions for their relevant scopes or make them themselves and document the decision-making process accordingly.",
          "pmt_breakdown": {
            "process": "ISO 26262 decision documentation",
            "method": "Trade-off analysis, decision matrices",
            "tool": "JIRA (decision tracking), Confluence (documentation)"
          },
          "comparison_type": "3-way",
          "scenario_distribution": {
            "A": 75.0,
            "B": 7.5,
            "C": 5.0,
            "D": 12.5
          },
          "gap_severity": "minor",
          "users_requiring_training": 33,
          "note": "Consider supplementary modules - 7.5% of users need higher levels"
        },
        {
          "competency_id": 7,
          "competency_name": "Communication",
          "current_level": 3,
          "target_level": 4,
          "max_role_requirement": 4,
          "gap": 1,
          "status": "training_required",
          "training_priority": 3.8,
          "learning_objective": "Participants are able to communicate constructively and efficiently in interdisciplinary teams and empathetically address the needs and ideas of colleagues and cooperation partners.",
          "base_template": "Participants are able to communicate constructively and efficiently in interdisciplinary teams and empathetically address the needs and ideas of colleagues and cooperation partners.",
          "comparison_type": "3-way",
          "scenario_distribution": {
            "A": 82.5,
            "B": 0,
            "C": 7.5,
            "D": 10.0
          },
          "gap_severity": "none",
          "users_requiring_training": 33
        },
        {
          "competency_id": 12,
          "competency_name": "Information Management",
          "current_level": 2,
          "target_level": 2,
          "max_role_requirement": 2,
          "gap": 0,
          "status": "target_achieved",
          "note": "Both archetype and role targets achieved. No training needed."
        }
      ],

      "summary": {
        "total_competencies": 16,
        "core_competencies_count": 4,
        "trainable_competencies_count": 16,
        "competencies_requiring_training": 10,
        "competencies_targets_achieved": 6,
        "average_competency_gap": 1.6,
        "total_gap_levels": 13,
        "estimated_training_duration_weeks": 26,
        "estimated_training_duration_readable": "26 weeks (6 months)"
      }
    }
  }
}
```

---

## API Specification

### Endpoint 1: Generate Learning Objectives

**POST** `/api/learning-objectives/generate`

**Description**: Main endpoint for generating learning objectives with full validation.

**Request**:
```json
{
  "organization_id": 28,
  "pmt_context": {
    "processes": "ISO 26262 for automotive safety, V-model for development",
    "methods": "Agile with 2-week sprints, requirements traceability",
    "tools": "DOORS for requirements, JIRA for project management, Enterprise Architect for SysML",
    "industry": "Automotive embedded systems",
    "additional_context": "Focus on ADAS and autonomous driving"
  },
  "force": false
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    // Complete output structure (see above)
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "error": "No assessment data available",
  "message": "No users have completed competency assessments for this organization"
}
```

**Error Response** (400 Bad Request - PMT Missing):
```json
{
  "success": false,
  "error": "PMT context required",
  "message": "Selected strategies require company PMT context",
  "strategies_requiring_pmt": [
    "Needs-based project-oriented training"
  ],
  "pmt_required": true
}
```

---

### Endpoint 2: Quick Validation Check

**GET** `/api/learning-objectives/<int:org_id>/validation`

**Description**: Quick check of strategy adequacy without generating full objectives.

**Response** (200 OK):
```json
{
  "organization_id": 28,
  "validation_timestamp": "2025-11-04T15:30:00Z",
  "strategy_validation": {
    "status": "GOOD",
    "severity": "low",
    "message": "Minor gaps in 2 competencies, manageable with Phase 3 module selection",
    "gap_percentage": 12.5,
    "strategies_adequate": true,
    "requires_strategy_revision": false
  },
  "cross_strategy_coverage": {
    "11": {
      "competency_name": "Decision Management",
      "has_real_gap": true,
      "gap_severity": "minor",
      "scenario_B_percentage": 7.5
    }
  }
}
```

---

### Endpoint 3: Update PMT Context

**PATCH** `/api/learning-objectives/<int:org_id>/pmt-context`

**Description**: Update company PMT context and optionally regenerate objectives.

**Request**:
```json
{
  "processes": "Updated ISO 26262 workflow",
  "methods": "Updated agile practices",
  "tools": "Added new tool: Polarion",
  "industry": "Automotive embedded systems",
  "additional_context": "New focus on battery management systems",
  "regenerate": true
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "PMT context updated successfully",
  "regenerated": true,
  "data": {
    // Full learning objectives output (if regenerate=true)
  }
}
```

---

### Endpoint 4: Add Recommended Strategy

**POST** `/api/learning-objectives/<int:org_id>/add-strategy`

**Description**: Add a strategy recommended by validation layer.

**Request**:
```json
{
  "strategy_name": "Continuous support",
  "pmt_context": {
    // Required if strategy needs deep customization
    "processes": "...",
    "methods": "...",
    "tools": "..."
  }
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Strategy added successfully",
  "pmt_required": true,
  "pmt_provided": true,
  "regenerated_objectives": {
    // Updated learning objectives including new strategy
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "error": "PMT context required",
  "message": "This strategy requires company PMT context for deep customization",
  "pmt_required": true
}
```

---

### Endpoint 5: Export Learning Objectives

**GET** `/api/learning-objectives/<int:org_id>/export`

**Description**: Export generated learning objectives in various formats.

**Query Parameters**:
- `format`: `pdf` | `excel` | `json` (required)
- `strategy`: Filter by specific strategy name (optional)
- `include_validation`: Include validation results (default: true)

**Examples**:
- `/api/learning-objectives/28/export?format=pdf`
- `/api/learning-objectives/28/export?format=excel&strategy=Needs-based project-oriented training`
- `/api/learning-objectives/28/export?format=json&include_validation=false`

**Response**: File download

**PDF Structure**:
1. Executive Summary
2. Strategy Validation Results
3. Per-Strategy Sections
   - Core Competencies (with notes)
   - Trainable Competencies (prioritized list)
   - Learning Objectives (full SMART text)
   - PMT Breakdown (if applicable)
4. Appendix: Scenario Distributions

**Excel Structure**:
- Sheet 1: Summary & Validation
- Sheet 2-N: One sheet per strategy with competency details
- Filterable columns: Competency, Status, Priority, Gap, etc.

---

## UI Flow & Components

### Complete User Flow

```
1. Phase 1: Strategy Selection
   ├─> User selects strategies
   ├─> System checks: "Do any strategies need PMT?"
   └─> If yes: Show optional PMT form (can skip, provide later)

2. Phase 2: Competency Assessment
   ├─> Users complete assessments
   └─> Admin monitors completion (dashboard shows progress)

3. Pre-Generation Validation (NEW)
   ├─> Button: "Check Strategy Adequacy"
   ├─> Quick API call: GET /validation
   ├─> Shows modal with results:
   │   ├─ "Strategy selection looks GOOD" (green)
   │   ├─ "Minor gaps detected" (yellow)
   │   └─ "Significant gaps found - review recommended" (red)
   └─> Allows admin to decide: continue or review strategies

4. PMT Context (Conditional)
   ├─> If deep-customization strategy selected AND no PMT yet:
   │   ├─ Show PMT form modal
   │   ├─ Sections: Processes, Methods, Tools, Industry, Additional
   │   └─ Validate minimum content (at least tools or processes)
   └─> If PMT already exists: Show "Update PMT" button

5. Generate Learning Objectives
   ├─> Confirmation Dialog: "Have all users completed their competency assessments?"
   │   ├─ [Yes, Generate Objectives] → Proceed
   │   └─ [No, Not Yet] → Return to assessment monitoring
   ├─> Prerequisites check:
   │   ├─ PMT available (if required)?
   │   └─ Strategies selected?
   ├─> Loading screen: "Analyzing competency gaps and validating strategies..."
   └─> Navigate to results page

6. Review Results
   ├─> Strategy Tabs (one per selected strategy)
   ├─> Validation Summary Card (top of page)
   │   ├─ Status badge (GOOD/ACCEPTABLE/INADEQUATE)
   │   ├─ Gap percentage
   │   ├─ Recommendation (if any)
   │   └─ "Add Recommended Strategy" button (if applicable)
   ├─> For each strategy tab:
   │   ├─ Summary Statistics Card
   │   │   ├─ Competencies requiring training: 8
   │   │   ├─ Average gap: 1.6 levels
   │   │   ├─ Estimated duration: 26 weeks
   │   │   └─ Total users: 40
   │   ├─ Core Competencies Section (collapsible)
   │   │   └─ Each with note about indirect development
   │   └─ Trainable Competencies Section
   │       ├─ Sorted by priority (highest first)
   │       ├─ Color-coded status badges:
   │       │   ├─ Green: Target achieved
   │       │   ├─ Blue: Training required
   │       │   └─ Yellow: Consider supplementary
   │       └─ Expandable cards showing:
   │           ├─ Current → Target visualization
   │           ├─ Full SMART objective text
   │           ├─ Priority score
   │           ├─ Users affected
   │           ├─ PMT breakdown (if applicable)
   │           └─ Scenario distribution chart
   └─> Action Buttons:
       ├─ "Export to PDF"
       ├─ "Export to Excel"
       ├─ "Update PMT and Regenerate"
       └─ "Approve and Continue to Phase 3"

7. Add Recommended Strategy (Conditional)
   ├─> If validation recommends additional strategy:
   │   ├─> Modal: "Add 'Continuous support' strategy?"
   │   ├─> Shows rationale
   │   ├─> If strategy needs PMT:
   │   │   └─> Show PMT form within modal
   │   └─> "Add and Regenerate" button
   └─> Regenerates objectives with new strategy
```

### Key UI Components

#### 1. PMT Context Form
```jsx
<PMTContextForm>
  <Section label="Processes">
    <TextArea
      placeholder="e.g., ISO 26262, V-model, Agile development process"
      rows={3}
    />
  </Section>

  <Section label="Methods">
    <TextArea
      placeholder="e.g., Scrum, requirements traceability, trade-off analysis"
      rows={3}
    />
  </Section>

  <Section label="Tools">
    <TextArea
      placeholder="e.g., DOORS for requirements, JIRA for project management, SysML tools"
      rows={3}
      required={true}
    />
  </Section>

  <Section label="Industry Context">
    <Input
      placeholder="e.g., Automotive embedded systems, Medical devices"
    />
  </Section>

  <Section label="Additional Context">
    <TextArea
      placeholder="Any other relevant company-specific information"
      rows={2}
    />
  </Section>

  <Actions>
    <Button type="secondary">Save for Later</Button>
    <Button type="primary">Save and Continue</Button>
  </Actions>
</PMTContextForm>
```

#### 2. Validation Summary Card
```jsx
<ValidationSummaryCard status={validationStatus}>
  <StatusBadge variant={status} />
  <Message>{validationMessage}</Message>

  <MetricsRow>
    <Metric label="Gap Percentage" value="12.5%" />
    <Metric label="Competencies with Gaps" value="2 / 16" />
    <Metric label="Users Affected" value="8" />
  </MetricsRow>

  {recommendations.length > 0 && (
    <RecommendationsSection>
      <Recommendation
        type={rec.type}
        message={rec.message}
        action={rec.action}
      />
    </RecommendationsSection>
  )}
</ValidationSummaryCard>
```

#### 3. Competency Detail Card
```jsx
<CompetencyCard priority={comp.training_priority}>
  <Header>
    <Title>{comp.competency_name}</Title>
    <PriorityBadge score={comp.training_priority} />
    <StatusBadge status={comp.status} />
  </Header>

  <LevelComparison>
    <LevelBar
      current={comp.current_level}
      target={comp.target_level}
      maxRole={comp.max_role_requirement}
    />
  </LevelComparison>

  <MainContent>
    <LearningObjective>
      {comp.learning_objective}
    </LearningObjective>

    {comp.pmt_breakdown && (
      <PMTBreakdown>
        <Item label="Process">{comp.pmt_breakdown.process}</Item>
        <Item label="Method">{comp.pmt_breakdown.method}</Item>
        <Item label="Tool">{comp.pmt_breakdown.tool}</Item>
      </PMTBreakdown>
    )}
  </MainContent>

  <MetaInfo>
    <InfoChip label="Gap" value={comp.gap} />
    <InfoChip label="Users Requiring Training" value={comp.users_requiring_training} />
    <InfoChip label="Estimated Duration" value="4 weeks" />
  </MetaInfo>

  {comp.scenario_distribution && (
    <ScenarioChart data={comp.scenario_distribution} />
  )}

  {comp.note && (
    <Note>{comp.note}</Note>
  )}
</CompetencyCard>
```

#### 4. Export Dialog
```jsx
<ExportDialog>
  <FormatSelector>
    <RadioButton value="pdf" label="PDF Report" icon="📄" />
    <RadioButton value="excel" label="Excel Workbook" icon="📊" />
    <RadioButton value="json" label="JSON Data" icon="{ }" />
  </FormatSelector>

  <FilterSection>
    <Checkbox label="Include Validation Results" checked={true} />
    <Select label="Strategy Filter" options={strategies} />
  </FilterSection>

  <Actions>
    <Button type="secondary">Cancel</Button>
    <Button type="primary" onClick={handleExport}>
      Download {selectedFormat.toUpperCase()}
    </Button>
  </Actions>
</ExportDialog>
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
**Task-Based Pathway + Data Setup**

- [ ] Database schema updates
  - [ ] `organization_pmt_context` table
  - [ ] Ensure `role_competency_matrix` is populated
- [ ] Load template files
  - [ ] `se_qpt_learning_objectives_template_latest.json`
  - [ ] Verify archetype targets and templates
- [ ] Implement task-based algorithm
  - [ ] Latest assessment query
  - [ ] Median calculation
  - [ ] Template retrieval
  - [ ] Basic output structure
- [ ] Test with Organization 28 (task-based)

### Phase 2: Role-Based Core (Weeks 3-5)
**Steps 2-3: Analysis & Aggregation**

- [ ] Implement Step 2: analyze_all_roles()
  - [ ] Per-role median calculation
  - [ ] Per-strategy scenario classification
  - [ ] Nested `by_strategy` data structure
- [ ] Implement Step 3: aggregate_by_user_distribution()
  - [ ] User counting per scenario per strategy
  - [ ] Handle multi-role users (sets)
  - [ ] Percentage calculations
- [ ] Test scenario classification logic
- [ ] Verify user distribution counts

### Phase 3: Validation Layer (Weeks 6-7)
**Steps 4-5: Cross-Strategy Coverage & Validation**

- [ ] Implement Step 4: check_cross_strategy_coverage()
  - [ ] Identify best strategy per competency
  - [ ] Calculate real gap users (Scenario B of best strategy)
  - [ ] Gap severity classification
- [ ] Implement Step 5: validate_strategy_adequacy()
  - [ ] Aggregate Scenario B across competencies
  - [ ] Apply thresholds (critical/significant/minor)
  - [ ] Generate validation status
- [ ] Test validation with different scenarios
  - [ ] Excellent strategy selection
  - [ ] Gaps requiring supplementary modules
  - [ ] Inadequate strategy selection

### Phase 4: Recommendations & Structure (Week 8)
**Steps 6-7: Decisions & Objectives Structure**

- [ ] Implement Step 6: make_distribution_based_decisions()
  - [ ] Holistic recommendations
  - [ ] Supplementary module guidance
  - [ ] Strategy addition suggestions
- [ ] Implement Step 7: generate_unified_objectives_structure()
  - [ ] Per-strategy output format
  - [ ] Include all validation context
  - [ ] Priority calculation (structure only)
- [ ] Test complete flow without text generation

### Phase 5: Text Generation (Weeks 9-10)
**Step 8: Learning Objective Text**

- [ ] Implement template retrieval functions
  - [ ] `get_template_objective()`
  - [ ] `get_template_objective_full()`
  - [ ] Handle PMT breakdown
- [ ] Implement LLM integration
  - [ ] OpenAI API setup
  - [ ] `llm_deep_customize()` function
  - [ ] SMART validation
  - [ ] Fallback to template
- [ ] Implement priority calculation
  - [ ] Multi-factor formula
  - [ ] Normalization
- [ ] Implement summary statistics
  - [ ] Duration estimation
  - [ ] Competency counts
- [ ] Test with and without PMT

### Phase 6: PMT System (Week 11)
**Conditional PMT Context**

- [ ] Implement PMT data model
  - [ ] `PMTContext` class
  - [ ] Database queries
- [ ] Implement PMT checking logic
  - [ ] `check_if_pmt_needed()`
  - [ ] `check_pmt_for_recommended_strategy()`
- [ ] Test PMT conditional flow
  - [ ] With deep-customization strategy
  - [ ] Without deep-customization strategy
  - [ ] Adding recommended strategy requiring PMT

### Phase 7: API Implementation (Week 12)
**All 5 Endpoints**

- [ ] Endpoint 1: POST /generate
  - [ ] Request validation
  - [ ] PMT requirement checking
  - [ ] Complete algorithm execution
  - [ ] Error handling
- [ ] Endpoint 2: GET /validation
  - [ ] Quick validation only
  - [ ] Lightweight response
- [ ] Endpoint 3: PATCH /pmt-context
  - [ ] Update PMT
  - [ ] Optional regeneration
- [ ] Endpoint 4: POST /add-strategy
  - [ ] Strategy addition
  - [ ] PMT check
  - [ ] Regeneration
- [ ] Endpoint 5: GET /export
  - [ ] PDF generation
  - [ ] Excel generation
  - [ ] JSON download
- [ ] API testing & documentation

### Phase 8: UI Development (Weeks 13-14)
**Frontend Components**

- [ ] PMT Context Form
  - [ ] Multi-section layout
  - [ ] Validation
  - [ ] Save/update functionality
- [ ] Validation Summary Card
  - [ ] Status visualization
  - [ ] Metrics display
  - [ ] Recommendations
- [ ] Learning Objectives Dashboard
  - [ ] Strategy tabs
  - [ ] Summary statistics
  - [ ] Competency cards (collapsible)
- [ ] Competency Detail Card
  - [ ] Level comparison visualization
  - [ ] SMART objective display
  - [ ] PMT breakdown
  - [ ] Scenario chart
  - [ ] Priority badge
- [ ] Export Dialog
  - [ ] Format selection
  - [ ] Filtering options
- [ ] Strategy Addition Flow
  - [ ] Modal for recommended strategy
  - [ ] PMT input (if needed)

### Phase 9: Integration & Testing (Week 15)
**End-to-End Testing**

- [ ] Test complete task-based flow
- [ ] Test complete role-based flow
- [ ] Test PMT conditional logic
- [ ] Test validation layer
- [ ] Test text generation
  - [ ] With deep customization
  - [ ] Without customization
- [ ] Test all 5 API endpoints
- [ ] Test UI flows
- [ ] Performance testing
- [ ] Error scenario testing

### Phase 10: Deployment Prep (Week 16)
**Production Readiness**

- [ ] Configuration finalization
- [ ] LLM API key setup
- [ ] Database migrations
- [ ] Documentation
  - [ ] API documentation
  - [ ] User guide
  - [ ] Admin guide
- [ ] Training for users
- [ ] Deployment to production

---

## Summary: What Makes v4.1 Complete

**v4.1 is simplified and phase-appropriate**:

✅ **From v3_INTEGRATED**:
- Complete validation layer (Steps 4-6)
- Multi-strategy handling with cross-coverage
- Holistic strategy validation
- User distribution aggregation

✅ **From Original Design**:
- Learning objective text generation (Step 8)
- Template structure and file paths
- PMT context system
- Rich output structure
- Training priorities
- Configuration system

✅ **New in v4**:
- Conditional PMT (only when needed)
- No light customization (simplified to deep-only)
- v4-adapted priority formula
- 5 API endpoints
- Complete UI specifications
- Circular dependency handling (validation → recommendation → PMT)

✅ **Simplified in v4.1** (Based on User Feedback):
- **Admin confirmation** instead of 70% completion threshold (more practical)
- **PMT-only customization** - no timeframes, benefits, or demonstrations (Phase 3 will add these)
- **Template fidelity** - capability statements only, not full SMART yet
- **Phase-appropriate design** - only what can be determined in Phase 2
- **Clear separation** between Phase 2 (capability statements) and Phase 3 (full SMART objectives)

**Key Insight**: Phase 2 generates **capability statements** with company PMT context. Phase 3 will enhance these to full SMART objectives after module selection and format decision.

**Status**: ✅ **PRODUCTION-READY** - Complete, validated, phase-appropriate, implementation-ready design.

---

*End of Document - v4.1 Simplified & Phase-Appropriate Design*
*Total Algorithm Steps: 8 (Task-based: 5, Role-based: 8)*
*Last Updated: November 4, 2025*
