# SE-QPT Implementation Guide for Claude Code
## Detailed Instructions for Updating JSON Questionnaires

---

## **OVERVIEW**
This document provides step-by-step instructions and prompts for using Claude Code to update your SE-QPT questionnaires from the current simplified version to a comprehensive implementation based on the BRETZ maturity model and proper archetype selection logic.

---

## **PART 1: MATURITY ASSESSMENT UPDATE**

### **Step 1.1: Backup Current Files**

**Prompt for Claude Code:**
```
Create backup copies of:
- maturity_assessment.json → maturity_assessment_backup.json
- archetype_selection.json → archetype_selection_backup.json
```

### **Step 1.2: Update Maturity Assessment Structure**

**Prompt for Claude Code:**
```
Update the maturity_assessment.json file with the following structure:

1. Replace the existing 3 questions with 12 comprehensive questions organized into 4 sections
2. Each section should have a section_weight that contributes to the overall maturity calculation
3. Implement the proper BRETZ model structure with these exact questions and scoring:

SECTION A: FUNDAMENTALS (section_weight: 0.25)
- MAT_01: SE Mindset & Culture (weight: 0.35)
  Options: Not available (0), Individual (1), Fragmented (2), Established (3), Optimized (4)
  
- MAT_02: Knowledge Base (weight: 0.30)
  Options: Not available (0), Ad hoc (1), Fragmented (2), Established (3), Optimized (4)
  
- MAT_03: Tailoring Concept (weight: 0.35)
  Options: Not available (0), Ad hoc (1), Simple logic (2), Tailoring rules (3), Assisted (4)

SECTION B: ORGANIZATION (section_weight: 0.30)
- MAT_04: SE Roles and Processes (weight: 0.35) [CRITICAL FOR ROUTING]
  Options: Not available (0), Ad hoc/undefined (1), Individually controlled (2), 
           Defined and established (3), Quantitatively predictable (4), Optimized (5)
  
- MAT_05: Rollout Scope (weight: 0.30) [CRITICAL FOR ROUTING]
  Options: Not available (0), Individual area (1), Development area (2), 
           Company-wide (3), Value chain (4)
  
- MAT_06: Training Concept (weight: 0.20)
  Options: Not available (0), Ad hoc (1), Fragmented (2), Established (3), Optimized (4)
  
- MAT_07: SE Organizational Structure (weight: 0.15)
  Options: Not available (0), Responsible defined (1), Positions filled (2), 
           Support available (3), Service available (4)

SECTION C: PROCESS CAPABILITY (section_weight: 0.25)
- MAT_08: Requirements Management Process (weight: 0.35)
  Options: Not performed (0), Performed (1), Managed (2), Established (3), 
           Predictable (4), Optimizing (5)
  
- MAT_09: System Architecture Process (weight: 0.35)
  Options: Not performed (0), Performed (1), Managed (2), Established (3), 
           Predictable (4), Optimizing (5)
  
- MAT_10: V&V Process (weight: 0.30)
  Options: Not performed (0), Performed (1), Managed (2), Established (3), 
           Predictable (4), Optimizing (5)

SECTION D: INFRASTRUCTURE (section_weight: 0.20)
- MAT_11: Tool Integration (weight: 0.50)
  Options: Not available (0), Single tool links (1), Bidirectional sync (2), 
           Cluster coupling (3), Complete integration (4)
  
- MAT_12: MBSE Adoption (weight: 0.50)
  Options: Not available (0), Ad hoc (1), Basic decisions (2), 
           Established (3), Comprehensive and optimized (4)

Add a "routing_variables" object that extracts:
- process_maturity: MAT_04 score
- rollout_scope: MAT_05 score
```

### **Step 1.3: Implement Scoring Algorithm**

**Prompt for Claude Code:**
```
Add the following scoring calculation to maturity_assessment.json:

"scoring": {
  "method": "hierarchical_weighted_average",
  "calculation_steps": [
    "1. Calculate section scores as weighted averages of questions within each section",
    "2. Calculate overall maturity as weighted average of section scores",
    "3. Extract routing variables MAT_04 and MAT_05 for archetype selection"
  ],
  "section_formulas": {
    "fundamentals_score": "Σ(MAT_01 to MAT_03 scores × weights) / Σ(weights)",
    "organization_score": "Σ(MAT_04 to MAT_07 scores × weights) / Σ(weights)",
    "process_score": "Σ(MAT_08 to MAT_10 scores × weights) / Σ(weights)",
    "infrastructure_score": "Σ(MAT_11 to MAT_12 scores × weights) / Σ(weights)",
    "overall_maturity": "Σ(section_scores × section_weights) / Σ(section_weights)"
  },
  "maturity_levels": {
    "initial": [0.0, 1.0],
    "developing": [1.0, 2.0],
    "defined": [2.0, 3.0],
    "managed": [3.0, 4.0],
    "optimized": [4.0, 5.0]
  },
  "routing_extraction": {
    "process_maturity": "Direct value of MAT_04",
    "rollout_scope": "Direct value of MAT_05"
  }
}
```

---

## **PART 2: ARCHETYPE SELECTION UPDATE**

### **Step 2.1: Restructure Archetype Selection Logic**

**Prompt for Claude Code:**
```
Update archetype_selection.json with the following dual-path logic:

1. Remove the existing simple conditional questions
2. Implement a two-path system based on maturity level:
   - LOW MATURITY PATH (MAT_04 ≤ 1): Dual archetype selection
   - HIGH MATURITY PATH (MAT_04 > 1): Single archetype selection

3. Structure the questionnaire as follows:

ROUTING LOGIC:
{
  "routing_rule": {
    "condition": "MAT_04_score",
    "low_maturity_threshold": 1,
    "paths": {
      "low_maturity": "dual_selection",
      "high_maturity": "single_selection"
    }
  }
}

LOW MATURITY PATH QUESTIONS:
- ARCH_01: Company Preference (weight: 1.0) [DECISIVE]
  Options: 
    A: "Apply SE in pilot" → Secondary: "Orientation in Pilot Project"
    B: "Build awareness" → Secondary: "Common Basic Understanding"
    C: "Develop experts" → Secondary: "Certification"
    
- ARCH_02: Management Readiness (weight: 0.30)
  Options: Need convincing (1), Somewhat interested (2), Actively supportive (3), Championing (4)
  
- ARCH_03: Pilot Project Availability (weight: 0.25) [CONDITIONAL: Only if ARCH_01 = A]
  Options: Need to identify (1), Candidates exist (2), Project ready (3), Multiple available (4)

HIGH MATURITY PATH QUESTIONS:
- ARCH_04: SE Application Breadth [AUTO-FILLED from MAT_05]
  Logic: If MAT_05 ≤ 1 → "Needs-based Training", If MAT_05 ≥ 2 → "Continuous Support"
  
- ARCH_05: Learning Preference (weight: 0.40)
  Options: Project-specific (A), Continuous coaching (B), Self-directed (C), Blended (D)

COMMON QUESTIONS (Both Paths):
- ARCH_06: Number of Participants (weight: 0.30)
  Options: 1-5 (A), 6-15 (B), 16-50 (C), 50+ (D)
  
- ARCH_07: Timeline Urgency (weight: 0.35)
  Options: 1-3 months (A), 3-6 months (B), 6-12 months (C), 12+ months (D)
```

### **Step 2.2: Implement Decision Tree**

**Prompt for Claude Code:**
```
Add the complete decision tree logic to archetype_selection.json:

"decision_tree": {
  "low_maturity_logic": {
    "primary": "ALWAYS: SE for Managers",
    "secondary": "BASED ON ARCH_01 preference",
    "implementation": [
      {
        "condition": "MAT_04 <= 1",
        "actions": [
          "1. Automatically select 'SE for Managers' as primary",
          "2. Show ARCH_01 for secondary selection",
          "3. Map ARCH_01 response to secondary archetype"
        ]
      }
    ]
  },
  "high_maturity_logic": {
    "selection": "SINGLE archetype based on rollout scope",
    "implementation": [
      {
        "condition": "MAT_04 > 1 AND MAT_05 <= 1",
        "result": "Needs-based Project-oriented Training"
      },
      {
        "condition": "MAT_04 > 1 AND MAT_05 >= 2",
        "result": "Continuous Support"
      }
    ]
  },
  "supplementary_logic": {
    "train_the_trainer": {
      "evaluation": "Always evaluated separately",
      "criteria": "Based on ARCH_06 (>50 participants) OR long-term planning (ARCH_07 = D)"
    }
  }
}
```

---

## **PART 3: VALIDATION AND TESTING**

### **Step 3.1: Create Validation Test Cases**

**Prompt for Claude Code:**
```
Create a test file validation_test_cases.json with the following scenarios:

TEST CASE 1: Low Maturity Company
Input:
- MAT_04 = 0 (No processes)
- MAT_05 = 0 (Not available)
- ARCH_01 = A (Apply in pilot)
Expected Output:
- Primary: SE for Managers
- Secondary: Orientation in Pilot Project

TEST CASE 2: Medium Maturity Company
Input:
- MAT_04 = 2 (Individually controlled)
- MAT_05 = 1 (Individual area)
Expected Output:
- Single: Needs-based Project-oriented Training

TEST CASE 3: High Maturity Company
Input:
- MAT_04 = 3 (Defined and established)
- MAT_05 = 3 (Company-wide)
Expected Output:
- Single: Continuous Support

TEST CASE 4: Edge Case - Transitioning Company
Input:
- MAT_04 = 1 (Ad hoc)
- ARCH_01 = B (Build awareness)
Expected Output:
- Primary: SE for Managers
- Secondary: Common Basic Understanding

Implement validation logic to check:
1. Correct archetype selection based on inputs
2. Proper dual vs single selection
3. Score calculations are accurate
4. Conditional questions appear correctly
```

### **Step 3.2: Create Score Calculation Validator**

**Prompt for Claude Code:**
```
Create a function to validate score calculations:

function validateScoring(responses) {
  // Section A: Fundamentals
  const fundamentals = [
    { id: 'MAT_01', score: responses.MAT_01, weight: 0.35 },
    { id: 'MAT_02', score: responses.MAT_02, weight: 0.30 },
    { id: 'MAT_03', score: responses.MAT_03, weight: 0.35 }
  ];
  const fundamentalsScore = calculateWeightedAverage(fundamentals);
  
  // Section B: Organization (CRITICAL)
  const organization = [
    { id: 'MAT_04', score: responses.MAT_04, weight: 0.35 }, // ROUTING VARIABLE
    { id: 'MAT_05', score: responses.MAT_05, weight: 0.30 }, // ROUTING VARIABLE
    { id: 'MAT_06', score: responses.MAT_06, weight: 0.20 },
    { id: 'MAT_07', score: responses.MAT_07, weight: 0.15 }
  ];
  const organizationScore = calculateWeightedAverage(organization);
  
  // Extract routing variables
  const routingVars = {
    process_maturity: responses.MAT_04,
    rollout_scope: responses.MAT_05
  };
  
  // Validate archetype selection
  const selectedArchetypes = selectArchetypes(routingVars, responses);
  
  return {
    sectionScores: {
      fundamentals: fundamentalsScore,
      organization: organizationScore,
      process: processScore,
      infrastructure: infrastructureScore
    },
    overallMaturity: calculateOverallMaturity(sectionScores),
    routingVariables: routingVars,
    selectedArchetypes: selectedArchetypes,
    validationPassed: validateLogic(selectedArchetypes, routingVars)
  };
}
```

---

## **PART 4: IMPLEMENTATION SEQUENCE**

### **Step 4.1: Complete Implementation Order**

**Prompt for Claude Code:**
```
Execute the following implementation sequence:

1. BACKUP Phase:
   - Create timestamped backups of existing JSON files
   - Store in /backups/[timestamp]/ directory

2. MATURITY UPDATE Phase:
   - Update maturity_assessment.json with 12 questions
   - Add section structure and weights
   - Implement scoring algorithm
   - Add routing variable extraction

3. ARCHETYPE UPDATE Phase:
   - Update archetype_selection.json with dual-path logic
   - Implement conditional question display
   - Add decision tree with proper dual selection
   - Remove budget question (ARCH_08)

4. VALIDATION Phase:
   - Create test cases file
   - Run validation tests
   - Generate validation report

5. INTEGRATION Phase:
   - Create unified questionnaire_controller.js
   - Implement adaptive flow logic
   - Add progress tracking
   - Enable save/resume functionality

6. DOCUMENTATION Phase:
   - Generate API documentation
   - Create user flow diagrams
   - Document scoring algorithms
   - Provide integration guidelines
```

---

## **PART 5: FINAL VALIDATION CHECKLIST**

### **Critical Points to Verify:**

**Prompt for Claude Code:**
```
Run final validation checks:

☐ MAT_04 (SE Roles and Processes) correctly triggers dual/single path
☐ MAT_05 (Rollout Scope) correctly determines high maturity archetype
☐ Low maturity ALWAYS selects "SE for Managers" as primary
☐ ARCH_01 properly maps to secondary archetypes
☐ No mention of "AI-assisted" in any question text
☐ Budget question (ARCH_08) completely removed
☐ Scoring weights sum to 1.0 within each section
☐ Section weights sum to 1.0 for overall calculation
☐ Conditional questions only appear when criteria met
☐ All 7 archetypes are properly mapped in decision logic

Generate a validation report showing:
- All checks passed/failed
- Score calculation examples
- Decision tree traversal examples
- Edge case handling
```

---

## **PART 6: QUICK REFERENCE**

### **Key Files to Update:**
```
/questionnaires/
  ├── maturity_assessment.json (12 questions, 4 sections)
  ├── archetype_selection.json (7 questions, dual-path logic)
  └── validation_test_cases.json (4+ test scenarios)
```

### **Critical Logic Rules:**
```javascript
// Dual Selection (Low Maturity)
if (MAT_04 <= 1) {
  archetypes = ['SE for Managers', getSecondaryBasedOn(ARCH_01)];
}

// Single Selection (High Maturity)  
else if (MAT_04 > 1) {
  if (MAT_05 <= 1) {
    archetypes = ['Needs-based Project-oriented Training'];
  } else {
    archetypes = ['Continuous Support'];
  }
}
```

### **Archetype Mapping:**
```
Low Maturity (Dual):
- Primary: SE for Managers (always)
- Secondary Options:
  - Orientation in Pilot Project (if ARCH_01 = A)
  - Common Basic Understanding (if ARCH_01 = B)
  - Certification (if ARCH_01 = C)

High Maturity (Single):
- Needs-based Project-oriented Training (if scope limited)
- Continuous Support (if scope broad)

Supplementary:
- Train the Trainer (evaluated separately)
```

---

## **ERROR HANDLING**

### **Common Issues and Solutions:**

**Prompt for Claude Code:**
```
Implement error handling for:

1. Missing routing variables:
   - If MAT_04 is null → Default to low maturity path
   - If MAT_05 is null → Request completion before archetype selection

2. Incomplete responses:
   - Track required vs optional questions
   - Prevent archetype selection until critical questions answered
   - Show clear error messages

3. Logic conflicts:
   - If scores indicate transition state → Provide both options
   - If archetype conflicts with participant numbers → Show warning

4. Score calculation errors:
   - Validate all scores are within expected ranges
   - Handle missing weights gracefully
   - Log calculation steps for debugging
```

---

## **SUCCESS METRICS**

Track and report on:
- Question completion rates per section
- Average time to complete each questionnaire
- Archetype selection distribution
- Validation test pass rate
- User-reported clarity scores

This implementation will create a robust, validated SE-QPT questionnaire system that properly implements the BRETZ maturity model and dual archetype selection logic.