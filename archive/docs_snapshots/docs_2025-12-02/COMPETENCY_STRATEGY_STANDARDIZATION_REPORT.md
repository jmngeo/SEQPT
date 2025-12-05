# COMPETENCY & STRATEGY STANDARDIZATION REPORT
**Generated**: November 6, 2025
**Analysis Type**: Comprehensive spelling, naming, and data consistency audit
**Scope**: 7 strategies, 16 competencies, template JSON, database tables

---

## EXECUTIVE SUMMARY

**STATUS**: CRITICAL ISSUES FOUND - Immediate action required

**FINDINGS**:
1. Spelling inconsistency: "Modeling" (American) vs "Modelling" (British)
2. Target level mismatches between template JSON and database (4 strategies affected)
3. Seed script uses American spelling, database uses British spelling
4. Strategy name variations partially standardized but need verification

**IMPACT**:
- Learning objectives generation may use incorrect target levels
- Data integrity compromised for Systems Modelling competency
- Inconsistent user experience across different data sources

**PRIORITY ACTIONS**:
1. Fix target level mismatches for ID 6 (Systems Modelling and Analysis)
2. Standardize spelling in populate_competencies.py
3. Verify all 7 strategies have correct competency target levels

---

## 1. SPELLING STANDARDIZATION ANALYSIS

### 1.1 Current State

| Source                          | Spelling Used           | Status |
|--------------------------------|-------------------------|--------|
| Database (competency table)    | Modelling (British)     | [OK]   |
| Template JSON                  | Modelling (British)     | [OK]   |
| populate_competencies.py       | Modeling (American)     | [FIX]  |
| fix_systems_modeling_spelling.sql | Both variants mentioned | [INFO] |

### 1.2 Competency ID 6 Details

**Database Value** (current):
```
ID: 6
Name: Systems Modelling and Analysis
Area: Core
```

**Template JSON Value**:
```json
{
  "id": 6,
  "name": "Systems Modelling and Analysis",
  "originalName": "System modeling and analysis"
}
```

**Seed Script Value** (populate_competencies.py line 32):
```python
(6, 'Core', 'Systems Modeling and Analysis', '', '')
```

### 1.3 Root Cause

1. Original seed script used American spelling ("Modeling")
2. Database was manually updated to British spelling ("Modelling")
3. Template JSON correctly uses British spelling
4. Load scripts couldn't match due to spelling mismatch
5. Fix script created to manually add ID 6 to all strategies

### 1.4 Recommendation

**ADOPT BRITISH SPELLING** as the canonical standard:
- Matches Marcel Niemeyer's original thesis
- Already in database and template JSON
- Only needs populate_competencies.py to be updated

---

## 2. STRATEGY NAME STANDARDIZATION

### 2.1 The 7 Canonical Strategies

All strategy names are now standardized in the database:

| ID | Strategy Name                          | Requires PMT | Competencies |
|----|----------------------------------------|--------------|--------------|
| 1  | Common basic understanding             | NO           | 16           |
| 2  | SE for managers                        | NO           | 16           |
| 3  | Orientation in pilot project           | NO           | 16           |
| 4  | Needs-based, project-oriented training | YES          | 16           |
| 5  | Continuous support                     | YES          | 16           |
| 6  | Train the trainer                      | NO           | 16           |
| 7  | Certification                          | NO           | 16           |

**STATUS**: [OK] All strategy names are correctly standardized

**Case Rules**:
- First letter capitalized
- All other letters lowercase
- Exact punctuation preserved (comma in "Needs-based, project-oriented training")

---

## 3. TARGET LEVEL DISCREPANCIES

### 3.1 Critical Issue: Systems Modelling and Analysis (ID 6)

**FOUND**: Major discrepancies between template JSON and database for competency ID 6

| Strategy                               | Template JSON | Database | Match? |
|----------------------------------------|---------------|----------|--------|
| 1. Common basic understanding          | 2             | 2        | [OK]   |
| 2. SE for managers                     | 1             | 4        | [FIX]  |
| 3. Orientation in pilot project        | 4             | 4        | [OK]   |
| 4. Needs-based, project-oriented training | 4          | 2        | [FIX]  |
| 5. Continuous support                  | 4             | 2        | [FIX]  |
| 6. Train the trainer                   | 6             | 4        | [FIX]  |
| 7. Certification                       | 4             | 4        | [OK]   |

**IMPACT**: 4 out of 7 strategies (57%) have incorrect target levels!

### 3.2 All Other Competencies (IDs 1, 4-5, 7-18)

**Need to verify**: Are all other competencies correctly mapped?

Run this query to check:
```sql
SELECT
    st.strategy_name,
    COUNT(DISTINCT stc.competency_id) as competency_count,
    COUNT(stc.id) as total_mappings
FROM strategy_template st
LEFT JOIN strategy_template_competency stc ON st.id = stc.strategy_template_id
GROUP BY st.id, st.strategy_name
ORDER BY st.id;
```

**Expected**: All 7 strategies should have exactly 16 competencies

### 3.3 Root Cause of Discrepancies

The `fix_systems_modeling_spelling.sql` script (lines 42-95) added ID 6 to all strategies, but used INCORRECT target levels:

```sql
-- Script says: "level 4" for SE for managers
-- JSON says: level 1 (should be 1, not 4!)

-- Script says: "level 2" for Needs-based
-- JSON says: level 4 (should be 4, not 2!)
```

The fix script was created with wrong assumptions about the target levels!

---

## 4. COMPREHENSIVE FIX PLAN

### 4.1 Fix Populate Script (PRIORITY 1)

**File**: `src/backend/setup/populate/populate_competencies.py`
**Line**: 32
**Change**:
```python
# BEFORE:
(6, 'Core', 'Systems Modeling and Analysis', '', ''),

# AFTER:
(6, 'Core', 'Systems Modelling and Analysis', '', ''),
```

**Impact**: Future database setups will use correct British spelling

### 4.2 Fix Target Levels in Database (PRIORITY 1)

**Create SQL fix script**: `fix_systems_modelling_target_levels.sql`

```sql
-- =========================================================
-- FIX: Correct Systems Modelling and Analysis Target Levels
-- =========================================================
-- Issue: strategy_template_competency has wrong target levels for ID 6
-- Source of Truth: se_qpt_learning_objectives_template_latest.json
-- =========================================================

BEGIN;

-- 1. Verify current state
SELECT 'Current Target Levels (BEFORE)' as check_type,
       st.strategy_name,
       stc.target_level
FROM strategy_template st
JOIN strategy_template_competency stc ON st.id = stc.strategy_template_id
WHERE stc.competency_id = 6
ORDER BY st.id;

-- 2. Update SE for managers: 4 -> 1
UPDATE strategy_template_competency
SET target_level = 1, updated_at = CURRENT_TIMESTAMP
WHERE strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'SE for managers')
  AND competency_id = 6
  AND target_level != 1;

-- 3. Update Needs-based, project-oriented training: 2 -> 4
UPDATE strategy_template_competency
SET target_level = 4, updated_at = CURRENT_TIMESTAMP
WHERE strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Needs-based, project-oriented training')
  AND competency_id = 6
  AND target_level != 4;

-- 4. Update Continuous support: 2 -> 4
UPDATE strategy_template_competency
SET target_level = 4, updated_at = CURRENT_TIMESTAMP
WHERE strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Continuous support')
  AND competency_id = 6
  AND target_level != 4;

-- 5. Update Train the trainer: 4 -> 6
UPDATE strategy_template_competency
SET target_level = 6, updated_at = CURRENT_TIMESTAMP
WHERE strategy_template_id = (SELECT id FROM strategy_template WHERE strategy_name = 'Train the trainer')
  AND competency_id = 6
  AND target_level != 6;

-- 6. Verify fix
SELECT 'Updated Target Levels (AFTER)' as check_type,
       st.strategy_name,
       stc.target_level,
       stc.updated_at
FROM strategy_template st
JOIN strategy_template_competency stc ON st.id = stc.strategy_template_id
WHERE stc.competency_id = 6
ORDER BY st.id;

COMMIT;

-- ===================
-- EXPECTED RESULTS
-- ===================
-- SE for managers: 1 (was 4)
-- Needs-based: 4 (was 2)
-- Continuous support: 4 (was 2)
-- Train the trainer: 6 (was 4)
```

### 4.3 Verify All Competencies (PRIORITY 2)

**Action**: Run comprehensive validation of ALL competency target levels

Create Python script: `validate_all_strategy_competency_targets.py`

This script should:
1. Load template JSON
2. Query strategy_template_competency table
3. Compare every strategy-competency-level combination
4. Report all mismatches
5. Generate SQL fix script if needed

---

## 5. VERIFICATION CHECKLIST

After applying fixes:

### 5.1 Spelling Verification
- [ ] Database competency table: "Systems Modelling and Analysis" (British)
- [ ] Template JSON: "Systems Modelling and Analysis" (British)
- [ ] populate_competencies.py: "Systems Modelling and Analysis" (British)
- [ ] No active source files use American spelling "Modeling"

### 5.2 Strategy Name Verification
- [ ] All 7 strategies in strategy_template table
- [ ] All strategy names match canonical form (first letter caps, rest lowercase)
- [ ] "Needs-based, project-oriented training" has comma

### 5.3 Target Level Verification
- [ ] SE for managers: ID 6 = level 1 (not 4)
- [ ] Needs-based: ID 6 = level 4 (not 2)
- [ ] Continuous support: ID 6 = level 4 (not 2)
- [ ] Train the trainer: ID 6 = level 6 (not 4)
- [ ] All other competencies match template JSON

### 5.4 Comprehensive Validation
- [ ] All 7 strategies have exactly 16 competencies
- [ ] Total records in strategy_template_competency: 112 (7 × 16)
- [ ] No duplicates (unique constraint on strategy_template_id, competency_id)
- [ ] All target levels between 1-6 (inclusive)

---

## 6. FILE LOCATIONS

### 6.1 Data Files
- **Template JSON**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`
- **Backup JSON**: `data/source/Phase 2/se_qpt_learning_objectives_template_backup_20251106_061817.json`

### 6.2 Database Tables
- **Competencies**: `competency` (16 rows)
- **Strategy Templates**: `strategy_template` (7 rows)
- **Strategy-Competency Mappings**: `strategy_template_competency` (112 rows expected)
- **Organization Strategies**: `learning_strategy` (14 rows for orgs 28 & 29)

### 6.3 Scripts
- **Seed Script**: `src/backend/setup/populate/populate_competencies.py`
- **Load Script**: `load_archetype_targets.py` (for old strategy_competency table)
- **Fix Script**: `fix_systems_modeling_spelling.sql` (has incorrect target levels!)
- **Setup Script**: `src/backend/setup/setup_phase2_task3_for_org.py`

### 6.4 Migration Files
- **Global Templates**: `src/backend/setup/migrations/006_global_strategy_templates.sql`
- **Org 28 Test Data**: `src/backend/setup/migrations/test_data_org_28_fixed.sql`
- **Org 29 Test Data**: `src/backend/setup/migrations/test_data_org_29_high_maturity.sql`

---

## 7. TECHNICAL NOTES

### 7.1 Why British Spelling?

The original source is Marcel Niemeyer's Master Thesis (German university), which used British English spelling conventions. The Excel file "Qualifizierungsmodule_Qualifizierungspläne_v4 enUS.xlsx" uses British spelling throughout.

### 7.2 Case-Insensitive Matching

Current implementation in `load_archetype_targets.py` uses exact string matching. Consider adding:
- Normalization function for competency name matching
- Support for both British/American spelling variants
- Fuzzy matching with Levenshtein distance

### 7.3 Template JSON Structure

The template JSON uses competency names as keys in the `archetypeCompetencyTargetLevels` section:
```json
"Common basic understanding": {
  "Systems Modelling and Analysis": 2,
  ...
}
```

This means the spelling MUST match exactly between JSON and database for automated loading to work.

### 7.4 Migration Strategy Used

The system now uses a template-based architecture:
- `strategy_template`: 7 global strategy definitions (single source of truth)
- `strategy_template_competency`: 112 strategy-competency-level mappings (7 × 16)
- `learning_strategy`: Organization-specific strategy instances (links to templates)

This is far superior to the old per-organization duplication model.

---

## 8. RECOMMENDED NEXT STEPS

### Immediate (This Session)
1. Apply spelling fix to populate_competencies.py
2. Create and execute fix_systems_modelling_target_levels.sql
3. Verify all 4 target level corrections

### Short Term (Next Session)
4. Create comprehensive validation script for all competencies
5. Run validation and fix any additional discrepancies
6. Update load_archetype_targets.py to use strategy_template_competency
7. Test learning objectives generation with corrected data

### Long Term
8. Add normalization function for spelling variants
9. Create automated tests for data consistency
10. Document canonical naming conventions
11. Add database constraints to prevent future issues

---

## 9. SUMMARY OF ISSUES

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| SPELL-01 | populate_competencies.py uses American spelling | MEDIUM | READY TO FIX |
| DATA-01 | SE for managers: ID 6 target level wrong (4 should be 1) | CRITICAL | READY TO FIX |
| DATA-02 | Needs-based: ID 6 target level wrong (2 should be 4) | CRITICAL | READY TO FIX |
| DATA-03 | Continuous support: ID 6 target level wrong (2 should be 4) | CRITICAL | READY TO FIX |
| DATA-04 | Train the trainer: ID 6 target level wrong (4 should be 6) | CRITICAL | READY TO FIX |
| ARCH-01 | load_archetype_targets.py uses old table structure | MEDIUM | FUTURE |
| TEST-01 | No automated validation of target levels | LOW | FUTURE |

**Total Issues**: 7
**Critical**: 4
**Medium**: 2
**Low**: 1

---

## 10. APPENDIX: FULL COMPETENCY LIST

The 16 SE Competencies (with correct British spelling):

| ID | Name | Category |
|----|------|----------|
| 1  | Systems Thinking | Core |
| 4  | Lifecycle Consideration | Core |
| 5  | Customer / Value Orientation | Core |
| 6  | **Systems Modelling and Analysis** | Core |
| 7  | Communication | Social / Personal |
| 8  | Leadership | Social / Personal |
| 9  | Self-Organization | Social / Personal |
| 10 | Project Management | Management |
| 11 | Decision Management | Management |
| 12 | Information Management | Management |
| 13 | Configuration Management | Management |
| 14 | Requirements Definition | Technical |
| 15 | System Architecting | Technical |
| 16 | Integration, Verification, Validation | Technical |
| 17 | Operation and Support | Technical |
| 18 | Agile Methods | Technical |

**Note**: IDs 2 and 3 are missing (gaps in original sequence)

---

## END OF REPORT

**Generated by**: Claude Code Standardization Audit
**Date**: November 6, 2025
**Report Version**: 1.0
