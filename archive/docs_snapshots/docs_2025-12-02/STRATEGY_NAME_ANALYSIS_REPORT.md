# Strategy Name Analysis Report
**Date**: November 6, 2025
**Status**: CRITICAL ISSUES FOUND

---

## Executive Summary

**CRITICAL PROBLEMS IDENTIFIED**:
1. **Missing "Certification" strategy** in template JSON and org 29
2. **"Train the SE-Trainer" NOT in template JSON** (appears in both orgs)
3. **Naming inconsistencies** across all sources
4. **Org 29 has 0 competencies** for "Common Basic Understanding"
5. **Duplicate strategies in org 29** with different capitalizations

---

## 1. Template JSON Strategies (GOLDEN REFERENCE)

**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

| # | Strategy Name (Exact Case) | Has Competencies? |
|---|---------------------------|-------------------|
| 1 | Common basic understanding | YES (15 comps) |
| 2 | SE for managers | YES (15 comps) |
| 3 | Orientation in pilot project | YES (15 comps) |
| 4 | Needs-based, project-oriented training | YES (15 comps) |
| 5 | Continuous support | YES (15 comps) |
| 6 | Train the trainer | YES (15 comps) |

**TOTAL**: 6 strategies in template

**MISSING**:
- [CRITICAL] "Certification" - NOT IN TEMPLATE
- [CRITICAL] "Train the SE-Trainer" - NOT IN TEMPLATE

---

## 2. Organization 28 Strategies (PRODUCTION DATA)

| ID | Strategy Name (Database) | Selected | Competencies | Match Template? |
|----|-------------------------|----------|--------------|----------------|
| 12 | Needs-based Project-oriented Training | YES | 15 | PARTIAL (case + hyphen) |
| 13 | Common Basic Understanding | YES | 15 | PARTIAL (case mismatch) |
| 14 | SE for Managers | YES | 15 | PARTIAL (case mismatch) |
| 16 | Orientation in Pilot Project | YES | 15 | PARTIAL (case mismatch) |
| 17 | **Certification** | YES | **16** | **NO - NOT IN TEMPLATE!** |
| 18 | Continuous Support | YES | 15 | PARTIAL (case mismatch) |
| 19 | Train the Trainer | NO | 15 | PARTIAL (case mismatch) |
| 21 | **Train the SE-Trainer** | YES | 15 | **NO - NOT IN TEMPLATE!** |

**TOTAL**: 8 strategies
**ISSUES**:
- Has "Certification" (16 comps) - NOT in template JSON
- Has "Train the SE-Trainer" (15 comps) - NOT in template JSON
- Has duplicate concept: "Train the Trainer" (ID 19) + "Train the SE-Trainer" (ID 21)
- Case inconsistencies on all strategies

---

## 3. Organization 29 Strategies (CURRENT TEST ORG)

| ID | Strategy Name (Database) | Selected | Competencies | Match Template? |
|----|-------------------------|----------|--------------|----------------|
| 25 | Needs-based project-oriented training | NO | 15 | PARTIAL (case) |
| 26 | SE for managers | NO | 15 | EXACT MATCH! |
| 27 | Train the SE-trainer | NO | 15 | NO - NOT IN TEMPLATE |
| 28 | **Train the SE-Trainer** | NO | 15 | **DUPLICATE of 27!** |
| 29 | **Needs-based Project-oriented Training** | NO | 15 | **DUPLICATE of 25!** |
| 30 | Common Basic Understanding | YES | **0** | **CRITICAL - NO DATA!** |

**TOTAL**: 6 strategies
**CRITICAL ISSUES**:
1. **"Common Basic Understanding" (ID 30) has 0 competencies!**
2. **Duplicate "Train the SE-Trainer"** (IDs 27 + 28, different case)
3. **Duplicate "Needs-based Project-oriented Training"** (IDs 25 + 29, different case)
4. **Missing "Certification"** strategy
5. **Missing "Orientation in Pilot Project"** strategy
6. **Missing "Continuous Support"** strategy

---

## 4. Naming Discrepancies Matrix

### 4.1 "Needs-based project-oriented training"

| Source | Exact Name | Notes |
|--------|-----------|-------|
| Template JSON | `Needs-based, project-oriented training` | WITH COMMA |
| Org 28 (ID 12) | `Needs-based Project-oriented Training` | NO COMMA, caps |
| Org 29 (ID 25) | `Needs-based project-oriented training` | NO COMMA, lowercase |
| Org 29 (ID 29) | `Needs-based Project-oriented Training` | NO COMMA, caps |

**Issue**: Template has comma, databases don't. Case mismatches everywhere.

### 4.2 "Train the Trainer" vs "Train the SE-Trainer"

| Source | Exact Name | Notes |
|--------|-----------|-------|
| Template JSON | `Train the trainer` | Lowercase |
| Org 28 (ID 19) | `Train the Trainer` | Capitalized, NOT selected |
| Org 28 (ID 21) | `Train the SE-Trainer` | "SE-" prefix, SELECTED |
| Org 29 (ID 27) | `Train the SE-trainer` | "SE-" prefix, lowercase 't' |
| Org 29 (ID 28) | `Train the SE-Trainer` | "SE-" prefix, capital 'T' |

**Issue**:
- Template has "Train the trainer"
- Orgs have "Train the SE-Trainer" (not in template)
- Org 28 has BOTH variants
- Org 29 has duplicate "Train the SE-Trainer" with case difference

### 4.3 "Common Basic Understanding"

| Source | Exact Name | Notes |
|--------|-----------|-------|
| Template JSON | `Common basic understanding` | All lowercase except 'C' |
| Org 28 (ID 13) | `Common Basic Understanding` | All words capitalized |
| Org 29 (ID 30) | `Common Basic Understanding` | All words capitalized, **0 comps!** |

**CRITICAL**: Org 29's "Common Basic Understanding" has **ZERO competencies loaded!**

---

## 5. Missing Strategies

### 5.1 Missing from Org 29 (vs Org 28 Golden Reference)

| Strategy Name | In Org 28? | In Org 29? | In Template? | Action Needed |
|---------------|-----------|-----------|--------------|---------------|
| Certification | YES (ID 17) | **NO** | **NO** | Add to org 29? Or remove from org 28? |
| Orientation in Pilot Project | YES (ID 16) | **NO** | YES | Add to org 29 |
| Continuous Support | YES (ID 18) | **NO** | YES | Add to org 29 |

### 5.2 Strategies NOT in Template JSON

| Strategy Name | In Org 28? | In Org 29? | In Template? | Issue |
|---------------|-----------|-----------|--------------|-------|
| Certification | YES (16 comps) | NO | **NO** | Where did this come from? |
| Train the SE-Trainer | YES (ID 21, 15 comps) | YES (IDs 27+28) | **NO** | Should be "Train the trainer" |

---

## 6. Competency Count Discrepancies

| Organization | Strategy | Competency Count | Expected | Status |
|--------------|----------|------------------|----------|--------|
| Org 28 | Certification | 16 | 15 | EXTRA 1 competency |
| Org 28 | All others | 15 | 15 | OK |
| Org 29 | Common Basic Understanding | **0** | 15 | **CRITICAL FAILURE** |
| Org 29 | All others | 15 | 15 | OK |

**CRITICAL**: Why does "Certification" have 16 competencies instead of 15?

---

## 7. Root Causes

### 7.1 Why "Certification" is NOT in Template

The template JSON was likely created from Marcel Niemeyer's research which defined 6 core learning strategies:
1. Common basic understanding
2. SE for managers
3. Orientation in pilot project
4. Needs-based, project-oriented training
5. Continuous support
6. Train the trainer

"Certification" appears to be a custom addition for org 28 that was never reflected back into the template.

### 7.2 Why "Train the SE-Trainer" Exists

This appears to be a naming variation of "Train the trainer" with the "SE-" prefix added. Org 28 has BOTH:
- ID 19: "Train the Trainer" (NOT selected)
- ID 21: "Train the SE-Trainer" (SELECTED)

This suggests someone created a variant but it was never standardized.

### 7.3 Why Org 29 Has 0 Competencies for "Common Basic Understanding"

Looking at the `load_archetype_targets.py` script output:
```
[SUCCESS] Loaded 196 archetype target levels
Strategy 29 has 15 competency targets
```

Strategy ID 29 is "Needs-based Project-oriented Training" (the duplicate).
Strategy ID 30 "Common Basic Understanding" was likely not matched during the loading process.

**Possible cause**: The script uses case-insensitive matching, but there might be whitespace or punctuation differences.

---

## 8. Recommended Fixes (Priority Order)

### HIGH PRIORITY (Blocks Learning Objectives Generation)

1. **Fix Org 29 "Common Basic Understanding" - 0 competencies**
   - Strategy ID 30 has NO competency data
   - Need to reload competencies from template
   - Match template name: "Common basic understanding"

2. **Remove Duplicate Strategies in Org 29**
   - DELETE ID 27 "Train the SE-trainer" (lowercase t)
   - KEEP ID 28 "Train the SE-Trainer" (if needed) OR replace with "Train the trainer"
   - DELETE ID 25 "Needs-based project-oriented training" (lowercase)
   - KEEP ID 29 "Needs-based Project-oriented Training" (currently has data)

3. **Add Missing Strategies to Org 29**
   - Add "Orientation in Pilot Project" (from template + org 28)
   - Add "Continuous Support" (from template + org 28)

### MEDIUM PRIORITY (Data Standardization)

4. **Standardize Strategy Names to Match Template**
   - Update all strategy names to match template JSON exactly
   - Use lowercase as in template: "Common basic understanding" not "Common Basic Understanding"
   - Fix "Needs-based, project-oriented training" (with comma)

5. **Resolve "Train the SE-Trainer" vs "Train the trainer"**
   - Decide: Keep template name "Train the trainer" OR use "Train the SE-Trainer"
   - If keeping "Train the SE-Trainer", add it to template JSON
   - If using template, rename all instances to "Train the trainer"

### LOW PRIORITY (Documentation/Cleanup)

6. **Resolve "Certification" Strategy**
   - Decision needed: Is this a valid 7th strategy or org 28-specific?
   - If valid: Add to template JSON with competency mappings
   - If org 28-specific: Document as custom strategy, don't expect in template

7. **Investigate Why "Certification" Has 16 Competencies**
   - All other strategies have 15 competencies
   - Certification has 16 - which extra competency?

---

## 9. Immediate Action Items

### For Next Session:

1. **Run `load_archetype_targets.py` diagnostics**:
   ```bash
   python load_archetype_targets.py --debug --org-id 29
   ```
   - Check why "Common Basic Understanding" didn't load
   - Check case-insensitive matching logic

2. **Check strategy_competency for org 29 strategy ID 30**:
   ```sql
   SELECT * FROM strategy_competency WHERE strategy_id = 30;
   ```
   - Should return 0 rows (confirming the issue)

3. **Manually load competencies for strategy ID 30**:
   ```sql
   -- Copy from a working strategy as reference
   INSERT INTO strategy_competency (strategy_id, competency_id, target_level)
   SELECT 30, competency_id, target_level
   FROM strategy_competency
   WHERE strategy_id = 13  -- Org 28's "Common Basic Understanding"
   ```

4. **Delete duplicate strategies in org 29**:
   ```sql
   DELETE FROM learning_strategy WHERE id IN (25, 27);
   ```

5. **Add missing strategies to org 29**:
   ```sql
   INSERT INTO learning_strategy (organization_id, strategy_name, selected, priority)
   VALUES
     (29, 'Orientation in Pilot Project', false, 4),
     (29, 'Continuous Support', false, 5);
   ```

---

## 10. Questions for User

1. **Is "Certification" a valid 7th strategy, or org 28-specific?**
   - If valid: Need to add to template JSON
   - If org 28-specific: Document and exclude from template matching

2. **Should we use "Train the trainer" (template) or "Train the SE-Trainer" (org 28)?**
   - Affects both template and database naming
   - Need consistency across all orgs

3. **Should strategy names be case-sensitive or case-insensitive?**
   - Template uses lowercase: "Common basic understanding"
   - Databases use title case: "Common Basic Understanding"
   - Which should be the standard?

---

## 11. Impact on Learning Objectives Generation

### Current Blockers:

1. **Org 29 will FAIL to generate objectives** because:
   - "Common Basic Understanding" (ID 30, selected=true) has 0 competencies
   - Algorithm will find no target levels for this strategy
   - Will return error or empty results

2. **Strategy name matching will fail** because:
   - Template has "Needs-based, project-oriented training" (with comma)
   - Database has "Needs-based Project-oriented Training" (no comma)
   - Case-insensitive matching might work, but punctuation won't

3. **Missing strategies in org 29**:
   - Can't select "Continuous Support" (not in database)
   - Can't select "Orientation in Pilot Project" (not in database)

---

## 12. Recommended Golden Standard

### Canonical Strategy Names (Use These Everywhere)

1. `Common basic understanding`
2. `SE for managers`
3. `Orientation in pilot project`
4. `Needs-based, project-oriented training`  (WITH COMMA)
5. `Continuous support`
6. `Train the trainer`  (OR decide to change to "Train the SE-Trainer")
7. `Certification` (IF approved as 7th strategy)

**Rules**:
- All lowercase except first letter
- Use exact punctuation from template
- No variations or duplicates

---

## END OF REPORT

**Next Steps**: Fix org 29 strategy issues before attempting to generate learning objectives.
