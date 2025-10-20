# rank_competency_indicators_llm.py

from app.models import CompetencyIndicator
from openai import AzureOpenAI
import json
from pydantic import BaseModel, Field
from langchain.prompts import ChatPromptTemplate
from langchain_openai import AzureChatOpenAI
from flask import current_app

# --- LLM Initialization and Indicator Ranking ---

# --- LLM Output Validation ---
class RankedIndicator(BaseModel):
    indicator: str = Field(..., description="The indicator being ranked.")
    rank: int = Field(..., description="The rank of the indicator.")

class CompetencyLevelRanking(BaseModel):
    level: str = Field(..., description="The level for which indicators are ranked.")
    ranked_indicators: list[RankedIndicator] = Field(..., description="List of ranked indicators for the level.")

class RankedIndicatorsResponse(BaseModel):
    competency_id: int = Field(..., description="The competency ID.")
    competency_name: str = Field(..., description="The competency name.")
    competency_levels: list[CompetencyLevelRanking] = Field(..., description="List of levels with ranked indicators.")

    def to_json(self):
        return self.dict()

def init_llm():
    azure_endpoint = "https://llmopenaidr.openai.azure.com/"
    api_key = "c6359d2f805b4915b212ed38d2259c0d"
    return AzureChatOpenAI(
        model="gpt-4",
        openai_api_key=api_key,
        azure_endpoint=azure_endpoint,
        api_version="2024-02-01",
        temperature=0.5
    )

def create_ranking_chain(llm):
    # Modify the prompt to handle multiple levels for each competency and request only top 3 indicators
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are an expert at ranking relevant Systems Engineering competency indicators based on the user's tasks and responsibilities."),
        ("user", """
        The user has the following tasks and responsibilities:
        {tasks}

        Below is a competency that requires ranking. For each level, return only the **top 3** indicators that are most relevant for performing the user's tasks and responsibilities and rank them from 1 to 3, where 1 being the most relevant.

        Competency:
        - Name: {competency_name}
        - Levels and Indicators:
        {competency_levels}
        """)
    ])
    structured_llm = llm.with_structured_output(RankedIndicatorsResponse)
    return prompt | structured_llm


def rank_indicators_with_llm(tasks, competency):
    llm = init_llm()
    ranking_chain = create_ranking_chain(llm)

    # Prepare the formatted competency levels for LLM input
    levels = [
        {
            "level": level,
            "indicators": indicators
        }
        for level, indicators in competency["competency_levels"].items()
    ]

    inputs = {
        "tasks": tasks,
        "competency_name": competency["competency_name"],
        "competency_levels": json.dumps(levels, indent=2)
    }
    print("LLM inputs:",inputs)
    ranked_result = ranking_chain.invoke(inputs)
    return ranked_result.to_json()

# --- SQLAlchemy Integration for Competency Indicators ---
def get_competency_indicators_with_sqlalchemy(competency_ids):
    try:
        competency_indicators = CompetencyIndicator.query.filter(
            CompetencyIndicator.competency_id.in_(competency_ids)
        ).order_by(CompetencyIndicator.competency_id, CompetencyIndicator.level).all()

        competency_data = {}
        for indicator in competency_indicators:
            if indicator.competency_id not in competency_data:
                competency_data[indicator.competency_id] = {"competency_name": indicator.competency.competency_name, "levels": {}}
            if indicator.level not in competency_data[indicator.competency_id]["levels"]:
                competency_data[indicator.competency_id]["levels"][indicator.level] = []
            competency_data[indicator.competency_id]["levels"][indicator.level].append(indicator.indicator)

        return competency_data

    except Exception as e:
        current_app.logger.error(f"Error querying competency indicators: {e}")
        return None

def process_user_tasks_and_competencies(tasks, competencies):
    competency_data = get_competency_indicators_with_sqlalchemy(competencies)

    if competency_data is None:
        print("Failed to retrieve competency data.")
        return None

    final_output = []
    count=0
    # Iterate over each competency to prepare consolidated data for LLM processing
    for competency_id, competency_info in competency_data.items():
        competency_name = competency_info["competency_name"]
        levels = competency_info["levels"]

        # Create a combined prompt for the LLM to rank indicators for all levels of this competency
        prompt_data = {
            "competency_id": competency_id,
            "competency_name": competency_name,
            "competency_levels": levels
        }

        # Call the LLM for the entire competency
        ranked_json = rank_indicators_with_llm(tasks, prompt_data)

        if ranked_json and "competency_levels" in ranked_json:
            # Ensure that only the top 3 indicators are returned (LLM should do this, but adding as a safeguard)
            for level_data in ranked_json["competency_levels"]:
                level_data["ranked_indicators"] = level_data["ranked_indicators"][:3]

            final_output.append({
                "competency_id": competency_id,
                "competency_name": competency_name,
                "competency_levels": ranked_json["competency_levels"]
            })
        else:
            final_output.append({
                "competency_id": competency_id,
                "competency_name": competency_name,
                "competency_levels": []
            })
            count=count+1
            if count==2:
                break
    print("LLM output")
    print(final_output)   
    return final_output
