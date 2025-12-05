# PMT Reference Files Summary
## For SE-QPT Application - Understanding Process, Method, Tool Documents

---

## Overview

This folder contains reference PMT (Process, Method, Tool) documents from Ulf that demonstrate
what real-world PMT documentation looks like. These can serve as templates/examples for users
of the SE-QPT application to understand what types of files they should upload.

---

## File Inventory

### 1. CQMS Confidential PDF (Process-Focused)
**Original File:** `CQMS-SOP-000172_Design_Input_confidential.pdf`
**Neutralized Version:** `NEUTRALIZED_Design_Input_Process_SOP.txt`

**Type:** Standard Operating Procedure (SOP) - **PROCESS** document
**Original Source:** Fresenius Medical Care (medical device industry)
**Pages:** 10

**Document Structure:**
1. Purpose
2. Scope
3. Responsibilities (RACI-style matrix)
4. Procedure
   - 4.1 Introduction
   - 4.2 Sources for Design Inputs
   - 4.3 UID Process (User Requirements)
   - 4.4 EID Process (Engineering Requirements)
   - 4.5 Requirements Tag Numbering
   - 4.6 Approval
5. References
6. Revision History

**Key Characteristics of a PROCESS Document:**
- Defines WHO does WHAT and WHEN
- Contains roles and responsibilities matrix
- Specifies workflow steps and decision points
- References related documents (forms, other SOPs)
- Includes approval and revision control
- Focuses on organizational workflow, not technical "how-to"

---

### 2. OneDrive Method Description Files (Method + Tool Focused)
**Location:** `OneDrive_1_21.11.2025/`

These are "Methodenbeschreibung" (Method Description) documents from BMW/Fraunhofer IEM
for the "Magic Grid" systems modeling methodology.

#### 2a. Part 0: Model Organization
**File:** `00_Methodenbeschreibung_Modellorganisation.pdf`
**Pages:** 14

**Document Structure:**
1. Introduction
   - 1.1 Hints and Best Practices
   - 1.2 BMW Magic Grid (overview)
   - 1.3 Nomenclature
2. Method: Model Organization
   - 2.1 Objective and Purpose
   - 2.2 Modeling Elements (Package, Project Usages)
3. Tool-Specific Implementation
   - 3.1 Profile Management
   - 3.2 Package Structure Setup

**Key Topics:**
- How to structure SysML models
- Package hierarchy (folders for Requirements, Functions, Logical, Physical)
- Profile management in Catia Magic (the TOOL)

---

#### 2b. Part 1: System Context
**File:** `01_Methodenbeschreibung_System_Context.pdf`
**Pages:** 22

**Document Structure:**
1. Introduction
   - 1.1 Hints and Best Practices
   - 1.2 Integration into BMW MagicGrid Methodology
2. Method: System Context
   - 2.1 Objective and Purpose
   - 2.2 Modeling Elements (Block, Composition, Port, Interface Block, Connector, Flows)
3. Tool-Specific Implementation
   - 3.1 Definition via Block Definition Diagram
   - 3.2 Context Diagram Creation
     - 3.2.1 Context Diagram Modeling
     - 3.2.2 Interaction Modeling
     - 3.2.3 Flow Modeling
     - 3.2.4 Interface Modeling

**Key Topics:**
- System of Interest vs Environment Elements
- External interface definition
- System boundary establishment
- SysML diagrams: BDD (Block Definition), IBD (Internal Block)

---

#### 2c. Part 6: White-Box Behavior
**File:** `06_Methodenbeschreibung_White_Box_Behaviour.pdf`
**Pages:** 15

**Document Structure:**
1. Introduction
   - 1.1 Hints and Best Practices
   - 1.2 Integration into BMW MagicGrid Methodology
2. Method: White-Box Behavior
   - 2.1 Objective and Purpose
   - 2.2 Modeling Elements (Swimlanes, Start/End, Actions, Control Flow)
3. Tool-Specific Implementation
   - 3.1 Activity Diagram Creation
   - 3.2 Start/End Modeling
   - 3.3 Actions Modeling
   - 3.4 Control Flow Modeling
   - 3.5 Swimlanes Creation

**Key Topics:**
- Activity diagrams for internal system behavior
- Swimlanes for component responsibilities
- Control flow (Decision, Fork, Join, Merge nodes)
- Call Behavior Actions

---

## PMT Classification

| Document | Process | Method | Tool |
|----------|---------|--------|------|
| CQMS Design Input SOP | **PRIMARY** | Referenced | Referenced |
| 00_Modellorganisation | - | **PRIMARY** | **DETAILED** |
| 01_System_Context | - | **PRIMARY** | **DETAILED** |
| 06_White_Box_Behaviour | - | **PRIMARY** | **DETAILED** |

### Explanation:

**PROCESS Documents** (like CQMS SOP):
- Focus on organizational workflow
- Define roles, responsibilities, approvals
- Answer: "What steps must our organization follow?"
- Example sections: Responsibilities Matrix, Approval Gates, Document Control

**METHOD Documents** (like BMW Methodenbeschreibung):
- Focus on HOW to perform technical activities
- Define modeling elements, diagrams, techniques
- Answer: "How do we technically accomplish this task?"
- Example sections: Modeling Elements, Objectives, Purpose

**TOOL Documents** (integrated in BMW docs as "Toolspezifische Umsetzung"):
- Focus on specific software/tool usage
- Step-by-step instructions with screenshots
- Answer: "How do we use this specific software?"
- Example sections: Menu navigation, Button clicks, Dialog boxes

---

## Key Observations for SE-QPT App

### What Users Should Upload

1. **Process Documents:**
   - SOPs (Standard Operating Procedures)
   - Work Instructions
   - Process Flowcharts
   - RACI Matrices
   - Quality Management docs

2. **Method Documents:**
   - Technical guidelines
   - Modeling guides
   - Design standards
   - Engineering handbooks
   - "How-to" technical documentation

3. **Tool Documents:**
   - Software user manuals
   - Tool configuration guides
   - Tool-specific tutorials
   - Quick reference cards

### Document Characteristics to Look For

| Characteristic | Process | Method | Tool |
|----------------|---------|--------|------|
| Contains roles/responsibilities | Yes | Sometimes | No |
| Has approval signatures | Yes | Sometimes | No |
| Shows software screenshots | No | Sometimes | Yes |
| Defines workflow steps | Yes | No | No |
| Explains technical concepts | No | Yes | No |
| Shows menu/button instructions | No | No | Yes |
| References standards/regulations | Yes | Yes | Sometimes |
| Has version control | Yes | Yes | Sometimes |

---

## Files Created/Available

| File | Type | Status |
|------|------|--------|
| `CQMS-SOP-000172_Design_Input_confidential.pdf` | Original Process doc | Confidential - DO NOT SHARE |
| `NEUTRALIZED_Design_Input_Process_SOP.txt` | Neutralized version | Safe to use as reference |
| `00_Methodenbeschreibung_Modellorganisation.pdf` | Method doc (German) | Reference only |
| `01_Methodenbeschreibung_System_Context.pdf` | Method doc (German) | Reference only |
| `06_Methodenbeschreibung_White_Box_Behaviour.pdf` | Method doc (German) | Reference only |

---

## Next Steps

1. **Paraphrase the Neutralized Document:**
   - The `NEUTRALIZED_Design_Input_Process_SOP.txt` still needs to be paraphrased
   - Goal: Create a finalized, generic reference that can serve as an example
   - Similar to the Test Roles docs approach

2. **Create Method/Tool Reference Examples:**
   - Consider creating English versions of the German Method docs
   - Or create generic Method/Tool examples for the SE-QPT context

3. **App Integration:**
   - Upload these reference files to the app
   - Let users view templates of PMT docs before uploading their own
   - Help users classify their documents correctly

---

## Document Notes from Ulf

> - The OneDrive folder has 3 files: Contain mainly "Method" description, also a bit of
>   how the methods are done using a "Tool".
> - The CQMS Confidential file: Focuses mostly on "Process" aspect.
> - After processing, these can be uploaded to our app for the purpose of letting the
>   user see reference templates of PMT docs.

---

*Last Updated: 2025-11-28*
