# Distribution Scenario Analysis for Training Planning

**Date:** 2025-11-24
**Purpose:** Analyze different user competency distribution patterns to determine appropriate aggregation and training methods
**Context:** To explore scenarios to understand when median works and when it doesn't
**Reference:** Links to TRAINING_METHODS.md for training approach recommendations

---

## Executive Summary

**Key Findings:**

1. **Median is reliable when:**
   - Distribution is tight (low variance)
   - Uniform or normal distribution
   - 70%+ of users cluster near median value

2. **Median is misleading when:**
   - Bimodal distribution (two distinct groups)
   - High variance (users scattered across levels)
   - Extreme outliers pull median away from majority

3. **Recommendation:** Use **Median + Distribution Context** approach
   - Decision based on median (simple, fast)
   - Calculate variance/distribution for validation
   - Flag anomalies for admin awareness

---

## Scenario Parameters

**Consistent Across All Scenarios:**
- **Role:** Requirements Engineer
- **Competency:** Systems Thinking
- **Strategy Target:** Level 4 (Applying)
- **Role Requirement:** Level 4 (from role-competency matrix)
- **Number of Users:** 20 (representative team size)

**Competency Scale:**
- 0 = No knowledge
- 1 = Awareness (Knowing)
- 2 = Understanding
- 4 = Application (Applying)
- 6 = Mastery

---

## Scenario 1: All at Level 0 (Complete Beginners)

### Distribution
```
Level 0: ████████████████████ (20 users, 100%)
Level 1:
Level 2:
Level 4:
Level 6:

User Scores: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
```

### Statistics
- **Median:** 0
- **Mean:** 0
- **Mode:** 0
- **Variance:** 0 (perfect uniformity)
- **Gap:** 4 levels (0 → 4)

### Analysis

**Is Median Reliable?** ✅ YES
- Perfect uniformity - median accurately represents everyone

**Training Need:**
- 100% of role needs training
- All need levels 1, 2, and 4 progressively

### Recommended Approach

**Training Method:** Group Classroom Training (Progressive Modules)
- **Module 1:** Level 1 (Knowing SE) - All 20 participants
- **Module 2:** Level 2 (Understanding SE) - All 20 participants
- **Module 3:** Level 4 (Applying SE) - All 20 participants

**Rationale:**
- Most cost-effective for large group
- Everyone starts at same point
- Build shared foundation and vocabulary
- Sequential learning path makes sense

**Estimated Cost:** Low per participant (€500-1000 per person for full 3-module program)

**Timeline:** 3-6 months (spread modules over time for application practice)

**Reference:** TRAINING_METHODS.md - Section 1: Group Classroom Training

---

## Scenario 2: All at Level 4 (Experts)

### Distribution
```
Level 0:
Level 1:
Level 2:
Level 4: ████████████████████ (20 users, 100%)
Level 6:

User Scores: [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
```

### Statistics
- **Median:** 4
- **Mean:** 4
- **Mode:** 4
- **Variance:** 0 (perfect uniformity)
- **Gap:** 0 levels (already at target)

### Analysis

**Is Median Reliable?** ✅ YES
- Perfect uniformity at target level

**Training Need:**
- 0% of role needs training
- Target achieved

### Recommended Approach

**Training Method:** No Training Required

**Optional Enhancement:**
- **Communities of Practice** - maintain and share knowledge
- **Mastery Development** (Level 6) - for 2-3 selected individuals who want to become trainers/experts

**Rationale:**
- Already competent at required level
- Resources better spent elsewhere
- Optional: Maintain competency through CoP

**Cost:** $0 for training (optional CoP facilitation ~€100/month)

**Reference:** TRAINING_METHODS.md - Section 8: Communities of Practice

---

## Scenario 3: 90% Beginners, 10% Experts (Majority Needs Training)

### Distribution
```
Level 0: ██████████████████ (18 users, 90%)
Level 1:
Level 2:
Level 4: ██ (2 users, 10%)
Level 6:

User Scores: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4]
```

### Statistics
- **Median:** 0
- **Mean:** 0.4
- **Mode:** 0
- **Variance:** 1.44 (low - most at level 0)
- **Gap:** 4 levels for majority

### Analysis

**Is Median Reliable?** ✅ YES
- Median = 0 accurately represents 90% of users
- The 2 experts (10%) are the exception, not the rule

**Training Need:**
- 90% of role needs training (18/20 users)
- 10% already at target (2/20 users)

### Recommended Approach

**Training Method:** Group Training with Experts as Mentors

**Implementation:**
- All 20 users attend the training program
- 18 beginners are learners
- 2 experts attend as facilitators/mentors/helpers
- Experts benefit from reinforcing knowledge by teaching others

**Benefits:**
- Cost-effective (one training program)
- Experts' knowledge is utilized
- Teaching reinforces expert competency
- Beginners get additional support from peers
- Builds team cohesion

**Alternative (Less Recommended):**
- Train 18 beginners only, 2 experts don't attend
- Risk: Creates knowledge silos, missed team-building opportunity

**Cost:** Low per participant (~€500-800 per person)

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Section 1: Group Classroom Training

**FLAG for Admin:** ✅ "90% of role needs training - group training highly appropriate"

---

## Scenario 4: 10% Beginners, 90% Experts (Minority Needs Training)

### Distribution
```
Level 0: ██ (2 users, 10%)
Level 1:
Level 2:
Level 4: ██████████████████ (18 users, 90%)
Level 6:

User Scores: [0,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
```

### Statistics
- **Median:** 4
- **Mean:** 3.6
- **Mode:** 4
- **Variance:** 1.44 (low - most at level 4)
- **Gap:** Median shows no gap, but 2 users have gap

### Analysis

**Is Median Reliable?** ⚠️ PARTIALLY
- Median = 4 = target → Says "no training needed"
- BUT 2 users (10%) do need training
- **Median hides the minority gap**

**Training Need:**
- 90% don't need training (18/20 users)
- 10% need training (2/20 users)

### Recommended Approach

**Training Method:** Individual Approach for the 2 Beginners

**Options for the 2 Users:**

**Option A: External Certification**
- Send 2 users to industry certification course
- Standardized content, recognized credential
- Cost: €2000-3000 per person
- Timeline: 1-2 weeks

**Option B: Mentoring by Internal Experts**
- Pair each beginner with one of the 18 experts
- Structured mentoring plan (3-6 months)
- Regular check-ins, guided learning
- Cost: Low (internal time allocation)

**Option C: Self-Study + Support**
- E-learning courses (Coursera, LinkedIn Learning)
- Expert available for Q&A
- Cost: Very low (~€50/person)
- Requires self-motivation

**Option D: Training on the Job**
- Assign beginner to projects with SE focus
- Expert supervision and feedback
- Progressive responsibility
- Cost: Low (supervision time)

**Recommended:** Option B or D (mentoring or on-the-job) - leverages internal experts

**DO NOT:** Run group training for all 20 users - not cost-effective for 2 people

**Cost:** Low (~€500 per person for mentoring time)

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Sections 5, 6: Mentoring and Training on the Job

**FLAG for Admin:** ⚠️ "Only 10% of role needs training (2/20 users) - individual approach recommended, group training not cost-effective"

---

## Scenario 5: Bimodal Distribution (50/50 Split)

### Distribution
```
Level 0: ██████████ (10 users, 50%)
Level 1:
Level 2:
Level 4:
Level 6: ██████████ (10 users, 50%)

User Scores: [0,0,0,0,0,0,0,0,0,0,6,6,6,6,6,6,6,6,6,6]
```

### Statistics
- **Median:** 3 (between 0 and 6)
- **Mean:** 3
- **Mode:** Bimodal (0 and 6)
- **Variance:** 9 (HIGH - very dispersed)
- **Gap:** Median suggests gap, but doesn't show bimodal reality

### Analysis

**Is Median Reliable?** ❌ NO - VERY MISLEADING
- Median = 3 (not even a valid level in our scale!)
- **NO ONE is actually at level 3**
- Two completely distinct groups:
  - Group A: 10 complete beginners (level 0)
  - Group B: 10 masters (level 6)
- Median completely hides this reality

**Training Need:**
- 50% need extensive training (10 users, levels 1,2,4)
- 50% need no training, already exceed target (10 users)

### Recommended Approach

**Training Method:** SPLIT INTO TWO SEPARATE GROUPS

**Group A (10 Beginners):**
- Progressive group training (levels 1, 2, 4)
- All 10 attend together
- Cost: €600-1000 per person
- Timeline: 3-6 months

**Group B (10 Masters):**
- No training required
- Optional: Advanced topics (mastery development)
- Optional: Train-the-trainer (make them internal trainers)
- Optional: Community of practice facilitators

**DO NOT:**
- Combine groups in one training
- Pace will frustrate both groups:
  - Too slow for experts (level 6)
  - Too fast for beginners (level 0)
- Waste of experts' time

**Potential Enhancement:**
- Experts mentor beginners (optional add-on)
- Creates knowledge transfer

**Cost:** Medium for Group A, zero for Group B

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Multiple methods

**FLAG for Admin:** 🚨 "BIMODAL DISTRIBUTION DETECTED - Median misleading. 50% at level 0, 50% at level 6. Split into separate training groups."

---

## Scenario 6: Wide Uniform Spread (Equal Distribution)

### Distribution
```
Level 0: ████ (4 users, 20%)
Level 1: ████ (4 users, 20%)
Level 2: ████ (4 users, 20%)
Level 4: ████ (4 users, 20%)
Level 6: ████ (4 users, 20%)

User Scores: [0,0,0,0,1,1,1,1,2,2,2,2,4,4,4,4,6,6,6,6]
```

### Statistics
- **Median:** 2 (middle value)
- **Mean:** 2.6
- **Mode:** All levels equal (no mode)
- **Variance:** 4.64 (HIGH - very dispersed)
- **Gap:** Median suggests gap to level 4

### Analysis

**Is Median Reliable?** ⚠️ QUESTIONABLE
- Median = 2, but users are EQUALLY spread across all levels
- No clear "typical" user
- **High variance indicates diverse needs**

**Training Need:**
- 60% need some training (12/20 users at levels 0,1,2)
- 20% already at target (4/20 at level 4)
- 20% exceed target (4/20 at level 6)

### Recommended Approach

**Training Method:** Blended/Flexible Multi-Track Approach

**Track 1: Beginners (4 users at level 0)**
- Full progressive training (levels 1,2,4)

**Track 2: Aware (4 users at level 1)**
- Skip level 1, train at levels 2,4

**Track 3: Understanding (4 users at level 2)**
- Skip levels 1-2, train only at level 4

**Track 4: Applying (4 users at level 4)**
- No training needed

**Track 5: Mastery (4 users at level 6)**
- No training needed, could be mentors

**Implementation Options:**

**Option A: Self-Paced E-Learning**
- Everyone accesses online modules
- Each person follows their track
- Mentors available for support
- Cost: Very low (~€100 per person)

**Option B: Mentoring Pairs**
- Pair 4 masters (level 6) with 4 beginners (level 0)
- Other 12 users: mixed approach
- Cost: Low (internal time)

**Option C: Multiple Parallel Training Groups**
- Run 3 different training programs simultaneously
- Group by current level
- Cost: High (3 separate programs)

**Recommended:** Option A (Self-paced) or Option B (Mentoring) - most flexible

**Cost:** Low to Medium

**Timeline:** Flexible (3-12 months depending on individual pace)

**Reference:** TRAINING_METHODS.md - Sections 5, 7, 9: Mentoring, Self-Study, Blended Approaches

**FLAG for Admin:** ⚠️ "HIGH VARIANCE DETECTED - Users spread across all levels (20% each). One-size-fits-all training not appropriate. Recommend differentiated approach."

---

## Scenario 7: Tight Cluster Around Median (Low Variance)

### Distribution
```
Level 0:
Level 1: ██ (2 users, 10%)
Level 2: ████████████████ (16 users, 80%)
Level 4: ██ (2 users, 10%)
Level 6:

User Scores: [1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4,4]
```

### Statistics
- **Median:** 2
- **Mean:** 2.2
- **Mode:** 2
- **Variance:** 0.56 (LOW - tight cluster)
- **Gap:** 2 levels (from median 2 to target 4)

### Analysis

**Is Median Reliable?** ✅ YES - HIGHLY RELIABLE
- Median = 2 accurately represents 80% of users
- Low variance confirms tight clustering
- 2 users at level 1 (close to median)
- 2 users at level 4 (close to target)
- **Median is very representative**

**Training Need:**
- 90% need training (18/20 users below target)
- 10% already at target (2/20 users)

### Recommended Approach

**Training Method:** Standard Group Training

**Implementation:**
- All 18 users below target attend training
- Focus on level 4 (application)
- Most are at level 2, so can skip level 1 refresher
- 2 users at level 4 don't need training (or attend as mentors)

**Simplified:**
- One training program: Level 2 → Level 4
- Assumption: Level 1 already achieved
- 18 participants

**Cost:** Low per participant (~€500-800)

**Timeline:** 2-4 months

**Reference:** TRAINING_METHODS.md - Section 1: Group Classroom Training

**FLAG for Admin:** ✅ "Tight cluster detected - median highly representative. 90% need training from level 2 to level 4. Group training appropriate."

---

## Scenario 8: One Extreme Outlier (Median Accurate for Majority)

### Distribution
```
Level 0: █ (1 user, 5%)
Level 1:
Level 2:
Level 4: ███████████████████ (19 users, 95%)
Level 6:

User Scores: [0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
```

### Statistics
- **Median:** 4
- **Mean:** 3.8
- **Mode:** 4
- **Variance:** 0.76 (low)
- **Gap:** Median shows no gap, but 1 user has gap

### Analysis

**Is Median Reliable?** ✅ YES for majority, but hides 1 outlier
- Median = 4 accurately represents 95%
- 1 outlier at level 0 gets completely ignored
- **Median correctly says "most don't need training"**
- But need to address the 1 outlier

**Training Need:**
- 95% don't need training (19/20 at target)
- 5% need training (1/20 at level 0)

### Recommended Approach

**Training Method:** Individual Approach for 1 Outlier

**For the 1 User at Level 0:**

**Option A: External Certification**
- Send to public SE training course
- Cost: €2000-3000

**Option B: Mentoring**
- Pair with one of the 19 experts
- 3-6 month structured mentoring
- Cost: Low (internal time)

**Option C: Self-Study**
- Online courses + expert Q&A support
- Cost: Very low (~€50)

**Option D: Reconsider Role Assignment**
- Is this user correctly assigned to this role?
- If misassigned, may not need this competency at level 4
- Consider role transfer or different development path

**Recommended:** Option B (Mentoring) or Option D (Reconsider role)

**Cost:** Low

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Section 5: Mentoring

**FLAG for Admin:** ⚠️ "95% at target, but 1 outlier at level 0. Individual approach recommended. Also consider: Is this user correctly assigned to this role?"

---

## Scenario 9: Skewed Distribution (Most Experts, Few Beginners)

### Distribution
```
Level 0: ███ (3 users, 15%)
Level 1: ██ (2 users, 10%)
Level 2:
Level 4: ███████████████ (15 users, 75%)
Level 6:

User Scores: [0,0,0,1,1,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
```

### Statistics
- **Median:** 4
- **Mean:** 3.2
- **Mode:** 4
- **Variance:** 2.56 (moderate)
- **Gap:** Median shows no gap, but 25% have gap

### Analysis

**Is Median Reliable?** ⚠️ PARTIALLY
- Median = 4 suggests no training needed
- But 25% (5 users) are below target
- **Median accurately represents majority (75%), but hides significant minority**

**Training Need:**
- 75% don't need training (15/20 at target)
- 25% need training (5/20 below target)

### Recommended Approach

**Training Method:** Small Group Training for the 5 Users

**Implementation:**
- Separate small training program for 5 users
- 3 users at level 0: Need levels 1,2,4
- 2 users at level 1: Need levels 2,4
- Cost: Medium (small group, but still group training)

**Alternative:**
- Individual approaches (mentoring, self-study)
- 15 experts can mentor 5 beginners (3:1 ratio)

**Recommendation Decision:**
- If 5 users are in same location/team → Small group training
- If 5 users are dispersed → Individual mentoring

**Cost:** Medium (~€800-1200 per person for small group, or €500 for mentoring)

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Sections 1, 5: Group Training or Mentoring

**FLAG for Admin:** ⚠️ "75% at target, 25% below target (5/20 users). Consider small group training or mentoring. Median hides this 25% minority."

---

## Scenario 10: Gradual Progression (Normal Distribution-like)

### Distribution
```
Level 0: ██ (2 users, 10%)
Level 1: ████ (4 users, 20%)
Level 2: ████████ (8 users, 40%)
Level 4: ████ (4 users, 20%)
Level 6: ██ (2 users, 10%)

User Scores: [0,0,1,1,1,1,2,2,2,2,2,2,2,2,4,4,4,4,6,6]
```

### Statistics
- **Median:** 2
- **Mean:** 2.4
- **Mode:** 2
- **Variance:** 2.24 (moderate)
- **Gap:** 2 levels (from median 2 to target 4)

### Analysis

**Is Median Reliable?** ✅ YES - Reasonably Reliable
- Median = 2, Mode = 2, both at same value
- 40% at level 2 (largest group at median)
- Normal-ish distribution around median
- Variance moderate but acceptable

**Training Need:**
- 70% need training (14/20 users below target)
- 20% at target (4/20 at level 4)
- 10% exceed target (2/20 at level 6)

### Recommended Approach

**Training Method:** Group Training with Differentiation

**Implementation:**

**Group A: Beginners (2 at level 0 + 4 at level 1 = 6 users)**
- Full progressive training (levels 1,2,4)
- Or skip level 1 for those at level 1

**Group B: Intermediate (8 users at level 2)**
- Training from level 2 → level 4
- Skip levels 1 (already achieved)
- Largest group

**Group C: Advanced (4 at level 4 + 2 at level 6 = 6 users)**
- No training needed
- Could be mentors or facilitators

**Simplified Approach:**
- One training program (level 2 → 4) for all 14 users below target
- Acknowledge some are slightly ahead/behind
- Group activity allows peer learning

**Cost:** Low to Medium (~€600-900 per person)

**Timeline:** 3-6 months

**Reference:** TRAINING_METHODS.md - Section 1: Group Classroom Training

**FLAG for Admin:** ✅ "Normal-ish distribution, 70% need training. Median reliable. Group training with some differentiation appropriate."

---

## Summary Table: When Median Works vs Doesn't Work

| Scenario | Distribution Pattern | Median | Variance | Median Reliable? | Recommended Approach |
|----------|---------------------|--------|----------|------------------|---------------------|
| 1 | All at 0 (uniform) | 0 | 0.00 | ✅ YES | Group training |
| 2 | All at 4 (uniform) | 4 | 0.00 | ✅ YES | No training |
| 3 | 90% at 0, 10% at 4 | 0 | 1.44 | ✅ YES | Group training (experts as mentors) |
| 4 | 10% at 0, 90% at 4 | 4 | 1.44 | ⚠️ PARTIAL | Individual approach for minority |
| 5 | 50% at 0, 50% at 6 (bimodal) | 3 | 9.00 | ❌ NO | Split into two groups |
| 6 | Equal at all levels (uniform spread) | 2 | 4.64 | ⚠️ QUESTION | Blended/flexible approach |
| 7 | 80% at 2, 10% at 1, 10% at 4 (tight cluster) | 2 | 0.56 | ✅ YES | Group training |
| 8 | 95% at 4, 5% at 0 (one outlier) | 4 | 0.76 | ✅ YES* | No training (+ individual for outlier) |
| 9 | 75% at 4, 25% below (skewed) | 4 | 2.56 | ⚠️ PARTIAL | Small group or individual for minority |
| 10 | Normal distribution around 2 | 2 | 2.24 | ✅ YES | Group training with differentiation |

*Median accurate for majority but hides outlier - needs flagging

---

## Decision Rules for Implementation

Based on scenario analysis, here are recommended algorithmic rules:

### Rule 1: Check Variance First

```python
IF variance < 1.0:
    # Low variance = tight cluster
    → Trust median completely
    → Use median for decision
    → Standard group training if gap exists

ELSE IF variance > 4.0:
    # High variance = dispersed distribution
    → Median may be misleading
    → FLAG for admin: "High variance detected"
    → Recommend analysis of distribution
    → Consider differentiated approach
```

### Rule 2: Check Distribution Pattern

```python
# Calculate percentage at each level
percentages = count_per_level / total_users

# Check for bimodal (two peaks)
IF two_peaks_detected(percentages):
    → FLAG: "Bimodal distribution - median misleading"
    → Recommend: Split into separate groups

# Check for extreme outliers
IF (percentage_at_target > 0.8) AND (percentage_below_target < 0.2):
    → FLAG: "Majority at target, small minority needs training"
    → Recommend: Individual approach for minority

IF (percentage_below_target > 0.8):
    → FLAG: "Majority needs training"
    → Recommend: Group training (experts as mentors if any)
```

### Rule 3: Calculate "Gap Percentage"

```python
gap_percentage = count(users below target) / total_users

IF gap_percentage > 0.7:
    → "Group training highly appropriate"
    → Use median for gap calculation

ELSE IF 0.3 < gap_percentage <= 0.7:
    → "Mixed needs - consider blended approach"
    → Use median but flag distribution

ELSE IF 0 < gap_percentage <= 0.3:
    → "Minority needs training - individual approach recommended"
    → Median may show no gap, but flag minority

ELSE: # gap_percentage == 0
    → "No training needed"
```

### Rule 4: Simplified Implementation (Recommended for Phase 2)

**Primary Decision:** Use median
**Secondary Check:** Calculate gap_percentage

```python
median = calculate_median(user_scores)
gap = target - median

IF gap > 0:
    # Gap exists based on median
    gap_percentage = count(users with score < target) / total_users

    IF gap_percentage > 0.6:
        recommendation = "Group training appropriate"
        flag = None

    ELSE IF 0.2 < gap_percentage <= 0.6:
        recommendation = "Group training or blended approach"
        flag = f"{gap_percentage:.0%} of role needs training - consider cost-effectiveness"

    ELSE: # gap_percentage <= 0.2
        recommendation = "Individual approach recommended"
        flag = f"Only {gap_percentage:.0%} of role needs training - group training not cost-effective"

ELSE: # gap <= 0
    # No gap based on median
    gap_percentage = count(users with score < target) / total_users

    IF gap_percentage > 0.2:
        recommendation = "No training based on median, BUT..."
        flag = f"{gap_percentage:.0%} still below target - review distribution"

    ELSE:
        recommendation = "No training needed"
        flag = None
```

---

## Recommendations for Phase 2 Implementation

### What to Implement Now:

1. **Median calculation** (already implemented) ✅
2. **Gap calculation** based on median ✅
3. **Distribution statistics:**
   - Count users below target
   - Calculate gap_percentage
   - Simple variance calculation (optional)

4. **Flagging logic:**
   - IF gap_percentage < 0.3 → Flag "minority needs training"
   - IF gap_percentage > 0.7 → Flag "majority needs training"
   - IF variance > 4.0 → Flag "high variance"

5. **UI display:**
   - Show median value
   - Show gap
   - Show flag if present
   - Example: "Systems Thinking: Training needed (median=2, target=4). [FLAG: Only 25% of role needs training - consider individual approach]"

### What to Defer to Phase 3:

- Bimodal detection
- Detailed distribution graphs
- Automatic training method recommendation
- Multi-track training planning
- Role re-assignment suggestions

---

## Conclusion

**Key Takeaway:** Median is a good starting point for decision-making, but needs distribution context for validation.

**Recommended Approach for SE-QPT:**
- **Decision:** Based on median (gap exists or not)
- **Validation:** Check gap_percentage and variance
- **Flagging:** Alert admin when median might be misleading
- **Transparency:** Show distribution statistics to admin

**This provides:**
- Simple, fast decisions (median-based)
- Awareness of edge cases (flagging)
- Admin empowerment (show context, let them decide)
- Phase 3 foundation (distribution data already calculated)

---

**Next Steps:**
1. Review scenarios
2. Confirm decision rules
3. Implement flagging logic in Phase 2
4. Test with real organizational data
5. Refine thresholds based on testing

---

*Date: 2025-11-24*
*References: TRAINING_METHODS.md, REMAINING_QUESTIONS_BEFORE_DESIGN_V5.md*
