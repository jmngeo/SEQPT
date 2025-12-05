# Learning Objectives Text Mapping Bug Analysis

**Date:** 2025-11-28
**Status:** FIXED (2025-11-28)
**Issue:** Agile Methods competency shows SysML diagram content (from System Architecting)

## FIX APPLIED

Changes made to `src/backend/app/services/learning_objectives_core.py`:

1. **Lowered LLM temperature** from 0.7 to 0.3 (both `customize_pmt_breakdown()` and `customize_objective_with_pmt()`)
2. **Updated prompts** with stricter constraints:
   - "CRITICAL CONSTRAINT: You MUST ONLY customize the exact text I provide"
   - "Do NOT include content about other competencies"
   - Added "unchanged" response option for when PMT doesn't apply
3. **Added validation functions**:
   - `_validate_text_relevance()` - Checks for cross-contamination keywords
   - `_validate_customization_relevance()` - Validates PMT breakdown customizations
   - `CROSS_CONTAMINATION_KEYWORDS` - Dictionary of forbidden keywords per competency
4. **Test script created**: `test_cross_contamination_fix.py` - All tests pass

---

---

## 1. THE PROBLEM

**Symptom**: For competency "Agile Methods" at Level 1, the generated LO text shows:
> "The participant knows various SysML diagram types including Requirements Diagram (REQ) for capturing requirements, Block Definition Diagram (BDD) for system structure, Internal Block Diagram (IBD) for internal connections, Activity Diagram (ACT) for workflows, and State Machine Diagram (STM) for discrete behavior, along with overall modeling best practices."

**Expected**: The template for Agile Methods Level 1 should show:
> "The participant knows the agile values and the relevant agile methods."

---

## 2. ROOT CAUSE ANALYSIS

### 2.1 Template File Analysis

I checked `se_qpt_learning_objectives_template_v2.json`:

**Agile Methods Level 1 in template**:
```json
"Agile Methods": {
  "1": {
    "unified": "The participant knows the agile values and the relevant agile methods.",
    "pmt_breakdown": {
      "method": "The participant knows the agile values and the relevant agile methods."
    }
  }
}
```

**System Architecting Level 1 in template** (contains SysML):
```json
"System Architecting": {
  "1": {
    "unified": "Participants know the purpose of architecture models and can categorize them...",
    "pmt_breakdown": {
      "process": "The participants know the purpose of architecture models...",
      "method": "The participant knows the various processes of system architecture...",
      "tool": "The participants know SysML and are able to understand simple representations."
    }
  }
}
```

**FINDING: The template files are CORRECT.** The SysML content is in System Architecting, not Agile Methods.

### 2.2 Code Flow Analysis

The LO generation flow is:

1. **`generate_learning_objectives()`** (learning_objectives_core.py:1449)
   - Iterates through `gaps_by_competency` dictionary
   - Uses `competency_id` as key
   - Gets `competency_name` from gap_data

2. **`get_template_objective_with_pmt()`** (learning_objectives_core.py:1728)
   - Takes `competency_name` as parameter
   - Looks up in `templates['learningObjectiveTemplates'][competency_name]`
   - Returns template text

3. **`customize_pmt_breakdown()`** (learning_objectives_core.py:1939) - IF PMT customization enabled
   - Takes `competency_name`, `level`, `pmt_breakdown`, and `pmt_context`
   - Calls LLM with **explicit competency name in prompt**

### 2.3 Possible Causes

**CAUSE 1: LLM Hallucination During PMT Customization** (MOST LIKELY)

When PMT customization is enabled, the LLM call at line 1571 (`customize_pmt_breakdown()`) could be:
- Hallucinating content from other competencies
- Not properly grounding output to the specific competency provided
- The prompt may not be strict enough about staying within the competency boundaries

The LLM prompt in `customize_pmt_breakdown()` includes:
```
Competency: {competency_name}
Level: {level} - {get_level_name(level)}

Original Learning Objective Sections:
{sections_text}
```

But the LLM may be:
1. Ignoring the competency name constraint
2. Pulling in content from its training data about SE (which includes SysML)
3. Not properly grounding to the PROVIDED template text

**CAUSE 2: Template Lookup Mismatch** (LESS LIKELY BUT POSSIBLE)

If `competency_name` in `gap_data` doesn't exactly match the template JSON key:
- "Agile Methods" vs "Agile Methodological Competence" vs "Agile methodological competence"
- Case sensitivity issues

However, I checked and the names should be consistent.

**CAUSE 3: Parallel Processing Race Condition** (UNLIKELY)

If multiple competencies are being customized in parallel (which they're not currently), there could be data mixing.

---

## 3. EVIDENCE SUPPORTING LLM HALLUCINATION

Looking at the symptom more closely:

1. The erroneous text mentions "SysML diagram types including Requirements Diagram (REQ)..."
2. This is EXACTLY the kind of content GPT would know about SE
3. SysML content is NOT in the Agile Methods template
4. The LLM is clearly not respecting the provided template text

The LLM model used is `gpt-4o-mini` with:
- `temperature=0.7` (relatively high, allows creativity/hallucination)
- `max_tokens=500`
- `timeout=15`

**Key Issue**: Temperature 0.7 is too high for strict template adherence.

---

## 4. WHY SPLITTING INTO INDIVIDUAL CALLS WON'T NECESSARILY HELP

Ulf suggested splitting bulk prompts into individual prompts per competency. However:

1. **The current code ALREADY makes individual calls** - one `customize_pmt_breakdown()` call per competency per level
2. The issue is NOT bulk processing - it's **LLM prompt engineering and temperature settings**

What we ACTUALLY need:
1. **Lower temperature** (0.3 or less) for more deterministic outputs
2. **Stricter prompt** that emphasizes staying within the provided template
3. **Output validation** that checks if the response contains irrelevant content
4. **Allow "no change" response** - if the PMT context doesn't match, return template unchanged

---

## 5. RECOMMENDED FIXES

### Fix 1: Lower LLM Temperature (QUICK FIX)

In `customize_pmt_breakdown()` at line 2039:
```python
# BEFORE:
temperature=0.7

# AFTER:
temperature=0.3  # More deterministic, less hallucination
```

### Fix 2: Stricter Prompt (IMPORTANT)

Update the prompt in `customize_pmt_breakdown()` to be more explicit:

```python
prompt = f"""You are an expert in Systems Engineering qualification planning.

CRITICAL CONSTRAINT: You MUST ONLY customize the text I provide. Do NOT add content from other SE competencies.

Your task: Adapt each section of the following learning objective breakdown to a specific company context.

Competency: {competency_name}
Level: {level} - {get_level_name(level)}

IMPORTANT: This is for the "{competency_name}" competency ONLY. Do not include content about other competencies.

Original Learning Objective Sections (KEEP THE CORE MEANING INTACT):
{sections_text}

Company Context (PMT):
- Processes: {org_processes}
- Methods: {org_methods}
- Tools: {org_tools}

Instructions:
1. ONLY modify text to incorporate company-specific tools/methods/processes
2. Keep the EXACT SAME competency scope as the original text
3. If no relevant company PMT applies, return the ORIGINAL TEXT UNCHANGED
4. Do NOT add content about SysML, requirements diagrams, or any other SE topic not in the original
5. Your response MUST be about "{competency_name}" only

Return ONLY valid JSON, nothing else.
"""
```

### Fix 3: Output Validation (SAFETY NET)

Add validation to detect when LLM hallucinates content from other competencies:

```python
def validate_customization_relevance(competency_name: str, original_text: str, customized_text: str) -> bool:
    """
    Check if customized text stays within competency boundaries.
    """
    # Keywords that indicate cross-contamination
    cross_contamination_keywords = {
        'Agile Methods': ['SysML', 'architecture model', 'BDD', 'IBD', 'REQ diagram'],
        'System Architecting': ['agile values', 'scrum', 'sprint'],
        'Requirements Definition': ['architecture model', 'test plan'],
        # Add more as needed
    }

    forbidden = cross_contamination_keywords.get(competency_name, [])
    for keyword in forbidden:
        if keyword.lower() in customized_text.lower():
            logger.warning(f"Cross-contamination detected: '{keyword}' in {competency_name}")
            return False

    return True
```

### Fix 4: Allow "No Change" Option

Update the LLM prompt to explicitly allow returning original text:

```python
# Add to prompt:
"""
If the company PMT context does not relate to this competency's content,
respond with exactly: {"unchanged": true}
"""

# Then in code:
if customized.get('unchanged'):
    return pmt_breakdown  # Return original
```

---

## 6. VERIFICATION STEPS

To verify the fix works:

1. **Check template file** - Verify `se_qpt_learning_objectives_template_v2.json` has correct content for each competency
2. **Run test** - Generate LOs for org with PMT context, specifically check:
   - Agile Methods
   - System Architecting
   - Requirements Definition
   - All other PMT-enabled competencies
3. **Compare** - Ensure generated text matches the template's competency scope
4. **Log analysis** - Add logging to track exactly what the LLM returns vs what we expect

---

## 7. IMMEDIATE ACTION ITEMS

1. **[QUICK]** Reduce temperature from 0.7 to 0.3 in `customize_pmt_breakdown()` and `customize_objective_with_pmt()`
2. **[IMPORTANT]** Update LLM prompts to be stricter about staying within competency scope
3. **[SAFETY]** Add output validation for cross-competency contamination
4. **[TEST]** Run comprehensive test of all 16 competencies to verify correct mapping

---

## 8. FILES TO MODIFY

1. `src/backend/app/services/learning_objectives_core.py`
   - Line 1939: `customize_pmt_breakdown()` - Update temperature and prompt
   - Line 1831: `customize_objective_with_pmt()` - Update temperature (if used)

2. `src/backend/app/services/learning_objectives_text_generator.py`
   - Line 293: `llm_deep_customize()` - Check if this is still used and update similarly

---

## 9. CONCLUSION

**Root Cause**: LLM hallucination during PMT customization due to:
1. Temperature too high (0.7)
2. Prompt not strict enough about staying within competency scope
3. No validation to catch cross-competency content contamination

**Solution**: NOT splitting into more API calls (already individual), but rather:
1. Lower temperature to 0.3
2. Stricter prompt engineering
3. Output validation
4. Allow "no change" response option

**Impact**: Minimal code changes required. No architectural changes needed.

---

*Analysis completed: 2025-11-28*
