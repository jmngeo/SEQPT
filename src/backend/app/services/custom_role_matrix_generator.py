"""
AI-powered custom role matrix generator service.
Generates role-process RACI values for custom roles using OpenAI with context awareness.

This service is used when an organization has custom roles (not mapped to SE clusters).
It generates appropriate RACI values (0-3) for all 30 SE processes while respecting
existing role assignments to maintain RACI validation rules.
"""

import os
import json
from typing import List, Dict, Any, Optional
from openai import OpenAI


class CustomRoleMatrixGenerator:
    """Service for generating RACI values for custom roles"""

    def __init__(self):
        """Initialize the service with OpenAI client"""
        self.client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        # Use gpt-4o-mini for cost-effective generation
        self.model = "gpt-4o-mini"

    def build_generation_prompt(self,
                                role_name: str,
                                role_description: str,
                                processes: List[Dict[str, Any]],
                                existing_matrix: Optional[Dict[int, Dict[int, int]]] = None,
                                existing_roles: Optional[List[Dict[str, Any]]] = None) -> str:
        """
        Build the prompt for OpenAI to generate RACI values for a custom role

        Args:
            role_name: Name of the custom role
            role_description: Description of what this role does
            processes: List of SE processes with id, name, description
            existing_matrix: Current matrix state {process_id: {role_id: raci_value}}
            existing_roles: List of existing roles {id, name, role_cluster}

        Returns:
            Formatted prompt string
        """

        # Format processes
        processes_text = "\n".join([
            f"{p['id']}. **{p['name']}**: {p.get('description', 'SE Process')}"
            for p in processes
        ])

        # Build context section if existing matrix is provided
        context_section = ""
        if existing_matrix and existing_roles:
            context_section = "\n\n## EXISTING ROLE ASSIGNMENTS (MUST RESPECT):\n\n"
            context_section += "The organization already has the following roles with assigned RACI values:\n\n"

            for process in processes:
                process_id = process['id']
                if process_id in existing_matrix:
                    context_section += f"### Process {process_id}: {process['name']}\n"

                    for role in existing_roles:
                        role_id = role['id']
                        if role_id in existing_matrix[process_id]:
                            raci_value = existing_matrix[process_id][role_id]
                            raci_label = self._get_raci_label(raci_value)
                            role_display = role.get('orgRoleName', role.get('role_name', f'Role {role_id}'))
                            cluster_info = f" (SE Cluster: {role.get('standardRoleName', 'N/A')})" if role.get('standardRoleName') else ""
                            context_section += f"  - {role_display}{cluster_info}: **{raci_value}** ({raci_label})\n"

                    context_section += "\n"

        prompt = f"""You are an expert in ISO/IEC 15288 Systems Engineering processes.

## TASK:
Analyze the provided CUSTOM ROLE and assign appropriate process involvement values for each of the 30 Systems Engineering processes.

## CUSTOM ROLE INFORMATION:
**Role Name**: {role_name}
**Role Description**: {role_description}

## SYSTEMS ENGINEERING PROCESSES:

{processes_text}

{context_section}

## PROCESS INVOLVEMENT SCALE:
- **0** = Not Involved - Role has no involvement in this process
- **1** = Supports - Role provides assistance, advice, or resources
- **2** = Performs/Executes - Role actively performs tasks in this process
- **3** = Leads/Designs - Role leads, designs, or has primary responsibility

## GUIDELINES:

1. **Analyze the role's typical responsibilities**:
   - What would this role realistically do in an SE organization?
   - Which processes align with this role's expertise and duties?

2. **Consider the existing role context** (if provided):
   - See what other roles are doing
   - Assign values that make sense alongside existing roles
   - Values complement but don't necessarily avoid overlap

3. **For non-SE roles** (e.g., Marketing, HR, Finance):
   - Most values should be 0 or 1
   - Only assign higher values if the role genuinely participates
   - Example: Marketing Manager might have value 1 for "Stakeholder Requirements Definition" but 0 for "Architecture Design"

4. **Be realistic and specific**:
   - Not every role is involved in every process
   - Assign 0 for processes completely outside this role's scope
   - Higher values (2-3) should reflect genuine involvement

## INSTRUCTIONS:

1. For each of the 30 processes, assign an involvement value (0-3) for this custom role
2. Provide a brief reasoning for your overall assignment strategy
3. Focus on what makes sense for this role, not strict validation rules
4. The user will review and adjust these values manually

## RESPONSE FORMAT (JSON):

Return ONLY valid JSON in this exact format (no markdown, no additional text):

{{
  "matrix": {{
    "1": 0,
    "2": 1,
    "3": 0,
    ...
    "30": 1
  }},
  "reasoning": "Brief explanation of the assignment strategy for this custom role and how it complements existing roles"
}}

IMPORTANT:
- Return ONLY valid JSON
- Include ALL 30 process IDs as keys (1-30)
- Values must be integers 0, 1, 2, or 3
- Ensure RACI rules are satisfied
- Process IDs are strings in the JSON object keys
"""

        return prompt

    def _get_raci_label(self, value: int) -> str:
        """Get human-readable RACI label"""
        labels = {
            0: "Not Involved",
            1: "Supports",
            2: "Responsible",
            3: "Accountable/Designs"
        }
        return labels.get(value, "Unknown")

    def generate_matrix_for_custom_role(self,
                                       role_name: str,
                                       role_description: str,
                                       processes: List[Dict[str, Any]],
                                       existing_matrix: Optional[Dict[int, Dict[int, int]]] = None,
                                       existing_roles: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """
        Generate RACI matrix values for a custom role using AI

        Args:
            role_name: Name of the custom role
            role_description: Description of the role
            processes: List of SE processes
            existing_matrix: Current matrix state (for context-aware generation)
            existing_roles: List of existing roles (for context-aware generation)

        Returns:
            {
                'success': True,
                'matrix': {
                    '1': 0,
                    '2': 1,
                    ...
                },
                'reasoning': '...',
                'validation': {
                    'passes_raci_rules': True,
                    'issues': []
                }
            }
        """

        prompt = self.build_generation_prompt(
            role_name,
            role_description,
            processes,
            existing_matrix,
            existing_roles
        )

        try:
            print(f"[INFO] Generating RACI matrix for custom role: {role_name}")

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert in Systems Engineering processes and RACI methodology. Always return valid JSON."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.3,  # Lower temperature for more deterministic results
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)

            # Validate the result
            if 'matrix' not in result:
                raise ValueError("AI response missing 'matrix' field")

            matrix = result['matrix']

            # Convert string keys to integers and validate
            validated_matrix = {}
            for process_id_str, raci_value in matrix.items():
                process_id = int(process_id_str)
                if not (0 <= raci_value <= 3):
                    print(f"[WARNING] Invalid RACI value {raci_value} for process {process_id}, setting to 0")
                    raci_value = 0
                validated_matrix[process_id] = raci_value

            # Ensure all processes are covered
            for process in processes:
                if process['id'] not in validated_matrix:
                    print(f"[WARNING] Missing process {process['id']}, setting to 0")
                    validated_matrix[process['id']] = 0

            print(f"[SUCCESS] Generated matrix for {role_name}")

            return {
                'success': True,
                'matrix': validated_matrix,
                'reasoning': result.get('reasoning', '')
            }

        except Exception as e:
            print(f"[ERROR] Matrix generation failed for {role_name}: {str(e)}")
            # Return all zeros as fallback
            fallback_matrix = {p['id']: 0 for p in processes}
            return {
                'success': False,
                'matrix': fallback_matrix,
                'reasoning': f'Error during AI generation: {str(e)}',
                'error': str(e)
            }

