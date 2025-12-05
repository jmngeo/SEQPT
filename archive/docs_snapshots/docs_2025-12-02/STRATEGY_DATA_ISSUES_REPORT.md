# Strategy Data Issues Report - Organization 28

**Date**: 2025-11-05
**Organization**: 28 (Lowmaturity ORG)
**Issue**: Data inconsistencies between database and template

---

## Issues Found

### ❌ **Issue 1: "Train the SE-Trainer" Missing Competency Mappings**

**Problem**: Strategy 21 had 0 competency mappings

**Status**: ✅ **FIXED**

**Solution**: Added 16 competency mappings with target level 6 for all competencies

```sql
INSERT INTO strategy_competency (strategy_id, competency_id, target_level)
VALUES (21, 1, 6), (21, 4, 6), ... (21, 18, 6);
```

---

### ⚠️ **Issue 2: "Certification" Doesn't Exist in Template**

**Problem**:
- Database has strategy 17 "Certification" (selected)
- Template does NOT include "Certification" as an archetype
- "Certification" has identical target levels as "Orientation in Pilot Project" (all level 4)

**Template Archetypes** (only 6):
1. Common basic understanding
2. SE for managers
3. Orientation in pilot project
4. Needs-based, project-oriented training
5. Continuous support
6. Train the trainer

**Status**: ⚠️ **UNRESOLVED** - Needs decision

**Options**:
1. Delete "Certification" strategy (ID 17)
2. Keep it as a custom organization-specific strategy
3. Give it different target levels to differentiate from "Orientation in Pilot Project"

---

### ⚠️ **Issue 3: Duplicate "Train the Trainer" Strategies**

**Problem**: Two strategies with similar names:
- Strategy 19: "Train the Trainer" (NOT selected) - exact template match
- Strategy 21: "Train the SE-Trainer" (IS selected) - custom name

**Comparison**:
| ID | Strategy Name | Selected | Competency Mappings | Template Match |
|----|---------------|----------|---------------------|----------------|
| 19 | Train the Trainer | ❌ No | Unknown | ✅ Exact |
| 21 | Train the SE-Trainer | ✅ Yes | 16 (level 6) | ⚠️ Similar |

**Status**: ⚠️ **UNRESOLVED** - Needs decision

**Recommendations**:
- Use **strategy 19** and deselect 21 (aligns with template)
- OR rename strategy 21 to "Train the Trainer" for consistency
- OR keep both if they serve different purposes

---

### ✅ **Issue 4: "Orientation in Pilot Project" and "Certification" are Identical**

**Problem**: Both have exactly the same competency targets

**Verification**:
```
Competency ID | Orientation Target | Certification Target
1             | 4                  | 4                    [SAME]
4             | 4                  | 4                    [SAME]
5             | 4                  | 4                    [SAME]
... (all 16 competencies)
18            | 4                  | 4                    [SAME]
```

**Status**: ✅ **ROOT CAUSE IDENTIFIED**

**Root Cause**: "Certification" is a duplicate/copy of "Orientation in Pilot Project" but not in the original design

---

## Current State

### **Template vs Database Comparison**

| # | Template Name | Database ID | Database Name | Selected | Mappings | Match |
|---|---------------|-------------|---------------|----------|----------|-------|
| 1 | Common basic understanding | 13 | Common Basic Understanding | ✅ Yes | 16 | ✅ Match |
| 2 | SE for managers | 14 | SE for Managers | ✅ Yes | 16 | ✅ Match |
| 3 | Orientation in pilot project | 16 | Orientation in Pilot Project | ✅ Yes | 16 | ✅ Match |
| 4 | Needs-based, project-oriented training | 12 | Needs-based Project-oriented Training | ✅ Yes | 16 | ✅ Match |
| 5 | Continuous support | 18 | Continuous Support | ✅ Yes | 16 | ✅ Match |
| 6 | Train the trainer | 19 | Train the Trainer | ❌ No | ? | ✅ Match |
| - | *(not in template)* | 17 | **Certification** | ✅ Yes | 16 | ❌ Extra |
| 6 | Train the trainer | 21 | **Train the SE-Trainer** | ✅ Yes | 16 | ⚠️ Similar |

### **Summary**:
- **7 strategies selected** (should be 6 based on template)
- **1 duplicate**: "Certification" (not in template)
- **1 naming variation**: "Train the SE-Trainer" vs "Train the Trainer"

---

## Validation Results

### **Strategies with Correct Objectives** ✅

| Strategy ID | Strategy Name | Competencies | Objectives Generated |
|-------------|---------------|--------------|----------------------|
| 12 | Needs-based Project-oriented Training | 16 | ✅ Yes |
| 13 | Common Basic Understanding | 16 | ✅ Yes |
| 14 | SE for Managers | 16 | ✅ Yes |
| 16 | Orientation in Pilot Project | 16 | ✅ Yes |
| 17 | **Certification** | 16 | ✅ Yes *(but identical to 16)* |
| 18 | Continuous Support | 16 | ✅ Yes |
| 21 | **Train the SE-Trainer** | 16 | ✅ Yes *(now fixed)* |

**All selected strategies now generate objectives correctly!**

---

## Recommendations

### **Immediate Actions** (Data Cleanup)

1. **Decide on "Certification"**:
   ```sql
   -- Option A: Delete it (not in template)
   DELETE FROM strategy_competency WHERE strategy_id = 17;
   DELETE FROM learning_strategy WHERE id = 17;

   -- Option B: Keep but give different targets
   -- (Requires manual updates to strategy_competency table)

   -- Option C: Just deselect it
   UPDATE learning_strategy SET selected = false WHERE id = 17;
   ```

2. **Consolidate "Train the Trainer" strategies**:
   ```sql
   -- Option A: Use template-matching strategy 19, deselect 21
   UPDATE learning_strategy SET selected = true WHERE id = 19;
   UPDATE learning_strategy SET selected = false WHERE id = 21;
   -- Then add competency mappings to strategy 19

   -- Option B: Rename strategy 21 to match template
   UPDATE learning_strategy
   SET strategy_name = 'Train the Trainer'
   WHERE id = 21;

   -- Option C: Keep both if they serve different purposes
   -- (No action needed)
   ```

### **For Future Organizations**

1. **Strategy Initialization**:
   - Use ONLY the 6 template archetypes
   - Don't create custom strategies unless specifically designed
   - Ensure strategy names match template exactly for proper text generation

2. **Competency Mapping Validation**:
   - Verify all strategies have 16 competency mappings
   - Check targets match template specifications
   - Validate no duplicate strategies with identical targets

---

## Testing After Fixes

### **Test Objectives Generation**

1. Navigate to: `http://localhost:3000/app/phases/2/admin/learning-objectives?orgId=28`
2. Click "Generate Learning Objectives"
3. Verify all 7 strategy tabs show results:
   - ✅ Common Basic Understanding
   - ✅ SE for Managers
   - ✅ Orientation in Pilot Project
   - ✅ Needs-based Project-oriented Training
   - ✅ Continuous Support
   - ⚠️ **Certification** (duplicate of Orientation)
   - ✅ **Train the SE-Trainer** (now has objectives)

### **Expected Behavior**

**"Train the SE-Trainer"** should show:
- **Target level**: 6 for ALL competencies (master/trainer level)
- **Gap**: Larger gaps (most users at level 2-3, target is 6)
- **Learning objectives**: Master-level objectives for all 12 trainable competencies
- **Core competencies**: Same explanatory note (4 core competencies)

**"Certification"** will show:
- Identical results to "Orientation in Pilot Project"
- This confirms they're duplicates

---

## Database Queries for Verification

### **Check all strategy competency counts**:
```sql
SELECT ls.id, ls.strategy_name, ls.selected,
       COUNT(sc.id) as competency_count,
       string_agg(DISTINCT sc.target_level::text, ',' ORDER BY sc.target_level::text) as targets
FROM learning_strategy ls
LEFT JOIN strategy_competency sc ON ls.id = sc.strategy_id
WHERE ls.organization_id = 28
GROUP BY ls.id, ls.strategy_name, ls.selected
ORDER BY ls.id;
```

### **Compare Orientation vs Certification**:
```sql
SELECT
  sc1.competency_id,
  sc1.target_level as orientation_target,
  sc2.target_level as certification_target,
  CASE WHEN sc1.target_level = sc2.target_level
       THEN 'SAME' ELSE 'DIFFERENT' END as comparison
FROM strategy_competency sc1
FULL OUTER JOIN strategy_competency sc2
  ON sc1.competency_id = sc2.competency_id
WHERE sc1.strategy_id = 16 AND sc2.strategy_id = 17
ORDER BY sc1.competency_id;
```

### **Check "Train the SE-Trainer" mappings**:
```sql
SELECT competency_id, target_level
FROM strategy_competency
WHERE strategy_id = 21
ORDER BY competency_id;
```

---

## Summary

### **Fixed** ✅
- [x] "Train the SE-Trainer" now has 16 competency mappings at level 6
- [x] All selected strategies generate learning objectives

### **Identified Issues** ⚠️
- [ ] "Certification" is not in template and duplicates "Orientation in Pilot Project"
- [ ] Two "Train the Trainer" strategies exist (19 and 21)
- [ ] 7 strategies selected instead of 6 standard archetypes

### **Decision Needed** 🤔
- Should "Certification" be removed or kept as custom strategy?
- Should strategies 19 and 21 be consolidated?
- Should we enforce template-only strategies for consistency?

---

**Status**: Objectives generation now works for all selected strategies, but data cleanup recommended for long-term consistency.
