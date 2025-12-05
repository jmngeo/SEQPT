# Phase 2 Task 3 - Complete Standardization & Architecture Plan
**Date**: November 6, 2025
**Status**: ARCHITECTURAL DESIGN DOCUMENT

---

## Executive Summary

This document defines the complete standardization strategy for Phase 2 Task 3 learning strategies, addressing:

1. **Template JSON Update** - Add Certification, standardize naming
2. **Global Strategy Architecture** - Make strategies organization-independent
3. **Automatic Org Setup** - Define procedures for new organizations
4. **Data Migration** - Convert existing orgs to new architecture

---

## 1. Standardized Strategy Names (CANONICAL)

### 1.1 The 7 Official Learning Strategies

| # | Canonical Name | Description | Competencies |
|---|---------------|-------------|--------------|
| 1 | Common basic understanding | Foundational SE knowledge for all team members | 15 (exclude ID 6) |
| 2 | SE for managers | Management-focused SE training | 15 (exclude ID 6) |
| 3 | Orientation in pilot project | Hands-on learning through pilot projects | 15 (exclude ID 6) |
| 4 | Needs-based, project-oriented training | Task-specific, on-demand training | 15 (exclude ID 6) |
| 5 | Continuous support | Ongoing mentoring and support | 15 (exclude ID 6) |
| 6 | Train the trainer | Prepare internal SE trainers | 15 (exclude ID 6) |
| 7 | **Certification** | Formal certification programs | **16 (ALL competencies)** |

**Note**: Strategy #7 "Certification" is added based on organization 28 golden reference.

### 1.2 Naming Conventions

**RULES**:
1. All lowercase except first letter
2. Use exact punctuation: "Needs-based, project-oriented training" (WITH comma)
3. NO variations: "Train the trainer" (NOT "Train the SE-Trainer")
4. Case-insensitive matching in code, but store canonical form in database

**CLARIFICATION**: "Train the trainer" and "Train the SE-Trainer" are THE SAME STRATEGY
- Canonical name: **"Train the trainer"**
- Variations to normalize: "Train the SE-Trainer", "Train the SE-trainer", "Train the Trainer"
- All should be converted to canonical form

---

## 2. Template JSON Update

### 2.1 Changes Required

**File**: `data/source/Phase 2/se_qpt_learning_objectives_template_latest.json`

**Updates**:
1. Add "Certification" to `qualificationArchetypes` array
2. Add "Certification" to `archetypeCompetencyTargetLevels` with all 16 competencies at level 4
3. Update metadata to reflect 7 total archetypes
4. Rename "Train the trainer" section to clarify (add note about variations)

### 2.2 Certification Strategy Values

All 16 competencies at target level 4:
```json
"Certification": {
  "Systems Thinking": 4,
  "Systems Modeling and Analysis": 4,  // ← UNIQUE to Certification
  "Lifecycle Consideration": 4,
  "Customer / Value Orientation": 4,
  "Requirements Definition": 4,
  "System Architecting": 4,
  "Integration, Verification, Validation": 4,
  "Operation and Support": 4,
  "Agile Methods": 4,
  "Self-Organization": 4,
  "Communication": 4,
  "Leadership": 4,
  "Project Management": 4,
  "Decision Management": 4,
  "Information Management": 4,
  "Configuration Management": 4
}
```

**Key Difference**: Certification includes "Systems Modeling and Analysis" (ID 6) which other strategies exclude.

---

## 3. Architectural Decision: Global vs Per-Org Strategies

### 3.1 Current Architecture (PROBLEMATIC)

```
learning_strategy (organization_id, strategy_name, selected, priority)
  ├─ Strategy ID varies per organization
  └─ strategy_competency (strategy_id, competency_id, target_level)
      └─ Duplicated for each org
```

**Problems**:
- Org 28 strategy ID 12 = "Needs-based Project-oriented Training"
- Org 29 strategy ID 29 = "Needs-based Project-oriented Training"
- Same strategy, different IDs = duplicate competency mappings (15 rows × 2 orgs = 30 rows)
- Multiply by 7 strategies × N orgs = massive duplication
- Inconsistency risk (one org has different targets)

### 3.2 RECOMMENDED: Global Strategy Template Architecture

```
strategy_template (id, strategy_name, description, requires_pmt_context)
  └─ Global, shared across all organizations

strategy_template_competency (strategy_template_id, competency_id, target_level)
  └─ Single source of truth for each strategy

learning_strategy (organization_id, strategy_template_id, selected, priority)
  └─ Per-org: just selection and priority
```

**Benefits**:
✅ Single source of truth
✅ No data duplication
✅ Consistent across all orgs
✅ Easy to update all orgs at once
✅ Smaller database
✅ Clear separation: template (what) vs instance (which orgs use it)

**Trade-off**:
❌ Organizations can't customize competency targets per strategy
✅ But this is DESIRED behavior - targets are research-based (Marcel Niemeyer)

### 3.3 Data Model Design

#### Table: `strategy_template`

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PRIMARY KEY | Template ID |
| strategy_name | VARCHAR(255) UNIQUE | Canonical strategy name |
| strategy_description | TEXT | Description |
| requires_pmt_context | BOOLEAN | TRUE for "Needs-based" and "Continuous support" |
| is_active | BOOLEAN | Allow deprecation without deletion |
| created_at | TIMESTAMP | Audit |
| updated_at | TIMESTAMP | Audit |

**Initial Data**: 7 rows (the 7 strategies)

#### Table: `strategy_template_competency`

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PRIMARY KEY | Mapping ID |
| strategy_template_id | INTEGER FK | Links to strategy_template |
| competency_id | INTEGER FK | Links to competency |
| target_level | INTEGER | Target level (1-6) |

**Unique Constraint**: (strategy_template_id, competency_id)

**Initial Data**: 106 rows
- 6 strategies × 15 competencies = 90 rows
- 1 strategy (Certification) × 16 competencies = 16 rows
- Total: 106 rows

#### Table: `learning_strategy` (REFACTORED)

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PRIMARY KEY | Instance ID |
| organization_id | INTEGER FK | Links to organization |
| strategy_template_id | INTEGER FK | **NEW**: Links to strategy_template |
| selected | BOOLEAN | Per-org selection |
| priority | INTEGER | Per-org priority |
| created_at | TIMESTAMP | Audit |
| updated_at | TIMESTAMP | Audit |

**Remove**: `strategy_name`, `strategy_description` (now in template)

**Unique Constraint**: (organization_id, strategy_template_id) - one instance per org per strategy

---

## 4. Migration Strategy

### 4.1 Migration Steps

1. **Create new tables** (`strategy_template`, `strategy_template_competency`)
2. **Populate templates** from org 28 golden reference
3. **Migrate existing orgs** to reference templates
4. **Verify data integrity**
5. **Drop old columns/tables** (optional, after verification)

### 4.2 Backward Compatibility

During migration period:
- Keep old `strategy_competency` table
- Add new `strategy_template_competency` table
- Application code checks both sources
- After all orgs migrated, drop old table

---

## 5. Automatic Organization Setup

### 5.1 Current Process (MANUAL)

When creating new organization:
1. Manually run SQL to create strategies
2. Manually run `load_archetype_targets.py` script
3. Hope names match template
4. Debug if they don't match

**Problems**:
- Error-prone
- Inconsistent naming
- Duplicates possible
- Time-consuming

### 5.2 NEW Process (AUTOMATIC)

When creating new organization via API:
```python
POST /api/organizations
{
  "name": "New Company",
  "maturity_level": 4,
  ...
}
```

**Backend automatically**:
1. Creates organization record
2. Calls `setup_phase2_task3_strategies(org_id)`
3. Inserts 7 learning_strategy records (references to templates)
4. Done - no manual steps

### 5.3 Setup Function

```python
def setup_phase2_task3_strategies(organization_id: int) -> dict:
    """
    Automatically setup Phase 2 Task 3 strategies for a new organization.
    Links organization to all 7 strategy templates.

    Returns:
        dict: Summary of strategies created
    """
    # Get all active strategy templates
    templates = db.query(StrategyTemplate).filter_by(is_active=True).all()

    created = []
    for i, template in enumerate(templates, 1):
        # Create learning_strategy instance for this org
        learning_strategy = LearningStrategy(
            organization_id=organization_id,
            strategy_template_id=template.id,
            selected=False,  # Default: not selected
            priority=i  # Sequential priority
        )
        db.add(learning_strategy)
        created.append(template.strategy_name)

    db.commit()

    return {
        "success": True,
        "strategies_created": len(created),
        "strategy_names": created
    }
```

**Called from**:
- Organization creation endpoint
- Admin "Initialize Strategies" button (for existing orgs)
- Database seed script (for test data)

---

## 6. Code Changes Required

### 6.1 Backend Changes

#### New Models (`models.py`)

```python
class StrategyTemplate(Base):
    __tablename__ = 'strategy_template'

    id = Column(Integer, primary_key=True)
    strategy_name = Column(String(255), unique=True, nullable=False)
    strategy_description = Column(Text)
    requires_pmt_context = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    competencies = relationship('StrategyTemplateCompetency', back_populates='strategy_template')
    learning_strategy_instances = relationship('LearningStrategy', back_populates='strategy_template')


class StrategyTemplateCompetency(Base):
    __tablename__ = 'strategy_template_competency'

    id = Column(Integer, primary_key=True)
    strategy_template_id = Column(Integer, ForeignKey('strategy_template.id'), nullable=False)
    competency_id = Column(Integer, ForeignKey('competency.id'), nullable=False)
    target_level = Column(Integer, nullable=False)

    __table_args__ = (
        UniqueConstraint('strategy_template_id', 'competency_id'),
    )

    # Relationships
    strategy_template = relationship('StrategyTemplate', back_populates='competencies')
    competency = relationship('Competency')


# Refactor LearningStrategy
class LearningStrategy(Base):
    __tablename__ = 'learning_strategy'

    id = Column(Integer, primary_key=True)
    organization_id = Column(Integer, ForeignKey('organization.id'), nullable=False)
    strategy_template_id = Column(Integer, ForeignKey('strategy_template.id'), nullable=False)  # NEW
    selected = Column(Boolean, default=False)
    priority = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('organization_id', 'strategy_template_id'),
    )

    # Relationships
    organization = relationship('Organization')
    strategy_template = relationship('StrategyTemplate', back_populates='learning_strategy_instances')
```

#### Service Changes (`pathway_determination.py`, etc.)

**Before**:
```python
# Get strategies by name matching
strategy = db.query(LearningStrategy).filter_by(
    organization_id=org_id,
    strategy_name='Common Basic Understanding'
).first()

# Get competency targets from strategy_competency
targets = db.query(StrategyCompetency).filter_by(
    strategy_id=strategy.id
).all()
```

**After**:
```python
# Get strategies by template name
strategy = db.query(LearningStrategy).join(StrategyTemplate).filter(
    LearningStrategy.organization_id == org_id,
    StrategyTemplate.strategy_name == 'Common basic understanding'
).first()

# Get competency targets from template
targets = db.query(StrategyTemplateCompetency).filter_by(
    strategy_template_id=strategy.strategy_template_id
).all()
```

### 6.2 Frontend Changes

Minimal - API responses include strategy name from template

```javascript
// Response structure unchanged
{
  "strategies": [
    {
      "id": 123,
      "strategy_name": "Common basic understanding",  // From template
      "selected": true,
      "priority": 1
    }
  ]
}
```

---

## 7. Implementation Plan

### Phase 1: Database Schema (Week 1)

1. ✅ Create `strategy_template` table
2. ✅ Create `strategy_template_competency` table
3. ✅ Add `strategy_template_id` to `learning_strategy`
4. ✅ Populate templates from org 28
5. ✅ Migrate existing orgs to use templates

### Phase 2: Backend Code (Week 2)

1. ✅ Add new models
2. ✅ Create `setup_phase2_task3_strategies()` function
3. ✅ Update pathway services to use templates
4. ✅ Update API endpoints
5. ✅ Add migration script

### Phase 3: Testing (Week 2)

1. ✅ Test new org creation
2. ✅ Test existing org migration
3. ✅ Test learning objectives generation
4. ✅ Verify data consistency

### Phase 4: Deployment (Week 3)

1. ✅ Run migration on production
2. ✅ Verify all orgs have 7 strategies
3. ✅ Monitor for issues
4. ✅ Update documentation

---

## 8. Benefits of New Architecture

### 8.1 Data Integrity

**Before**:
- 2 orgs × 7 strategies × 15 competencies = **210 strategy_competency rows**
- 10 orgs × 7 strategies × 15 competencies = **1,050 rows**
- 100 orgs = **10,500 rows** (massive duplication)

**After**:
- 7 strategies × 15-16 competencies = **106 strategy_template_competency rows** (ONE TIME)
- 100 orgs × 7 strategies = **700 learning_strategy rows** (just references)
- **Total: 806 rows vs 10,500 rows** = 92% reduction

### 8.2 Consistency

**Before**: Risk of inconsistency
- Org A has "Common Basic Understanding" with target level 2 for "Systems Thinking"
- Org B has "Common basic understanding" with target level 3 for "Systems Thinking"
- Which is correct?

**After**: Guaranteed consistency
- All orgs use same template
- One source of truth
- Update template = all orgs updated

### 8.3 Maintainability

**Before**: Update nightmare
- Marcel Niemeyer updates research with new target levels
- Must manually update every organization
- Risk of missing some orgs

**After**: Simple update
- Update strategy_template_competency
- All orgs instantly have new targets
- No risk of inconsistency

---

## 9. Rollback Plan

If migration fails:

1. Keep old tables (`strategy_competency`) intact
2. Revert code changes
3. Drop new tables (`strategy_template`, `strategy_template_competency`)
4. Resume using old architecture

**Risk**: LOW - migration is additive, doesn't delete old data

---

## 10. Next Steps

### Immediate (Today)

1. ✅ Update template JSON with Certification
2. ✅ Create migration SQL script
3. ✅ Test migration on dev database

### Short-term (This Week)

1. ✅ Implement new models in `models.py`
2. ✅ Create `setup_phase2_task3_strategies()` function
3. ✅ Update pathway services
4. ✅ Run migration on org 28 and 29

### Long-term (Next 2 Weeks)

1. ✅ Test with new organization creation
2. ✅ Update all API documentation
3. ✅ Add admin UI for strategy template management
4. ✅ Deploy to production

---

## 11. Questions & Decisions

### Q1: Should we allow organizations to customize competency targets?

**Decision**: NO
- Targets are research-based (Marcel Niemeyer)
- Customization would break validation
- Defeats purpose of standardization

**Alternative**: Add custom notes field if needed

### Q2: What about "Train the trainer" vs "Train the SE-Trainer"?

**Decision**: Standardize to "Train the trainer"
- Matches template JSON
- More generic (applies beyond SE)
- Update all instances to canonical form

### Q3: Keep old strategy_competency table after migration?

**Decision**: YES (for 1 month)
- Verify no issues
- Allow rollback if needed
- Then drop table

---

## END OF PLAN

**Status**: Ready for implementation
**Owner**: Development Team
**Approval Required**: Yes (Database schema changes)
