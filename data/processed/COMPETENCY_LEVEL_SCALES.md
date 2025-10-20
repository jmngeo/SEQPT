# Competency Level Scales - Clarification

## Summary

There are **TWO different competency level scales** used in the SE-QPT system:

### Scale 1: Excel/Role-Competency Matrix Scale (0, 1, 2, 3/4, 6)
**Used in:**
- `role_competency_matrix_corrected.json`
- `standard_learning_objectives.json` (levels: 1, 2, 4, 6)
- Excel file: "Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx"

**Mapping:**
```
0 = Not relevant / Not required
1 = Know (Awareness)
2 = Understand (Basic understanding)
3 or 4 = Apply (Can apply independently)
6 = Master (Expert level, can train others)
```

### Scale 2: Archetype Matrix Scale (0-5)
**Used in:**
- `archetype_competency_matrix.json`

**Mapping:**
```
0 = Not required / Not applicable
1 = Awareness (Know about it)
2 = Basic (Can apply with guidance)
3 = Intermediate (Can apply independently)
4 = Advanced (Can mentor others)
5 = Expert (Can define processes and train trainers)
```

## Conversion Between Scales

### Excel Scale → Archetype Scale
```
Excel  →  Archetype  |  Description
-------|-------------|-------------
  0    →     0       |  Not relevant
  1    →     1       |  Know / Awareness
  2    →     2       |  Understand / Basic
  4    →     3       |  Apply / Intermediate
  6    →     4-5     |  Master / Advanced-Expert
```

### For Learning Objectives Selection

**The correct process is:**

1. **Archetype Selection** (Phase 1)
   - Archetype defines target levels using **0-5 scale**
   - Example: "Common Basic Understanding" → Systemic thinking = Level 2

2. **Learning Objective Lookup**
   - Convert archetype level to excel scale:
     - Level 2 (archetype) → Level 2 (excel) = "Understand"
   - Look up in `standard_learning_objectives.json`:
     ```json
     "1": {  // Systemic thinking
       "2": {  // Level 2 = Understand
         "objective": "The participant understands the interaction..."
       }
     }
     ```

3. **Special Cases:**
   - Archetype Level 3 → Excel Level 4 (Apply)
   - Archetype Level 4 → Excel Level 6 (Master)
   - Archetype Level 5 → Excel Level 6 (Master) - same as level 4

## Recommendation

For consistency, the system should **standardize on ONE scale**. Two options:

### Option A: Use Excel Scale (1, 2, 4, 6) Everywhere
- **Pros:** Matches the standard learning objectives structure
- **Cons:** Need to update archetype_competency_matrix.json

### Option B: Use Archetype Scale (0-5) Everywhere
- **Pros:** More granular (5 levels vs 4 levels)
- **Cons:** Need to update standard_learning_objectives.json to include level 3 and 5

### Option C: Keep Both with Explicit Mapping (Current State)
- **Pros:** Preserves both sources of truth
- **Cons:** Requires conversion logic in code

## Current Implementation Status

✅ **standard_learning_objectives.json** - Uses correct Excel scale (1, 2, 4, 6)
✅ **role_competency_matrix_corrected.json** - Documents Excel scale (0, 1, 2, 3/4, 6)
⚠️ **archetype_competency_matrix.json** - Uses different 0-5 scale
❓ **Decision needed:** Which scale to use system-wide?

## Recommended Mapping Function

```python
def convert_archetype_to_excel_level(archetype_level):
    """
    Convert archetype scale (0-5) to excel scale (0,1,2,4,6)
    """
    mapping = {
        0: 0,  # Not relevant
        1: 1,  # Know / Awareness
        2: 2,  # Understand / Basic
        3: 4,  # Apply / Intermediate
        4: 6,  # Master / Advanced
        5: 6   # Expert / Master (maps to same as 4)
    }
    return mapping.get(archetype_level, 0)

def get_learning_objective(competency_id, archetype_level):
    """
    Get standard learning objective based on archetype level
    """
    excel_level = convert_archetype_to_excel_level(archetype_level)

    # Load standard_learning_objectives.json
    objectives = load_standard_objectives()

    return objectives["competencies"][str(competency_id)]["learning_objectives_by_level"].get(str(excel_level))
```
