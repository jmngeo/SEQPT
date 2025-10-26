# Phase 2: 16 SE Competencies Quick Reference

**Database:** `competency_assessment`
**Table:** `competency`

---

## The 16 SE Competencies

### Core Competencies (4)

| ID | Competency Name | German | Description Focus |
|----|----------------|--------|-------------------|
| **1** | **Systems Thinking** | Systemdenken | Holistic view, interconnections |
| **4** | **Lifecycle Consideration** | Lebenszyklus-Betrachtung | Full system lifecycle awareness |
| **5** | **Customer / Value Orientation** | Kundennutzenorientierung | Customer needs, value delivery |
| **6** | **Systems Modelling and Analysis** | Systemmodellierung und -analyse | Modeling techniques, analysis |

### Social / Personal Competencies (3)

| ID | Competency Name | German | Description Focus |
|----|----------------|--------|-------------------|
| **7** | **Communication** | Kommunikation | Effective communication |
| **8** | **Leadership** | Führung | Team leadership, motivation |
| **9** | **Self-Organization** | Selbstorganisation | Time management, self-direction |

### Management Competencies (4)

| ID | Competency Name | German | Description Focus |
|----|----------------|--------|-------------------|
| **10** | **Project Management** | Projektmanagement | Planning, scheduling, resources |
| **11** | **Decision Management** | Entscheidungsmanagement | Decision-making processes |
| **12** | **Information Management** | Informationsmanagement | Data handling, documentation |
| **13** | **Configuration Management** | Konfigurationsmanagement | Version control, change management |

### Technical Competencies (5)

| ID | Competency Name | German | Description Focus |
|----|----------------|--------|-------------------|
| **14** | **Requirements Definition** | Anforderungsdefinition | Elicitation, specification, management |
| **15** | **System Architecting** | Systemarchitektur | Architecture design, patterns |
| **16** | **Integration, Verification, Validation** | Integration, Verifikation, Validierung | Testing, validation methods |
| **17** | **Operation and Support** | Betrieb und Unterstützung | Maintenance, support processes |
| **18** | **Agile Methods** | Agile Methoden | Agile practices, frameworks |

---

## Competency Level Scale

### Values Used in Database

```
0 = Not Relevant (nicht relevant)
1 = Know (kennen)
2 = Understand (verstehen)
4 = Apply (anwenden)
6 = Master (beherrschen)
```

**Note:** Values 3 and 4 are both "apply" but represent different proficiency levels in some contexts.

---

## Competency Indicators

Each competency has **4 levels × 3 indicators = 12 indicators**

### Level Structure:

| Level | German | English | Score | Group |
|-------|--------|---------|-------|-------|
| 1 | Kennen | Know | 1 | Group 1 |
| 2 | Verstehen | Understand | 2 | Group 2 |
| 3/4 | Anwenden | Apply | 4 | Group 3 |
| 4/6 | Beherrschen | Master | 6 | Group 4 |
| 0 | Keine | None | 0 | Group 5 |

**Example for "Systems Thinking":**

**Group 1 - Kennen (Know):**
- I know what systems thinking means
- I can define systems thinking
- I am familiar with basic systems concepts

**Group 2 - Verstehen (Understand):**
- I understand how systems thinking applies to SE
- I can explain systems thinking principles
- I comprehend system boundaries and interfaces

**Group 3 - Anwenden (Apply):**
- I apply systems thinking in my daily work
- I use systems thinking to solve problems
- I can identify system interdependencies

**Group 4 - Beherrschen (Master):**
- I master systems thinking across complex domains
- I teach others about systems thinking
- I lead systems thinking initiatives

---

## Competency Area Distribution

```
Total: 16 competencies

Core:             4 competencies (25%)
Social/Personal:  3 competencies (19%)
Management:       4 competencies (25%)
Technical:        5 competencies (31%)
```

---

## Role-Competency Matrix Values

From `role_competency_matrix` table:

```sql
SELECT
  c.competency_name,
  rc.role_cluster_id,
  rc.role_competency_value,
  rc.organization_id
FROM role_competency_matrix rc
JOIN competency c ON rc.competency_id = c.id
WHERE rc.organization_id = [org_id]
ORDER BY rc.role_cluster_id, c.id;
```

**Possible values:** -100, 0, 1, 2, 3, 4, 6

**Meaning:**
- `-100` = Invalid/not set
- `0` = Not relevant for this role
- `1, 2, 4, 6` = Required competency level for this role

---

## Phase 2 Usage

### Task 1: Determine Necessary Competencies

**Query to get necessary competencies for selected roles:**

```sql
SELECT
  c.id,
  c.competency_name,
  c.competency_area,
  MAX(rcm.role_competency_value) as required_level
FROM competency c
JOIN role_competency_matrix rcm ON c.id = rcm.competency_id
WHERE rcm.role_cluster_id IN ([selected_role_ids])
  AND rcm.organization_id = [org_id]
  AND rcm.role_competency_value > 0  -- FILTER OUT IRRELEVANT
GROUP BY c.id, c.competency_name, c.competency_area
ORDER BY c.id;
```

### Task 2: Identify Competency Gaps

**For each necessary competency, ask the user:**

```
Question: To which of these groups do you identify yourself for [Competency Name]?

Options:
  Group 1: Know - [3 indicators]
  Group 2: Understand - [3 indicators]
  Group 3: Apply - [3 indicators]
  Group 4: Master - [3 indicators]
  Group 5: None of these

User selects: Groups [2, 3]
Score = MAX([2, 3]) = 3 → Mapped to score 4 (Apply)
```

**Gap Calculation:**

```python
gap = required_level - user_score

if gap > 0:
    status = "needs_improvement"
    priority = "high" if gap >= 2 else "medium"
elif gap == 0:
    status = "meets_requirement"
else:  # gap < 0
    status = "exceeds_requirement"
```

### Task 3: Learning Objectives

**Aggregate across all employees:**

```python
# For each competency:
avg_current_level = AVERAGE(user_scores for competency_id)
avg_required_level = AVERAGE(required_levels for competency_id)
avg_gap = avg_required_level - avg_current_level

# Prioritize competencies by:
1. Largest avg_gap (biggest deficiency)
2. Number of employees below requirement
3. Criticality (Core > Technical > Management > Social)
```

---

## API Endpoints Summary

### Get All Competencies
```
GET /competencies
Returns: All 16 competencies with details
```

### Get Competency Indicators
```
GET /get_competency_indicators_for_competency/<competency_id>
Returns: 4 levels × 3 indicators, grouped by level
```

### Get Required Competencies for Roles
```
POST /get_required_competencies_for_roles
Body: { role_ids, organization_id }
Returns: Competencies with required_level > 0
```

### Submit Competency Assessment
```
POST /submit_survey
Body: { competency_scores: [{competencyId, score}] }
Saves to: user_se_competency_survey_results
```

### Get Assessment Results
```
GET /get_user_competency_results
Params: username, organization_id
Returns: user_scores, max_scores, feedback_list
```

---

## Database Tables

### Core Tables:
- `competency` - 16 SE competencies
- `competency_indicators` - 192 indicators (16 × 4 × 3)

### Matrix Tables:
- `role_competency_matrix` - Role → Competency (org-specific)
- `role_process_matrix` - Role → Process (org-specific)
- `process_competency_matrix` - Process → Competency (global)

### Assessment Tables:
- `user_se_competency_survey_results` - Individual scores
- `user_competency_survey_feedback` - LLM feedback
- `competency_assessment` - Assessment instances (Phase 2)

---

## Quick Stats

```
Total Competencies:     16
Total Indicators:       192 (16 × 4 × 3)
Competency Areas:       4 (Core, Social, Management, Technical)
Competency Levels:      4 (Know, Understand, Apply, Master)
Level Score Values:     0, 1, 2, 4, 6
```

---

**Last Updated:** 2025-10-20
**Source:** Database `competency_assessment`
