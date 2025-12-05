# Remaining Questions Before Learning Objectives Design v5

**Date:** 2025-11-24
**Purpose:** Document unresolved questions that need answers before finalizing Phase 2 Task 3 design
**Context:** After analyzing meeting with Ulf (21.11.2025) and clearing backlog items

---

## ✅ What We Now Know (Confirmed)

### Core Architectural Decisions

1. **Levels 3 and 5:** RESOLVED - No longer in system, only 0,1,2,4,6 valid
2. **High Maturity Strategy Count:** ONE strategy only (Continuous Support OR Needs-based)
3. **PMT in Low Maturity:** Check if provided; suggest strategy change if empty
4. **Multiple Strategies with Conflicting Targets:** Take HIGHER target
5. **Progressive Learning:** Generate objectives for ALL intermediate levels (e.g., 0→4 generates 1,2,4)
6. **Pyramid Structure:** High maturity uses level-based pyramid; Low maturity uses strategy-based view
7. **Aggregation Basis:** Role-based (not user-based), but distribution awareness needed
8. **Train the Trainer:** Separate track, excluded from validation

### Scope Decisions

9. **Cross-Strategy Validation:** OUT OF SCOPE (deferred)
10. **SE for Managers Special Handling:** BACKLOG (Phase 3)
11. **Process and Policy Manager:** BACKLOG (Phase 3)
12. **Role-Based Pyramid View (2nd view):** BACKLOG (Phase 3)
13. **AI PMT Document Extraction:** BACKLOG (Phase 3)

---

## ❓ Critical Questions Remaining

### 1. Graying Out Logic - UI Presentation

**Question:** When a competency is "already achieved" at a specific level, how do we display it?

**Context:**
- Meeting notes mention "graying out" multiple times
- Jomon's understanding: "Show all 16 competencies, gray out achieved ones"
- My mock UI shows this approach

**Need to Confirm:**

**Option A: Show All 16, Gray Some (Current Mock UI Approach)**
```
LEVEL 2: Understanding SE
  [ACTIVE] Systems Thinking - Training Required
  [ACTIVE] Requirements Definition - Training Required
  [GRAY] Communication - Already at Level 2+
  [GRAY] Decision Management - Already at Level 2+
  ... (all 16 shown)
```

**Option B: Show Only Active, Hide Achieved**
```
LEVEL 2: Understanding SE
  [ACTIVE] Systems Thinking - Training Required
  [ACTIVE] Requirements Definition - Training Required
  (8 competencies hidden - already achieved)
```

**Option C: Show All with Status Indicators**
```
LEVEL 2: Understanding SE
  [GAP] Systems Thinking - Target: 2, Current: 0
  [GAP] Requirements Definition - Target: 2, Current: 1
  [OK] Communication - Current: 3 (Already achieved)
  [OK] Decision Management - Current: 4 (Already achieved)
  ... (all 16 shown with clear status)
```

**My Recommendation:** Option A (show all 16, gray out achieved)
- Provides complete picture
- Admin sees what IS needed and what IS NOT needed
- Gray = informational, not actionable

**Question for Jomon:** Which option aligns with your vision?

---

### 2. Distribution Awareness vs Pure Median

**Question:** How do we handle distribution when median might be misleading?

**Context:**
- Ulf raised concerns about median hiding outliers
- Example: 6 at level 2, 6 at level 6, 1 at level 4 → Median=4, but bimodal distribution
- Ulf wants scenario-based analysis to determine when median works

**Current Approach:**
- Use median for PRIMARY decision (gap exists or not)
- But acknowledge distribution matters

**Need to Decide:**

**Option A: Pure Median (Simplest)**
- Use median across all role members
- Decision: Gap exists if median < target
- Ignore distribution entirely
- Fast, simple, but may miss important patterns

**Option B: Median + Distribution Flags (Recommended)**
- Use median for decision
- But CALCULATE distribution statistics
- FLAG anomalies for admin awareness
- Example: "Training needed (median=2, target=4), but only 15% of role (3/20 users)"
- Admin sees recommendation but also context

**Option C: Scenario-Based Decision (Complex)**
- Calculate distribution pattern
- Classify as: Uniform, Bimodal, Outlier-based, etc.
- Different decision logic per pattern
- Example: Bimodal → Split training recommendation
- Most accurate, but complex to implement

**My Recommendation:** Option B for Phase 2, Option C for Phase 3

**Question for Jomon:** Go with Option B (median + flags) for Phase 2?

---

### 3. Validation Outcome - Block or Warn?

**Question:** When strategy validation detects mismatch (current levels exceed strategy targets), what should happen?

**Context:**
- Cross-strategy validation is OUT OF SCOPE
- But basic validation (current vs target) might still be useful
- Meeting notes suggest re-evaluating maturity assessment

**Options:**

**Option A: BLOCKING**
```
[ERROR] Strategy Inadequate
Your competency assessment results show higher levels than
selected strategy targets. This suggests a mismatch in Phase 1
maturity assessment.

Action Required: Return to Phase 1 and re-evaluate organizational
maturity level.

[Button: Return to Phase 1]
(No learning objectives shown)
```

**Option B: WARNING**
```
[WARNING] Potential Strategy Mismatch
Your competency assessment results exceed selected strategy targets
in 8/16 competencies. Consider re-evaluating maturity assessment.

You can proceed with current selection, but training plan may not
be optimal.

[Button: Proceed Anyway] [Button: Return to Phase 1]
(Learning objectives shown below with warning banner)
```

**Option C: INFORMATIONAL ONLY**
```
[INFO] Strategy Alignment
Current competency levels align with selected strategy for 12/16
competencies. 4 competencies already exceed targets.

(Learning objectives shown, no action required)
```

**Option D: NO VALIDATION (Skip This Entirely)**
- Trust that Phase 1 was done correctly
- Just generate learning objectives based on gaps
- No validation at all

**My Recommendation:** Option D (No Validation) for Phase 2
- Cross-strategy validation is explicitly out of scope
- Trust the Phase 1 process
- Keep it simple

**Alternative:** Option B (Warning) if we want some validation

**Question for Jomon:** Should we include validation at all? If yes, blocking or warning?

---

### 4. Progressive Objectives - UI Display

**Question:** When showing progressive objectives (levels 1, 2, 4 for one competency), how should UI present them?

**Context:**
- Confirmed we generate objectives for all intermediate levels
- High maturity uses pyramid structure (level tabs)
- Low maturity uses strategy structure (strategy tabs)

**High Maturity (PYRAMID) - Clear:**
```
[TAB: Level 1 - Knowing] [TAB: Level 2 - Understanding] [TAB: Level 4 - Applying]

Current Tab: Level 2

Systems Thinking (Target: 4, Current: 0)
Learning Objective (Level 2):
"Participants understand the principles of systems thinking and
can identify system boundaries, interfaces, and interactions."
```
Each level has separate tab, clear separation.

**Low Maturity (STRATEGY-BASED) - Need to Clarify:**

**Option A: All Levels Within Competency Card (Collapsed)**
```
Strategy: SE for Managers

Systems Thinking (Current: 0, Target: 4)
  > Progressive Levels (click to expand)
    [+] Level 1: Knowing
    [+] Level 2: Understanding
    [+] Level 4: Applying
```

**Option B: All Levels Shown Expanded**
```
Strategy: SE for Managers

Systems Thinking (Current: 0, Target: 4)

  Level 1: Knowing SE
  "Participants are aware of systems thinking concepts..."

  Level 2: Understanding SE
  "Participants understand the principles of systems thinking..."

  Level 4: Applying SE
  "Participants are able to apply systems thinking to analyze..."
```

**Option C: Separate Sections per Level**
```
Strategy: SE for Managers

LEVEL 1 OBJECTIVES:
  - Systems Thinking
  - Communication
  - (6 other competencies needing level 1)

LEVEL 2 OBJECTIVES:
  - Systems Thinking
  - Decision Management
  - (4 other competencies needing level 2)

LEVEL 4 OBJECTIVES:
  - Systems Thinking
  - Requirements Definition
  - (8 competencies needing level 4)
```

**My Recommendation:**
- High Maturity: Use pyramid tabs (clear)
- Low Maturity: Option B (all levels shown expanded within competency)

**Question for Jomon:** Which low maturity presentation do you prefer?

---

### 5. Low Maturity Strategy Rules

**Question:** Is "SE for Managers" always mandatory for low maturity organizations?

**Context:**
- My understanding from notes: Low maturity = "SE for Managers" + 1 other
- But not explicitly confirmed by Ulf
- Affects algorithm logic

**Need to Confirm:**

**Scenario A: Mandatory "SE for Managers"**
```
IF maturity < 3:
    strategies_required = ["SE for Managers"]
    strategies_optional = [
        "Common Basic Understanding",
        "Orientation in Pilot Project",
        "Certification"
    ]
    user_must_select = 1 strategy from optional
    total_strategies = 2
```

**Scenario B: Any 2 from Low Maturity Pool**
```
IF maturity < 3:
    strategies_available = [
        "SE for Managers",
        "Common Basic Understanding",
        "Orientation in Pilot Project",
        "Certification"
    ]
    user_must_select = 2 strategies from available
    total_strategies = 2
```

**My Understanding:** Scenario A (Managers mandatory)
- But need explicit confirmation

**Question for Jomon:** Is "SE for Managers" mandatory for low maturity?

---

### 6. Role Assignment Granularity

**Question:** When listing "Roles that need this competency at this level", which roles do we include?

**Scenario:**
```
Competency: Systems Thinking at Level 2
- Role A: 20/20 users need it (100%)
- Role B: 15/20 users need it (75%)
- Role C: 8/20 users need it (40%)
- Role D: 2/20 users need it (10%)
- Role E: 0/20 users need it (0%)
```

**Options:**

**Option A: All Roles with ANY Gap (Even 1 User)**
- Show: Role A, Role B, Role C, Role D
- Don't show: Role E
- Most inclusive

**Option B: Only Roles with MAJORITY Gap (>50%)**
- Show: Role A, Role B
- Don't show: Role C, Role D, Role E
- Focus on significant needs

**Option C: Threshold-Based (e.g., >25%)**
- Show: Role A, Role B, Role C
- Don't show: Role D, Role E
- Configurable threshold

**Option D: All Roles with Indicators**
```
Roles needing Level 2 - Systems Thinking:
- Role A [CRITICAL: 20/20 users]
- Role B [MAJORITY: 15/20 users]
- Role C [MODERATE: 8/20 users]
- Role D [MINORITY: 2/20 users]
```

**My Recommendation:** Option D (all with indicators) for Phase 3, Option B (majority) for Phase 2

**Question for Jomon:** Which approach for Phase 2?

---

### 7. Entire Level Graying Out

**Question:** If NO competencies have gaps at a specific level (e.g., Level 6), how do we show this?

**Options:**

**Option A: Gray Out Tab, Still Clickable**
```
[TAB: Level 1] [TAB: Level 2] [TAB: Level 4] [TAB: Level 6 - ACHIEVED]

Click Level 6 →
"All competencies already at Level 6 or higher. No training needed."
(Shows all 16 competencies grayed out)
```

**Option B: Hide Level Entirely**
```
[TAB: Level 1] [TAB: Level 2] [TAB: Level 4]
(Level 6 not shown at all)
```

**Option C: Disabled Tab with Tooltip**
```
[TAB: Level 1] [TAB: Level 2] [TAB: Level 4] [TAB: Level 6 ✓]
                                                (Disabled, can't click)
Hover over Level 6 → Tooltip: "No training needed - all competencies achieved"
```

**My Recommendation:** Option A (gray out tab, still clickable for transparency)

**Question for Jomon:** Which approach?

---

## 📊 Distribution Scenario Analysis - Pending

**Status:** Not yet created (next todo)

**Purpose:**
- Explore different distribution patterns (uniform, bimodal, outlier-based, etc.)
- Determine when median is reliable vs when it's misleading
- Map patterns to training method recommendations

**Questions to Address in Analysis:**
- What distribution patterns exist in real organizations?
- When does median accurately represent group need?
- When does median hide important information?
- What thresholds/flags should we use?

**Will be created separately as next todo.**

---

## 💡 My Recommendations Summary

Based on analysis, here are my recommendations for Design v5:

### Phase 2 Must-Haves:

1. **Graying Out:** Show all 16 competencies, gray out achieved (Option A)
2. **Distribution:** Use median + distribution flags (Option B) - calculated but not complex logic
3. **Validation:** Skip validation entirely (Option D) - keep it simple
4. **Low Maturity Progressive Display:** All levels shown expanded within competency (Option B)
5. **Role Assignment:** Show roles with >50% gap (Option B - majority-based)
6. **Level Graying:** Gray out tab, still clickable (Option A)

### Phase 2 Assumptions (Need Confirmation):

7. **"SE for Managers" Mandatory:** Assume YES (Scenario A)
8. **Low Maturity Strategy Count:** Always 2 strategies

### Data Needs:

- Median calculation per role per competency ✅ (already implemented)
- Distribution calculation (new): count users below target, percentage
- Role requirement from role-competency matrix ✅ (already have)
- Strategy target from archetype templates ✅ (already have)

### Algorithm Changes from v4:

**What Changes:**
- Generate objectives for ALL intermediate levels (not just target)
- Organize by LEVEL for high maturity (not by strategy)
- Show all 16 competencies (not just ones with gaps)
- Calculate distribution statistics (new)

**What Stays:**
- PMT customization logic
- Dual-track processing (Train the Trainer)
- Template-based objective generation
- Strategy target lookup

---

## Next Steps

1. **Get answers to 7 questions above** (especially 2, 3, 5)
2. **Create Distribution Scenario Analysis** (next todo)
3. **Create Design v5 document** incorporating confirmed answers
4. **Review design with Jomon** before implementation
5. **Begin implementation** of redesigned Learning Objectives page

---

## Questions for Jomon (Summary)

**Please answer these 7 questions:**

1. **Graying Out UI:** Option A (show all 16, gray achieved), Option B (hide achieved), or Option C (show all with status)? → **Recommend: A**

2. **Distribution Handling:** Pure median (A), Median + flags (B), or Scenario-based (C)? → **Recommend: B for Phase 2**

3. **Validation:** No validation (D), Warning (B), or Blocking (A)? → **Recommend: D for Phase 2**

4. **Low Maturity Progressive Display:** Collapsed (A), Expanded (B), or Sectioned (C)? → **Recommend: B**

5. **"SE for Managers" Mandatory:** Yes (Scenario A) or No (Scenario B)? → **Recommend: Yes**

6. **Role Assignment:** Any gap (A), Majority (B), Threshold (C), or All with indicators (D)? → **Recommend: B for Phase 2**

7. **Level Graying:** Clickable gray (A), Hide (B), or Disabled (C)? → **Recommend: A**

---

*Document Status: Ready for review*
*Next Action: Get answers, then proceed to Distribution Scenario Analysis*
*Date: 2025-11-24*
