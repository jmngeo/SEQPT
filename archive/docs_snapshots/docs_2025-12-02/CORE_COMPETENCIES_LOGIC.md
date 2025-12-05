# Core Competencies vs Trainable Competencies - Algorithm Logic

**Date**: 2025-11-05
**Purpose**: Document how the algorithm handles core competencies differently

---

## Overview

The Phase 2 Task 3 algorithm treats **4 core competencies** completely differently from the other **12 trainable competencies**.

---

## Core Competencies (IDs: 1, 4, 5, 6)

### **The 4 Core Competencies:**
1. **Systems Thinking** (ID: 1)
2. **Lifecycle Consideration** (ID: 4)
3. **Customer / Value Orientation** (ID: 5)
4. **Systems Modelling and Analysis** (ID: 6)

### **Why They're Special:**
These competencies **cannot be directly trained**. They develop indirectly through practice in other areas.

### **What the Algorithm Does:**

✅ **NO gap calculations**
- Does NOT calculate current_level from user assessments
- Does NOT compare current vs target
- Does NOT calculate gap size

✅ **Only generates explanatory note**
- Generic note: "This core competency develops indirectly through training in other competencies. It will be strengthened through practice in requirements definition, system architecting, integration, and other technical activities."

✅ **Skips all comparison logic**
```python
# From task_based_pathway.py lines 321-330
if comp_id in CORE_COMPETENCIES:
    core_obj = generate_core_competency_objective(comp_id, target_level)
    core_competencies_output.append({
        'competency_id': comp_id,
        'competency_name': core_obj['competency_name'],
        'note': core_obj['note'],
        'status': 'core_competency'
    })
    continue  # Skip all comparison logic
```

### **Output Structure:**
```json
{
  "competency_id": 1,
  "competency_name": "Systems Thinking",
  "note": "This core competency develops indirectly...",
  "status": "core_competency"
}
```

### **What's NOT Included:**
- ❌ No `current_level`
- ❌ No `target_level` (in output, though passed to function)
- ❌ No `gap`
- ❌ No `learning_objective` text
- ❌ No `comparison_type`

---

## Trainable Competencies (IDs: 7-18)

### **The 12 Trainable Competencies:**
7. Communication
8. Leadership
9. Self-Organization
10. Project Management
11. Decision Management
12. Information Management
13. Configuration Management
14. Requirements Definition
15. System Architecting
16. Integration, Verification, Validation
17. Operation and Support
18. Agile Methods

### **What the Algorithm Does:**

✅ **Full gap calculation**
1. Calculates median current_level across all users
2. Compares current_level vs target_level
3. Calculates gap if training required
4. Generates learning objective text from template
5. Optionally applies PMT deep customization

### **Algorithm Logic:**
```python
# From task_based_pathway.py lines 336-368
if current_level < target_level:
    # Training required
    gap = target_level - current_level
    learning_objective = get_template_objective(comp_id, target_level)

    trainable_obj = {
        'competency_id': comp_id,
        'competency_name': comp_name,
        'current_level': current_level,
        'target_level': target_level,
        'gap': gap,
        'learning_objective': learning_objective,
        'comparison_type': '2-way',  # Internal metadata
        'status': 'training_required',
        'pmt_customization_applied': pmt_applied
    }
else:
    # Target already achieved
    trainable_obj = {
        'competency_id': comp_id,
        'competency_name': comp_name,
        'current_level': current_level,
        'target_level': target_level,
        'status': 'target_achieved'
    }
```

### **Output Structure (Training Required):**
```json
{
  "competency_id": 7,
  "competency_name": "Communication",
  "current_level": 3,
  "target_level": 4,
  "gap": 1,
  "learning_objective": "Participants are able to communicate constructively...",
  "comparison_type": "2-way",
  "status": "training_required",
  "pmt_customization_applied": false
}
```

### **Output Structure (Target Achieved):**
```json
{
  "competency_id": 8,
  "competency_name": "Leadership",
  "current_level": 5,
  "target_level": 4,
  "status": "target_achieved"
}
```

---

## Frontend Display

### **Core Competencies Section:**
```vue
<el-card>
  <template #header>
    <strong>Systems Thinking</strong>
    <el-tag type="info" size="small">Core Competency</el-tag>
  </template>
  <p>
    This core competency develops indirectly through training in
    other competencies. It will be strengthened through practice...
  </p>
</el-card>
```

**Display:**
- Competency name
- "Core Competency" badge
- Explanatory note
- NO current level
- NO target level
- NO gap
- NO learning objective

### **Trainable Competencies Section:**

**Training Required:**
```vue
<el-card>
  <template #header>
    <strong>Communication</strong>
    <el-tag type="warning">Gap: 1 levels</el-tag>
    <el-tag type="info">Current: 3 → Target: 4</el-tag>
  </template>
  <el-alert type="success">
    <template #title>Learning Objective</template>
    <p>Participants are able to communicate constructively...</p>
  </el-alert>
  <!-- NO "2-way comparison" tag anymore -->
  <div v-if="pmt_customization_applied">
    <el-tag type="success">PMT Customized</el-tag>
  </div>
</el-card>
```

**Target Achieved:**
```vue
<el-card style="background: #f0f9ff;">
  <strong>Leadership</strong>
  <el-tag type="success">Target Achieved</el-tag>
  <p>Current level (5) meets or exceeds target (4)</p>
</el-card>
```

---

## Algorithm Flow Diagram

```
For each competency in all_competencies:

  Is competency in CORE_COMPETENCIES (1,4,5,6)?
  ├─ YES → Generate explanatory note
  │         Add to core_competencies_output[]
  │         SKIP all comparison logic (continue)
  │
  └─ NO → Is this a trainable competency (7-18)?
           │
           ├─ Strategy doesn't target this? (target_level = 0)
           │  └─ Skip (don't include in output)
           │
           └─ Strategy targets this competency
              │
              ├─ current_level < target_level?
              │  ├─ YES → Training Required
              │  │        Calculate gap
              │  │        Generate learning objective
              │  │        Add to trainable_competencies_output[]
              │  │
              │  └─ NO → Target Achieved
              │           Add to trainable_competencies_output[]
              │           with status='target_achieved'
```

---

## Summary Statistics

### **Total Competencies: 16**
- **Core Competencies**: 4 (25%)
  - No gap calculations
  - Only explanatory notes

- **Trainable Competencies**: 12 (75%)
  - Full gap analysis
  - Learning objectives generated
  - Can be "training required" or "target achieved"

### **Typical Strategy Output:**
```json
{
  "strategy_name": "SE for Managers",
  "core_competencies": [
    {...}, {...}, {...}, {...}  // 4 core competencies
  ],
  "trainable_competencies": [
    {...}, {...}, ... // 6-12 trainable competencies
  ],
  "summary": {
    "total_competencies": 14,
    "core_competencies_count": 4,
    "trainable_competencies_count": 10,
    "competencies_requiring_training": 6,
    "competencies_targets_achieved": 4
  }
}
```

---

## Frontend Changes Made

### **Removed:**
- ❌ "2-way comparison" tag from trainable competencies cards
- This was internal metadata not meant for user display

### **Kept:**
- ✅ "PMT Customized" tag (if applicable)
- ✅ Current/Target levels
- ✅ Gap size
- ✅ Learning objective text
- ✅ Status badges

### **Added:**
- ✅ Full cards for core competencies (was just tags before)
- ✅ Explanatory notes displayed prominently
- ✅ "Core Competency" badge

---

## Code References

### **Backend:**
- `src/backend/app/services/task_based_pathway.py:321-330` - Core competency handling
- `src/backend/app/services/learning_objectives_text_generator.py:46` - CORE_COMPETENCIES definition
- `src/backend/app/services/learning_objectives_text_generator.py:387-426` - generate_core_competency_objective()

### **Frontend:**
- `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue:147-166` - Core competencies display
- `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue:105-145` - Trainable competencies display

---

## Design Rationale

### **Why Core Competencies Are Treated Differently:**

1. **Cannot Be Directly Trained**
   - Systems thinking, lifecycle consideration, customer orientation, and modeling are foundational mindsets
   - They develop through experience and practice, not through specific training courses

2. **Develop Indirectly**
   - Strengthened by working on technical competencies
   - Enhanced through real project work
   - Grow through repeated application in various contexts

3. **No Meaningful Gap Calculation**
   - User's current level doesn't directly predict training needs
   - Gap analysis would be misleading
   - Better to acknowledge they develop indirectly

4. **Educational Approach**
   - Inform administrators these competencies exist
   - Explain how they develop
   - Don't create false expectations about direct training

---

## User Experience

### **What Administrators See:**

**Core Competencies Section:**
- Clearly labeled as "Core Competencies (Develop Indirectly)"
- Info alert explaining they develop through other training
- Each displayed in a card with explanatory note
- No confusing gap/target numbers

**Trainable Competencies Section:**
- Clear gap analysis with numbers
- Specific learning objectives
- Training/achievement status
- Optional PMT customization badge

**Result:** Clear distinction between what can be directly trained and what develops indirectly.

---

**Status**: ✅ **COMPLETE**
**Frontend Display**: Updated to match algorithm logic
**Documentation**: Comprehensive explanation provided
