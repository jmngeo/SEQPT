# SE-QPT Project Refactoring Instructions

## Project Overview
Refactor the Systems Engineering Qualification Planning Tool (SE-QPT) to align with the new 4-phase structure defined in SEQPT.xlsx. The tool should guide companies through a systematic process to assess their SE maturity, identify qualification needs, and develop comprehensive training plans.

## New Phase Structure

### Phase 1: Prepare SE Training
**Objective:** Establish the foundation for SE qualification planning by understanding the company's current state and strategic direction.

**Tasks to Implement:**
1. **Determine current maturity level**
   - Implement maturity model assessment
   - Use the maturity dimensions from the "Maturity" sheet
   - Fields of Action to assess: Process implementation, Role definition, Rollout scope, etc.

2. **Identify SE roles**
   - Map existing company roles to standard role clusters
   - Integrate role identification from the "Roles" sheet
   - Support customer, development, and management role categories

3. **Select SE training strategy**
   - Implement decision tree logic for strategy selection
   - Include strategy profile cards interface
   - Support multiple strategy combinations

**Deliverables (Output Components):**
- SE maturity assessment report
- Identified SE roles mapping
- Selected SE training strategy document

### Phase 2: Identify Requirements and Competencies
**Objective:** Define specific learning needs and identify competency gaps.

**Tasks to Implement:**
1. **Determine necessary competencies**
   - Implement SE competencies framework
   - Create task-competency matrix interface
   - Link competencies to identified roles

2. **Formulate learning objectives**
   - Implement learning objective templates
   - Support customization based on company context
   - Use RAG LLM for company-specific objectives generation

3. **Identify competency gaps**
   - Integrate Derik's competency assessor
   - Individual assessment per role
   - Gap analysis visualization

**Deliverables (Output Components):**
- Competency skill gaps analysis
- Company-specific learning objectives document

### Phase 3: Macro Planning
**Objective:** Design the high-level training concept with modules and formats.

**Tasks to Implement:**
1. **Define modules**
   - Module selection based on competency gaps
   - Integration with existing training offers
   - Module dependency management

2. **Select formats**
   - Implement qualification format profiles
   - Format selection decision tree
   - Integration with Sachin Kumar's learning formats framework

**Deliverables (Output Components):**
- SE training concept document
- Module-format mapping

### Phase 4: Micro Planning
**Objective:** Create detailed implementation plans for training execution.

**Tasks to Implement:**
1. **Define detailed concept**
   - Implement AVIVA method
   - Concept template generation
   - Concrete implementation timeline

**Deliverables (Output Components):**
- SE training detailed concept
- Implementation roadmap

## Implementation Requirements

### Core Components to Refactor:

1. **Navigation Structure**
   - Update to 4-phase navigation
   - Progress tracking across phases
   - Phase dependencies and validation

2. **Data Model**
   - Align database schema with new phase structure
   - Update state management for 4 phases
   - Ensure data persistence between phases

3. **UI Components**
   ```
   - Phase 1: Maturity assessment wizard, Role mapping interface, Strategy selection tree
   - Phase 2: Competency matrix, Learning objectives editor, Gap analysis dashboard
   - Phase 3: Module selector, Format decision support, Concept builder
   - Phase 4: AVIVA method implementation, Timeline planner, Export functionality
   ```

4. **Integration Points**
   - RAG LLM integration for learning objectives
   - Derik's competency assessor integration
   - Sachin's learning format selector integration
   - Excel import/export for Qualifizierungsmodule_Qualifizierungspläne_v4

5. **Strategy Selection Logic**
   Implement decision tree based on:
   - SE introduction phase (motivation vs. implementation)
   - Current maturity level
   - Rollout scope
   - Target group size (<20, 20-100, 100-500, 500-1500, >1500)

### Strategy Options to Include:
- Train the Trainer (internal/external)
- SE for Managers
- Orientation in Pilot Project
- Common Basic Understanding
- Certification
- Needs-based Project-oriented Training
- Continuous Support

### Key Features to Preserve:
- Maturity model assessment functionality
- Role cluster mapping
- Competency gap analysis
- Learning objective customization
- Module selection and configuration
- Format selection based on parameters
- Export capabilities for documentation

### Migration Notes:
1. The previous "Analysis", "Requirements", "Pre-concept", and "Detailed concept" stages map to the new 4 phases
2. Ensure backward compatibility for existing data
3. Update all references to old phase names
4. Maintain integration with existing qualification modules Excel file

### Testing Requirements:
- Phase transition validation
- Data persistence across phases
- Strategy selection accuracy
- Competency assessment integration
- Learning objective generation
- Export functionality

## File Structure Recommendation:
```
/src
  /phases
    /phase1-prepare
      - MaturityAssessment.jsx
      - RoleMapping.jsx
      - StrategySelection.jsx
    /phase2-requirements
      - CompetencyMatrix.jsx
      - LearningObjectives.jsx
      - GapAnalysis.jsx
    /phase3-macro-planning
      - ModuleSelection.jsx
      - FormatSelection.jsx
      - ConceptBuilder.jsx
    /phase4-micro-planning
      - AVIVAMethod.jsx
      - DetailedConcept.jsx
      - ImplementationPlan.jsx
  /shared
    - Navigation.jsx
    - ProgressTracker.jsx
    - DataPersistence.js
  /integrations
    - CompetencyAssessor.js
    - LearningFormats.js
    - RAGLLMConnector.js
```

## Priority Implementation Order:
1. Update navigation and phase structure
2. Implement Phase 1 components (foundation)
3. Integrate competency assessor in Phase 2
4. Add RAG LLM for learning objectives
5. Implement module and format selection in Phase 3
6. Complete detailed planning in Phase 4
7. Add export and reporting functionality
8. Testing and validation

## Additional Context Files to Reference:
- Qualifizierungsmodule_Qualifizierungspläne_v4 enUS.xlsx (matrices and learning objectives)
- DerikRoby_MasterThesis_Evaluation_Summary.pdf (competency assessment logic)
- Sachin_Kumar_Master_Thesis_6906625.pdf (learning format parameters)

Use this document as the primary reference for refactoring the SE-QPT project to align with the new phase structure and requirements.