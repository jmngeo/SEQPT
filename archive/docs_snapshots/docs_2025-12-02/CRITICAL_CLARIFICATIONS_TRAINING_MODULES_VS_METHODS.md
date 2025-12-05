# Critical Clarifications - Training Modules vs Methods & Level 6 Handling

**Date:** 2025-11-24
**Purpose:** Clarify distinction between training modules and methods, handle Level 6 mastery training
**Context:** Jomon's feedback on Design v5

---

## Issue 1: Training Methods vs Training Modules

### The Confusion

I was conflating two distinct concepts:

**Training Methods (HOW to deliver):**
- Group classroom training
- Individual coaching
- Mentoring
- External certification
- Self-study / e-learning
- Training on the job
- Blended approaches

**Training Modules (WHAT content to deliver):**
- Module 1: "Knowing SE" (Level 1 competencies)
- Module 2: "Understanding SE" (Level 2 competencies)
- Module 3: "Applying SE" (Level 4 competencies)
- Module 4: "Mastering SE" (Level 6 competencies)

### What We're Actually Doing

**Phase 2 Task 3:**
1. ✅ **Determine Training Modules Needed**
   - Based on gaps: Which levels (1, 2, 4, 6) need training?
   - Generate learning objectives for each module
   - Show in pyramid structure

2. ✅ **Group Users by Distribution Pattern** (per module)
   - Calculate who needs each module
   - Show distribution statistics
   - Example: "15/20 users need Level 2 module"

3. ✅ **Recommend Training Method** (per module per role)
   - Based on distribution pattern
   - Example: "Level 2 module for this role: Group training recommended (75% need it)"
   - **This is Phase 3 logic, but calculated and DISPLAYED in Phase 2**

**Phase 3 (Future):**
4. ⏸️ **Create Training Cohorts**
   - Group users into cohorts based on their specific needs
   - Example: Cohort A needs modules 1+2+4, Cohort B needs only module 4

5. ⏸️ **Schedule Training**
   - Assign cohorts to specific training sessions
   - Select actual trainers
   - Set timelines

### Corrected Understanding

**Training Modules** = The pyramid levels (1, 2, 4, 6)
- Each level IS a training module
- Contains learning objectives for that level
- Users progress through modules sequentially

**Training Methods** = Delivery approach PER module
- How we deliver each module depends on distribution
- Same module might use different methods for different roles
- Example:
  - Role A, Module 2: Group training (15/20 need it)
  - Role B, Module 2: Individual coaching (2/20 need it)

**What Phase 2 Shows:**
```
LEVEL 2: Understanding SE (This is a TRAINING MODULE)

Systems Thinking
  Learning Objective: "..." (Module content)

  Roles needing this module:
    - Requirements Engineer (8/10 users)
      Training Method Recommendation: Group training
      [Reasoning: 80% of role needs this module]

    - Test Engineer (2/10 users)
      Training Method Recommendation: Individual coaching
      [Reasoning: Only 20% of role needs this module]
```

**So we ARE addressing both concepts:**
- ✅ Training Modules: The pyramid levels themselves
- ✅ Training Methods: The recommendations shown per role

**Status:** NOT a backlog feature - already in Design v5, just needed clarification

---

## Issue 2: Role Requirements vs Strategy Targets

### The Problem

**Scenario:**
- Role-competency matrix says: "System Architect needs Systems Thinking at Level 6 (Mastery)"
- Selected strategies: "Continuous Support" (targets up to Level 4)
- **MISMATCH:** Role requires level 6, but strategy only provides level 4

**Current Design v5 Behavior (WRONG):**
- Condition 2 for graying out: "Selected strategy targets don't include this level"
- Would gray out Level 6 because strategy max = 4
- Ignores the fact that ROLE REQUIRES level 6

**Corrected Behavior (CORRECT):**
- Check TWO things:
  1. What does the role REQUIRE? (from role-competency matrix)
  2. What does the strategy PROVIDE? (from strategy targets)
- If role requires > strategy provides → **INADEQUACY FLAG**

### Three-Way Comparison

```python
# Three values to compare:
role_requirement = 6       # From role-competency matrix
strategy_target = 4        # From selected strategies
current_median = 2         # From user assessments

# Decision logic:
if role_requirement > strategy_target:
    # PROBLEM: Strategy inadequate for role requirements
    flag = "STRATEGY_INADEQUATE_FOR_ROLE"
    message = "Role requires Level 6, but selected strategy only targets Level 4"
    recommendation = "Consider adding 'Train the Trainer' strategy"

elif current_median > strategy_target:
    # Validation issue (already handled)
    flag = "OVER_TRAINING"
    message = "Current levels already exceed strategy targets"

elif current_median < strategy_target:
    # Normal training scenario
    flag = None
    generate_LOs_for_gap()
```

### Updated Graying Out Logic

**Condition 2 (REVISED):**

```python
def check_if_level_grayed_revised(level_num, gaps, role_requirements):
    """
    Determine if entire pyramid level should be grayed out.

    Two conditions (REVISED):
    1. No users have gaps at this level
    2. Level exceeds BOTH strategy targets AND role requirements
    """

    # Get max strategy target (excluding Train the Trainer)
    max_strategy_target = max(
        data['target_level']
        for data in gaps['by_competency'].values()
        if data['strategy_name'] != 'Train the Trainer'
    )

    # Get max role requirement across all roles
    max_role_requirement = 0
    if has_roles:
        max_role_requirement = max(
            role_comp_matrix[role_id][comp_id]
            for role_id in all_roles
            for comp_id in all_competencies
        )

    # Take HIGHER of strategy target or role requirement
    max_needed_level = max(max_strategy_target, max_role_requirement)

    if level_num > max_needed_level:
        # This level exceeds both strategy AND role requirements
        return True, f"Level {level_num} not required (max needed: {max_needed_level})"

    # Condition 1: Check if any user needs this level
    any_user_needs_level = any(
        level_num in data.get('levels_needed', [])
        for data in gaps['by_competency'].values()
    )

    if not any_user_needs_level:
        return True, f"No users need training at Level {level_num}"

    return False, None
```

**Key Change:** Don't gray out level 6 just because strategy doesn't provide it, if ROLE REQUIRES it.

---

## Issue 3: Level 6 / Mastery Training Special Case

### Only "Train the Trainer" Provides Level 6

**Reality Check:**
- "Train the Trainer" is the ONLY strategy that targets Level 6 (Mastery)
- All other strategies max out at Level 4 (Applying)
- Exception: Some roles might REQUIRE level 6 from role-competency matrix

### Three Scenarios for Level 6

**Scenario A: "Train the Trainer" Selected**
- Strategy targets: Level 6 for competencies
- Show Level 6 in pyramid
- Generate mastery LOs
- Ask: Internal or external trainers?

**Scenario B: Role Requires Level 6, but "Train the Trainer" NOT Selected**
- Role requirement: Level 6
- Strategy targets: Max Level 4
- **MISMATCH: Show WARNING**

**Scenario C: No Level 6 Needed**
- No role requires level 6
- "Train the Trainer" not selected
- Gray out Level 6 tab

### Handling Scenario B (Most Critical)

**UI Display:**

```
┌─ STRATEGY INADEQUACY WARNING ─────────────────────────────────┐
│ [!] The following roles require Mastery (Level 6) competencies │
│     but your selected strategies only provide up to Level 4.    │
│                                                                 │
│ Affected Roles & Competencies:                                 │
│   - System Architect: Systems Thinking (requires 6, strategy 4)│
│   - Process Manager: All 16 competencies (requires 6, strategy 4)│
│                                                                 │
│ Recommended Actions:                                            │
│   [Button] Add "Train the Trainer" Strategy                    │
│   [Button] Accept Limited Training (risk acknowledged)         │
│   [Button] Hire External Mastery-Level Trainers                │
└─────────────────────────────────────────────────────────────────┘
```

**Backend Logic:**

```python
def check_mastery_requirements(org_id, selected_strategies):
    """
    Check if any roles require Level 6 but strategies don't provide it.
    """

    # Check if "Train the Trainer" is selected
    ttt_selected = any(s['strategy_name'] == 'Train the Trainer' for s in selected_strategies)

    if ttt_selected:
        # Level 6 is covered by strategy
        return {'status': 'OK'}

    # Get max strategy target (excluding TTT)
    max_strategy_target = 4  # Typical max for non-TTT strategies

    # Check role requirements
    roles_requiring_mastery = []

    for role in get_organization_roles(org_id):
        for competency in ALL_16_COMPETENCIES:
            role_requirement = get_role_requirement(role.id, competency.id)

            if role_requirement == 6:
                # This role requires mastery
                roles_requiring_mastery.append({
                    'role_id': role.id,
                    'role_name': role.name,
                    'competency_id': competency.id,
                    'competency_name': competency.name,
                    'required': 6,
                    'strategy_provides': max_strategy_target,
                    'gap': 2
                })

    if len(roles_requiring_mastery) > 0:
        return {
            'status': 'INADEQUATE',
            'severity': 'HIGH',
            'message': (
                f"{len(roles_requiring_mastery)} role-competency combinations "
                f"require Mastery (Level 6), but selected strategies only provide "
                f"up to Level {max_strategy_target}."
            ),
            'affected': roles_requiring_mastery,
            'recommendations': [
                {
                    'action': 'add_ttt_strategy',
                    'label': 'Add "Train the Trainer" Strategy',
                    'description': 'Develop internal trainers to mastery level'
                },
                {
                    'action': 'accept_risk',
                    'label': 'Accept Limited Training',
                    'description': 'Roles will not achieve full competency (risk accepted)'
                },
                {
                    'action': 'external_trainers',
                    'label': 'Hire External Mastery Trainers',
                    'description': 'Bring in external experts for mastery training'
                }
            ]
        }

    return {'status': 'OK'}
```

---

## Issue 4: "Train the Trainer" Display & Integration

### Current Dual-Track Approach (v4)

In Design v4, we already separated "Train the Trainer":
- Processed separately
- Excluded from validation
- Shown in separate section

**This is still CORRECT.**

### Recommended Approach for v5

**Option A: Completely Separate Section (RECOMMENDED)**

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN PYRAMID                              │
│  [Levels 1, 2, 4, 6 tabs]                                    │
│  [Learning objectives from selected strategies]              │
│  [Excludes "Train the Trainer"]                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         MASTERY DEVELOPMENT (Train the Trainer)              │
│  [Special icon/color scheme]                                 │
│                                                              │
│  This section covers development of internal trainers to     │
│  mastery level (Level 6).                                    │
│                                                              │
│  Do you want internal or external trainers?                  │
│  [ ] Internal Trainers (develop from within organization)    │
│  [ ] External Trainers (hire/contract external experts)      │
│                                                              │
│  [If Internal selected:]                                     │
│    Competencies requiring mastery training:                  │
│    - Systems Thinking (3 users to train as trainers)         │
│    - Requirements Definition (2 users to train as trainers)  │
│    ...                                                       │
│                                                              │
│  [Learning Objectives for each competency at Level 6]        │
└─────────────────────────────────────────────────────────────┘
```

**Option B: Integrated with Visual Separation**

```
LEVEL 6 Tab: Mastering SE

┌─ STANDARD MASTERY (From Other Strategies) ─────────────────┐
│ [Empty if no other strategies target level 6]              │
│ [Shows competencies if any non-TTT strategy targets 6]     │
└─────────────────────────────────────────────────────────────┘

┌─ TRAIN THE TRAINER (Special Section) ─────────────────────┐
│ [Different background color - e.g., gold/amber]            │
│ [Special icon: graduation cap or teacher icon]             │
│                                                            │
│ Internal or External Trainers? [Selector]                 │
│                                                            │
│ [Competencies requiring trainer development]              │
│ [Learning Objectives for mastery level]                   │
└─────────────────────────────────────────────────────────────┘
```

**My Recommendation:** Option A (Separate Section)

**Rationale:**
- Clearer separation of concerns
- "Train the Trainer" has different purpose (develop trainers vs train employees)
- Different decision point (internal vs external)
- Aligns with dual-track processing we already have
- Avoids confusion in main pyramid

### Where to Show the Separate Section

**Placement Option 1: After Main Pyramid**
```
[Main Pyramid: Levels 1, 2, 4, 6]

[Separator / Divider]

[Train the Trainer Section]
```

**Placement Option 2: Before Main Pyramid (with explanation)**
```
[Info Box: First, select trainer development approach]

[Train the Trainer Section]

[Separator]

[Main Pyramid: Levels 1, 2, 4, 6]
```

**Placement Option 3: Collapsible Section**
```
[Main Pyramid: Levels 1, 2, 4, 6]

[Expandable Section]
► MASTERY DEVELOPMENT (Train the Trainer)
  [Click to expand and configure trainer development]
```

**Recommendation:** Option 1 or 3 (after main pyramid or collapsible)

---

## Issue 5: Exclude "Train the Trainer" from Target Selection

### Current Algorithm (WRONG)

```python
# Algorithm 1: Gap Detection
strategy_targets = calculate_combined_targets(selected_strategies)

def calculate_combined_targets(selected_strategies):
    """Take HIGHER target if multiple strategies."""
    targets = {}
    for strategy in selected_strategies:  # INCLUDES Train the Trainer
        strategy_archetype = get_strategy_targets(strategy)
        for competency in all_16_competencies:
            if competency not in targets:
                targets[competency] = strategy_archetype[competency]
            else:
                targets[competency] = max(targets[competency], strategy_archetype[competency])
    return targets
```

**Problem:** If "Train the Trainer" is selected, all targets become 6 (mastery).

### Corrected Algorithm

```python
def calculate_combined_targets(selected_strategies):
    """
    Calculate combined strategy targets.

    EXCLUDE "Train the Trainer" from main target calculation.
    Process TTT separately.
    """

    # Separate TTT from other strategies
    ttt_strategy = None
    other_strategies = []

    for strategy in selected_strategies:
        if strategy['strategy_name'] == 'Train the Trainer':
            ttt_strategy = strategy
        else:
            other_strategies.append(strategy)

    # Calculate targets from other strategies (take HIGHER)
    main_targets = {}
    for strategy in other_strategies:
        strategy_archetype = get_strategy_targets(strategy)
        for competency in all_16_competencies:
            if competency.id not in main_targets:
                main_targets[competency.id] = strategy_archetype[competency.id]
            else:
                main_targets[competency.id] = max(
                    main_targets[competency.id],
                    strategy_archetype[competency.id]
                )

    # TTT targets (all level 6)
    ttt_targets = {}
    if ttt_strategy:
        ttt_archetype = get_strategy_targets(ttt_strategy)
        ttt_targets = {comp.id: ttt_archetype[comp.id] for comp in all_16_competencies}

    return {
        'main_targets': main_targets,      # For main pyramid
        'ttt_targets': ttt_targets,         # For TTT section (separate)
        'ttt_selected': ttt_strategy is not None
    }
```

### Updated Gap Detection

```python
def detect_gaps(org_id, selected_strategies):
    """
    Detect training gaps with TTT separation.
    """

    # Get targets (TTT separated)
    targets = calculate_combined_targets(selected_strategies)

    # Process main pyramid (excluding TTT)
    main_gaps = process_gaps_for_targets(
        org_id,
        targets['main_targets'],
        include_ttt=False
    )

    # Process TTT separately (if selected)
    ttt_gaps = None
    if targets['ttt_selected']:
        ttt_gaps = process_ttt_gaps(
            org_id,
            targets['ttt_targets']
        )

    return {
        'main_pyramid': main_gaps,
        'train_the_trainer': ttt_gaps,
        'metadata': {
            'ttt_selected': targets['ttt_selected'],
            'mastery_requirements_check': check_mastery_requirements(
                org_id,
                selected_strategies
            )
        }
    }
```

---

## Updated Design v5 Changes Required

### Algorithm 1: Gap Detection - REVISED

**Changes:**
1. Separate "Train the Trainer" from other strategies
2. Calculate `main_targets` (excluding TTT) and `ttt_targets` (separate)
3. Check role requirements vs strategy targets (mastery inadequacy check)
4. Process main pyramid with main_targets
5. Process TTT section separately (if selected)

### Algorithm 6: Structure Final Output - REVISED

**Add:**
- `train_the_trainer` section (separate from main pyramid)
- `mastery_requirements_check` in metadata
- Warning/info boxes for inadequacy

### UI Components - NEW

**New Component: MasteryDevelopmentSection.vue**

```vue
<template>
  <div v-if="tttData" class="mastery-development-section">
    <v-card elevation="4" color="amber lighten-5">
      <v-card-title>
        <v-icon left color="amber darken-2">mdi-school-outline</v-icon>
        Mastery Development (Train the Trainer)
      </v-card-title>

      <v-card-text>
        <p>
          This section covers development of internal trainers to mastery level (Level 6).
        </p>

        <!-- Internal vs External Selection -->
        <v-radio-group v-model="trainerType" label="Trainer Development Approach:">
          <v-radio label="Internal Trainers (develop from within organization)" value="internal" />
          <v-radio label="External Trainers (hire/contract external experts)" value="external" />
        </v-radio-group>

        <!-- If Internal: Show competencies and LOs -->
        <div v-if="trainerType === 'internal'">
          <h3>Competencies Requiring Mastery Training:</h3>
          <CompetencyCard
            v-for="comp in tttData.competencies"
            :key="comp.competency_id"
            :competency="comp"
            :is-ttt="true"
          />
        </div>

        <!-- If External: Show information -->
        <div v-else-if="trainerType === 'external'">
          <v-alert type="info">
            External trainers will be hired or contracted for the following competencies:
            <ul>
              <li v-for="comp in tttData.competencies" :key="comp.competency_id">
                {{ comp.competency_name }}
              </li>
            </ul>
          </v-alert>
        </div>
      </v-card-text>
    </v-card>
  </div>
</template>
```

**New Component: MasteryRequirementsWarning.vue**

```vue
<template>
  <v-alert
    v-if="inadequacy && inadequacy.status === 'INADEQUATE'"
    type="warning"
    prominent
    border="left"
    colored-border
    elevation="2"
  >
    <v-row align="center">
      <v-col cols="12">
        <h3>
          <v-icon left>mdi-alert</v-icon>
          Strategy Inadequacy: Mastery Requirements Not Met
        </h3>
        <p>{{ inadequacy.message }}</p>
      </v-col>
    </v-row>

    <!-- Affected Roles Table -->
    <v-simple-table dense>
      <template v-slot:default>
        <thead>
          <tr>
            <th>Role</th>
            <th>Competency</th>
            <th>Required</th>
            <th>Strategy Provides</th>
            <th>Gap</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in inadequacy.affected" :key="`${item.role_id}-${item.competency_id}`">
            <td>{{ item.role_name }}</td>
            <td>{{ item.competency_name }}</td>
            <td>Level {{ item.required }}</td>
            <td>Level {{ item.strategy_provides }}</td>
            <td>{{ item.gap }} levels</td>
          </tr>
        </tbody>
      </template>
    </v-simple-table>

    <!-- Recommended Actions -->
    <v-card-actions>
      <v-btn
        v-for="rec in inadequacy.recommendations"
        :key="rec.action"
        color="primary"
        @click="handleAction(rec.action)"
      >
        {{ rec.label }}
      </v-btn>
    </v-card-actions>
  </v-alert>
</template>
```

---

## Summary of Changes to Design v5

### Backend Changes:

1. **Algorithm 1 - Gap Detection:**
   - ✅ Separate TTT from other strategies
   - ✅ Process main pyramid and TTT section separately
   - ✅ Add mastery requirements check

2. **New Function: `check_mastery_requirements()`**
   - Compare role requirements vs strategy targets
   - Flag inadequacy if role requires > strategy provides
   - Recommend solutions

3. **New Function: `process_ttt_gaps()`**
   - Process TTT competencies separately
   - Generate level 6 objectives
   - Handle internal vs external trainer selection

4. **Updated: `check_if_level_grayed()`**
   - Consider BOTH role requirements AND strategy targets
   - Don't gray out if role requires that level

### Frontend Changes:

1. **New Component: `MasteryDevelopmentSection.vue`**
   - Separate section for TTT
   - Internal vs external selection
   - Show level 6 competencies and LOs

2. **New Component: `MasteryRequirementsWarning.vue`**
   - Warning when role requires > strategy provides
   - Show affected roles
   - Action buttons (add TTT, accept risk, external trainers)

3. **Updated: `LearningObjectivesPage.vue`**
   - Add mastery requirements warning
   - Add mastery development section
   - Handle TTT data separately

### Data Structure Changes:

**Response Output - REVISED:**

```python
response_output = {
    'success': bool,
    'data': {
        'main_pyramid': {
            'levels': {1, 2, 4, 6},
            'metadata': {...}
        },
        'train_the_trainer': {
            'enabled': bool,
            'competencies': [...],
            'trainer_type': 'internal' | 'external' | null
        } or None,
        'mastery_requirements_check': {
            'status': 'OK' | 'INADEQUATE',
            'affected': [...],
            'recommendations': [...]
        }
    }
}
```

---

## Answers to Your Questions

### Q1: Training Modules vs Training Methods

**Answer:** We ARE handling both:
- **Training Modules** = The pyramid levels (1, 2, 4, 6)
- **Training Methods** = Delivery recommendations shown per role/module
- **NOT a backlog feature** - already in design, just needed clarification

### Q2: Level 6 / Mastery Requirements

**Answer:** Need to check THREE values:
- Role requirement (from role-competency matrix)
- Strategy target (from selected strategies)
- Current level (from assessments)

**If role requires > strategy provides:**
- Show inadequacy warning
- Recommend adding TTT or external trainers

### Q3: Train the Trainer Display

**Answer:** **Separate section** (not integrated in main pyramid)
- After main pyramid
- Different styling
- Internal vs external selection
- Shows level 6 LOs

### Q4: Exclude TTT from HIGHER Selection

**Answer:** ✅ YES - Corrected in algorithms above
- Process TTT separately
- Main pyramid uses `main_targets` (excluding TTT)
- TTT section uses `ttt_targets` (level 6 for all)

---

## Implementation Impact

**New Backend Work:**
- `check_mastery_requirements()` function
- `process_ttt_gaps()` function
- Updated `calculate_combined_targets()` to separate TTT
- Updated `check_if_level_grayed()` to consider role requirements

**New Frontend Work:**
- `MasteryDevelopmentSection.vue` component
- `MasteryRequirementsWarning.vue` component
- Updated `LearningObjectivesPage.vue` to show both sections

**Estimated Additional Effort:** +1 week (now 7 weeks total for Phase 2)

---

**Document Status:** FINAL CLARIFICATIONS
**Date:** 2025-11-24
**Next:** Update Design v5 documents with these changes
