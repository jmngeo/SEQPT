# Learning Objectives Design v5 - Part 3 FINAL

**Continuation of:** LEARNING_OBJECTIVES_DESIGN_V5_COMPREHENSIVE_PART2.md

---

## Edge Cases & Error Handling

### Edge Case 1: No Assessment Data

**Scenario:** Organization has no completed competency assessments

**Detection:**
```python
if len(all_user_scores) == 0:
    # No assessment data
```

**Handling:**
- **Backend:** Return error 400 "No competency assessment data found"
- **Frontend:** Show message "Please complete competency assessments (Phase 2 Task 1) before generating learning objectives"
- **Alternative:** Generate based on assumed gaps (all users at level 0) - NOT RECOMMENDED

**Decision:** BLOCK generation - assessment data is required

---

### Edge Case 2: High Maturity but No Roles Defined

**Scenario:** Maturity ≥ 3, but role-competency matrix is empty

**Detection:**
```python
if maturity_level >= 3 and len(get_organization_roles(org_id)) == 0:
    # Inconsistency
```

**Handling:**
- **Backend:** WARN but proceed as low maturity (organizational view)
- **Log:** "Inconsistency: High maturity without roles - proceeding as low maturity"
- **Frontend:** Show info banner "Note: Processing as low maturity (no roles defined)"

**Decision:** WARN and adapt - not a blocker

---

### Edge Case 3: Only TTT Strategy Selected

**Scenario:** User selects ONLY "Train the Trainer", no other strategies

**Detection:**
```python
if len(other_strategies) == 0 and ttt_strategy is not None:
    # Only TTT selected
```

**Handling:**
- **Backend:** `main_targets` all set to 0, only TTT section generated
- **Frontend:** Show main pyramid as all grayed (no regular training)
- **TTT Section:** Show Level 6 objectives
- **Message:** "Regular training not selected - only mastery development (TTT) will be provided"

**Decision:** ALLOW - valid edge case

---

### Edge Case 4: Role Requires Level 6, TTT Not Selected

**Scenario:** Role-competency matrix has Level 6 requirements, but TTT strategy not selected

**Detection:** Handled by `validate_mastery_requirements()`

**Handling:**
- **Backend:** Return INADEQUATE status with HIGH severity
- **Frontend:** Show prominent warning with affected roles
- **Action Options:**
  - Add TTT strategy
  - Accept risk
  - Plan external trainers

**Decision:** WARN (not block) - admin makes final decision

---

### Edge Case 5: All Users at Target or Above

**Scenario:** All users already at or above strategy target levels

**Detection:**
```python
if not any(score < target for score in user_scores):
    # No gap exists
```

**Handling:**
- **Backend:** `has_gap = False`, no levels needed
- **Frontend:** Show all competencies grayed with "Target achieved"
- **Message:** "Congratulations! Your organization has achieved all target competency levels"

**Decision:** Show success state - valid outcome

---

### Edge Case 6: PMT Required but Not Provided

**Scenario:** Strategy requires PMT (e.g., "Continuous Support"), but no PMT context provided

**Detection:**
```python
if strategy_requires_pmt(strategy) and pmt_context is None:
    # PMT missing
```

**Handling:**
- **Option A:** BLOCK - require PMT collection first
- **Option B:** WARN - use standard templates anyway
- **Recommendation:** Option B (WARN)

**Implementation:**
- **Backend:** Use standard templates, set `customized = False`
- **Frontend:** Show info banner "PMT not provided - using standard templates"
- **Log:** Warning for audit trail

**Decision:** WARN and proceed with standard templates

---

### Edge Case 7: LLM Customization Fails

**Scenario:** OpenAI API call fails or returns invalid response

**Detection:**
```python
try:
    customized = call_openai_gpt4(prompt)
except Exception as e:
    # LLM failure
```

**Handling:**
- **Fallback:** Use standard template objective
- **Log:** Error with details
- **Set:** `customized = False` for that objective
- **Continue:** Don't fail entire generation

**Decision:** Graceful degradation - use templates

---

### Edge Case 8: Invalid Competency Levels in Database

**Scenario:** User assessment has level 3 or 5 (should be cleaned, but edge case)

**Detection:**
```python
if score not in [0, 1, 2, 4, 6]:
    # Invalid level
```

**Handling:**
- **Round down:** 3 → 2, 5 → 4
- **Log:** Warning
- **Continue:** Process with rounded value

**Decision:** Auto-correct with logging

---

### Edge Case 9: Zero Total Users

**Scenario:** Calculation results in division by zero

**Detection:**
```python
if len(user_scores) == 0:
    gap_percentage = 0  # or 1.0 depending on assumption
```

**Handling:**
- **Avoid division:** Check before calculating percentage
- **Default:** `gap_percentage = 0` or `gap_percentage = None`
- **Skip:** Distribution statistics if no data

**Decision:** Handle with null checks

---

### Edge Case 10: Extremely Large Organization

**Scenario:** 1000+ users, slow generation

**Detection:**
- Monitor response time
- If > 5 seconds → concern

**Handling:**
- **Optimization:** Cache median calculations
- **Pagination:** Not applicable (need complete data)
- **Async:** Generate in background, return job ID (future enhancement)

**Decision:** Optimize queries, acceptable for Phase 2 with <500 users

---

## Critical Analysis & Risk Assessment

### Risk 1: Performance with Large Datasets

**Scenario:** 500 users × 16 competencies × 4 levels = 32,000 calculations

**Analysis:**
- Median calculation: O(n log n) per competency per role
- Worst case: 20 roles × 16 competencies × median = ~320 calculations
- Each median: ~100 users → 100 log 100 ≈ 665 operations
- Total: ~213,000 operations (manageable)

**Mitigation:**
- ✅ Use efficient sorting algorithms
- ✅ Cache results where possible
- ✅ Database indexing on user_id, competency_id
- ⚠️ Consider async processing for orgs > 500 users

**Risk Level:** LOW (acceptable for Phase 2)

---

### Risk 2: LLM API Latency

**Scenario:** PMT customization requires 16 LLM calls (one per competency)

**Analysis:**
- OpenAI GPT-4: ~2-5 seconds per call
- 16 competencies × 3-4 levels ≈ 48-64 calls
- Sequential: 96-320 seconds (UNACCEPTABLE)
- Parallel (10 concurrent): 20-64 seconds (BETTER)

**Mitigation:**
- ✅ Parallel API calls (asyncio)
- ✅ Timeout per call (10 seconds)
- ✅ Fallback to template on timeout
- ✅ Cache customized objectives (reuse for same PMT)
- ⚠️ Consider pre-generation (background job)

**Risk Level:** MEDIUM (needs optimization)

---

### Risk 3: Incorrect Role-Competency Matrix

**Scenario:** Admin sets wrong requirements (e.g., all roles need Level 6)

**Analysis:**
- System will recommend mastery training for all
- Could be incorrect or too ambitious
- GIGO (Garbage In, Garbage Out)

**Mitigation:**
- ✅ Validation warnings if unusual patterns detected
- ✅ Mastery requirements check catches extreme cases
- ✅ Distribution statistics help admin verify
- ⚠️ No automatic correction (trust admin input)

**Risk Level:** MEDIUM (user error, not system error)

---

### Risk 4: Strategy Archetype Data Inconsistency

**Scenario:** Strategy archetype templates have wrong target levels

**Analysis:**
- If "Continuous Support" says target=1 (should be 4) → wrong LOs generated
- Critical dependency on data quality

**Mitigation:**
- ✅ Validate archetype data on load
- ✅ Check: targets in valid range [0-6]
- ✅ Check: targets only use valid levels [0,1,2,4,6]
- ✅ Admin review in Phase 1 Task 3
- ⚠️ No runtime validation (assume correct)

**Risk Level:** LOW (data validated at setup)

---

### Risk 5: Distribution Statistics Misinterpretation

**Scenario:** Admin sees "Individual coaching" recommendation but does group training anyway

**Analysis:**
- Training recommendations are SUGGESTIONS, not requirements
- Admin may have valid reasons to override (e.g., company culture, budget)
- Phase 3 will allow different decision

**Mitigation:**
- ✅ Clear labeling as "Recommendation"
- ✅ Show rationale for transparency
- ✅ Allow admin override in Phase 3
- ✅ Not a bug - by design

**Risk Level:** NONE (expected behavior)

---

### Risk 6: Median Hides Outliers

**Scenario:** 19 experts + 1 beginner → median=expert → no training

**Analysis:**
- "ANY gap" rule prevents this (LO generated for that 1 person)
- But admin sees "median=expert" and might be confused
- Distribution stats provide context

**Mitigation:**
- ✅ "ANY gap" rule ensures LO exists
- ✅ Distribution stats show "Only 5% need training"
- ✅ Clear messaging: "1/20 users need training"
- ✅ Training recommendation: "Individual coaching"

**Risk Level:** LOW (mitigated by design)

---

### Risk 7: Two Views Confusion

**Scenario:** User confused between Organizational and Role-Based views

**Analysis:**
- Two different perspectives of same data
- Organizational: "What does organization need?"
- Role-Based: "What does this specific role need?"
- Potential for confusion

**Mitigation:**
- ✅ Clear labeling and toggle
- ✅ Informational tooltips
- ✅ Different layouts/styling
- ✅ Help documentation
- ⚠️ User training may be needed

**Risk Level:** LOW (UX issue, manageable)

---

### Risk 8: TTT Separation Clarity

**Scenario:** Admin doesn't understand why Level 6 is separate section

**Analysis:**
- "Train the Trainer" has different purpose (develop trainers vs train employees)
- Separation is intentional
- Might not be obvious to new users

**Mitigation:**
- ✅ Clear section title: "Mastery Development (Train the Trainer)"
- ✅ Explanatory text in section header
- ✅ Different styling (gold/amber)
- ✅ Help documentation

**Risk Level:** LOW (UX clarity, documentation fixes)

---

## Testing Strategy - Comprehensive

### Unit Tests (Backend)

**Test Suite 1: Target Calculation**
```python
def test_calculate_combined_targets_single_strategy():
    """Test target calculation with one strategy."""
    strategies = [{'strategy_id': 1, 'strategy_name': 'Continuous Support'}]
    result = calculate_combined_targets(strategies)

    assert result['main_targets'][1] == 4  # Systems Thinking
    assert result['ttt_selected'] == False
    assert result['ttt_targets'] is None

def test_calculate_combined_targets_multiple_strategies():
    """Test HIGHER target selection."""
    strategies = [
        {'strategy_id': 1, 'strategy_name': 'SE for Managers'},  # Target=2
        {'strategy_id': 2, 'strategy_name': 'Orientation'}       # Target=4
    ]
    result = calculate_combined_targets(strategies)

    assert result['main_targets'][1] == 4  # Take HIGHER

def test_calculate_combined_targets_with_ttt():
    """Test TTT separation."""
    strategies = [
        {'strategy_id': 1, 'strategy_name': 'Continuous Support'},
        {'strategy_id': 5, 'strategy_name': 'Train the Trainer'}
    ]
    result = calculate_combined_targets(strategies)

    assert result['main_targets'][1] == 4  # From Continuous Support
    assert result['ttt_selected'] == True
    assert result['ttt_targets'][1] == 6  # All TTT targets are 6

def test_calculate_combined_targets_only_ttt():
    """Test edge case: only TTT selected."""
    strategies = [{'strategy_id': 5, 'strategy_name': 'Train the Trainer'}]
    result = calculate_combined_targets(strategies)

    assert result['main_targets'][1] == 0  # No regular training
    assert result['ttt_selected'] == True
```

**Test Suite 2: Gap Detection**
```python
def test_detect_gaps_any_user_triggers():
    """Test 'ANY gap' principle: even 1 user triggers LO generation."""
    # Mock: 19 users at level 4, 1 user at level 0
    # Target: level 4
    # Expected: gap exists, generate LOs for levels 1,2,4

    result = process_competency_organizational(
        org_id=28,
        competency=SystemsThinking,
        target_level=4
    )

    assert result['has_gap'] == True
    assert 1 in result['levels_needed']
    assert 2 in result['levels_needed']
    assert 4 in result['levels_needed']

def test_detect_gaps_no_gap_when_all_at_target():
    """Test no gap when all users at target."""
    # Mock: All 20 users at level 4
    # Target: level 4
    # Expected: no gap

    result = process_competency_organizational(
        org_id=28,
        competency=SystemsThinking,
        target_level=4
    )

    assert result['has_gap'] == False
    assert len(result['levels_needed']) == 0

def test_detect_gaps_progressive_levels():
    """Test progressive level generation."""
    # Mock: Users at level 0
    # Target: level 6
    # Expected: levels 1, 2, 4, 6

    result = process_competency_organizational(
        org_id=28,
        competency=SystemsThinking,
        target_level=6
    )

    assert result['levels_needed'] == [1, 2, 4, 6]

def test_detect_gaps_with_roles():
    """Test role-based processing."""
    # Mock: 2 roles, one has gap, one doesn't

    result = process_competency_with_roles(
        org_id=28,
        competency=SystemsThinking,
        target_level=4
    )

    assert result['has_gap'] == True  # At least one role has gap
    assert len(result['roles']) >= 1  # Roles with gaps included
```

**Test Suite 3: Mastery Validation**
```python
def test_mastery_validation_ok():
    """Test validation passes when requirements met."""
    # Mock: Role requires level 4, strategy provides level 4

    result = validate_mastery_requirements(
        org_id=28,
        selected_strategies=[...],
        main_targets={1: 4, 2: 4, ...}
    )

    assert result['status'] == 'OK'

def test_mastery_validation_inadequate():
    """Test validation flags when role requires > strategy."""
    # Mock: Role requires level 6, strategy provides level 4, no TTT

    result = validate_mastery_requirements(
        org_id=28,
        selected_strategies=[...],  # No TTT
        main_targets={1: 4, ...}  # Max = 4
    )

    assert result['status'] == 'INADEQUATE'
    assert result['severity'] == 'HIGH'
    assert len(result['affected']) > 0
```

**Test Coverage Target:** 80%+ for core algorithms

---

### Integration Tests (Backend + Database)

**Test Scenario 1: Complete Flow - High Maturity**
```python
def test_complete_flow_high_maturity():
    """Test end-to-end generation for high maturity org."""
    # Setup: Org 28 with roles, assessments, strategies

    response = generate_learning_objectives_api(
        org_id=28,
        selected_strategies=[
            {'strategy_id': 1, 'strategy_name': 'Continuous Support'}
        ],
        pmt_context={'processes': 'ISO 26262', 'methods': 'Scrum', 'tools': 'DOORS'}
    )

    assert response['success'] == True
    assert 'main_pyramid' in response['data']
    assert len(response['data']['main_pyramid']['levels']) == 4
    assert response['data']['main_pyramid']['metadata']['has_roles'] == True

    # Check Level 2
    level_2 = response['data']['main_pyramid']['levels']['2']
    assert len(level_2['competencies']) == 16  # All 16 shown

    # Check at least one has training
    training_required = [c for c in level_2['competencies'] if c['status'] == 'training_required']
    assert len(training_required) > 0

def test_complete_flow_low_maturity():
    """Test end-to-end generation for low maturity org."""
    response = generate_learning_objectives_api(
        org_id=30,  # Low maturity
        selected_strategies=[
            {'strategy_id': 3, 'strategy_name': 'SE for Managers'},
            {'strategy_id': 4, 'strategy_name': 'Common Basic Understanding'}
        ],
        pmt_context=None
    )

    assert response['success'] == True
    assert response['data']['main_pyramid']['metadata']['has_roles'] == False
    assert response['data']['main_pyramid']['metadata']['pmt_customization'] == False
```

**Test Scenario 2: TTT Processing**
```python
def test_ttt_separation():
    """Test Train the Trainer is processed separately."""
    response = generate_learning_objectives_api(
        org_id=28,
        selected_strategies=[
            {'strategy_id': 1, 'strategy_name': 'Continuous Support'},
            {'strategy_id': 5, 'strategy_name': 'Train the Trainer'}
        ]
    )

    # Main pyramid should have targets from Continuous Support only
    level_6 = response['data']['main_pyramid']['levels']['6']
    grayed_count = sum(1 for c in level_6['competencies'] if c['grayed_out'])
    assert grayed_count > 0  # Some grayed (not all need level 6 from main)

    # TTT section should exist
    assert response['data']['train_the_trainer'] is not None
    assert response['data']['train_the_trainer']['enabled'] == True
```

---

### Frontend Tests (Component Unit Tests)

**Test Suite 1: Component Rendering**
```javascript
describe('CompetencyCard', () => {
  it('renders active card with LO', () => {
    const competency = {
      status: 'training_required',
      competency_name: 'Systems Thinking',
      learning_objective: {
        objective_text: 'Participants understand...'
      },
      grayed_out: false
    };

    const wrapper = mount(CompetencyCard, {
      props: { competency, hasRoles: true, grayedOut: false }
    });

    expect(wrapper.find('.learning-objective').exists()).toBe(true);
    expect(wrapper.text()).toContain('Systems Thinking');
    expect(wrapper.find('.grayed-out-card').exists()).toBe(false);
  });

  it('renders grayed card without LO', () => {
    const competency = {
      status: 'achieved',
      competency_name: 'Communication',
      message: 'Already at Level 2+',
      grayed_out: true
    };

    const wrapper = mount(CompetencyCard, {
      props: { competency, hasRoles: true, grayedOut: true }
    });

    expect(wrapper.find('.grayed-out-card').exists()).toBe(true);
    expect(wrapper.find('.learning-objective').exists()).toBe(false);
  });
});
```

**Test Suite 2: View Switching**
```javascript
describe('ViewSelector', () => {
  it('disables role-based view when no roles', () => {
    const wrapper = mount(ViewSelector, {
      props: { currentView: 'organizational', hasRoles: false }
    });

    const roleBtn = wrapper.findAll('button')[1];
    expect(roleBtn.attributes('disabled')).toBeDefined();
  });

  it('enables role-based view when roles exist', () => {
    const wrapper = mount(ViewSelector, {
      props: { currentView: 'organizational', hasRoles: true }
    });

    const roleBtn = wrapper.findAll('button')[1];
    expect(roleBtn.attributes('disabled')).toBeUndefined();
  });
});
```

---

### E2E Tests (Full User Flows)

**Scenario 1: High Maturity Organizational View**
```javascript
test('Navigate pyramid levels and view competencies', async () => {
  // Login as org 28 admin
  await loginAs('org28_admin');

  // Navigate to Phase 2 Task 3
  await page.click('[data-test="phase2-task3"]');

  // Wait for pyramid to load
  await page.waitForSelector('.pyramid-level-tabs');

  // Check all 4 level tabs exist
  const tabs = await page.$$('.v-tab');
  expect(tabs.length).toBe(4);

  // Click Level 2 tab
  await page.click('[data-test="level-2-tab"]');

  // Check 16 competencies shown
  const competencies = await page.$$('.competency-card');
  expect(competencies.length).toBe(16);

  // Check at least one active competency
  const activeCards = await page.$$('.competency-card:not(.grayed-out-card)');
  expect(activeCards.length).toBeGreaterThan(0);

  // Click on active competency
  const firstActive = activeCards[0];
  await firstActive.click();

  // Check learning objective text exists
  const loText = await page.$('.learning-objective');
  expect(loText).toBeTruthy();
});
```

**Scenario 2: Switch to Role-Based View**
```javascript
test('Switch to role-based view and select role', async () => {
  await loginAs('org28_admin');
  await page.click('[data-test="phase2-task3"]');

  // Wait for pyramid
  await page.waitForSelector('.view-selector');

  // Click role-based view button
  await page.click('[data-test="role-based-view-btn"]');

  // Select role from dropdown
  await page.click('.role-selector');
  await page.click('[data-test="role-requirements-engineer"]');

  // Check pyramid updates
  await page.waitForSelector('.role-based-pyramid');

  // Check competencies filtered for role
  const competencies = await page.$$('.competency-card');
  expect(competencies.length).toBeGreaterThan(0);
});
```

---

## Implementation Plan - 6 Week Phased Approach

### Week 1: Backend Core (Algorithms 1-3)

**Days 1-2: Target Calculation & Validation**
- Implement `calculate_combined_targets()`
- Implement `validate_mastery_requirements()`
- Write unit tests
- Test with orgs 28, 29, 30

**Days 3-4: Gap Detection**
- Implement `detect_gaps()`
- Implement `process_competency_with_roles()`
- Implement `process_competency_organizational()`
- Write unit tests
- Test edge cases

**Day 5: TTT Processing**
- Implement `process_ttt_gaps()`
- Write unit tests
- Integration testing

**Deliverable:** Core gap detection working with test coverage

---

### Week 2: Backend LO Generation & Structuring

**Days 1-2: LO Generation**
- Implement `generate_learning_objectives()`
- Implement `customize_objective_with_pmt()`
- Template loading logic
- Write unit tests

**Days 3-4: Pyramid Structuring**
- Implement `structure_pyramid_output()`
- Implement `build_level_structure()`
- Implement `check_if_level_grayed()`
- Write unit tests

**Day 5: API Endpoint**
- Create `/api/phase2/task3/generate-learning-objectives` endpoint
- Request validation
- Error handling
- Integration testing

**Deliverable:** Complete backend API working end-to-end

---

### Week 3: Frontend Core (Main Components)

**Days 1-2: Page Structure**
- Create `LearningObjectivesPage.vue`
- Create `ViewSelector.vue`
- Create `ValidationSummary.vue`
- Create `MasteryRequirementsWarning.vue`
- Wire up API calls

**Days 3-4: Pyramid Components**
- Create `OrganizationalPyramid.vue`
- Create `LevelView.vue`
- Create `CompetencyCard.vue`
- Create `RoleCard.vue`
- Styling and layout

**Day 5: TTT Section**
- Create `MasteryDevelopmentSection.vue`
- Integration with main page
- Styling

**Deliverable:** Functional UI with organizational view

---

### Week 4: Frontend Role-Based View & Polish

**Days 1-2: Role-Based View**
- Create `RoleBasedPyramid.vue`
- Create `RoleLevelView.vue`
- Role selector component
- Data filtering logic

**Days 3-4: Interactive Features**
- Tab navigation
- View switching
- Expandable sections
- Tooltips and help text

**Day 5: Responsive Design**
- Mobile/tablet layouts
- Grid adjustments
- Testing on different screens

**Deliverable:** Complete UI with both views working

---

### Week 5: Testing & Refinement

**Days 1-2: Comprehensive Testing**
- Run all unit tests (backend + frontend)
- Run integration tests
- E2E test scenarios
- Fix bugs

**Days 3-4: Edge Case Testing**
- Test all 10 edge cases documented
- Test with unusual data
- Error handling validation
- Performance testing

**Day 5: UI/UX Refinement**
- User testing feedback
- Visual polish
- Loading states
- Error messages

**Deliverable:** Stable, tested system

---

### Week 6: Integration & Documentation

**Days 1-2: Phase 1 Integration**
- Integrate with strategy selection output
- Integrate with PMT collection
- End-to-end flow testing

**Days 3-4: Phase 2 Task 1-2 Integration**
- Ensure assessment data compatibility
- Ensure role data compatibility
- Full workflow testing

**Day 5: Documentation & Handoff**
- API documentation
- User guide
- Code comments
- Deployment guide

**Deliverable:** Production-ready Phase 2 Task 3

---

## Success Criteria

### Functional Requirements
- ✅ Generates LO if ANY user has gap (not median-based)
- ✅ Both pathways use pyramid structure
- ✅ Progressive objectives (all intermediate levels)
- ✅ Two views working (organizational + role-based)
- ✅ TTT separated and processed correctly
- ✅ Mastery requirements validation
- ✅ Distribution statistics calculated
- ✅ Training method recommendations shown
- ✅ PMT customization working
- ✅ All 16 competencies shown per level

### Performance Requirements
- ✅ API response < 3 seconds (typical org, 50 users)
- ✅ API response < 10 seconds (large org, 500 users)
- ✅ Frontend renders smoothly (no lag)
- ✅ Tab switching instant

### Quality Requirements
- ✅ 80%+ test coverage (backend)
- ✅ All edge cases handled
- ✅ Error messages clear and actionable
- ✅ No data loss on errors

### UX Requirements
- ✅ Intuitive navigation
- ✅ Clear visual hierarchy
- ✅ Active vs grayed distinction clear
- ✅ Help text available
- ✅ Responsive design

---

## Open Questions - NONE

All questions answered by Jomon during session 2025-11-24.

---

## Change Log

**v5.0 (2025-11-24) - FINAL**
- ✅ Both pathways use pyramid (not strategy-based for low maturity)
- ✅ "ANY gap" rule for LO generation
- ✅ Exclude TTT from main target calculation
- ✅ Mastery requirements validation added
- ✅ Simplified TTT section (no internal/external in Phase 2)
- ✅ Two views both in Phase 2
- ✅ Training modules vs methods clarified
- ✅ Comprehensive critical analysis added

**v4.0 (2025-11-14)** - Superseded
- Strategy-based organization for low maturity
- Per-competency best-fit strategy selection
- Median-based gap detection

---

**Document Status:** FINAL - APPROVED FOR IMPLEMENTATION
**Date:** 2025-11-24
**Next Action:** Begin Week 1 implementation

---

*End of Design v5 Comprehensive Documentation*
*Total Pages: 3 parts*
*Total Algorithms: 8 complete specifications*
*Total Components: 10+ Vue components*
*Ready for Implementation*
