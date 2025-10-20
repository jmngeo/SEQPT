# Phase 1 - SE-QPT Questionnaire Implementation Complete

## Summary

Successfully implemented comprehensive Phase 1 questionnaire system with BRETZ maturity model and dual-path archetype selection logic.

**Date:** 2025-10-13
**Scope:** Major update to Phase 1 questionnaires and backend logic
**Status:** IMPLEMENTED - Ready for Testing

---

## What Was Implemented

### 1. Maturity Assessment Questionnaire (12 Questions)

**File:** `data/source/questionnaires/phase1/maturity_assessment.json`

**Structure:**
- **12 comprehensive questions** organized in 4 sections (BRETZ model):
  - **Section A: Fundamentals** (25% weight) - MAT_01 to MAT_03
  - **Section B: Organization** (30% weight) - MAT_04 to MAT_07
  - **Section C: Process Capability** (25% weight) - MAT_08 to MAT_10
  - **Section D: Infrastructure** (20% weight) - MAT_11 to MAT_12

**Key Features:**
- Each question has weighted importance within its section
- Questions use 0-4 or 0-5 scoring scales
- **MAT_04** (SE Roles and Processes) - Marked as `routing_critical` for archetype path selection
- **MAT_05** (Rollout Scope) - Marked as `routing_critical` for high maturity archetype selection
- Hierarchical weighted average scoring algorithm
- Maturity level classification (Initial, Developing, Defined, Managed, Optimized)

**Scoring Algorithm:**
```
Section Score = Σ(Question_Score × Question_Weight) / Σ(Question_Weights)
Overall Maturity = Σ(Section_Score × Section_Weight) / Σ(Section_Weights)
```

**Routing Variables Extracted:**
- `process_maturity`: MAT_04 score
- `rollout_scope`: MAT_05 score

---

### 2. Archetype Selection Questionnaire (7 Questions with Adaptive Routing)

**File:** `data/source/questionnaires/phase1/archetype_selection.json`

**Dual-Path Structure:**

#### Low Maturity Path (MAT_04 ≤ 1)
Questions shown to organizations with undeveloped SE processes:
- **ARCH_01**: Company Preference (Decisive question - weight 1.0)
  - Options map to secondary archetypes:
    - "Apply SE in pilot" → Orientation in Pilot Project
    - "Build basic understanding" → Common Basic Understanding
    - "Develop SE experts" → Certification
- **ARCH_02**: Management Readiness (weight 0.30)
- **ARCH_03**: Pilot Project Availability (conditional on ARCH_01 = "apply_pilot")

**Result:** Dual selection - Primary: "SE for Managers" + Secondary based on ARCH_01

#### High Maturity Path (MAT_04 > 1)
Questions shown to organizations with established SE processes:
- **ARCH_04**: SE Application Breadth (Auto-calculated from MAT_05)
  - Logic determines single archetype recommendation
- **ARCH_05**: Learning Preference (weight 0.40)
  - Project-specific / Continuous / Self-directed / Blended

**Result:** Single selection based on MAT_05:
- MAT_05 ≤ 1 → "Needs-based Project-oriented Training"
- MAT_05 ≥ 2 → "Continuous Support"

#### Common Questions (All Paths)
- **ARCH_06**: Number of Participants (weight 0.35)
  - 1-5 / 6-15 / 16-50 / 50+
- **ARCH_07**: Implementation Timeline (weight 0.35)
  - 1-3 months / 3-6 months / 6-12 months / 12+ months

**Supplementary Evaluation:**
- **Train the Trainer** suggested if:
  - ARCH_06 = "enterprise" (50+ participants) OR
  - ARCH_07 = "long" (12+ months)

**7 Archetypes Mapped:**
1. SE for Managers (Low maturity primary - always selected)
2. Orientation in Pilot Project (Low maturity secondary option)
3. Common Basic Understanding (Low maturity secondary option)
4. Certification (Low maturity secondary option)
5. Needs-based Project-oriented Training (High maturity, limited scope)
6. Continuous Support (High maturity, broad scope)
7. Train the Trainer (Supplementary evaluation)

---

### 3. Backend Route Updates

**File:** `src/competency_assessor/app/routes.py`

**Updated Endpoint:** `/api/seqpt/phase1/archetype-selection` (Lines 1784-1906)

**New Logic:**
- Accepts `maturity_responses` with MAT_04 and MAT_05 scores
- Accepts `responses` with archetype questionnaire answers
- Implements dual-path decision tree:

```python
if MAT_04 <= 1:
    # Low Maturity: Dual Selection
    primary = "SE for Managers"
    if ARCH_01 == "apply_pilot":
        secondary = "Orientation in Pilot Project"
    elif ARCH_01 == "build_awareness":
        secondary = "Common Basic Understanding"
    elif ARCH_01 == "develop_experts":
        secondary = "Certification"

    result = primary + secondary

else:
    # High Maturity: Single Selection
    if MAT_05 <= 1:
        result = "Needs-based Project-oriented Training"
    else:
        result = "Continuous Support"

# Supplementary Evaluation
if ARCH_06 == "enterprise" or ARCH_07 == "long":
    supplementary.append("Train the Trainer")
```

**Response Format:**
```json
{
  "success": true,
  "archetype": {
    "name": "SE for Managers + Common Basic Understanding",
    "primary": "SE for Managers",
    "secondary": "Common Basic Understanding",
    "supplementary": [
      {
        "name": "Train the Trainer",
        "rationale": "Large-scale implementation benefits..."
      }
    ],
    "selection_type": "dual",
    "requires_dual_processing": true,
    "rationale": "Low SE maturity requires...",
    "details": {}
  }
}
```

---

## Files Modified

### Updated Files:
1. `data/source/questionnaires/phase1/maturity_assessment.json`
   - Replaced 3 questions with 12 BRETZ questions
   - Added section structure with weights
   - Added routing_critical flags to MAT_04 and MAT_05

2. `data/source/questionnaires/phase1/archetype_selection.json`
   - Replaced simple 4 questions with 7-question adaptive system
   - Added routing logic based on MAT_04
   - Added conditional question display
   - Added complete decision tree with 7 archetypes

3. `src/competency_assessor/app/routes.py`
   - Updated `/api/seqpt/phase1/archetype-selection` endpoint (lines 1784-1906)
   - Implemented dual-path logic using MAT_04 and MAT_05
   - Added supplementary archetype evaluation

### Backup Files Created:
- `data/source/questionnaires/phase1/maturity_assessment_backup_old.json`
- `data/source/questionnaires/phase1/archetype_selection_backup_old.json`

---

## Key Decision Logic

### Maturity Level Calculation

**Question Weights by Section:**
- Fundamentals: MAT_01 (0.35), MAT_02 (0.30), MAT_03 (0.35)
- Organization: MAT_04 (0.35), MAT_05 (0.30), MAT_06 (0.20), MAT_07 (0.15)
- Process Capability: MAT_08 (0.35), MAT_09 (0.35), MAT_10 (0.30)
- Infrastructure: MAT_11 (0.50), MAT_12 (0.50)

**Section Weights:**
- Fundamentals: 0.25
- Organization: 0.30
- Process Capability: 0.25
- Infrastructure: 0.20

**Maturity Levels:**
- Initial: 0.0-1.0
- Developing: 1.0-2.0
- Defined: 2.0-3.0
- Managed: 3.0-4.0
- Optimized: 4.0-5.0

### Archetype Selection Decision Tree

```
MAT_04 (SE Roles and Processes)?
├─ ≤ 1 (Low Maturity)
│   ├─ Primary: SE for Managers (automatic)
│   └─ Secondary: ARCH_01 (Company Preference)
│       ├─ apply_pilot → Orientation in Pilot Project
│       ├─ build_awareness → Common Basic Understanding
│       └─ develop_experts → Certification
│
└─ > 1 (High Maturity)
    └─ MAT_05 (Rollout Scope)?
        ├─ ≤ 1 (Limited) → Needs-based Project-oriented Training
        └─ ≥ 2 (Broad) → Continuous Support

Supplementary (All Paths):
└─ ARCH_06 = enterprise OR ARCH_07 = long?
    └─ Yes → Suggest Train the Trainer
```

---

## Testing Requirements

### 1. Maturity Assessment Testing

**Test Scenarios:**

**A. Low Maturity Organization (MAT_04 = 0 or 1)**
- Input all questions with low scores (0-1 range)
- Verify MAT_04 ≤ 1
- Verify system routes to low maturity archetype path
- Expected: Dual selection required

**B. Medium Maturity Organization (MAT_04 = 2)**
- Input questions with mixed scores
- Verify MAT_04 = 2 (triggers high maturity path)
- Verify MAT_05 ≤ 1
- Expected: Single archetype - "Needs-based Project-oriented Training"

**C. High Maturity Organization (MAT_04 ≥ 3, MAT_05 ≥ 2)**
- Input questions with high scores (3-5 range)
- Verify MAT_04 > 1 and MAT_05 ≥ 2
- Expected: Single archetype - "Continuous Support"

### 2. Archetype Selection Testing

**Test Scenarios:**

**A. Low Maturity - Pilot Project Path**
- Prerequisites: MAT_04 ≤ 1
- ARCH_01: Select "apply_pilot"
- ARCH_02: Select any management readiness
- ARCH_03: Should appear (conditional), select any
- Expected Result:
  - Primary: "SE for Managers"
  - Secondary: "Orientation in Pilot Project"
  - Selection Type: "dual"

**B. Low Maturity - Build Awareness Path**
- Prerequisites: MAT_04 ≤ 1
- ARCH_01: Select "build_awareness"
- ARCH_02: Select any management readiness
- ARCH_03: Should NOT appear
- Expected Result:
  - Primary: "SE for Managers"
  - Secondary: "Common Basic Understanding"
  - Selection Type: "dual"

**C. Low Maturity - Certification Path**
- Prerequisites: MAT_04 ≤ 1
- ARCH_01: Select "develop_experts"
- Expected Result:
  - Primary: "SE for Managers"
  - Secondary: "Certification"
  - Selection Type: "dual"

**D. High Maturity - Limited Scope**
- Prerequisites: MAT_04 > 1, MAT_05 ≤ 1
- ARCH_04: Auto-calculated
- ARCH_05: Select any learning preference
- Expected Result:
  - Primary: "Needs-based Project-oriented Training"
  - Selection Type: "single"

**E. High Maturity - Broad Scope**
- Prerequisites: MAT_04 > 1, MAT_05 ≥ 2
- ARCH_04: Auto-calculated
- ARCH_05: Select any learning preference
- Expected Result:
  - Primary: "Continuous Support"
  - Selection Type: "single"

**F. Train the Trainer Supplementary**
- Any maturity level
- ARCH_06: Select "enterprise" (50+) OR
- ARCH_07: Select "long" (12+ months)
- Expected Result:
  - Supplementary array contains "Train the Trainer"

### 3. Scoring Algorithm Testing

**Validate Section Calculations:**
```javascript
// Example for Fundamentals section
const fundamentals_score =
  (MAT_01_score * 0.35 + MAT_02_score * 0.30 + MAT_03_score * 0.35) /
  (0.35 + 0.30 + 0.35)

// Overall maturity
const overall_maturity =
  (fundamentals_score * 0.25 + organization_score * 0.30 +
   process_score * 0.25 + infrastructure_score * 0.20) /
  (0.25 + 0.30 + 0.25 + 0.20)
```

**Test Cases:**
1. All zeros → Overall: 0.0 (Initial)
2. All ones → Overall: 1.0 (Developing)
3. All twos → Overall: 2.0 (Defined)
4. Mixed values → Verify weighted calculation
5. Maximum values → Overall: 4.5-5.0 (Optimized)

### 4. End-to-End Testing

**Complete Flow:**
1. Start Phase 1 → Maturity Assessment
2. Answer all 12 questions
3. Submit and calculate maturity score
4. System extracts MAT_04 and MAT_05
5. Route to appropriate archetype path
6. Answer archetype questions (conditional display)
7. Compute archetype recommendation
8. Display results with rationale
9. Save to organization table

**Validation Points:**
- Conditional question display (ARCH_03 only if ARCH_01 = "apply_pilot")
- Correct path routing (low vs high maturity)
- Accurate archetype selection
- Supplementary evaluation logic
- Data persistence to organization.phase1_* columns

---

## Frontend Compatibility

The existing `QuestionnaireComponent.vue` should work with minimal changes:
- Already handles sections via `question.section`
- Already handles conditional questions via `question.conditional`
- Already handles help_text display
- Already handles different question types

**No Breaking Changes:**
- Question structure maintained (id, text, type, options)
- Option structure maintained (value, label, description, score)
- Backend transformation (routes.py:1646-1684) already handles new structure

---

## Database Schema

**Phase 1 Data Storage (Organization Table):**
```sql
-- Columns already exist (added via previous migrations):
maturity_score DECIMAL          -- Overall maturity percentage
selected_archetype VARCHAR(255) -- Primary archetype name
organization_size VARCHAR(50)   -- Small/Medium/Large
maturity_responses JSONB        -- All MAT_01-12 responses
archetype_responses JSONB       -- All ARCH_01-07 responses
computed_archetype JSONB        -- Full archetype result object
phase1_completed BOOLEAN
phase1_completed_at TIMESTAMP
```

**No database migrations required** - columns already exist.

---

## Next Steps

### Immediate Testing (Recommended Order):

1. **Start Backend Server**
   ```bash
   cd "C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\competency_assessor"
   set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
   set FLASK_APP=run.py
   set FLASK_DEBUG=1
   python run.py
   ```

2. **Start Frontend Server** (if not running)
   ```bash
   cd "C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis\src\frontend"
   npm run dev
   ```

3. **Test Maturity Assessment**
   - Navigate to Phase 1 maturity assessment questionnaire
   - Verify all 12 questions display with sections
   - Verify help text shows for MAT_04 and MAT_05
   - Complete questionnaire and verify score calculation

4. **Test Archetype Selection - Low Maturity**
   - Set MAT_04 = 0 or 1 in maturity assessment
   - Verify only ARCH_01, ARCH_02, ARCH_06, ARCH_07 appear
   - Select ARCH_01 = "apply_pilot"
   - Verify ARCH_03 appears conditionally
   - Verify dual selection result

5. **Test Archetype Selection - High Maturity**
   - Set MAT_04 = 3, MAT_05 = 2 in maturity assessment
   - Verify ARCH_05, ARCH_06, ARCH_07 appear
   - Verify single selection result (Continuous Support)

6. **Test Supplementary Logic**
   - Set ARCH_06 = "enterprise" or ARCH_07 = "long"
   - Verify Train the Trainer appears in supplementary array

7. **Validate Data Persistence**
   - Complete full Phase 1 flow
   - Check organization table for saved data
   - Verify maturity_responses and archetype_responses JSONBcontent

---

## Validation Test Cases

### Test Case 1: Low Maturity Company - Pilot Focus
**Maturity Assessment:**
- MAT_01 = 1, MAT_02 = 0, MAT_03 = 1 (Fundamentals: Low)
- MAT_04 = 0, MAT_05 = 0, MAT_06 = 1, MAT_07 = 0 (Organization: Very Low)
- MAT_08 = 1, MAT_09 = 1, MAT_10 = 1 (Process: Low)
- MAT_11 = 0, MAT_12 = 1 (Infrastructure: Low)

**Expected Overall Maturity:** ~0.6 (Initial level)

**Archetype Selection:**
- ARCH_01: "apply_pilot"
- ARCH_02: 2 (Somewhat interested)
- ARCH_03: 3 (Project selected)
- ARCH_06: "medium" (6-15)
- ARCH_07: "short" (3-6 months)

**Expected Result:**
- Primary: "SE for Managers"
- Secondary: "Orientation in Pilot Project"
- Supplementary: None
- Selection Type: "dual"

---

### Test Case 2: High Maturity Company - Broad Scope
**Maturity Assessment:**
- MAT_01 = 3, MAT_02 = 3, MAT_03 = 3
- MAT_04 = 3, MAT_05 = 3, MAT_06 = 3, MAT_07 = 3
- MAT_08 = 4, MAT_09 = 3, MAT_10 = 3
- MAT_11 = 3, MAT_12 = 3

**Expected Overall Maturity:** ~3.1 (Managed level)

**Archetype Selection:**
- ARCH_05: "continuous"
- ARCH_06: "enterprise" (50+)
- ARCH_07: "long" (12+ months)

**Expected Result:**
- Primary: "Continuous Support"
- Secondary: None
- Supplementary: ["Train the Trainer"]
- Selection Type: "single"

---

### Test Case 3: Medium Maturity - Limited Scope
**Maturity Assessment:**
- MAT_01 = 2, MAT_02 = 2, MAT_03 = 2
- MAT_04 = 2, MAT_05 = 1, MAT_06 = 2, MAT_07 = 2
- MAT_08 = 2, MAT_09 = 2, MAT_10 = 2
- MAT_11 = 2, MAT_12 = 2

**Expected Overall Maturity:** ~2.0 (Defined level)

**Archetype Selection:**
- ARCH_05: "project_specific"
- ARCH_06: "large" (16-50)
- ARCH_07: "medium" (6-12 months)

**Expected Result:**
- Primary: "Needs-based Project-oriented Training"
- Secondary: None
- Supplementary: None
- Selection Type: "single"

---

## Implementation Checklist

- [x] Backup existing JSON files
- [x] Update maturity_assessment.json with 12 BRETZ questions
- [x] Add section structure and weights
- [x] Mark MAT_04 and MAT_05 as routing_critical
- [x] Update archetype_selection.json with dual-path logic
- [x] Add low maturity path questions (ARCH_01-03)
- [x] Add high maturity path questions (ARCH_04-05)
- [x] Add common questions (ARCH_06-07)
- [x] Update decision tree with 7 archetypes
- [x] Update backend endpoint to use MAT_04/MAT_05 routing
- [x] Implement dual-path selection logic
- [x] Implement supplementary evaluation (Train the Trainer)
- [ ] Test maturity assessment in frontend
- [ ] Test archetype selection in frontend
- [ ] Validate scoring algorithms
- [ ] Test end-to-end Phase 1 flow
- [ ] Create validation test report

---

## Known Limitations

1. **Frontend Conditional Display**: The frontend `QuestionnaireComponent.vue` may need updates to handle:
   - `conditional.show_if` string expressions (e.g., "MAT_04 <= 1")
   - Auto-calculated questions (ARCH_04)

2. **Score Calculation**: Frontend may need to implement hierarchical weighted average for section-based scoring

3. **Routing Variable Passing**: Frontend needs to pass `maturity_responses` to archetype selection endpoint

---

## Support & Troubleshooting

**Backend Logs:**
- Check terminal running `python run.py` for `[ARCHETYPE]` prefixed logs
- Logs show routing variables, path selection, and final archetype

**Common Issues:**
1. **"MAT_04 score required" error**: Ensure maturity assessment completed first
2. **Wrong archetype path**: Verify MAT_04 value being passed correctly
3. **Conditional questions not appearing**: Check conditional.show_if logic in frontend
4. **Score calculation incorrect**: Verify weighted average implementation

**Database Verification:**
```sql
-- Check Phase 1 completion
SELECT id, organization_name, maturity_score, selected_archetype,
       phase1_completed, phase1_completed_at
FROM organization
WHERE phase1_completed = true;

-- Check saved responses
SELECT id, organization_name,
       maturity_responses, archetype_responses, computed_archetype
FROM organization
WHERE maturity_responses IS NOT NULL;
```

---

## References

**Design Documents:**
- `data/source/questionnaires/phase 1 - to update/se-qpt-claude-code-instructions.md`
- `data/source/questionnaires/phase 1 - to update/updated-se-qpt-questionnaires.md`
- `data/source/questionnaires/phase 1 - to update/final-validated-questionnaires.json`

**Implementation Files:**
- Maturity: `data/source/questionnaires/phase1/maturity_assessment.json`
- Archetype: `data/source/questionnaires/phase1/archetype_selection.json`
- Backend: `src/competency_assessor/app/routes.py` (lines 1784-1906)
- Frontend: `src/frontend/src/components/common/QuestionnaireComponent.vue`

**Backups:**
- `data/source/questionnaires/phase1/maturity_assessment_backup_old.json`
- `data/source/questionnaires/phase1/archetype_selection_backup_old.json`

---

**END OF IMPLEMENTATION SUMMARY**
