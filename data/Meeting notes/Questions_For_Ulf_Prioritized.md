# Critical Questions for Ulf - Phase 2 Task 3 Learning Objectives

**Date Prepared:** 2025-11-14
**Context:** Confirming pyramid structure approach and clarifying implementation details
**Mock UI Available:** See `Phase2_Task3_Mock_UI_Presentation.html` in this folder

---

## 🔴 TOP 5 CRITICAL QUESTIONS (Must Answer - Blocks Implementation)

### 1. LEVELS 3 and 5 - Data Mismatch ⚠️ MOST CRITICAL

**Problem Discovered:** Our system currently has:
- 262 user assessments with level 3
- 46 user assessments with level 5
- 18 role-competency matrix entries with level 3

But learning objectives templates only exist for levels **1, 2, 4, 6** (no 3 or 5).

**Question:** How should we handle existing levels 3 and 5?

**Options:**
- A) Round down (3→2, 5→4)?
- B) Round up (3→4, 5→6)?
- C) Create learning objective templates for levels 3 and 5?
- D) Migrate data to valid levels (0,1,2,4,6) and restrict future input?

**My Recommendation:** Option B + D (round down: 3→2, 5→4, then migrate data and restrict future input)

---

### 2. Strategy Validation Threshold

**Context:** When validating if selected strategy matches organizational competency gaps.

**Question:** What percentage of competencies showing "over-training" (current level > strategy target) should trigger "Strategy Inadequate" warning?

**Options:**
- A) 50% (8 out of 16 competencies)?
- B) 70% (11-12 out of 16)?
- C) Different threshold?

**My Current Understanding:** We compare current median levels vs strategy target levels across all 16 competencies holistically (not per-competency). If MAJORITY show over-training → recommend re-evaluating maturity assessment.

**Follow-up:** Should validation be BLOCKING (don't show pyramid until fixed) or WARNING (show pyramid with prominent warning)?

**My Opinion:** BLOCKING - forces admin to fix root cause (maturity assessment mismatch).

---

### 3. PMT in Low Maturity Organizations

**Context:** Low maturity orgs typically don't have formalized SE processes/methods/tools.

**Question:** Can a low maturity organization select a PMT-requiring strategy like "Needs-based project-oriented training"?

**If YES:**
- Should we collect PMT context from them (assuming they might have some processes)?
- Or always use standard template objectives for low maturity regardless of strategy?

**If NO:**
- Should we block PMT-requiring strategies in Phase 1 for low maturity orgs?

**My Opinion:** Strict blocking - low maturity orgs shouldn't select high-maturity strategies requiring PMT.

---

### 4. Aggregation - Pure Median Confirmed?

**Context:** Meeting notes discussed 9 experts + 1 beginner scenario.

**Question:** Confirmed that we use **pure median (per role)** for deciding training needs, ignoring user-level distribution?

**Example Scenario:**
- Role: Requirements Engineer (10 users)
- Competency: Systems Thinking
- User scores: [0, 4, 4, 4, 4, 4, 4, 4, 4, 4]
- Median: 4
- Role requirement: 4

**With pure median approach:**
- Median = 4, Requirement = 4 → No gap → Don't show in pyramid
- The 1 user with score=0 would need individual coaching (outside the system)

**Is this the correct approach?**

**Alternative:** Should we FLAG distribution anomalies (e.g., "Only 10% of this role needs training - consider individual coaching") but still base decision on median?

---

### 5. Per-Role Pyramid Views - Needed or Not?

**Context:** Meeting notes Line 8-10 mention "each role has such pyramids" but then you said "not sure if we need this."

**Question:** For the UI, which approach:

**Option A:** One organizational pyramid only
- Roles are listed WITHIN each competency at each level
- Example: "Level 2 - Systems Thinking: Roles needing this level: Requirements Engineer (8/10 users), Test Engineer (5/8 users)"

**Option B:** One organizational pyramid + optional per-role drill-down
- Main view shows organizational pyramid
- Click on a role → see that role's specific pyramid (what THEY need at each level)

**Option C:** Both views equally important

**My Mock UI shows Option A.** Is this sufficient or do you want Option B?

---

## 🟡 IMPORTANT CLARIFICATIONS (Affects Quality)

### 6. Progressive Learning Levels - Confirmation

**Understanding:** For a competency with current = 0 and target = 4:

We generate objectives for levels **1, 2, AND 4** (all intermediate steps).

**Confirmed in your feedback.** Just double-checking:
- Current = 0, Target = 6 → Generate 1, 2, 4, 6 (4 objectives)
- Current = 2, Target = 6 → Generate 4, 6 (2 objectives - skip 1 and 2 since already at 2)
- Current = 1, Target = 4 → Generate 2, 4 (2 objectives - skip 1 since already at 1)

**Correct?**

---

### 7. Pyramid Visualization - All 16 Competencies?

**Understanding:** At each level in the pyramid (e.g., Level 2), we show **ALL 16 competencies**:
- Active/highlighted = competency has training gap at this level
- Grayed out = competency already achieved at this level

**Example:** Level 2 shows all 16 competencies, but 8 are grayed out (already at level 2+), 8 are active (need level 2 training).

**Is this correct? Or should we only show competencies with gaps and hide the ones already achieved?**

**My Mock UI uses "show all 16, gray out achieved" approach.**

---

### 8. Train the Trainer - Internal vs External Decision

**Context:** After selecting "Train the Trainer" strategy, we ask "Do you want internal or external trainers?"

**Question:** What should happen based on the answer?

**My Current Understanding:**
- This is a separate track (excluded from validation)
- Shown in separate section (not in main pyramid)

**But what's the difference between internal vs external?**
- Internal trainers → Show full mastery-level learning objectives (they need to become experts)?
- External trainers → Don't show objectives (externally handled)?
- Or something else?

---

### 9. Strategy Validation - 2-way or 3-way Comparison?

**Question:** When validating strategy adequacy, do we compare:

**Option A: 2-way comparison**
- Current user levels vs Strategy targets only
- Meeting notes Line 135 seemed to suggest this

**Option B: 3-way comparison**
- Current user levels vs Strategy targets vs Role requirements

**Which is correct for validation?**

**My Opinion:** Option A (2-way) - validation checks if strategy matches current organizational state, not if it matches role requirements (that's a different check).

---

### 10. Low Maturity - Maximum Level Restriction?

**Context:** Meeting notes Line 78 say "low maturity is just until level 2, not higher."

**BUT:** Low maturity strategies like "SE for Managers" have level 4 targets in the archetype template.

**Question:** For low maturity organizations:
- Should we CAP all training at level 2 (ignore higher strategy targets)?
- OR allow the strategy's natural targets (which may include level 4)?

**My Opinion:** Allow strategy's natural targets - "SE for Managers" can have level 4 even in low maturity orgs. The "until level 2" comment might have been about "Common Basic Understanding" strategy specifically, not all low-maturity strategies.

**Need clarification!**

---

### 11. Multiple Strategies in Low Maturity - Target Selection

**Context:** Low maturity org selects 2 strategies (e.g., "SE for Managers" + "Common Basic Understanding").

**Scenario:**
- "Common Basic Understanding": Systems Thinking = Level 2
- "SE for Managers": Systems Thinking = Level 4

**Question:** Which target do we use?
- A) HIGHER target (Level 4) - user confirmed this in feedback
- B) Show BOTH strategies separately (user sees Systems Thinking in both strategy tabs)
- C) Something else?

**My Mock UI uses Option B** (separate strategy tabs, Systems Thinking appears in both with different targets). Is this correct?

---

## 🔵 RESEARCH & RESOURCES

### 12. Progressive Learning Literature

**Your Request (Meeting notes Line 47-51):** Find research evidence for progressive/sequential learning.

**Question:** Do you have specific papers, books, or frameworks to recommend?

**Topics to research:**
- Bloom's Taxonomy (cognitive domain levels)
- Sequential vs jump-based learning effectiveness
- Competency scaffolding in engineering education
- Systems Engineering training best practices

**SE-specific frameworks:**
- INCOSE competency framework?
- IEEE/ISO standards on SE education?
- GfSE (German SE Society) materials?

**Any specific sources you recommend for the thesis literature review?**

---

### 13. PMT Example Documents

**Your Offer (PMT file Line 7):** "Ulf can provide some template materials of such PMT describing docs."

**Request:** Could you share 1-2 anonymized example documents showing:
- SE processes documentation (e.g., V-model guide, ISO compliance docs)
- Methods descriptions (e.g., Agile/Scrum process guides)
- Tools landscape (e.g., tool integration diagrams)

**Purpose:**
- Test AI extraction prompts (future Phase 3 enhancement)
- Understand real-world PMT documentation format

---

## 📋 CONFIRMATIONS (Verify Understanding)

### 14. High Maturity Strategy Count

**My Understanding:** High maturity organizations select **ONE strategy only**:
- Either "Continuous Support" OR "Needs-based project-oriented training"
- These are the 2 options to choose FROM (mutually exclusive)

**Your note:** "2 strategies possible" = 2 options available, but select only 1

**Confirmed?**

---

### 15. Low Maturity Strategy Rules

**My Understanding:**
- Low maturity orgs must include **"SE for Managers"** (mandatory)
- Plus **ONE of**: "Common Basic Understanding", "Orientation in Pilot Project", or "Certification"
- Total: Always 2 strategies for low maturity

**Confirmed?**

---

### 16. Train the Trainer - Separate Track

**My Understanding:**
- "Train the Trainer" is excluded from validation
- Processed separately (dual-track approach)
- Shown in separate section of results (not in main pyramid)
- Independent of maturity level (can be selected by any org)

**Confirmed?**

---

### 17. Graying Out Entire Level

**My Understanding:** If NO competencies have gaps at a specific level (e.g., Level 6), we:
- Gray out the entire Level 6 tab
- Mark it as "ACHIEVED" or "NO TRAINING NEEDED"
- User can still click to see it, but all 16 competencies are grayed out

**Confirmed?**

---

### 18. Organizational vs Per-Role Focus

**My Understanding:**
- Training planning is **role-based**, not user-based
- We aggregate to role level using **median**
- We say "Requirements Engineer role needs Systems Thinking Level 2 training"
- We DON'T say "User ID 42 needs Systems Thinking Level 2 training"
- Individual users who are outliers handle gaps through individual coaching (outside the system)

**Confirmed?**

---

### 19. Phase 2 Scope - What Must Be Implemented?

**Question:** What functionality MUST be in Phase 2 (for thesis completion)?

**My assumption (please confirm):**
- ✅ Pyramid structure generation (high maturity)
- ✅ Strategy-based view (low maturity)
- ✅ Progressive level objectives (1, 2, 4, 6)
- ✅ Role assignment to levels
- ✅ Strategy validation
- ✅ PMT customization (manual input)
- ✅ Learning objective text generation (template-based + LLM for PMT strategies)
- ✅ UI visualization

**Can be deferred to Phase 3 or post-thesis:**
- 🔄 AI-based PMT document extraction
- 🔄 Per-role pyramid drill-down views
- 🔄 Advanced analytics/reporting
- 🔄 Full SMART objective enhancement (timeframes, benefits, demonstrations)

**Is this scope division correct?**

---

## 📊 Mock UI Reference

**File:** `Phase2_Task3_Mock_UI_Presentation.html` (in this folder)

**What it shows:**
1. **High Maturity Scenario** (Pyramid View):
   - Organization-wide pyramid with 4 levels (Knowing, Understanding, Applying, Mastering)
   - Level 6 grayed out (no gaps)
   - All 16 competencies shown at each level (active or grayed)
   - Roles listed within each competency card
   - PMT-customized learning objectives
   - Validation summary at top

2. **Low Maturity Scenario** (Strategy-Based View):
   - Two strategy tabs (SE for Managers + Common Basic Understanding)
   - Progressive objectives shown within each competency
   - No role information (no defined roles in low maturity)
   - Standard template objectives (no PMT customization)
   - Validation summary at top

**Please review the mock UI and provide feedback on:**
- Is this the visualization approach you envision?
- Any changes needed to layout or structure?
- Does this clarify the pyramid concept?

---

## Summary of Critical Blockers

These **5 questions MUST be answered** before proceeding with implementation:

1. ❗ **Levels 3 and 5 handling** (data mismatch)
2. ❗ **Strategy validation threshold** (percentage)
3. ❗ **PMT in low maturity** (allowed or blocked)
4. ❗ **Pure median confirmation** (aggregation method)
5. ❗ **Per-role pyramid views** (needed or optional)

All other questions can be clarified during implementation, but these 5 are **architectural decisions**.

---

**Next Steps:**
1. Review mock UI HTML file
2. Answer critical questions (especially top 5)
3. Provide feedback on visualization approach
4. Share PMT example documents (if available)
5. Recommend progressive learning literature sources

---

*Document prepared by: Jomon (with Claude Code assistance)*
*For meeting with: Ulf (Thesis Advisor)*
*Date: 2025-11-14*
