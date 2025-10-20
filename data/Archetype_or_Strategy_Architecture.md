# SE-QPT Updated System Architecture

## Core System Components

### **1. Strategy Classification Module**
```
Input: Selected Qualification Strategy
Output: Route to High/Low Customization Path

Logic:
- IF strategy IN ['Continuous Support', 'Needs-based Project-oriented Training']:
    → Route to High Customization Path
- ELIF strategy IN ['Common Basic Understanding', 'SE for Managers', 'Orientation in Pilot Project', 'Certification']:
    → Route to Low Customization Path  
- ELIF strategy == 'Train the Trainer':
    → Display "Out of Scope" message + external resources
```

### **2. Dual Processing Architecture**

#### **High Customization Path (90% Company-Specific)**
```
Components Required:
├── Advanced RAG LLM Engine
├── Company PMT Data Processor
├── Individual Learning Objective Generator
├── Custom Competency Mapper
└── Company-Specific Validation Module

Data Flow:
1. Extensive PMT Input Collection
2. RAG Processing of Company Context
3. Custom Learning Objective Generation
4. Role-Specific Competency Mapping
5. Individual Qualification Plan Output
```

#### **Low Customization Path (10% Company-Specific)**
```
Components Required:
├── Standardized Learning Objective Library
├── Template Selection Engine
├── Minimal Context Adapter
├── Pre-defined Competency Mapper
└── Standard Validation Module

Data Flow:
1. Basic Company Info Collection
2. Template Selection Based on Strategy
3. Minor Context-Based Customization
4. Standard Learning Objective Retrieval
5. Standardized Qualification Plan Output
```

### **3. Updated Input Collection Module**

#### **For High Customization Strategies:**
```
Required Inputs:
- Company Processes (detailed descriptions)
- Company Methods (comprehensive documentation)
- Company Tools (complete inventory with usage context)
- Existing Role Definitions
- Current Competency Levels per Role
- Company-Specific Constraints
- Project Context (for Needs-based)
- Support Infrastructure (for Continuous Support)
```

#### **For Low Customization Strategies:**
```
Required Inputs:
- Company Size
- Industry Sector  
- Number of Participants
- Timeline Preferences
- Basic Maturity Level
- Strategy Preference Reason
- Available Resources (time/budget)
```

### **4. Learning Objective Management System**

#### **Individual Learning Objectives Database**
- Template structures for RAG generation
- Company context integration points
- Custom competency frameworks
- Dynamic objective creation rules

#### **Standardized Learning Objectives Library**  
- Pre-defined objectives per strategy
- Competency level mappings
- Standard role cluster assignments
- Minor customization parameters

### **5. Output Generation Module**

#### **High Customization Output:**
```
Generated Content:
- Company-specific learning objectives (90% custom)
- Tailored competency development paths
- Custom module selections
- Company PMT-integrated examples
- Role-specific qualification roadmaps
```

#### **Low Customization Output:**
```
Generated Content:
- Standardized learning objectives (10% custom)
- Standard competency development paths  
- Pre-defined module selections
- Generic examples with company name insertion
- Standard qualification templates
```

## Implementation Phases

### **Phase 1: Basic Framework**
1. Implement Strategy Classification Module
2. Create dual routing system
3. Build basic input collection forms
4. Develop standardized path (easier to implement)

### **Phase 2: Advanced Customization**
1. Integrate RAG LLM for high customization path
2. Develop company PMT processing algorithms
3. Create individual learning objective generation
4. Build advanced validation systems

### **Phase 3: Integration & Optimization**
1. Connect both paths to unified output system
2. Optimize processing performance
3. Add quality assurance mechanisms
4. Implement user experience improvements

## Technical Specifications

### **Technology Stack Requirements:**

#### **High Customization Path:**
- Advanced NLP/RAG models (GPT-4, Claude, or similar)
- Vector databases for PMT data processing
- Custom ML models for competency mapping
- High-performance computing resources

#### **Low Customization Path:**
- Simple template engines
- Standard database queries
- Basic rule-based systems  
- Standard web application resources

### **Performance Expectations:**
- **High Customization**: 5-15 minutes processing time
- **Low Customization**: 30 seconds - 2 minutes processing time