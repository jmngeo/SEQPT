# Comprehensive Analysis of Meeting Notes (28.11.2025)

I've thoroughly read through your meeting notes with Ulf. This is a detailed analysis covering requirements, feedback, clarifications, and open questions.

---

## SECTION 1: FEEDBACK ON CURRENT LEARNING OBJECTIVES IMPLEMENTATION

### 1.1 UI/Display Issues Identified

| Issue | Current State | Ulf's Feedback | Required Action |
|-------|--------------|----------------|-----------------|
| **"20 Skill Gaps to Train" label** | Shows total gap count | Confusing - suggests 20 competencies have gaps when there are only 16 total | Change wording to **"Levels to Advance"** |
| **"16 Total Competencies" stat** | Shows total competencies | Should show competencies WITH gaps, not total | Show **"Competencies with Gap"** (unique count) |
| **LO text format** | One paragraph per competency | Hard to see how many objectives exist | Convert to **bullet points per sentence** for clarity |
| **Level numbering in UI** | Shows "Level 1, Level 2, Level 4" | Users ask "Why no Level 3?" | **Remove level numbers** - just show "Knowing SE", "Understanding SE", "Applying SE" |

### 1.2 LO Text Mapping Bug (CRITICAL)

**Problem Identified**: For competency "Agile Methods", the generated LO text incorrectly mentions "SysML diagram types including Requirements Diagram (REQ)..." - this is System Architecting content, NOT Agile Methods content.

**Ulf's Analysis**: The LLM is incorrectly mapping/hallucinating content to wrong competencies.

**Your Understanding (Correct)**:
1. Check template_v2.json first to ensure correct base data
2. Check LLM prompt structure
3. Verify structured input is being sent correctly (competency name, level, template text)
4. Ensure structured output maintains correct mapping

**Ulf's Suggestions**:
1. Split bulk prompts into individual prompts (one per competency per level)
2. Make LLM prompt stricter - allow "no matching data" as valid output
3. Prevent hallucination by being explicit that LLM shouldn't force-find content

---

## SECTION 2: NEW FEATURE REQUIREMENTS

### 2.1 Export Feature
**Requirement**: Add export button to download LOs as Excel
- Structure similar to the "Learning Objectives" sheet
- Matrix of Competencies and their LO texts, levels - all in one sheet
- "All-in-one Competency view"

### 2.2 PMT Breakdown Display
**Requirement**: Keep showing Process, Method, Tool breakdown in competency cards where applicable
- Currently we have this for some competencies (Requirements Definition, System Architecting, etc.)

### 2.3 Role Legend Enhancement
**Requirement**: For orgs with roles, we show "Roles Needing This Level: Integration Engineer (2/4)"
- Add legend explaining: "(2/4) = 2 out of 4 Integration Engineers have not achieved this level yet"
- Place near existing legend "Level indicator: Current -> Target"

### 2.4 PMT Competencies Update (Template Change)
**Ulf's Statement**: These additional competencies need PMT breakdown:
- Integration, Verification & Validation *(currently hasPMT: false)*
- Project Management *(already has PMT)*
- Decision Management *(currently hasPMT: false)*
- Information Management *(currently hasPMT: false)*
- Configuration Management *(already has PMT)*

---

## SECTION 3: TRAIN THE TRAINER (TTT) STRATEGY - MAJOR DESIGN CHANGE

### 3.1 TTT Separate Treatment
**Current Design**: TTT is handled in a separate section below main pyramid

**Ulf's NEW Direction**:
1. TTT should be a **third additional path** (separate from high/low maturity paths)
2. The user should **complete the entire training planning first** (Phases 3 and 4)
3. **Then loop back** to Phase 2 LO task for TTT handling as the **last step**
4. For now: **Skip Level 6 from the main view entirely**

### 3.2 Level 6 / Mastery Handling
**Ulf's Clarification**:
- Level 6 is for **process owners** specifically
- Not everyone needs Level 6
- Only process owners for specific processes need Level 6 in those competencies
- Example: Process owner for Requirements Management needs Level 6 only in Requirements Definition

**Decision for Now**:
- **Skip Level 6 "Mastering" from the LO results page**
- Focus on showing levels 1, 2, 4 only
- TTT and Level 6 will be handled later (backlog item) when we implement process owner logic

---

## SECTION 4: PHASE 3 - MODULE SELECTION & LEARNING FORMAT RECOMMENDATIONS

This is the major forward-looking discussion. **Key insight**: Ulf doesn't have fixed requirements yet.

### 4.1 Training Format Question Clarification

**Ulf's Question**: "Training Format recommendation: Based on the competency assessment, the idea is to give hints which format would be the best to use independently from the strategy, right?"

**Your TODO**: Check current implementation and provide answer.

### 4.2 DISTRIBUTION_SCENARIO_ANALYSIS.md Feedback

Ulf liked this analysis! He wants to keep and use it with modifications:

**Per-Scenario Analysis** (from your meeting):

| Scenario | Ulf's Input | Modules Needed | Recommended Approach |
|----------|-------------|----------------|---------------------|
| 1: All at Level 0 | 3 modules needed | All 3 | Group training |
| 2: All at Level 4 | No modules needed | 0 | No training |
| 3: 90% Beginners, 10% Experts | 3 modules needed | 3 (but few don't need) | Use experts as mentors |
| 4: 10% Beginners, 90% Experts | Only 2 users need training | Consider external | **IMPORTANT**: Recommend Certification strategy change |
| 5: 50/50 split | Full 3 modules | 3 | Split into 2 groups |
| 6: Equal distribution all levels | All levels needed | All | Consider approach |
| 7: 80% at Level 2 | Makes sense to have modules | Depends | Group training |
| 8: Few users need training | Doesn't make sense | Consider external | Similar to Scenario 4 |

### 4.3 Key Phase 3 Design Principles

**CRITICAL INSIGHT from Ulf**:

1. **Module Structure Decision**:
   - We have **3 modules per competency** (since we skip Level 6)
   - Corresponds to Levels 1, 2, 4
   - If no gap exists for a level → cut that module

2. **Two Separate Concerns**:
   - **What modules are needed** (gap-based)
   - **What training approaches/formats** to recommend for those modules

3. **Scope of Analysis**:
   - Originally you were analyzing per-role (DISTRIBUTION_SCENARIO_ANALYSIS.md)
   - **Ulf says**: Consider ALL roles and ALL users together
   - Question becomes: "How many people need to achieve Level 2 across ALL roles?"

4. **Aggregation Approach**:
   - Per-competency view: "400 people need Level 2 in Systems Thinking"
   - Then: "What roles are these people from?"
   - Not per-role deep dive, but aggregate counts

5. **Learning Format Considerations** (from Ulf):
   - E-learning can only get you to Understanding level (Level 2), not Applying (Level 4)
   - Group training for Knowing level alone may not make sense
   - Large number → Online training or E-learning for lower levels
   - Small number → Group training, coaching, or certification

### 4.4 Sachin's Thesis - TODO

**Action Required**: Study Sachin's thesis on "Identifying suitable learning formats for Systems Engineering"
- Use Sachin's learning format definitions/wording
- This provides the foundation for format recommendations

### 4.5 Cost Consideration

**Ulf's Decision**: We will **NOT** make cost recommendations directly
- Sachin's work has hints about initial effort, etc.
- User can read Sachin's work themselves to understand cost implications
- We don't calculate or recommend based on cost

---

## SECTION 5: PHASE 3 OUTPUT EXPECTATIONS

### 5.1 What to Show User

1. **Learning Objectives** derived from gaps
2. **Learning Format Options** (list of what they could use)
3. **Recommendations with Rationale**:
   - "Based on your input: 400 people need Level 2 in Systems Thinking"
   - "We recommend: E-learning format"
   - "Rationale: Large group size makes e-learning cost-effective for Understanding level"

4. **Per-Competency Recommendations** (not per-role)
5. **User can click formats** to see Sachin's overview/explanation
6. **User makes final selection** (recommendations only, not mandatory)

### 5.2 Next Meeting Preparation

**Ulf's Request**:
- Take a step back from implementation
- Create a **conceptual design visualization**
- Show: What inputs we have → How they are processed → What outputs we produce
- Focus on: What is actually necessary? What needs to be considered?

---

## SECTION 6: CLARIFICATIONS & CONFIRMATIONS

### 6.1 Confirmed Items

| Topic | Confirmation |
|-------|-------------|
| "20 Skill Gaps" data usage | Yes, this maps to modules in Phase 3 - the levels to advance |
| PMT breakdown display | Keep showing P, M, T separately in competency cards |
| LO template structure | Current template_v2.json is mostly OK |
| Distribution scenarios | Valuable work, should be part of thesis |
| Learning format selection | Part of Phase 3, uses gap data + group size |
| Recommendations only | User has ability to choose, not forced |

### 6.2 Items to Skip/Defer

| Topic | Decision |
|-------|----------|
| Level 6 in UI | Skip for now, show levels 1, 2, 4 only |
| TTT handling | Defer to backlog, after Phase 3 & 4 completion |
| Per-role deep analysis | Aggregate across roles instead |
| Cost calculations | Not in scope |

---

## SECTION 7: QUESTIONS & CLARIFICATIONS

### Q1: Level 6 Removal Scope
**Decision**: Remove Level 6 tab entirely from UI, no TTT section for now.

### Q2: "Competencies with Gap" Stat
**Decision**: Count unique competencies that have ANY gap at ANY level across all users.
- Example: If Systems Thinking has gaps at Level 1 and Level 2, that's 1 competency with gap, not 2.

### Q3: PMT Breakdown for Additional Competencies
**Decision**: Create new PMT breakdown text for IVV, Decision Management, Information Management based on analyzing current template patterns.

### Q4: LLM Prompt Issue
**Priority**: Fix this first. Analyze thoroughly why mismatch occurred before deciding on implementation approach.

### Q5: Role Legend Format
**Confirmed**: (2/4) = "2 out of 4 Integration Engineers have NOT achieved this level yet" (need training)

### Q6: Training Format Recommendation
**Clarification**: This is for Phase 3 Learning format task. Current "Recommended Training Approach" in Role-Based View is a preview. Learning formats are NOT tied to strategies.

### Q7: Scenario 4 Strategy Change Recommendation
**Decision**: Provide as textual recommendation for now. No automatic strategy updates.

### Q8: E-learning Level Limitation Rule
**RULE**: E-learning can only achieve up to Level 2 (Understanding). Never recommend E-learning for Level 4 (Applying).

### Q9: Process Owner Definition
**Confirmed**: Process owner = Role that is "Responsible" for a process (not just Supporting/Involved).
**Note**: TTT and Process Owner topics are BACKLOG items.

### Q10: Per-Role vs Aggregate Analysis
**Decision**: Show aggregate primarily, with optional drill-down to per-role.
- Check what modules (gaps) are needed by how many users irrespective of roles
- Make insights into user counts per module per competency
- Then link back role data for per-role view

### Q11: Sachin's Thesis
**Location**: `\data\source\thesis_files\Sachin_Kumar_Master_Thesis_6906625.pdf`
**Action**: Analyze later for creating format recommendations design.

### Q12: Conceptual Design
**Action**: Create visualization after brainstorming and finalizing design.

---

## SECTION 8: SEPARATION OF CONCERNS

As per Jomon's guidance, we separate:

### Part A: Phase 2 LO Task - Current Implementation Fixes
1. Fix LO text mapping bug (investigate root cause first)
2. UI label changes
3. Remove Level 6 from display
4. Add Excel export
5. Update PMT templates

### Part B: Phase 3 Learning Format & Module Selection - Future Design
1. Study Sachin's thesis
2. Brainstorm design with all inputs
3. Create conceptual visualization
4. Implement after Phase 2 LO task is finalized

---

## SUMMARY OF IMMEDIATE ACTION ITEMS

### Priority 1 (Bug Investigation)
1. Investigate LO text mapping bug root cause
2. Check all LO texts for correct competency mapping

### Priority 2 (UI Changes)
3. Change "Skill Gaps to Train" → "Levels to Advance"
4. Change "Total Competencies" → "Competencies with Gap" (unique count)
5. Convert LO text to bullet points
6. Remove level numbers from UI (show names only)
7. Add role legend explanation
8. Remove Level 6 tab from UI

### Priority 3 (Feature Additions)
9. Add Excel export button
10. Create PMT templates for additional competencies

### Priority 4 (Documentation)
11. Update BACKLOG.md with deferred items
12. Prepare for Phase 3 design brainstorming

---

*Document Created: 2025-11-28*
*Source: Meeting notes 28.11.2025.txt*
