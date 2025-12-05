"""
Learning Objectives Text Generator - Phase 2 Task 3 Step 8
==========================================================

Generates actual learning objective text from templates with optional PMT customization.

CRITICAL: This is Phase 2 - PMT-only customization (capability statements)
NOT Phase 3 - which adds timeframes, demonstrations, and benefits

Phase 2 Output Example:
"Participants are able to prepare decisions for their relevant scopes using JIRA
decision logs and document the decision-making process according to ISO 26262 requirements."

Phase 3 Will Add (Not Now):
- Timeframes: "At the end of the 2-day workshop..."
- Demonstrations: "by conducting trade-off analyses..."
- Benefits: "so that all decisions are traceable..."

Date: November 4, 2025
Status: Production-Ready
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Union
import logging
from openai import OpenAI

logger = logging.getLogger(__name__)

# Template file path (v2 with PMT breakdown structure)
# Supports both Docker deployment and local development
_current_file = Path(__file__).resolve()
_backend_root = _current_file.parent.parent.parent  # services -> app -> backend

def _get_template_path():
    """
    Get path to LO template file.

    Path resolution order:
    1. Local to backend (Docker): src/backend/data/templates/se_qpt_learning_objectives_template_v2.json
    2. Project root (Local dev): data/source/Phase 2/se_qpt_learning_objectives_template_v2.json
    """
    # Path 1: Docker path (template inside backend)
    docker_path = _backend_root / 'data' / 'templates' / 'se_qpt_learning_objectives_template_v2.json'
    if docker_path.exists():
        return docker_path

    # Path 2: Local dev path (template at project root)
    project_root = _backend_root.parent.parent  # backend -> src -> project_root
    dev_path = project_root / 'data' / 'source' / 'Phase 2' / 'se_qpt_learning_objectives_template_v2.json'
    if dev_path.exists():
        return dev_path

    # Return Docker path as default (will show appropriate error if missing)
    return docker_path

TEMPLATE_PATH = _get_template_path()

# Strategies requiring deep customization with PMT (use normalized canonical names)
DEEP_CUSTOMIZATION_STRATEGIES = [
    'Needs-based, project-oriented training',  # Canonical name from template JSON
    'Continuous support'  # Canonical name from template JSON
]

# Core competencies that cannot be directly trained
CORE_COMPETENCIES = [1, 4, 5, 6]

# Strategy name normalization map
# Maps database variations → template JSON canonical names
STRATEGY_NAME_MAP = {
    # Exact matches (pass through)
    "Common basic understanding": "Common basic understanding",
    "SE for managers": "SE for managers",
    "Orientation in pilot project": "Orientation in pilot project",
    "Needs-based, project-oriented training": "Needs-based, project-oriented training",
    "Continuous support": "Continuous support",
    "Train the trainer": "Train the trainer",
    "Certification": "Certification",

    # Capitalization variations
    "Common Basic Understanding": "Common basic understanding",
    "SE for Managers": "SE for managers",
    "Orientation in Pilot Project": "Orientation in pilot project",
    "Continuous Support": "Continuous support",
    "Train the Trainer": "Train the trainer",

    # Punctuation variations
    "Needs-based Project-oriented Training": "Needs-based, project-oriented training",
    "Needs-based project-oriented training": "Needs-based, project-oriented training",

    # Wording variations
    "Train the SE-Trainer": "Train the trainer",
    "Train the SE-trainer": "Train the trainer",
}


def normalize_strategy_name(strategy_name: str) -> str:
    """
    Normalize strategy name to match template JSON canonical names.

    Handles:
    - Capitalization differences
    - Punctuation variations (comma vs no comma)
    - Wording differences (e.g., "Train the SE-Trainer" → "Train the trainer")

    Args:
        strategy_name: Strategy name from database

    Returns:
        Normalized strategy name matching template JSON, or original if no mapping found
    """
    # Try exact match first
    if strategy_name in STRATEGY_NAME_MAP:
        normalized = STRATEGY_NAME_MAP[strategy_name]
        logger.debug(f"[Normalize] '{strategy_name}' → '{normalized}'")
        return normalized

    # Fallback: return original (will log warning if template lookup fails)
    logger.warning(f"[Normalize] No mapping for strategy '{strategy_name}' - using as-is")
    return strategy_name


# ============================================================================
# Competency ID to Name Mapping
# ============================================================================

COMPETENCY_ID_TO_NAME = {
    1: "Systems Thinking",
    4: "Lifecycle Consideration",
    5: "Customer / Value Orientation",
    6: "Systems Modelling and Analysis",
    7: "Communication",
    8: "Leadership",
    9: "Self-Organization",
    10: "Project Management",
    11: "Decision Management",
    12: "Information Management",
    13: "Configuration Management",
    14: "Requirements Definition",
    15: "System Architecting",
    16: "Integration, Verification, Validation",
    17: "Operation and Support",
    18: "Agile Methods"
}


# ============================================================================
# Template Loading
# ============================================================================

def load_learning_objective_templates() -> Dict:
    """
    Load learning objective templates from JSON file

    Returns:
        Dict with keys:
        - archetypeCompetencyTargetLevels
        - learningObjectiveTemplates
        - competencies
        - metadata
    """
    if not TEMPLATE_PATH.exists():
        logger.error(f"Template file not found: {TEMPLATE_PATH}")
        raise FileNotFoundError(f"Template file not found: {TEMPLATE_PATH}")

    with open(TEMPLATE_PATH, 'r', encoding='utf-8') as f:
        templates = json.load(f)

    logger.info(f"[OK] Loaded learning objective templates from {TEMPLATE_PATH}")
    return templates


# ============================================================================
# Template Retrieval Functions
# ============================================================================

def get_template_objective(competency_id: int, level: int) -> str:
    """
    Get template text for competency at specific level
    Returns string only (unified text, no PMT breakdown)

    Args:
        competency_id: Competency ID (1-18, note: gaps at 2,3)
        level: Competency level (0, 1, 2, 4, 6)

    Returns:
        Template text string

    Note:
        Template v2 format supports both:
        - Simple string: "The participant knows..."
        - Dict with PMT: {"unified": "...", "pmt_breakdown": {...}}

        This function returns the unified/simple text for backward compatibility.
        Use get_template_objective_full() to get full PMT breakdown.
    """
    templates = load_learning_objective_templates()

    competency_name = COMPETENCY_ID_TO_NAME.get(competency_id)
    if not competency_name:
        logger.warning(f"Unknown competency ID: {competency_id}")
        return f"[Template missing - unknown competency ID: {competency_id}]"

    if competency_name not in templates['learningObjectiveTemplates']:
        logger.warning(f"No templates found for competency: {competency_name}")
        return f"[Template missing for {competency_name}]"

    level_str = str(level)
    template_data = templates['learningObjectiveTemplates'][competency_name].get(level_str)

    if template_data is None:
        logger.warning(f"No template for {competency_name} level {level}")
        return f"[Template missing for {competency_name} level {level}]"

    # Handle both string templates and dict templates (with PMT breakdown)
    if isinstance(template_data, dict):
        # v2 format uses 'unified' key, fallback to 'base_template' for older format
        return template_data.get('unified', template_data.get('base_template', '[Template structure error]'))
    else:
        return template_data


def get_template_objective_full(competency_id: int, level: int) -> Dict:
    """
    Get full template data with PMT breakdown (v2 format)

    Args:
        competency_id: Competency ID (1-18)
        level: Competency level (0, 1, 2, 4, 6)

    Returns:
        Dict with structure:
        {
            'objective_text': str,  # Unified text
            'has_pmt': bool,        # Whether PMT breakdown exists
            'pmt_breakdown': {      # Only present if has_pmt is True
                'process': str or None,
                'method': str or None,
                'tool': str or None
            }
        }
    """
    templates = load_learning_objective_templates()

    result = {
        'objective_text': None,
        'has_pmt': False,
        'pmt_breakdown': None
    }

    competency_name = COMPETENCY_ID_TO_NAME.get(competency_id)
    if not competency_name:
        result['objective_text'] = "[Template missing]"
        return result

    if competency_name not in templates['learningObjectiveTemplates']:
        result['objective_text'] = "[Template missing]"
        return result

    level_str = str(level)
    template_data = templates['learningObjectiveTemplates'][competency_name].get(level_str)

    if template_data is None:
        result['objective_text'] = "[Template missing]"
        return result

    # Handle both string and dict (with PMT breakdown) formats
    if isinstance(template_data, dict):
        # v2 format uses 'unified' key
        result['objective_text'] = template_data.get('unified', template_data.get('base_template', ''))
        if 'pmt_breakdown' in template_data:
            result['has_pmt'] = True
            result['pmt_breakdown'] = template_data['pmt_breakdown']
    else:
        result['objective_text'] = template_data

    return result


def get_archetype_targets_for_strategy(strategy_name: str) -> Dict[str, int]:
    """
    Get competency target levels for a specific strategy

    Args:
        strategy_name: Strategy name (e.g., "SE for managers")

    Returns:
        Dict mapping competency name → target level
    """
    templates = load_learning_objective_templates()

    # Normalize strategy name to match template JSON canonical names
    normalized_name = normalize_strategy_name(strategy_name)

    # Try exact match with normalized name
    if normalized_name in templates['archetypeCompetencyTargetLevels']:
        logger.debug(f"[get_archetype_targets] Found targets for '{normalized_name}'")
        return templates['archetypeCompetencyTargetLevels'][normalized_name]

    # Fallback: Try case-insensitive match (should not be needed after normalization)
    for key in templates['archetypeCompetencyTargetLevels'].keys():
        if key.lower() == normalized_name.lower():
            logger.debug(f"[get_archetype_targets] Found targets for '{key}' (case-insensitive)")
            return templates['archetypeCompetencyTargetLevels'][key]

    logger.warning(f"No archetype targets found for strategy: {strategy_name} (normalized: {normalized_name})")
    return {}


# ============================================================================
# PMT-Only LLM Customization (Phase 2)
# ============================================================================

def llm_deep_customize(
    template: str,
    pmt_context,  # PMTContext model instance
    current_level: int,
    target_level: int,
    competency_id: int,
    pmt_breakdown: Optional[Dict] = None
) -> str:
    """
    PMT-only customization for Phase 2 (Simplified)

    IMPORTANT: This is Phase 2 - we only add company-specific PMT references.
    Phase 3 (after module selection) will add:
    - Timeframes ("At the end of the 2-day workshop...")
    - Demonstration methods ("by conducting a simulation...")
    - Benefit statements ("so that they can...")

    This function ONLY:
    - Replaces generic tool/process names with company-specific ones
    - Keeps template structure exactly
    - Maintains capability statement format

    Args:
        template: Base template text
        pmt_context: PMTContext model instance with processes, methods, tools
        current_level: Current competency level
        target_level: Target competency level
        competency_id: Competency ID
        pmt_breakdown: Optional PMT breakdown from template

    Returns:
        Customized learning objective text (Phase 2 format only)
    """
    # Check if PMT context is complete
    if not pmt_context or not pmt_context.is_complete():
        logger.warning(f"PMT context incomplete or missing, returning template as-is. Context: {pmt_context}")
        return template

    logger.info(f"[LLM Deep Customize] PMT context is complete. Processes: {len(pmt_context.processes or '')} chars, Tools: {len(pmt_context.tools or '')} chars")

    # Build PMT context string
    pmt_text = f"""
Company Context:
- Tools: {pmt_context.tools or 'Not specified'}
- Processes: {pmt_context.processes or 'Not specified'}
- Methods: {pmt_context.methods or 'Not specified'}
- Industry: {pmt_context.industry or 'Not specified'}
"""

    # Build PMT breakdown context if available
    pmt_breakdown_text = ""
    if pmt_breakdown:
        pmt_breakdown_text = f"""
Expected PMT Coverage (from template):
- Process: {pmt_breakdown.get('process', 'N/A')}
- Method: {pmt_breakdown.get('method', 'N/A')}
- Tool: {pmt_breakdown.get('tool', 'N/A')}
"""

    competency_name = COMPETENCY_ID_TO_NAME.get(competency_id, f"Competency {competency_id}")

    # Simplified LLM Prompt (Phase 2 only)
    prompt = f"""
You are customizing a Systems Engineering learning objective for Phase 2.

Base Template:
{template}

Competency: {competency_name}
Target Level: {target_level}

{pmt_text}

{pmt_breakdown_text}

Instructions (CRITICAL - follow exactly):
1. KEEP the template structure exactly (do not change sentence structure)
2. REPLACE generic tool/process names with company-specific ones from the context
3. DO NOT add timeframes (e.g., "At the end of...")
4. DO NOT add "so that" benefit statements
5. DO NOT add "by doing X" demonstration methods
6. Keep it as a capability statement (what participants can do)
7. Maximum 2 sentences
8. If no relevant PMT to add, return the template unchanged

Example:
Original: "Participants are able to manage requirements using a requirements database."
Customized: "Participants are able to manage requirements using DOORS according to ISO 29148 process."

Generate the PMT-customized objective (template structure only):
"""

    try:
        # Get OpenAI API key
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            logger.warning("OpenAI API key not found, returning template as-is")
            return template

        # Call LLM API
        client = OpenAI(api_key=api_key)

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are an SE training expert. Customize learning objectives with company context while maintaining template structure."
                },
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=200
        )

        customized_text = response.choices[0].message.content.strip()

        # Validate response maintains template structure (no Phase 3 elements)
        if not validate_phase2_format(customized_text):
            logger.warning(
                f"LLM output contains Phase 3 elements, falling back to template. "
                f"Output: {customized_text[:100]}..."
            )
            return template

        logger.info(f"[OK] Deep customization completed for competency {competency_id}")
        return customized_text

    except Exception as e:
        logger.error(f"LLM customization failed: {str(e)}, returning template as-is")
        return template


def validate_phase2_format(text: str) -> bool:
    """
    Validate that customization maintained template structure
    (Only PMT names changed, no timeframes/benefits added)

    Args:
        text: Customized learning objective text

    Returns:
        True if valid Phase 2 format, False if Phase 3 elements detected
    """
    # Must have reasonable length
    if len(text) < 30 or len(text) > 500:
        logger.warning(f"Text length invalid: {len(text)} characters")
        return False

    # Should contain action verbs from template
    action_verbs = ['able to', 'can', 'will', 'understand', 'know', 'apply',
                    'demonstrate', 'evaluate', 'learn', 'participants']
    if not any(verb in text.lower() for verb in action_verbs):
        logger.warning("No action verbs found in text")
        return False

    # Should NOT have Phase 3 elements
    phase_3_indicators = [
        'at the end of',
        'so that',
        'in order to',
        'by conducting',
        'by creating',
        'by performing',
        'by doing',
        'after the workshop',
        'upon completion'
    ]

    for indicator in phase_3_indicators:
        if indicator in text.lower():
            logger.warning(f"Phase 3 indicator detected: '{indicator}'")
            return False  # LLM added Phase 3 elements - reject

    return True


# ============================================================================
# Core Competency Handling
# ============================================================================

def get_core_competency_note(competency_id: int) -> str:
    """
    Get informational note for core competencies

    Core competencies (1, 4, 5, 6) develop more indirectly through practice
    in other competencies. This note provides educational context to users.

    Args:
        competency_id: Competency ID

    Returns:
        Informational note string, or None if not a core competency
    """
    if competency_id not in CORE_COMPETENCIES:
        return None

    return (
        "This core competency develops indirectly through training in other competencies. "
        "It will be strengthened through practice in requirements definition, system architecting, "
        "integration, and other technical activities."
    )


def generate_core_competency_objective(
    competency_id: int,
    target_level: int
) -> Dict:
    """
    DEPRECATED: This function is kept for backward compatibility only.

    Core competencies are now processed like all other competencies.
    Use get_core_competency_note() to get the informational note.

    Args:
        competency_id: Core competency ID
        target_level: Target level from strategy

    Returns:
        Dict with competency info and note about indirect development
    """
    competency_name = COMPETENCY_ID_TO_NAME.get(competency_id, f"Competency {competency_id}")

    # Generic note for all core competencies
    note = get_core_competency_note(competency_id)

    # Get template for display purposes
    template_text = get_template_objective(competency_id, target_level)

    return {
        'competency_id': competency_id,
        'competency_name': competency_name,
        'target_level': target_level,
        'status': 'not_directly_trainable',
        'note': note,
        'reference_objective': template_text  # For context only
    }


# ============================================================================
# Helper Functions
# ============================================================================

def check_if_strategy_needs_pmt(strategy_name: str) -> bool:
    """
    Check if a strategy requires PMT context for deep customization

    Args:
        strategy_name: Strategy name (will be normalized before checking)

    Returns:
        True if strategy needs PMT, False otherwise
    """
    # Normalize name before checking
    normalized_name = normalize_strategy_name(strategy_name)
    needs_pmt = normalized_name in DEEP_CUSTOMIZATION_STRATEGIES
    logger.debug(f"[check_if_strategy_needs_pmt] '{strategy_name}' (normalized: '{normalized_name}') → {needs_pmt}")
    return needs_pmt


def get_competency_name(competency_id: int) -> str:
    """
    Get competency name from ID

    Args:
        competency_id: Competency ID (1-18)

    Returns:
        Competency name string
    """
    return COMPETENCY_ID_TO_NAME.get(competency_id, f"Competency {competency_id}")


# ============================================================================
# Testing Function
# ============================================================================

def test_text_generation():
    """Test text generation with sample data"""
    print("=" * 70)
    print("Testing Learning Objectives Text Generator")
    print("=" * 70)

    # Test 1: Load templates
    print("\n[TEST 1] Loading templates...")
    try:
        templates = load_learning_objective_templates()
        print(f"[OK] Loaded {len(templates['learningObjectiveTemplates'])} competencies")
    except Exception as e:
        print(f"[ERROR] Failed to load templates: {e}")
        return

    # Test 2: Get simple template
    print("\n[TEST 2] Get simple template...")
    text = get_template_objective(11, 4)  # Decision Management, level 4
    print(f"[OK] Template: {text[:80]}...")

    # Test 3: Get full template with PMT breakdown
    print("\n[TEST 3] Get full template with PMT breakdown...")
    full_template = get_template_objective_full(14, 4)  # Requirements Definition, level 4
    if isinstance(full_template, dict):
        print(f"[OK] Has PMT breakdown: {list(full_template.get('pmt_breakdown', {}).keys())}")
    else:
        print(f"[OK] Simple template (no PMT breakdown)")

    # Test 4: Validate Phase 2 format
    print("\n[TEST 4] Validate Phase 2 format...")
    valid_text = "Participants are able to prepare decisions using JIRA."
    invalid_text = "At the end of the workshop, participants are able to..."

    assert validate_phase2_format(valid_text) == True, "Valid text rejected"
    assert validate_phase2_format(invalid_text) == False, "Invalid text accepted"
    print("[OK] Format validation working")

    # Test 5: Core competency
    print("\n[TEST 5] Generate core competency objective...")
    core_obj = generate_core_competency_objective(1, 4)  # Systems Thinking
    print(f"[OK] Core competency: {core_obj['competency_name']}")
    print(f"     Status: {core_obj['status']}")

    print("\n" + "=" * 70)
    print("[SUCCESS] All tests passed!")
    print("=" * 70)


if __name__ == '__main__':
    test_text_generation()
