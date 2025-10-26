# Phase 2 Task 3: Generate Learning Objectives - Complete Design Document

**Date**: 2025-10-26
**Status**: Awaiting advisor approval before implementation
**Version**: 1.0

---

## Table of Contents
1. [Overview](#overview)
2. [Design Discussion Summary](#design-discussion-summary)
3. [Key Insights from Marcel's Thesis](#key-insights-from-marcels-thesis)
4. [Data Sources](#data-sources)
5. [Learning Objective Generation Logic](#learning-objective-generation-logic)
6. [Configuration & Future-Proofing](#configuration--future-proofing)
7. [API Design](#api-design)
8. [UI Flow](#ui-flow)
9. [Design Decisions Log](#design-decisions-log)
10. [Open Questions for Advisor](#open-questions-for-advisor)

---

## Overview

**Objective**: Generate company-specific learning objectives based on:
- Selected training strategies from Phase 1
- Aggregated competency assessment data from Phase 2
- Role-specific competency requirements
- Company-specific PMT (Processes, Methods, Tools) context

**Key Challenge**: Perform three-way comparison between:
1. **Current competency levels** (from assessments)
2. **Strategy/Archetype target levels** (from selected strategy)
3. **Role target levels** (from role-competency matrix)

---

## Design Discussion Summary

### Initial Understanding

The learning objectives generation process integrates multiple data sources:
- **7 training strategies** with their qualification goals (from Phase 1)
- **16 competencies** with 4 levels each (1, 2, 4, 6)
- **Archetype-competency target levels** mapping strategies to target competency levels
- **Learning objective templates** for each competency at each level
- **RAG LLM customization** to adapt templates to company context

### Critical Discovery: Marcel's Thesis Note

Found important guidance in "Learning objectives- note from Marcel's thesis.txt" that fundamentally shaped the design:

**INSIGHT 1: The 4 Core Competencies Cannot Be Directly Trained**
- Systems Thinking
- Systems Modelling and Analysis
- Lifecycle Consideration
- Customer / Value Orientation

These improve indirectly through training in the other 12 competencies.

**INSIGHT 2: Internal Training Only Up to Level 4**
- Training within a company only makes sense up to level 4 ("Apply")
- Level 6 ("Mastery") is only for "Train the trainer" strategy and is external

**INSIGHT 3: Three-Way Comparison Logic**
Must compare:
- Current competency level
- Archetype target level
- Role maximum required level

Four scenarios emerge from this comparison (detailed in logic section below).

**INSIGHT 4: PMT Division**
Training should be divided into:
- Process & Method training
- Tool training

---

## Key Insights from Marcel's Thesis

### The Three-Way Comparison Scenarios

From Marcel's thesis section 4.4.2:

**Scenario A**: Current < Archetype Target ≤ Role Target
- **Action**: Generate learning objective for this archetype
- **Reason**: Training is needed and appropriate for the role

**Scenario B**: Archetype Target ≤ Current < Role Target
- **Action**: No training in this archetype (already achieved)
- **Recommendation**: Consider qualifying under a different (higher-level) archetype

**Scenario C**: Archetype Target > Role Maximum
- **Action**: Question if this archetype is appropriate
- **Recommendation**: Selecting an archetype with lower targets might make more sense

**Scenario D**: Current ≥ Archetype Target AND Current ≥ Role Target
- **Action**: No training needed
- **Reason**: All targets already achieved

### Example from Thesis (Figure 4-5 Spider Web Chart)

**Context**: "Common Basic Understanding" archetype for "Systemtechniker" (System Engineer) role

**Technical Competencies shown**:
- Anforderungsmanagement (Requirements Definition)
- Systemarchitekturgestaltung (System Architecting)
- Integration, Verification & Validation
- Betrieb, Service und Instandhaltung (Operation and Support)
- Agile Methodenkompetenz (Agile Methods)

**Three lines on chart**:
- Green (Zielreifegrad): Role target level
- Blue (Aktuelle Reife): Current level from assessment
- Yellow (Zielreife Archetyp): Archetype target level

**Analysis from thesis**:
- "Operation and Support" & "Integration, Verification & Validation": Current < Archetype target → **Training required**
- "System Architecting": Archetype target already reached → **No training needed**
- "Agile Methods": Exceeds archetype target → **Question if training needed**
- "Requirements Definition": Archetype achieved but role target higher → **Consider different archetype**

---

## Data Sources

### 1. Training Strategy Definitions
**File**: `data/source/strategy_definitions.json`

7 strategies with their descriptions:
1. SE for managers
2. Common basic understanding
3. Orientation in pilot project
4. Certification
5. Continuous support
6. Needs-based project-oriented training
7. Train the SE-trainer

**Note**: Strategy and Archetype are the same concept. Reference files use "Archetype" but our app uses "Strategy".

### 2. Archetype Target Competency Levels
**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

**Structure**:
```json
{
  "archetypeCompetencyTargetLevels": {
    "SE for managers": {
      "Systems Thinking": 4,
      "Communication": 4,
      "Decision Management": 4,
      ...
    },
    "Common basic understanding": {
      "Systems Thinking": 2,
      "Requirements Definition": 2,
      ...
    },
    ...
  }
}
```

**Update**: The latest file has no null values (previous version had nulls for "Continuous support" strategy).

### 3. Learning Objective Templates
**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

**Structure**:
```json
{
  "learningObjectiveTemplates": {
    "Decision Management": {
      "1": "Participants know the main decision-making bodies...",
      "2": "Participants learn about decision support methods...",
      "4": "Participants are able to prepare decisions for their relevant scopes...",
      "6": "Participants can evaluate decisions and define overarching processes..."
    },
    ...
  }
}
```

**Characteristics**:
- Some competencies have PMT breakdown (Process, Method, Tool sections)
  - Requirements Definition
  - System Architecting
  - Project Management
  - Configuration Management
- Others are more general
- All follow SMART criteria from `learning_objectives_guidelines.json`

### 4. Learning Objectives Guidelines
**File**: `data/source/templates/learning_objectives_guidelines.json`

Defines:
- SMART criteria (Specific, Measurable, Achievable, Relevant, Time-bound)
- Formulation guidelines
- Action verbs by level (Bloom's taxonomy alignment)
- Competency-specific examples
- PMT consideration requirements

### 5. Role Target Competency Levels
**Database**: `role_competency_matrix` table

**Structure**:
```sql
CREATE TABLE role_competency_matrix (
    id SERIAL PRIMARY KEY,
    role_cluster_id INTEGER NOT NULL,
    competency_id INTEGER NOT NULL,
    role_competency_value INTEGER, -- Values: -100, 0, 1, 2, 3, 4, 6
    organization_id INTEGER NOT NULL,
    FOREIGN KEY (role_cluster_id) REFERENCES role_cluster(id),
    FOREIGN KEY (competency_id) REFERENCES competency(id),
    FOREIGN KEY (organization_id) REFERENCES organization(id)
);
```

**Source Data**: `data/processed/role_competency_matrix.json` (14 roles × 16 competencies)

**Roles** include:
- Customer, Customer representative
- Project manager
- System engineer, Developer
- V&V employee
- Quality manager
- Process & policy manager
- And 7 others

### 6. Current Competency Levels
**Source**: Phase 2 Task 2 - Competency Assessment results

**Data flow**:
1. Users complete competency assessment surveys
2. Results stored in database per user
3. Aggregated across organization for learning objective generation

**Aggregation method**: Median (configurable to min/max/average in future)

### 7. Company PMT Context
**Input**: Admin-provided text description

**Format**: Free text describing:
- Specific SE processes used in the company
- Methods currently employed
- Tool landscape (e.g., "DOORS for requirements", "SysML for modeling")
- Role structure specifics
- Industry context

**Usage**:
- **Light customization** for most strategies
- **Deep customization** for "Continuous support" and "Needs-based project-oriented training"

---

## Learning Objective Generation Logic

### Step 1: Data Aggregation

**1.1 Aggregate Current Competency Levels**
```python
FOR each competency IN all_16_competencies:
    # Get all completed assessments for users in organization
    user_levels = []
    FOR each user IN organization.users:
        IF user.has_completed_assessment():
            user_levels.append(user.competency_level[competency])

    # Calculate organizational level (median by default)
    org_current_level[competency] = calculate_median(user_levels)
```

**1.2 Determine Organizational Role Targets**
```python
FOR each competency IN all_16_competencies:
    # Get all roles in the organization
    org_roles = get_organization_roles(organization_id)

    role_targets = []
    FOR each role IN org_roles:
        role_target = query_role_competency_matrix(
            role_id=role.id,
            competency_id=competency.id,
            organization_id=organization.id
        )
        role_targets.append(role_target)

    # Use HIGHEST role target to accommodate everyone
    org_role_target[competency] = max(role_targets)
```

### Step 2: Generate Learning Objectives Per Strategy

```python
# Main generation loop
learning_objectives_output = {}

FOR each strategy IN organization.selected_strategies:

    strategy_objectives = {
        "strategy_name": strategy,
        "core_competencies": [],      # Special handling
        "trainable_competencies": [], # Main objectives
        "summary": {}
    }

    FOR each competency IN all_16_competencies:

        # --- SPECIAL CASE: Core Competencies ---
        IF competency IN ["Systems Thinking",
                         "Systems Modelling and Analysis",
                         "Lifecycle Consideration",
                         "Customer / Value Orientation"]:

            strategy_objectives["core_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "status": "not_directly_trainable",
                "note": "This core competency develops indirectly through training in other technical, management, and social competencies."
            })
            CONTINUE  # Skip to next competency

        # --- TRAINABLE COMPETENCIES: Three-Way Comparison ---

        current = org_current_level[competency]
        archetype_target = archetypeCompetencyTargetLevels[strategy][competency]
        role_target = org_role_target[competency]

        # Scenario A: Training Required
        IF current < archetype_target AND archetype_target <= role_target:

            # Get base template
            base_template = learningObjectiveTemplates[competency][archetype_target]

            # Customize based on strategy
            IF strategy IN ["Continuous support",
                           "Needs-based project-oriented training"]:
                # Deep customization with RAG LLM
                customized_objective = llm_deep_customize(
                    template=base_template,
                    company_pmt=admin_pmt_context,
                    current_level=current,
                    target_level=archetype_target,
                    competency_name=competency
                )
            ELSE:
                # Light customization
                customized_objective = llm_light_customize(
                    template=base_template,
                    company_pmt=admin_pmt_context
                )

            strategy_objectives["trainable_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "current_level": current,
                "archetype_target": archetype_target,
                "role_target": role_target,
                "gap": archetype_target - current,
                "status": "training_required",
                "learning_objective": customized_objective,
                "training_priority": calculate_priority(gap, role_target)
            })

        # Scenario B: Archetype Achieved, Role Not Fully Met
        ELIF archetype_target <= current AND current < role_target:

            strategy_objectives["trainable_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "current_level": current,
                "archetype_target": archetype_target,
                "role_target": role_target,
                "status": "consider_higher_archetype",
                "recommendation": f"Current archetype target ({archetype_target}) already achieved. Current level is {current}, but role requires {role_target}. Consider selecting a higher-level strategy to reach role target."
            })

        # Scenario C: Archetype Exceeds Role (Future: warning feature)
        ELIF archetype_target > role_target:

            strategy_objectives["trainable_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "current_level": current,
                "archetype_target": archetype_target,
                "role_target": role_target,
                "status": "archetype_exceeds_role",
                "note": f"Strategy target ({archetype_target}) exceeds organizational role requirements ({role_target}). Training to this level may not be necessary for current roles."
            })

        # Scenario D: All Targets Achieved
        ELSE:  # current >= archetype_target AND current >= role_target

            strategy_objectives["trainable_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "current_level": current,
                "archetype_target": archetype_target,
                "role_target": role_target,
                "status": "targets_achieved",
                "note": "Both archetype and role targets achieved. No training needed."
            })

    # Add strategy summary
    strategy_objectives["summary"] = {
        "total_competencies_requiring_training": count_by_status("training_required"),
        "total_competencies_achieved": count_by_status("targets_achieved"),
        "competencies_exceeding_targets": count_by_status("consider_higher_archetype"),
        "average_competency_gap": calculate_average_gap()
    }

    learning_objectives_output[strategy] = strategy_objectives

RETURN learning_objectives_output
```

### Step 3: Special Handling for "Train the Trainer" (Level 6)

```python
# Special case for level 6 objectives
IF strategy == "Train the trainer":

    FOR each trainable_competency:

        archetype_target = 6  # All competencies target level 6

        IF current < 6:

            base_template = learningObjectiveTemplates[competency][6]

            strategy_objectives["trainable_competencies"].append({
                "competency_name": competency,
                "competency_id": competency.id,
                "current_level": current,
                "archetype_target": 6,
                "role_target": role_target,
                "status": "external_training_recommended",
                "learning_objective": base_template,  # Use template as-is
                "note": "Mastery level (6) training typically conducted externally by certified SE trainers. Consider partnering with external training providers or SE certification bodies.",
                "external_training_flag": True  # Easy to filter/remove in future
            })
```

### Helper Functions

```python
def calculate_median(values):
    """Calculate median of list of values"""
    sorted_values = sorted(values)
    n = len(sorted_values)
    if n % 2 == 0:
        return (sorted_values[n//2 - 1] + sorted_values[n//2]) / 2
    else:
        return sorted_values[n//2]

def llm_deep_customize(template, company_pmt, current_level, target_level, competency_name):
    """
    Use RAG LLM to deeply customize learning objective
    - Replace generic tools with company-specific tools
    - Adapt to company processes
    - Reference company methods
    - Include industry-specific context
    """
    prompt = f"""
    Customize the following learning objective template for {competency_name}:

    Template: {template}

    Company Context (PMT):
    {company_pmt}

    Current Level: {current_level}
    Target Level: {target_level}

    Requirements:
    1. Replace generic references with company-specific processes, methods, and tools
    2. Maintain SMART criteria (Specific, Measurable, Achievable, Relevant, Time-bound)
    3. Keep the structure: Timeframe + Action + Observable demonstration + Benefit
    4. Ensure measurability through concrete examples from company context

    Return only the customized learning objective.
    """

    return call_llm_api(prompt)

def llm_light_customize(template, company_pmt):
    """
    Light customization - mainly replace tool names if mentioned
    """
    prompt = f"""
    Lightly adapt this learning objective to company context:

    Template: {template}
    Company Tools/Context: {company_pmt}

    Only replace generic tool/process names with specific company ones if mentioned.
    Keep everything else the same.
    """

    return call_llm_api(prompt)

def calculate_priority(gap, role_target):
    """
    Calculate training priority based on gap size and role importance
    Higher gap + higher role target = higher priority
    """
    return (gap * 0.6) + (role_target * 0.4)
```

---

## Configuration & Future-Proofing

### Configuration File Structure

**File**: `config/learning_objectives_config.json`

```json
{
  "version": "1.0",
  "aggregation": {
    "method": "median",
    "available_options": ["median", "min", "max", "average"],
    "description": "How to aggregate current competency levels across users"
  },

  "role_target_strategy": {
    "method": "highest",
    "available_options": ["highest", "majority", "per_role"],
    "description": "How to determine organizational role targets when multiple roles exist"
  },

  "customization": {
    "default_level": "light",
    "strategies_requiring_deep_customization": [
      "Continuous support",
      "Needs-based project-oriented training"
    ],
    "description": "Level of LLM customization for learning objectives"
  },

  "multiple_strategies": {
    "handling": "separate",
    "available_options": ["separate", "merged"],
    "description": "Generate separate objective sets or merge into one"
  },

  "features": {
    "include_level_6_objectives": true,
    "show_core_competencies_with_note": true,
    "enable_archetype_suitability_warnings": false,
    "generate_individual_user_objectives": false
  },

  "output_formats": {
    "api_response": true,
    "pdf_report": true,
    "excel_export": true,
    "json_download": true
  }
}
```

### Future Enhancement Flags

**Easily Changeable Decisions**:

1. **Aggregation Method** (currently: median)
   - Flag: `aggregation.method`
   - Change to min/max/average without code changes

2. **Role Target Strategy** (currently: highest)
   - Flag: `role_target_strategy.method`
   - Future: Could generate per-role or by majority role

3. **Multiple Strategies Handling** (currently: separate)
   - Flag: `multiple_strategies.handling`
   - Future: Could merge into single unified set

4. **Level 6 Inclusion** (currently: included)
   - Flag: `features.include_level_6_objectives`
   - Easy to disable "Train the trainer" level 6 objectives

5. **Archetype Warnings** (currently: disabled)
   - Flag: `features.enable_archetype_suitability_warnings`
   - Future: Warn when archetype > role target (Scenario C)

6. **Individual User Objectives** (currently: disabled)
   - Flag: `features.generate_individual_user_objectives`
   - Future: Generate personalized development plans per user

---

## API Design

### Endpoint 1: Generate Learning Objectives

**POST** `/api/learning-objectives/generate`

**Request**:
```json
{
  "organization_id": 1,
  "pmt_context": {
    "processes": "We follow ISO 26262 for automotive safety...",
    "methods": "Agile development with 2-week sprints, V-model for safety-critical components",
    "tools": "DOORS for requirements, Enterprise Architect for SysML, JIRA for project management",
    "industry": "Automotive embedded systems",
    "additional_context": "Focus on ADAS and autonomous driving systems"
  },
  "config_overrides": {
    "aggregation_method": "median"
  }
}
```

**Response**:
```json
{
  "organization_id": 1,
  "organization_name": "AutoTech Systems GmbH",
  "generated_at": "2025-10-26T14:30:00Z",
  "strategies": ["SE for managers", "Common basic understanding"],
  "aggregation_stats": {
    "total_users_assessed": 25,
    "aggregation_method": "median",
    "roles_in_organization": ["Developer", "Project Manager", "System Engineer"],
    "assessment_completion_rate": "92%"
  },

  "learning_objectives": {

    "SE for managers": {
      "strategy_description": "Focuses on managers as enablers of change...",

      "core_competencies": [
        {
          "competency_name": "Systems Thinking",
          "competency_id": 1,
          "status": "not_directly_trainable",
          "note": "This core competency develops indirectly through training in other competencies."
        },
        {
          "competency_name": "Systems Modelling and Analysis",
          "competency_id": 6,
          "status": "not_directly_trainable",
          "note": "This core competency develops indirectly through training in other competencies."
        }
        // ... 2 more core competencies
      ],

      "trainable_competencies": [
        {
          "competency_name": "Decision Management",
          "competency_id": 11,
          "category": "Management Competencies",
          "current_level": 2,
          "archetype_target": 4,
          "role_target": 4,
          "gap": 2,
          "status": "training_required",
          "training_priority": 3.6,
          "learning_objective": "At the end of the four-week management module, participants will be able to prepare complex technical decisions for their relevant scopes using the company's decision management framework in JIRA and Confluence. They will document the decision-making process according to ISO 26262 requirements, including rationale, alternatives considered, and trade-off analyses, so that all safety-critical decisions are traceable and auditable for ADAS system development.",
          "base_template": "Participants are able to prepare decisions for their relevant scopes or make them themselves and document the decision-making process accordingly.",
          "pmt_breakdown": {
            "process": "ISO 26262 decision documentation",
            "method": "Trade-off analysis, decision trees",
            "tool": "JIRA (decision tracking), Confluence (documentation)"
          }
        },
        {
          "competency_name": "Communication",
          "competency_id": 7,
          "category": "Social / Personal Competencies",
          "current_level": 3,
          "archetype_target": 4,
          "role_target": 4,
          "gap": 1,
          "status": "training_required",
          "training_priority": 3.0,
          "learning_objective": "At the end of the two-week communication workshop, participants will be able to communicate constructively and efficiently in cross-functional ADAS development teams while being empathetic to the needs and ideas of colleagues from different engineering disciplines. They will demonstrate this by facilitating sprint planning meetings and conducting effective stakeholder presentations, so that project goals are clearly understood and team collaboration is enhanced."
        },
        {
          "competency_name": "Requirements Definition",
          "competency_id": 14,
          "category": "Technical Competencies",
          "current_level": 2,
          "archetype_target": 1,
          "role_target": 4,
          "status": "consider_higher_archetype",
          "recommendation": "Current archetype target (1) already achieved. Current level is 2, but role requires 4. Consider selecting 'Orientation in pilot project' or 'Needs-based project-oriented training' strategy to reach role target."
        },
        {
          "competency_name": "Information Management",
          "competency_id": 12,
          "category": "Management Competencies",
          "current_level": 2,
          "archetype_target": 2,
          "role_target": 2,
          "status": "targets_achieved",
          "note": "Both archetype and role targets achieved. No training needed."
        }
        // ... more competencies
      ],

      "summary": {
        "total_competencies_requiring_training": 5,
        "total_competencies_achieved": 3,
        "competencies_exceeding_targets": 2,
        "average_competency_gap": 1.4,
        "estimated_training_duration": "12 weeks",
        "recommended_modules": 8
      }
    },

    "Common basic understanding": {
      // Similar structure...
    }
  }
}
```

### Endpoint 2: Get Existing Learning Objectives

**GET** `/api/learning-objectives/<organization_id>`

Returns previously generated learning objectives without regeneration.

### Endpoint 3: Export Learning Objectives

**GET** `/api/learning-objectives/<organization_id>/export?format=pdf`

Query params:
- `format`: pdf | excel | json
- `strategy`: (optional) filter by specific strategy

Returns downloadable file.

### Endpoint 4: Update PMT Context

**PATCH** `/api/learning-objectives/<organization_id>/pmt-context`

Allows admin to update PMT context and trigger regeneration.

---

## UI Flow

### Admin Dashboard Flow

```
1. Phase 1 Completion
   ├─> Selected strategies stored
   └─> Proceed to Phase 2

2. PMT Context Configuration
   ├─> Admin Dashboard > "Configure Company Context"
   ├─> Text form with sections:
   │   ├─ Processes (e.g., ISO standards, development models)
   │   ├─ Methods (e.g., Agile, V-model, Scrum)
   │   ├─ Tools (e.g., DOORS, JIRA, SysML)
   │   └─ Industry context
   └─> Save PMT context

3. Phase 2 Task 1-2: Competency Assessment
   ├─> Users complete assessments
   ├─> Admin monitors completion rate
   └─> Dashboard shows: "25/27 users completed (92%)"

4. Phase 2 Task 3: Generate Learning Objectives
   ├─> Button: "Generate Learning Objectives"
   ├─> Prerequisites check:
   │   ├─ At least 70% users completed assessment?
   │   ├─ PMT context configured?
   │   └─ Strategies selected in Phase 1?
   ├─> If all OK: Trigger generation
   └─> Loading screen: "Analyzing competency gaps..."

5. Review Generated Objectives
   ├─> Tabbed view per strategy:
   │   ├─ "SE for managers" tab
   │   ├─ "Common basic understanding" tab
   │   └─ ...
   ├─> For each strategy:
   │   ├─ Summary cards:
   │   │   ├─ "5 competencies need training"
   │   │   ├─ "3 competencies already achieved"
   │   │   └─ "Avg gap: 1.4 levels"
   │   ├─> Competency list (expandable):
   │   │   ├─ Training Required (highlighted)
   │   │   ├─ Targets Achieved (grayed out)
   │   │   └─ Consider Higher Strategy (info badge)
   │   └─> Each competency shows:
   │       ├─ Current: 2, Target: 4 (visual progress bar)
   │       ├─ Learning objective (full text)
   │       └─ PMT breakdown (if applicable)
   └─> Actions:
       ├─ "Regenerate with different context"
       ├─ "Export to PDF"
       └─ "Export to Excel"

6. Export Options
   ├─> PDF Report:
   │   ├─ Executive summary
   │   ├─ Strategy-by-strategy breakdown
   │   ├─ Competency gap analysis charts
   │   └─ Detailed learning objectives
   └─> Excel Workbook:
       ├─ Sheet 1: Summary
       ├─ Sheet 2-N: One per strategy
       └─ Filterable/sortable columns
```

### UI Components Needed

1. **PMT Context Form**
   - Multi-section text areas
   - Save/Update buttons
   - Validation for minimum content

2. **Learning Objectives Dashboard**
   - Strategy tabs
   - Summary cards with statistics
   - Expandable competency cards
   - Status badges (Training Required, Achieved, etc.)
   - Progress bars for current vs target

3. **Competency Detail Card**
   - Competency name + category
   - Three-level comparison (Current, Archetype, Role)
   - Learning objective text (formatted)
   - PMT breakdown (if available)
   - Training priority indicator

4. **Export Dialog**
   - Format selection (PDF/Excel/JSON)
   - Strategy filter (all or specific)
   - Generate button

---

## Design Decisions Log

### Decision 1: Terminology - Strategy vs Archetype
- **Question**: Use "Strategy" or "Archetype"?
- **Decision**: Use "Strategy" in the app (more intuitive for users)
- **Rationale**: Reference materials use "Archetype" but it's less clear to end users

### Decision 2: Core Competencies Display
- **Question**: Hide core competencies or show with note?
- **Decision**: Show with explanatory note
- **Rationale**: Provides transparency about why they're not trained directly
- **Future-proof**: Config flag `show_core_competencies_with_note`

### Decision 3: Aggregation Method
- **Question**: How to aggregate current levels across users?
- **Decision**: Median (middle ground)
- **Alternatives considered**: Min (most conservative), Max (most optimistic), Average
- **Rationale**: Median is robust to outliers
- **Future-proof**: Config flag `aggregation.method`

### Decision 4: Role Target Strategy
- **Question**: When org has multiple roles, which target to use?
- **Decision**: Highest role target (accommodate everyone)
- **Alternatives considered**: Majority role, Per-role objectives
- **Rationale**: Ensures all employees can benefit from training
- **Future-proof**: Config flag `role_target_strategy.method`

### Decision 5: Multiple Strategies Handling
- **Question**: If org selected multiple strategies, generate separate or merged objectives?
- **Decision**: Separate objective sets per strategy
- **Rationale**: Each strategy has distinct focus and target levels
- **Future-proof**: Config flag `multiple_strategies.handling`

### Decision 6: PMT Customization Level
- **Question**: Same customization for all strategies?
- **Decision**: Light for most, deep for "Continuous support" and "Needs-based project-oriented"
- **Rationale**: These two strategies explicitly mentioned in requirements as needing company-specific customization
- **Future-proof**: Config array `strategies_requiring_deep_customization`

### Decision 7: Level 6 Objectives
- **Question**: Include "Train the trainer" level 6 objectives?
- **Decision**: Yes, but flag as external training
- **Rationale**: Completeness, but acknowledge it's typically external
- **Future-proof**: Config flag `include_level_6_objectives` (easy to disable)

### Decision 8: Archetype Suitability Warnings
- **Question**: Warn when archetype target > role target?
- **Decision**: Track the scenario but don't show warnings yet
- **Rationale**: Need advisor input on UX for warnings
- **Future-proof**: Config flag `enable_archetype_suitability_warnings` (currently false)

### Decision 9: Individual vs Organizational Objectives
- **Question**: Generate per-user or org-level objectives?
- **Decision**: Organizational level (admin view)
- **Rationale**: Primary use case is organizational planning
- **Future-proof**: Flag `generate_individual_user_objectives` for future feature

### Decision 10: Data Source for Role Targets
- **Question**: Is role-competency matrix the same as role target levels?
- **Decision**: Yes, confirmed
- **Rationale**: Database table `role_competency_matrix` contains role target values
- **Verification**: Checked data structure and Marcel's thesis Figure 4-5

---

## Open Questions for Advisor

### Question 1: Three-Way Comparison Edge Cases
**Context**: Marcel's thesis describes 4 scenarios. In practice:
- What if role_target is 0 (not relevant for role)?
- What if archetype_target is 6 but role_target is 4?

**Proposed handling**:
- role_target = 0 → Skip competency (not applicable)
- archetype > role → Note as "may not be necessary"

**Question for advisor**: Is this handling appropriate?

---

### Question 2: Aggregation Boundary Conditions
**Context**: Using median for org-level aggregation

**Edge cases**:
- What if only 1-2 users completed assessment?
- What if user levels are very spread (e.g., [1, 1, 1, 6, 6])?

**Proposed handling**:
- Minimum threshold: 70% completion rate
- Show warning if spread > 3 levels

**Question for advisor**: Appropriate thresholds?

---

### Question 3: Learning Objective Customization Depth
**Context**: LLM will customize objectives based on PMT

**Concerns**:
- Over-customization may deviate from validated templates
- Under-customization may be too generic

**Proposed balance**:
- Keep structure and level from template
- Only replace tool/process names
- Maintain SMART criteria

**Question for advisor**: Is this the right balance? Should we allow more/less freedom?

---

### Question 4: Multiple Strategies - Training Sequence
**Context**: If org selected multiple strategies (e.g., "Common basic" + "SE for managers")

**Question for advisor**:
- Should we recommend a sequence? (e.g., basic before advanced)
- Or leave it to admin to decide?
- Should objectives from multiple strategies be merged if there's overlap?

---

### Question 5: PMT Context - Required vs Optional
**Context**: PMT context drives customization

**Question for advisor**:
- Should PMT context be mandatory?
- Or allow generation with generic templates if not provided?
- What's minimum acceptable PMT input?

---

### Question 6: Validation of Generated Objectives
**Context**: LLM generates customized objectives

**Question for advisor**:
- Should admin review/approve before finalizing?
- Should there be a feedback loop to improve?
- How to ensure objectives remain SMART-compliant after customization?

---

### Question 7: Training Priority Calculation
**Proposed formula**: `priority = (gap × 0.6) + (role_target × 0.4)`

**Question for advisor**:
- Is this weighting appropriate?
- Should other factors be considered (e.g., business criticality)?
- Should priorities be explicit or hidden?

---

### Question 8: Level 3 and 5 Handling
**Context**: Only levels 1, 2, 4, 6 exist in templates

**Question for advisor**:
- If user is at level 3, what's their "current" level? (Round down to 2? Or up to 4?)
- Should we interpolate objectives for level 3/5?

**Note**: Current assumption is level 3/5 don't exist in the competency model.

---

### Question 9: Continuous Support Strategy Specifics
**Context**: Marcel's thesis says this strategy is for "continuous learning" and "already trained organizations"

**Question for advisor**:
- Should there be prerequisites before selecting this strategy?
- How does "continuous support" differ in objective generation vs other strategies?
- Should objectives be more "on-demand" or "just-in-time" focused?

---

### Question 10: Individual User Objectives - Future Feature
**Context**: Currently generating org-level, but may need individual plans

**Question for advisor**:
- Is individual user objective generation in scope for thesis?
- Or strictly organizational planning?
- If individual: How to present to users without demotivating (showing gaps)?

---

## Implementation Readiness

### Ready to Implement After Advisor Approval:

✅ Data sources identified and verified
✅ Three-way comparison logic defined
✅ Configuration structure for future changes
✅ API design complete
✅ UI flow mapped

### Pending Advisor Input:

⏳ Edge case handling confirmation
⏳ Customization depth validation
⏳ Priority calculation approval
⏳ Multiple strategies sequence recommendation
⏳ PMT context requirements

### Next Steps After Approval:

1. Finalize design based on advisor feedback
2. Create database schema updates (if needed)
3. Implement backend API endpoints
4. Implement LLM customization logic (RAG)
5. Create UI components
6. Write unit tests for three-way comparison logic
7. Integration testing with real data
8. User acceptance testing with admin

---

## Appendix A: Reference Files

- `data/source/strategy_definitions.json` - Strategy descriptions
- `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json` - Templates and targets
- `data/source/templates/learning_objectives_guidelines.json` - SMART criteria and guidelines
- `data/source/Phase 2/Learning objectives- note from Marcel's thesis.txt` - Key design insights
- `data/source/Phase 2/Figure 4-5 spider-web chart.png` - Three-way comparison visual
- `data/processed/role_competency_matrix.json` - Role target levels (source data)
- Database: `role_competency_matrix` table - Role targets (operational data)

---

## Appendix B: Competency Lists

### 4 Core Competencies (Not Directly Trainable):
1. Systems Thinking (ID: 1)
2. Systems Modelling and Analysis (ID: 6)
3. Lifecycle Consideration (ID: 4)
4. Customer / Value Orientation (ID: 5)

### 12 Trainable Competencies:

**Technical (5)**:
5. Requirements Definition (ID: 14)
6. System Architecting (ID: 15)
7. Integration, Verification, Validation (ID: 16)
8. Operation and Support (ID: 17)
9. Agile Methods (ID: 18)

**Social/Personal (3)**:
10. Self-Organization (ID: 9)
11. Communication (ID: 7)
12. Leadership (ID: 8)

**Management (4)**:
13. Project Management (ID: 10)
14. Decision Management (ID: 11)
15. Information Management (ID: 12)
16. Configuration Management (ID: 13)

---

## Appendix C: Competency Level Definitions

**Level 0**: Not relevant / Not performing
**Level 1**: Know (Remember) - Awareness
**Level 2**: Understand (Comprehend) - Basic knowledge
**Level 4**: Apply (Execute) - Practical application
**Level 6**: Master (Create/Evaluate) - Expert level

**Note**: Levels 3 and 5 do not exist in this competency model.

---

**Document End**

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-26 | 1.0 | Initial design document created | Claude Code |

---

## Approval Section

**To be completed by Thesis Advisor:**

- [ ] Design logic approved
- [ ] Edge case handling approved
- [ ] Customization approach validated
- [ ] Multiple strategies handling confirmed
- [ ] PMT requirements clarified
- [ ] Ready for implementation

**Advisor Name**: _________________
**Date**: _________________
**Signature**: _________________
**Comments/Changes Required**:

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
