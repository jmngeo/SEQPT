# Learning Objectives Generation - Visual Flowcharts and Diagrams
**Supplementary Visual Documentation for Thesis Advisor**
**Date**: November 3, 2025

---

## Complete System Architecture

```mermaid
flowchart TB
    subgraph "Phase 1 Outputs"
        P1A[Maturity Score]
        P1B[Selected Strategies<br/>1-3 with Priorities]
        P1C[Target Group Size]
    end

    subgraph "Phase 2 Assessments"
        P2A[Employee<br/>Competency Scores]
        P2B[Role Selections<br/>or Task Descriptions]
    end

    subgraph "Reference Data"
        RD1[Strategy Templates<br/>Target Levels]
        RD2[Role-Competency Matrix<br/>Requirements]
        RD3[Learning Objective<br/>Templates]
    end

    subgraph "Processing Engine"
        PE1{Pathway<br/>Determination}
        PE2[Aggregation<br/>Engine]
        PE3[Comparison<br/>Logic]
        PE4[Decision<br/>Engine]
        PE5[Objective<br/>Generator]
    end

    subgraph "Outputs"
        O1[Learning Objectives<br/>Per Strategy]
        O2[Strategic<br/>Recommendations]
        O3[Module Planning<br/>Guidance]
    end

    P1A --> PE1
    P1B --> PE3
    P1C --> PE1

    P2A --> PE2
    P2B --> PE1

    RD1 --> PE3
    RD2 --> PE3
    RD3 --> PE5

    PE1 --> PE2
    PE2 --> PE3
    PE3 --> PE4
    PE4 --> PE5

    PE5 --> O1
    PE4 --> O2
    PE5 --> O3
```

---

## Detailed Data Flow - Task-Based Pathway

```mermaid
flowchart LR
    subgraph "Input Stage"
        A1[40 Employees<br/>Complete Assessment]
        A2[Each Rates<br/>16 Competencies]
        A3[Scores: 0,1,2,4,6]
    end

    subgraph "Aggregation Stage"
        B1[Collect Scores<br/>Per Competency]
        B2[Calculate<br/>Median]
        B3[Result:<br/>Org Level]
    end

    subgraph "Comparison Stage"
        C1[Get Strategy<br/>Target]
        C2[2-Way<br/>Compare]
        C3{Gap<br/>Exists?}
    end

    subgraph "Generation Stage"
        D1[Generate<br/>Objective]
        D2[Calculate<br/>Training Hours]
        D3[Note<br/>Impact %]
    end

    A1 --> A2 --> A3 --> B1
    B1 --> B2 --> B3 --> C2
    C1 --> C2
    C2 --> C3
    C3 -->|Yes| D1 --> D2 --> D3
    C3 -->|No| E[Mark Complete]
```

---

## Detailed Data Flow - Role-Based Pathway

```mermaid
flowchart TB
    subgraph "Role Analysis"
        RA[For Each Role]
        RA --> R1[Developer<br/>20 users]
        RA --> R2[Manager<br/>5 users]
        RA --> R3[Architect<br/>3 users]
    end

    subgraph "Per-Role Processing"
        R1 --> P1[Median Score: 2<br/>Role Needs: 4]
        R2 --> P2[Median Score: 3<br/>Role Needs: 6]
        R3 --> P3[Median Score: 4<br/>Role Needs: 6]
    end

    subgraph "3-Way Comparison"
        P1 --> C1[Current: 2<br/>Strategy: 4<br/>Role: 4<br/>→ Scenario A]
        P2 --> C2[Current: 3<br/>Strategy: 4<br/>Role: 6<br/>→ Scenario A]
        P3 --> C3[Current: 4<br/>Strategy: 4<br/>Role: 6<br/>→ Scenario B]
    end

    subgraph "User Distribution"
        C1 --> D1[A: 25 users]
        C2 --> D1
        C3 --> D2[B: 3 users]
        D1 --> PCT[A: 89%<br/>B: 11%]
    end

    subgraph "Decision"
        PCT --> DEC{B < 20%?}
        DEC -->|Yes| ACT1[Proceed with<br/>Current Strategy]
        DEC -->|No| ACT2[Consider<br/>Supplements]
    end
```

---

## Scenario Classification Logic

```mermaid
stateDiagram-v2
    [*] --> Input: Employee Data Available

    Input --> Compare: Start 3-Way Comparison

    Compare --> CheckCurrent: Evaluate Current Level

    CheckCurrent --> ScenarioA: Current less than Archetype less or equal Role
    CheckCurrent --> ScenarioB: Archetype less or equal Current less than Role
    CheckCurrent --> ScenarioC: Archetype greater than Role
    CheckCurrent --> ScenarioD: Current greater or equal All Targets

    ScenarioA --> Action1: Generate Standard Training Objective
    ScenarioB --> Action2: Recommend Higher Strategy
    ScenarioC --> Action3: Warning Over-Training Risk
    ScenarioD --> Action4: No Training Needed

    Action1 --> [*]
    Action2 --> [*]
    Action3 --> [*]
    Action4 --> [*]
```

---

## Multi-Role User Handling

```mermaid
flowchart TD
    User[Employee X]
    --> Roles[Selects Multiple Roles]

    Roles --> R1[Developer]
    Roles --> R2[Tester]

    R1 --> Req1[Decision Mgmt: 4]
    R2 --> Req2[Decision Mgmt: 2]

    Req1 --> Max[Use Maximum: 4]
    Req2 --> Max

    Max --> Objective[Generate for<br/>Level 4]
```

---

## Decision Thresholds Visualization

```mermaid
graph LR
    subgraph "User Distribution"
        Total[100 Users<br/>Total]
    end

    subgraph "Scenario Distribution"
        A[65 Users<br/>Scenario A<br/>65%]
        B[20 Users<br/>Scenario B<br/>20%]
        C[5 Users<br/>Scenario C<br/>5%]
        D[10 Users<br/>Scenario D<br/>10%]
    end

    subgraph "Decision Logic"
        Check1[20% in B<br/>Significant<br/>Minority]
        Action[Add<br/>Supplementary<br/>Modules]
    end

    Total --> A
    Total --> B
    Total --> C
    Total --> D

    B --> Check1
    Check1 --> Action
```

---

## Strategy Priority Processing

```mermaid
flowchart TD
    Strategies[Organization Selects<br/>3 Strategies]

    Strategies --> S1[PRIMARY:<br/>Needs-Based Project]
    Strategies --> S2[SUPPLEMENTARY:<br/>SE for Managers]
    Strategies --> S3[SECONDARY:<br/>Common Understanding]

    S1 --> P1[Generate Full<br/>Objectives]
    S2 --> P2[Generate for<br/>Gap Areas]
    S3 --> P3[Optional<br/>Enhancements]

    P1 --> Combine[Unified<br/>Output]
    P2 --> Combine
    P3 --> Combine

    Combine --> Final[One Training<br/>Plan for<br/>Organization]
```

---

## Aggregation Methods Comparison

```mermaid
flowchart LR
    subgraph "Input Data"
        Scores[Employee Scores:<br/>1,2,2,4,6]
    end

    subgraph "Mean (Not Used)"
        MeanCalc[Average = 3.0<br/>Invalid Level!]
    end

    subgraph "Median (Used)"
        MedianCalc[Middle = 2<br/>Valid Level]
    end

    subgraph "Mode Method"
        ModeCalc[Most Common = 2<br/>Less Robust]
    end

    Scores --> MeanCalc
    Scores --> MedianCalc
    Scores --> ModeCalc

    MeanCalc --> X1[Not a<br/>Real Level]
    MedianCalc --> Check[Actual<br/>Competency Level]
    ModeCalc --> X2[Ignores<br/>Distribution]
```

---

## Complete Example: Decision Management Competency

```mermaid
flowchart TB
    subgraph "Organization 28 Data"
        Org[Low Maturity<br/>No Roles<br/>40 Employees]
    end

    subgraph "Assessment Scores"
        Scores[0,0,1,1,1,2,2,2...<br/>Median = 2]
    end

    subgraph "Strategy: Needs-Based Project"
        Target[Target Level = 4]
    end

    subgraph "2-Way Comparison"
        Compare[Current: 2<br/>Target: 4<br/>Gap: 2 Levels]
    end

    subgraph "Generated Objective"
        Obj[From Understanding<br/>To Applying<br/>16 Hours Training<br/>85% Need This]
    end

    Org --> Scores
    Scores --> Compare
    Target --> Compare
    Compare --> Obj
```

---

## Output Generation Flow

```mermaid
flowchart TD
    subgraph "Per Strategy"
        S1[Strategy 1<br/>Objectives]
        S2[Strategy 2<br/>Objectives]
        S3[Strategy 3<br/>Objectives]
    end

    subgraph "Aggregation"
        AGG[Combine into<br/>Unified Set]
    end

    subgraph "Enhancement"
        REC[Add<br/>Recommendations]
        MOD[Add Module<br/>Guidance]
        FUT[Add Future<br/>Pipeline]
    end

    subgraph "Final Output"
        OUT[Complete Learning<br/>Objectives Document]
    end

    S1 --> AGG
    S2 --> AGG
    S3 --> AGG

    AGG --> REC
    AGG --> MOD
    AGG --> FUT

    REC --> OUT
    MOD --> OUT
    FUT --> OUT
```

---

## Edge Case Handling

```mermaid
flowchart TD
    Start[Check Data]

    Start --> C1{Completion<br/>< 70%?}
    C1 -->|Yes| E1[Error: Insufficient<br/>Data]
    C1 -->|No| C2{All at<br/>Same Level?}

    C2 -->|Yes| E2[Note: Limited<br/>Variance]
    C2 -->|No| C3{All Targets<br/>Met?}

    C3 -->|Yes| E3[Congratulations:<br/>No Training Needed]
    C3 -->|No| C4{Gaps Too<br/>Large?>}

    C4 -->|Yes| E4[Recommend:<br/>Phased Approach]
    C4 -->|No| Normal[Proceed with<br/>Normal Generation]
```

---

## System Validation Points

```mermaid
graph TD
    subgraph "Data Validation"
        V1[✓ 70% Completion]
        V2[✓ Latest Assessment Only]
        V3[✓ Valid Score Levels]
    end

    subgraph "Logic Validation"
        V4[✓ Correct Pathway]
        V5[✓ Proper Aggregation]
        V6[✓ Valid Comparisons]
    end

    subgraph "Output Validation"
        V7[✓ All Competencies]
        V8[✓ All Strategies]
        V9[✓ Unified Format]
    end

    V1 --> V4
    V2 --> V5
    V3 --> V6
    V4 --> V7
    V5 --> V8
    V6 --> V9

    V7 --> Success[Valid Learning<br/>Objectives]
    V8 --> Success
    V9 --> Success
```

---

*These visual flowcharts complement the detailed text explanation, providing a graphical representation of the Learning Objectives Generation algorithm for easier comprehension.*