# PMT Test Files

Test files for validating the PMT document upload and extraction feature.

## Test Files Summary

| File | Primary Type | Description | Complexity |
|------|-------------|-------------|------------|
| `TEST_01_automotive_process.txt` | PROCESS | V-Model, ISO 26262, review gates | Medium |
| `TEST_02_sysml_method.txt` | METHOD | SysML modeling guidelines | Medium |
| `TEST_03_tools_landscape.txt` | TOOL | Enterprise tools inventory | High |
| `TEST_04_mixed_small_company.txt` | MIXED | Small company practices | Low |
| `TEST_05_medical_device.txt` | PROCESS | FDA/ISO 13485 regulated process | High |
| `TEST_06_aerospace_methods.txt` | METHOD | SE methods for aerospace | High |
| `TEST_07_devops_tools.txt` | TOOL | DevOps/CI-CD tool stack | High |
| `TEST_08_german_process.txt` | PROCESS | German language process doc | Medium |
| `TEST_09_agile_practices.txt` | MIXED | Scrum/Kanban practices | Medium |
| `TEST_10_minimal_startup.txt` | MIXED | Minimal startup doc | Low |

## Expected Extraction Results

### TEST_01_automotive_process.txt
- **Document Type:** process
- **Processes:** V-Model lifecycle, ISO 26262/ASPICE compliance, Review gates (SRR/PDR/CDR/TRR), Change Control Board
- **Methods:** Few (review process)
- **Tools:** Minimal

### TEST_02_sysml_method.txt
- **Document Type:** method
- **Methods:** SysML diagrams (REQ, BDD, IBD, ACT, STM), modeling conventions, traceability rules
- **Processes:** Model reviews
- **Tools:** Implied (SysML tool)

### TEST_03_tools_landscape.txt
- **Document Type:** tool
- **Tools:** DOORS, Jama, Rhapsody, MATLAB, Enterprise Architect, MS Project, Jira, Confluence, Git, ClearCase, Windchill, CANoe, dSPACE, LDRA, Teams, Miro
- **Processes:** Minimal
- **Methods:** Minimal

### TEST_04_mixed_small_company.txt
- **Document Type:** mixed
- **Processes:** Agile/Scrum, hardware approval
- **Methods:** User stories, design reviews, testing approach
- **Tools:** VS Code, PlatformIO, GitHub, KiCad, FreeCAD, Notion, Linear, Slack, pytest, Postman

### TEST_05_medical_device.txt
- **Document Type:** process
- **Processes:** FDA 21 CFR 820, ISO 13485, IEC 62304, ISO 14971, Design Control phases, Change management
- **Methods:** FMEA, FTA, Usability testing
- **Tools:** MasterControl QMS

### TEST_06_aerospace_methods.txt
- **Document Type:** method
- **Methods:** Stakeholder analysis, JAD workshops, QFD, N2 diagrams, FFBD, Trade studies, FMECA, Monte Carlo, TPM
- **Processes:** Configuration management, Risk management
- **Tools:** Minimal

### TEST_07_devops_tools.txt
- **Document Type:** tool
- **Tools:** GitLab, SonarQube, Checkmarx, Snyk, Artifactory, Kubernetes, Docker, Terraform, Ansible, Prometheus, Grafana, ELK, Jaeger, Vault, Slack, Confluence, Jira
- **Processes:** CI/CD pipeline
- **Methods:** GitFlow, Infrastructure as Code

### TEST_08_german_process.txt
- **Document Type:** process (German language)
- **Processes:** Project phases, requirements management, change management, approval process
- **Methods:** MoSCoW, FMEA, SysML
- **Tools:** Enterprise Architect, EPLAN, TIA Portal, CODESYS

### TEST_09_agile_practices.txt
- **Document Type:** mixed
- **Processes:** Scrum ceremonies, Definition of Done/Ready
- **Methods:** Planning Poker, TDD, Pair Programming, Code Review
- **Tools:** Jira, Confluence, Slack, Zoom, Miro, GitHub, VS Code

### TEST_10_minimal_startup.txt
- **Document Type:** mixed (minimal content)
- **Tools:** VS Code, GitHub, Notion, Figma, Slack, React, Node.js, PostgreSQL, AWS
- **Processes:** Minimal (weekly sync)
- **Methods:** None explicit

## Testing Recommendations

1. **Start with TEST_10** - Minimal content to test edge cases
2. **Test single-type docs** - TEST_01 (process), TEST_02 (method), TEST_03 (tool)
3. **Test mixed docs** - TEST_04, TEST_09
4. **Test complex docs** - TEST_05, TEST_06, TEST_07
5. **Test German** - TEST_08 for language handling
