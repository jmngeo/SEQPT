# Certification Archetype - Design Documentation

**Date**: 2025-11-05
**Source**: Marcel Niemeyer's Master Thesis
**Status**: 7th Qualification Archetype (Extension to SE4OWL)

---

## Overview

**"Certification"** is the 7th qualification archetype, added by Marcel Niemeyer in his thesis as an extension to the original 6 archetypes from the SE4OWL research project.

---

## Background (from Marcel's Thesis)

### **Why Certification is Separate**

> "The certification archetype was not addressed in the SE4OWL research project. However, certifications are part of the 'orientation in the pilot project' archetype. In this work, certification is defined as a separate archetype due to its typical characteristics, such as fixed and standardized training content and the issuing of certification certificates."

### **Key Characteristics**

1. **External Providers**: Certifications take place externally with certification providers
2. **Standardized Content**: Fixed curriculum specified by certification body
3. **Certificates Issued**: Official certification certificates awarded
4. **No Content Planning**: Content is pre-defined by curriculum
5. **Scheduling Required**: Organizations need to schedule with external providers

### **Typical Certifications**

- **SE-Zert**: 12-day training course
- **CSEP** (Certified Systems Engineering Professional): 3-day training
- **ASEP**: 3-day training

### **Qualification Objective**

- Suitable for the **"Apply"** qualification objective
- Can be used in the **motivation phase** of SE introduction

---

## Competency Target Levels

### **Design Decision**

Certification uses the **same competency targets** as "Orientation in Pilot Project" (all level 4).

**Rationale**:
- Certifications stem from the pilot project archetype conceptually
- Target level 4 represents "Apply" proficiency
- All 16 competencies trained to consistent professional level

### **Target Levels**

| Competency ID | Competency Name | Target Level |
|---------------|-----------------|--------------|
| 1 | Systems Thinking | 4 |
| 4 | Lifecycle Consideration | 4 |
| 5 | Customer / Value Orientation | 4 |
| 6 | Systems Modelling and Analysis | 4 |
| 7 | Communication | 4 |
| 8 | Leadership | 4 |
| 9 | Self-Organization | 4 |
| 10 | Project Management | 4 |
| 11 | Decision Management | 4 |
| 12 | Information Management | 4 |
| 13 | Configuration Management | 4 |
| 14 | Requirements Definition | 4 |
| 15 | System Architecting | 4 |
| 16 | Integration, Verification, Validation | 4 |
| 17 | Operation and Support | 4 |
| 18 | Agile Methods | 4 |

**All 16 competencies → Target Level 4**

---

## Comparison: Certification vs Orientation in Pilot Project

| Aspect | Orientation in Pilot Project | Certification |
|--------|------------------------------|---------------|
| **Target Levels** | All level 4 | All level 4 ✓ |
| **Provider** | Internal (organization) | External (certification body) |
| **Content** | Customizable project work | Fixed standardized curriculum |
| **Duration** | Flexible (project-based) | Fixed (12 days SE-Zert, 3 days CSEP) |
| **Output** | Project completion | Official certificate |
| **Planning Needed** | Content + Scheduling | Scheduling only |
| **Curriculum** | Organization defines | Pre-defined by provider |

### **Why Same Targets Are Correct**

Both aim for **level 4 proficiency** ("Apply" objective):
- Users can apply SE methods in practice
- Professional working knowledge achieved
- Suitable for independent work

The **difference** is in **delivery method**, not competency levels:
- **Orientation**: Learn by doing (pilot project)
- **Certification**: Learn by formal training (standardized course)

---

## Implementation in SE-QPT

### **Database**

**Strategy Table**:
```sql
SELECT id, strategy_name, selected
FROM learning_strategy
WHERE organization_id = 28 AND strategy_name = 'Certification';

-- Result:
-- id: 17
-- strategy_name: Certification
-- selected: true
```

**Competency Mappings**:
```sql
SELECT competency_id, target_level
FROM strategy_competency
WHERE strategy_id = 17
ORDER BY competency_id;

-- Result: 16 rows, all with target_level = 4
```

### **Learning Objectives Generation**

When "Certification" strategy is selected:

1. **Core Competencies** (IDs: 1, 4, 5, 6):
   - No gap calculations
   - Explanatory note only
   - "Develops indirectly through training in other competencies"

2. **Trainable Competencies** (IDs: 7-18):
   - Compare current_level (median) vs target_level (4)
   - Calculate gap if current < 4
   - Generate learning objective from template
   - Level 4 objective: "Participant is able to apply [competency] in practice"

### **Frontend Display**

Certification appears as one of 7 strategy tabs in results view:
1. Common Basic Understanding
2. SE for Managers
3. **Orientation in Pilot Project**
4. Needs-based Project-oriented Training
5. Continuous Support
6. **Certification** ← Same objectives as Orientation (by design)
7. Train the SE-Trainer

---

## Frequently Asked Questions

### **Q: Why do Certification and Orientation have identical objectives?**

**A:** This is correct by design. Both target level 4 proficiency. The difference is:
- **Orientation**: Internal pilot project (hands-on learning)
- **Certification**: External standardized course (formal training)

Organizations choose based on their situation:
- Need flexibility → Orientation in Pilot Project
- Want standardized certification → Certification (SE-Zert, CSEP)

### **Q: Should Certification have different target levels?**

**A:** No. Marcel's thesis design uses level 4 for both because:
- Both aim for "Apply" qualification objective
- Level 4 = Professional working competency
- Difference is delivery method, not competency depth

### **Q: Is Certification a duplicate?**

**A:** No, it's an intentional 7th archetype with distinct characteristics:
- External providers
- Fixed curriculum
- Official certificates
- Scheduling-focused planning

### **Q: Can an organization select both Orientation and Certification?**

**A:** Yes! Organizations can select both if they want to:
- Offer internal pilot projects AND external certifications
- Provide flexibility for different employee needs
- Combine hands-on experience with formal certification

---

## SE4OWL vs Marcel's Thesis Archetypes

### **Original 6 Archetypes** (SE4OWL Research Project)

1. Common basic understanding
2. SE for managers
3. Orientation in pilot project
4. Needs-based, project-oriented training
5. Continuous support
6. Train the trainer

### **Extended 7 Archetypes** (Marcel's Thesis)

All 6 above, PLUS:

**7. Certification** ← New archetype
- External standardized training
- Fixed curriculum
- Official certificates
- Same competency targets as "Orientation" (level 4)

---

## Usage Scenarios

### **Scenario 1: Large Enterprise**

Selects both "Orientation in Pilot Project" AND "Certification":
- New hires → Internal pilot project (Orientation)
- Experienced staff → External SE-Zert certification (Certification)
- Result: Flexible qualification options

### **Scenario 2: Small Startup**

Selects only "Certification":
- Limited internal resources
- Prefers external standardized training
- Official certificates boost credibility
- Result: Outsource training to providers

### **Scenario 3: Mature Organization**

Selects "Needs-based Project-oriented Training" AND "Certification":
- Project-specific training for active projects
- Certification for formal qualification recognition
- Result: Practical + formal qualification path

---

## Implementation Notes

### **For Algorithm**

- Certification follows same rules as other strategies
- Target levels: All 4
- Text generation: Uses level 4 templates
- No special handling needed

### **For Frontend**

- Display as separate strategy tab
- Show identical objectives as "Orientation" (expected)
- No special UI treatment needed

### **For Database**

```sql
-- Verify Certification strategy exists and has correct mappings
SELECT
  ls.id,
  ls.strategy_name,
  COUNT(sc.id) as mapping_count,
  string_agg(DISTINCT sc.target_level::text, ',') as unique_levels
FROM learning_strategy ls
LEFT JOIN strategy_competency sc ON ls.id = sc.strategy_id
WHERE ls.organization_id = 28 AND ls.strategy_name = 'Certification'
GROUP BY ls.id, ls.strategy_name;

-- Expected result:
-- id: 17
-- strategy_name: Certification
-- mapping_count: 16
-- unique_levels: 4
```

---

## Summary

### **Key Points**

✅ Certification is the **7th archetype** (extension to SE4OWL)
✅ **Same target levels** as Orientation (all level 4) is **correct by design**
✅ Difference is **delivery method**, not competency levels
✅ Provides **standardized external training** option
✅ Suitable for **formal certification** needs (SE-Zert, CSEP)

### **Current Status**

- ✅ Strategy exists in database (ID: 17)
- ✅ All 16 competency mappings at level 4
- ✅ Selected for Org 28
- ✅ Generates learning objectives correctly
- ✅ Displays in UI alongside other strategies

### **No Action Required**

Certification archetype is **working as designed**.

---

**References**:
- Marcel Niemeyer's Master Thesis (Qualification Archetypes)
- SE4OWL Research Project (Original 6 Archetypes)
- SE-Zert Certification: [SEZ22-ol]
