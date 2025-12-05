# Global vs Organization-Specific Tables

## GLOBAL REFERENCE TABLES (Shared by All Organizations)

```
┌─────────────────────────────────────────────────────────────┐
│ GLOBAL KNOWLEDGE BASE (Research-Validated)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  strategy_template (7 rows)                                 │
│  ├─ 1. Common basic understanding                           │
│  ├─ 2. SE for managers                                      │
│  ├─ 3. Orientation in pilot project                         │
│  ├─ 4. Needs-based, project-oriented training               │
│  ├─ 5. Continuous support                                   │
│  ├─ 6. Train the trainer                                    │
│  └─ 7. Certification                                        │
│                                                              │
│  strategy_template_competency (112 rows)                    │
│  ├─ Template 1 → Competency 1 → Level 2                     │
│  ├─ Template 1 → Competency 2 → Level 2                     │
│  ├─ ...                                                      │
│  └─ Template 7 → Competency 16 → Level 6                    │
│                                                              │
│  [7 templates × 16 competencies = 112 universal mappings]   │
└─────────────────────────────────────────────────────────────┘
        ↑                              ↑
        │ References                   │ References
        │                              │
┌───────┴──────────┐          ┌────────┴────────┐
│  Organization 28 │          │  Organization 29 │
│  (TechCorp)      │          │  (AutoSystems)   │
└──────────────────┘          └──────────────────┘
```

## ORGANIZATION-SPECIFIC TABLES (Unique Per Organization)

```
Organization 28:
  learning_strategy (7 rows)
  ├─ Strategy "Needs-based" → links to Template 4 (GLOBAL)
  ├─ Strategy "SE for managers" → links to Template 2 (GLOBAL)
  └─ ... (just pointers, no duplicate data)

  organization_pmt_context (1 row)
  └─ Tools: "DOORS, JIRA", Process: "ISO 26262", Industry: "Automotive"

Organization 29:
  learning_strategy (8 rows)
  ├─ Strategy "Needs-based" → links to Template 4 (SAME GLOBAL)
  ├─ Strategy "Certification" → links to Template 7 (SAME GLOBAL)
  └─ ... (different selections, but same templates)

  organization_pmt_context (1 row)
  └─ Tools: "PTC Integrity", Process: "ASPICE", Industry: "Medical devices"
```

## Key Insight: Reference vs Instance

**GLOBAL (Reference)**:
- strategy_template: "What strategies exist" (universal knowledge)
- strategy_template_competency: "What each strategy aims for" (universal targets)
- Like a **menu** at a restaurant - same for everyone

**ORG-SPECIFIC (Instance)**:
- learning_strategy: "What THIS org ordered from the menu" (selections)
- organization_pmt_context: "THIS org's special dietary needs" (customization)
- Like a **customer's order** - unique per customer

## Data Flow

```
GLOBAL KNOWLEDGE (Created Once)
     ↓
  [Templates loaded from research]
     ↓
  strategy_template + strategy_template_competency
     ↓
     ├─→ Org 28 picks strategies → learning_strategy (links to templates)
     ├─→ Org 29 picks strategies → learning_strategy (links to templates)
     └─→ Org 30 picks strategies → learning_strategy (links to templates)

All orgs share the same 112 template competency mappings!
```

## Why This Matters

**If you update a global template**:
```sql
-- Update "SE for managers" Communication target from 2 → 4
UPDATE strategy_template_competency
SET target_level = 4
WHERE strategy_template_id = 2 AND competency_id = 7;
```

**Result**: ALL organizations using "SE for managers" instantly see the update!
- Org 28: Updated ✓
- Org 29: Updated ✓
- Org 100: Updated ✓

No need to update each organization separately.

