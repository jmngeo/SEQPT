"""
Learning Objectives Generator
Generates SMART learning objectives based on:
- Qualification archetype (target level)
- Competency gaps (current vs target)
- Company context (PMT - Processes, Methods, Tools)
- Derik's competency framework
"""

import json
import os
from pathlib import Path
from openai import OpenAI
from typing import Dict, List, Optional

# Load archetype matrix
ARCHETYPE_MATRIX_PATH = Path(__file__).parent.parent.parent.parent / 'data' / 'processed' / 'archetype_competency_matrix.json'
GUIDELINES_PATH = Path(__file__).parent.parent.parent.parent / 'data' / 'source' / 'templates' / 'learning_objectives_guidelines.json'

class LearningObjectivesGenerator:
    """
    Generate SMART learning objectives using RAG-LLM
    """

    def __init__(self, openai_api_key: Optional[str] = None):
        """Initialize with OpenAI API key"""
        self.api_key = openai_api_key or os.getenv('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("OpenAI API key required")

        self.client = OpenAI(api_key=self.api_key)

        # Load archetype matrix
        with open(ARCHETYPE_MATRIX_PATH, 'r', encoding='utf-8') as f:
            self.archetype_data = json.load(f)

        # Load learning objectives guidelines
        with open(GUIDELINES_PATH, 'r', encoding='utf-8') as f:
            self.guidelines = json.load(f)

    def get_archetype_target_level(self, archetype_name: str, competency_id: int) -> int:
        """Get target level for a competency in given archetype"""
        archetype = self.archetype_data['archetypes'].get(archetype_name, {})
        levels = archetype.get('competency_levels', {})
        return levels.get(str(competency_id), 0)

    def get_competency_name(self, competency_id: int) -> str:
        """Get competency name from ID"""
        return self.archetype_data['competency_names'].get(str(competency_id), f'Competency {competency_id}')

    def build_system_prompt(self) -> str:
        """Build the system prompt for learning objectives generation"""
        return f"""You are an expert Systems Engineering educator and instructional designer specializing in creating SMART learning objectives.

**Your Task:**
Generate SMART learning objectives for SE competency development based on:
1. The learner's qualification archetype (learning strategy)
2. Competency gaps (current level vs target level)
3. Company-specific context (processes, methods, tools)

**SMART Criteria:**
{json.dumps(self.guidelines['smart_criteria'], indent=2)}

**Formulation Guidelines:**
{json.dumps(self.guidelines['formulation_guidelines'], indent=2)}

**Structure Template:**
{json.dumps(self.guidelines['structure_template'], indent=2)}

**Action Verbs by Level:**
{json.dumps(self.guidelines['action_verbs_by_level'], indent=2)}

**Critical Requirements:**
1. MUST be formulated positively
2. MUST include measurability through "by" statements
3. MUST include benefit through "so that" or "in order to"
4. MUST reference specific SE processes, methods, or tools (PMT)
5. MUST align with the competency level and archetype strategy
6. MUST follow the timeframe conventions of the archetype

**Example:**
{self.guidelines['example_complete']['full_objective']}
"""

    def build_user_prompt(
        self,
        competency_id: int,
        current_level: int,
        target_level: int,
        archetype_name: str,
        company_context: Optional[Dict] = None
    ) -> str:
        """Build user prompt for specific learning objective generation"""

        competency_name = self.get_competency_name(competency_id)
        archetype = self.archetype_data['archetypes'][archetype_name]

        # Get company context
        pmt_context = ""
        if company_context:
            processes = company_context.get('processes', [])
            methods = company_context.get('methods', [])
            tools = company_context.get('tools', [])

            if processes:
                pmt_context += f"\n**Company Processes:** {', '.join(processes)}"
            if methods:
                pmt_context += f"\n**Company Methods:** {', '.join(methods)}"
            if tools:
                pmt_context += f"\n**Company Tools:** {', '.join(tools)}"

        prompt = f"""Generate a SMART learning objective for the following scenario:

**Competency:** {competency_name} (ID: {competency_id})
**Current Level:** {current_level} - {self._get_level_description(current_level)}
**Target Level:** {target_level} - {self._get_level_description(target_level)}
**Gap:** {target_level - current_level} level(s) to bridge

**Qualification Archetype:** {archetype_name}
**Archetype Description:** {archetype['description']}
**Target Audience:** {archetype['target_audience']}
**Typical Duration:** {archetype['duration_weeks']}
{pmt_context}

**Required Output Format:**
Return a JSON object with the following structure:
{{
  "competency_id": {competency_id},
  "competency_name": "{competency_name}",
  "archetype": "{archetype_name}",
  "current_level": {current_level},
  "target_level": {target_level},
  "learning_objective": {{
    "timeframe": "At the end of...",
    "knowledge_statement": "participants [verb] [content]",
    "demonstration": "by [observable action]",
    "benefit": "so that [outcome]",
    "full_text": "Complete SMART objective combining all parts"
  }},
  "suggested_duration": "X weeks/days",
  "key_topics": ["topic1", "topic2", "topic3"],
  "assessment_methods": ["method1", "method2"],
  "pmt_references": {{
    "processes": ["process1", "process2"],
    "methods": ["method1", "method2"],
    "tools": ["tool1", "tool2"]
  }}
}}

Ensure the objective is specific to the competency gap and archetype strategy.
"""
        return prompt

    def _get_level_description(self, level: int) -> str:
        """Get description for competency level"""
        descriptions = self.archetype_data['metadata']['level_scale']
        return descriptions.get(str(level), "Unknown level")

    def generate_learning_objective(
        self,
        competency_id: int,
        current_level: int,
        target_level: int,
        archetype_name: str,
        company_context: Optional[Dict] = None,
        temperature: float = 0.7
    ) -> Dict:
        """
        Generate a single SMART learning objective

        Args:
            competency_id: Derik's competency ID (1-18)
            current_level: Current competency level (0-5)
            target_level: Target competency level (0-5)
            archetype_name: Qualification archetype name
            company_context: Optional dict with 'processes', 'methods', 'tools'
            temperature: LLM temperature (0-1)

        Returns:
            Dict containing the generated learning objective
        """

        if target_level <= current_level:
            return {
                'error': 'Target level must be higher than current level',
                'competency_id': competency_id,
                'current_level': current_level,
                'target_level': target_level
            }

        system_prompt = self.build_system_prompt()
        user_prompt = self.build_user_prompt(
            competency_id,
            current_level,
            target_level,
            archetype_name,
            company_context
        )

        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=temperature,
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)
            result['generation_metadata'] = {
                'model': 'gpt-4o-mini',
                'temperature': temperature,
                'tokens_used': response.usage.total_tokens
            }

            return result

        except Exception as e:
            return {
                'error': f'Generation failed: {str(e)}',
                'competency_id': competency_id,
                'current_level': current_level,
                'target_level': target_level
            }

    def generate_archetype_learning_plan(
        self,
        archetype_name: str,
        competency_gaps: Dict[int, tuple],  # {competency_id: (current, target)}
        company_context: Optional[Dict] = None
    ) -> Dict:
        """
        Generate complete learning plan for an archetype with multiple competency gaps

        Args:
            archetype_name: Qualification archetype name
            competency_gaps: Dict mapping competency_id to (current_level, target_level)
            company_context: Optional company PMT context

        Returns:
            Dict containing full learning plan with objectives for all gaps
        """

        learning_plan = {
            'archetype': archetype_name,
            'archetype_info': self.archetype_data['archetypes'][archetype_name],
            'total_gaps': len(competency_gaps),
            'learning_objectives': [],
            'summary': {
                'total_competencies': len(competency_gaps),
                'estimated_duration': self._estimate_total_duration(competency_gaps, archetype_name),
                'priority_order': []
            }
        }

        # Generate objectives for each gap
        for comp_id, (current, target) in competency_gaps.items():
            if target > current:  # Only generate if there's a gap
                objective = self.generate_learning_objective(
                    comp_id,
                    current,
                    target,
                    archetype_name,
                    company_context
                )
                learning_plan['learning_objectives'].append(objective)
                learning_plan['summary']['priority_order'].append({
                    'competency_id': comp_id,
                    'competency_name': self.get_competency_name(comp_id),
                    'gap_size': target - current,
                    'priority': self._calculate_priority(comp_id, target - current, archetype_name)
                })

        # Sort by priority
        learning_plan['summary']['priority_order'].sort(
            key=lambda x: x['priority'],
            reverse=True
        )

        return learning_plan

    def _estimate_total_duration(self, gaps: Dict[int, tuple], archetype: str) -> str:
        """Estimate total duration based on gaps and archetype"""
        total_gap = sum(target - current for current, target in gaps.values())
        base_duration = self.archetype_data['archetypes'][archetype]['duration_weeks']

        # Parse duration string
        if 'Variable' in base_duration or 'Continuous' in base_duration:
            return base_duration

        # Extract weeks
        weeks = int(base_duration.split('-')[0])
        adjusted_weeks = weeks + (total_gap * 2)  # Rough estimate: 2 weeks per gap level

        return f"{adjusted_weeks}-{adjusted_weeks + 4} weeks"

    def _calculate_priority(self, comp_id: int, gap_size: int, archetype: str) -> int:
        """Calculate priority score for a competency gap"""
        # Higher gap = higher priority
        priority = gap_size * 10

        # Core competencies get bonus
        comp_name = self.get_competency_name(comp_id)
        core_competencies = ['Systems Thinking', 'Requirements Definition', 'System Architecting']
        if comp_name in core_competencies:
            priority += 20

        # Archetype-specific adjustments
        if archetype == 'SE for Managers':
            management_comps = ['Leadership', 'Project Management', 'Decision Management']
            if comp_name in management_comps:
                priority += 15

        return priority


# Example usage and testing
if __name__ == '__main__':
    # Test the generator
    generator = LearningObjectivesGenerator()

    # Example: Generate objective for Systems Thinking gap
    result = generator.generate_learning_objective(
        competency_id=1,  # Systems Thinking
        current_level=1,  # Awareness
        target_level=3,   # Intermediate
        archetype_name='Orientation in Pilot Project',
        company_context={
            'processes': ['Agile Development', 'Requirements Management', 'V-Model'],
            'methods': ['Use Cases', 'User Stories', 'System Modeling (SysML)'],
            'tools': ['DOORS', 'Enterprise Architect', 'JIRA']
        }
    )

    print("Generated Learning Objective:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
