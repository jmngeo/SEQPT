# Core Competency Handling - Design Change Implementation

**Date**: November 7, 2025
**Status**: ✅ COMPLETE
**Change Type**: Design Modification - Core Competency Processing

---

## Executive Summary

**Previous Behavior**: Core competencies (Systems Thinking, Lifecycle Consideration, Customer/Value Orientation, Systems Modelling and Analysis) were treated as "not directly trainable" and skipped normal processing - they did not go through gap analysis or get learning objectives.

**New Behavior**: Core competencies are now processed identically to all other competencies - they go through full gap analysis, get learning objectives from templates, and are included in the trainable competencies list. An informational note is added to explain their indirect development nature.

---

## Design Rationale

While core competencies develop more indirectly through practice in other technical activities, they still benefit from:
1. Structured learning objectives that guide their development
2. Gap analysis to identify current vs target levels
3. PMT customization where applicable
4. Consistent treatment across the system

The informational note provides educational context without limiting functionality.

---

## Files Modified

### 1. Design Document
**File**: `data/source/Phase 2/LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

**Changes**:
- Updated "The 4 Core Competencies" section (lines 126-142)
- Removed special handling code examples in algorithm sections
- Updated output structure examples to show core competencies in trainable list
- Updated `calculate_strategy_summary()` function signature
- Updated example JSON output structure

**Key Points**:
- Core competencies now flagged with `is_core: true` and include `core_note` field
- Processed through same steps as other competencies
- No separate `core_competencies` array in output

---

### 2. Backend: Text Generator
**File**: `src/backend/app/services/learning_objectives_text_generator.py`

**Changes**:
- **Added** new function: `get_core_competency_note(competency_id: int) -> str`
  - Returns informational note for core competencies
  - Returns None for non-core competencies
- **Modified** existing function: `generate_core_competency_objective()`
  - Marked as DEPRECATED
  - Updated to use new `get_core_competency_note()` function
  - Kept for backward compatibility

**Lines Modified**: 445-500

**New Function**:
```python
def get_core_competency_note(competency_id: int) -> str:
    """
    Get informational note for core competencies
    Returns: Note string or None if not core
    """
    if competency_id not in CORE_COMPETENCIES:
        return None

    return (
        "This core competency develops indirectly through training in other competencies. "
        "It will be strengthened through practice in requirements definition, system architecting, "
        "integration, and other technical activities."
    )
```

---

### 3. Backend: Task-Based Pathway
**File**: `src/backend/app/services/task_based_pathway.py`

**Changes**:
- **Updated imports** (lines 46-54, 65-73): Replaced `generate_core_competency_objective` with `get_core_competency_note`
- **Removed** core competency skip logic (lines 456-465): Deleted entire `if comp_id in CORE_COMPETENCIES` block
- **Added** core competency flags to output objects:
  - Line 519-520: Added `is_core` flag and `core_note` to training_required competencies
  - Line 542-543: Added `is_core` flag and `core_note` to target_achieved competencies
- **Updated** strategy summary calculation (lines 553-574):
  - Removed separate `core_competencies_output` array
  - Calculate `core_count` from trainable competencies with `is_core` flag
  - Updated summary statistics structure

**Impact**: Core competencies now flow through normal 2-way comparison logic

---

### 4. Backend: Role-Based Pathway
**File**: `src/backend/app/services/role_based_pathway_fixed.py`

**Changes**:
- **Updated imports** (all instances): Replaced `generate_core_competency_objective` with `get_core_competency_note`
- **Removed** core competency skip logic (lines 1044-1059): Deleted entire special handling block
- **Added** core competency flags to output objects:
  - Line 1077-1078: Added to target_achieved competencies
  - Line 1151-1152: Added to training_required competencies
- **Updated** strategy summary calculation (lines 1189-1209):
  - Removed separate `core_competencies` output
  - Calculate `core_count` from trainable competencies
  - Updated summary structure

**Impact**: Core competencies now flow through normal 3-way comparison logic

---

### 5. Frontend: Learning Objectives View
**File**: `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue`

**Changes**:
- **Removed** separate core competencies section (lines 170-189)
  - Deleted "Core Competencies (Develop Indirectly)" heading
  - Deleted special rendering for core competencies
- **Updated** summary display (line 100-102):
  - Changed from `strategyData.core_competencies?.length` to `strategyData.summary?.core_competencies_count`

**Impact**: Core competencies now display in main trainable competencies list with other competencies

---

### 6. Frontend: Competency Card
**File**: `src/frontend/src/components/phase2/task3/CompetencyCard.vue`

**Changes**:
- **Added** core competency note display (lines 163-177)
  - Added `el-alert` component that displays when `isCore && competency.core_note`
  - Info-type alert with "Core Competency Development" title
  - Shows the informational note text

**Kept**:
- Core competency badge display (lines 7-9) - provides visual indication
- `isCore` computed property (lines 182-184) - determines badge visibility

**Impact**: Core competencies show learning objectives PLUS informational note about indirect development

---

## Output Structure Changes

### Before (Old Structure)
```json
{
  "learning_objectives_by_strategy": {
    "1": {
      "strategy_name": "...",
      "core_competencies": [
        {
          "competency_id": 1,
          "competency_name": "Systems Thinking",
          "status": "not_directly_trainable",
          "note": "..."
        }
      ],
      "trainable_competencies": [
        // 12 non-core competencies only
      ],
      "summary": {
        "core_competencies_count": 4,
        "trainable_competencies_count": 12
      }
    }
  }
}
```

### After (New Structure)
```json
{
  "learning_objectives_by_strategy": {
    "1": {
      "strategy_name": "...",
      "trainable_competencies": [
        {
          "competency_id": 1,
          "competency_name": "Systems Thinking",
          "current_level": 2,
          "target_level": 4,
          "gap": 2,
          "status": "training_required",
          "learning_objective": "Participants develop systems thinking...",
          "is_core": true,
          "core_note": "This core competency develops indirectly..."
        },
        // All 16 competencies (4 core + 12 trainable)
      ],
      "summary": {
        "total_competencies": 16,
        "core_competencies_count": 4,
        "trainable_competencies_count": 16
      }
    }
  }
}
```

---

## Key Differences Summary

| Aspect | Old Behavior | New Behavior |
|--------|-------------|--------------|
| **Gap Analysis** | ❌ Skipped for core competencies | ✅ Performed for all competencies |
| **Learning Objectives** | ❌ Not generated | ✅ Generated from templates |
| **PMT Customization** | ❌ Not applied | ✅ Applied if strategy requires it |
| **Output Structure** | Separate `core_competencies` array | All in `trainable_competencies` |
| **Visual Display** | Separate section at bottom | Integrated in main list with badge + note |
| **User Experience** | Fragmented (core vs trainable) | Unified (all together, cores flagged) |

---

## Testing Checklist

### Backend Tests
- [ ] Task-based pathway processes core competencies (IDs 1, 4, 5, 6)
- [ ] Role-based pathway processes core competencies
- [ ] Core competencies have `is_core: true` flag
- [ ] Core competencies have `core_note` field populated
- [ ] Gap analysis runs for core competencies
- [ ] Learning objectives generated from templates for core competencies
- [ ] PMT customization applies to core competencies (if strategy requires it)
- [ ] Summary statistics correctly count core competencies

### Frontend Tests
- [ ] Core competencies display in main trainable competencies list
- [ ] Core competency badge displays (red "Core Competency" tag)
- [ ] Core competency note displays below learning objective
- [ ] No separate "Core Competencies (Develop Indirectly)" section
- [ ] Core competencies can be filtered/sorted with other competencies
- [ ] Export functions include core competencies in main data

---

## Expected Behavior After Changes

### User Perspective
1. Admin sees all 16 competencies in unified list (not split into core vs trainable)
2. Core competencies have visual badge indicating special nature
3. Each core competency shows:
   - Full gap analysis (current → target)
   - Complete learning objective text
   - Informational note explaining indirect development
4. Core competencies can be filtered and sorted like any other competency

### System Perspective
1. Core competencies go through identical processing pipeline
2. Templates used for learning objectives
3. PMT customization applies where needed
4. Priority scores calculated
5. All analytics include core competencies

---

## Migration Notes

### No Database Changes Required
- This is a processing logic change only
- No database schema modifications needed
- Existing data remains valid

### Backward Compatibility
- Old function `generate_core_competency_objective()` kept as DEPRECATED
- Can be removed in future cleanup
- Frontend still checks for both old `status: 'core_competency'` and new `is_core: true` flag

---

## Future Considerations

### Phase 3 Integration
- Core competencies will be included in module selection
- Their indirect nature will be reflected in module recommendations
- Training duration estimates will account for indirect development

### Analytics Impact
- Training progress tracking now includes core competencies
- Completion rates will reflect all 16 competencies
- Gap closure metrics will track core competency improvements

---

## Files Summary

**Total Files Modified**: 6

### Design Documentation
1. `data/source/Phase 2/LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md`

### Backend
2. `src/backend/app/services/learning_objectives_text_generator.py`
3. `src/backend/app/services/task_based_pathway.py`
4. `src/backend/app/services/role_based_pathway_fixed.py`

### Frontend
5. `src/frontend/src/components/phase2/task3/LearningObjectivesView.vue`
6. `src/frontend/src/components/phase2/task3/CompetencyCard.vue`

---

## Validation Steps

To verify changes are working correctly:

1. **Generate learning objectives** for organization with both pathways
2. **Check output structure**: All competencies in `trainable_competencies` array
3. **Verify core flags**: Core competencies (1, 4, 5, 6) have `is_core: true`
4. **Verify notes**: Core competencies have populated `core_note` field
5. **Check frontend**: Core competencies display with badge and note
6. **Test filtering**: Core competencies can be filtered/sorted normally
7. **Test exports**: PDF/Excel/JSON exports include core competencies correctly

---

## Conclusion

This change aligns core competency handling with the rest of the system while preserving the educational context about their indirect development nature. The result is a more consistent, unified user experience without loss of information.

**Status**: ✅ All changes implemented and documented
**Next Step**: Test with actual data to verify behavior
