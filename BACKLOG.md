# SE-QPT Project Backlog

**Last Updated:** 2025-12-06

This document tracks features, improvements, and issues that have been identified but deferred for future implementation (Phase 3, Phase 4, or post-thesis).

---

## Priority 1: High Impact, Deferred to Phase 3

### 1. SE for Managers Special Handling

**Source:** Meeting with Ulf, 21.11.2025 (Q1 discussion)

**Problem:**
- Managers need different learning objectives focus than other roles
- Should emphasize "What does SE mean for my company?" rather than "How to apply SE techniques"
- Currently treated the same as other competencies

**Requirements:**
- Create filtering/sectioning system in UI
- Section 1: "Learning Objectives for Managers"
- Section 2: "Learning Objectives for Technical Roles"
- Different phrasing/focus in LO text generation for manager pathway
- Need to define: Which competencies differ for managers? All 16 or subset?

**Impact:** Medium - Affects LO text generation and UI presentation

**Effort:** 2-3 weeks

---

### 2. Process and Policy Manager Role - Special Case Handling

**Source:** Meeting with Ulf, 21.11.2025 (Q5 discussion)

**Problem:**
- "Process and Policy Manager" role currently has ALL competencies at level 6
- Unrealistic - they're typically only responsible for ONE specific process (e.g., requirements process)
- Should only need high competency (level 6) in their specific process area, not all 16 competencies

**Requirements:**

**For Text-Based Role Input (Task-Based Assessment):**
- AI can infer which process from role description
- Example: "I am responsible for defining requirements" → Only high value for Requirements Definition competency

**For Role Selection (Standard Role Selection):**
- Add UI question: "Which process are you responsible for?"
- Dropdown with SE processes mapped to competencies
- Only assign high value (6) to that specific competency
- Other competencies get moderate values (2-4)

**Data Model Changes:**
- Potentially need `role_specialization` table
- Map specializations to competency requirements

**Impact:** Medium - Affects role-competency matrix logic and assessment

**Effort:** 2-3 weeks

---

### 3. AI-Based PMT Document Extraction

**Source:** PMT input method.md, Meeting notes

**Current State:**
- Manual PMT input via text fields (Processes, Methods, Tools)
- Works but time-consuming for users

**Enhancement:**
- Allow users to upload PDF/Word documents describing their SE processes
- AI (GPT-4/Claude) extracts:
  - Processes: "ISO 26262", "V-model", "Agile development"
  - Methods: "Scrum", "requirements traceability", "trade studies"
  - Tools: "DOORS", "JIRA", "Enterprise Architect"
- Pre-fill PMT form with extracted data
- User reviews and edits before proceeding

**Requirements:**
- Document upload component
- PDF/Word parsing
- LLM prompt engineering for extraction
- Validation and mapping to competency areas
- User review interface

**PMT Sample Files Available:** `/data/PMT` folder

**Impact:** High - Major UX improvement

**Effort:** 3-4 weeks

---

### 4. Role-Based Pyramid View (Second View)

**Source:** Meeting with Ulf, 21.11.2025 (Q5 discussion)

**Requirement:** Two different visualization views

**View 1 (CURRENT - Phase 2):** Competency Pyramid View
- Organizational pyramid (4 levels: Knowing, Understanding, Applying, Mastering)
- Each level shows all 16 competencies
- Within each competency: List roles that need training
- Example: "Level 2 - Systems Thinking: Requirements Engineer (8/10), Test Engineer (5/8)"

**View 2 (BACKLOG - Phase 3):** Role-Based View
- User selects one role from dropdown
- Shows that role's specific competency profile
- Pyramid structure showing what THIS ROLE needs at each level
- Competency cards show only if this role has gap
- Allows drill-down analysis per role

**Implementation:**
- Toggle/tab to switch between views
- Data structure supports both aggregations
- Cache role-specific pyramids for performance
- UI design for role selector and filtered pyramid

**Impact:** Medium - Enhances usability for role-focused analysis

**Effort:** 2 weeks

---

## Priority 2: Medium Impact

### 5. Cross-Strategy Validation and Recommendations

**Source:** Meeting with Ulf, 21.11.2025 (Q3 discussion)
**Status:** Explicitly deferred by Ulf ("Let's keep it out of scope for now")

**Concept:**
- Compare current competency levels vs selected strategy targets
- If 75%+ of competencies already exceed strategy targets → Show warning
- Suggest: "Competencies exceed strategy targets. Change strategy or Continue?"
- Provide recommendation for more appropriate strategy

**Note:** Only applicable to LOW MATURITY pathway

**Ulf's Comment:**
> "Last time I said we need it, this time I said we don't need it, maybe next time I'll say we need it."

**Decision:** Defer indefinitely. May reconsider after Phase 2 testing.

**Impact:** Low - Nice to have, not critical

**Effort:** 1-2 weeks

**Implementation Note (2025-12-06):**
Related but separate: `role_based_pathway_fixed.py` contains a fully implemented threshold-based validation system for the HIGH MATURITY pathway that calculates:
- Scenario A/B/C/D user classification
- Gap severity (critical/significant/minor) using configurable thresholds
- Strategy adequacy status (CRITICAL/INADEQUATE/ACCEPTABLE/GOOD/EXCELLENT)
- Fit scores per strategy per competency

This code **runs and calculates values** but the results at `gap_based_training.strategy_validation` are **not displayed in the frontend**. The frontend only shows the simpler "Mastery Level Advisory" from `validate_mastery_requirements()` in `learning_objectives_core.py`.

The thresholds are configurable in `src/backend/config/learning_objectives_config.json`:
- `critical_gap_threshold`: 60%
- `significant_gap_threshold`: 20%
- `inadequate_gap_percentage`: 40%

This is technical debt - the calculation runs but output is unused. Options for future:
1. Wire frontend to display threshold validation results
2. Remove unused code to simplify
3. Leave as-is for potential future use

---

### 6. Individual Coaching Recommendations

**Source:** Aggregation discussion, Meeting notes

**Problem:**
- Pure median aggregation can hide outliers
- Example: 9 experts + 1 beginner → Median = expert → No training planned
- The 1 beginner gets ignored

**Current Solution:**
- Focus on role-level training (median-based)
- Individual outliers are admin's responsibility (outside system)

**Potential Enhancement:**
- Flag distribution anomalies for admin awareness
- "Only 10% of this role needs training (1/10 users) - consider individual coaching"
- Separate section: "Individual Coaching Recommendations"
- List specific users who are outliers (far from median)
- Suggest: External certification, mentoring, one-on-one training

**Requirements:**
- Calculate distribution statistics (standard deviation, percentiles)
- Define threshold for "outlier" (e.g., >2 standard deviations from median)
- UI section for individual recommendations
- User privacy considerations

**Impact:** Medium - Helps catch edge cases

**Effort:** 2-3 weeks

---

### 7. Distribution Visualization

**Source:** Meeting with Ulf, 21.11.2025 (Q2 discussion)

**Requirement:**
> "We need a mechanism to visualize this range of values... if one person has a big gap but others don't, median will say gap is 0."

**Enhancement:**
- Per-competency overview showing:
  - Target level (from strategy)
  - How many roles/users achieved it
  - How many are below it
  - How many "haven't heard about it" (level 0)
  - Distribution graph (box plot, histogram, etc.)
- Statistics: Min, Max, Median, Mean, Standard Deviation
- Visual representation: "Line of values with middle box being the median"

**Use Cases:**
- Admin sees full picture before deciding training approach
- Understand spread: Tight cluster vs wide variance
- Identify bimodal distributions (2 distinct groups)

**Impact:** Medium - Better decision support

**Effort:** 2-3 weeks

---

## Priority 3: Low Impact or Post-Thesis

### 8. Advanced Analytics and Reporting

**Features:**
- Export learning objectives to PDF/Excel
- Generate training plan summary reports
- Cost estimation (based on training hours, external vs internal)
- Timeline projections (if sequential training over months)
- Competency gap heatmaps
- Progress tracking (if users retake assessment after training)

**Impact:** Low - Nice to have, not critical for thesis

**Effort:** 3-4 weeks

---

### 9. Full SMART Objective Enhancement

**Current State:**
- Learning objectives are template-based
- Generic structure with some PMT customization

**Enhancement:**
- Add **Timeframes**: "Within 3 months, participants are able to..."
- Add **Benefits**: "...enabling them to reduce requirements defects by 30%"
- Add **Demonstration methods**: "Demonstrated through project deliverables and peer review"
- Add **Measurement criteria**: "Success = 80% completion rate on competency assessment"

**Impact:** Low - Nice to have, but templates are sufficient for Phase 2

**Effort:** 1-2 weeks

---

### 10. Multi-Language Support

**Current State:**
- All content in English
- German templates exist but not integrated

**Enhancement:**
- Switch between English/German UI
- Translated learning objectives
- Localized competency descriptions

**Impact:** Low - Not required for thesis, but needed for real deployment in Germany

**Effort:** 2-3 weeks

---

## Bug Fixes and Technical Debt (No Timeline)

### 11. LLM Implementation Standardization

**Source:** Production debugging session, 2025-12-06

**Problem:**
The codebase has 11 LLM implementations using two different approaches:
- **LangChain ChatOpenAI** (4 instances): `generate_survey_feedback.py`, `llm_process_identification_pipeline.py`
- **Direct OpenAI SDK** (7 instances): All other files

This inconsistency caused a production issue where `langchain-openai==0.0.2` didn't support `with_structured_output()` used by feedback generation.

**Current State:**
| File | Approach | Output Format |
|------|----------|---------------|
| `generate_survey_feedback.py` | LangChain | Structured (Pydantic) |
| `llm_process_identification_pipeline.py` | LangChain | Structured (Pydantic) |
| `role_cluster_mapping_service.py` | Direct SDK | JSON |
| `custom_role_matrix_generator.py` | Direct SDK | JSON |
| `learning_objectives_core.py` | Direct SDK | Plain text |
| `learning_objectives_text_generator.py` | Direct SDK | Plain text |
| `routes.py` (document extraction) | Direct SDK | JSON |

**Recommendation:** Standardize on LangChain
- Better type safety with Pydantic models
- Automatic validation via `with_structured_output()`
- Consistent error handling
- Future-proof (LangChain handles API changes)

**Implementation Steps:**
1. Create central LLM client: `src/backend/app/services/llm_client.py`
2. Migrate Direct SDK calls to LangChain
3. Create Pydantic models for all structured responses
4. Centralize temperature constants (0=deterministic, 0.3=controlled, 0.8=creative)
5. Add token management across all implementations

**Fixed (2025-12-06):**
- Updated `requirements.txt`: `langchain-openai` 0.0.2 → 0.2.14
- Updated `langchain` 0.1.0 → 0.3.14
- Updated `langchain-community` 0.0.10 → 0.3.14
- Updated `pydantic` 2.5.2 → >=2.7.4

**Impact:** Low - Technical debt, not user-facing

**Effort:** 2-3 weeks

---

### 12. Flask Hot-Reload Issues (Windows)

**Problem:** Flask hot-reload doesn't work reliably on Windows

**Workaround:** Manual server restart after code changes

**Proper Fix:** Investigate watchdog configuration, consider using different development server

---

### 13. Unicode/Emoji Handling in Windows Console

**Problem:** Windows console (charmap encoding) can't handle emoji characters

**Current Mitigation:** Avoid all emoji/Unicode in code, use ASCII alternatives

**Proper Fix:** Configure proper UTF-8 encoding for console output

---

### 14. Database Connection Pooling

**Problem:** No connection pooling configured

**Risk:** Performance issues with many concurrent users

**Fix:** Configure SQLAlchemy connection pool for production

---

## Completed Items (Moved from Backlog)

### ✅ Levels 3 and 5 Data Mismatch

**Status:** RESOLVED (2025-11-24)

**Problem:** Database had 262 assessments with level 3, 46 with level 5, but templates only for 1,2,4,6

**Solution:** Data migration completed, assessment forms now only allow 0,1,2,4,6

---

### ✅ Dual-Track Processing (Train the Trainer)

**Status:** IMPLEMENTED (Phase 2)

**Requirement:** Separate processing for "Train the Trainer" strategy

**Solution:** Excluded from validation, processed separately, shown in dedicated section

---

## Backlog Items from Meeting 28.11.2025

### 14. Train the Trainer (TTT) - Third Path Implementation

**Source:** Meeting with Ulf, 28.11.2025

**Current State:** TTT shown in separate section below main pyramid

**Ulf's New Direction:**
- TTT should be a **third additional path** (separate from high/low maturity paths)
- User should **complete entire training planning first** (Phases 3 and 4)
- **Then loop back** to Phase 2 LO task for TTT handling as the **last step**
- Level 6 is specifically for **process owners**

**Requirements:**
- Define what makes someone a "process owner" (Role that is "Responsible" for a process in role-process matrix)
- Determine which specific competency needs Level 6 based on which process they own
- May need to derive from role-process and process-competency matrix calculations
- Create separate TTT workflow after Phase 4 completion

**Decision for Now:** Skip Level 6 from UI, defer TTT implementation

**Impact:** Medium - Architectural change to workflow

**Effort:** 3-4 weeks (after Phase 3-4 completion)

---

### 15. Level 6 / Mastery - Process Owner Logic

**Source:** Meeting with Ulf, 28.11.2025

**Problem:**
- Level 6 is for process owners specifically
- Not everyone needs Level 6
- Only process owners for specific processes need Level 6 in THOSE competencies
- Example: Process owner for Requirements Management needs Level 6 only in Requirements Definition

**Requirements:**
- Identify process owners from role-process matrix (roles with "Responsible" designation)
- Map process ownership to specific competency requirements
- Calculate Level 6 requirements per role based on process ownership
- Show Level 6 only for applicable role-competency combinations

**Open Questions:**
- How exactly to map process → competency for Level 6 requirements?
- Does owning Requirements process = Level 6 in Requirements Definition only? Or related competencies too?

**Decision:** Defer to backlog, implement when TTT workflow is built

**Impact:** Medium - Affects role-competency matrix logic

**Effort:** 2-3 weeks

---

### 16. Phase 3 Learning Format Recommendations - Design Required

**Source:** Meeting with Ulf, 28.11.2025

**Current State:**
- Per-role "Recommended Training Approach" shown in Role-Based View (sneak preview)
- DISTRIBUTION_SCENARIO_ANALYSIS.md created with scenario-based recommendations

**Ulf's Direction:**
- Learning formats are NOT tied to strategies
- Need aggregate view: "How many people need Level X across ALL roles"
- Per-competency recommendations, not per-role primarily
- Optional drill-down to per-role after aggregate view
- Must consider: Group size from Phase 1, gap distribution patterns, level being targeted

**Key Rules from Ulf:**
- **E-learning limitation:** Can only achieve up to Level 2 (Understanding), NOT Level 4 (Applying)
- **Module structure:** 3 modules per competency (Levels 1, 2, 4) - cut module if no gap exists
- **Two concerns:** (1) What modules needed, (2) What format for those modules
- **Recommendations only:** User makes final selection, we suggest with rationale

**Design Inputs Required:**
- Sachin's thesis on learning formats (`\data\source\thesis_files\Sachin_Kumar_Master_Thesis_6906625.pdf`)
- DISTRIBUTION_SCENARIO_ANALYSIS.md
- TRAINING_METHODS.md
- Gap data per competency per level
- User counts per module need
- Training group size from Phase 1

**Next Steps:**
1. Study Sachin's thesis
2. Brainstorm comprehensive design
3. Create conceptual visualization for Ulf
4. Implement after Phase 2 LO task finalized

**Impact:** High - Major Phase 3 feature

**Effort:** 4-6 weeks

---

### 17. Strategy Change Recommendation (Textual Only)

**Source:** Meeting with Ulf, 28.11.2025 (Scenario 4 discussion)

**Context:**
- In Scenario 4 (10% beginners, 90% experts), Ulf suggested recommending Certification strategy
- This implies the system might suggest changing strategies based on distribution analysis

**Decision:**
- Provide as **textual recommendation only** for now
- Do NOT automatically update selected strategies
- Example text: "Based on distribution analysis, only 2 users need training. Consider using Certification strategy for these individuals."
- Future enhancement may allow actual strategy updates

**Impact:** Low - Text recommendation only

**Effort:** 1 week (as part of Phase 3 format recs)

---

### 18. PMT Breakdown for Additional Competencies

**Source:** Meeting with Ulf, 28.11.2025

**Ulf's Statement:** These competencies need PMT breakdown added:
- Integration, Verification & Validation (currently hasPMT: false)
- Decision Management (currently hasPMT: false)
- Information Management (currently hasPMT: false)

**Already Have PMT:**
- Project Management ✓
- Configuration Management ✓
- Requirements Definition ✓
- System Architecting ✓
- Agile Methods ✓

**Requirements:**
- Analyze current PMT template patterns
- Create consistent PMT breakdown text for the 3 missing competencies
- Update se_qpt_learning_objectives_template_v2.json

**Impact:** Low - Template content update

**Effort:** 1 week

---

## Notes

- **Phase 2 Scope:** Focus on core learning objectives generation with pyramid structure
- **Phase 3 Candidates:** Items 1-4, 7 (highest priority enhancements)
- **Post-Thesis:** Items 5-6, 8-10 (nice to have, not critical)
- **Ulf's Prioritization:** "SE for Managers special handling" and "Role-based view" mentioned explicitly

---

**How to Use This Backlog:**

1. When new features are discussed but deferred → Add to this file
2. When starting Phase 3 → Review Priority 1 items
3. When planning post-thesis deployment → Review Priority 2-3 items
4. Keep "Completed Items" section as historical reference

---

*Last reviewed: 2025-11-24*
*Next review: After Phase 2 completion*
