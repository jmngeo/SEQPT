# Updated SE-QPT Questionnaires
## Maturity Assessment & Archetype Selection

---

## **QUESTIONNAIRE 1: SE MATURITY ASSESSMENT**
*Based on BRETZ Maturity Model - Streamlined to 12 Essential Questions*

### **Section A: Fundamentals (Weight: 25%)**

**MAT_01. SE Mindset & Culture**
How would you describe the prevalence of systems thinking and SE mindset in your organization?
- [0] **Not available** - No SE awareness or systems thinking present
- [1] **Individual** - Few individuals have SE mindset from external experience  
- [2] **Fragmented** - Pockets of SE thinking in specific teams
- [3] **Established** - SE mindset widely understood and practiced
- [4] **Optimized** - SE culture continuously reinforced and evolving
- *Weight: 0.35*

**MAT_02. Knowledge Base**
What is the state of your organization's SE knowledge management?
- [0] **Not available** - No documented SE knowledge
- [1] **Ad hoc** - Individual knowledge, not shared systematically
- [2] **Fragmented** - Some documented knowledge in silos
- [3] **Established** - Centralized, accessible SE knowledge base
- [4] **Optimized** - Continuously updated, AI-enhanced knowledge system
- *Weight: 0.30*

**MAT_03. Tailoring Concept**
How does your organization adapt SE practices to specific contexts?
- [0] **Not available** - No adaptation mechanisms
- [1] **Ad hoc** - Informal, individual adaptations
- [2] **Simple logic** - Basic selection criteria for different project types
- [3] **Tailoring rules** - Documented adaptation guidelines
- [4] **Assisted** - Tool-supported, data-driven tailoring
- *Weight: 0.35*

### **Section B: Organization (Weight: 30%)**

**MAT_04. SE Roles and Processes**
To what extent are SE roles and processes defined and implemented?
- [0] **Not available** - No SE roles or processes defined
- [1] **Ad hoc/undefined** - Informal, inconsistent application
- [2] **Individually controlled** - Basic processes, roles emerging
- [3] **Defined and established** - Clear roles, documented processes
- [4] **Quantitatively predictable** - Measured and controlled processes
- [5] **Optimized** - Continuously improved based on metrics
- *Weight: 0.35*

**MAT_05. Rollout Scope**
What is the current reach of SE implementation in your organization?
- [0] **Not available** - SE not used
- [1] **Individual area** - Single team or department
- [2] **Development area** - Engineering/development departments
- [3] **Company-wide** - Entire organization
- [4] **Value chain** - Extended to suppliers/partners
- *Weight: 0.30*

**MAT_06. Training Concept**
How structured is your SE training and qualification approach?
- [0] **Not available** - No training concept
- [1] **Ad hoc** - Occasional, unplanned training
- [2] **Fragmented** - Some structured programs, not comprehensive
- [3] **Established** - Systematic training program
- [4] **Optimized** - Adaptive, personalized learning paths
- *Weight: 0.20*

**MAT_07. SE Organizational Structure**
How well-defined is the SE organizational structure?
- [0] **Not available** - No SE organizational elements
- [1] **Responsible defined** - SE contact persons identified
- [2] **Positions filled** - Dedicated SE roles staffed
- [3] **Support available** - SE support functions established
- [4] **Service available** - Full SE service organization
- *Weight: 0.15*

### **Section C: Process Capability (Weight: 25%)**

**MAT_08. Requirements Management Process**
What is the maturity of your requirements engineering processes?
- [0] **Not performed** - No systematic requirements management
- [1] **Performed** - Basic requirements captured
- [2] **Managed** - Requirements tracked and controlled
- [3] **Established** - Defined process with standards
- [4] **Predictable** - Quantitatively managed
- [5] **Optimizing** - Continuous improvement
- *Weight: 0.35*

**MAT_09. System Architecture Process**
How mature is your system architecture development?
- [0] **Not performed** - No systematic architecture approach
- [1] **Performed** - Basic architecture documentation
- [2] **Managed** - Architecture reviews and governance
- [3] **Established** - Standard architecture framework
- [4] **Predictable** - Architecture metrics and analysis
- [5] **Optimizing** - Model-based architecture optimization
- *Weight: 0.35*

**MAT_10. V&V Process**
What is the maturity of verification and validation processes?
- [0] **Not performed** - No systematic V&V
- [1] **Performed** - Basic testing conducted
- [2] **Managed** - Test planning and tracking
- [3] **Established** - Comprehensive V&V standards
- [4] **Predictable** - V&V metrics and prediction
- [5] **Optimizing** - Risk-based, optimized V&V
- *Weight: 0.30*

### **Section D: Infrastructure (Weight: 20%)**

**MAT_11. Tool Integration**
How integrated are your SE tools and platforms?
- [0] **Not available** - No SE tools or standalone only
- [1] **Single tool links** - Some point-to-point integrations
- [2] **Bidirectional sync** - Key tools exchange data
- [3] **Cluster coupling** - Process-area tool integration
- [4] **Complete integration** - Full tool chain integration
- *Weight: 0.50*

**MAT_12. MBSE Adoption**
To what extent is Model-Based Systems Engineering used?
- [0] **Not available** - No model usage
- [1] **Ad hoc** - Sporadic model use by individuals
- [2] **Basic decisions** - Models inform some decisions
- [3] **Established** - Systematic MBSE methodology
- [4] **Optimized** - AI-assisted, comprehensive MBSE
- *Weight: 0.50*

### **Scoring Algorithm:**
```
Fundamentals_Score = Weighted_Average(MAT_01 to MAT_03)
Organization_Score = Weighted_Average(MAT_04 to MAT_07)  
Process_Score = Weighted_Average(MAT_08 to MAT_10)
Infrastructure_Score = Weighted_Average(MAT_11 to MAT_12)

Overall_Maturity = √[(F² + O² + P² + I²) / 4]

Key Decision Variables:
- Process_Maturity = MAT_04 score
- Scope_Extent = MAT_05 score
```

---

## **QUESTIONNAIRE 2: ARCHETYPE SELECTION**
*Decision Tree Implementation - Reduced to 8 Essential Questions*

### **Section A: Maturity-Based Routing (Automated)**

**ARCH_00. Maturity Gate** *(Auto-calculated from MAT_04)*
```
IF MAT_04 ≤ 1 (Not available or Ad hoc):
    → Route to DUAL ARCHETYPE SELECTION (Low Maturity Path)
    → Primary: SE for Managers (Mandatory)
    → Secondary: Choice required (ARCH_01)
    
ELSE IF MAT_04 > 1:
    → Route to SINGLE ARCHETYPE SELECTION (High Maturity Path)
    → Based on MAT_05 (Rollout Scope)
```

### **Section B: Low Maturity Path (Dual Selection)**
*Only shown if MAT_04 ≤ 1*

**ARCH_01. Company Preference for SE Introduction**
Since SE processes and roles are not yet established, which approach does your company prefer?
- **[A] Apply SE in pilot** - "We want to test SE in a real project"
  → Selects: Orientation in Pilot Project
- **[B] Build awareness** - "We need basic understanding first"
  → Selects: Common Basic Understanding  
- **[C] Develop experts** - "We want certified SE specialists"
  → Selects: Certification
- *Weight: 1.0 (Decisive question)*

**ARCH_02. Management Readiness**
How prepared is your management team for SE introduction?
- [1] Need significant convincing
- [2] Somewhat interested
- [3] Actively supportive
- [4] Championing the initiative
- *Weight: 0.30*

**ARCH_03. Pilot Project Availability** *(Only if ARCH_01 = A)*
Do you have a suitable pilot project for SE application?
- [1] Need to identify one
- [2] Potential candidates exist
- [3] Project selected and ready
- [4] Multiple projects available
- *Weight: 0.25*

### **Section C: High Maturity Path (Single Selection)**
*Only shown if MAT_04 > 1*

**ARCH_04. SE Application Breadth** *(Auto-filled from MAT_05)*
```
IF MAT_05 ≤ 1 (Not available or Individual area):
    → Recommend: Needs-based Project-oriented Training
    
ELSE IF MAT_05 ≥ 2 (Development area or higher):
    → Recommend: Continuous Support
```

**ARCH_05. Organizational Learning Preference**
What is your preferred approach for ongoing SE development?
- [A] Project-specific intensive training
- [B] Continuous coaching and support
- [C] Self-directed with expert consultation
- [D] Blended approach
- *Weight: 0.40*

### **Section D: Common Selection Criteria (All Paths)**

**ARCH_06. Number of Participants**
How many employees need SE qualification?
- [A] 1-5 (Individual or small team)
- [B] 6-15 (Department or large team)
- [C] 16-50 (Multiple departments)
- [D] 50+ (Organization-wide)
- *Weight: 0.20*

**ARCH_07. Timeline Urgency**
What is your implementation timeline requirement?
- [A] Immediate (1-3 months)
- [B] Short-term (3-6 months)
- [C] Medium-term (6-12 months)
- [D] Long-term (12+ months)
- *Weight: 0.15*

**ARCH_08. Budget Allocation**
What is your approximate budget per participant?
- [A] <€1,000 (Basic training)
- [B] €1,000-3,000 (Standard program)
- [C] €3,000-5,000 (Comprehensive)
- [D] >€5,000 (Premium/certification)
- *Weight: 0.15*

### **Decision Logic Summary:**

```python
def select_archetypes(maturity_scores, preferences):
    archetypes = []
    
    # Check process maturity (MAT_04)
    if maturity_scores['MAT_04'] <= 1:
        # Low maturity: Dual selection
        archetypes.append('SE for Managers')  # Always first
        
        # Add secondary based on preference
        if preferences['ARCH_01'] == 'A':
            archetypes.append('Orientation in Pilot Project')
        elif preferences['ARCH_01'] == 'B':
            archetypes.append('Common Basic Understanding')
        elif preferences['ARCH_01'] == 'C':
            archetypes.append('Certification')
            
    else:
        # High maturity: Single selection
        if maturity_scores['MAT_05'] <= 1:
            archetypes.append('Needs-based Project-oriented Training')
        else:
            archetypes.append('Continuous Support')
    
    # Always evaluate Train the Trainer separately
    if evaluate_trainer_need(preferences):
        archetypes.append('Train the Trainer (Supplementary)')
    
    return archetypes
```

---

## **Implementation Benefits**

### **Reduced Complexity:**
- **From 38 to 20 questions** (47% reduction)
- **12 maturity questions** capture essential BRETZ elements
- **8 archetype questions** implement clear decision logic

### **Improved Decision Quality:**
- **Automated routing** based on maturity scores
- **Clear dual vs. single selection paths**
- **Explicit company preference capture** for low maturity

### **Better Alignment:**
- **Follows BRETZ model structure** (4 design areas, key action elements)
- **Implements Marcel's decision tree** accurately
- **Incorporates professor's dual selection guidance**

### **Enhanced Usability:**
- **Progressive disclosure** - only show relevant questions
- **Auto-calculation** of key decision points
- **Clear scoring algorithms** for transparency

---

## **Next Steps for Implementation**

1. **Validation Testing:**
   - Test with 3-5 pilot companies at different maturity levels
   - Validate scoring thresholds
   - Refine question wording based on feedback

2. **Integration Points:**
   - Connect to Derik's competency assessment (Step 2.1)
   - Link to learning format selection (Sachin's research)
   - Enable RAG processing for high-customization paths

3. **User Experience:**
   - Implement adaptive questionnaire flow
   - Add progress indicators
   - Provide real-time archetype recommendations

4. **Quality Metrics:**
   - Track completion rates
   - Measure decision confidence scores
   - Monitor archetype selection distribution