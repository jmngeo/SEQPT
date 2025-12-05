# Phase 3 Learning Format Recommendations - Design Inputs

**Date:** 2025-11-28
**Source:** Meeting with Ulf (28.11.2025)
**Status:** DESIGN REQUIRED - Implementation deferred until Phase 2 LO task complete

This document captures all inputs from Ulf's meeting for designing the Phase 3 Learning Format Recommendations and Module Selection tasks.

---

## 1. KEY DESIGN PRINCIPLES FROM ULF

### 1.1 Two Separate Concerns

Ulf emphasized separating:

1. **What modules are needed** (gap-based determination)
   - 3 modules per competency (Levels 1, 2, 4)
   - If no gap at a level -> cut that module
   - Based purely on assessment gaps

2. **What training format/approach to use** for those modules
   - E-learning, Group Training, Coaching, Certification, etc.
   - Based on: group size, distribution pattern, level being targeted

### 1.2 Module Structure

- **3 modules per competency maximum** (since Level 6 is excluded)
- Modules correspond to: Level 1 (Knowing), Level 2 (Understanding), Level 4 (Applying)
- Cut module if no gap exists at that level

### 1.3 Aggregate View vs Per-Role View

**Ulf's direction**: Start with AGGREGATE view (all users across all roles):
- "How many people need to achieve Level 2 in Systems Thinking?"
- Not per-role deep dive as primary

**Then optional**: Drill-down to per-role view
- "Who are these 400 people? What roles are they?"
- Secondary analysis layer

### 1.4 Learning Formats are NOT Tied to Strategies

Learning format recommendations are independent of selected strategies.
- Strategies determine TARGET levels
- Formats determine HOW to achieve those targets
- Different considerations

---

## 2. CRITICAL RULES FROM ULF

### 2.1 E-Learning Level Limitation

**RULE**: E-learning can ONLY achieve up to Level 2 (Understanding)

| Level | E-Learning Suitable? |
|-------|---------------------|
| Level 1 (Knowing) | YES |
| Level 2 (Understanding) | YES |
| Level 4 (Applying) | NO - requires hands-on practice |

**Implication**: Never recommend E-learning for Level 4 training

### 2.2 Group Size Considerations

- **Large number (e.g., 1000 people)** needing Level 2 -> E-learning or Online training
- **Small number** needing Level 4 -> Group training, Coaching, Workshop
- **Very small number** (e.g., 2 people) -> Individual coaching, External certification

### 2.3 Module Grouping Possibility

Ulf mentioned possibility of grouping modules together:
- Example: Workshop covering Levels 1+2+4 together
- For users who need to go from Level 0 to Level 4
- "One big workshop" approach

### 2.4 Cost is NOT Calculated

**Decision**: We do NOT calculate or recommend based on cost
- Sachin's thesis has hints about cost implications
- User can read Sachin's work to understand cost factors
- We show formats and let user decide

---

## 3. SCENARIO-BASED RECOMMENDATIONS (from DISTRIBUTION_SCENARIO_ANALYSIS.md)

Ulf reviewed and APPROVED this analysis. Key mapping:

| Scenario | Distribution | Modules Needed | Ulf's Format Recommendation |
|----------|-------------|----------------|----------------------------|
| 1: All Level 0 | 100% beginners | All 3 | Group Training (progressive) |
| 2: All Level 4 | 100% experts | 0 | No training needed |
| 3: 90% beginners, 10% experts | Most need training | All 3 | Group Training, experts as mentors |
| 4: 10% beginners, 90% experts | Few need training | Consider external | **Recommend Certification strategy change** |
| 5: 50/50 split | Bimodal | All 3 | Split into 2 groups |
| 6: Equal distribution | Spread across levels | All | Blended/flexible approach |
| 7: 80% at Level 2 | Tight cluster | Depends | Group training |
| 8: Few users need | Very few gaps | Consider external | Similar to Scenario 4 |

**Key Insight for Scenario 4 & 8**: When only a few users need training, recommend:
- NOT building internal training
- Instead: External certification, individual coaching
- Textual recommendation to "consider changing to Certification strategy"

---

## 4. DESIGN INPUTS TO CONSIDER

### 4.1 Available Data Inputs

1. **Gap Data per Competency per Level**
   - How many users need Level 1, Level 2, Level 4 for each competency
   - Aggregate across all roles

2. **Training Group Size** (from Phase 1)
   - "Total training group size" input from organization

3. **Distribution Pattern**
   - Variance, bimodal detection
   - Gap percentage (what % of users need training)

4. **User Count per Module Need**
   - For each competency: X users need Level 1, Y users need Level 2, Z users need Level 4

5. **Role Association** (secondary, for drill-down)
   - Which roles are these users from?
   - Per-role distribution statistics

### 4.2 Sachin's Thesis (TO BE ANALYZED)

**Location**: `\data\source\thesis_files\Sachin_Kumar_Master_Thesis_6906625.pdf`

**What to extract**:
- Learning format definitions and terminology (use Sachin's wording)
- Format-level suitability matrix (which formats for which levels)
- Initial effort vs ongoing cost considerations
- Pros/cons of each format
- Any decision rules or flowcharts

### 4.3 Existing Reference Documents

1. **DISTRIBUTION_SCENARIO_ANALYSIS.md** - Scenario-based recommendations (Ulf approved)
2. **TRAINING_METHODS.md** - Training method descriptions
3. **Design v5 documentation** - Current LO design context

---

## 5. OUTPUT EXPECTATIONS

### 5.1 What to Show User

1. **Learning Objectives** (already generated in Phase 2)

2. **Module Overview** (NEW)
   - Per competency: Which modules (levels) are needed
   - User counts per module
   - "Systems Thinking: 400 users need Level 2 module"

3. **Learning Format Options** (NEW)
   - List of available formats (from Sachin's thesis)
   - User can click to see explanation

4. **Recommendations with Rationale** (NEW)
   - Per competency or per module
   - "We recommend: E-learning for Level 2"
   - "Rationale: 400 users need this level, making e-learning cost-effective"

5. **User Selection** (NEW)
   - Recommendations are suggestions only
   - User can select different format
   - Final selection stored for Phase 4

### 5.2 Recommendation Presentation

Ulf's guidance:
> "We would say these are the learning objectives you have to work on based on the gaps you have. These are the LO you should achieve. What you have to do now is to select a learning format how you think you want to achieve that."

Show:
- Gap data (from Phase 2)
- Format options (from Sachin)
- Our recommendation + rationale
- Let user decide

---

## 6. OPEN DESIGN QUESTIONS

### 6.1 Scope Questions

1. **Per-competency or per-module recommendations?**
   - One recommendation per competency (covering all its modules)?
   - Or one recommendation per module (per level)?
   - Ulf seemed to suggest per-competency

2. **How to handle mixed level needs?**
   - User needs Level 1, 2, AND 4 in same competency
   - Different formats for different levels?
   - Or one combined workshop?

3. **How granular is the drill-down?**
   - Show per-role breakdown always?
   - Or only on user request?

### 6.2 Logic Questions

1. **How to determine bimodal distribution?**
   - What threshold triggers "split into groups" recommendation?
   - Need algorithm definition

2. **How to combine multiple factors?**
   - Group size + distribution + level = recommendation
   - Need decision matrix or rules engine

3. **When to suggest strategy change?**
   - Scenario 4 suggests "change to Certification strategy"
   - What exact conditions trigger this?

---

## 7. NEXT STEPS

### 7.1 Immediate (Before Design)

1. [ ] Complete Phase 2 LO task fixes (separate document)
2. [ ] Study Sachin's thesis thoroughly
3. [ ] Extract learning format definitions
4. [ ] Map format-level suitability

### 7.2 Design Phase

1. [ ] Brainstorm session with all inputs
2. [ ] Create decision matrix/rules
3. [ ] Design aggregate view structure
4. [ ] Design drill-down flow
5. [ ] Create conceptual visualization for Ulf

### 7.3 Implementation (After Design Approval)

1. [ ] Backend: Calculate module needs from gap data
2. [ ] Backend: Implement recommendation logic
3. [ ] Frontend: Module overview UI
4. [ ] Frontend: Format selection UI
5. [ ] Testing with real data

---

## 8. RELATED BACKLOG ITEMS

From BACKLOG.md (updated 2025-11-28):

- **#14**: Train the Trainer (TTT) - Third Path Implementation (DEFERRED)
- **#15**: Level 6 / Mastery - Process Owner Logic (DEFERRED)
- **#16**: Phase 3 Learning Format Recommendations - Design Required (THIS DOCUMENT)
- **#17**: Strategy Change Recommendation - Textual Only

---

## 9. KEY QUOTES FROM ULF

> "I'm always trying to think about the company Miele. At Miele, there are certain engineers who need to Understand Requirements Engineering, some who need to Apply it, and all need to Know it. They said - not everyone needs to get into our training. For the Knowing ones we have a Video they can watch."

> "We need to identify what kind of modules we need. We have 3 modules per competency. If there is no gap, then one module can be cut."

> "E-learning can help you create understanding basics. You probably might not be able to achieve Applying level with e-learning."

> "These are just recommendations. What is more interesting than having this kind of calculation is what are the recommendations we would provide."

> "We take a step back and focus on how would we do that without all the information we have used before. Get a better understanding of what is actually necessary."

---

*Document created: 2025-11-28*
*Source: Meeting notes 28.11.2025.txt*
*Status: Input collection complete, design phase pending*
