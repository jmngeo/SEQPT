# Phase 2 Learning Objectives Task - Requirements from Meeting 28.11.2025

**Date:** 2025-11-28
**Source:** Meeting with Ulf
**Scope:** Current Phase 2 LO Task Implementation Fixes & Improvements

This document focuses ONLY on the Phase 2 Learning Objectives task.
For Phase 3 Learning Format Recommendations, see: `PHASE3_FORMAT_RECS_DESIGN_INPUTS.md`

---

## Summary of Changes Needed

| Priority | Change | Type | Effort | Status |
|----------|--------|------|--------|--------|
| P1 | Fix LO text mapping bug (LLM hallucination) | Bug Fix | 1-2 hours | **DONE** |
| P2 | Change "Skill Gaps to Train" -> "Levels to Advance" | UI Label | 5 min | **DONE** |
| P2 | Change "Total Competencies" -> "Competencies with Gap" | UI + Logic | 30 min | **DONE** |
| P2 | Remove Level 6 from pyramid UI | UI + Backend | 1-2 hours | **DONE** |
| P3 | Convert LO text to bullet points | UI | 30 min | **DONE** |
| P3 | Remove level numbers from tabs (show names only) | UI | 15 min | **DONE** |
| P3 | Add role legend explanation for (X/Y) format | UI | 15 min | **DONE** |
| P4 | Add Excel export button | Feature | 2-3 hours | Pending |
| P4 | Add PMT breakdown for 3 additional competencies | Template | 2-3 hours | Pending |

---

## PRIORITY 1: Bug Fixes

### 1.1 LO Text Mapping Bug (CRITICAL)

**Issue**: Agile Methods competency shows SysML content (from System Architecting)

**Root Cause**: LLM hallucination during PMT customization
- Temperature too high (0.7)
- Prompt not strict enough about staying within competency scope
- No validation for cross-competency contamination

**Fix Required** (in `learning_objectives_core.py`):

1. **Lower temperature** in `customize_pmt_breakdown()` (line ~2039):
   ```python
   # Change from:
   temperature=0.7
   # To:
   temperature=0.3
   ```

2. **Update prompt** to be stricter:
   - Add: "CRITICAL: Only customize the provided text, do NOT add content from other competencies"
   - Add: "If no relevant PMT applies, return original text unchanged"
   - Add explicit constraint: "This is for {competency_name} ONLY"

3. **Add validation** to detect cross-contamination:
   - Check for keywords from other competencies
   - Log warning and fallback to template if detected

**See**: `LO_TEXT_MAPPING_BUG_ANALYSIS.md` for full details

---

## PRIORITY 2: UI Label & Logic Changes

### 2.1 "Skill Gaps to Train" -> "Levels to Advance"

**Location**: Frontend LO results page summary stats

**Current**: "20 Skill Gaps to Train"
**Change to**: "20 Levels to Advance"

**Rationale**: Ulf found "Skill Gaps to Train" confusing since total competencies is 16, but gaps shown was 20 (counting each level as separate gap)

**Files to modify**:
- `src/frontend/src/views/phases/PhaseTwo.vue` (or wherever LO results page is)
- Look for summary stats component

### 2.2 "Total Competencies" -> "Competencies with Gap"

**Location**: Frontend LO results page summary stats

**Current**: "16 Total Competencies"
**Change to**: "X Competencies with Gap" (where X is count of unique competencies that have ANY gap)

**Logic**: Count unique competencies that have at least one level needing training
- Example: Systems Thinking needs Level 1 AND Level 2 -> counts as 1
- Do NOT double-count levels

**Backend Change** (may already exist, verify):
```python
# Count unique competencies with gaps
competencies_with_gap = sum(
    1 for comp_data in gaps_by_competency.values()
    if comp_data.get('has_gap', False)
)
```

### 2.3 Remove Level 6 from Pyramid UI

**Current**: Shows 4 tabs - Level 1, Level 2, Level 4, Level 6
**Change to**: Show 3 tabs - Knowing SE, Understanding SE, Applying SE

**Why**:
- Level 6 is for process owners (specific use case)
- TTT strategy handling is deferred to backlog
- Confuses users who don't understand Level 6 purpose

**Changes Required**:

1. **Backend**: Filter out Level 6 from response (or frontend filters)
   ```python
   # In structure_pyramid_output() or similar
   DISPLAY_LEVELS = [1, 2, 4]  # Remove 6
   ```

2. **Frontend**:
   - Remove Level 6 tab
   - Remove TTT section below pyramid
   - Only show levels 1, 2, 4

3. **TTT Logic**: Can remain in backend (unused for now), mark as BACKLOG

---

## PRIORITY 3: UI Display Improvements

### 3.1 Convert LO Text to Bullet Points

**Current**: LO text shown as single paragraph
**Change to**: Split into bullet points per sentence

**Implementation**:
```javascript
// In LO display component
const formatAsBullets = (text) => {
  // Split by period, filter empty, create list items
  return text.split('.')
    .map(s => s.trim())
    .filter(s => s.length > 0)
    .map(s => `<li>${s}.</li>`)
    .join('');
};
```

**Display**: Use `<ul>` list with bullets

### 3.2 Remove Level Numbers from Tabs

**Current**: "Level 1 - Knowing SE", "Level 2 - Understanding SE", etc.
**Change to**: Just "Knowing SE", "Understanding SE", "Applying SE"

**Why**: Users ask "Why no Level 3?" - confusing without context

**Files**: Update tab labels in Vue component

### 3.3 Add Role Legend for (X/Y) Format

**Current**: Shows "Integration Engineer (2/4)" without explanation
**Add**: Legend text explaining what (2/4) means

**Legend Text**:
> "Roles Needing This Level: (X/Y) indicates X out of Y total users in that role have NOT achieved this level yet"

**Placement**: Near existing legend "Level indicator: Current -> Target"

---

## PRIORITY 4: New Features

### 4.1 Excel Export Button

**Requirement**: Export LOs as Excel file

**Structure** (single sheet, "All-in-one Competency view"):
| Competency | Level | Level Name | Learning Objective | PMT Breakdown (P) | PMT Breakdown (M) | PMT Breakdown (T) | Gap Users | Total Users |
|------------|-------|------------|-------------------|-------------------|-------------------|-------------------|-----------|-------------|
| Systems Thinking | 1 | Knowing SE | The participant knows... | - | - | - | 15 | 20 |
| Systems Thinking | 2 | Understanding SE | The participant understands... | - | - | - | 10 | 20 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

**Implementation**:
- Add "Export to Excel" button on LO results page
- Use library like `xlsx` or `exceljs` (frontend) or generate on backend
- Include all competencies and all levels (even achieved ones)

### 4.2 PMT Breakdown for Additional Competencies

**Ulf Request**: Add PMT breakdown for these competencies:
- Integration, Verification & Validation (ID: 16)
- Decision Management (ID: 11)
- Information Management (ID: 12)

**Current State** (`se_qpt_learning_objectives_template_v2.json`):
- These competencies have `hasPMT: false`
- Only have unified text, no pmt_breakdown structure

**Task**:
1. Analyze pattern of existing PMT breakdowns (Project Management, System Architecting, etc.)
2. Create PMT breakdown text for each level of the 3 competencies
3. Update template JSON file

**Example Pattern** (from Requirements Definition):
```json
"1": {
  "unified": "...",
  "pmt_breakdown": {
    "process": "Participants can differentiate between requirements types...",
    "method": "The participants know the different processes of requirements...",
    "tool": "The participant knows how to create a requirements table."
  }
}
```

**Create Similar for**:
- IVV: Process = test process, Method = test methods, Tool = test tools
- Decision Management: Process = decision process, Method = decision methods, Tool = decision tools (if applicable)
- Information Management: Process = info management process, Method = knowledge transfer methods, Tool = platforms/tools

---

## Testing Checklist

After implementing changes:

- [ ] LO text for Agile Methods shows correct agile content (not SysML)
- [ ] LO text for System Architecting shows correct architecture/SysML content
- [ ] All 16 competencies show correct LO text for their domain
- [ ] "Levels to Advance" shows correct count
- [ ] "Competencies with Gap" shows unique count (not level count)
- [ ] Only 3 tabs shown (Knowing, Understanding, Applying)
- [ ] No Level 6 or TTT section visible
- [ ] LO text displays as bullet points
- [ ] Tab labels show names only (no "Level X")
- [ ] Role legend explains (X/Y) format
- [ ] Excel export downloads correctly formatted file
- [ ] New PMT breakdowns render properly for IVV, Decision, Info Management

---

## Files to Modify

### Backend
- `src/backend/app/services/learning_objectives_core.py`
  - Fix LLM temperature and prompt (Bug fix)
  - Add validation for cross-contamination
  - Filter Level 6 from output (optional, can do in frontend)

### Frontend
- `src/frontend/src/views/phases/PhaseTwo.vue` (or LO results component)
  - Update stat labels
  - Remove Level 6 tab
  - Update tab labels
  - Add bullet point formatting
  - Add role legend
  - Add export button

### Templates
- `data/source/Phase 2/se_qpt_learning_objectives_template_v2.json`
  - Add PMT breakdowns for IVV, Decision Management, Information Management
  - Update `hasPMT` flags

---

## Definition of Done

Phase 2 LO Task is COMPLETE when:
1. All P1 bugs fixed (LO text mapping)
2. All P2 UI changes implemented (labels, Level 6 removal)
3. All P3 display improvements done (bullets, legend)
4. P4 features implemented (Excel export, PMT templates)
5. All tests pass
6. Ulf reviews and approves in next meeting

---

*Document created: 2025-11-28*
*Source: Meeting notes 28.11.2025.txt*
