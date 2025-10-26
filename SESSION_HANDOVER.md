well.

---

## Session: 2025-10-26 - Phase 2 Task 3 Design Planning

**Timestamp**: 2025-10-26 (Date format from system)
**Focus**: Design planning for Phase 2 Task 3 - Generate Learning Objectives
**Status**: Design complete, awaiting advisor approval before implementation

### What Was Accomplished

#### 1. Complete Design Documentation Created
- **File**: `data/source/Phase 2/PHASE2_TASK3_LEARNING_OBJECTIVES_DESIGN.md` (1000+ lines)
- **File**: `data/source/Phase 2/PHASE2_TASK3_DECISION_FLOWCHART.md` (flowchart + examples)

These documents contain ALL session discussion, decisions, and design details.

#### 2. Key Design Discoveries

**Critical Insight from Marcel's Thesis**:
- Found `data/source/Phase 2/Learning objectives- note from Marcel's thesis.txt`
- **4 Core Competencies CANNOT be directly trained** (Systems Thinking, Modelling, Lifecycle, Customer Value)
  - They develop indirectly through training other competencies
  - Only generate objectives for 12 trainable competencies
- **Internal training only up to Level 4** (Level 6 is external for "Train the trainer")
- **Three-way comparison required**: Current Level vs Archetype Target vs Role Target

**Four Comparison Scenarios Identified**:
1. **Scenario A** (C < A ≤ R): Training required → Generate learning objective
2. **Scenario B** (A ≤ C < R): Archetype achieved → Recommend higher strategy
3. **Scenario C** (A > R): Archetype exceeds role → May not be necessary
4. **Scenario D** (C ≥ A AND C ≥ R): All targets achieved → No training needed

Where:
- C = Current competency level (median across org users)
- A = Archetype/Strategy target level
- R = Role maximum target (highest across org roles)

#### 3. Data Sources Verified

1. **Archetype Target Levels**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`
2. **Learning Objective Templates**: Same file
3. **Role Target Levels**: Database table `role_competency_matrix` (verified structure)
4. **Current Levels**: From Phase 2 Task 2 competency assessments (aggregated)
5. **PMT Context**: Admin text input (processes, methods, tools)

#### 4. Design Decisions Made (All Configurable)

| Decision | Choice | Config Flag |
|----------|--------|-------------|
| Core competencies | Show with note | `show_core_competencies_with_note` |
| Aggregation method | Median | `aggregation.method` |
| Role targets | Highest (accommodate all) | `role_target_strategy.method` |
| Multiple strategies | Separate sets | `multiple_strategies.handling` |
| Customization | Light (deep for 2 specific) | `customization.strategies_requiring_deep` |
| Level 6 objectives | Include with flag | `include_level_6_objectives` |
| Archetype warnings | Disabled (future) | `enable_archetype_suitability_warnings` |
| Individual objectives | Disabled (org-level only) | `generate_individual_user_objectives` |

All decisions can be changed based on advisor feedback without code changes.

#### 5. LLM Customization Strategy

- **Light customization** for most strategies (replace tool names only)
- **Deep customization** for "Continuous support" and "Needs-based project-oriented training"
  - Replace generic processes/methods/tools with company-specific PMT context
  - Maintain SMART criteria structure

#### 6. Reference Materials Added

- `data/source/strategy_definitions.json` - 7 training strategies with descriptions
- `data/source/Phase 2/Figure 4-5 spider-web chart.png` - Visual three-way comparison
- `data/source/templates/learning_objectives_guidelines.json` - SMART criteria

### Files Modified/Created

**Created**:
- `data/source/Phase 2/PHASE2_TASK3_LEARNING_OBJECTIVES_DESIGN.md` ⭐ **READ THIS FIRST**
- `data/source/Phase 2/PHASE2_TASK3_DECISION_FLOWCHART.md` ⭐ **FOR ADVISOR PRESENTATION**
- `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`
- `data/source/Phase 2/Learning objectives- note from Marcel's thesis.txt`
- `data/source/Phase 2/Figure 4-5 spider-web chart.png`
- `data/source/strategy_definitions.json`
- `DATA_DIRECTORY_ANALYSIS.md`
- `DATA_REORGANIZATION_SUMMARY.md`
- `DEPLOYMENT_CHECKLIST.md`
- `data/archive/README.md`

**Committed**: All above files committed to git (commit e89a1405)

### Key Technical Details

**Generation Logic Summary**:
```
FOR each selected strategy:
  FOR each of 16 competencies:
    IF core competency:
      ADD note "develops indirectly"
    ELSE:
      current = median(user_levels)
      archetype_target = strategy_target
      role_target = max(org_role_targets)

      IF current < archetype_target ≤ role_target:
        Generate customized learning objective
      ELIF archetype_target ≤ current < role_target:
        Recommend higher archetype
      ELIF archetype_target > role_target:
        Note "may not be necessary"
      ELSE:
        Note "targets achieved"
```

**API Endpoint** (designed but not implemented):
- `POST /api/learning-objectives/generate`
- `GET /api/learning-objectives/<org_id>`
- `GET /api/learning-objectives/<org_id>/export?format=pdf`

### Open Questions for Advisor (10 Total)

See section "Open Questions for Advisor" in design document for details:
1. Three-way comparison edge cases (role_target = 0, archetype > role)
2. Aggregation boundary conditions (min completion rate, spread thresholds)
3. LLM customization depth balance
4. Multiple strategies - training sequence recommendation
5. PMT context - required vs optional, minimum input
6. Validation of generated objectives (review/approval process)
7. Training priority calculation formula validation
8. Level 3/5 handling (don't exist in model, confirmed)
9. Continuous Support strategy prerequisites
10. Individual user objectives - in scope for thesis?

### Next Steps

**IMPORTANT**: **DO NOT START IMPLEMENTATION** until advisor approves design!

**After Advisor Meeting**:
1. Review design documents with advisor
2. Get feedback on 10 open questions
3. Update design based on advisor input
4. Get formal approval
5. THEN begin implementation:
   - Backend API endpoints
   - LLM customization logic (RAG)
   - Database queries/aggregation
   - UI components
   - Testing

### System Status

**Servers Running**:
- Backend: `cd src/backend && python run.py` (Flask)
- Frontend: `cd src/frontend && npm run dev` (Vue 3)

**Database**: PostgreSQL `seqpt_database` on port 5432
**Credentials**: `seqpt_admin:SeQpt_2025@localhost:5432/seqpt_database`

### Important Notes

1. **Terminology**: "Strategy" and "Archetype" are the same - we use "Strategy" in our app
2. **Competency Levels**: Only 1, 2, 4, 6 exist (NO level 3 or 5)
3. **12 Trainable Competencies**: Exclude 4 core competencies from direct training
4. **Reference Implementation**: Still use Derik's original work at `sesurveyapp-main/` for comparison
5. **No Emojis**: Windows console encoding issue - use [OK], [ERROR], etc.

### How to Use Design Documents

**For Quick Understanding**:
- Read: `PHASE2_TASK3_DECISION_FLOWCHART.md`
- Look at: Mermaid flowchart (render in VS Code, GitHub, or mermaid.live)
- Example walk-through: Decision Management competency

**For Complete Details**:
- Read: `PHASE2_TASK3_LEARNING_OBJECTIVES_DESIGN.md`
- All discussion preserved
- All decisions documented with rationale
- API design, UI flow, configuration structure
- Advisor approval section at end

**For Advisor Presentation**:
- Use flowchart as visual aid
- Walk through example (shows real data flowing)
- Reference design doc for detailed questions
- Present 10 open questions for discussion

### Questions/Issues

None - design is complete and well-documented. All decisions are configurable for easy changes based on advisor feedback.

---

**Session Summary**: Completed comprehensive design for Phase 2 Task 3 Learning Objectives generation. All design decisions documented with rationale, all edge cases considered, all data sources verified. Ready for advisor review and approval before implementation begins.

**Next Session Should Start With**: Review advisor feedback and update design accordingly, OR if approved, begin implementation planning and database schema updates.
