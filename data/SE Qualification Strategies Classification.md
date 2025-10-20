# Updated Systems Engineering Qualification Strategies Classification

## Strategy Categories for SE-QPT Implementation

### **Excluded from Detailed Planning**
- **Train the Trainer** 
  - Reason: Does not require detailed planning consideration
  - Status: Out of scope for SE-QPT prototype

### **Dual Selection Strategies (No Processes/Roles Available)**

When companies have **no processes and roles in place** (maturity level "not available" or "ad hoc/undefined"), the system must implement a **mandatory dual archetype selection**:

#### **Primary Archetype (Always Required):**

#### 1. SE for Managers/Leaders
- **Selection Rule**: MANDATORY when Process_Score ≤ 1.5
- **Customization Level**: 10% company-specific
- **RAG Processing**: Minimal processing required
- **Rationale**: Management buy-in is essential as enabler for implementation projects
- **Target Phase**: Motivation phase

#### **Secondary Archetype (One Must Be Selected):**

Based on company preference ("Which approach does the company prefer?"):

#### 2a. Orientation in Pilot Project
- **Selection Trigger**: Company preference = "SE shall be applied"
- **Customization Level**: 10% company-specific
- **RAG Processing**: Minimal processing required
- **Input Requirements**: Basic company context + pilot project details
- **Learning Objective Source**: Pre-defined standardized objectives from knowledge base
- **Target Phase**: Motivation/Introduction phase

#### 2b. Common Basic Understanding  
- **Selection Trigger**: Company preference = "Basic understanding should be created"
- **Customization Level**: 10% company-specific
- **RAG Processing**: Minimal processing required
- **Input Requirements**: Basic company context
- **Learning Objective Source**: Pre-defined standardized objectives from knowledge base
- **Target Phase**: Motivation phase

#### 2c. Certification
- **Selection Trigger**: Company preference = "Experts should be trained"
- **Customization Level**: 10% company-specific
- **RAG Processing**: Minimal processing required
- **Input Requirements**: Certification type selection
- **Learning Objective Source**: Pre-defined standardized objectives from knowledge base
- **Target Phase**: Motivation phase

### **Individual Learning Objectives Strategies (High Customization - 90% Company-Specific)**

When companies have **processes and roles in place** (maturity level ≥ "individually controlled"):

#### 3. Continuous Support
- **Selection Trigger**: Process_Score > 1.5 AND Scope_Score ≥ 3.0
- **Customization Level**: 90% company-specific
- **RAG Processing**: High intensity required
- **Input Requirements**: Extensive company PMT data needed
- **Learning Objective Source**: Generated via RAG LLM from company context
- **Target Phase**: Continuation/Stabilization phase

#### 4. Needs-based Project-oriented Training  
- **Selection Trigger**: Process_Score > 1.5 AND Scope_Score < 3.0
- **Customization Level**: 90% company-specific
- **RAG Processing**: High intensity required
- **Input Requirements**: Extensive company PMT data needed
- **Learning Objective Source**: Generated via RAG LLM from company context
- **Target Phase**: Introduction phase with defined processes

## Implementation Implications for SE-QPT

### **Critical Architectural Requirements**

#### **Dual Selection Logic (No Processes/Roles)**
```
IF (Process_Score ≤ 1.5) THEN
    Archetype_Primary = "SE_for_Managers" (MANDATORY)
    
    IF (Company_Preference = "Apply_SE") THEN
        Archetype_Secondary = "Orientation_Pilot_Project"
    ELSE IF (Company_Preference = "Basic_Understanding") THEN
        Archetype_Secondary = "Common_Understanding"  
    ELSE IF (Company_Preference = "Expert_Training") THEN
        Archetype_Secondary = "Certification"
    END IF
    
    RETURN [Archetype_Primary, Archetype_Secondary]
END IF
```

#### **Single Selection Logic (Processes/Roles Available)**
```
ELSE IF (Process_Score > 1.5) THEN
    IF (Scope_Score ≥ 3.0) THEN
        RETURN ["Continuous_Support"]
    ELSE
        RETURN ["Needs_Based_Training"]
    END IF
END IF
```

### **System Architecture Requirements**

#### **Low Customization Path (Dual Selection Required)**
- **Processing**: Template-based approach for BOTH selected archetypes
- **RAG Integration**: Minimal processing for both primary and secondary
- **Learning Objectives**: Two sets of standardized objectives must be retrieved and combined
- **Resource Requirements**: Lower computational needs but DUAL processing pipelines
- **Timeline**: Fast processing for both archetype selections

#### **High Customization Path (Single Selection)**
- **Processing**: Advanced RAG LLM integration for single selected archetype
- **RAG Integration**: High intensity processing for comprehensive customization
- **Learning Objectives**: Single set of company-specific objectives generated
- **Resource Requirements**: Higher computational needs for single comprehensive analysis
- **Timeline**: Longer processing time for deep customization

### **Data Input Requirements**

#### **For Dual Selection (Low Maturity Companies):**
- Basic company information
- Company preference selection (Apply/Understanding/Expert)
- Number of participants for both tracks
- Timeline constraints
- Management structure overview

#### **For Single Selection (High Maturity Companies):**
- Detailed Process descriptions
- Comprehensive Methods documentation  
- Complete Tools inventory
- Role-specific competency gaps
- Company-specific constraints and preferences

### **Learning Objective Generation Process**

#### **Dual Selection Process (10% Company-Specific Each):**
1. Retrieve standardized "SE for Managers" objectives
2. Retrieve standardized secondary archetype objectives
3. Apply minimal company context adaptation to both sets
4. Combine and sequence the dual learning paths
5. Output integrated dual qualification plan

#### **Single Selection Process (90% Company-Specific):**
1. Analyze company PMT data via RAG
2. Map to role clusters and competencies
3. Generate custom learning objectives for selected archetype
4. Validate against company context
5. Output tailored qualification plan

## Updated Decision Tree Logic

```
1. Assess Company Maturity (Process & Scope Scores)
2. IF Low Maturity (Process_Score ≤ 1.5):
   - SELECT "SE for Managers" (Mandatory)
   - PROMPT for Company Preference
   - SELECT Secondary Archetype based on preference
   - PROCESS dual standardized learning objectives
3. ELSE IF High Maturity (Process_Score > 1.5):
   - ASSESS Scope Score
   - SELECT single archetype (Continuous Support OR Needs-based)
   - PROCESS single customized learning objectives
4. CONSIDER "Train the Trainer" (Always available, external reference)
```

## Quality Assurance

### **Validation Metrics:**
- **Dual Selection**: Measure integration effectiveness between primary and secondary archetype learning paths
- **Single Selection**: Measure relevance of generated objectives to company PMT
- **Both**: Measure achievement of target competency levels per archetype combination

### **Critical Success Factors:**
- Proper sequencing of dual archetypes (managers first, then secondary)
- Seamless integration between standardized learning objective sets
- Clear differentiation between low and high maturity processing paths
- Robust decision tree logic implementation