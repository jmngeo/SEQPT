# Phase 1 to Phase 2 Integration: Strategy Selection Flow

**Question**: Are Phase 1 strategy selections written to the `learning_strategy` table?

**Answer**: **NO - Not directly.** Phase 1 and Phase 2 use different but related concepts.

---

## Phase 1 vs Phase 2: Different Purposes

### Phase 1: Strategic Archetype Selection (High-Level)

**Purpose**: Organization selects their **overall qualification philosophy**

**Storage**: `organization.selected_archetype` (single text field)

**Examples**:
- "SE_for_Managers" - Executive awareness focus
- "Certification" - INCOSE CSEP/ASEP focus
- "Common_Understanding" - Foundation for everyone
- "Needs_Based" - Project-specific training

**Characteristics**:
- **ONE archetype** per organization
- **High-level strategic decision**
- **Guides** Phase 2 selections (but doesn't dictate them)

### Phase 2: Specific Learning Strategies (Tactical)

**Purpose**: Organization selects **specific training programs** to implement

**Storage**: `learning_strategy` table (multiple rows per organization)

**Examples**:
- "Common basic understanding" workshop (2 days)
- "Needs-based, project-oriented training" (6 months)
- "SE for managers" executive course (1 day)

**Characteristics**:
- **MULTIPLE strategies** per organization (typically 3-7)
- **Specific training programs** with target levels
- **Implements** the Phase 1 archetype choice

---

## The Relationship: Archetype → Strategies

**Analogy**: Think of it like choosing a diet (Phase 1) vs selecting specific meals (Phase 2)

### Phase 1: Strategic Choice
```
Organization decides: "We want a CERTIFICATION approach"
↓
Stored in: organization.selected_archetype = "Certification"
```

### Phase 2: Tactical Implementation
```
To implement "Certification", we select these specific strategies:
1. Common basic understanding (foundation)
2. CSEP Preparation Course (certification focus)
3. Continuous support (exam coaching)
↓
Stored in: learning_strategy table (3 rows for this org)
  - Row 1: "Common basic understanding" → Template 1
  - Row 2: "Certification" → Template 7
  - Row 3: "Continuous support" → Template 5
```

---

## Data Flow (Complete Picture)

```
PHASE 1: Archetype Selection
┌─────────────────────────────────────────────────────┐
│ Admin selects: "Certification" archetype            │
│ ↓                                                    │
│ Stored in: organization.selected_archetype          │
│            = "Certification"                         │
└─────────────────────────────────────────────────────┘
                        ↓
              (guides but doesn't auto-populate)
                        ↓
PHASE 2: Strategy Selection
┌─────────────────────────────────────────────────────┐
│ Admin reviews recommended strategies based on        │
│ archetype and selects specific ones:                 │
│                                                       │
│ ✓ Common basic understanding                         │
│ ✓ Certification                                      │
│ ✓ Continuous support                                 │
│ ✗ SE for managers (not needed)                       │
│ ✗ Train the trainer (not yet)                        │
│ ↓                                                     │
│ Stored in: learning_strategy table (3 rows)          │
│   - ID 101: Org 30 → "Common basic" → Template 1    │
│   - ID 102: Org 30 → "Certification" → Template 7   │
│   - ID 103: Org 30 → "Continuous support" → Template 5 │
└─────────────────────────────────────────────────────┘
                        ↓
PHASE 2: Learning Objectives Generation
┌─────────────────────────────────────────────────────┐
│ System queries learning_strategy for Org 30          │
│ Gets templates 1, 7, 5                               │
│ Queries strategy_template_competency                 │
│ Generates customized objectives                      │
└─────────────────────────────────────────────────────┘
```

---

## Current State: Test Data (Orgs 28 & 29)

### What We Found
```sql
-- Check Phase 1 selections
SELECT id, organization_name, selected_archetype
FROM organization WHERE id IN (28, 29);

Results:
  28 | Lowmaturity ORG  | [NULL/Empty]
  29 | Highmaturity ORG | [NULL/Empty]
```

**Interpretation**:
- Orgs 28 & 29 are **test organizations** created for Phase 2 development
- They **skipped Phase 1** (no archetype selected)
- Their `learning_strategy` records were created **directly** using the setup script
- This is **OK for testing** but not the normal user flow

### Normal User Flow
```
Real Organization (e.g., Org 30):
1. Phase 1: Admin selects archetype → organization.selected_archetype = "Certification"
2. Phase 2: System suggests recommended strategies based on archetype
3. Phase 2: Admin reviews and selects specific strategies
4. Phase 2: System creates learning_strategy records
5. Phase 2: Learning objectives generated from selected strategies
```

---

## How Strategies Are Created

### Method 1: Manual Setup Script (Testing/Admin)
```python
# File: src/backend/setup/setup_phase2_task3_for_org.py

def setup_phase2_task3_strategies(organization_id: int):
    """
    Creates learning_strategy records for ALL 7 templates
    Used for testing or initial setup
    """
    templates = db.query(StrategyTemplate).all()  # Get all 7

    for template in templates:
        strategy = LearningStrategy(
            organization_id=organization_id,
            strategy_name=template.strategy_name,
            strategy_template_id=template.id,  # Link to global template
            selected=False,  # Admin must enable them
            priority=None
        )
        db.add(strategy)

    db.commit()
    # Result: 7 learning_strategy rows created (one per template)
```

**Usage**:
```python
setup_phase2_task3_strategies(28)  # Creates 7 strategies for org 28
setup_phase2_task3_strategies(29)  # Creates 7 strategies for org 29
```

### Method 2: Frontend Selection (Production)
```javascript
// User flow in frontend (Phase 2 Task 3)

// Step 1: Show strategies based on Phase 1 archetype
const archetype = organization.selected_archetype;  // "Certification"
const recommendedStrategies = getRecommendedStrategies(archetype);
// Returns: ["Common basic understanding", "Certification", "Continuous support"]

// Step 2: User selects which ones to implement
const userSelections = [
  { strategy_name: "Common basic understanding", priority: 1 },
  { strategy_name: "Certification", priority: 2 },
  { strategy_name: "Continuous support", priority: 3 }
];

// Step 3: Backend creates learning_strategy records
POST /api/organizations/30/learning-strategies
{
  "strategies": userSelections
}

// Backend creates 3 learning_strategy rows:
INSERT INTO learning_strategy (organization_id, strategy_name, strategy_template_id, selected, priority)
VALUES
  (30, 'Common basic understanding', 1, true, 1),
  (30, 'Certification', 7, true, 2),
  (30, 'Continuous support', 5, true, 3);
```

---

## Archetype → Strategy Mapping (Recommendations)

### Archetype: "Certification"
**Recommended Strategies**:
1. Common basic understanding (foundation)
2. Certification (core)
3. Continuous support (exam prep)
4. Train the trainer (optional - for internal coaches)

### Archetype: "SE_for_Managers"
**Recommended Strategies**:
1. Common basic understanding (foundation)
2. SE for managers (core)
3. Continuous support (optional - for ongoing questions)

### Archetype: "Needs_Based"
**Recommended Strategies**:
1. Needs-based, project-oriented training (core)
2. Continuous support (core)
3. Common basic understanding (optional - if gaps exist)

### Archetype: "Common_Understanding"
**Recommended Strategies**:
1. Common basic understanding (core)
2. Orientation in pilot project (optional - for hands-on)

---

## Why This Two-Level Approach?

### Benefits of Separation

**1. Flexibility**
- Phase 1 archetype is a **guide**, not a constraint
- Organizations can select strategies that don't match their archetype
- Example: "Certification" org can still choose "SE for managers" if executives need it

**2. Granularity**
- Phase 1: Strategic vision (one choice)
- Phase 2: Tactical execution (multiple choices)
- Better matches real-world decision-making

**3. Evolution**
- Organization's archetype may change over time
- But specific strategies can be added/removed independently
- No need to redo Phase 1 to adjust Phase 2

**4. Reusability**
- Same archetype can map to different strategy combinations
- Different organizations with same archetype can customize differently

---

## Summary: Integration Points

### Direct Data Flow
```
Phase 1 Selection:
  organization.selected_archetype = "Certification"
  ↓ (guides but doesn't auto-populate)

Phase 2 Selection:
  learning_strategy table (user chooses specific strategies)
  ├─ Row 1: Organization 30 → Strategy "Common basic" → Template 1
  ├─ Row 2: Organization 30 → Strategy "Certification" → Template 7
  └─ Row 3: Organization 30 → Strategy "Continuous support" → Template 5
```

### Key Points
1. **Phase 1 does NOT automatically populate learning_strategy**
2. **Phase 1 archetype is used to RECOMMEND strategies in Phase 2**
3. **User manually selects which strategies to implement in Phase 2**
4. **learning_strategy table is Phase 2's "shopping cart"**
5. **Strategy templates are GLOBAL (not org-specific)**

### Data Ownership
- `organization.selected_archetype`: Phase 1 data
- `learning_strategy`: Phase 2 data (references global templates)
- `strategy_template`: Global reference (not owned by any phase)
- `strategy_template_competency`: Global reference (not owned by any phase)

---

## Example Scenarios

### Scenario 1: Standard Flow
```
1. Org 40 completes Phase 1
   → selected_archetype = "Certification"

2. Org 40 enters Phase 2 Task 3
   → Frontend shows: "Based on your Certification archetype, we recommend:"
      ✓ Common basic understanding
      ✓ Certification
      ✓ Continuous support
      ✓ Train the trainer

3. Admin selects 3 of them
   → System creates 3 learning_strategy rows (links to templates 1, 7, 5)

4. Learning objectives generated
   → Queries templates 1, 7, 5 from strategy_template_competency
```

### Scenario 2: Test Data (Current Orgs 28 & 29)
```
1. Orgs 28 & 29 created for testing
   → selected_archetype = NULL (skipped Phase 1)

2. Admin runs setup script
   → setup_phase2_task3_strategies(28)
   → Creates 7 learning_strategy rows (all templates)

3. Learning objectives can be generated
   → Uses whichever strategies admin enables (selected=true)
```

### Scenario 3: Archetype Mismatch (Allowed)
```
1. Org 50 selected archetype = "Common_Understanding"

2. Later, executives want certification too
   → Admin adds "Certification" strategy in Phase 2
   → Creates learning_strategy row linking to Template 7

3. Organization now has:
   → Phase 1: "Common_Understanding" archetype
   → Phase 2: "Common basic" + "Certification" strategies
   → This is VALID (flexibility by design)
```

---

## Conclusion

**Your Question**: Are Phase 1 strategies written to learning_strategy?

**Answer**:
- **NO** - Phase 1 archetypes are NOT automatically written to learning_strategy
- **YES** - Phase 1 archetypes GUIDE Phase 2 strategy selections
- **HOW** - Admins select specific strategies in Phase 2, system creates learning_strategy rows

**Key Insight**:
- Phase 1 = Strategic vision (one archetype)
- Phase 2 = Tactical implementation (multiple strategies)
- learning_strategy = Phase 2's action plan (references global templates)

**Data Flow**:
1. Phase 1: Archetype selected → stored in organization table
2. Phase 2: Strategies selected → stored in learning_strategy table
3. Backend: Templates queried → from strategy_template_competency table
4. Result: Customized learning objectives generated

---

**Created**: 2025-11-06
**Reference**: LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md, PHASE2_TASK3_TABLE_ARCHITECTURE_EXPLAINED.md
